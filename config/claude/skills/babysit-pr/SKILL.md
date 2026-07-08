---
name: babysit-pr
description: Babysit a GitHub pull request to green by looping until it is clean — keep it rebased on its base branch (resolving merge conflicts), and fix + reply to + resolve every CodeRabbit review comment, re-checking after each push until CI is green and no review threads remain open. Use when the user says "babysit the PR", "babysit this PR", "watch my PR", "keep my PR clean", "handle the CodeRabbit comments", "get this PR to green", or runs /babysit-pr. Operates on the PR for the current branch by default, or on a PR passed as a URL or number.
---

# Babysit PR

Drive a pull request to a clean state and keep it there: rebased on its base with no
conflicts, all CodeRabbit review threads addressed, and CI green. This runs as a
**self-paced loop** — each invocation does one pass, then schedules the next pass to
re-check after CI and CodeRabbit have had time to react, repeating until clean.

## Definition of "clean" (loop stops here)

All three must hold:
1. **No merge conflicts** — PR is rebased on its base; `mergeStateStatus` not `DIRTY`/`BEHIND`.
2. **No open CodeRabbit threads** — every unresolved CodeRabbit thread has either been
   resolved (fix applied) or replied-to with a decline rationale (see Step 3).
3. **CI green** — `statusCheckRollup` has no failing checks and none still pending.

When all three hold, report ✅ and **do not** schedule another pass.

## Scripts

All under `scripts/` (relative to this file). Run with `bash <skill-dir>/scripts/<name>`.

| Script | Purpose |
|---|---|
| `pr-context.sh [url\|number]` | Resolve the target PR and print its state JSON (number, base/head, mergeable, mergeStateStatus, failing/pending checks). No arg → PR for current branch. |
| `coderabbit-threads.sh <pr>` | List **unresolved** CodeRabbit review threads as JSON lines (threadId, path, line, firstCommentId, body, replyCount, lastAuthor). |
| `reply-resolve-thread.sh <pr> <commentId> <threadId> [--no-resolve]` | Reply (body on stdin) under a thread, then resolve it unless `--no-resolve`. |

Your GitHub login (for detecting your own replies): `gh api user --jq .login`.

## One pass

### Step 0 — Resolve the PR and checkout

```bash
bash <skill-dir>/scripts/pr-context.sh "$ARG"   # $ARG = the URL/number, or empty
```
- If a URL/number was given and it is **not** the current branch, check it out:
  `gh pr checkout <number>`. Otherwise stay on the current branch.
- Record `number`, `baseRefName`, `headRefName` for the rest of the pass.
- If `state` is `MERGED` or `CLOSED`: report it and stop (no more passes).

### Step 1 — Rebase on base, resolve conflicts

```bash
git fetch origin
git rebase origin/<baseRefName>
```
- **Clean rebase** → continue.
- **Conflicts** → resolve each one by understanding the intent of both sides (read the
  conflicting hunks, the surrounding code, and the PR's purpose). Then
  `git add <files>` and `git rebase --continue`. Repeat until done.
  - Honor project conventions in `CLAUDE.md` when resolving (e.g. ERB-only, Pundit, typo fixes).
  - **If a conflict is genuinely ambiguous or risky** (you can't confidently tell which
    side is correct, or resolving means dropping someone's logic), abort with
    `git rebase --abort`, stop the loop, and ask the user. Do not guess on risky merges.
- After a successful rebase that changed history, push:
  `git push --force-with-lease`. **Never** plain `--force`; **never** push the base branch.
- If nothing rebased (already up to date) and the tree is unchanged, skip the push.

### Step 2 — Address CodeRabbit threads

```bash
bash <skill-dir>/scripts/coderabbit-threads.sh <number>
```
For each thread returned:
- **Skip if already addressed**: `lastAuthor` equals your login → you already replied on a
  prior pass; leave it (counts as addressed, not open).
- **Read the comment** (`body`, `path`, `line`) and judge the suggestion:
  - **Valid** → apply the code fix. Match surrounding style and project conventions.
    Stage the fix (committed in Step 3). Then reply + resolve:
    ```bash
    echo "Fixed in <short note>." | bash <skill-dir>/scripts/reply-resolve-thread.sh \
      <number> <firstCommentId> <threadId>
    ```
  - **Invalid / nitpick you decline** → reply with a concise rationale and **do not resolve**
    (leave it for the human), using `--no-resolve`:
    ```bash
    echo "Declining: <reason>." | bash <skill-dir>/scripts/reply-resolve-thread.sh \
      <number> <firstCommentId> <threadId> --no-resolve
    ```
- Be honest: only resolve a thread when the underlying issue is actually handled.

### Step 3 — Commit and push fixes

If Step 2 changed files:
```bash
git add -A
git commit -m "fix(<scope>): address review feedback"   # Conventional Commits, see CLAUDE.md
git push --force-with-lease     # plain push if history wasn't rewritten this pass
```
Use one focused commit (or a few) — keep messages under 50 chars, lowercase, imperative.

### Step 4 — Assess and decide the next pass

Re-run `pr-context.sh <number>` and `coderabbit-threads.sh <number>`.

- **Clean** (all three conditions) → report ✅ with a short summary (conflicts resolved,
  threads handled, CI status). **Stop. Do not schedule another pass.**
- **Not clean** → schedule the next pass with `ScheduleWakeup`, passing the **same**
  `/babysit-pr` invocation back as the prompt, then end the turn. Pick the delay by what
  you're waiting on:
  - **Just pushed** (CodeRabbit will re-review, CI just started) → ~240s. Stays in cache;
    gives CodeRabbit time to post a fresh review before the next pass.
  - **Only waiting on slow CI** with nothing else to do → ~600–1200s.
  - **Threads still open that you haven't replied to** → loop immediately (do another pass
    now) rather than scheduling; there's actionable work.

## Loop & safety notes

- This skill is the loop driver via `ScheduleWakeup`. The user can also wrap it with
  `/loop /babysit-pr` — either way, each pass is idempotent and stateless (re-derives
  everything from the live PR), so re-running is always safe.
- **Stop and ask the user** (no further passes) when: a rebase conflict is risky/ambiguous,
  the PR is closed/merged, CI fails for a reason unrelated to review feedback that you
  can't fix from the diff (e.g. infra/flaky), or `--force-with-lease` is rejected because
  someone else pushed (don't clobber their work).
- Only ever force-push the **PR head branch**, and only with `--force-with-lease`.
- Surface failures faithfully: if CI is red, say which checks and why; never report clean
  while a check is failing.
