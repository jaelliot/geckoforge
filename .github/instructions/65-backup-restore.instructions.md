---
applyTo: "scripts/*backup*.sh,home/modules/*backup*.nix,.rclone.conf"
---

---
description: Backup strategies with rclone encryption, external HDDs, and future onsite server
alwaysApply: false
version: 0.3.0
---

## Use when
- Setting up backup infrastructure
- Performing backups or restores
- Planning disaster recovery
- Configuring rclone for offsite backups

## Backup Philosophy

**3-2-1 Rule: 3 copies, 2 media types, 1 offsite**

- **Local**: Multiple external HDDs (rotating)
- **Config**: Git repository (geckoforge)
- **Offsite**: Encrypted rclone (cloud storage)
- **Future**: Onsite backup server (NAS)

---

## Backup Tiers

### Tier 1: Critical (Daily/Weekly)
- Git repositories (`~/git/`)
- IDE configurations (VS Code, Cursor, Kiro, Void)
- SSH keys (`~/.ssh/`)
- GPG keys (`~/.gnupg/`)
- Browser profiles (bookmarks, passwords via Bitwarden)
- Documents (`~/Documents/`)
- Configuration files (`~/.config/`, `~/.local/`)

### Tier 2: Important (Weekly/Monthly)
- Projects in progress (`~/projects/`)
- Database dumps
- Docker volumes (if any persistent data)
- Virtual machines (if any)

### Tier 3: Archival (Monthly/Quarterly)
- Old projects
- Media files (photos, videos)
- Large datasets
- Historical snapshots

---

## Configuration Backup (Git)

### Already Handled
- ✅ geckoforge repository (ISO builder)
- ✅ home/ directory (Home-Manager config)
- ✅ scripts/ (user setup scripts)
- ✅ docs/ (documentation)

### Best Practice
```bash
# Daily workflow
cd ~/git/geckoforge
git add .
git commit -m "config: update X"
git push

# Automatic via cron (future)
# See automation section below
```

---

## External HDD Backup

### Setup (Layer 3: User Setup)

#### HDD Preparation
```bash
# scripts/setup-backup-hdd.sh
#!/usr/bin/env bash
set -euo pipefail

echo "[backup] Preparing external HDD..."

# Identify HDD
lsblk
read -p "Enter device (e.g., sdb): " DEVICE

# Format with LUKS encryption
sudo cryptsetup luksFormat "/dev/$DEVICE" --type luks2

# Open encrypted volume
sudo cryptsetup open "/dev/$DEVICE" backup-hdd

# Create filesystem
sudo mkfs.btrfs /dev/mapper/backup-hdd

# Create mount point
sudo mkdir -p /mnt/backup

# Mount
sudo mount /dev/mapper/backup-hdd /mnt/backup

# Set ownership
sudo chown "$USER:$USER" /mnt/backup

echo "[backup] HDD prepared and mounted at /mnt/backup"
```

#### Backup Script
```bash
# scripts/backup-to-hdd.sh
#!/usr/bin/env bash
set -euo pipefail

BACKUP_ROOT="/mnt/backup"
DATE=$(date +%Y-%m-%d)
BACKUP_DIR="$BACKUP_ROOT/geckoforge-$DATE"

echo "[backup] Starting backup to $BACKUP_DIR..."

# Create timestamped backup directory
mkdir -p "$BACKUP_DIR"

# Tier 1: Critical files
echo "[backup] Backing up critical files..."
rsync -av --progress \
  ~/git/ \
  ~/.ssh/ \
  ~/.gnupg/ \
  ~/Documents/ \
  ~/.config/ \
  ~/.local/ \
  "$BACKUP_DIR/critical/"

# Tier 2: Important files
echo "[backup] Backing up important files..."
if [ -d ~/projects ]; then
  rsync -av --progress ~/projects/ "$BACKUP_DIR/projects/"
fi

# Create manifest
echo "[backup] Creating backup manifest..."
find "$BACKUP_DIR" -type f > "$BACKUP_DIR/MANIFEST.txt"
du -sh "$BACKUP_DIR" >> "$BACKUP_DIR/MANIFEST.txt"
date >> "$BACKUP_DIR/MANIFEST.txt"

echo "[backup] Backup complete: $BACKUP_DIR"
echo "Files: $(wc -l < "$BACKUP_DIR/MANIFEST.txt")"
echo "Size: $(du -sh "$BACKUP_DIR" | cut -f1)"
```

### HDD Rotation Strategy
```bash
# Multiple HDDs with rotation
# HDD-1: Weekly full backup
# HDD-2: Monthly full backup
# HDD-3: Quarterly archive backup

# Label HDDs clearly:
# "GECKOFORGE-WEEKLY"
# "GECKOFORGE-MONTHLY" 
# "GECKOFORGE-ARCHIVE"
```

---

## Offsite Backup (rclone)

