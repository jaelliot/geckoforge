---
applyTo: "scripts/*ide*.sh,home/modules/*ide*.nix"
---

---
description: IDE configuration backup and sync for VS Code, Cursor, Kiro, and Void
globs: ["scripts/*ide*.sh", "home/modules/*ide*.nix"]
alwaysApply: false
version: 0.3.0
---

## Use when
- Setting up IDEs on fresh installation
- Backing up IDE configurations
- Syncing settings across devices
- Managing IDE extensions

## IDE Priority

**Primary**: VS Code, Cursor  
**Secondary**: Kiro (AWS), Void (Ollama)

---

## VS Code Configuration

### Installation (Layer 4: Home-Manager)

```nix
# home/modules/ide.nix
{ pkgs, ... }:

{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    
    extensions = with pkgs.vscode-extensions; [
      # Essential
      ms-vscode.cpptools
      ms-python.python
      golang.go
      rust-lang.rust-analyzer
      
      # TypeScript/JavaScript
      bradlc.vscode-tailwindcss
      esbenp.prettier-vscode
      
      # Nix
      bbenoist.nix
      
      # Git
      eamodio.gitlens
      
      # Docker
      ms-azuretools.vscode-docker
      
      # Markdown
      yzhang.markdown-all-in-one
    ];
    
    userSettings = {
      "editor.fontSize" = 14;
      "editor.fontFamily" = "'Fira Code', 'Droid Sans Mono', monospace";
      "editor.fontLigatures" = true;
      "editor.tabSize" = 2;
      "editor.insertSpaces" = true;
      "editor.rulers" = [ 80 120 ];
      "editor.minimap.enabled" = false;
      "editor.formatOnSave" = true;
      
      "workbench.colorTheme" = "Default Dark+";
      "workbench.iconTheme" = "vscode-icons";
      
      "terminal.integrated.fontSize" = 13;
      "terminal.integrated.shell.linux" = "${pkgs.bash}/bin/bash";
      
      "files.autoSave" = "afterDelay";
      "files.autoSaveDelay" = 1000;
      
      "git.enableSmartCommit" = true;
      "git.confirmSync" = false;
      
      "nix.enableLanguageServer" = true;
      "nix.serverPath" = "${pkgs.nil}/bin/nil";
    };
  };
}
```

### Settings Backup Location

```bash
~/.config/Code/User/settings.json  # User settings
~/.config/Code/User/keybindings.json  # Keybindings
~/.config/Code/User/snippets/  # Custom snippets
```

### Extension List Backup

```bash
# scripts/backup-vscode-extensions.sh
#!/usr/bin/env bash
set -euo pipefail

OUTPUT="$HOME/git/geckoforge/config/vscode-extensions.txt"

echo "[vscode] Backing up extension list..."

code --list-extensions > "$OUTPUT"

echo "[vscode] Extensions saved to $OUTPUT"
echo "Total: $(wc -l < "$OUTPUT") extensions"
```

### Extension Restore

```bash
# scripts/restore-vscode-extensions.sh
#!/usr/bin/env bash
set -euo pipefail

INPUT="$HOME/git/geckoforge/config/vscode-extensions.txt"

if [ ! -f "$INPUT" ]; then
    echo "[vscode] Extension list not found at $INPUT"
    exit 1
fi

echo "[vscode] Restoring extensions from $INPUT..."

while read -r extension; do
    echo "Installing $extension..."
    code --install-extension "$extension" --force
done < "$INPUT"

echo "[vscode] Extensions restored"
```

---

## Cursor Configuration

### Installation (Manual or via download)

```bash
# Cursor is VS Code fork, install manually
# Download from: https://cursor.sh/

# Or via Flatpak (if available)
flatpak install flathub com.cursor.Cursor
```

### Settings Location

```bash
~/.cursor/  # All Cursor config
~/.cursor/settings.json
~/.cursor/keybindings.json
```

### Sync with VS Code

