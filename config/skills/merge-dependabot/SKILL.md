---
name: merge-dependabot
description: Review every open Dependabot PR in the current repo and merge the ones that are safe — CI green, mergeable, lockfile-only diff, no breaking change that touches code this repo actually uses — then report a table of what was merged and why the rest were not. Use whenever the user mentions Dependabot PRs, dependency bumps, "merge the dependabot stuff", "run through the dependency PRs", "clean up the bot PRs", "are the dependabot PRs safe", or runs /merge-dependabot. Also use when the user asks to check or triage Dependabot PRs without merging — same process, stop before the merge step and report.
---

# Merge Dependabot PRs

Triage all open Dependabot PRs in one pass and merge the safe ones. The point is to
get routine bumps off the board quickly without ever merging something that will
break the app. "Safe" means every gate below passes. One failing gate is enough
to hold a PR back — report it, don't fix it, unless the user asked for that.

Mode: if the user asked to merge ("merge them", "do it if safe"), merge. If they only
asked to check, review, or triage, run everything except step 5 and report.

## 1. List

```bash
gh pr list --author app/dependabot --state open --limit 50 \
  --json number,title,headRefName,mergeable,mergeStateStatus,statusCheckRollup,url
```

Pull the whole set in one call. Read `mergeable`, `mergeStateStatus` and the name +
conclusion of every check in `statusCheckRollup`. Nothing else is needed for the
first cut.

If there are none, say so and stop.

## 2. CI and mergeability gate

A PR passes only when `mergeStateStatus` is `CLEAN` and every check concluded
`SUCCESS` (or `SKIPPED`/`NEUTRAL`). Anything else is "not ready":

- a check is `FAILURE` → name the check. Open its log with
  `gh run view <id> --log-failed` only if the user asked why; otherwise just report.
- a check is still pending → report as "CI still running", re-check after the others.
- `BEHIND` → branch is stale against base. Comment `@dependabot rebase` on the PR
  and report; do not merge a stale branch even if the old run was green.
- `DIRTY` / `CONFLICTING` → conflict. Same: `@dependabot rebase`, report.
- `BLOCKED` → branch protection wants something (review, up-to-date). Report what.

Don't re-run CI yourself and don't push to Dependabot branches — Dependabot
force-pushes on rebase and will discard your commits.

## 3. Diff gate — lockfile only

```bash
gh pr diff <n> --name-only
gh pr diff <n> | grep -E '^[+-] ' | grep -v '^[+-]\s*$'
```

Expected: only the lockfile (`Gemfile.lock`, `package-lock.json`, `yarn.lock`,
`pnpm-lock.yaml`, `go.sum`, ...). Read the changed lines, not just the filename:

- Version lines only, same gem/package plus a few transitive bumps → fine.
- New transitive dependencies appear (new `+` lines with no `-` partner) → fine, but
  name them in the report. Someone reading the merge later wants to know a new gem
  entered the bundle.
- The manifest changed too (`Gemfile`, `package.json`) → the version constraint
  moved, which usually means a major bump. Not an automatic reject, but treat it as
  step 4 with extra care and say so in the report.
- Anything outside manifest + lockfile → not a routine bump. Hold it and report.

## 4. Breaking-change gate

Classify the bump from the title (`from X to Y`): patch, minor, or major.

- **Major**: don't auto-merge. Report it with a one-line summary of the breaking
  changes from the PR body so the user can decide.
- **Minor or patch**: scan the PR body (Dependabot pastes the changelog) for the
  words that signal removed or changed behaviour:

```bash
gh pr view <n> --json body -q .body | grep -iE 'break|deprecat|remov|drop|minimum|require'
```

No hits → done. Hits → read each one and ask: does this repo use the thing that
changed? Grep for it. Example: webmock 3.30 removed the session hash from
`to_rack` stubs; `grep -rn to_rack test/` came back empty, so the bump was safe.
Found a use → not ready; report the file and the changelog line. Dev-only
dependencies get the same treatment — a green test suite is strong evidence but a
removed API can hide in a code path tests don't reach.

Patch bumps with no changelog hits need no further reading. Don't open every
upstream release page for a `0.29.1 → 0.29.2`; CI plus the grep is the check.

## 5. Merge

Match the repo's existing merge style so history stays consistent. Look at
`git log --oneline origin/<base> -10`: merge commits (`Merge pull request #...`) →
`--merge`; linear history → `--squash` or `--rebase`. Confirm the method is allowed:

```bash
gh repo view --json mergeCommitAllowed,squashMergeAllowed,rebaseMergeAllowed
```

Then merge sequentially, oldest first:

```bash
gh pr merge <n> --<method> --delete-branch
```

Sequential, not parallel: each merge changes the base, and GitHub recomputes the
others' mergeability. If a later PR flips to `BEHIND` or `DIRTY` after an earlier
merge (branch protection requiring up-to-date branches does this), comment
`@dependabot rebase` on it and report it as "needs rebase after #<earlier>"
rather than forcing it.

Never add attribution trailers or extra commit text; `gh pr merge` uses the
default merge message and that is what the repo expects.

## 6. Verify

```bash
gh pr list --author app/dependabot --state open --json number | jq length
git fetch -q origin <base> && git log --oneline origin/<base> -<count+1>
```

Open count should equal the number you held back. Every merged PR should appear
on the base branch. Say so plainly if either doesn't match.

## 7. Report

One table, merged and held-back together, then nothing else unless a held-back
PR needs a sentence of explanation:

| PR | Bump | Verdict |
|---|---|---|
| #189 | opentelemetry-instrumentation-net_http 0.29.1 → 0.29.2 | Merged. Patch. Adds otel logs-api and metrics-api as new transitive gems. |
| #186 | webmock 3.26.4 → 3.30.0 (dev) | Merged. Only removal is `to_rack` session; repo doesn't use it. |
| #184 | rails 7.2 → 8.0 | Held. Major. Needs manual review. |
| #183 | nokogiri 1.16.1 → 1.16.2 | Held. `system-test` check failed. |

Link PR numbers to the repo's PR URLs. Lead with the count merged and the count
held, then the table. Mention anything that changed base mid-run (another PR
landing) in one line only if it affected a merge.
