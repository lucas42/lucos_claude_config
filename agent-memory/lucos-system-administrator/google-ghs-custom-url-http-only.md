---
name: google-ghs-custom-url-http-only
description: Google's legacy CNAME-to-ghs.google.com/ghs.googlehosted.com custom service URL feature is HTTP-only by design — never a DNS problem
metadata:
  type: reference
---

lucos_dns#126 (2026-08-09): subdomains CNAMEd to `ghs.google.com` (Google Workspace "custom service URLs" — e.g. `cal.`/`mail.`/`docs.` on lukeblaney.co.uk, `home.`/`boat.`/`cal.` on rowanblaney.co.uk) stopped working. Not a DNS issue — CNAME/A resolution was correct throughout.

**Root cause, confirmed against Google's current documentation** (support.google.com/a/answer/53340 → knowledge.workspace.google.com/admin/getting-started/customize-a-google-workspace-service-url): "The Admin console supports only HTTP connections for custom URLs... If your domain uses a security measure that requires HTTPS connections, such as HTTP Strict Transport Security, you can't customize service addresses for your domain." This is not a deprecation, not a recent change server-side — it has always been HTTP-only by design.

**Verified directly with `openssl s_client`**: TLS handshake to the `ghs.google.com` / `ghs.googlehosted.com` IP fails immediately (`SSL_ERROR_SYSCALL`, connection closed after ClientHello, 0 bytes) for ANY SNI tested — including a known-good Google hostname on the same IP. Confirms the endpoint doesn't serve TLS at all, for anyone — not a missing-cert-for-our-domain problem. Switching the CNAME target from `ghs.google.com` to `ghs.googlehosted.com` (the currently-documented target) changes nothing — identical behaviour on both.

**Why it "recently" broke with unchanged infra**: client-side, not server-side. Modern browsers (Chrome et al.) default new navigations to HTTPS-first (HTTPS-Upgrades, on by default since ~2021) — so a request to one of these subdomains tries HTTPS first, fails immediately with no fallback to the working HTTP redirect.

**No DNS/BIND fix exists.** Remediation is a design choice: (A) self-host a TLS-terminated redirect (e.g. via lucos_router) pointing at the current Google Workspace URLs, or (B) drop the custom subdomains and use Google's URLs directly. Flag any future "ghs.google.com stopped working" report the same way — check TLS first, don't assume DNS or a Google-side outage.
