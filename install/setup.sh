#!/bin/bash
# Runs every installer in this folder by running each subfolder's setup.sh.
# Drop a new <name>/setup.sh in here and it gets picked up automatically
# (subfolders run in alphabetical order; each is independent).
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"

for sub in "$DIR"/*/; do
  [[ -f "$sub/setup.sh" ]] || continue
  name="$(basename "$sub")"
  echo "--- install: $name ---"
  bash "$sub/setup.sh"
  echo ""
done