```bash
# scripts/sync-cursor-from-vscode.sh
#!/usr/bin/env bash
set -euo pipefail

VSCODE_CONFIG="$HOME/.config/Code/User"
CURSOR_CONFIG="$HOME/.cursor"

echo "[cursor] Syncing configuration from VS Code..."

# Create Cursor config directory
mkdir -p "$CURSOR_CONFIG"

# Copy settings
if [ -f "$VSCODE_CONFIG/settings.json" ]; then
    cp "$VSCODE_CONFIG/settings.json" "$CURSOR_CONFIG/settings.json"
    echo "✅ Settings synced"
fi

# Copy keybindings
if [ -f "$VSCODE_CONFIG/keybindings.json" ]; then
    cp "$VSCODE_CONFIG/keybindings.json" "$CURSOR_CONFIG/keybindings.json"
    echo "✅ Keybindings synced"
fi

# Copy snippets
if [ -d "$VSCODE_CONFIG/snippets" ]; then
    cp -r "$VSCODE_CONFIG/snippets" "$CURSOR_CONFIG/"
    echo "✅ Snippets synced"
fi

echo "[cursor] Sync complete"
```

### Extension Sync for Cursor

```bash
# scripts/sync-cursor-extensions.sh
#!/usr/bin/env bash
set -euo pipefail

EXTENSION_LIST="$HOME/git/geckoforge/config/vscode-extensions.txt"

if [ ! -f "$EXTENSION_LIST" ]; then
    echo "[cursor] Creating extension list from VS Code..."
    code --list-extensions > "$EXTENSION_LIST"
fi

echo "[cursor] Installing extensions in Cursor..."

while read -r extension; do
    echo "Installing $extension in Cursor..."
    cursor --install-extension "$extension" --force
done < "$EXTENSION_LIST"

echo "[cursor] Extension sync complete"
```

---

## Kiro (AWS IDE) Configuration

### Installation

```bash
# Download from AWS (manual installation)
# https://aws.amazon.com/kiro/

# Or via AppImage
wget https://releases.kiro.aws/kiro-latest.AppImage
chmod +x kiro-latest.AppImage
sudo mv kiro-latest.AppImage /usr/local/bin/kiro
```

### Configuration Backup

```bash
# scripts/backup-kiro-config.sh
#!/usr/bin/env bash
set -euo pipefail

KIRO_CONFIG="$HOME/.config/kiro"
BACKUP_DIR="$HOME/git/geckoforge/config/kiro"

echo "[kiro] Backing up configuration..."

if [ -d "$KIRO_CONFIG" ]; then
    mkdir -p "$BACKUP_DIR"
    rsync -av "$KIRO_CONFIG/" "$BACKUP_DIR/"
    echo "✅ Kiro config backed up to $BACKUP_DIR"
else
    echo "❌ Kiro config directory not found"
fi
```

### AWS Integration Settings

```json
// config/kiro/settings.json
{
  "aws.profile": "default",
  "aws.region": "us-west-2",
  "kiro.autoConnect": true,
  "kiro.syncSettings": true,
  "editor.fontSize": 14,
  "editor.fontFamily": "Fira Code",
  "terminal.integrated.shell.linux": "/bin/bash"
}
```

---

## Void (Ollama IDE) Configuration

### Installation via Home-Manager

```nix
# home/modules/ide.nix (add to existing config)
{
  home.packages = with pkgs; [
    # Ollama for local AI
    ollama
  ];
  
  # Void IDE (if available in nixpkgs)
  # Otherwise manual installation required
}
```

### Ollama Setup

```bash
# scripts/setup-ollama.sh
#!/usr/bin/env bash
set -euo pipefail

echo "[ollama] Setting up Ollama for Void IDE..."

# Start Ollama service
systemctl --user enable --now ollama

# Pull required models
ollama pull codellama:7b
ollama pull codellama:13b

# Test Ollama
ollama list

echo "[ollama] Setup complete"
echo "Models available:"
ollama list
```

### Void Configuration

