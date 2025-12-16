# Step-by-Step: VirtualBox + openSUSE + geckoforge Setup

**Date**: December 15, 2025  
**Time Required**: ~45 minutes  
**Prerequisites**: 
- VirtualBox installed
- openSUSE Leap 15.6 ISO downloaded
- 8GB+ RAM available
- 50GB+ disk space

---

## Phase 1: Create VirtualBox VM (5 minutes)

### Step 1: Open VirtualBox and Create New VM

1. Launch **VirtualBox**
2. Click **"New"** button (or Machine → New)
3. In the dialog:

   **Name and Operating System:**
   ```
   Name: geckoforge-test
   Folder: (default is fine)
   Type: Linux
   Version: openSUSE (64-bit)
   ```
   
   Click **Next**

### Step 2: Configure Memory

```
RAM: 8192 MB (8 GB)
```

**Note**: If you have 16GB+ RAM available, consider 12GB or 16GB for better performance.

Click **Next**

### Step 3: Create Virtual Hard Disk

```
○ Create a virtual hard disk now
```

Click **Create**

### Step 4: Hard Disk File Type

```
○ VDI (VirtualBox Disk Image)
```

Click **Next**

### Step 5: Storage on Physical Hard Disk

```
○ Dynamically allocated
```

**Note**: This means the VM disk only uses space as needed, not the full 50GB upfront.

Click **Next**

### Step 6: File Location and Size

```
File location: geckoforge-test (default)
Size: 50.00 GB
```

Click **Create**

---

## Phase 2: Configure VM Settings (5 minutes)

### Step 7: Open VM Settings

1. Right-click **geckoforge-test** VM
2. Select **Settings**

### Step 8: System Settings

Go to **System** tab:

**Motherboard Tab:**
```
✓ Enable EFI (special OSes only)  ← CRITICAL!
Boot Order:
  ✓ Optical
  ✓ Hard Disk
  ☐ Floppy
  ☐ Network
```

**Processor Tab:**
```
Processor(s): 4 CPUs
```

Click **OK** to apply

### Step 9: Display Settings

Go to **Display** tab:

```
Video Memory: 128 MB
Graphics Controller: VMSVGA (or VBoxSVGA)
☐ Enable 3D Acceleration (keep unchecked)
```

Click **OK**

### Step 10: Shared Folders Setup

Go to **Shared Folders** tab:

1. Click the **folder icon with +** (Add Shared Folder)
2. In the dialog:

   ```
   Folder Path: Click dropdown → Other
                Navigate to: /home/jay/Documents/Vaidya-Solutions-Code/geckoforge
                Select Folder
   
   Folder Name: geckoforge  ← Will be used to mount later
   
   ✓ Auto-mount
   ✓ Make Permanent
   ☐ Read-only (leave unchecked)
   
   Mount point: (leave blank - will auto-mount to /media/sf_geckoforge)
   ```

3. Click **OK**
4. Click **OK** to close Settings

### Step 11: Attach ISO

1. With **geckoforge-test** selected, go to **Settings**
2. Go to **Storage** tab
3. Under **Controller: IDE** or **Controller: SATA**, select **Empty** (optical drive)
4. On the right, under **Attributes**, click the **disc icon**
5. Select **"Choose a disk file..."**
6. Navigate to your downloaded ISO:
   ```
   openSUSE-Leap-15.6-DVD-x86_64-Current.iso
   ```
7. Click **Open**
8. Click **OK** to close Settings

---

## Phase 3: Install openSUSE (20 minutes)

### Step 12: Start VM

1. Select **geckoforge-test**
2. Click **Start** (green arrow)
3. VM window opens and boots from ISO

### Step 13: Installation Boot Menu

When you see the openSUSE boot menu:

```
> Installation
  Upgrade
  Rescue System
  ...
```

1. Select **"Installation"** (should be default)
2. Press **Enter**

**Wait**: System loads installer (~1-2 minutes)

