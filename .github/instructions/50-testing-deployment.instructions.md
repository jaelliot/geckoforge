---
applyTo: ".github/workflows/**,scripts/**,tools/**,**/*test*"
---

---
description: Testing requirements and deployment verification procedures
globs: ["tools/**/*", "scripts/**/*", "docs/testing-plan.md"]
alwaysApply: false
---

## Use when
- Building and testing ISO images
- Verifying system functionality
- Planning deployment to new hardware
- Creating test procedures

## Testing Philosophy

### Test Before Deploy (MANDATORY)
```
Code Changes → ISO Build → VM Test → Laptop Test → Production
     ↓            ↓           ↓           ↓            ↓
   Quick      10-15 min    30 min    1-2 weeks   Stable Use
```

**Never skip VM testing before deploying to physical hardware.**

---

## Three-Phase Testing Strategy

### Phase 1: VM Testing (Required)
**Duration**: 1-2 days  
**Goal**: Catch showstopper bugs in safe environment  
**Tools**: QEMU/KVM or VirtualBox

#### Test VM Configuration:
```bash
# QEMU
qemu-system-x86_64 \
    -enable-kvm \
    -m 8192 \
    -smp 4 \
    -cdrom out/geckoforge-*.iso \
    -drive file=test.qcow2,format=qcow2 \
    -boot d \
    -vga virtio
```

#### VM Test Checklist:
- [ ] ISO boots to live environment
- [ ] Installer launches successfully
- [ ] LUKS encryption works
- [ ] Installation completes
- [ ] System boots to SDDM login
- [ ] First-boot scripts execute
  - [ ] `geckoforge-firstboot.service` completes (NVIDIA will fail in VM - OK)
  - [ ] `geckoforge-nix.service` completes
  - [ ] `/nix` directory exists
- [ ] User can log in to KDE
- [ ] Network connectivity works
- [ ] Can clone geckoforge repo
- [ ] `scripts/firstrun-user.sh` completes
- [ ] Home-Manager installs successfully
- [ ] Docker works (basic `hello-world`)
- [ ] Flatpaks install
- [ ] Can compile TeX document
- [ ] Snapper snapshots exist

---

### Phase 2: Laptop Testing (Recommended)
**Duration**: 1-2 weeks  
**Goal**: Validate NVIDIA, power management, daily workflows  
**Hardware**: NVIDIA laptop or secondary workstation

#### Laptop Test Checklist:
- [ ] NVIDIA driver installs automatically
- [ ] `nvidia-smi` shows GPU
- [ ] KDE Plasma loads with GPU acceleration
- [ ] Multi-monitor setup works
- [ ] External displays detected
- [ ] NVIDIA Container Toolkit installs
- [ ] `docker run --gpus all` works
- [ ] GPU containers access CUDA cores
- [ ] Suspend/resume works
- [ ] Battery indicator accurate
- [ ] Brightness control works
- [ ] Audio works
- [ ] Bluetooth works
- [ ] Wi-Fi stable
- [ ] USB devices recognized
- [ ] Webcam works (if applicable)
- [ ] OBS NVENC available
- [ ] TeX compiles real documents
- [ ] Elixir/Phoenix development works
- [ ] VS Code + extensions functional
- [ ] Docker Compose projects work
- [ ] No kernel panics or freezes
- [ ] System stays responsive under load

#### Daily Driver Test:
Use laptop as primary machine for 1-2 weeks:
- [ ] Web browsing (Chromium)
- [ ] Development work (VS Code, terminal)
- [ ] Meetings (Teams/Zoom)
- [ ] Email and communication
- [ ] File management (Dolphin)
- [ ] Media playback
- [ ] Document creation
- [ ] Container development

---

### Phase 3: Production Deployment
**Duration**: Ongoing  
**Goal**: Replace Windows 10 on main workstation  
**Hardware**: 130GB RAM, AMD Ryzen, NVIDIA GPU

