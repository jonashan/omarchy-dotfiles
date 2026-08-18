#!/bin/bash
# Patches Omarchy's Hyprland Lua config with custom input settings.
#
# Omarchy 4 (Quattro) configures Hyprland in Lua, not .conf. The user files in
# ~/.config/hypr/ are loaded *after* Omarchy's defaults, so a later hl.config()
# call simply overrides the keys it sets. We append a marked block rather than
# uncommenting the shipped template, so package updates can rewrite the template
# freely without breaking us.
set -euo pipefail

INPUT_LUA="$HOME/.config/hypr/input.lua"
BINDINGS_LUA="$HOME/.config/hypr/bindings.lua"

BEGIN_MARKER="-- >>> omarchy-dotfiles (managed) >>>"
END_MARKER="-- <<< omarchy-dotfiles (managed) <<<"

# Drop any previous managed block, then append the current one. Re-running with
# changed values therefore updates them instead of stacking duplicates.
apply_block() {
  local file="$1" block="$2"
  sed -i "/^${BEGIN_MARKER}$/,/^${END_MARKER}$/d" "$file"
  printf '\n%s\n%s\n%s\n' "$BEGIN_MARKER" "$block" "$END_MARKER" >>"$file"
}

# --- input.lua: US + Danish keyboard layouts, no mouse acceleration ---
if [[ -f "$INPUT_LUA" ]]; then
  apply_block "$INPUT_LUA" 'hl.config({
  input = {
    kb_layout = "us,dk",
    accel_profile = "flat",
  },
})'
  echo "Set kb_layout = us,dk and accel_profile = flat in input.lua"
else
  echo "WARNING: $INPUT_LUA not found"
fi

# --- bindings.lua: layout switch + Linear web app ---
if [[ -f "$BINDINGS_LUA" ]]; then
  apply_block "$BINDINGS_LUA" 'o.bind("SUPER + ALT + PERIOD", "Switch keyboard layout", "hyprctl switchxkblayout all next")
o.bind("SUPER + SHIFT + L", "Linear", { webapp = "https://linear.app" })
hl.unbind("SUPER + SHIFT + E")
o.bind("SUPER + SHIFT + E", "Email", { webapp = "https://mail.google.com" })
hl.unbind("SUPER + SHIFT + C")
o.bind("SUPER + SHIFT + C", "Calendar", { webapp = "https://calendar.google.com" })'
  echo "Added keybinds: language switch, Linear, Gmail (Super+Shift+E), Google Calendar (Super+Shift+C)"
else
  echo "WARNING: $BINDINGS_LUA not found"
fi

# Hyprland auto-reloads on save, but reload explicitly so we can surface errors.
if command -v hyprctl &>/dev/null && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
  hyprctl reload >/dev/null
  # A clean config prints only whitespace (older builds print "no errors").
  errors="$(hyprctl configerrors | tr -d '[:space:]')"
  if [[ -z "$errors" || "$errors" == *"noerrors"* ]]; then
    echo "Hyprland reloaded, config OK"
  else
    echo "WARNING: hyprctl configerrors reported:"
    echo "$errors"
  fi
else
  echo "Hyprland not running — changes apply on next login"
fi
