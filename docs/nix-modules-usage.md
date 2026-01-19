# Nix Modules Usage Guide

## New Declarative Modules

After Phase 1 & 2 consolidation, these features are now configured in `home.nix`:

---

### 1. Python Development (`development.nix`)

**Nix-based Python workflow with direnv:**

geckoforge uses a **hybrid approach** for Python development:
- **Nix provides**: Python 3.14.2, cryptographic libraries (libsodium, blake3), build tools
- **pip manages**: Python packages in project-local `.venv`
- **direnv automates**: Environment activation when entering project directories

**Quick Start:**

```bash
# Copy the template
cp -r ~/git/geckoforge/examples/python-nix-direnv my-project
cd my-project

# Allow direnv
direnv allow

# Environment auto-activates with Python 3.14.2 + KERI libraries
python --version
pip list
```

**Features:**
- Reproducible Python environments across machines
- Automatic activation via direnv (no manual `source venv/bin/activate`)
- VS Code integration (auto-detects `.venv/bin/python`)
- pytest with async support, coverage reporting
- mypy type checking
- KERI cryptographic libraries pre-configured

**Documentation:**
- **Generic Python**: [Python Development Guide](python-development.md)
- **KERI Projects**: [KERI Development Guide](keri-development.md)
- **Example Template**: `examples/python-nix-direnv/`

**Configuration:** Already enabled in [home/modules/development.nix](../home/modules/development.nix) - no changes needed.

---

### 2. Power Management (`power.nix`)

**Enable laptop power optimization:**

```nix
programs.power = {
  enable = true;
  
  # Defaults are optimized for MSI GF65 (Intel i7-10750H + RTX 3060)
  # Customize if needed:
  cpu.maxFreqBattery = 3200000;  # 3.2GHz max on battery
  battery.stopThreshold = 80;     # Stop charging at 80%
};
```

**Apply:**
```bash
home-manager switch --flake ~/git/home

# One-time: Install TLP system-wide
sudo cp ~/.config/tlp/tlp.conf /etc/tlp.conf
sudo systemctl enable --now tlp
```

**Tools**: `check-thermals`, `power-status`, `temps`, `battery`

---

### 2. Auto-Updates (`auto-updates.nix`)

**Enable automatic security updates:**

```nix
programs.autoUpdates = {
  enable = true;
  schedule = "daily";           # Or specific time "02:00"
  onlySecurityPatches = true;   # Security only (recommended)
};
```

**Apply:**
```bash
home-manager switch --flake ~/git/home

# One-time: Install system-wide
install-auto-updates
```

**Tools**: `update-status`, `update-logs`

---

### 3. Network Security (`network.nix`)

**Enable DNS-over-TLS:**

```nix
programs.network = {
  enable = true;
  
  dns.provider = "quad9";       # or "cloudflare", "google"
  dns.enableDNSSEC = true;
  
  vpn.installProtonVPN = false; # Optional
};
```

**Apply:**
```bash
home-manager switch --flake ~/git/home

# One-time: Install DNS config
install-secure-dns
```

**Tools**: `check-dns`, `dns-status`, `dns-test`

---

### 4. Docker Utilities (`docker.nix`)

**Enable Docker automation:**

```nix
programs.docker.utilities = {
  enable = true;
  autoPrune = true;
  pruneSchedule = "weekly";
  pruneVolumes = false;  # Be careful with volumes!
};
```

**Apply:**
```bash
home-manager switch --flake ~/git/home

# One-time: Install prune timer
install-docker-prune
```

**Tools**: `docker-status`, `dstat`, `dps`, `dimg`, `dprune`

---

### 5. Gaming (`gaming.nix`)

**Enable Steam + optimizations:**

```nix
programs.gaming = {
  enable = true;
  
  performance.gamemode = true;
  performance.mangohud = true;
  hardware.nvidia = true;
  hardware.gamepad = true;
};
```

**Apply:**
```bash
home-manager switch --flake ~/git/home
```

**Tools**: `steam`, `steam-fps`, `gamemode-status`

---

### 6. Backup Monitoring (`backup.nix`)

**Already included when backup module enabled:**

```nix
# Backup module auto-generates check-backups script
# Just configure rclone and enable timers
```

**Tools**: `check-backups`, `backup-status`, `backup-now`, `backup-verify`

---

## Complete Example Configuration

```nix
# home/home.nix (after all modules imported)
{
  # Laptop power management
  programs.power.enable = true;
  
  # Auto-updates
  programs.autoUpdates.enable = true;
  
  # Secure DNS
  programs.network = {
    enable = true;
    dns.provider = "quad9";
  };
  
  # Docker utilities
  programs.docker.utilities = {
    enable = true;
    autoPrune = true;
  };
  
  # Gaming (drone training)
  programs.gaming = {
    enable = true;
    performance.gamemode = true;
    performance.mangohud = true;
  };
  
  # Existing modules work as before...
}
```

**Apply everything:**
```bash
home-manager switch --flake ~/git/home

# Then install system-level configs (one-time):
install-auto-updates    # Auto-updates timer
install-secure-dns      # DNS-over-TLS
install-docker-prune    # Docker cleanup
```

---

## Benefits Over Scripts

### Before (Bash Scripts)
```bash
# User must remember to run:
./scripts/setup-laptop-power.sh
./scripts/setup-auto-updates.sh
./scripts/setup-secure-dns.sh
./scripts/check-backups.sh
# etc...
```

### After (Declarative Nix)
```nix
# User enables in home.nix:
programs.power.enable = true;
programs.autoUpdates.enable = true;
programs.network.enable = true;

# Run once:
home-manager switch
```

✅ **Reproducible** - Same config on any machine  
✅ **Version controlled** - All in Git  
✅ **Easy rollback** - `home-manager rollback`  
✅ **Customizable** - Edit options in home.nix  
✅ **Self-documenting** - Options have descriptions

---

## Remaining Scripts (Valid Reasons)

These scripts **should stay** as interactive/one-time setup tools:

- **firstrun-user.sh** - Main setup wizard (Layer 3)
- **setup-docker.sh** - One-time Docker install
- **docker-nvidia-*.sh** - GPU container setup
- **setup-rclone.sh** - Interactive cloud wizard
- **setup-synergy.sh** - Requires license file
- **setup-winapps.sh** - Complex Docker VM setup
- **setup-chrome.sh** - Proprietary repo
- **setup-firewall.sh** - Network-specific config
- **setup-protonmail-bridge.sh** - Interactive setup

---

## Migration Checklist

If you were using the old scripts:

- [x] Phase 1: Power, shell, keyboard → Nix modules
- [x] Phase 2: Auto-updates, DNS, Docker utils, backups → Nix modules
- [ ] Update your `home.nix` to enable new modules
- [ ] Run `home-manager switch`
- [ ] Install system-wide configs with helper scripts
- [ ] Test each feature
- [ ] Remove old script bookmarks/aliases

---

**Total Consolidation**: 20 scripts → 10 scripts (50% reduction!)  
**New Nix modules**: 7 (power, auto-updates, network, docker, gaming, and extended backup, thunderbird)

Ready to deploy! 🚀
