# Getting Started with Geckoforge

## 🚀 Installation Overview

**Timeline**: ~45 minutes total
- ISO creation: 10-15 min
- Installation: 10-15 min
- First boot (automatic): 5-10 min
- User setup: 15-20 min

---

## Step 1: Build the ISO

```bash
git clone https://github.com/jaelliot/geckoforge.git
cd geckoforge

# Build the ISO
./tools/kiwi-build.sh profiles/leap-15.6/kde-nvidia

# ISO will be in: out/geckoforge-leap156-kde.x86_64-*.iso
```

---

## Step 2: Create Bootable USB

**Linux**:
```bash
# Find your USB device
lsblk

# Write ISO (replace sdX with your device)
sudo dd if=out/geckoforge-*.iso of=/dev/sdX bs=4M status=progress
sudo sync
```

**Windows**: Use [Rufus](https://rufus.ie/) or [Etcher](https://www.balena.io/etcher/)

**macOS**:
```bash
diskutil list
diskutil unmountDisk /dev/diskN
sudo dd if=geckoforge-*.iso of=/dev/rdiskN bs=1m
```

---

## Step 3: Install to Hardware

### Boot from USB

1. Insert USB into target machine
2. Enter BIOS/UEFI (F2, F12, or Del)
3. **Disable Secure Boot** temporarily
4. Boot from USB

### Installation

1. **Welcome**: Select language
2. **License**: Accept
3. **Disk setup**:
   - Select disk
   - Choose **Guided - Use Entire Disk**
   - Enable **Encrypt Disk (LUKS2)**
   - Set strong passphrase
4. **Partitioning**: Confirm Btrfs layout
5. **Timezone**: Select region
6. **User account**: Create user and password
7. **Installation**: Wait 10-15 minutes
8. **Reboot**: Remove USB

---

## Step 4: First Boot (Automatic)

System automatically:
1. ✅ Boots into KDE Plasma
2. ✅ Runs `geckoforge-firstboot.service` (installs NVIDIA driver)
3. ✅ Runs `geckoforge-nix.service` (installs Nix)
4. ✅ Prompts for reboot

**Wait time**: ~5-10 minutes

### Verify

After automatic reboot:

```bash
# NVIDIA driver installed?
nvidia-smi

# Nix installed?
nix --version

# Check logs
journalctl -u geckoforge-firstboot.service
journalctl -u geckoforge-nix.service
```

---

## Step 5: User Setup

Run the setup wizard:

```bash
mkdir -p ~/git
cd ~/git
git clone https://github.com/jaelliot/geckoforge.git
cd geckoforge

# Make scripts executable
chmod +x scripts/*.sh

# Run wizard
./scripts/firstrun-user.sh
```

**This installs**:
- Podman (rootless containers)
- NVIDIA Container Toolkit (GPU in containers)
- Google Chrome (optional)
- Flatpak apps (Postman, DBeaver, OBS, Signal, Android Studio)
- Home-Manager (Nix dotfiles)

**Time**: 15-20 minutes

---

## Step 6: Configure Home-Manager

### Option A: Use Example Config

```bash
# Link example config
ln -s ~/git/geckoforge/home ~/git/home

# Edit with your info
nano ~/git/home/home.nix
# Update: username, email

# Apply
home-manager switch --flake ~/git/home
```

### Option B: Use Your Dotfiles

```bash
# When prompted by firstrun-user.sh, enter your repo URL
# It will clone to ~/git/home

# Apply
cd ~/git/home
home-manager switch --flake .
```

**Log out and back in** for full effect.

---

## Step 7: Verify Installation

```bash
# Nix works?
nix run nixpkgs#hello

# Podman works?
podman run hello-world

# GPU works? (NVIDIA only)
nvidia-smi
podman run --rm --device nvidia.com/gpu=all \
  nvidia/cuda:12.4.0-base nvidia-smi

# Flatpaks installed?
flatpak list
```

---

## Step 8: Enable Secure Boot (Optional)

1. Reboot → enter BIOS/UEFI
2. Re-enable Secure Boot
3. Enroll MOK (if prompted)
4. Verify: `mokutil --sb-state`

---

## Step 9: Harden Security

```bash
cd ~/git/geckoforge
./scripts/harden.sh
```

Configures:
- Firewall (firewalld)
- Automatic security updates
- Optional: fail2ban, auditd

---

## Step 10: Set Up Backups

See [Backup & Restore](backup-restore.md).

**Quick start**:
```bash
sudo zypper install restic
restic init --repo /mnt/backup/restic
# Copy backup script from docs/backup-restore.md
systemctl --user enable --now backup.timer
```

---

## Daily Use

### Updates (Monthly)

```bash
# OS
sudo zypper patch

# Nix apps
cd ~/git/home
nix flake update
home-manager switch --flake .

# Flatpaks
flatpak update
```

### Rollback

**OS** (Snapper):
```bash
sudo snapper list
sudo snapper rollback 42
sudo reboot
```

**Apps** (Nix):
```bash
home-manager generations
home-manager rollback
```

---

## Troubleshooting

### "nvidia-smi: command not found"

```bash
lspci | grep -i nvidia  # Verify GPU detected
sudo /usr/local/sbin/firstboot-nvidia.sh
sudo reboot
```

### "Nix command not found"

```bash
source ~/.nix-profile/etc/profile.d/nix.sh
# Or log out and back in
```

### "Podman permission denied"

```bash
grep "^$USER:" /etc/subuid /etc/subgid
~/git/geckoforge/scripts/setup-podman.sh
```

### "GPU not accessible in containers"

```bash
sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
nvidia-ctk cdi list
```

---

## Next Steps

1. Customize KDE: Right-click desktop → Configure
2. Import Firefox profile
3. Set up SSH keys: `ssh-keygen -t ed25519`
4. Install dev tools: Edit `~/git/home/modules/development.nix`
5. Configure backups

See full documentation in `docs/` directory.
