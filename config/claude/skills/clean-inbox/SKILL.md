---
name: clean-inbox
description: Clean up Jonas's Gmail inbox by archiving noise (newsletters, promos, notifications, stale info mail) and reporting back what actually needs attention — plus what changed in any archived status/monitoring report. Never deletes. Use when Jonas says "clean my inbox", "ryd op i min indbakke", "archive the noise", "inbox zero", "triage my email", or runs /clean-inbox.
---

# Clean Inbox

Archive the noise, hand back a short brief of what matters.

## Hard rules
- **NEVER DELETE.** No `trash_message`, `trash_thread`, `mark_*_spam`, or
  `apply_sensitive_*_label`. Archiving only — everything stays searchable.
- **Archive = remove `INBOX`**: `unlabel_thread(threadId, ["INBOX"])`. Nothing else.
- **Never archive unread mail from a human** without it appearing in the brief.
- When unsure whether something is noise → **leave it in the inbox** and list it.
- Don't mark things read, don't unstar, don't move to user labels.

## Procedure

### 1. Pull the inbox
`search_threads` with `query: "in:inbox"`, `pageSize: 50`, default view (gives
subject + snippet + sender + labels). Paginate with `pageToken` until the inbox is
covered or you hit ~200 threads — if there are more, say so and offer to continue.

### 2. Bucket every thread

**Archive** (noise):
- Newsletters, digests, marketing/promos, `category:promotions`, "unsubscribe" mail.
- Automated notifications already actioned or non-actionable: CI passed, PR merged,
  build succeeded, backup completed, deploy OK, calendar acceptances, receipts for
  known recurring charges.
- Social/product noise: LinkedIn, Slack/Linear/GitHub digests, app announcements.
- **Stale info mail**: event invites/reminders whose date has passed, "server going
  down tonight" for a night that already passed, expired offers, threads whose
  question was answered later in the same thread.
- Status/monitoring reports — but read them first, see step 3.

**Keep** (leave in inbox):
- Anything from a real person addressed to Jonas that expects a reply.
- Customers, colleagues, anything mentioning TeamEffect customers/incidents.
- Bills, contracts, legal, tax, security alerts, password/2FA/account changes.
- Anything with an open action, deadline, or a future date still ahead.
- Unresolved errors, failing jobs, active alerts.

### 3. Status / monitoring reports — diff before archiving
For each recurring automated report (uptime, performance, error digests, cost
reports, security scans, backups):
1. `get_thread` with `messageFormat: "PLAIN_TEXT"` and pull the key numbers /
   incidents.
2. Find the previous one: `search_threads` with e.g.
   `from:<sender> subject:<subject-ish> -in:inbox older:<this one's date>`, then
   `get_thread` the most recent hit. **Gmail's archive is the state store — do not
   write a state file.**
3. Compare. Report anything that moved meaningfully (>~20%, or a threshold crossed),
   plus **any incident/outage/downtime mentioned — including ones already resolved.**
   Resolved-but-happened is exactly the thing Jonas wants surfaced.
4. Then archive it.

If there's no previous report to compare against, say "first one seen" and just
report the current numbers.

### 4. Archive
Archive one thread at a time with `unlabel_thread(threadId, ["INBOX"])`. If a call
fails, note it and carry on — don't abort the run.

### 5. Report back
Output in this shape, tightest form possible:

```
## Needs you (N)
- <sender> — <subject> — <why, one line>

## Changed / incidents
- <report>: <metric> 120ms → 310ms (+158%)
- <report>: outage 02:14–02:41 on 2026-08-30, resolved — root cause: <x>

## Archived (N)
- 14 newsletters, 9 CI notifications, 3 expired invites, 2 status reports
  (grouped by kind, not one line each — name only anything borderline)

## Left alone, unsure (N)
- <sender> — <subject> — <why unsure>
```

Empty sections: drop them. If nothing needed archiving, say so in one line.

## Notes
- Thread fetches can overflow to a file; if so use
  `jq -r '.messages[].plaintextBody'` to read just the bodies.
- Batch the reading: `search_threads` snippets are usually enough to bucket. Only
  `get_thread` for status reports and genuinely ambiguous threads.
- To undo an archive: `label_thread(threadId, ["INBOX"])`.
