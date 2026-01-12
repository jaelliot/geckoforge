# geckoforge Audit Compliance Checklist

## Purpose
This checklist codifies all 20 issues identified in the January 2026 audit to prevent regressions.

## Pre-Build Checklist

### KIWI Schema Validation (Critical)

- [ ] **ISSUE-001**: Config file named `config.xml` (NOT `config.kiwi.xml`)
- [ ] **ISSUE-002**: `<description>` contains `<contact>` element
- [ ] **ISSUE-003**: No `<files>` element (use `root/` overlay instead)
- [ ] **ISSUE-004**: No `hybrid` attribute on `<type>` (use `mediacheck` if needed)
- [ ] **ISSUE-005**: All `<package>` elements use `name="..."` attribute
- [ ] **ISSUE-006**: Run `kiwi-ng system validate --description profile/` passes

### Build Environment (Critical)

- [ ] **ISSUE-007**: Building on x86_64 host for x86_64 target (or using `boxbuild --x86_64`)
- [ ] **ISSUE-008**: Using native KIWI NG (not Docker container on VMware Fusion)

### First-Boot Services (High)

- [ ] **ISSUE-009**: Services have proper ordering (`After=`, `Wants=`)
- [ ] **ISSUE-010**: Services use `ConditionPathExists` for one-shot behavior
- [ ] **ISSUE-011**: Symlinks (not files) in `multi-user.target.wants/`
- [ ] **ISSUE-012**: First-boot scripts wait for `network-online.target`

### NVIDIA Configuration (High)

- [ ] **ISSUE-013**: Using signed drivers for Secure Boot (`nvidia-open-driver-G06-signed`)
- [ ] **ISSUE-014**: Optimus laptops have `suse-prime` package
- [ ] **ISSUE-015**: NVIDIA repo configured in `root/etc/zypp/repos.d/nvidia.repo`

### Project Structure (Medium)

- [ ] **ISSUE-016**: No duplicate directories (`profile/` is canonical, not `profiles/`)
- [ ] **ISSUE-017**: First-boot scripts in `profile/root/usr/local/sbin/`
- [ ] **ISSUE-018**: Correct permissions set in `config.sh` (scripts: 0755, configs: 0644)

### Home-Manager Configuration (Medium)

- [ ] **ISSUE-019**: TeX Live uses `scheme-medium` (NOT `scheme-full`)
- [ ] **ISSUE-020**: Nix flake pins to stable nixpkgs (24.05)

## Validation Commands

```bash
# 1. Validate KIWI schema
kiwi-ng system validate --description profile/

# 2. Check config file name
ls profile/config.xml && echo "✅ Correct" || echo "❌ Wrong name"

# 3. Check for deprecated elements
grep -n "hybrid=" profile/config.xml && echo "❌ hybrid found" || echo "✅ No hybrid"
grep -n "<files>" profile/config.xml && echo "❌ files found" || echo "✅ No files"

# 4. Check package syntax
grep -n "<package>" profile/config.xml | grep -v 'name=' && echo "❌ Wrong syntax" || echo "✅ Correct"

# 5. Check contact element
grep -n "<contact>" profile/config.xml && echo "✅ Contact found" || echo "❌ Missing contact"

# 6. Check symlinks
ls -la profile/root/etc/systemd/system/multi-user.target.wants/ | grep -v "^l" | grep service && echo "❌ Files found" || echo "✅ All symlinks"

# 7. Check TeX scheme
grep -r "scheme-full" home/ && echo "❌ scheme-full found" || echo "✅ No scheme-full"
```

## Issue Severity Reference

| Severity | Count | Issues |
|----------|-------|--------|
| Critical | 5 | ISSUE-001, 002, 003, 004, 005, 006, 007 |
| High | 7 | ISSUE-008, 009, 010, 011, 012, 013, 014, 015 |
| Medium | 4 | ISSUE-016, 017, 018, 019, 020 |
| Low | 4 | Documentation gaps, unused files |

## Quick Fix Reference

### Wrong config file name
```bash
mv profile/config.kiwi.xml profile/config.xml
```

### Missing contact element
```xml
<description type="system">
  <author>Jay-Alexander Elliot</author>
  <contact>geckoforge@example.com</contact>
  <specification>...</specification>
</description>
```

### Wrong package syntax
```xml
<!-- Change from: -->
<package>kernel-default</package>
<!-- Change to: -->
<package name="kernel-default"/>
```

### File instead of symlink
```bash
cd profile/root/etc/systemd/system/multi-user.target.wants/
rm service-name.service
ln -s ../service-name.service .
```

### Permissions in config.sh
```bash
chmod 0755 /usr/local/sbin/firstboot-*.sh
chmod 0644 /etc/systemd/system/geckoforge-*.service
```

## Regression Prevention

This checklist should be run:
1. **Before every commit** that touches `profile/`
2. **Before every ISO build**
3. **After pulling changes** from the repository
4. **During code review** of any KIWI-related changes

## Related Skills

- [kiwi-schema-validation.md](kiwi-schema-validation.md) - Detailed schema rules
- [kiwi-build-environment.md](kiwi-build-environment.md) - Build setup guide
- [firstboot-services.md](firstboot-services.md) - Service configuration
- [nvidia-driver-installation.md](nvidia-driver-installation.md) - NVIDIA setup
- [anti-pattern-prevention.md](anti-pattern-prevention.md) - Common mistakes

## Audit Source

Full audit report: `docs/research/Geckoforge-Kiwi-NG-Audit-and-Remediation-Report.md`
