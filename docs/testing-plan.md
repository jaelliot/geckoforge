# Geckoforge Testing Plan

## Testing Phases

### Phase 1: VM Testing
**Duration**: 1 week  
**Goal**: Catch showstopper bugs in safe environment

### Phase 2: NVIDIA Laptop Testing
**Duration**: 2-3 weeks  
**Goal**: Validate GPU, power management, daily workflows

### Phase 3: Windows 10 Replacement
**Duration**: Ongoing  
**Goal**: Full production use on main workstation

---

## Phase 1: VM Testing Checklist

### Prerequisites
- [ ] VirtualBox or QEMU installed
- [ ] 20GB disk space
- [ ] Built ISO in `out/`

### VM Configuration
```
CPU: 4 cores
RAM: 8GB
Disk: 50GB (dynamic)
Network: NAT
Display: 3D acceleration enabled
```

### Test Cases

#### TC-001: ISO Build
- [ ] `./tools/kiwi-build.sh` completes
- [ ] ISO exists in `out/`
- [ ] ISO size < 3GB

#### TC-002: Installation
- [ ] ISO boots in VM
- [ ] KDE Live environment loads
- [ ] Installer launches
- [ ] LUKS encryption works
- [ ] Installation completes
- [ ] Boots to SDDM login

#### TC-003: First-Boot Scripts
- [ ] `geckoforge-firstboot.service` runs
- [ ] `geckoforge-nix.service` runs
- [ ] Nix installed: `nix --version`
- [ ] `/nix` directory exists
- [ ] Logs show no errors

#### TC-004: User Setup
- [ ] Clone repo succeeds
- [ ] `firstrun-user.sh` completes
- [ ] Podman: `podman run hello-world`
- [ ] Chrome installs (if opted in)
- [ ] Flatpaks: `flatpak list` shows apps
- [ ] Home-Manager: `home-manager generations`

#### TC-005: Package Management
- [ ] zypper: `sudo zypper ref`
- [ ] Nix: `nix run nixpkgs#hello`
- [ ] Flatpak: `flatpak run org.signal.Signal`
- [ ] Home-Manager: `home-manager switch`

#### TC-006: Snapper Rollback
- [ ] Snapshots exist: `sudo snapper list`
- [ ] Create snapshot: `sudo snapper create -d "test"`
- [ ] Make change to filesystem
- [ ] Rollback: `sudo snapper rollback <id>`
- [ ] Verify change reverted

#### TC-007: Nix Rollback
- [ ] List: `home-manager generations`
- [ ] Edit `~/git/home/home.nix`
- [ ] Apply: `home-manager switch`
- [ ] Rollback: `home-manager rollback`
- [ ] Verify change reverted

#### TC-008: Updates
- [ ] Check: `sudo zypper lu`
- [ ] Apply: `sudo zypper patch`
- [ ] Snapper created snapshots
- [ ] Nix: `cd ~/git/home && nix flake update`
- [ ] Flatpak: `flatpak update`

#### TC-009: Documentation
- [ ] All docs render in browser
- [ ] Commands are copy-pasteable
- [ ] No broken links

---

## Phase 2: NVIDIA Laptop Testing

### Prerequisites
- [ ] Laptop with NVIDIA GPU
- [ ] Backup of current OS
- [ ] USB with geckoforge ISO
- [ ] External drive for backups

### Test Cases

#### TC-101: NVIDIA Driver
- [ ] First-boot detects GPU
- [ ] Driver installs automatically
- [ ] `nvidia-smi` shows GPU
- [ ] KDE session loads
- [ ] Multi-monitor works
- [ ] External displays work

#### TC-102: GPU Containers
- [ ] Toolkit installed
- [ ] CDI spec: `/etc/cdi/nvidia.yaml`
- [ ] Devices: `nvidia-ctk cdi list`
- [ ] Container test: `podman run --device nvidia.com/gpu=all nvidia/cuda:12.4.0-base nvidia-smi`
- [ ] Rootless works

#### TC-103: OBS NVENC
- [ ] OBS installed via Flatpak
- [ ] NVENC in Settings → Output
- [ ] Test recording
- [ ] CPU usage low (<10%)
- [ ] Quality acceptable

#### TC-104: Power Management
- [ ] Suspend: `systemctl suspend`
- [ ] Resume works
- [ ] GPU functional after resume
- [ ] Battery indicator accurate
- [ ] Brightness control works

#### TC-105: Secure Boot
- [ ] Enabled in BIOS
- [ ] System boots
- [ ] MOK enrolled (if prompted)
- [ ] `mokutil --sb-state` = enabled

---

## Phase 3: Windows 10 Replacement

### Pre-Migration Backup
- [ ] Documents
- [ ] Pictures/Videos
- [ ] Firefox/Chrome profile
- [ ] SSH keys (`~/.ssh/`)
- [ ] VS Code settings
- [ ] Git repositories
- [ ] Passwords (KeePass export)

### Migration Strategy

**Option A: Dual Boot** (Recommended)
1. [ ] Shrink Windows partition
2. [ ] Install geckoforge on free space
3. [ ] Test for 2 weeks
4. [ ] Wipe Windows if stable

**Option B: Direct Replace**
1. [ ] Full Windows backup
2. [ ] Create recovery USB
3. [ ] Install geckoforge
4. [ ] Restore data

### Post-Migration Checklist
- [ ] Web browsing works
- [ ] Email accessible
- [ ] Code editing (VS Code, vim)
- [ ] Git operations
- [ ] SSH connections
- [ ] Video calls (Zoom/Teams)
- [ ] Development environment
- [ ] GPU workloads
- [ ] OBS recording/streaming
- [ ] Gaming (Steam/Proton)

---

## Acceptance Criteria (v0.2.0)

Before Windows replacement:

- [ ] ✅ ISO builds successfully
- [ ] ✅ First-boot scripts work
- [ ] ✅ NVIDIA driver installs
- [ ] ✅ Nix + Home-Manager functional
- [ ] ✅ Podman rootless works
- [ ] ✅ GPU containers work
- [ ] ✅ Snapper rollbacks work
- [ ] ✅ Nix rollbacks work
- [ ] ✅ Docs complete and accurate

### Tested On
- [ ] VM (QEMU/VirtualBox)
- [ ] NVIDIA laptop
- [ ] Bare metal workstation

---

## Bug Reporting Template

```markdown
**Title**: [Component] Brief description

**Environment**:
- ISO: v0.2.0
- Hardware: [Model or VM]
- GPU: [NVIDIA model or None]

**Steps to Reproduce**:
1. ...
2. ...

**Expected**: ...
**Actual**: ...

**Logs**:
- journalctl -u geckoforge-firstboot.service
- journalctl -u geckoforge-nix.service

**Workaround**: ...
```

---

## Monthly Maintenance (After v0.2.0)

1. Rebuild ISO with latest patches
2. Quick VM test
3. Update production:
   ```bash
   sudo zypper patch
   cd ~/git/home && nix flake update && home-manager switch
   flatpak update
   ```
4. Verify critical workflows
5. Create backup

---

## Emergency Rollback

### OS Broken (Snapper)
1. GRUB → "Bootable snapshots"
2. Boot last working snapshot
3. `sudo snapper rollback`

### Apps Broken (Nix)
```bash
home-manager rollback
```

### Both Broken
1. Boot from USB
2. Mount encrypted disk
3. Restore from backup
4. Reinstall (last resort)
