---
applyTo: "docs/troubleshooting/**/*.md"
---

---
description: Systematic troubleshooting procedures organized by component and layer
globs: ["docs/troubleshooting/**/*.md"]
alwaysApply: false
version: 0.3.0
---

## Use when
- Debugging build, boot, or runtime issues
- System behaving unexpectedly
- Creating troubleshooting documentation
- Diagnosing performance problems

## Troubleshooting Philosophy

**Systematic debugging > Random fixes**

1. Identify the layer (ISO, first-boot, user-setup, Home-Manager)
2. Check logs for that layer
3. Isolate the component
4. Test in minimal environment
5. Document findings in daily summary

---

## Quick Diagnostic Commands

```bash
# System status overview
sudo systemctl status
journalctl -b -p err  # Boot errors

# Layer-specific logs
journalctl -u geckoforge-*  # First-boot services
docker ps -a  # Container status
home-manager generations  # Nix history

# Hardware
nvidia-smi  # GPU status
lspci | grep -i nvidia  # GPU detection
df -h  # Disk space
free -h  # Memory

# Network
ip a  # Network interfaces
ping -c 3 1.1.1.1  # Connectivity
resolvectl status  # DNS configuration
```

---

## Layer 1: ISO Build Issues

### Symptom: ISO Build Fails

#### Check 1: KIWI Configuration
```bash
# Validate XML syntax
xmllint --noout profiles/leap-15.6/kde-nvidia/config.kiwi.xml

# Check for typos in package names
grep '<package>' profiles/leap-15.6/kde-nvidia/config.kiwi.xml
```

**Common causes:**
- Malformed XML (unclosed tags)
- Non-existent package names
- Incorrect repository URLs

#### Check 2: Package Availability
```bash
# Test if packages exist in repos
zypper search package-name

# Check repository connectivity
zypper refresh
```

**Fix:**
```bash
# Correct package name
$EDITOR profiles/leap-15.6/kde-nvidia/config.kiwi.xml

# Rebuild
./tools/kiwi-build.sh profiles/leap-15.6/kde-nvidia
```

### Symptom: ISO Too Large (>4GB)

#### Check: Package List
```bash
# List all packages in config
grep '<package>' profiles/leap-15.6/kde-nvidia/config.kiwi.xml | wc -l

# Identify large packages
zypper info package-name | grep "Installed Size"
```

**Common causes:**
- Too many language packs
- Development packages in Layer 1 (move to Layer 4)
- Full TeX installation (use scheme-medium)

**Fix:**
```bash
# Remove unnecessary packages
$EDITOR profiles/leap-15.6/kde-nvidia/config.kiwi.xml

# Move dev tools to Home-Manager
$EDITOR home/modules/development.nix
```

---

## Layer 2: First-Boot Issues

### Symptom: First-Boot Services Fail

#### Check: Service Status
```bash
# Check first-boot service status
sudo systemctl status geckoforge-firstboot
sudo systemctl status geckoforge-nix

# View service logs
journalctl -u geckoforge-firstboot -f
journalctl -u geckoforge-nix -f
```

#### Check: NVIDIA Driver Installation
```bash
# Check if NVIDIA driver installed
nvidia-smi
lsmod | grep nvidia

# Check driver installation logs
journalctl -u geckoforge-firstboot | grep nvidia
```

**Common causes:**
- Network connectivity issues
- Repository problems
- Hardware not detected

**Fix:**
```bash
# Manual NVIDIA driver install
sudo zypper install -y nvidia-open-driver-G06-signed

# Restart first-boot service
sudo systemctl restart geckoforge-firstboot
```

#### Check: Nix Installation
```bash
# Check if Nix installed
which nix
nix --version

# Check Nix daemon
sudo systemctl status nix-daemon

# Check Nix store permissions
ls -la /nix/
```

**Common causes:**
- Download failure (network)
- Permission issues
- Systemd service conflicts

**Fix:**
```bash
# Manual Nix installation
curl -L https://nixos.org/nix/install | sh -s -- --daemon

# Enable experimental features
echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf
sudo systemctl restart nix-daemon
```

---

## Layer 3: User Setup Issues

### Symptom: Docker Installation Fails

#### Check: Docker Status
```bash
# Check Docker installation
docker --version
sudo systemctl status docker

# Check Docker daemon logs
journalctl -u docker -f

# Test Docker functionality
docker run hello-world
```

**Common causes:**
- Package not available
- Service not started
- User not in docker group

