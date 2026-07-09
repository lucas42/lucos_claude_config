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

**How to apply:** any review where the proposed fix is a new type/label/allowlist entry/exemption to quiet a recurring check. Ask: does its correctness depend on a human later reversing it? If yes, prefer the self-healing finding. Related: [[feedback_alertable_check_must_recover]], [[feedback_detector_inverse_failure_mode]].
