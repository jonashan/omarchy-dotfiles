---
name: review
description: Multi-angle code review — fans out parallel agents over the current branch (or a PR) for correctness & code patterns, data layer, accessibility (WCAG AA), security, and persona fit (driving the app in a browser as each affected user type), verifies every finding adversarially, then reports one deduped ranked list. Use when the user says "review this", "review the branch", "review this PR", "code review", or runs /review. Operates on the current branch by default, or a PR passed as a URL or number.
argument-hint: "[PR url or number — defaults to the current branch]"
---

# Multi-Angle Review

Up to five specialists read the same diff from angles that don't overlap, then a verifier
tries to kill every finding. What survives gets reported. Nothing else.

## Scripts

Under `scripts/` (relative to this file). Run with `bash <skill-dir>/scripts/<name>`.

| Script | Purpose |
|---|---|
| `pr-diff.sh [url\|number]` | Resolve the target PR (or current branch) and print metadata + commits, changed files, and the full diff vs. the base branch. No arg → PR/branch checked out now. Shared with the `qa` skill. |
| `dev-server.sh start\|stop` | Boot `bin/dev` for the browser pass and wait until it answers, or stop one this script started. Prints `STARTED`, `ALREADY RUNNING` (reuses it, refuses to stop it later) or `FAILED` + the log tail. Only the persona-fit agent runs this. |

## Step 1 — Gather the changes

```bash
bash <skill-dir>/scripts/pr-diff.sh "$ARG"   # $ARG = the URL/number, or empty
```

Then, if `git status --porcelain` is non-empty, also capture uncommitted work with
`git diff HEAD` and include it — a review of a dirty tree that ignores the dirt is wrong.

Read the diff yourself before dispatching. You need enough of it to write the angle
briefs and to judge findings later.

## Step 2 — Pick the angles that apply

Always run: **correctness**, **data**, **security**.

Run **accessibility** only if the diff touches frontend surface — `app/views/**`,
`app/components/**`, `app/javascript/**`, `app/helpers/**`, `*.erb`, `*.vue`, `*.jsx`,
`*.tsx`, `*.html`, or CSS. No frontend in the diff → skip it and say so in one line.
Drop **data** likewise if nothing touches `db/`, models, queries, or migrations.

Run **persona fit** only if the repo defines personas — `te-build/prd/personas.md` — *and*
the diff touches frontend surface. Read that file plus `te-build/prd/ux-principles.md`
before writing its brief; the personas are the spec, not your idea of a user.

Never invent a sixth angle. Never split one into two.

## Step 3 — Fan out

Spawn every applicable angle as a `general-purpose` agent, **all in one message** so
they run concurrently. Each agent gets: the full diff, the repo path, the shared
contract below, and its own brief.

### Shared contract (paste into every agent prompt)

> You are reviewing a diff. Read the surrounding code — the diff alone lies about
> context; open every file you cite and follow the callers.
> Report only defects that are real in **this** code. No style preferences, no
> "consider extracting", no praise, no summary of what the diff does.
> Before you report a finding, try to disprove it: find the guard, the validation, the
> callback, the middleware that already handles it. If you find one, drop the finding.
> Max 6 findings. If you have none, say `NO FINDINGS` — that is a good answer.
>
> Format every finding exactly as:
>
> ```
> - **[Critical|High|Medium]** `path/to/file.rb:123` — <one sentence: the defect>
>   - Fails when: <concrete input or state → the wrong outcome it produces>
>   - Fix: <one line>
> ```

### Brief: correctness

> Angle: logic bugs and code structure. Hunt: wrong conditionals and off-by-one,
> nil/empty/missing-key paths that raise, unhandled error branches, state mutated in the
> wrong order, `rescue` that swallows, background jobs assuming synchronous state, race
> conditions between requests.
> Also structure, but only where it's a defect and not a taste call: logic in a place
> that can't be reached by the other callers that need it, a concern or service object
> that duplicates something already in the codebase (grep before claiming it), a
> namespace that puts a class where nobody will find it, a pattern used inconsistently
> with the same pattern elsewhere in this repo. Match the repo's existing conventions —
> read a neighbouring file to learn them, don't import your own.
> NOT yours: SQL/query performance, authorization, accessibility.

