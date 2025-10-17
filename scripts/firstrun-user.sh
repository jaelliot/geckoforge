#!/usr/bin/env bash
set -euo pipefail

cat <<'EOF'
╔════════════════════════════════════════╗
║   Geckoforge First-Run Setup Wizard    ║
╚════════════════════════════════════════╝

This script will set up your workstation by:
1. Installing Docker (with optional Podman cleanup)
2. Configuring NVIDIA GPU for Docker (if applicable)
3. Installing Flatpak applications
4. Setting up Home-Manager (Nix)

Press Enter to continue, or Ctrl+C to exit.
EOF

read -r

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo "=== [1/4] Docker Setup ==="
"$SCRIPT_DIR/setup-docker.sh"

echo ""
if lspci | grep -qi 'VGA.*NVIDIA'; then
    echo "=== [2/4] NVIDIA GPU Detected - Installing Container Toolkit ==="
    "$SCRIPT_DIR/docker-nvidia-install.sh"
    echo ""
    echo "Testing GPU access..."
    "$SCRIPT_DIR/docker-nvidia-verify.sh"
else
    echo "=== [2/4] No NVIDIA GPU detected, skipping ==="
fi

echo ""
echo "=== [3/4] Flatpak Applications ==="
"$SCRIPT_DIR/install-flatpaks.sh"

echo ""
echo "=== [4/4] Home-Manager Setup ==="
if [ ! -d ~/git/home ]; then
    echo "Cloning home configuration..."
    mkdir -p ~/git
    read -p "Enter your dotfiles repo URL (or press Enter to skip): " REPO_URL
    if [ -n "$REPO_URL" ]; then
        git clone "$REPO_URL" ~/git/home
    else
        echo "Skipping - you can clone manually to ~/git/home later"
    fi
fi

if [ -d ~/git/home ] && [ -f ~/git/home/flake.nix ]; then
    echo "Installing Home-Manager..."
    nix run nixpkgs#home-manager -- init --switch --flake ~/git/home
else
    echo "No flake found at ~/git/home - skipping Home-Manager"
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
