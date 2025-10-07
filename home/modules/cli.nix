{ pkgs, ... }:

{
  home.packages = with pkgs; [
    ripgrep
    fd
    fzf
    bat
    eza
    zoxide
    htop
    ncdu
    wget
    curl
    jq
    yq
  ];

  programs.bash = {
    enable = true;
    shellAliases = {
      ls = "eza";
      cat = "bat";
      grep = "rg";
    };
  };
}
