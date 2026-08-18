#!/bin/bash
# Symlinks the personal alias file to ~/.bash_aliases and makes ~/.bashrc source
# it. Aliases are owned wholesale (like config/claude/), so they're symlinked
# rather than appended into ~/.bashrc — edit aliases.sh and the change is live
# in the next shell, without re-running this script.
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="$DIR/aliases.sh"
DEST="$HOME/.bash_aliases"
BASHRC="$HOME/.bashrc"

# --- Link the alias file ---
if [[ -L "$DEST" && "$(readlink -f "$DEST")" == "$(readlink -f "$SRC")" ]]; then
  echo "Already linked: $DEST"
elif [[ -e "$DEST" || -L "$DEST" ]]; then
  echo "WARNING: $DEST already exists and is not our symlink — backing up to $DEST.bak"
  mv "$DEST" "$DEST.bak"
  ln -s "$SRC" "$DEST"
  echo "Linked: $DEST -> $SRC"
else
  ln -s "$SRC" "$DEST"
  echo "Linked: $DEST -> $SRC"
fi

# --- Source it from ~/.bashrc ---
# Appended at the end, after Omarchy's own rc, so these aliases take precedence.
SOURCE_LINE='[[ -r ~/.bash_aliases ]] && source ~/.bash_aliases'

if [[ ! -f "$BASHRC" ]]; then
  echo "WARNING: $BASHRC not found"
elif grep -qF "$SOURCE_LINE" "$BASHRC"; then
  echo "~/.bashrc already sources ~/.bash_aliases"
else
  printf '\n# Personal aliases (managed by omarchy-dotfiles)\n%s\n' "$SOURCE_LINE" >>"$BASHRC"
  echo "Added ~/.bash_aliases source line to ~/.bashrc"
fi
