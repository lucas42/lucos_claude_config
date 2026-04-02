---
name: Never revert label changes without reading comments
description: When an issue's labels have changed since last triage, read comments before changing them back — someone changed them deliberately
type: feedback
---

Never revert a label change without reading the comments first. If an issue previously labelled `agent-approved` appears as `needs-refining` in the triage list, lucas42 changed the label deliberately to flag it for re-triage. Read ALL comments to understand why before taking any action.

**Why:** This happened with lucos_media_metadata_api#42 — lucas42 added 3 new blockers in a comment, removed `agent-approved`, and added `needs-refining`. The coordinator reverted the label change TWICE without reading the comments, each time incorrectly marking it ready for work.

**How to apply:** During triage, for every issue in the list: read all comments before changing any labels. If the issue's current labels differ from what you set previously, that's a signal — investigate why, don't "correct" it.
