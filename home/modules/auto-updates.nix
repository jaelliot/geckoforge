# @file home/modules/auto-updates.nix
# @description Automatic security updates via systemd timers
# @update-policy Update when security update strategies change

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.autoUpdates;
in

{
  options.programs.autoUpdates = {
    enable = mkEnableOption "automatic security updates";
    
    schedule = mkOption {
      type = types.str;
      default = "daily";
      example = "02:00";
      description = "When to run updates (systemd calendar format)";
    };
    
    randomDelay = mkOption {
      type = types.int;
      default = 3600;
      description = "Random delay in seconds (prevents all machines updating at once)";
    };
    
    onlySecurityPatches = mkOption {
      type = types.bool;
      default = true;
      description = "Only install security patches (not all updates)";
    };
  };
  
  config = mkIf cfg.enable {
    # Generate systemd user units for reference
    # User must install to system: sudo cp ~/.config/systemd/user/* /etc/systemd/system/
    
    xdg.configFile."systemd/user/geckoforge-security-updates.service".text = ''
      [Unit]
      Description=Apply security patches via zypper
      After=network-online.target
      Wants=network-online.target
      
      [Service]
      Type=oneshot
      ExecStart=${pkgs.zypper}/bin/zypper --non-interactive ${if cfg.onlySecurityPatches then "patch --category security" else "update"}
      Nice=10
      IOSchedulingClass=best-effort
      IOSchedulingPriority=7
      SuccessExitStatus=0 100
    '';
    
    xdg.configFile."systemd/user/geckoforge-security-updates.timer".text = ''
      [Unit]
      Description=Daily security patch installation
      
      [Timer]
      OnCalendar=${cfg.schedule}
      RandomizedDelaySec=${toString cfg.randomDelay}
      Persistent=true
      
      [Install]
      WantedBy=timers.target
    '';
    
    # Installation helper script
    home.file.".local/bin/install-auto-updates" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Install auto-updates systemd units system-wide
        
        echo "Installing geckoforge auto-updates to system..."
        
        sudo cp ~/.config/systemd/user/geckoforge-security-updates.service /etc/systemd/system/
        sudo cp ~/.config/systemd/user/geckoforge-security-updates.timer /etc/systemd/system/
        
        sudo systemctl daemon-reload
        sudo systemctl enable --now geckoforge-security-updates.timer
        
        echo "✓ Auto-updates enabled"
        echo ""
        echo "Status: sudo systemctl status geckoforge-security-updates.timer"
        echo "Logs: sudo journalctl -u geckoforge-security-updates.service"
      '';
    };
    
    # Activation message
    home.activation.autoUpdatesInfo = lib.hm.dag.entryAfter ["writeBoundary"] ''
      echo "[auto-updates] Systemd units generated in ~/.config/systemd/user/"
      echo "[auto-updates] To enable system-wide: install-auto-updates"
    '';
    
    # Shell aliases
    programs.bash.shellAliases = mkIf config.programs.bash.enable {
      update-status = "sudo systemctl status geckoforge-security-updates.timer";
      update-logs = "sudo journalctl -u geckoforge-security-updates.service -n 50";
    };
    
    programs.zsh.shellAliases = mkIf config.programs.zsh.enable {
      update-status = "sudo systemctl status geckoforge-security-updates.timer";
      update-logs = "sudo journalctl -u geckoforge-security-updates.service -n 50";
    };
  };
}
