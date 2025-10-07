#!/usr/bin/env bash
set -euo pipefail

if loginctl show-user "$USER" | grep -q "Linger=yes"; then
    echo "[linger] Already enabled for $USER"
else
    echo "[linger] Enabling for $USER..."
    loginctl enable-linger "$USER"
fi