### Step 14: Language and Keyboard

```
Language: English (or your preference)
Keyboard Layout: English (US) (or your preference)
```

Click **Next**

### Step 15: Online Repositories

```
○ No, Skip Online Repositories  ← Recommended for faster install
```

**Note**: We'll update after installation via scripts.

Click **Next**

### Step 16: System Role

```
○ Desktop with KDE Plasma  ← CRITICAL! Select this one
```

**Do NOT select:**
- ☐ Server
- ☐ Transactional Server
- ☐ Desktop with GNOME

Click **Next**

### Step 17: Suggested Partitioning

**Default partitioning is PERFECT:**
```
Partition Setup:
  /boot/efi   512 MB    vfat
  /           (rest)    Btrfs with snapshots ✓

Filesystem: Btrfs
Enable Snapshots: Yes ✓
```

**Don't change anything here** - openSUSE's default Btrfs setup is exactly what geckoforge expects!

Click **Next**

### Step 18: Clock and Time Zone

```
Region: (Your region, e.g., America)
Time Zone: (Your timezone, e.g., New York)

Hardware Clock Set To UTC: ✓ (keep checked)
```

Click **Next**

### Step 19: Local User

**IMPORTANT**: Create your user account

```
User's Full Name: Jay Elliott (or your name)
Username: jay  ← This matches geckoforge defaults

Password: [your password]
Confirm Password: [your password]

☐ Use this password for system administrator  ← UNCHECK THIS
✓ Automatic Login  ← Optional, convenient for testing
```

Click **Next**

### Step 20: Authentication for System Administrator

```
Root Password: [your root password]
Confirm Password: [your root password]
```

**Security Note**: For testing VM, you can use the same password as your user.

Click **Next**

### Step 21: Installation Settings Summary

You'll see a summary screen. Verify:

```
✓ System: x86_64, EFI
✓ Keyboard: English (US)
✓ Partitioning: Btrfs with snapshots
✓ Software: KDE Plasma Desktop
✓ User: jay
```

**Optional**: Click **"Software"** to see what's being installed
- You should see patterns like `kde`, `kde_plasma`, `base`, `enhanced_base`

Click **Install** (bottom right)

### Step 22: Confirm Installation

Popup asks: **"Start Installation?"**

```
All data on selected drives will be erased!
```

Click **Install**

### Step 23: Installation Progress

**Wait**: Installation takes **15-20 minutes**

You'll see:
- Package installation progress
- Generating initrd
- Preparing system for first boot

**DO NOT CLOSE THE WINDOW OR STOP THE VM**

When complete:
```
Installation Successfully Completed
```

Click **Finish**

### Step 24: First Reboot

1. VM will reboot automatically
2. **IMPORTANT**: When you see the boot screen, quickly go to:
   - VirtualBox menu: **Devices → Optical Drives → Remove disk from virtual drive**
   - Or it may auto-eject

3. System boots into openSUSE for the first time

---

## Phase 4: First Boot Configuration (5 minutes)

### Step 25: Login

**If you enabled Auto Login**: You'll boot directly to KDE Plasma desktop

**If not**:
```
Username: jay
Password: [your password]
```

Click **Log In**

### Step 26: KDE Welcome Wizard (Optional)

KDE may show a welcome wizard. You can:
- Click through it (takes 2 minutes)
- Or skip: Click **"Skip"** or close window

### Step 27: Open Terminal (Konsole)

1. Click **Application Launcher** (bottom left, KDE logo)
2. Type: `konsole`
3. Press **Enter**

Or use keyboard shortcut: **Ctrl+Alt+T**

### Step 28: Update System

```bash
# Refresh repositories
sudo zypper refresh

# Update all packages
sudo zypper update -y
```

**Wait**: Updates take ~5-10 minutes depending on how recent your ISO is.

