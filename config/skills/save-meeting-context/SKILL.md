---
name: save-meeting-context
description: Sync new meetings from Circleback into Obsidian vault and Google Drive. Use this skill whenever the user asks to sync meetings, save meeting notes, update the vault with new meetings, run the meeting context workflow, or anything related to saving or archiving meeting data. Also triggers for phrases like 'check for new meetings', 'update my meeting notes', 'sync Circleback', 'save today's meetings', or 'meeting backup'. Even if the user doesn't mention Circleback or Obsidian by name, use this skill when they're asking about meeting notes, transcripts, or meeting archival.
---
 
# Save Meeting Context
 
Sync new meetings from Circleback into Jonas's Obsidian vault and Google Drive. This is an automated workflow — run it fully without asking clarifying questions.
 
---
 
## Step 1: Check existing meetings in Obsidian
 
List all `.md` files in `/home/jonas/Documents/SecondBrainNew/04. Meetings/` to know which meetings are already saved. The filenames follow the pattern `YYYY-MM-DD - Meeting Name.md`. Keep this list in mind — you'll use it to skip meetings that already exist.
 
---
 
## Step 2: Fetch recent meetings from Circleback
 
Use `SearchMeetings` to find meetings from roughly the past 7-14 days (adjust the window if needed to catch anything that might have been missed). Page through results if 20 are returned.
 
---
 
## Step 3: Identify new meetings
 
Compare the Circleback results against the existing Obsidian files. A meeting is "new" if there is no file in the Meetings folder whose name matches the meeting date and title. When in doubt (e.g. slight title differences), treat it as already synced to avoid duplicates.
 
---
 
## Step 4: For each new meeting, fetch full details
 
For each new meeting, make two parallel calls:
- `ReadMeetings` -- to get the full notes, action items, and attendee list
- `GetTranscriptsForMeetings` -- to get the full transcript
If fetching transcripts for many meetings at once causes context overflow, fetch them one at a time.
 
---
 
## Step 5: Format and save to Obsidian
 
Create a `.md` file at `/home/jonas/Documents/SecondBrainNew/04. Meetings/YYYY-MM-DD - [Meeting Name].md`.
 
### Obsidian document format
 
The file should follow this structure:
 
    ---
    created_at: YYYY-MM-DD HH:MM
    Id: YYYYMMDDHHMMss
    tags:
      - meeting
    people:
      - "[[Person Name]]"
      - "[[Person Name]]"
    related_to:
      - "[[TeamEffect]]"
    ---
 
    # YYYY-MM-DD - [Meeting Name]
 
    ## Agenda
    -
 
    ## Notes
    [structured notes from Circleback]
 
    ## Action Items
    - Action item (**Assignee** if known)
 
    ---
 
    ## Transskript
    | Tid | Taler | Tekst |
    |-----|-------|-------|
    | M:SS | Speaker Name | What they said |
 
### Key formatting rules
 
**YAML frontmatter:** Include created_at, Id, tags, people, and related_to. The people field should list all attendees as wiki-linked names where known (e.g. "[[Jonas Steen Christensen]]"). If only a first name is known, use that without wiki-link brackets.
 
**Identifying anonymized participants:** Circleback sometimes anonymizes attendees as "Participant 4", "Participant 5", etc. Before writing the document, scan the transcript for self-introductions (e.g. "jeg hedder X", "I'm X", "my name is X") to identify the real names behind these placeholders. Also use context from the notes -- if a Participant is described doing something specific, cross-reference with known team roles. Known TeamEffect team members:
- Jonas Steen Christensen (CTO -- coding, IT revision, technical work)
- Peter Christensen (Director/Sales -- customer meetings, deals, contracts)
- Mathias Kudahl Laursen (Developer -- PRs, landing pages, reports, frontend)
**Attendee wiki-links:** Any attendee whose full name is known should be written as [[First Name Last Name]] in the people frontmatter field and anywhere they appear in notes and action items. Jonas himself should always be [[Jonas Steen Christensen]]. People with only a first name known can be listed without wiki-link brackets.
 
**Action items:** Use bullet points (-), never checkboxes (- [ ]). Bold the assignee's name if known.
 
**Transcript timing:** Convert the raw timestamp (seconds) to M:SS format (e.g. 65.3 = 1:05). Use the speaker's real name if known; fall back to "Participant X" if not. Use wiki-links for known speakers in the transcript table.
 
**Notes language:** Keep the notes in whatever language Circleback wrote them in (typically Danish). Don't translate.
 
---
 
## Step 6: Upload to Google Drive
 
Upload the same .md file to Google Drive using the create_file tool from the Google Drive MCP (mcp ID: 2536b1c0-97bf-46e0-bbd0-8e85bc410462).
 
**Target folder:** 1ioi_ADqGVMhs1vtqLY6whFRbG5sB9vao
(This is: AI Vault > Meetings > Jonas Steen Christensen)
 
**How to upload:**
1. Base64-encode the markdown file content (use base64 -w 0 in bash to get a single-line string)
2. Call create_file with:
   - title: the meeting name with .md extension (e.g. "2026-04-22 - Daily Standup.md")
   - mimeType: text/markdown
   - parentId: 1ioi_ADqGVMhs1vtqLY6whFRbG5sB9vao
   - content: the base64-encoded string
   - disableConversionToGoogleType: true (keeps it as a markdown file, not a Google Doc)
The Google Drive file should include everything: frontmatter, notes, action items, AND the full transcript.
 
---
 
## Step 7: Report
 
After processing all new meetings, briefly report:
- How many new meetings were found and saved
- Meeting titles and dates
- Confirmation that both Obsidian and Google Drive were updated
If no new meetings were found, say so clearly.