```bash
# scripts/backup-void-config.sh
#!/usr/bin/env bash
set -euo pipefail

VOID_CONFIG="$HOME/.config/void"
BACKUP_DIR="$HOME/git/geckoforge/config/void"

echo "[void] Backing up configuration..."

if [ -d "$VOID_CONFIG" ]; then
    mkdir -p "$BACKUP_DIR"
    rsync -av "$VOID_CONFIG/" "$BACKUP_DIR/"
    echo "✅ Void config backed up to $BACKUP_DIR"
else
    echo "❌ Void config directory not found"
fi
```

---

## Unified IDE Management

### Master Backup Script

```bash
# scripts/backup-all-ides.sh
#!/usr/bin/env bash
set -euo pipefail

BACKUP_BASE="$HOME/git/geckoforge/config"
DATE=$(date +%Y-%m-%d)

echo "[ide] Starting comprehensive IDE backup..."

# Create backup directory
mkdir -p "$BACKUP_BASE"

# VS Code
echo "[ide] Backing up VS Code..."
if command -v code >/dev/null 2>&1; then
    code --list-extensions > "$BACKUP_BASE/vscode-extensions-$DATE.txt"
    
    if [ -d "$HOME/.config/Code/User" ]; then
        mkdir -p "$BACKUP_BASE/vscode"
        cp "$HOME/.config/Code/User/settings.json" "$BACKUP_BASE/vscode/" 2>/dev/null || true
        cp "$HOME/.config/Code/User/keybindings.json" "$BACKUP_BASE/vscode/" 2>/dev/null || true
        cp -r "$HOME/.config/Code/User/snippets" "$BACKUP_BASE/vscode/" 2>/dev/null || true
    fi
    echo "✅ VS Code backed up"
else
    echo "⚠️  VS Code not found"
fi

# Cursor
echo "[ide] Backing up Cursor..."
if command -v cursor >/dev/null 2>&1; then
    cursor --list-extensions > "$BACKUP_BASE/cursor-extensions-$DATE.txt" 2>/dev/null || true
    
    if [ -d "$HOME/.cursor" ]; then
        mkdir -p "$BACKUP_BASE/cursor"
        cp "$HOME/.cursor/settings.json" "$BACKUP_BASE/cursor/" 2>/dev/null || true
        cp "$HOME/.cursor/keybindings.json" "$BACKUP_BASE/cursor/" 2>/dev/null || true
    fi
    echo "✅ Cursor backed up"
else
    echo "⚠️  Cursor not found"
fi

# Kiro
echo "[ide] Backing up Kiro..."
if [ -d "$HOME/.config/kiro" ]; then
    mkdir -p "$BACKUP_BASE/kiro"
    rsync -av "$HOME/.config/kiro/" "$BACKUP_BASE/kiro/"
    echo "✅ Kiro backed up"
else
    echo "⚠️  Kiro config not found"
fi

# Void
echo "[ide] Backing up Void..."
if [ -d "$HOME/.config/void" ]; then
    mkdir -p "$BACKUP_BASE/void"
    rsync -av "$HOME/.config/void/" "$BACKUP_BASE/void/"
    echo "✅ Void backed up"
else
    echo "⚠️  Void config not found"
fi

# Git commit changes
cd "$HOME/git/geckoforge"
git add config/
if git diff --staged --quiet; then
    echo "[ide] No changes to commit"
else
    git commit -m "config: backup IDE configurations ($DATE)"
    echo "✅ Changes committed to git"
fi

echo "[ide] Backup complete!"
```

### Master Restore Script

