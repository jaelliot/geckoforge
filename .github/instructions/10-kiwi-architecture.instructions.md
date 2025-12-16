---
applyTo: profile/**,tools/**,scripts/**,**/*.kiwi.xml
---

---
description: KIWI image builder architecture and 4-layer system design
alwaysApply: false
version: 0.3.0
---

## Use when
- Making changes to KIWI profiles, first-boot scripts, or build tools
- Planning feature additions that span multiple layers
- Deciding where new functionality belongs
- Creating or modifying systemd units for first-boot automation

## Four-Layer Architecture (MANDATORY)

### Layer 1: ISO Layer (KIWI Profile)
**Lives in**: `profile/`  
**Executed**: Once, during ISO build  
**Purpose**: Bake immutable system structure into the ISO

#### Responsibilities:
- Base package selection (kernel, NetworkManager, KDE, Snapper, Btrfs)
- Repository configuration (openSUSE + NVIDIA repos)
- File system structure
- Essential system utilities

#### Files:
- `config.kiwi.xml` - Package lists, repos, file inclusions
- `root/` - Files to overlay onto ISO (`/etc/`, `/usr/local/sbin/`)
- `scripts/` - Scripts copied into ISO for first-boot execution

#### What belongs here:
```xml
<!-- System packages -->
<package>kernel-default</package>
<package>plasma5-desktop</package>
<package>nvidia-open-driver-G06-signed</package>

<!-- File overlays -->
<file name="/etc/zypp/repos.d/nvidia.repo" mode="0644">
  root/etc/zypp/repos.d/nvidia.repo
</file>
```

#### What does NOT belong here:
- ❌ User-specific configuration
- ❌ Docker or container runtimes (requires user groups)
- ❌ Development tools (belong in Home-Manager)
- ❌ GUI applications (use Flatpak via Home-Manager)

---

### Layer 2: First-Boot Layer (Systemd Units)
**Lives in**: `profiles/.../root/etc/systemd/system/`  
**Executed**: Once, on first boot after installation  
**Purpose**: System-level automation that requires root but runs once

#### Responsibilities:
- NVIDIA driver detection and installation
- Nix multi-user daemon installation
- System-level directory structure (e.g., `/nix` Btrfs subvolume)
- One-time system configuration

#### Services:
- `geckoforge-firstboot.service` - NVIDIA driver installer
- `geckoforge-nix.service` - Nix multi-user setup

#### What belongs here:
```bash
# profiles/.../scripts/firstboot-nvidia.sh
#!/usr/bin/env bash
# Detect GPU and install appropriate driver
if lspci | grep -qi 'VGA.*NVIDIA'; then
  sudo zypper -n in --recommends nvidia-open-driver-G06-signed
fi
```

#### What does NOT belong here:
- ❌ User scripts (no `$USER` available)
- ❌ Docker setup (requires user in `docker` group)
- ❌ Home-Manager configuration
- ❌ Anything requiring user interaction

---

### Layer 3: User-Setup Layer (Manual Scripts)
**Lives in**: `scripts/`  
**Executed**: Once per user, manually after first boot  
**Purpose**: User-specific setup requiring group membership or preferences

#### Responsibilities:
- Docker installation and user group configuration
- NVIDIA Container Toolkit setup
- Google Chrome installation (optional)
- Flatpak application installation
- Home-Manager initial setup

#### Main script:
- `scripts/firstrun-user.sh` - Orchestration wizard

#### Supporting scripts:
- `scripts/setup-docker.sh` - Docker + Podman removal
- `scripts/docker-nvidia-install.sh` - NVIDIA Container Toolkit
- `scripts/setup-chrome.sh` - Chrome repo + install
- `scripts/install-flatpaks.sh` - Flatpak apps batch install

#### What belongs here:
```bash
# scripts/setup-docker.sh
sudo zypper install -y docker docker-compose
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"  # Requires user context
```

#### What does NOT belong here:
- ❌ System packages (use Layer 1)
- ❌ First-boot automation (use Layer 2)
- ❌ User environment config (use Layer 4)

---

### Layer 4: Home-Manager Layer (Nix)
**Lives in**: `home/`  
**Executed**: Per-user, repeatable via `home-manager switch`  
**Purpose**: Reproducible user environment and application management

#### Responsibilities:
- User packages (CLI tools, development environments)
- Application configuration (Firefox, Git, shell)
- Desktop environment customization
- Programming language toolchains

#### Files:
- `home/flake.nix` - Nix flake definition
- `home/home.nix` - User configuration entrypoint
- `home/modules/` - Modular configurations by domain

#### What belongs here:
```nix
# home/modules/development.nix
{
  home.packages = with pkgs; [
    # Development tools
    git lazygit gnumake cmake
    
    # Languages
    go python3 nodejs_20
    
    # TeX (MUST be scheme-medium)
    texlive.combined.scheme-medium
  ];
}
```

#### What does NOT belong here:
- ❌ System packages (use Layer 1)
- ❌ Docker installation (use Layer 3)
- ❌ Root-level configuration (use Layers 1-2)

