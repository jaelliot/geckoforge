# Encrypted Cloud Backup and Recovery

Complete guide for Geckoforge's rclone-based encrypted backup system.

## Overview

The backup system provides zero-knowledge encrypted cloud storage for DevOps engineers working with infrastructure code, configurations, and sensitive data. All backups are encrypted client-side before uploading to cloud providers.

### Key Features

- **Zero-knowledge encryption**: Your data is encrypted before leaving your machine
- **Multi-strategy backups**: Critical daily, projects weekly, infrastructure monthly
- **Automated scheduling**: systemd timers handle automatic backups
- **Health monitoring**: Built-in verification and alerting
- **Multi-cloud support**: Google Drive, AWS S3, Backblaze B2, OneDrive
- **Declarative configuration**: Everything managed via Home-Manager

## Security Model

### Encryption

All data is encrypted using **AES-256** with:
- **Encryption password**: Encrypts file contents and names
- **Salt password**: Additional entropy for key derivation
- **Standard filename encryption**: Obscures file/directory names
- **Directory name encryption**: Hides folder structure

**Critical**: If you lose these passwords, your data is **permanently unrecoverable**.

### What Gets Backed Up

#### Critical Backup (Daily)
```
~/.ssh/                    # SSH keys and configurations
~/.gnupg/                  # GPG keys and settings
~/.aws/                    # AWS credentials and config
~/.kube/                   # Kubernetes configurations
~/.docker/                 # Docker configurations
~/Documents/               # Important documents
~/.local/share/password-store/  # Pass password store
~/.config/rclone/          # Rclone configurations (encrypted)
```

#### Projects Backup (Weekly)
```
~/git/                     # All Git repositories
~/projects/                # Active project files
~/workspace/               # Development workspaces
~/.config/Code/            # VS Code settings and extensions
```

#### Infrastructure Backup (Monthly)
```
/etc/nixos/                # NixOS system configuration
~/.nixpkgs/                # Nix user configuration
~/infrastructure/          # Infrastructure as Code
~/ansible/                 # Ansible playbooks
~/terraform/               # Terraform configurations
```

### What Gets Excluded

- **Large binaries**: `node_modules/`, `.git/objects/`, build artifacts
- **Temporary files**: `*.tmp`, `*.cache`, `.DS_Store`
- **Sensitive runtime**: Active tokens, temporary credentials
- **Virtual environments**: Python venv, Docker containers
- **Media files**: Videos, ISOs, large downloads

## Quick Start

### 1. Initial Setup

```bash
# Enable backup module (already done in home.nix)
cd ~/git/home
home-manager switch --flake .

# Configure cloud provider and encryption
~/git/geckoforge/scripts/setup-rclone.sh

# Test configuration
~/git/geckoforge/scripts/check-backups.sh --test
```

### 2. Enable Automated Backups

```bash
# Enable daily critical backups
systemctl --user enable --now rclone-backup-critical.timer

# Enable weekly project backups
systemctl --user enable --now rclone-backup-projects.timer

# Optional: Enable monthly infrastructure backups
systemctl --user enable --now rclone-backup-infra.timer
```

### 3. Verify Operation

```bash
# Check timer status
systemctl --user list-timers

# Run health check
~/git/geckoforge/scripts/check-backups.sh -v

# Manual backup test
systemctl --user start rclone-backup-critical.service
journalctl --user -u rclone-backup-critical.service -f
```

## Cloud Provider Setup

### Google Drive (Recommended for Personal Use)

**Pros**: 15GB free, familiar interface, good reliability  
**Cons**: Google has access to metadata, limited free storage

```bash
# Run setup wizard
~/git/geckoforge/scripts/setup-rclone.sh

# Select Google Drive when prompted
# Follow OAuth flow in browser
# Create encrypted wrapper: gdrive-crypt
```

### AWS S3 (Recommended for Professional Use)

**Pros**: Pay-as-you-go, enterprise-grade, many regions  
**Cons**: More complex setup, costs money

```bash
# Prerequisites: AWS account, bucket created, IAM user with S3 access

# Get credentials from AWS Console
AWS_ACCESS_KEY_ID="AKIA..."
AWS_SECRET_ACCESS_KEY="..."
BUCKET_NAME="my-backup-bucket"
REGION="us-west-2"

# Run setup wizard and provide these details
~/git/geckoforge/scripts/setup-rclone.sh
```

### Backblaze B2 (Cost-Effective Alternative)

**Pros**: Cheaper than S3, simple pricing, good performance  
**Cons**: Smaller company, fewer regions

```bash
# Prerequisites: Backblaze account, bucket created, app key

APPLICATION_KEY_ID="..."
APPLICATION_KEY="..."
BUCKET_NAME="my-backup-bucket"

# Configure via setup wizard
~/git/geckoforge/scripts/setup-rclone.sh
```

## Manual Operations

### Immediate Backup

