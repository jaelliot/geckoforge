#!/usr/bin/env bash
set -euo pipefail

echo "[flatpak] Ensuring Flathub is enabled..."
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

echo "[flatpak] Installing priority applications..."
APPS=(
    "com.getpostman.Postman"
    "io.dbeaver.DBeaverCommunity"
    "com.google.AndroidStudio"
    "com.obsproject.Studio"
    "org.signal.Signal"
)

for app in "${APPS[@]}"; do
    if flatpak list | grep -q "$app"; then
        echo "  ✓ $app already installed"
    else
        echo "  → Installing $app..."
        flatpak install -y flathub "$app"
    fi
done

echo "[flatpak] Installation complete"
flatpak list | grep -E "$(IFS='|'; echo "${APPS[*]}")"
