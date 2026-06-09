---
name: encryption-at-rest-vs-ransomware
description: Backup security — encryption-at-rest protects confidentiality, NOT availability vs ransomware that encrypts/deletes the copy; the availability lever is append-only/immutable destination access
metadata:
  type: reference
---

# Encryption-at-rest ≠ ransomware-availability defence

When weighing a backup/storage mechanism's security, do **not** treat "encryption at rest" as a mitigation for a *ransomware* gap. They address different properties:

- **Encryption-at-rest → confidentiality.** Protects the backup's contents if someone *reads/exfiltrates* the destination. Does nothing if ransomware *encrypts or deletes* the copy — a malicious encrypt-on-top destroys an already-encrypted repo just as it destroys a plaintext tree. You lose the copy either way.
- **The real ransomware-*availability* levers:** (a) **append-only / immutable destination access** — a restricted destination key/account that can append new backups but not delete or rewrite existing ones (restic `--append-only` + restricted SSH key; object-lock / WORM on object stores); (b) **geographic / offline diversity** — a copy ransomware on the LAN can't reach.

**Why it matters / how to apply:** surfaced reviewing lucos_backups ADR-0002 (PR #319, 2026-06-09), where rsync-`--link-dest` vs restic was partly argued on restic's encryption "mitigating" ADR-0001's LAN-ransomware gap. But ADR-0001's gap is explicitly *availability/geographic* ("aurora gives media diversity, not geographic diversity — avalon remains the only off-premises copy"). So encryption was orthogonal to the named gap; the honest restic edge on that axis is **append-only**, not encryption. When a backup decision invokes "ransomware," ask whether the proposed control defends *confidentiality* or *availability*, and match it to which gap is actually stated. Note: rsync hardlink-rotation has no native append-only/immutability equivalent — that's a genuine restic edge, separate from its restore-fragility downside (lost repo password = total loss of irreplaceable data, which is why rsync still won as primary there). See [[reference_named_volume_shadows_image]] only loosely related (backups).
