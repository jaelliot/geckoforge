# Building KIWI ISO in VM

**Purpose**: Build a bootable deployment ISO from within a VM (VirtualBox or VMware Fusion)

---

## Prerequisites

1. ✅ VM running openSUSE Leap 15.6 or Tumbleweed
2. ✅ Sufficient disk space (~15GB free)
3. ✅ Internet connection for package downloads

---

## Why Build in VM?

**Problem**: WSL2 can't build bootable ISOs (kernel restrictions)  
**Solution**: Use a VM as the build environment

**Benefits**:
- ✅ Full Linux kernel access
- ✅ No Docker permission issues
- ✅ Test configs before building
- ✅ No dual-boot or separate Linux machine needed

---

## Quick Build

```bash
# Clone the repo (or pull latest)
cd ~/geckoforge
git pull

# Build the ISO (installs KIWI automatically if needed)
./tools/kiwi-build.sh profile
```

**Time**: 15-20 minutes  
**Output**: `out/geckoforge-leap-15.6-*.iso`

---

## Detailed Steps

### Step 1: Prepare VM

```bash
# Login to VM
# Open Konsole (terminal)

# Clone repo if not already done
git clone https://github.com/jaelliot/geckoforge.git
cd geckoforge

# Or update existing repo
cd ~/geckoforge
git pull
```

### Step 2: Check Disk Space

```bash
# Need ~15GB free for build
df -h /

# If low, clean up:
sudo zypper clean --all
```

### Step 3: Optional - Take Snapshot

**Before building, take a VM snapshot:**

**VirtualBox**: Machine → Take Snapshot  
**VMware Fusion**: Virtual Machine → Snapshots → Take Snapshot

Name it `before-kiwi-build` - lets you revert if needed.

### Step 4: Build ISO

```bash
cd ~/geckoforge

# Start build (will install KIWI if not present)
./tools/kiwi-build.sh profile
```

**What happens:**
1. Installs KIWI NG if missing (~2 min)
2. Validates profile configuration
3. Builds openSUSE system image (~10 min)
4. Creates bootable ISO (~5 min)

**Total**: ~15-20 minutes

**Output:**
```
Building image: geckoforge-leap-15.6
...
ISO created: out/geckoforge-leap-15.6-*.iso
```

### Step 5: Verify ISO

```bash
# In VM
ls -lh ~/geckoforge/out/

# Should show:
# geckoforge-leap-15.6-*.iso  (~2-4GB)
```

### Step 6: Transfer ISO to Host (Optional)

**Option A: SCP from host**
```bash
# From your Mac/Windows terminal
scp user@VM_IP:~/geckoforge/out/*.iso ~/Downloads/
```

**Option B: Shared folder (if configured)**
```bash
# Copy to shared folder
cp ~/geckoforge/out/*.iso /mnt/vm-shared/
```

---

## Burn ISO to USB

### On macOS

```bash
# Find USB device
diskutil list

# Unmount USB (replace diskN with your disk)
diskutil unmountDisk /dev/diskN

# Burn ISO (CAREFUL: double-check device!)
sudo dd if=geckoforge-leap-15.6-*.iso \
        of=/dev/rdiskN \
        bs=4m \
        status=progress

# Eject
diskutil eject /dev/diskN
```

### On Windows (with Rufus)

1. Download **Rufus**: https://rufus.ie/
2. Insert USB drive (8GB+)
3. Open Rufus
4. **Device**: Select your USB drive
5. **Boot selection**: Click **SELECT** → Choose `geckoforge-*.iso`
6. **Partition scheme**: GPT
7. **Target system**: UEFI
8. Click **START**
9. Wait ~5 minutes
10. Safely eject USB

### On Linux

```bash
# Find USB device
lsblk

# Unmount if mounted
sudo umount /dev/sdX*

# Burn ISO (CAREFUL: double-check device!)
sudo dd if=geckoforge-leap-15.6-*.iso \
        of=/dev/sdX \
        bs=4M \
        status=progress \
        conv=fsync

# Eject
sudo eject /dev/sdX
```

---

## Deploy to Laptop

### Step 1: Boot from USB

1. Insert USB drive in laptop
2. Power on laptop
3. Press **Boot Menu** key (F12, F2, ESC, or DEL)
4. Select USB drive
5. Press Enter

### Step 2: Install

The installer is **automated** with KDE Plasma pre-selected:

1. **Language**: Select and click Next
2. **Keyboard**: Select and click Next
3. **System Role**: Should auto-select "Desktop with KDE Plasma" → Next
4. **Partitioning**: Accept defaults (Btrfs + snapshots) → Next
5. **User**: Create your user → Next
6. **Confirm**: Click Install

**Time**: ~15-20 minutes

