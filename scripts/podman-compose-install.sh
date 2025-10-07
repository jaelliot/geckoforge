#!/usr/bin/env bash
set -euo pipefail

if command -v podman-compose >/dev/null 2>&1; then
    echo "[compose] Already installed"
    podman-compose version
    exit 0
fi

if zypper search -x podman-compose | grep -q podman-compose; then
    sudo zypper install -y podman-compose
else
    echo "[compose] Not in repos, installing via pip..."
    pip3 install --user podman-compose
fi

echo "[compose] Installed. Test with: podman-compose version"
