# @file home/modules/backup.nix
# @description Rclone-based encrypted cloud backup system with automation
# @update-policy Update when backup strategies or cloud providers change

{ config, pkgs, lib, ... }:

{
  # ===== Package Installation =====
  home.packages = with pkgs; [
    rclone        # Cloud storage sync and encryption
    age           # Additional encryption tool for secrets
  ];

  # ===== Rclone Configuration Structure =====
  # Note: Actual credentials configured interactively via 'rclone config'
  # This creates the directory structure and base configuration
  
  xdg.configFile."rclone/rclone.conf".text = ''
    # Rclone Configuration for Geckoforge
    # 
    # IMPORTANT: This file is managed by Home-Manager for structure only.
    # Actual remote configurations (with credentials) are added via:
    #   rclone config
    #
    # Recommended setup:
    # 1. Base remote (e.g., gdrive, s3, onedrive)
    # 2. Crypt remote wrapping the base (e.g., gdrive-crypt)
    #
    # Example structure after configuration:
    #
    # [gdrive]
    # type = drive
    # scope = drive
    # token = {...}
    #
    # [gdrive-crypt]
    # type = crypt
    # remote = gdrive:encrypted-backup
    # filename_encryption = standard
    # directory_name_encryption = true
    # password = <obscured>
    # password2 = <obscured>
    #
    # Run 'rclone config' to add your remotes
  '';

  # ===== Backup Filter Configuration =====
  # Defines what to include/exclude in backups
  
  xdg.configFile."rclone/critical-filter.txt".text = ''
    # Critical Files Backup Filter
    # Format: + include, - exclude
    
    # === Include: Configuration Files ===
    + /.config/rclone/rclone.conf
    + /.ssh/***
    + /.gnupg/***
    + /.aws/***
    + /.kube/***
    + /.docker/config.json
    + /.gitconfig
    + /.git-credentials
    
    # === Include: Shell Configuration ===
    + /.zshrc
    + /.zsh_history
    + /.p10k.zsh
    + /.bashrc
    + /.bash_history
    + /.profile
    
    # === Include: Application Configs ===
    + /.config/Code/User/settings.json
    + /.config/Code/User/keybindings.json
    + /.config/Code/User/snippets/***
    + /.cursor/***
    + /.config/kitty/***
    
    # === Include: Small Important Files ===
    + /Documents/credentials/***
    + /Documents/keys/***
    
    # === Exclude: Everything Else ===
    - *
  '';
  
  xdg.configFile."rclone/projects-filter.txt".text = ''
    # Projects Backup Filter
    # More permissive for development directories
    
    # === Include: Source Code ===
    + /git/***
    + /projects/***
    + /code/***
    
    # === Exclude: Build Artifacts ===
    - **/.git/
    - **/node_modules/
    - **/venv/
    - **/__pycache__/
    - **/target/
    - **/dist/
    - **/build/
    - **/.next/
    - **/.nuxt/
    - **/vendor/
    
    # === Exclude: Large Files ===
    - **/*.iso
    - **/*.img
    - **/*.qcow2
    - **/*.vmdk
    - **/*.log
    
    # === Exclude: Temporary Files ===
    - **/.cache/
    - **/tmp/
    - **/*.swp
    - **/*.swo
    - **/*~
  '';
  
  xdg.configFile."rclone/infra-filter.txt".text = ''
    # Infrastructure Configuration Backup Filter
    # For Kubernetes, Terraform, IaC files
    
    # === Include: Kubernetes ===
    + /.kube/config
    + /.kube/configs/***
    
    # === Include: Terraform ===
    + /terraform/***/*.tf
    + /terraform/***/*.tfvars
    + /terraform/**/.terraform.lock.hcl
    
    # === Include: Ansible ===
    + /ansible/***/*.yml
    + /ansible/***/*.yaml
    + /ansible/***/inventory
    
    # === Include: Docker Compose ===
    + /**/docker-compose.yml
    + /**/docker-compose.yaml
    
    # === Exclude: Terraform State (too large, store separately) ===
    - **/.terraform/
    - **/terraform.tfstate*
    
    # === Exclude: Everything Else ===
    - *
  '';

  # ===== Systemd Services for Automated Backups =====
  
  # Service: Critical Files Backup (daily)
  systemd.user.services.rclone-backup-critical = {
    Unit = {
      Description = "Backup critical files to encrypted cloud storage";
      After = [ "network-online.target" ];
    };
    
    Service = {
      Type = "oneshot";
      
      # Create log directory
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %h/.local/share/rclone/logs";
      
      # Run backup with filtering
      ExecStart = pkgs.writeShellScript "rclone-backup-critical" ''
        set -euo pipefail
        
        REMOTE="gdrive-crypt"  # Change to your remote name
        BACKUP_PATH="geckoforge-backups/critical"
        DATE=$(${pkgs.coreutils}/bin/date +%Y-%m-%d)
        LOG_FILE="$HOME/.local/share/rclone/logs/critical-$DATE.log"
        
        echo "[$(${pkgs.coreutils}/bin/date)] Starting critical files backup..." | ${pkgs.coreutils}/bin/tee -a "$LOG_FILE"
        
        # Check if remote exists
        if ! ${pkgs.rclone}/bin/rclone listremotes | ${pkgs.gnugrep}/bin/grep -q "^$REMOTE:"; then
          echo "[ERROR] Remote '$REMOTE' not configured. Run: rclone config" | ${pkgs.coreutils}/bin/tee -a "$LOG_FILE"
          exit 1
        fi
        
        # Sync critical files
        ${pkgs.rclone}/bin/rclone sync \
          --filter-from "$HOME/.config/rclone/critical-filter.txt" \
          "$HOME" \
          "$REMOTE:$BACKUP_PATH" \
          --backup-dir "$REMOTE:$BACKUP_PATH-archive-$DATE" \
          --fast-list \
          --transfers 8 \
          --checkers 16 \
          --log-file "$LOG_FILE" \
          --log-level INFO \
          --stats 5s \
          --stats-one-line
        
        echo "[$(${pkgs.coreutils}/bin/date)] Backup completed successfully" | ${pkgs.coreutils}/bin/tee -a "$LOG_FILE"
      '';
      
      # Cleanup old logs (keep 30 days)
      ExecStartPost = pkgs.writeShellScript "cleanup-logs" ''
        ${pkgs.findutils}/bin/find "$HOME/.local/share/rclone/logs" \
          -name "critical-*.log" \
          -mtime +30 \
          -delete
      '';
    };
  };
  
  # Timer: Run critical backup daily at 2 AM
  systemd.user.timers.rclone-backup-critical = {
    Unit = {
      Description = "Daily backup of critical files";
    };
    
    Timer = {
      OnCalendar = "*-*-* 02:00:00";  # Daily at 2 AM
      Persistent = true;  # Run if system was off at scheduled time
      RandomizedDelaySec = "15m";  # Avoid exact hour load
    };
    
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };
  
  # Service: Projects Backup (weekly)
  systemd.user.services.rclone-backup-projects = {
    Unit = {
      Description = "Backup project directories to encrypted cloud storage";
      After = [ "network-online.target" ];
    };
    
    Service = {
      Type = "oneshot";
      
      ExecStart = pkgs.writeShellScript "rclone-backup-projects" ''
        set -euo pipefail
        
        REMOTE="gdrive-crypt"
        BACKUP_PATH="geckoforge-backups/projects"
        DATE=$(${pkgs.coreutils}/bin/date +%Y-%m-%d)
        LOG_FILE="$HOME/.local/share/rclone/logs/projects-$DATE.log"
        
        echo "[$(${pkgs.coreutils}/bin/date)] Starting projects backup..." | ${pkgs.coreutils}/bin/tee -a "$LOG_FILE"
        
        if ! ${pkgs.rclone}/bin/rclone listremotes | ${pkgs.gnugrep}/bin/grep -q "^$REMOTE:"; then
          echo "[ERROR] Remote '$REMOTE' not configured" | ${pkgs.coreutils}/bin/tee -a "$LOG_FILE"
          exit 1
        fi
        
        # Sync projects with compression
        ${pkgs.rclone}/bin/rclone sync \
          --filter-from "$HOME/.config/rclone/projects-filter.txt" \
          "$HOME" \
          "$REMOTE:$BACKUP_PATH" \
          --backup-dir "$REMOTE:$BACKUP_PATH-archive-$DATE" \
          --fast-list \
          --transfers 4 \
          --checkers 8 \
          --log-file "$LOG_FILE" \
          --log-level INFO
        
        echo "[$(${pkgs.coreutils}/bin/date)] Projects backup completed" | ${pkgs.coreutils}/bin/tee -a "$LOG_FILE"
      '';
    };
  };
  
  # Timer: Run projects backup weekly on Sunday at 3 AM
  systemd.user.timers.rclone-backup-projects = {
    Unit = {
      Description = "Weekly backup of project directories";
    };
    
    Timer = {
      OnCalendar = "Sun *-*-* 03:00:00";
      Persistent = true;
    };
    
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };

  # ===== Cloud Storage Mount Service (Optional) =====
  # Uncomment and configure to mount cloud storage as a local directory
  
  # systemd.user.services.rclone-mount = {
  #   Unit = {
  #     Description = "Mount encrypted cloud storage";
  #     After = [ "network-online.target" ];
  #   };
  #   
  #   Service = {
  #     Type = "notify";
  #     ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %h/CloudStorage";
  #     ExecStart = ''
  #       ${pkgs.rclone}/bin/rclone mount gdrive-crypt: %h/CloudStorage \
  #         --vfs-cache-mode writes \
  #         --vfs-cache-max-age 24h \
  #         --dir-cache-time 1h \
  #         --poll-interval 15s \
  #         --allow-other
  #     '';
  #     ExecStop = "${pkgs.fuse}/bin/fusermount -u %h/CloudStorage";
  #     Restart = "on-failure";
  #     RestartSec = "10s";
  #   };
  #   
  #   Install = {
  #     WantedBy = [ "default.target" ];
  #   };
  # };

  # ===== Activation Scripts =====
  # Remind user to configure rclone after first boot
  
  # ===== Backup Verification Script =====
  home.file.".local/bin/check-backups" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Check rclone backup status and health
      
      RED='\033[0;31m'
      GREEN='\033[0;32m'
      YELLOW='\033[1;33m'
      NC='\033[0m'
      
      echo "=== Backup Health Check ==="
      echo ""
      
      # Check if rclone configured
      if ! ${pkgs.rclone}/bin/rclone listremotes | grep -q "."; then
          echo -e "''${RED}✗ No rclone remotes configured''${NC}"
          echo "  Run: rclone config"
          exit 1
      fi
      
      echo -e "''${GREEN}✓ Rclone configured''${NC}"
      echo "Remotes:"
      ${pkgs.rclone}/bin/rclone listremotes | sed 's/^/  /'
      echo ""
      
      # Check systemd timers
      if systemctl --user is-enabled rclone-backup-critical.timer >/dev/null 2>&1; then
          echo -e "''${GREEN}✓ Backup timer enabled''${NC}"
          
          LAST_RUN=$(systemctl --user show rclone-backup-critical.timer -p LastTriggerUSec --value 2>/dev/null)
          if [ "$LAST_RUN" != "n/a" ] && [ -n "$LAST_RUN" ]; then
              echo "  Last run: $LAST_RUN"
          else
              echo -e "  ''${YELLOW}⚠ Never run yet''${NC}"
          fi
          
          NEXT_RUN=$(systemctl --user show rclone-backup-critical.timer -p NextElapseUSecRealtime --value 2>/dev/null)
          echo "  Next run: $NEXT_RUN"
      else
          echo -e "''${YELLOW}⚠ Backup timer not enabled''${NC}"
          echo "  Enable: systemctl --user enable --now rclone-backup-critical.timer"
      fi
      
      echo ""
      echo "Commands:"
      echo "  rclone-backup-critical  - Run backup now"
      echo "  rclone-verify-critical  - Verify backup"
    '';
  };
  
  # Shell aliases for backup management
  programs.bash.shellAliases = {
    backup-status = "check-backups";
    backup-now = "rclone-backup-critical";
    backup-verify = "rclone-verify-critical";
  };
  
  programs.zsh.shellAliases = {
    backup-status = "check-backups";
    backup-now = "rclone-backup-critical";
    backup-verify = "rclone-verify-critical";
  };
  
  home.activation.rcloneSetup = lib.hm.dag.entryAfter ["writeBoundary"] ''
    echo "[backup] Rclone configuration and check-backups script installed"
    echo "[backup] Verify: check-backups"
    echo "[backup] Next steps:"
    echo "  1. Configure remote:  rclone config"
    echo "  2. Run first backup:  rclone-backup-critical"
    echo "  3. Verify backup:     rclone-verify-critical"
    echo "  4. Set up automation: systemctl --user enable --now rclone-backup-critical.timer"
  '';
}