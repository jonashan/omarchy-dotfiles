#!/bin/bash
# Patches Omarchy's shell.json in place: lock the screen after 1 minute idle.
# shell.json hot-reloads on save, so no restart is needed.
set -euo pipefail

SHELL_JSON="$HOME/.config/omarchy/shell.json"

if [[ ! -f "$SHELL_JSON" ]]; then
  echo "WARNING: $SHELL_JSON not found"
  exit 0
fi

jq '.idle.lock = 60' "$SHELL_JSON" >"$SHELL_JSON.tmp" && mv "$SHELL_JSON.tmp" "$SHELL_JSON"
echo "Set idle.lock = 60 in shell.json"
