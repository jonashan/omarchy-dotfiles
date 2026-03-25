#!/bin/bash
# Patches hypridle.conf: screensaver at 1min, lock when screensaver is dismissed
set -euo pipefail

HYPRIDLE_CONF="$HOME/.config/hypr/hypridle.conf"
WRAPPER="$HOME/.local/bin/omarchy-screensaver-then-lock"

if [[ ! -f "$HYPRIDLE_CONF" ]]; then
  echo "WARNING: $HYPRIDLE_CONF not found"
  exit 1
fi

# Install the wrapper script
mkdir -p "$(dirname "$WRAPPER")"
cat > "$WRAPPER" << 'SCRIPT'
#!/bin/bash
# Launch screensaver, then lock when it's dismissed
pidof hyprlock && exit 0

omarchy-launch-screensaver

# Wait for the screensaver terminal to be dismissed (user pressed a key)
sleep 0.5
while pidof -x omarchy-cmd-screensaver >/dev/null; do
  sleep 0.1
done

# Lock the screen
loginctl lock-session
SCRIPT
chmod +x "$WRAPPER"

# Patch hypridle.conf
python3 -c "
import re

with open('$HYPRIDLE_CONF') as f:
    content = f.read()

# Remove any standalone lock-session listener block
content = re.sub(
    r'listener \{[^}]*on-timeout = loginctl lock-session[^}]*\}\n*',
    '',
    content
)

# Replace the screensaver listener block with the wrapper
content = re.sub(
    r'listener \{[^}]*omarchy-launch-screensaver[^}]*\}',
    '''listener {
    timeout = 60                                  # 1min
    on-timeout = omarchy-screensaver-then-lock    # screensaver, then lock on dismiss
}''',
    content
)

# If no matching listener existed, insert one after the general block
if 'omarchy-screensaver-then-lock' not in content:
    content = content.replace(
        '}\n\nlistener',
        '''}\n
listener {
    timeout = 60                                  # 1min
    on-timeout = omarchy-screensaver-then-lock    # screensaver, then lock on dismiss
}

listener''',
        1
    )

with open('$HYPRIDLE_CONF', 'w') as f:
    f.write(content)
"

# Restart hypridle to pick up changes (it doesn't auto-reload)
killall hypridle 2>/dev/null; sleep 0.2; hypridle &

echo "Configured screensaver at 60s + lock on dismiss in hypridle.conf"
