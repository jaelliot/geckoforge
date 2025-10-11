---
applyTo: "**/*Dockerfile*,**/*docker-compose*.yml,**/*compose*.yml,scripts/**docker**"
---

---
description: Docker-only container runtime with NVIDIA GPU support policies
globs: ["scripts/*docker*.sh", "scripts/firstrun-user.sh", "docs/*docker*.md", "scripts/examples/**"]
alwaysApply: false
---

## Use when
- Setting up container runtimes or GPU acceleration
- Creating scripts that interact with containers
- Documenting container workflows
- Writing examples using Docker/NVIDIA

## Container Runtime Policy (MANDATORY)

### Docker Only - No Podman
This project uses **Docker exclusively**. Podman has been completely removed.

**Rationale:**
- User preference for Docker ecosystem
- Simpler NVIDIA integration
- Better compatibility with existing workflows
- No runtime confusion

---

## Docker Installation (Layer 3: User Setup)

### Installation Script Pattern (REQUIRED)
```bash
# scripts/setup-docker.sh

#!/usr/bin/env bash
set -euo pipefail

echo "[docker] Installing Docker..."

# Remove Podman if present
if command -v podman >/dev/null 2>&1; then
    echo "[docker] Removing Podman..."
    sudo zypper remove -y podman buildah skopeo
    
    # Offer to remove Podman data
    read -p "Remove Podman data (~/.local/share/containers)? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf ~/.local/share/containers
    fi
fi

# Install Docker
sudo zypper install -y docker docker-compose

# Enable and start daemon
sudo systemctl enable --now docker

# Add user to docker group
sudo usermod -aG docker "$USER"

echo "[docker] Installation complete!"
echo "⚠️  Log out and back in for group changes to take effect"
```

**Key points:**
- ✅ Automatic Podman removal
- ✅ Prompt for data cleanup
- ✅ Docker daemon enabled/started
- ✅ User added to docker group
- ⚠️ Requires logout/login for group activation

---

## NVIDIA GPU Support

### Architecture
```
┌─────────────────────────────────────┐
│ Container (CUDA app)                │
└─────────────────────────────────────┘
              ↓ --gpus all
┌─────────────────────────────────────┐
│ NVIDIA Container Toolkit            │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│ Host NVIDIA Driver                  │
│ (from openSUSE/NVIDIA repos)        │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│ NVIDIA GPU (Hardware)               │
└─────────────────────────────────────┘
```

### NVIDIA Container Toolkit Installation
```bash
# scripts/docker-nvidia-install.sh

#!/usr/bin/env bash
set -euo pipefail

# Verify NVIDIA driver is installed
if ! command -v nvidia-smi >/dev/null 2>&1; then
    echo "[ERROR] NVIDIA driver not found"
    exit 1
fi

echo "[nvidia] Installing NVIDIA Container Toolkit..."

# Add NVIDIA Container Toolkit repository
DIST="opensuse15.6"
curl -s -L https://nvidia.github.io/libnvidia-container/$DIST/libnvidia-container.repo | \
    sudo tee /etc/zypp/repos.d/nvidia-container-toolkit.repo >/dev/null

# Install toolkit
sudo zypper refresh
sudo zypper install -y nvidia-container-toolkit

# Configure Docker daemon
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

echo "[nvidia] Setup complete!"
```

### Verification Script
```bash
# scripts/docker-nvidia-verify.sh

#!/usr/bin/env bash
set -euo pipefail

CUDA_IMAGE="nvidia/cuda:12.4.0-base-ubuntu22.04"

echo "=== NVIDIA Docker Verification ==="
echo ""

# Test 1: Host driver
echo "[1/2] Host driver check:"
if nvidia-smi; then
    echo "✓ Host driver OK"
else
    echo "✗ Host driver FAILED"
    exit 1
fi

# Test 2: Container GPU access
echo ""
echo "[2/2] Container GPU access:"
if docker run --rm --gpus all "$CUDA_IMAGE" nvidia-smi; then
    echo "✓ Container GPU OK"
else
    echo "✗ Container GPU FAILED"
    exit 1
fi

echo ""
echo "=== All checks passed ==="
```

