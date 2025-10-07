#!/usr/bin/env bash
set -euo pipefail

CUDA_IMAGE="docker.io/nvidia/cuda:12.4.0-base-ubuntu22.04"

echo "=== NVIDIA Verification ==="
echo ""

echo "[1/3] Host driver check:"
if nvidia-smi; then
    echo "✓ Host driver OK"
else
    echo "✗ Host driver FAILED"
    exit 1
fi
echo ""

echo "[2/3] Container GPU access (may need sudo for first pull):"
if sudo podman run --rm --device nvidia.com/gpu=all "$CUDA_IMAGE" nvidia-smi; then
    echo "✓ Container GPU (root) OK"
else
    echo "✗ Container GPU (root) FAILED"
    echo "Hint: Check if CDI spec exists at /etc/cdi/nvidia.yaml"
    exit 1
fi
echo ""

echo "[3/3] Rootless container GPU access:"
if podman run --rm --device nvidia.com/gpu=all "$CUDA_IMAGE" nvidia-smi; then
    echo "✓ Rootless GPU OK"
else
    echo "✗ Rootless GPU FAILED"
    echo "Hint: Try regenerating CDI: sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml"
    exit 1
fi
echo ""

echo "=== All checks passed ==="
