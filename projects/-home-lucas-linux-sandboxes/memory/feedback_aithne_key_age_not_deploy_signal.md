---
name: feedback-aithne-key-age-not-deploy-signal
description: "aithne /_info signing_key_age is a liveness signal, NOT deploy confirmation — confirm deploys authoritatively (container/image, not the key-age proxy)"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 1a322f6a-b1ba-45ab-8435-5406ebc4888e
---

aithne's `/_info` `active_signing_key_age_seconds` / `signing_key_age` check is a **liveness** signal ("process has run too long without a deploy"), **not** a deploy-confirmation signal. The signing key lives in the persistent `credential_store` volume and is rotated at startup **only if it is already older than the rotation interval** (per the check's own techDetail: "rotates it at startup once older than the rotation interval"). So a normal restart/redeploy leaves a still-fresh key **unchanged** — the key age does **not** reset on every restart, and "key age high ⇒ hasn't redeployed" is **false**.

**Why:** 2026-06-25 — I built a redeploy-watch that polled `/_info` waiting for the key age to "reset to near-zero" as the deploy-landed signal, polled ~40 min, wrongly concluded "aithne hasn't redeployed / broken version never reached prod," and escalated to SRE. aithne had actually redeployed at 12:56:31Z onto the latest commit. SRE corrected the mental model via direct ground-truth (container `StartedAt` + image tag).

**How to apply:** To confirm a deploy actually landed, use an **authoritative** source — **loganne deploy events** (per lucas42, loganne records what version of an app was recently deployed — the self-serve interim check; see [`references/monitoring-loganne.md`](../../../.claude/references/monitoring-loganne.md)), the container `StartedAt` / image tag (SRE via SSH), or a `version`/`commit` field in `/_info` (being added — lucas42/lucos_aithne#215; estate-wide spec version parked in Ideation). Do **not** infer deploy state from the key-age proxy. As coordinator (no SSH), when I need deploy confirmation I can't get directly, ask SRE rather than asserting from a proxy metric whose semantics I've only inferred from a description. General rule: this is the [[hedge-unverified-claims]] failure mode — reverse-engineering a signal's meaning from its label is a hypothesis, not evidence.
