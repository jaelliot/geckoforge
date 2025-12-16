#!/usr/bin/env bash
set -euo pipefail

ISO="${1:-$(ls out/*.iso 2>/dev/null | tail -n1 || true)}"

if [ ! -f "$ISO" ]; then
    echo "❌ Error: ISO not found"
    echo "Build it first: ./tools/kiwi-build.sh profile"
    exit 1
fi

echo "🧪 Testing ISO: $(basename "$ISO")"
echo ""

# Create test disk
DISK_DIR="$(dirname "$0")/../work/test-vms"
mkdir -p "$DISK_DIR"
DISK="$DISK_DIR/geckoforge-test-$(date +%Y%m%d-%H%M%S).qcow2"

echo "Creating 50GB test disk: $DISK"
qemu-img create -f qcow2 "$DISK" 50G

echo ""
echo "╔════════════════════════════════════════╗"
echo "║      VM Testing Instructions           ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "1. Install geckoforge to the virtual disk"
echo "2. Reboot (remove ISO)"
echo "3. Check first-boot scripts:"
echo "   journalctl -u geckoforge-firstboot.service"
echo "   journalctl -u geckoforge-nix.service"
echo "4. Verify:"
echo "   nix --version"
echo "   nvidia-smi (will fail in VM, OK)"
echo "5. Run: ~/git/geckoforge/scripts/firstrun-user.sh"
echo ""
echo "Press Enter to launch VM, or Ctrl+C to cancel"
read -r

# Launch QEMU
qemu-system-x86_64 \
    -enable-kvm \
    -m 8192 \
    -smp 4 \
    -cdrom "$ISO" \
    -drive file="$DISK",format=qcow2,if=virtio \
    -boot d \
    -display gtk \
    -vga virtio \
    -usb \
    -device usb-tablet

echo ""
echo "╔════════════════════════════════════════╗"
echo "║         Test Complete                  ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "Test disk saved: $DISK"
echo ""
echo "Keep disk for further testing? (y/N)"
read -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    rm -f "$DISK"
    echo "✓ Test disk deleted"
fi

echo ""
echo "Next steps:"
echo "1. Review test checklist: docs/testing-plan.md"
echo "2. Document any issues: GitHub Issues"
echo "3. If all tests pass, proceed to laptop testing"
