<!-- docs/templates/implementation-prom4.  **Verify & Document**:
    *   **CONFIRM** the change works via automated checks and targeted manual validation (KIWI build tests, Nix evaluations, script syntax).
    *   **NOTE**: Full validation requires building and testing the ISO, which may be deferred for complex changes.
    *   **UPDATE** the relevant documentation (guides, templates, README, testing plan) to match the new ISO behavior.
    *   When adding or modifying Markdown, Nix, or shell files, **follow the mandatory header guidance in `40-documentation.mdc`**.
    *   As the final step, ✅ **APPEND** a comprehensive entry to `docs/daily-summaries/YYYY-MM/YYYY-MM-DD.md` (today's date).
    *   Finally, **OUTPUT** a Conventional Commit message (see `.cursor/rules/25-lefthook-quality.mdc` → "Commit message generation") in this format:-->
<!-- @file docs/templates/implementation-prompt.md -->
<!-- @description Task-oriented template for geckoforge implementation sessions -->
<!-- @update-policy Update this header only when documentation scope or target audience materially changes. -->

## ✅ PROMPT: **Code Implementation Prompt Template (Per-Task Execution)**

> 🛠️ **Purpose**: Used by a build-focused AI to execute a single geckoforge remediation or enhancement task derived from the planning prompt.
> 🚨 **STRICT EXECUTION ENFORCEMENT**: Must produce real changes and log them in the active daily summary.

---

# 🧪 IMPLEMENTATION PROMPT

## **⚠️ CRITICAL IMPLEMENTATION INSTRUCTION**

This is an **action-oriented implementation task** for the **geckoforge KIWI image builder**. Follow this execution flow precisely:

**🦎 KIWI CONTEXT**: We are configuring openSUSE KIWI NG to build a custom distribution ISO, not implementing directly against a live system. Changes modify:
- KIWI profile configurations (`profiles/leap-15.6/kde-nvidia/`)
- Home-Manager modules (`home/modules/`) 
- User setup scripts (`scripts/`)
- Build and validation tools (`tools/`)

The resulting configuration will be **built into an ISO** that users install, not applied to an existing openSUSE system.

You are running on a Windows development machine without Nix installed. All Nix code should be syntactically correct but validation will happen when the ISO is built and deployed on the target Linux system. Focus on proper Nix syntax and Home-Manager patterns from the existing codebase.

1.  **Plan & Structure**:
    *   Briefly outline your implementation plan. Organize work into numbered batches for major steps and lettered sub-batches for granular tasks (e.g., 1a, 1b, 2a).
    *   Use artifacts to keep batches small and auditable; avoid mega-drops that span multiple layers simultaneously.

2.  **Review & Amend Rules**:
    *   Before coding, review `.cursor/rules/` (especially `00-style-canon.mdc`, `10-kiwi-architecture.mdc`, `20-nix-home-management.mdc`, `25-lefthook-quality.mdc`, and `30-container-runtime.mdc`) for constraints.
    *   If any rule conflicts with the task, propose the smallest possible amendment and **wait for explicit approval** before editing code or docs.

3.  **Implement Code & Tests**:
    *   Once the plan (and any rule adjustments) are approved, **MODIFY** the target KIWI configuration files, Home-Manager modules, or setup scripts with correct, working code.
    *   **REMEMBER**: Changes affect the ISO build process and resulting distribution, not the current development system.
    *   **IMPLEMENT** matching tests or verification scripts (e.g., shell smoke tests, Nix evaluations, KIWI validation) to prevent regressions.

4.  **Verify & Document**:
    *   **CONFIRM** the change works via automated checks and targeted manual validation.
    *   **UPDATE** the relevant documentation (guides, templates, README, testing plan) to match behavior.
    *   When adding or modifying Markdown, Nix, or shell files, **follow the mandatory header guidance in `40-documentation.mdc`**.
    *   As the final step, ✅ **APPEND** a comprehensive entry to `docs/daily-summaries/YYYY-MM/YYYY-MM-DD.md` (today’s date).
    *   Finally, **OUTPUT** a Conventional Commit message (see `.cursor/rules/25-lefthook-quality.mdc` → “Commit message generation”) in this format:

  ```
  <type>(<scope>): <concise subject>

  - <area/file>: <what changed>
  - ...
  ```
  Only emit after all validations pass.

---

## 🏷️ TASK: \[TASK TITLE]

### 📌 Context

Brief overview of current violation or improvement target and its location in the geckoforge KIWI configuration. 

**🏗️ Build Context**: Specify which layer of the 4-layer architecture is affected:
- **Layer 1 (ISO)**: KIWI profile packages, repositories, file overlays
- **Layer 2 (First-Boot)**: systemd units, driver installation, Nix setup  
- **Layer 3 (User Setup)**: Docker installation, NVIDIA toolkit, Flatpaks
- **Layer 4 (Home-Manager)**: User packages, dotfiles, development environments

---

## 🛠️ Implementation Requirements

### Step 1: \[Action Title]

**File(s):** `[scripts/setup-docker.sh]`, `[home/modules/development.nix]`, ...

**Required Change:**
\[Concise description of what needs to change in the KIWI configuration, Home-Manager modules, or setup scripts and why]

**Implementation Details:**
```bash
# Provide runnable code for the target environment (ISO users, not development system)
# Example: User setup script content
sudo zypper install -y docker docker-compose
sudo systemctl enable --now docker
```

**Key Requirements:**

* Respect the four-layer architecture (ISO → First-Boot → User Setup → Home-Manager).
* **Target Environment**: Code runs in the built ISO or on systems installed from the ISO, not the development machine.
* Follow `.cursor/rules/` for style, layering, quality gates, and package sourcing.
* Reuse existing helpers (e.g., shared shell functions, Nix modules) when available.
* Document assumptions and note any deferred work in follow-ups.

---

## ✅ Verification Steps

After completing the KIWI configuration implementation:

1. [ ] Run `lefthook run pre-commit` (fast gates: shell syntax, Nix eval, markdown lint, etc.).
2. [ ] Validate shell scripts with `bash -n` (and `shellcheck` when available); document if tooling is missing.
3. [ ] Evaluate Nix changes (`nix eval .#homeConfigurations.<user>.activationPackage` or `home-manager switch --flake ./home --dry-run`).
4. [ ] **KIWI Validation**: If KIWI assets changed, run `./tools/kiwi-build.sh profiles/leap-15.6/kde-nvidia` to test ISO build or record why it was deferred.
5. [ ] For Docker/NVIDIA changes, run `scripts/docker-nvidia-verify.sh` or an equivalent GPU-enabled test (may require ISO installation for full validation).
6. [ ] Manually sanity-check the configuration (e.g., review KIWI XML, test Home-Manager evaluation, verify script logic).
7. [ ] Append a detailed changelog entry to `docs/daily-summaries/YYYY-MM/YYYY-MM-DD.md`:

```
✅ 2025-10-10: [Task Title] – Implemented [concise summary] in [path/to/file]
```

---

## 🧪 Testing Requirements

### Functional Tests

* [ ] Describe behavioral verification for the target environment (ISO build success, Home-Manager evaluation, script execution in built ISO).
* [ ] Provide unit or integration tests when business logic is non-trivial (e.g., shell functions, Nix modules with assertions).
* [ ] **Note**: Some tests may require building and installing the ISO for full validation.

### Edge Cases

* [ ] Account for first-run vs. repeat-run scenarios in the built ISO (idempotency).
* [ ] Consider offline install paths and missing GPU hardware in target systems.
* [ ] Validate behavior when optional dependencies (Flatpak, shellcheck) are absent on target systems.
* [ ] Ensure changes respect layer boundaries and do not regress other layers in the built ISO.

---

## 📂 Files to Modify

**Primary Files:**

* `profiles/leap-15.6/kde-nvidia/config.kiwi.xml` (ISO layer packages/config)
* `profiles/leap-15.6/kde-nvidia/scripts/firstboot-*.sh` (first-boot automation)
* `scripts/<task>.sh` (user setup scripts)
* `home/modules/<domain>.nix` (Home-Manager configuration)

**Supporting Files:**

* `docs/<relevant-guide>.md`
* `docs/daily-summaries/YYYY-MM/YYYY-MM-DD.md`
* `tools/<supporting-script>.sh` (build/validation tools)

**Instruction:**
Review neighboring files for consistency (e.g., other scripts in the same layer, related Nix modules, corresponding documentation). Remember that changes affect the **built ISO behavior**, not the development system.

---

## 🧭 Priority

* Priority: \[Critical | High | Medium | Low]
* Expected Completion Time: \[e.g. \~30 minutes]

---

## 🚨 Reminder

You MUST:

* Modify actual code
* Skip no required logic
* Avoid inserting TODOs or placeholder comments
* Record validation steps and append the changelog entry only after successful verification