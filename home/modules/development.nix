# @file home/modules/development.nix
# @description Multi-language development environment with toolchains and utilities
# @update-policy Update when adding new languages or development tools

{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Core development tooling
    lazygit        # Git TUI (git itself configured via programs.git below)
    gnumake
    cmake
    pkg-config

    # JavaScript / TypeScript
    # Using Node.js 22 LTS - long-term support until April 2027
    nodejs_22
    nodePackages_latest.typescript
    nodePackages_latest.pnpm

    # Go
    # Using Go 1.24 - latest stable with improved performance
    go_1_24

    # Python
    # Using Python 3.14.2 - latest stable with modern features
    python314
    python314Packages.pip
    python314Packages.virtualenv
    python314Packages.poetry

    # Nim
    # Latest stable Nim compiler
    nim

    # .NET / C#
    # Using .NET SDK 9 - latest LTS (long-term support)
    dotnet-sdk_9

    # R language and tooling
    R
    rPackages.languageserver

    # Elixir managed through asdf (see elixir.nix)
    # Provides flexibility for project-specific Erlang/Elixir versions
    asdf-vm

    # Cloud + infrastructure
    awscli2
    google-cloud-sdk
    terraform
    terraform-ls
    kubectl
    helm
    k9s

    # Documentation and typesetting
  texlive.combined.scheme-medium # scheme-medium is the stability sweet spot on Leap 15.6 (≈2 GB); add per-project pkgs via tlmgr if required


    # Quality and validation tools
    shellcheck      # Shell script linter (required for lefthook)
    markdownlint-cli  # Markdown linter
    # xmllint is part of libxml2 (usually pre-installed on openSUSE)
    lefthook        # Git hooks manager
  ];

  programs.bash.shellAliases = {
    d = "docker";
    "d-ps" = "docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'";
    "d-stacks" = "docker compose ls";
    "d-logs" = "docker compose logs -f";
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    
    # === Nix-based Python Development with direnv ===
    #
    # direnv automatically loads project-specific environments when you cd into a directory.
    # For Python projects, we recommend using Nix flakes with the hybrid approach:
    # - Nix provides system dependencies (Python, libsodium, build tools)
    # - pip/venv manages Python packages (installed in .venv)
    #
    # Quick Start:
    # 1. Create .envrc in your project root:
    #      use flake
    #
    # 2. Create flake.nix (see examples/python-nix-direnv/flake.nix)
    #
    # 3. Allow direnv:
    #      direnv allow
    #
    # The environment activates automatically when you enter the directory.
    # Your shell prompt shows "direnv" when active.
    #
    # For detailed documentation:
    # - Generic Python workflow: docs/python-development.md
    # - KERI development: docs/keri-development.md
    # - Example template: examples/python-nix-direnv/
    #
    # Legacy alternatives (not recommended):
    # - poetry: Add "layout poetry" to .envrc
    # - virtualenv: Add "layout python python3.14" to .envrc
  };

  # Session variables for development environment
  home.sessionVariables = {
    # Editors
    EDITOR = "vim";
    VISUAL = "vim";
    
    # Development paths
    GOPATH = "${config.home.homeDirectory}/go";
    
    # Build flags
    MAKEFLAGS = "-j$(nproc)";
    
    # PERF: Build cache directories (explicit configuration)
    GOCACHE = "${config.home.homeDirectory}/.cache/go-build";
    GOMODCACHE = "${config.home.homeDirectory}/go/pkg/mod";
    
    # Python
    PYTHONDONTWRITEBYTECODE = "1";  # Don't create .pyc files
    PIP_CACHE_DIR = "${config.home.homeDirectory}/.cache/pip";
    
    # direnv (reduce log noise)
    DIRENV_LOG_FORMAT = "";
    
    # Node.js
    NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.npm-global";
    NPM_CONFIG_CACHE = "${config.home.homeDirectory}/.cache/npm";
    
    # Elixir/Erlang build optimization
    ERL_AFLAGS = "-kernel shell_history enabled";
    
    # Cargo (Rust) cache
    CARGO_HOME = "${config.home.homeDirectory}/.cargo";
    
    # Nix build optimization
    NIX_BUILD_CORES = "0";  # Use all available cores
    
    # === TELEMETRY DISABLING (duplicated from privacy.nix for development context) ===
    # Note: These are also set in privacy.nix, but duplicated here for visibility
    # in development context and to ensure they're set even if privacy.nix is disabled
    
    # Go telemetry (Go 1.23+)
    GOTELEMETRY = "off";
    GOTELEMETRYDIR = "/dev/null";
    
    # .NET CLI telemetry
    DOTNET_CLI_TELEMETRY_OPTOUT = "1";
    
    # Terraform telemetry
    CHECKPOINT_DISABLE = "1";
  };

  programs.go = {
    enable = true;
    goPath = "~/go";
  };

  # Module metadata
  meta = {
    maintainers = [ "Jay Elliot" ];
  };
}
