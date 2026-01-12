# KIWI NG Build Environment Skill

## Purpose
Guide on setting up and using the KIWI NG build environment, particularly for cross-platform scenarios.

## Supported Build Environments

| Host | Target | Status | Notes |
|------|--------|--------|-------|
| x86_64 openSUSE | x86_64 ISO | ✅ Supported | Native build |
| ARM64 openSUSE | ARM64 ISO | ✅ Supported | Native build |
| ARM64 openSUSE | x86_64 ISO | ⚠️ Requires boxbuild | Use `--x86_64` flag |
| macOS (Apple Silicon) | x86_64 ISO | ⚠️ Via VM | Run openSUSE VM in VMware Fusion |
| Windows (WSL2) | Any ISO | ❌ Not supported | WSL2 kernel limitations |

## Build on Apple Silicon (M1/M2/M3)

### Setup

1. **Install VMware Fusion** (free for personal use)
2. **Create openSUSE Tumbleweed ARM64 VM**
   - Download: https://get.opensuse.org/tumbleweed/
   - Allocate: 4+ CPU cores, 8+ GB RAM, 50+ GB disk
3. **Install KIWI NG in VM**
   ```bash
   sudo zypper install python3-kiwi kiwi-systemdeps-iso-media kiwi-systemdeps-bootloaders
   ```

### Building x86_64 ISO from ARM64 Host

**Option A: Native ARM64 ISO (for ARM64 targets)**
```bash
# This builds an ARM64 ISO
./tools/kiwi-build.sh profile
```

**Option B: x86_64 ISO using boxbuild (QEMU emulation)**
```bash
# Install boxbuild dependencies
sudo zypper install kiwi-boxed-plugin qemu-x86

# Build x86_64 ISO from ARM64 host
kiwi-ng --type iso \
  system boxbuild \
  --box-memory 4G \
  --x86_64 \
  --description profile/ \
  --target-dir out/
```

**Option C: Remote x86_64 builder**
```bash
# SSH to x86_64 machine and build there
ssh x86-builder "cd geckoforge && ./tools/kiwi-build.sh profile"
scp x86-builder:geckoforge/out/*.iso ./out/
```

## Build Script (kiwi-build.sh)

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
PROFILE="${1:-profile}"
PROFILE_PATH="$REPO_ROOT/$PROFILE"
OUT_DIR="$REPO_ROOT/out"

# Install KIWI if not present
if ! command -v kiwi-ng >/dev/null 2>&1; then
    echo "Installing KIWI NG..."
    sudo zypper install -y python3-kiwi kiwi-systemdeps-iso-media kiwi-systemdeps-bootloaders
fi

# Verify profile exists
if [[ ! -f "$PROFILE_PATH/config.xml" ]]; then
    echo "Error: No config.xml found in $PROFILE_PATH"
    exit 1
fi

# Create output directory
mkdir -p "$OUT_DIR"

# Build the ISO
sudo kiwi-ng --color-output \
    --type iso \
    system build \
    --description "$PROFILE_PATH" \
    --target-dir "$OUT_DIR"
```

## Common Build Issues

### Issue: KiwiConfigFileNotFound
```
[ ERROR   ]: KiwiConfigFileNotFound: no XML description found in /path/
```
**Cause:** File named `config.kiwi.xml` instead of `config.xml`
**Fix:** Rename to `config.xml`

### Issue: Schema validation failed
```
[ ERROR   ]: KiwiDescriptionInvalid: Failed to validate schema
```
**Cause:** Invalid XML structure
**Fix:** Check missing `<contact>`, wrong package syntax, deprecated elements

### Issue: Docker volume mount permissions
```
Error: Permission denied on /build/desc
```
**Cause:** Docker on VMware Fusion has volume mount issues
**Fix:** Use native KIWI installation instead of Docker container

### Issue: Cross-architecture packages not found
```
Error: Package xyz not found for x86_64
```
**Cause:** Building ARM64 ISO but specifying x86_64-only packages
**Fix:** Use `arch="x86_64"` attribute or use boxbuild

## Verification After Build

```bash
# Check ISO was created
ls -lh out/*.iso

# Verify ISO contents
isoinfo -l -i out/*.iso | head -50

# Check ISO is bootable
file out/*.iso
# Should show: "DOS/MBR boot sector" for hybrid ISO

# Test boot in QEMU
qemu-system-x86_64 -cdrom out/*.iso -m 4G -enable-kvm
```
