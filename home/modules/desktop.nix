# @file home/modules/desktop.nix
# @description KDE Plasma desktop configuration including night color and Chromium
# @update-policy Update when KDE or desktop configuration changes

{ config, lib, pkgs, ... }:

with lib;

let
  nightCfg = config.programs.kde.nightColor;
  locationCfg = nightCfg.location;
  scheduleCfg = nightCfg.schedule;

  modeMapping = {
    automatic = "Automatic";
    timed = "Timings";
    constant = "Constant";
  };

  ensureTime = label: value:
    let
      pattern = "^[0-2][0-9]:[0-5][0-9]$";
    in
      if builtins.match pattern value == null then
        throw "programs.kde.nightColor.${label} must be in HH:MM format"
      else
        value;

  formatCoordinate = coord:
    let
      value = if builtins.isInt coord || builtins.isFloat coord then coord else 0;
    in
      builtins.toString value;

  nightColorLines = let
    locationLines =
      if nightCfg.mode != "automatic" then
        [ ]
      else if locationCfg.autoDetect then
        [ "LocationAuto=true" ]
      else
        [
          "LocationAuto=false"
          "LatitudeFixed=${formatCoordinate locationCfg.latitude}"
          "LongitudeFixed=${formatCoordinate locationCfg.longitude}"
        ];

    scheduleLines =
      if nightCfg.mode != "timed" then
        [ ]
      else
        [
          "EveningBeginFixed=${scheduleCfg.evening}"
          "MorningBeginFixed=${scheduleCfg.morning}"
        ];
  in
    [
      "[NightColor]"
      "Active=true"
      "Mode=${modeMapping.${nightCfg.mode}}"
      "DayTemperature=${toString nightCfg.dayTemperature}"
      "NightTemperature=${toString nightCfg.nightTemperature}"
      "TransitionTime=${toString nightCfg.transitionMinutes}"
    ]
    ++ locationLines
    ++ scheduleLines;

  nightColorFragment = optionalString nightCfg.enable (
    concatStringsSep "\n" nightColorLines
  );
