---
name: test-prescribed-values-against-rule
description: When you verify a validation rule AND prescribe concrete values to enter against it, test each value against the rule before publishing
metadata:
  type: feedback
---

When you've just verified a validation rule / allowlist / format constraint **and** you're handing someone concrete values to enter against it ("type exactly this", "set the field to X"), test **each prescribed value** against the rule before publishing.

**Why:** 2026-06-14, lucas42/lucos_auth_scopes#6 — I verified the lucos_creds scope allowlist as "alphanumerics + colon + comma only", then in the same thread prescribed `media-metadata:read` / `media-metadata:write` / `media-metadata:read,media-metadata:write,webhook`. Every `media-metadata:*` value contains a hyphen the rule rejects. The hyphen was visible in both the rule and the strings; I never cross-checked them. lucas42 hit `Validation Error: scope contains invalid character '-'` entering it in production. eolas (`eolas:read`, no hyphen) worked, masking the gap. The decision that followed was sound (relax the creds allowlist to permit `-`, since the vocabulary deliberately uses kebab-case domains like `media-metadata`) — but it should never have surfaced as a production failure.

**How to apply:** the moment a comment/message contains both (a) a constraint you verified and (b) a literal value to be entered against it, run the value through the constraint character-by-character before sending. This is Self-Verification item 11 in the persona. Distinct from "parse reference data, never hand-build it" ([[feedback_parse_reference_data_never_handbuild.md]]): that's about the reference set; this is about the *values you prescribe* against a rule.

**Update 2026-06-14:** the relaxation has landed — `lucos_creds` `server/src/storage.go:350` now permits hyphens (allowlist comment: "alphanumeric, colons, commas, and hyphens (for kebab-case domain names, e.g. media-metadata:read)"). So `media-metadata:read` now validates; do NOT re-warn that the creds scope rule rejects hyphens.

**What a rehearsal can and cannot show (2026-08-18, `lucos_claude_config#133`).** A rehearsal answers *"does this do what I wrote?"* — never *"did I write the right thing?"* It faithfully reproduces whichever design you built, so it is **strong evidence against** a design (a failure means something is genuinely wrong) and **weak evidence for** one. Usable form: *would this observation look different if the design were wrong?* If no, the run is a demonstration, not a test — and the tell is being able to predict the result exactly beforehand. Concrete case: a commit recorded *"verified the state file is never touched while sync is failing"*, which was a correct verification of the **wrong** design — the behaviour confirmed *was* the defect, written down as the pass criterion. When reporting a rehearsal in a commit or ticket, state what it **could not** have shown; one clause makes the scope visible to every later reader, who otherwise cannot tell a note confirming a right design from one confirming a wrong design. Danger is highest after a run of rehearsal successes, when the method's credibility transfers to conclusions it never supported.

