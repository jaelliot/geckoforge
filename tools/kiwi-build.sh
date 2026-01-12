#!/usr/bin/env bash
set -euo pipefail
PROFILE="${1:-profile}"

mkdir -p out work

# Use Docker only (project standard)
if ! command -v docker >/dev/null 2>&1; then
    echo "Error: Docker is required but not found"
    echo "Install Docker: sudo zypper install docker"
    exit 1
fi

RUNCMD=docker
# Using openSUSE Tumbleweed with KIWI NG installed
IMG="opensuse/tumbleweed:latest"

echo "Pulling base image and installing KIWI NG..."
$RUNCMD pull "$IMG"
$RUNCMD run --rm -it \
  -v "$PWD/$PROFILE":/build/desc:z \
  -v "$PWD/out":/build/out:z \
  -v "$PWD/work":/build/work:z \
  --privileged \
  "$IMG" \
  bash -c "zypper --non-interactive install python3-kiwi && kiwi-ng --color-output --type iso system build --description /build/desc --target-dir /build/out"