---

## Docker GPU Syntax (MANDATORY)

### Correct Syntax:
```bash
# Run container with GPU access
docker run --rm --gpus all nvidia/cuda:12.4.0-base nvidia-smi

# Specific GPU
docker run --rm --gpus '"device=0"' nvidia/cuda:12.4.0-base nvidia-smi

# Multiple GPUs
docker run --rm --gpus '"device=0,1"' nvidia/cuda:12.4.0-base nvidia-smi
```

### Incorrect Syntax (Podman):
```bash
# ❌ WRONG - This is Podman syntax
docker run --rm --device nvidia.com/gpu=all nvidia/cuda:12.4.0-base nvidia-smi

# ❌ WRONG - CDI syntax from Podman
docker run --rm --device nvidia.com/gpu=0 nvidia/cuda:12.4.0-base nvidia-smi
```

---

## Docker Compose with GPU

### Correct Pattern:
```yaml
# docker-compose.yml
version: '3.8'

services:
  gpu-app:
    image: nvidia/cuda:12.4.0-base
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
    command: nvidia-smi
```

### Alternative Syntax (Docker Compose v2.3+):
```yaml
version: '2.3'

services:
  gpu-app:
    image: nvidia/cuda:12.4.0-base
    runtime: nvidia
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
    command: nvidia-smi
```

---

## Common Use Cases

### PostgreSQL with Docker Compose
```yaml
# scripts/examples/postgres-docker-compose/docker-compose.yml
version: '3.8'

services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: dev
      POSTGRES_PASSWORD: devpass
      POSTGRES_DB: devdb
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

```bash
# Start
docker-compose up -d

# Connect
psql -h localhost -U dev -d devdb
```

### CUDA Development Container
```bash
docker run -it --gpus all \
  -v "$PWD:/workspace" \
  -w /workspace \
  nvidia/cuda:12.4.0-devel-ubuntu22.04 \
  bash
```

### PyTorch with GPU
```bash
docker run -it --gpus all \
  -v "$PWD:/workspace" \
  -w /workspace \
  pytorch/pytorch:2.1.0-cuda12.1-cudnn8-runtime \
  python train.py
```

### Ollama (LLM) with GPU
```bash
docker run -d --gpus all \
  --name ollama \
  -p 11434:11434 \
  ollama/ollama:latest
```

---

## Docker Management

### Useful Commands:
```bash
# List containers
docker ps -a

# Remove stopped containers
docker container prune

# Remove unused images
docker image prune -a

# View disk usage
docker system df

# Complete cleanup
docker system prune -a --volumes

# View logs
docker logs <container-name>

# Execute command in running container
docker exec -it <container-name> bash
```

### Systemd Integration:
```bash
# Generate systemd unit for container
docker create --name myapp --gpus all myimage:latest
systemctl --user import-environment PATH
systemctl --user daemon-reload

# Start on boot
systemctl --user enable docker-myapp.service
```

---

## Troubleshooting

### "permission denied" when running docker
**Cause**: User not in docker group or hasn't logged out/in  
**Fix**:
```bash
# Verify group membership
groups | grep docker

# If not present, add user
sudo usermod -aG docker "$USER"

# Then log out and back in
```

### "nvidia-smi not found" in container
**Cause**: NVIDIA Container Toolkit not installed  
**Fix**:
```bash
./scripts/docker-nvidia-install.sh
```

### "could not select device driver" with gpu
**Cause**: Docker daemon not configured for NVIDIA  
**Fix**:
```bash
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

