---
name: feedback-scratch-image-ca-bundle
description: FROM scratch Go images need ca-certificates.crt copied in before adding any outbound HTTPS call
metadata:
  type: feedback
---

When a Go service uses `FROM scratch` for its runtime stage, the trust store is empty. The moment you add the **first outbound HTTPS call** (e.g. `contacts.Get()`), you must also add:

```dockerfile
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
```

**Why:** `FROM scratch` has no CA bundle. Go's TLS client rejects all valid public certs with `x509: certificate signed by unknown authority`. The Docker build passes, CI passes — it only fails at runtime on the outbound HTTPS code path. Bit us in lucos_aithne#106 when #105 added `contacts.Get()`.

**How to apply:** Any time you add an HTTP/HTTPS client to a service, check the Dockerfile. If the runtime stage is `FROM scratch` or `FROM distroless` without `ca-certificates`, add the COPY lines before opening the PR. Don't wait for CI or a production incident to catch it.

Secondary note: non-fatal fallbacks (e.g. contacts name lookup falls back to contact ID) are good for blast radius but keep `/_info` green while a path is broken, so the degradation hides until someone exercises the specific code path.
