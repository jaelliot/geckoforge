# Geckoforge v0.4.0 Migration Guide
**Date**: 2025-12-15  
**Changes**: Script consolidation, Nix migration, Home-Manager enhancements

---

## Overview

Geckoforge v0.4.0 consolidates user setup scripts and migrates more functionality to declarative Nix configuration. This improves maintainability, reproducibility, and reduces manual steps.

**Key Changes**:
- ✅ 5 scripts removed (-23%)
- ✅ Firewall configuration consolidated
- ✅ Flatpak installation moved to Home-Manager
- ✅ Theme + Night Color fully declarative
- ✅ Improved orchestration in firstrun-user.sh

---

## What Changed

### 1. Firewall Configuration (Consolidated)

**Before (2 scripts)**:
```bash
./scripts/harden.sh                    # Basic firewall + fail2ban
./scripts/setup-secure-firewall.sh     # Advanced firewall zones
```

**After (1 script)**:
```bash
./scripts/setup-firewall.sh            # Comprehensive firewall + security
```

**Features**:
- Combines basic hardening + advanced zones
- Configures firewalld with custom geckoforge-trusted zone
- Optional fail2ban installation (interactive)
- Automatic security updates configuration
- Single entry point for all firewall config

**Migration**: Replace calls to old scripts with `./scripts/setup-firewall.sh`

---

### 2. Flatpak Installation (Moved to Nix)

**Before**:
```bash
./scripts/install-flatpaks.sh          # Bash script installs Flatpaks
```

**After**:
```nix
# home/home.nix (automatic on Home-Manager activation)
home.activation.installFlatpaks = config.lib.dag.entryAfter ["writeBoundary"] ''
  flatpak install -y --user --noninteractive flathub \
    com.getpostman.Postman \
    io.dbeaver.DBeaverCommunity \
    com.google.AndroidStudio \
    com.obsproject.Studio \
    org.signal.Signal || true
'';
```

**Benefits**:
- Declarative (version controlled in Git)
- Reproducible across machines
- Runs automatically on `home-manager switch`
- No manual script execution needed

**Migration**: 
- Remove calls to `install-flatpaks.sh` from scripts
- Flatpaks auto-install when activating Home-Manager
- Add/remove Flatpaks by editing `home/home.nix`

---

### 3. KDE Theme Configuration (Declarative)

**Before**:
```bash
./scripts/setup-jux-theme.sh           # Interactive theme activation
```

**After**:
```nix
# home/modules/kde-theme.nix
programs.kde.theme = {
  enable = true;
  colorScheme = "JuxTheme";
  plasmaTheme = "JuxPlasma";
  windowDecoration = "__aurorae__svg__JuxDeco";
  kvantumTheme = "NoMansSkyJux";
};
```

**Benefits**:
- Declarative theme configuration
- Reproducible across machines
- No manual kwriteconfig5 commands
- Automatic activation on Home-Manager switch

**Migration**:
- Enable in `home/home.nix` or your config
- Theme applies automatically
- No manual script needed

---

### 4. Night Color Configuration (Declarative)

**Before**:
```bash
./scripts/configure-night-color.sh     # Interactive wizard
```

**After**:
```nix
# home/modules/kde-theme.nix (integrated with theme config)
programs.kde.theme = {
  enable = true;
  nightColor = {
    enable = true;
    mode = "Automatic";              # or "Location", "Times", "Constant"
    dayTemperature = 6500;           # K
    nightTemperature = 3500;         # K
    transitionTime = 1800;           # seconds (30 minutes)
  };
};
```

**Benefits**:
- Declarative configuration
- No interactive prompts
- Version controlled settings
- Reproducible across machines

**Migration**:
- Configure in `home/modules/kde-theme.nix`
- Applies automatically with theme
- Test with `./scripts/test-night-color.sh`

---

## Home-Manager Enhancements

### New Features in kde-theme.nix

```nix
# home/modules/kde-theme.nix now supports:
programs.kde.theme = {
  enable = true;
  
  # Theme components
  colorScheme = "JuxTheme";
  plasmaTheme = "JuxPlasma";
  windowDecoration = "__aurorae__svg__JuxDeco";
  kvantumTheme = "NoMansSkyJux";
  
  # Night Color (NEW!)
  nightColor = {
    enable = true;
    mode = "Automatic";              # Sunrise/sunset detection
    dayTemperature = 6500;
    nightTemperature = 3500;
    transitionTime = 1800;           # 30 min transition
  };
};
```

### Flatpak Activation

```nix
# home/home.nix
home.activation.installFlatpaks = config.lib.dag.entryAfter ["writeBoundary"] ''
  if command -v flatpak >/dev/null 2>&1; then
    echo "Installing Flatpaks..."
    flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo || true
    
    # Add your Flatpaks here
    flatpak install -y --user --noninteractive flathub com.getpostman.Postman || true
    # ... more apps
  fi
'';
```

---

## Migration Steps

### For New Installations

**No action required!** The new structure is used automatically.

1. Build ISO: `./tools/kiwi-build.sh profile`
2. Install geckoforge
3. Run: `./scripts/firstrun-user.sh`
4. Activate Home-Manager (includes theme, Night Color, Flatpaks)

### For Existing Installations

**If you already ran old scripts:**

1. **Update your scripts directory**:
   ```bash
   cd ~/git/geckoforge
   git pull origin main
   ```

2. **Verify new consolidated script**:
   ```bash
   ./scripts/setup-firewall.sh --help
   ```

3. **Enable theme + Night Color in Home-Manager**:
   ```bash
   # Edit ~/git/home/home.nix or your config
   nano ~/git/home/home.nix
   
   # Add or ensure enabled:
   programs.kde.theme = {
     enable = true;
     nightColor.enable = true;
   };
   
   # Apply
   home-manager switch --flake ~/git/home
   ```

