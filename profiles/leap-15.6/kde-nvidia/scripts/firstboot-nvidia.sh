#!/usr/bin/env bash
set -euo pipefail

if ! lspci | grep -qi 'VGA.*NVIDIA'; then
  echo "[geckoforge] No NVIDIA GPU detected; skipping driver install."
  exit 0
fi

echo "[geckoforge] NVIDIA GPU detected; installing driver..."

# Add NVIDIA repo if not present
if [ ! -f /etc/zypp/repos.d/nvidia.repo ]; then
    echo "[nvidia] Adding NVIDIA repository..."
    sudo zypper ar -f https://download.nvidia.com/opensuse/leap/15.6/ nvidia
fi

sudo zypper -n ref || true

# Try signed open driver first (modern GPUs)
if zypper -n se -x nvidia-open-driver-G06-signed | grep -q 'nvidia-open-driver-G06-signed'; then
  echo "[nvidia] Installing signed open driver..."
  sudo zypper -n in --recommends nvidia-open-driver-G06-signed || true
fi

# Verify installation, fallback to proprietary if needed
if ! command -v nvidia-smi >/dev/null 2>&1; then
  echo "[nvidia] Open driver not available, installing proprietary G06..."
  sudo zypper -n in --recommends nvidia-driver-G06 || true
fi

# Add Wayland support (optional, can be enabled later if needed)
# Uncomment if you experience issues with Wayland + NVIDIA
# if ! grep -q "nvidia-drm.modeset=1" /etc/default/grub; then
#     sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="nvidia-drm.modeset=1 /' /etc/default/grub
#     sudo grub2-mkconfig -o /boot/grub2/grub.cfg
# fi

if command -v nvidia-smi >/dev/null 2>&1; then
  echo "[nvidia] Driver installed successfully!"
  nvidia-smi
  echo "[nvidia] Reboot may be required for full functionality."
else
  echo "[nvidia] Driver installation failed. Check logs."
  exit 1
fi
