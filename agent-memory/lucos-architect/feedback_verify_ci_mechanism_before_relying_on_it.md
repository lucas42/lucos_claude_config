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

- **2026-06-05 — ADR-0010 follow-up + lucos#217 (DNS SOA monitoring).** I specified the SOA-serial-consistency check as "an `/_info`-exposed signal on the DNS systems" — assuming the systems expose `/_info`. They don't: they're bare BIND containers with no HTTP server, and (no `http_port`) they're excluded from monitoring's `/_info` poll list, which is built from configy's `/systems/http`. lucas42 caught it. The correct mechanism was a `schedule_tracker` scheduled job (push), which monitoring already consumes for non-HTTP workloads. "Expose it via `/_info`" silently assumes an HTTP server exists — verify the service *has* one before specifying `/_info`; non-HTTP workloads (BIND, cron jobs, `lucos_docker_health`) report via schedule_tracker push instead.

- **2026-06-07 — ADR-0002 (test environments).** team-lead relayed that `lucos_contacts/test` "already exists" because a CI job's `scp tests@creds.l42.eu:lucos_contacts/test/.env` exited 0. I verified the CI *config* (the pull is attempted, no error suppression) and wrote "the env exists and is non-empty" into the ADR as established fact. Wrong: `controller.go readFileByHandle` sets `found=true` **unconditionally** for any well-formed `system/env/.env` handle (there is no not-found path), and `SYSTEM`/`ENVIRONMENT` built-ins are auto-injected for any combo — so the scp *always* exits 0 with at least the standard vars, regardless of whether any `test` secret is stored. exit-0 is not evidence of existence. lucas42 confirmed no secrets are stored with environment=`test` anywhere; the pattern is genuinely greenfield. I'd read the config (the call site) but not the *handler* that defines what the success signal means.

All four instances share the same shape: a claim that **assumes a mechanism property** (CI sequencing; severity tier; an HTTP `/_info` endpoint; that a success signal implies stored state) **without reading the implementation** to confirm. The substantive direction may have been right or wrong, but the mechanism scaffold was a fiction.

**How to apply:**

- Whenever a design hinges on a system's behaviour, **stop and read the actual code** before posting. Specifically:
  - CI sequencing or registry visibility → read `.circleci/config.yml` of the affected repos and the relevant orb commands (`~/sandboxes/lucos_deploy_orb/src/...`). See [reference_buildx_bake_additional_contexts.md](reference_buildx_bake_additional_contexts.md) for what the orb actually does.
  - lucos_repos convention engine shape → read `conventions/conventions.go` and an existing convention file (e.g. `docker-healthcheck-on-built-services.go`) to see what `ConventionResult` fields are supported. There is no `Severity` field; the engine is binary.
  - API / registry behaviour → read the source of the API or registry, not just its documentation. Behaviour and docs drift.
  - "expose via `/_info`" → confirm the service runs an HTTP server and has an `http_port` (it's then in configy's `/systems/http` and monitoring's `fetcher_info`). Non-HTTP workloads (BIND, cron, distroless agents) report via `schedule_tracker` push, consumed by `fetcher_scheduled_jobs`.
- Treat "this'll work because [some implicit ordering / tier / hook / fallback]" as a yellow flag and verify before posting. Implicit properties are exactly the kind of thing that's wrong silently.
- **Don't infer existence/state from a success signal** (`exit 0`, `found=true`, `200 OK`, a non-empty response) without reading what that signal *means* in the target system. A success code can be unconditional (creds `readFileByHandle` always returns `found=true`; an `.env` always carries auto-injected built-ins). Reading the *call site* (the CI step that runs the command) is not enough — read the *handler* that produces the signal. If "X exists" rests on "the fetch for X succeeded", confirm the fetch can actually fail when X is absent.
- This applies even when the substantive recommendation is correct. Both halves of the proposal — the substance and the mechanism it rides on — need rigour. A right answer carried by a fictional mechanism still doesn't ship.

Related rules: [[feedback_grep_and_conclude_anti_pattern]] (verify before concluding from a partial check), [[feedback_read_the_pr_not_the_description]] (read the artefact, not a paraphrase of it).
