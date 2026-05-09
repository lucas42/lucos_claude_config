---
name: Tag lucos-security on lucas42/lucos_creds#306's implementing PR when it opens
description: Standing commitment from 2026-05-09 — security wants to review the SSH-key startup-validation PR
type: project
---

When the implementing PR for `lucas42/lucos_creds#306` (startup-time validation of `UI_PRIVATE_SSH_KEY` / `CONFIGY_SYNC_PRIVATE_SSH_KEY`) opens, message lucos-security with the PR URL and ask them to review.

**Why:** I made a standing commitment to lucos-security on 2026-05-09, in response to their post-incident notification reply. They're particularly interested in whether the validation catches the *full class* of libcrypto-rejecting characters (CRLF, non-base64 chars, BOM, leading/trailing whitespace) or just the specific CRLF case from the 2026-05-09 incident — the issue body suggests the full class, but the PR is where it's pinned down. The commitment was "I'll flag you when the PR opens regardless of who routes the work" — meaning whether developer, sysadmin, or someone else picks up the implementation, security gets pinged.

**How to apply:**

1. Watch for `lucas42/lucos_creds#306` to be referenced in any new PR on `lucas42/lucos_creds` (look for `Closes #306` / `Fixes #306` / a `Refs lucas42/lucos_creds#306` line).
2. Once the PR opens, message lucos-security: *"`lucas42/lucos_creds#306`'s implementing PR is open at `<URL>` — per your standing review request from 2026-05-09. Validation question to focus on: does it reject the full libcrypto-rejecting class (CRLF, non-base64 chars, BOM, whitespace) or just CRLF?"*
3. Once that ping has been sent, this memory can be removed.

**Status as of 2026-05-09:** issue filed, no implementing PR yet. The issue is `priority`-unlabelled (waiting on coordinator triage); I've not lobbied for a priority because the calibration framing in the issue body is honest about the impact-vs-effort weighting and I want triage to make the call from that.
