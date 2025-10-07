# CUDA Quick Test

## Basic GPU check
```bash
podman run --rm --device nvidia.com/gpu=all \
  docker.io/nvidia/cuda:12.4.0-base-ubuntu22.04 \
  nvidia-smi
```

## Interactive CUDA container
```bash
podman run -it --device nvidia.com/gpu=all \
  docker.io/nvidia/cuda:12.4.0-devel-ubuntu22.04 \
  bash
```

## With volume mount (for your code)
```bash
podman run --rm \
  --device nvidia.com/gpu=all \
  -v "$PWD:/workspace:Z" \
  -w /workspace \
  docker.io/nvidia/cuda:12.4.0-devel-ubuntu22.04 \
  python your_script.py
```
