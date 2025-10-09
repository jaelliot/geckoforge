#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '%s\n' "$1"
}

header() {
  echo ""
  echo "╔════════════════════════════════════════╗"
  printf "║ %38s ║\n" "$1"
  echo "╚════════════════════════════════════════╝"
  echo ""
}

ensure_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log "[error] Required command '$1' not found. Install it and rerun."
    exit 1
  fi
}

header "Docker Setup"

enable_sudo_keepalive() {
  if sudo -n true 2>/dev/null; then
    return
  fi
  log "[auth] Elevated privileges required. Enter password if prompted."
  sudo -v
  # Refresh sudo timestamp while script runs
  while true; do
    sleep 60
    sudo -n true >/dev/null 2>&1 || exit 0
  done &
  SUDO_KEEPALIVE_PID=$!
}

cleanup_sudo_keepalive() {
  if [[ -n "${SUDO_KEEPALIVE_PID:-}" ]]; then
    kill "$SUDO_KEEPALIVE_PID" >/dev/null 2>&1 || true
  fi
}

trap cleanup_sudo_keepalive EXIT

enable_sudo_keepalive

log "[check] Using $(lsb_release -ds 2>/dev/null || echo 'openSUSE Leap')"

if rpm -q podman >/dev/null 2>&1; then
  log "[podman] Podman detected. Preparing to remove..."
  sudo systemctl stop --now podman.socket podman.service 2>/dev/null || true
  sudo systemctl disable podman.socket podman.service 2>/dev/null || true
  sudo zypper rm -y podman podman-remote podman-plugins podman-compose buildah skopeo crun 2>/dev/null || \
    sudo zypper rm -y podman buildah skopeo podman-compose || true

  echo ""
  read -rp "Remove Podman data directories (~/.local/share/containers, ~/.config/containers)? [y/N]: " purge_podman
  if [[ "${purge_podman,,}" == "y" ]]; then
    rm -rf ~/.local/share/containers ~/.config/containers ~/.config/containers* ~/.local/share/containers* 2>/dev/null || true
    sudo rm -rf /var/lib/containers 2>/dev/null || true
    log "[podman] Data directories removed."
  else
    log "[podman] Leaving user data in place."
  fi
else
  log "[podman] Not installed. Skipping removal."
fi

log "[docker] Refreshing repositories..."
sudo zypper refresh

log "[docker] Installing Docker engine and Compose..."
sudo zypper install -y docker docker-compose || {
  log "[docker] Installation failed. Check zypper output for details."
  exit 1
}

log "[docker] Enabling and starting daemon..."
sudo systemctl enable --now docker

if ! getent group docker >/dev/null 2>&1; then
  log "[docker] Creating docker group..."
  sudo groupadd docker
fi

if id -nG "$USER" | grep -qw docker; then
  log "[docker] User '$USER' already in docker group."
else
  log "[docker] Adding '$USER' to docker group..."
  sudo usermod -aG docker "$USER"
  NEW_GROUP_ASSIGNED=1
fi

log "[docker] Checking daemon status..."
sudo systemctl status docker --no-pager --lines=0 >/dev/null 2>&1 || {
  log "[docker] Docker daemon not running. Inspect logs with 'sudo journalctl -u docker'."
  exit 1
}

log "[docker] Pulling hello-world image for verification..."
sudo docker pull hello-world >/dev/null

log "[docker] Running hello-world test (requires sudo until new shell)..."
if sudo docker run --rm hello-world >/dev/null 2>&1; then
  log "[docker] Hello World test passed."
else
  log "[docker] Hello World test failed. Investigate with 'sudo docker run --rm hello-world'."
fi

echo ""
log "[summary] Docker installed successfully."
if [[ -n "${NEW_GROUP_ASSIGNED:-}" ]]; then
  log "[summary] Log out and back in (or run 'newgrp docker') before running Docker without sudo."
fi
log "[summary] Next steps:"
log "  • Install NVIDIA container toolkit (if applicable): ./docker-nvidia-install.sh"
log "  • Verify GPU support: ./docker-nvidia-verify.sh"
log "  • Explore example compose project: scripts/examples/postgres-docker-compose"
