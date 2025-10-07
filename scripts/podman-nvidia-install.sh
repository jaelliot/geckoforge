#!/usr/bin/env bash
set -euo pipefail

if ! command -v nvidia-smi >/dev/null 2>&1; then
    echo "[ERROR] NVIDIA driver not found. Run firstboot-nvidia.sh first."
    exit 1
fi

echo "[nvidia-toolkit] Adding NVIDIA container repo..."
DIST="opensuse15.6"
curl -s -L https://nvidia.github.io/libnvidia-container/$DIST/libnvidia-container.repo | \
    sudo tee /etc/zypp/repos.d/nvidia-container-toolkit.repo >/dev/null

echo "[nvidia-toolkit] Installing NVIDIA Container Toolkit..."
sudo zypper refresh
sudo zypper install -y nvidia-container-toolkit

echo "[nvidia-toolkit] Generating CDI spec..."
sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml

echo "[nvidia-toolkit] Available GPU devices:"
nvidia-ctk cdi list

echo "[nvidia-toolkit] Setup complete. Run podman-nvidia-verify.sh to test."
