#!/bin/bash
# Patches Omarchy Hyprland config with custom settings
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"

INPUT_CONF="$HOME/.config/hypr/input.conf"
BINDINGS_CONF="$HOME/.config/hypr/bindings.conf"

# --- input.conf: Set keyboard layouts to US (default) + DK ---
if [[ -f "$INPUT_CONF" ]]; then
  sed -i 's/^\(\s*\)kb_layout\s*=.*/\1kb_layout = us,dk/' "$INPUT_CONF"
  echo "Set kb_layout = us,dk in input.conf"

  # Disable mouse acceleration
  sed -i 's/^\(\s*\)force_no_accel\s*=.*/\1force_no_accel = true/' "$INPUT_CONF"
  echo "Set force_no_accel = true in input.conf"
else
  echo "WARNING: $INPUT_CONF not found"
fi

# --- bindings.conf: Add language switch keybind (Alt + Super + .) ---
if [[ -f "$BINDINGS_CONF" ]]; then
  if ! grep -q 'switchxkblayout' "$BINDINGS_CONF"; then
    sed -i '/^# Overwrite existing bindings/i bindd = SUPER ALT, period, Switch keyboard layout, exec, hyprctl switchxkblayout all next' "$BINDINGS_CONF"
    echo "Added language switch keybind (Super + Alt + .)"
  else
    echo "Language switch keybind already present"
  fi
else
  echo "WARNING: $BINDINGS_CONF not found"
fi

# --- autostart.conf: Start 1Password on login for SSH agent ---
AUTOSTART_CONF="$HOME/.config/hypr/autostart.conf"
if [[ -f "$AUTOSTART_CONF" ]]; then
  if ! grep -q '1password' "$AUTOSTART_CONF"; then
    echo 'exec-once = uwsm-app -- 1password --silent' >> "$AUTOSTART_CONF"
    echo "Added 1Password autostart for SSH agent"
  else
    echo "1Password autostart already present"
  fi
else
  echo "WARNING: $AUTOSTART_CONF not found"
fi

# --- hypridle.conf: Lock screen after 3 minutes ---
bash "$DIR/setup-hypridle.sh"