### Installation (Layer 4: Home-Manager)
```nix
# home/modules/backup.nix
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    rclone
    age  # For additional encryption
  ];

  # rclone config will be in ~/.config/rclone/rclone.conf
  home.file.".config/rclone/.keep".text = "";
}
```

### Cloud Storage Setup
```bash
# scripts/setup-rclone.sh
#!/usr/bin/env bash
set -euo pipefail

echo "[rclone] Setting up encrypted cloud storage..."

# Configure rclone interactively
rclone config

# Test connection
echo "[rclone] Testing connection..."
rclone lsd remote:

echo "[rclone] Setup complete"
echo "Config stored in ~/.config/rclone/rclone.conf"
```

### Encrypted Backup Script
```bash
# scripts/backup-to-cloud.sh
#!/usr/bin/env bash
set -euo pipefail

REMOTE="remote:geckoforge-backups"
DATE=$(date +%Y-%m-%d)
LOCAL_BACKUP="/tmp/geckoforge-backup-$DATE"

echo "[rclone] Creating encrypted backup..."

# Create temporary backup
mkdir -p "$LOCAL_BACKUP"

# Critical files only (small, frequent)
tar -czf "$LOCAL_BACKUP/critical-$DATE.tar.gz" \
  ~/git/geckoforge \
  ~/.ssh \
  ~/.gnupg

# Encrypt with age (additional layer)
age -r "$(cat ~/.age/public.key)" \
  "$LOCAL_BACKUP/critical-$DATE.tar.gz" > \
  "$LOCAL_BACKUP/critical-$DATE.tar.gz.age"

# Upload to cloud (already encrypted by rclone crypt)
rclone copy "$LOCAL_BACKUP/critical-$DATE.tar.gz.age" "$REMOTE/"

# Cleanup
rm -rf "$LOCAL_BACKUP"

echo "[rclone] Backup uploaded to $REMOTE/critical-$DATE.tar.gz.age"
```

### Restore Script
```bash
# scripts/restore-from-cloud.sh
#!/usr/bin/env bash
set -euo pipefail

REMOTE="remote:geckoforge-backups"

echo "[rclone] Available backups:"
rclone ls "$REMOTE" | grep critical

read -p "Enter backup filename: " BACKUP_FILE
read -p "Restore to directory: " RESTORE_DIR

# Download
rclone copy "$REMOTE/$BACKUP_FILE" "/tmp/"

# Decrypt
age -d -i ~/.age/private.key "/tmp/$BACKUP_FILE" > "/tmp/${BACKUP_FILE%.age}"

# Extract
mkdir -p "$RESTORE_DIR"
tar -xzf "/tmp/${BACKUP_FILE%.age}" -C "$RESTORE_DIR"

echo "[rclone] Restored to $RESTORE_DIR"
```

---

## Future: Onsite Server Backup

### Planned Architecture
```
Workstation → Onsite NAS → Offsite Cloud
    ↓            ↓            ↓
  Hourly       Daily       Weekly
  Snapshots    Sync        Archive
```

### NAS Requirements
- **Hardware**: Mini PC with 4+ drive bays
- **OS**: NixOS or TrueNAS
- **Storage**: Btrfs or ZFS with redundancy
- **Network**: Gigabit LAN, VPN access
- **Services**: SSH, rclone, Syncthing

### Implementation (Future)
```bash
# scripts/setup-nas-sync.sh (future)
#!/usr/bin/env bash
set -euo pipefail

NAS_HOST="nas.local"
NAS_USER="backup"

echo "[nas] Setting up onsite NAS sync..."

# Install Syncthing for continuous sync
sudo zypper install -y syncthing

# Configure for critical directories
# ~/git/ → NAS → Cloud (continuous)
# ~/Documents/ → NAS → Cloud (hourly)
# ~/projects/ → NAS (daily)

echo "[nas] Setup complete"
```

---

## Backup Automation

### Systemd Timers (Layer 3: User Setup)

#### Daily Backup Timer
```bash
# scripts/install-backup-timers.sh
#!/usr/bin/env bash
set -euo pipefail

echo "[backup] Installing backup automation..."

# Create systemd user service
mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/backup-daily.service <<EOF
[Unit]
Description=Daily backup to external HDD
After=network.target

[Service]
Type=oneshot
ExecStart=$HOME/git/geckoforge/scripts/backup-to-hdd.sh
User=%i

[Install]
WantedBy=default.target
EOF

cat > ~/.config/systemd/user/backup-daily.timer <<EOF
[Unit]
Description=Run daily backup
Requires=backup-daily.service

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Enable timer
systemctl --user daemon-reload
systemctl --user enable backup-daily.timer
systemctl --user start backup-daily.timer

echo "[backup] Daily backup timer installed"
systemctl --user status backup-daily.timer
```

