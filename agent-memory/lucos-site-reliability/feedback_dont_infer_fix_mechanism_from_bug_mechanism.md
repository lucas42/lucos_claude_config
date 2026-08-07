---
name: feedback-dont-infer-fix-mechanism-from-bug-mechanism
description: Before asserting what a fix does or doesn't cover, READ the fix. A fix rarely works by the same mechanism the bug failed by, so reasoning from the bug's shape produces confident, wrong coverage claims.
metadata:
  type: feedback
---

**Never state what a fix covers, or fails to cover, without reading its implementation.** The trap is specific: you know the *bug's* mechanism intimately (you probably diagnosed it), so you reason about the *fix* as though it must operate on the same axis. It usually doesn't — a good fix often sidesteps the bug's mechanism entirely, which is exactly why it works.

**Why:** 2026-08-07, lucos_media_import#188 (fixing #173). #173's failure is *"`docker stop` SIGTERMs PID 1, the shell doesn't forward, so `import.py` — a cron **grandchild** — is SIGKILLed with its handler never firing"*. Purely a process-tree story. When asked to own the post-deploy verification, I asserted that an ad-hoc `docker exec` run "**cannot** verify the SIGTERM half, because the exec'd process isn't a cron grandchild" — and sent it to team-lead, who began relaying it to lucas42 as a statement about how well his fix was verified. `lucos-developer` challenged it. The fix doesn't propagate down the tree at all; `startup.sh` traps TERM and calls `pkill -TERM -f "python -u import\.py"`, which matches `/proc/*/cmdline` across the whole PID namespace and is **lineage-independent**. An exec'd process is matched identically. I had carried the shape of the bug onto the shape of the fix, and asserted a limitation of code I had not read — while holding the PR's file list in front of me.

**How to apply:**

- Trigger is any sentence of the form "this fix does / doesn't handle X", "the test can't reach Y", "that only works when Z". Before sending: open the diff. `gh-as-agent … pulls/{n}/files --jq '.[] | select(.filename=="<f>") | .patch'` is one call.
- **Then check the mechanism actually matches your case**, not just that it exists — e.g. `pkill -f "python -u import\.py"` needs the *invocation* to produce a matching cmdline; `pipenv run python -u import.py` does, but a differently-shaped launch might not.
- Beware the inverse error too: assuming a fix covers a case because the bug's mechanism is gone. Same rule, same remedy.
- Highest-stakes moment is **defining or scoping a verification gate** — a false "we can't verify this" quietly downgrades how well something is believed to ship, and travels fast to whoever is approving it.

**When the conclusion survives the correction, rewrite the reason.** Here the plan was unchanged (don't kill a live multi-hour production scan to test SIGTERM) but my justification — "an ad-hoc run *can't* prove it" — was false, and the developer's — "it doesn't *need* to; the mechanism is architecture-level, so a synthetic test covers it fully" — was correct. A right answer propped up by a collapsed reason gets reused where the answer isn't right. Same principle as [[feedback_apply_own_evidence_to_own_positions]]: the restraint may survive, the stated reason must not.

Related: [[feedback_verify_state_file_semantics_before_reading_history]], [[feedback_verify_check_claim_against_underlying_store]], [[feedback_no_attribution_overclaim]].
