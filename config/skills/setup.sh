#!/bin/bash
# Links the repo's shared Agent Skills into every supported coding agent. Each
# skill is linked individually so agent-specific and system-provided skills are
# left alone. Re-running this script also migrates links from the former
# config/claude/skills location.
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$DIR/../.." && pwd)"

TARGET_DIRS=(
  "$HOME/.claude/skills"
  "$HOME/.codex/skills"
  "$HOME/.config/opencode/skills"
)

canonical_path() {
  realpath -m "$1"
}

backup_destination() {
  local dest="$1" backup="$dest.bak" suffix=1

  while [[ -e "$backup" || -L "$backup" ]]; do
    backup="$dest.bak.$suffix"
    suffix=$((suffix + 1))
  done

  echo "WARNING: $dest already exists and is not a repo-managed skill — backing up to $backup"
  mv "$dest" "$backup"
}

link_skill() {
  local src="$1" target_dir="$2" name dest src_path legacy_path dest_path

  name="$(basename "$src")"
  dest="$target_dir/$name"
  src_path="$(canonical_path "$src")"
  legacy_path="$(canonical_path "$REPO_DIR/config/claude/skills/$name")"

  if [[ -L "$dest" ]]; then
    dest_path="$(canonical_path "$dest")"
    if [[ "$dest_path" == "$src_path" ]]; then
      echo "Already linked: $dest"
      return
    fi

    if [[ "$dest_path" == "$legacy_path" ]]; then
      rm "$dest"
      ln -s "$src" "$dest"
      echo "Migrated: $dest -> $src"
      return
    fi
  fi

  if [[ -e "$dest" || -L "$dest" ]]; then
    backup_destination "$dest"
  fi

  ln -s "$src" "$dest"
  echo "Linked: $dest -> $src"
}

for target_dir in "${TARGET_DIRS[@]}"; do
  mkdir -p "$target_dir"
  for skill in "$DIR"/*/; do
    [[ -d "$skill" ]] || continue
    link_skill "${skill%/}" "$target_dir"
  done
done
