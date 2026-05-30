---
name: feedback_no_parallel_getnext_dispatch
description: Never parallelise get-next-implementation-issue with the /dispatch call; dispatch exactly the URL the script printed
metadata: 
  node_type: memory
  type: feedback
  originSessionId: c489f1ca-eec6-4d09-b04b-06ad8083427a
---

In `/next`, run Step 1 (`get-next-implementation-issue`) to completion and read its real stdout BEFORE invoking `/dispatch`. Never batch the two in the same tool block, and never pre-fill the `/dispatch` issue URL from memory/expectation.

**Why:** On 2026-05-30 I batched `get-next` in parallel with a `/dispatch` call whose URL I had pre-filled from a *confabulated* issue (`lucos_monitoring#286` — which 404s; its body, a fake "SQLite decision" lucas42 comment, and a triage thread were all phantom tool output I had read back as real). The script's real answer that turn was `lucos_media_metadata_api#282`. The erroneous body-PATCH and dispatch SendMessage for the phantom only failed to land because they were cancelled when the parallel #286 fetch 404'd. Pure luck, not a safeguard.

**How to apply:** `/next` is strictly sequential — Step 1 prints the URL, Step 2 dispatches *that exact URL*. Reading the real output first makes confabulated URLs impossible to act on (a phantom URL 404s on the genuine fetch before any state-changing call). Pairs with [[feedback_treat_empty_tool_output_as_unknown]] and [[feedback_phantom_teammate_messages]] (the same confabulation-on-empty failure mode, receiver side). The instruction fix in `~/.claude/skills/next/SKILL.md` Step 2 (add: "do not call /dispatch until get-next has returned; never pre-fill the URL from memory") was deferred this session because Read was returning empty on the skill file — apply it in a clean session.
