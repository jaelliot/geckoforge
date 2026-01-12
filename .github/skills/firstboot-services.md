# First-Boot Services Skill

## Purpose
Configure systemd first-boot services correctly with proper dependencies and ordering.

## Service Chain

```
multi-user.target
    │
    ├── geckoforge-firstboot.service (NVIDIA driver)
    │       After=network-online.target
    │       Wants=network-online.target
    │
    ├── geckoforge-nix.service (Nix multi-user)
    │       After=geckoforge-firstboot.service
    │       After=network-online.target
    │
    └── geckoforge-ssh-hardening.service
            After=network-online.target
            After=sshd.service
```

## Correct Service File Template

```ini
# /etc/systemd/system/geckoforge-firstboot.service
[Unit]
Description=geckoforge First Boot NVIDIA Driver Installation
After=network-online.target
Wants=network-online.target
ConditionPathExists=!/var/lib/geckoforge/.firstboot-nvidia-done

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/sbin/firstboot-nvidia.sh
ExecStartPost=/usr/bin/touch /var/lib/geckoforge/.firstboot-nvidia-done
StandardOutput=journal+console
StandardError=journal+console

[Install]
WantedBy=multi-user.target
```

## Common Service Errors

### ❌ ERROR: Service runs on every boot
**Problem:** Service runs repeatedly, not just on first boot
```ini
# WRONG - no condition
[Unit]
Description=First boot setup

[Service]
ExecStart=/usr/local/sbin/firstboot.sh
```

**Fix:** Add ConditionPathExists to make it one-shot
```ini
# CORRECT - runs only if marker doesn't exist
[Unit]
Description=First boot setup
ConditionPathExists=!/var/lib/geckoforge/.firstboot-done

[Service]
ExecStart=/usr/local/sbin/firstboot.sh
ExecStartPost=/usr/bin/touch /var/lib/geckoforge/.firstboot-done
```

### ❌ ERROR: Service fails before network
**Problem:** Downloads fail because network isn't ready
```ini
# WRONG - no network dependency
[Unit]
Description=Install NVIDIA drivers
```

**Fix:** Wait for network-online.target
```ini
# CORRECT
[Unit]
Description=Install NVIDIA drivers
After=network-online.target
Wants=network-online.target
```

### ❌ ERROR: Services run in wrong order
**Problem:** Nix tries to install before NVIDIA drivers complete
```ini
# WRONG - no ordering between services
[Unit]
Description=Install Nix
```

**Fix:** Add explicit ordering
```ini
# CORRECT
[Unit]
Description=Install Nix
After=geckoforge-firstboot.service
After=network-online.target
```

### ❌ ERROR: Symlink in multi-user.target.wants is a file
**Problem:** Service won't enable because it's a copy, not a symlink
```bash
# WRONG - file instead of symlink
-rw-r--r-- geckoforge-firstboot.service

# CORRECT - symlink
lrwxrwxrwx geckoforge-firstboot.service -> ../geckoforge-firstboot.service
```

**Fix in profile/root/:**
```bash
cd profile/root/etc/systemd/system/multi-user.target.wants/
rm geckoforge-firstboot.service
ln -s ../geckoforge-firstboot.service .
```

## First-Boot Script Template

```bash
#!/usr/bin/env bash
# /usr/local/sbin/firstboot-nvidia.sh
set -euo pipefail

LOG_FILE="/var/log/geckoforge-firstboot.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=== geckoforge NVIDIA First Boot: $(date) ==="

# Detect NVIDIA GPU
if lspci | grep -qi 'VGA.*NVIDIA\|3D.*NVIDIA'; then
    echo "NVIDIA GPU detected, installing drivers..."
    
    # Refresh repos
    zypper --non-interactive refresh
    
    # Install NVIDIA drivers (signed for Secure Boot)
    zypper --non-interactive install \
        nvidia-open-driver-G06-signed-kmp-default \
        nvidia-gl-G06 \
        nvidia-compute-utils-G06
    
    echo "NVIDIA drivers installed successfully"
else
    echo "No NVIDIA GPU detected, skipping driver installation"
fi

echo "=== First boot complete: $(date) ==="
```

## Directory Structure

```
profile/root/
├── etc/systemd/system/
│   ├── geckoforge-firstboot.service
│   ├── geckoforge-nix.service
│   ├── geckoforge-ssh-hardening.service
│   └── multi-user.target.wants/
│       ├── geckoforge-firstboot.service -> ../geckoforge-firstboot.service
│       ├── geckoforge-nix.service -> ../geckoforge-nix.service
│       └── geckoforge-ssh-hardening.service -> ../geckoforge-ssh-hardening.service
├── usr/local/sbin/
│   ├── firstboot-nvidia.sh
│   ├── firstboot-nix.sh
│   └── firstboot-ssh-hardening.sh
└── var/lib/geckoforge/
    └── .gitkeep
```

## config.sh Permissions

```bash
# profile/config.sh
#!/bin/bash
set -euo pipefail

# Set executable permissions on first-boot scripts
chmod 0755 /usr/local/sbin/firstboot-nvidia.sh
chmod 0755 /usr/local/sbin/firstboot-nix.sh
chmod 0755 /usr/local/sbin/firstboot-ssh-hardening.sh

# Set permissions on service files
chmod 0644 /etc/systemd/system/geckoforge-*.service

# Create marker directory
mkdir -p /var/lib/geckoforge

# Enable services (redundant if symlinks exist, but safe)
systemctl enable geckoforge-firstboot.service || true
systemctl enable geckoforge-nix.service || true
systemctl enable geckoforge-ssh-hardening.service || true
```

## Verification Commands

```bash
# Check service is enabled
systemctl is-enabled geckoforge-firstboot.service

# Check service status
systemctl status geckoforge-firstboot.service

# View service logs
journalctl -u geckoforge-firstboot.service

# Check symlinks are correct
ls -la /etc/systemd/system/multi-user.target.wants/

# Verify script permissions
ls -la /usr/local/sbin/firstboot-*.sh
```
