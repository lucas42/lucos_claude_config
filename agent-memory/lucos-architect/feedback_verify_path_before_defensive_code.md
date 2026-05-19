---
name: verify-path-before-defensive-code
description: Before architecting defensive code for a hypothetical state, run the cheap falsifying check that a real code path produces that state
metadata:
  type: feedback
---

When proposing defensive code for a scenario ("X might happen when Y"), run the cheap falsifying check that a real code path actually produces the scenario, before committing the defence to a ticket body or an architecture review. The check is usually a single grep / one read of the relevant write path. The cost of skipping it is multiplied across every consumer who acts on the ticket as if the scenario were real.

**Why:** I architected lucas42/lucos_media_metadata_api#138 (`contactDeleted` handler — implemented and shipped via PR #243) and lucas42/lucos_media_metadata_api#139 (`contactUpdated` handler — in flight as PR #244) on the premise that media tags might hold `contacts.l42.eu` URIs via a "pre-link window" scenario. lucas42 asked the obvious question on 2026-05-19: "which contact URIs does the media ecosystem already know about?" The answer was none. `eolas:thing_create` always returns eolas URIs; nothing in the media write path produces a contacts URI; the PHP frontend has no contacts integration. The "pre-link window" was hypothesised, not traced. A 30-second grep would have falsified it before I filed either ticket.

The downstream cost was real: a shipped handler that needs removing (#248), a draft PR (#244) requiring rework, an SSRF-mitigation ticket (#245) with the wrong allowlist, and architect time across multiple chats. All for a scenario that doesn't arise.

**How to apply:** Whenever a ticket body or design contains the words "in case X happens" / "for the scenario where Y" / "if Z is ever in state W", before publishing, run a single targeted check: name the file/function that produces X/Y/Z/W. If you can't, the defence is hypothetical and the ticket needs reframing as "if we ever decide to support X, we'll need to handle Y" — not as a defensive feature for a state that already exists. Related: [[grep_and_conclude_anti_pattern]] (the converse failure mode: grep finds nothing and you conclude nothing's there; this is the inverse: you assume something's there and don't grep at all), [[check_value_when_fix_complexity_grows]] (when the defence grows new components, check the premise first).
