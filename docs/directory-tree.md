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
├── .vscode
│   ├── instructions
│   └── .gitkeep
├── home
│   ├── modules
│   │   ├── cli.nix
│   │   ├── desktop.nix
│   │   ├── development.nix
│   │   ├── elixir.nix
│   │   └── firefox.nix
│   ├── flake.nix
│   └── home.nix
├── profiles
│   └── leap-15.6
│       └── kde-nvidia
│           ├── root
│           │   └── etc
│           │       ├── firefox
│           │       │   └── policies
│           │       ├── snapper
│           │       │   └── configs
│           │       ├── systemd
│           │       │   └── system
│           │       └── zypp
│           │           └── repos.d
│           ├── scripts
│           │   ├── firstboot-nix.sh
│           │   └── firstboot-nvidia.sh
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
│   ├── docker-nvidia-install.sh
│   ├── docker-nvidia-verify.sh
│   ├── firstrun-user.sh
│   ├── harden.sh
│   ├── install-flatpaks.sh
│   ├── make-executable.sh
│   ├── prune-containers.service
│   ├── prune-containers.timer
│   ├── setup-chrome.sh
│   └── setup-docker.sh
├── tools
│   ├── kiwi-build.sh
│   └── test-iso.sh
├── .gitignore
├── LICENSE
└── README.md

26 directories, 45 files
