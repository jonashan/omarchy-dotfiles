#!/bin/bash
# Apply all custom Omarchy configurations
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Applying Hyprland config ==="
bash "$DIR/hypr/setup.sh"

echo ""
echo "=== Applying Waybar config ==="
bash "$DIR/waybar/setup.sh"

echo ""
echo "Done!"