```bash
# scripts/restore-all-ides.sh
#!/usr/bin/env bash
set -euo pipefail

BACKUP_BASE="$HOME/git/geckoforge/config"

echo "[ide] Starting comprehensive IDE restore..."

# VS Code
echo "[ide] Restoring VS Code..."
if [ -f "$BACKUP_BASE/vscode/settings.json" ]; then
    mkdir -p "$HOME/.config/Code/User"
    cp "$BACKUP_BASE/vscode/settings.json" "$HOME/.config/Code/User/"
    cp "$BACKUP_BASE/vscode/keybindings.json" "$HOME/.config/Code/User/" 2>/dev/null || true
    cp -r "$BACKUP_BASE/vscode/snippets" "$HOME/.config/Code/User/" 2>/dev/null || true
    echo "✅ VS Code settings restored"
fi

if [ -f "$BACKUP_BASE/vscode-extensions.txt" ]; then
    while read -r extension; do
        code --install-extension "$extension" --force
    done < "$BACKUP_BASE/vscode-extensions.txt"
    echo "✅ VS Code extensions restored"
fi

# Cursor
echo "[ide] Restoring Cursor..."
if [ -f "$BACKUP_BASE/cursor/settings.json" ]; then
    mkdir -p "$HOME/.cursor"
    cp "$BACKUP_BASE/cursor/settings.json" "$HOME/.cursor/"
    cp "$BACKUP_BASE/cursor/keybindings.json" "$HOME/.cursor/" 2>/dev/null || true
    echo "✅ Cursor settings restored"
fi

if [ -f "$BACKUP_BASE/cursor-extensions.txt" ]; then
    while read -r extension; do
        cursor --install-extension "$extension" --force 2>/dev/null || true
    done < "$BACKUP_BASE/cursor-extensions.txt"
    echo "✅ Cursor extensions restored"
fi

# Kiro
echo "[ide] Restoring Kiro..."
if [ -d "$BACKUP_BASE/kiro" ]; then
    mkdir -p "$HOME/.config/kiro"
    rsync -av "$BACKUP_BASE/kiro/" "$HOME/.config/kiro/"
    echo "✅ Kiro restored"
fi

# Void
echo "[ide] Restoring Void..."
if [ -d "$BACKUP_BASE/void" ]; then
    mkdir -p "$HOME/.config/void"
    rsync -av "$BACKUP_BASE/void/" "$HOME/.config/void/"
    echo "✅ Void restored"
fi

echo "[ide] Restore complete!"
```

---

## Extension Management

### Essential Extensions List

```bash
# config/essential-extensions.txt
ms-vscode.cpptools
ms-python.python
golang.go
rust-lang.rust-analyzer
bbenoist.nix
esbenp.prettier-vscode
bradlc.vscode-tailwindcss
eamodio.gitlens
ms-azuretools.vscode-docker
yzhang.markdown-all-in-one
ms-vscode.vscode-typescript-next
hashicorp.terraform
redhat.vscode-yaml
ms-kubernetes-tools.vscode-kubernetes-tools
```

### Extension Categories

```bash
# config/extension-categories/
├── development.txt     # Core dev tools
├── languages.txt       # Language support
├── productivity.txt    # Productivity tools
├── themes.txt         # Themes and icons
└── optional.txt       # Nice-to-have extensions
```

### Bulk Extension Management

```bash
# scripts/manage-extensions.sh
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/git/geckoforge/config"

case "${1:-help}" in
    backup)
        echo "[ext] Backing up all extensions..."
        code --list-extensions > "$CONFIG_DIR/all-extensions.txt"
        echo "Extensions saved to $CONFIG_DIR/all-extensions.txt"
        ;;
    
    restore)
        echo "[ext] Restoring all extensions..."
        if [ -f "$CONFIG_DIR/all-extensions.txt" ]; then
            while read -r ext; do
                code --install-extension "$ext" --force
            done < "$CONFIG_DIR/all-extensions.txt"
        fi
        ;;
    
    essential)
        echo "[ext] Installing essential extensions only..."
        if [ -f "$CONFIG_DIR/essential-extensions.txt" ]; then
            while read -r ext; do
                code --install-extension "$ext" --force
            done < "$CONFIG_DIR/essential-extensions.txt"
        fi
        ;;
    
    list)
        echo "[ext] Currently installed extensions:"
        code --list-extensions | sort
        ;;
    
    clean)
        echo "[ext] Removing all extensions..."
        code --list-extensions | while read -r ext; do
            code --uninstall-extension "$ext"
        done
        ;;
    
    *)
        echo "Usage: $0 {backup|restore|essential|list|clean}"
        echo ""
        echo "Commands:"
        echo "  backup    - Backup current extension list"
        echo "  restore   - Restore all extensions from backup"
        echo "  essential - Install only essential extensions"
        echo "  list      - List currently installed extensions"
        echo "  clean     - Remove all extensions"
        ;;
esac
```