#### Weekly Cloud Backup Timer
```bash
cat > ~/.config/systemd/user/backup-cloud.service <<EOF
[Unit]
Description=Weekly backup to cloud storage
After=network.target

[Service]
Type=oneshot
ExecStart=$HOME/git/geckoforge/scripts/backup-to-cloud.sh
User=%i

[Install]
WantedBy=default.target
EOF

cat > ~/.config/systemd/user/backup-cloud.timer <<EOF
[Unit]
Description=Run weekly cloud backup
Requires=backup-cloud.service

[Timer]
OnCalendar=weekly
Persistent=true

[Install]
WantedBy=timers.target
EOF
```

---

## Monitoring and Verification

### Backup Health Check
```bash
# scripts/backup-health-check.sh
#!/usr/bin/env bash
set -euo pipefail

echo "[backup] Health check starting..."

# Check HDD availability
if [ -d "/mnt/backup" ]; then
  echo "✅ External HDD mounted"
  echo "   Free space: $(df -h /mnt/backup | tail -1 | awk '{print $4}')"
else
  echo "❌ External HDD not mounted"
fi

# Check recent backups
LATEST_HDD=$(find /mnt/backup -name "geckoforge-*" -type d | sort | tail -1)
if [ -n "$LATEST_HDD" ]; then
  echo "✅ Latest HDD backup: $(basename "$LATEST_HDD")"
else
  echo "❌ No HDD backups found"
fi

# Check cloud connectivity
if rclone lsd remote: >/dev/null 2>&1; then
  echo "✅ Cloud storage accessible"
  LATEST_CLOUD=$(rclone ls remote:geckoforge-backups | tail -1 | awk '{print $2}')
  echo "   Latest cloud backup: $LATEST_CLOUD"
else
  echo "❌ Cloud storage not accessible"
fi

# Check git status
cd ~/git/geckoforge
if git status --porcelain | grep -q .; then
  echo "⚠️  Uncommitted changes in geckoforge"
  git status --short
else
  echo "✅ Git repository clean"
fi

echo "[backup] Health check complete"
```

### Recovery Testing
```bash
# scripts/test-backup-recovery.sh
#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="/tmp/backup-recovery-test"
mkdir -p "$TEST_DIR"

echo "[backup] Testing recovery procedures..."

# Test HDD recovery
if [ -d "/mnt/backup" ]; then
  LATEST_BACKUP=$(find /mnt/backup -name "geckoforge-*" -type d | sort | tail -1)
  if [ -n "$LATEST_BACKUP" ]; then
    echo "Testing HDD recovery from $LATEST_BACKUP"
    rsync -av "$LATEST_BACKUP/critical/git/" "$TEST_DIR/hdd-recovery/"
    echo "✅ HDD recovery test successful"
  fi
fi

# Test cloud recovery (if configured)
if command -v rclone >/dev/null 2>&1; then
  LATEST_CLOUD=$(rclone ls remote:geckoforge-backups | grep critical | tail -1 | awk '{print $2}')
  if [ -n "$LATEST_CLOUD" ]; then
    echo "Testing cloud recovery from $LATEST_CLOUD"
    rclone copy "remote:geckoforge-backups/$LATEST_CLOUD" "$TEST_DIR/"
    echo "✅ Cloud recovery test successful"
  fi
fi

# Cleanup
rm -rf "$TEST_DIR"
echo "[backup] Recovery tests complete"
```

---

## Best Practices

### Security
- ✅ Encrypt all external storage (LUKS2)
- ✅ Encrypt cloud backups (rclone crypt + age)
- ✅ Store encryption keys separately
- ✅ Test recovery procedures regularly

### Performance
- ✅ Use rsync for incremental backups
- ✅ Compress archives before cloud upload
- ✅ Schedule backups during off-hours
- ✅ Monitor backup storage usage

### Reliability
- ✅ Multiple backup destinations (3-2-1 rule)
- ✅ Verify backup integrity regularly
- ✅ Document recovery procedures
- ✅ Practice disaster recovery scenarios

### Automation
- ✅ Use systemd timers for scheduling
- ✅ Send notifications on failure
- ✅ Log all backup operations
- ✅ Monitor backup health automatically

## Implementation Checklist

### Phase 1: Basic Setup
- [ ] Install rclone via Home-Manager
- [ ] Configure external HDD encryption
- [ ] Create basic backup scripts
- [ ] Test manual backup/restore

### Phase 2: Automation
- [ ] Install systemd timers
- [ ] Configure cloud storage
- [ ] Set up backup monitoring
- [ ] Create health check scripts

### Phase 3: Advanced Features
- [ ] Plan onsite NAS deployment
- [ ] Implement continuous sync
- [ ] Add backup verification
- [ ] Create disaster recovery docs

## Notes

### Cost Considerations
- External HDDs: ~$50-100 each (need 2-3)
- Cloud storage: ~$5-10/month for 100GB
- Future NAS: ~$300-500 for basic setup

### Storage Requirements
- Critical files: ~1-5GB
- Development projects: ~10-50GB
- Full system backup: ~100-500GB

### Rotation Schedule
- **Daily**: Git commits (automatic)
- **Weekly**: External HDD backup
- **Monthly**: Cloud backup + HDD rotation
- **Quarterly**: Archive backup + verification