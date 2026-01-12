# MSI GF65 Thin 10UE Laptop Optimization Guide
**Date**: December 15, 2025  
**Hardware**: MSI GF65 Thin 10UE (MS-16W2)  
**Specs**: Intel i7-10750H, RTX 3060 Laptop, 64GB RAM, 1TB HDD + SSD

---

## Hardware Specifications

### Your Laptop (MSI GF65 Thin 10UE)
- **CPU**: Intel Core i7-10750H (6-core, 12-thread, 2.6-5.0GHz)
- **GPU**: NVIDIA GeForce RTX 3060 Laptop (6GB GDDR6, Max-Q 80W TDP)
- **RAM**: 64GB DDR4-2933 (upgraded from stock 8GB/16GB)
- **Storage**:
  - Primary: 512GB NVMe SSD (likely)
  - Secondary: 1TB HDD (user-added)
- **Display**: 15.6" FHD (1920x1080) 144Hz IPS
- **Chipset**: Intel HM470
- **WiFi**: Intel Wi-Fi 6 AX201
- **Ethernet**: Realtek RTL8111/8168/8411
- **Audio**: Nahimic 3
- **Ports**: 3x USB-A 3.2, 1x USB-C 3.2, HDMI 2.0, Mini DisplayPort 1.2, SD card reader
- **Battery**: 51Wh (3-cell)
- **Weight**: 1.86 kg

### Key Differences from Workstation
| Feature | Workstation | MSI GF65 Laptop | Impact |
|---------|-------------|-----------------|--------|
| CPU | AMD Ryzen (desktop) | Intel i7-10750H | Different power mgmt |
| GPU | Desktop RTX | RTX 3060 Max-Q (80W) | Lower TDP, thermal limits |
| RAM | 130GB | 64GB | Still excellent |
| Cooling | Tower | Laptop (2 fans) | Thermal throttling possible |
| Power | Unlimited | Battery + 180W adapter | Need power management |
| Hybrid GPU | No | Intel iGPU + NVIDIA | PRIME offload needed |

---

## Optimizations Needed

### 1. **Intel CPU Optimizations** (vs AMD Ryzen)
- ✅ Different power governors (intel_pstate)
- ✅ Enable Turbo Boost management
- ✅ Thermal monitoring (i7-10750H runs hot)
- ✅ P-state/C-state configuration

### 2. **Laptop GPU (RTX 3060 Max-Q)**
- ✅ Lower power limit (80W vs 180W+ desktop)
- ✅ Thermal throttling awareness
- ✅ PRIME offload configuration (Intel iGPU + NVIDIA)
- ✅ Dynamic power management
- ✅ Suspend/resume handling

### 3. **Dual Storage Configuration**
- ✅ SSD for OS + applications
- ✅ HDD for data/media
- ✅ Proper mount options (noatime for SSD)
- ✅ Steam library on HDD strategy

### 4. **Power Management**
- ✅ TLP configuration (already in ISO)
- ✅ Battery charge thresholds (40-80%)
- ✅ CPU governors (performance on AC, powersave on battery)
- ✅ USB autosuspend
- ✅ WiFi power saving

### 5. **Thermal Management**
- ✅ Monitor temperatures (CPU >80°C, GPU >75°C = throttling)
- ✅ Fan curve adjustments (if supported)
- ✅ Undervolting (Intel i7-10750H benefits from -100mV)
- ✅ Repaste thermal compound (if temps high)

### 6. **Display Optimization**
- ✅ 144Hz refresh rate configuration
- ✅ External monitor support (HDMI 2.0, Mini DP 1.2)
- ✅ Night Color/blue light filtering
- ✅ Power saving on battery

---

## Already Configured (in geckoforge)

✅ **TLP power management** - Package included in ISO (profile/config.xml)  
✅ **NVIDIA Dynamic PM** - Configured in firstboot-nvidia.sh  
✅ **Hybrid graphics** - PRIME offload ready  
✅ **Suspend/resume** - NVIDIA services enabled  
✅ **modprobe options** - NVreg_DynamicPowerManagement=0x02

---

## Optimizations Included (Declarative!)