**Fix:**
```bash
# Install Docker
sudo zypper install -y docker docker-compose

# Start Docker service
sudo systemctl enable --now docker

# Add user to docker group
sudo usermod -aG docker "$USER"
newgrp docker  # Apply group changes
```

### Symptom: NVIDIA Container Toolkit Fails

#### Check: NVIDIA Integration
```bash
# Check NVIDIA Container Toolkit
docker run --rm --gpus all nvidia/cuda:12.4.0-base nvidia-smi

# Check toolkit installation
nvidia-ctk --version
```

**Common causes:**
- NVIDIA driver not installed
- Container toolkit not configured
- Wrong Docker syntax (using Podman flags)

**Fix:**
```bash
# Install NVIDIA Container Toolkit
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L "https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list" | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo zypper refresh
sudo zypper install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

### Symptom: Flatpak Installation Fails

#### Check: Flatpak Status
```bash
# Check Flatpak installation
flatpak --version
flatpak remotes

# Check available apps
flatpak search firefox
```

**Common causes:**
- Flathub repository not added
- Network connectivity issues
- Permission problems

**Fix:**
```bash
# Add Flathub repository
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Install application
flatpak install flathub org.mozilla.firefox
```

---

## Layer 4: Home-Manager Issues

### Symptom: Home-Manager Switch Fails

#### Check: Nix Configuration
```bash
# Check Home-Manager status
home-manager --version
home-manager generations

# Check for syntax errors
cd ~/git/geckoforge/home
nix flake check

# Test build without switching
home-manager build
```

**Common causes:**
- Nix syntax errors
- Package not available in nixpkgs
- Conflicting configurations

**Fix:**
```bash
# Check syntax in specific module
nix-instantiate --parse home/modules/development.nix

# Validate package names
nix search nixpkgs package-name

# Switch with more verbose output
home-manager switch -v
```

### Symptom: Package Installation Fails

#### Check: Package Availability
```bash
# Search for package in nixpkgs
nix search nixpkgs firefox
nix search nixpkgs code

# Check package details
nix show-derivation nixpkgs#firefox
```

**Common causes:**
- Package name changed
- Package not available on current platform
- Unfree packages not allowed

**Fix:**
```bash
# Allow unfree packages
echo "{ nixpkgs.config.allowUnfree = true; }" >> ~/.config/nixpkgs/config.nix

# Use correct package name
$EDITOR home/modules/development.nix

# Switch configuration
home-manager switch
```

---

## Hardware-Specific Issues

### NVIDIA GPU Problems

#### Symptom: GPU Not Detected
```bash
# Check GPU hardware
lspci | grep -i nvidia
lshw -c display

# Check driver loading
lsmod | grep nvidia
dmesg | grep -i nvidia
```

**Common causes:**
- Secure Boot enabled (conflicts with unsigned drivers)
- Hardware not supported
- Power management issues

**Fix:**
```bash
# Disable Secure Boot in BIOS
# Install signed drivers
sudo zypper install nvidia-open-driver-G06-signed

# Check power management
sudo nvidia-settings
```

#### Symptom: CUDA Not Working
```bash
# Check CUDA installation
nvcc --version
nvidia-smi

# Test CUDA functionality
cd /usr/local/cuda/samples/1_Utilities/deviceQuery
sudo make
./deviceQuery
```

**Common causes:**
- CUDA toolkit not installed
- Wrong CUDA version for driver
- Environment variables not set

**Fix:**
```bash
# Install CUDA toolkit
sudo zypper install cuda

# Set environment variables
export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
```

### Network Issues

#### Symptom: No Internet Connectivity
```bash
# Check network interfaces
ip a
ip route

# Check DNS resolution
nslookup google.com
resolvectl status

# Check NetworkManager
sudo systemctl status NetworkManager
nmcli device status
```

**Common causes:**
- NetworkManager not running
- DNS configuration issues
- Firewall blocking connections

**Fix:**
```bash
# Restart NetworkManager
sudo systemctl restart NetworkManager

# Reset DNS
sudo systemctl restart systemd-resolved

# Check firewall
sudo iptables -L
```

### Storage Issues

#### Symptom: Disk Full
```bash
# Check disk usage
df -h
du -sh ~/.*  # Hidden directories
du -sh /var/log/

# Check for large files
find / -size +1G -type f 2>/dev/null
```

**Common causes:**
- Docker images taking space
- Log files growing large
- Nix store bloat

**Fix:**
```bash
# Clean Docker
docker system prune -a

# Clean package caches
sudo zypper clean

# Clean Nix store
nix-collect-garbage -d

