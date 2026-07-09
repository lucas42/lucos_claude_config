---
name: policy-dev-prod-credential-containment
description: Dev environments must never hold a functioning prod-aithne (or any prod) credential, even a purpose-scoped one minted specifically for dev use
metadata:
  type: project
---

**Decision (2026-07-09, lucos_worlds dev-login blocker):** when lucos_creds' link-validation blocked linking dev worlds' `KEY_LUCOS_AITHNE` to aithne's production credential ("only read-only scopes... permitted on a link from non-production to production"), the proposed workaround — mint a *separate* dev-only OIDC client (`lucos_worlds_dev`) in prod aithne with its own secret + localhost redirect_uri, then hand-copy that secret into dev creds — was vetoed.

**Why:**
1. The lucos_creds link-validation only fires on *linking* dev to an *existing* prod credential. Hand-minting a fresh credential and manually writing it into dev creds never touches that check at all — and agents already have dev-environment write access, so nothing technical stops it. This degrades "dev never holds a working prod credential" from an enforced system invariant into a paperwork convention, which is a bigger loss than the specific credential's narrow scope suggests.
2. Residual risk on the credential isn't zero even with redirect_uri pinned to localhost — [[risk-prompt-injection-and-ci-logs]] and the broader "no internal trusted network" fact mean a compromised dev host or an accidentally-exposed dev port turns a leaked secret into live impersonation against prod aithne for that client.

**Resolution:** lucos_worlds dev uses standard (non-OIDC) auth for now to unblock local dev. A separate aithne-dev-infra initiative (mkcert-issued HTTPS cert in front of *dev* aithne, so dev finally satisfies OIDC clients' hard `https://` issuer requirements like BookStack's) is the preferred long-term fix — but it's estate-wide (aithne's issuer derives from a single `APP_ORIGIN`, so serving dev aithne over HTTPS changes the issuer for *every* dev OIDC consumer and needs CA trust added to each consumer container), so it's tracked as its own initiative, not bundled into the lucos_worlds ticket.

**How to apply:** if any other lucos service hits this same "dev can't complete real OIDC/OAuth against a prod-only IdP" wall, the answer is the same: reject any path that ends with a working prod credential in dev, whether via lucos_creds link or a hand-minted separate client. Point them at (a) standard auth in dev as the cheap unblock, or (b) the aithne-dev-HTTPS initiative as the durable fix, once it exists.
