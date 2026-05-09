---
name: Credential rotation must distribute the public material, not just store the private side
description: Cross-service watch heuristic. Any rotation script that writes a new credential to lucos_creds (or any other store) but doesn't push the public side to every consumer that needs it leaves a latent procedural gap that only surfaces on the first real rotation. Worth a periodic scan across services with rotatable secrets.
type: reference
---

Heuristic raised by lucos-architect after the 2026-05-09 lucos_backups SSH-key-rotation incident. Reproduced (paraphrased) here so it surfaces during ops checks and code reviews:

**The shape to watch for**: a service has a rotation script that (a) generates new credential material, (b) writes the private/secret side to lucos_creds (or another store), and (c) **stops there**, leaving the public side undistributed. The public side has to land on a remote host or peer for the new credential to actually function. Until the operator runs a separate, undocumented step to distribute it, the system is broken — but the rotation appears to have succeeded.

**Why it's a latent gap**: the rotation works on the credential-store side. The breakage only surfaces the first time anyone actually runs the rotation in anger; on day one of the script's existence the existing manual setup is still in place, so the gap is invisible until someone follows the documented procedure and finds the system broken.

**Where to scan during ops checks** (any service that has a rotatable secret with a public side that lives on a different system from the secret itself):

- SSH keys (e.g. `lucos_backups` / done — fixed in lucas42/lucos_backups#267).
- OAuth client secrets pinned into another system's config (the consumer needs the new client_secret too).
- mTLS client certificates presented to a peer (the peer's allow-list needs the new public cert).
- Webhook signing secrets (the receiver needs the new shared secret).
- API tokens used by an external service (the external system's allow-list).
- Any "we hand the consumer a hash/fingerprint of our key" (consumer's allow-list).

**Action when spotted**: if I find a second service with the same "create-but-not-distribute" shape, **ping lucos-architect rather than filing a per-service ticket immediately**. The architect's call: with two cases on the table, it may be worth lifting to a cross-cutting convention ("every rotation script must call a distribute step") rather than fixing one repo at a time. With one case, file per-repo (#266 / #268 already covers `lucos_backups`).

**Related architect memory**: `feedback_reference_implementation_propagation.md` (architect-side, encoded 2026-04-29) covers the related "new script inherits old script's defects" pattern, which is what made #267 ship with the same `/home/${USERNAME}/` path-hardcoding bug as `init-host.sh` until the path-expansion fix landed mid-loop.

Not a per-service ticket on its own — this is a watch heuristic to apply during cross-service reviews and ops checks. Filed 2026-05-09.
