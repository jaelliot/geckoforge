# Btrfs Subvolume Layout

## Recommended Structure

```
Volume (/)
├── @           → /           (OS, snapshotted)
├── @home       → /home       (user data, snapshotted separately)
├── @nix        → /nix        (reproducible, exclude or infrequent)
├── @snapshots  → /.snapshots (Snapper metadata)
└── @var_log    → /var/log    (exclude from snapshots)
```

## Why?

- **@**: OS files, snapshotted before every zypper update
- **@home**: User data, daily snapshots, kept longer
- **@nix**: Reproducible from `flake.lock`, can exclude or snapshot less often
- **@snapshots**: Required for Snapper metadata
- **@var_log**: Log files, no snapshots (waste space)

## Setup (during install or first boot)

If you're using the KIWI ISO, you'll need to create these manually on first boot OR extend the KIWI config to create them.

### Manual Setup (post-install)

```bash
# Identify root device
ROOTDEV=$(findmnt -no SOURCE /)

# Mount top-level subvolume
sudo mkdir -p /mnt/btrfs
sudo mount "$ROOTDEV" /mnt/btrfs -o subvolid=5

# Create subvolumes
cd /mnt/btrfs
sudo btrfs subvolume create @nix
sudo btrfs subvolume create @var_log

# Update /etc/fstab
UUID=$(blkid -s UUID -o value "$ROOTDEV")
cat <<EOF | sudo tee -a /etc/fstab
UUID=$UUID /nix      btrfs subvol=@nix,compress=zstd,noatime 0 0
UUID=$UUID /var/log  btrfs subvol=@var_log,compress=zstd,noatime 0 0
EOF

# Mount
sudo mkdir -p /nix /var/log
sudo mount /nix
sudo mount /var/log

# Migrate existing data
sudo rsync -a /var/log.old/ /var/log/ && sudo rm -rf /var/log.old

sudo umount /mnt/btrfs
```

## Snapper Configuration

### Root subvolume (@)
- **Timeline**: hourly (keep 10), daily (keep 7), weekly (keep 4)
- **Number cleanup**: keep last 10
- Triggered by zypper (pre/post snapshots)

### Home subvolume (@home)
```bash
sudo snapper -c home create-config /home
sudo snapper -c home set-config TIMELINE_CREATE=yes
sudo snapper -c home set-config TIMELINE_LIMIT_HOURLY=0
sudo snapper -c home set-config TIMELINE_LIMIT_DAILY=7
sudo snapper -c home set-config TIMELINE_LIMIT_WEEKLY=4
sudo snapper -c home set-config TIMELINE_LIMIT_MONTHLY=6
```

### Nix subvolume (@nix)
```bash
# Option 1: No snapshots (fully reproducible)
sudo snapper -c nix create-config /nix
sudo snapper -c nix set-config TIMELINE_CREATE=no

# Option 2: Weekly snapshots (if you want faster recovery)
sudo snapper -c nix set-config TIMELINE_CREATE=yes
sudo snapper -c nix set-config TIMELINE_LIMIT_HOURLY=0
sudo snapper -c nix set-config TIMELINE_LIMIT_DAILY=0
sudo snapper -c nix set-config TIMELINE_LIMIT_WEEKLY=2
```

## Verification

```bash
# List subvolumes
sudo btrfs subvolume list /

# Check mount points
findmnt -t btrfs

# Snapper configs
sudo snapper list-configs

# Storage usage
sudo btrfs filesystem usage /
```
