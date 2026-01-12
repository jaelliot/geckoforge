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
    zypper ar -f https://download.nvidia.com/opensuse/leap/15.6/ nvidia
fi

if ! zypper -n ref; then
  echo "[nvidia] Warning: Repository refresh failed, proceeding anyway..."
fi

# Try signed open driver first (modern GPUs)
if zypper -n se -x nvidia-open-driver-G06-signed | grep -q 'nvidia-open-driver-G06-signed'; then
  echo "[nvidia] Installing signed open driver..."
  if ! zypper -n in --recommends nvidia-open-driver-G06-signed; then
    echo "[nvidia] Warning: Signed open driver installation failed"
  fi
fi

# Verify installation, fallback to proprietary if needed
if ! command -v nvidia-smi >/dev/null 2>&1; then
  echo "[nvidia] Open driver not available, installing proprietary G06..."
  if ! zypper -n in --recommends nvidia-driver-G06; then
    echo "[nvidia] Error: Proprietary driver installation also failed"
    exit 1
  fi
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
  
  # Configure NVIDIA power management for Optimus laptops
  echo "[nvidia] Configuring hybrid graphics power management..."
  cat > /etc/modprobe.d/nvidia-pm.conf << 'EOF'
# NVIDIA Dynamic Power Management for Optimus laptops
options nvidia NVreg_DynamicPowerManagement=0x02
options nvidia-drm modeset=1 fbdev=1
options nvidia NVreg_PreserveVideoMemoryAllocations=1
EOF

  # Enable NVIDIA suspend/resume services (optional, may not exist on all systems)
  for service in nvidia-suspend nvidia-hibernate nvidia-resume; do
    if systemctl list-unit-files | grep -q "${service}.service"; then
      systemctl enable "${service}.service" && echo "[nvidia] Enabled ${service}.service" || echo "[nvidia] Warning: Could not enable ${service}.service"
    fi
  done
  
  echo "[nvidia] Hybrid graphics configuration complete."
  echo "[nvidia] Reboot required for full functionality."
else
  echo "[nvidia] Driver installation failed. Check logs."
  exit 1
fi
