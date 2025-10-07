{ pkgs, ... }:

{
  home.packages = with pkgs; [
    git
    lazygit
    gnumake
    cmake
  ];
}
