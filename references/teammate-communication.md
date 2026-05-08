# Teammate communication

How agents on the lucos team talk to each other. Applies to **every** persona.

## Use SendMessage, not plain text

**All communication with teammates must use the `SendMessage` tool.** Plain text output is only visible to the user — it is NOT delivered to other agents. This applies to every message you send to a teammate: reporting task completion, asking a question, requesting a review, flagging a blocker.

If you respond to a teammate message in plain text rather than via `SendMessage`, they will never receive your reply. From their perspective, you ignored them.

This is not optional. It applies to every response to every teammate, including the dispatcher (team-lead) and lucos-code-reviewer.

## The user cannot see messages between teammates

Your messages to the team-lead (and their messages to you) are not shown to the user. The user only sees what the team-lead writes in plain text. When reporting findings or recommendations to the team-lead, be aware that the team-lead must relay the full content to the user — do not assume the user has any context from your previous messages.

## `teammate_id` is NOT the SendMessage target name

When you receive a `<teammate-message teammate_id="...">` message, the `teammate_id` attribute is a harness-internal identifier and may differ from the canonical persona name. Always address replies by the canonical persona name (e.g. `lucos-code-reviewer`, `lucos-security`, `lucos-site-reliability`, `team-lead`) as the `to:` field in `SendMessage`. Never echo the `teammate_id` from the envelope.

If unsure, the canonical names are the filenames in `~/.claude/agents/lucos-*.md` (minus the extension). The coordinator's canonical name is `team-lead`.

## Take the first action before going idle

When given multi-step work via SendMessage, take the first action before going idle. Processing an inbox message and then idling without acting on it creates a stalled-progress gap that the team-lead can only resolve by sending a redundant nudge — a real, observable failure mode in this team's workflow.

If the work is non-trivial, send a brief acknowledgement (`"starting now, will report back when X is done"`) before launching the first tool call; don't go silent between receiving the instruction and taking the first action. This is the inbox-processing analogue of the rule in [`references/incident-reporting.md` § "Don't gate drafting or shipping on long-running verification"](incident-reporting.md) — applied to your own queue rather than to verification windows. Same principle: durability of forward motion matters more than tidy batched updates.

## Cross-check substantive claims before forwarding

Cross-check a teammate's substantive claims against the durable source of truth before forwarding them to team-lead. A teammate's SendMessage chat content can drift from the formal artifacts they post on GitHub (review bodies, PR comments, commit messages) — both are real, but they may carry different content.

When a teammate makes a claim that affects what you or team-lead should do next (e.g. "this PR is supervised", "this issue is closed", "this commit landed at X"), and you have reason to suspect the claim might be wrong, verify against the durable source of truth (GitHub API for PR/repo state, git log for history) **before** flagging the claim — or any disagreement with it — to team-lead. Belt-and-braces against cross-channel mismatch: trust verifiable sources over secondary channels, even when the secondary channel is your own inbox.

When you do quote a teammate, quote verbatim from the source you have, and name the channel ("from the SendMessage they sent me", "from the GitHub review body") so the recipient can cross-check.

## Persona-specific extensions

Personas may extend this reference with:

- Additional rules specific to their workflow (e.g. the developer's "report PR approval as URL only — no supervision status").
- Persona-specific guidance on tone or content of messages to particular teammates.

Such extensions belong in the persona file, layered **on top of** the rules in this reference. Persona-specific guidance must not contradict the rules above.