---

## Layer Interaction Rules

### Valid Interactions:
```
Layer 1 (ISO) → Layer 2 (First-boot)
  ✅ KIWI copies first-boot scripts into ISO

Layer 2 (First-boot) → Layer 3 (User-setup)
  ✅ First-boot installs Nix, user runs scripts later

Layer 3 (User-setup) → Layer 4 (Home-Manager)
  ✅ User scripts help set up Home-Manager

Layer 4 (Home-Manager) → Layer 3 (via activation)
  ✅ Home-Manager can run Flatpak installs
```

### Invalid Interactions:
```
Layer 1 → Layer 3
  ❌ KIWI cannot run user-specific scripts

Layer 2 → Layer 4
  ❌ First-boot cannot configure user environment

Layer 3 → Layer 1
  ❌ User scripts cannot modify ISO contents

Layer 4 → Layer 2
  ❌ Home-Manager cannot change system structure
```

---

## KIWI Build Process

### Development Workflow:
```bash
# 1. Make changes to profile
cd geckoforge/
$EDITOR profile/config.kiwi.xml

# 2. Build ISO
./tools/kiwi-build.sh profile

# 3. ISO appears in out/
ls out/*.iso

# 4. Test in VM
./tools/test-iso.sh out/geckoforge-*.iso
```

### Build Container:
- Uses official openSUSE KIWI container
- Mounts profile as read-only
- Outputs ISO to `out/`, work files to `work/`
- No persistent state between builds

---

## Profile Organization

### Required Structure:
```
profile/
├── config.kiwi.xml              # Main KIWI configuration
├── root/                        # File overlays
│   ├── etc/
│   │   ├── snapper/configs/root
│   │   ├── systemd/system/
│   │   │   ├── geckoforge-firstboot.service
│   │   │   ├── geckoforge-nix.service
│   │   │   └── multi-user.target.wants/
│   │   ├── zypp/repos.d/
│   │   │   └── nvidia.repo
│   │   └── firefox/policies/
│   │       └── policies.json
│   └── usr/local/sbin/          # First-boot scripts
│       ├── firstboot-nvidia.sh
│       └── firstboot-nix.sh
└── scripts/                     # Source scripts (copied by KIWI)
    ├── firstboot-nvidia.sh
    └── firstboot-nix.sh
```

---

## Common Mistakes and Fixes

### ❌ Mistake: Adding Docker to KIWI config
**Problem**: Docker requires user in `docker` group, which doesn't exist at ISO build time.  
**Fix**: Move to Layer 3 (user-setup scripts).

### ❌ Mistake: Running user scripts in first-boot systemd
**Problem**: First-boot runs as root before any users log in.  
**Fix**: Move to Layer 3 (manual user execution).

### ❌ Mistake: Installing Nix packages in KIWI
**Problem**: Nix packages are user-specific and change frequently.  
**Fix**: Move to Layer 4 (Home-Manager).

### ❌ Mistake: Configuring Home-Manager in first-boot
**Problem**: Home-Manager requires user context and `.config/` directory.  
**Fix**: Move to Layer 3 (user runs `home-manager switch`).

---

## Laptop-Specific Patterns (Desktop Prioritized)

**Note**: geckoforge is primarily designed for desktop workstations (130GB RAM, AMD Ryzen, NVIDIA GPU). Laptop support is secondary but validated on two NVIDIA laptops.

### Power Management (Layer 1 + 3)

#### TLP Installation (Layer 1: KIWI)

```xml
<!-- profile/config.kiwi.xml -->
<packages type="image">
  <package>tlp</package>
  <package>tlp-rdw</package>  <!-- For NetworkManager integration -->
</packages>
```

#### TLP Configuration (Layer 3: User Setup)

```bash
# scripts/setup-laptop-power.sh
#!/usr/bin/env bash
set -euo pipefail

echo "[laptop] Configuring power management..."

# Enable TLP
sudo systemctl enable tlp
sudo systemctl start tlp

# TLP configuration for NVIDIA laptops
sudo tee /etc/tlp.conf <<EOF
# Battery thresholds (if supported)
START_CHARGE_THRESH_BAT0=40
STOP_CHARGE_THRESH_BAT0=80

# CPU scaling governor
CPU_SCALING_GOVERNOR_ON_AC=performance
CPU_SCALING_GOVERNOR_ON_BAT=powersave

# NVIDIA runtime power management
RUNTIME_PM_ON_BAT=auto

# USB autosuspend
USB_AUTOSUSPEND=1

# Wireless power saving
WIFI_PWR_ON_AC=off
WIFI_PWR_ON_BAT=on
EOF

echo "[laptop] Power management configured"
echo "Check status: sudo tlp-stat"
```

### Battery Optimization

#### Best Practices
- **80% charge limit** (if hardware supports) - extends battery life
- **powersave governor on battery** - reduces CPU power
- **Performance mode when plugged in** - full desktop experience

