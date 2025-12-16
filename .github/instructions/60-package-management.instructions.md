---
applyTo: "**/package.json,**/package-lock.json,**/*.nix,**/requirements*.txt,**/pyproject.toml"
---

---
description: Package management policies and verification procedures for all package sources
alwaysApply: false
version: 0.3.0
---

## Use when
- Adding packages to any layer of the system
- Verifying package availability
- Troubleshooting package installation issues
- Choosing between package sources (zypper/Nix/Flatpak)

## Package Management Matrix

### Decision Tree:
```
Need a package?
│
├─ System-level dependency (kernel, drivers, base system)?
│  → Use zypper (Layer 1: KIWI config)
│
├─ Development tool or CLI utility?
│  → Use Nix (Layer 4: Home-Manager)
│
├─ GUI application (complex, sandboxed)?
│  → Use Flatpak (Layer 4: activation script)
│
└─ Web application with good interface?
   → Use PWA (Chrome --app flag)
```

---

## zypper (openSUSE System Packages)

### When to Use:
- ✅ Kernel and drivers (NVIDIA)
- ✅ System daemons (NetworkManager, Docker)
- ✅ Desktop environment (KDE Plasma)
- ✅ Base utilities (bash, coreutils)
- ✅ Firmware updates

### Where to Specify:
**Layer 1 (KIWI)**:
```xml
<!-- profile/config.kiwi.xml -->
<packages type="image">
  <package>kernel-default</package>
  <package>plasma5-desktop</package>
  <package>docker</package>
</packages>
```

**Layer 3 (User Scripts)**:
```bash
# scripts/setup-docker.sh
sudo zypper install -y docker docker-compose
```

### Verification:
```bash
# Check if package exists
zypper search package-name

# Check installed version
zypper info package-name

# List all available packages
zypper packages

# Search with pattern
zypper search '*nvidia*'
```

### Common Mistakes:
- ❌ Using Ubuntu package names (`apt install gcc`)
- ❌ Using Fedora package names (`dnf install kernel-devel`)
- ❌ Assuming package names are universal
- ✅ Verify with `zypper search` before adding to config

---

## Nix (User Packages)

### When to Use:
- ✅ Development tools (git, make, cmake)
- ✅ Programming languages (Go, Python, Node.js)
- ✅ CLI utilities (ripgrep, fd, jq)
- ✅ Terminal emulators (kitty, alacritty)
- ✅ Text editors (vim, emacs, VS Code)
- ✅ TeX Live (REQUIRED: scheme-medium)

### Where to Specify:
**Layer 4 (Home-Manager)**:
```nix
# home/modules/development.nix
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    git
    python3
    texlive.combined.scheme-medium
  ];
}
```

### Verification:
```bash
# Search nixpkgs
nix search nixpkgs package-name

# Check available versions
nix search nixpkgs --json package-name | jq

# Verify package exists before adding
nix eval nixpkgs#package-name.version

# Check what's installed
nix profile list
```

### Package Naming:
```nix
# Common patterns
pkgs.python3          # Python 3.x (latest)
pkgs.nodejs_20        # Node.js 20.x
pkgs.gcc13            # GCC 13.x
pkgs.postgresql_16    # PostgreSQL 16.x

# Special cases
pkgs.texlive.combined.scheme-medium  # TeX Live scheme
pkgs.vscode-extensions.ms-python.python  # VS Code extensions
```

### Common Mistakes:
- ❌ `pkgs.python` (use `pkgs.python3`)
- ❌ `pkgs.node` (use `pkgs.nodejs_20`)
- ❌ `pkgs.postgres` (use `pkgs.postgresql_16`)
- ❌ `texlive.combined.scheme-full` (use `scheme-medium`)

---

## Flatpak (GUI Applications)

### When to Use:
- ✅ Complex GUI apps (Postman, DBeaver)
- ✅ Proprietary software (Discord, Slack)
- ✅ Apps needing sandboxing (Signal)
- ✅ Apps not in nixpkgs or broken Nix packages
- ✅ Apps requiring frequent updates (browsers, IDEs)

