# @file home/modules/cli.nix
# @description Essential CLI utilities and shell aliases for daily workflows
# @update-policy Update when adding new CLI tools or aliases

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
