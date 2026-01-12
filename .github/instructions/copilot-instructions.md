# GitHub Copilot Instructions — Global Baseline

> Updated 2026-01-12.  
> This file is intentionally **short**. Detailed, area‑specific guidance lives in **`.github/instructions/*.instructions.md`** with `applyTo:` globs. Copilot should prefer the most specific applicable instructions.

## Quick Reference: Critical Rules

### KIWI NG Configuration
- Config file MUST be named `config.xml` (NOT `config.kiwi.xml`)
- Package elements MUST use `<package name="..."/>` (NOT text content)
- `<description>` MUST include `<contact>` element
- Do NOT use `<files>` element (use `root/` overlay directory instead)
- Do NOT use `hybrid` attribute on ISO type (use `mediacheck` instead)

### Container Runtime
- Use Docker ONLY (NO Podman, NO CDI syntax)
- GPU access: `docker run --gpus all` (NOT `--device nvidia.com/gpu=`)

### TeX Live
- Use `scheme-medium` ONLY (NOT `scheme-full`)

### Build Environment
- Build on native openSUSE VM (NOT Docker on VMware Fusion)
- For x86_64 ISO from ARM64 host: use `kiwi-ng system boxbuild --x86_64`

## Scope & Precedence
- Use **path‑scoped instruction files** when present (they reflect the source `.cursor/rules/*` verbatim).  
- This global file covers only cross‑cutting norms that apply everywhere.
- **Skills** in `.github/skills/` provide task-specific guidance (schema validation, driver installation, etc.)

## Cross‑Cutting Norms
1. **Security & Secrets**
   - Never commit secrets, tokens, or private keys. Redact examples. Prefer env/secret managers over inline values.
   - Default to least privilege; avoid enabling telemetry by default.

2. **Reproducibility**
   - Prefer pinned versions and lockfiles. Avoid `curl | bash` style installers.
   - Scripts should be **idempotent**, safe, and explicit. For POSIX shell: start with `set -euo pipefail` and document required tools.

3. **Consistency > Cleverness**
   - Match existing patterns and directory structure. Keep changes minimal, maintainable, and well‑commented.
   - Use clear naming, small functions, and predictable behavior.

4. **Documentation**
   - When adding or changing behavior, update `README.md` or `docs/` with: purpose, dependencies, setup steps, and rollback hints.
   - Prefer examples that can be copy‑pasted and run deterministically.

5. **Quality Gates**
   - Respect existing hooks/CI. Ensure changes pass formatters, linters, and tests defined by the repo (e.g., Lefthook, workflows under `.github/workflows/`).

6. **Privacy & Networking**
   - Favor local/offline‑first defaults where reasonable. Expose only necessary ports/permissions. Avoid phone‑home behavior.

## Don’t Do
- Don’t restructure the repository or edit `.cursor/rules/*` unless explicitly asked.
- Don’t introduce unpinned dependencies or hidden global state.
- Don’t add new external services without docs and a clear rollback path.

## Path‑Scoped Rules (Authoritative)
The following instruction files mirror the project’s canonical rules and should be treated as **authoritative** within their paths:
- `00-style-canon.instructions.md` (global style)
- `05-project-overview.instructions.md` (project context)
- `10-kiwi-architecture.instructions.md` (KIWI build/profiles/tools/scripts)
- `20-nix-home-management.instructions.md` (Nix & Home Manager)
- `25-lefthook-quality.instructions.md` (hooks & quality gates)
- `30-container-runtime.instructions.md` (containers & compose)
- `40-documentation.instructions.md` (docs & markdown)
- `50-testing-deployment.instructions.md` (testing/CI/CD)
- `55-networking-privacy.instructions.md` (networking/privacy configs)
- `60-package-management.instructions.md` (package managers & manifests)

> If guidance appears to conflict, **favor the most specific path‑scoped file** for the code you’re editing, then align global norms where possible.
