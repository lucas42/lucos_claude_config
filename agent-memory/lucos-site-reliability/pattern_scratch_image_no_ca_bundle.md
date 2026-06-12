---
name: pattern-scratch-image-no-ca-bundle
description: x509 "signed by unknown authority" from one of our OWN Go services, when the served cert is valid, = the CLIENT (scratch image) has no CA bundle, not a cert problem on the serving end
metadata:
  type: project
---

`tls: failed to verify certificate: x509: certificate signed by unknown authority` in a lucos service's logs, where the *target's* cert is a valid public LE cert, is a **client-side trust gap, not a serving-end cert problem**.

**Why:** a `FROM scratch` Go runtime image (CGO_ENABLED=0 static binary) ships ONLY the binary — no `/etc/ssl/certs/ca-certificates.crt`. With no root CAs, Go's TLS stack rejects every public cert. Latent until the service makes its *first* outbound HTTPS call, so a deploy that adds a new outbound dependency can surface it long after the image was built.

**How to apply:**
- Diagnostic confirmation: `docker exec <svc> sh` returns `exec: "sh": executable file not found` → it's a scratch/distroless image. No shell + outbound x509 errors = missing CA bundle.
- Check the served cert is genuinely valid first (`openssl s_client -connect <host>:443`); if it is, stop blaming the serving end.
- Fix (developer, via PR — config-as-code, no production restart helps): add to the scratch stage `COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt` (Debian-based golang builder carries it). Add `/usr/share/zoneinfo` too if the binary loads `time.LoadLocation`.
- Verification: `/_info` green does NOT prove the fix — it only fails on the outbound-HTTPS path. Exercise the real path + confirm no further x509 errors.

First hit 2026-06-12: lucos_aithne (1.15.10) admin pages → `contacts.Get()` → `https://contacts.l42.eu`. Dockerfile comment had explicitly deferred CA certs "when the service makes its first outbound HTTPS calls"; PRs #101/#105 (~13:11Z deploy) brought that moment, fix never done. Tracked lucos_aithne#106. Other estate Go services on `FROM scratch` could have the same latent gap. Relates to [[pattern_three_stage_env_var_wiring]] as a "latent gap activated by deploy" class.
