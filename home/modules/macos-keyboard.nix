# @file home/modules/macos-keyboard.nix
# @description macOS-style keyboard remapping using Kanata for Command/Control swap
# @update-policy Update when keyboard layout or remapping rules change

{ config, lib, pkgs, ... }:

let
  cfg = config.geckoforge.macosKeyboard;
  mkKanataConfig = devicePath: ''
(defcfg
  input  (device-file "${devicePath}")
  output (uinput-sink "kanata-macos-virtual")
  fallthrough true
  allow-cmd true
)

(defsrc
  esc      f1    f2    f3    f4    f5    f6    f7    f8    f9    f10   f11   f12
  grv      1     2     3     4     5     6     7     8     9     0     minus equal bspc
  tab      q     w     e     r     t     y     u     i     o     p     lbrc rbrc bslash
  capslock a     s     d     f     g     h     j     k     l     semicolon apostrophe ret
  lsft     z     x     c     v     b     n     m     comma dot   slash rsft
  lctl     lmet  lalt  spc   ralt  rmet  menu  rctl
)

(deflayer macos
  esc      f1    f2    f3    f4    f5    f6    f7    f8    f9    f10   f11   f12
  grv      1     2     3     4     5     6     7     8     9     0     minus equal bspc
  tab      q     w     e     r     t     y     u     i     o     p     lbrc rbrc bslash
  capslock a     s     d     f     g     h     j     k     l     semicolon apostrophe ret
  lsft     z     x     c     v     b     n     m     comma dot   slash rsft
  lmet     lctl  lalt  spc   ralt  rctl  menu  rmet
)
'';

  kanataDevicePath =
    if cfg.devicePath != null then cfg.devicePath
    else "/dev/input/by-path/platform-i8042-serio-0-event-kbd";

  vsCodeKeybindings = pkgs.writeText "keybindings.json" ''
[
  { "key": "cmd+c", "command": "editor.action.clipboardCopyAction" },
  { "key": "cmd+v", "command": "editor.action.clipboardPasteAction" },
  { "key": "cmd+x", "command": "editor.action.clipboardCutAction" },
  { "key": "cmd+s", "command": "workbench.action.files.save" },
  { "key": "cmd+shift+s", "command": "workbench.action.files.saveAs" },
  { "key": "cmd+q", "command": "workbench.action.quit" },
  { "key": "cmd+w", "command": "workbench.action.closeActiveEditor" },
  { "key": "cmd+t", "command": "workbench.action.showAllSymbols" },
  { "key": "cmd+,", "command": "workbench.action.openSettings" }
]
'';

in {
  options.geckoforge.macosKeyboard = {
    enable = lib.mkEnableOption "macOS-style keyboard remapping via Kanata";

    devicePath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = lib.mdDoc ''
        Absolute path to the keyboard device Kanata should capture.
        Run `kanata --list-devices` or `scripts/setup-macos-keyboard.sh` to
        discover the appropriate `/dev/input/...` path. Defaults to the primary
        built-in keyboard path commonly used on laptops.
      '';
      example = "/dev/input/by-path/platform-i8042-serio-0-event-kbd";
    };

    manageVSCode = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = lib.mdDoc "Whether to install macOS-style VS Code keybindings.";
    };

    manageFirefox = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = lib.mdDoc "Whether to set Firefox accelKey to Meta (Cmd).";
    };

    manageKate = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = lib.mdDoc "Whether to override Kate shortcuts with Meta equivalents.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.kanata ];

    xdg.configFile."kanata/macos.kbd" = {
      text = mkKanataConfig kanataDevicePath;
      onChange = ''
        systemctl --user try-restart kanata-macos.service >/dev/null 2>&1 || true
      '';
    };

    systemd.user.services."kanata-macos" = {
      Unit = {
        Description = "Kanata macOS-style keyboard remapping";
        After = [ "graphical-session.target" ];
        ConditionPathExists = "%h/.config/kanata/macos.kbd";
      };
      Service = {
        Type = "simple";
        ExecStart = lib.escapeShellArgs [
          "kanata"
          "--cfg"
          "%h/.config/kanata/macos.kbd"
        ];
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    home.activation.macosKdeShortcuts = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      if command -v kwriteconfig5 >/dev/null 2>&1; then
        kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window Close" "Meta+Q\tAlt+F4,Meta+Q,Close Window"
        kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window Minimize" "Meta+M,Meta+M,Minimize Window"
        kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Walk Through Windows" "Meta+Tab,Alt+Tab,Walk Through Windows"
        kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Walk Through Windows (Reverse)" "Meta+Shift+Tab,Alt+Shift+Tab,Walk Through Windows (Reverse)"
        kwriteconfig5 --file ksmserver --group logout --key "Lock Session" "Meta+L\tCtrl+Alt+L,Meta+L,Lock Screen"
        qdbus org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
      fi
    '';

    xdg.configFile."Code/User/keybindings.json" = lib.mkIf cfg.manageVSCode {
      source = vsCodeKeybindings;
    };

    programs.firefox = lib.mkIf (cfg.manageFirefox && config.programs.firefox.enable) (lib.mkMerge [
      {
        profiles.default.settings."ui.key.accelKey" = 224;
      }
    ]);

    home.activation.macosKateShortcuts = lib.mkIf cfg.manageKate (config.lib.dag.entryAfter [ "writeBoundary" ] ''
      if command -v kwriteconfig5 >/dev/null 2>&1; then
        kwriteconfig5 --file katerc --group Shortcuts --key copy "Meta+C"
        kwriteconfig5 --file katerc --group Shortcuts --key paste "Meta+V"
        kwriteconfig5 --file katerc --group Shortcuts --key cut "Meta+X"
        kwriteconfig5 --file katerc --group Shortcuts --key save "Meta+S"
        kwriteconfig5 --file katerc --group Shortcuts --key close "Meta+W"
      fi
    '');
  };
}
