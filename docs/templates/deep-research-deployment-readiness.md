<!-- Copyright (c) Vaidya Solutions -->
<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- -->
<!-- docs/templates/deep-research-deployment-readiness.md -->
<!-- @file docs/templates/deep-research-deployment-readiness.md -->
<!-- @description Deep research prompt for pre-deployment validation of geckoforge KIWI image builder -->
<!-- @update-policy Update when deployment workflow, layer architecture, or critical validation steps change -->

# 🧠 GECKOFORGE DEPLOYMENT READINESS RESEARCH

## 🔍 CRITICAL RESEARCH INSTRUCTION

This is a **pre-deployment research and validation task.** Your primary function is to thoroughly audit the geckoforge codebase, identify bugs, architectural violations, configuration errors, and deployment blockers before attempting laptop installation. **Code fixes will be implemented after this research identifies all issues.**

Your analysis should reference the project's architectural rules (`.github/instructions/*.instructions.md`), validate against openSUSE Leap 15.6 compatibility, verify Nix syntax, and ensure layer boundary compliance.

---

## 1. Primary Objective

**Conduct a comprehensive pre-deployment audit of the geckoforge KIWI image builder project to identify and document all bugs, configuration errors, architectural violations, and deployment blockers before deploying to an MSI laptop.**

**Success Criteria:**
- Zero shell syntax errors across all scripts
- All Nix expressions validate successfully
- No layer boundary violations
- All package names verified against openSUSE Leap 15.6 repositories
- KIWI configuration passes XML validation
- Docker-only syntax enforced (no Podman references)
- TeX Live scheme-medium verified
- Hardware compatibility confirmed for target laptop

---

## 2. Context & Scope

### Current Situation

**Project:** geckoforge - Custom openSUSE Leap 15.6 distribution built with KIWI NG

**Purpose:** "Configure once, avoid BS forever" - Reproducible, production-grade KDE Plasma development workstation targeting NVIDIA GPU systems

**Technology Stack:**
- **Base OS:** openSUSE Leap 15.6 (stable, 18-month cycle)
- **Desktop:** KDE Plasma 5
- **Filesystem:** Btrfs + Snapper (snapshots)
- **Build System:** KIWI NG (image builder)
- **Package Management:** 3-layer (zypper/Nix/Flatpak)
- **Container Runtime:** Docker (NOT Podman)
- **User Environment:** Nix + Home-Manager
- **Development:** Multi-language (Python, Go, TypeScript, Elixir, etc.)

**Current Pain Points:**
- Never tested on real hardware (VM only)
- No comprehensive validation pass before deployment
- Potential layer boundary violations
- Unknown package availability issues on Leap 15.6
- FreeRDP version uncertainty for WinApps
- Untested first-boot automation
- Unknown hardware compatibility with target MSI laptop

### Desired Future State / Goals

**Primary Goal:** Deploy geckoforge to MSI laptop successfully on first attempt with zero manual intervention required after ISO boot.

**Key Success Metrics:**
- ✅ ISO builds without errors
- ✅ Installation completes successfully
- ✅ First-boot scripts execute without failures
- ✅ NVIDIA driver installs automatically (if GPU present)
- ✅ Nix + Home-Manager activate successfully
- ✅ Docker + NVIDIA Container Toolkit work on first launch
- ✅ All user setup scripts execute without errors
- ✅ System responsive and stable after setup

### In-Scope Files

**CRITICAL - All files in the following directories:**
- `profiles/leap-15.6/kde-nvidia/` - KIWI profile and first-boot scripts
- `home/` - All Home-Manager Nix modules
- `scripts/` - All user setup scripts
- `.github/instructions/` - Architectural rules and guidelines
- `docs/guides/` - User-facing documentation

**Specifically Review:**
- `profiles/leap-15.6/kde-nvidia/config.kiwi.xml` - Package lists, repos
- All shell scripts in `profiles/.../scripts/` and `scripts/`
- All `.nix` files in `home/modules/`
- `home/home.nix` and `home/flake.nix`
- `scripts/firstrun-user.sh` - Primary user setup orchestrator
- Recently added: `scripts/setup-winapps.sh`, `home/modules/winapps.nix`

