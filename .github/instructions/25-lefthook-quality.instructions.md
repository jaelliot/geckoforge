---
applyTo: ".lefthook.yml,**/.lefthook/**,scripts/**,.github/**"
---

---
description: Lefthook pre-commit and pre-push quality gates for geckoforge
alwaysApply: false
version: 0.3.0
---

## Use when
- Setting up or modifying lefthook configuration
- Creating new quality checks
- Debugging hook failures
- Adding validation scripts

## Philosophy

**Fast feedback, hard stops on critical issues.**

- Pre-commit: Syntax, formatting, obvious errors (< 30 seconds)
- Pre-push: Deeper validation, ISO build test (< 5 minutes)
- No bypassing critical checks without explicit justification

---

## Lefthook Configuration

### File Location
`lefthook.yml` at repository root

### Basic Structure
```yaml
# lefthook.yml
pre-commit:
  parallel: true
  commands:
    # Fast checks here

pre-push:
  parallel: false  # Sequential for better error reporting
  commands:
    # Deeper validation here
```

---

## Pre-Commit Checks (Fast, < 30s)

### 1. Shell Script Validation
```yaml
pre-commit:
  commands:
    shellcheck:
      glob: "**/*.sh"
      run: |
        shellcheck {staged_files} || {
          echo "❌ ShellCheck failed"
          echo "Fix errors or add # shellcheck disable=SCXXXX with justification"
          exit 1
        }
```

**What it catches:**
- Unquoted variables
- Missing error handling
- Incorrect shebangs
- Common bash pitfalls

### 2. Nix Syntax Check
```yaml
    nix-check:
      glob: "home/**/*.nix"
      run: |
        for file in {staged_files}; do
          nix-instantiate --parse "$file" > /dev/null || {
            echo "❌ Nix syntax error in $file"
            exit 1
          }
        done
```

**What it catches:**
- Syntax errors
- Unterminated strings
- Invalid attribute names

### 3. KIWI XML Validation
```yaml
    kiwi-validate:
      glob: "profiles/**/config.kiwi.xml"
      run: |
        xmllint --noout {staged_files} || {
          echo "❌ KIWI XML validation failed"
          exit 1
        }
```

**What it catches:**
- Malformed XML
- Unclosed tags
- Invalid structure

### 4. Markdown Linting
```yaml
    markdown-lint:
      glob: "**/*.md"
      run: |
        markdownlint {staged_files} || {
          echo "❌ Markdown linting failed"
          echo "Run: markdownlint --fix {staged_files}"
          exit 1
        }
```

**What it catches:**
- Heading hierarchy
- Link formatting
- Code block syntax

### 5. Anti-Pattern Detection
```yaml
    anti-patterns:
      glob: "**/*.{sh,nix,md}"
      run: |
        # Check for Podman references
        if grep -rn "podman\|--device nvidia.com/gpu" {staged_files}; then
          echo "❌ Podman reference detected (Docker only!)"
          exit 1
        fi
        
        # Check for TeX scheme-full
        if grep -rn "scheme-full" {staged_files}; then
          echo "❌ TeX scheme-full detected (use scheme-medium!)"
          exit 1
        fi
        
        # Check for Ubuntu/Debian commands
        if grep -rn "apt-get\|apt install" {staged_files}; then
          echo "❌ Debian package manager detected (use zypper!)"
          exit 1
        fi
```

**What it catches:**
- Podman syntax (should be Docker)
- TeX scheme-full (should be scheme-medium)
- Wrong package manager commands

### 6. Executable Bit Check
```yaml
    executable-check:
      glob: "scripts/**/*.sh"
      run: |
        for file in {staged_files}; do
          if [ ! -x "$file" ]; then
            echo "❌ Script not executable: $file"
            echo "Run: chmod +x $file"
            exit 1
          fi
        done
```

**What it catches:**
- Non-executable scripts
- Missing permissions

### 7. TODO/FIXME Tracker
```yaml
    todo-tracker:
      glob: "**/*.{sh,nix,md}"
      run: |
        todos=$(grep -rn "TODO\|FIXME" {staged_files} | wc -l)
        if [ "$todos" -gt 0 ]; then
          echo "⚠️  Found $todos TODO/FIXME markers"
          grep -rn "TODO\|FIXME" {staged_files}
          # Warning only, don't fail
        fi
```

