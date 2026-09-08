#!/bin/bash
# Symlinks Claude Code-specific config into ~/.claude. Shared Agent Skills are
# managed by ../skills/setup.sh so Claude, Codex, and OpenCode use one source.
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

mkdir -p "$CLAUDE_DIR"

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

# settings.json (NOT settings.local.json or .credentials.json — those stay machine-local)
link "$DIR/settings.json" "$CLAUDE_DIR/settings.json"
link "$DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
link "$DIR/statusline-command.sh" "$CLAUDE_DIR/statusline-command.sh"
