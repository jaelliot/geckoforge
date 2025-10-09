# CUDA Quick Test

## Basic GPU check
```bash
docker run --rm --gpus all \
  docker.io/nvidia/cuda:12.4.0-base-ubuntu22.04 \
  nvidia-smi
```

## Interactive CUDA container
```bash
docker run -it --rm --gpus all \
  docker.io/nvidia/cuda:12.4.0-devel-ubuntu22.04 \
  bash
```

## With volume mount (for your code)
```bash
docker run --rm --gpus all \
  -v "$PWD:/workspace" \
  -w /workspace \
  docker.io/nvidia/cuda:12.4.0-devel-ubuntu22.04 \
  python your_script.py
```
