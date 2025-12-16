---
applyTo: profile/**,scripts/**,**/*.conf,**/*.ini,**/*.yaml,**/*.yml
---

---
description: VPN (ProtonVPN) and privacy-respecting DNS configuration
alwaysApply: false
version: 0.3.0
---

## Use when
- Setting up VPN connectivity
- Configuring DNS privacy
- Troubleshooting network issues
- Adding network-related Home-Manager modules

## Privacy Philosophy

**Privacy by default, convenience when needed.**

- DNS: Use privacy-respecting resolvers (Quad9, Cloudflare, NextDNS)
- VPN: ProtonVPN for sensitive work and travel
- Firewall: Restrict unnecessary connections
- No telemetry: Disable KDE/system telemetry

---

## DNS Configuration

### Privacy-Respecting DNS Providers

**Recommended (in order):**
1. **Quad9** (9.9.9.9) - Non-profit, DNSSEC, malware blocking
2. **Cloudflare** (1.1.1.1) - Fast, privacy-focused
3. **NextDNS** - Customizable, paid tiers available

### System-Wide DNS (Layer 1/3)

#### Via NetworkManager (Preferred)
```bash
# scripts/setup-dns.sh
#!/usr/bin/env bash
set -euo pipefail

echo "[dns] Configuring privacy-respecting DNS..."

# Get active connection
CONNECTION=$(nmcli -t -f NAME connection show --active | head -n1)

# Configure DNS
nmcli connection modify "$CONNECTION" \
  ipv4.dns "9.9.9.9,149.112.112.112" \
  ipv4.ignore-auto-dns yes \
  ipv6.dns "2620:fe::fe,2620:fe::9" \
  ipv6.ignore-auto-dns yes

# Apply changes
nmcli connection up "$CONNECTION"

echo "[dns] DNS configured to Quad9"
echo "Test: nslookup google.com"
```

#### Via systemd-resolved
```bash
# Alternative: Edit /etc/systemd/resolved.conf
sudo tee /etc/systemd/resolved.conf <<EOF
[Resolve]
DNS=9.9.9.9 149.112.112.112
FallbackDNS=1.1.1.1 1.0.0.1
DNSSEC=yes
DNSOverTLS=opportunistic
EOF

sudo systemctl restart systemd-resolved
```

### DNS Verification
```bash
# Check active DNS
resolvectl status

# Test resolution
nslookup google.com

# Check for DNS leaks
curl https://www.dnsleaktest.com/
```

---

## ProtonVPN Setup

### Installation (Layer 3: User Setup)

#### Option 1: Official ProtonVPN CLI (Recommended)
```bash
# scripts/setup-protonvpn.sh
#!/usr/bin/env bash
set -euo pipefail

echo "[vpn] Installing ProtonVPN..."

# Add ProtonVPN repo (if available for openSUSE)
# Otherwise, use manual installation

# Install dependencies
sudo zypper install -y openvpn dialog python3-pip

# Install ProtonVPN CLI
sudo pip3 install protonvpn-cli

# Initialize
protonvpn init

echo "[vpn] ProtonVPN installed"
echo "Login: protonvpn login"
echo "Connect: protonvpn connect --fastest"
```

#### Option 2: OpenVPN + ProtonVPN Config Files
```bash
# Download ProtonVPN OpenVPN configs
# From: https://account.protonvpn.com/downloads

# Place configs in:
mkdir -p ~/.config/protonvpn/ovpn

# Connect manually
sudo openvpn --config ~/.config/protonvpn/ovpn/us-free-01.protonvpn.net.udp.ovpn
```

### ProtonVPN via Home-Manager (Layer 4)

```nix
# home/modules/networking.nix
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    openvpn
    # protonvpn-cli not in nixpkgs - install via pip
  ];

  # Helper scripts
  home.file.".local/bin/vpn-connect" = {
    text = ''
      #!/usr/bin/env bash
      protonvpn connect --fastest
    '';
    executable = true;
  };

  home.file.".local/bin/vpn-disconnect" = {
    text = ''
      #!/usr/bin/env bash
      protonvpn disconnect
    '';
    executable = true;
  };

  # Shell aliases
  programs.bash.shellAliases = {
    vpn = "protonvpn";
    vpn-on = "protonvpn connect --fastest";
    vpn-off = "protonvpn disconnect";
    vpn-status = "protonvpn status";
  };
}
```

### ProtonVPN Usage

```bash
# Login (one-time)
protonvpn login

# Connect to fastest server
protonvpn connect --fastest

# Connect to specific country
protonvpn connect --cc US

# Connect to P2P server
protonvpn connect --p2p

# Disconnect
protonvpn disconnect

# Check status
protonvpn status

# List servers
protonvpn list
```

### VPN Kill Switch (Optional)

```bash
# Prevent traffic when VPN disconnects
protonvpn configure

# Enable kill switch when prompted
```

---

## Firewall Configuration

### UFW (Uncomplicated Firewall)

#### Installation
```bash
sudo zypper install -y ufw

# Enable
sudo systemctl enable --now ufw

# Default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing
```

#### Basic Rules
```bash
# Allow SSH (if needed)
sudo ufw allow ssh

# Allow HTTP/HTTPS
sudo ufw allow http
sudo ufw allow https

# Allow KDE Connect (if using)
sudo ufw allow 1714:1764/tcp
sudo ufw allow 1714:1764/udp

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status verbose
```

---

## Docker Network Configuration

### Prevent DNS Leaks

```bash
# /etc/docker/daemon.json
sudo tee /etc/docker/daemon.json <<EOF
{
  "dns": ["9.9.9.9", "149.112.112.112"],
  "dns-search": []
}
EOF

sudo systemctl restart docker
```

### Verify Docker DNS
```bash
docker run --rm alpine nslookup google.com
# Should use configured DNS
```

---

## KDE Privacy Settings

### Disable Telemetry

```bash
# Disable KDE telemetry (if present)
kwriteconfig5 --file kdeglobals --group KDE --key "UserFeedbackConsent" false

# Disable Plasma crash reporting
kwriteconfig5 --file kcrashrc --group "KCrash" --key "Enabled" false
```

### Privacy-Focused KDE Settings

```bash
# Disable online accounts
kwriteconfig5 --file kded5rc --group "Module-kaccounts" --key "autoload" false

# Disable weather widget (prevents location leaks)
# Do manually via Plasma settings

# Disable web search in KRunner
kwriteconfig5 --file krunnerrc --group "Plugins" --key "baloosearchEnabled" false
```

---

## Chromium Privacy Hardening

### Via Home-Manager

```nix
# home/modules/desktop.nix (already configured)
programs.chromium = {
  enable = true;
  extensions = [
    { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; }  # uBlock Origin
    { id = "nngceckbapebfimnlniiiahkandclblb"; }  # Bitwarden
  ];
  commandLineArgs = [
    # Privacy flags
    "--disable-background-networking"
    "--disable-breakpad"
    "--disable-crash-reporter"
    "--disable-sync"
    "--disable-speech-api"
    
    # Performance
    "--enable-features=VaapiVideoDecoder"
    "--disable-features=UseChromeOSDirectVideoDecoder"
    
    # DNS-over-HTTPS (optional, redundant with system DNS)
    "--enable-features=DnsOverHttps"
    "--dns-over-https-server=https://dns.quad9.net/dns-query"
  ];
};
```

---

## Network Monitoring

### Check Active Connections
```bash
# List open connections
sudo ss -tupn

# List listening ports
sudo ss -tulpn

# Check for suspicious connections
sudo netstat -antup | grep ESTABLISHED
```

### Monitor DNS Queries
```bash
# Check systemd-resolved queries (if using)
sudo journalctl -u systemd-resolved -f

# Or use tcpdump
sudo tcpdump -i any port 53
```

---

## Travel / Public WiFi Setup

### Pre-Travel Checklist
- [ ] VPN installed and tested
- [ ] DNS configured to privacy-respecting servers
- [ ] Firewall enabled
- [ ] uBlock Origin active in Chromium
- [ ] Kill switch enabled (if using ProtonVPN)

### Connection Procedure
```bash
# 1. Connect to WiFi
nmcli device wifi connect SSID password PASSWORD

# 2. Immediately connect VPN
protonvpn connect --fastest

# 3. Verify connection
curl https://ifconfig.me  # Should show VPN IP
resolvectl status  # Should show VPN DNS

# 4. Test for leaks
curl https://www.dnsleaktest.com/
```

---

## Troubleshooting

### DNS Not Resolving
```bash
# Check DNS configuration
resolvectl status

# Flush DNS cache
sudo resolvectl flush-caches

# Test specific DNS server
nslookup google.com 9.9.9.9
```

### VPN Won't Connect
```bash
# Check OpenVPN logs
sudo journalctl -u openvpn@*

# Test manually
sudo openvpn --config /path/to/config.ovpn

# Check firewall
sudo ufw status
sudo ufw allow 1194/udp  # OpenVPN port
```

### VPN Drops Frequently
```bash
# Enable kill switch
protonvpn configure
# Select "Enable Kill Switch"

# Use more stable protocol
protonvpn connect --protocol tcp
```

### DNS Leaks
```bash
# Force DNS through VPN
# Edit /etc/NetworkManager/NetworkManager.conf
[main]
dns=none

sudo systemctl restart NetworkManager

# Manually set DNS
nmcli connection modify "$CONNECTION" ipv4.dns "10.8.8.1"
```

---

## Verification Checklist

After setup:
- [ ] `nslookup google.com` uses Quad9 (9.9.9.9)
- [ ] `curl https://ifconfig.me` shows non-ISP IP when VPN active
- [ ] `protonvpn status` shows connected
- [ ] `sudo ufw status` shows active with rules
- [ ] Docker containers use custom DNS
- [ ] No DNS leaks: https://www.dnsleaktest.com/
- [ ] WebRTC doesn't leak IP: https://browserleaks.com/webrtc

---

## Advanced: Split Tunneling (Future)

```bash
# Route only specific apps through VPN
# Or exclude specific apps from VPN

# This is complex and may require custom routing rules
# Document when implemented
```

---

## Best Practices

### Do:
- ✅ Use VPN on public WiFi
- ✅ Verify DNS settings after connecting
- ✅ Enable kill switch for sensitive work
- ✅ Test for leaks periodically
- ✅ Keep firewall enabled

### Don't:
- ❌ Trust public WiFi without VPN
- ❌ Use ISP DNS servers
- ❌ Disable firewall without reason
- ❌ Forget to disconnect VPN when not needed (affects speed)

---

## Integration with firstrun-user.sh

```bash
# scripts/firstrun-user.sh (add section)

echo ""
echo "=== Network Privacy Setup ==="
read -p "Configure privacy-respecting DNS (Quad9)? (Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    ./scripts/setup-dns.sh
fi

read -p "Install ProtonVPN? (Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    ./scripts/setup-protonvpn.sh
fi
```