### ✅ Home-Manager Module: `home/modules/power.nix`

**All laptop power management is now declarative!** No bash scripts needed.

Enable in your `home.nix`:

```nix
programs.power = {
  enable = true;
  
  # Optional customization (these are defaults):
  cpu = {
    governorAC = "performance";
    governorBattery = "powersave";
    turboAC = true;
    turboBattery = false;           # Save battery
    maxFreqBattery = 3200000;       # 3.2GHz max on battery
  };
  
  battery = {
    enableThresholds = true;
    startThreshold = 40;
    stopThreshold = 80;              # Extends battery life
  };
  
  storage.devices = [ "nvme0n1" "sda" ];  # SSD + HDD
  
  thermal.monitoring = true;         # Installs check-thermals
};
```

After configuration:

```bash
home-manager switch --flake ~/git/home

# Copy TLP config to system (one-time):
sudo cp ~/.config/tlp/tlp.conf /etc/tlp.conf
sudo systemctl enable --now tlp
```

**Tools provided**:
- `check-thermals` - Monitor CPU/GPU temps
- `power-status` - TLP and battery status
- Shell aliases: `temps`, `battery`, `power`

```bash
#!/usr/bin/env bash
# Laptop-specific power optimizations for MSI GF65 Thin 10UE
set -euo pipefail

echo "[laptop] Configuring power management for MSI GF65..."

# Check if laptop
if [ ! -d /sys/class/power_supply/BAT* ]; then
    echo "[laptop] No battery detected, skipping laptop config"
    exit 0
fi

# TLP configuration for Intel i7-10750H + RTX 3060
sudo tee /etc/tlp.conf <<'EOF'
# CPU (Intel i7-10750H specific)
CPU_SCALING_GOVERNOR_ON_AC=performance
CPU_SCALING_GOVERNOR_ON_BAT=powersave
CPU_ENERGY_PERF_POLICY_ON_AC=performance
CPU_ENERGY_PERF_POLICY_ON_BAT=balance_power
CPU_BOOST_ON_AC=1
CPU_BOOST_ON_BAT=0

# CPU min/max frequencies (i7-10750H: 2.6GHz base, 5.0GHz turbo)
CPU_SCALING_MIN_FREQ_ON_AC=1200000   # 1.2GHz min on AC
CPU_SCALING_MAX_FREQ_ON_AC=5000000   # 5.0GHz max on AC (turbo)
CPU_SCALING_MIN_FREQ_ON_BAT=800000   # 800MHz min on battery
CPU_SCALING_MAX_FREQ_ON_BAT=3200000  # 3.2GHz max on battery (save power)

# Battery thresholds (extends battery life)
START_CHARGE_THRESH_BAT0=40
STOP_CHARGE_THRESH_BAT0=80

# Platform profile (Intel)
PLATFORM_PROFILE_ON_AC=performance
PLATFORM_PROFILE_ON_BAT=low-power

# Hard disk power management (1TB HDD)
DISK_DEVICES="nvme0n1 sda"
DISK_APM_LEVEL_ON_AC="254 254"       # Max performance
DISK_APM_LEVEL_ON_BAT="128 128"      # Power saving

# AHCI runtime power management
AHCI_RUNTIME_PM_ON_AC=on
AHCI_RUNTIME_PM_ON_BAT=auto

# PCI Express power management
PCIE_ASPM_ON_AC=default
PCIE_ASPM_ON_BAT=powersupersave

# Graphics (NVIDIA RTX 3060 + Intel iGPU)
RUNTIME_PM_ON_AC=on
RUNTIME_PM_ON_BAT=auto

# USB autosuspend
USB_AUTOSUSPEND=1
USB_DENYLIST="046d:c52b"  # Example: exclude specific devices if issues

# Wireless power saving (Intel AX201)
WIFI_PWR_ON_AC=off
WIFI_PWR_ON_BAT=on

# Audio power saving
SOUND_POWER_SAVE_ON_AC=0
SOUND_POWER_SAVE_ON_BAT=1

# Bluetooth
DEVICES_TO_DISABLE_ON_STARTUP=""
DEVICES_TO_ENABLE_ON_STARTUP="bluetooth wifi"
EOF

# Enable and start TLP
sudo systemctl enable tlp
sudo systemctl start tlp

# Intel GPU power management
if [ -d /sys/module/i915 ]; then
    echo "[laptop] Configuring Intel GPU power saving..."
    sudo tee /etc/modprobe.d/i915.conf <<'EOF'
# Intel iGPU power management
options i915 enable_guc=3 enable_fbc=1 enable_psr=1
EOF
fi

# Display power management
sudo tee /etc/X11/xorg.conf.d/20-intel.conf <<'EOF'
Section "Device"
    Identifier "Intel Graphics"
    Driver "modesetting"
    Option "TearFree" "true"
    Option "DRI" "3"
EndSection
EOF

echo "[laptop] Power management configured"
echo "[laptop] Reboot for all changes to take effect"
echo "[laptop] Check status: sudo tlp-stat"
```

