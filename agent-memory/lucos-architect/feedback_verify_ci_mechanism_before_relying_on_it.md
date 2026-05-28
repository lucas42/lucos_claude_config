---
name: Verify the mechanism's properties before designing around them
description: Don't assume a system supports the shape you're designing for — read the engine / orb / registry / config and confirm what actually exists before posting the design
type: feedback
---

# Verify the mechanism's properties before designing around them

**Rule:** When a design depends on a system (CI, audit engine, registry, API) supporting a particular shape — ordering, tiers, severity levels, lifecycle hooks, conditional behaviour — verify that shape exists by reading the implementation before posting the design. Don't infer the shape from how you'd expect the system to work or how analogous systems work; check the actual code/config.

If the assumed shape doesn't exist, the design is fictional from the moment it ships and someone (usually lucas42) will catch it. The fix at that point is bigger than the verification would have been at write time.

**Why — incidents this rule has fired on:**

- **2026-04-29 — lucos_contacts#668 / lucos_eolas#212.** I proposed `FROM lucas42/lucos_<repo>_app:latest` in a web Dockerfile, waving at "build-order coupling between app and nginx images. Already implicit in CI." That was hand-waving, not architecture. The lucos orb builds via `docker buildx bake` in a single call — there's no "build A before B" sequencing to lean on. Had it shipped, the web build would have pulled the *previous* deploy's `app:latest` from Docker Hub, perfectly reproducing the staleness bug at a different layer. lucas42 spotted it because the ordering claim was vague enough to obviously need verification.

- **2026-05-28 — lucos_repos#404 (loopback-healthcheck convention).** I proposed a convention with `Severity: Warning (not Fail)` as the load-bearing mechanism that would surface findings for review without forcing changes. lucas42 pointed out the convention engine is binary — pass or fail-with-issue, no third tier. The "warning" I'd designed around didn't exist. The ticket closed `not_planned`; the rule lives entirely in `lucas42/lucos_claude_config#97`'s reference doc.

Both instances share the same shape: a design proposal that **assumes a mechanism property** (CI sequencing; severity tier) **without reading the implementation** to confirm. The substantive direction may have been right or wrong, but the mechanism scaffold was a fiction.

**How to apply:**

- Whenever a design hinges on a system's behaviour, **stop and read the actual code** before posting. Specifically:
  - CI sequencing or registry visibility → read `.circleci/config.yml` of the affected repos and the relevant orb commands (`~/sandboxes/lucos_deploy_orb/src/...`). See [reference_buildx_bake_additional_contexts.md](reference_buildx_bake_additional_contexts.md) for what the orb actually does.
  - lucos_repos convention engine shape → read `conventions/conventions.go` and an existing convention file (e.g. `docker-healthcheck-on-built-services.go`) to see what `ConventionResult` fields are supported. There is no `Severity` field; the engine is binary.
  - API / registry behaviour → read the source of the API or registry, not just its documentation. Behaviour and docs drift.
- Treat "this'll work because [some implicit ordering / tier / hook / fallback]" as a yellow flag and verify before posting. Implicit properties are exactly the kind of thing that's wrong silently.
- This applies even when the substantive recommendation is correct. Both halves of the proposal — the substance and the mechanism it rides on — need rigour. A right answer carried by a fictional mechanism still doesn't ship.

Related rules: [[feedback_grep_and_conclude_anti_pattern]] (verify before concluding from a partial check), [[feedback_read_the_pr_not_the_description]] (read the artefact, not a paraphrase of it).
