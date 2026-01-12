# Phase 2 Script Consolidation Plan
**Date**: December 15, 2025  
**Goal**: Further reduce script count by moving declarative logic to Nix

---

## Current State After Phase 1
- **Scripts**: 13 (down from 20)
- **Removed**: 7 scripts → Nix modules or integrated

---

## Phase 2 Targets (High Confidence)

### 1. Auto-Updates Module
**Current**: `scripts/setup-auto-updates.sh` (54 lines)  
**New**: `home/modules/auto-updates.nix`

**Rationale**: Systemd units are perfect for declarative Nix  
**Benefit**: User can enable with `programs.autoUpdates.enable = true;`

---

### 2. Network Module (DNS + VPN)
**Current**: `scripts/setup-secure-dns.sh` (86 lines)  
**New**: `home/modules/network.nix`

**Rationale**: systemd-resolved config is declarative  
**Benefit**: DNS-over-TLS configured in home.nix, no script needed

---

### 3. Docker Utilities Module
**Current**: `prune-containers.service`, `prune-containers.timer`  
**New**: Add to existing Docker setup or create `home/modules/docker.nix`

**Rationale**: Systemd timers perfect for Nix  
**Benefit**: User can enable `programs.docker.autoPrune = true;`

---

### 4. Extend backup.nix
**Current**: `check-backups.sh` (standalone)  
**New**: Generate script in `home/modules/backup.nix`

**Rationale**: Backup module should include monitoring  
**Benefit**: Consistent with how power.nix generates check-thermals

---

## Medium Priority (Partial)

### 5. Extend thunderbird.nix
**Current**: `setup-protonmail-bridge.sh` (186 lines)  
**Action**: Extract Flatpak installation to thunderbird.nix, keep interactive parts

---

## Keep As Scripts (Interactive/Proprietary)

These **MUST stay** as scripts due to:
- Interactive wizards (rclone, synergy)
- Proprietary software (Chrome)
- Complex multi-step setups (WinApps)
- Requires licenses or credentials

**Keep**:
- `setup-rclone.sh` - Interactive cloud config wizard
- `setup-synergy.sh` - Requires license file
- `setup-winapps.sh` - Complex Docker setup (has Nix module for config)
- `setup-chrome.sh` - Proprietary repo (could use Flatpak alternative)
- `setup-firewall.sh` - System-level, preference-based

---

## Expected Results

### Before Phase 2:
```
scripts/
  check-backups.sh
  docker-nvidia-install.sh
  docker-nvidia-verify.sh
  firstrun-user.sh
  setup-auto-updates.sh        ← Move to Nix
  setup-chrome.sh
  setup-docker.sh
  setup-firewall.sh
  setup-protonmail-bridge.sh   ← Partial consolidation
  setup-rclone.sh
  setup-secure-dns.sh          ← Move to Nix
  setup-synergy.sh
  setup-winapps.sh
  prune-containers.*           ← Move to Nix
```

### After Phase 2:
```
scripts/
  docker-nvidia-install.sh
  docker-nvidia-verify.sh
  firstrun-user.sh
  setup-chrome.sh              ← Optional proprietary
  setup-docker.sh
  setup-firewall.sh            ← Optional system-level
  setup-protonmail-bridge.sh   ← Optional interactive
  setup-rclone.sh              ← Optional interactive
  setup-synergy.sh             ← Optional license required
  setup-winapps.sh             ← Optional complex

home/modules/
  auto-updates.nix             ← NEW
  network.nix                  ← NEW
  docker.nix                   ← NEW (or extend existing)
  backup.nix                   ← EXTENDED
  (existing modules)
```

**Reduction**: 13 → 10 scripts (-23%)  
**New Nix modules**: +3 (auto-updates, network, docker utilities)

---

## Implementation Priority

1. **High**: auto-updates.nix (simple systemd units)
2. **High**: network.nix (DNS-over-TLS config)
3. **Medium**: docker.nix (prune timers)
4. **Medium**: Extend backup.nix (check script)
5. **Low**: Consolidate thunderbird.nix

**Timeline**: 1 hour implementation, 30 min testing

---

## Benefits

✅ **More declarative** - Less bash, more Nix  
✅ **Easier to customize** - Edit home.nix, not run scripts  
✅ **Version controlled** - All config in Git  
✅ **Reproducible** - Same config on any machine  
✅ **Fewer scripts** - Simpler directory structure

---

## What Stays as Scripts (Good Reasons)

1. **Interactive wizards** - rclone, synergy (need user input)
2. **One-time setup** - Docker, NVIDIA (Layer 3 responsibility)
3. **Proprietary** - Chrome (repo management)
4. **Complex state** - WinApps (Docker VM management)
5. **System-level** - Firewall (requires root, varies by network)

**These scripts serve legitimate purposes and shouldn't be forced into Nix.**

---

Ready to implement Phase 2?
