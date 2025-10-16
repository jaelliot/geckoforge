{ config, pkgs, ... }:

{
  imports = [
    ./modules/backup.nix
    ./modules/cli.nix
    ./modules/desktop.nix
    ./modules/development.nix
    ./modules/elixir.nix
    ./modules/firefox.nix
    ./modules/kde-theme.nix
    ./modules/macos-keyboard.nix
    ./modules/shell.nix
    ./modules/thunderbird.nix
  ];

  home.username = "jay";
  home.homeDirectory = "/home/jay";
  home.stateVersion = "24.05";

  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    userName = "Jay";
    userEmail = "jay@example.com";
  };

  # Hardened Thunderbird email client
  programs.thunderbird-hardened = {
    enable = true;
    disableLinks = true;          # Anti-phishing: no clickable links
    disableRemoteContent = true;  # Privacy: block tracking pixels
    preferPlainText = true;       # Security: plain text by default
    disableTelemetry = true;      # Privacy: no data collection
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
