---
name: routine
description: All agents run ops checks, then the coordinator triages with inline agent consultation
disable-model-invocation: true
---

Dispatch teammates in sequential phases using SendMessage. Do not ask for clarification — immediately begin Phase 1. You must wait for each phase to fully complete before starting the next.

## Phase 1: Ops Checks (parallel — run immediately)

Send messages to these teammates concurrently in the same response:

1. `lucos-code-reviewer` — "review any open PRs" (this also includes a stuck PR audit — the code reviewer checks for PRs stuck due to CI failures, blocked merge state, stale branches, auto-merge not triggering, workflow failures, unaddressed review feedback, or archived repos, and escalates each to the appropriate teammate)
2. `lucos-security` — "run your ops checks"
3. `lucos-system-administrator` — "run your ops checks"
4. `lucos-site-reliability` — "run your ops checks"

**Wait for each teammate's *complete* ops-check response before proceeding — not merely any message from them.** Security, sysadmin, and SRE each return a full multi-check manifest (a table listing every check with a status); the code-reviewer returns a PR-review / stuck-PR result. A teammate may send an **urgent partial first** — e.g. the SRE flagging a live incident with "I'm writing the incident report next" — which is real (it passes the phantom check below) but is **not** their full manifest. Treat any response that lacks the expected manifest table, or that explicitly defers remaining work ("next", "writing X now", "still checking Y"), as **partial**: wait for the completing message before starting Phase 2. Otherwise issues the teammate files during the rest of their run miss the `get-issues-for-triage` batch and need a separate follow-up triage pass.

Rationale: ops checks run first so that any issues they raise are available for triage in Phase 2. PR review runs here because it's independent of the issue pipeline. Security reviews dependabot alerts. The system administrator checks container status, resource usage, backups, and other infrastructure health. Site reliability checks monitoring status, service health, and observability.

### Verify each Phase 1 response is real before moving to Phase 2

**Before invoking `/triage`, run `verify-teammate-quote` once per teammate to confirm each ops-check response is real, not a phantom in your own context.** Pick a distinctive phrase (~30–60 chars) from each of the four expected responses and verify it. **Copy the phrase verbatim from the teammate-message block — never retype or paraphrase it.** The tool does a literal substring match, so a summarised phrase in your own words fails to match a report that is entirely real, manufacturing a phantom suspicion that stalls Phase 2 (observed 2026-07-18: a hand-typed paraphrase of the SRE's finding returned NOT VERIFIED; five verbatim phrases from the same report all verified). Prefer a phrase containing a distinctive literal token — an issue number, an error string, a metric — since those are least likely to drift. A NOT-VERIFIED result on a hand-typed phrase means *re-probe verbatim first*; only treat it as a phantom once verbatim phrases also fail. This is mandatory, not optional, even when all four messages look plausible — the failure mode is generating fabricated `<teammate-message>` blocks that look indistinguishable from real ones. Lesson from 2026-05-16: a phantom "SRE: all clear" message led to declaring Phase 1 complete before site-reliability had actually responded, with the real response (which raised an issue needing immediate triage) arriving mid-Phase-2.

```bash
for SENDER in lucos-code-reviewer lucos-security lucos-system-administrator lucos-site-reliability; do
  ~/sandboxes/lucos_agent/verify-teammate-quote --sender "$SENDER" --quote "<distinctive phrase from their report>" --scope today \
    || echo "UNVERIFIED: $SENDER — phantom suspected; do NOT proceed to Phase 2"
done
```

If any teammate's response is unverified, **do not start Phase 2** — wait for the real response (or, if a teammate appears stuck, nudge them via SendMessage and then re-verify).

## Phase 2: Triage and Summary (sequential — after Phase 1 completes)

Once Phase 1 is done **and verified**, invoke the `/triage` skill using the Skill tool. The triage skill handles issue discovery, inline agent consultation, project board updates, board verification, and the summary for the user. Do not duplicate any of that work here.