**What it reports:**
- Outstanding TODOs
- FIXME markers
- (Warning only, doesn't block)

---

## Pre-Push Checks (Thorough, < 5 min)

### 1. Package Existence Verification
```yaml
pre-push:
  commands:
    verify-packages:
      glob: "profiles/**/config.kiwi.xml"
      run: |
        echo "🔍 Verifying zypper packages..."
        # Extract package names from XML
        packages=$(xmllint --xpath '//package/text()' {all_files} | sort -u)
        
        for pkg in $packages; do
          if ! zypper search -x "$pkg" &>/dev/null; then
            echo "❌ Package not found in repos: $pkg"
            exit 1
          fi
        done
        echo "✅ All zypper packages exist"
```

### 2. Nix Package Verification
```yaml
    verify-nix-packages:
      glob: "home/**/*.nix"
      run: |
        echo "🔍 Verifying Nix packages..."
        # Extract package references (basic pattern matching)
        suspicious=$(grep -rn "pkgs\.[a-zA-Z0-9_-]*" {all_files} | \
                    grep -v "pkgs.lib\|pkgs.stdenv\|pkgs.fetchurl")
        
        # This is a warning - full verification requires nix-build
        if [ -n "$suspicious" ]; then
          echo "⚠️  Review package references manually"
          echo "$suspicious"
        fi
        echo "✅ Nix syntax passed"
```

### 3. Layer Assignment Validation
```yaml
    validate-layers:
      run: |
        echo "🔍 Validating layer assignments..."
        
        # Check for Docker in first-boot (Layer 2)
        if grep -rn "docker" profiles/*/scripts/firstboot-*.sh; then
          echo "❌ Docker found in first-boot scripts (should be Layer 3)"
          exit 1
        fi
        
        # Check for user scripts in KIWI systemd
        if grep -rn "scripts/setup-" profiles/*/root/etc/systemd/system/; then
          echo "❌ User setup scripts in systemd units (Layer 2/3 violation)"
          exit 1
        fi
        
        echo "✅ Layer assignments correct"
```

### 4. Documentation Sync Check
```yaml
    docs-sync:
      run: |
        echo "🔍 Checking documentation sync..."
        
        # Check if daily summary exists for today
        today=$(date +%Y-%m-%d)
        summary="docs/daily-summaries/$(date +%Y-%m)/$today.md"
        
        if [ ! -f "$summary" ]; then
          echo "⚠️  No daily summary for $today"
          echo "Consider creating: $summary"
          # Warning only
        fi
        
        echo "✅ Documentation check complete"
```

### 5. ISO Build Smoke Test
```yaml
    iso-smoke-test:
      run: |
        echo "🔍 Running ISO build smoke test..."
        
        # Validate config without building
        if ! ./tools/kiwi-build.sh --validate-only profile; then
          echo "❌ ISO build validation failed"
          exit 1
        fi
        
        echo "✅ ISO build validation passed"
        echo "💡 Run full build: ./tools/kiwi-build.sh profile"
```

---

## Tool Installation

### Required Tools
```bash
# Install quality tools
sudo zypper install -y shellcheck xmllint

# Install via Home-Manager
home.packages = with pkgs; [
  shellcheck
  markdownlint-cli
  xmllint
];

# Install lefthook
curl -1sLf 'https://dl.cloudsmith.io/public/evilmartians/lefthook/setup.rpm.sh' | sudo -E bash
sudo zypper install -y lefthook
```

---

## Bypassing Hooks (Emergency Only)

### Skip All Hooks
```bash
# AVOID THIS
git commit --no-verify -m "Emergency fix"
git push --no-verify
```

### Skip Specific Check
```bash
# Better: Skip one check with justification
LEFTHOOK_EXCLUDE=shellcheck git commit -m "WIP: Disable shellcheck for prototype"
```

### Document Bypasses
```bash
# Add to daily summary why you bypassed
echo "- Bypassed shellcheck for scripts/prototype.sh (WIP)" >> docs/daily-summaries/...
```

---

## Custom Validation Scripts

### Location
`tools/` directory

### Example: `tools/check-anti-patterns.sh`
```bash
#!/usr/bin/env bash
set -euo pipefail

echo "🔍 Checking for anti-patterns..."

errors=0

# Check for Podman
if git diff --cached --name-only | xargs grep -l "podman" 2>/dev/null; then
  echo "❌ Found 'podman' references (use Docker)"
  errors=$((errors + 1))
fi

# Check for scheme-full
if git diff --cached --name-only | xargs grep -l "scheme-full" 2>/dev/null; then
  echo "❌ Found 'scheme-full' (use scheme-medium)"
  errors=$((errors + 1))
fi

if [ $errors -gt 0 ]; then
  echo ""
  echo "Fix these issues or document bypass in daily summary"
  exit 1
fi

echo "✅ No anti-patterns detected"
```

---

## Performance Optimization

### Parallel Execution
```yaml
pre-commit:
  parallel: true  # Run checks concurrently
  commands:
    # Each command runs in parallel
```

### File Filtering
```yaml
pre-commit:
  commands:
    shellcheck:
      glob: "**/*.sh"  # Only run on .sh files
      run: shellcheck {staged_files}
```

### Skip Patterns
```yaml
pre-commit:
  skip:
    - ref: main  # Skip on main branch
    - merge      # Skip on merge commits
```

---

## Troubleshooting

### Hook Not Running
```bash
# Reinstall hooks
lefthook install

# Check installation
lefthook version
ls -la .git/hooks/
```

### False Positives
```bash
# Disable specific check temporarily
# In file:
# shellcheck disable=SC2086

# Or in lefthook.yml:
commands:
  shellcheck:
    skip: true  # Disable entirely (not recommended)
```

### Slow Hooks
```bash
# Profile hook execution
time lefthook run pre-commit

# Check individual commands
lefthook run pre-commit --commands shellcheck
```

---

## Integration with Daily Workflow

### Normal Flow
```bash
# Make changes
$EDITOR scripts/setup-docker.sh

# Stage changes (triggers pre-commit)
git add scripts/setup-docker.sh
# Hooks run automatically

# Commit (if hooks passed)
git commit -m "feat(docker): improve error handling"

# Push (triggers pre-push)
git push
# Deeper validation runs
```

### Hook Failure Flow
```bash
# Hooks fail
git add file.sh
# ❌ ShellCheck failed

# Fix issues
shellcheck file.sh
$EDITOR file.sh

# Try again
git add file.sh
git commit -m "fix: resolve shellcheck warnings"
# ✅ All checks passed
```

---

## Best Practices

### Do:
- ✅ Keep pre-commit checks fast (< 30s)
- ✅ Make error messages actionable
- ✅ Provide fix suggestions
- ✅ Test hooks before committing
- ✅ Document bypasses in daily summary

### Don't:
- ❌ Add slow checks to pre-commit (move to pre-push)
- ❌ Bypass hooks without documentation
- ❌ Disable checks globally
- ❌ Skip pre-push validation before hardware deployment

---

## Evolution Path

### v0.3.0 (Current)
- Basic validation (syntax, anti-patterns)
- Fast pre-commit checks

### v0.4.0 (Future)
- Nix build tests in pre-push
- Security scanning (gitleaks)
- Performance regression detection

### v0.5.0 (Future)
- Automated ISO builds in pre-push
- VM boot testing
- Comprehensive package verification

---

## Example lefthook.yml (Complete)

```yaml
# lefthook.yml
pre-commit:
  parallel: true
  commands:
    shellcheck:
      glob: "**/*.sh"
      run: shellcheck {staged_files}
    
    nix-check:
      glob: "home/**/*.nix"
      run: |
        for file in {staged_files}; do
          nix-instantiate --parse "$file" > /dev/null
        done
    
    xml-validate:
      glob: "profiles/**/config.kiwi.xml"
      run: xmllint --noout {staged_files}
    
    anti-patterns:
      glob: "**/*.{sh,nix,md}"
      run: tools/check-anti-patterns.sh
    
    executable-check:
      glob: "scripts/**/*.sh"
      run: |
        for file in {staged_files}; do
          [ -x "$file" ] || {
            echo "❌ Not executable: $file"
            echo "Run: chmod +x $file"
            exit 1
          }
        done

pre-push:
  parallel: false
  commands:
    validate-layers:
      run: tools/check-layer-assignments.sh
    
    iso-validate:
      run: ./tools/kiwi-build.sh --validate-only profile
    
    docs-check:
      run: |
        today=$(date +%Y-%m-%d)
        summary="docs/daily-summaries/$(date +%Y-%m)/$today.md"
        [ -f "$summary" ] || echo "⚠️  Consider creating daily summary: $summary"
```

---

## Success Metrics

Hooks are effective when:
- ✅ Pre-commit completes in < 30 seconds
- ✅ Catch 90%+ of trivial errors before push
- ✅ No Podman/scheme-full ever reaches main branch
- ✅ Developers understand why hooks failed
- ✅ Bypass rate < 5% (with documented reasons)