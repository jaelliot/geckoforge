#!/usr/bin/env bash
set -euo pipefail

CUDA_IMAGE="docker.io/nvidia/cuda:12.4.0-base-ubuntu22.04"

header() {
  echo ""
  echo "╔════════════════════════════════════════╗"
  printf "║ %38s ║\n" "$1"
  echo "╚════════════════════════════════════════╝"
  echo ""
}

step() {
  printf '\n=== %s ===\n\n' "$1"
}

header "Docker GPU Verification"

if ! command -v docker >/dev/null 2>&1; then
  echo "[error] Docker not detected. Run ./setup-docker.sh first."
  exit 1
fi

step "1/3 Host driver"
if nvidia-smi; then
  echo "✓ NVIDIA driver responding"
else
  echo "✗ Unable to run nvidia-smi."
  exit 1
fi

step "2/3 Docker runtime"
if docker info --format '{{json .Runtimes}}' | grep -q 'nvidia'; then
  echo "✓ NVIDIA runtime registered"
else
  echo "✗ NVIDIA runtime missing"
  echo "Hint: Rerun ./docker-nvidia-install.sh"
  exit 1
fi

echo "nvidia" | docker info --format '{{json .Runtimes}}' >/dev/null 2>&1 || true

step "3/3 Container GPU access"
docker pull --quiet "$CUDA_IMAGE" >/dev/null 2>&1 || true
if docker run --rm --gpus all "$CUDA_IMAGE" nvidia-smi; then
  echo "✓ Container GPU test passed"
else
  echo "✗ Container GPU test failed"
  echo "Troubleshooting:"
  echo "  • Check /etc/docker/daemon.json"
  echo "  • Verify nvidia-ctk runtime configure --runtime=docker"
  echo "  • Inspect docker logs: sudo journalctl -u docker"
  exit 1
fi

step "All checks passed"
