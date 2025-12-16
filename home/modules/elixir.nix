# @file home/modules/elixir.nix
# @description Elixir and Erlang development environment via asdf version manager
# @update-policy Update when Erlang/Elixir versions change or asdf configuration needs adjustment

{ config, pkgs, ... }:

let
  asdfPkg = pkgs.asdf-vm;
  asdfSh = "${asdfPkg}/share/asdf-vm/asdf.sh";
  asdfDataDir = "${config.home.homeDirectory}/.asdf";
  toolVersions = "${config.home.homeDirectory}/.tool-versions";
  erlangVersion = "28.1";
  elixirVersion = "1.18.4-otp-28";
  phoenixArchive = "phx_new";
  phoenixArchiveVersion = "1.7.12";
  importNodeKeys = "${asdfDataDir}/plugins/nodejs/bin/import-release-team-keyring";
  asdfBin = "${asdfPkg}/bin/asdf";
  elixirLsExtension = pkgs.vscode-extensions.jakebecker.elixir-ls;
in
{
  home.packages = with pkgs; [
    autoconf
    automake
    libtool
    m4
    unzip
    gnumake
    gcc
    pkg-config
    ncurses
    openssl
    wxGTK32
    libGL
    libGLU
    fop
    perl
    git
    elixir_ls
  ];

  home.sessionVariables = {
    ASDF_DATA_DIR = asdfDataDir;
    ASDF_DEFAULT_TOOL_VERSIONS_FILENAME = toolVersions;
  };

  home.sessionPath = [
    "${asdfDataDir}/bin"
    "${asdfDataDir}/shims"
  ];

  programs.bash.initExtra = ''
    if [ -f "${asdfSh}" ]; then
      . "${asdfSh}"
    fi
  '';

  home.activation.asdfElixirBootstrap = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    export ASDF_DATA_DIR="${asdfDataDir}"
    export ASDF_DEFAULT_TOOL_VERSIONS_FILENAME="${toolVersions}"
    mkdir -p "$ASDF_DATA_DIR"

    PATH="${asdfPkg}/bin:$ASDF_DATA_DIR/bin:$ASDF_DATA_DIR/shims:$PATH"
    ASDF_BIN="${asdfBin}"

    if [ ! -f "${asdfSh}" ]; then
      echo "[asdf] asdf shim script missing; ensure asdf-vm package is installed." >&2
      exit 1
    fi

    . "${asdfSh}"

    install_plugin() {
      local plugin="$1"
      local repo="$2"
      if ! "$ASDF_BIN" plugin list | grep -Fx "$plugin" >/dev/null 2>&1; then
        "$ASDF_BIN" plugin add "$plugin" "$repo"
      fi
    }

    install_plugin erlang https://github.com/asdf-vm/asdf-erlang.git
    install_plugin elixir https://github.com/asdf-vm/asdf-elixir.git
    install_plugin nodejs https://github.com/asdf-vm/asdf-nodejs.git

    if [ ! -f "$ASDF_DATA_DIR/keyrings/nodejs/release-keyring.gpg" ] && [ -x "${importNodeKeys}" ]; then
      "${importNodeKeys}"
    fi

    install_tool() {
      local plugin="$1"
      local version="$2"
      if ! "$ASDF_BIN" list "$plugin" 2>/dev/null | grep -Fx "$version" >/dev/null 2>&1; then
        echo "[asdf] Installing $plugin $version..."
        if ! "$ASDF_BIN" install "$plugin" "$version"; then
          echo "[asdf] ERROR: Failed to install $plugin $version" >&2
          echo "[asdf] Check build dependencies for $plugin" >&2
          return 1
        fi
      else
        echo "[asdf] $plugin $version already installed"
      fi
      
      echo "[asdf] Setting global $plugin version to $version"
      "$ASDF_BIN" global "$plugin" "$version"
    }

    install_tool erlang "${erlangVersion}"
    install_tool elixir "${elixirVersion}"

    latest_node_minor="$($ASDF_BIN latest nodejs 22 >/dev/null 2>&1 && $ASDF_BIN latest nodejs 22)"
    if [ -z "$latest_node_minor" ]; then
      latest_node_minor="22.7.0"
    fi
    install_tool nodejs "$latest_node_minor"

    "$ASDF_BIN" reshim

    # Generate .tool-versions file in home directory
    echo "[asdf] Generating ~/.tool-versions"
    cat > "${toolVersions}" <<EOF
erlang ${erlangVersion}
elixir ${elixirVersion}
nodejs $latest_node_minor
EOF
    echo "[asdf] Created ${toolVersions}"

    # Install Hex and Rebar if mix is available
    if command -v mix >/dev/null 2>&1; then
      echo "[asdf] Installing Hex and Rebar..."
      mix local.hex --force
      mix local.rebar --force
      
      # Install Phoenix archive
      if ! mix archive --list | grep -F "${phoenixArchive}-${phoenixArchiveVersion}" >/dev/null 2>&1; then
        echo "[asdf] Installing Phoenix ${phoenixArchiveVersion}..."
        mix archive.install hex ${phoenixArchive} ${phoenixArchiveVersion} --force
      fi
    else
      echo "[asdf] WARNING: mix not found, skipping Hex/Rebar installation" >&2
    fi
    
    echo "[asdf] ✓ Elixir development environment ready"
    echo "[asdf] Erlang: ${erlangVersion}, Elixir: ${elixirVersion}, Node.js: $latest_node_minor"
  '';

  programs.vscode = {
    enable = true;
    extensions = [ elixirLsExtension ];
  };
}
