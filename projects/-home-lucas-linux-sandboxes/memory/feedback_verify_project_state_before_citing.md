---
name: feedback-verify-project-state-before-citing
description: Never cite a project-state claim (parked / deferred / on hold / completed) from a MEMORY.md index line without re-reading the underlying memory file AND verifying against the live ticket/board
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 95dd3212-10dc-4f8f-9047-e18d6d22e7d3
---

When about to write a project-state claim into a durable artefact — a triage comment, an AskUserQuestion, a SendMessage to a teammate, a PR body — verify the claim against current ground truth before posting. "Currently parked", "deferred", "completed", "on hold", "no longer a priority" all qualify. Do NOT rely on a one-line MEMORY.md index entry as authoritative.

**Why:** On 2026-05-18 I posted triage comments on `lucos_media_metadata_api#238`/`#239`/`#240` claiming "the broader v2→v3 migration was parked on 2026-04-05". This was false: the linked memory file actually said the v3 migration was *completed* on 2026-04-08, and the MEMORY.md index line was stale and never updated to match. To compound it, I was also conflating two different work streams — the v3 *API* migration (completed) and the v3 *controlled-vocabulary* migration (never started, the thing #140 had tracked). Lucas42 had to ask "what parked migration are you referring to?", at which point I had to verify, walk back the comments, and rewrite them.

**How to apply:**

1. **Read the actual memory file**, not just the MEMORY.md index line, before citing any project status. The index line is a navigation hint, not authoritative content. If the two contradict, the file content wins — and that's a signal to fix the index line in the same edit.
2. **Verify against the live source.** For "parked / deferred" claims, the ticket itself (Status field, recent comments, lucas42's last statement) is the source of truth. A memory file describing project state is by construction a snapshot — it can be weeks or months old.
3. **Watch for work-stream conflation.** "v3 migration" might mean two completely different things in the same repo. If a memory line uses a short name, check it actually refers to the work stream you're triaging before citing it.

See [[feedback-refetch-before-accusing]] (same pattern, applied to teammate-state claims) and [[feedback-phantom-teammate-messages]] (same pattern, applied to fabricated quotes). All three are variants of "verify against ground truth before durable post".
