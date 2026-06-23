#!/usr/bin/env bash
# Reply to a CodeRabbit review thread and (optionally) resolve it.
#
# Usage:
#   reply-resolve-thread.sh <pr-number> <first-comment-id> <thread-id> [--no-resolve] <<<"reply body"
#   echo "reply body" | reply-resolve-thread.sh <pr> <comment-id> <thread-id>
#
# The reply body is read from stdin (supports multi-line / markdown).
# Posts the reply under the thread, then resolves it unless --no-resolve is given.
set -euo pipefail

pr="${1:?usage: reply-resolve-thread.sh <pr> <comment-id> <thread-id> [--no-resolve]}"
comment_id="${2:?need first-comment-id}"
thread_id="${3:?need thread-id}"
resolve=1
[[ "${4:-}" == "--no-resolve" ]] && resolve=0

body="$(cat)"
[[ -z "$body" ]] && { echo "error: empty reply body on stdin" >&2; exit 1; }

repo="$(gh repo view --json nameWithOwner -q .nameWithOwner)"

# Reply under the existing review comment thread (REST).
gh api "repos/$repo/pulls/$pr/comments/$comment_id/replies" \
  -f body="$body" --jq '.id' >/dev/null
echo "replied to comment $comment_id"

if [[ "$resolve" == "1" ]]; then
  gh api graphql -f query='
  mutation($id:ID!){
    resolveReviewThread(input:{threadId:$id}){ thread{ id isResolved } }
  }' -F id="$thread_id" --jq '.data.resolveReviewThread.thread.isResolved' >/dev/null
  echo "resolved thread $thread_id"
fi