### Step 3: First Boot

After install completes:

1. Reboot (remove USB)
2. Login to KDE
3. Everything is pre-configured!
   - NVIDIA drivers detected and installed
   - All scripts in `/opt/geckoforge`
   - Home-Manager ready to apply

### Step 4: Finalize (Optional)

```bash
# Apply Home-Manager if not already applied
cd /opt/geckoforge/home
home-manager switch --flake .

# Install Flatpaks
cd /opt/geckoforge
./scripts/install-flatpaks.sh

# Reboot
sudo reboot
```

---

## Build Customization

### Minimal Build (Faster)

Edit `profiles/leap-15.6/kde-nvidia/config.kiwi.xml`:

```xml
<!-- Remove optional packages -->
<package name="games-*"/>  <!-- Remove games -->
<package name="libreoffice"/>  <!-- Add office later via Flatpak -->
```

Rebuild:
```bash
./tools/kiwi-build.sh profiles/leap-15.6/kde-nvidia
```

### Add Pre-installed Software

Edit `config.kiwi.xml`:

```xml
<packages type="image">
  <package name="vim"/>
  <package name="tmux"/>
  <package name="htop"/>
  <!-- Your additions -->
</packages>
```

---

## Troubleshooting

### "Permission denied" accessing shared folder

```bash
# In VM
sudo usermod -aG vboxsf $USER
sudo reboot
```

### Docker not running

```bash
# In VM
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
# Logout/login for group to take effect
```

### KIWI build fails

```bash
# Check logs
cd /media/sf_geckoforge
./tools/kiwi-build.sh profiles/leap-15.6/kde-nvidia 2>&1 | tee build.log

# Common issues:
# 1. Insufficient disk space → Clean up
# 2. Docker daemon not running → Start it
# 3. Network issues → Check connectivity
```

### ISO doesn't appear on host

```bash
# In VM, check output location
ls -la /media/sf_geckoforge/out/

# The shared folder should sync automatically
# If not, try:
# 1. Refresh Windows Explorer
# 2. Check VirtualBox shared folder settings
# 3. Restart VM
```

### ISO won't boot on laptop

**Check BIOS/UEFI settings:**
1. UEFI mode enabled (not Legacy/BIOS)
2. Secure Boot disabled (initially)
3. Boot order: USB first

**Re-burn ISO:**
- Try different USB drive
- Use Rufus instead of dd (or vice versa)
- Verify ISO checksum

---

## Advanced: Automated Builds

### Script to Build Multiple ISOs

```bash
#!/bin/bash
# build-all-isos.sh

PROFILES=(
  "profiles/leap-15.6/kde-nvidia"
  # Add more profiles
)

for profile in "${PROFILES[@]}"; do
  echo "Building $profile..."
  ./tools/kiwi-build.sh "$profile"
done

echo "All ISOs built in out/"
```

### CI/CD Integration

The VM can be automated:

```bash
# Headless VM start
VBoxManage startvm "geckoforge-test" --type headless

# SSH into VM
ssh -p 2222 jay@localhost

# Run build
cd /media/sf_geckoforge
./tools/kiwi-build.sh profiles/leap-15.6/kde-nvidia

# Shutdown VM
VBoxManage controlvm "geckoforge-test" poweroff

# ISO is now on host in out/
```

---

## Workflow Summary

```
┌─────────────────────────────────────────────┐
│ 1. Develop/Test in VM (shared folder)      │
│    • Edit configs on host                  │
│    • Test in VM instantly                  │
│    • Use snapshots for safety              │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│ 2. Build ISO in VM (when satisfied)        │
│    • Run: ./tools/kiwi-build.sh            │
│    • Wait 15-20 minutes                    │
│    • ISO appears in out/ on host          │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│ 3. Burn to USB (on host)                   │
│    • Use Rufus or dd                       │
│    • 8GB+ USB drive                        │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│ 4. Deploy to Laptop                        │
│    • Boot from USB                         │
│    • Install (~20 min)                     │
│    • First boot → finalize → done!        │
└─────────────────────────────────────────────┘
```

---

## Tips

1. **Keep VM clean** - Restore snapshot before each build for consistency
2. **Version ISOs** - Tag builds with Git version numbers
3. **Test ISOs in VM first** - Mount ISO in VirtualBox, test before burning
4. **Document changes** - Update CHANGELOG with each ISO release
5. **Backup ISOs** - Store successful builds (cloud, external drive)

---

## Next Steps

After deploying to laptop:
1. Daily driver testing (1-2 weeks)
2. Document any issues
3. Fix in Packer VM
4. Rebuild ISO
5. Deploy to production workstation (if stable)

---

**Your VM is now a complete build environment!** Test, build, deploy - all from one place. 🚀