# Clean logs
sudo journalctl --vacuum-time=7d
```

#### Symptom: Btrfs Issues
```bash
# Check filesystem status
sudo btrfs filesystem show
sudo btrfs filesystem usage /

# Check for errors
sudo btrfs scrub status /
dmesg | grep -i btrfs
```

**Common causes:**
- Filesystem corruption
- Subvolume issues
- Snapshot problems

**Fix:**
```bash
# Check and repair filesystem
sudo btrfs check /dev/sdXY

# Balance filesystem
sudo btrfs balance start /

# Clean old snapshots
sudo snapper list
sudo snapper delete SNAPSHOT_NUMBER
```

---

## Performance Issues

### System Slowdown

#### Check: Resource Usage
```bash
# Check CPU usage
top
htop

# Check memory usage
free -h
ps aux --sort=-%mem | head

# Check I/O usage
iotop
```

**Common causes:**
- Background processes
- Memory leaks
- Disk I/O bottlenecks

**Fix:**
```bash
# Identify resource hogs
systemd-analyze blame
systemd-analyze critical-chain

# Kill problematic processes
sudo kill -9 PID

# Restart problematic services
sudo systemctl restart SERVICE_NAME
```

### GPU Performance Issues

#### Check: GPU Utilization
```bash
# Monitor GPU usage
nvidia-smi -l 1
watch -n 1 nvidia-smi

# Check GPU processes
nvidia-smi pmon

# Check GPU memory
nvidia-smi --query-gpu=memory.used,memory.total --format=csv
```

**Common causes:**
- GPU overheating
- Power limits
- Driver issues

**Fix:**
```bash
# Check temperatures
nvidia-smi --query-gpu=temperature.gpu --format=csv

# Adjust power limit
sudo nvidia-smi -pl 300  # Set power limit to 300W

# Update drivers
sudo zypper update nvidia-open-driver-G06-signed
```

---

## Recovery Procedures

### Boot Issues

#### Symptom: System Won't Boot

**Recovery steps:**
1. Boot from geckoforge ISO in rescue mode
2. Mount encrypted root filesystem
3. Chroot into system
4. Fix configuration
5. Rebuild initramfs
6. Reboot

```bash
# Boot from ISO, then:
sudo cryptsetup open /dev/sdXY system-root
sudo mount /dev/mapper/system-root /mnt
sudo mount /dev/sdX1 /mnt/boot  # EFI partition
sudo chroot /mnt

# Fix issue (e.g., restore config)
# Rebuild initramfs
sudo mkinitrd

# Update bootloader
sudo update-bootloader

# Exit and reboot
exit
sudo umount /mnt/boot
sudo umount /mnt
sudo cryptsetup close system-root
sudo reboot
```

### Configuration Rollback

#### Btrfs Snapshots
```bash
# List snapshots
sudo snapper list

# Boot from older snapshot
# (Select snapshot in GRUB menu)

# Or restore manually
sudo snapper rollback SNAPSHOT_NUMBER
sudo reboot
```

#### Home-Manager Rollback
```bash
# List generations
home-manager generations

# Rollback to previous generation
home-manager switch --rollback

# Or rollback to specific generation
/nix/var/nix/profiles/per-user/$USER/home-manager-XX-link/activate
```

### Data Recovery

#### From Backups
```bash
# Mount backup HDD
sudo cryptsetup open /dev/sdX backup-hdd
sudo mount /dev/mapper/backup-hdd /mnt/backup

# Restore specific files
rsync -av /mnt/backup/latest/critical/git/ ~/git/

# Or restore from cloud
rclone copy remote:geckoforge-backups/latest.tar.gz.age /tmp/
age -d -i ~/.age/private.key /tmp/latest.tar.gz.age | tar -xz -C ~/
```

---

## Prevention Strategies

### Monitoring
- Set up systemd timers for health checks
- Monitor disk space, memory, and GPU usage
- Check logs regularly for warnings
- Verify backups periodically

### Maintenance
- Update system monthly
- Clean package caches weekly
- Test disaster recovery quarterly
- Document all configuration changes

### Documentation
- Record all troubleshooting steps
- Update daily summaries with solutions
- Create runbooks for common issues
- Share solutions with community

## Escalation

### When to Reinstall
If troubleshooting takes longer than rebuilding:
- Multiple layer failures
- Filesystem corruption
- Hardware changes
- Major version upgrades

### When to Get Help
- Hardware-specific issues
- Security concerns
- Performance problems affecting work
- Data recovery situations

If all above checked, reinstall may be faster than debugging.