---

## Automation and Monitoring

### Daily IDE Health Check

```bash
# scripts/ide-health-check.sh
#!/usr/bin/env bash
set -euo pipefail

echo "[ide] IDE Health Check - $(date)"
echo "================================"

# Check VS Code
if command -v code >/dev/null 2>&1; then
    echo "✅ VS Code: $(code --version | head -1)"
    echo "   Extensions: $(code --list-extensions | wc -l)"
else
    echo "❌ VS Code: Not installed"
fi

# Check Cursor
if command -v cursor >/dev/null 2>&1; then
    echo "✅ Cursor: Available"
else
    echo "❌ Cursor: Not installed"
fi

# Check Kiro
if [ -x /usr/local/bin/kiro ]; then
    echo "✅ Kiro: Available"
else
    echo "❌ Kiro: Not installed"
fi

# Check Void
if command -v void >/dev/null 2>&1; then
    echo "✅ Void: Available"
else
    echo "❌ Void: Not installed"
fi

# Check Ollama (for Void)
if command -v ollama >/dev/null 2>&1; then
    echo "✅ Ollama: $(ollama --version 2>/dev/null || echo 'Available')"
    echo "   Models: $(ollama list 2>/dev/null | tail -n +2 | wc -l || echo '0')"
else
    echo "❌ Ollama: Not installed"
fi

# Check config backup freshness
CONFIG_DIR="$HOME/git/geckoforge/config"
if [ -f "$CONFIG_DIR/vscode-extensions.txt" ]; then
    BACKUP_AGE=$(find "$CONFIG_DIR" -name "vscode-extensions*.txt" -mtime -7 | wc -l)
    if [ "$BACKUP_AGE" -gt 0 ]; then
        echo "✅ Config backups: Recent (within 7 days)"
    else
        echo "⚠️  Config backups: Outdated (>7 days)"
    fi
else
    echo "❌ Config backups: Not found"
fi

echo "================================"
```

### Weekly Backup Automation

```bash
# Add to crontab with: crontab -e
# 0 9 * * 1 /home/jay/git/geckoforge/scripts/backup-all-ides.sh >/tmp/ide-backup.log 2>&1

# Or use systemd timer
# ~/.config/systemd/user/ide-backup.timer
[Unit]
Description=Weekly IDE configuration backup
Requires=ide-backup.service

[Timer]
OnCalendar=weekly
Persistent=true

[Install]
WantedBy=timers.target
```

---

## Best Practices

### Configuration Management
- ✅ Keep settings in version control
- ✅ Use relative paths when possible
- ✅ Document custom keybindings
- ✅ Export extension lists regularly

### Cross-IDE Consistency
- ✅ Use same font family across IDEs
- ✅ Standardize indentation settings
- ✅ Keep similar color schemes
- ✅ Sync essential extensions

### Backup Strategy
- ✅ Daily: Automatic git commits for config changes
- ✅ Weekly: Full extension and settings backup
- ✅ Monthly: Verify restore procedures
- ✅ Before major updates: Create backup snapshots

### Performance Optimization
- ✅ Disable unnecessary extensions
- ✅ Configure reasonable memory limits
- ✅ Use workspace-specific settings
- ✅ Monitor resource usage

## Implementation Checklist

### Phase 1: Basic Setup
- [ ] Install primary IDEs (VS Code, Cursor)
- [ ] Configure basic settings and themes
- [ ] Install essential extensions
- [ ] Test basic functionality

### Phase 2: Configuration Management
- [ ] Create backup scripts
- [ ] Set up git tracking for configs
- [ ] Test restore procedures
- [ ] Document custom settings

### Phase 3: Advanced Integration
- [ ] Set up Kiro for AWS development
- [ ] Configure Void with Ollama
- [ ] Create unified management scripts
- [ ] Implement automated backups

### Phase 4: Automation
- [ ] Schedule weekly backups
- [ ] Set up health monitoring
- [ ] Create restore automation
- [ ] Document troubleshooting procedures