```bash
# Backup critical files now
systemctl --user start rclone-backup-critical.service

# Backup specific directory
rclone sync ~/Documents/ gdrive-crypt:critical/Documents/ \
  --filter-from ~/.config/rclone/critical-filters.txt \
  --progress --stats 30s

# Backup with custom filters
echo "- *.tmp" | rclone sync ~/project/ gdrive-crypt:manual/project/ \
  --filter-from - --progress
```

### File Recovery

```bash
# List available backups
rclone ls gdrive-crypt:critical/ | head -20

# Restore specific file
rclone copy gdrive-crypt:critical/ssh/id_ed25519 ~/.ssh/

# Restore entire directory
rclone sync gdrive-crypt:projects/git/myproject/ ~/git/myproject/ \
  --progress --stats 30s

# Browse backups interactively
rclone mount gdrive-crypt: /tmp/backup-mount &
ls /tmp/backup-mount/
fusermount -u /tmp/backup-mount
```

### Emergency Recovery

If your system is completely lost:

```bash
# 1. Install rclone on new system
curl https://rclone.org/install.sh | sudo bash

# 2. Recreate base remote (Google Drive, S3, etc.)
rclone config create mycloud googledrive

# 3. Recreate encrypted remote with SAME passwords
rclone config create mycloud-crypt crypt \
  remote mycloud:encrypted-backup \
  filename_encryption standard \
  directory_name_encryption true
# Enter same encryption passwords!

# 4. Verify access
rclone ls mycloud-crypt:critical/ | head -10

# 5. Restore critical files
rclone sync mycloud-crypt:critical/ssh/ ~/.ssh/
rclone sync mycloud-crypt:critical/gnupg/ ~/.gnupg/
chmod 600 ~/.ssh/id_* ~/.gnupg/*
```

## Configuration

### Backup Filters

Filter files control what gets backed up. Located in `~/.config/rclone/`:

#### Critical Filters (`critical-filters.txt`)
```
# SSH keys and config
+ .ssh/**
+ .gnupg/**

# Cloud credentials
+ .aws/**
+ .kube/**

# Password management
+ .local/share/password-store/**

# Documents
+ Documents/**

# Exclude common cruft
- **/.git/objects/**
- **/node_modules/**
- **/*.tmp
- **/.cache/**
```

#### Project Filters (`projects-filters.txt`)
```
# Source code repositories
+ git/**
+ projects/**
+ workspace/**

# Development configs
+ .config/Code/**
+ .vscode/**

# Exclude build artifacts
- **/build/**
- **/dist/**
- **/target/**
- **/.next/**
- **/node_modules/**
```

### Customizing Backup Targets

Edit `~/git/home/modules/backup.nix`:

```nix
# Change remote name
REMOTE="my-s3-crypt";

# Modify backup paths for critical backup
--include-from ${config.home.homeDirectory}/.config/rclone/critical-filters.txt \
${config.home.homeDirectory}/my-custom-docs \
```

Then apply changes:
```bash
cd ~/git/home
home-manager switch --flake .
systemctl --user daemon-reload
```

### Schedule Customization

Timers use systemd calendar format. Edit in `backup.nix`:

```nix
# Daily at 2 AM
OnCalendar = "02:00";

# Every 6 hours
OnCalendar = "*-*-* 00,06,12,18:00:00";

# Weekdays at 9 AM
OnCalendar = "Mon-Fri 09:00";

# Monthly on 1st at midnight
OnCalendar = "monthly";
```

## Monitoring and Alerting

### Health Checks

```bash
# Basic health check
~/git/geckoforge/scripts/check-backups.sh

# Verbose output
~/git/geckoforge/scripts/check-backups.sh -v

# Test backup/restore cycle
~/git/geckoforge/scripts/check-backups.sh --test

# Attempt to fix issues
~/git/geckoforge/scripts/check-backups.sh --fix
```

### Log Analysis

```bash
# View recent backup logs
ls -la ~/.local/share/rclone/logs/

# Follow critical backup in real-time
tail -f ~/.local/share/rclone/logs/critical-$(date +%Y%m%d).log

# Check for errors in last backup
grep -i "error\|failed" ~/.local/share/rclone/logs/critical-*.log | tail -10

# Service status
systemctl --user status rclone-backup-critical.service
journalctl --user -u rclone-backup-critical.service --since yesterday
```

### Integration with Monitoring Systems

#### Prometheus Metrics (Optional)

Add to `backup.nix` for metrics exposure:

```nix
# Add to systemd service
ExecStartPost = ''${pkgs.writeScript "backup-metrics" '''
  #!/bin/bash
  echo "backup_success{type=\"critical\"} 1" > /tmp/backup-metrics.prom
  echo "backup_duration_seconds{type=\"critical\"} $SECONDS" >> /tmp/backup-metrics.prom
'''}'';
```

#### Email Notifications

For backup failures, add to service:

```nix
OnFailure = "backup-notify-failure@%i.service";
```

## Troubleshooting

### Common Issues

