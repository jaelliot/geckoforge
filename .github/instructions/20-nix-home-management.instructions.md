---
applyTo: "home/**,**/*.nix"
---

---
description: Nix and Home-Manager patterns, module organization, and package management
alwaysApply: false
version: 0.3.0
---

## Use when
- Creating or modifying Home-Manager modules
- Adding packages to the user environment
- Configuring applications via Home-Manager
- Setting up programming language environments
- Managing the Nix flake or Home-Manager activation

## Nix Installation (Layer 2: First-Boot)

### Multi-User Installation (REQUIRED)
The system installs Nix once at first boot via `geckoforge-nix.service`:

```bash
# profiles/.../scripts/firstboot-nix.sh
sh <(curl -L https://nixos.org/nix/install) --daemon
echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf
systemctl restart nix-daemon
```

**Key points:**
- ✅ Daemon mode (multi-user)
- ✅ Flakes enabled
- ✅ System-level installation (all users can access)
- ✅ Automatic on first boot
- ❌ Do NOT reinstall in user scripts
- ❌ Do NOT use single-user mode

---

## Home-Manager Structure

### Directory Layout (REQUIRED)
```
home/
├── flake.nix                    # Nix flake definition
├── home.nix                     # Main configuration entrypoint
└── modules/                     # Modular configurations
    ├── cli.nix                  # CLI tools and shell config
    ├── desktop.nix              # Desktop apps (Chromium, Kitty)
    ├── development.nix          # Dev tools, languages, TeX
    ├── elixir.nix               # Elixir/Erlang via asdf
    └── firefox.nix              # Firefox config and extensions
```

### Module Organization Rules
- **One domain per file**: Don't mix desktop and development configs
- **Import in home.nix**: All modules must be imported in the main config
- **Self-contained**: Each module should work independently
- **Documented**: Include comments explaining package choices

---

## Flake Configuration

### flake.nix Pattern (REQUIRED)
```nix
{
  description = "Jay's Home Manager configuration for geckoforge";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;  # For Chrome, VS Code, etc.
      };
    in {
      homeConfigurations.jay = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./home.nix ];
      };
    };
}
```

**Key elements:**
- ✅ Pin to stable nixpkgs (24.05)
- ✅ Allow unfree packages explicitly
- ✅ Single homeConfiguration per user
- ✅ Import main module from ./home.nix

---

## home.nix Pattern (REQUIRED)

```nix
{ config, pkgs, ... }:

{
  imports = [
    ./modules/development.nix
    ./modules/desktop.nix
    ./modules/cli.nix
    ./modules/elixir.nix
    ./modules/firefox.nix
  ];

  home.username = "jay";
  home.homeDirectory = "/home/jay";
  home.stateVersion = "24.05";

  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    userName = "Jay";
    userEmail = "jay@example.com";
  };

  # Flatpak installation via activation script
  home.activation.installFlatpaks = config.lib.dag.entryAfter ["writeBoundary"] ''
    if command -v flatpak >/dev/null 2>&1; then
      flatpak install -y --user --noninteractive flathub \
        com.getpostman.Postman \
        io.dbeaver.DBeaverCommunity || true
    fi
  '';
}
```

**Key patterns:**
- ✅ Import all modules
- ✅ Set stateVersion (never change after initial setup)
- ✅ Enable home-manager self-management
- ✅ Configure programs declaratively
- ✅ Use activation scripts for Flatpaks (they lack Nix packages)

---

## Module Patterns

### CLI Module (cli.nix)
```nix
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Search tools
    ripgrep fd fzf
    
    # File tools
    bat eza tree
    
    # System tools
    htop btop ncdu
    
    # Network tools
    wget curl
    
    # Data tools
    jq yq
  ];

  programs.bash = {
    enable = true;
    shellAliases = {
      ls = "eza";
      cat = "bat";
      grep = "rg";
    };
  };
}
```

