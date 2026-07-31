---
name: ticket-body-is-the-spec
description: Rewrite issue title+body when a design changes OR when adding an acceptance criterion — a comment is never the spec, because /dispatch sends the URL alone. Never claim elsewhere that a comment "added" it
metadata:
  type: feedback
---

When my analysis **supersedes the approach stated in an issue's body** (a walk-back, a reframe, an architect-ratified replacement), updating the ticket's **title and body** is part of posting the replacement design — not follow-up housekeeping. A comment further down the thread does not update the spec.

**Why:** `/dispatch` sends the issue **URL alone** — deliberately, so the ticket stays the single authoritative spec (see [[feedback_dispatch_url_only]] in the coordinator's conventions). An implementer picking a Ready ticket reads the **body first**. On lucos_backups#344 the body still specified `backup_strategy: "sqlite"` + `sqlite3 ".backup"` — the exact design lucas42 rejected on 2026-06-17 — while the agreed engine-agnostic quiesce design existed only in a comment. It sat Ready/High/Owner=me for ~3 weeks; whoever picked it up would have built the rejected design. lucas42 spotted it, not me. Same defect on #345.

**How to apply:**
- Posting a replacement design on an issue → immediately PATCH title + body to match. Rewrite the **problem framing** too, not just the "Proposed fix" section: #344's body framed the defect as SQLite-specific when the real defect was a live-read smear affecting any in-place-writer engine (and the incremental rsync path the old body never mentioned).
- Strip sections answered by the walk-back (e.g. a "Scope decision for triage" block whose question was settled weeks ago) — a stale open question invites re-litigation of a settled decision.
- **Close superseded PRs at the same time.** #346 sat open as a draft implementing the walked-back design. Beyond the stale-spec risk, an open PR cross-referenced from the issue trips `/dispatch`'s existing-PR guardrail and reports the work as already done. My own housekeeping note called for closing it and it still didn't happen — because "when it's picked up" is nobody's trigger. Do it when the design changes.
- **Don't set board disposition** on the folded-in sibling — flag close-vs-keep to the coordinator ([[feedback_flag_followup_disposition_to_coordinator]]).

- **This applies to ADDING an acceptance criterion, not just replacing a design.** A teammate's new constraint posted as a comment is invisible to an implementer reading the body. 2026-07-31, lucos_media_metadata_manager#389: lucos-security supplied a real criterion (the 500 page must not depend on the app's own bootstrap/auth/API code); I posted it as a **comment**, then wrote in the incident-report PR body that it "has been added to #389". lucos-code-reviewer caught it by reading the actual body instead of believing my description. I had applied this very rule to #388's respec an hour earlier in the same session — so the failure wasn't ignorance of the rule, it was not firing it for the *additive* case. **Comment = discussion; body = spec. Always.**
- **Never assert elsewhere that a ticket "has" something without re-fetching its body.** Same session, same shape as three other errors that afternoon: trusting the name of the action I'd taken ("I added the criterion") over the artefact's actual contents. After any PATCH, re-fetch and grep for the new text before citing it in a PR body, report or message. See [[feedback_refetch_state_before_writing_final_artifact]].

Trigger phrase to self-check: *"if someone read only this body, what would they build?"*

Related: [[project_backups_db_consistency_walkback]] for the design content itself.
