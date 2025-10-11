---
applyTo: "**"
---

---
description: Universal prohibitions and non-negotiable standards for geckoforge
alwaysApply: true
globs: ["**/*.sh", "**/*.nix", "**/*.xml", "**/*.yml", "**/*.yaml", "**/*.md"]
version: 0.3.0
---

## Role & Intent
These rules are **source-of-truth architecture guidance** for the geckoforge KIWI image builder project. Violations indicate hallucinations or misunderstandings about the project structure.

## Zero-Tolerance Anti-Patterns

### Container Runtime Violations
- Using Podman commands, flags, or CDI syntax anywhere in the codebase
- Using `--device nvidia.com/gpu=all` (Podman GPU syntax)
- Referring to Podman in documentation, scripts, or comments
- Creating Podman-related scripts or configuration files

**Required**: Docker only, with `--gpus all` for NVIDIA access

### TeX Live Violations
- Using `texlive.combined.scheme-full` (5GB, unstable)
- Recommending full TeX installation
- Ignoring user's explicit choice of scheme-medium

**Required**: `texlive.combined.scheme-medium` (2GB, stable on openSUSE Leap)

### Architecture Layer Violations
- Placing Docker setup in KIWI first-boot systemd units
- Placing user-specific scripts in `/usr/local/sbin/`
- Running commands that require user group membership at first-boot
- Mixing ISO-baked, first-boot, user-setup, and Home-Manager layer responsibilities

**Required**: Respect the 4-layer architecture (see 10-kiwi-architecture.mdc)

### Package Hallucinations
- Inventing package names not available in openSUSE Leap 15.6 repos
- Using Ubuntu/Debian package names on openSUSE
- Assuming packages exist without checking `zypper search`
- Using Nix packages that don't exist in nixpkgs

**Required**: Verify package availability before suggesting installations

### Path and File Violations
- Creating scripts outside `scripts/` directory
- Placing KIWI profiles outside `profiles/leap-15.6/`
- Creating documentation outside `docs/` directory
- Using incorrect file paths in config.kiwi.xml

**Required**: Follow established directory structure (see 05-project-overview.mdc)

## Required Patterns

### Script Naming and Location
- User scripts: `scripts/*.sh`
- KIWI first-boot: `profiles/leap-15.6/kde-nvidia/scripts/firstboot-*.sh`
- Examples: `scripts/examples/*/`
- All scripts must be executable: `chmod +x`

### Home-Manager Modules
- Core modules: `home/modules/*.nix`
- Main config: `home/home.nix`
- Flake: `home/flake.nix`
- Import new modules in `home.nix`

### Documentation Structure
- Architecture: `docs/architecture/`
- Guides: `docs/guides/`
- Daily summaries: `docs/daily-summaries/YYYY-MM/`
- Examples: `docs/examples/`

### KIWI Configuration
- Profile: `profiles/leap-15.6/kde-nvidia/`
- Config: `config.kiwi.xml`
- Scripts: `scripts/` subdirectory
- Root overlay: `root/` subdirectory

## Mandatory Verifications

Before suggesting changes:
1. **Package exists**: Check if package is available in openSUSE Leap 15.6 or nixpkgs
2. **Layer appropriate**: Confirm change belongs in the correct architecture layer
3. **Path valid**: Verify file paths match project structure
4. **Syntax correct**: Use Docker (not Podman), scheme-medium (not full)
5. **Dependencies resolved**: Check for required libraries, tools, configurations

## Forbidden Terms and Patterns

### Container Runtime
- ❌ `podman`
- ❌ `--device nvidia.com/gpu=`
- ❌ `nvidia.com/gpu=all`
- ❌ `cdi`
- ❌ `podman-compose`
- ✅ `docker`
- ✅ `--gpus all`
- ✅ `docker-compose`

### TeX Live
- ❌ `scheme-full`
- ❌ `texlive-full`
- ❌ "complete TeX installation"
- ✅ `scheme-medium`
- ✅ `texlive.combined.scheme-medium`

### Package Management
- ❌ `apt-get`, `apt install` (Ubuntu/Debian)
- ❌ `yum`, `dnf` (Fedora/RHEL)
- ❌ `pacman` (Arch)
- ✅ `zypper` (openSUSE system packages)
- ✅ `nix` (Home-Manager packages)
- ✅ `flatpak` (sandboxed GUI apps)

## Notes / Examples

### Correct Docker GPU syntax:
```bash
# CORRECT
docker run --rm --gpus all nvidia/cuda:12.4.0-base nvidia-smi

# WRONG (Podman syntax)
podman run --rm --device nvidia.com/gpu=all nvidia/cuda:12.4.0-base nvidia-smi
```

### Correct TeX Live specification:
```nix
# CORRECT (home/modules/development.nix)
texlive.combined.scheme-medium

# WRONG
texlive.combined.scheme-full
```

### Correct script placement:
```
# CORRECT (user scripts)
scripts/setup-docker.sh
scripts/docker-nvidia-install.sh

# WRONG (these are KIWI first-boot scripts)
/usr/local/sbin/setup-docker.sh
profiles/.../root/etc/systemd/system/setup-docker.service
```

### Correct layer responsibility:
```yaml
# ISO Layer (KIWI config.kiwi.xml)
- Base packages (kernel, NetworkManager, KDE)
- Repository configuration
- System structure

# First-boot Layer (systemd one-shot)
- NVIDIA driver detection/install
- Nix multi-user installation
- System-level automation

# User-setup Layer (scripts/)
- Docker installation
- NVIDIA Container Toolkit
- Chrome, Flatpaks
- Home-Manager setup

# Home-Manager Layer (home/)
- User packages and configuration
- Development environments
- Desktop applications
- Shell configuration
```

## Implementation Safety

When AI suggests changes:
1. **Verify package names** against official repos
2. **Check syntax** for correct Docker/TeX/Nix patterns
3. **Confirm layer** matches responsibility
4. **Test paths** before committing
5. **Review docs** after making changes