#### "Remote not found"
```bash
# Check configured remotes
rclone listremotes

# Verify remote works
rclone ls myremote: --max-depth 1

# Reconfigure if needed
rclone config
```

#### "Authentication failed"
```bash
# Re-authenticate (Google Drive, OneDrive)
rclone config reconnect myremote:

# Check credentials (S3, B2)
rclone config show myremote
```

#### "Permission denied"
```bash
# Fix rclone config permissions
chmod 600 ~/.config/rclone/rclone.conf

# Fix backup directory permissions
chmod 700 ~/.local/share/rclone
```

#### "Backup service failed"
```bash
# Check service status
systemctl --user status rclone-backup-critical.service

# View recent logs
journalctl --user -u rclone-backup-critical.service -n 50

# Reset failed service
systemctl --user reset-failed rclone-backup-critical.service
systemctl --user start rclone-backup-critical.service
```

### Performance Issues

#### Slow uploads
```bash
# Check transfer speeds
rclone sync ~/test/ myremote:test/ --progress --stats 10s

# Increase parallelism
rclone sync ~/Documents/ myremote:backup/ --transfers 8 --checkers 16

# Use compression for text files
rclone sync ~/Documents/ myremote:backup/ --compress
```

#### High memory usage
```bash
# Reduce memory for large syncs
rclone sync ~/large-folder/ myremote:backup/ --buffer-size 16M

# Process files individually
find ~/Documents -type f -exec rclone copy {} myremote:backup/Documents/ \;
```

### Data Recovery Issues

#### "File appears corrupted"
```bash
# Verify rclone config integrity
rclone config show

# Test with known good file
echo "test" | rclone rcat myremote-crypt:test.txt
rclone cat myremote-crypt:test.txt

# Check for multiple versions
rclone ls myremote-crypt: --max-age 30d | grep filename
```

#### "Cannot decrypt"
```bash
# Verify you're using correct passwords
rclone config

# Try alternative decrypt method
rclone mount myremote-crypt: /tmp/mount --read-only
```

## Best Practices

### Security

1. **Store passwords securely**
   - Use a password manager (Bitwarden, 1Password)
   - Never commit passwords to Git
   - Consider hardware security keys for 2FA

2. **Regular testing**
   ```bash
   # Monthly recovery test
   ~/git/geckoforge/scripts/check-backups.sh --test
   
   # Verify critical files can be restored
   rclone copy myremote-crypt:critical/ssh/config /tmp/test-restore/
   ```

3. **Multiple backup destinations**
   ```bash
   # Configure second remote for redundancy
   rclone config create backup2 s3 # or other provider
   rclone config create backup2-crypt crypt remote backup2:encrypted
   
   # Sync to both remotes
   rclone sync myremote-crypt: backup2-crypt:
   ```

### Performance

1. **Optimize sync frequency**
   - Critical: Daily (small, important files)
   - Projects: Weekly (larger, but important for work)
   - Infrastructure: Monthly (infrequent changes)

2. **Monitor storage costs**
   ```bash
   # Check storage usage
   rclone size myremote-crypt:
   
   # Clean up old backups
   rclone delete myremote-crypt:old-backups/
   ```

3. **Use appropriate regions**
   - Choose geographically close cloud regions
   - Consider data residency requirements

### Disaster Recovery

1. **Document your setup**
   - Keep provider credentials secure but accessible
   - Document encryption passwords location
   - Test recovery procedures annually

2. **Offline backups**
   ```bash
   # Additional local backup to external drive
   rclone sync ~/Documents/ /media/backup-drive/Documents/
   ```

3. **Cross-platform compatibility**
   - Test restoring on different OS (Windows, macOS)
   - Verify rclone works on target recovery systems

## Integration with Geckoforge

### Home-Manager Integration

The backup system is fully integrated with Geckoforge's Home-Manager configuration:

```nix
# home/modules/backup.nix provides:
# - rclone package installation
# - systemd services and timers
# - backup filter templates
# - logging configuration
# - directory structure
```

### Layer Architecture Compliance

Following Geckoforge's 4-layer architecture:

- **Layer 1 (ISO)**: Base system, no backup components
- **Layer 2 (First-boot)**: Nix installation (enables Home-Manager)
- **Layer 3 (User setup)**: rclone initial configuration via scripts
- **Layer 4 (Home-Manager)**: Automated backup services and configuration

### Development Workflow

```bash
# 1. Modify backup configuration
$EDITOR ~/git/home/modules/backup.nix

# 2. Apply changes
cd ~/git/home
home-manager switch --flake .

# 3. Reload systemd services
systemctl --user daemon-reload

# 4. Test changes
~/git/geckoforge/scripts/check-backups.sh --test

# 5. Commit changes
git add modules/backup.nix
git commit -m "backup: update configuration"
```

## See Also

- [Rclone Documentation](https://rclone.org/docs/)
- [Geckoforge Architecture](../architecture/README.md)
- [Home-Manager Guide](../home-manager.md)
- [Security Best Practices](../security.md)