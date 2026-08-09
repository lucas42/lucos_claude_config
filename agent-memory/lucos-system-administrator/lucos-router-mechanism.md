---
name: lucos-router-mechanism
description: How lucos_router actually provisions certs and routes domains — certbot mechanism, non-l42.eu precedent, template shapes, domain-set sourcing
metadata:
  type: reference
---

Read the actual source (not just the README) while scoping lucos_router#104 (2026-08-09, TLS-terminated redirects for ghs.google.com subdomains).

**Cert provisioning is NOT restricted to `l42.eu` domains.** `scripts/update-domains.sh` runs `certbot certonly --nginx ...` (standard HTTP-01 challenge) per domain in the active domain-set — the only requirement is DNS pointing at the router host at request time (documented gotcha: "DNS needs set-up _before_ running"). Live precedent already running: `scripts/fetch-domainsets.sh` hardcodes `tfluke.uk`/`www.tfluke.uk` (proxying to `https://lucas42.github.io`, entirely external) as a special case for the `avalon` host, and `nas.l42.eu` similarly for `xwing`. Any future "can lucos_router serve domain X outside l42.eu" question is already answered: yes, same mechanism.

**Domain sourcing**: `fetch-domainsets.sh` pulls the normal domain list from `configy.l42.eu/hosts/http` + `/systems/host/{id}` (real lucos systems only). Non-system domains (personal redirects, external proxies) get hardcoded directly in this script as host-specific special cases — that's the established pattern for anything that isn't a registered lucos system.

**Template shapes** (`templates/`): `https.conf` is `proxy_pass {{backend}}` only — reverse-proxies to a live backend, forwards the original `Host` header. **Not suitable for redirecting to a third party like Google** — sending `Host: our-domain` to Google's servers breaks their own routing/login flow. `router.conf` (used for the host's own bare domain) already does a plain `return 301 https://l42.eu/;` for its home-page case — that's the precedent to copy for a straight external-URL redirect, not `https.conf`'s proxy_pass.

**Domain-set file format** is currently `DOMAIN BACKEND_URL` pairs, always fed into the proxy_pass template — no existing way to mark an entry as "redirect to this URL" vs. "proxy to this backend". A `return 301` use case needs a small format/template-selection extension.

**Gotcha carried over from README**: DNS must resolve to the router host *before* `update-domains.sh` runs, or the certbot HTTP-01 challenge fails. Sequence DNS changes before/alongside router-side domain-set additions, not after.
