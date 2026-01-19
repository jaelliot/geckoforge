{
  description = "Python development environment with KERI support";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        # System dependencies (C libraries, build tools, Python)
        systemDeps = with pkgs; [
          # Python 3.14.2 - latest stable
          python314
          python314Packages.pip
          python314Packages.virtualenv
          
          # Cryptographic libraries (required for KERI)
          libsodium       # Ed25519, X25519 cryptography
          blake3          # Fast cryptographic hashing
          
          # Build tools (required for compiling Python packages with C extensions)
          gcc
          gnumake
          pkg-config
          
          # Optional: Database tools (KERI uses LMDB internally)
          lmdb
        ];
      in
      {
        devShells.default = pkgs.mkShell {
          packages = systemDeps;
          
          # Set library paths so Python packages can find system libraries
          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
            pkgs.libsodium
            pkgs.blake3
            pkgs.lmdb
          ];
          
          # Environment setup on shell activation
          shellHook = ''
            # Display banner
            echo "╔═══════════════════════════════════════════╗"
            echo "║   Python Development Environment          ║"
            echo "╚═══════════════════════════════════════════╝"
            echo ""
            
            # Create virtual environment if it doesn't exist
            if [ ! -d .venv ]; then
              echo "→ Creating virtual environment..."
              python -m venv .venv
              echo "✓ Virtual environment created"
            fi
            
            # Activate virtual environment
            source .venv/bin/activate
            
            # Upgrade pip silently
            pip install --upgrade pip > /dev/null 2>&1
            
            # Install/update Python packages from requirements.txt
            if [ -f requirements.txt ]; then
              echo "→ Installing Python packages..."
              pip install -r requirements.txt
              echo "✓ Packages installed"
            fi
            
            echo ""
            echo "Environment ready!"
            echo "  Python: $(python --version)"
            echo "  Location: $(which python)"
            echo "  libsodium: $(pkg-config --modversion libsodium 2>/dev/null || echo 'system')"
            echo ""
            echo "Available commands:"
            echo "  pytest          - Run tests"
            echo "  mypy .          - Type check code"
            echo "  pip list        - Show installed packages"
            echo ""
          '';
        };
      }
    );
}
