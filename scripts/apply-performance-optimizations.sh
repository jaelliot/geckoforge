#!/usr/bin/env bash
# @file scripts/apply-performance-optimizations.sh
# @description Apply system-level performance optimizations that require root access
# @usage ./scripts/apply-performance-optimizations.sh

set -euo pipefail

echo "=== GeckoForge Performance Optimization Installer ==="
echo ""
echo "This script will apply system-level optimizations that require root access:"
echo "  • Kernel sysctl parameters (memory, I/O, network)"
echo "  • Docker daemon configuration"
echo "  • TLP power management (laptop only)"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "❌ This script must be run as root"
  echo "Usage: sudo $0"
  exit 1
fi

# Detect if laptop
IS_LAPTOP=false
if [ -d /sys/class/power_supply/BAT0 ] || [ -d /sys/class/power_supply/BAT1 ]; then
  IS_LAPTOP=true
  echo "✓ Laptop detected"
fi

echo ""
echo "=== Step 1: Kernel sysctl Parameters ==="

# Check if config exists
if [ ! -f ~/.config/sysctl.d/99-geckoforge-performance.conf ]; then
  echo "❌ sysctl configuration not found at ~/.config/sysctl.d/99-geckoforge-performance.conf"
  echo "Run 'home-manager switch' first to generate the file"
  exit 1
fi

# Copy sysctl config
cp ~/.config/sysctl.d/99-geckoforge-performance.conf /etc/sysctl.d/99-geckoforge-performance.conf
chmod 644 /etc/sysctl.d/99-geckoforge-performance.conf

# Apply immediately
sysctl --system
echo "✓ Sysctl parameters applied"

echo ""
echo "=== Step 2: Docker Daemon Configuration ==="

# Check if Docker is installed
if ! command -v docker >/dev/null 2>&1; then
  echo "⚠ Docker not installed, skipping Docker configuration"
  echo "Install Docker with: ./scripts/setup-docker.sh"
else
  # Create Docker config directory
  mkdir -p /etc/docker
  
  # Check if config exists
  if [ ! -f ~/.config/docker/daemon.json ]; then
    echo "❌ Docker daemon.json not found at ~/.config/docker/daemon.json"
    echo "Run 'home-manager switch' first to generate the file"
  else
    # Backup existing config
    if [ -f /etc/docker/daemon.json ]; then
      cp /etc/docker/daemon.json /etc/docker/daemon.json.backup
      echo "✓ Backed up existing Docker config to /etc/docker/daemon.json.backup"
    fi
    
    # Copy new config
    cp ~/.config/docker/daemon.json /etc/docker/daemon.json
    chmod 644 /etc/docker/daemon.json
    
    # Restart Docker daemon
    systemctl restart docker
    echo "✓ Docker daemon configuration applied and service restarted"
  fi
fi

echo ""
echo "=== Step 3: TLP Power Management (Laptop Only) ==="

if [ "$IS_LAPTOP" = true ]; then
  # Check if TLP config exists
  if [ ! -f ~/.config/tlp/tlp.conf ]; then
    echo "⚠ TLP configuration not found, skipping"
  else
    # Install TLP if not present
    if ! command -v tlp >/dev/null 2>&1; then
      echo "Installing TLP..."
      zypper -n in tlp tlp-rdw
    fi
    
    # Copy TLP config
    cp ~/.config/tlp/tlp.conf /etc/tlp.conf
    chmod 644 /etc/tlp.conf
    
    # Enable and start TLP
    systemctl enable --now tlp
    echo "✓ TLP power management enabled"
  fi
else
  echo "⚠ Not a laptop, skipping TLP configuration"
fi

echo ""
echo "=== Step 4: Create ZSH History Directory ==="
if [ -n "${SUDO_USER:-}" ]; then
  USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
  mkdir -p "$USER_HOME/.cache/zsh"
  chown -R "$SUDO_USER:$(id -gn $SUDO_USER)" "$USER_HOME/.cache/zsh"
  echo "✓ ZSH cache directory created"
fi

echo ""
echo "=== Performance Optimizations Applied Successfully! ==="
echo ""
echo "Recommended Next Steps:"
echo "  1. Reboot to ensure all optimizations are active"
echo "  2. Run 'systemd-analyze time' after reboot to check boot time"
echo "  3. Run 'systemd-analyze blame' to identify slow services"
echo "  4. Check 'docker info' to verify storage driver is overlay2"
echo ""
echo "Performance Monitoring Commands:"
echo "  • System status: check-thermals"
echo "  • Power status: power-status"
echo "  • Docker status: docker-status"
echo "  • Boot analysis: systemd-analyze critical-chain"
