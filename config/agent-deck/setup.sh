#!/bin/bash
# Symlinks the Agent Deck config into ~/.config/agent-deck so edits made here
# flow straight back into this repo. Like the Claude config, agent-deck owns its
# config.toml wholesale, so we symlink it rather than patching a live file.
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
AGENT_DECK_DIR="$HOME/.config/agent-deck"

mkdir -p "$AGENT_DECK_DIR"

link() {
  local src="$1" dest="$2"
  if [[ -L "$dest" && "$(readlink -f "$dest")" == "$(readlink -f "$src")" ]]; then
    echo "Already linked: $dest"
  elif [[ -e "$dest" || -L "$dest" ]]; then
    echo "WARNING: $dest already exists and is not our symlink — backing up to $dest.bak"
    mv "$dest" "$dest.bak"
    ln -s "$src" "$dest"
    echo "Linked: $dest -> $src"
  else
    ln -s "$src" "$dest"
    echo "Linked: $dest -> $src"
  fi
}

link "$DIR/config.toml" "$AGENT_DECK_DIR/config.toml"
