# Building KIWI ISO in VirtualBox VM

**Purpose**: Build a bootable deployment ISO from within your testing VM

---

## Prerequisites

1. ✅ VirtualBox VM running openSUSE Leap 15.6 + KDE
2. ✅ Shared folder configured: `/media/sf_geckoforge`
3. ✅ Docker installed in VM
4. ✅ Sufficient disk space (~15GB free)

---

## Why Build in VM?

**Problem**: WSL2 can't build bootable ISOs (kernel restrictions)  
**Solution**: Use the testing VM as the build environment

**Benefits**:
- ✅ Full Linux kernel access
- ✅ Test configs before building
- ✅ Shared folder = ISO available on host
- ✅ No dual-boot or separate Linux machine needed

---

## Quick Build

```bash
# Inside VM
cd /media/sf_geckoforge
./tools/kiwi-build.sh profiles/leap-15.6/kde-nvidia
```

**Time**: 15-20 minutes  
**Output**: `out/geckoforge-leap-15.6-Build*.iso`

The ISO is **immediately available on your host** via shared folder!

---

## Detailed Steps

### Step 1: Prepare VM

```bash
# Login to VM
# Open Konsole (terminal)

# Verify shared folder is mounted
ls /media/sf_geckoforge
# Should show: home/ scripts/ docs/ profiles/ etc.

# Navigate to repo
cd /media/sf_geckoforge

# Verify Docker is running
sudo systemctl status docker
# Should show: active (running)

# If not running:
sudo systemctl start docker
```

### Step 2: Check Disk Space

```bash
# Need ~15GB free for build
df -h /

# If low, clean up:
sudo zypper clean --all
docker system prune -a
```

### Step 3: Optional - Take Snapshot

**Before building, take a VM snapshot:**

1. VirtualBox window → **Machine** → **Take Snapshot**
2. Name: `before-kiwi-build`
3. Click **OK**

This lets you revert to clean state after build.

### Step 4: Build ISO

```bash
cd /media/sf_geckoforge

# Start build
./tools/kiwi-build.sh profiles/leap-15.6/kde-nvidia
```

**What happens:**
1. Pulls KIWI container image (~2 min)
2. Installs KIWI NG in container (~3 min)
3. Builds openSUSE system image (~10 min)
4. Creates bootable ISO (~5 min)

**Total**: ~15-20 minutes

**Output:**
```
Building image: geckoforge-leap-15.6
...
ISO created: out/geckoforge-leap-15.6-Build7.10.iso
```

### Step 5: Verify ISO

```bash
# In VM
ls -lh /media/sf_geckoforge/out/

# Should show:
# geckoforge-leap-15.6-Build7.10.iso  (~2-4GB)
```

### Step 6: Access ISO on Host

**On your host (Windows/WSL2):**

```bash
cd ~/Documents/Vaidya-Solutions-Code/geckoforge/out
ls -lh

# Same ISO is there! (via shared folder)
```

---

## Burn ISO to USB

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
   - Docker installed
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
