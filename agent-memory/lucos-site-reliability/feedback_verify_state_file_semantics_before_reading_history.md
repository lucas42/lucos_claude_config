---
name: feedback-verify-state-file-semantics-before-reading-history
description: A working-state file is not a history. Before inferring "X never happened" from a checkpoint/lock/cursor, read the code that WRITES and CLEARS it — and prefer the purpose-built history source.
metadata:
  type: feedback
---

**Before treating any on-disk state file as evidence of what has or hasn't ever happened, read the code that writes it *and* the code that deletes it.** Files that record progress are usually **per-run and self-deleting on success**, which makes their mere existence a signal of *failure* and their contents a snapshot of *one bad run* — the exact opposite of a historical record.

**Why:** 2026-08-07, lucos_media_import. I read `completed_dirs` from `/var/state/import_checkpoint.json` (15 of 27 directories) and concluded "12 directories have **never** been reached; **72%** of the library is outside the weekly scan's reach; deterministic starvation, same tail every week." I published that to two tickets, told team-lead, and it reached lucas42 — who was told the wrong headline figure. All false. `import.py` calls `clear_checkpoint()` on clean completion, so **the file only exists when a run has failed**, and those 15 entries were one night's progress (2026-08-06). The full scan had in fact completed successfully on **2026-07-30 13:01:09Z with `errors: 0`** — all 27 directories. It also caused a downstream error: team-lead raised lucos_media_import#186 to High specifically because I'd said no backstop existed.

**How to apply:**

1. **Grep for the deleter, not just the writer.** `clear_*`, `unlink`, `os.remove`, `truncate`, `DELETE FROM`. If success deletes the file, its presence means failure and its contents describe only the failed attempt. Same trap: lockfiles (presence ≠ running — check the pid), `*.tmp`, resume cursors, `.part` files.
2. **Ask what the file's absence would mean.** If "absent" is the healthy state, you are looking at an error artefact, not a ledger.
3. **Prefer the purpose-built history source.** For "did this scheduled job ever complete?", that is `curl https://schedule-tracker.l42.eu/jobs` → match `system`+`job_name` → `metrics.age` (seconds since last completion) and `metrics.errors`. One HTTP call, and it is *designed* to answer the question. Also loganne for event history ([[reference_loganne_read_self_verify]], [[feedback_monitoring_history_from_loganne_not_snapshots]] — the same "snapshots lie about duration" mistake, one layer down).
4. **A vivid mechanism is not corroboration of its premise.** The `sorted()` uppercase-before-lowercase discovery was real and genuinely explained the 15 entries — which is precisely why I stopped checking. An elegant mechanism that fits the data makes the *unverified premise underneath it* feel established. Verify the premise separately from the mechanism.

5. **A timestamp field in someone else's data format may be stamped by the PRODUCER, not the receiver — so it cannot tell you when *you* learned something.** 2026-08-19, lucos_locations: I "verified" `location-freshness` alerts against `created_at` in the OwnTracks recorder's `.rec` files and twice concluded false-positive. `created_at` is written by the **phone**, not the recorder; the client queues messages while disconnected and flushes them on reconnect, so both `tst` and `created_at` run right through an outage in which we received nothing. That method had underpinned lucas42/lucos_locations#105's whole premise for three weeks. **Test:** find a window where a *receipt-side* source independently proves nothing arrived (here: broker connection log, `/store/monitor`, file mtimes) and check whether the field you're trusting has entries inside it. If it does, it is not a receipt clock.

Related: [[feedback_verify_check_claim_against_underlying_store]] (read the artefact, not its name), [[feedback_apply_own_evidence_to_own_positions]], [[feedback_treat_empty_tool_output_as_unknown]].
