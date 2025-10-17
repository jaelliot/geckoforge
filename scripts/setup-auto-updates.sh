#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "[auto-updates] $*"
}

require_binary() {
  local bin="$1"
  if ! command -v "$bin" >/dev/null 2>&1; then
    log "Missing required command: $bin"
    exit 1
  fi
}

write_unit_files() {
  local service="/etc/systemd/system/geckoforge-security-updates.service"
  local timer="/etc/systemd/system/geckoforge-security-updates.timer"

  sudo tee "$service" >/dev/null <<'EOF'
[Unit]
Description=Apply security patches (zypper patch)
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/zypper --non-interactive patch --category security
Nice=10
IOSchedulingClass=best-effort
IOSchedulingPriority=7
SuccessExitStatus=0 100
EOF

  sudo tee "$timer" >/dev/null <<'EOF'
[Unit]
Description=Daily security patch installation

[Timer]
OnCalendar=daily
RandomizedDelaySec=3600
Persistent=true

[Install]
WantedBy=timers.target
EOF

  sudo systemctl daemon-reload
  sudo systemctl enable --now geckoforge-security-updates.timer
  log "Enabled geckoforge-security-updates.timer"
}

main() {
  require_binary "sudo"
  require_binary "systemctl"
  require_binary "zypper"

  write_unit_files

  cat <<'EOF'
Automatic security updates configured.
- Runs daily with a random delay up to 60 minutes
- Applies only security patches via zypper
- Review logs: journalctl -u geckoforge-security-updates.service
No automatic reboot is performed; reboot manually for kernel updates.
EOF
}

main "$@"
