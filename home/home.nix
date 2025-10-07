{ config, pkgs, ... }:

{
  home.username = "jay";
  home.homeDirectory = "/home/jay";
  home.stateVersion = "24.05";

  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    userName = "Jay";
    userEmail = "jay@example.com";
  };

  home.activation.installFlatpaks = config.lib.dag.entryAfter ["writeBoundary"] ''
    if command -v flatpak >/dev/null 2>&1; then
      echo "Installing Flatpaks..."
      flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo || true

      flatpak install -y --user --noninteractive flathub com.getpostman.Postman || true
      flatpak install -y --user --noninteractive flathub io.dbeaver.DBeaverCommunity || true
      flatpak install -y --user --noninteractive flathub com.google.AndroidStudio || true
      flatpak install -y --user --noninteractive flathub com.obsproject.Studio || true
      flatpak install -y --user --noninteractive flathub org.signal.Signal || true
    fi
  '';
}
