#!/usr/bin/env bash
# @file setup-winapps.sh
# @description Install and configure WinApps for seamless Windows application integration
# @update-policy Update when WinApps dependencies or installation methods change

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/winapps"
CONFIG_FILE="$CONFIG_DIR/winapps.conf"
WINAPPS_REPO="https://github.com/winapps-org/winapps"

echo "=== WinApps Setup for geckoforge ==="
echo ""
echo "WinApps allows seamless integration of Windows applications on Linux."
echo "This requires:"
echo "  - Docker (already configured)"
echo "  - ~20-30GB disk space for Windows VM"
echo "  - 4-8GB RAM allocation"
echo "  - Windows installation (automated from Microsoft servers)"
echo ""

# Check Docker is running
if ! command -v docker &>/dev/null; then
    echo "[error] Docker not found. Run ./scripts/setup-docker.sh first." >&2
    exit 1
fi

if ! docker info &>/dev/null; then
    echo "[error] Docker daemon not running. Start it with:" >&2
    echo "  sudo systemctl start docker" >&2
    exit 1
fi

if ! groups | grep -q docker; then
    echo "[error] User not in docker group. Log out and back in after running setup-docker.sh." >&2
    exit 1
fi

echo "[1/4] Installing system dependencies..."
DEPS=(dialog freerdp netcat-openbsd)
MISSING=()

for dep in "${DEPS[@]}"; do
    if ! zypper search -i "$dep" &>/dev/null; then
        MISSING+=("$dep")
    fi
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
    echo "Installing: ${MISSING[*]}"
    sudo zypper install -y "${MISSING[@]}"
else
    echo "All dependencies already installed."
fi

# Check FreeRDP version
FREERDP_VERSION=$(rpm -q freerdp --qf '%{VERSION}' 2>/dev/null || echo "unknown")
if [[ "$FREERDP_VERSION" == "unknown" ]]; then
    echo "[warn] Could not determine FreeRDP version. WinApps requires v3.0+." >&2
elif [[ "${FREERDP_VERSION%%.*}" -lt 3 ]]; then
    echo "[warn] FreeRDP ${FREERDP_VERSION} detected. WinApps requires v3.0+." >&2
    echo "[warn] You may need to use the Flatpak version or compile from source." >&2
fi

echo ""
echo "[2/4] Installing WinApps..."
if [[ -d "$HOME/.local/bin" ]] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# Run WinApps installer
if command -v winapps &>/dev/null; then
    echo "WinApps already installed. Updating..."
    bash <(curl -s "$WINAPPS_REPO/raw/main/setup.sh") --update || true
else
    echo "Installing WinApps from upstream..."
    bash <(curl -s "$WINAPPS_REPO/raw/main/setup.sh") || {
        echo "[error] WinApps installation failed. Check network connection and try again." >&2
        exit 1
    }
fi

echo ""
echo "[3/4] Creating WinApps configuration..."
mkdir -p "$CONFIG_DIR"

if [[ -f "$CONFIG_FILE" ]]; then
    echo "Configuration file already exists at: $CONFIG_FILE"
    read -rp "Overwrite with defaults? [y/N]: " OVERWRITE
    if [[ ! "$OVERWRITE" =~ ^[Yy]$ ]]; then
        echo "Keeping existing configuration."
    else
        rm "$CONFIG_FILE"
    fi
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
    cat > "$CONFIG_FILE" <<'EOF'
##################################
#   WINAPPS CONFIGURATION FILE   #
##################################

# [WINDOWS USERNAME]
RDP_USER="WinAppsUser"

# [WINDOWS PASSWORD]
RDP_PASS="ChangeMe123!"

# [WINDOWS DOMAIN]
RDP_DOMAIN=""

# [WINDOWS IPV4 ADDRESS]
RDP_IP="127.0.0.1"

# [WINAPPS BACKEND]
WAFLAVOR="docker"

# [DISPLAY SCALING FACTOR]
# Valid: 100, 140, 180
RDP_SCALE="100"

# [MOUNTING REMOVABLE PATHS]
REMOVABLE_MEDIA="/run/media"

# [ADDITIONAL FREERDP FLAGS]
RDP_FLAGS="/cert:tofu /sound /microphone +home-drive"

# [DEBUG WINAPPS]
DEBUG="true"

# [AUTOMATICALLY PAUSE WINDOWS]
AUTOPAUSE="off"

# [AUTOPAUSE TIMEOUT (seconds)]
AUTOPAUSE_TIME="300"

# [FREERDP COMMAND]
FREERDP_COMMAND=""

# [TIMEOUTS]
PORT_TIMEOUT="5"
RDP_TIMEOUT="30"
APP_SCAN_TIMEOUT="60"
BOOT_TIMEOUT="120"

# [FREERDP RAIL HIDEF]
HIDEF="on"
EOF

    chmod 600 "$CONFIG_FILE"
    echo "Created default configuration at: $CONFIG_FILE"
    echo ""
    echo "IMPORTANT: Edit $CONFIG_FILE and set:"
    echo "  - RDP_USER (Windows username)"
    echo "  - RDP_PASS (Windows password)"
    echo ""
fi

echo "[4/4] Testing Docker access..."
if docker ps &>/dev/null; then
    echo "Docker access confirmed."
else
    echo "[error] Cannot access Docker. Ensure daemon is running." >&2
    exit 1
fi

echo ""
echo "=== WinApps Setup Complete ==="
echo ""
echo "Next steps:"
echo "  1. Edit $CONFIG_FILE"
echo "     Set your desired Windows username/password"
echo ""
echo "  2. Create Windows VM with WinApps:"
echo "     winapps-setup"
echo ""
echo "  3. Follow the interactive wizard to:"
echo "     - Download Windows 11 ISO from Microsoft"
echo "     - Configure VM resources (RAM, CPU, disk)"
echo "     - Install Windows automatically"
echo ""
echo "  4. After Windows installation, run:"
echo "     winapps-setup --install-apps"
echo ""
echo "  5. (Optional) Install WinApps Launcher:"
echo "     See: https://github.com/winapps-org/winapps-launcher"
echo ""
echo "Documentation: https://github.com/winapps-org/winapps"
