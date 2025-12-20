# Text Expansion with espanso

Geckoforge includes **espanso**, a cross-platform text expander that works system-wide.

## What is espanso?

espanso automatically expands text shortcuts as you type. Type `:gdate` and it becomes `2025-12-20`.

Works everywhere: VS Code, terminals, browsers, chat apps, etc.

## Quick Start

espanso starts automatically when you log in. No manual setup required.

### Toggle On/Off

- **Keyboard**: Press `Alt+Shift+E` to enable/disable
- **CLI**: `espanso status` to check if running

### Search Mode

Press `Alt+Space` or type `::` to open interactive search menu for available shortcuts.

## Built-in Shortcuts

### Date & Time
- `:gdate` → `2025-12-20` (current date)
- `:gtime` → `14:30:45` (current time)
- `:gdatetime` → `2025-12-20 14:30:45` (both)

### Git Commits (Conventional Commits)
- `:gfix` → `fix: `
- `:gfeat` → `feat: `
- `:gdocs` → `docs: `
- `:grefactor` → `refactor: `
- `:gtest` → `test: `
- `:gchore` → `chore: `
- `:gstyle` → `style: `
- `:gperf` → `perf: `

### Symbols
- `:check` → ✅
- `:cross` → ❌
- `:warn` → ⚠️
- `:info` → ℹ️
- `:rocket` → 🚀
- `:bug` → 🐛
- `:fire` → 🔥
- `:sparkles` → ✨
- `:shrug` → ¯\_(ツ)_/¯

### Paths
- `:ghome` → `/home/yourusername` (your home directory)
- `:ghomedir` → `~/git/geckoforge/home` (Home-Manager config)
- `:gprofile` → `~/git/geckoforge/profile` (KIWI profile)

## Customization

### Add Your Own Shortcuts

Edit: `~/.config/espanso/match/user.yml`

Example:
```yaml
matches:
  - trigger: ":email"
    replace: "your.email@example.com"
  
  - trigger: ":sig"
    replace: |
      Best regards,
      Your Name
  
  - trigger: ":addr"
    replace: |
      123 Main Street
      City, State 12345
```

### Advanced Features

espanso supports powerful expansion features beyond simple text replacement.

#### Shell Commands

Run shell commands and insert their output:

```yaml
matches:
  - trigger: ":gitbranch"
    replace: "{{output}}"
    vars:
      - name: output
        type: shell
        params:
          cmd: "git branch --show-current"
```

Usage: Type `:gitbranch` → `main`

#### Cursor Positioning

Place the cursor at a specific position after expansion:

```yaml
matches:
  - trigger: ":func"
    replace: "function $|$() {\n  \n}"
```

Usage: Type `:func` → Cursor appears at `$|$` position

#### Forms (Interactive Input)

Prompt for input when expanding:

```yaml
matches:
  - trigger: ":greet"
    replace: "Hello {{name}}, how are you?"
    vars:
      - name: name
        type: form
        params:
          prompt: "Enter person's name:"
```

Usage: Type `:greet` → Dialog prompts for name → `Hello John, how are you?`

#### Multi-line Expansions

Create code snippets or templates:

```yaml
matches:
  - trigger: ":elixirmod"
    replace: |
      defmodule {{module}} do
        @moduledoc """
        {{doc}}
        """
        
        def hello do
          :world
        end
      end
    vars:
      - name: module
        type: form
        params:
          prompt: "Module name:"
      - name: doc
        type: form
        params:
          prompt: "Module documentation:"
          multiline: true
```

### Configuration Location

espanso configuration files are in `~/.config/espanso/`:

```
~/.config/espanso/
├── config/
│   └── default.yml       # espanso settings
└── match/
    ├── base.yml          # Default shortcuts (managed by Nix)
    └── user.yml          # Your custom shortcuts
```

**Important**: Edit `user.yml` for your own shortcuts. Don't edit `base.yml` directly - it's managed by Home-Manager and will be overwritten.

To add shortcuts permanently via Home-Manager, edit:
```bash
~/git/geckoforge/home/modules/espanso.nix
```

Then apply changes:
```bash
home-manager switch
```

## Integration Examples

### Daily Summaries

Create a shortcut for daily summary headers:

```yaml
matches:
  - trigger: ":gsum"
    replace: |
      # {{date}} — geckoforge Session Summary
      
      ## Session Overview
      **Date**: {{date}}
      **Duration**: 
      **Goals**: 
      **Status**: In Progress
      
      ## Major Accomplishments
      - 
      
      ## Key Changes
      
      ### Files Created
      
      ### Files Modified
      
      ## Next Steps
      - [ ] 
    vars:
      - name: date
        type: date
        params:
          format: "%Y-%m-%d"
```

### Git Workflow

Shortcuts for common git operations:

```yaml
matches:
  - trigger: ":gpush"
    replace: "git add . && git commit -m \"{{msg}}\" && git push"
    vars:
      - name: msg
        type: form
        params:
          prompt: "Commit message:"
  
  - trigger: ":gpr"
    replace: "feat: {{feature}}\n\n- Added: {{added}}\n- Changed: {{changed}}\n\nCloses #{{issue}}"
    vars:
      - name: feature
        type: form
        params:
          prompt: "Feature name:"
      - name: added
        type: form
        params:
          prompt: "What was added?"
      - name: changed
        type: form
        params:
          prompt: "What was changed?"
      - name: issue
        type: form
        params:
          prompt: "Issue number:"
```

### Code Snippets

Common code patterns:

```yaml
matches:
  # Docker Compose service template
  - trigger: ":dcserv"
    replace: |
      {{service}}:
        image: {{image}}
        container_name: {{name}}
        ports:
          - "{{port}}:{{port}}"
        environment:
          - KEY=value
        volumes:
          - ./data:/data
        restart: unless-stopped
    vars:
      - name: service
        type: form
        params:
          prompt: "Service name:"
      - name: image
        type: form
        params:
          prompt: "Docker image:"
      - name: name
        type: form
        params:
          prompt: "Container name:"
      - name: port
        type: form
        params:
          prompt: "Port number:"
  
  # Python function docstring
  - trigger: ":pydoc"
    replace: |
      """
      {{summary}}
      
      Args:
          {{args}}: {{argdesc}}
      
      Returns:
          {{returns}}: {{retdesc}}
      
      Raises:
          {{raises}}: {{raisedesc}}
      """
    vars:
      - name: summary
        type: form
        params:
          prompt: "Function summary:"
      - name: args
        type: form
        params:
          prompt: "Argument name:"
      - name: argdesc
        type: form
        params:
          prompt: "Argument description:"
      - name: returns
        type: form
        params:
          prompt: "Return type:"
      - name: retdesc
        type: form
        params:
          prompt: "Return description:"
      - name: raises
        type: form
        params:
          prompt: "Exception type:"
      - name: raisedesc
        type: form
        params:
          prompt: "Exception description:"
```

## Troubleshooting

### espanso not working

Check if the daemon is running:

```bash
# Check status
espanso status

# Restart service
systemctl --user restart espanso

# View logs
journalctl --user -u espanso -f
```

### Shortcuts not expanding

1. **Check if espanso is enabled**: Press `Alt+Shift+E` to toggle
2. **Check trigger syntax**: Ensure trigger starts with `:` and matches your config
3. **Reload config**: `espanso restart`
4. **Check logs**: `journalctl --user -u espanso -f`

### Conflicts with application shortcuts

If espanso shortcuts conflict with application-specific shortcuts:

1. **Temporarily disable**: Press `Alt+Shift+E`
2. **Use different triggers**: Edit `~/.config/espanso/match/user.yml` to change trigger prefixes
3. **Application-specific config**: Create app-specific match files

Example app-specific config (`~/.config/espanso/match/vscode.yml`):

```yaml
filter_title: "Visual Studio Code"

matches:
  - trigger: ":vsdebug"
    replace: "// TODO: Debug this"
```

### Performance issues

If espanso causes typing lag:

1. **Check CPU usage**: `top` or `htop`
2. **Reduce match files**: Fewer shortcuts = faster matching
3. **Disable unused features**: Edit `~/.config/espanso/config/default.yml`

```yaml
# Disable clipboard integration if not needed
preserve_clipboard: false

# Increase debounce delay (milliseconds)
key_delay: 200
```

### X11 vs Wayland

espanso works on both X11 and Wayland, but some features differ:

**X11**: Full feature support  
**Wayland**: Limited clipboard access, may require additional permissions

To force a specific backend:

```yaml
# In ~/.config/espanso/config/default.yml
backend: X11  # or Wayland, Clipboard
```

## Applying Changes

### After editing espanso config files

```bash
# Reload configuration
espanso restart

# Or manually restart service
systemctl --user restart espanso
```

### After editing Home-Manager module

If you modified `home/modules/espanso.nix`:

```bash
cd ~/git/geckoforge
home-manager switch
```

This regenerates the base config and restarts the systemd service.

## Uninstall

To remove espanso:

1. Edit `home/home.nix` and remove the import:
   ```nix
   # Remove this line:
   ./modules/espanso.nix
   ```

2. Apply changes:
   ```bash
   home-manager switch
   ```

3. Stop and disable service:
   ```bash
   systemctl --user stop espanso
   systemctl --user disable espanso
   ```

4. Remove config (optional):
   ```bash
   rm -rf ~/.config/espanso
   ```

## Further Reading

- **Official Documentation**: https://espanso.org/docs/
- **Hub (Community Packages)**: https://hub.espanso.org/
- **GitHub Repository**: https://github.com/espanso/espanso
- **Examples**: https://espanso.org/docs/matches/

## See Also

- [Shell Configuration](shell.nix) - Zsh aliases and shortcuts
- [VS Code Configuration](vscode-migration.md) - Code snippets
- [macOS Keyboard](keyboard-configuration.md) - System-wide keyboard shortcuts
