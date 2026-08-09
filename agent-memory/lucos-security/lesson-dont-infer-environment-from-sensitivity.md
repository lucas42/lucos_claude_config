---
name: lesson-dont-infer-environment-from-sensitivity
description: don't infer a credential is a production secret from how sensitive it sounds — check its actual lucos_creds system/environment/name before asserting who can write it
metadata:
  type: feedback
---

lucas42/lucos#286 (2026-08-08/09, `LUCOS_AGENT_PEM` rotation): team-lead's original framing was appropriately hedged ("*if* the plaintext lives in production lucos_creds, part of this is his and part may be ours"). I flattened that hedge into a flat assertion in the ticket body I wrote — "writing the new key into production lucos_creds is a production write... both halves of this rotation are his to perform" — without independently checking. It turned out to be a `development`-environment credential (`lucos_agent/development/LUCOS_AGENT_PEM`) all along; only the GitHub App key *regeneration* was actually lucas42-only, not the storage step. Team-lead's own diagnosis of their identical error applies to mine too: **"sensitive-sounding stood in for non-development" — I reasoned from the credential *being a private key* to it *being a production secret*, rather than looking up where it was actually stored.**

**Why this matters for this persona specifically:** dev-vs-production lucos_creds environment is a *routing-determining* fact across a lot of what I do — who can execute a remediation (agent vs. lucas42-only), how urgently something needs to be escalated, whether an Open Questions gate is warranted. Getting it wrong doesn't just misstate a detail, it misroutes the actual task (here: the whole rotation read as blocked on lucas42 when only the App-key-regen half was).

**How to apply:** before writing "this needs lucas42" or "this is a production write" into an issue body, check the actual lucos_creds system/environment/name (or explicitly flag it as unverified, the way I already do for other unconfirmed claims) — don't infer environment from how sensitive the credential sounds, how privileged its use is, or who told me about it. A PEM/API key/password being *powerful* says nothing about which lucos_creds environment it lives in. This is the same discipline as [[lesson-grep-verification-blind-spots]] (don't trust an inference's scope beyond what was actually checked) applied to credential routing specifically rather than search methodology.
