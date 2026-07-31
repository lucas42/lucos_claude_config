---
name: prefer-self-healing-finding-over-silent-suppression
description: In design review, reject an exemption/type/allowlist whose correctness depends on a human remembering a transition; prefer a loud self-healing finding
metadata:
  type: feedback
---

When a repeated audit/monitoring finding is annoying, resist "add a classification/exemption that suppresses it." Weigh the two remediation *architectures* by their failure modes:

- A **loud finding** that self-heals when the real condition is fixed (e.g. `in-lucos-configy` firing on an unclassified-but-soon-to-be-scaffolded repo) fails *safe*: it's noisy precisely because it wants resolving, and it disappears the moment the underlying state is corrected.
- A **standing suppression gated on a human transition** (e.g. a "planned" RepoType that must be flipped to "system" once the repo is built) fails *silent*: forget the transition and the suppressed checks — often the very deploy/security gates — never re-activate. You've built a permanent, invisible escape hatch.

**Rule:** a suppression whose correctness depends on someone remembering to un-suppress it is worse than the finding it silences. Only add a durable exemption/type when the exempted conventions are *permanently and falsely* inapplicable (a genuine non-system that will never have CI/deploy — architecture_models), not merely *not-yet* applicable (a future-system that's just empty today — worlds_atlas). For the not-yet case, leave it unconfigured/flagged and let the finding self-heal on scaffolding; if noise ever becomes real, fix it at the *finding-lifecycle* level (acknowledge/snooze — visible, per-item, reversible), not by suppressing a whole class of checks.

**Why:** 2026-07-09, lucos_repos repo-type assessment (architecture_models#3). Sysadmin floated a "planned" RepoType to spare empty future-systems the ~20 system conventions; I recommended against it and for a non-executable `docs` type only for genuine non-systems.

**Answering the "but the noise is a real cost" objection — the automatability argument.** The rule above says the loud option fails *safe*; that's true but it loses arguments, because the noise cost is concrete and the avoided risk is hypothetical. The decisive point is operational rather than a values judgement:

> The loud option's residue is an **artefact**. The silent option's residue is an **absence**. Artefacts can be listed, counted, aged and swept by a scheduled job. You cannot write a sweep for things that were never created.

So it isn't that one cost is more tolerable — it's that one has a cheap mechanical remedy available and the other has *none*, because it produces nothing to act on. Concede the noise cost honestly, then point out it's a housekeeping ticket while the alternative is unmanageable by construction. Same principle as "a service whose checks only probe dependencies cannot report its own failure" ([[recurring-docker-healthy-not-reachability]]): **a thing that cannot report its own failure cannot be managed.**

Worked example: 2026-07-31, lucas42/lucos#273 layer choice. Team-lead priced the stale-PR residue of a CI-assertion layer against a dependabot `ignore`. The `ignore` looks cheaper right up until you ask how you'd *detect* it over-matching — you can't, and `lucos_media_import`'s own comment records that the syntax fails silently. Also worth checking whether the residue is bounded/self-clearing before conceding its size (a blocked pre-release PR is superseded once the stable release lands — I flagged that as unverified rather than leaning on it).

**How to apply:** any review where the proposed fix is a new type/label/allowlist entry/exemption to quiet a recurring check, **or** a choice between a layer that fails visibly and one that fails silently. Ask: does its correctness depend on a human later reversing it? Does its failure produce an artefact anyone could sweep? If no to the second, that's usually decisive on its own. Related: [[feedback_alertable_check_must_recover]], [[feedback_detector_inverse_failure_mode]], [[base-image-bump-incident-class]].