### Architectural Guidelines (CRITICAL)

**All recommendations MUST strictly adhere to geckoforge's 4-layer architecture and zero-tolerance anti-patterns.**

#### Four-Layer Architecture (MANDATORY)

```
┌─────────────────────────────────────┐
│ Layer 4: Home-Manager (Nix)        │  ~/.config, user packages
│ User environment, dev toolchains   │  Declarative, version-pinned
└─────────────────────────────────────┘
                  ↑
┌─────────────────────────────────────┐
│ Layer 3: User Setup (scripts/)     │  Docker, NVIDIA Toolkit, Flatpaks
│ Post-install automation            │  Interactive, opt-in features
└─────────────────────────────────────┘
                  ↑
┌─────────────────────────────────────┐
│ Layer 2: First-Boot (systemd)      │  NVIDIA driver, Nix installer
│ One-shot system configuration      │  Automated, root-level
└─────────────────────────────────────┘
                  ↑
┌─────────────────────────────────────┐
│ Layer 1: ISO (KIWI profile)        │  Base OS, repositories, themes
│ Immutable system image             │  Reproducible builds
└─────────────────────────────────────┘
```

**Layer Responsibilities:**
- **Layer 1 (ISO):** Base packages (kernel, NetworkManager, KDE), repos, file overlays
- **Layer 2 (First-Boot):** NVIDIA driver install, Nix daemon setup (root, one-time)
- **Layer 3 (User Setup):** Docker, NVIDIA Container Toolkit, Flatpaks (user context, manual)
- **Layer 4 (Home-Manager):** User packages, dev tools, desktop config (declarative, repeatable)

**FORBIDDEN Layer Violations:**
- ❌ Docker in Layer 2 (requires user group membership)
- ❌ User-specific config in Layer 1 or 2
- ❌ Root-level operations in Layer 3 or 4
- ❌ System packages in Layer 4 (use Layer 1)

#### Zero-Tolerance Anti-Patterns

**Container Runtime:**
- ❌ FORBIDDEN: `podman`, `--device nvidia.com/gpu=`, CDI syntax, Podman references
- ✅ REQUIRED: `docker`, `--gpus all` for NVIDIA access

**TeX Live:**
- ❌ FORBIDDEN: `texlive.combined.scheme-full`, "complete TeX installation"
- ✅ REQUIRED: `texlive.combined.scheme-medium` (2GB, stable on Leap 15.6)

**Package Management:**
- ❌ FORBIDDEN: `apt-get`, `apt install`, `yum`, `dnf`, `pacman` (wrong distro commands)
- ✅ REQUIRED: `zypper` (openSUSE system), `nix` (Home-Manager), `flatpak` (sandboxed GUI)

**Script Requirements:**
- ✅ All scripts in `scripts/` must be executable (`chmod +x`)
- ✅ All scripts must pass `bash -n` (syntax validation)
- ✅ First-boot scripts go in `profiles/.../scripts/firstboot-*.sh`
- ✅ User scripts go in `scripts/*.sh`

**Home-Manager Module Requirements:**
- ✅ Core modules in `home/modules/*.nix`
- ✅ All modules imported in `home/home.nix`
- ✅ Flake pins nixpkgs to stable release (24.05)
- ✅ `home.stateVersion` never changes after initial setup

#### Target Hardware Context

**MSI Laptop (from provided screenshot):**
- Model: Unknown (extract from barcode if possible: `BCFH-001`, `ISM2SNUS1`)
- Likely specs: NVIDIA GPU (based on kde-nvidia profile), modern CPU
- **Critical Unknowns:**
  - GPU model (GTX? RTX? Quadro?)
  - RAM amount (minimum 8GB, ideally 16GB+)
  - CPU (Intel/AMD, generation)
  - Storage type/size (NVMe? SATA? capacity?)
  - Display resolution (impacts RDP scaling for WinApps)

**Deployment Assumptions:**
- UEFI boot (Secure Boot disabled during install)
- Single OS installation (no dual-boot)
- Full disk encryption (LUKS2) will be enabled
- Network connectivity available during install
- User will run `firstrun-user.sh` after first boot

---

## 3. Core Research Areas

