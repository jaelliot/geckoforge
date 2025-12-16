#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "[ssh-hardening] $*"
}

ensure_dependencies() {
  local missing=()
  for cmd in ssh-keygen tee systemctl; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
  done
  if ((${#missing[@]})); then
    log "Missing required commands: ${missing[*]}"
    exit 1
  fi
}

ensure_host_keys() {
  log "Ensuring SSH host keys are present"
  ssh-keygen -A
}

harden_sshd_config() {
  local sshd_config="/etc/ssh/sshd_config"
  local backup="${sshd_config}.geckoforge.bak"

  if [[ ! -f "$sshd_config" ]]; then
    log "sshd_config not found; aborting"
    exit 1
  fi

  if [[ ! -f "$backup" ]]; then
    cp "$sshd_config" "$backup"
    log "Backed up original sshd_config to $backup"
  fi

  cat >"$sshd_config" <<'EOF'
# geckoforge hardened SSH configuration
# Generated during first-boot to apply production security standards.
# Based on openSUSE defaults with targeted overrides for cryptography,
# access controls, and auditing. Original file preserved as
# /etc/ssh/sshd_config.geckoforge.bak

Port 223
AddressFamily any
ListenAddress 0.0.0.0
ListenAddress ::

Protocol 2
HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_rsa_key

KexAlgorithms curve25519-sha256@libssh.org,curve25519-sha256
Ciphers aes256-gcm@openssh.com,chacha20-poly1305@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com

# Authentication hardening
authenticationmethods publickey
PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
PermitEmptyPasswords no
PermitRootLogin no
MaxAuthTries 3
LoginGraceTime 30

# Session management
UsePAM yes
AllowTcpForwarding no
X11Forwarding no
AllowAgentForwarding no
AllowStreamLocalForwarding no
PermitTunnel no
GatewayPorts no
ClientAliveInterval 300
ClientAliveCountMax 1
MaxSessions 2

# Logging and auditing
SyslogFacility AUTHPRIV
LogLevel VERBOSE

# Legal banner: /etc/issue.net managed separately
Banner /etc/issue.net

# Misc hardened defaults
IgnoreRhosts yes
HostbasedAuthentication no
PermitUserEnvironment no
PrintMotd no
Compression no
TCPKeepAlive no
StrictModes yes

# Only modern public key types
PubkeyAcceptedAlgorithms ssh-ed25519,rsa-sha2-512,rsa-sha2-256
HostKeyAlgorithms ssh-ed25519,rsa-sha2-512,rsa-sha2-256
EOF

  chmod 600 "$sshd_config"
  log "Applied hardened sshd_config"
}

write_security_banner() {
  local banner="/etc/issue.net"
  local backup="${banner}.geckoforge.bak"

  if [[ -f "$banner" && ! -f "$backup" ]]; then
    cp "$banner" "$backup"
    log "Backed up existing banner to $backup"
  fi

  cat >"$banner" <<'EOF'
**********************************************************************
*  Authorized Access Only                                            *
*                                                                    *
*  This system is the property of Jay Elliot (geckoforge).           *
*  Unauthorized access or use is prohibited and may result in        *
*  criminal and/or civil penalties.                                  *
*                                                                    *
*  All activities on this system are monitored and logged.           *
*  Evidence of unauthorized use may be provided to law enforcement.  *
*                                                                    *
*  By accessing this system you consent to monitoring and logging.   *
**********************************************************************
EOF

  chmod 644 "$banner"
  log "Security banner updated"
}

restart_sshd() {
  systemctl daemon-reload
  if systemctl is-enabled sshd.service >/dev/null 2>&1; then
    systemctl restart sshd.service
  else
    systemctl enable --now sshd.service
  fi
  log "sshd restarted with hardened configuration"
}

main() {
  ensure_dependencies
  ensure_host_keys
  harden_sshd_config
  write_security_banner
  restart_sshd
}

main "$@"
