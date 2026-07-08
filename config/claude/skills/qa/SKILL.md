---
name: qa
description: Build a step-by-step QA / manual-test plan from the commits a PR (or the current branch) adds, then save it onto the PR description. Use when the user says "create a QA plan", "write a test plan", "qa this PR", "how do I test this PR", or runs /qa. Operates on the PR for the current branch by default, or a PR passed as a URL or number.
argument-hint: "[PR url or number — defaults to the current branch]"
---

# QA Plan

Turn the changes a PR introduces into a concrete, step-by-step QA plan a human can
follow to manually verify **every part** of the new implementation, then write that
plan into the PR description (idempotently — re-running refreshes the section, never
stacks duplicates).

## Scripts

Under `scripts/` (relative to this file). Run with `bash <skill-dir>/scripts/<name>`.

| Script | Purpose |
|---|---|
| `pr-diff.sh [url\|number]` | Resolve the target PR (or current branch) and print metadata + the commits, changed files, and full diff vs. the base branch. This is the source material for the plan. No arg → PR/branch checked out now. |
| `update-pr-body.sh [url\|number]` | Read QA-plan markdown on **stdin** and insert/replace it inside `<!-- QA-PLAN -->` markers in the PR description. |

## Steps

### Step 1 — Gather the changes

```bash
bash <skill-dir>/scripts/pr-diff.sh "$ARG"   # $ARG = the URL/number, or empty
```
- Read the `=== META ===` header for the PR `number`/`url`/`base`/`head`.
- If the script reports **no PR exists** for the branch: there's nowhere to save the
  plan. Ask the user whether to `gh pr create` first, or just print the plan in chat.
  Don't invent a PR silently.
- Read the commits, changed files, and full diff. This — not assumptions — is what the
  plan must be grounded in.

### Step 2 — Understand the implementation

Work through the diff and group it into the distinct, user-observable pieces of behavior
it adds or changes. For anything the diff references but doesn't show, read the
surrounding files so each test step is concrete. For every piece, note:
- The **happy path** — what a user does and what should happen.
- **Edge cases & error states** — empty/invalid input, permissions, limits, missing data.
- **Setup/preconditions** — env vars, migrations, seed data, feature flags, accounts/roles.
- **Regression risk** — existing behavior near the change that could break.

### Step 3 — Write the QA plan

Produce markdown the author can follow top-to-bottom without reading the code. Structure:

```markdown
**What changed:** 1–2 sentence summary of the PR.

### Setup
- [ ] Prerequisites: branch checked out, migrations run, env/flags set, test accounts.

### <Feature / area 1>
1. <action to perform>
   - **Expected:** <observable result>
2. ...

### <Feature / area 2>
...

### Edge cases & error handling
- [ ] <invalid input / boundary> → **Expected:** <result>

### Regression checks
- [ ] <nearby existing behavior still works>
```

Rules:
- **Cover every part of the change** — each meaningfully changed feature/file gets steps.
  Don't summarize; enumerate.
- Steps are concrete and ordered: a click, a command, a request — each with an
  **Expected** result so pass/fail is unambiguous.
- Use `- [ ]` checkboxes so the author can tick items off in the PR.
- Skip nothing testable, but don't pad with steps unrelated to this diff.

### Step 4 — Save it onto the PR

```bash
bash <skill-dir>/scripts/update-pr-body.sh <number> <<'PLAN'
<the QA-plan markdown from Step 3>
PLAN
```
The script wraps the plan in `<!-- QA-PLAN:START -->` / `<!-- QA-PLAN:END -->` markers, so
re-running replaces the existing QA Plan section instead of appending a second one.

Finish by reporting the PR URL and a one-line summary of what the plan covers.
