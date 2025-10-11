#!/usr/bin/env bash
# @file scripts/setup-jux-theme.sh
# @description Activate Mystical Blue (Jux) theme for KDE Plasma and Qt applications
# @update-policy Update when theme activation methods change or new components are added

set -euo pipefail

cat <<'EOF'
═══════════════════════════════════════════
  Mystical Blue (Jux) Theme Activation
═══════════════════════════════════════════

This script activates the Mystical Blue theme:
• JuxTheme color scheme (KDE)
• JuxPlasma desktop theme (panels/widgets)
• JuxDeco window decorations (titlebar)
• NoMansSkyJux Qt theme (applications)

Changes take effect after logging out and back in.

═══════════════════════════════════════════
EOF

echo ""
read -p "Activate Mystical Blue theme? (y/N): " confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo "Activating theme..."

# 1. KDE Color Scheme
echo "  • Setting color scheme..."
kwriteconfig5 --file kdeglobals --group General --key ColorScheme JuxTheme

# 2. Plasma Desktop Theme
echo "  • Setting desktop theme..."
plasma-apply-desktoptheme JuxPlasma

# 3. Window Decorations
echo "  • Setting window decorations..."
kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key theme __aurorae__svg__JuxDeco

# 4. Kvantum Qt Theme
echo "  • Setting Qt theme..."
kvantummanager --set NoMansSkyJux

# 5. Force KWin to reload
echo "  • Reloading window manager..."
qdbus org.kde.KWin /KWin reconfigure

echo ""
echo "═══════════════════════════════════════════"
echo "  Theme Activated!"
echo "═══════════════════════════════════════════"
echo ""
echo "For full effect:"
echo "  1. Log out (click user menu → Log Out)"
echo "  2. Log back in"
echo ""
echo "To revert to default theme:"
echo "  System Settings → Appearance"
echo ""