#!/bin/bash
# Removes unwanted web apps and configures Google Calendar
set -euo pipefail

BINDINGS="$HOME/.config/hypr/bindings.conf"

# --- Remove unwanted web apps ---
REMOVE_APPS=("Basecamp" "Fizzy" "HEY" "WhatsApp" "Zoom")

for app in "${REMOVE_APPS[@]}"; do
  if [[ -f "$HOME/.local/share/applications/$app.desktop" ]]; then
    omarchy-webapp-remove "$app"
  else
    echo "$app not installed, skipping"
  fi
done

# --- Install Google Calendar web app (idempotent) ---
if [[ ! -f "$HOME/.local/share/applications/Google Calendar.desktop" ]]; then
  omarchy-webapp-install "Google Calendar" "https://calendar.google.com" ""
  echo "Installed Google Calendar web app"
else
  echo "Google Calendar already installed"
fi

# --- Install Gmail web app (idempotent) ---
if [[ ! -f "$HOME/.local/share/applications/Gmail.desktop" ]]; then
  omarchy-webapp-install "Gmail" "https://mail.google.com" ""
  echo "Installed Gmail web app"
else
  echo "Gmail already installed"
fi

# --- Patch keybindings ---
if [[ -f "$BINDINGS" ]]; then
  # Remove HEY Calendar keybind (SUPER SHIFT, C)
  sed -i '/hey\.com\/calendar/d' "$BINDINGS"

  # Remove HEY Email keybind (SUPER SHIFT, E)
  sed -i '/hey\.com/d' "$BINDINGS"

  # Remove WhatsApp keybind
  sed -i '/whatsapp/Id' "$BINDINGS"

  # Add Google Calendar keybind if not present
  if ! grep -q 'Google Calendar' "$BINDINGS"; then
    sed -i '/^# Overwrite existing bindings/i bindd = SUPER SHIFT, C, Google Calendar, exec, omarchy-launch-webapp "https://calendar.google.com"' "$BINDINGS"
    echo "Added Google Calendar keybind (Super + Shift + C)"
  else
    echo "Google Calendar keybind already present"
  fi

  # Add Gmail keybind if not present
  if ! grep -q 'Gmail' "$BINDINGS"; then
    sed -i '/^# Overwrite existing bindings/i bindd = SUPER SHIFT, E, Gmail, exec, omarchy-launch-webapp "https://mail.google.com"' "$BINDINGS"
    echo "Added Gmail keybind (Super + Shift + E)"
  else
    echo "Gmail keybind already present"
  fi
else
  echo "WARNING: $BINDINGS not found"
fi
