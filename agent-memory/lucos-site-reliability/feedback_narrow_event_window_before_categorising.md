---
name: narrow-event-window-before-categorising
description: When characterising the "client mix" / "error mix" / "source mix" of an incident burst, filter to the incident's time window before counting categories — counts over a wider range produce misleading cross-client claims.
metadata:
  type: feedback
---

# Narrow the event window before counting categories

When characterising the client mix, error-message mix, or source mix of an incident burst, the first thing to filter on is **the incident's time window** — not "today", not "this week". Counting over a wider range silently buckets unrelated background events into the burst's category distribution and produces false-positive cross-client / cross-source narratives.

**Why:** On 2026-05-18 I reported that a 79-error track-error burst (14:46–15:00 UTC) was cross-client (browser + mpg123), supporting an xwing-NAT-blip theory. The mpg123 count came from filtering `today's lastErrorMessage` events — which included mpg123 errors at 02:11Z, 08:41Z, 09:19Z that were scattered across the day, **none** during the 14:46–15:00 burst. Re-running the count with the proper window filter showed all 81 burst-window errors were browser-only. The cross-client claim was an artefact of my bucket boundary. Sysadmin's investigation pursued an upstream-network theory partly on the strength of that claim.

**How to apply:** Before saying "the burst was X% A and Y% B" or "two unrelated clients hit the same failure", explicitly define and filter to the burst's [start, end] window. Aggregate buckets only over that filtered set. Distinguish in the writeup between "characteristics of the burst" (filtered) and "characteristics of the day" (unfiltered) — and prefer the former for causation arguments.

Related: [[no-attribution-overclaim]] — same hygiene applied to what other people said. Both rules trace to the same root: be specific about scope before making claims that ride on the scope being right.
