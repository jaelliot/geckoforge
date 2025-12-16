#!/usr/bin/env bash
# Build geckoforge complete VM with Packer

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$SCRIPT_DIR"

echo "═══════════════════════════════════════════════════════════"
echo "  Building geckoforge Complete VM Image"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "This will:"
echo "  1. Download NET ISO (~180MB)"
echo "  2. Install minimal openSUSE Leap 15.6 + KDE"
echo "  3. Install VirtualBox Guest Additions"
echo "  4. Bake in geckoforge configuration:"
echo "     • Docker"
echo "     • Nix + Home-Manager"
echo "     • VS Code + all extensions"
echo "     • Development environment"
echo "     • All scripts and configs"
echo ""
echo "Build time: ~45-60 minutes"
echo "Output: output-virtualbox/geckoforge-test.ova"
echo ""

# Check prerequisites
if ! command -v packer >/dev/null 2>&1; then
    echo "❌ Error: Packer is not installed"
    echo ""
    echo "Install with:"
    echo "  # Ubuntu/Debian"
    echo "  curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -"
    echo "  sudo apt-add-repository \"deb [arch=amd64] https://apt.releases.hashicorp.com \$(lsb_release -cs) main\""
    echo "  sudo apt-get update && sudo apt-get install packer"
    echo ""
    echo "  # Or download from: https://www.packer.io/downloads"
    exit 1
fi

if ! command -v VBoxManage >/dev/null 2>&1; then
    echo "❌ Error: VirtualBox is not installed"
    echo ""
    echo "Install with:"
    echo "  sudo apt-get install virtualbox"
    echo ""
    exit 1
fi

echo "✓ Packer version: $(packer version)"
echo "✓ VirtualBox version: $(VBoxManage --version)"
echo ""

# Validate template
echo "Validating Packer template..."
packer validate opensuse-leap-geckoforge.pkr.hcl

if [ $? -eq 0 ]; then
    echo "✓ Template is valid"
else
    echo "❌ Template validation failed"
    exit 1
fi

echo ""
read -p "Start build? (y/N) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Build cancelled"
    exit 0
fi

echo ""
echo "Starting build..."
echo ""

# Build with Packer
packer build \
  -force \
  -on-error=ask \
  opensuse-leap-geckoforge.pkr.hcl

if [ $? -eq 0 ]; then
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  ✅ Build Complete!"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    echo "Output: output-virtualbox/geckoforge-test.ova"
    echo ""
    echo "Import to VirtualBox:"
    echo "  VBoxManage import output-virtualbox/geckoforge-test.ova"
    echo ""
    echo "Or use GUI:"
    echo "  File → Import Appliance → Select .ova"
    echo ""
    echo "What's included:"
    echo "  ✓ openSUSE Leap 15.6 + KDE Plasma"
    echo "  ✓ Docker + NVIDIA Container Toolkit"
    echo "  ✓ Nix + Home-Manager"
    echo "  ✓ VS Code + 29 extensions"
    echo "  ✓ Python, Node.js, Go, Elixir, R, .NET"
    echo "  ✓ All geckoforge scripts and configs"
    echo ""
    echo "First boot:"
    echo "  1. Login (user: jay, password: vagrant)"
    echo "  2. Double-click 'Complete geckoforge Setup' on desktop"
    echo "  3. Reboot when complete"
    echo ""
    echo "Repository: /opt/geckoforge"
    echo ""
else
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  ❌ Build Failed"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    echo "Check the output above for errors"
    echo ""
    exit 1
fi
