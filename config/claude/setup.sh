#!/bin/bash
# Symlinks global agent instructions into Claude Code, Codex, and OpenCode.
# Shared Agent Skills are managed by ../skills/setup.sh.
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
CODEX_DIR="$HOME/.codex"
OPENCODE_DIR="$HOME/.config/opencode"

mkdir -p "$CLAUDE_DIR"
mkdir -p "$CODEX_DIR" "$OPENCODE_DIR"

link() {
  local src="$1" dest="$2"
  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    echo "Already linked: $dest"
  elif [[ -L "$dest" && "$(readlink -f "$dest")" == "$(readlink -f "$src")" ]]; then
    rm "$dest"
    ln -s "$src" "$dest"
    echo "Re-linked: $dest -> $src"
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

remove_legacy_guidance_link() {
  local dest="$1"

  if [[ -L "$dest" && "$(readlink -f "$dest")" == "$(readlink -f "$DIR/CLAUDE.md")" ]]; then
    rm "$dest"
    echo "Removed legacy guidance link: $dest"
  fi
}

# settings.json (NOT settings.local.json or .credentials.json — those stay machine-local)
link "$DIR/settings.json" "$CLAUDE_DIR/settings.json"
link "$DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
link "$DIR/CLAUDE.md" "$CLAUDE_DIR/AGENTS.md"
link "$DIR/statusline-command.sh" "$CLAUDE_DIR/statusline-command.sh"

# Codex and OpenCode load AGENTS.md, which is the shared Claude guidance.
remove_legacy_guidance_link "$CODEX_DIR/CLAUDE.md"
remove_legacy_guidance_link "$OPENCODE_DIR/CLAUDE.md"
link "$DIR/CLAUDE.md" "$CODEX_DIR/AGENTS.md"
link "$DIR/CLAUDE.md" "$OPENCODE_DIR/AGENTS.md"
