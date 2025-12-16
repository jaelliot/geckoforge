{ config, pkgs, ... }:

{
  imports = [
    ./modules/auto-updates.nix
    ./modules/backup.nix
    ./modules/cli.nix
    ./modules/desktop.nix
    ./modules/development.nix
    ./modules/docker.nix
    ./modules/elixir.nix
    ./modules/firefox.nix
    ./modules/gaming.nix
    ./modules/kde-theme.nix
    ./modules/macos-keyboard.nix
    ./modules/network.nix
    ./modules/power.nix
    ./modules/security.nix
    ./modules/shell.nix
    ./modules/thunderbird.nix
    ./modules/vscode.nix
    ./modules/winapps.nix
  ];

  home.username = "jay";
  home.homeDirectory = "/home/jay";
  home.stateVersion = "24.05";

  programs.home-manager.enable = true;

  # VS Code with all language support (migrated from existing setup)
  programs.vscode = {
    enable = true;
    
    # All languages from your current VS Code setup
    languageSupport = {
      python = true;
      elixir = true;
      go = true;
      csharp = true;
      r = true;
      nix = true;
      latex = true;
      terraform = true;
    };
    
    features = {
      copilot = true;    # GitHub Copilot (requires sign-in)
      docker = true;
      markdown = true;
    };
    
    # Add any custom settings here
    customSettings = {
      # "editor.fontSize" = 14;
      # "editor.fontFamily" = "'JetBrains Mono', 'Fira Code', monospace";
    };
  };

  programs.git = {
    enable = true;
    userName = "Jay";
    userEmail = "jay@example.com";
    ignores = [
      "*.log"
      "node_modules"
      "dist"
      "__pycache__/"
      ".venv"
    ];
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
