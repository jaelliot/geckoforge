# Keyboard Configuration — macOS-style Shortcuts

## Overview
This guide explains how to enable macOS-style keyboard behavior on geckoforge. The
setup uses the Kanata keyboard remapper to swap Control and Command semantics,
applies KDE Plasma shortcuts that mirror macOS defaults, and layers consistent
shortcuts into common applications like VS Code, Firefox, and Kate.

## Prerequisites
- geckoforge installation with a KDE session
- User account with sudo privileges
- Internet connectivity for package installation

## Step 1 — Run the setup script
```
./scripts/setup-macos-keyboard.sh
```

What the script does:
- Installs the `kanata` package via `zypper`
- Detects the keyboard event device (prompts when multiple are present)
- Writes `~/.config/kanata/macos.kbd` with macOS-style modifiers
- Creates and enables `kanata-macos.service` (systemd user unit)
- Updates KDE global shortcuts (Cmd+Q, Cmd+M, Cmd+Tab, Cmd+L)
- Seeds VS Code, Kate, and Firefox with Command-centric shortcuts

Log out and back in after the script completes to ensure the new uinput device is
active. For external keyboards, rerun the script when a new device is attached.

## Step 2 — Declarative Home-Manager enablement (optional)
Add the module and enable it in `home/home.nix` if you want the configuration to
be reapplied automatically by Home-Manager:

```nix
geckoforge.macosKeyboard = {
  enable = true;
  devicePath = "/dev/input/by-path/platform-i8042-serio-0-event-kbd";
  manageVSCode = true;
  manageFirefox = true;
  manageKate = true;
};
```

Apply the changes:
```
home-manager switch --flake ~/git/home
```

The module installs Kanata, writes the same configuration file, ensures the user
service stays enabled, reapplies KDE shortcuts during activation, and keeps the
application-specific bindings in sync.

## Step 3 — Verify configuration
Use the verification helper for automated checks:
```
./scripts/test-macos-keyboard.sh
```

The script verifies:
- Kanata binary availability
- Presence and content of the configuration and service files
- systemd user service status
- KDE shortcut overrides
- Application-specific keybinding files

## Manual smoke tests
- Press **Cmd+C** / **Cmd+V** inside a terminal and vs code window
- Press **Cmd+Q** to close a KDE app
- Press **Cmd+Tab** to switch windows
- In Firefox, open `about:config` and confirm `ui.key.accelKey` equals `224`

## Troubleshooting
- *Service inactive*: `systemctl --user restart kanata-macos.service`
- *Wrong keyboard captured*: rerun `scripts/setup-macos-keyboard.sh` and select the
  correct `/dev/input/...-event-kbd` entry
- *VS Code custom bindings overwritten*: disable management in Home-Manager with
  `manageVSCode = false;` and manage the file manually
- *Firefox still expects Ctrl*: ensure `~/.mozilla/firefox/<profile>/user.js`
  contains `user_pref("ui.key.accelKey", 224);`

## Related Material
- `scripts/setup-macos-keyboard.sh`
- `scripts/test-macos-keyboard.sh`
- `home/modules/macos-keyboard.nix`
