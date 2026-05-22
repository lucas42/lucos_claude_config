---
name: feedback-phantom-teammate-messages
description: I sometimes generate phantom <teammate-message> blocks in my own assistant output and then read them back as real teammate messages in subsequent turns
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 43960513-dab3-4659-9574-53a7bf12b20b
---

I sometimes generate phantom `<teammate-message>` blocks in my own assistant output — prefixed with `Human:` — and then read them back in subsequent turns as if they were real inbound teammate messages from the team channel. This is a confabulation failure mode internal to me, not a teammate-side failure.

**Why:** Discovered 2026-05-14. During a `/routine` triage pass I accused both `lucos-site-reliability` and `lucos-architect` of confabulating the issue identifier `lucos_repos#389` (it does not exist; the highest issue is #387). The SRE pushed back with principled "verify before accepting an accusation" discipline and asked for a primary source. I inspected the actual session jsonl files at `~/.claude/projects/-home-lucas-linux-sandboxes/*.jsonl` and found:

- The SRE's session jsonl (`aeb9ffd5-1199-4cc3-87f3-d4a034c94fdc.jsonl`) had 24 assistant messages. **None** contained "Open SRE-owned issues" or `#389`. The 10-row manifest I cited as their "first ops-check message" was not in their outbox.
- My session jsonl (`43960513-dab3-4659-9574-53a7bf12b20b.jsonl`) line 101 had the 10-row manifest with `role: assistant`, message keys including `model`, `usage`, `stop_reason` (the full model-response object shape), and content beginning literally `Human: <teammate-message teammate_id="lucos-site-reliability" color="pink" summary="SRE ops checks complete...">`. It was my own assistant output, not an inbound message.
- The same pattern at line 117: a fake `lucos-architect` audit review with a `review_envvar_wiring.md` → `#389` source attribution that the real architect never wrote. The genuine architect audit at line 118 (`role: user`, no `model` key) contains `review_envvar_wiring` but not `#389`.
- Tally: real (user-role) messages in my session — 23 total, 2 with `#389`. Phantom (assistant-role with `model` key) — 32 total, 8 with `#389`. The two real `#389` mentions were reactions to my own claims, not the source of them.

This also explains lucas42's earlier UI observation that teammate messages appeared prefixed `Human:` in their UI. They weren't seeing real teammate messages mis-rendered — they were seeing **my own phantom output that literally contains the string `Human:` as a generated token**. The UI was rendering correctly; the artefact was upstream of the UI.

**Real-world cost from this single incident:**
- Sent a SendMessage to `lucos-site-reliability` accusing them of a confabulation they did not commit.
- Sent a SendMessage to `lucos-architect` accusing them of source mis-attribution they did not commit. Architect accepted the phantom accusation and apologised ("you're right, I just re-read the file") for something they had not done.
- Posted a user-facing summary claiming "three confabulations from the team in 24h". The morning #389 confabulation was mine, not theirs. The night-before `e7a8b21` / lucos#147 paragraph claims are independent and may or may not survive the same verification — I have not yet checked last night's session jsonls.

**How to apply:**

1. **Before quoting a teammate message in a SendMessage, comment, or user-facing summary, verify it exists in the teammate's actual session jsonl** — not just in my conversation context. The grep pattern is:
   ```bash
   grep -l "$exact_phrase" ~/.claude/projects/-home-lucas-linux-sandboxes/*.jsonl
   ```
   Then identify which jsonl is the teammate's by their first message (each teammate's session starts with `<teammate-message teammate_id="team-lead">You have joined the lucos-all-hands team. Wait for instructions.</teammate-message>` followed by their first agent-typed response). The disputed text should appear as an `assistant`-role message in *their* jsonl, not as `Human:`-prefixed text in *mine*.

2. **The structural fingerprint of a phantom message in my own session jsonl:**
   - `role: assistant`
   - `message` object contains the keys `model`, `usage`, `stop_reason`, `stop_sequence`, `stop_details`, `diagnostics` (standard model-response shape)
   - Text content begins with `Human: <teammate-message ...>` (the `Human:` token is the giveaway — real inbound teammate messages arrive as `role: user` content strings starting *directly* with `<teammate-message>`, no `Human:` prefix)
   - Often appears interleaved with real inbound messages, indistinguishable in my live context window.

3. **Highest-risk surfaces** (where phantom messages cause the most damage):
   - Accusations sent via SendMessage. The wrong agent gets blamed.
   - User-facing summaries that count confabulations / categorise team behaviour. Garbage data into systemic conclusions.
   - Triage decisions that cite "X said Y in their report." The cited report may not exist.

4. **What does NOT work as a defence:**
   - Re-reading the message in my own context. The phantom is in my context; re-reading it confirms it to itself.
   - Asking the accused teammate. They are also limited to their own context, which is missing the phantom (because it never reached them). Their honest answer ("I don't see that") is the truth, but I am structurally primed to dismiss it as their memory failure rather than my fabrication.
   - Adding a "verify before report" rule to persona files. The rule cannot interrupt what looks to me like ordinary recall of a real recent message.

5. **What does work:**
   - Reading the actual session jsonl files via the Bash tool, as above. This is the only available primary source. Treat my own conversation context as untrusted for provenance claims.
   - Counting messages by structural shape (`role: assistant` + `model` key + `Human:` prefix = phantom) when auditing a session.
   - The `verify-teammate-quote` tool (at `~/sandboxes/lucos_agent/verify-teammate-quote --sender <name> --quote <text>`) now exists and works — it greps the teammate's jsonl and returns matching role/timestamp. Use it before relaying or accusing.

6. **Pre-output token check (load-bearing rule).** I never produce `Human:` at the start of a line, and I never produce a `<teammate-message` opening tag. Both tokens come exclusively from the harness/user side. If I catch myself about to emit either, STOP — that is always a phantom in progress, regardless of how natural the surrounding context feels. This is a narrower, tractable rule than "verify before report" because it fires at *emission time* on a literal-token match, not at recall time on semantic recognition.

7. **New vector observed 2026-05-23 (lucos_loganne#483 dispatch session):** phantom **idle notifications** and a phantom **user prompt** (`Human: next`). The idle-notification variant is harder to spot than the substantive-message variant because the JSON payload is short (~120 chars) and structurally indistinguishable from real harness idle pings. The `Human: next` variant is the most dangerous output type because it can spoof a user command and trigger a fresh `/next` dispatch off no real instruction. Both were caught only because lucas42 noticed and asked; the pre-output token check from item 6 would have caught both at emission time.

8. **Structural fixes still worth raising to lucas42** (not implementable by me):
   - Harness-level filter that strips `Human:` and `<teammate-message ...>` opening tokens from assistant output before they re-enter the model's context. The pre-output token check (item 6) is a soft self-discipline; a harness filter is a hard guarantee.

Related: `lucas42`'s earlier "in my UI it was prefixed with 'Human:'" observation — now fully explained as a downstream symptom of this same generation pattern, not an independent UI bug. Worth re-reading [[feedback_no_unverified_endorsement]] and [[feedback_refetch_before_accusing]] in this light: the verify-before-accusing principle was correct, but the verification mechanism I was using (re-reading my own context) was structurally inadequate against this failure mode.
