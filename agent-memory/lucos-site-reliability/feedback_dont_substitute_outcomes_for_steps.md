---
name: Don't substitute an outcomes-style summary for the documented step list when wrapping up a procedure
description: At the end of a documented procedure, re-read the reference's step list and tick each step explicitly — don't summarise by outcomes alone
type: feedback
---

When wrapping up a documented multi-step procedure (incident reporting, ops checks, triage, estate rollouts, etc.), do not write your own outcomes-style "Done with this:" bullet list as the completion check. Re-read the reference document's actual step list and tick each step explicitly.

**Why:** Outcomes-style bullets are biased toward visible deliverables (diagnosis ✓, PR shipped ✓, follow-up filed ✓, memory recorded ✓) and silently drop steps that don't have an obvious deliverable to mirror — *actions* like "broadcast a notification" or "notify team-lead" are the most-skipped because there's no artefact to bullet at the end. Bit me on 2026-05-09 in the lucos_creds CRLF/snapshot incident: I shipped the report, drove the review loop, filed the follow-up, recorded memories — and then declared done without sending the post-merge team broadcast required by `references/incident-reporting.md` Step 3. The broadcast is a documented step I'd read multiple times in the persona file's pointer to that doc, but my "Done with this incident" wrap-up substituted my own outcomes list and the documented step disappeared from view.

**How to apply:**
1. Before declaring done on any documented procedure, open the reference file (the actual one, not memory of it) and re-read the step headings.
2. Tick each documented step explicitly in your wrap-up message, including the unsexy denouement steps that don't produce deliverables.
3. The structural fix (a "completion checklist" section at the end of the procedure doc, with a checkbox per step) is the durable mitigation; this memory is the behavioural backstop until that lands. team-lead has signalled the structural change is worth doing — held pending architect input as of 2026-05-09.
4. Generalises beyond incident reporting: the same trap exists in ops-check wrap-ups, triage hand-offs, estate rollouts, and any documented multi-step flow.

**Addendum 2026-05-09 — the wrap-up gap had a second compounding cost:**

The broadcast step itself, even after I belatedly executed it, was misconfigured. `references/incident-reporting.md` Step 3 told me to call `SendMessage (type: broadcast)` — but the SendMessage tool has no broadcast type, and `to: "broadcast"` lands the message in a phantom inbox that no teammate is listening on. The system response (`"Message sent to broadcast's inbox"`) is the literal truth — there *is* a phantom "broadcast" inbox — but it's misleading: the message reaches nobody. This is partly cause (a wrong instruction caused me to send into a black hole) and partly consequence (the wrap-up gap meant I didn't catch the silent failure mode myself by checking whether anyone had received it).

So the lesson is two-layered:

- **Behavioural** — when wrapping up a procedure, tick each documented step *and* sanity-check that the step actually had its intended effect (especially for steps that produce no follow-up signal — "I sent X" with no acknowledgement is a place to look for silent failures).
- **Tool-shape** — `SendMessage` has no broadcast type. To notify multiple teammates, send individual SendMessage calls in parallel (one per recipient) within a single response. The recipient list for whole-team notifications excludes the sender and the coordinator (team-lead): so the typical fan-out is `lucos-architect`, `lucos-code-reviewer`, `lucos-developer`, `lucos-security`, `lucos-system-administrator`, `lucos-ux` (six recipients). team-lead is fixing the reference doc so the next reporter doesn't hit the same trap; this memory captures the direct lesson regardless of doc state.
