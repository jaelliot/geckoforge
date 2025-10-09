# Geckoforge Cursor Rules Index

| File                          | Attachment      | Globs                                                                                  | Purpose                                                                           | Version |
| ----------------------------- | --------------- | -------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- | ------- |
| 00-style-canon.mdc            | Always          | **/*.sh, **/*.nix, **/*.xml, **/*.yml, **/*.yaml, **/*.md                             | Universal prohibitions and non-negotiable standards for geckoforge                | 0.3.0   |
| 05-project-overview.mdc       | Agent Requested | n/a                                                                                    | High-level project context, goals, and target platform                            | 0.3.0   |
| 10-kiwi-architecture.mdc      | Auto Attached   | profiles/**/* , tools/**/* , scripts/**/*                                             | KIWI image builder 4-layer architecture and layer responsibilities                | 0.3.0   |
| 20-nix-home-manager.mdc       | Auto Attached   | home/**/*.nix, profiles/**/firstboot-nix.sh                                           | Nix and Home-Manager patterns, module organization, package management            | 0.3.0   |
| 30-container-runtime.mdc      | Auto Attached   | scripts/*docker*.sh, scripts/firstrun-user.sh, docs/*docker*.md, scripts/examples/** | Docker-only container runtime with NVIDIA GPU support policies                    | 0.3.0   |
| 40-documentation.mdc          | Agent Requested | docs/**/*.md, README.md, **/*.md                                                       | Documentation governance, structure, and daily summary requirements               | 0.3.0   |
| 50-testing-deployment.mdc     | Agent Requested | tools/**/* , scripts/**/* , docs/testing-plan.md                                      | Three-phase testing strategy and deployment verification procedures               | 0.3.0   |
| 60-package-management.mdc     | Auto Attached   | profiles/**/*.xml, home/**/*.nix, scripts/**/*.sh                                     | Package source selection (zypper/Nix/Flatpak) and verification procedures         | 0.3.0   |
| RULES_INDEX.md                | Always          | n/a                                                                                    | This file - index of all rules with metadata                                      | 0.3.0   |

---

## Rule Attachment Types

- **Always**: Applied to all file types, enforces universal standards
- **Auto Attached**: Automatically applied when working with matching file globs
- **Agent Requested**: Applied when explicitly needed for context or planning

---

## Quick Reference by Use Case

### Adding Packages
→ `60-package-management.mdc` + `10-kiwi-architecture.mdc`

### Container/GPU Work
→ `30-container-runtime.mdc` (Docker only, `--gpus all`)

### TeX Configuration
→ `20-nix-home-manager.mdc` (scheme-medium only)

### Script Creation
→ `10-kiwi-architecture.mdc` (layer assignment) + `00-style-canon.mdc`

### ISO Building
→ `10-kiwi-architecture.mdc` + `50-testing-deployment.mdc`

### Documentation
→ `40-documentation.mdc` (daily summaries, structure)

---

## Critical Prohibitions (from 00-style-canon.mdc)

### Never Use
- ❌ Podman syntax (`--device nvidia.com/gpu=`)
- ❌ TeX scheme-full
- ❌ Ubuntu/Debian package names
- ❌ Scripts in wrong layers
- ❌ Invented package names

### Always Use
- ✅ Docker syntax (`--gpus all`)
- ✅ TeX scheme-medium
- ✅ openSUSE package names (zypper)
- ✅ Correct layer placement
- ✅ Verified package names

---

## Rule Files

### Core Rules (Always Apply)

#### `00-style-canon.mdc`
**Always applies**: Yes  
**Purpose**: Universal prohibitions and non-negotiable standards

**Key policies:**
- Zero-tolerance anti-patterns (Podman syntax, TeX scheme-full, layer violations)
- Required patterns (Docker, scheme-medium, 4-layer architecture)
- Mandatory verifications before suggesting changes
- Forbidden terms and correct alternatives

**When to reference**: 
- Before suggesting any change
- When encountering container/GPU syntax
- When adding TeX Live packages
- When placing scripts in the project

---

### Architecture Rules

#### `05-project-overview.mdc`
**Applies to**: Repository structure, high-level goals  
**Purpose**: Project vision and context

**Key concepts:**
- This is a KIWI image builder (not a direct installer)
- Target: openSUSE Leap 15.6 with KDE Plasma
- Goal: Reproducible development workstation
- Hardware: NVIDIA GPU support mandatory

