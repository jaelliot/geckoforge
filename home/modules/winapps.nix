# @file home/modules/winapps.nix
# @description WinApps integration for seamless Windows application support
# @update-policy Update when WinApps flake changes or new configuration options emerge

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.winapps;
  
  configFile = pkgs.writeText "winapps.conf" ''
    ##################################
    #   WINAPPS CONFIGURATION FILE   #
    ##################################
    
    RDP_USER="${cfg.rdpUser}"
    RDP_PASS="${cfg.rdpPassword}"
    RDP_DOMAIN="${cfg.rdpDomain}"
    RDP_IP="${cfg.rdpIP}"
    
    WAFLAVOR="${cfg.backend}"
    RDP_SCALE="${toString cfg.displayScale}"
    REMOVABLE_MEDIA="${cfg.removableMedia}"
    RDP_FLAGS="${cfg.rdpFlags}"
    
    DEBUG="${if cfg.debug then "true" else "false"}"
    AUTOPAUSE="${if cfg.autoPause.enable then "on" else "off"}"
    AUTOPAUSE_TIME="${toString cfg.autoPause.timeout}"
    
    ${optionalString (cfg.freerdpCommand != "") ''FREERDP_COMMAND="${cfg.freerdpCommand}"''}
    
    PORT_TIMEOUT="${toString cfg.timeouts.port}"
    RDP_TIMEOUT="${toString cfg.timeouts.rdp}"
    APP_SCAN_TIMEOUT="${toString cfg.timeouts.appScan}"
    BOOT_TIMEOUT="${toString cfg.timeouts.boot}"
    
    HIDEF="${if cfg.hidef then "on" else "off"}"
  '';

  winappsFlake = builtins.fetchGit {
    url = "https://github.com/winapps-org/winapps";
    ref = "main";
  };

in
{
  options.programs.winapps = {
    enable = mkEnableOption "WinApps for Windows application integration";

    package = mkOption {
      type = types.package;
      default = (import winappsFlake).packages.${pkgs.system}.winapps;
      description = "WinApps package to use.";
    };

    launcher = mkOption {
      type = types.bool;
      default = false;
      description = "Install WinApps Launcher system tray widget.";
    };

    rdpUser = mkOption {
      type = types.str;
      default = "WinAppsUser";
      description = "Windows username for RDP connection.";
    };

    rdpPassword = mkOption {
      type = types.str;
      default = "";
      description = "Windows password for RDP connection. Leave empty to configure manually.";
    };

    rdpDomain = mkOption {
      type = types.str;
      default = "";
      description = "Windows domain (optional).";
    };

    rdpIP = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Windows VM IP address.";
    };

    backend = mkOption {
      type = types.enum [ "docker" "podman" "libvirt" "manual" ];
      default = "docker";
      description = "WinApps backend virtualization method.";
    };

    displayScale = mkOption {
      type = types.enum [ 100 140 180 ];
      default = 100;
      description = "Display scaling factor for high-DPI displays.";
    };

    removableMedia = mkOption {
      type = types.str;
      default = "/run/media";
      description = "Mount point for removable media.";
    };

    rdpFlags = mkOption {
      type = types.str;
      default = "/cert:tofu /sound /microphone +home-drive";
      description = "Additional FreeRDP flags and arguments.";
    };

    debug = mkOption {
      type = types.bool;
      default = true;
      description = "Enable debug logging to ~/.local/share/winapps/winapps.log";
    };

    autoPause = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Automatically pause Windows VM when inactive.";
      };

      timeout = mkOption {
        type = types.int;
        default = 300;
        description = "Inactivity timeout before auto-pause (seconds, minimum 20).";
        apply = timeout: max 20 timeout;
      };
    };

    freerdpCommand = mkOption {
      type = types.str;
      default = "";
      description = "Custom FreeRDP command (auto-detected if empty).";
    };

    timeouts = {
      port = mkOption {
        type = types.int;
        default = 5;
        description = "Port check timeout (seconds).";
      };

      rdp = mkOption {
        type = types.int;
        default = 30;
        description = "RDP connection test timeout (seconds).";
      };

      appScan = mkOption {
        type = types.int;
        default = 60;
        description = "Application scan timeout (seconds).";
      };

      boot = mkOption {
        type = types.int;
        default = 120;
        description = "Windows boot timeout (seconds).";
      };
    };

    hidef = mkOption {
      type = types.bool;
      default = true;
      description = "Enable FreeRDP RAIL hidef mode.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      cfg.package
    ] ++ optionals cfg.launcher [
      (import winappsFlake).packages.${pkgs.system}.winapps-launcher
    ];

    home.file.".config/winapps/winapps.conf" = mkIf (cfg.rdpPassword != "") {
      source = configFile;
      mode = "0600";
    };

    home.activation.winappsWarning = lib.hm.dag.entryBefore ["writeBoundary"] (
      optionalString (cfg.rdpPassword == "") ''
        echo "[winapps] Warning: RDP password not set. Configure manually at ~/.config/winapps/winapps.conf"
      ''
    );
  };
}
