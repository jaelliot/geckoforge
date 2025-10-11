{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Core development tooling
    git
    lazygit
    gnumake
    cmake
    pkg-config

    # JavaScript / TypeScript
    nodejs_22
    nodePackages_latest.typescript
    nodePackages_latest.pnpm

    # Go
    go_1_24

    # Python
    python312
    python312Packages.pip
    python312Packages.virtualenv
    python312Packages.poetry

    # Nim
    nim

    # .NET / C#
    dotnet-sdk_9

    # R language and tooling
    R
    rPackages.languageserver

    # Elixir managed through asdf
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

    # Developer utilities (duplicated intentionally for visibility)
    jq
    yq
    ripgrep
    fd
    fzf
    bat
    eza
    htop
    ncdu

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

  programs.go = {
    enable = true;
    goPath = "~/go";
  };

  programs.git = {
    enable = true;
    ignores = [
      "*.log"
      "node_modules"
      "dist"
      "__pycache__/"
      ".venv"
    ];
  };
}
