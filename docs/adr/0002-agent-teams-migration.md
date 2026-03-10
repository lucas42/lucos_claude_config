# ADR-0002: Migration from subagent dispatch to agent teams

**Date:** 2026-03-10
**Status:** Accepted

## Context

The lucos AI agent system originally used a **subagent dispatch model**: a single dispatcher session launched personas sequentially or in parallel via the Task tool. Each persona ran as a subagent within the dispatcher's context, reported its results back, and terminated. All inter-agent communication was routed through the dispatcher.

Claude Code introduced an experimental **agent teams** feature that allows multiple named teammates to run concurrently within a session, communicate directly via a mailbox system (SendMessage), and coordinate via a shared task list. lucas42 identified this as a potential improvement over the dispatcher model, particularly for direct interaction with individual agents.

The key architectural concern was **per-agent GitHub identity**. Each persona authenticates as a distinct GitHub App (via `gh-as-agent --app <name>` and `git-as-agent --app <name>`) so that commits, comments, and issues are attributed to the correct bot. Agent teams has no native per-teammate identity mechanism -- all teammates inherit the lead's permissions.

A secondary concern was whether the sequential phase ordering required by the `/routine` skill could be preserved. The subagent model gave the dispatcher precise control over execution order; agent teams coordinates via SendMessage, which is less deterministic.

## Decision

Migrate fully from subagent dispatch to agent teams. The migration was completed on 2026-03-10 in a single session. The key decisions were:

### 1. Identity via persona instructions (not enforcement)

Each persona's agent description file includes instructions to use the correct `--app` flag with `gh-as-agent` and `git-as-agent`. Because persona files are loaded as the agent description when a teammate is spawned, these identity instructions are present in every teammate's system prompt from the start.

This is the same mechanism that enforced identity in the subagent model -- the persona file was always the source of identity instructions. The delivery path changed (agent description instead of Task tool prompt), but the enforcement strength is equivalent.

### 2. Phase ordering via SendMessage + wait

The `/routine` skill preserves its sequential-then-parallel phase structure by using SendMessage with explicit "wait for all teammates to respond before proceeding" instructions between phases. This provides the same ordering guarantees as the subagent model: triage runs before ops checks, ops checks run before issue review.

### 3. PR review loop decentralised

The dispatcher no longer orchestrates PR reviews. Implementation teammates drive their own review loop: they message `lucos-code-reviewer` directly, address feedback, handle specialist reviews, and report the outcome when done. This uses agent teams' direct messaging for its intended purpose and reduces dispatcher complexity.

### 4. Dynamic team assembly

A `/team` skill discovers persona files by globbing `~/.claude/agents/lucos-*.md` (excluding non-persona files like ops check references), creates a team named `lucos-all-hands`, and spawns all teammates. New personas are automatically included without hardcoding.

### 5. Team config in version control

`teams/lucos-all-hands/config.json` is tracked in git. The `.gitignore` permits `config.json` while excluding inbox files and other runtime state.

## Consequences

### Positive

- **Direct interaction with agents.** The user can message any agent directly without routing through the dispatcher. This was the primary motivation for the migration.
- **Inter-agent communication.** Agents can message each other directly. The PR review loop benefits most: the developer and code reviewer iterate without dispatcher mediation.
- **Cleaner dispatcher role.** The dispatcher orchestrates workflow phases and reports to the user. It no longer needs to relay messages between agents or manage review loop state.
- **Parallel visibility.** In split-pane mode, all agents' work is visible simultaneously.

### Negative

- **Experimental feature dependency.** Agent teams is explicitly marked as experimental by Anthropic. The feature's API surface, behaviour, and limitations may change without notice. This is the most significant risk.
- **No enforcement of identity.** Per-agent GitHub identity relies on prompt compliance, not a technical enforcement mechanism. If a teammate ignores or misinterprets its identity instructions, it could authenticate as the wrong bot. In practice this has not been observed, but it is a weaker guarantee than a hypothetical native per-teammate identity feature.
- **Higher token usage.** Each teammate is a full Claude Code instance with its own context window. The subagent model summarised results back into the dispatcher's context, which was more token-efficient. The actual cost difference has not been measured yet (see Known Constraints below).

### Known constraints

These are accepted trade-offs that do not require immediate action but should be revisited as the feature matures.

**No session resumability.** Agent teams does not support `/resume` or `/rewind` for in-process teammates. If a session is interrupted (e.g. during a `/routine` run), all teammate state is lost and the run must be restarted from scratch. The previous subagent model had the same limitation in practice -- subagent context was ephemeral -- so this is not a regression, but it is worth documenting explicitly so nobody attempts to resume a team session expecting teammates to survive.

**Token cost not yet measured.** The issue-manager's pre-migration analysis flagged higher token usage as a concern. Now that the migration is complete, actual usage should be measured on a `/routine` run and compared to the pre-migration baseline. If the cost is significantly higher, mitigation options include: using lighter models for low-complexity teammates, reducing the number of concurrent teammates, or reverting specific workflows to subagent dispatch.

**No documented rollback procedure.** The migration rewrote all three skills (`/team`, `/routine`, `/next`) and the PR review loop document. The old subagent approach still technically works (the Task tool exists and persona files are unchanged), but reverting would require restoring the pre-migration versions of those files from git history. If agent teams proves unstable in production use, the rollback path is `git revert` of the migration commits (visible in the `lucos_claude_config` commit log from 2026-03-10). This is straightforward but not instant -- it requires a deliberate decision and a clean session restart.
