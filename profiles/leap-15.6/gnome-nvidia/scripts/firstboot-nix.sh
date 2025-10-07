#!/usr/bin/env bash
set -euo pipefail

# 1. Check if Nix already installed
if command -v nix >/dev/null 2>&1; then
    echo "[nix] Already installed, skipping"
    exit 0
fi

# 2. Ensure /nix subvolume exists (if Btrfs)
ROOTDEV=$(findmnt -no SOURCE /)
FSTYPE=$(findmnt -no FSTYPE /)
if [[ "$FSTYPE" == "btrfs" ]]; then
    if ! mountpoint -q /nix; then
        echo "[nix] Creating /nix subvolume..."
        btrfs subvolume create /@nix || true
        mkdir -p /nix
        UUID=$(blkid -s UUID -o value "$ROOTDEV")
        if ! grep -q " /nix " /etc/fstab; then
            echo "UUID=$UUID /nix btrfs subvol=@nix,compress=zstd,noatime 0 0" >> /etc/fstab
        fi
        mount /nix
    fi
fi

# 3. Install Nix (daemon mode)
echo "[nix] Installing Nix (multi-user)..."
sh <(curl -L https://nixos.org/nix/install) --daemon

# 4. Enable flakes
echo "[nix] Enabling flakes..."
mkdir -p /etc/nix
if ! grep -q "experimental-features" /etc/nix/nix.conf 2>/dev/null; then
    echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf
fi

# 5. Restart daemon
systemctl restart nix-daemon || true

echo "[nix] Installation complete. Users should log out/in or source ~/.nix-profile/etc/profile.d/nix.sh"