#### Pre-Deployment Backup (MANDATORY):
- [ ] Documents and projects backed up
- [ ] SSH keys backed up
- [ ] Browser profiles exported
- [ ] VS Code settings synced
- [ ] Git repositories pushed
- [ ] Database backups created
- [ ] Important files archived
- [ ] Windows recovery USB created

#### Deployment Checklist:
- [ ] Windows backup verified
- [ ] ISO written to USB
- [ ] Boot from USB successful
- [ ] Installation completed
- [ ] First-boot scripts completed
- [ ] User setup completed
- [ ] Home-Manager configured
- [ ] Docker + NVIDIA functional
- [ ] All development tools work
- [ ] Data restored from backup
- [ ] Workflow validated

---

## ISO Build Testing

### Build Verification:
```bash
# Build ISO
./tools/kiwi-build.sh profiles/leap-15.6/kde-nvidia

# Check build artifacts
ls -lh out/geckoforge-*.iso
# Should be 2.5-3.5 GB

# Verify ISO is bootable
file out/geckoforge-*.iso
# Should show: DOS/MBR boot sector ISO 9660
```

### Common Build Issues:

#### "Package not found"
**Symptom**: KIWI fails during package installation  
**Cause**: Package name incorrect or not in repos  
**Fix**: Verify with `zypper search package-name`

#### "File not found"
**Symptom**: KIWI can't copy overlay files  
**Cause**: Path mismatch in config.kiwi.xml  
**Fix**: Check paths in `<file>` elements

#### "Repository metadata invalid"
**Symptom**: Can't access openSUSE repos  
**Cause**: Network issue or repo URL changed  
**Fix**: Check repo URLs in config.kiwi.xml

---

## Automated Testing Script

### Quick ISO Test:
```bash
# tools/test-iso.sh

#!/usr/bin/env bash
set -euo pipefail

ISO="${1:-$(ls out/*.iso 2>/dev/null | tail -n1)}"

if [ ! -f "$ISO" ]; then
    echo "❌ ISO not found"
    exit 1
fi

echo "🧪 Testing ISO: $(basename "$ISO")"

# Create test disk
DISK="work/test-$(date +%s).qcow2"
qemu-img create -f qcow2 "$DISK" 50G

# Launch VM
qemu-system-x86_64 \
    -enable-kvm \
    -m 8192 \
    -smp 4 \
    -cdrom "$ISO" \
    -drive file="$DISK",format=qcow2,if=virtio \
    -boot d \
    -vga virtio \
    -usb \
    -device usb-tablet

# Cleanup
read -p "Delete test disk? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -f "$DISK"
fi
```

---

## Component Testing

### TeX Live Verification:
```bash
# Test TeX installation
cat > test.tex <<'EOF'
\documentclass{article}
\usepackage{amsmath}
\usepackage{graphicx}
\begin{document}
\title{Test Document}
\author{Your Name}
\maketitle
\section{Introduction}
This is a test of \LaTeX\ with math:
\begin{equation}
E = mc^2
\end{equation}
\end{document}
EOF

pdflatex test.tex
ls test.pdf  # Should exist
```

### Docker + GPU Verification:
```bash
# Test Docker
docker run hello-world

# Test NVIDIA
nvidia-smi

# Test GPU in container
docker run --rm --gpus all nvidia/cuda:12.4.0-base nvidia-smi
```

### Elixir Verification:
```bash
# Test Elixir installation
elixir --version

# Test Phoenix installation
mix archive.install hex phx_new
mix phx.new test_app --no-ecto
cd test_app
mix deps.get
mix phx.server
# Should start on http://localhost:4000
```

---

## Performance Testing

### System Responsiveness:
```bash
# CPU stress test
stress-ng --cpu 8 --timeout 60s --metrics

# Memory test
stress-ng --vm 4 --vm-bytes 80% --timeout 30s

# Disk I/O test
dd if=/dev/zero of=test.img bs=1G count=1 oflag=direct
rm test.img

# GPU test (NVIDIA)
nvidia-smi dmon -s u -c 10
```

