#!/bin/bash
# KIWI config.sh - Runs at the end of the prepare step
# This script configures the unpacked image

set -euo pipefail

echo "=== geckoforge config.sh starting ==="

#----------------------------------------------
# Set permissions on first-boot scripts (0755)
#----------------------------------------------
chmod 0755 /usr/local/sbin/firstboot-nvidia.sh
chmod 0755 /usr/local/sbin/firstboot-nix.sh
chmod 0755 /usr/local/sbin/firstboot-ssh-hardening.sh

#----------------------------------------------
# Set permissions on systemd service files (0644)
#----------------------------------------------
chmod 0644 /etc/systemd/system/geckoforge-firstboot.service
chmod 0644 /etc/systemd/system/geckoforge-nix.service
chmod 0644 /etc/systemd/system/geckoforge-ssh-hardening.service

#----------------------------------------------
# Set permissions on config files (0644)
#----------------------------------------------
chmod 0644 /etc/zypp/repos.d/nvidia.repo
chmod 0644 /etc/snapper/configs/root
chmod 0644 /etc/firefox/policies/policies.json

#----------------------------------------------
# Set permissions on JuxTheme files
#----------------------------------------------
# Aurorae window decoration theme
chmod -R 0755 /usr/share/aurorae/themes/JuxDeco
find /usr/share/aurorae/themes/JuxDeco -type f -exec chmod 0644 {} \;

# Plasma desktop theme
chmod -R 0755 /usr/share/plasma/desktoptheme/JuxPlasma
find /usr/share/plasma/desktoptheme/JuxPlasma -type f -exec chmod 0644 {} \;

# Kvantum Qt theme
chmod -R 0755 /usr/share/Kvantum/NoMansSkyJux
find /usr/share/Kvantum/NoMansSkyJux -type f -exec chmod 0644 {} \;

# Color scheme
chmod 0644 /usr/share/color-schemes/JuxTheme.colors

#----------------------------------------------
# Enable first-boot services
#----------------------------------------------
systemctl enable geckoforge-firstboot.service || true
systemctl enable geckoforge-nix.service || true
systemctl enable geckoforge-ssh-hardening.service || true

#----------------------------------------------
# Enable essential system services
#----------------------------------------------
systemctl enable NetworkManager || true
systemctl enable sddm || true
systemctl enable firewalld || true
systemctl enable apparmor || true
systemctl enable snapper-timeline.timer || true
systemctl enable snapper-cleanup.timer || true
systemctl enable tlp || true
systemctl enable thermald || true
systemctl enable bluetooth || true

#----------------------------------------------
# Enable PipeWire audio (user session)
#----------------------------------------------
systemctl --global enable pipewire.socket || true
systemctl --global enable pipewire-pulse.socket || true
systemctl --global enable wireplumber.service || true

#----------------------------------------------
# Configure Flatpak remotes
#----------------------------------------------
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true

echo "=== geckoforge config.sh complete ==="
