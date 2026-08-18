#!/bin/bash
# Removes the preinstalled Omarchy web apps this desktop doesn't use and
# installs the ones it does.
#
# Note: these launchers are package-owned templates in
# /usr/share/omarchy/applications/, copied into ~/.local/share/applications/.
# `omarchy-refresh-applications` restores every one of them, so re-run this
# script after a refresh.
set -euo pipefail

APPS_DIR="$HOME/.local/share/applications"

REMOVE_APPS=("Basecamp" "HEY" "WhatsApp" "Zoom")

# name|url — installed with an auto-fetched site icon.
INSTALL_APPS=(
  "Google Calendar|https://calendar.google.com"
  "Gmail|https://mail.google.com"
  "Linear|https://linear.app"
  "Messenger|https://www.messenger.com"
  "TeamEffect V1 - Repo|https://github.com/teameffect/teameffect"
  "TeamEffect V2 - Repo|https://github.com/teameffect/teameffect-v2"
)

# --- Remove unwanted web apps ---
for app in "${REMOVE_APPS[@]}"; do
  if [[ -f "$APPS_DIR/$app.desktop" ]]; then
    omarchy-webapp-remove "$app"
  else
    echo "$app not installed, skipping"
  fi
done

# --- Install wanted web apps ---
for entry in "${INSTALL_APPS[@]}"; do
  name="${entry%%|*}"
  url="${entry#*|}"

  if [[ -f "$APPS_DIR/$name.desktop" ]]; then
    echo "Already installed: $name"
    continue
  fi

  # An empty icon argument makes omarchy-webapp-install fetch the site's own
  # icon; it exits non-zero if that fails, which must not abort the whole run.
  if omarchy-webapp-install "$name" "$url" ""; then
    echo "Installed: $name"
  else
    echo "WARNING: could not install $name (icon fetch failed?)"
  fi
done
