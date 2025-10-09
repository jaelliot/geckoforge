# GPU Container as Systemd Service

This example shows how to run a GPU-enabled Docker container as a user systemd service.

## Setup

1. Create a named container:
```bash
docker create \
  --name ollama-gpu \
  --gpus all \
  --restart unless-stopped \
  -p 11434:11434 \
  docker.io/ollama/ollama:latest
```

2. Generate systemd unit:
```bash
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/ollama-gpu.service <<'EOF'
[Unit]
Description=Ollama GPU container
After=default.target

[Service]
Type=simple
ExecStart=docker start -a ollama-gpu
ExecStop=docker stop ollama-gpu
Restart=always

[Install]
WantedBy=default.target
EOF
```

3. Enable and start:
```bash
systemctl --user daemon-reload
systemctl --user enable --now ollama-gpu.service
```

4. Verify:
```bash
systemctl --user status ollama-gpu.service
docker logs ollama-gpu
```

## Auto-start on boot

Ensure linger is enabled:
```bash
loginctl enable-linger $USER
```