4. **Flatpaks already installed?**
   - They continue working
   - Future updates managed via Home-Manager
   - Can remove old `install-flatpaks.sh` calls from custom scripts

---

## Removed Files

**Scripts removed** (functionality preserved elsewhere):

```bash
scripts/harden.sh                      → Merged into setup-firewall.sh
scripts/setup-secure-firewall.sh       → Merged into setup-firewall.sh
scripts/install-flatpaks.sh            → Moved to home/home.nix activation
scripts/setup-jux-theme.sh             → Declarative in home/modules/kde-theme.nix
scripts/configure-night-color.sh       → Declarative in home/modules/kde-theme.nix
```

**No functionality lost** - everything is just organized better!

---

## Remaining Scripts (17 total)

### System Setup (Layer 3)
- `setup-docker.sh` - Docker installation
- `docker-nvidia-install.sh` - NVIDIA Container Toolkit
- `docker-nvidia-verify.sh` - GPU container testing
- `setup-firewall.sh` - **NEW** - Consolidated firewall + security
- `setup-auto-updates.sh` - Automatic security patches
- `setup-secure-dns.sh` - DNS-over-TLS (Quad9)

### Optional Features
- `setup-chrome.sh` - Google Chrome (alternative to Chromium)
- `setup-rclone.sh` - Cloud backup configuration
- `setup-synergy.sh` - Multi-machine KVM
- `setup-winapps.sh` - Windows application integration
- `setup-protonmail-bridge.sh` - ProtonMail Bridge + Thunderbird
- `setup-macos-keyboard.sh` - macOS-style shortcuts
- `setup-shell.sh` - Zsh shell setup

### Testing & Utilities
- `test-macos-keyboard.sh` - Keyboard config verification
- `test-night-color.sh` - Night Color verification
- `check-backups.sh` - Backup health checks
- `make-executable.sh` - Development utility

### Orchestration
- `firstrun-user.sh` - **UPDATED** - Main setup wizard

---

## Benefits of Consolidation

### Developer Experience
- ✅ Fewer scripts to maintain
- ✅ Clear separation of concerns
- ✅ Single source of truth for each feature
- ✅ Easier to understand codebase

### User Experience
- ✅ Fewer manual steps
- ✅ Automatic Flatpak installation
- ✅ Declarative theme configuration
- ✅ Reproducible setup across machines

### Reproducibility
- ✅ Theme settings version-controlled
- ✅ Flatpak list in Git
- ✅ Night Color config tracked
- ✅ Easy rollback with `home-manager generations`

### Maintenance
- ✅ Less bash script duplication
- ✅ Nix handles dependencies
- ✅ Type-safe configuration (Nix)
- ✅ Easier testing and validation

---

## Troubleshooting

### Theme not applying after Home-Manager activation?

```bash
# Force KDE to reload configuration
qdbus org.kde.KWin /KWin reconfigure
kquitapp5 plasmashell && kstart5 plasmashell

# Or log out and back in
```

### Night Color not working?

```bash
# Verify configuration
./scripts/test-night-color.sh

# Check kwinrc
cat ~/.config/kwinrc | grep -A 10 "\[NightColor\]"

# Reconfigure KWin
qdbus org.kde.KWin.ColorCorrect /ColorCorrect reconfigure
```

### Flatpaks not installing?

```bash
# Check Home-Manager activation logs
home-manager switch --flake ~/git/home

# Manually trigger Flatpak installation
flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y --user flathub com.getpostman.Postman
```

### Firewall too restrictive?

```bash
# Check current zones
sudo firewall-cmd --list-all-zones

# Temporarily allow service
sudo firewall-cmd --zone=geckoforge-trusted --add-service=<service>

# Make permanent
sudo firewall-cmd --runtime-to-permanent
```

---

## FAQ

### Q: Can I still use the old scripts?
**A**: No, they've been removed. Use the new consolidated versions or declarative Nix config.

### Q: Will my existing setup break?
**A**: No. If you already ran old scripts, everything continues working. The new structure just provides a better path forward.

### Q: Do I need to rebuild my ISO?
**A**: Recommended but not required. The changes are in Layer 3 (user scripts) and Layer 4 (Home-Manager), so you can update those without rebuilding.

### Q: Can I customize the theme settings?
**A**: Yes! Edit `home/modules/kde-theme.nix` and run `home-manager switch`.

### Q: How do I add more Flatpaks?
**A**: Edit `home/home.nix`, add to the `installFlatpaks` activation script, run `home-manager switch`.

### Q: What if I prefer bash scripts to Nix?
**A**: System-level scripts (Docker, firewall, etc.) remain as bash. User configuration (theme, Flatpaks) moved to Nix for better reproducibility.

---

## Next Steps

1. ✅ Update your local copy: `git pull`
2. ✅ Review changes: `git log --oneline`
3. ✅ Test new consolidated script: `./scripts/setup-firewall.sh`
4. ✅ Enable theme + Night Color in Home-Manager
5. ✅ Run `home-manager switch` to apply
6. ✅ Build new ISO (optional): `./tools/kiwi-build.sh profile`

---

## Version History

- **v0.4.0** (2025-12-15) - Script consolidation, Nix migration
- **v0.3.0** - Docker-only, TeX scheme-medium, multi-language dev
- **v0.2.0** - KDE + GPU containers + docs
- **v0.1.0** - Initial GNOME + NVIDIA profile

---

**Questions?** Open an issue or check [docs/troubleshooting/](docs/troubleshooting/)
