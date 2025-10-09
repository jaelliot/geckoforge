#!/usr/bin/env bash
set -euo pipefail

header() {
  echo ""
  echo "╔════════════════════════════════════════╗"
  printf "║ %38s ║\n" "$1"
  echo "╚════════════════════════════════════════╝"
  echo ""
}

log() {
  printf '%s\n' "$1"
}

header "Docker NVIDIA Toolkit"

if ! command -v nvidia-smi >/dev/null 2>&1; then
  log "[error] NVIDIA driver not detected. Install drivers and rerun."
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  log "[error] Docker is required. Run ./setup-docker.sh first."
  exit 1
fi

log "[info] Detected GPU: $(nvidia-smi --query-gpu=name --format=csv,noheader | head -n1)"

log "[auth] Elevation required for repository configuration."
sudo -v

DIST="opensuse15.6"
REPO_URL="https://nvidia.github.io/libnvidia-container/${DIST}/libnvidia-container.repo"
REPO_PATH="/etc/zypp/repos.d/nvidia-container-toolkit.repo"

log "[repo] Configuring NVIDIA container repository (${REPO_URL})..."
curl -fsSL "$REPO_URL" | sudo tee "$REPO_PATH" >/dev/null

log "[zypper] Refreshing repositories..."
sudo zypper refresh

log "[install] Installing nvidia-container-toolkit..."
sudo zypper install -y nvidia-container-toolkit

if ! command -v nvidia-ctk >/dev/null 2>&1; then
  log "[error] nvidia-ctk not found after installation. Check zypper output."
  exit 1
fi

log "[config] Generating NVIDIA CDI specification..."
sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml

log "[config] Configuring Docker runtime..."
sudo nvidia-ctk runtime configure --runtime=docker --set-as-default

log "[daemon] Restarting Docker..."
sudo systemctl restart docker
sleep 3

log "[verify] Checking Docker info for nvidia runtime..."
if sudo docker info | grep -qi 'Runtimes:.*nvidia'; then
  log "[verify] NVIDIA runtime registered."
else
  log "[warn] NVIDIA runtime not reported by docker info. Inspect /etc/docker/daemon.json."
fi

log "[next] Run ./docker-nvidia-verify.sh to confirm container GPU access."