### Development Module (development.nix)
```nix
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Version control
    git lazygit
    
    # Build tools
    gnumake cmake
    
    # Languages
    go
    python3
    nodejs_20
    
    # TeX Live (REQUIRED: scheme-medium)
    texlive.combined.scheme-medium
  ];
}
```

**CRITICAL**: TeX Live MUST use `scheme-medium`, NOT `scheme-full`

### Desktop Module (desktop.nix)
```nix
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    kitty  # Terminal emulator
  ];

  programs.chromium = {
    enable = true;
    extensions = [
      { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; }  # uBlock Origin
      { id = "nngceckbapebfimnlniiiahkandclblb"; }  # Bitwarden
    ];
    commandLineArgs = [
      "--enable-features=VaapiVideoDecoder"
      "--disable-features=UseChromeOSDirectVideoDecoder"
    ];
  };
}
```

### Elixir Module (elixir.nix)
```nix
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # asdf version manager
    asdf-vm
    
    # Elixir build dependencies
    autoconf automake openssl readline
    ncurses zlib libyaml libxslt libtool
    unixODBC wxGTK32 libxml2 fop
  ];

  programs.bash.initExtra = ''
    # asdf setup
    . ${pkgs.asdf-vm}/share/asdf-vm/asdf.sh
    . ${pkgs.asdf-vm}/share/asdf-vm/completions/asdf.bash
    
    # Erlang/Elixir versions
    export KERL_BUILD_DOCS=yes
    export KERL_INSTALL_HTMLDOCS=no
  '';

  # Post-installation: User runs manually
  # asdf plugin add erlang
  # asdf plugin add elixir
  # asdf install erlang 28.1
  # asdf install elixir 1.18.4-otp-28
  # asdf global erlang 28.1
  # asdf global elixir 1.18.4-otp-28
}
```

### Firefox Module (firefox.nix)
```nix
{ config, pkgs, ... }:

{
  programs.firefox = {
    enable = true;
    profiles.default = {
      id = 0;
      name = "default";
      isDefault = true;
      
      search.default = "Google";
      
      settings = {
        "browser.newtabpage.enabled" = true;
        "privacy.trackingprotection.enabled" = true;
        "dom.security.https_only_mode" = true;
      };
    };
  };
}
```

---

## Package Selection Guidelines

### When to use Nix:
- ✅ CLI tools and utilities
- ✅ Development toolchains
- ✅ Terminal emulators
- ✅ Text editors (vim, emacs, VS Code)
- ✅ Programming languages (Go, Python, Node.js)
- ✅ Build tools (make, cmake, gcc)

### When to use Flatpak (via activation script):
- ✅ GUI applications with complex dependencies
- ✅ Proprietary software (Postman, DBeaver)
- ✅ Applications needing sandboxing (Signal, Discord)
- ✅ Apps not in nixpkgs or with broken Nix packages

### When to use zypper (System Layer 1):
- ✅ Kernel and drivers
- ✅ System daemons (NetworkManager, systemd)
- ✅ Desktop environment (KDE Plasma)
- ✅ Fundamental system utilities

### When to use PWA:
- ✅ Web apps with good mobile support (Claude, Teams)
- ✅ Services without official Linux clients
- ✅ Apps where web version is best experience

---

## Common Patterns

### Installing a Package
```bash
# 1. Add to appropriate module
$EDITOR home/modules/development.nix

# 2. Apply changes
home-manager switch --flake ~/git/home

# 3. Verify installation
which your-package
```

### Creating a New Module
```bash
# 1. Create module file
cat > home/modules/your-module.nix <<'EOF'
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    your-package
  ];
}
EOF

# 2. Import in home.nix
$EDITOR home/home.nix  # Add ./modules/your-module.nix to imports

# 3. Apply
home-manager switch --flake ~/git/home
```

### Updating Packages
```bash
cd ~/git/home
nix flake update
home-manager switch --flake .
```

