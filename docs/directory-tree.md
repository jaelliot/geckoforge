# Geckoforge Directory Structure

> **Last updated:** 2026-01-12
> 
> This document reflects the flattened v0.4.0 structure after the January 2026 audit remediation.

```
geckoforge/
├── .github/
│   ├── instructions/           # Copilot path-specific instructions
│   │   ├── 00-style-canon.instructions.md
│   │   ├── 05-project-overview.instructions.md
│   │   ├── 10-kiwi-architecture.instructions.md
│   │   ├── 20-nix-home-management.instructions.md
│   │   ├── 25-lefthook-quality.instructions.md
│   │   ├── 30-container-runtime.instructions.md
│   │   ├── 40-documentation.instructions.md
│   │   ├── 50-testing-deployment.instructions.md
│   │   ├── 55-networking-privacy.instructions.md
│   │   ├── 60-package-management.instructions.md
│   │   ├── 65-backup-restore.instructions.md
│   │   ├── 70-troubleshooting.instructions.md
│   │   ├── 75-ide-config.instructions.md
│   │   └── copilot-instructions.md
│   ├── skills/                 # Copilot task-specific skills
│   │   ├── anti-pattern-prevention.md
│   │   ├── audit-compliance-checklist.md
│   │   ├── firstboot-services.md
│   │   ├── kiwi-build-environment.md
│   │   ├── kiwi-schema-validation.md
│   │   └── nvidia-driver-installation.md
│   └── workflows/              # GitHub Actions
├── docs/
│   ├── audits/                 # Quality audits
│   ├── prompts/                # AI prompt templates
│   ├── research/               # Research documents and audit reports
│   └── summaries/              # Development session logs
├── examples/
│   ├── cuda-nv-smi/            # CUDA container example
│   ├── postgres-docker-compose/ # PostgreSQL with Docker
│   └── systemd-gpu-service/    # GPU systemd service
├── home/                       # Home-Manager (Nix) configuration
│   ├── modules/                # Modular configs by domain
│   │   ├── auto-updates.nix
│   │   ├── backup.nix
│   │   ├── cli.nix
│   │   ├── desktop.nix
│   │   ├── development.nix
│   │   ├── docker.nix
│   │   ├── elixir.nix
│   │   ├── espanso.nix
│   │   ├── firefox.nix
│   │   ├── gaming.nix
│   │   ├── kde-theme.nix       # JuxTheme + Night Color
│   │   ├── macos-keyboard.nix
│   │   ├── network.nix
│   │   ├── power.nix
│   │   ├── privacy.nix
│   │   ├── security.nix
│   │   ├── shell.nix
│   │   ├── thunderbird.nix
│   │   ├── vscode.nix
│   │   └── winapps.nix
│   ├── flake.lock
│   ├── flake.nix
│   └── home.nix
├── packer/                     # Alternative ISO build via Packer
│   ├── http/
│   │   └── autoyast.xml
│   ├── build.sh
│   ├── opensuse-leap-geckoforge.pkr.hcl
│   └── README.md
├── profile/                    # KIWI NG profile (Layer 1)
│   ├── root/                   # File overlays (copied to image)
│   │   ├── etc/
│   │   │   ├── firefox/policies/
│   │   │   ├── snapper/configs/
│   │   │   ├── systemd/system/     # First-boot services
│   │   │   └── zypp/repos.d/       # NVIDIA repo
│   │   └── usr/
│   │       ├── local/sbin/         # First-boot scripts
│   │       └── share/              # Themes (Jux*)
│   ├── scripts/                # DEPRECATED - use root/usr/local/sbin/
│   ├── config.sh               # Post-prepare script
│   └── config.xml              # KIWI NG configuration (NOT .kiwi.xml!)
├── scripts/                    # User setup scripts (Layer 3)
│   ├── apply-performance-optimizations.sh
│   ├── docker-nvidia-install.sh
│   ├── docker-nvidia-verify.sh
│   ├── firstrun-user.sh        # Main setup wizard
│   ├── setup-chrome.sh
│   ├── setup-docker.sh
│   ├── setup-firewall.sh
│   ├── setup-protonmail-bridge.sh
│   ├── setup-rclone.sh
│   ├── setup-synergy.sh
│   └── setup-winapps.sh
├── themes/                     # Theme source files
│   ├── JuxDeco/                # Window decoration (Aurorae)
│   ├── JuxPlasma/              # Plasma desktop theme
│   ├── NoMansSkyJux/           # Kvantum Qt theme
│   └── JuxTheme.colors         # KDE color scheme
├── tools/                      # Build and validation tools
│   ├── check-anti-patterns.sh
│   ├── check-layer-assignments.sh
│   ├── kiwi-build.sh
│   ├── test-iso.sh
│   └── verify-no-telemetry.sh
├── LICENSE
├── README.md
└── lefthook.yml
```

## Key Directories

### profile/ - KIWI NG Image Definition
The primary KIWI profile for building the ISO. Contains:
- `config.xml` - Main KIWI NG description file (**NOT** `config.kiwi.xml`)
- `config.sh` - Post-prepare script that sets permissions and enables services
- `root/` - Overlay directory; files here are copied to the same path in the image

### home/ - Home-Manager Configuration
Nix-based user environment configuration. Modules are imported in `home.nix`:
- `kde-theme.nix` - Mystical Blue (Jux) theme activation
- `development.nix` - Programming languages and tools
- `cli.nix` - Shell configuration and CLI utilities

### scripts/ - User Setup Scripts
Post-installation scripts run manually by user (Layer 3):
- `firstrun-user.sh` - Main setup wizard that orchestrates other scripts
- `setup-docker.sh` - Docker installation with NVIDIA support
- `setup-firewall.sh` - Security hardening

### themes/ - Theme Source Files
Source files for the Mystical Blue (Jux) theme. These are:
1. Kept in `themes/` for version control
2. Copied to `profile/root/usr/share/` for ISO inclusion
3. Installed system-wide when ISO is built

## Removed/Deprecated

The following were removed in v0.4.0 flattening:
- ❌ `profiles/leap-15.6/kde-nvidia/` → Replaced by `profile/`
- ❌ `config.kiwi.xml` → Renamed to `config.xml`
- ❌ `scripts/examples/` → Moved to `examples/`
- ❌ `profile/scripts/` → Use `profile/root/usr/local/sbin/` instead

## Generated Directories (gitignored)

- `out/` - Built ISO images
- `work/` - KIWI NG work files during build
