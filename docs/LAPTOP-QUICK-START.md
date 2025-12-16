# MSI GF65 Thin 10UE - Quick Reference Card

## Hardware Specs
- **Model**: MSI GF65 Thin 10UE (MS-16W2)
- **CPU**: Intel i7-10750H (6C/12T, 2.6-5.0GHz)
- **GPU**: NVIDIA RTX 3060 Laptop (6GB, 80W TDP)
- **RAM**: 64GB DDR4-2933
- **Storage**: NVMe SSD + 1TB HDD
- **Display**: 15.6" FHD 144Hz
- **Battery**: 51Wh

---

## Deployment Checklist

### Phase 1: VM Testing (1-2 days)
```bash
# Build ISO
./tools/kiwi-build.sh profile

# Test in VM
./tools/test-iso.sh out/geckoforge-*.iso
```

- [ ] ISO boots
- [ ] Installation completes
- [ ] First-boot services run
- [ ] No errors in `journalctl -b`

### Phase 2: Laptop Installation
```bash
# 1. Write ISO to USB
sudo dd if=geckoforge-*.iso of=/dev/sdX bs=4M status=progress

# 2. Boot from USB, install

# 3. After first boot, run:
./scripts/firstrun-user.sh
# (Will auto-detect laptop and offer power optimizations)
```

### Phase 3: Laptop-Specific Setup
```bash
# Power management is now in Home-Manager!
# Enable in your home.nix:
programs.power.enable = true;

# Then apply:
home-manager switch --flake ~/git/home

# Dual storage configuration (if HDD present)
# This is offered during firstrun-user.sh
```

---

## Key Differences from Workstation

| Feature | Workstation | MSI GF65 Laptop |
|---------|-------------|-----------------|
| CPU | AMD Ryzen | Intel i7-10750H |
| GPU TDP | 180W+ | 80W (Max-Q) |
| RAM | 130GB | 64GB |
| Cooling | Tower | 2x laptop fans |
| Power | AC only | Battery + 180W adapter |
| Hybrid GPU | No | Intel iGPU + NVIDIA |

---

## Quick Commands

### Thermal Monitoring
```bash
check-thermals          # CPU/GPU temps + throttling
sensors                 # Detailed CPU sensors
nvidia-smi              # GPU status
```

### Power Management
```bash
sudo tlp-stat           # TLP status
sudo tlp-stat -b        # Battery info
check-storage           # Disk usage
sudo tlp fullcharge BAT0  # Charge to 100% once
```

### Battery Optimization
- **Default**: 40-80% charging (extends life)
- **Expected life**: 4-5 hours light use, 3-4 hours coding
- **Gaming**: 1.5-2 hours (not recommended on battery)

### Storage
```bash
check-storage           # Disk usage + health
df -h                   # Quick disk usage
lsblk                   # Show all drives

# HDD locations (if configured)
~/Downloads-HDD         # Large downloads
~/.steam-library-hdd    # Steam games
~/VMs                   # Virtual machines
```

### Gaming Performance
```bash
steam                   # Optimized launcher
steam-fps               # With MangoHud overlay
gamemode-status         # Check if gamemode active
```

---

## Performance Expectations

### CPU (i7-10750H)
- **On AC**: 4.5-5.0GHz turbo (1-2 cores)
- **On Battery**: 2.6GHz base or lower
- **Thermal limit**: 80°C

### GPU (RTX 3060 Laptop)
- **Gaming FPS**: 60-100 FPS @1080p high
- **Drone sims**: 100+ FPS
- **CUDA cores**: 3840
- **Thermal limit**: 75°C

### Battery
- **Light use**: 4-5 hours
- **Development**: 3-4 hours
- **Gaming**: 1.5-2 hours

---

## Troubleshooting

### CPU Overheating (>85°C)
```bash
check-thermals          # Monitor temps
sudo tlp bat            # Force battery profile (lower TDP)

# Long-term: repaste thermal compound
```

### Poor Battery Life
```bash
sudo tlp-stat -b        # Check optimization
sudo powertop           # Find power hogs
sudo powertop --auto-tune  # Enable all optimizations
```

### GPU Not Accessible
```bash
nvidia-smi              # Should show RTX 3060
lspci | grep VGA        # Check detection

# PRIME offload test
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia glxinfo | grep "renderer"
```

### Suspend/Resume Issues
```bash
# Check logs
journalctl -b | grep -i suspend
systemctl status nvidia-suspend

# Test
systemctl suspend
```

---

## Gaming on Laptop

### Recommended Settings
1. **Enable gamemode**: Automatic CPU/GPU boost
2. **Monitor temps**: Use MangoHud (`Shift+F12`)
3. **144Hz display**: Enable in game settings
4. **Power profile**: AC power for best FPS
5. **Temp limit**: Keep GPU <75°C

### Steam Library Setup
```bash
# Add HDD library in Steam
# Settings → Storage → (+) Add Drive
# Select: /mnt/data/$USER/Steam

# Install large games on HDD to save SSD space
```

---

## Documentation

- **Full guide**: [docs/laptop-msi-gf65-optimization.md](docs/laptop-msi-gf65-optimization.md)
- **Gaming setup**: [docs/gaming-steam-setup.md](docs/gaming-steam-setup.md)
- **Testing plan**: [docs/testing-plan.md](docs/testing-plan.md)

---

## Support Scripts

All scripts in `scripts/`:
- `setup-laptop-power.sh` - Power management
- `setup-dual-storage.sh` - SSD + HDD config
- `setup-docker.sh` - Docker installation
- `docker-nvidia-install.sh` - NVIDIA container toolkit
- `docker-nvidia-verify.sh` - GPU verification
- `firstrun-user.sh` - Main setup wizard

---

## After Installation

1. ✅ Reboot (power management takes effect)
2. ✅ Run `check-thermals` during first use
3. ✅ Monitor battery life over 1-2 days
4. ✅ Test suspend/resume (close/open lid)
5. ✅ Install Steam and test drone simulator
6. ✅ Check `sudo tlp-stat` for optimization status

---

**Ready to deploy!** 🚀

Test in VM first, then install on laptop. Monitor thermals during first gaming session.
