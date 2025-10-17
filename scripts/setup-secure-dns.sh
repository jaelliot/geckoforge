#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "[secure-network] $*"
}

require_binary() {
  local bin="$1"
  if ! command -v "$bin" >/dev/null 2>&1; then
    log "Missing required command: $bin"
    exit 1
  fi
}

configure_dns_over_tls() {
  local dropin_dir="/etc/systemd/resolved.conf.d"
  local dropin_file="${dropin_dir}/10-geckoforge-secure-dns.conf"

  sudo mkdir -p "$dropin_dir"
  sudo tee "$dropin_file" >/dev/null <<'EOF'
[Resolve]
DNS=9.9.9.9#dns.quad9.net 149.112.112.112#dns.quad9.net
FallbackDNS=
DNSOverTLS=yes
DNSSEC=yes
Domains=~.
EOF

  if [[ ! -L /etc/resolv.conf ]]; then
    sudo rm -f /etc/resolv.conf
    sudo ln -s /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
  fi

  sudo systemctl enable --now systemd-resolved
  sudo systemctl restart systemd-resolved
  log "Configured Quad9 DNS-over-TLS with systemd-resolved"
}

install_protonvpn_cli() {
  if command -v protonvpn >/dev/null 2>&1; then
    log "ProtonVPN CLI already installed"
    return
  fi

  if sudo zypper search --match-exact protonvpn-cli >/dev/null 2>&1; then
    log "Installing protonvpn-cli"
    sudo zypper install -y protonvpn-cli
    log "ProtonVPN CLI installed"
  else
    cat <<'EOF'
[warn] protonvpn-cli package not found in configured repositories.
To install ProtonVPN CLI, add the official Proton repository:
  sudo zypper ar https://repo.protonvpn.com/linux/opensuse/leap/15.6 stable-protonvpn
  sudo zypper refresh
  sudo zypper install -y protonvpn-cli
If the repository URL changes, refer to ProtonVPN's official documentation.
EOF
  fi
}

main() {
  require_binary "sudo"
  require_binary "systemctl"
  require_binary "tee"
  require_binary "zypper"

  configure_dns_over_tls
  install_protonvpn_cli

  cat <<'EOF'
Secure networking configuration complete.
- DNS: Quad9 over TLS with DNSSEC enabled
- ProtonVPN: CLI installed or installation instructions provided

Verify DNS:
  resolvectl status

Initialize ProtonVPN:
  sudo protonvpn init
  protonvpn login <username>
EOF
}

main "$@"
