<!-- @file docs/themes.md -->
<!-- @description Guide for using and customizing the Mystical Blue (Jux) theme -->
<!-- @update-policy Update when new themes are added or activation methods change -->

# Mystical Blue (Jux) Theme

Geckoforge includes the **Mystical Blue (Jux)** theme - a professional dark blue aesthetic for KDE Plasma.

---

## Theme Components

### JuxTheme Color Scheme
- **Dark blue/gray palette** - Professional workspace appearance
- **High contrast** - Excellent readability
- **Accent color** - Mystical blue (#3e6fd9)

### JuxPlasma Desktop Theme
- **Modern panels** - Sleek, minimal panel styling
- **Widget theming** - Unified widget appearance
- **Icon integration** - Works with any icon set

### JuxDeco Window Decorations
- **Minimal titlebar** - Clean, unobtrusive borders
- **Rounded corners** - Modern window appearance
- **Matching colors** - Consistent with overall theme

### NoMansSkyJux Qt Theme
- **Kvantum-based** - Advanced Qt styling engine
- **Application theming** - Unified appearance across Qt apps
- **Custom buttons** - Themed UI elements

---

## Quick Activation

### Option 1: Setup Script (Recommended)

```bash
cd ~/git/geckoforge
./scripts/setup-jux-theme.sh
```

**Then:**
1. Log out
2. Log back in
3. Theme is active!

### Option 2: Home-Manager (Declarative)

Edit `~/git/home/home.nix`:

```nix
{
  imports = [ ./modules/kde-theme.nix ];
  
  programs.kde.theme.enable = true;
}
```

Apply changes:
```bash
home-manager switch --flake ~/git/home
```

**Then:** Log out and back in.

### Option 3: Manual (KDE System Settings)

1. **Color Scheme:**
   - System Settings → Appearance → Colors
   - Select "JuxTheme"
   - Click Apply

2. **Desktop Theme:**
   - System Settings → Appearance → Plasma Style
   - Select "JuxPlasma"
   - Click Apply

3. **Window Decorations:**
   - System Settings → Appearance → Window Decorations
   - Select "JuxDeco"
   - Click Apply

4. **Qt Application Theme:**
   - System Settings → Appearance → Application Style
   - Select "Kvantum"
   - Click Apply
   - Open Kvantum Manager
   - Select "NoMansSkyJux"

---

## Customization

### Change Accent Color

Edit the color scheme:
```bash
kate ~/.local/share/color-schemes/JuxTheme.colors
```

Modify `DecorationFocus` values (currently `62,111,217` - blue).

### Use Different Components

Mix and match:
- Use JuxTheme colors with different Plasma theme
- Use JuxDeco decorations with different colors
- Use NoMansSkyJux with different desktop theme

**Example:** JuxTheme + Breeze Plasma + JuxDeco

### Create Variant

Copy and modify:
```bash
cp -r ~/.local/share/plasma/desktoptheme/JuxPlasma \
      ~/.local/share/plasma/desktoptheme/MyCustomTheme
```

Edit `metadata.json` to change name and author.

---

## Reverting to Default

### Quick Revert

System Settings → Appearance:
1. Colors → Select "Breeze"
2. Plasma Style → Select "Breeze"
3. Window Decorations → Select "Breeze"
4. Application Style → Select "Breeze"

### Script Revert (Future Enhancement)

```bash
./scripts/revert-theme.sh  # TODO: Create this
```

---

## Troubleshooting

### Qt Apps Don't Match Theme

**Symptom:** Some applications still look default

**Fix:**
```bash
kvantummanager --set NoMansSkyJux
# Log out and back in
```

### Window Decorations Not Applied

**Symptom:** Titlebars still look default

**Fix:**
```bash
kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key theme __aurorae__svg__JuxDeco
qdbus org.kde.KWin /KWin reconfigure
```

### Panels Look Wrong

**Symptom:** Panels have wrong colors

**Fix:**
```bash
plasma-apply-desktoptheme JuxPlasma
# Log out and back in
```

---

## Theme Credits

**Mystical Blue (Jux)** created by [Juxtopposed](https://github.com/Juxtopposed)

- Original theme: https://github.com/Juxtopposed/Mystical-Blue-Theme
- License: See theme AUTHORS files
- Modified: Integrated into geckoforge

**Components:**
- **JuxDeco** - Window decorations
- **JuxPlasma** - Desktop theme
- **NoMansSkyJux** - Kvantum Qt theme (based on No Man's Sky theme by Patrik Wyde)
- **JuxTheme** - Color scheme

---

## Adding Custom Themes

Want to add your own theme to geckoforge?

1. Place theme files in `themes/your-theme/`
2. Follow directory structure:
   ```
   themes/your-theme/
   ├── aurorae/YourDeco/
   ├── plasma/YourPlasma/
   ├── kvantum/YourKvantum/
   └── YourTheme.colors
   ```
3. Copy to KIWI overlay: `profiles/.../root/usr/share/`
4. Build ISO: `./tools/kiwi-build.sh`

See contribution guide for details.