---
name: feedback-askuserquestion-layer-disambiguation
description: AskUserQuestion option labels must name the implementation layer when the same action is possible at multiple layers (code change vs detector change vs config change)
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 1d8b0493-7b56-4592-950d-0bfb7fba2120
---

When composing AskUserQuestion options, if the literal action described could plausibly be performed at more than one system layer, the option label or description **must** name the layer. Ambiguous labels get resolved at parse-time (by me, when reading the answer back), not at execution-time (by lucas42, when picking the option) — which means my misinterpretation silently overrides his intent.

**Why:** On 2026-05-16 I asked lucas42 how to handle `HOME` being flagged by the new `env_var_passthrough` convention. Option 3 was labelled "Stop reading HOME entirely" with description "Refactor the code to not use HOME — hardcode the path or read it via another mechanism. Larger code change." Lucas42 selected it, intending "stop the convention from flagging HOME" (i.e. exclude `HOME` from the detector). I executed it as "refactor lucos_media_linuxplayer's code to not read HOME" — filed an issue, triaged it, sent an architect consultation, and was about to /dispatch when he interrupted. Cost: one wasted issue (`lucos_media_linuxplayer#115`), one misframed architect SendMessage, and an in-flight dispatch I had to abort.

The verbatim option label "Stop reading HOME entirely" was the problem — it could describe (a) refactoring application code, or (b) modifying the detector to skip HOME. The description elaborated on (a) but lucas42 read the label as (b) because the rollout context was about the convention's design, not about linuxplayer's code.

**How to apply:** Before sending AskUserQuestion, sweep every option label and ask "could this describe an action at more than one layer of the system being discussed?" If yes — and it usually is, when the conversation has spanned multiple layers — rewrite the label so the layer is explicit. Examples:

- Bad: "Stop reading HOME entirely". Good: "Refactor linuxplayer code to not read HOME" vs "Exclude HOME from the convention's detector".
- Bad: "Don't validate this". Good: "Skip validation in the API handler" vs "Remove the schema constraint".
- Bad: "Ignore X". Good: "Filter X out at the ingest stage" vs "Drop X from the dashboard query".

The description field is not enough — lucas42 (and I) read labels first; the description is glanced at. Put the layer in the label itself.

See also [[feedback-ask-about-the-plan-first]] for the plan-shape rule that this complements.
