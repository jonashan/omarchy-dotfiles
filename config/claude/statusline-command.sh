#!/usr/bin/env bash
input=$(cat)

cwd=$(echo "$input" | jq -r '.cwd')
display_cwd=${cwd/#$HOME/\~}
model=$(echo "$input" | jq -r '.model.display_name // empty')

# Git branch (skip lock, read-only)
branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)

# Context bar
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$used" ]; then
  used_int=${used%.*}
  filled=$(( (used_int + 5) / 10 ))
  empty=$((10 - filled))
  bar=$(printf '%0.s█' $(seq 1 $filled 2>/dev/null))$(printf '%0.s░' $(seq 1 $empty 2>/dev/null))
  ctx_str="\033[92m${bar}\033[0m ${used_int}%"
fi

# Assemble with " | " separators
sep=" \033[90m|\033[0m "
out="$display_cwd"
[ -n "$branch" ] && out="$out$sep\033[95m\033[0m $branch"
[ -n "$model" ] && out="$out$sep$model"
[ -n "$ctx_str" ] && out="$out$sep$ctx_str"
printf '%b' "$out"
