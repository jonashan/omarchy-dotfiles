#!/bin/bash
# Installs the repo's Claude Code mods (plugins) at user scope, so terminal and
# Claude Desktop sessions both load them. This folder is a directory
# marketplace, so plugins are read straight from the repo: edit, then
# /reload-plugins — no reinstall.
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
MARKETPLACE="omarchy-dotfiles"

if ! command -v claude &>/dev/null; then
  echo "WARNING: claude not found — skipping mods"
  exit 0
fi

if claude plugin marketplace list 2>/dev/null | grep -q "$MARKETPLACE"; then
  echo "Marketplace already added: $MARKETPLACE"
else
  claude plugin marketplace add "$DIR"
fi

for plugin in "$DIR"/plugins/*/; do
  name="$(basename "$plugin")"
  if claude plugin list 2>/dev/null | grep -q "$name@$MARKETPLACE"; then
    echo "Already installed: $name@$MARKETPLACE"
  else
    claude plugin install "$name@$MARKETPLACE" --scope user
  fi
done
