#!/usr/bin/env bash
set -euo pipefail

cat <<'EOF'
╔════════════════════════════════════════╗
║   Geckoforge First-Run Setup Wizard    ║
╚════════════════════════════════════════╝

This script will set up your workstation by:
1. Installing Docker
2. Configuring NVIDIA GPU for Docker (if applicable)
3. Setting up Home-Manager (Nix)
   • Includes Flatpak applications
   • KDE theme configuration
   • Development tools

Note: Flatpak installation is now handled by Home-Manager.
      Theme configuration is managed declaratively in Nix.

Press Enter to continue, or Ctrl+C to exit.
EOF

read -r

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function: Dual storage setup (SSD + HDD)
setup_dual_storage() {
    echo ""
    echo "=== Dual Storage Configuration ==="
    
    SSD_DEV=$(lsblk -d -n -o NAME,ROTA | awk '$2=="0" {print $1; exit}')
    HDD_DEV=$(lsblk -d -n -o ROTA | grep -q "^1$" && lsblk -d -n -o NAME,ROTA | awk '$2=="1" {print $1; exit}')
    
    echo "SSD: $SSD_DEV (OS, applications)"
    echo "HDD: $HDD_DEV (data, media, Steam)"
    echo ""
    
    if [ -z "$HDD_DEV" ]; then
        echo "No HDD detected, skipping"
        return
    fi
    
    # Enable TRIM for SSD
    sudo systemctl enable fstrim.timer
    sudo systemctl start fstrim.timer
    echo "✓ TRIM enabled for SSD"
    
    # Find HDD partition
    HDD_PART=$(lsblk -n -o NAME "/dev/$HDD_DEV" | grep -v "^${HDD_DEV}$" | head -1)
    
    if [ -z "$HDD_PART" ]; then
        echo "HDD has no partitions - format it first"
        echo "  sudo fdisk /dev/$HDD_DEV"
        echo "  sudo mkfs.ext4 /dev/${HDD_DEV}1"
        return
    fi
    
    # Create mount point and configure
    DATA_DIR="/mnt/data"
    sudo mkdir -p "$DATA_DIR"
    
    HDD_UUID=$(sudo blkid -s UUID -o value "/dev/$HDD_PART" 2>/dev/null)
    
    if [ -z "$HDD_UUID" ]; then
        echo "HDD partition needs formatting"
        echo "  sudo mkfs.ext4 /dev/$HDD_PART"
        return
    fi
    
    # Add to fstab if not present
    if ! grep -q "$HDD_UUID" /etc/fstab 2>/dev/null; then
        sudo cp /etc/fstab /etc/fstab.backup.$(date +%Y%m%d)
        echo "UUID=$HDD_UUID $DATA_DIR ext4 defaults,noatime 0 2" | sudo tee -a /etc/fstab
        sudo mount -a
        echo "✓ HDD configured in /etc/fstab"
    fi
    
    # Create user directories
    USER_DATA="$DATA_DIR/$USER"
    sudo mkdir -p "$USER_DATA"/{Downloads,Videos,Music,Documents,Projects,Steam,VirtualMachines}
    sudo chown -R "$USER:$USER" "$USER_DATA"
    
    # Create symlinks
    ln -sf "$USER_DATA/Downloads" ~/Downloads-HDD 2>/dev/null || true
    ln -sf "$USER_DATA/Steam" ~/.steam-library-hdd 2>/dev/null || true
    ln -sf "$USER_DATA/VirtualMachines" ~/VMs 2>/dev/null || true
    
    echo "✓ Dual storage configured"
    echo "  HDD mount: $DATA_DIR"
    echo "  Steam library: $USER_DATA/Steam"
    echo "  Add in Steam → Settings → Storage → (+) Add Drive"
}

echo ""
echo "=== [1/3] Docker Setup ==="
if ! "$SCRIPT_DIR/setup-docker.sh"; then
    echo ""
    echo "ERROR: Docker setup failed. Cannot proceed with NVIDIA Container Toolkit."
    echo "Fix Docker installation and re-run this script."
    exit 1
fi

echo ""
if lspci | grep -qi 'VGA.*NVIDIA'; then
    echo "=== [2/3] NVIDIA GPU Detected - Installing Container Toolkit ==="
    if ! "$SCRIPT_DIR/docker-nvidia-install.sh"; then
        echo ""
        echo "WARNING: NVIDIA Container Toolkit setup failed."
        echo "Docker works, but GPU containers will not function."
        echo "Run ./docker-nvidia-install.sh manually to fix."
    fi
    echo ""
    echo "Testing GPU access..."
    if ! "$SCRIPT_DIR/docker-nvidia-verify.sh"; then
        echo ""
        echo "WARNING: GPU verification failed."
        echo "Review errors above and run ./docker-nvidia-verify.sh manually."
    fi
