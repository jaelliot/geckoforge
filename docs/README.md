# 🗂️ Architecture Documentation Helpers

## Feature Flags Overview

The platform uses GO Feature Flag (GOFF) to gate tool availability both at initialization and at runtime:

- Init‑time gating: disabled tools are not registered by the registry
- Runtime gating: already registered tools can be disabled without restart; `InvokeTool` denies calls when disabled

See `docs/feature-flags/README.md` for configuration, hot‑reload behavior, and operational guidance.

This directory holds foundational documentation about the project’s structure and patterns.  
For end-user setup and client configuration, see the User Guide: `../user-guide.md`.
To keep these docs current, run the following commands from the **repository root**.

## 1. Generate an up-to-date directory tree
```bash
# writes docs/directory-tree.md
# (omit heavy or irrelevant paths via -I)
tree -a \
  -I "node_modules|.git|ios|dist|build|.expo|__tests__|*.log|Documentation|coverage|assets|cdk.out|.terraform|cdk.out|docs" \
  -L 7 --dirsfirst \
  > docs/directory-tree.md
```

## 2. Capture a dated snapshot (history of structure changes)
```bash
mkdir -p docs/tree-snapshots

tree -a \
  -I "node_modules|.git|ios|dist|build|.expo|__tests__|*.log|Documentation|coverage|assets|cdk.out|.terraform|cdk.out" \
  -L 7 --dirsfirst \
  > "docs/tree-snapshots/$(date +%Y-%m-%d)-directory-tree.md"
```

Place these commands in your automation scripts or run them manually whenever the directory layout changes.

See also: `docs/layout-policy.md` for guidelines on when to use `cmd/`, `internal/`, and avoiding `pkg/` by default.