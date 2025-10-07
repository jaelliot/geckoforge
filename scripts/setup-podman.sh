#!/usr/bin/env bash
set -euo pipefail

echo "[podman] Installing Podman stack..."
sudo zypper install -y podman buildah skopeo

if ! grep -q "^${USER}:" /etc/subuid; then
    echo "[podman] Configuring subuid/subgid for ${USER}..."
    echo "${USER}:100000:65536" | sudo tee -a /etc/subuid >/dev/null
    echo "${USER}:100000:65536" | sudo tee -a /etc/subgid >/dev/null
fi

mkdir -p ~/.config/containers
if [ ! -f ~/.config/containers/storage.conf ]; then
    cat > ~/.config/containers/storage.conf <<EOF
[storage]
driver = "overlay"
runroot = "/run/user/$(id -u)/containers"
graphroot = "~/.local/share/containers/storage"
EOF
fi

echo "[podman] Running podman system migrate..."
podman system migrate || true

echo "[podman] Setup complete. Test with: podman run hello-world"
