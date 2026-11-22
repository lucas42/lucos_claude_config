---
name: risk-lucos-backups-dev-prod-ssh-key-exercised
description: lucos_backups dev store holds the prod SSH key; a laptop dev copy actually ran create/prune-backups against production on 14 days (2026-07-04 to 11-22)
metadata:
  type: project
---

lucas42/lucos_backups#442 (my 2026-10-19 finding, raised Medium to High on 2026-11-22) was exercised in practice, not just theoretical. lucas42's laptop log confirms the dev copy ran `create-backups` and `prune-backups` against production hosts on 14 days between 2026-07-04 and 2026-11-22 (the unexplained ~04:49Z deleter in lucas42/lucos_backups#365). Fingerprint comparison and sshd logs were unavailable, so the hypothesis was confirmed by the laptop log only.

**Why:** I rated it Medium because "it adds nothing for agents" and ignored non-agent readers/runners of the dev store. **How to apply:** when sizing a dev-store credential, consider every machine that pulls the dev `.env` (`localcreds`), not just agents. Disposition: split keys, rotate prod with an overlap (add new pubkey, redeploy, then remove old).