### 3.1. KIWI Configuration Validation

**Objective:** Verify `config.kiwi.xml` is valid, all packages exist, and repos are accessible.

**Key Activities:**
1. **XML Validation:**
   - Verify `config.kiwi.xml` passes `xmllint --noout`
   - Check for malformed XML, unclosed tags, invalid structure
   - Verify all `<package>` elements have valid names

2. **Package Availability:**
   - Cross-reference all `<package>` entries against openSUSE Leap 15.6 repos
   - Verify NVIDIA packages are available (`nvidia-open-driver-G06-signed`)
   - Check KDE Plasma 5 packages (`plasma5-desktop`, etc.)
   - Validate system tools (`snapper`, `btrfs-progs`, `NetworkManager`)
   - Flag any invented/non-existent packages

3. **Repository Configuration:**
   - Verify all `<repository>` sources are reachable
   - Check openSUSE mirror URLs are valid
   - Validate NVIDIA repository configuration
   - Ensure no Ubuntu/Debian repos are referenced

4. **File Overlays:**
   - Verify all files in `root/` directory have correct paths
   - Check systemd units have proper syntax
   - Validate file permissions are set correctly

**Expected Output:**
- List of invalid packages (if any)
- List of unreachable repositories (if any)
- XML validation errors (if any)
- Recommended fixes for each issue

---

### 3.2. First-Boot Script Validation (Layer 2)

**Objective:** Ensure all first-boot scripts execute successfully and comply with layer boundaries.

**Key Activities:**
1. **Script Syntax:**
   - Run `bash -n` on all `profiles/.../scripts/firstboot-*.sh`
   - Check for syntax errors, unquoted variables, missing error handling
   - Verify `set -euo pipefail` is present in all scripts

2. **Layer Boundary Compliance:**
   - Verify NO Docker installation/configuration in first-boot
   - Verify NO user-specific operations (`$USER`, `~`, user groups)
   - Verify NO commands requiring user interaction
   - Confirm only root-level, one-time setup (NVIDIA, Nix daemon)

3. **NVIDIA Driver Logic:**
   - Verify GPU detection logic is robust
   - Check driver installation doesn't require user input
   - Validate fallback behavior if no GPU detected

4. **Nix Installation:**
   - Verify multi-user (daemon) installation is used
   - Check `/etc/nix/nix.conf` configuration is correct
   - Validate systemd service activation

5. **Systemd Integration:**
   - Verify all `.service` files have correct syntax
   - Check systemd unit activation links are correct
   - Validate service dependencies and ordering

**Expected Output:**
- List of syntax errors (if any)
- List of layer violations (if any)
- Recommended fixes for each script
- Potential runtime failures to address

---

### 3.3. User Setup Script Validation (Layer 3)

**Objective:** Ensure all user setup scripts execute successfully and handle errors gracefully.

**Key Activities:**
1. **Script Syntax:**
   - Run `bash -n` on all `scripts/*.sh`
   - Check for syntax errors, unquoted variables, logic bugs
   - Verify `set -euo pipefail` is present

2. **Dependency Checks:**
   - Verify scripts check for required dependencies before running
   - Validate Docker is running before Docker-dependent operations
   - Check Nix is available before Home-Manager operations

3. **Docker Setup (`setup-docker.sh`):**
   - Verify Podman removal logic is correct
   - Check Docker installation uses correct package names
   - Validate user group addition (`usermod -aG docker`)
   - Confirm service enablement is correct

4. **NVIDIA Container Toolkit (`docker-nvidia-install.sh`):**
   - Verify NVIDIA driver is checked before proceeding
   - Check repository URL is valid
   - Validate `nvidia-ctk` configuration is correct
   - Verify GPU verification test is robust

5. **WinApps Setup (`setup-winapps.sh`):**
   - Verify dependency installation (dialog, freerdp, netcat-openbsd)
   - Check FreeRDP version detection logic
   - Validate WinApps installer invocation
   - Verify configuration file creation and permissions

6. **First-Run Orchestrator (`firstrun-user.sh`):**
   - Verify correct order of operations
   - Check error handling between steps
   - Validate optional prompts work correctly
   - Confirm final instructions are accurate

