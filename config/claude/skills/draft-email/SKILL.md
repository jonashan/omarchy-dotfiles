---
name: draft-email
description: Draft an email in Jonas's voice (warm, fast, human, usually Danish) and save it as a Gmail draft for review — never send. Use when Jonas says "draft an email", "write a reply to...", "skriv en mail til...", "svar på denne mail", "help me reply", or runs /draft-email. Works from a description of what to say, or from an existing thread to reply to.
---

# Draft Email

Write emails that sound like Jonas and save them as **Gmail drafts** for his review.
The full style guide lives in `tone-of-voice.md` next to this file — **read it first,
every time.**

## Hard rules
- **Never send.** Always create a draft with `create_draft` (or `create_draft` on the
  thread for replies). Sending is Jonas's call.
- **Default to Danish.** Switch to English only if the recipient/thread is in English.
- **Match the register** to the recipient (customer / colleague / sales) per the tone guide.
- **Show the draft in chat** and ask if it should be adjusted or saved as-is.
- **Never write a signature/sign-off block.** Gmail appends the signature (`Med Venlig
  Hilsen`, name, title, phone, links) automatically. End the draft on the last line of
  the actual message — no closer, no name.
- **Never invent product/data facts.** If a reply asserts how TeamEffect behaves (a
  feature, setting, data field, etc.), verify it against the product repo at
  `/home/jonas/Work/TeamEffect/` first, or ask Jonas. Don't guess column names,
  settings, or capabilities.
- **When in doubt about what to answer, ask Jonas** (use AskUserQuestion) rather than
  guessing — especially on product/data specifics.

## Procedure

### 1. Read the tone guide
Read `tone-of-voice.md` in this skill's directory. It defines greetings, sign-offs,
length, emoji use, softeners, and per-audience register.

### 2. Gather context
- **Replying to a thread?** Use `search_threads` to find it (or take the thread ID
  Jonas gives), then `get_thread` (FULL_CONTENT) to read what's being answered.
  Note the recipient's name, language, and tone (do they open with `Kære` or `Hej`?).
  Threads can be large — if `get_thread` overflows, the result is saved to a file;
  use `jq -r '.messages[] | select(.sender|test("..."))| .plaintextBody'` to extract
  just the relevant bodies.
- **New email?** Get the recipient and the gist from Jonas. Ask only what you can't
  infer (recipient address, the one key fact you're missing) — don't over-interview.

### 3. Identify the audience and pick the register
- Customer (municipal staff/IT/leaders) → warm, reassuring, solution-first, a smiley.
- Colleague (e.g. Peter, Mathias) → brief, casual, banter ok, often no greeting.
- Sales/commercial → pragmatic, risk/value framing, still relaxed.

### 4. Draft it
- Greeting: `Hej [Fornavn]` (or none for quick colleague replies).
- 1–4 sentences, one idea. Lead with the answer or the acknowledgement.
- **Phrase tasks as already done** ("Det er hermed klaret", "Det er på plads nu") —
  Jonas usually replies after he's done the work. Avoid "jeg vender tilbage" / "jeg
  kigger på det". See the tone guide.
- Add a softener and an emoji where it fits naturally. Close by lowering the barrier
  (offer a call / next step) when relevant.
- **No sign-off block** — Gmail adds the signature itself. End on the last line of the
  message; never type `Med Venlig Hilsen`, your name, or contact details.
- Read it back against `tone-of-voice.md`. Cut anything corporate or stiff.

### 5. Save as draft
- Present the draft text in chat.
- Create the Gmail draft with `create_draft`, using `replyToMessageId` = the **last**
  message id in the thread (so it threads correctly) and `to` = the sender you're replying to.
- Tell Jonas it's saved and ask whether to tweak it. **Do not send.**

### 6. Return a todo list (when drafts claim completed actions)
Because drafts are written as already-done, any reply that asserts an action was taken
(e.g. "Mikkel har nu samme rettigheder", "Den er slået til for jer nu", "vedhæftet")
implies Jonas still has to actually do it. After saving the drafts, give Jonas a short
checklist of the concrete actions to perform before sending each one (incl. anything
the draft promises as attached).

## Notes
- The tone guide is a living document. If Jonas corrects a draft's voice, update
  `tone-of-voice.md` so future drafts improve.
- **No update/delete-draft tool exists.** To revise a draft, create a new one and tell
  Jonas which old draft to discard (identify it by its distinguishing wording).
- Thread fetches can overflow to a file; use the `jq` extraction in step 2
  (`.sender` / `.plaintextBody`) to read just the relevant message bodies.
