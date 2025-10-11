# @file home/modules/kde-theme.nix
# @description Declarative KDE theme configuration via Home-Manager
# @update-policy Update when new theme options or KDE versions require changes

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