### 2. Thermal Monitoring Script

Create `scripts/monitor-thermals.sh`:

```bash
#!/usr/bin/env bash
# Monitor CPU/GPU temperatures and throttling

echo "=== MSI GF65 Thermal Monitor ==="
echo ""

# CPU temps (i7-10750H)
if command -v sensors >/dev/null; then
    echo "CPU Temperatures:"
    sensors | grep -i "core"
    echo ""
fi

# GPU temps (RTX 3060)
if command -v nvidia-smi >/dev/null; then
    echo "GPU Status:"
    nvidia-smi --query-gpu=temperature.gpu,power.draw,clocks.current.graphics,clocks.current.memory,utilization.gpu --format=csv,noheader
    echo ""
fi

# Check thermal throttling
if [ -f /sys/devices/system/cpu/cpu0/thermal_throttle/package_throttle_count ]; then
    THROTTLE_COUNT=$(cat /sys/devices/system/cpu/cpu0/thermal_throttle/package_throttle_count)
    echo "CPU Thermal Throttle Events: $THROTTLE_COUNT"
    
    if [ "$THROTTLE_COUNT" -gt 0 ]; then
        echo "⚠ WARNING: CPU is thermally throttling!"
        echo "  Consider: repaste, clean fans, undervolt"
    fi
fi

# Power consumption
if command -v tlp-stat >/dev/null; then
    echo ""
    echo "Power Consumption:"
    tlp-stat -b | grep -E "power_now|energy_now"
fi
```

### 3. Storage Configuration Script

Create `scripts/setup-dual-storage.sh`:

```bash
#!/usr/bin/env bash
# Optimize dual storage (SSD + HDD) configuration
set -euo pipefail

echo "[storage] Configuring dual storage setup..."

# Identify drives
SSD=$(lsblk -d -o NAME,ROTA | awk '$2=="0" {print $1; exit}')  # First non-rotating
HDD=$(lsblk -d -o NAME,ROTA | awk '$2=="1" {print $1; exit}')  # First rotating

echo "[storage] SSD detected: $SSD"
echo "[storage] HDD detected: $HDD"

# Create data directory on HDD (if not exists)
if [ -n "$HDD" ]; then
    DATA_DIR="/mnt/data"
    sudo mkdir -p "$DATA_DIR"
    
    # Add to /etc/fstab if not present
    if ! grep -q "$DATA_DIR" /etc/fstab; then
        echo "[storage] Adding HDD mount to /etc/fstab..."
        HDD_UUID=$(blkid -s UUID -o value "/dev/${HDD}1" || echo "")
        
        if [ -n "$HDD_UUID" ]; then
            echo "UUID=$HDD_UUID $DATA_DIR ext4 defaults,noatime 0 2" | sudo tee -a /etc/fstab
            sudo mount -a
        fi
    fi
    
    # Create user directories on HDD
    mkdir -p "$DATA_DIR/$USER"/{Downloads,Videos,Music,Documents,Steam}
    
    # Symlink to home
    ln -sf "$DATA_DIR/$USER/Downloads" ~/Downloads-HDD
    ln -sf "$DATA_DIR/$USER/Steam" ~/.steam-library-hdd
    
    echo "[storage] HDD configured at $DATA_DIR"
    echo "[storage] Steam library: $DATA_DIR/$USER/Steam"
fi

# SSD optimizations
if [ -n "$SSD" ]; then
    echo "[storage] Enabling SSD optimizations..."
    
    # Enable TRIM
    sudo systemctl enable fstrim.timer
    sudo systemctl start fstrim.timer
    
    # Check if noatime is set
    if ! mount | grep "/dev/$SSD" | grep -q "noatime"; then
        echo "[storage] Consider adding 'noatime' to SSD mount in /etc/fstab"
    fi
fi

echo "[storage] Storage configuration complete"
```