**When to reference**:
- Onboarding to the project
- Explaining project goals to users
- Making architectural decisions

---

#### `10-kiwi-architecture.mdc`
**Applies to**: `profiles/**/*`, `tools/**/*`, `scripts/**/*`  
**Purpose**: KIWI image builder 4-layer architecture

**Four layers:**
1. **ISO Layer** (KIWI profile) - Immutable system structure
2. **First-Boot Layer** (systemd units) - One-time system automation
3. **User-Setup Layer** (scripts) - Manual user configuration
4. **Home-Manager Layer** (Nix) - Reproducible user environment

**Critical rules:**
- Docker MUST be in Layer 3 (not Layer 2)
- User scripts MUST NOT be in first-boot systemd
- Layer interactions are strictly defined

**When to reference**:
- Adding new features
- Deciding where functionality belongs
- Creating or modifying scripts
- Building ISO images

---

#### `20-nix-home-manager.mdc`
**Applies to**: `home/**/*.nix`, `profiles/**/firstboot-nix.sh`  
**Purpose**: Nix and Home-Manager patterns

**Key patterns:**
- Nix installed at first-boot (Layer 2)
- Home-Manager for user packages (Layer 4)
- TeX Live MUST use scheme-medium
- Module organization by domain

**Critical requirements:**
- `texlive.combined.scheme-medium` (NOT scheme-full)
- Import all modules in home.nix
- Use activation scripts for Flatpaks

**When to reference**:
- Adding packages to Home-Manager
- Creating new modules
- Configuring user applications
- Installing development tools

---

#### `30-container-runtime.mdc`
**Applies to**: `scripts/*docker*.sh`, Docker examples  
**Purpose**: Docker-only container runtime with NVIDIA GPU support

**Critical policies:**
- Docker only (NO Podman)
- GPU syntax: `--gpus all` (NOT `--device nvidia.com/gpu=`)
- Automatic Podman removal in setup script
- NVIDIA Container Toolkit in Layer 3

**When to reference**:
- Working with containers
- Setting up GPU access
- Writing examples
- Troubleshooting container issues

---

### Documentation & Quality

#### `40-documentation.mdc`
**Applies to**: `docs/**/*.md`, `README.md`  
**Purpose**: Documentation governance and daily summaries

**Key requirements:**
- Daily summaries required for code changes
- Specific template and structure
- File paths must be included
- Maintenance schedule defined

**When to reference**:
- Writing documentation
- Recording work sessions
- Creating guides
- Updating examples

---

#### `50-testing-deployment.mdc`
**Applies to**: `tools/**/*`, test procedures  
**Purpose**: Testing requirements and deployment verification

**Three-phase testing:**
1. VM Testing (required before hardware)
2. Laptop Testing (1-2 weeks daily use)
3. Production Deployment (main workstation)

**Never skip VM testing.**

**When to reference**:
- Building new ISO
- Making major changes
- Deploying to hardware
- Creating test procedures

---

#### `60-package-management.mdc`
**Applies to**: Package additions across all layers  
**Purpose**: Package source selection and verification

**Decision matrix:**
- zypper: System packages (kernel, drivers, base)
- Nix: Development tools, CLI utilities
- Flatpak: GUI applications, sandboxed apps
- PWA: Web-first services

**Verification required before adding packages.**

**When to reference**:
- Adding any package
- Choosing package source
- Troubleshooting installations
- Updating packages

---

## Quick Reference

### Common Scenarios

#### "I want to add a new package"
1. Check `60-package-management.mdc` for source selection
2. Verify package exists in chosen source
3. Determine correct layer (from `10-kiwi-architecture.mdc`)
4. Add to appropriate file
5. Update documentation (per `40-documentation.mdc`)

#### "I want to set up GPU containers"
1. Follow `30-container-runtime.mdc` exclusively
2. Use Docker syntax: `--gpus all`
3. Never use Podman CDI syntax
4. Install NVIDIA Container Toolkit in Layer 3

#### "I want to add a development tool"
1. Add to `home/modules/development.nix` (Layer 4)
2. Verify with `nix search nixpkgs tool-name`
3. Use correct package name from nixpkgs
4. Test with `nix shell nixpkgs#tool-name`

