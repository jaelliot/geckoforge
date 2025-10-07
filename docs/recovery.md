# Recovery Workflows

## OS-Level Rollback (Snapper)

### Via YaST (GUI)
1. Open YaST → System → Snapper
2. Browse snapshots (created before zypper updates)
3. Select pre-update snapshot
4. Click "Restore" → reboot

### Via CLI
```bash
# List snapshots
sudo snapper list

# Compare current to snapshot #42
sudo snapper status 42..0

# Rollback to #42
sudo snapper rollback 42

# Reboot
sudo reboot
```

### At Boot (GRUB)
1. In GRUB menu, select "Bootable snapshots"
2. Choose snapshot
3. Boot into that snapshot
4. If it works, make it permanent: `sudo snapper rollback`

## App-Level Rollback (Nix)

### Home-Manager generations
```bash
# List generations
home-manager generations

# Rollback to previous
home-manager rollback

# Rollback to specific generation
home-manager switch --flake ~/git/home#<generation>

# Or via Nix directly
nix profile rollback

# Garbage collect old generations (after testing)
nix-collect-garbage -d
```

### Rebuild from clean state
```bash
cd ~/git/home
git log  # Find working commit
git checkout <commit-hash>
home-manager switch --flake .
```

## Full Disaster Recovery

### Prerequisites
- Bootable geckoforge ISO
- Backup drive with restic/borg repo
- Git repo access (for dotfiles)

### Steps
1. **Boot from ISO**, install to disk (LUKS + Btrfs)
2. **First boot**: System runs `firstboot-nvidia.sh` and `firstboot-nix.sh`
3. **User setup**: Log in, run `scripts/firstrun-user.sh`
4. **Restore data**:
   ```bash
   # Mount backup drive
   sudo mount /dev/sdX1 /mnt/backup
   
   # Restore home
   restic -r /mnt/backup/restic restore latest --target /
   ```
5. **Rebuild Nix environment**:
   ```bash
   cd ~/git/home
   home-manager switch --flake .
   ```
6. **Verify**: Check that all apps work, containers start, GPU accessible

### Post-Recovery Checklist
- [ ] Firefox profile synced
- [ ] Git SSH keys present (`~/.ssh/`)
- [ ] VS Code settings synced
- [ ] Flatpak apps show in app menu
- [ ] `nvidia-smi` works
- [ ] Podman GPU test passes
- [ ] Home-Manager generation matches expected

## Common Issues

### "Snapper snapshot boot fails"
- **Symptom**: Snapshot boots but system is unstable
- **Fix**: Boot into working snapshot, run `sudo zypper verify` to check for broken packages

### "Home-Manager generation broken"
- **Symptom**: `home-manager switch` fails with build error
- **Fix**: Roll back to previous generation, check `flake.lock` for bad package version

### "GPU not working after restore"
- **Symptom**: `nvidia-smi` or container GPU fails
- **Fix**:
  1. Check driver: `zypper se -i nvidia`
  2. Reinstall toolkit: `scripts/podman-nvidia-install.sh`
  3. Regenerate CDI: `sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml`
