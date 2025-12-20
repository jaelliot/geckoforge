# @file home/modules/espanso.nix
# @description Cross-platform text expander with declarative configuration
# @update-policy Update when adding new default shortcuts or changing espanso configuration

{ config, pkgs, lib, ... }:

{
  # Install espanso package
  home.packages = [ pkgs.espanso ];

  # Base configuration with productivity shortcuts
  home.file.".config/espanso/match/base.yml".text = ''
    matches:
      # ===== Date/Time Helpers =====
      - trigger: ":gdate"
        replace: "{{mydate}}"
        vars:
          - name: mydate
            type: date
            params:
              format: "%Y-%m-%d"
      
      - trigger: ":gtime"
        replace: "{{mytime}}"
        vars:
          - name: mytime
            type: date
            params:
              format: "%H:%M:%S"
      
      - trigger: ":gdatetime"
        replace: "{{mydatetime}}"
        vars:
          - name: mydatetime
            type: date
            params:
              format: "%Y-%m-%d %H:%M:%S"

      # ===== Development Shortcuts =====
      # Home directory path
      - trigger: ":ghome"
        replace: "${config.home.homeDirectory}"

      # ===== Git Commit Prefixes (Conventional Commits) =====
      - trigger: ":gfix"
        replace: "fix: "
      
      - trigger: ":gfeat"
        replace: "feat: "
      
      - trigger: ":gdocs"
        replace: "docs: "
      
      - trigger: ":grefactor"
        replace: "refactor: "
      
      - trigger: ":gtest"
        replace: "test: "
      
      - trigger: ":gchore"
        replace: "chore: "
      
      - trigger: ":gstyle"
        replace: "style: "
      
      - trigger: ":gperf"
        replace: "perf: "

      # ===== Common Symbols =====
      - trigger: ":shrug"
        replace: "¯\\_(ツ)_/¯"
      
      - trigger: ":check"
        replace: "✅"
      
      - trigger: ":cross"
        replace: "❌"
      
      - trigger: ":warn"
        replace: "⚠️"
      
      - trigger: ":info"
        replace: "ℹ️"
      
      - trigger: ":rocket"
        replace: "🚀"
      
      - trigger: ":bug"
        replace: "🐛"
      
      - trigger: ":fire"
        replace: "🔥"
      
      - trigger: ":sparkles"
        replace: "✨"

      # ===== Geckoforge-Specific Shortcuts =====
      - trigger: ":ghomedir"
        replace: "~/git/geckoforge/home"
      
      - trigger: ":gprofile"
        replace: "~/git/geckoforge/profile"
      
      - trigger: ":gdocs"
        replace: "~/git/geckoforge/docs"
  '';

  # espanso daemon configuration
  home.file.".config/espanso/config/default.yml".text = ''
    # ===== espanso Configuration =====
    
    # Toggle key: Alt+Shift+E to enable/disable espanso
    toggle_key: ALT+SHIFT+E
    
    # Show notification when toggling
    show_notifications: true
    
    # Preserve clipboard contents after expansion
    preserve_clipboard: true
    
    # Search trigger: Type :: to open search menu
    search_trigger: "::"
    
    # Search shortcut: Alt+Space for interactive expansion menu
    search_shortcut: ALT+SPACE
    
    # Auto-restart on config changes
    auto_restart: true
    
    # Backend configuration (X11/Wayland compatibility)
    backend: auto
    
    # Clipboard threshold (paste for expansions longer than this)
    clipboard_threshold: 100
  '';

  # Auto-start espanso as systemd user service
  systemd.user.services.espanso = {
    Unit = {
      Description = "Espanso text expander daemon";
      Documentation = "https://espanso.org/docs/";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.espanso}/bin/espanso daemon";
      Restart = "on-failure";
      RestartSec = 3;
      
      # Environment variables
      Environment = [
        "PATH=${pkgs.espanso}/bin"
      ];
    };
    
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
