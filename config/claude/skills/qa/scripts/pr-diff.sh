#!/usr/bin/env bash
# Gather the source material for a QA plan: the metadata, commits, changed files,
# and full diff a PR (or the current branch) introduces relative to its base.
#
# Usage:
#   pr-diff.sh            # PR / branch checked out now
#   pr-diff.sh <url|num>  # explicit PR
#
# Prints a META header, then COMMITS, FILES CHANGED, and DIFF sections.
set -euo pipefail

arg="${1:-}"
repo="$(gh repo view --json nameWithOwner -q .nameWithOwner)"

# Resolve PR metadata if a PR exists for the target; otherwise fall back to the
# repo's default branch as the base so we can still build a plan from the branch.
if fields="$(gh pr view $arg --repo "$repo" \
      --json number,url,title,baseRefName,headRefName \
      -q '[.number,.url,.title,.baseRefName,.headRefName] | @tsv' 2>/dev/null)"; then
  IFS=$'\t' read -r number url title base head <<<"$fields"
else
  number=""
  url=""
  title="$(git log -1 --format=%s 2>/dev/null || true)"
  base="$(gh repo view --repo "$repo" --json defaultBranchRef -q .defaultBranchRef.name)"
  head="$(git rev-parse --abbrev-ref HEAD)"
fi

git fetch -q origin "$base" || true
# Three-dot range: changes the branch adds since it diverged from base (ignores
# base's own commits since the fork point).
range="origin/$base...HEAD"

echo "=== META ==="
if [[ -n "$number" ]]; then
  echo "PR:     #$number"
  echo "URL:    $url"
else
  echo "PR:     (none — no open PR for this branch)"
fi
echo "Title:  $title"
echo "Base:   $base"
echo "Head:   $head"
echo
echo "=== COMMITS ==="
git log --no-merges --format='%h %s' "$range" || true
echo
echo "=== FILES CHANGED ==="
git diff --stat "$range" || true
echo
echo "=== DIFF ==="
git diff "$range" || true