### Docker daemon won't start
**Cause**: Conflicts with Podman or broken config  
**Fix**:
```bash
# Stop and disable Podman if present
sudo systemctl stop podman.socket
sudo systemctl disable podman.socket

# Reset Docker config
sudo rm -rf /var/lib/docker
sudo systemctl restart docker
```

---

## Best Practices

### Do:
- ✅ Use `--gpus all` for GPU access
- ✅ Mount volumes for persistent data
- ✅ Use official images when possible
- ✅ Clean up stopped containers regularly
- ✅ Use Docker Compose for multi-container apps
- ✅ Version your image tags (not `:latest`)
- ✅ Test GPU access with verification script

### Don't:
- ❌ Use Podman syntax (`--device nvidia.com/gpu=`)
- ❌ Run containers as root unnecessarily
- ❌ Store data inside containers
- ❌ Use `:latest` tag in production
- ❌ Expose ports without firewall rules
- ❌ Leave unused containers running
- ❌ Skip verification after NVIDIA setup

---

## Security Considerations

### Dockerfile Best Practices:
```dockerfile
# Use specific versions
FROM nvidia/cuda:12.4.0-base-ubuntu22.04

# Run as non-root user
RUN useradd -m -u 1000 appuser
USER appuser

# Don't expose unnecessary ports
EXPOSE 8080

# Use least privilege
# Don't use --privileged unless absolutely necessary
```

### Container Scanning:
```bash
# Scan image for vulnerabilities
docker scout cves nvidia/cuda:12.4.0-base
```

---

## Example Workflows

### ML Training Pipeline:
```bash
# Build training image
docker build -t ml-training:v1 .

# Train model with GPU
docker run --gpus all \
  -v "$PWD/data:/data" \
  -v "$PWD/models:/models" \
  ml-training:v1 \
  python train.py --epochs 100

# Export trained model
docker cp <container-id>:/models/final.pt ./models/
```

### Development Container:
```bash
# Start dev container with GPU and code mount
docker run -it --gpus all \
  --name dev-env \
  -v "$PWD:/workspace" \
  -v "$HOME/.ssh:/home/dev/.ssh:ro" \
  -p 8080:8080 \
  nvidia/cuda:12.4.0-devel-ubuntu22.04 \
  bash
```

---

## Integration with firstrun-user.sh

The main user setup script orchestrates Docker installation:

```bash
# scripts/firstrun-user.sh (excerpt)

echo ""
echo "=== Docker Setup ==="
./scripts/setup-docker.sh

if lspci | grep -qi 'VGA.*NVIDIA'; then
    echo ""
    echo "=== NVIDIA GPU Detected ==="
    ./scripts/docker-nvidia-install.sh
    ./scripts/docker-nvidia-verify.sh
fi
```

---

## Migration from Podman

If upgrading from older geckoforge version:

1. **Backup Podman data**:
```bash
tar -czf podman-backup.tar.gz ~/.local/share/containers
```

2. **Run Docker setup**:
```bash
./scripts/setup-docker.sh
# (This automatically removes Podman)
```

3. **Verify Docker works**:
```bash
docker run hello-world
```

4. **Setup NVIDIA (if applicable)**:
```bash
./scripts/docker-nvidia-install.sh
./scripts/docker-nvidia-verify.sh
```

---

## Verification Checklist

After Docker setup:
- [ ] `docker --version` shows Docker version
- [ ] `docker run hello-world` works
- [ ] `docker ps` runs without sudo
- [ ] (If NVIDIA) `nvidia-smi` works
- [ ] (If NVIDIA) `docker run --gpus all nvidia/cuda:12.4.0-base nvidia-smi` works
- [ ] No Podman commands in `$PATH`
- [ ] No Podman systemd units active

---

## Documentation References

- Docker setup: `scripts/setup-docker.sh`
- NVIDIA setup: `scripts/docker-nvidia-install.sh`
- Verification: `scripts/docker-nvidia-verify.sh`
- Examples: `scripts/examples/*/`
- Full guide: `docs/podman-to-docker-migration.md`