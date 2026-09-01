# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal dotfiles for an [Omarchy](https://omarchy.org) 4 "Quattro" (Arch Linux + Hyprland) desktop. Rather than storing config files to copy into place, most scripts here **patch the live Omarchy-managed configs in `~/.config/` in place**. The repo owns the deltas, not the files.

Sub-setups live in two top-level buckets: `config/` (customize existing config) and `install/` (install/remove software). Each bucket has a `setup.sh` that runs every subfolder's `setup.sh` in alphabetical order, so adding a new one is just dropping a `<name>/setup.sh` into the right bucket — no orchestrator edit needed.

The exceptions to the patch-in-place rule are `config/claude/` and `config/aliases/`, which own their files wholesale and **symlink** them into place (`~/.claude/` and `~/.bash_aliases`) so edits flow straight back into this repo.

## Commands

```bash
./setup.sh                          # Apply everything (installs, then configs)
bash install/setup.sh               # Run every installer in install/
bash config/setup.sh                # Apply every config in config/
bash install/webapps/setup.sh       # Install/remove web apps
bash install/dev-services/setup.sh  # Run Postgres + Redis dev containers (docker)
bash config/hypr/setup.sh           # Hyprland: keyboard layouts, mouse accel
bash config/shell/setup.sh          # Omarchy shell: lock screen after 1 min idle
bash config/aliases/setup.sh        # Symlink aliases.sh to ~/.bash_aliases + source it
bash config/claude/setup.sh         # Symlink Claude Code skills + settings.json into ~/.claude
```

There is no build, lint, or test step — these are bash scripts run directly on the target machine. `setup.sh` runs `install/setup.sh` then `config/setup.sh`; each of those runs its subfolders' `setup.sh` alphabetically. All sub-setups are independent and idempotent, so order does not matter.

## Conventions that matter

**Idempotency is mandatory.** Every script must be safe to re-run. The established patterns:
- Check for a `.desktop` file before `omarchy-webapp-install` / `omarchy-webapp-remove`.
- For managed blocks in Omarchy's config files, **delete the marked block first, then re-append it** (see `apply_block` in `config/hypr/setup.sh`). Changed values then propagate on re-run instead of stacking duplicates.
- Guard anything that can fail on a cold machine (network, missing binary) so `set -e` doesn't abort the whole run.

**Patching technique.** Omarchy 4 configures Hyprland in **Lua**, not `.conf` — `~/.config/hypr/{bindings,input,autostart,monitors,looknfeel}.lua`. These user files are loaded *after* Omarchy's packaged defaults, so a later `hl.config({...})` call overrides only the keys it sets, and `o.bind(...)` adds bindings. To override a default binding you must `hl.unbind("...")` first. Append a marked block rather than uncommenting the shipped template, so package updates can rewrite the template freely.

**Never edit `/usr/share/omarchy/`.** It is package-owned and overwritten on `omarchy update`. Reading it is safe and encouraged — `/usr/share/omarchy/default/hypr/bindings/applications.lua` is the source of truth for default keybinds.

**Reload after patching.** Hyprland auto-reloads on save; still run `hyprctl reload` and check `hyprctl configerrors`. `~/.config/omarchy/shell.json` (bar, idle, lock) hot-reloads on save.

**Omarchy helpers** are the intended API for desktop changes — prefer them over hand-editing. The `omarchy <group> <action>` dispatcher is the stable form (`omarchy pkg add`, `omarchy restart shell`, `omarchy theme set`); the underlying `omarchy-*` binaries still exist on `PATH`. Run `omarchy commands` to list everything. The `omarchy` skill is available for broader desktop customization.

**All scripts** start with `set -euo pipefail` and warn (`WARNING: ... not found`) rather than hard-failing when a target config is absent.

## Hardcoded specifics to know

- Keyboard layouts are set per-machine, not managed here; switch bind is Super+Alt+. ; mouse accel disabled (`config/hypr/setup.sh`).
- Web apps installed: Google Calendar, Gmail, Linear, Messenger, TeamEffect V1/V2 repos.
- Web apps removed: Basecamp, HEY, WhatsApp, Zoom. `omarchy-refresh-applications` restores them, so re-run the script after a refresh.
- Dev containers: Postgres on `:5432` (password `postgres`), Redis on `:6379`, both `--restart unless-stopped`.
- Shell aliases live in `config/aliases/aliases.sh`. Edit it directly — it is symlinked to `~/.bash_aliases` and applies in the next shell; no re-run needed.

## Not managed here

Deliberately out of scope, after the Quattro cleanup: package installs and the status bar (Omarchy's shell ships a keyboard-layout widget).
