#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "[secure-firewall] $*"
}

require_binary() {
  local bin="$1"
  if ! command -v "$bin" >/dev/null 2>&1; then
    log "Missing required command: $bin"
    exit 1
  fi
}

firewall_cmd() {
  sudo firewall-cmd "$@"
}

ensure_firewalld_active() {
  if ! systemctl is-enabled firewalld >/dev/null 2>&1; then
    log "Enabling firewalld"
    sudo systemctl enable --now firewalld
  elif ! systemctl is-active firewalld >/dev/null 2>&1; then
    log "Starting firewalld"
    sudo systemctl start firewalld
  fi
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
  ensure_zone_exists "$zone"

  for cidr in 192.168.0.0/16 10.0.0.0/8 172.16.0.0/12; do
    if ! firewall_cmd --permanent --zone="$zone" --list-sources | tr ' ' '\n' | grep -qx "$cidr"; then
      log "Adding source $cidr to $zone"
      firewall_cmd --permanent --zone="$zone" --add-source="$cidr"
    fi
  done

  # Allow SSH on custom port, KDE Connect, and mDNS inside trusted networks
  firewall_cmd --permanent --zone="$zone" --add-port=223/tcp
  firewall_cmd --permanent --zone="$zone" --add-service=kdeconnect
  firewall_cmd --permanent --zone="$zone" --add-service=mdns
  firewall_cmd --permanent --zone="$zone" --add-service=dhcpv6-client

  log "Trusted zone configured"
}

configure_default_policy() {
  local default_zone
  default_zone=$(firewall_cmd --get-default-zone)
  if [[ "$default_zone" != "drop" ]]; then
    log "Setting default zone to drop"
    firewall_cmd --set-default-zone=drop
    firewall_cmd --permanent --set-default-zone=drop
  fi

  # Ensure outgoing connections allowed; drop zone blocks unsolicited incoming
  firewall_cmd --permanent --zone=drop --set-target=DROP
  firewall_cmd --permanent --zone=drop --remove-service=ssh >/dev/null 2>&1 || true
  firewall_cmd --permanent --zone=drop --remove-service=kdeconnect >/dev/null 2>&1 || true
}

assign_interfaces() {
  local zone="geckoforge-trusted"
  if command -v nmcli >/dev/null 2>&1; then
    log "Current interfaces: $(nmcli -t -f DEVICE device status 2>/dev/null | tr '\n' ' ')"
  fi
  cat <<'EOF'
If you want to assign a specific interface (e.g., ethernet or wifi) to the
trusted zone, run:
  sudo firewall-cmd --zone=geckoforge-trusted --change-interface=<iface>
EOF
}

reload_firewall() {
  firewall_cmd --reload
  log "firewalld reloaded"
  log "Default zone: $(firewall_cmd --get-default-zone)"
  log "Trusted zone services: $(firewall_cmd --zone=geckoforge-trusted --list-all)"
}

main() {
  require_binary "firewall-cmd"
  require_binary "systemctl"
  ensure_firewalld_active
  configure_trusted_zone
  configure_default_policy
  reload_firewall
  assign_interfaces

  cat <<'EOF'
Firewall hardened.
- Default zone: drop (unsolicited inbound blocked)
- Trusted networks: 192.168.0.0/16, 10.0.0.0/8, 172.16.0.0/12
- Allowed services in trusted zone: SSH (port 223), KDE Connect, mDNS

Remember to assign specific interfaces to geckoforge-trusted if needed.
EOF
}

main "$@"