When prompted about conflicts or vendor changes:
```
Solution 1: replace [package] with [newer version]
```
Type: `1` and press **Enter** (choose to replace/update)

### Step 29: Install VirtualBox Guest Additions

```bash
# Install required packages
sudo zypper install -y virtualbox-guest-tools kernel-devel

# Reboot to activate Guest Additions
sudo reboot
```

**Wait**: VM reboots (~30 seconds)

### Step 30: Log Back In

After reboot, login again:
```
Username: jay
Password: [your password]
```

---

## Phase 5: Configure Shared Folder Access (2 minutes)

### Step 31: Add User to vboxsf Group

Open terminal (Konsole) again:

```bash
# Add your user to VirtualBox shared folder group
sudo usermod -aG vboxsf $USER

# Verify it was added
groups $USER
```

**Expected output should include**: `... wheel vboxsf ...`

### Step 32: Reboot for Group to Take Effect

```bash
sudo reboot
```

**Note**: You MUST reboot for group membership to activate. Logging out/in is not enough.

### Step 33: Verify Shared Folder Access

After reboot and login, open terminal:

```bash
# Check if shared folder is mounted
ls -la /media/sf_geckoforge

# You should see your geckoforge repo files:
# home/  scripts/  docs/  etc.
```

**If it says "Permission denied"**: Group membership didn't apply yet. Try:
```bash
# Manual mount (temporary)
sudo mount -t vboxsf geckoforge /mnt/geckoforge
cd /mnt/geckoforge
```

**If it says "No such file or directory"**: Shared folder not configured. Go back to Phase 2, Step 10.

---

## Phase 6: Run geckoforge Setup (15 minutes)

### Step 34: Navigate to Shared Folder

```bash
# Go to your geckoforge repo (via shared folder)
cd /media/sf_geckoforge

# Verify you're in the right place
ls -la
# Should show: home/  scripts/  docs/  README.md  etc.

# Check current location
pwd
# Should show: /media/sf_geckoforge
```

### Step 35: Make Scripts Executable (if needed)

```bash
# Ensure scripts are executable
chmod +x scripts/*.sh
```

### Step 36: Run First-Run Setup

```bash
# Run the main setup script
./scripts/firstrun-user.sh
```

**This script will**:
1. Detect no NVIDIA GPU (gracefully skip GPU setup)
2. Install Docker
3. Install Nix (multi-user)
4. Set up Home-Manager
5. Guide you through configuration

**Follow the prompts**:
- Docker setup: `y` (yes)
- NVIDIA detection: Will say "No NVIDIA GPU detected - skipping"
- Nix installation: `y` (yes)
- Home-Manager setup: `y` (yes)

**Wait**: This takes ~10-15 minutes

### Step 37: Source Nix Environment

After firstrun-user.sh completes:

```bash
# Reload shell to pick up Nix
source ~/.nix-profile/etc/profile.d/nix.sh

# Verify Nix is available
nix --version
# Should show: nix (Nix) 2.x.x

# Verify Home-Manager is available
home-manager --version
# Should show: 24.05 (or similar)
```

### Step 38: Apply Home-Manager Configuration

```bash
# Navigate to home config
cd /media/sf_geckoforge/home

# Apply your full configuration
home-manager switch --flake .
```

**This installs**:
- VS Code + all 29 extensions
- Python, Node.js, Go, Elixir, etc.
- Development tools
- All Nix modules (power, network, docker, etc.)

**Wait**: First build takes ~10-15 minutes (downloads packages)

**Expected output**:
```
Starting Home Manager activation
...
[vscode] VS Code configured with 29 extensions
[docker] Docker utilities installed
[network] DNS-over-TLS configured
...
Activation complete
```

### Step 39: Verify Installation

```bash
# Check VS Code
code --version

# Check Node.js
node --version

# Check Python
python3 --version

# Check Go
go version

# Check Docker
docker --version

# Test Docker
sudo usermod -aG docker $USER
# Logout/login or newgrp docker for group to take effect
```

