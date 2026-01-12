#!/usr/bin/env bash
set -euo pipefail

# geckoforge KIWI ISO Builder
# Builds openSUSE Leap 15.6 KDE live ISO directly on the host

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
PROFILE="${1:-profile}"
PROFILE_PATH="$REPO_ROOT/$PROFILE"
OUT_DIR="$REPO_ROOT/out"

# Ensure we're running on openSUSE
if ! grep -q "openSUSE" /etc/os-release 2>/dev/null; then
    echo "Warning: This script is designed for openSUSE. Proceed with caution."
fi

# Install KIWI if not present
if ! command -v kiwi-ng >/dev/null 2>&1; then
    echo "Installing KIWI NG..."
    sudo zypper install -y python3-kiwi kiwi-systemdeps-iso-media kiwi-systemdeps-bootloaders
fi

# Verify profile exists (KIWI accepts config.xml or *.kiwi)
if [[ ! -f "$PROFILE_PATH/config.xml" ]] && [[ ! -f "$PROFILE_PATH/config.kiwi" ]]; then
    echo "Error: No config.xml found in $PROFILE_PATH"
    echo "Available profiles:"
    find "$REPO_ROOT" -name "config.xml" -printf "  %h\n" 2>/dev/null || echo "  None found"
    exit 1
fi

# Create output directory
mkdir -p "$OUT_DIR"

echo "========================================"
echo "geckoforge ISO Builder"
echo "========================================"
echo "Profile:    $PROFILE_PATH"
echo "Output:     $OUT_DIR"
echo "========================================"

# Build the ISO
echo "Starting KIWI build (this takes 15-20 minutes)..."
sudo kiwi-ng --color-output \
    --type iso \
    system build \
    --description "$PROFILE_PATH" \
    --target-dir "$OUT_DIR"

echo "========================================"
echo "Build complete!"
echo "ISO location: $OUT_DIR"
ls -lh "$OUT_DIR"/*.iso 2>/dev/null || echo "No ISO found - check for errors above"
echo "========================================"
