---
name: Incident report review completeness checks
description: Incident report review heuristics — incomplete actions tables, stale cumulative records, detector signal-class mismatches, and unverified linked follow-up issues all warrant REQUEST_CHANGES
type: feedback
---

## Rule 1 — Missing follow-up actions warrant REQUEST_CHANGES

When reviewing an incident report that correctly identifies a detection gap or systemic issue in its analysis section, but does NOT include a corresponding follow-up action in the actions table, **request changes** — do not approve with a note.

**Why:** Approvals end the review loop. Nobody reads review comments on an already-approved PR. A note in an approval is effectively invisible. The only way to ensure the follow-up gets recorded is to block the merge until it's added.

**How to apply:** If the analysis says "this wasn't caught because X" and there's no action item to fix X, post REQUEST_CHANGES asking the author to add the follow-up issue/action to the table before approving. This applies to incident reports, post-mortems, and any doc PR where completeness is the point.

Confirmed by lucas42: "Your follow-up suggestion wasn't considered because you approved the PR and no-one looks at it after that. Best to request changes when you have a suggestion like that. Be firm."

## Rule 2 — "(updated)" cumulative tables must be checked against prior reports

When a section is titled "Daily recurrence pattern (updated)" / "(continued)" / "(see also: prior report)", **verify the table or list is actually complete against the prior reports it references.** Specifically:

- Fetch the prior report files and compare row-by-row. A table that silently drops a prior row regresses the cumulative record even if the new entries are correct.
- The absence of a row is easy to miss on a diff-only review because diff only shows additions.

**Why:** Confirmed in lucos PR #197 (2026-05-26 seinn incident report) — the "Daily recurrence pattern (updated)" table dropped the 2026-05-21 row that the 2026-05-22 report had recorded. The "(updated)" framing created an implicit promise of completeness that wasn't met.

**How to apply:** For incident reports with a cumulative/longitudinal section, read the prior report(s) named in the section heading or body, and confirm every row/entry from those reports is either present in the new version or explicitly noted as excluded.

## Rule 4 — Daemon log quotes: Docker `"take affect"` is a confirmed upstream typo

When reviewing incident reports that quote the Docker daemon's live-restore warning, **`"will not take affect"` is correct** — it is Docker's own typo in `moby/moby daemon/daemon_unix.go:839`. Do NOT flag it as a report error. If there is no `[sic]`, suggest adding one with the source citation so future responders don't second-guess the spelling.

The message: `"there are running containers, updated network configuration will not take affect"` (note: "affect" not "effect"). Confirmed via GitHub code search on `moby/moby` — zero matches for "take effect", one match for "take affect" at `daemon_unix.go:839`. Surfaced during review of lucos PR #200 (2026-05-28 xwing incident TBD-fill).

## Rule 5 — Linked follow-up issues must be read directly, not trusted from the PR body's account of them

When an incident report's PR body or Follow-up Actions table claims something was "added to #N" or that a linked follow-up issue reflects a correction folded into the report, **fetch #N's actual current body and check** — don't take the claim at face value even from a careful, otherwise-accurate author.

Two independent failure modes to check for, both confirmed in the same PR (lucas42/lucos#274, 2026-07-31 media-metadata mbstring incident):

- **Stale pre-correction framing surviving in the linked issue.** A correction applied to the incident report itself (e.g. "the bare error page didn't actually delay the report") doesn't automatically propagate to a follow-up issue that was filed citing the old framing. `incident-reporting.md`'s "propagate factual corrections through every narrative section" names the report's own sections, but a linked follow-up issue is a narrative surface too — grep/read it for the same stale wording.
- **A claimed addition that isn't actually there.** The PR body asserted a specialist's (security's) acceptance criterion "has been added to #389"; the issue's actual Acceptance Criteria list didn't contain it. This is indistinguishable from a true claim unless you fetch the issue and read the list yourself.

**How to apply:** For every follow-up issue linked in the Follow-up Actions table, fetch its current body via the API and check it against (a) the report's own corrected narrative and (b) any specific "X was added to this issue" claims in the PR body. Takes one API call per issue; catches drift that a diff-only review of the incident-report file itself cannot see, since the issue lives in a different repo.

## Rule 3 — "We already have a detector for this" claims need signal-class verification

When a PR or report claims "the existing detector covers this" or implies an existing detector would have caught the failure, **check what signal the detector actually watches vs. the class of failure being described.**

- Ask: does the detector watch the right *signal*? A sliding-window detector on CacheStorage eviction churn cannot see client-side decode/fetch failures, even if both produce the same surface symptom (music stops).
- Ask: does the detector watch success *and* failure paths? A detector that only fires on successful evictions misses eviction failures entirely (the 2026-05-22 gap that `#470` fixed).

**Why:** Confirmed in the 2026-05-19/22/26 seinn incident chain — three successive "the detector should have caught this" gaps, each because the detector watched the right service but the wrong signal class. The `#460` detector (eviction storms), `#470` extension (eviction failures), and `#483` addition (playback errors) each addressed a distinct signal class that the prior one couldn't see.
