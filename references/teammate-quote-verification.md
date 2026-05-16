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
| Paraphrasing a known-real message ("X recommended a different approach") | No |
| Referencing a past decision without quoting ("X's ADR concluded…") | No |
| Relaying an outcome already visible to the user ("PR merged", "X completed the task") | No |

The trigger is broader than verbatim-quoting: **any time the existence or content of a recent inbound teammate message is load-bearing for what you say or do next.** Lesson from 2026-05-16: the original "verbatim + attribution only" framing let a phantom slip through because I was summarising in my own words rather than quoting. Acting on a phantom is the same failure mode as quoting one — the trust step is the same, only the surface form differs.

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
