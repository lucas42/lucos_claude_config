---
name: feedback_dispatch_url_only
description: "Dispatch messages carry only the issue URL — never restate the ticket's design"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 9dec23f5-2604-4ec2-a4fa-ad772fae61b5
---

# Dispatch messages: URL only, no design summary

When dispatching an issue to an implementer, the SendMessage body must be just `implement issue {url}` — nothing more. Do NOT restate, summarise, or "helpfully" highlight the ticket's design, decision, implementation notes, or "things easy to miss".

**Why:** The ticket is the single authoritative spec and the implementer reads it in full as step one. A design summary in the dispatch message is (a) redundant and (b) a second, unversioned copy that can drift from or contradict the ticket. On 2026-05-30, dispatching lucos_media_metadata_api#278, I padded the message with a design summary that described the **rejected** Option B (async defer) as the chosen approach — when the ticket plainly recorded **Option A (fail-fast)**, picked by lucas42. The ticket was correct; my embellishment was the sole source of the error and I had to send a correction. The padding added zero information and one serious bug.

**How to apply:** If you catch yourself typing "the design is…", "summary:", "key points:", "note that…", or pasting decision/option details into a dispatch SendMessage, STOP and delete it. If the ticket seems ambiguous or under-specified, fix the *ticket* before dispatching — don't compensate in the message. Also: never parallelise the dispatch SendMessage with the issue-fetch; that's how I sent a design description before reading the ticket. Related: [[feedback_no_options_in_consultations]] (same anti-pattern — don't inject my own framing of someone else's authoritative content).