### 4. Gaming Optimizations for Laptop

Update `home/modules/gaming.nix` to add laptop-specific settings:

```nix
# Laptop-specific gaming options
laptop = {
  enable = mkOption {
    type = types.bool;
    default = false;
    description = "Enable laptop-specific optimizations (battery, thermals)";
  };
  
  maxTDP = mkOption {
    type = types.int;
    default = 80;  # RTX 3060 Max-Q TDP
    description = "Maximum GPU TDP (watts)";
  };
  
  thermalLimit = mkOption {
    type = types.int;
    default = 75;  # Conservative for laptop
    description = "GPU temperature limit (°C)";
  };
};
```

Add laptop-specific gamemode config:

```nix
# In gamemode.ini generation
${optionalString cfg.laptop.enable ''
# Laptop-specific settings
gpu_optimisations=conservative

[custom]
start=${pkgs.writeShellScript "gamemode-start-laptop" ''
  # Laptop mode: moderate optimizations
  
  # Set GPU power limit (RTX 3060 Max-Q)
  nvidia-smi -pl ${toString cfg.laptop.maxTDP} || true
  
  # Set temp limit
  nvidia-smi -lgc 0,$(nvidia-smi --query-gpu=clocks.max.graphics --format=csv,noheader,nounits | head -1) || true
  
  # CPU turbo (if on AC power)
  if [ -f /sys/class/power_supply/AC/online ] && [ "$(cat /sys/class/power_supply/AC/online)" = "1" ]; then
    echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo || true
  fi
  
  echo "Gamemode: Laptop optimizations applied"
''}
''}
```

---

## VM Testing Strategy

### VM Configuration for Testing

Before deploying to the actual laptop, test in a VM with similar specs:

```bash
# QEMU/KVM VM configuration
virt-install \
  --name geckoforge-test \
  --ram 8192 \
  --vcpus 4 \
  --cpu host \
  --disk path=/var/lib/libvirt/images/geckoforge.qcow2,size=50 \
  --cdrom /path/to/geckoforge-leap156-kde.iso \
  --os-variant opensuse-leap15.6 \
  --network network=default \
  --graphics spice \
  --virt-type kvm \
  --boot uefi
```

### VM Test Checklist

- [ ] ISO boots in UEFI mode
- [ ] KDE Plasma loads
- [ ] Installation completes (<30 min)
- [ ] First-boot services run successfully
- [ ] Network configured (DHCP)
- [ ] zypper update works
- [ ] Home-Manager installs
- [ ] Steam installs (gaming module)
- [ ] No critical errors in logs

### Laptop Test Checklist (Post-VM)

**Hardware Detection**:
- [ ] NVIDIA RTX 3060 detected (`lspci | grep VGA`)
- [ ] nvidia-smi shows GPU
- [ ] Intel iGPU detected
- [ ] Battery detected (`/sys/class/power_supply/BAT0`)
- [ ] 64GB RAM recognized
- [ ] Both drives detected (SSD + HDD)
- [ ] WiFi works (Intel AX201)
- [ ] Ethernet works
- [ ] SD card reader works

**Display**:
- [ ] 144Hz refresh rate active
- [ ] Brightness controls work (Fn+F4/F5)
- [ ] External HDMI works
- [ ] Mini DisplayPort works
- [ ] Night Color activates

**Power Management**:
- [ ] TLP active (`systemctl status tlp`)
- [ ] Battery percentage accurate
- [ ] AC adapter detection works
- [ ] Suspend works (close lid)
- [ ] Resume works (open lid)
- [ ] GPU accessible after resume
- [ ] Battery lasts >3 hours (light use)

