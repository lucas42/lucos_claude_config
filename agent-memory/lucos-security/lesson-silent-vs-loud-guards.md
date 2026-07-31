---
name: lesson-silent-vs-loud-guards
description: Prefer security/CI guards that fail loudly over ones that succeed silently — a working-but-unmonitored guard can stop matching and nobody notices
metadata:
  type: project
---

Surfaced during review of the 2026-07-31 media-metadata.l42.eu incident report (lucas42/lucos#274, PHP alpha base image dropped `mbstring`). lucos-system-administrator independently verified that the `lucos_media_import` Dependabot `ignore` rule for Python pre-releases genuinely works — it suppressed a live pre-release for ~40 days — but its correctness is **invisible**: nothing announces it if the registry's tag format shifts and the rule stops matching. lucos-site-reliability folded this into the incident report as a general lesson: prefer guards that fail loudly (a CI check that visibly reds out, per lucas42/lucos_mail#61's verified approach) over guards that succeed silently (a `.yml` ignore/suppress rule with no drift detection).

**Why:** A silent-success guard degrades from "protecting you" to "doing nothing" with zero signal at the transition point. The team only trusts it because it worked in the past, not because anyone would notice it stopped working. This is the same shape as [[risk-unattended-upgrades-origin-scope]] (a restriction that silently broadened for months, config drift undetected) — a different mechanism, identical failure mode.

**How to apply:** Generalises beyond Dependabot to security-control review broadly — when reviewing any suppression/allowlist/ignore mechanism (Dependabot ignore rules, CodeQL dismissals, firewall allowlists, WAF exception rules, auth bypass allowlists), ask not just "does this work today?" but "what tells anyone if this silently stops matching/firing?" If the answer is nothing, that's a finding worth raising even if the guard is currently functioning correctly — the absence of drift detection is the risk, not the current state. Ties into the existing estate policy of never proposing semver-major Dependabot ignore rules — this lesson is the sharper, more general reason why: it's not just that major bumps should flow through, it's that ignore-style guards are inherently harder to verify are still doing their job.
