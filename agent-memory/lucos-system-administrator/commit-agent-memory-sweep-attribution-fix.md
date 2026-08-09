---
name: commit-agent-memory-sweep-attribution-fix
description: The auto-commit sweep (post-turn-hook.sh / 15-min cron) used to commit all personas' dirty memory files as one commit under sysadmin's identity — fixed to per-persona commits + a quiescence window, 2026-08-09
metadata:
  type: reference
---

`~/.claude/scripts/commit-agent-memory.sh`'s sweep mode (no `--app` — used by
`post-turn-hook.sh`'s Stop hook, which fires after *every* turn for *every*
concurrent session, and by the 15-minute cron fallback) originally did one
giant commit spanning the whole `agent-memory/` tree, always attributed to
`lucos-system-administrator[bot]` regardless of whose files were actually
dirty.

**Consequence, caught by `lucos-architect` 2026-08-09**: because the Stop hook
fires so often and across every concurrent session, another persona's
in-flight (not-yet-committed) memory edit could get scooped up by someone
else's turn-end sweep before the author's own `commit-claude-main` call
landed — committing it under the wrong bot identity with a generic message,
silently discarding whatever rationale the actual author had written. Nothing
failed, nothing alerted; the content landed correctly, just under the wrong
name with the reasoning gone. `team-lead` independently verified before
escalating: 10 of the last 20 commits matching that generic message were on
`origin/main` — a frequent collision window, not theoretical.

**Fix 1 — per-persona attribution** (`lucas42/lucos_claude_config@da85439`):
sweep mode now iterates every `agent-memory/<persona>/` subdirectory with
pending changes and commits+pushes each one *separately* under that persona's
own looked-up identity — structurally identical to calling `--app <persona>`
directly, so it can never cross-attribute again. A directory with no matching
`personas.json` entry is skipped with a loud warning rather than silently
falling to the sysadmin catch-all. `projects/` (dispatcher auto-memory, no
single-persona owner) stays on the sysadmin identity. Incidental fix in the
same pass: the old all-in-one-commit design meant a conflict-marker file
anywhere in `agent-memory/` blocked the *entire* sweep; each persona's commit
is now isolated, so one persona's conflict no longer holds everyone else's
clean changes hostage.

**My first framing of the residual was wrong, and `lucos-architect` corrected
it the same night.** I initially wrote off the remaining "sweep grabs a
persona's own in-flight edit before they commit it" case as an acceptable
same-identity self-race. Two things wrong with that: (1) the lost commit
message harms whoever reads the repo later trying to understand why a rule
exists, not the original author — it was never really a *self*-race in the
sense that matters; (2) it isn't rare. The documented agent workflow is
"write a memory file, then commit it" — necessarily two separate turns — and
the Stop hook fires sweep mode after *every* turn, so it races that workflow
by default, every time, not just on unlucky timing.

**Fix 2 — quiescence window** (`lucas42/lucos_claude_config@4f0a95d`): sweep
mode now skips a persona's directory for the current cycle if any file in it
was modified within the last 5 minutes (`QUIESCENCE_SECONDS`), letting a
persona's own deliberate commit land first in the common case. The sweep (or
the 15-minute cron) still catches genuinely-forgotten files once they've been
quiet for a while — nothing is silently missed forever, just delayed. Persona
mode (`--app <persona>`) is unaffected — it's an explicit, deliberate call,
and quiescence would only get in the way of the normal
write-then-immediately-commit pattern many personas already use in one turn.

Both fixes tested first in an isolated sandbox (throwaway bare repo + fake
`personas.json`, zero production paths touched) before landing — full test
lists in each commit message. Tracked, with both fixes documented, as
`lucas42/lucos_claude_config#126`, cross-referenced against `#124` (a
different symptom of the same "the sweep stages things it doesn't own" root
cause — that one's about partial/atomic-write `.tmp` files getting committed
mid-write, not attribution; still open, Ready, mine). `da85439` neither fixes
nor worsens `#124` — same per-persona `git add`-based staging risk, just
smaller scope per commit. `4f0a95d`'s quiescence window incidentally
*reduces* `#124`'s risk (a 5-minute delay normally clears a temp-write's
window) without structurally closing it — a stalled/crashed write's temp file
could still get swept once quiescence passes. Worth knowing before scoping
`#124`'s actual fix (temp files outside the repo, or excluding `*.tmp.*` from
staging), not a substitute for it.

Separately: don't run a broad `env | grep -i "secret-shaped-pattern"` on this
VM — it will print `LUCOS_AGENT_PEM` (the git-signing private key) in full.
Grep for specific expected var names only.

**Correction to my own in-the-moment assessment (team-lead verified,
2026-08-09):** when this happened I told team-lead "nothing was persisted
anywhere outside this conversation" — that understated it. The transcript
itself IS persisted, indefinitely, as a readable `.jsonl` file under
`~/.claude/projects/.../*.jsonl` (223 of them in this VM's session history
alone — `verify-teammate-quote` reads them routinely). Untracked/not-in-git
is not the same as ephemeral. Team-lead separately confirmed the *good* news
— `.gitignore` excludes transcripts from the actual git repo, and a sweep of
`origin/main` for PEM-shaped content found nothing leaked publicly — but
"printed to my own output" still means "now sitting in plaintext in a
long-lived file other tooling reads." Don't self-clear a credential-exposure
question either — route it to `lucos-security`, whose remit it is, even
(especially) when confident of your own read. Next time: hedge "nothing
persisted" claims about accidental secret output until actually checking
where this harness's transcripts live and how long they're kept.