**Performance**:
- [ ] CPU turbo works on AC
- [ ] CPU throttles on battery (expected)
- [ ] GPU accessible via PRIME offload
- [ ] No thermal throttling at idle
- [ ] Fans respond to load

**Gaming**:
- [ ] Steam installs
- [ ] Drone simulator runs smoothly
- [ ] Gamemode activates
- [ ] MangoHud shows FPS
- [ ] GPU utilization correct
- [ ] No overheating during gaming
- [ ] Controller works

---

## Deployment Strategy

### Phase 1: VM Testing (1-2 days)
1. Build ISO with laptop optimizations
2. Test in VM
3. Verify all scripts work
4. Check for errors in logs

### Phase 2: Laptop Installation (Day 1)
1. **Backup current system** (if dual-boot)
2. Boot from USB
3. Install geckoforge
4. Let first-boot complete
5. Run laptop setup scripts:
   ```bash
   ./scripts/setup-laptop-power.sh
   ./scripts/setup-dual-storage.sh
   ```

### Phase 3: Configuration (Day 1-2)
1. Configure Home-Manager
2. Enable gaming module
3. Install drone simulators
4. Test all hardware
5. Monitor thermals

### Phase 4: Daily Driver (1-2 weeks)
1. Use for development
2. Monitor battery life
3. Check for thermal issues
4. Test suspend/resume
5. Verify gaming performance

### Phase 5: Production (After validation)
1. Deploy to workstation (if laptop successful)
2. Document any issues
3. Update configurations

---

## Expected Performance

### CPU (i7-10750H)
- **On AC**: Full turbo (4.5-5.0GHz on 1-2 cores)
- **On Battery**: Base clock (2.6GHz) or lower
- **Thermal limit**: ~80°C before throttling

### GPU (RTX 3060 Laptop, 80W)
- **Gaming FPS**: 60-100 FPS (1080p high settings)
- **Drone sims**: 100+ FPS (well-optimized)
- **Thermal limit**: ~75°C (conservative)
- **CUDA cores**: 3840 (vs 3584 desktop RTX 3060)

### Battery Life
- **Light use**: 4-5 hours (web, documents)
- **Development**: 3-4 hours (coding, Docker)
- **Gaming**: 1.5-2 hours (on battery, not recommended)

### Storage
- **SSD**: OS boot <20 seconds
- **HDD**: Steam library, media storage

---

## Troubleshooting

### High Temperatures

```bash
# Monitor temps
watch -n 1 'sensors; nvidia-smi'

# Check throttling
./scripts/monitor-thermals.sh

# Reduce GPU power (if overheating)
sudo nvidia-smi -pl 60  # Reduce to 60W
```

### Poor Battery Life

```bash
# Check power consumption
sudo tlp-stat -b
sudo powertop

# Identify power hogs
sudo powertop --auto-tune
```

### Suspend/Resume Issues

```bash
# Check logs
journalctl -b -u nvidia-suspend
journalctl -b | grep -i suspend

# Test suspend
systemctl suspend
```

### PRIME Offload Not Working

```bash
# Check available GPUs
glxinfo | grep "OpenGL renderer"

# Test NVIDIA offload
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia glxinfo | grep "OpenGL renderer"

# Should show "NVIDIA GeForce RTX 3060"
```

---

## References

- [MSI GF65 Specifications](https://www.msi.com/Laptop/GF65-Thin-10UX)
- [Intel i7-10750H Specs](https://ark.intel.com/content/www/us/en/ark/products/201837/intel-core-i7-10750h-processor-12m-cache-up-to-5-00-ghz.html)
- [RTX 3060 Laptop Specs](https://www.nvidia.com/en-us/geforce/graphics-cards/30-series/rtx-3060-3060ti/)
- [TLP Documentation](https://linrunner.de/tlp/)
- [PRIME Offload](https://wiki.archlinux.org/title/PRIME)

---

**Ready for testing!** 🚀

Start with VM testing, then deploy to laptop. Monitor thermals carefully during first gaming session.
