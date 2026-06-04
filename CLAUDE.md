# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal dotfiles for an [Omarchy](https://omarchy.org) (Arch Linux + Hyprland) desktop. Rather than storing config files to copy into place, every script here **patches the live Omarchy-managed configs in `~/.config/`** in place. The repo owns the deltas, not the files.

## Commands

```bash
./setup.sh                  # Apply everything (runs all sub-setups in order)
bash hypr/setup.sh          # Hyprland: keyboard layouts, keybinds, autostart, idle lock
bash hypr/setup-hypridle.sh # Idle lock only (called by hypr/setup.sh)
bash webapps/setup.sh       # Install/remove PWAs + their keybinds
bash waybar/setup.sh        # Waybar language indicator
bash aliases/setup.sh       # Append shell aliases to ~/.bashrc
```

There is no build, lint, or test step — these are bash scripts run directly on the target machine. `setup.sh` orchestrates the sub-scripts in order: hypr → webapps → waybar → aliases.

## Conventions that matter

**Idempotency is mandatory.** Every script must be safe to re-run. The established patterns:
- `grep -q <marker>` before appending/inserting, then echo "already present" on the else branch.
- Check for a `.desktop` file before `omarchy-webapp-install`.
- For one-time settings, `sed -i 's/^key.*/key = newval/'` (replace, not append).
- When changing a value that may already exist from a prior version, **remove the stale line first, then add the new one** (see the Lazygit keybind rewrite in `hypr/setup.sh`).

**Patching technique.** Insertions into Hyprland's `bindings.conf` anchor on the `# Overwrite existing bindings` comment via `sed -i '/marker/i ...'`. Waybar's JSONC is patched with `sed` insertions keyed off existing module names. `hypr/setup-hypridle.sh` uses an inline `python3` script for multi-line regex edits that sed can't do cleanly.

**Reload after patching.** Config changes only take effect after the relevant daemon restarts: `omarchy-restart-waybar`, or `killall hypridle; hypridle &`. Include the reload in the script.

**Omarchy helpers** are the intended API for desktop changes — prefer them over hand-editing where one exists: `omarchy-webapp-install`, `omarchy-webapp-remove`, `omarchy-launch-webapp`, `omarchy-launch-tui`, `omarchy-restart-waybar`. The `omarchy` skill is available for broader desktop customization.

**All scripts** start with `set -euo pipefail` and `WARNING: ... not found` (don't hard-fail) when a target config is absent, except where a missing file is fatal.

## Hardcoded specifics to know

- Keyboard layouts: `us,dk`; switch with Super+Alt+. ; mouse accel disabled.
- Idle lock at 180s (`hypr/setup-hypridle.sh`); screensaver listener stripped out.
- Work paths are hardcoded to this machine: `~/Work/TeamEffect/` (`te`), `~/Work/teameffect-v2/` (`te2`); Lazygit keybind opens `/home/jonas/Work/teameffect-v2`.
- Keybinds: Super+Shift+C Calendar, +E Gmail, +K Linear, +G Lazygit.
- 1Password autostarts (`--silent`) on login to provide the SSH agent.
