# Podman + NVIDIA GPU Containers

Complete guide for GPU-accelerated containers on geckoforge.

## Prerequisites

- NVIDIA GPU (check: `lspci | grep -i nvidia`)
- openSUSE Leap 15.6 with geckoforge profile

## Architecture

```
┌─────────────────────────────────────┐
│ Container                           │
│  └─ App (PyTorch, CUDA, etc.)       │
└─────────────────────────────────────┘
              ↓ CDI device
┌─────────────────────────────────────┐
│ NVIDIA Container Toolkit            │
│  └─ /etc/cdi/nvidia.yaml            │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│ Host NVIDIA Driver (from SUSE repo) │
│  └─ /usr/bin/nvidia-smi             │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│ NVIDIA GPU (Hardware)               │
└─────────────────────────────────────┘
```

## Setup Steps

### 1. Host Driver (first boot - automatic)

Geckoforge's `firstboot-nvidia.sh` detects your GPU and installs:
- `nvidia-open-driver-G06-signed` (preferred, Secure Boot compatible)
- OR `nvidia-driver-G06` (fallback)

**Verify**:
```bash
nvidia-smi  # Should show GPU, driver version, CUDA version
```

### 2. Container Toolkit + CDI

Run the setup script:
```bash
~/scripts/podman-nvidia-install.sh
```

This:
1. Adds NVIDIA Container Toolkit repo
2. Installs `nvidia-container-toolkit`
3. Generates CDI spec at `/etc/cdi/nvidia.yaml`
4. Lists available GPU devices

**Verify**:
```bash
nvidia-ctk cdi list
# Output: nvidia.com/gpu=0  (or =all for all GPUs)
```

### 3. Test GPU Access

Run the verification script:
```bash
~/scripts/podman-nvidia-verify.sh
```

This tests:
- Host driver
- Container GPU access (root)
- Container GPU access (rootless)

## Usage

### Quick test (CLI)

```bash
podman run --rm --device nvidia.com/gpu=all \
  docker.io/nvidia/cuda:12.4.0-base-ubuntu22.04 \
  nvidia-smi
```

### Interactive CUDA container

```bash
podman run -it --device nvidia.com/gpu=all \
  docker.io/nvidia/cuda:12.4.0-devel-ubuntu22.04 \
  bash

# Inside container:
nvidia-smi
nvcc --version
```

### Run your code with GPU

```bash
podman run --rm \
  --device nvidia.com/gpu=all \
  -v "$PWD:/workspace:Z" \
  -w /workspace \
  docker.io/pytorch/pytorch:latest \
  python train.py
```

### GPU container as systemd service

See `scripts/examples/systemd-gpu-service/` for full example.

**Quick version**:
```bash
# 1. Create named container
podman create \
  --name ollama-gpu \
  --device nvidia.com/gpu=all \
  -p 11434:11434 \
  docker.io/ollama/ollama:latest

# 2. Generate systemd unit
mkdir -p ~/.config/systemd/user
podman generate systemd --new --name ollama-gpu --files \
  > ~/.config/systemd/user/ollama-gpu.service

# 3. Enable and start
systemctl --user daemon-reload
systemctl --user enable --now ollama-gpu.service
```

## Compose (GPU)

Podman Compose supports GPU, but CDI syntax varies by version. Prefer `podman run` + systemd for GPU workloads.

**If using Compose**:
```yaml
version: '3.8'
services:
  gpu-app:
    image: nvidia/cuda:12.4.0-base
    devices:
      - nvidia.com/gpu=all
    command: nvidia-smi
```

## Common Issues

### "no devices found" when running container

**Cause**: CDI spec not generated or outdated.

**Fix**:
```bash
sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
nvidia-ctk cdi list  # Verify devices appear
```

### "could not load library libcuda.so"

**Cause**: Driver not installed or wrong version.

**Fix**:
```bash
nvidia-smi  # Should work on host first
sudo zypper up nvidia-*  # Update if needed
sudo reboot
```

### Container works as root, fails as user

**Cause**: Permissions or rootless Podman config.

**Fix**:
```bash
# Check subuid/subgid
grep "^$USER:" /etc/subuid /etc/subgid

# Reinitialize Podman
podman system migrate
```

### CDI devices not visible after driver update

**Cause**: CDI spec references old driver paths.

**Fix**:
```bash
sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
podman run --rm --device nvidia.com/gpu=all nvidia/cuda:12.4.0-base nvidia-smi
```

## Advanced: Multiple GPUs

**List devices**:
```bash
nvidia-ctk cdi list
# nvidia.com/gpu=0
# nvidia.com/gpu=1
# nvidia.com/gpu=all
```

**Use specific GPU**:
```bash
podman run --rm --device nvidia.com/gpu=0 nvidia/cuda:12.4.0-base nvidia-smi
```

**Use multiple GPUs**:
```bash
podman run --rm \
  --device nvidia.com/gpu=0 \
  --device nvidia.com/gpu=1 \
  nvidia/cuda:12.4.0-base nvidia-smi
```

## References

- [NVIDIA Container Toolkit Docs](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/)
- [CDI Specification](https://github.com/cncf-tags/container-device-interface)
- [Podman Rootless Docs](https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md)