### Brief: data

> Angle: the data layer. Hunt: N+1 queries (including ones hidden in views, serializers
> and ViewComponents), missing indexes for new lookups or foreign keys, queries loading
> more rows or columns than needed, `find_each` vs `each` on large sets.
> Migrations: destructive or irreversible steps, adding a NOT NULL column without a
> default or backfill, changes that lock a big table, migrations that break the currently
> deployed code (deploy runs before the new code on every box), missing `dependent:` on
> associations leaving orphans, validations without the matching DB constraint.
> Transaction boundaries: writes that should be atomic and aren't, external calls or job
> enqueues inside a transaction.
> NOT yours: application logic bugs, authorization, accessibility.

### Brief: accessibility

> Angle: WCAG 2.1 AA on the frontend this diff adds or changes. Hunt: images without
> meaningful `alt` (or missing `alt=""` when decorative), form inputs with no associated
> `<label>`, buttons/links whose only content is an icon and no accessible name, `<div>`
> or `<span>` given click handlers instead of a real `<button>`, keyboard traps and
> anything reachable only by mouse, missing or wrong focus management on modals,
> drawers and dynamically-inserted content, heading levels that skip, colour used as the
> sole carrier of meaning, contrast below 4.5:1 for text and 3:1 for UI/large text where
> the diff sets a colour, missing `aria-live` on async status updates, `aria-*` used
> where a native element would do the job.
> If the repo has `te-build/how-we-build/accessibility.md`, read it first and follow it
> where it is stricter or more specific than the list above — it is the house standard.
> Only judge markup and styles in the diff. Do not audit the whole app.
> NOT yours: logic bugs, queries, authorization, whether the screen suits its user.

### Brief: security

> Angle: security of what this diff changes. Hunt: missing or wrong authorization on a
> new endpoint or action (this repo uses Pundit — check the policy exists, is invoked,
> and scopes the collection, not just the record), mass-assignment via permissive strong
> params, IDOR — records fetched by id without scoping to the current user/account/tenant.
> Injection: string-interpolated SQL, `html_safe`/`raw`/`sanitize` on user input,
> unescaped output, command or template injection.
> Also: secrets or tokens committed or logged, PII written to logs, unvalidated redirects
> and file uploads, CSRF exemptions, auth/session/cookie changes, tokens compared without
> constant time, new external HTTP calls without timeouts or TLS verification, a new
> dependency pulled in for something trivial.
> NOT yours: general logic bugs, query performance, accessibility.

### Brief: persona fit

Only this agent may use the browser — never give two agents browser tools in the same run.

