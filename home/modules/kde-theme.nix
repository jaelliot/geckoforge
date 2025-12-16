# @file home/modules/kde-theme.nix
# @description Declarative KDE theme configuration via Home-Manager
# @update-policy Update when new theme options or KDE versions require changes
# @note Consolidates theme activation and Night Color configuration

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.kde.theme;
in

{
  options.programs.kde.theme = {
    enable = mkEnableOption "Mystical Blue (Jux) KDE theme";
    
    colorScheme = mkOption {
      type = types.str;
      default = "JuxTheme";
      description = "KDE color scheme name";
    };
    
    plasmaTheme = mkOption {
      type = types.str;
      default = "JuxPlasma";
      description = "Plasma desktop theme name";
    };
    
    windowDecoration = mkOption {
      type = types.str;
      default = "__aurorae__svg__JuxDeco";
      description = "Window decoration theme";
    };
    
    kvantumTheme = mkOption {
      type = types.str;
      default = "NoMansSkyJux";
      description = "Kvantum Qt theme name";
    };
    
    nightColor = {
      enable = mkEnableOption "KDE Night Color (blue light reduction)";
      
      mode = mkOption {
        type = types.enum [ "Constant" "Automatic" "Times" "Location" ];
        default = "Automatic";
        description = "Night Color activation mode";
      };
      
      dayTemperature = mkOption {
        type = types.int;
        default = 6500;
        description = "Color temperature during day (K)";
      };
      
      nightTemperature = mkOption {
        type = types.int;
        default = 3500;
        description = "Color temperature at night (K)";
      };
      
      transitionTime = mkOption {
        type = types.int;
        default = 1800;
        description = "Transition duration in seconds (default: 30 minutes)";
      };
    };
  };
  
  config = mkIf cfg.enable {
    # KDE color scheme
    home.file.".config/kdeglobals".text = ''
      [General]
      ColorScheme=${cfg.colorScheme}
    '';
    
    # Plasma desktop theme
    home.file.".config/plasmarc".text = ''
      [Theme]
      name=${cfg.plasmaTheme}
    '';
    
    # Window decorations
    home.file.".config/kwinrc".text = ''
      [org.kde.kdecoration2]
      theme=${cfg.windowDecoration}
      
      ${optionalString cfg.nightColor.enable ''
      [NightColor]
      Active=true
      Mode=${toString (if cfg.nightColor.mode == "Automatic" then 0
                      else if cfg.nightColor.mode == "Location" then 1
                      else if cfg.nightColor.mode == "Times" then 2
                      else 3)}
      NightTemperature=${toString cfg.nightColor.nightTemperature}
      DayTemperature=${toString cfg.nightColor.dayTemperature}
      TransitionTime=${toString cfg.nightColor.transitionTime}
      ''}
    '';
    
    # Kvantum theme
    home.file.".config/Kvantum/kvantum.kvconfig".text = ''
      [General]
      theme=${cfg.kvantumTheme}
    '';
    
    # Ensure Kvantum is available
    home.packages = with pkgs; [
      libsForQt5.qtstyleplugin-kvantum
      qt6Packages.qtstyleplugin-kvantum
    ];
  };
}