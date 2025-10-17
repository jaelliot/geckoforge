# Night Color — Blue Light Filtering

## Overview
Night Color is KDE Plasma's integrated blue light filter. geckoforge enables it
by default through Home-Manager so you start each session with a comfortable
6500K day temperature, a warmer 4500K night mode, and smooth 45-minute
transitions. This guide covers the declarative defaults, optional customization,
and verification tooling.

## Quick Start
1. Run the first-run wizard:
   ```bash
   ./scripts/firstrun-user.sh
   ```
   Accept the Night Color prompt to launch the configurator directly.
2. Make changes later with the dedicated script:
   ```bash
   ./scripts/configure-night-color.sh
   ```
3. Verify the resulting settings at any time:
   ```bash
   ./scripts/test-night-color.sh
   ```

## Declarative Defaults (Home-Manager)
The module `home/modules/desktop.nix` owns the canonical Night Color defaults. It
ships with:
- `Active=true` to ensure the filter runs on login
- `Mode=Automatic` for sunrise/sunset transitions
- Temperatures of **6500K day** and **4500K night**
- `LocationAuto=true` so KDE/GNOME location services provide coordinates
- `TransitionTime=45` for gradual eye-friendly changes

Override these values by adjusting `programs.kde.nightColor` inside your personal
Home-Manager flake:
```nix
programs.kde.nightColor = {
  enable = true;
  dayTemperature = 6200;
  nightTemperature = 4000;
  transitionMinutes = 60;
  mode = "timed";
  schedule = {
    evening = "21:00";
    morning = "06:30";
  };
  location = {
    autoDetect = false;
    latitude = 37.7749;
    longitude = -122.4194;
  };
};
```
Apply updates with `home-manager switch --flake ~/git/home`.

## Interactive Configuration Script
`scripts/configure-night-color.sh` provides an ergonomic CLI for tailoring Night
Color without editing Nix:
- Validates temperature ranges (1000K–10000K)
- Offers automatic GeoIP lookup, manual coordinates, or KDE auto-detect
- Supports automatic (sunrise/sunset), timed, and constant schedules
- Writes settings via `kwriteconfig5` and triggers a KWin reconfigure

Re-run the script whenever you change location or prefer different color
profiles. The script is idempotent and safe to execute multiple times.

## Verification Utility
`scripts/test-night-color.sh` inspects the declarative and runtime state:
- Dumps all key Night Color settings from `~/.config/kwinrc`
- Flags out-of-range temperatures or missing coordinates
- Checks the runtime DBus interface when `qdbus` is available
- Optionally performs a toggle test (DBus `toggle` twice) to confirm live updates

Warnings are emitted with exit code `2` (configuration issues) or `3` (runtime
DBus problems) so you can automate health checks in future workflows.

## Troubleshooting
- **Night Color stays disabled:** Run the configurator and ensure Home-Manager is
  enabled for your user. KDE sometimes requires a logout/login after first
  enabling the filter.
- **Automatic location fails:** Provide manual coordinates via the script or set
  `autoDetect = false` with explicit latitude/longitude in Home-Manager.
- **Settings revert after `home-manager switch`:** Update
  `home/modules/desktop.nix` (or your overlay module) so declarative values match
  your desired configuration.
- **DBus toggle test fails:** Confirm you are in a running KDE Plasma session.
  Wayland sessions require `qdbus6`; install `qt6-tools` if missing.

## Related Resources
- KDE UserBase: [Night Color](https://userbase.kde.org/Plasma/Night_Color)
- geckoforge Night Color scripts:
  - `scripts/configure-night-color.sh`
  - `scripts/test-night-color.sh`
- Home-Manager module: `home/modules/desktop.nix`
