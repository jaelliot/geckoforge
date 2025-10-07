# GPU Container as Systemd Service

This example shows how to run a GPU-enabled container as a user systemd service.

## Setup

1. Create a named container:
```bash
podman create \
  --name ollama-gpu \
  --device nvidia.com/gpu=all \
  -p 11434:11434 \
  docker.io/ollama/ollama:latest
```

2. Generate systemd unit:
```bash
mkdir -p ~/.config/systemd/user
podman generate systemd --new --name ollama-gpu --files \
  --restart-policy=always \
  > ~/.config/systemd/user/ollama-gpu.service
```

3. Enable and start:
```bash
systemctl --user daemon-reload
systemctl --user enable --now ollama-gpu.service
```

4. Verify:
```bash
systemctl --user status ollama-gpu.service
podman logs ollama-gpu
```

## Auto-start on boot

Ensure linger is enabled:
```bash
loginctl enable-linger $USER
```
