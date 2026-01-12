#!/usr/bin/env bash
# @file tools/opa-check.sh
# @description Evaluate policies for geckoforge compliance (OPA-inspired)
# @update-policy Update when new file types need to be checked or policies change
#
# Usage: tools/opa-check.sh [--staged|--all]
#   --staged: Check only staged files (default for pre-commit)
#   --all:    Check all files in repository
#
# Note: This script implements OPA-style policy checks in bash for portability.
#       Full OPA/Rego support can be added if needed.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

MODE="${1:---staged}"
VIOLATIONS=0
WARNINGS=0

echo "🔍 Running OPA policy checks ($MODE)..."

# =============================================================================
# CRITICAL CHECKS (based on audit ISSUE-001 through ISSUE-006)
# =============================================================================

# ISSUE-001: Check for wrong config file name
if [ -f "$REPO_ROOT/profile/config.kiwi.xml" ]; then
    echo "❌ CRITICAL [ISSUE-001]: Config file must be 'config.xml', not 'config.kiwi.xml'"
    VIOLATIONS=$((VIOLATIONS + 1))
fi

# ISSUE-002: Check for missing <contact> in config.xml
if [ -f "$REPO_ROOT/profile/config.xml" ]; then
    if grep -q "<description" "$REPO_ROOT/profile/config.xml" && \
       ! grep -q "<contact>" "$REPO_ROOT/profile/config.xml"; then
        echo "❌ CRITICAL [ISSUE-002]: Missing <contact> element in <description>"
        VIOLATIONS=$((VIOLATIONS + 1))
    fi
fi

# ISSUE-003: Check for deprecated <files> element
if [ -f "$REPO_ROOT/profile/config.xml" ]; then
    if grep -q "<files>" "$REPO_ROOT/profile/config.xml"; then
        echo "❌ CRITICAL [ISSUE-003]: Deprecated <files> element found. Use root/ overlay"
        VIOLATIONS=$((VIOLATIONS + 1))
    fi
fi

# ISSUE-004: Check for deprecated hybrid attribute
if [ -f "$REPO_ROOT/profile/config.xml" ]; then
    if grep -E 'hybrid\s*=' "$REPO_ROOT/profile/config.xml" | grep -v "hybridpersistent" >/dev/null 2>&1; then
        echo "❌ CRITICAL [ISSUE-004]: Deprecated 'hybrid' attribute. ISOs are hybrid by default"
        VIOLATIONS=$((VIOLATIONS + 1))
    fi
fi

# ISSUE-005: Check for wrong package syntax (text content instead of name attribute)
if [ -f "$REPO_ROOT/profile/config.xml" ]; then
    if grep -E '<package>[^<]+</package>' "$REPO_ROOT/profile/config.xml" >/dev/null 2>&1; then
        echo "❌ CRITICAL [ISSUE-005]: Use <package name=\"...\"/> not <package>text</package>"
        VIOLATIONS=$((VIOLATIONS + 1))
    fi
fi

# =============================================================================
# HIGH SEVERITY CHECKS
# =============================================================================

# Get files based on mode
if [ "$MODE" = "--all" ]; then
    SCRIPT_FILES=$(find "$REPO_ROOT/scripts" "$REPO_ROOT/profile" -name "*.sh" 2>/dev/null || true)
    NIX_FILES=$(find "$REPO_ROOT/home" -name "*.nix" 2>/dev/null || true)
else
    # Exclude policy documentation and check scripts from staged files
    EXCLUDE_PATTERN="opa-check\.sh\|check-anti-patterns\.sh\|opa-integration\.md\|daily-summaries/\|policies/opa/"
    SCRIPT_FILES=$(cd "$REPO_ROOT" && git diff --cached --name-only --diff-filter=ACM 2>/dev/null | \
        grep '\.sh$' | grep -v "$EXCLUDE_PATTERN" | while read -r f; do echo "$REPO_ROOT/$f"; done || true)
    NIX_FILES=$(cd "$REPO_ROOT" && git diff --cached --name-only --diff-filter=ACM 2>/dev/null | \
        grep '\.nix$' | grep -v "$EXCLUDE_PATTERN" | while read -r f; do echo "$REPO_ROOT/$f"; done || true)
fi