### Boot Time:
```bash
# Check boot time
systemd-analyze
# Target: <20 seconds to login

# Identify slow services
systemd-analyze blame
```

---

## Regression Testing

### Checklist After Changes:
- [ ] ISO builds successfully
- [ ] ISO size reasonable (2.5-3.5 GB)
- [ ] VM boots and installs
- [ ] First-boot scripts complete
- [ ] No new systemd failures
- [ ] Home-Manager switches without errors
- [ ] Critical workflows still work:
  - [ ] Docker containers
  - [ ] TeX compilation
  - [ ] GUI apps launch
  - [ ] Network connectivity
  - [ ] GPU access (on hardware)

---

## Acceptance Criteria

### For v0.3.0 Release:
- [ ] ✅ ISO builds without errors
- [ ] ✅ Docker replaces Podman completely
- [ ] ✅ TeX uses scheme-medium
- [ ] ✅ NVIDIA driver auto-installs
- [ ] ✅ Multi-language dev stack works
- [ ] ✅ Elixir/Phoenix functional
- [ ] ✅ Chromium with extensions
- [ ] ✅ All scripts executable
- [ ] ✅ Documentation complete
- [ ] ✅ Tested in VM
- [ ] ✅ Tested on laptop (2 weeks)
- [ ] ⏳ Production deployment

---

## Rollback Procedures

### If VM Test Fails:
1. Review build logs: `less work/*.log`
2. Check config.kiwi.xml for errors
3. Verify package names with `zypper search`
4. Fix issues
5. Rebuild ISO
6. Test again

### If Laptop Test Fails:
1. Boot from USB again
2. Identify failing component
3. Update config or scripts
4. Rebuild ISO
5. Reinstall on laptop
6. Test specific component

### If Production Deployment Fails:
1. Boot Windows recovery USB
2. Restore Windows from backup
3. Extract failed config details
4. Fix issues in dev environment
5. Repeat VM → Laptop → Production

---

## Continuous Verification

### Weekly Checks:
```bash
# Update packages
sudo zypper refresh && sudo zypper update
cd ~/git/home && nix flake update && home-manager switch
flatpak update

# Verify core functionality
docker run hello-world
nvidia-smi
pdflatex --version
elixir --version
```

### Monthly Checks:
```bash
# Rebuild ISO with latest packages
./tools/kiwi-build.sh profiles/leap-15.6/kde-nvidia

# Test in VM
./tools/test-iso.sh out/geckoforge-*.iso

# Update documentation
```

## Upgrade and Migration Procedures

### Philosophy

**Test everything in VM first. Never upgrade production directly.**

---

## openSUSE Leap Version Upgrades

### Preparation (1 week before)

1. **Backup everything**
   ```bash
   # Create Btrfs snapshot
   sudo snapper create --description "Before Leap 15.7 upgrade"
   
   # Backup to external HDD
   ./scripts/backup-to-hdd.sh
   
   # Backup to cloud
   ./scripts/backup-to-cloud.sh
   ```

2. **Check compatibility**
   - Verify NVIDIA driver support for new Leap version
   - Check if any installed packages will be removed
   - Review release notes: https://doc.opensuse.org/release-notes/

3. **Build test ISO with new version**
   ```bash
   # Update KIWI config
   $EDITOR profiles/leap-15.6/kde-nvidia/config.kiwi.xml
   # Change repos to 15.7
   
   # Build test ISO
   ./tools/kiwi-build.sh profiles/leap-15.7/kde-nvidia
   
   # Test in VM for 1 week
   ./tools/test-iso.sh out/geckoforge-leap157-*.iso
   ```

### Upgrade Procedure (In-Place)

**Warning**: In-place upgrades are risky. Clean install recommended.

