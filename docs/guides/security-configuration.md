# Security Configuration — Hardened Networking and Applications

## Overview
This guide describes the layered security enhancements included with geckoforge.
The workflow covers SSH hardening during first boot, a default-deny firewall with
trusted LAN access, encrypted DNS with ProtonVPN CLI integration, automatic
security updates, and sandboxed Flatpak deployments for high-risk applications.

## Layer 2 — SSH Hardening
`profiles/leap-15.6/kde-nvidia/scripts/firstboot-ssh-hardening.sh` runs during
initial boot to apply production SSH policies:

- Moves the daemon to port **223** with ed25519 and RSA host keys
- Restricts cryptography to Curve25519 key exchange, AES-256-GCM, and ChaCha20
- Disables password authentication and reduces login grace/attempts
- Enables VERBOSE logging for auditing
- Installs an enhanced legal banner at `/etc/issue.net`

After installation, connect with:
```
ssh -p 223 <user>@<hostname>
```

## Layer 3 — Secure Network Tooling
Run the user setup scripts as needed:

### Firewall
```
./scripts/setup-secure-firewall.sh
```
- Enforces a drop-by-default policy via firewalld
- Creates `geckoforge-trusted` zone for RFC1918 networks (10/8, 172.16/12, 192.168/16)
- Allows SSH (port 223), KDE Connect, and mDNS only inside trusted networks
- Prompts to bind specific interfaces to the trusted zone

### DNS over TLS & ProtonVPN
```
./scripts/setup-secure-dns.sh
```
- Configures systemd-resolved with Quad9 DNS-over-TLS and DNSSEC
- Re-links `/etc/resolv.conf` to the systemd stub resolver
- Installs ProtonVPN CLI if available via zypper or prints repository instructions

### Automatic Security Updates
```
./scripts/setup-auto-updates.sh
```
- Creates `geckoforge-security-updates.service` and timer for daily security patches
- Randomizes execution within a 60-minute window to avoid predictable traffic
- Logs activity to `journalctl -u geckoforge-security-updates.service`

## Layer 4 — Application Sandboxing
Enable the security module in `home/home.nix`:
```nix
geckoforge.security.enable = true;
```

The module performs the following on `home-manager switch`:

- Installs `bubblewrap`, `dnsutils`, and `rkhunter`
- Ensures Flatpak availability and installs:
  - `org.mozilla.firefox`
  - `org.chromium.Chromium`
  - `org.libreoffice.LibreOffice`
- Applies strict overrides:
  - Removes access to the home directory
  - Grants read/write access to `~/Downloads` (and `~/Documents` for LibreOffice)
- Drops wrapper scripts (`~/.local/bin/firefox`, `chromium`, `libreoffice`) that exec
  the Flatpak builds
- Installs Firefox enterprise policies with preloaded security extensions
  (uBlock Origin, HTTPS Everywhere, ClearURLs) and disables password storage

## Verification Checklist
- `sshd -T | grep -E "port|ciphers|kexalgorithms"` shows the hardened settings
- `firewall-cmd --get-default-zone` returns `drop`
- `resolvectl status` reports Quad9 with DNSOverTLS=yes
- `systemctl list-timers geckoforge-security-updates.timer` displays the schedule
- `flatpak info org.mozilla.firefox` confirms the sandboxed browsers are present

## Troubleshooting
- **Cannot reach SSH**: Confirm firewall trusted zone contains your subnet and that
  you are connecting on port 223.
- **DNS override skipped**: Verify `systemd-resolved` is enabled; some server setups
  use NetworkManager DNS management which may need alignment.
- **ProtonVPN package missing**: Add Proton's repository per script output or follow
  the latest instructions from ProtonVPN.
- **Flatpak overrides reset**: Rerun `home-manager switch` to reapply sandbox rules.

## Related Files
- `profiles/leap-15.6/kde-nvidia/scripts/firstboot-ssh-hardening.sh`
- `scripts/setup-secure-firewall.sh`
- `scripts/setup-secure-dns.sh`
- `scripts/setup-auto-updates.sh`
- `home/modules/security.nix`
