---
name: feedback-priority-field-vs-severity
description: Board Priority field is not the same axis as my severity rating — team-lead can set Priority below my severity without contradicting it
metadata:
  type: feedback
---

Team-lead set Priority = Medium on lucas42/lucos_agent_coding_sandbox#102 (docker-group root-equivalent access) after I'd recommended High. My severity write-up ("High not Critical: requires prior access, so below the private-advisory bar; not P3 either, ceiling is full host compromise") was left untouched on the record — only the board's Priority field was overridden.

**Why:** `docs/priorities.md` reserves the High *priority* tier for the active strategic priority, current alerts, or genuinely urgent work. #102 describes a long-standing, static condition (true since docker group membership was granted, unchanged by my finding it today) that requires prior SSH-key/agent-session compromise to exploit — not an active or imminent trigger. Priority = queue urgency relative to other work; Severity = technical impact/likelihood if exploited. The two axes can legitimately diverge: a High-severity finding on a static, prior-access-gated condition can sit at Medium priority without the finding being under-weighted, as long as it's genuinely queued (Awaiting Decision, not silently parked) and my severity language isn't rewritten.

**How to apply:** Don't treat a Priority-field override as a disagreement with my severity assessment — check whether my severity text was left intact (it was here) before deciding whether to push back. Only escalate/push back if either (a) the underlying severity analysis itself gets diluted/rewritten, or (b) the item is moved somewhere that reads as "ignored" rather than "queued" (e.g. Ideation instead of Awaiting Decision/Ready). Being invited to disagree and declining because the reasoning is sound is a legitimate outcome, not a cave — no need to relitigate every Priority-field call that comes with a clear rationale.