### Rolling Back
```bash
# List generations
home-manager generations

# Rollback to previous
home-manager rollback

# Rollback to specific generation
home-manager switch --flake ~/git/home#<generation>
```

---

## TeX Live Configuration (CRITICAL)

### REQUIRED Configuration:
```nix
# home/modules/development.nix
{
  home.packages = with pkgs; [
    texlive.combined.scheme-medium
  ];
}
```

### Why scheme-medium:
- ✅ 2GB size (vs 5GB for scheme-full)
- ✅ Stable on openSUSE Leap
- ✅ Includes essential packages
- ✅ User's explicit requirement
- ✅ Sufficient for most documents

### Testing TeX Installation:
```bash
# After home-manager switch
cat > test.tex <<'EOF'
\documentclass{article}
\usepackage{amsmath}
\begin{document}
Hello, \LaTeX!
$E = mc^2$
\end{document}
EOF

pdflatex test.tex
# Should produce test.pdf
```

---

## Activation Scripts

Use for tasks that don't fit Nix's declarative model:

```nix
home.activation.yourTask = config.lib.dag.entryAfter ["writeBoundary"] ''
  if command -v some-tool >/dev/null 2>&1; then
    # Your imperative task here
    some-tool setup || true  # Don't fail on errors
  fi
'';
```

**Common uses:**
- Installing Flatpaks
- Running external installers (asdf plugins)
- Creating directories
- Symlinking files outside $HOME

---

## Troubleshooting

### "Package not found"
Check if package exists:
```bash
nix search nixpkgs your-package
```

### "Unfree package"
Add to flake.nix:
```nix
config.allowUnfree = true;
```

Or per-package in module:
```nix
nixpkgs.config.allowUnfree = true;
```

### "Collision between X and Y"
Use `home.packages` for most packages, `programs.X.enable` for configured programs:
```nix
# BAD (collision)
home.packages = [ pkgs.git ];
programs.git.enable = true;

# GOOD (choose one)
programs.git.enable = true;  # Preferred for configured programs
```

### "home-manager not found"
Source Nix profile:
```bash
source ~/.nix-profile/etc/profile.d/nix.sh
```

Or log out and back in.

---

## Performance Considerations

### Reduce Build Times:
- Use binary caches (enabled by default for nixpkgs)
- Avoid building from source when possible
- Pin to stable releases (not unstable/master)

### Disk Space Management:
```bash
# Remove old generations
nix-collect-garbage -d

# List generations
home-manager generations

# Remove specific generation
nix-env --delete-generations 1 2 3
```

---

## Best Practices

### Do:
- ✅ Pin nixpkgs to stable release (24.05)
- ✅ Import modules in home.nix
- ✅ Use programs.X for configured apps
- ✅ Document package choices with comments
- ✅ Test changes before committing
- ✅ Use scheme-medium for TeX Live
- ✅ Keep modules focused and self-contained

### Don't:
- ❌ Use unstable nixpkgs without good reason
- ❌ Mix home.packages and programs.X for same tool
- ❌ Install system packages via Home-Manager
- ❌ Use scheme-full for TeX Live
- ❌ Scatter configuration across multiple files
- ❌ Commit flake.lock without testing
- ❌ Install Nix via user scripts (already done at first-boot)

---

## Examples

### Adding VS Code with extensions:
```nix
{ pkgs, ... }:

{
  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      ms-python.python
      ms-vscode.cpptools
      golang.go
    ];
  };
}
```

### Adding shell configuration:
```nix
programs.bash = {
  enable = true;
  shellAliases = {
    ll = "ls -lah";
    ".." = "cd ..";
  };
  initExtra = ''
    export EDITOR=vim
    export PATH="$HOME/.local/bin:$PATH"
  '';
};
```

### Adding Git configuration:
```nix
programs.git = {
  enable = true;
  userName = "Your Name";
  userEmail = "you@example.com";
  extraConfig = {
    init.defaultBranch = "main";
    pull.rebase = true;
  };
};
```