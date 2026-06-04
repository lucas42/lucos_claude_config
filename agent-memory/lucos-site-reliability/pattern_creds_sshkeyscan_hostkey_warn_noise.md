---
name: pattern-creds-sshkeyscan-hostkey-warn-noise
description: lucos_creds log WARN "no common algorithm for host key" bursts are benign ssh-keyscan multi-algo probes, not failures — don't re-investigate
metadata:
  type: project
---

`lucos_creds` server log shows recurring bursts of 4 WARN lines:
`Failed to create a new server connection error="ssh: no common algorithm for host key; we offered: [ssh-ed25519], peer offered: [rsa-sha2-512 ...]"` — one each for rsa, ecdsa, sk-ecdsa, sk-ed25519.

**Benign — do NOT file an issue or re-investigate each creds rotation.**

**Why:** Each 4-WARN burst is *immediately followed* (1-2s later) by a successful `INFO Served .env system=X environment=Y`. The fetch/deploy tooling runs `ssh-keyscan` (or an equivalent multi-key-type host-key probe) against creds.l42.eu before fetching credentials. The creds SSH server holds ONLY an ed25519 host key, so the RSA/ECDSA/sk probes fail with "no common algorithm" (logged server-side as WARN); the ed25519 probe + the real credential fetch succeed. Every credential fetch works. Confirmed 2026-06-04 ops checks: WARN bursts at 23:17/23:18/23:19/23:22/23:23 06-03 + 01:25 06-04, each followed by `Served .env` for lucos_configy/photos/arachne/deploy_orb.

**How to apply:** If you see these WARNs during Check 4 container log review, recognise the WARN→Served pairing and move on. Only escalate if a WARN burst is NOT followed by a successful Served .env (i.e. a real client genuinely can't connect). The only theoretical cost is log signal-to-noise in a security-sensitive service; not worth a fix given every fetch succeeds. Related: [[reference_lucos_creds_self_deploy]].