in
{
  options.programs.kde = {
    kwinrcFragments = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Ordered list of INI fragments that should be written to ~/.config/kwinrc.
        Modules append fragments with mkBefore/mkAfter; desktop.nix handles final serialization.
      '';
    };

    nightColor = {
      enable = mkEnableOption "KDE Night Color blue light filtering" // { default = true; };

      dayTemperature = mkOption {
        type = types.int;
        default = 6500;
        description = "Color temperature (Kelvin) for daytime lighting.";
        apply = temp: clamp 1000 10000 temp;
      };

      nightTemperature = mkOption {
        type = types.int;
        default = 4500;
        description = "Color temperature (Kelvin) for nighttime lighting.";
        apply = temp: clamp 1000 10000 temp;
      };

      mode = mkOption {
        type = types.enum [ "automatic" "timed" "constant" ];
        default = "automatic";
        description = "Scheduling mode: automatic sunrise/sunset, fixed times, or constant tint.";
      };

      transitionMinutes = mkOption {
        type = types.int;
        default = 45;
        description = "Duration of color temperature transition in minutes.";
        apply = minutes: clamp 5 180 minutes;
      };

      location = {
        autoDetect = mkOption {
          type = types.bool;
          default = true;
          description = "Use KDE's location services to derive coordinates automatically.";
        };

        latitude = mkOption {
          type = types.nullOr types.float;
          default = null;
          description = "Manual latitude (-90.0 to 90.0) used when autoDetect = false.";
          apply = coord: if coord == null then null else clamp (-90.0) 90.0 coord;
        };

        longitude = mkOption {
          type = types.nullOr types.float;
          default = null;
          description = "Manual longitude (-180.0 to 180.0) used when autoDetect = false.";
          apply = coord: if coord == null then null else clamp (-180.0) 180.0 coord;
        };
      };

      schedule = {
        evening = mkOption {
          type = types.str;
          default = "20:00";
          description = "Start time for Night Color when using timed mode (HH:MM).";
          apply = ensureTime "schedule.evening";
        };

        morning = mkOption {
          type = types.str;
          default = "07:00";
          description = "End time for Night Color when using timed mode (HH:MM).";
          apply = ensureTime "schedule.morning";
        };
      };
    };
  };

  config = mkMerge [
    {
      home.packages = with pkgs; [
        kitty
        chromium

        # Essential fonts for development and desktop
        (nerdfonts.override { fonts = [ "FiraCode" "JetBrainsMono" "SourceCodePro" ]; })
        fira-code
        jetbrains-mono
        source-code-pro
        ubuntu-font-family
        liberation_ttf
        dejavu_fonts
        noto-fonts
        noto-fonts-cjk
        noto-fonts-emoji
      ];

      programs.chromium = {
        enable = true;

        extensions = [
          # Manifest V2-compatible extensions focused on privacy and developer tooling
          { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # uBlock Origin
          { id = "gcbommkclmclpchllfjekcdonpmejbdp"; } # HTTPS Everywhere
          { id = "pkehgijcmpdhfbdbbnkijodmdjhbjlgp"; } # Privacy Badger
          { id = "fmkadmapgofadopljbjfkapdkoienihi"; } # React Developer Tools
          { id = "hfhhnacclhffhdffklopdkcgdhifgngh"; } # Altair GraphQL Client
          { id = "mdnleldcmiljblolnjhpnblkcekpdkpa"; } # Requestly
          { id = "hlepfoohegkhhmjieoechaddaejaokhf"; } # Refined GitHub
          { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; } # Dark Reader
          { id = "mnjggcdmjocbbbhaepdhchncahnbgone"; } # SponsorBlock for YouTube
        ];

        commandLineArgs = [
          "--enable-features=VaapiVideoDecoder,CanvasOopRasterization"
          "--enable-gpu-rasterization"
          "--force-dark-mode"
          "--disable-features=UseChromeOSDirectVideoDecoder,MediaRouter"
          "--disable-background-networking"
          "--disable-default-apps"
          "--disable-search-engine-choice-screen"
          "--disable-sync"
          "--metrics-recording-only"
          "--no-default-browser-check"
          "--password-store=basic"
          "--ozone-platform-hint=auto"
        ];
      };

      # Font configuration for development and desktop use
      fonts.fontconfig.enable = true;

      # Terminal configuration with development-focused font
      programs.kitty = {
        enable = true;
        font = {
          name = "FiraCode Nerd Font Mono";
          size = 12;
        };
        settings = {
          # Font rendering
          font_family = "FiraCode Nerd Font Mono";
          bold_font = "FiraCode Nerd Font Mono Bold";
          italic_font = "FiraCode Nerd Font Mono Italic";
          bold_italic_font = "FiraCode Nerd Font Mono Bold Italic";

          # Font features for better coding
          font_features = "FiraCode-Regular +cv01 +cv02 +cv05 +cv09 +cv14 +cv16 +cv18 +cv25 +cv26 +cv28 +cv29 +cv30 +cv31";
          disable_ligatures = "never";

          # Terminal appearance
          background_opacity = "0.95";
          window_padding_width = "8";
          scrollback_lines = "10000";

          # Development-friendly colors (Gruvbox Dark)
          foreground = "#ebdbb2";
          background = "#282828";
          selection_foreground = "#655b53";
          selection_background = "#ebdbb2";

          # Gruvbox color palette
          color0 = "#282828";
          color1 = "#cc241d";
          color2 = "#98971a";
          color3 = "#d79921";
          color4 = "#458588";
          color5 = "#b16286";
          color6 = "#689d6a";
          color7 = "#a89984";
          color8 = "#928374";
          color9 = "#fb4934";
          color10 = "#b8bb26";
          color11 = "#fabd2f";
          color12 = "#83a598";
          color13 = "#d3869b";
          color14 = "#8ec07c";
          color15 = "#ebdbb2";
        };
      };
    }

    (mkIf nightCfg.enable {
      programs.kde.kwinrcFragments = mkAfter [ nightColorFragment ];
    })

    (mkIf (!nightCfg.location.autoDetect && nightCfg.enable) {
      assertions = [
        {
          assertion = locationCfg.latitude != null;
          message = "programs.kde.nightColor.location.latitude must be set when auto detection is disabled";
        }
        {
          assertion = locationCfg.longitude != null;
          message = "programs.kde.nightColor.location.longitude must be set when auto detection is disabled";
        }
      ];
    })

    (mkIf (config.programs.kde.kwinrcFragments != [ ]) {
      home.file.".config/kwinrc".text =
        let
          trimmed = map (fragment: strings.trim fragment) config.programs.kde.kwinrcFragments;
        in
          (concatStringsSep "\n\n" trimmed) + "\n";
    })
  ];
}
