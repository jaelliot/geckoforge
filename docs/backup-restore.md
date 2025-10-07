# Backup & Restore Strategy

## What to Backup

### Critical (daily)
- `/home/$USER` (your data)
  - Exclude: `.cache/`, `.local/share/flatpak/`, `.local/share/containers/`
- Git repos with config
  - `~/git/home` (Home-Manager flake)
  - `~/git/geckoforge` (if you've customized the ISO)

### Important (weekly)
- `/etc` (system configs)
- Snapper snapshots metadata (for reference)

### Not needed (reproducible)
- `/nix` - Rebuild from `flake.lock`
- Container images - Re-pull from registry
- Flatpak runtimes - Re-download on restore

## Backup Tools

### Option 1: Restic (recommended)

**Setup**:
```bash
# Install
sudo zypper install restic

# Initialize repo (local external drive)
restic init --repo /mnt/backup/restic

# Or cloud (example: B2)
restic init --repo b2:bucketname:path
```

**Backup script** (`~/bin/backup.sh`):
```bash
#!/bin/bash
set -euo pipefail

REPO="/mnt/backup/restic"
export RESTIC_PASSWORD_FILE=~/.config/restic/password

restic -r "$REPO" backup \
  --exclude-file ~/.config/restic/excludes \
  /home/$USER

# Prune old snapshots
restic -r "$REPO" forget \
  --keep-daily 7 \
  --keep-weekly 4 \
  --keep-monthly 6 \
  --prune
```

**Exclude file** (`~/.config/restic/excludes`):
```
.cache/
.local/share/flatpak/
.local/share/containers/
.local/share/Trash/
node_modules/
.venv/
__pycache__/
```

**Restore**:
```bash
# List snapshots
restic -r /mnt/backup/restic snapshots

# Restore specific snapshot
restic -r /mnt/backup/restic restore latest --target /tmp/restore

# Restore specific file
restic -r /mnt/backup/restic restore latest \
  --target /tmp \
  --include /home/$USER/Documents/important.txt
```

### Option 2: Borg

Similar to restic but with deduplication. See [Borg docs](https://borgbackup.readthedocs.io/).

## Automated Backups

**Systemd timer** (`~/.config/systemd/user/backup.service`):
```ini
[Unit]
Description=Daily backup

[Service]
Type=oneshot
ExecStart=%h/bin/backup.sh
```

**Timer** (`~/.config/systemd/user/backup.timer`):
```ini
[Unit]
Description=Daily backup timer

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
```

**Enable**:
```bash
systemctl --user enable --now backup.timer
```

## Recovery Scenarios

### Scenario 1: Restore single file
```bash
restic -r /mnt/backup/restic restore latest \
  --include /home/$USER/.vimrc \
  --target /tmp
cp /tmp/home/$USER/.vimrc ~/
```

### Scenario 2: Full home directory restore
```bash
# On fresh install, after first-boot scripts
restic -r /mnt/backup/restic restore latest --target /
# Or specific snapshot: restic -r ... restore <snapshot-id> --target /
```

### Scenario 3: Disaster recovery (bare metal)
1. Reinstall from geckoforge ISO
2. Run firstrun-user.sh
3. Restore home: `restic restore latest --target /`
4. Rebuild Nix: `home-manager switch --flake ~/git/home`
5. Verify: check critical files, re-login to sync services
