---
name: base-image-bump-incident-class
description: Recurring estate incident class — auto-merged base-image bumps break production because CI validates an artifact we don't ship; my position on the lucos#273 convention decision
metadata:
  type: reference
---

Three production breaks in ~7 weeks from container base-image changes. Decision issue: lucas42/lucos#273 (my analysis: https://github.com/lucas42/lucos/issues/273#issuecomment-5143891081).

**Occurrences:**

| Date | Repo | Bump | Outcome |
|---|---|---|---|
| 2026-06-11 | lucos_mail | `alpine:3.21.1 → 3.24.0` (**stable**) | Dovecot 2.4 breaking config. SMTP down ~14 min |
| 2026-06-23 | lucos_contacts, lucos_eolas | `python:3.15.0a8 → 3.15.0b2` | psycopg couldn't find `libpq`. **No outage** — CI check blocked the merge |
| 2026-07-31 | lucos_media_metadata_manager | `php:8.5.8 → 8.6.0alpha2` | alpha image dropped `mbstring`; all pages 500 for 6h29m, monitoring green |

**The frame that matters.** Not "guard against auto-merged base-image bumps" and not "block pre-releases". Dependabot is the *agent* of the change, not the hazard — a hand-edited `FROM` line has identical exposure. The common factor is: **CI validates an artifact we don't ship (or only that it assembles), and `/_info` checks largely probe other people's services.** Base-image bumps are just the change class where the thing that breaks is *underneath* the code we wrote.

**Which defence catches which — the table that should drive the decision:**

| Defence | mail (stable) | py beta | php alpha | hand-edited FROM |
|---|---|---|---|---|
| dependabot pre-release `ignore` (lucos_media_import) | ✗ | ✓ | ✓ | ✗ |
| CI pre-release tag grep (lucos_media_metadata_manager#386) | ✗ | ✓ | ✓ | ✓ |
| tests-in-shipped-image (`FROM app AS test`, lucos_eolas) | ✓ | ✓ | **✗** | partial |
| stack-boot CI job (lucos_mail#61) | ✓ | ✓ | **✗** | ✓ |

**Both bolded cells are the crux, and I got the second one wrong first time.**

- `lucos_eolas` `FROM app AS test` is the most-cited "durable fix" but misses the php case: mmm has **no test that renders a view**, so running the existing suite in the production image goes green through a total outage. Tests-in-the-real-image is coverage-dependent and inherits each repo's coverage gaps — and the thinnest-coverage repos are least likely to have a test on the broken path.
- Stack-boot (`lucos_mail#61`) also misses it. **SRE caught this after I marked it ✓.** That job asserts the container *healthcheck* passes; mmm's healthcheck is `test: ["CMD", "curl", "-fs", "http://127.0.0.1:80/_info"]` (verified on `origin/main`), and `/_info` was green throughout. So it would have gone green too.

**The corrected conclusion is blunter: no defence currently in the estate would have caught this incident, and three of the four would have reported success while doing it.** Boot-and-probe is independent of *unit-test* coverage but depends completely on **what the probe asserts** — and every probe in the estate asserts `/_info`. So the `/_info` self-check isn't step one of a sequence, it's the precondition without which the CI-boot step is theatre.

**The meta-lesson, and I made this error twice in one session:** I caught the `/_info` version by reading `_info.php` at source, then reproduced it one row down by reasoning about the stack-boot pattern from its *description* instead of checking what the healthcheck it asserts actually probes. The trap isn't `/_info` — it's assuming any named guard exercises the thing it's named after. SRE's phrasing is the keeper: **a guard must exercise the thing it's guarding, not merely start it.** Trace every proposed guard to the assertion at its leaf before scoring it.

**My recommendation (ordered — ordering is load-bearing):**
1. `/_info` must check the service's **own** primary function — see [[recurring-docker-healthy-not-reachability]] for why a CI job without this asserts nothing.
2. CI boots the shipped image, asserts `/_info` healthy. Open design cost: dependency checks legitimately fail in CI (nothing for mmm's `metadata-api` probe to talk to) — needs a self-vs-dependency distinction settled in the spec, not bolted onto `checks` (`dependsOn` is a different axis: deploy suppression).
3. Non-HTTP services (backups, media_import, firewall, dns, cron/batch) have no `/_info` — narrower "does it start and stay up" form.
4. Pre-release tag check kept, but justified as **"a pre-release base image requires a human decision"**, not as a safety net (it misses the mail case). That framing also dissolves the exemption question — repos deliberately tracking pre-releases pin explicitly.

**Layer choice principle:** prefer the layer that fails *visibly*. Rejected dependabot `ignore` as the estate mechanism — it never opens a PR, and the `lucos_media_import` comment records that its syntax fails silently. A defence you can't see working is one you'll wrongly trust.

**Scale (2026-07-31, approximate — counted from local `origin/main` refs):** ~30 repos with a root `Dockerfile` + docker dependabot ecosystem + auto-merge, plus ~13 more with Dockerfiles in subdirectories (arachne, creds, photos, mail, dns, locations, media_metadata_api, configy, comhra, scheduled_scripts…). So ~43 ship images; 4 have any defence. Rollout should stage by blast radius (user-facing HTTP first) and each stage verified by re-introducing a known-bad bump — we now have three real ones, a better test set than anything invented.
