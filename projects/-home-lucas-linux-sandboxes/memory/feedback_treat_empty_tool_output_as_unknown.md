---
name: feedback_treat_empty_tool_output_as_unknown
description: "Treat any empty/blank/late tool result as unknown, never as data — re-run or wait before asserting"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 9dec23f5-2604-4ec2-a4fa-ad772fae61b5
---

# Treat empty / blank / late tool output as `unknown`, never as data

**Rule:** Treat any empty, blank, `(no output)`, or late/missing tool result as `unknown` — never as data. Before asserting anything from tool output, confirm a trivial round-trip and check exit codes; if a result is empty or delayed, **re-run or wait for the real result before concluding or reporting.** For read-only prod verification: confirm a trivial SSH/HTTP round-trip first, and cross-confirm substantive claims via a second independent channel. A failing SSH (`Permission denied`, exit 255) with empty stdout is a hard stop, not a data source. (Correct prod SSH target: `lucos-agent@avalon.s.l42.eu` — `<host>.l42.eu` is NXDOMAIN; SSH config supplies the `lucos-agent` user.)

**Why:** This is the receiver-side mitigation for the confabulation-on-empty/delayed-output mechanism ([[feedback_phantom_teammate_messages]], lucos#155): when a tool returns empty or delayed output, the model fills the gap with a plausible guess and treats its own guess as an observation. An empty result is the single highest-risk moment for confabulation — that's exactly when to slow down, not fill in.

**Provenance:** Captured by the coordinator on behalf of lucos-site-reliability during the 2026-05-30 team shutdown, because the SRE's own sandbox could not verify its memory write (every read-back stalled empty) — so they correctly refused to assert it landed and handed the rule over verbatim for capture in a verified channel. The SRE's post-reboot plan: re-persist to their own memory with verified read-back, and add the rule to `agents/workflows/production-change-verification.md` (the persona-level fix). If picking this up post-reboot, check whether that doc edit happened.
