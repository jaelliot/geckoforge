#!/usr/bin/env bash
# @file scripts/setup-synergy.sh
# @description Synergy Setup Helper - guides users through KVM switching configuration
# @update-policy Update when Synergy versions change or new configuration options needed

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
  printf "${GREEN}[synergy]${NC} %s\n" "$1"
}

warn() {
  printf "${YELLOW}[synergy]${NC} %s\n" "$1"
}

error() {
  printf "${RED}[synergy]${NC} %s\n" "$1"
}

cat <<'EOF'
═══════════════════════════════════════════
  Synergy Setup Helper
═══════════════════════════════════════════

This script helps you set up Synergy for sharing
keyboard and mouse across multiple computers.

Requirements:
• Synergy license from symless.com
• Downloaded Synergy RPM file

What this script does:
1. Install Synergy RPM (if needed)
2. Configure firewall ports
3. Set up auto-start service
4. Launch Synergy for license activation

═══════════════════════════════════════════
EOF

echo ""
read -p "Press Enter to continue, or Ctrl+C to exit... "
echo ""

# ============================================================================
# Step 1: Check if Synergy is already installed
# ============================================================================
echo "Step 1: Checking for Synergy..."
echo ""

if command -v synergy &> /dev/null; then
    log "✅ Synergy is already installed"
    SYNERGY_INSTALLED=true
else
    warn "❌ Synergy not found"
    SYNERGY_INSTALLED=false
    
    echo ""
    echo "To install Synergy:"
    echo "1. Go to https://symless.com/synergy/downloads"
    echo "2. Log in with your account"
    echo "3. Download the Linux RPM file"
    echo "4. Save to ~/Downloads/"
    echo ""
    
    read -p "Have you downloaded the Synergy RPM? (y/n): " has_rpm
    
    if [[ ! "$has_rpm" =~ ^[Yy]$ ]]; then
        echo ""
        log "Download Synergy first, then re-run this script."
        exit 0
    fi
    
    # Look for RPM in Downloads
    echo ""
    log "Looking for Synergy RPM in ~/Downloads..."
    RPM_FILE=$(find ~/Downloads -name "synergy-*.rpm" -type f | head -n1)
    
    if [ -z "$RPM_FILE" ]; then
        error "❌ No Synergy RPM found in ~/Downloads"
        echo ""
        echo "Please download from https://symless.com/synergy/downloads"
        exit 1
    fi
    
    log "✅ Found: $(basename "$RPM_FILE")"
    echo ""
    log "Installing Synergy..."
    sudo zypper install -y "$RPM_FILE"
    log "✅ Synergy installed"
    SYNERGY_INSTALLED=true
fi

echo ""
echo "═══════════════════════════════════════════"
echo ""

# ============================================================================
# Step 2: Configure Firewall
# ============================================================================
echo "Step 2: Configuring firewall..."
echo ""
echo "Opening ports for Synergy:"
echo "  • 24800 (main connection)"
echo "  • 24802 (background service)"
echo "  • 24804 (background service)"
echo ""

sudo firewall-cmd --permanent --add-port=24800/tcp
sudo firewall-cmd --permanent --add-port=24802/tcp
sudo firewall-cmd --permanent --add-port=24804/tcp
sudo firewall-cmd --reload

log "✅ Firewall configured"
echo ""
echo "═══════════════════════════════════════════"
echo ""

# ============================================================================
# Step 3: Choose Client or Server Mode
# ============================================================================
echo "Step 3: Configure Synergy mode"
echo ""
echo "Is this computer:"
echo "  1) Client - use another computer's keyboard/mouse"
echo "  2) Server - share this computer's keyboard/mouse"
echo ""
read -p "Choose (1 or 2): " mode

echo ""

if [ "$mode" = "1" ]; then
    # Client mode - need server IP
    log "Client mode selected"
    echo ""
    read -p "Enter your Synergy server IP address: " server_ip
    
    if [ -z "$server_ip" ]; then
        error "❌ No server IP provided"
        exit 1
    fi
    
    echo ""
    log "Setting up auto-start service..."
    echo "  • Will connect to: $server_ip:24800"
    echo "  • Starts automatically at login"
    echo ""
    
    # Create systemd user service
    mkdir -p ~/.config/systemd/user
    
    cat > ~/.config/systemd/user/synergy-client.service <<EOF
[Unit]
Description=Synergy Client
After=graphical-session.target network.target

[Service]
ExecStart=/usr/bin/synergy --no-tray --name $(hostname) --server $server_ip:24800
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF
    
    systemctl --user daemon-reload
    systemctl --user enable synergy-client.service
    
    log "✅ Auto-start service enabled"
    CLIENT_MODE=true
    
else
    # Server mode
    log "Server mode selected"
    echo ""
    echo "You'll configure screen layout in the Synergy GUI"
    CLIENT_MODE=false
fi

echo ""
echo "═══════════════════════════════════════════"
echo ""

# ============================================================================
# Step 4: Launch Synergy
# ============================================================================
echo "Step 4: Launch Synergy"
echo ""

if [ "$SYNERGY_INSTALLED" = true ]; then
    log "Launching Synergy..."
    echo ""
    echo "Next steps in Synergy window:"
    echo "  1. Enter your license key (if first time)"
    
    if [ "$CLIENT_MODE" = true ]; then
        echo "  2. Client mode is configured automatically"
        echo "  3. Connection will start at next login"
    else
        echo "  2. Configure screen layout"
        echo "  3. Add client computers"
        echo "  4. Click 'Start' to activate server"
    fi
    
    echo ""
    synergy &
    sleep 2
fi

# ============================================================================
# Success Summary
# ============================================================================
echo ""
echo "═══════════════════════════════════════════"
echo "  Setup Complete"
echo "═══════════════════════════════════════════"
echo ""
echo "Configuration:"
echo "  • Synergy: Installed and configured"
echo "  • Firewall: Ports 24800, 24802, 24804 open"

if [ "$CLIENT_MODE" = true ]; then
    echo "  • Mode: Client"
    echo "  • Server: $server_ip:24800"
    echo "  • Auto-start: Enabled"
    echo ""
    echo "Next steps:"
    echo "  1. Enter license key in Synergy window"
    echo "  2. Log out and back in"
    echo "  3. Client will auto-connect to server"
    echo ""
    echo "Troubleshooting:"
    echo "  • Check status: systemctl --user status synergy-client"
    echo "  • View logs: journalctl --user -u synergy-client -f"
    echo "  • Test connection: ping $server_ip"
else
    echo "  • Mode: Server"
    echo ""
    echo "Next steps:"
    echo "  1. Enter license key in Synergy window"
    echo "  2. Configure screen layout in Settings"
    echo "  3. Add client computers"
    echo "  4. Click 'Start' button"
fi

echo ""
echo "Documentation: https://help.symless.com/"
echo ""
log "Setup complete! Enjoy your multi-computer workflow!"