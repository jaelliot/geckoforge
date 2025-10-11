# Font Configuration Guide

Geckoforge uses a carefully curated font stack optimized for development workflows and modern desktop use.

## Font Strategy

### Primary Development Font: FiraCode Nerd Font
- **Purpose**: Terminal, code editor, development tools
- **Features**: Programming ligatures, comprehensive symbols, monospace
- **Source**: Mozilla Fira Code + Nerd Font patches
- **Size**: 12pt default (configurable)

### System Font Stack
1. **Liberation** - Microsoft font metric-compatible
2. **DejaVu** - Comprehensive Unicode coverage  
3. **Noto Sans** - Google's universal font family
4. **Noto Emoji** - Color emoji support
5. **Noto CJK** - Chinese, Japanese, Korean support

## Font Distribution

### System Level (KIWI Profile)
```xml
<package>liberation-fonts</package>
<package>dejavu-fonts</package>
<package>noto-sans-fonts</package>
<package>noto-emoji-fonts</package>
<package>fontconfig</package>
```

### User Level (Home-Manager)
```nix
# Enhanced development fonts
(nerdfonts.override { fonts = [ "FiraCode" "JetBrainsMono" "SourceCodePro" ]; })
fira-code
jetbrains-mono
source-code-pro
ubuntu-font-family
liberation_ttf
dejavu_fonts
noto-fonts
noto-fonts-cjk
noto-fonts-emoji
```

## Terminal Configuration

### Kitty Terminal
- **Font**: FiraCode Nerd Font Mono
- **Ligatures**: Enabled for better code readability
- **Features**: Enhanced symbol rendering for development
- **Theme**: Gruvbox Dark for comfortable extended use

### Font Features Enabled
```
+cv01 +cv02 +cv05 +cv09 +cv14 +cv16 +cv18 +cv25 +cv26 +cv28 +cv29 +cv30 +cv31
```

These features provide:
- Better arrow symbols
- Enhanced equality operators
- Improved parentheses and brackets
- Clearer distinction between similar characters

## Why These Choices?

### FiraCode for Development
- **Ligatures**: Combines characters like `->`, `=>`, `!=` into single symbols
- **Nerd Font patch**: Adds icons and symbols for shells, file managers, status bars
- **Readability**: Designed specifically for code with clear character distinction
- **Compatibility**: Works across terminals, editors, and development tools

### Comprehensive System Coverage
- **Liberation**: Ensures compatibility with Microsoft Office documents
- **DejaVu**: Provides excellent fallback for technical and scientific symbols
- **Noto**: Google's commitment to supporting all Unicode scripts
- **Emoji support**: Modern communication and documentation needs

### Development Optimizations
- **Monospace consistency**: All development fonts maintain proper spacing
- **Symbol coverage**: Mathematical, logical, and programming symbols included
- **Ligature support**: Enhanced readability for common programming constructs
- **High DPI support**: Scalable fonts that work on modern high-resolution displays

## Usage Examples

### Terminal/Shell
- **Git status**: Enhanced with Nerd Font symbols
- **File listings**: Icons and symbols for different file types
- **Shell prompts**: Rich symbols for status, git branches, etc.

### Code Editors
- **Ligatures**: `==`, `!=`, `->`, `=>` render as single symbols
- **Comments**: Clear distinction from code
- **Strings**: Easy identification with font styling

### System UI
- **KDE Plasma**: Uses system fonts for menus and dialogs
- **Application text**: Consistent rendering across applications
- **International text**: Proper support for non-Latin scripts

## Customization

### Changing Terminal Font
Edit `home/modules/desktop.nix`:
```nix
programs.kitty = {
  font = {
    name = "JetBrains Mono Nerd Font";  # Alternative
    size = 14;                         # Larger size
  };
};
```

### Adding Fonts
Add to font packages list:
```nix
home.packages = with pkgs; [
  # Add your preferred fonts
  cascadia-code
  hack-font
  # etc.
];
```

### System-wide Fonts
Add to KIWI profile `config.kiwi.xml`:
```xml
<package>your-font-package</package>
```

## Font Resources

### Testing Fonts
- **FiraCode specimens**: [GitHub repository](https://github.com/tonsky/FiraCode)
- **Nerd Font previews**: [nerdfonts.com](https://www.nerdfonts.com/)
- **Font testing**: Use `fc-list` to see installed fonts

### Alternative Development Fonts
If FiraCode doesn't suit your preference:
- **JetBrains Mono**: Modern, designed by JetBrains
- **Source Code Pro**: Adobe's monospace font
- **Cascadia Code**: Microsoft's development font
- **Hack**: Designed specifically for code

### Troubleshooting
```bash
# List available fonts
fc-list | grep -i fira

# Test font rendering
echo "Testing FiraCode: -> => != >= <="

# Fontconfig cache refresh
fc-cache -fv
```

## Integration with Geckoforge

### Architecture Compliance
- **Layer 1 (ISO)**: Basic system fonts for installer and early boot
- **Layer 4 (Home-Manager)**: Development and user-specific fonts
- **No layer violations**: Fonts properly distributed between system and user space

### Performance Considerations
- **Nerd Font subset**: Only includes needed fonts (FiraCode, JetBrains, Source Code)
- **System fonts**: Essential coverage without bloat
- **Font caching**: Fontconfig handles caching automatically

### Development Workflow
Fonts are version-controlled and reproducible:
1. Modify font configuration in `home/modules/desktop.nix`
2. Apply with `home-manager switch --flake .`
3. Fonts available immediately in new terminal sessions
4. Changes tracked in Git for team consistency

## See Also
- [Terminal Configuration](terminal-setup.md)
- [Development Environment](development-setup.md)
- [KDE Customization](kde-theming.md)