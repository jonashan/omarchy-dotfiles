#!/bin/bash
# Installs the extra packages this desktop depends on.
# Add a package name to the relevant list below and re-run.
set -euo pipefail

# AUR packages — installed via yay through omarchy-pkg-aur-add.
# (agent-deck ships as the prebuilt AUR package `agent-deck-bin`.)
AUR_PKGS=(
  agent-deck-bin
)

# Official-repo packages — installed via pacman through omarchy-pkg-add.
REPO_PKGS=(
  direnv
)

install_pkgs() {
  local helper="$1"; shift
  if ! command -v "$helper" &>/dev/null; then
    echo "WARNING: $helper not found — skipping ${*:-(none)}"
    return
  fi
  for pkg in "$@"; do
    if pacman -Q "$pkg" &>/dev/null; then
      echo "Already installed: $pkg"
    else
      "$helper" "$pkg" && echo "Installed: $pkg"
    fi
  done
}

[[ ${#AUR_PKGS[@]}  -gt 0 ]] && install_pkgs omarchy-pkg-aur-add "${AUR_PKGS[@]}"
[[ ${#REPO_PKGS[@]} -gt 0 ]] && install_pkgs omarchy-pkg-add "${REPO_PKGS[@]}"

exit 0
