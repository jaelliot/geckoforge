# @file home/modules/docker.nix
# @description Docker utilities and automation
# @update-policy Update when Docker management needs change

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.docker;
in

{
  options.programs.docker = {
    utilities = {
      enable = mkEnableOption "Docker utility scripts and automation";
      
      autoPrune = mkOption {
        type = types.bool;
        default = true;
        description = "Enable automatic pruning of unused containers/images";
      };
      
      pruneSchedule = mkOption {
        type = types.str;
        default = "weekly";
        description = "When to prune (systemd calendar format)";
      };
      
      pruneAll = mkOption {
        type = types.bool;
        default = true;
        description = "Prune all unused images (not just dangling)";
      };
      
      pruneVolumes = mkOption {
        type = types.bool;
        default = false;
        description = "Also prune unused volumes (be careful!)";
      };
    };
  };
  
  config = mkIf cfg.utilities.enable {
    # PERF: Docker daemon configuration (for reference, requires root to apply)
    xdg.configFile."docker/daemon.json".text = builtins.toJSON {
      # Storage driver optimized for Btrfs (openSUSE default)
      storage-driver = "overlay2";
      storage-opts = [
        "overlay2.override_kernel_check=true"
      ];
      
      # Log rotation to prevent disk fill
      log-driver = "json-file";
      log-opts = {
        max-size = "10m";
        max-file = "3";
      };
      
      # Resource limits
      default-ulimits = {
        nofile = {
          Name = "nofile";
          Hard = 64000;
          Soft = 64000;
        };
      };
      
      # Performance optimizations
      max-concurrent-downloads = 10;
      max-concurrent-uploads = 5;
      
      # NVIDIA GPU support
      runtimes = {
        nvidia = {
          path = "nvidia-container-runtime";
          runtimeArgs = [];
        };
      };
      
      # IPv6 disabled (if not needed)
      ipv6 = false;
      
      # Experimental features
      experimental = false;
      
      # Live restore (containers keep running during daemon restart)
      live-restore = true;
    };
    
    # Docker prune systemd units
    xdg.configFile."systemd/user/docker-prune.service".text = ''
      [Unit]
      Description=Prune unused Docker containers and images
      
      [Service]
      Type=oneshot
      ExecStart=${pkgs.docker}/bin/docker system prune ${optionalString cfg.utilities.pruneAll "-a"} -f ${optionalString cfg.utilities.pruneVolumes "--volumes"}
    '';
    
    xdg.configFile."systemd/user/docker-prune.timer".text = ''
      [Unit]
      Description=${if cfg.utilities.pruneSchedule == "weekly" then "Weekly" else "Scheduled"} Docker cleanup
      
      [Timer]
      OnCalendar=${cfg.utilities.pruneSchedule}
      Persistent=true
      
      [Install]
      WantedBy=timers.target
    '';
    
    # Installation helper
    home.file.".local/bin/install-docker-prune" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Install Docker prune timer system-wide
        
        echo "Installing Docker auto-prune timer..."
        
        sudo cp ~/.config/systemd/user/docker-prune.service /etc/systemd/system/
        sudo cp ~/.config/systemd/user/docker-prune.timer /etc/systemd/system/
        
        sudo systemctl daemon-reload
        sudo systemctl enable --now docker-prune.timer
        
        echo "✓ Docker auto-prune enabled"
        echo ""
        echo "Status: sudo systemctl status docker-prune.timer"
        echo "Manual prune: docker system prune -a${optionalString cfg.utilities.pruneVolumes " --volumes"}"
      '';
    };
    
    # Docker status script
    home.file.".local/bin/docker-status" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Show Docker disk usage and status
        
        echo "=== Docker Status ==="
        echo ""
        
        if ! command -v docker >/dev/null; then
            echo "Docker not installed"
            exit 1
        fi
        
        if ! docker info >/dev/null 2>&1; then
            echo "Docker daemon not running"
            echo "Start: sudo systemctl start docker"
            exit 1
        fi
        
        echo "Disk Usage:"
        docker system df
        
        echo ""
        echo "Running Containers:"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Size}}"
        
        echo ""
        echo "Auto-Prune Status:"
        if systemctl is-enabled docker-prune.timer >/dev/null 2>&1; then
            systemctl status docker-prune.timer --no-pager --lines=0
        else
            echo "  Not enabled (run: install-docker-prune)"
        fi
      '';
    };
    
    # Activation message
    home.activation.dockerUtilitiesInfo = lib.hm.dag.entryAfter ["writeBoundary"] ''
      ${optionalString cfg.utilities.autoPrune ''
        echo "[docker] Auto-prune timer generated (${cfg.utilities.pruneSchedule})"
        echo "[docker] To enable: install-docker-prune"
      ''}
      echo "[docker] Check status: docker-status"
    '';
    
    # Shell aliases
    programs.bash.shellAliases = mkIf config.programs.bash.enable {
      dps = "docker ps";
      dpsa = "docker ps -a";
      dimg = "docker images";
      dprune = "docker system prune -a${optionalString cfg.utilities.pruneVolumes " --volumes"}";
      dstat = "docker-status";
    };
    
    programs.zsh.shellAliases = mkIf config.programs.zsh.enable {
      dps = "docker ps";
      dpsa = "docker ps -a";
      dimg = "docker images";
      dprune = "docker system prune -a${optionalString cfg.utilities.pruneVolumes " --volumes"}";
      dstat = "docker-status";
    };
  };
}
