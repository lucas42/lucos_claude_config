---
name: pattern-circleci-unknownsgate-estate-storm
description: Estate-wide simultaneous circleci monitoringAlert storm = a multi-min CircleCI API outage tripping the UnknownsGate (threshold 3), NOT workflow failures
metadata:
  type: project
---

**Many systems (e.g. 33) all firing a `circleci` `monitoringAlert` within seconds, then all recovering ~1 min later = a CircleCI *API* outage tripping the UnknownsGate — NOT real workflow failures.**

Why: every repo's `ciRepoLoop` probes the SAME CircleCI API. When that API returns 503 (or is unreachable) for ≥3 consecutive 60s polls, `fetcher_circleci` emits `ok: unknown` → UnknownsGate (`?CONSECUTIVE_UNKNOWNS_THRESHOLD = 3` in monitoring_state_server.erl) flips to `ok: false` on the 3rd → alert. 3 polls × 60s ⇒ alert at the ~2-min mark. Decorrelated poll timing stops mattering once the outage outlasts the gate window — all loops flip together. Same Case-1 mechanism as the single-system 2026-05-11 flap (lucos_monitoring#228), just estate-wide.

**Diagnostic — check the debug field FIRST.** Pull a full `monitoringAlert` event from Loganne (`failingChecks[].debug`). `"Received HTTP response with status 503 ... from pipeline endpoint"` (or transport-error text) = the ok:unknown→UnknownsGate path. `"Workflow \"X\" failed"` = the ok:false workflow path. On 2026-06-09 I first wrongly hypothesised the workflow-failed path from the gate code alone; the debug field settled it instantly. Don't reason from code mechanics when one event payload gives ground truth.

**Fix lever = the UnknownsGate threshold, NOT failThreshold.** `failThreshold:2` on circleci is the wrong tool (gates ok:false; the alert arrives via unknown→false flip) and was deliberately rejected in lucos_monitoring#226 — the architect's `make_third_party_probe_check` docstring forbids it. The threshold value of 3 was itself signed off by lucas42 in #226.

**lucos_monitoring#279 is DONE (verified 2026-07-14): threshold raised 3→5, lucas42 signed off the value 2026-06-09, closed as completed.** So the gate now needs **5 consecutive unknowns (~5 min)**. Do NOT cite #279 as an open proposal.

**The threshold-5 value is VINDICATED — don't propose another bump without extraordinary evidence.** 2026-07-14 03:30-03:56: a genuine ~26-min intermittent CircleCI API degradation produced **271 `CircleCI API request failed ... timeout` lines across 52 DISTINCT repos** (read from `lucos_monitoring` container logs), yet **only 3 systems alerted**, ~3 min each. Timeouts were roughly every-5th-poll per repo, so almost no repo ever hit 5 *consecutive*. The gate absorbed a 26-min third-party outage down to 3 brief alerts, and those 3 were **CORRECT** (they genuinely had no CI signal for 5+ min). Filing another bump here would revisit a signed-off value on evidence that *supports* it.

**Baseline for Check 4 log review:** ~10-15 CircleCI timeout warnings per repo per ~27 days in `lucos_monitoring` logs is NORMAL background noise, not a defect. A wall of them is the expected steady state.

**Self-inflicted artifact — a `rerun` fakes a recovery.** The `circleci` check reads the **most recent workflow**, and an *in-flight* workflow isn't "failed". So triggering `POST /api/v2/workflow/{id}/rerun` on a red system emits a spurious `monitoringRecovery`, then a fresh `monitoringAlert` when it fails again. Seen 2026-07-14 (lukeblaney_co_uk "recovery" 09:23Z was my own re-run). Don't read that recovery as real, and don't let it pollute the Check-3 >30min outage pairing.

UnknownsGate only affects `ok: unknown` emitters: circleci (`fetcher_circleci.erl:59`) + one fetch-info path (`fetcher_info.erl:92`). It does NOT touch fetch-info/tls `ok:false`+`failThreshold:2` direct-probe alerting.
