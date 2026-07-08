#!/usr/bin/env bash
# List UNRESOLVED CodeRabbit review threads on a PR as JSON (one object per line).
#
# Usage: coderabbit-threads.sh <pr-number>
#
# Each object:
#   { threadId, isOutdated, path, line, firstCommentId, body,
#     replyCount, lastAuthor }
#
# Only threads whose FIRST comment author looks like CodeRabbit are returned,
# and only while unresolved.
#   threadId        -> resolveReviewThread / reply-resolve-thread.sh
#   firstCommentId  -> the comment id to reply under
#   replyCount      -> comments after the first (0 = nobody has replied yet)
#   lastAuthor      -> login of the most recent comment; if it's YOU, the
#                      thread was already addressed (e.g. declined) on a prior pass
set -euo pipefail

pr="${1:?usage: coderabbit-threads.sh <pr-number>}"
repo="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
owner="${repo%%/*}"
name="${repo##*/}"

gh api graphql -f query='
query($owner:String!,$name:String!,$pr:Int!,$cursor:String){
  repository(owner:$owner,name:$name){
    pullRequest(number:$pr){
      reviewThreads(first:100, after:$cursor){
        pageInfo{ hasNextPage endCursor }
        nodes{
          id isResolved isOutdated
          comments(first:50){ nodes{ databaseId author{login} body path line } }
        }
      }
    }
  }
}' -F owner="$owner" -F name="$name" -F pr="$pr" --paginate \
  --jq '.data.repository.pullRequest.reviewThreads.nodes[]
    | select(.isResolved == false)
    | .comments.nodes as $c
    | select($c[0].author.login | ascii_downcase | test("coderabbit"))
    | {
        threadId: .id,
        isOutdated: .isOutdated,
        path: $c[0].path,
        line: $c[0].line,
        firstCommentId: $c[0].databaseId,
        body: $c[0].body,
        replyCount: (($c | length) - 1),
        lastAuthor: ($c[-1].author.login)
      }'
