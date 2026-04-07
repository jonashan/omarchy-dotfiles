#!/bin/bash
# Patches hypridle.conf: disable screensaver, lock after 1min idle
set -euo pipefail

HYPRIDLE_CONF="$HOME/.config/hypr/hypridle.conf"

if [[ ! -f "$HYPRIDLE_CONF" ]]; then
  echo "WARNING: $HYPRIDLE_CONF not found"
  exit 1
fi

# Remove the old wrapper script if it exists
rm -f "$HOME/.local/bin/omarchy-screensaver-then-lock"

python3 -c "
import re

with open('$HYPRIDLE_CONF') as f:
    content = f.read()

# Remove any screensaver listener block
content = re.sub(
    r'listener \{[^}]*screensaver[^}]*\}\n*',
    '',
    content
)

# Update the lock-session listener timeout to 60s
content = re.sub(
    r'(listener \{[^}]*?)timeout = \d+(\s*#[^\n]*)?\n([^}]*on-timeout = loginctl lock-session)',
    r'\1timeout = 60                                  # 1min\n\3',
    content
)

with open('$HYPRIDLE_CONF', 'w') as f:
    f.write(content)
"

# Restart hypridle to pick up changes (it doesn't auto-reload)
killall hypridle 2>/dev/null; sleep 0.2; hypridle &

echo "Configured: no screensaver, lock at 60s idle"
