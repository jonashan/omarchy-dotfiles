#!/usr/bin/env bash
# Resolve the PR to babysit and print its current state as JSON.
#
# Usage:
#   pr-context.sh            # PR for the current branch
#   pr-context.sh <pr-url>   # explicit PR (URL or number)
#
# Output JSON fields:
#   number, headRefName, baseRefName, state, mergeable, mergeStateStatus,
#   url, reviewDecision, checks (rollup state + failing check names)
set -euo pipefail

arg="${1:-}"

if [[ -n "$arg" ]]; then
  # Accept a full URL or a bare number.
  pr="$arg"
else
  pr="" # gh infers from the current branch
fi

# Repo in owner/name form (works inside a worktree too).
repo="$(gh repo view --json nameWithOwner -q .nameWithOwner)"

gh pr view $pr \
  --repo "$repo" \
  --json number,headRefName,baseRefName,state,mergeable,mergeStateStatus,url,reviewDecision,statusCheckRollup \
  --jq '{
    number, headRefName, baseRefName, state, mergeable, mergeStateStatus, url, reviewDecision,
    checks: {
      total: (.statusCheckRollup | length),
      failing: [ .statusCheckRollup[]
        | select((.conclusion // .state) as $c | ($c=="FAILURE" or $c=="ERROR" or $c=="CANCELLED" or $c=="TIMED_OUT"))
        | (.name // .context) ],
      pending: [ .statusCheckRollup[]
        | select((.status // .state) as $s | ($s=="IN_PROGRESS" or $s=="QUEUED" or $s=="PENDING" or $s=="WAITING"))
        | (.name // .context) ]
    }
  }'
