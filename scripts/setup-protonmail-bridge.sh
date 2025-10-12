#!/usr/bin/env bash
#
# setup-protonmail-bridge.sh - ProtonMail Bridge installation and configuration
#
# Part of geckoforge workstation image
# Layer 3: User Setup
#
# Usage: ./scripts/setup-protonmail-bridge.sh
#

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Logging functions
info() { echo -e "${BLUE}ℹ${NC} $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
warning() { echo -e "${YELLOW}⚠${NC} $*"; }
error() { echo -e "${RED}✗${NC} $*" >&2; }
header() { echo -e "\n${BLUE}━━━${NC} ${BOLD}$*${NC}\n"; }

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    error "This script should NOT be run as root"
    exit 1
fi

# Main installation flow
main() {
    header "ProtonMail Bridge Setup"
    
    info "ProtonMail Bridge allows you to use Thunderbird with ProtonMail."
    info "It creates a local IMAP/SMTP server that handles ProtonMail encryption."
    echo

    # Check if already installed
    if command -v protonmail-bridge &> /dev/null; then
        success "ProtonMail Bridge is already installed"
        BRIDGE_INSTALLED=true
    else
        BRIDGE_INSTALLED=false
        warning "ProtonMail Bridge is NOT installed"
    fi

    echo
    info "ProtonMail Bridge installation options:"
    echo "  1) Install via Flatpak (recommended - sandboxed)"
    echo "  2) Download official RPM from proton.me"
    echo "  3) Skip installation (already have it)"
    echo "  q) Quit"
    echo
    read -r -p "Select option [1]: " choice
    choice=${choice:-1}

    case $choice in
        1)
            install_flatpak
            ;;
        2)
            info "Please download the RPM from: https://proton.me/mail/bridge"
            info "Then run: sudo zypper install ~/Downloads/protonmail-bridge-*.rpm"
            read -r -p "Press Enter when ready to continue..."
            ;;
        3)
            info "Skipping installation..."
            ;;
        q|Q)
            info "Setup cancelled"
            exit 0
            ;;
        *)
            error "Invalid option"
            exit 1
            ;;
    esac

    # Configuration
    if command -v protonmail-bridge &> /dev/null || flatpak list | grep -q "ch.protonmail.protonmail-bridge"; then
        configure_bridge
    else
        warning "ProtonMail Bridge not found. Install it first."
        exit 1
    fi

    success "ProtonMail Bridge setup complete!"
    echo
    info "Next steps:"
    echo "  1. Start Bridge: protonmail-bridge --cli (or via app menu)"
    echo "  2. Log in with your ProtonMail credentials"
    echo "  3. Open Thunderbird and add new account:"
    echo "     - IMAP: 127.0.0.1:1143 (STARTTLS)"
    echo "     - SMTP: 127.0.0.1:1025 (STARTTLS)"
    echo "     - Username/Password: from Bridge interface"
    echo
    info "Full documentation: ~/git/geckoforge/docs/thunderbird-setup.md"
}

install_flatpak() {
    header "Installing ProtonMail Bridge via Flatpak"
    
    # Ensure Flatpak is available
    if ! command -v flatpak &> /dev/null; then
        error "Flatpak not found. Install it first: sudo zypper install flatpak"
        exit 1
    fi

    # Add Flathub if not present
    if ! flatpak remotes | grep -q "flathub"; then
        info "Adding Flathub repository..."
        flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo
    fi

    # Install Bridge
    info "Installing ProtonMail Bridge..."
    flatpak install --user -y flathub ch.protonmail.protonmail-bridge

    success "ProtonMail Bridge installed via Flatpak"
    
    # Create convenient launcher
    mkdir -p ~/bin
    cat > ~/bin/protonmail-bridge << 'EOF'
#!/bin/bash
flatpak run ch.protonmail.protonmail-bridge "$@"
EOF
    chmod +x ~/bin/protonmail-bridge
    
    success "Created launcher: ~/bin/protonmail-bridge"
}

configure_bridge() {
    header "ProtonMail Bridge Configuration"
    
    info "ProtonMail Bridge will run on:"
    echo "  - IMAP: 127.0.0.1:1143"
    echo "  - SMTP: 127.0.0.1:1025"
    echo
    
    # Create systemd user service for auto-start
    info "Creating systemd user service for auto-start..."
    
    mkdir -p ~/.config/systemd/user
    
    # Determine correct ExecStart based on installation method
    if flatpak list | grep -q "ch.protonmail.protonmail-bridge"; then
        EXEC_START="flatpak run ch.protonmail.protonmail-bridge --no-window"
    else
        EXEC_START="protonmail-bridge --no-window"
    fi
    
    cat > ~/.config/systemd/user/protonmail-bridge.service << EOF
[Unit]
Description=ProtonMail Bridge
After=network.target

[Service]
Type=simple
ExecStart=$EXEC_START
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
EOF

    success "Systemd service created"
    
    # Enable but don't start (user needs to configure first)
    systemctl --user daemon-reload
    
    read -r -p "Enable ProtonMail Bridge to start automatically on login? [Y/n] " response
    response=${response:-Y}
    
    if [[ $response =~ ^[Yy]$ ]]; then
        systemctl --user enable protonmail-bridge.service
        success "ProtonMail Bridge will start automatically on login"
    else
        info "Auto-start not enabled. Enable later with:"
        echo "  systemctl --user enable protonmail-bridge.service"
    fi
}

# Run main
main "$@"