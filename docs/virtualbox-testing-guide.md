# VirtualBox Testing Guide for geckoforge

**Date**: December 15, 2025  
**Purpose**: Automated testing with shared folders and snapshots

---

## Quick Setup: VirtualBox + Shared Folder

### 1. Create VM in VirtualBox

```bash
# VM Settings
Name: geckoforge-test
Type: Linux
Version: openSUSE (64-bit)
RAM: 8GB (8192 MB)
CPUs: 4 cores
Disk: 50GB VDI (dynamically allocated)

# Important
✓ Enable EFI (System → Motherboard)
✓ Video Memory: 128MB
✓ Attach openSUSE-Leap-15.6-DVD ISO
```

### 2. Configure Shared Folder (Before First Boot)

**In VirtualBox Manager:**

1. Right-click VM → Settings → Shared Folders
2. Click folder icon (Add Shared Folder)
3. Settings:
   - **Folder Path**: `/home/jay/Documents/Vaidya-Solutions-Code/geckoforge`
   - **Folder Name**: `geckoforge`
   - **Mount Point**: `/mnt/geckoforge` (or leave auto)
   - ✓ **Auto-mount**
   - ✓ **Make Permanent**

### 3. Install openSUSE (~20 minutes)

Boot VM → Install → Choose:
- Desktop: **KDE Plasma**
- Partitioning: **Guided (Btrfs + snapshots)**
- User: `jay` (or your preference)
- Hostname: `geckoforge-vm`

After install, reboot and remove ISO.

### 4. Install VirtualBox Guest Additions

```bash
# In VM after first boot
sudo zypper install -y virtualbox-guest-tools kernel-devel

# Reboot to activate
sudo reboot
```

### 5. Access Shared Folder

```bash
# Add user to vboxsf group
sudo usermod -aG vboxsf $USER

# Reboot or re-login for group to take effect
sudo reboot

# Access shared folder (after reboot)
cd /media/sf_geckoforge
# Or if custom mount point:
cd /mnt/geckoforge

# Verify access
ls -la
```

### 6. Run geckoforge Setup

```bash
# Navigate to shared folder
cd /media/sf_geckoforge

# Update system first
sudo zypper refresh && sudo zypper update -y

# Run first-run setup
./scripts/firstrun-user.sh

# Apply Home-Manager
cd home
home-manager switch --flake .

# Test VS Code
code --version
```

---

## Snapshot Strategy

### Create Base Snapshots

```bash
# Snapshot 1: Fresh install
VirtualBox → Machine → Take Snapshot
Name: "01-fresh-install"
Description: "openSUSE Leap 15.6 + KDE, before geckoforge"

# Snapshot 2: After geckoforge setup
Name: "02-geckoforge-applied"
Description: "After firstrun-user.sh + home-manager"

# Snapshot 3: Before testing changes
Name: "03-before-test-[feature]"
Description: "Before testing [specific feature]"
```

### Revert to Snapshot

```bash
# GUI
VirtualBox → Right-click VM → Snapshots → Select → Restore

# CLI
VBoxManage snapshot "geckoforge-test" restore "02-geckoforge-applied"
```

---

## Automated Testing Workflow

### Test → Document → Revert → Retry

```bash
# 1. Take snapshot before test
VBoxManage snapshot "geckoforge-test" take "before-[feature]"

# 2. Run test in VM (via shared folder)
cd /media/sf_geckoforge
./scripts/setup-docker.sh  # Example

# 3. If fails, document error
# Create: docs/test-failures/[feature]-[date].md

# 4. Revert to snapshot
VBoxManage snapshot "geckoforge-test" restore "02-geckoforge-applied"

# 5. Fix in host WSL2
cd ~/Documents/Vaidya-Solutions-Code/geckoforge
# Edit scripts/setup-docker.sh

# 6. Changes immediately visible in VM (shared folder!)

# 7. Retry test
# Boot VM → cd /media/sf_geckoforge → run script again
```

---

## Shared Folder Benefits

✅ **No Git commits needed** - edit in WSL2, test in VM immediately  
✅ **Fast iteration** - no rsync, no file transfers  
✅ **Version control** - changes tracked in host Git  
✅ **Atomic reverts** - VM snapshot restores instantly  
✅ **Parallel testing** - multiple VMs can share same folder (read-only)

---

## Testing Checklist

### Phase 1: Basic Setup
- [ ] firstrun-user.sh completes without errors
- [ ] Nix multi-user installation works
- [ ] Home-Manager switches successfully
- [ ] VS Code installs with extensions
- [ ] All 8 languages configured

### Phase 2: Scripts
- [ ] setup-docker.sh works
- [ ] docker-nvidia-install.sh detects no GPU gracefully
- [ ] All optional scripts run or skip appropriately

### Phase 3: Nix Modules
- [ ] programs.power.enable = true (test TLP config)
- [ ] programs.network.enable = true (test DNS-over-TLS)
- [ ] programs.docker.utilities.enable = true (test prune timer)
- [ ] programs.autoUpdates.enable = true (test update timer)

### Phase 4: Applications
- [ ] VS Code launches and Copilot signs in
- [ ] Chromium opens with extensions
- [ ] Flatpaks install (Postman, DBeaver, OBS, Signal)
- [ ] Terminal emulator (Kitty) works
- [ ] Development tools accessible (node, python, go, etc.)

---

## Troubleshooting

### Shared Folder Not Visible

```bash
# Check if mounted
mount | grep vboxsf

# Manual mount
sudo mkdir -p /mnt/geckoforge
sudo mount -t vboxsf geckoforge /mnt/geckoforge

# Add to /etc/fstab for persistence
echo "geckoforge /mnt/geckoforge vboxsf defaults,uid=1000,gid=1000 0 0" | sudo tee -a /etc/fstab
```

### Permission Denied

```bash
# Verify group membership
groups $USER

# Should show: vboxsf

# If not, add and reboot
sudo usermod -aG vboxsf $USER
sudo reboot
```

### Guest Additions Not Working

```bash
# Reinstall
sudo zypper remove virtualbox-guest-tools
sudo zypper install virtualbox-guest-tools kernel-devel
sudo reboot
```

---

## Pro Tips

1. **Headless Mode**: Run VM without GUI for faster testing
   ```bash
   VBoxManage startvm "geckoforge-test" --type headless
   VBoxManage controlvm "geckoforge-test" poweroff
   ```

2. **SSH Access**: Enable SSH for remote testing
   ```bash
   # In VM
   sudo systemctl enable --now sshd
   
   # From host (if NAT + port forward)
   ssh -p 2222 jay@localhost
   ```

3. **Automation Script**: Create test runner
   ```bash
   #!/usr/bin/env bash
   # test-in-vm.sh
   
   SNAPSHOT="02-geckoforge-applied"
   VM="geckoforge-test"
   
   # Restore snapshot
   VBoxManage snapshot "$VM" restore "$SNAPSHOT"
   
   # Start VM
   VBoxManage startvm "$VM"
   
   # Wait for boot (30 seconds)
   sleep 30
   
   # SSH and run test
   ssh -p 2222 jay@localhost "cd /media/sf_geckoforge && ./scripts/firstrun-user.sh"
   ```

4. **Parallel Testing**: Clone VM for different test scenarios
   ```bash
   VBoxManage clonevm "geckoforge-test" --name "geckoforge-test-variant" --register
   ```

---

## Next: Packer Automation

For fully automated builds, see [packer-automation.md](./packer-automation.md)
