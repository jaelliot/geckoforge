# geckoforge Deployment Strategy

**Date**: December 15, 2025  
**Version**: 1.0.0

---

## Overview

geckoforge uses a **two-track approach** for different use cases:

```
┌─────────────────────────────────────┐
│  Packer: Testing & Development      │
│  • VirtualBox VMs                   │
│  • Shared folder workflow           │
│  • Rapid iteration                  │
│  • Safe experimentation             │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│  KIWI: Bare Metal Deployment        │
│  • Custom bootable ISO              │
│  • Laptop/workstation installation  │
│  • Production deployments           │
│  • Built in Packer VM               │
└─────────────────────────────────────┘
```

---

## Track 1: Packer (Testing)

### Purpose
- Test geckoforge configurations safely
- Rapid iteration with snapshots
- Development environment
- Team collaboration (share OVA)

### Process
```bash
# Build VM with Packer
cd packer
./build.sh

# Or use VirtualBox manually with shared folder
# Follow: docs/SETUP-STEP-BY-STEP.md
```

### Key Features
- ✅ **Shared folder**: Edit in host (WSL2), test in VM instantly
- ✅ **Snapshots**: Revert to known-good state in seconds
- ✅ **Isolated**: Break things without risk
- ✅ **Reproducible**: Same environment every time

### Workflow
```
1. Edit configs in WSL2/host
   ↓
2. Changes visible immediately in VM via shared folder
   ↓
3. Test in VM
   ↓
4. Break something? Restore snapshot
   ↓
5. Fix in host, retry
   ↓
6. Success? Document and commit
```

---

## Track 2: KIWI (Deployment)

### Purpose
- Deploy to physical hardware (laptop, workstation)
- Production-ready installations
- Custom bootable ISO with geckoforge baked in

### Process
```bash
# IN THE PACKER VM (with shared folder)
cd /media/sf_geckoforge  # Or /mnt/geckoforge
./tools/kiwi-build.sh profiles/leap-15.6/kde-nvidia

# Output: out/geckoforge-leap-15.6-*.iso
# Copy to host, burn to USB, deploy to laptop
```

### Key Features
- ✅ **Everything baked in**: Drivers, configs, scripts
- ✅ **Bootable USB**: Flash and deploy
- ✅ **NVIDIA support**: Auto-detected on hardware
- ✅ **Built in VM**: No WSL2 kernel restrictions

### Workflow
```
1. Test configs in Packer VM
   ↓
2. Validate everything works
   ↓
3. Build KIWI ISO in VM
   ↓
4. Copy ISO to host
   ↓
5. Burn to USB
   ↓
6. Deploy to laptop/workstation
```

---

## Why This Approach?

### Problem: WSL2 Limitations
- ❌ KIWI needs kernel access (loop devices, ISO creation)
- ❌ Docker in WSL2 has restricted capabilities
- ❌ Can't build bootable ISOs directly

### Solution: VM as Build Environment
- ✅ Full Linux kernel access in VM
- ✅ Shared folder = live development
- ✅ Safe testing before building deployment ISO
- ✅ One environment for both workflows

---

## Complete Workflow

### Phase 1: Development & Testing (Packer VM)

```bash
# 1. Build or setup VM
cd packer && ./build.sh
# OR follow docs/SETUP-STEP-BY-STEP.md

# 2. Configure shared folder
# VirtualBox → Settings → Shared Folders
# Path: /home/jay/Documents/Vaidya-Solutions-Code/geckoforge
# Name: geckoforge
# Mount: /media/sf_geckoforge

# 3. Develop and test
# Host: Edit configs
# VM: Test immediately
# VM: Take snapshots before risky changes

# 4. Iterate until satisfied
```

### Phase 2: Build Deployment ISO (In VM)

```bash
# Inside Packer VM
cd /media/sf_geckoforge

# Build KIWI ISO
./tools/kiwi-build.sh profiles/leap-15.6/kde-nvidia

# Wait 15-20 minutes
# Output: out/geckoforge-leap-15.6-Build7.10.iso
```

### Phase 3: Deploy to Laptop

```bash
# On host (WSL2/Windows)
cd ~/Documents/Vaidya-Solutions-Code/geckoforge/out

# Verify ISO exists
ls -lh geckoforge-*.iso

# Burn to USB (Linux)
sudo dd if=geckoforge-leap-15.6-*.iso of=/dev/sdX bs=4M status=progress

# Or use Rufus on Windows

# Boot laptop from USB → Install → Done!
```

---

## Directory Structure

```
geckoforge/
├── packer/                    # Packer templates (testing)
│   ├── opensuse-leap-geckoforge.pkr.hcl
│   ├── build.sh
│   └── http/autoyast.xml
│
├── profiles/                  # KIWI profiles (deployment)
│   └── leap-15.6/
│       └── kde-nvidia/
│           ├── config.kiwi.xml
│           ├── root/
│           └── scripts/
│
├── tools/
│   └── kiwi-build.sh         # Build KIWI ISO (run in VM)
│
├── docs/
│   ├── DEPLOYMENT-STRATEGY.md (this file)
│   ├── SETUP-STEP-BY-STEP.md  # Packer VM setup
│   └── packer-automation.md    # Packer details
│
└── out/                       # Build outputs
    ├── *.ova                  # Packer VMs
    └── *.iso                  # KIWI ISOs (created in VM)
```