**Expected Output:**
- List of syntax errors (if any)
- List of logic bugs (if any)
- Missing error handling cases
- Recommended improvements for robustness

---

### 3.4. Home-Manager Nix Configuration Validation (Layer 4)

**Objective:** Ensure all Nix expressions validate, packages exist, and Home-Manager activates successfully.

**Key Activities:**
1. **Nix Syntax Validation:**
   - Run `nix-instantiate --parse` on all `.nix` files
   - Check for syntax errors, unterminated strings, invalid attributes
   - Verify `with lib;` usage is correct

2. **Package Availability:**
   - Cross-reference all `pkgs.*` references against nixpkgs 24.05
   - Verify custom packages are properly defined
   - Check for invented/non-existent packages
   - Validate TeX Live `scheme-medium` (not `scheme-full`)

3. **Module Structure:**
   - Verify all modules follow Home-Manager patterns
   - Check imports in `home/home.nix` are complete
   - Validate module options are properly defined
   - Verify no conflicting file definitions

4. **Flake Configuration (`flake.nix`):**
   - Verify nixpkgs is pinned to stable (24.05)
   - Check `allowUnfree = true` is set
   - Validate flake inputs are reachable
   - Verify `homeConfigurations` is correct

5. **Application Configuration:**
   - Check Chromium extensions are valid IDs
   - Verify Firefox settings are correct
   - Validate Kitty terminal config
   - Check KDE Night Color settings

6. **WinApps Module (`winapps.nix`):**
   - Verify WinApps flake is reachable
   - Check builtins.fetchGit syntax is correct
   - Validate config file generation
   - Verify package references are correct

7. **Layer Compliance:**
   - Verify NO system packages in Home-Manager
   - Check NO root-level operations
   - Validate NO Docker installation attempts

**Expected Output:**
- List of Nix syntax errors (if any)
- List of non-existent packages (if any)
- Module structure issues (if any)
- Recommended fixes for each error

---

### 3.5. Documentation Accuracy

**Objective:** Ensure all user-facing documentation matches actual implementation.

**Key Activities:**
1. **Command Verification:**
   - Verify all example commands in `docs/guides/*.md` are correct
   - Check file paths referenced in docs exist
   - Validate script names match actual files

2. **Feature Parity:**
   - Verify README features match implemented functionality
   - Check guides cover all setup steps
   - Validate troubleshooting sections address real issues

3. **Consistency:**
   - Check Docker syntax is correct throughout (no Podman)
   - Verify TeX Live references use `scheme-medium`
   - Validate layer architecture descriptions are accurate

**Expected Output:**
- List of documentation errors (if any)
- Outdated or incorrect instructions
- Missing documentation for new features

---

### 3.6. Hardware Compatibility Assessment

**Objective:** Identify potential hardware-specific issues for MSI laptop deployment.

**Key Activities:**
1. **NVIDIA Driver Compatibility:**
   - Verify `nvidia-open-driver-G06-signed` supports likely GPU models
   - Check driver version is compatible with modern RTX/GTX cards
   - Validate fallback behavior for unsupported GPUs

2. **Laptop-Specific Concerns:**
   - Check for missing power management tools (TLP, laptop-mode-tools)
   - Verify suspend/resume logic for NVIDIA
   - Check WiFi driver availability
   - Validate touchpad configuration

3. **Display Scaling:**
   - Check KDE DPI settings for potential HiDPI display
   - Verify Night Color and WinApps scaling options
   - Validate display manager configuration

4. **Resource Requirements:**
   - Verify ISO build size is reasonable
   - Check installed system size estimate
   - Validate RAM requirements (8GB minimum, 16GB recommended)
   - Confirm disk space requirements (50GB minimum)

**Expected Output:**
- List of potential hardware incompatibilities
- Recommended laptop-specific configurations
- Missing drivers or tools to add

---

### 3.7. Anti-Pattern Detection

**Objective:** Identify all violations of zero-tolerance anti-patterns.

**Key Activities:**
1. **Podman References:**
   - Grep all files for `podman`, `--device nvidia.com/gpu=`, `cdi`
   - Check for Podman-related configuration files
   - Verify no Podman commands in scripts or docs

