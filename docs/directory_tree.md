.
├── .cursor
│   └── rules
│       ├── 00-style-canon.mdc
│       ├── 05-project-overview.mdc
│       ├── 10-kiwi-architecture.mdc
│       ├── 20-nix-home-management.mdc
│       ├── 25-lefthook-quality.mdc
│       ├── 30-container-runtime.mdc
│       ├── 40-documentation.mdc
│       ├── 50-testing-deployment.mdc
│       ├── 55-networking-privacy.mdc
│       ├── 60-package-management.mdc
│       ├── 65-backup-restore.mdc
│       ├── 70-troubleshooting.mdc
│       ├── 75-ide-config.mdc
│       └── RULES_INDEX.md
├── .github
│   ├── instructions
│   │   ├── 00-style-canon.instructions.md
│   │   ├── 05-project-overview.instructions.md
│   │   ├── 10-kiwi-architecture.instructions.md
│   │   ├── 20-nix-home-management.instructions.md
│   │   ├── 25-lefthook-quality.instructions.md
│   │   ├── 30-container-runtime.instructions.md
│   │   ├── 40-documentation.instructions.md
│   │   ├── 50-testing-deployment.instructions.md
│   │   ├── 55-networking-privacy.instructions.md
│   │   ├── 60-package-management.instructions.md
│   │   ├── 65-backup-restore.instructions.md
│   │   ├── 70-troubleshooting.instructions.md
│   │   ├── 75-ide-config.instructions.md
│   │   └── copilot-instructions.md
│   └── workflows
├── docs
│   ├── architecture
│   │   ├── README.md
│   │   └── directory-tree.md
│   ├── audits
│   │   └── 2025-12-15-instructions-audit.md
│   ├── daily-summaries
│   │   ├── 2025-01
│   │   ├── 2025-10
│   │   │   ├── 2025-10-06.md
│   │   │   ├── 2025-10-08.md
│   │   │   ├── 2025-10-10.md
│   │   │   ├── 2025-10-11.md
│   │   │   ├── 2025-10-15.md
│   │   │   └── 2025-10-16.md
│   │   ├── 2025-12
│   │   │   └── 2025-12-15.md
│   │   └── .gitkeep
│   ├── guides
│   │   ├── keyboard-configuration.md
│   │   ├── night-color.md
│   │   ├── security-configuration.md
│   │   └── winapps.md
│   ├── resources
│   │   └── readme.md
│   ├── templates
│   │   ├── claude-project-instructions.md
│   │   ├── deep-research-deployment-readiness.md
│   │   ├── implementation-prompt.md
│   │   └── task-implementation-format.md
│   ├── to-do
│   │   └── questions.md
│   ├── backup-recovery.md
│   ├── backup-restore.md
│   ├── btrfs-layout.md
│   ├── directory_tree.md
│   ├── docker-nvidia.md
│   ├── font-configuration.md
│   ├── getting-started.md
│   ├── obs-nvenc-setup.md
│   ├── recovery.md
│   ├── synergy-setup.md
│   ├── testing-plan.md
│   ├── tex-verification.md
│   ├── themes.md
│   └── thunderbird-setup.md
├── home
│   ├── modules
│   │   ├── backup.nix
│   │   ├── cli.nix
│   │   ├── desktop.nix
│   │   ├── development.nix
│   │   ├── elixir.nix
│   │   ├── firefox.nix
│   │   ├── kde-theme.nix
│   │   ├── macos-keyboard.nix
│   │   ├── security.nix
│   │   ├── shell.nix
│   │   ├── thunderbird.nix
│   │   └── winapps.nix
│   ├── flake.nix
│   └── home.nix
├── profiles
│   └── leap-15.6
│       └── kde-nvidia
│           ├── root
│           │   ├── etc
│           │   │   ├── firefox
│           │   │   │   └── policies
│           │   │   ├── snapper
│           │   │   │   └── configs
│           │   │   ├── systemd
│           │   │   │   └── system
│           │   │   └── zypp
│           │   │       └── repos.d
│           │   └── usr
│           │       └── share
│           │           ├── Kvantum
│           │           ├── aurorae
│           │           ├── color-schemes
│           │           └── plasma
│           ├── scripts
│           │   ├── firstboot-nix.sh
│           │   ├── firstboot-nvidia.sh
│           │   └── firstboot-ssh-hardening.sh
│           └── config.kiwi.xml
├── scripts
│   ├── examples
│   │   ├── cuda-nv-smi
│   │   │   └── README.md
│   │   ├── postgres-docker-compose
│   │   │   ├── README.md
│   │   │   └── docker-compose.yml
│   │   └── systemd-gpu-service
│   │       ├── Makefile
│   │       └── README.md
│   ├── check-backups.sh
│   ├── configure-night-color.sh
│   ├── docker-nvidia-install.sh
│   ├── docker-nvidia-verify.sh
│   ├── firstrun-user.sh
│   ├── harden.sh
│   ├── install-flatpaks.sh
│   ├── make-executable.sh
│   ├── prune-containers.service
│   ├── prune-containers.timer
│   ├── setup-auto-updates.sh
│   ├── setup-chrome.sh
│   ├── setup-docker.sh
│   ├── setup-jux-theme.sh
│   ├── setup-macos-keyboard.sh
│   ├── setup-protonmail-bridge.sh
│   ├── setup-rclone.sh
│   ├── setup-secure-dns.sh
│   ├── setup-secure-firewall.sh
│   ├── setup-shell.sh
│   ├── setup-synergy.sh
│   ├── setup-winapps.sh
│   ├── test-macos-keyboard.sh
│   └── test-night-color.sh
├── themes
│   ├── JuxDeco
│   │   ├── AUTHORS
│   │   ├── JuxDecorc
│   │   ├── alldesktops.svg
│   │   ├── close.svg
│   │   ├── decoration.svg
│   │   ├── keepabove.svg
│   │   ├── keepbelow.svg
│   │   ├── maximize.svg
│   │   ├── metadata.desktop
│   │   ├── metadata.json
│   │   ├── minimize.svg
│   │   └── restore.svg
│   ├── JuxPlasma
│   │   ├── dialogs
│   │   │   └── background.svgz
│   │   ├── weather
│   │   │   └── wind-arrows.svgz
│   │   ├── widgets
│   │   │   ├── actionbutton.svgz
│   │   │   ├── arrows.svgz
│   │   │   ├── background.svgz
│   │   │   ├── bar_meter_horizontal.svgz
│   │   │   ├── bar_meter_vertical.svgz
│   │   │   ├── busywidget.svgz
│   │   │   ├── button.svgz
│   │   │   ├── calendar.svgz
│   │   │   ├── checkmarks.svg
│   │   │   ├── clock.svgz
│   │   │   ├── configuration-icons.svgz
│   │   │   ├── containment-controls.svgz
│   │   │   ├── frame.svgz
│   │   │   ├── glowbar.svgz
│   │   │   ├── line.svgz
│   │   │   ├── lineedit.svgz
│   │   │   ├── listitem.svgz
│   │   │   ├── margins-highlight.svgz
│   │   │   ├── menubaritem.svgz
│   │   │   ├── pager.svgz
│   │   │   ├── panel-background.svgz
│   │   │   ├── plasmoidheading.svgz
│   │   │   ├── plot-background.svgz
│   │   │   ├── radiobutton.svgz
│   │   │   ├── scrollbar.svgz
│   │   │   ├── scrollwidget.svgz
│   │   │   ├── slider.svgz
│   │   │   ├── tabbar.svgz
│   │   │   ├── tasks.svgz
│   │   │   ├── timer.svgz
│   │   │   ├── toolbar.svgz
│   │   │   ├── tooltip.svgz
│   │   │   ├── translucentbackground.svgz
│   │   │   └── viewitem.svgz
│   │   ├── colors
│   │   ├── metadata.json
│   │   └── plasmarc
│   ├── NoMansSkyJux
│   │   ├── NoMansSkyJux.kvconfig
│   │   └── NoMansSkyJux.svg
│   └── JuxTheme.colors
├── tools
│   ├── validate
│   │   ├── check-anti-patterns.sh
│   │   └── check-layer-assignments.sh
│   ├── kiwi-build.sh
│   └── test-iso.sh
├── .gitignore
├── LICENSE
├── README.md
└── lefthook.yml

52 directories, 172 files