### Step 40: Test VS Code

```bash
# Launch VS Code
code /media/sf_geckoforge

# Or open specific file
code /media/sf_geckoforge/home/home.nix
```

**VS Code should**:
- Launch successfully
- Show all extensions in Extensions panel
- Prompt to sign into GitHub Copilot (if enabled)

---

## Phase 7: Testing Workflow (Ongoing)

### Taking Snapshots

**Create base snapshot now**:

1. In VirtualBox window menu: **Machine → Take Snapshot**
2. Name: `01-base-geckoforge-setup`
3. Description: `After firstrun-user.sh and home-manager switch`
4. Click **OK**

**Before testing any change**:
1. Take snapshot: Name it `before-test-[feature]`
2. Make changes in WSL2 (they appear instantly in VM via shared folder)
3. Test in VM: `cd /media/sf_geckoforge && ...`
4. If breaks: **Machine → Restore Snapshot**
5. Fix in WSL2
6. Test again

### Edit-Test Cycle

**In WSL2**:
```bash
cd ~/Documents/Vaidya-Solutions-Code/geckoforge
vim home/home.nix  # Make changes
# No git commit needed!
```

**In VM** (changes visible immediately):
```bash
cd /media/sf_geckoforge/home
home-manager switch --flake .  # Apply changes
```

**If it breaks**:
1. VirtualBox: Restore snapshot (10 seconds)
2. WSL2: Fix the config
3. VM: Try again (instantly sees new changes)

---

## Troubleshooting

### Shared Folder Not Visible

```bash
# Check if VirtualBox modules loaded
lsmod | grep vbox

# Check if shared folder is defined
VBoxControl sharedfolder list

# Manual mount
sudo mkdir -p /mnt/geckoforge
sudo mount -t vboxsf geckoforge /mnt/geckoforge
cd /mnt/geckoforge
```

### Permission Denied on Shared Folder

```bash
# Verify group membership
groups
# Should show: ... vboxsf ...

# If not there, add again
sudo usermod -aG vboxsf $USER
sudo reboot
```

### Docker Permission Denied

```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Either logout/login OR
newgrp docker

# Test
docker ps
```

### Home-Manager Fails

```bash
# Check Nix is sourced
which nix
# Should show: /nix/store/.../bin/nix

# If not, source Nix profile
source ~/.nix-profile/etc/profile.d/nix.sh

# Try again
cd /media/sf_geckoforge/home
home-manager switch --flake . --show-trace
```

### VS Code Won't Launch

```bash
# Check if installed
which code
# Should show path

# If not, ensure home-manager applied successfully
cd /media/sf_geckoforge/home
home-manager switch --flake .

# Try launching with error output
code --verbose
```

---

## Quick Reference: Common Commands

```bash
# Access shared folder
cd /media/sf_geckoforge

# Apply Home-Manager changes
cd /media/sf_geckoforge/home && home-manager switch --flake .

# Check Home-Manager generations
home-manager generations

# Rollback if something breaks
home-manager rollback

# Update system packages
sudo zypper refresh && sudo zypper update

# Reboot VM
sudo reboot

# Shutdown VM
sudo shutdown -h now
```

---

## What's Next?

✅ **You now have**:
- Working openSUSE Leap 15.6 + KDE Plasma
- VirtualBox Guest Additions (shared folders working)
- Docker installed and configured
- Nix + Home-Manager set up
- VS Code with all extensions
- Complete development environment
- Instant edit-test workflow via shared folders

✅ **You can**:
- Edit configs in WSL2
- Test instantly in VM
- Revert with snapshots in seconds
- Document any failures
- Iterate quickly

🚀 **Next phase**: Once you've tested everything and are confident, we'll set up **Packer automation** to build reproducible VMs automatically!

---

**Total Setup Time**: ~45 minutes  
**Your geckoforge environment is now ready for testing!** 🎉
