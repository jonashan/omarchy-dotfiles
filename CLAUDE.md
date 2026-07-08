# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal dotfiles for an [Omarchy](https://omarchy.org) (Arch Linux + Hyprland) desktop. Rather than storing config files to copy into place, every script here **patches the live Omarchy-managed configs in `~/.config/`** in place. The repo owns the deltas, not the files.

Sub-setups live in two top-level buckets: `config/` (customize existing config) and `install/` (install/remove software). Each bucket has a `setup.sh` that runs every subfolder's `setup.sh` in alphabetical order, so adding a new one is just dropping a `<name>/setup.sh` into the right bucket — no orchestrator edit needed.

The exceptions to the patch-in-place rule are `config/claude/` and `config/agent-deck/`, which own their files wholesale and **symlink** them into place so edits flow straight back into this repo: `config/claude/setup.sh` links the Claude Code skills and `settings.json` into `~/.claude/`, and `config/agent-deck/setup.sh` links `config.toml` into `~/.config/agent-deck/`.

## Commands

```bash
./setup.sh                          # Apply everything (installs, then configs)
bash install/setup.sh               # Run every installer in install/
bash config/setup.sh                # Apply every config in config/
bash install/packages/setup.sh      # Install AUR/repo packages (agent-deck-bin, ...)
bash install/webapps/setup.sh       # Install/remove PWAs + their keybinds
bash config/hypr/setup.sh           # Hyprland: keyboard layouts, keybinds, autostart, idle lock
bash config/hypr/setup-hypridle.sh  # Idle lock only (called by config/hypr/setup.sh)
bash config/waybar/setup.sh         # Waybar language indicator
bash config/aliases/setup.sh        # Append shell aliases to ~/.bashrc
bash config/claude/setup.sh         # Symlink Claude Code skills + settings.json into ~/.claude
bash config/agent-deck/setup.sh     # Symlink Agent Deck config.toml into ~/.config/agent-deck
```

There is no build, lint, or test step — these are bash scripts run directly on the target machine. `setup.sh` runs `install/setup.sh` then `config/setup.sh`; each of those runs its subfolders' `setup.sh` alphabetically. All sub-setups are independent and idempotent, so order does not matter.

## Conventions that matter

**Idempotency is mandatory.** Every script must be safe to re-run. The established patterns:
- `grep -q <marker>` before appending/inserting, then echo "already present" on the else branch.
- Check for a `.desktop` file before `omarchy-webapp-install`.
- For one-time settings, `sed -i 's/^key.*/key = newval/'` (replace, not append).
- When changing a value that may already exist from a prior version, **remove the stale line first, then add the new one** (see the Lazygit keybind rewrite in `config/hypr/setup.sh`).

**Patching technique.** Insertions into Hyprland's `bindings.conf` anchor on the `# Overwrite existing bindings` comment via `sed -i '/marker/i ...'`. Waybar's JSONC is patched with `sed` insertions keyed off existing module names. `config/hypr/setup-hypridle.sh` uses an inline `python3` script for multi-line regex edits that sed can't do cleanly.

**Reload after patching.** Config changes only take effect after the relevant daemon restarts: `omarchy-restart-waybar`, or `killall hypridle; hypridle &`. Include the reload in the script.

**Omarchy helpers** are the intended API for desktop changes — prefer them over hand-editing where one exists: `omarchy-webapp-install`, `omarchy-webapp-remove`, `omarchy-launch-webapp`, `omarchy-launch-tui`, `omarchy-restart-waybar`. For packages, `omarchy-pkg-add <pkg>` installs from the **official repos** (`pacman -S`) while `omarchy-pkg-aur-add <pkg>` installs from the **AUR** (`yay -S`) — pick by where the package lives (`-bin` / other AUR names need the AUR helper). Both are idempotent. The `omarchy` skill is available for broader desktop customization.

**All scripts** start with `set -euo pipefail` and `WARNING: ... not found` (don't hard-fail) when a target config is absent, except where a missing file is fatal.

## Hardcoded specifics to know

- Keyboard layouts: `us,dk`; switch with Super+Alt+. ; mouse accel disabled.
- Idle lock at 180s (`config/hypr/setup-hypridle.sh`); screensaver listener stripped out.
- Work paths are hardcoded to this machine: `~/Work/TeamEffect/` (`te`), `~/Work/teameffect-v2/` (`te2`); Lazygit keybind opens `/home/jonas/Work/teameffect-v2`.
- Keybinds: Super+Shift+C Calendar, +E Gmail, +K Linear, +G Lazygit.
- 1Password autostarts (`--silent`) on login to provide the SSH agent.