### Where to Specify:
**Layer 4 (Home-Manager activation)**:
```nix
# home/home.nix
home.activation.installFlatpaks = config.lib.dag.entryAfter ["writeBoundary"] ''
  if command -v flatpak >/dev/null 2>&1; then
    flatpak install -y --user --noninteractive flathub \
      com.getpostman.Postman \
      io.dbeaver.DBeaverCommunity \
      com.obsproject.Studio || true
  fi
'';
```

Or **Layer 3 (User Script)**:
```bash
# scripts/install-flatpaks.sh
flatpak install -y flathub \
  com.getpostman.Postman \
  io.dbeaver.DBeaverCommunity
```

### Verification:
```bash
# Search Flathub
flatpak search postman

# Check app ID
flatpak search --columns=application dbeaver

# List installed
flatpak list

# Check app details
flatpak info com.getpostman.Postman
```

### Common App IDs:
```bash
com.getpostman.Postman              # Postman
io.dbeaver.DBeaverCommunity         # DBeaver
com.google.AndroidStudio            # Android Studio
com.obsproject.Studio               # OBS Studio
org.signal.Signal                   # Signal
com.visualstudio.code               # VS Code (if not using Nix)
```

---

## PWA (Web Applications)

### When to Use:
- ✅ Web apps with good mobile support (Claude, ChatGPT)
- ✅ Services without official Linux clients (Teams)
- ✅ Apps where web version is feature-complete

### How to Create:
```bash
# Using Chromium (from Home-Manager)
chromium --app=https://claude.ai

# Desktop entry for app menu
cat > ~/.local/share/applications/claude-pwa.desktop <<EOF
[Desktop Entry]
Name=Claude
Exec=chromium --app=https://claude.ai
Type=Application
Icon=text-html
Categories=Network;Office;
EOF

update-desktop-database ~/.local/share/applications
```

---

## Package Verification Workflow

### Before Adding Any Package:

1. **Identify correct source**:
   ```bash
   # System package?
   zypper search package-name
   
   # Nix package?
   nix search nixpkgs package-name
   
   # Flatpak?
   flatpak search package-name
   ```

2. **Verify exact name**:
   ```bash
   # zypper: Check info
   zypper info package-name
   
   # Nix: Check derivation
   nix eval nixpkgs#package-name.version
   
   # Flatpak: Check app ID
   flatpak search --columns=application package-name
   ```

3. **Check dependencies**:
   ```bash
   # zypper
   zypper info --requires package-name
   
   # Nix
   nix why-depends nixpkgs#package-name nixpkgs#dep
   
   # Flatpak
   flatpak info --show-permissions package-id
   ```

4. **Test in isolation** (before committing):
   ```bash
   # zypper: Test in VM
   # Nix: Test with temporary package
   nix shell nixpkgs#package-name
   
   # Flatpak: Install user-level first
   flatpak install --user flathub app-id
   ```

---

## Package Source Priority

### Default Preference Order:
1. **zypper** - System-critical, drivers, base tools
2. **Nix** - Development tools, CLI utilities, reproducible environments
3. **Flatpak** - GUI applications, sandboxed apps
4. **PWA** - Web-first services

### Example: Installing VS Code
```bash
# Option 1: Nix (Recommended for declarative config)
# home/modules/desktop.nix
programs.vscode = {
  enable = true;
  extensions = [ /* ... */ ];
};

# Option 2: Flatpak (Good for stable GUI experience)
flatpak install flathub com.visualstudio.code

# Option 3: zypper (If Microsoft repo configured)
sudo zypper ar https://packages.microsoft.com/yumrepos/vscode vscode
sudo zypper install code

# ❌ NOT recommended: Download .deb or .rpm manually
```

---

## Repository Configuration

### openSUSE Repos (Layer 1):
```xml
<!-- config.kiwi.xml -->
<repository type="rpm-md">
  <source path="http://download.opensuse.org/distribution/leap/15.6/repo/oss/"/>
</repository>
<repository type="rpm-md">
  <source path="https://download.nvidia.com/opensuse/leap/15.6/"/>
</repository>
```

### Nix Channels (Layer 2):
```bash
# Configured in firstboot-nix.sh and home/flake.nix
nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
```

### Flatpak Remotes (Layer 3/4):
```bash
# Flathub (default)
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
```