```bash
# Update current system first
sudo zypper refresh
sudo zypper update

# Add new Leap 15.7 repos
sudo zypper ar http://download.opensuse.org/distribution/leap/15.7/repo/oss/ leap157-oss
sudo zypper ar http://download.opensuse.org/distribution/leap/15.7/repo/non-oss/ leap157-non-oss

# Disable old repos
sudo zypper mr -d leap156-oss
sudo zypper mr -d leap156-non-oss

# Perform distribution upgrade
sudo zypper dup --allow-vendor-change

# Reboot
sudo reboot

# Verify
cat /etc/os-release
# Should show Leap 15.7
```

### Rollback (If Upgrade Fails)

```bash
# Boot from Btrfs snapshot
# At GRUB, select snapshot from before upgrade

# Or manually rollback
sudo snapper rollback <snapshot-number>
sudo reboot
```

### Recommended: Clean Install

Instead of in-place upgrade:
1. Build new ISO for Leap 15.7
2. Test in VM
3. Test on laptop (1-2 weeks)
4. Back up data
5. Clean install on desktop
6. Restore data

---

## Home-Manager (Nix) Updates

### Monthly Updates (Routine)

```bash
cd ~/git/home

# Update flake inputs
nix flake update

# Preview changes
nix flake show

# Apply updates
home-manager switch --flake .

# If issues, rollback
home-manager rollback
```

### Major nixpkgs Version Update (e.g., 24.05 → 24.11)

```bash
cd ~/git/home

# Before: Pin current working version
git add flake.lock
git commit -m "checkpoint: working config on nixpkgs-24.05"

# Update to new release
$EDITOR home/flake.nix
# Change: nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";

# Update and test
nix flake update
home-manager switch --flake . --show-trace

# Check for broken packages
# Fix any issues

# Commit new config
git add flake.nix flake.lock
git commit -m "upgrade: nixpkgs 24.05 → 24.11"
```

### Handling Breaking Changes

```bash
# If home-manager switch fails:

# 1. Check build log
home-manager switch --flake . --show-trace 2>&1 | tee build.log

# 2. Identify broken package
grep "error:" build.log

# 3. Options:
# a) Remove broken package temporarily
$EDITOR home/modules/problematic.nix
# Comment out broken package

# b) Pin package to older version
# In flake.nix:
packages = [
  (import nixpkgs-old { inherit system; }).broken-package
];

# c) Wait for fix in nixpkgs-unstable
# d) Build from source if critical
```

---

## Docker Updates

### Docker Engine Updates

```bash
# Check current version
docker --version

# Update via zypper
sudo zypper refresh
sudo zypper update docker

# Restart daemon
sudo systemctl restart docker

# Verify
docker run hello-world
```

### NVIDIA Container Toolkit Updates

```bash
# Update toolkit
sudo zypper refresh
sudo zypper update nvidia-container-toolkit

# Reconfigure
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# Verify
docker run --rm --gpus all nvidia/cuda:12.4.0-base nvidia-smi
```

---

## NVIDIA Driver Updates

### Minor Updates (Automatic)

```bash
# Via zypper patches
sudo zypper patch

# Reboot if kernel modules updated
sudo reboot
```

### Major Version Updates (e.g., 550 → 555)

```bash
# Backup current driver version
nvidia-smi  # Note version

# Create snapshot
sudo snapper create --description "Before NVIDIA 555"

# Update
sudo zypper refresh
sudo zypper update nvidia-open-driver-G06-signed

# Reboot
sudo reboot

# Verify
nvidia-smi

# If issues, rollback snapshot
```

---

## Migration to New Hardware

### Same Architecture (AMD → AMD, Intel → Intel)

1. **Build fresh ISO** (latest geckoforge)
2. **Install on new hardware**
3. **Restore from backup**:
   ```bash
   # Git configs
   git clone https://github.com/user/geckoforge.git ~/git/geckoforge
   
   # Home-Manager
   cd ~/git/geckoforge/home
   home-manager switch --flake .
   
   # User data
   ./scripts/restore-from-hdd.sh
   # or
   ./scripts/restore-from-cloud.sh
   ```

