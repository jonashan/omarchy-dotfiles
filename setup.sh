#!/bin/bash
# Apply all custom Omarchy configurations
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Running installs ==="
bash "$DIR/install/setup.sh"

echo "=== Applying configs ==="
bash "$DIR/config/setup.sh"

echo "Done!"
