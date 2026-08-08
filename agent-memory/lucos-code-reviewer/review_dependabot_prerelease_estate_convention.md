---
name: review-dependabot-prerelease-estate-convention
description: Pre-release/beta Docker base-image Dependabot bumps are an open estate-wide policy question (lucos#273) — don't recommend a per-repo dependabot.yml ignore rule
metadata:
  type: reference
---

When a Dependabot PR proposes bumping a Docker base image to a pre-release/beta/alpha tag (e.g. `python:3.15.0b2-alpine`, `php:8.6.0alpha2`), this is **not** a fresh problem to solve per-repo. `lucas42/lucos#273` ("Decide an estate convention for runtime breakage that CI and `/_info` both miss") already covers it, tracking three prior incidents (lucos_mail alpine/Dovecot outage, lucos_contacts+lucos_eolas python beta CI-block, lucos_media_metadata_manager php alpha outage) and is an open "premise decision" awaiting lucas42.

**Do not recommend a per-repo `dependabot.yml ignore` rule as the fix.** lucos#273's own analysis rejects that layer explicitly: an `ignore` rule that silently stops matching is invisible and can't be swept (no PR ever opens, so nothing announces the guard has gone stale), whereas a failing required CI check produces a discoverable, self-clearing PR. The recommendation on #273 (point 4) is instead "a pre-release base image requires a human decision" enforced via a **CI assertion**, not Dependabot config.

**What to do on a fresh occurrence:**
1. REQUEST_CHANGES / recommend closing the specific PR (the beta-image reasoning itself still stands — betas aren't appropriate for production).
2. Add the occurrence as a data point comment on lucas42/lucos#273 (repo, bump, outcome, whether CI caught it or it shipped) — do **not** file a new per-repo issue proposing an ignore-rule fix.
3. If you've already filed such an issue before reading this, close it as superseded by #273 and move the data point there instead.

Confirmed miss: lucos_creds#511 (python 3.14.5→3.15.0b2, 2026-08-08) — filed lucos_creds#512 recommending a per-repo `ignore` rule before checking for an existing estate-wide issue on the same pattern; had to retract and redirect to #273. The gap was in "search for existing issues before filing" — I checked the target repo's own issues but not the `lucos` meta-repo for a cross-cutting convention issue on the same failure class. **Extend that search to the `lucos` meta-repo whenever the follow-up is an infra/convention pattern (CI, Dependabot, Docker, `/_info`, monitoring config) rather than a repo-local bug** — those are exactly the kind of thing likely to already have a cross-repo tracking issue.

Related: [[feedback_dependabot_stale_regression]] (deterministic-recreate discipline — separate but adjacent Dependabot judgment call).