else
    echo "=== [2/3] No NVIDIA GPU detected, skipping ==="
fi

echo ""
echo "=== [3/3] Home-Manager Setup ==="

# Prompt for Home-Manager flake location
read -p "Home-Manager flake path [~/git/home]: " HM_PATH
HM_PATH=${HM_PATH:-~/git/home}

if [ ! -d "$HM_PATH" ]; then
    echo "Cloning home configuration..."
    mkdir -p "$(dirname "$HM_PATH")"
    read -p "Enter your dotfiles repo URL (or press Enter to skip): " REPO_URL
    if [ -n "$REPO_URL" ]; then
        git clone "$REPO_URL" "$HM_PATH"
    else
        echo "Skipping - you can clone manually to $HM_PATH later"
    fi
fi

if [ -d "$HM_PATH" ] && [ -f "$HM_PATH/flake.nix" ]; then
    echo "Installing Home-Manager from $HM_PATH..."
    nix run nixpkgs#home-manager -- init --switch --flake "$HM_PATH"
else
    echo "No flake found at $HM_PATH - skipping Home-Manager"
fi

echo ""
echo "=== Night Color Blue Light Filter (Optional) ==="
cat <<'EONC'
KDE's Night Color feature reduces blue light in the evening for less eye strain.
The configurator enables it with the geckoforge defaults (6500K day / 4500K night)
and can also collect your location or custom schedule.

EONC

read -r -p "Run the Night Color setup wizard now? [Y/n]: " NIGHT_COLOR_CHOICE
if [[ -z "${NIGHT_COLOR_CHOICE}" || "${NIGHT_COLOR_CHOICE}" =~ ^[Yy]$ ]]; then
    if "$SCRIPT_DIR/configure-night-color.sh"; then
        echo "Night Color configuration complete."
    else
        echo "Night Color setup encountered an issue; run scripts/configure-night-color.sh later to retry." >&2
    fi
else
    echo "Skipping Night Color setup. Launch scripts/configure-night-color.sh later to customize manually."
fi

echo ""
echo "=== Laptop-Specific Optimizations (Optional) ==="
if [ -d /sys/class/power_supply/BAT* ]; then
    cat <<'EOLAP'
Laptop detected! Power management is now handled by Home-Manager.
Enable in your home.nix:

  programs.power.enable = true;

After enabling, run: home-manager switch --flake ~/git/home

Would you like to configure dual storage (SSD + HDD) now?
EOLAP

    # Detect HDD
    if lsblk -d -n -o ROTA | grep -q "^1$"; then
        read -r -p "HDD detected! Configure dual storage optimization? [Y/n]: " STORAGE_CHOICE
        if [[ -z "${STORAGE_CHOICE}" || "${STORAGE_CHOICE}" =~ ^[Yy]$ ]]; then
            setup_dual_storage
        fi
    else
        echo "Single SSD detected - no dual storage configuration needed"
    fi
else
    echo "Desktop detected - skipping laptop-specific configuration"
fi

echo ""
echo "=== Windows Application Support (Optional) ==="
cat <<'EOWIN'
WinApps enables seamless Windows application integration (Office, Adobe, game engines).
Requires ~20-30GB disk space and 4-8GB RAM for Windows VM.
Windows ISO downloaded automatically from Microsoft servers.

EOWIN

read -r -p "Install WinApps for Windows application support? [y/N]: " WINAPPS_CHOICE
if [[ "${WINAPPS_CHOICE}" =~ ^[Yy]$ ]]; then
    if "$SCRIPT_DIR/setup-winapps.sh"; then
        echo "WinApps installation complete. Run 'winapps-setup' to create Windows VM."
    else
        echo "WinApps setup encountered an issue; run scripts/setup-winapps.sh later to retry." >&2
    fi
else
    echo "Skipping WinApps. Install later with scripts/setup-winapps.sh if needed."
fi

cat <<'EOF'

╔════════════════════════════════════════╗
║         Setup Complete! 🎉             ║
╚════════════════════════════════════════╝

Next steps:
1. Log out and back in (to activate Nix profile)
2. Test GPU: docker run --rm --gpus all nvidia/cuda:12.4.0-base nvidia-smi
3. Customize your Home-Manager config at ~/git/home
4. Run 'home-manager switch --flake ~/git/home' to apply changes
5. Optional: ./scripts/setup-macos-keyboard.sh for macOS-style shortcuts

EOF
