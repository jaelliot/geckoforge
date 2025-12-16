# Docker + NVIDIA GPU Containers

This guide explains how to enable and validate GPU-accelerated Docker containers on Geckoforge v0.3.0.

## Prerequisites

- NVIDIA GPU (verify with `lspci | grep -i nvidia`)
- Geckoforge ISO installed with first-boot scripts completed
- Docker installed via `scripts/firstrun-user.sh`

## Architecture

```
┌─────────────────────────────────────┐
│ Container                           │
│  └─ App (PyTorch, CUDA, Phoenix)    │
└─────────────────────────────────────┘
              ↓ --gpus all
┌─────────────────────────────────────┐
│ Docker Engine + NVIDIA runtime      │
│  └─ /etc/docker/daemon.json         │
└─────────────────────────────────────┘
              ↓ CDI devices
┌─────────────────────────────────────┐
│ NVIDIA Container Toolkit (nvidia-ctk) │
│  └─ /etc/cdi/nvidia.yaml             │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│ Host NVIDIA Driver (zypper)         │
│  └─ /usr/bin/nvidia-smi             │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│ NVIDIA GPU Hardware                 │
└─────────────────────────────────────┘
```

## Step-by-step setup

### 1. Host driver (automatic)

`firstboot-nvidia.sh` installs the correct driver during first boot. Confirm:

```bash
nvidia-smi
```

### 2. Install NVIDIA Container Toolkit

```bash
~/git/geckoforge/scripts/docker-nvidia-install.sh
```

The script:

1. Adds the NVIDIA container repository
2. Installs `nvidia-container-toolkit`
3. Configures Docker's runtime via `nvidia-ctk runtime configure`
4. Restarts Docker

### 3. Verify GPU access

```bash
~/git/geckoforge/scripts/docker-nvidia-verify.sh
```

This runs three checks: host driver, Docker runtime, and a CUDA container smoke test.

## Everyday usage

### Quick CUDA test

```bash
docker run --rm --gpus all \
  docker.io/nvidia/cuda:12.4.0-base-ubuntu22.04 \
  nvidia-smi
```

### Interactive development container

```bash
docker run -it --rm --gpus all \
  -v "$PWD:/workspace" \
  -w /workspace \
  docker.io/nvidia/cuda:12.4.0-devel-ubuntu22.04 \
  bash
```

Inside the container:

```bash
nvidia-smi
nvcc --version
```

### Running Phoenix assets (Node.js)

```bash
docker run --rm --gpus all \
  -v "$PWD:/app" -w /app \
  -p 4000:4000 \
  docker.io/hexpm/elixir:1.18.4-erlang-28.1-debian-bookworm-20240115 \
  mix phx.server
```

### Systemd service

Use the example in `examples/systemd-gpu-service/` to generate user services with Docker Compose or plain `docker run`.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `docker: Error response from daemon: could not select device driver "nvidia"` | Re-run `docker-nvidia-install.sh`; check `/etc/docker/daemon.json`. |
| `permission denied` on `/var/run/docker.sock` | Run `newgrp docker` or log out/in. |
| `nvidia-smi` works on host but not in container | Run `docker-nvidia-verify.sh`; ensure CUDA image matches driver (check `nvidia-smi` output). |
| `unknown runtime specified nvidia` | `sudo systemctl restart docker` after running the install script. |

## Maintenance tips

- Update CUDA base images regularly: `docker pull nvidia/cuda:12.4.0-base-ubuntu22.04`
- Review `/etc/docker/daemon.json` after upgrades to ensure the NVIDIA runtime is still configured.
- For multi-GPU systems, use `--gpus "device=GPU-UUID"` or `--gpus "device=0"` to target a specific card.