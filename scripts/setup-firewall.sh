#!/usr/bin/env bash
# @file scripts/setup-firewall.sh
# @description Comprehensive firewall and security hardening for geckoforge
# @update-policy Update when security requirements change or new hardening options emerge
# @note Consolidates functionality from harden.sh and setup-secure-firewall.sh

set -euo pipefail

log() {
  echo "[firewall] $*"
}

require_binary() {
  local bin="$1"
  if ! command -v "$bin" >/dev/null 2>&1; then
    log "ERROR: Missing required command: $bin"
    exit 1
  fi
}

firewall_cmd() {
  sudo firewall-cmd "$@"
}

# ===== FIREWALL CONFIGURATION =====

ensure_firewalld_active() {
  log "Ensuring firewalld is active..."
  if ! systemctl is-enabled firewalld >/dev/null 2>&1; then
    sudo systemctl enable --now firewalld
  elif ! systemctl is-active firewalld >/dev/null 2>&1; then
    sudo systemctl start firewalld
  fi
  log "✓ firewalld active"
}

ensure_zone_exists() {
  local zone="$1"
  if ! firewall_cmd --permanent --get-zones | tr ' ' '\n' | grep -qx "$zone"; then
    log "Creating zone '$zone'"
    firewall_cmd --permanent --new-zone="$zone"
  fi
}

configure_trusted_zone() {
  local zone="geckoforge-trusted"
  log "Configuring trusted network zone..."
  
  ensure_zone_exists "$zone"

  # Add private network ranges to trusted zone
  for cidr in 192.168.0.0/16 10.0.0.0/8 172.16.0.0/12; do
    if ! firewall_cmd --permanent --zone="$zone" --list-sources | tr ' ' '\n' | grep -qx "$cidr"; then
      log "  Adding source $cidr to $zone"
      firewall_cmd --permanent --zone="$zone" --add-source="$cidr"
    fi
  done

  # Allow SSH on custom port 223
  firewall_cmd --permanent --zone="$zone" --add-port=223/tcp
  
  # Allow KDE Connect for device integration
  firewall_cmd --permanent --zone="$zone" --add-service=kdeconnect
  
  # Allow mDNS for local network discovery
  firewall_cmd --permanent --zone="$zone" --add-service=mdns
  
  # Allow DHCPv6 client
  firewall_cmd --permanent --zone="$zone" --add-service=dhcpv6-client

  log "✓ Trusted zone configured"
}

configure_default_policy() {
  log "Setting default firewall policy to DROP..."
  
  local default_zone
  default_zone=$(firewall_cmd --get-default-zone)
  
  if [[ "$default_zone" != "drop" ]]; then
    firewall_cmd --set-default-zone=drop
    firewall_cmd --permanent --set-default-zone=drop
  fi

  # Ensure drop zone blocks unsolicited incoming
  firewall_cmd --permanent --zone=drop --set-target=DROP
  firewall_cmd --permanent --zone=drop --remove-service=ssh >/dev/null 2>&1 || true
  firewall_cmd --permanent --zone=drop --remove-service=kdeconnect >/dev/null 2>&1 || true
  
  log "✓ Default policy: DROP (block unsolicited inbound)"
}

# ===== AUTOMATIC UPDATES =====

configure_auto_updates() {
  log "Configuring automatic security updates..."
  
  if ! command -v yast2-online-update-configuration >/dev/null 2>&1; then
    sudo zypper install -y yast2-online-update-configuration
  fi
  
  sudo sed -i 's/^UPDATE_MESSAGES=.*/UPDATE_MESSAGES="yes"/' /etc/sysconfig/automatic_online_update
  sudo sed -i 's/^AOU_ENABLE_CRONJOB=.*/AOU_ENABLE_CRONJOB="true"/' /etc/sysconfig/automatic_online_update
  
  sudo systemctl enable --now yast2-online-update.timer 2>/dev/null || true
  
  log "✓ Automatic security updates enabled"
}

# ===== FAIL2BAN =====

configure_fail2ban() {
  log ""
  read -p "Install fail2ban for SSH brute-force protection? (y/N): " -n 1 -r
  echo
  
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    log "Installing fail2ban..."
    sudo zypper install -y fail2ban
    
    sudo tee /etc/fail2ban/jail.d/sshd.local >/dev/null <<'EOF'
[sshd]
enabled = true
port = 223
maxretry = 5
bantime = 3600
findtime = 600
EOF
    
    sudo systemctl enable --now fail2ban
    sudo systemctl restart fail2ban
    
    log "✓ fail2ban configured for SSH port 223"
  else
    log "Skipping fail2ban installation"
  fi
}

# ===== INTERFACE ASSIGNMENT =====

show_interface_help() {
  log ""
  log "Current network interfaces:"
  if command -v nmcli >/dev/null 2>&1; then
    nmcli -t -f DEVICE,STATE device status 2>/dev/null | column -t -s:
  else
    ip -br link show | grep -v "^lo"
  fi
  
  log ""
  log "To assign an interface to the trusted zone, run:"
  log "  sudo firewall-cmd --zone=geckoforge-trusted --change-interface=<interface>"
  log "  sudo firewall-cmd --runtime-to-permanent"
}

# ===== SUMMARY =====

reload_and_summarize() {
  log ""
  log "Reloading firewall configuration..."
  firewall_cmd --reload
  
  log ""
  log "═══════════════════════════════════════════"
  log "  Firewall & Security Hardening Complete"
  log "═══════════════════════════════════════════"
  log ""
  log "Firewall Status:"
  log "  • Default policy: DROP (blocks unsolicited inbound)"
  log "  • Trusted networks: 192.168.0.0/16, 10.0.0.0/8, 172.16.0.0/12"
  log "  • Allowed services in trusted zone:"
  log "    - SSH (port 223)"
  log "    - KDE Connect"
  log "    - mDNS"
  log "    - DHCPv6 client"
  log ""
  log "Security Features:"
  log "  • Automatic security updates: enabled"
  log "  • fail2ban: $(systemctl is-active fail2ban 2>/dev/null || echo "not installed")"
  log ""
  log "Verify configuration:"
  log "  sudo firewall-cmd --list-all-zones"
  log "  sudo firewall-cmd --zone=geckoforge-trusted --list-all"
  log ""
}

# ===== MAIN =====

main() {
  require_binary "firewall-cmd"
  require_binary "systemctl"
  require_binary "zypper"
  
  log "═══════════════════════════════════════════"
  log "  Geckoforge Firewall & Security Setup"
  log "═══════════════════════════════════════════"
  log ""
  
  ensure_firewalld_active
  configure_trusted_zone
  configure_default_policy
  configure_auto_updates
  configure_fail2ban
  reload_and_summarize
  show_interface_help
}

main "$@"
