# Teammate communication

How agents on the lucos team talk to each other. Applies to **every** persona.

## Use SendMessage, not plain text

**All communication with teammates must use the `SendMessage` tool.** Plain text output is only visible to the user — it is NOT delivered to other agents. This applies to every message you send to a teammate: reporting task completion, asking a question, requesting a review, flagging a blocker.

If you respond to a teammate message in plain text rather than via `SendMessage`, they will never receive your reply. From their perspective, you ignored them.

This is not optional. It applies to every response to every teammate, including the dispatcher (team-lead) and lucos-code-reviewer.

## Direct user questions get direct replies

The rule above is about teammate-to-teammate communication. When the user addresses you directly (no `<teammate-message>` wrapper around their message), reply in plain text — they can read it. SendMessage is for teammate-to-teammate communication and for relaying outcomes back to team-lead after dispatched work. **Don't route direct user questions through team-lead.**

The failure mode if you do: team-lead receives a substantive answer addressed to them about a question that wasn't theirs in the first place, treats it as a coordination event, and gets distracted from other work. The user, meanwhile, has to ask why you went silent. Even if team-lead does relay your answer, the user reads the same text twice — which the global memory explicitly forbids ("Don't bulk-re-quote agent output to the user").

The team-context system message ("the user interacts primarily with the team lead") describes the default *routing* of new work into the team — it does not mean every reply from every persona should go through team-lead. Direct question to you → direct reply from you.

## Silence is not "no reply yet"

The rule above is sender-side guidance, but its failure mode is silent — a teammate who composes a reply only in their prose output produces no `<teammate-message>` envelope, so from the asker's side it looks identical to "they haven't picked it up yet."

When you've asked a question and a reply is blocking your next action, prompt the teammate to resend if you haven't seen an envelope arrive in your inbox. Don't assume silence means "still working on it" — assume it could mean "answered in prose, never delivered." A redundant nudge is cheap; stalling on a phantom reply is not.

## A reply may not be answering your latest message

SendMessage is **asynchronous and queued**, not a synchronous request/response. A teammate does not read their inbox the instant you send — they finish whatever turn they are already in first, *including emitting any replies that turn produces*, and only read your new message when they next process their inbox. Your outgoing send-order is **not** their inbox-processing order.

So when a `<teammate-message>` arrives shortly after you sent something, do **not** assume it is a response to *that* message. It may be:

- answering an **earlier** message of yours (the one they had actually read when their turn began),
- a self-initiated status report unrelated to your latest message, or
- the product of work they were already mid-flight on when your message arrived.

Correlate a reply to what it is actually about by its **content**, never by "it arrived after I sent X, so it must be about X." Consequences that bite repeatedly:

