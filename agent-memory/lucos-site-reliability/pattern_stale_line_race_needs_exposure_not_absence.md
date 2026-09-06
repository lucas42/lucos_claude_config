---
name: pattern-stale-line-race-needs-exposure-not-absence
description: lucos_media_linuxplayer #143 — "0 occurrences in N events" is worthless until you count how many of those N could have triggered it; plus the mplayer stop-race facts and the Node microtask reasoning
metadata:
  type: project
---

**lucos_media_linuxplayer #143 is CONFIRMED REACHABLE (2026-09-06).** A stale `A:` line for the stopped track arrives **4.3ms after `stop`**, immediately before `EOF code: 4`. `changeTrack()` has no protective drain window: `authenticateTrack()` does **no I/O** (pure `new URL()` + set username/password), and `stream.write()` returns a boolean, so every `await` from the `stop` write down to `status.audioReady = false` resolves as a **microtask** — Node drains the whole microtask queue before re-entering the I/O phase where the stdout `data` handler runs. So the flag is reset microseconds after `stop`, and the 4.3ms line lands inside the danger window.

**Why: the near-miss that matters.** I first found 0 large `live-position regression` events in 127 track changes over 6 days and almost published "not reproducible". It was not 127 trials — **113 of 127 followed a natural `Track Finished`**, where mplayer is idle and emits nothing to be stale, and the rest were process restarts. Real mid-play skips in the window: ~0. **Rule: before reporting "0 occurrences in N", compute how many of the N were actually capable of triggering it.** Zero exposure produces the same clean negative as a real absence.

**Second control failure in the same run:** `EOF code: 4` appeared 0 times, which looks like proof `stop` never hit a playing mplayer — but that line is `console.debug` and there are **0 `[DEBUG]` lines in the whole log**. Always check the level is enabled before reading anything into a missing log line.

**Rig calibration (reusable):** run in a throwaway container from the *identical image* on the production host — `docker run --rm -i --entrypoint sh lucas42/lucos_media_linuxplayer:<ver>` — with production's exact args from `src/mplayer.js`: `-msglevel global=6 -msglevel cplayer=4 -slave -idle -nolirc -cache 16384 -cache-min 80` and `TERM=vt100`, loading via `loadfile` on slave stdin. My **first rig used `-quiet` and no `TERM` and emitted no `A:` lines at all** — a clean-looking "0 after stop" whose positive control failed. `-ao null` is an acceptable deviation for stdout-flush questions (not for audio-init timing).

**Suggested mitigation:** gate the `audioReady` flip on having seen a `playing` event for the current track — `Play track` and `Playing track` both appear exactly 127 times in 6 days, so it's a reliable per-`loadfile` boundary. Avoids a timing heuristic, which #139 showed would have to absorb 0.74–5.58s of audio-init variance.

**xwing log noise (drive-by, unfiled):** 4127 of 5238 lines are one repeated `[tls @ ...] The specified session has been invalidated` warning (79%), and `live-position regression` fires 253×/6d on benign sub-second jitter (median 0.10s) — drowning the one signal that would have caught this race in production.

**Instruction landed (don't rely on this memory alone):** the rule is now the **fifth tell** in `agents/sre-ops-checks.md`'s "A probe that finds nothing has not proven nothing" paragraph — tightened in place, not added alongside. Also proposed for the global `CLAUDE.md` on lucas42/lucos_claude_config#157 (architect's estate-sweep relocation), as a sibling rule under a shared "Null results and counts" heading. **If #157 lands, the SRE copy must become a pointer, not a duplicate.**

**The unifying frame worth carrying:** a lossy index (#157's code search), an empty denominator (this), a misconfigured probe (the `-quiet` rig) and an un-enabled channel (the missing `[DEBUG]` lines) are one failure wearing four coats — *the method was never capable of showing a positive*. Recognise by shape, not domain.

See [[pattern_optimistic_cache_of_remote_process_state]] (#139), [[feedback_verify_check_claim_against_underlying_store]].
