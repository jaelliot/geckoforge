#!/usr/bin/env bash
# @file tools/validate/check-layer-assignments.sh
# @description Validate 4-layer architecture boundaries are respected
# @update-policy Update when layer responsibilities change

set -euo pipefail

echo "🔍 Validating layer assignments..."

errors=0

# Layer 2 (First-boot) should NOT contain Docker setup
if grep -rn "docker install\|docker-compose" profiles/*/scripts/firstboot-*.sh 2>/dev/null; then
  echo "❌ Docker installation found in first-boot scripts (should be Layer 3)"
  errors=$((errors + 1))
fi

# Layer 2 (First-boot systemd) should NOT call Layer 3 scripts
if grep -rn "scripts/setup-\|scripts/firstrun-user" profiles/*/root/etc/systemd/system/*.service 2>/dev/null; then
  echo "❌ User setup scripts called from systemd units (Layer 2/3 violation)"
  errors=$((errors + 1))
fi

# Layer 1 (KIWI ISO) should NOT contain Docker packages
if grep -n "<package>docker</package>" profiles/**/config.kiwi.xml 2>/dev/null; then
  echo "❌ Docker package in KIWI config (should be installed in Layer 3)"
  errors=$((errors + 1))
fi

# Check for user-specific config in ISO layer
if grep -rn "home-manager\|\.config/" profiles/*/root/ 2>/dev/null | grep -v ".md:\|comment"; then
  echo "❌ User-specific config in ISO root overlay (should be Layer 4)"
  errors=$((errors + 1))
fi

if [ $errors -gt 0 ]; then
  echo ""
  echo "❌ Found $errors layer boundary violation(s)"
  echo "💡 Review '.cursor/rules/10-kiwi-architecture.mdc' for layer responsibilities"
  exit 1
fi

echo "✅ Layer assignments correct"