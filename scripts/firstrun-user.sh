#!/usr/bin/env bash
set -euo pipefail

cat <<'EOF'
╔════════════════════════════════════════╗
║   Geckoforge First-Run Setup Wizard    ║
╚════════════════════════════════════════╝

This script will set up your workstation by:
1. Installing Podman (rootless containers)
2. Configuring NVIDIA GPU for containers
3. Installing Google Chrome
4. Installing Flatpak applications
5. Setting up Home-Manager (Nix)

Press Enter to continue, or Ctrl+C to exit.
EOF

read -r

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo "=== [1/5] Podman Setup ==="
"$SCRIPT_DIR/setup-podman.sh"
"$SCRIPT_DIR/podman-loginctl-linger.sh"
"$SCRIPT_DIR/podman-compose-install.sh"

echo ""
if lspci | grep -qi 'VGA.*NVIDIA'; then
    echo "=== [2/5] NVIDIA GPU Detected - Installing Container Toolkit ==="
    "$SCRIPT_DIR/podman-nvidia-install.sh"
    echo ""
    echo "Testing GPU access..."
    "$SCRIPT_DIR/podman-nvidia-verify.sh"
else
    echo "=== [2/5] No NVIDIA GPU detected, skipping ==="
fi

echo ""
echo "=== [3/5] Google Chrome ==="
read -p "Install Google Chrome? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    "$SCRIPT_DIR/setup-chrome.sh"
fi

echo ""
echo "=== [4/5] Flatpak Applications ==="
"$SCRIPT_DIR/install-flatpaks.sh"

echo ""
echo "=== [5/5] Home-Manager Setup ==="
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

cat <<'EOF'

╔════════════════════════════════════════╗
║         Setup Complete! 🎉             ║
╚════════════════════════════════════════╝

Next steps:
1. Log out and back in (to activate Nix profile)
2. Test GPU: podman run --rm --device nvidia.com/gpu=all nvidia/cuda:12.4.0-base nvidia-smi
3. Customize your Home-Manager config at ~/git/home
4. Run 'home-manager switch --flake ~/git/home' to apply changes

EOF
