#!/usr/bin/env bash
set -euo pipefail

if lspci | grep -qi 'VGA.*NVIDIA'; then
  echo "[geckoforge] NVIDIA GPU detected; installing driver..."
  zypper -n ref || true
  # Prefer signed/open if available, fallback to proprietary G06 meta
  if zypper -n se -x nvidia | grep -q 'nvidia-open-driver-G06'; then
    zypper -n in --recommends nvidia-open-driver-G06-signed || true
  fi
  if ! command -v nvidia-smi >/dev/null 2>&1; then
    zypper -n in --recommends nvidia-driver-G06 || true
  fi
  echo "[geckoforge] Driver install attempted. Reboot may be required."
else
  echo "[geckoforge] No NVIDIA GPU detected; skipping driver install."
fi
