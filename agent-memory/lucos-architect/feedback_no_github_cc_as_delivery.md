---
name: no-github-cc-as-delivery
description: GitHub @-mentions and "cc" prose in issue bodies / PR comments do not notify agents — they're signage for humans, not delivery. If you want a teammate to see something on a ticket, SendMessage them with the URL.
metadata:
  type: feedback
---

A `cc'ing @lucos-foo` line in a GitHub issue body or PR comment does NOT deliver a notification to that agent. Agents only receive ticket context via SendMessage or by being told a URL and fetching it.

**Why:** Agents have no GitHub notification subscriptions; they don't poll the notifications API; mentions only render to human readers. The failure mode is silent — the cc renders in the UI, the author moves on assuming delivery, and the recipient gets nothing.

**How to apply:** If you want a teammate to see something on a ticket, do both — write the cc for human readers AND `SendMessage` the teammate directly with the URL and a one-line "FYI, may be relevant to your X" framing. Don't route through team-lead unnecessarily; direct delivery saves a round-trip.

The canonical rule lives in [`references/teammate-communication.md`](../../references/teammate-communication.md) under "GitHub cc / @-mentions do not notify teammate agents". This memory is the persona-local pointer.

**Surfaced by:** 2026-05-28 — wrote a `cc'ing \`lucos-site-reliability\`` line in the ADR-0008 PR comment on `lucas42/lucos#199`. SRE never saw it. lucas42 caught it and team-lead had to SendMessage SRE manually. The fix was consolidation — the rule previously lived in two persona-local copies (coordinator and SRE) but not in the shared reference. Now in the shared reference, with the SRE duplicate removed.
