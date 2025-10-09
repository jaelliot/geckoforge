.
├── home
│   ├── modules
│   │   ├── cli.nix
│   │   ├── desktop.nix
│   │   ├── development.nix
│   │   └── elixir.nix
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
│   │   ├── postgres-docker-compose
│   │   │   ├── README.md
│   │   │   └── docker-compose.yml
│   │   └── systemd-gpu-service
│   │       ├── Makefile
│   │       └── README.md
│   ├── firstrun-user.sh
│   ├── harden.sh
│   ├── install-flatpaks.sh
│   ├── docker-nvidia-install.sh
│   ├── docker-nvidia-verify.sh
│   ├── prune-containers.service
│   ├── prune-containers.timer
│   ├── setup-chrome.sh
│   └── setup-docker.sh
├── tools
│   └── kiwi-build.sh
├── .gitignore
├── LICENSE
└── README.md

20 directories, 25 files