2. **TeX Live Violations:**
   - Grep for `scheme-full`, `texlive-full`
   - Verify only `scheme-medium` is used
   - Check documentation doesn't recommend full installation

3. **Wrong Package Manager:**
   - Grep for `apt-get`, `apt install`, `yum`, `dnf`, `pacman`
   - Verify only `zypper`, `nix`, `flatpak` are used
   - Check no Ubuntu/Debian patterns exist

4. **Layer Boundary Violations:**
   - Check for Docker in Layer 2 (first-boot)
   - Verify no user operations in Layer 1 or 2
   - Check no root operations in Layer 3 or 4

**Expected Output:**
- Complete list of anti-pattern violations
- File and line number for each violation
- Recommended fixes for each

---

### 3.8. Deployment Readiness Checklist

**Objective:** Create a comprehensive pre-deployment checklist.

**Key Activities:**
1. **Build Validation:**
   - Verify ISO builds without errors
   - Check ISO size is reasonable
   - Validate ISO is bootable (if VM test available)

2. **Installation Validation:**
   - Verify installer prompts are clear
   - Check encryption setup works
   - Validate user creation process

3. **First-Boot Validation:**
   - Check all systemd services activate
   - Verify NVIDIA driver installs successfully
   - Validate Nix daemon starts correctly

4. **User Setup Validation:**
   - Check `firstrun-user.sh` completes successfully
   - Verify Docker installation works
   - Validate GPU access in containers
   - Check Home-Manager activates

5. **Post-Setup Validation:**
   - Verify system boots successfully after setup
   - Check all applications launch
   - Validate GPU acceleration works
   - Confirm network connectivity

**Expected Output:**
- Complete deployment readiness checklist
- List of blocking issues (must fix before deploy)
- List of non-blocking issues (nice to fix)
- Recommended deployment procedure

---

## 4. Compliance Verification

### Required Check

**Before finalizing recommendations, verify compliance with architectural rules:**

```bash
# Check all instruction files
cat .github/instructions/00-style-canon.instructions.md
cat .github/instructions/10-kiwi-architecture.instructions.md
cat .github/instructions/20-nix-home-management.instructions.md
cat .github/instructions/25-lefthook-quality.instructions.md
cat .github/instructions/30-container-runtime.instructions.md
```

### Verification Checklist

For each issue found, verify:

- [ ] **Container Runtime:** Does NOT use Podman syntax
- [ ] **TeX Live:** Uses scheme-medium, NOT scheme-full
- [ ] **Package Management:** Uses correct distro commands (zypper/nix/flatpak)
- [ ] **Layer Boundaries:** Respects 4-layer architecture
- [ ] **Script Location:** User scripts in `scripts/`, first-boot in `profiles/.../scripts/`
- [ ] **Nix Modules:** Follow Home-Manager patterns
- [ ] **Documentation:** Matches implementation
- [ ] **Hardware Compatibility:** Considers laptop deployment

### Compliance Matrix

| Issue | Instruction File | Severity | Blocks Deployment? | Fix Complexity |
|-------|-----------------|----------|-------------------|----------------|
| Example: Podman in docs | 30-container-runtime.instructions.md | Critical | No | Low (find/replace) |
| Example: Docker in Layer 2 | 10-kiwi-architecture.instructions.md | Critical | Yes | High (refactor) |
| Example: Missing package | 00-style-canon.instructions.md | High | Yes | Medium (verify/replace) |

### Non-Compliant Issues

**If ANY issue violates architectural rules:**

1. **Flag the violation explicitly:**
   ```
   ⚠️ CRITICAL: This violates [instruction file name]
   ```

2. **Explain why it's non-compliant:**
   ```
   Using Podman in setup-docker.sh violates 30-container-runtime.instructions.md.
   This will confuse users and conflicts with Docker-only policy.
   ```

3. **Provide compliant fix:**
   ```
   COMPLIANT FIX:
   - Remove all Podman references
   - Replace with Docker equivalent
   - Update documentation
   ```

4. **Classify severity:**
   - **CRITICAL:** Blocks deployment or causes system failure
   - **HIGH:** Causes feature failure or major UX issue
   - **MEDIUM:** Causes minor UX issue or inconsistency
   - **LOW:** Cosmetic issue or documentation improvement

