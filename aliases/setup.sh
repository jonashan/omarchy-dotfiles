#!/bin/bash
# Adds custom shell aliases to .bashrc
set -euo pipefail

BASHRC="$HOME/.bashrc"

declare -A ALIASES=(
  ["lg"]="lazygit"
  ["ld"]="lazygit"
  ["te"]="cd ~/Work/TeamEffect/"
  ["te2"]="cd ~/Work/teameffect-v2/"
)

for name in "${!ALIASES[@]}"; do
  alias_line="alias $name='${ALIASES[$name]}'"
  if ! grep -qF "$alias_line" "$BASHRC"; then
    echo "$alias_line" >> "$BASHRC"
    echo "Added alias: $name=${ALIASES[$name]}"
  else
    echo "Alias already present: $name"
  fi
done
