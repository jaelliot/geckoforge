# @file home/modules/gaming.nix
# @description Steam gaming optimizations for drone training and simulation
# @update-policy Update when new Steam features, gamemode, or GPU optimizations emerge

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.gaming;
in

{
  options.programs.gaming = {
    enable = mkEnableOption "Steam gaming with optimizations";
    
    steam = {
      enable = mkEnableOption "Steam with FHS environment" // { default = cfg.enable; };
      
      extraCompatPackages = mkOption {
        type = types.listOf types.package;
        default = [ pkgs.proton-ge-bin ];
        description = "Additional compatibility tools (Proton versions, Wine, etc.)";
      };
      
      extraLibraries = mkOption {
        type = types.listOf types.package;
        default = [ ];
        description = "Extra 32-bit libraries for game compatibility";
      };
    };
    
    performance = {
      gamemode = mkEnableOption "Gamemode for CPU/GPU optimizations" // { default = cfg.enable; };
      
      mangohud = mkEnableOption "MangoHud for FPS/performance overlay" // { default = cfg.enable; };
      
      cpuGovernor = mkOption {
        type = types.enum [ "performance" "ondemand" "conservative" "powersave" "schedutil" ];
        default = "performance";
        description = "CPU governor when gamemode activates";
      };
      
      niceLevel = mkOption {
        type = types.int;
        default = -10;
        description = "Process priority for games (lower = higher priority)";
      };
      
      ioClass = mkOption {
        type = types.str;
        default = "realtime";
        description = "I/O scheduling class for games";
      };
      
      enableShaderCache = mkOption {
        type = types.bool;
        default = true;
        description = "Enable shader pre-compilation cache";
      };
    };
    
    optimizations = {
      vmMaxMapCount = mkOption {
        type = types.int;
        default = 2147483642;
        description = "Increase vm.max_map_count for games (prevents crashes)";
      };
      
      openFileLimit = mkOption {
        type = types.int;
        default = 524288;
        description = "Increase open file descriptor limit";
      };
      
      disableCompositor = mkOption {
        type = types.bool;
        default = false;
        description = "Disable KDE compositor for better performance (manual toggle recommended)";
      };
      
      useVulkan = mkOption {
        type = types.bool;
        default = true;
        description = "Force Vulkan renderer for better performance";
      };
    };
    
    hardware = {
      nvidia = mkOption {
        type = types.bool;
        default = true;
        description = "Enable NVIDIA-specific optimizations";
      };
      
      gamepad = mkOption {
        type = types.bool;
        default = true;
        description = "Enable gamepad/controller support";
      };
    };
  };
  
  config = mkIf cfg.enable {
    # Steam installation with FHS compatibility
    home.packages = with pkgs; [
      # Steam client
      steam
      steam-run  # FHS-compatible chroot for non-Steam games
      
      # Proton compatibility
      ] ++ cfg.steam.extraCompatPackages ++ [
      
      # Performance tools
      ] ++ optionals cfg.performance.gamemode [
        gamemode
        gamemoderun  # Wrapper to run games with gamemode
      ] ++ optionals cfg.performance.mangohud [
        mangohud
      ] ++ [
      
      # Controller support
      ] ++ optionals cfg.hardware.gamepad [
        antimicrox  # Gamepad to keyboard mapping
        jstest-gtk  # Joystick testing
      ] ++ [
      
      # Vulkan support
      ] ++ optionals cfg.optimizations.useVulkan [
        vulkan-tools
        vulkan-loader
        vulkan-validation-layers
      ] ++ [
      
      # Additional gaming utilities
      protontricks  # Winetricks for Proton prefixes
      sc-controller  # Steam Controller configuration
      steamtinkerlaunch  # Advanced game launcher
    ];
    
    # MangoHud configuration
    xdg.configFile."MangoHud/MangoHud.conf" = mkIf cfg.performance.mangohud {
      text = ''
        # Performance overlay
        fps
        frametime=0
        frame_timing=1
        
        # GPU stats
        gpu_stats
        gpu_temp
        gpu_power
        gpu_core_clock
        gpu_mem_clock
        throttling_status
        
        # CPU stats
        cpu_stats
        cpu_temp
        cpu_power
        cpu_mhz
        
        # RAM usage
        ram
        vram
        
        # Position and style
        position=top-left
        font_size=22
        background_alpha=0.4
        round_corners=10
        
        # Toggle key
        toggle_hud=Shift_R+F12
        toggle_fps_limit=Shift_R+F1
        
        # FPS limiting
        fps_limit=0,60,120,144,165,240
        
        # Logging
        output_folder=/tmp/mangohud
        log_duration=30
        autostart_log=0
      '';
    };
    
    # Gamemode configuration
    xdg.configFile."gamemode.ini" = mkIf cfg.performance.gamemode {
      text = ''
        [general]
        ; Time in seconds before reverting to normal governor
        reaper_freq=5
        
        ; Process priority (nice level)
        desiredgov=${cfg.performance.cpuGovernor}
        defaultgov=ondemand
        
        ; I/O priority
        ioprio=${cfg.performance.ioClass}
        
        [filter]
        ; Whitelist (empty = all processes)
        whitelist=
        
        ; Blacklist
        blacklist=
        
        [gpu]
        ; Apply GPU optimizations
        apply_gpu_optimisations=accept
        
        ; NVIDIA power mode (0=adaptive, 1=prefer maximum performance)
        ${optionalString cfg.hardware.nvidia "nv_powermizer_mode=1"}
        
        ; AMD GPU power profile (auto, low, high, manual)
        amd_performance_level=high
        
        [custom]
        ; Custom scripts
        start=${pkgs.writeShellScript "gamemode-start" ''
          # Disable KDE compositor (if enabled in config)
          ${optionalString cfg.optimizations.disableCompositor ''
            qdbus org.kde.KWin /Compositor suspend
          ''}
          
          # Set process priority
          renice ${toString cfg.performance.niceLevel} -p $GAMEMODE_PIDFD
          
          # NVIDIA-specific optimizations
          ${optionalString cfg.hardware.nvidia ''
            # Set GPU power limit to max
            nvidia-smi -pl $(nvidia-smi -q -d POWER | grep "Max Power Limit" | awk '{print $5}') || true
            
            # Set GPU to performance mode
            nvidia-settings -a "[gpu:0]/GpuPowerMizerMode=1" 2>/dev/null || true
          ''}
          
          echo "Gamemode: Optimizations applied"
        ''}
        
        end=${pkgs.writeShellScript "gamemode-end" ''
          # Re-enable KDE compositor (if disabled)
          ${optionalString cfg.optimizations.disableCompositor ''
            qdbus org.kde.KWin /Compositor resume
          ''}
          
          # NVIDIA: Return to adaptive mode
          ${optionalString cfg.hardware.nvidia ''
            nvidia-settings -a "[gpu:0]/GpuPowerMizerMode=0" 2>/dev/null || true
          ''}
          
          echo "Gamemode: Reverted optimizations"
        ''}
      '';
    };
    
    # Steam launch options helper script
    home.file.".local/bin/steam-optimized" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Launch Steam with performance optimizations
        
        # Environment variables for better performance
        export __GL_SHADER_DISK_CACHE=1
        export __GL_SHADER_DISK_CACHE_SKIP_CLEANUP=1
        export DXVK_STATE_CACHE=1
        export DXVK_CONFIG_FILE="$HOME/.config/dxvk.conf"
        export vblank_mode=0  # Disable vsync (control via game)
        
        ${optionalString cfg.hardware.nvidia ''
        # NVIDIA optimizations
        export __GL_THREADED_OPTIMIZATIONS=1
        export __GL_SYNC_TO_VBLANK=0
        export PROTON_ENABLE_NVAPI=1
        export PROTON_HIDE_NVIDIA_GPU=0
        ''}
        
        ${optionalString cfg.optimizations.useVulkan ''
        # Force Vulkan
        export PROTON_USE_WINED3D=0
        ''}
        
        ${optionalString cfg.performance.enableShaderCache ''
        # Shader cache optimizations
        export MESA_SHADER_CACHE_DIR="$HOME/.cache/mesa_shader_cache"
        export RADV_PERFTEST=gpl
        mkdir -p "$MESA_SHADER_CACHE_DIR"
        ''}
        
        # Launch Steam with gamemode if available
        ${if cfg.performance.gamemode then ''
        exec gamemoderun ${pkgs.steam}/bin/steam "$@"
        '' else ''
        exec ${pkgs.steam}/bin/steam "$@"
        ''}
      '';
    };
    
    # DXVK configuration for better performance
    xdg.configFile."dxvk.conf" = {
      text = ''
        # DXVK performance optimizations
        dxvk.enableAsync = true
        dxvk.numCompilerThreads = 0  # Use all available threads
        dxvk.numAsyncThreads = 8
        
        # Shader optimizations
        dxvk.useRawSsbo = True
        
        # Memory optimizations
        dxvk.maxFrameLatency = 1
        dxvk.maxChunkSize = 32
        
        # HUD (0 = off, 1 = FPS, full = all stats)
        dxvk.hud = fps
      '';
    };
    
    # Steam library symlink helper
    home.activation.createSteamDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
      # Create Steam directories if they don't exist
      mkdir -p ~/.local/share/Steam/steamapps/compatdata
      mkdir -p ~/.local/share/Steam/steamapps/shadercache
      mkdir -p ~/.cache/mesa_shader_cache
      
      echo "Steam directories created"
    '';
    
    # Shell aliases for convenience
    programs.bash.shellAliases = mkIf config.programs.bash.enable {
      steam = "steam-optimized";
      steam-big = "steam-optimized -bigpicture";
      steam-debug = "STEAM_LINUX_RUNTIME_LOG=1 PROTON_LOG=1 steam-optimized";
      gamemode-status = "gamemoded -s";
      steam-fps = "MANGOHUD=1 steam-optimized";
    };
    
    programs.zsh.shellAliases = mkIf config.programs.zsh.enable {
      steam = "steam-optimized";
      steam-big = "steam-optimized -bigpicture";
      steam-debug = "STEAM_LINUX_RUNTIME_LOG=1 PROTON_LOG=1 steam-optimized";
      gamemode-status = "gamemoded -s";
      steam-fps = "MANGOHUD=1 steam-optimized";
    };
  };
}