#### Monitor Battery Health
```bash
# Check battery status
tlp-stat -b

# Check power consumption
sudo powertop
```

### Suspend/Resume (Layer 2: First-Boot)

#### NVIDIA Suspend Hook (if needed)

```bash
# profile/root/etc/systemd/system/nvidia-suspend.service
[Unit]
Description=NVIDIA GPU suspend helper
Before=sleep.target

[Service]
Type=oneshot
ExecStart=/usr/bin/nvidia-sleep.sh suspend

[Install]
WantedBy=sleep.target
```

```bash
# profile/root/usr/bin/nvidia-sleep.sh
#!/bin/bash
case "$1" in
    suspend|hibernate)
        # Save GPU state
        /usr/bin/nvidia-smi -pm 0
        ;;
    resume|thaw)
        # Restore GPU state
        /usr/bin/nvidia-smi -pm 1
        ;;
esac
```

### Hybrid Graphics (Intel + NVIDIA)

#### PRIME Offload (if laptop has Intel iGPU)

```bash
# Use Intel for desktop, NVIDIA for specific apps
# No configuration needed - works by default on openSUSE

# Run app with NVIDIA:
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia app-name

# Or create desktop entry:
cat > ~/.local/share/applications/app-nvidia.desktop <<EOF
[Desktop Entry]
Name=App (NVIDIA)
Exec=env __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia app-name
EOF
```

### Laptop Hardware Quirks

#### Touchpad Configuration
```bash
# KDE Plasma settings
kwriteconfig5 --file touchpadxlibinputrc --group "Alps Touchpad" --key "TapToClick" true
```

#### Brightness Control
```bash
# Usually works out of box
# If not, add kernel parameter:
# acpi_backlight=vendor
```

#### Function Keys
```bash
# Fn keys should work by default
# If swapped, toggle in BIOS
```

### Testing Checklist (Laptop-Specific)

After deploying to laptop:
- [ ] Battery indicator shows correct percentage
- [ ] Suspend works (close lid)
- [ ] Resume works (open lid)
- [ ] Brightness controls work (Fn+F5/F6)
- [ ] Volume controls work (Fn+F7/F8)
- [ ] WiFi toggles work
- [ ] Touchpad works
- [ ] External monitor detection
- [ ] HDMI/DisplayPort works
- [ ] USB ports work
- [ ] Webcam works (if needed)
- [ ] Microphone works
- [ ] NVIDIA GPU accessible (`nvidia-smi`)
- [ ] Battery lasts reasonable time (>3 hours light use)

### Known Limitations (Laptop)

- **Desktop prioritized**: Some optimizations favor desktop (e.g., no aggressive power saving by default)
- **NVIDIA battery drain**: Discrete GPU uses more power than iGPU
- **Testing**: Laptop configurations tested less frequently than desktop

### When to Use Laptop Build

Use the same ISO for both desktop and laptop. Laptop-specific configuration happens at Layer 3 (user setup):

```bash
# Detect if laptop
if [ -d /sys/class/power_supply/BAT* ]; then
    echo "Laptop detected"
    ./scripts/setup-laptop-power.sh
else
    echo "Desktop detected - skipping laptop config"
fi
```

## Verification Checklist

Before committing changes:
- [ ] Layer 1 (ISO) only contains system packages and repos
- [ ] Layer 2 (first-boot) only contains root-level, one-time automation
- [ ] Layer 3 (user-setup) handles group membership and user choices
- [ ] Layer 4 (Home-Manager) manages reproducible user environment
- [ ] No Docker in KIWI config or first-boot scripts
- [ ] No user scripts in systemd units
- [ ] No system packages in Home-Manager
- [ ] ISO builds successfully: `./tools/kiwi-build.sh`

---

## Examples

### Adding a New System Package
```xml
<!-- profiles/.../config.kiwi.xml -->
<packages type="image">
  <package>your-package-here</package>
</packages>
```

### Adding First-Boot Automation
```bash
# 1. Create script: profiles/.../scripts/firstboot-something.sh
#!/usr/bin/env bash
# System-level setup that runs once

# 2. Create systemd unit: profiles/.../root/etc/systemd/system/
[Unit]
Description=Your first-boot task
ConditionFirstBoot=yes

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/firstboot-something.sh

# 3. Enable unit: profiles/.../root/etc/systemd/system/multi-user.target.wants/
ln -s ../your-service.service
```

### Adding User Script
```bash
# scripts/your-script.sh
#!/usr/bin/env bash
# User-specific setup
```

### Adding Home-Manager Config
```nix
# home/modules/your-module.nix
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    your-package
  ];
}

# home/home.nix
imports = [
  ./modules/your-module.nix
];
```

---

## Notes

- This is a **KIWI image builder**, not a direct system installer
- The 4-layer architecture is **non-negotiable** and prevents common pitfalls
- openSUSE Leap 15.6 is the **target OS** - do not suggest Ubuntu/Debian/Arch patterns
- Respect the **stability promise** - no cutting-edge or experimental packages in Layer 1