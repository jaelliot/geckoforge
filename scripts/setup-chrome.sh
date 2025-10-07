#!/usr/bin/env bash
set -euo pipefail

if command -v google-chrome >/dev/null 2>&1; then
    echo "[chrome] Already installed"
    google-chrome --version
    exit 0
fi

echo "[chrome] Adding Google Chrome repository..."
sudo rpm --import https://dl.google.com/linux/linux_signing_key.pub
sudo zypper ar -f https://dl.google.com/linux/chrome/rpm/stable/x86_64 google-chrome

echo "[chrome] Installing Google Chrome..."
sudo zypper refresh
sudo zypper install -y google-chrome-stable

echo "[chrome] Installation complete"
google-chrome --version
