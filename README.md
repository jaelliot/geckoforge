# 🦎 Geckoforge

**Reproducible, production-grade KDE Plasma desktop for openSUSE Leap 15.6**

Built with KIWI NG + Nix + Podman for maximum stability and GPU-accelerated AI workloads.

![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)
![openSUSE](https://img.shields.io/badge/openSUSE-Leap%2015.6-73BA25.svg)
![Desktop](https://img.shields.io/badge/desktop-KDE%20Plasma-1D99F3.svg)

---

## ✨ Features

- 🔒 **Secure by default**: LUKS2 encryption, Secure Boot, AppArmor, firewalld
- 📸 **Instant rollbacks**: Btrfs + Snapper (OS) + Nix generations (apps)
- 🎮 **GPU containers**: NVIDIA driver + Container Toolkit with CDI
- 🔄 **Fully reproducible**: Everything in Git, rebuild ISO anytime
- 🐳 **Rootless Podman**: Containers as systemd services, no Docker daemon
- 🖥️ **KDE Plasma**: Modern, customizable, lightweight desktop

---

## 🎯 Use Case

**"Configure once, avoid BS forever"** workstation for:

- **AI/ML development**: GPU containers for PyTorch, TensorFlow, CUDA
- **Software engineering**: Reproducible dev environments via Nix
- **Content creation**: OBS with NVENC, Kdenlive, GIMP
- **Daily driver**: Replacing Windows 10 with rock-solid Linux

**Hardware**: Powerful workstations/laptops with NVIDIA GPUs

---

## 🚀 Quick Start

### 1. Build ISO

```bash
git clone https://github.com/jaelliot/geckoforge.git
cd geckoforge
./tools/kiwi-build.sh profiles/leap-15.6/kde-nvidia
```

**Output**: `out/geckoforge-leap156-kde.x86_64-*.iso`

### 2. Install to Hardware

1. Write ISO to USB
2. Boot from USB
3. Install (enable LUKS encryption)
4. Reboot

### 3. First Boot (Automatic)

System automatically:
- Detects NVIDIA GPU → installs driver
- Installs Nix with flakes
- Prompts for reboot

### 4. User Setup (Manual)

```bash
git clone https://github.com/jaelliot/geckoforge.git ~/git/geckoforge
cd ~/git/geckoforge
./scripts/firstrun-user.sh
```

See [Getting Started](docs/getting-started.md) for full guide.

---

## 📖 Documentation

| Guide | Description |
|-------|-------------|
| [Getting Started](docs/getting-started.md) | Installation & setup |
| [Testing Plan](docs/testing-plan.md) | VM → Laptop → Production |
| [Backup & Restore](docs/backup-restore.md) | Data safety |
| [Recovery](docs/recovery.md) | Rollback procedures |
| [Podman + NVIDIA](docs/podman-nvidia.md) | GPU containers |
| [OBS NVENC](docs/obs-nvenc-setup.md) | Hardware encoding |
| [Btrfs Layout](docs/btrfs-layout.md) | Subvolume structure |

---

## 🏗️ Architecture

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

**Why this works**:
- **Leap 15.6**: Enterprise stability (18-month releases)
- **Nix**: Reproducible environments, atomic upgrades
- **Flatpak**: Sandboxed apps, auto-updates
- **Btrfs + Snapper**: Instant OS rollbacks
- **Secure Boot + LUKS2**: Security by default

---

## 🧪 Testing Status

| Phase | Status |
|-------|--------|
| ISO builds | ✅ |
| First-boot scripts | ✅ |
| NVIDIA driver | ✅ |
| Nix + Home-Manager | ✅ |
| GPU containers | ✅ |
| Documentation | ✅ |
| VM testing | 🔄 In progress |
| Laptop deployment | ⏸️ Pending |
| Windows replacement | ⏸️ Pending |

---

## 🛠️ Development

### Build

```bash
./tools/kiwi-build.sh profiles/leap-15.6/kde-nvidia
```

### Test in VM

```bash
./tools/test-iso.sh
```

### Clean

```bash
rm -rf out/ work/
```

---

## 📊 Roadmap

- ✅ **v0.1.0**: Basic KIWI profile
- ✅ **v0.2.0**: KDE + GPU containers + docs (current)
- 🔜 **v0.3.0**: CI/CD automation
- 🔜 **v1.0.0**: Battle-tested on production hardware

---

## 🤝 Contributing

Personal project, but you're welcome to:
- Fork for your own use
- Report bugs via Issues
- Share feedback

---

## 📄 License

Apache 2.0 - See [LICENSE](LICENSE)

---

## 🙏 Credits

- [openSUSE Leap](https://www.opensuse.org/)
- [KIWI NG](https://osinside.github.io/kiwi/)
- [Nix](https://nixos.org/) + [Home-Manager](https://github.com/nix-community/home-manager)
- [Podman](https://podman.io/)
- [NVIDIA Container Toolkit](https://github.com/NVIDIA/nvidia-container-toolkit)

---

**Ready to replace Windows?** → [Get Started](docs/getting-started.md)