---

## Troubleshooting

### "Package not found" (zypper)
```bash
# Update repo metadata
sudo zypper refresh

# Search with wildcards
zypper search '*package*'

# Check if it's in a disabled repo
zypper repos
zypper search --repo repo-name package
```

### "Package not found" (Nix)
```bash
# Update flake inputs
cd ~/git/home
nix flake update

# Search all attributes
nix search nixpkgs --json package-name

# Check if it's in a different attribute set
nix eval nixpkgs#python3Packages.package-name
```

### "Runtime not found" (Flatpak)
```bash
# Install required runtime
flatpak install flathub org.freedesktop.Platform//23.08

# Check runtime versions
flatpak list --runtime
```

### Version Conflicts
```bash
# zypper: Lock package to specific version
sudo zypper addlock package-name

# Nix: Pin in flake
inputs.nixpkgs.url = "github:nixos/nixpkgs/commit-hash";

# Flatpak: Pin to specific branch
flatpak install flathub//stable app-id
```

---

## Package Update Strategy

### Monthly Update Cycle:
```bash
# 1. Update system packages (zypper)
sudo zypper refresh
sudo zypper patch

# 2. Update Nix packages (Home-Manager)
cd ~/git/home
nix flake update
home-manager switch --flake .

# 3. Update Flatpaks
flatpak update

# 4. Verify critical workflows
docker run hello-world
nvidia-smi
pdflatex --version
```

### Selective Updates:
```bash
# Update specific zypper package
sudo zypper update package-name

# Update specific Nix package (modify flake.lock manually)
nix flake lock --update-input nixpkgs

# Update specific Flatpak
flatpak update app-id
```

---

## Package Removal

### Removing Packages:
```bash
# zypper
sudo zypper remove package-name
sudo zypper remove --clean-deps package-name

# Nix (remove from module, then)
home-manager switch --flake ~/git/home

# Flatpak
flatpak uninstall app-id
flatpak uninstall --unused  # Remove unused runtimes
```

### Cleanup:
```bash
# zypper
sudo zypper clean
sudo zypper packages --orphaned

# Nix
nix-collect-garbage -d
nix store gc

# Flatpak
flatpak uninstall --unused
flatpak repair
```

---

## Special Cases

### TeX Live (CRITICAL):
```nix
# ALWAYS use scheme-medium
home.packages = with pkgs; [
  texlive.combined.scheme-medium
];

# If specific package needed, add it
(texlive.combine {
  inherit (texlive) scheme-medium algorithm2e;
})
```

### NVIDIA Drivers:
```bash
# MUST be installed via zypper from NVIDIA repo
# NEVER use Nix NVIDIA drivers on openSUSE

# Correct: (Layer 2 - first-boot)
sudo zypper -n in nvidia-open-driver-G06-signed

# Wrong:
# home.packages = with pkgs; [ linuxPackages.nvidia_x11 ];
```

### Docker:
```bash
# MUST be installed via zypper
# Home-Manager/Nix Docker is for NixOS only

# Correct: (Layer 3 - user setup)
sudo zypper install docker

# Wrong:
# home.packages = with pkgs; [ docker ];
```

---

## Best Practices

### Do:
- ✅ Verify package exists before adding
- ✅ Use correct package manager for each layer
- ✅ Test packages in isolation first
- ✅ Document package choices
- ✅ Keep packages updated monthly
- ✅ Use stable releases (not latest/unstable)
- ✅ Check package size before installing

### Don't:
- ❌ Mix package managers (don't install same app via multiple sources)
- ❌ Use Ubuntu/Debian/Arch package names
- ❌ Install system packages via Nix on openSUSE
- ❌ Use Nix NVIDIA drivers
- ❌ Install Docker via Nix on openSUSE
- ❌ Use TeX scheme-full
- ❌ Install from source unless absolutely necessary

---

## Package Verification Checklist

Before committing package additions:
- [ ] Package exists in chosen source
- [ ] Package name spelled correctly
- [ ] Version available is suitable
- [ ] Dependencies understood
- [ ] Layer assignment correct
- [ ] No conflicts with existing packages
- [ ] Tested in isolation
- [ ] Documentation updated