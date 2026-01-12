# Open Policy Agent (OPA) Integration

Geckoforge uses [Open Policy Agent](https://www.openpolicyagent.org/) for policy-as-code compliance checking. This ensures that all commits meet the quality standards defined in the [KIWI NG Audit Report](docs/research/Geckoforge-Kiwi-NG-Audit-and-Remediation-Report.md).

## Quick Start

### Install OPA (Optional but Recommended)

```bash
# macOS
brew install opa

# Linux (x86_64)
curl -L -o opa https://openpolicyagent.org/downloads/latest/opa_linux_amd64_static
chmod +x opa
sudo mv opa /usr/local/bin/

# Verify
opa version
```

If OPA is not installed, the checks will skip gracefully with a warning.

### Run Checks Manually

```bash
# Check staged files (pre-commit mode)
./tools/opa-check.sh --staged

# Check all files (full audit)
./tools/opa-check.sh --all
```

## Policy Coverage

The OPA policies enforce compliance with the 20 issues identified in the audit report:

### Critical (Blocks Commits)

| Issue | Rule | Description |
|-------|------|-------------|
| ISSUE-001 | `config_file_name` | Config must be `config.xml`, not `config.kiwi.xml` |
| ISSUE-002 | `missing_contact` | `<description>` must contain `<contact>` element |
| ISSUE-003 | `deprecated_files` | `<files>` element is deprecated; use `root/` overlay |
| ISSUE-004 | `hybrid_attribute` | `hybrid` attribute is deprecated; ISOs are hybrid by default |
| ISSUE-005 | `package_syntax` | Use `<package name="..."/>`, not `<package>text</package>` |

### High Severity (Blocks Commits)

| Check | Description |
|-------|-------------|
| Podman usage | Docker only - no Podman commands |
| Podman GPU syntax | Use `--gpus all`, not `--device nvidia.com/gpu` |
| TeX scheme-full | Use `scheme-medium`, not `scheme-full` |
| Wrong package manager | Use `zypper`, not `apt-get`/`dnf`/`pacman` |

### Medium Severity (Warnings)

| Issue | Rule | Description |
|-------|------|-------------|
| ISSUE-012 | `target_wants_files` | Services in `multi-user.target.wants/` should be symlinks |

### Low Severity (Advisory)

| Issue | Rule | Description |
|-------|------|-------------|
| ISSUE-019 | `missing_firmware` | Consider adding `kernel-firmware` packages |

## Lefthook Integration

OPA checks are automatically run by lefthook:

### Pre-commit (Fast, Staged Files Only)
```yaml
pre-commit:
  commands:
    opa-policy:
      glob: "**/*.{sh,nix,xml,service}"
      run: tools/opa-check.sh --staged
```

### Pre-push (Thorough, All Files)
```yaml
pre-push:
  commands:
    opa-full-check:
      run: tools/opa-check.sh --all
```

## Policy Files

### Location
```
policies/
└── opa/
    └── geckoforge.rego   # Main policy file (Rego language)
```

### Adding New Policies

1. Edit `policies/opa/geckoforge.rego`
2. Add new violation rule:
   ```rego
   violation_new_check contains msg if {
       # Your condition
       some file in input.files
       # Pattern match
       msg := sprintf("SEVERITY [ISSUE-XXX]: Description in %s", [file])
   }
   ```
3. Add to `violations` set
4. Test with `./tools/opa-check.sh --all`

## Bypassing Checks (When Necessary)

For legitimate exceptions, document in daily summary:

```markdown
## Policy Exceptions

### Exception: [ISSUE-XXX]
**File**: path/to/file
**Reason**: Explanation of why this is acceptable
**Approved**: Date and approver
```

Then add file to exclusion list in `tools/opa-check.sh`:
```bash
[[ "$file" == *"exception_file"* ]] && continue
```

## Troubleshooting

### "OPA not installed - skipping"
Install OPA using the commands above. This is optional but recommended.

### "Commit blocked due to policy violations"
1. Read the violation message carefully
2. Fix the issue in your code
3. Re-run `./tools/opa-check.sh --staged` to verify
4. Commit again

### False Positives
If a check triggers incorrectly:
1. Check if the file should be excluded (instructions, docs)
2. Update exclusion patterns in `tools/opa-check.sh`
3. Open an issue if the rule needs adjustment

## Related Documentation

- [KIWI NG Audit Report](docs/research/Geckoforge-Kiwi-NG-Audit-and-Remediation-Report.md)
- [Anti-Pattern Prevention](.github/skills/anti-pattern-prevention.md)
- [Audit Compliance Checklist](.github/skills/audit-compliance-checklist.md)
- [Lefthook Quality Gates](.github/instructions/25-lefthook-quality.instructions.md)
