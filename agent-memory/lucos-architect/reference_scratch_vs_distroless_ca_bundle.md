---
name: scratch-vs-distroless-ca-bundle
description: FROM scratch ships no CA bundle/tzdata; distroless/static does. Choose distroless/static for any Go service that might make outbound HTTPS.
metadata:
  type: reference
---

For Go services compiled `CGO_ENABLED=0`:

- **`FROM scratch`** ships *nothing* — no CA bundle, no tzdata, no /etc/passwd, no nonroot user. Go's TLS client verifies against `/etc/ssl/certs/ca-certificates.crt`; absent that file the trust store is empty and it rejects *every* public cert with `x509: certificate signed by unknown authority`. `time.LoadLocation` likewise needs `/usr/share/zoneinfo`.
- **`gcr.io/distroless/static-debian12`** ships a CA bundle, tzdata, /etc/passwd and a nonroot user by default, for a marginal size/attack-surface cost over scratch.

Estate state (verified 2026-06-12): `lucos_docker_health` uses distroless/static; `lucos_aithne` used `FROM scratch` and shipped no CA bundle.

**Incident (2026-06-12, lucos_aithne#106):** aithne deferred the CA bundle to "when the service makes its first outbound HTTPS call" — in a Dockerfile *comment*, with no tracking issue and no CI guard. `lucos_aithne#105` was exactly that moment (first `contacts.Get()` over HTTPS); the deferred work was due but nothing connected the trigger to the task. ~1h55m admin-only degradation. Fixed by copying ca-certificates.crt + zoneinfo into the scratch stage (`#107`). SRE incident report: lucos PR #241. Estate audit: lucos#240.

**Architectural takeaways:**
1. A source comment is not a tracking mechanism — no trigger, owner, or surfacing. Design-time deferrals belong in tracked issues with a named trigger condition. (See [[feedback_file_followups_during_design]].)
2. Deferring a near-zero-cost robustness measure (a few hundred KB, two COPY lines) to save almost nothing, creating a silently-activating latent failure, is the anti-pattern. Ship CA certs + tzdata in any image that *might* ever make an outbound call.
3. Prefer **distroless/static over scratch as the default** for new Go services unless the service provably needs nothing outbound and no timezone handling — "makes no outbound calls" is true at creation and goes false later, silently. scratch's only genuine merit is absolute-minimum attack surface. Convention/ADR candidate if reframed from lucos#240.
4. Non-fatal fallback (log + degrade) correctly contains blast radius but keeps /_info green while broken — surface the degraded state (counter / monitoring warning tier, [[lucos_monitoring#74]]) rather than making the call fatal. See [[reference_docker_healthy_not_reachability]].