> Angle: does each changed screen fit the people who actually reach it? Read
> `te-build/prd/personas.md` and `te-build/prd/ux-principles.md` first — they are the spec.
>
> **Map before you judge.** For each screen in the diff, work out which personas can
> reach it, from the Pundit policy and role checks in the code (`Membership.role` —
> `employee` / `amr` / `leader` — plus the `customer_admin` and `hr` flags, and
> `te_admin`). A screen only `leader` reaches is not judged as a frontline screen.
>
> **Static pass (always).** Against each reaching persona's device, frequency and
> "Design implication" line, hunt: desktop-dense tables or multi-column forms on a screen
> frontline employees reach on a phone; a daily frontline interaction that takes more
> than ~30 seconds or more taps than it needs; tap targets, spacing or text sized for a
> mouse; an admin/HR screen missing the density, sorting, filtering or bulk actions that
> persona's work needs; an AMR view that isn't scoped and filtered to their area or lacks
> status / overdue signals; technical or code-heavy surface (raw ESAW codes and the like)
> exposed to frontline, which principle P1 forbids; a leader dashboard that shows data
> without a follow-up action; export missing where a decision-maker or caseworker needs
> it; a deadline that isn't first-class UI on a caseworker screen. Danish domain terms
> wrong or untranslated counts — check `te-build/prd/glossary.md`.
>
>
> **Browser pass.** Boot the app yourself:
>
> ```bash
> cd <repo> && bash <skill-dir>/scripts/dev-server.sh start
> ```
>
> - `STARTED` → it is yours. You **must** run `dev-server.sh stop` when the pass ends,
>   including on every failure path. Leaving a server running is a bug in the review.
> - `ALREADY RUNNING` → reuse it and never stop it; it is the developer's.
> - `FAILED` / `NO bin/dev` → read the log tail it printed, report the reason in one line,
>   and fall back to the static findings. Do not debug the environment or retry.
>
> Run **no** migrations and **no** seeds — booting a server is reversible, writing to the
> developer's database is not. If nobody can log in because the data is empty, say so and
> point at `bin/rails db:seed`.
>
> Get the login path from the app rather than assuming one:
> `bin/rails routes | grep -i login`. Read the seeded
> credentials out of `db/seeds/customer_data/profile.rb` (leader `anders`, AMR `fie`,
> employees share one password) — read the file, never guess a password.
> Then, for each reaching persona that has a login, **in sequence**: log in, resize to that
> persona's device (390×844 for mobile personas, 1440×900 for desktop ones), visit the
> changed screen, and walk its primary task.
> Report what you actually observe: content cut off or overflowing at that width,
> controls that can't be hit, a task needing far more steps than the persona's budget,
> a dead end with no way back, an empty state that says nothing.
> Ceiling: 3 personas, 2 screens each. If a login fails twice, end the browser pass and
> report the static findings — do not debug the environment. Whatever happens, if you
> started the server, stop it.
>
> A finding must name the persona and what it costs them. "Frontline employee on mobile
> hits a 4-column table" is a finding; "this could be more responsive" is not.
> NOT yours: WCAG conformance (that is the accessibility angle), logic bugs, queries,
> authorization *correctness* — though note it if a persona plainly sees a screen that
> isn't theirs.

## Step 4 — Verify

Collect every finding from every angle. Spawn **one** `general-purpose` verifier with
the full list, the diff, and:

> For each finding, decide CONFIRMED or REJECTED. Open the cited file and the code
> around it. Look for the thing that already prevents the failure: a validation, a
> `before_action`, a policy, a DB constraint, a default, a guard clause, a framework
> behaviour that handles it. Assume the author is competent and the finding is wrong
> until the code proves otherwise.
> CONFIRMED requires a concrete path: specific input or state, the line it reaches, the
> wrong result. "Could be a problem" is REJECTED. Something the framework already does
> is REJECTED. A style preference is REJECTED.
> A persona-fit finding is CONFIRMED only if it names a specific persona, the screen,
> and a concrete cost to that persona's task — and the persona genuinely reaches that
> screen. Findings the browser pass observed directly are CONFIRMED unless the cited
> element isn't in the diff. Taste ("feels cluttered") is REJECTED.
> Return each finding verbatim with its verdict and one line of reasoning.

Drop everything REJECTED. Do not argue with the verifier and do not resurrect findings.

## Step 5 — Report

One list, most severe first, deduped — the same defect found by two angles is one
finding, keep the clearer wording. Cap at 8; if more survive, keep the worst 8 and note
the count you dropped.

```markdown
**Reviewed:** <PR #N / branch> — <n> files, angles: correctness, data, security[, accessibility][, persona fit (browser|static)]

- **[Critical]** `path/file.rb:123` — <the defect>
  - Fails when: <input/state → wrong outcome>
  - Fix: <one line>

_Skipped: accessibility (no frontend in diff). Persona fit: browser pass on 3 personas (server booted and stopped)._
```

If nothing survives verification, say exactly that in one line. A clean review is a
result, not a failure — never pad it with nits to look thorough.

Report in chat. Only post to the PR if the user asks.