#### "I want to add TeX packages"
1. Base must be `texlive.combined.scheme-medium`
2. Never use scheme-full
3. If specific package needed, use texlive.combine
4. Test with real documents (see `50-testing-deployment.mdc`)

#### "I need to modify the ISO build"
1. Review `10-kiwi-architecture.mdc` for layer rules
2. System packages go in `config.kiwi.xml` (Layer 1)
3. First-boot automation in systemd units (Layer 2)
4. User scripts in `scripts/` (Layer 3)
5. Test with `./tools/kiwi-build.sh`

---

## Anti-Pattern Quick Reference

### ❌ Forbidden

**Container Runtime:**
- Using Podman commands or syntax
- Using `--device nvidia.com/gpu=` syntax
- Creating Podman-related files

**TeX Live:**
- Using scheme-full
- Recommending full TeX installation
- Exceeding 3GB for TeX

**Architecture:**
- Placing Docker setup in first-boot
- Running user scripts as systemd units
- Mixing layer responsibilities

**Packages:**
- Using Ubuntu/Debian package names
- Inventing non-existent packages
- Installing system packages via Nix

---

## ✅ Required Patterns

**Container Runtime:**
- Docker only
- `--gpus all` for GPU access
- Automatic Podman removal

**TeX Live:**
- `texlive.combined.scheme-medium`
- ~2GB size
- Stable on openSUSE Leap

**Architecture:**
- Respect 4-layer separation
- Scripts in `scripts/`
- User setup in Layer 3

**Packages:**
- Verify before suggesting
- Use openSUSE package names
- Match package to layer

---

## Enforcement

### Pre-Commit
- Review relevant rules for changed files
- Verify package names
- Check syntax (Docker, TeX, Nix)
- Update documentation

### During Development
- Reference rules when uncertain
- Cross-check against anti-patterns
- Verify layer assignments
- Test changes incrementally

### Code Review
- Check compliance with rules
- Verify documentation updated
- Ensure tests planned/executed
- Validate package choices

---

## Updating Rules

### When to Update:
- New anti-patterns discovered
- Architecture changes
- Policy clarifications needed
- Best practices emerge

### How to Update:
1. Identify pattern requiring formalization
2. Add to appropriate rule file
3. Update this index
4. Document in daily summary
5. Test with real scenarios

---

## Getting Help

### If Rules Conflict:
1. Core rules (00-style-canon) take precedence
2. Specific rules (20-60) override general guidance
3. Document conflict in daily summary
4. Propose resolution in next session

### If Rules Are Unclear:
1. Check examples in rule files
2. Review related documentation
3. Test in isolation
4. Document findings in daily summary

---

## Version History

### v0.3.0 (Current)
- Initial comprehensive rule set
- Covers all major patterns and anti-patterns
- Enforces Docker-only policy
- Mandates TeX scheme-medium
- Defines 4-layer architecture

---

## Files Overview

```
.cursor/rules/
├── 00-style-canon.mdc           # Universal prohibitions
├── 05-project-overview.mdc      # High-level context
├── 10-kiwi-architecture.mdc     # 4-layer architecture
├── 20-nix-home-manager.mdc      # Nix patterns
├── 30-container-runtime.mdc     # Docker + NVIDIA
├── 40-documentation.mdc         # Docs governance
├── 50-testing-deployment.mdc    # Testing requirements
├── 60-package-management.mdc    # Package policies
└── RULES_INDEX.md               # This file
```

---

## Usage with AI Assistants

### Initial Context:
When starting a new session, reference:
1. `RULES_INDEX.md` (this file)
2. `00-style-canon.mdc` (core prohibitions)
3. Relevant specific rule for the task

### During Development:
- AI should reference rules proactively
- Flag potential violations before suggesting code
- Verify package names before proposing additions
- Check layer assignment before placing files

### Before Committing:
- Review all applicable rules
- Verify no anti-patterns introduced
- Check documentation updated
- Plan testing approach

---

## Success Metrics

Rules are effective when:
- ✅ No Podman references in new code
- ✅ No TeX scheme-full suggestions
- ✅ Correct layer assignment for new features
- ✅ Valid package names only
- ✅ Daily summaries maintained
- ✅ Tests planned before hardware deployment
- ✅ Documentation kept current

---

**Remember**: These rules exist to prevent hallucinations and maintain consistency. When in doubt, check the rules first.