---

## 5. Expected Output

**Deliverable:** Comprehensive pre-deployment audit report

For each issue found, provide:

### Issue Template

```markdown
## Issue #N: [Brief Description]

**Category:** [KIWI Config / First-Boot / User Setup / Home-Manager / Documentation / Hardware]
**Severity:** [CRITICAL / HIGH / MEDIUM / LOW]
**Blocks Deployment:** [YES / NO]
**Violates:** [Instruction file name, if applicable]

**Problem:**
[Detailed description of the issue]

**Current Code/Config:**
[Code snippet or config showing the problem]

**Impact:**
[What happens if this isn't fixed before deployment]

**Proposed Fix:**
[Clear, actionable fix with code examples]

**Files to Modify:**
- `path/to/file1.ext` - [what to change]
- `path/to/file2.ext` - [what to change]

**Verification:**
[How to verify the fix works]

**Estimated Fix Time:** [5 min / 30 min / 2 hours / etc.]
```

### Report Structure

```markdown
# Geckoforge Pre-Deployment Audit Report

## Executive Summary
- Total issues found: [N]
- Critical (deployment-blocking): [N]
- High priority: [N]
- Medium priority: [N]
- Low priority: [N]

## Deployment Recommendation
[READY / NOT READY / READY WITH CAVEATS]

[If not ready: List of blocking issues that must be fixed]
[If ready with caveats: List of known limitations/workarounds]

## Issues by Category

### 3.1. KIWI Configuration Issues
[List all issues found in this area]

### 3.2. First-Boot Script Issues
[List all issues found in this area]

### 3.3. User Setup Script Issues
[List all issues found in this area]

### 3.4. Home-Manager Configuration Issues
[List all issues found in this area]

### 3.5. Documentation Issues
[List all issues found in this area]

### 3.6. Hardware Compatibility Issues
[List all issues found in this area]

### 3.7. Anti-Pattern Violations
[List all violations found]

## Priority Fix List

### Must Fix Before Deployment (CRITICAL)
1. [Issue #N]: [Brief description] - [Estimated time]
2. [Issue #N]: [Brief description] - [Estimated time]

### Should Fix Before Deployment (HIGH)
1. [Issue #N]: [Brief description] - [Estimated time]
2. [Issue #N]: [Brief description] - [Estimated time]

### Can Fix After Deployment (MEDIUM/LOW)
1. [Issue #N]: [Brief description] - [Estimated time]
2. [Issue #N]: [Brief description] - [Estimated time]

## Deployment Readiness Checklist

- [ ] ISO builds successfully
- [ ] All packages exist in Leap 15.6 repos
- [ ] No Podman references remain
- [ ] TeX Live uses scheme-medium only
- [ ] All scripts pass bash -n syntax check
- [ ] All Nix expressions parse successfully
- [ ] No layer boundary violations
- [ ] Documentation is accurate
- [ ] Hardware compatibility addressed
- [ ] First-boot automation tested
- [ ] User setup scripts tested
- [ ] Home-Manager activation tested

## Recommended Deployment Procedure

1. [Step-by-step deployment plan considering all issues found]
2. [Include validation steps at each stage]
3. [Include rollback procedures]

## Post-Deployment Monitoring

[List of things to monitor/verify after deployment]
```

---

## 6. Final Instructions

### Research Priorities

1. **Focus on deployment blockers first** - Critical issues that will cause failure
2. **Verify syntax before logic** - Catch parse errors before runtime issues
3. **Check package availability early** - Missing packages block ISO build
4. **Validate layer boundaries strictly** - Architecture violations cause cascading issues
5. **Test paths and references** - Broken file paths are easy to miss

### Analysis Depth

- **Be exhaustive for CRITICAL issues** - Missing one blocks entire deployment
- **Be thorough for HIGH issues** - These cause major UX problems
- **Be pragmatic for MEDIUM/LOW** - Document but don't over-analyze

### Tone and Format

- **Be direct and actionable** - Engineer needs clear fixes, not theories
- **Provide code examples** - Show exact changes needed
- **Estimate effort realistically** - Help prioritize fix order
- **Flag assumptions explicitly** - Note where you can't verify without running code