---

## Use Cases

### Use Case 1: Testing New Home-Manager Module

```bash
# Host: Create new module
vim home/modules/new-feature.nix

# Host: Import in home.nix
vim home/home.nix

# VM: Apply immediately (via shared folder)
cd /media/sf_geckoforge/home
home-manager switch --flake .

# VM: Test functionality
# If breaks: Restore snapshot
# If works: Commit to Git
```

### Use Case 2: Testing Script Changes

```bash
# Host: Edit script
vim scripts/setup-docker.sh

# VM: Test immediately (shared folder = instant sync)
cd /media/sf_geckoforge
./scripts/setup-docker.sh

# VM: Verify Docker works
docker ps

# If breaks: Restore snapshot, fix script, retry
# If works: Build deployment ISO
```

### Use Case 3: Deploying to New Laptop

```bash
# 1. Test everything in Packer VM
# 2. Build ISO in VM:
cd /media/sf_geckoforge
./tools/kiwi-build.sh profiles/leap-15.6/kde-nvidia

# 3. Copy ISO to host:
# ISO appears in out/ directory (shared)

# 4. Burn to USB on host

# 5. Deploy to laptop
# Boot from USB → Install → Complete!
```

### Use Case 4: Team Collaboration

```bash
# Developer A: Test in Packer VM
# Developer A: Commit changes to Git
# Developer A: Build KIWI ISO

# Developer B: Pull changes
# Developer B: Test in their Packer VM
# Developer B: Validate

# Everyone: Use same KIWI ISO for deployment
```

---

## Best Practices

### Testing (Packer VM)
1. ✅ **Always take snapshots** before risky changes
2. ✅ **Use shared folder** for instant iteration
3. ✅ **Document failures** in docs/test-failures/
4. ✅ **Test incrementally** - small changes, verify, commit
5. ✅ **Revert freely** - snapshots are cheap

### Building ISOs (KIWI in VM)
1. ✅ **Test first** - validate in VM before building ISO
2. ✅ **Clean build** - restore VM snapshot before KIWI build
3. ✅ **Version ISOs** - tag builds in Git, name ISOs accordingly
4. ✅ **Document changes** - update CHANGELOG for each ISO
5. ✅ **Test on real hardware** - before mass deployment

### Deployment (Laptop/Workstation)
1. ✅ **Backup first** - always backup existing data
2. ✅ **Test on laptop** - deploy to MSI GF65 first (testing)
3. ✅ **Validate 1-2 weeks** - daily driver testing
4. ✅ **Then workstation** - deploy to production workstation
5. ✅ **Keep old ISO** - in case rollback needed

---

## Troubleshooting

### Shared Folder Not Working in VM

```bash
# In VM
sudo usermod -aG vboxsf $USER
sudo reboot

# After reboot
ls /media/sf_geckoforge
```

### KIWI Build Fails in VM

```bash
# Ensure Docker is running
sudo systemctl start docker

# Ensure sufficient disk space
df -h /

# Check KIWI build logs
cd /media/sf_geckoforge
./tools/kiwi-build.sh profiles/leap-15.6/kde-nvidia 2>&1 | tee build.log
```

### ISO Won't Boot on Laptop

- Verify UEFI/BIOS settings
- Disable Secure Boot temporarily
- Try different USB port
- Re-burn ISO with Rufus (Windows) or dd (Linux)

---

## Timeline Example

### Week 1: Setup & Testing
- **Monday**: Build Packer VM or manual setup
- **Tuesday-Thursday**: Test all modules and scripts
- **Friday**: Document any issues found

### Week 2: Refinement
- **Monday-Wednesday**: Fix issues, iterate in VM
- **Thursday**: Full regression test
- **Friday**: Build KIWI ISO (if tests pass)

### Week 3: Deployment
- **Monday**: Deploy to MSI GF65 laptop
- **Week 3-4**: Daily driver on laptop, monitor stability
- **If stable**: Deploy to production workstation

---

## Version History

### v1.0.0 (December 15, 2025)
- Initial deployment strategy
- Packer for testing
- KIWI for deployment
- VM as build environment

---

## Summary

| Aspect | Packer (Testing) | KIWI (Deployment) |
|--------|------------------|-------------------|
| **Purpose** | Safe testing | Production deployment |
| **Environment** | VirtualBox VM | Bare metal (laptop/workstation) |
| **Build Location** | Host or automated | Inside Packer VM |
| **Iteration Speed** | Instant (shared folder) | Slow (rebuild ISO) |
| **Risk** | Zero (snapshots) | High (real hardware) |
| **Output** | OVA (shareable) | Bootable ISO |
| **Use When** | Developing/testing | Deploying to hardware |

**Key Insight:** Test thoroughly in Packer VM using shared folder workflow, then build deployment ISO in that same VM when ready. This leverages the best of both tools while working around WSL2 limitations.

---

**Remember:** Packer for testing, KIWI for deployment, VM bridges both worlds! 🚀
