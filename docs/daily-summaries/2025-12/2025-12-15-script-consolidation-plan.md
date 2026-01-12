# Script Consolidation Plan - December 15, 2025

## Current State
- **27 shell scripts** across 3 directories
- **Duplication**: Some functionality already in Nix modules
- **Complexity**: Too many scripts for user to navigate

## Consolidation Strategy

### Phase 1: Move to Nix (Declarative > Imperative)

**REMOVE** (functionality already in Home-Manager):
- ❌ `setup-shell.sh` → Already in `shell.nix`
- ❌ `setup-macos-keyboard.sh` → Already in `macos-keyboard.nix`
- ❌ `test-macos-keyboard.sh` → Not needed (module handles it)
- ❌ `test-night-color.sh` → Not needed (KDE handles it)

**CREATE** new Home-Manager module `home/modules/power.nix`:
- ✅ Absorb `setup-laptop-power.sh` functionality
- ✅ TLP configuration
- ✅ Intel CPU power states
- ✅ Battery thresholds
- ✅ Thermal monitoring setup

**RESULT**: -5 scripts, +1 Nix module

---

### Phase 2: Merge Optional Features into Single Script

**CREATE** `scripts/setup-optional.sh` (interactive menu):
```
Optional Features Setup
1. Firewall hardening
2. Automatic updates
3. Secure DNS (Quad9)
4. Rclone backup
5. ProtonMail Bridge
6. Chrome/Chromium
7. WinApps (Windows integration)
8. Synergy (KVM sharing)
9. All of the above
0. Exit
```

**REMOVE**:
- ❌ `setup-firewall.sh`
- ❌ `setup-auto-updates.sh`
- ❌ `setup-secure-dns.sh`
- ❌ `setup-rclone.sh`
- ❌ `setup-protonmail-bridge.sh`
- ❌ `setup-chrome.sh`
- ❌ `setup-synergy.sh`

**KEEP** (called by firstrun):
- ✅ `setup-winapps.sh` (complex enough to stay separate)

**RESULT**: -7 scripts, +1 unified menu script

---

### Phase 3: Simplify Storage Configuration

**MERGE** into `firstrun-user.sh`:
- ❌ `setup-dual-storage.sh` → Integrate as function in firstrun

**RATIONALE**: Storage setup is one-time, better in main wizard

**RESULT**: -1 script

---

### Phase 4: Remove Redundant Utilities

**REMOVE**:
- ❌ `make-executable.sh` → Just use `chmod +x` directly

**KEEP**:
- ✅ `check-backups.sh` → Useful standalone utility

**RESULT**: -1 script

---

## Final Structure

### `profile/scripts/` (3 scripts - unchanged)
```
firstboot-nix.sh
firstboot-nvidia.sh
firstboot-ssh-hardening.sh
```

### `scripts/` (8 scripts - down from 20!)
```
Core:
  firstrun-user.sh          # Main setup wizard (enhanced)
  setup-docker.sh           # Docker installation
  docker-nvidia-install.sh  # NVIDIA Container Toolkit
  docker-nvidia-verify.sh   # GPU verification

Optional:
  setup-optional.sh         # NEW: Unified optional features menu
  setup-winapps.sh          # Windows integration (complex)

Utilities:
  check-backups.sh          # Backup verification
```

### `tools/` (4 scripts - unchanged)
```
kiwi-build.sh
test-iso.sh
check-anti-patterns.sh
check-layer-assignments.sh
```

### `home/modules/` (+1 new module)
```
power.nix                   # NEW: Laptop power management
(existing modules)
```

---

## Benefits

1. **-14 scripts** (27 → 13 total, -52%)
2. **Declarative over imperative** (more in Nix)
3. **Single entry point** for optional features
4. **Clearer structure** (fewer choices to make)
5. **Less maintenance** (one menu vs 7 scripts)

---

## Migration Path

1. Create `home/modules/power.nix`
2. Create `scripts/setup-optional.sh`
3. Update `firstrun-user.sh` to integrate storage setup
4. Remove redundant scripts
5. Update documentation
6. Test in VM

---

## User Experience Improvement

**Before**:
```bash
# User sees 20 scripts, unsure which to run
ls scripts/
setup-auto-updates.sh
setup-chrome.sh
setup-docker.sh
setup-firewall.sh
...
# Overwhelming!
```

**After**:
```bash
# Clear, simple structure
ls scripts/
check-backups.sh
docker-nvidia-install.sh
docker-nvidia-verify.sh
firstrun-user.sh           # ← Start here
setup-docker.sh
setup-optional.sh          # ← Optional features
setup-winapps.sh

# Run firstrun, it handles everything
./scripts/firstrun-user.sh
```

---

## Implementation Priority

1. **High**: Create `power.nix` and remove redundant scripts
2. **High**: Create `setup-optional.sh` menu
3. **Medium**: Integrate storage into firstrun
4. **Low**: Remove utilities

**Timeline**: 1-2 hours implementation, 30 min testing

---

**Ready to implement?** This will make geckoforge much cleaner and easier to use!