### Scope Boundaries

**IN SCOPE:**
- All configuration files, scripts, and Nix modules
- Documentation accuracy
- Architectural compliance
- Package availability
- Syntax validation

**OUT OF SCOPE:**
- Performance optimization (unless it blocks deployment)
- Feature enhancements (unless required for hardware compatibility)
- UI/UX improvements (unless affecting setup success)
- Code style consistency (unless violating rules)

### Validation Methods

**Use these techniques to validate findings:**

1. **Static Analysis:**
   - `bash -n script.sh` for shell syntax
   - `nix-instantiate --parse file.nix` for Nix syntax
   - `xmllint --noout config.kiwi.xml` for XML validation
   - `grep -r "pattern" .` for anti-pattern detection

2. **Reference Checks:**
   - Cross-reference package names with openSUSE Leap 15.6 repos
   - Verify file paths exist in repository structure
   - Check instruction files for compliance rules

3. **Logical Analysis:**
   - Trace script execution flow
   - Identify missing error handling
   - Check for race conditions or ordering issues

4. **Documentation Cross-Reference:**
   - Verify commands in docs match implementation
   - Check examples are executable
   - Validate file paths are correct

---

## 7. Context-Specific Guidance

### MSI Laptop Deployment Context

**Known from photo:**
- Brand: MSI
- Model codes visible: `BCFH-001`, `ISM2SNUS1`
- Likely has NVIDIA GPU (based on project focus)

**Critical unknowns to address:**
- GPU model (affects driver compatibility)
- Display resolution (affects scaling config)
- RAM amount (affects WinApps VM allocation)
- WiFi chipset (affects driver needs)
- Battery/power management needs

**Laptop-specific checks:**
- Power management tools availability
- Suspend/resume compatibility with NVIDIA
- WiFi driver availability
- Touchpad configuration
- Display scaling for potential HiDPI
- Battery threshold settings (if supported)

### First Deployment Constraints

**This is the first real hardware deployment:**
- No prior testing on actual laptop
- VM testing only validates ISO build
- First-boot automation never tested on hardware
- Unknown hardware-specific issues may arise

**Be conservative:**
- Flag anything that might fail on real hardware
- Recommend validation steps at each stage
- Suggest fallback procedures
- Note known limitations

### Time Sensitivity

**User wants to deploy ASAP:**
- Prioritize deployment blockers ruthlessly
- Group related fixes together
- Provide time estimates for each fix
- Suggest parallel fix strategies where possible

---

## 8. Example Issue (for reference)

```markdown
## Issue #1: Invalid Package Name in KIWI Config

**Category:** KIWI Configuration
**Severity:** CRITICAL
**Blocks Deployment:** YES
**Violates:** 00-style-canon.instructions.md (Package Hallucinations)

**Problem:**
Package `texlive-full` referenced in `config.kiwi.xml` line 147 does not exist in openSUSE Leap 15.6 repositories. This will cause ISO build failure.

**Current Code:**
```xml
<package>texlive-full</package>
```

**Impact:**
KIWI build will fail immediately with "package not found" error. Cannot create bootable ISO.

**Proposed Fix:**
Remove `texlive-full` entirely. TeX Live is handled by Home-Manager using `texlive.combined.scheme-medium` (as per project policy).

**Files to Modify:**
- `profiles/leap-15.6/kde-nvidia/config.kiwi.xml` - Remove line 147

**Verification:**
```bash
# Verify package is removed
grep -n "texlive-full" profiles/leap-15.6/kde-nvidia/config.kiwi.xml
# Should return no results

# Verify KIWI build succeeds
./tools/kiwi-build.sh profiles/leap-15.6/kde-nvidia
```

**Estimated Fix Time:** 2 minutes
```

---

**END OF RESEARCH PROMPT TEMPLATE**

**To use this template:**
1. Feed this entire document to an AI research assistant
2. Ensure the AI has read access to all geckoforge repository files
3. Request the structured audit report as specified in Section 5
4. Review findings and prioritize fixes based on severity
5. Implement critical fixes before deployment attempt
6. Re-run research after fixes to validate
