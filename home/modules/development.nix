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
    # Using Python 3.12 - modern features (match statements, typing improvements)
    python312
    python312Packages.pip
    python312Packages.virtualenv
    python312Packages.poetry

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
    
    # Python
    PYTHONDONTWRITEBYTECODE = "1";  # Don't create .pyc files
    
    # Node.js
    NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.npm-global";
    
    # Elixir/Erlang (set by asdf, documented here for reference)
    # KERL_BUILD_DOCS="yes"
    # KERL_INSTALL_HTMLDOCS="no"
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
