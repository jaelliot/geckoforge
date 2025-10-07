#!/usr/bin/env bash
set -euo pipefail

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

find "$SCRIPT_ROOT" -type f -name "*.sh" -print0 | while IFS= read -r -d '' file; do
  chmod +x "$file"
  echo "✓ chmod +x $file"
done

echo "All shell scripts are now executable."
