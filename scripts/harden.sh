#!/usr/bin/env bash
set -euo pipefail

echo "[harden] Applying security hardening..."

echo "[firewall] Configuring firewalld..."
sudo systemctl enable --now firewalld

sudo firewall-cmd --set-default-zone=public

read -p "Allow SSH through firewall? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo firewall-cmd --permanent --add-service=ssh
fi

sudo firewall-cmd --reload

echo "[updates] Enabling automatic security patches..."
sudo zypper install -y yast2-online-update-configuration

sudo sed -i 's/^UPDATE_MESSAGES=.*/UPDATE_MESSAGES="yes"/' /etc/sysconfig/automatic_online_update
sudo sed -i 's/^AOU_ENABLE_CRONJOB=.*/AOU_ENABLE_CRONJOB="true"/' /etc/sysconfig/automatic_online_update

sudo systemctl enable --now yast2-online-update.timer || true

read -p "Install fail2ban for SSH protection? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo zypper install -y fail2ban
    sudo systemctl enable --now fail2ban
    sudo tee /etc/fail2ban/jail.d/sshd.local <<EOF
[sshd]
enabled = true
maxretry = 5
bantime = 3600
EOF
    sudo systemctl restart fail2ban
fi

read -p "Enable auditd for security monitoring? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo zypper install -y audit
    sudo systemctl enable --now auditd
fi

echo "[harden] Hardening complete!"
echo ""
echo "Firewall status:"
sudo firewall-cmd --list-all
