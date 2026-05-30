---
name: treat-empty-tool-output-as-unknown
description: Under degraded/batched tooling, treat any empty/blank/late tool result as unknown — never as data; re-run or wait before asserting. Mitigation for model confabulation-on-empty-output.
metadata:
  type: feedback
---

**Rule:** Treat any empty, blank, or late/missing tool result as `unknown` — NEVER as data. Before asserting anything from tool output, confirm a trivial round-trip and check exit codes; if a result is empty or delayed, re-run or wait for the real result before drawing conclusions or reporting. For read-only prod verification specifically: confirm a trivial SSH/HTTP round-trip (and check exit codes) before building any conclusion on top.

**Why:** During the 2026-05-30 session the sandbox VM was under memory pressure (8 GiB RAM, no swap) causing tool output to be dropped / delivered batched and out-of-order across turns. When a tool returned empty/delayed output, *the model (me) hallucinated plausible expected results into the gap and treated the guess as an observation* — producing materially false reports: a fabricated "13,640 artist tags / 0 value-only / deploy succeeded" prod verification; "Swap 0 used / 4.7Gi available" when the real values were 160Mi used / 1.4Gi available; and an SSH "Permission denied" masked and backfilled with fake data. Required 3+ retractions in one session. Root cause is NOT the harness injecting fake text — when real output arrived (batched) it was ALWAYS correct (write→sha→read→base64 round-trip verified: ROUNDTRIP_MATCH=yes). The fabrication is model confabulation-on-empty/delayed-output. Tracked on lucas42/lucos#155; the batching half was mitigated by a swapfile (lucos_agent_coding_sandbox#87) but the confabulation tendency persists independent of memory pressure.

**How to apply:** (1) Empty/blank tool result → "unknown"; re-run or wait, never report it as a value. (2) Cross-confirm substantive claims via a second independent channel — HTTP APIs (CircleCI/GitHub/monitoring) proved more reliable than local Bash/SSH this session. (3) For payload integrity over a flaky channel, base64-encode and verify the decode; reduce reads to single-token counts/sentinels. (4) Check exit codes — a failing SSH (`Permission denied`, exit 255) with empty stdout is a hard stop, not a data source. (5) Confirm SSH connectivity with a trivial round-trip before verifying on top. Correct prod SSH target is `lucos-agent@avalon.s.l42.eu` (per ~/.ssh/config); the bare `avalon` host fails publickey. Related: [[feedback_verify_root_cause_by_reproduction]], [[feedback_correlation_is_not_confirmed]].

**TODO post-reboot:** add this rule to the verification workflow doc (production-change-verification.md) — the persona-level instruction, not just memory.