- **A superseding instruction is not in effect until acknowledged.** If you send message B that changes or cancels message A and then a reply arrives, check whether the reply reflects B before assuming B has landed. The teammate may have acted on A and not yet seen B. Don't treat the old state as overridden until you see an acknowledgement of B *specifically*.
- **Don't fire an actionable message and then a second related one in quick succession.** (a) A question then its answer — ask "which way, (a) or (b)?" then immediately "hold, it's neither" — they may act on the question before reading the retraction. (b) A **dispatch** (`implement issue {url}`) then a follow-up heads-up referencing that same work — the two cross, and it becomes unclear (to both of you) what's actually in flight. Either **fold the context into the single dispatch message**, or wait for the teammate to engage before sending the second. And when a status seems off, remember a **missing PR is ambiguous — it can mean "in flight, PR not opened yet", not "dropped"** — so **ask the teammate to confirm status rather than asserting they dropped it and re-dispatching** (a wrong "you dropped it" + re-dispatch risks duplicate work and erodes trust). Observed 2026-07-09: a `notes#441` dispatch fired right before a cross-PR propagation note; when a state check showed no PR I wrongly concluded it was dropped and re-dispatched — the dev had it in flight and opened the PR (lucos_notes#455) moments later; the messages had simply crossed.
- **A reply that doesn't reflect your latest message is not the teammate "ignoring" it.** It almost always means they hadn't read it yet. Confirm against timing evidence before concluding anything about what they "had in hand" — see [§ Cross-check substantive claims](#cross-check-substantive-claims-from-teammates).

A redundant clarification ("to be clear, this supersedes my previous message") is cheap; acting on a false assumption about what the other agent currently knows is expensive.

## Don't spawn teammates as subagents

When you need to interact with another `lucos-*` persona during a workflow (request a code review, escalate to security, ask for an SRE assessment), **always use `SendMessage` with `to: "<persona-name>"`** — they are already running teammates on the same team you are.

**Never use the `Agent` tool with `subagent_type: "lucos-..."`** to spawn a fresh subagent for the same purpose. It looks like the same outcome but it isn't:

- A fresh subagent has no shared inbox with the team — your "message" reaches them as a one-shot prompt with no context, and their reply comes back to you alone as a tool-call return rather than being visible to team-lead and the rest of the team.
- The team coordinator loses sight of what's happening, because none of the messages flow through SendMessage routing.
- The subagent bills its own context window, including re-loading its persona file, MEMORY.md, and any references — paid every time, instead of using the warm running teammate.
- Multi-round workflows (e.g. PR review iterations) become impossible to drive coherently, because each Agent call starts a stateless persona with no recollection of the prior round.

The `Agent` tool is for genuinely new contexts — research subtasks, file lookups, isolated worktree operations. It is **not** the mechanism for talking to a teammate that already exists.

If you find yourself reaching for `Agent({subagent_type: "lucos-foo"})`, stop and use `SendMessage({to: "lucos-foo", ...})` instead.

## Don't set a teammate as `owner` on your own tracking tasks

Setting `owner: "lucos-foo"` on a `TaskCreate`/`TaskUpdate` task surfaces to that teammate as a **`task_assignment` notification** — a *second*, weaker channel that competes with the real `SendMessage` dispatch and gets confused with it. The coordinator's tracking tasks (e.g. "Dispatch aithne#301 to lucos-developer") are the coordinator's *own* to-do list; **keep them owned by the coordinator (`team-lead`), never the implementing teammate.** A teammate's only real work-trigger is a `SendMessage` reading `implement issue {url}` — nothing else counts as a dispatch.

Observed failure (2026-07-09): dispatch-tracking tasks with `owner: lucos-developer` reached the developer as `task_assignment`s, which it read as a "duplicate #92 dispatch" and as a "#301 assignment with no `implement issue` trigger" — costing a round of clarifying messages. If you track a multi-dispatch sequence with tasks, own them yourself; dispatch is SendMessage-only.

## The user cannot see messages between teammates

Your messages to the team-lead (and their messages to you) are not shown to the user. The user only sees what the team-lead writes in plain text. When reporting findings or recommendations to the team-lead, be aware that the team-lead must relay the full content to the user — do not assume the user has any context from your previous messages.

## `teammate_id` is NOT the SendMessage target name

When you receive a `<teammate-message teammate_id="...">` message, the `teammate_id` attribute is a harness-internal identifier and may differ from the canonical persona name. Always address replies by the canonical persona name (e.g. `lucos-code-reviewer`, `lucos-security`, `lucos-site-reliability`, `team-lead`) as the `to:` field in `SendMessage`. Never echo the `teammate_id` from the envelope.

If unsure, the canonical names are the filenames in `~/.claude/agents/lucos-*.md` (minus the extension). The coordinator's canonical name is `team-lead`.

## A persona name is not a session — more than one session can share it

Two or more sessions can run concurrently under the same persona, sharing one name, one `SendMessage` address, and one `[bot]` git identity. Nothing in the envelope distinguishes them. This cuts both ways, and both halves have already bitten.

**Receiving / attributing.** A `verify-teammate-quote` VERIFIED result proves *the persona* said it — **not** that the session you are addressing said it. The tool searches across all of that persona's sessions, so it will happily verify a quote from session A while you are replying to session B, and return VERIFIED. That is the strongest possible false confidence, because the quote is genuine and the attribution is still wrong. It prints the session id (`→ session <id>… line N`) — read it, and treat a match from a different session as **unverified for attribution purposes**. Git authorship disambiguates nothing either: every session commits as the same `<persona>[bot]`, so a commit proves a run happened, not *which* session ran it. Prefer attributing to the **artifact** (ticket, PR, commit) over the sender whenever a persona may be running more than once, and never build a nudge, a correction, or a thank-you on cross-session attribution.

**Receiving / replying.** Do not assume a message addressed to your persona was meant for *your* session. If the incoming context doesn't match work you actually did, **say so immediately** — do not reconstruct a plausible history to fit it. The details in a misrouted message are specific enough to feel like something you might have forgotten, which is exactly what makes reconstruction tempting; and a reconstructed account propagates a fiction into the sender's context and onward to lucas42. Naming the mismatch costs one sentence. The reply shape that works: "this looks routed to the wrong session — I did X, not Y", followed by whatever you *do* actually own.

(Origin, 2026-07-19: two `lucos-site-reliability` sessions ran concurrently — one doing ops checks, one investigating lucos_photos#475. The coordinator matched a quote against the ops-check session's transcript and used it to reassure the *investigation* session that its message had landed, crediting it with a manifest and a judgement call it never made. The investigation session disowned the credit rather than reconstructing, which is what contained it.)

## Take the first action before going idle

When given multi-step work via SendMessage, take the first action before going idle. Processing an inbox message and then idling without acting on it creates a stalled-progress gap that the team-lead can only resolve by sending a redundant nudge — a real, observable failure mode in this team's workflow.

If the work is non-trivial, send a brief acknowledgement (`"starting now, will report back when X is done"`) before launching the first tool call; don't go silent between receiving the instruction and taking the first action. This is the inbox-processing analogue of the rule in [`references/incident-reporting.md` § "Don't gate drafting or shipping on long-running verification"](incident-reporting.md) — applied to your own queue rather than to verification windows. Same principle: durability of forward motion matters more than tidy batched updates.

## Cross-check substantive claims from teammates

Cross-check a teammate's substantive claims against the durable source of truth before forwarding them to team-lead, concurring with them, signing off on work they describe, or building further work on top. A teammate's SendMessage chat content can drift from the formal artifacts they post on GitHub (review bodies, PR comments, commit messages) — both are real, but they may carry different content. The rule applies even when you have no specific reason to suspect the claim is wrong; that's exactly when stale claims slip through unchallenged.

When a teammate makes a claim that affects what you or team-lead should do next — including past-tense reports of completed work ("pushed commit X", "amended PR Y", "filed ticket Z", "ran X and got Y") — verify against the durable source of truth (GitHub API for PR/repo state, `git log` for history, fetched issue/PR bodies for content claims) before flagging it, concurring with it, signing off on the work it describes, or building further work on top. The cheap-to-verify rule of thumb: if verification is one `gh api` call or one `git log`, do it. It's faster than recovering from a stale concurrence later. Belt-and-braces against cross-channel mismatch: trust verifiable sources over secondary channels, even when the secondary channel is your own inbox.

Past-tense work claims are the easy-to-miss subspecies — "pushed", "amended", "merged", "filed", "ran", "updated" — because they read as confirmations rather than predictions. Treat them as predictions until verified. The "I almost concurred without checking" *near-miss* is itself a signal that the verification habit needs to fire — those are actionable too, not just the failures. If you catch yourself reaching for "thanks, looks good" before you've fetched the artifact, stop and fetch.

When you do quote a teammate, quote verbatim from the source you have, and name the channel ("from the SendMessage they sent me", "from the GitHub review body") so the recipient can cross-check.

This section is the canonical placement of a pattern that several personas have local memories for under different names (e.g. `feedback_verify_before_propagating.md`, `feedback_verify_past_tense_work_claims.md`, `feedback_no_unverified_endorsement.md`, `feedback_refetch_before_accusing.md`, `feedback_verify_sibling_repo_claims.md`). Persona-local memories may add specific application examples; the rule itself lives here.

## Responding to `shutdown_request`

When team-lead sends a JSON message with `type: "shutdown_request"`, the **only** correct response is a structured `shutdown_response` sent via `SendMessage`:

```json
{
  "to": "team-lead",
  "message": {
    "type": "shutdown_response",
    "request_id": "<echo the request_id from the inbound request>",
    "approve": true
  }
}
```

This is the prescribed termination mechanism — it releases the shutdown handler and lets your process exit cleanly. The coordinator-persona (`~/.claude/agents/coordinator-persona.md`) explicitly waits for every teammate to confirm shutdown before calling `TeamDelete`. Without your `shutdown_response`, the coordinator hangs indefinitely and your process stays alive.

**Do NOT, during shutdown:**

- Spawn a fresh `Agent` (known to extend process lifetime past shutdown).
- Run `Bash` commands or use any other tool for in-band work.
- Reply with plain text only ("Acknowledged. Shutting down.") — the coordinator is waiting on the structured envelope, and a text reply never reaches it.

The single SendMessage with the structured `shutdown_response` IS the prescribed mechanism, not a violation of "no extra work during shutdown". The hazard during shutdown is starting new work (Agent spawns, Bash runs, multi-step tool chains), not the protocol response itself.

**Lesson from 2026-05-19/20 (lucos-architect):** an over-generalised feedback memory ("no tool calls during shutdown, not even SendMessage") led to a plain-text-only response to a shutdown_request. The coordinator hung overnight waiting for a confirmation that never came. The fix was to surface the protocol in this reference so personas don't have to rediscover it.

## Persona-specific extensions

Personas may extend this reference with:

- Additional rules specific to their workflow (e.g. the developer's "report PR approval as URL only — no supervision status").
- Persona-specific guidance on tone or content of messages to particular teammates.

Such extensions belong in the persona file, layered **on top of** the rules in this reference. Persona-specific guidance must not contradict the rules above.
