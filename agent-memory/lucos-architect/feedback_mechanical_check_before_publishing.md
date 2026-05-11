---
name: Do the mechanical check before publishing
description: For any audit/rollout/ADR scope list or cross-reference set, do the trivially-greppable check before pushing. Memory-derived lists hallucinate; reference-format consistency rots silently.
type: feedback
---

When publishing an artefact whose correctness involves a mechanical, greppable property — an audit's in-scope list, a cross-repo reference format pattern, an enumeration of callsites in a migration ticket — **do the grep yourself before publishing**. Don't rely on memory; don't rely on the reviewer to spot it.

**Why:** Three failures in the same 24h window (May 2026), all same shape:

1. **PR #485 (ADR-0003)** shipped with 9 issue-reference format violations — same-repo refs written as `lucas42/lucos_arachne#N` (need bare `#N`), cross-repo refs missing the `lucas42/` prefix. The reviewer caught all nine. I'd explicitly asked them to spot-check the format because I wasn't confident — but the "if not confident, grep first" version of the same impulse would have saved the round-trip. The grep is `grep -nE "lucas42/<this_repo>#|<other_repo>#"`, trivially fast.

2. **`lucos_arachne#484` audit** body listed six in-scope producers — extrapolated from memory of "services emitting RDF". Two (`lucos_weightings`, `lucos_mood`) didn't exist as repos. Two (`lucos_photos`, `lucos_schedule_tracker`) didn't emit RDF and weren't in arachne's `live_systems`. One (`lucos_configy`) did emit RDF and was in `live_systems` but was missing from my list. The audit's authoritative scope-source was `lucos_arachne/ingestor/triplestore.py:live_systems`, four entries on origin/main — a single file I could have read in 5 seconds when writing the audit body.

3. **`~/.claude` push from a stale branch** promoted an unintended second commit to main alongside my memory update. The sandbox was on `document-issue-manager-pr-limitation` (a previous-session branch) when I ran `git push origin HEAD:main`. The branch had an inherited sysadmin commit (`5269789`) that I didn't realise was there. The commit turned out to be legitimate and clearly-intended-to-ship (team-lead confirmed; it matched lucas42's explicit policy on `#71`), but the *process* was wrong — I shouldn't push without knowing what's about to land. The mechanical check that would have caught this: `git log HEAD --oneline ^origin/main` before any push, which lists exactly the commits that will be pushed regardless of which branch is checked out. Team-lead has endorsed adding this as a standing pre-push checkpoint.

All three failures are the same shape: I had a claim about a finite enumerable set (refs, repos, commits) and didn't run the cheap mechanical check that would have confirmed or refuted it.

**How to apply:**

- **Before publishing any ticket / ADR / PR body that names a set of items, identify the authoritative source-of-truth for that set and check against it.** For arachne emitter audits: `live_systems` in `triplestore.py`. For cross-repo issue references: a `grep -nE "<this_repo>#|<other_repo>#"` against the prose. For migration callsites: a `grep -nE "<old_pattern>"` against the producer code. **For any push from `~/.claude` (or any other repo): `git log HEAD --oneline ^origin/main` before pushing**, to see exactly which commits are about to land — the sandbox is sticky across sessions and the working branch may not be a clean fast-forward of main.
- **The grep is cheaper than the round-trip cost of being wrong.** Reviewer round-trip on a doc PR is at least 30 minutes (write → review → fix → re-review → merge); the grep is 30 seconds. The math always favours the grep.
- **The "spot-check this for me" instruction to the reviewer is a tell.** If I'm not confident enough to skip a spot-check, I'm not confident enough to skip running the grep myself. Spotting that impulse as a signal to do the check before publishing — not delegate it — is the systemic fix.
- **For scope lists specifically: derive, don't recall.** When the scope is "all services that do X", read the file that *defines* "doing X" rather than reconstructing the list from memory. Memory hallucinates non-existent repos as readily as it omits real ones.
