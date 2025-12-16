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
./tools/kiwi-build.sh profile

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

# Run wizard
./scripts/firstrun-user.sh
```

**This installs**:
- Docker (removes Podman and prompts before deleting data)
- NVIDIA Container Toolkit for Docker (when GPU detected)
- Flatpak apps (Postman, DBeaver, OBS, Signal, Android Studio)
- Home-Manager bootstrap (Nix dotfiles)

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

# Docker works?
docker run hello-world

# GPU works? (NVIDIA only)
nvidia-smi
docker run --rm --gpus all \
  nvidia/cuda:12.4.0-base nvidia-smi

# TeX Live ready?
cd ~/git/geckoforge/docs
less tex-verification.md

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

## Step 10: Keyboard/Mouse Sharing (Optional)

If you use Synergy to share keyboard/mouse across multiple computers:

```bash
cd ~/git/geckoforge
./scripts/setup-synergy.sh
```

**Requirements:**
- Synergy license from symless.com
- Downloaded Synergy RPM

The script will guide you through installation and configuration.

**Time:** 5 minutes

---

## Step 11: Activate Theme (Optional)

Geckoforge includes the **Mystical Blue (Jux)** theme - a professional dark blue aesthetic.

**Activate the theme:**
```bash
cd ~/git/geckoforge
./scripts/setup-jux-theme.sh
```

**Then:**
- Log out and back in
- Theme is active!

**Time:** 2 minutes

**Details:** See [Theme Guide](themes.md)

---

## Step 12: Configure Email Client (Thunderbird)

Geckoforge includes Mozilla Thunderbird with hardened anti-phishing settings.

### Quick Setup

1. Open Thunderbird (from application menu or `thunderbird` command)
2. Add your email accounts:
   - **Gmail:** Use OAuth2 authentication
   - **Outlook:** Use OAuth2 authentication  
   - **ProtonMail:** Run `~/git/geckoforge/scripts/setup-protonmail-bridge.sh` first

### Security Notice

⚠️ **Links in emails are NOT clickable** by default (anti-phishing protection).

To open a link:
1. Right-click → Copy Link Location
2. Inspect the URL
3. Paste into browser if safe

**Complete setup guide:** [Thunderbird Setup Documentation](thunderbird-setup.md)

**Time:** 10-15 minutes per email account

---

## Step 13: Set Up Encrypted Cloud Backups

Geckoforge includes a comprehensive encrypted backup system for DevOps workflows.

### Quick Setup

```bash
cd ~/git/geckoforge

# Configure cloud provider and encryption
./scripts/setup-rclone.sh

# Test backup system
./scripts/check-backups.sh --test

# Enable automated backups
systemctl --user enable --now rclone-backup-critical.timer
systemctl --user enable --now rclone-backup-projects.timer

# Verify operation
systemctl --user list-timers
```

### What Gets Backed Up

- **Critical (Daily)**: SSH keys, GPG keys, AWS credentials, Kubernetes configs, documents
- **Projects (Weekly)**: Git repositories, development workspaces, VS Code settings
- **Infrastructure (Monthly)**: Infrastructure as Code, Ansible playbooks, Terraform configs

### Cloud Provider Options

1. **Google Drive**: 15GB free, good for personal use
2. **AWS S3**: Pay-as-you-go, best for professional use
3. **Backblaze B2**: Cheaper alternative to S3
4. **OneDrive**: If you have O365 subscription

### Security Features

- **Zero-knowledge encryption**: Data encrypted client-side before upload
- **AES-256 encryption**: Industry-standard encryption strength
- **Filename obfuscation**: Even file names are encrypted
- **Password protection**: Dual-password system (encryption + salt)

### Monitoring

```bash
# Health check
./scripts/check-backups.sh

# View backup logs
ls ~/.local/share/rclone/logs/

# Service status
systemctl --user status rclone-backup-critical.service
```

**Complete guide**: [Backup & Recovery Documentation](backup-recovery.md)

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

### "Docker permission denied"

```bash
newgrp docker
~/git/geckoforge/scripts/setup-docker.sh
```

### "GPU not accessible in containers"

```bash
~/git/geckoforge/scripts/docker-nvidia-install.sh
~/git/geckoforge/scripts/docker-nvidia-verify.sh
```

---

## Quality Gates (Lefthook)

This repository uses [lefthook](https://github.com/evilmartians/lefthook) for automated quality checks.

### Installation

```bash
# Via zypper (openSUSE)
sudo zypper install lefthook

# Or via Home-Manager (add to home/modules/development.nix)
home.packages = with pkgs; [
  lefthook
  shellcheck
  markdownlint-cli
];
```

### Setup

```bash
# Install hooks
lefthook install

