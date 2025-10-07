.
├── home
│   ├── modules
│   │   ├── cli.nix
│   │   ├── desktop.nix
│   │   └── development.nix
│   ├── flake.nix
│   └── home.nix
├── profiles
│   └── leap-15.6
│       └── kde-nvidia
│           ├── root
│           │   └── etc
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
│   │   └── systemd-gpu-service
│   │       ├── Makefile
│   │       └── README.md
│   ├── firstrun-user.sh
│   ├── harden.sh
│   ├── install-flatpaks.sh
│   ├── podman-compose-install.sh
│   ├── podman-loginctl-linger.sh
│   ├── podman-nvidia-install.sh
│   ├── podman-nvidia-verify.sh
│   ├── prune-containers.service
│   ├── prune-containers.timer
│   ├── setup-chrome.sh
│   └── setup-podman.sh
├── tools
│   └── kiwi-build.sh
├── .gitignore
├── LICENSE
└── README.md

19 directories, 26 files
