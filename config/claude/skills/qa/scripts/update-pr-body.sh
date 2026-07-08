#!/usr/bin/env bash
# Idempotently write a QA plan into a PR description. Reads the QA-plan markdown
# from stdin and inserts/replaces it inside marker comments, so re-running just
# refreshes the section instead of stacking duplicates.
#
# Usage:  update-pr-body.sh [url|number]   (QA-plan markdown on stdin)
set -euo pipefail

arg="${1:-}"
repo="$(gh repo view --json nameWithOwner -q .nameWithOwner)"

plan="$(cat)"
if [[ -z "${plan// /}" ]]; then
  echo "ERROR: no QA-plan markdown received on stdin." >&2
  exit 1
fi

if ! current="$(gh pr view $arg --repo "$repo" --json body -q .body 2>/dev/null)"; then
  echo "ERROR: no PR found for '${arg:-current branch}'. Create one first (gh pr create)." >&2
  exit 1
fi

new="$(QA_PLAN="$plan" python3 - "$current" <<'PY'
import os, re, sys
body = sys.argv[1] or ""
plan = os.environ["QA_PLAN"].strip()
start, end = "<!-- QA-PLAN:START -->", "<!-- QA-PLAN:END -->"
section = f"{start}\n## 🧪 QA Plan\n\n{plan}\n{end}"
pat = re.compile(re.escape(start) + r".*?" + re.escape(end), re.DOTALL)
if pat.search(body):
    body = pat.sub(lambda _: section, body)
else:
    body = (body.rstrip() + "\n\n" + section) if body.strip() else section
print(body)
PY
)"

gh pr edit $arg --repo "$repo" --body "$new"
echo "QA plan written to PR description."
