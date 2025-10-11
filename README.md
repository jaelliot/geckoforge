<!-- @file README.md --># 🦎 Geckoforge

<!-- @description Main project documentation for geckoforge - openSUSE Leap 15.6 + KDE + NVIDIA custom distribution -->

<!-- @update-policy Update when major features are added, architecture changes, or project goals evolve -->**Reproducible, production-grade KDE Plasma desktop for openSUSE Leap 15.6**



<div align="center">Built with KIWI NG + Nix + Docker for maximum stability and GPU-accelerated AI workloads.



# 🦎 Geckoforge![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)

![openSUSE](https://img.shields.io/badge/openSUSE-Leap%2015.6-73BA25.svg)

**A custom openSUSE Leap 15.6 distribution built with KIWI NG**![Desktop](https://img.shields.io/badge/desktop-KDE%20Plasma-1D99F3.svg)



*Professional workstation image with KDE Plasma, NVIDIA GPU support, and declarative configuration*---



[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)## ✨ Features

[![openSUSE Leap 15.6](https://img.shields.io/badge/openSUSE-Leap%2015.6-73ba25?logo=opensuse)](https://www.opensuse.org/)

[![KDE Plasma](https://img.shields.io/badge/KDE-Plasma%205-1d99f3?logo=kde)](https://kde.org/plasma-desktop/)- 🔒 **Secure by default**: LUKS2 encryption, Secure Boot, AppArmor, firewalld

[![Built with KIWI](https://img.shields.io/badge/built%20with-KIWI%20NG-orange)](https://osinside.github.io/kiwi/)- 📸 **Instant rollbacks**: Btrfs + Snapper (OS) + Nix generations (apps)

- 🎮 **GPU containers**: NVIDIA driver + Container Toolkit with CDI

[Features](#-features) • [Quick Start](#-quick-start) • [Documentation](#-documentation) • [Architecture](#-architecture) • [Contributing](#-contributing)- 🔄 **Fully reproducible**: Everything in Git, rebuild ISO anytime

- 🐳 **Docker + NVIDIA**: Daemon-based runtime with toolkit + CDI for GPU workloads

</div>- 🧱 **Multi-language dev stack**: TypeScript, Go, Python, Nim, C#, R, and Elixir via asdf

- 🖨️ **TeX Live scheme-medium**: Stable 2 GB distribution tuned for Leap 15.6

---- 🖥️ **KDE Plasma**: Modern, customizable, lightweight desktop



## 🎯 Overview---



Geckoforge is a **four-layer reproducible workstation image** targeting developers, data scientists, and power users who need:## 🎯 Use Case



✅ **NVIDIA GPU support** out-of-the-box (Docker + CUDA)  **"Configure once, avoid BS forever"** workstation for:

✅ **Professional theming** with Mystical Blue aesthetic  

✅ **Declarative configuration** via Nix Home-Manager  - **AI/ML development**: GPU containers for PyTorch, TensorFlow, CUDA

✅ **Multi-machine workflows** with KVM switching (Synergy)  - **Software engineering**: Reproducible dev environments via Nix

✅ **Developer toolchains** (Python, Node.js, Go, Elixir, Nim, R, .NET)  - **Content creation**: OBS with NVENC, Kdenlive, GIMP

✅ **Encrypted backups** with rclone and cloud storage  - **Daily driver**: Replacing Windows 10 with rock-solid Linux

✅ **Zero-drift philosophy**: *"Configure once, avoid BS forever"*

**Hardware**: Powerful workstations/laptops with NVIDIA GPUs

Built on **openSUSE Leap 15.6** (enterprise-grade stability) with **KDE Plasma** desktop and **Btrfs + Snapper** for system snapshots.

---

---

## 🚀 Quick Start

## ✨ Features

### 1. Build ISO

### 🎨 Visual Polish

```bash

- **Mystical Blue (Jux) Theme** - Professional dark blue aestheticgit clone https://github.com/jaelliot/geckoforge.git

  - JuxPlasma desktop theme with modern panelscd geckoforge

  - JuxDeco window decorations with rounded corners./tools/kiwi-build.sh profiles/leap-15.6/kde-nvidia

  - NoMansSkyJux Kvantum Qt theme for unified app styling```

  - System-wide color coordination

- **One-command activation** - `./scripts/setup-jux-theme.sh`**Output**: `out/geckoforge-leap156-kde.x86_64-*.iso`

- **Declarative theming** - Optional Home-Manager configuration

### 2. Install to Hardware

### 🚀 GPU-Ready Docker

1. Write ISO to USB

- **Docker Engine** with NVIDIA Container Toolkit2. Boot from USB

- **Automatic GPU detection** and configuration3. Install (enable LUKS encryption)

- **Verified installation** - Tests GPU access in containers4. Reboot

- **Production-ready** - No manual driver management

- **CDI support** - Container Device Interface for resource allocation### 3. First Boot (Automatic)



### 🖥️ Multi-Machine KVMSystem automatically:

- Detects NVIDIA GPU → installs driver

- **Synergy 3 support** - Share keyboard/mouse across computers- Installs Nix with flakes

- **Input Leap alternative** - FOSS option with better Wayland support- Prompts for reboot

- **Automated setup** - Firewall, systemd service, configuration

- **Client & server modes** - Flexible workspace layouts### 4. User Setup (Manual)

- **Interactive wizard** - `./scripts/setup-synergy.sh`

```bash

### 🏠 Declarative Home Environmentgit clone https://github.com/jaelliot/geckoforge.git ~/git/geckoforge

cd ~/git/geckoforge

- **Nix Home-Manager** - Reproducible user configuration./scripts/firstrun-user.sh

- **Version-pinned packages** - No dependency conflicts```

- **Shell configuration** - Zsh + Oh My Zsh + Powerlevel10k

- **Development toolchains** - Multi-language support with asdf-vmSee [Getting Started](docs/getting-started.md) for full guide.

- **Git-tracked configs** - Portable across machines

---

### 💾 Encrypted Cloud Backups

## 📖 Documentation

- **rclone integration** - Supports Google Drive, S3, OneDrive, Backblaze B2

- **Zero-knowledge encryption** - Cloud provider cannot read backups| Guide | Description |

- **Automated schedules** - Daily critical files, weekly projects|-------|-------------|

- **systemd timers** - User-level automation| [Getting Started](docs/getting-started.md) | Installation & setup |

- **Interactive setup** - `./scripts/setup-rclone.sh`| [Testing Plan](docs/testing-plan.md) | VM → Laptop → Production |

| [Backup & Restore](docs/backup-restore.md) | Data safety |

### 🛠️ Developer Toolchains| [Recovery](docs/recovery.md) | Rollback procedures |

| [Podman → Docker Migration](docs/podman-to-docker-migration.md) | Rationale & command map |

**Languages:**| [Docker + NVIDIA](docs/docker-nvidia.md) | GPU containers |

- Python 3.12 (with ruff, black, pytest)| [TeX Verification](docs/tex-verification.md) | Validate TeX Live scheme-medium |

- Node.js (via asdf-vm)| [OBS NVENC](docs/obs-nvenc-setup.md) | Hardware encoding |

- Go, Nim, Elixir, R, .NET 9| [Btrfs Layout](docs/btrfs-layout.md) | Subvolume structure |

- LaTeX (TeX Live scheme-medium - 2GB stable distribution)

---

**Tools:**

- Docker + docker-compose with GPU support## 🏗️ Architecture

- Git with sensible defaults and delta pager

- VS Code, Cursor, WebStorm (via script setup)### Three-Layer Package Management

- MongoDB Compass, DBeaver, Postman (Flatpak)

```

### 🔒 System Resilience┌─────────────────────────────────────┐

│ Layer 3: Flatpak (Sandboxed GUI)   │

- **Btrfs filesystem** - Copy-on-write, compression, snapshots│ OBS, Signal, DBeaver, Postman, etc. │

- **Snapper integration** - Automatic pre/post-update snapshots└─────────────────────────────────────┘

- **GRUB snapshot boot** - Rollback from boot menu              ↓

- **Home-Manager generations** - Rollback user environment┌─────────────────────────────────────┐

- **LUKS2 encryption** - Full-disk encryption with secure defaults│ Layer 2: Nix (Reproducible Apps)    │

│ Dev tools, CLI utils, pinned with   │

### ⚡ Quality Gates│ flake.lock                          │

└─────────────────────────────────────┘

- **Lefthook pre-commit** - Fast syntax checks (<30s)              ↓

  - Shell script validation (shellcheck + bash -n)┌─────────────────────────────────────┐

  - Nix expression evaluation│ Layer 1: zypper (Base OS)           │

  - Anti-pattern detection (Podman usage, wrong TeX scheme)│ Kernel, NVIDIA driver, systemd,     │

- **Lefthook pre-push** - Thorough validation│ KDE Plasma                          │

  - Layer boundary enforcement└─────────────────────────────────────┘

  - Package policy compliance```

  - Documentation synchronization

**Why this works**:

---- **Leap 15.6**: Enterprise stability (18-month releases)

- **Nix**: Reproducible environments, atomic upgrades

## 🚀 Quick Start- **Flatpak**: Sandboxed apps, auto-updates

- **Btrfs + Snapper**: Instant OS rollbacks

### Prerequisites- **Secure Boot + LUKS2**: Security by default



- **openSUSE Leap 15.6** (or compatible) for building---

- **KIWI NG** installed (`zypper install kiwi-ng`)

- **NVIDIA GPU** (optional - detects and configures automatically)## 🧪 Testing Status

- **8+ GB RAM** and **50+ GB disk** for ISO build

| Phase | Status |

### Build the ISO|-------|--------|

| ISO builds | ✅ |

```bash| First-boot scripts | ✅ |

# Clone repository| NVIDIA driver | ✅ |

git clone https://github.com/jaelliot/geckoforge.git| Nix + Home-Manager | ✅ |

cd geckoforge| GPU containers | ✅ |

| Documentation | ✅ |

# Build ISO| VM testing | 🔄 In progress |

./tools/kiwi-build.sh profiles/leap-15.6/kde-nvidia| Laptop deployment | ⏸️ Pending |

| Windows replacement | ⏸️ Pending |

# ISO created in: out/geckoforge-leap156-kde.x86_64-*.iso

```---



**Build time:** ~10-15 minutes (depending on network/CPU)## 🛠️ Development



### Install to Hardware### Build



1. **Create bootable USB:**```bash

   ```bash./tools/kiwi-build.sh profiles/leap-15.6/kde-nvidia

   sudo dd if=out/geckoforge-*.iso of=/dev/sdX bs=4M status=progress```

   sync

   ```### Test in VM



2. **Boot from USB** (disable Secure Boot temporarily)```bash

./tools/test-iso.sh

3. **Install** - Follow installer prompts```

   - Enable disk encryption (recommended)

   - Set strong user password### Clean



4. **First boot** - System automatically:```bash

   - Installs NVIDIA drivers (if GPU detected)rm -rf out/ work/

   - Installs Nix package manager with flakes```

   - Prompts for reboot

---

5. **User setup** - Run wizard:

   ```bash## 📊 Roadmap

   cd ~/git

   git clone https://github.com/jaelliot/geckoforge.git- ✅ **v0.1.0**: Basic KIWI profile

   cd geckoforge- ✅ **v0.2.0**: KDE + GPU containers + docs (current)

   ./scripts/firstrun-user.sh- 🔜 **v0.3.0**: CI/CD automation

   ```- 🔜 **v1.0.0**: Battle-tested on production hardware



**Total time:** ~45 minutes (build + install + setup)---



**Next steps:** See [Getting Started Guide](docs/getting-started.md)## 🤝 Contributing



---Personal project, but you're welcome to:

- Fork for your own use

## 📚 Documentation- Report bugs via Issues

- Share feedback

### User Guides

---

- **[Getting Started](docs/getting-started.md)** - Installation and initial setup

- **[Docker + NVIDIA](docs/docker-nvidia.md)** - GPU container workflows## 📄 License

- **[Themes](docs/themes.md)** - Theme activation and customization

- **[Synergy Setup](docs/synergy-setup.md)** - Multi-machine KVM configurationApache 2.0 - See [LICENSE](LICENSE)

- **[Backup & Recovery](docs/backup-recovery.md)** - Cloud backups and system restore

- **[Testing Plan](docs/testing-plan.md)** - Validation procedures---



### Architecture## 🙏 Credits



- **[Architecture Overview](docs/architecture/README.md)** - Four-layer design- [openSUSE Leap](https://www.opensuse.org/)

- **[Directory Structure](docs/architecture/directory-tree.md)** - Repository layout- [KIWI NG](https://osinside.github.io/kiwi/)

- **[Btrfs Layout](docs/btrfs-layout.md)** - Filesystem and snapshots- [Nix](https://nixos.org/) + [Home-Manager](https://github.com/nix-community/home-manager)

- [Docker](https://www.docker.com/)

### Development- [NVIDIA Container Toolkit](https://github.com/NVIDIA/nvidia-container-toolkit)



- **[Daily Summaries](docs/daily-summaries/)** - Development log---

- **[Contributing](#-contributing)** - How to contribute

- **[Cursor Rules](.cursor/rules/)** - AI assistant guidelines**Ready to replace Windows?** → [Get Started](docs/getting-started.md)


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

**See:** [Architecture Documentation](docs/architecture/README.md)

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
./tools/kiwi-build.sh profiles/leap-15.6/kde-nvidia

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
./tools/kiwi-build.sh profiles/leap-15.6/kde-nvidia

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
├── profiles/leap-15.6/kde-nvidia/  # KIWI profile (Layer 1)
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

1. **Read documentation** - Especially [Architecture](docs/architecture/README.md)
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