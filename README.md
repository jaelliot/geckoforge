<!-- @file README.md -->
<!-- @description Main project documentation for geckoforge - openSUSE Leap 15.6 + KDE + NVIDIA custom distribution -->
<!-- @update-policy Update when major features are added, architecture changes, or project goals evolve -->

<div align="center">

# 🦎 Geckoforge

**A custom openSUSE Leap 15.6 distribution built with KIWI NG**

*Professional workstation image with KDE Plasma, NVIDIA GPU support, and declarative configuration*

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![openSUSE Leap 15.6](https://img.shields.io/badge/openSUSE-Leap%2015.6-73ba25?logo=opensuse)](https://www.opensuse.org/)
[![KDE Plasma](https://img.shields.io/badge/KDE-Plasma%205-1d99f3?logo=kde)](https://kde.org/plasma-desktop/)
[![Built with KIWI](https://img.shields.io/badge/built%20with-KIWI%20NG-orange)](https://osinside.github.io/kiwi/)

[Features](#-features) • [Quick Start](#-quick-start) • [Documentation](#-documentation) • [Architecture](#-architecture) • [Contributing](#-contributing)

</div>

---

## 🎯 Overview

Geckoforge is a **four-layer reproducible workstation image** targeting developers, data scientists, and power users who need:

**"Configure once, avoid BS forever"** workstation for:

- **AI/ML development**: GPU containers for PyTorch, TensorFlow, CUDA
- **Software engineering**: Reproducible dev environments via Nix
- **Content creation**: OBS with NVENC, Kdenlive, GIMP
- **Daily driver**: Replacing Windows 10 with rock-solid Linux

**Hardware**: Powerful workstations/laptops with NVIDIA GPUs

Built on **openSUSE Leap 15.6** (enterprise-grade stability) with **KDE Plasma** desktop and **Btrfs + Snapper** for system snapshots.

---

## ✨ Features

### 🎨 Visual Polish

- **Mystical Blue (Jux) Theme** - Professional dark blue aesthetic
  - JuxPlasma desktop theme with modern panels
  - JuxDeco window decorations with rounded corners
  - NoMansSkyJux Kvantum Qt theme for unified app styling
  - System-wide color coordination
- **Declarative theming** - Managed via Home-Manager (`home/modules/kde-theme.nix`)
- **Night Color included** - Blue light reduction configured declaratively

### 🌙 Night Color Comfort

- **Night Color configured declaratively** - 6500K day, 3500K night via Home-Manager
- **Location-aware scheduling** - Automatic sunrise/sunset via KDE services
- **Customizable** - Edit `home/modules/kde-theme.nix` to adjust temperatures and timing
- **Health check utility** - `./scripts/test-night-color.sh` validates configuration

### 🪟 Windows Application Integration

- **WinApps support** - Run Windows applications seamlessly on Linux via Docker
- **Automated Windows installation** - ISO downloaded from Microsoft servers
- **Full application compatibility** - Microsoft Office, Adobe Creative Cloud, game engines
- **Native-like experience** - Windows apps appear in KDE menu, open files via right-click
- **Declarative configuration** - Manage WinApps via Home-Manager with reproducible settings

### 🚀 GPU-Ready Docker

- **Docker Engine** with NVIDIA Container Toolkit
- **Automatic GPU detection** and configuration
- **Verified installation** - Tests GPU access in containers
- **Production-ready** - No manual driver management
- **CDI support** - Container Device Interface for resource allocation

### 🖥️ Multi-Machine KVM

- **Synergy 3 support** - Share keyboard/mouse across computers
- **Input Leap alternative** - FOSS option with better Wayland support
- **Automated setup** - Firewall, systemd service, configuration
- **Client & server modes** - Flexible workspace layouts
- **Interactive wizard** - `./scripts/setup-synergy.sh`

### 🏠 Declarative Home Environment

- **Nix Home-Manager** - Reproducible user configuration
- **Version-pinned packages** - No dependency conflicts
- **Shell configuration** - Zsh + Oh My Zsh + Powerlevel10k
- **Development toolchains** - Multi-language support with asdf-vm
- **Git-tracked configs** - Portable across machines

### 💾 Encrypted Cloud Backups

- **rclone integration** - Supports Google Drive, S3, OneDrive, Backblaze B2
- **Zero-knowledge encryption** - Cloud provider cannot read backups
- **Automated schedules** - Daily critical files, weekly projects
- **systemd timers** - User-level automation
- **Interactive setup** - `./scripts/setup-rclone.sh`

### 📧 Hardened Email Client

- **Mozilla Thunderbird** with anti-phishing configuration
- **Clickable links disabled** by default (copy/paste URLs manually)
- **Remote content blocked** - No tracking pixels or external images
- **OAuth2 support** for Gmail/Outlook, ProtonMail Bridge compatible
- **Plain text preference** - HTML rendering minimized for security

### 🛠️ Developer Toolchains

**Languages:**
- Python 3.12 (with ruff, black, pytest)
- Node.js (via asdf-vm)
- Go, Nim, Elixir, R, .NET 9
- LaTeX (TeX Live scheme-medium - 2GB stable distribution)

**Tools:**
- Docker + docker-compose with GPU support
- Git with sensible defaults and delta pager
- VS Code, Cursor, WebStorm (via script setup)
- MongoDB Compass, DBeaver, Postman (Flatpak)

### ⌨️ Text Expansion (espanso)

- **espanso integration** - System-wide text expansion
- **Cross-platform shortcuts** - Same config works on Linux and Windows WSL
- **Declarative configuration** - Managed via Home-Manager
- **Auto-start on login** - systemd user service
- **Useful defaults** - Date/time, git commits, symbols, paths
- **Customizable** - Edit `~/.config/espanso/match/user.yml`
- **Interactive search** - `Alt+Space` to browse available shortcuts

**See:** [Text Expander Guide](docs/text-expander.md)

### ⌨️ macOS-style Keyboard Experience

- **Kanata-powered remapping** - Swap Command/Control semantics system-wide
- **KDE alignment** - Cmd+Q, Cmd+M, Cmd+Tab, and Cmd+L mirror macOS behavior
- **Editor integrations** - VS Code, Firefox, and Kate receive Command shortcuts
- **Declarative option** - Reapply configuration via `geckoforge.macosKeyboard`
- **Verification tooling** - `scripts/test-macos-keyboard.sh` validates setup

### 🔒 System Resilience

- **Btrfs filesystem** - Copy-on-write, compression, snapshots
- **Snapper integration** - Automatic pre/post-update snapshots
- **GRUB snapshot boot** - Rollback from boot menu
- **Home-Manager generations** - Rollback user environment
- **LUKS2 encryption** - Full-disk encryption with secure defaults

### ⚡ Quality Gates

- **Lefthook pre-commit** - Fast syntax checks (<30s)
  - Shell script validation (shellcheck + bash -n)
  - Nix expression evaluation
  - Anti-pattern detection (Podman usage, wrong TeX scheme)
- **Lefthook pre-push** - Thorough validation
  - Layer boundary enforcement
  - Package policy compliance
  - Documentation synchronization

---

## 🚀 Quick Start

### Prerequisites

- **openSUSE Leap 15.6** (or compatible) for building
- **KIWI NG** installed (`zypper install kiwi-ng`)
- **NVIDIA GPU** (optional - detects and configures automatically)
- **8+ GB RAM** and **50+ GB disk** for ISO build

### Build the ISO

```bash
# Clone repository
git clone https://github.com/jaelliot/geckoforge.git
cd geckoforge

# Build ISO
./tools/kiwi-build.sh profile

# ISO created in: out/geckoforge-leap156-kde.x86_64-*.iso
```

**Build time:** ~10-15 minutes (depending on network/CPU)

### Install to Hardware

1. **Create bootable USB:**
   ```bash
   sudo dd if=out/geckoforge-*.iso of=/dev/sdX bs=4M status=progress
   sync
   ```

2. **Boot from USB** (disable Secure Boot temporarily)

3. **Install** - Follow installer prompts
   - Enable disk encryption (recommended)
   - Set strong user password

4. **First boot** - System automatically:
   - Installs NVIDIA drivers (if GPU detected)
   - Installs Nix package manager with flakes
   - Prompts for reboot

5. **User setup** - Run wizard:
   ```bash
   cd ~/git
   git clone https://github.com/jaelliot/geckoforge.git
   cd geckoforge
   ./scripts/firstrun-user.sh
   ```

6. **Optional macOS-style shortcuts** - Align modifiers with macOS:
  ```bash
  ./scripts/setup-macos-keyboard.sh
  ```

7. **Security hardening (recommended)** - Apply layered defenses:
  ```bash
  # Security hardening
  ./scripts/setup-firewall.sh
  ./scripts/setup-secure-dns.sh
  ./scripts/setup-auto-updates.sh
  ```

**Total time:** ~45 minutes (build + install + setup)

**Next steps:** See [Getting Started Guide](docs/getting-started.md)

---

## 📖 Documentation

### User Guides

- **[Getting Started](docs/getting-started.md)** - Installation and initial setup
- **[Docker + NVIDIA](docs/docker-nvidia.md)** - GPU container workflows
- **[Themes](docs/themes.md)** - Theme activation and customization
- **[Night Color](docs/night-color.md)** - Blue light filtering defaults, customization, and verification
- **[WinApps](docs/winapps.md)** - Windows application integration (Office, Adobe, game engines)
- **[Keyboard Configuration](docs/keyboard-configuration.md)** - macOS-style shortcut setup
- **[Security Configuration](docs/security-configuration.md)** - Layered hardening tasks
- **[Synergy Setup](docs/synergy-setup.md)** - Multi-machine KVM configuration
- **[Backup & Recovery](docs/backup-recovery.md)** - Cloud backups and system restore
- **[Testing Plan](docs/testing-plan.md)** - Validation procedures

### Architecture

- **[Architecture Overview](docs/README.md)** - Four-layer design
- **[Directory Structure](docs/directory-tree.md)** - Repository layout
- **[Btrfs Layout](docs/btrfs-layout.md)** - Filesystem and snapshots

### Development

- **[Daily Summaries](docs/daily-summaries/)** - Development log
- **[Contributing](#-contributing)** - How to contribute
- **[Cursor Rules](.cursor/rules/)** - AI assistant guidelines

### Migration & Consolidation (v0.4.0)

**Script Consolidation** - Simplified setup with fewer scripts:
- `setup-firewall.sh` - Merged firewall + security hardening (was `harden.sh` + `setup-secure-firewall.sh`)
- Flatpak installation - Now in Home-Manager activation (was `install-flatpaks.sh`)
- Theme configuration - Declarative via `home/modules/kde-theme.nix` (was `setup-jux-theme.sh`)
- Night Color - Declarative via `home/modules/kde-theme.nix` (was `configure-night-color.sh`)

**Benefits**:
- 5 fewer scripts to maintain (-23%)
- Reproducible theme + Night Color config
- Flatpaks version-controlled in Git
- Single source of truth for security hardening

---

## 🏗️ Architecture

Geckoforge uses a **four-layer architecture** for reproducibility and maintainability:

```
┌─────────────────────────────────────┐
│ Layer 4: Home-Manager (Nix)        │  ~/.config, user packages
│ User environment, dev toolchains   │  Declarative, version-pinned
└─────────────────────────────────────┘
                  ↑
┌─────────────────────────────────────┐
│ Layer 3: User Setup (scripts/)     │  Docker, NVIDIA Toolkit, Flatpaks
│ Post-install automation            │  Interactive, opt-in features
└─────────────────────────────────────┘
                  ↑
┌─────────────────────────────────────┐
│ Layer 2: First-Boot (systemd)      │  NVIDIA driver, Nix installer
│ One-shot system configuration      │  Automated, root-level
└─────────────────────────────────────┘
                  ↑
┌─────────────────────────────────────┐
│ Layer 1: ISO (KIWI profile)        │  Base OS, repositories, themes
│ Immutable system image             │  Reproducible builds
└─────────────────────────────────────┘
```

### Repository Structure (Flattened v0.4.0)

```
geckoforge/
├── profile/          # KIWI image definition (was profiles/leap-15.6/kde-nvidia/)
│   ├── config.kiwi.xml
│   ├── root/         # File overlays
│   └── scripts/      # First-boot automation
├── home/             # Home-Manager (Nix) configuration
│   ├── flake.nix
│   ├── home.nix
│   └── modules/      # Modular configs (theme, shell, dev tools)
├── scripts/          # User setup scripts (Layer 3)
├── examples/         # Working code examples (was scripts/examples/)
├── tools/            # Build and validation tools
├── themes/           # KDE theme source files
└── docs/             # Flattened documentation
    ├── audits/       # Quality audits
    └── summaries/    # Development log (was daily-summaries/YYYY-MM/)
```

### Three-Layer Package Management

```
┌─────────────────────────────────────┐
│ Layer 3: Flatpak (Sandboxed GUI)   │
│ OBS, Signal, DBeaver, Postman, etc. │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│ Layer 2: Nix (Reproducible Apps)    │
│ Dev tools, CLI utils, pinned with   │
│ flake.lock                          │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│ Layer 1: zypper (Base OS)           │
│ Kernel, NVIDIA driver, systemd,     │
│ KDE Plasma                          │
└─────────────────────────────────────┘
```

**Key Principles:**

- **Layer boundaries** - No cross-layer violations
- **Reproducibility** - Deterministic builds, version-pinned
- **Idempotency** - Scripts can run multiple times safely
- **Documentation parity** - Code and docs stay in sync

**Why this works:**
- **Leap 15.6**: Enterprise stability (18-month releases)
- **Nix**: Reproducible environments, atomic upgrades
- **Flatpak**: Sandboxed apps, auto-updates
- **Btrfs + Snapper**: Instant OS rollbacks
- **Secure Boot + LUKS2**: Security by default

**See:** [Architecture Documentation](docs/README.md)

---

## 🧪 Testing

### Quality Gates (Lefthook)

```bash
# Install hooks
lefthook install

# Run pre-commit checks (fast)
lefthook run pre-commit

# Run pre-push checks (thorough)
lefthook run pre-push
```

### ISO Build Test

```bash
# Build and validate ISO
./tools/kiwi-build.sh profile

# Test in VM
./tools/test-iso.sh out/geckoforge-*.iso
```

### Current Status

| Phase | Status |
|-------|--------|
| ISO builds | ✅ |
| First-boot scripts | ✅ |
| NVIDIA driver | ✅ |
| Nix + Home-Manager | ✅ |
| GPU containers | ✅ |
| Mystical Blue theme | ✅ |
| Synergy KVM setup | ✅ |
| Quality gates | ✅ |
| Cloud backups | ✅ |
| Documentation | ✅ |
| VM testing | 🔄 In progress |
| Laptop deployment | ⏸️ Pending |

**See:** [Testing Plan](docs/testing-plan.md) for comprehensive validation procedures

---

## 🛠️ Development

### Build Commands

```bash
# Build ISO
./tools/kiwi-build.sh profile

# Test in VM
./tools/test-iso.sh

# Clean build artifacts
rm -rf out/ work/

# Run quality gates
lefthook run pre-commit
```

### Project Structure

```
geckoforge/
├── profile/  # KIWI profile (Layer 1)
├── home/                           # Home-Manager config (Layer 4)
├── scripts/                        # User setup scripts (Layer 3)
├── docs/                           # Documentation
├── themes/                         # Visual themes
└── tools/                          # Build and test tools
```

---

## 🤝 Contributing

Contributions welcome! Please follow these guidelines:

### Before Contributing

1. **Read documentation** - Especially [Architecture](docs/README.md)
2. **Check `.cursor/rules/`** - Repository conventions and policies
3. **Review existing issues** - Avoid duplicate work

### Contribution Workflow

1. **Fork repository**
2. **Create feature branch** - `git checkout -b feat/amazing-feature`
3. **Make changes** - Follow style canon in `.cursor/rules/00-style-canon.mdc`
4. **Test locally** - Run quality gates: `lefthook run pre-commit`
5. **Update documentation** - Keep docs in sync with code
6. **Commit** - Use conventional commits: `feat(scope): description`
7. **Submit PR** - Clear description, link related issues

### Areas for Contribution

- **Theme variants** - Additional color schemes
- **Language support** - More development toolchains
- **Documentation** - Improve guides, add examples
- **Testing** - Expand test coverage
- **Bug fixes** - See [Issues](https://github.com/jaelliot/geckoforge/issues)

---

## 📋 Roadmap

**Current Focus (v0.2.0):**
- [x] Mystical Blue theme integration
- [x] Synergy KVM support
- [x] Quality gates (Lefthook)
- [x] Encrypted cloud backups
- [x] Docker + NVIDIA automation
- [ ] ISO build automation (CI/CD)
- [ ] Additional theme options
- [ ] Windows migration tooling

**Future Enhancements:**
- Multiple KDE profile variants (minimal, developer, data science)
- Alternative desktop environments (GNOME, XFCE)
- Cloud-init support for automated deployments
- Integration testing framework
- Pre-built ISO releases

**See:** [Daily Summaries](docs/daily-summaries/) for development progress

---

## 🙏 Credits

### Geckoforge

- **Creator**: Jay Elliot ([jaelliot](https://github.com/jaelliot))
- **Philosophy**: "Configure once, avoid BS forever"

### Mystical Blue Theme

- **Author**: Juxtopposed ([GitHub](https://github.com/Juxtopposed))
- **Source**: [Mystical-Blue-Theme](https://github.com/Juxtopposed/Mystical-Blue-Theme)
- **Components**:
  - JuxDeco window decorations
  - JuxPlasma desktop theme
  - NoMansSkyJux Kvantum theme (based on No Man's Sky theme by Patrik Wyde)

### Built With

- **[openSUSE Leap 15.6](https://www.opensuse.org/)** - Base distribution
- **[KIWI NG](https://osinside.github.io/kiwi/)** - Image builder
- **[KDE Plasma](https://kde.org/plasma-desktop/)** - Desktop environment
- **[Nix](https://nixos.org/)** / **[Home-Manager](https://github.com/nix-community/home-manager)** - Package management
- **[Docker](https://www.docker.com/)** - Container runtime
- **[Btrfs](https://btrfs.wiki.kernel.org/)** - Filesystem
- **[Snapper](http://snapper.io/)** - Snapshot management
- **[Lefthook](https://github.com/evilmartians/lefthook)** - Quality gates

---

## 📄 License

This project is licensed under the **Apache License 2.0** - see the [LICENSE](LICENSE) file for details.

**Third-party components:**
- Mystical Blue theme: See theme-specific license files
- Other dependencies: Respective licenses apply

---

## 🔗 Links

- **Repository**: https://github.com/jaelliot/geckoforge
- **Documentation**: [docs/](docs/)
- **Issues**: https://github.com/jaelliot/geckoforge/issues
- **Discussions**: https://github.com/jaelliot/geckoforge/discussions

---

<div align="center">

**Built with ❤️ for the openSUSE community**

*Gecko: Adaptable, resilient, evolved*

**Ready to replace Windows?** → [Get Started](docs/getting-started.md)

</div>