# Verify installation
lefthook version
```

### Usage

Hooks run automatically on commit and push. To run manually:

```bash
# Run pre-commit checks
lefthook run pre-commit

# Run pre-push checks  
lefthook run pre-push

# Run specific check
lefthook run pre-commit --commands shellcheck
```

### Bypassing Hooks (Emergency Only)

```bash
# Skip all hooks (NOT RECOMMENDED)
git commit --no-verify

# Skip specific check
LEFTHOOK_EXCLUDE=shellcheck git commit -m "WIP: prototype"

# Document bypasses in daily summary!
```

See `.cursor/rules/25-lefthook-quality.mdc` for full quality gate documentation.

---

## Shell Configuration

### DevOps-Optimized Zsh

Geckoforge uses **zsh** with **Oh My Zsh** and **Powerlevel10k** for a powerful DevOps terminal experience.

**Features:**
- **Instant prompt** - Shell appears immediately, loads config in background
- **Autosuggestions** - Commands from history appear as you type (press `→` to accept)
- **Syntax highlighting** - Invalid commands show in red before you execute
- **DevOps plugins** - Native completion for kubectl, terraform, docker, aws
- **fzf integration** - Press `Ctrl+R` for fuzzy history search
- **Context-aware prompt** - Current kubectl context, AWS profile, Terraform workspace
- **Safety coloring** - Production contexts appear RED, staging YELLOW
- **Large history** - 50,000 commands with deduplication
- **Privacy mode** - Space-prefixed commands excluded from history

### Activating Zsh

After first boot, change your default shell:

```bash
# Change default shell to zsh
./scripts/setup-shell.sh

# Log out and back in
# (Ctrl+D or close terminal)

# After logging back in, activate Oh My Zsh configuration
cd ~/git/home
home-manager switch --flake .

# Start a new terminal to see the Powerlevel10k prompt
```

### Using Autosuggestions

As you type commands, zsh suggests from your history in gray text:

```bash
# You type: kubect
# Suggestion appears: kubectl get pods -n production
# Press → (right arrow) to accept the full suggestion
# Or press Alt+F to accept word-by-word
```

**Tips:**
- Suggestions are based on your most recent matching commands
- Works great for long Docker/Kubernetes commands
- Press `Tab` for traditional completion if you don't want history

### Using fzf History Search

Press `Ctrl+R` to open fuzzy finder for your command history:

```bash
# Press Ctrl+R
# Type: docker run
# See ALL matching commands from history
# Navigate with arrow keys, press Enter to select
```

**Other fzf shortcuts:**
- `Ctrl+T` - Fuzzy find files in current directory
- `Alt+C` - Fuzzy find and cd into directory

### Privacy & Security

**Sensitive commands:** Prefix with space to exclude from history:

```bash
# This WILL be saved to history:
aws configure set region us-east-1

# This WON'T be saved (note the leading space):
 aws configure set aws_access_key_id AKIA...
 export DATABASE_PASSWORD=secret123
```

**Context awareness:** The prompt shows your kubectl context and AWS profile. Production contexts appear in **RED** as a visual warning.

### DevOps Plugin Reference

**kubectl plugin:**
- `k` - Alias for `kubectl`
- `kgp` - Get pods
- `kgd` - Get deployments
- Tab completion for resources, namespaces, contexts

**docker plugin:**
- `dps` - `docker ps`
- `dex` - `docker exec -it`
- Tab completion for containers, images

**terraform plugin:**
- `tf` - Alias for `terraform`
- Tab completion for commands, workspaces

**aws plugin:**
- Tab completion for AWS CLI commands
- Profile completion

After first boot, change your default shell:

```bash
# Change default shell to zsh
./scripts/setup-shell.sh

# Log out and back in

# Activate Oh My Zsh configuration
cd ~/git/home
home-manager switch --flake .
```

### Customizing Powerlevel10k

Edit `~/.p10k.zsh` (managed by Home-Manager) or run:

```bash
p10k configure
```

Configuration is stored in `home/modules/shell.nix` for version control.

### AWS CLI

Default AWS configuration:
- **Region:** us-east-1
- **Output:** json

Configure credentials:

```bash
aws configure
# Enter AWS Access Key ID and Secret Access Key
```

---

## Next Steps

1. Customize KDE: Right-click desktop → Configure
2. Import Firefox profile
3. Set up SSH keys: `ssh-keygen -t ed25519`
4. Install dev tools: Edit `~/git/home/modules/development.nix`
5. Configure backups

See full documentation in `docs/` directory.
