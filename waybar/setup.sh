#!/bin/bash
# Patches Omarchy Waybar config with language indicator
set -euo pipefail

CONFIG="$HOME/.config/waybar/config.jsonc"
STYLE="$HOME/.config/waybar/style.css"

# --- config.jsonc: Add hyprland/language module ---
if [[ -f "$CONFIG" ]]; then
  if ! grep -q 'hyprland/language' "$CONFIG"; then
    # Add to modules-right after tray-expander
    sed -i '/"group\/tray-expander"/s/$/\n    "hyprland\/language",/' "$CONFIG"

    # Add module config before "tray" section
    sed -i '/"tray": {/i\
  "hyprland/language": {\
    "format": "{short}",\
    "on-click": "hyprctl switchxkblayout all next",\
    "tooltip-format": "{long}\\n\\nAlt + Super + ."\
  },' "$CONFIG"
    echo "Added hyprland/language module to waybar config"
  else
    echo "hyprland/language module already present"
  fi
else
  echo "WARNING: $CONFIG not found"
fi

# --- style.css: Add spacing for language indicator ---
if [[ -f "$STYLE" ]]; then
  if ! grep -q '#language' "$STYLE"; then
    sed -i '/#bluetooth {/i\
#language {\
  margin-right: 12px;\
}\
' "$STYLE"
    echo "Added #language styling to waybar style.css"
  else
    echo "#language styling already present"
  fi
else
  echo "WARNING: $STYLE not found"
fi

# Restart waybar to apply
omarchy-restart-waybar
echo "Waybar restarted"
