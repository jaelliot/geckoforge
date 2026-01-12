# NVIDIA Driver Installation Skill

## Purpose
Correctly install NVIDIA drivers for openSUSE Leap 15.6 on both desktop and laptop (Optimus) systems.

## Target Hardware

| System | GPU | Driver Type |
|--------|-----|-------------|
| Desktop | Discrete NVIDIA | Full driver |
| Laptop (MSI GF65) | NVIDIA + Intel (Optimus) | Hybrid with suse-prime |

## Driver Selection

### Signed vs Unsigned Drivers (Secure Boot)

```bash
# For Secure Boot ENABLED systems (recommended)
nvidia-open-driver-G06-signed-kmp-default

# For Secure Boot DISABLED systems
nvidia-open-driver-G06-kmp-default
```

**Note:** Signed drivers require MOK (Machine Owner Key) enrollment on first boot.

### Package Groups

```bash
# Essential driver packages
nvidia-open-driver-G06-signed-kmp-default  # Kernel module (signed)
nvidia-gl-G06                               # OpenGL libraries
nvidia-compute-utils-G06                    # CUDA utilities

# Optional for compute/AI
nvidia-video-G06                            # Video decode
cuda                                        # CUDA toolkit (large!)

# For Optimus laptops
suse-prime                                  # GPU switching
plasma5-applet-suse-prime                   # KDE applet
```

## KIWI Profile Configuration

### Add NVIDIA Repository (profile/root/etc/zypp/repos.d/nvidia.repo)

```ini
[nvidia]
name=NVIDIA openSUSE Leap 15.6
baseurl=https://download.nvidia.com/opensuse/leap/15.6/
enabled=1
autorefresh=1
gpgcheck=1
gpgkey=https://download.nvidia.com/opensuse/leap/15.6/repodata/repomd.xml.key
type=rpm-md
```

### Add to config.xml (if pre-installing drivers)

```xml
<!-- Repository -->
<repository type="rpm-md">
  <source path="https://download.nvidia.com/opensuse/leap/15.6/"/>
</repository>

<!-- Packages for Optimus laptop -->
<packages type="image">
  <package name="suse-prime"/>
  <package name="plasma5-applet-suse-prime"/>
</packages>

<!-- Note: Actual NVIDIA driver is installed at first boot to detect GPU -->
```

## First-Boot Installation Script

```bash
#!/usr/bin/env bash
# /usr/local/sbin/firstboot-nvidia.sh
set -euo pipefail

LOG="/var/log/geckoforge-nvidia.log"
exec > >(tee -a "$LOG") 2>&1

echo "=== NVIDIA Driver Installation: $(date) ==="

# Detect NVIDIA GPU
if ! lspci | grep -qi 'VGA.*NVIDIA\|3D.*NVIDIA'; then
    echo "No NVIDIA GPU detected, skipping"
    exit 0
fi

echo "NVIDIA GPU detected:"
lspci | grep -i nvidia

# Refresh repositories
zypper --non-interactive refresh

# Detect if Secure Boot is enabled
if mokutil --sb-state 2>/dev/null | grep -qi "enabled"; then
    echo "Secure Boot is ENABLED - using signed drivers"
    DRIVER_PKG="nvidia-open-driver-G06-signed-kmp-default"
else
    echo "Secure Boot is DISABLED - using unsigned drivers"
    DRIVER_PKG="nvidia-open-driver-G06-kmp-default"
fi

# Install driver
echo "Installing: $DRIVER_PKG"
zypper --non-interactive install \
    "$DRIVER_PKG" \
    nvidia-gl-G06 \
    nvidia-compute-utils-G06

# Detect Optimus laptop (Intel + NVIDIA)
if lspci | grep -qi 'VGA.*Intel'; then
    echo "Intel GPU also detected - configuring Optimus hybrid graphics"
    zypper --non-interactive install suse-prime plasma5-applet-suse-prime
    
    # Set Intel as default (power saving)
    prime-select intel || true
    echo "Optimus configured. Use 'prime-select nvidia' for dedicated GPU"
fi

# Rebuild initramfs
echo "Rebuilding initramfs..."
dracut --force

echo "=== NVIDIA Installation Complete ==="
echo "REBOOT REQUIRED for drivers to load"
```

## Secure Boot MOK Enrollment

If using signed drivers with Secure Boot:

1. First boot will show "Perform MOK management"
2. Select "Enroll MOK"
3. Select "Continue"
4. Enter the password: `suse` (default for openSUSE-signed modules)
5. Select "Reboot"

## Desktop vs Laptop Configuration

### Desktop (Discrete NVIDIA Only)

```bash
# No special configuration needed
# NVIDIA is the only GPU, will be used automatically
nvidia-smi  # Verify driver loaded
```

### Laptop (Optimus - Intel + NVIDIA)

```bash
# Switch to NVIDIA (performance)
sudo prime-select nvidia

# Switch to Intel (battery)
sudo prime-select intel

# Check current mode
prime-select get-current

# Use NVIDIA for specific app
prime-run glxinfo | grep "OpenGL renderer"
```

## Docker/Container GPU Access

```bash
# Install NVIDIA Container Toolkit (Layer 3: User Setup)
sudo zypper addrepo https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo
sudo zypper --non-interactive install nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# Test GPU access in container
docker run --rm --gpus all nvidia/cuda:12.4.0-base nvidia-smi
```

## Verification Commands

```bash
# Check driver loaded
lsmod | grep nvidia

# Check GPU status
nvidia-smi

# Check OpenGL
glxinfo | grep "OpenGL renderer"

# Check Vulkan
vulkaninfo | grep "GPU"

# Check CUDA
nvcc --version  # If CUDA toolkit installed
```

## Troubleshooting

### Driver not loading after boot
```bash
# Check for module issues
dmesg | grep -i nvidia

# Check Secure Boot blocking
dmesg | grep -i "module verification failed"

# Solution: Enroll MOK key or disable Secure Boot
```

### Black screen after driver install
```bash
# Boot with nomodeset
# At GRUB: press 'e', add 'nomodeset' to linux line

# Then remove nvidia and use nouveau
sudo zypper remove nvidia-*
```

### Optimus not switching
```bash
# Check bbswitch module
lsmod | grep bbswitch

# Force module load
sudo modprobe bbswitch
```
