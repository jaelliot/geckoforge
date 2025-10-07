#!/usr/bin/env bash
set -euo pipefail
PROFILE="${1:-profiles/leap-15.6/kde-nvidia}"

mkdir -p out work
RUNCMD=$(command -v podman || command -v docker)
IMG="registry.opensuse.org/opensuse/kiwi-ng/containerfile:latest"

$RUNCMD pull "$IMG"
$RUNCMD run --rm -it \
  -v "$PWD/$PROFILE":/build/desc:ro \
  -v "$PWD/out":/build/out \
  -v "$PWD/work":/build/work \
  "$IMG" \
  kiwi-ng --color output --type iso --description /build/desc --target-dir /build/out --temp-dir /build/work
