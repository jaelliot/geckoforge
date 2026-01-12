#!/usr/bin/env bash
# @file tools/check-anti-patterns.sh
# @description Detect forbidden patterns (Podman, scheme-full, wrong package managers)
# @update-policy Update when new anti-patterns are identified

set -euo pipefail

echo "🔍 Checking for anti-patterns..."

errors=0

# Files to exclude (documentation about anti-patterns)
EXCLUDE_PATTERN="\.github/instructions/\|\.github/skills/\|check-anti-patterns\.sh\|docs/research/\|docs/summaries/"

# Get staged or all files
if [ "${1:-}" = "--all" ]; then
  files=$(find . -type f \( -name "*.sh" -o -name "*.nix" -o -name "*.md" -o -name "*.xml" \) \
    -not -path "./.git/*" -not -path "./out/*" -not -path "./.github/instructions/*" -not -path "./.github/skills/*")
else
  files=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(sh|nix|md|xml)$' | grep -v "$EXCLUDE_PATTERN" || true)
fi

if [ -z "$files" ]; then
  echo "✅ No files to check (instruction/skill files excluded)"
  exit 0
fi

# Check for Podman references
if echo "$files" | xargs grep -n "podman" 2>/dev/null | grep -v "# Podman removal\|Podman-related\|Removing Podman\|podman-to-docker\|Podman detected\|Podman data\|Found 'podman'\|check-anti-patterns.sh\|Check for podman\|@description\|zypper rm.*podman\|systemctl.*podman\|docker.sh.*podman"; then
  echo "❌ Found 'podman' references (Docker only)"
  echo "   Exception: Comments about Podman removal are allowed"
  errors=$((errors + 1))
fi

# Check for Podman GPU syntax
if echo "$files" | xargs grep -n "\--device nvidia.com/gpu" 2>/dev/null | grep -v "❌\|@description\|check-anti-patterns.sh\|example"; then
  echo "❌ Found Podman GPU syntax (use '--gpus all')"
  errors=$((errors + 1))
fi

# Check for TeX scheme-full
if echo "$files" | xargs grep -n "scheme-full" 2>/dev/null | grep -v "scheme-full.*NOT\|scheme-full.*use scheme-medium\|Found 'scheme-full'\|check-anti-patterns.sh\|@description\|❌.*scheme-full\|scheme-full.*should be\|tex-verification.md"; then
  echo "❌ Found 'scheme-full' (use 'scheme-medium')"
  errors=$((errors + 1))
fi

# Check for wrong package managers
if echo "$files" | xargs grep -nE "apt-get|apt install|dnf install|pacman -S" 2>/dev/null | grep -v "^#\|^\s*#\|❌.*apt install\|Found non-openSUSE\|@description\|check-anti-patterns.sh"; then
  echo "❌ Found non-openSUSE package manager commands"
  echo "   Use: zypper (system), nix (user), flatpak (GUI apps)"
  errors=$((errors + 1))
fi

# Check for podman-compose
if echo "$files" | xargs grep -n "podman-compose" 2>/dev/null | grep -v "❌.*podman-compose\|Found 'podman-compose'\|check-anti-patterns.sh\|zypper rm.*podman-compose"; then
  echo "❌ Found 'podman-compose' (use 'docker compose')"
  errors=$((errors + 1))
fi

if [ $errors -gt 0 ]; then
  echo ""
  echo "❌ Found $errors anti-pattern violation(s)"
  echo "💡 Fix these issues or document bypass in daily summary"
  exit 1
fi

echo "✅ No anti-patterns detected"