### Different Architecture (AMD → Intel)

**Changes needed**:
- KIWI profile might need different kernel packages
- NVIDIA driver usually same
- CPU-specific optimizations in Home-Manager

**Process**:
1. Test ISO in VM with emulated target CPU
2. Adjust if needed
3. Build new ISO
4. Follow same migration as above

---

## Breaking Change Checklist

Before making breaking changes:
- [ ] Document current working state in daily summary
- [ ] Create Btrfs snapshot
- [ ] Commit current config to Git
- [ ] Test in VM first
- [ ] Have rollback plan ready
- [ ] Schedule during low-priority time
- [ ] Keep old ISO available

---

## Version Compatibility Matrix

### Tested Configurations

| Component | Version | Status | Notes |
|-----------|---------|--------|-------|
| openSUSE Leap | 15.6 | ✅ Stable | Current production |
| openSUSE Leap | 15.7 | 🚧 Testing | VM only |
| nixpkgs | 24.05 | ✅ Stable | Current production |
| nixpkgs | 24.11 | 🚧 Testing | VM only |
| NVIDIA Driver | 550.x | ✅ Stable | Open kernel modules |
| Docker | 24.x | ✅ Stable | Current |
| Home-Manager | 24.05 | ✅ Stable | Matches nixpkgs |

### Known Incompatibilities

- **Leap 15.6 + nixpkgs unstable**: May have glibc version conflicts
- **Old NVIDIA (< 525) + New Kernels**: Use newer driver
- **Docker < 20 + NVIDIA Toolkit**: Update Docker first

---

## Migration Timeline Example

### openSUSE Leap 15.6 → 15.7

**Month 1**: Preparation
- Week 1: Review release notes
- Week 2: Update KIWI profile for 15.7
- Week 3: Build test ISO
- Week 4: Test in VM

**Month 2**: Testing
- Week 1-2: Daily use in VM
- Week 3: Deploy to laptop
- Week 4: Monitor laptop for issues

**Month 3**: Production
- Week 1: Final backup
- Week 2: Deploy to desktop
- Week 3-4: Monitor production

---

## Emergency Rollback Plan

### If Production System Breaks

1. **Don't panic**
   ```bash
   # Boot from snapshot (at GRUB)
   # Or boot from USB
   ```

2. **Diagnose**
   ```bash
   sudo journalctl -b -p err
   # Identify what broke
   ```

3. **Quick fix or full rollback**
   ```bash
   # Quick fix: Uninstall problematic package
   sudo zypper remove broken-package
   
   # Full rollback: Use Btrfs snapshot
   sudo snapper rollback <snapshot-number>
   sudo reboot
   ```

4. **Document**
   ```bash
   # Write to daily summary what failed
   # Prevent future occurrence
   ```

---

## Bug Reporting Template

```markdown
## Bug Report

**ISO Version**: v0.3.0  
**Build Date**: 2025-01-06  
**Hardware**: [VM / NVIDIA Laptop / AMD Workstation]

### Steps to Reproduce:
1. ...
2. ...

### Expected Behavior:
...

### Actual Behavior:
...

### Logs:
```
# Relevant logs from journalctl or build output
```

### Workaround:
...

### Impact:
[Critical / High / Medium / Low]
```

---

## Success Metrics

### ISO Quality:
- ✅ Builds in <15 minutes
- ✅ Size between 2.5-3.5 GB
- ✅ Boots on VM and hardware
- ✅ No critical errors in logs

### User Experience:
- ✅ Installation <30 minutes
- ✅ First-boot completes automatically
- ✅ User setup <20 minutes
- ✅ System responsive on modern hardware

### Stability:
- ✅ No kernel panics
- ✅ Suspend/resume works
- ✅ Multi-day uptime without issues
- ✅ GPU acceleration stable

---

## Notes

- Always test in VM before hardware
- Document any deviations from test plan
- Keep test results in daily summaries
- Update test checklists as system evolves
- Share findings that could help others