# Podman usage check (excluding comments, removals, and documentation)
for file in $SCRIPT_FILES; do
    [ -f "$file" ] || continue
    # Exclude instruction files and check scripts
    [[ "$file" == *"instructions"* ]] && continue
    [[ "$file" == *"opa-check"* ]] && continue
    [[ "$file" == *"check-anti-patterns"* ]] && continue
    
    # Check for podman usage that's NOT removal/cleanup/detection
    # Legitimate: rpm -q podman, zypper rm podman, systemctl stop podman, purge_podman variable
    if grep -n "podman" "$file" 2>/dev/null | \
       grep -v "^[[:space:]]*#" | \
       grep -v "rpm -q podman\|zypper.*podman\|systemctl.*podman\|rm.*podman\|remove.*podman\|detected\|Found\|purge_podman\|Remove Podman\|Podman data\|\[podman\]" >/dev/null 2>&1; then
        echo "❌ HIGH: Podman usage detected in $(basename "$file"). Use Docker instead"
        VIOLATIONS=$((VIOLATIONS + 1))
    fi
done

# Podman GPU syntax check
for file in $SCRIPT_FILES; do
    [ -f "$file" ] || continue
    [[ "$file" == *"instructions"* ]] && continue
    
    if grep -n "\--device nvidia.com/gpu" "$file" 2>/dev/null | grep -v "^[[:space:]]*#" >/dev/null 2>&1; then
        echo "❌ HIGH: Podman GPU syntax in $(basename "$file"). Use '--gpus all'"
        VIOLATIONS=$((VIOLATIONS + 1))
    fi
done

# TeX scheme-full check
for file in $NIX_FILES; do
    [ -f "$file" ] || continue
    [[ "$file" == *"instructions"* ]] && continue
    
    if grep -n "scheme-full" "$file" 2>/dev/null | grep -v "^[[:space:]]*#" | grep -v "NOT\|instead" >/dev/null 2>&1; then
        echo "❌ HIGH: TeX scheme-full in $(basename "$file"). Use scheme-medium"
        VIOLATIONS=$((VIOLATIONS + 1))
    fi
done

# Wrong package manager check
for file in $SCRIPT_FILES; do
    [ -f "$file" ] || continue
    [[ "$file" == *"instructions"* ]] && continue
    
    if grep -nE "(apt-get|apt install|dnf install|pacman -S)" "$file" 2>/dev/null | grep -v "^[[:space:]]*#" >/dev/null 2>&1; then
        echo "❌ MEDIUM: Non-openSUSE package manager in $(basename "$file"). Use zypper"
        VIOLATIONS=$((VIOLATIONS + 1))
    fi
done

# =============================================================================
# MEDIUM SEVERITY CHECKS
# =============================================================================

# Check for services in multi-user.target.wants that should be symlinks
TARGET_WANTS_DIR="$REPO_ROOT/profile/root/etc/systemd/system/multi-user.target.wants"
if [ -d "$TARGET_WANTS_DIR" ]; then
    shopt -s nullglob
    for file in "$TARGET_WANTS_DIR"/*.service; do
        [ -f "$file" ] || continue
        if [ ! -L "$file" ]; then
            echo "⚠️  MEDIUM [ISSUE-012]: $(basename "$file") should be a symlink, not a file"
            WARNINGS=$((WARNINGS + 1))
        fi
    done
    shopt -u nullglob
fi

# =============================================================================
# LOW SEVERITY WARNINGS
# =============================================================================

# Check for missing firmware packages (only in full mode)
if [ "$MODE" = "--all" ] && [ -f "$REPO_ROOT/profile/config.xml" ]; then
    if ! grep -q "kernel-firmware" "$REPO_ROOT/profile/config.xml"; then
        echo "⚠️  LOW [ISSUE-019]: Consider adding kernel-firmware packages for laptop support"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

# =============================================================================
# SUMMARY
# =============================================================================

echo ""
echo "📊 OPA Policy Check Summary"
echo "==========================="
echo "   Violations: $VIOLATIONS"
echo "   Warnings:   $WARNINGS"
echo ""

if [ "$VIOLATIONS" -gt 0 ]; then
    echo "❌ Commit blocked due to $VIOLATIONS policy violation(s)"
    echo ""
    echo "💡 Fix the issues above or document exceptions in daily summary"
    echo "   See: docs/research/Geckoforge-Kiwi-NG-Audit-and-Remediation-Report.md"
    exit 1
fi

if [ "$WARNINGS" -gt 0 ]; then
    echo "⚠️  $WARNINGS warning(s) - consider addressing before deployment"
fi

echo "✅ OPA policy check passed"
exit 0
