#!/bin/bash
# Symlinks Claude Code config (skills + settings.json) into ~/.claude so edits
# made by Claude flow straight back into this repo. Unlike the patching scripts
# in this repo, the Claude config files are owned wholesale, so we symlink them
# rather than patching live files in place.
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

# Ensure ~/.claude/skills exists as a real dir so we link individual skills into
# it (and never accidentally turn all of ~/.claude into a symlink).
mkdir -p "$CLAUDE_DIR/skills"

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

# Each skill directory
for skill in "$DIR"/skills/*/; do
  [[ -d "$skill" ]] || continue
  name="$(basename "$skill")"
  link "${skill%/}" "$CLAUDE_DIR/skills/$name"
done
