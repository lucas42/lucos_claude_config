---
name: pattern-circleci-unknownsgate-estate-storm
description: Estate-wide simultaneous circleci monitoringAlert storm = a multi-min CircleCI API outage tripping the UnknownsGate (threshold 3), NOT workflow failures
metadata:
  type: project
---

**Many systems (e.g. 33) all firing a `circleci` `monitoringAlert` within seconds, then all recovering ~1 min later = a CircleCI *API* outage tripping the UnknownsGate — NOT real workflow failures.**

Why: every repo's `ciRepoLoop` probes the SAME CircleCI API. When that API returns 503 (or is unreachable) for ≥3 consecutive 60s polls, `fetcher_circleci` emits `ok: unknown` → UnknownsGate (`?CONSECUTIVE_UNKNOWNS_THRESHOLD = 3` in monitoring_state_server.erl) flips to `ok: false` on the 3rd → alert. 3 polls × 60s ⇒ alert at the ~2-min mark. Decorrelated poll timing stops mattering once the outage outlasts the gate window — all loops flip together. Same Case-1 mechanism as the single-system 2026-05-11 flap (lucos_monitoring#228), just estate-wide.

**Diagnostic — check the debug field FIRST.** Pull a full `monitoringAlert` event from Loganne (`failingChecks[].debug`). `"Received HTTP response with status 503 ... from pipeline endpoint"` (or transport-error text) = the ok:unknown→UnknownsGate path. `"Workflow \"X\" failed"` = the ok:false workflow path. On 2026-06-09 I first wrongly hypothesised the workflow-failed path from the gate code alone; the debug field settled it instantly. Don't reason from code mechanics when one event payload gives ground truth.

**Fix lever = the UnknownsGate threshold, NOT failThreshold.** `failThreshold:2` on circleci is the wrong tool (gates ok:false; the alert arrives via unknown→false flip) and was deliberately rejected in lucos_monitoring#226 — the architect's `make_third_party_probe_check` docstring forbids it. The threshold value of 3 was itself signed off by lucas42 in #226. Raised-threshold proposal tracked in lucos_monitoring#279 (2026-06-09): bump `?CONSECUTIVE_UNKNOWNS_THRESHOLD` 3→5. Revisits a lucas42-signed-off value, so needs his sign-off — verify #279 state before citing.

UnknownsGate only affects `ok: unknown` emitters: circleci (`fetcher_circleci.erl:59`) + one fetch-info path (`fetcher_info.erl:92`). It does NOT touch fetch-info/tls `ok:false`+`failThreshold:2` direct-probe alerting.
