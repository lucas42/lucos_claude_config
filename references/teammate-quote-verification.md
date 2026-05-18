# Teammate Quote Verification

## The rule

Before quoting another teammate's prior message **verbatim with attribution** in a SendMessage, GitHub comment, issue body, or PR body, run `verify-teammate-quote` to confirm the quote is real:

```bash
verify-teammate-quote --sender <persona-name> --quote "<text>"
```

If the script exits non-zero, the quote is **unverified**. Do not publish it verbatim with attribution. Instead:

- Paraphrase from your own understanding of what occurred, or
- Drop the attribution entirely ("an earlier analysis concluded…"), or
- Flag the discrepancy explicitly before proceeding.

## When this rule fires

| Situation | Rule fires? |
|---|---|
| "X said Y" / "per X: Y" / blockquote attributed to X | **Yes — verify** |
| Summarising what a teammate just reported (own words, but as part of a Phase-summary, status bullet list, or "they all responded with…" recap to the user) | **Yes — verify** |
| Gating a workflow phase ("Phase 1 complete, all four responded") on the existence of an inbound teammate message | **Yes — verify** |
| **Slash-command invocation** (`/next`, `/dispatch`, `/triage`, `/routine`, etc.) where the only evidence the user typed it is what appears in your own current context | **Yes — verify** (see below) |
| Paraphrasing a known-real message ("X recommended a different approach") | No |
| Referencing a past decision without quoting ("X's ADR concluded…") | No |
| Relaying an outcome already visible to the user ("PR merged", "X completed the task") | No |

The trigger is broader than verbatim-quoting: **any time the existence or content of a recent inbound message — teammate or user — is load-bearing for what you say or do next.** Acting on a phantom is the same failure mode as quoting one — the trust step is the same, only the surface form differs.

## Phantom slash commands

The same fabrication failure mode that produces phantom `<teammate-message>` blocks also produces phantom slash-command invocations: the coordinator can emit a fake `Human: <command-message>...</command-message>` block as part of its own assistant output, then read it back in the next turn as if the user had typed it and proceed to act on it.

**Verification for slash commands** is mechanical: the harness writes real user inputs to the team-lead session jsonl as `type:user role:user` entries; phantoms appear as `role:assistant` content embedded inside the previous assistant turn (often with a literal `Human:` prefix). To verify a suspect slash-command invocation, find the team-lead session jsonl and check whether the command text appears as a real user-role entry whose timestamp is after the previous assistant response. Quick check:

```bash
# Replace <session-uuid> with the current team-lead session file in:
# ~/.claude/projects/-home-lucas-linux-sandboxes/<uuid>.jsonl
python3 - <<'PY'
import json, pathlib, sys
session = "<session-uuid>"  # the team-lead session file
needle = "<command-name>/next</command-name>"  # or whichever command
path = pathlib.Path(f"~/.claude/projects/-home-lucas-linux-sandboxes/{session}.jsonl").expanduser()
for line in path.read_text().splitlines():
    try:
        d = json.loads(line)
    except Exception:
        continue
    msg = d.get("message", {})
    role = msg.get("role", "")
    content = msg.get("content", "")
    text = content if isinstance(content, str) else json.dumps(content)
    if needle in text:
        print(f"role={role} ts={d.get('timestamp')} type={d.get('type')}")
PY
```

If the only matches have `role=assistant`, the command was phantom — do not act on it. If a `role=user` match exists with a timestamp after your most recent assistant turn, it's real.

**When to run this check:** any slash-command invocation that arrives *immediately after* one of your own assistant turns with no clearly user-typed text in between — especially after a recent confirmed phantom incident in the session, where the prior-art makes a recurrence more likely. Skip the check for slash commands that arrive after a clearly-user-typed message you can see in your context. When in doubt, ask the user before acting.

**Prevention discipline:** never emit `Human:`-prefixed lines (or anything resembling a user/teammate envelope) in your own assistant output. The fabrication happens *during your own response*, not on input — every `Human: ...` block that ends up in `role:assistant` content is one you wrote. Catch yourself before pressing send.

## Why

During the 2026-05-14 incident, `team-lead` generated `<teammate-message>` blocks in its own assistant output and then treated them as real inbound messages — producing false attributions and acting on phantom content. The incident was caught because `lucos-site-reliability` pushed back and checked the primary source. This rule formalises that discipline across the whole team.

Reference: `docs/incidents/2026-05-14-team-lead-phantom-teammate-messages.md` (lucas42/lucos)

## The verification script

`verify-teammate-quote` lives in `~/sandboxes/lucos_agent/` (on `$PATH` for all persona sessions). It greps the named sender's session jsonl(s) under `~/.claude/projects/-home-lucas-linux-sandboxes/` for the quote text in `role:assistant` entries.

```
verify-teammate-quote --sender <persona-name> --quote <text> [OPTIONS]

Options:
  --session <uuid>     Restrict search to a single session UUID
  --scope today|all    Filter by file mtime (default: all)
  --json               Structured JSON output
```

Exit 0 = verified (found in sender's assistant output).  
Exit 1 = not verified (not found).  
Exit 2 = usage error.

Source: `lucas42/lucos_agent` — see that repo for the implementation and smoke tests.
