# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) for all projects in this environment.

## Commit Messages

Do not add `Co-Authored-By` trailers to git commits. The bot identity on each commit already makes authorship clear.

**Always use `git-as-agent`** (not raw `git`) for all git operations — commits, rebases, cherry-picks, etc. This ensures commits are attributed to the correct bot identity. See [`references/agent-github-identity.md`](references/agent-github-identity.md) for details.

**Exception — files under `~/.claude`:** commit them with `commit-claude-main --app <persona> -m "..." <files…>`, never a hand-rolled `git-as-agent` add/commit/pull-rebase/push. The `~/.claude` checkout is *shared* and routinely dirty with other agents' uncommitted memory files, so a manual rebase/stash on it can drop their in-flight work; `commit-claude-main` commits onto a freshly-fetched `origin/main` via an isolated throwaway worktree that never touches the shared tree. See the "Committing `~/.claude` changes" section of that reference.

## Terminology

Avoid deprecated master/slave terminology in all infrastructure naming. Use primary/secondary instead — in volume names, directory names, comments, and documentation. BIND configuration uses `type secondary` (modern terminology); match this in surrounding infrastructure names.

## Learning from Mistakes

When you fail to follow an instruction, do not apologise. Instead, suggest a concrete improvement to the instructions or environment that would prevent the same mistake from happening again. There is nothing wrong with making mistakes — but we should always learn from them.

When a routine operation hits a **hard error due to a structural constraint** (e.g. a tool limitation, API restriction) that will recur in future runs, fix the relevant instructions immediately — don't just work around it and move on. The first occurrence is the right time to fix it, not the third.

**Trigger — hard tool errors:** Whenever a tool call returns a hard error (`Blocked:`, `InputValidationError`, permission denied, invalid input, etc.), **stop before retrying or working around it** and ask: *was this call prescribed by an instruction file (skill, persona, routine doc)?* If yes, the instruction is what needs fixing — update it first, then retry. A local workaround without an instruction fix guarantees the next session hits the same wall. Helpful error messages that suggest a workaround (e.g. "use run_in_background: true") are especially dangerous — they make it easy to patch the symptom and forget the cause.

**Update the instruction, not just the memory.** When a mistake occurs in a routine task (ops checks, triage, issue review, etc.), find the instruction file that should have prevented it — persona file, skill file, reference — and fix it (or delegate to the appropriate teammate). Memory is session context that may not persist reliably across conversations; instructions are what agents actually follow every run. Saving a feedback memory is not a complete fix on its own — always pair it with the instruction update. If you catch yourself saving a memory and moving on without finding the instruction to edit, stop and find it.

**When updating an instruction, prefer consolidation over additive growth.** If a rule already covers your case and a mistake happened anyway, the existing rule needs tightening, relocating, or rephrasing — not a parallel duplicate. N near-identical rules dilute each other; one well-placed rule at the moment of action is more likely to fire than three echoes scattered through the file. Before adding a new CHECKPOINT or paragraph, find the existing instance and edit it in place. Aim for the section's net size to stay flat or shrink, not grow. (Long instruction files cause attention degradation — agents skip rules buried deep; consolidating keeps the surviving rules load-bearing.)

---

## Hedge Unverified Claims

When you state something you do not have direct evidence for, explicitly mark it as unverified. Use hedging language: "I think", "possibly", "it seems", "a plausible explanation is", "my best guess is", "I haven't verified, but", "the most likely reason is — though I haven't checked".

Speak with full authority only when you have just observed the source of truth (the output of a command, the contents of a file, a response from an API, a tool result in this turn). The moment your reasoning runs past your evidence, switch register and signal it. This applies as much to internal-feeling reasoning ("the script's criteria say X, so the runtime state must have been Y") as to obvious guesses — reverse-engineering from logic is a hypothesis, not evidence about what actually happened.

When a user or another agent asks for evidence and you don't have it, say so plainly: "I don't have direct evidence — I was inferring from {X}." Do not dress the inference up as fact. Specifically:

- Do not present a hypothesis ("Status was null") as an observation ("Status was null").
- Do not assert state from memory of a prior session — re-fetch first, or hedge.
- Do not extrapolate from one observed sample to a general claim without hedging.
- Do not relay another agent's statement as fact unless you've verified it (per the existing `verify-teammate-quote` rule).

The same rule applies in inter-agent communication: an unhedged claim relayed verbatim becomes a fact in the next agent's context, which then propagates downstream. Hedge the original so the hedge survives the relay.

---

## Environment Variables & lucos_creds

Secrets and environment-varying config are managed by a service called **lucos_creds**. To write the local development `.env` file, run:

```bash
scp -P 2202 "creds.l42.eu:${PWD##*/}/development/.env" .
```

This is aliased as `localcreds` in the user's shell, but that alias is not available to Claude — use the raw command above.

### Standard vars always provided by lucos_creds

Every project gets these automatically:

| Variable | Description |
|---|---|
| `SYSTEM` | The system name (e.g. `lucos_photos`) |
| `ENVIRONMENT` | `development` or `production` |
| `PORT` | The port this service is exposed on |
| `APP_ORIGIN` | The public-facing base URL |

### Variable naming conventions

- External event infrastructure: `LOGANNE_ENDPOINT` (not `LUCOS_LOGANNE_URL` or similar)
- Contacts API: `LUCOS_CONTACTS_ORIGIN`

#### `*_ENDPOINT` vs `*_ORIGIN`

Use `*_ENDPOINT` for full URLs used as-is in code (e.g. `LOGANNE_ENDPOINT="https://loganne.l42.eu/events"`) and `*_ORIGIN` for base URLs to which code appends paths (e.g. `APP_ORIGIN="https://photos.l42.eu"`). Full convention documented in [lucos#148](https://github.com/lucas42/lucos/issues/148).

### What goes where

- **Hardcode in `docker-compose.yml`**: non-sensitive values that never vary between environments (internal service URLs, fixed usernames, database names)
- **lucos_creds (`.env`)**: sensitive values and anything that varies between dev and production

### Writing to lucos_creds

Agents have read and write access to the `development` environment in lucos_creds. For all other environments (e.g. `production`), **only lucas42 can write credentials**. Never ask any agent to store credentials in a non-development environment — route that step back to lucas42.

Writes go via SSH exec, not SCP/SFTP — SCP is read-only for all keys, so a permission-denied result on `scp` does not indicate the absence of exec write permission.

Avoid constructing compound values (e.g. `DATABASE_URL`) in docker-compose using variable interpolation — the CI build step only has access to a dummy `PORT` and will fail if other variables are referenced. Instead, construct them in application code at startup (e.g. SQLAlchemy's `URL.create()`).

---

## GitHub Workflow

For the `gh-as-agent` / `git-as-agent` wrappers, the heredoc + file-backed body patterns, the `{owner}/{repo}` template-substitution gotcha, and cross-repo issue references, see [`references/agent-github-identity.md`](references/agent-github-identity.md). For GitHub App limits, the GitHub Projects PAT, draft-PR-ready GraphQL, and bulk cross-repo operation safety, see [`references/github-workflow.md`](references/github-workflow.md). For the per-issue implementation walk (starting comments, branching, PR creation, closing keywords, supervised-repo reviewer requests), see [`agents/workflows/implement-issue.md`](agents/workflows/implement-issue.md).

**Cross-repo issue/PR references in GitHub comments and bodies must be fully-qualified plain text** — write `lucas42/<repo>#N`, never a bare `#N` (which always links to the *host* repo's #N, not the repo you meant) and never wrapped in backticks (a code span renders literally and does not autolink). Qualify **every** occurrence — autolinking is per-token, so qualifying once in a paragraph doesn't carry. A bare `#N` is only correct when that number genuinely lives in the host repo. To intentionally avoid a link, drop the `#` ("issue 14 in lucos_firewall"), not backticks. Detail: [`references/agent-github-identity.md`](references/agent-github-identity.md) §"Cross-repo issue references".

---

## Reference Files

Detailed conventions are documented in `~/.claude/references/`. Consult these when working on the relevant infrastructure:

| File | Contents |
|---|---|
| [`references/teammate-communication.md`](references/teammate-communication.md) | SendMessage rules, `teammate_id` handling, "user cannot see messages between teammates", take-the-first-action rule |
| [`references/agent-github-identity.md`](references/agent-github-identity.md) | `gh-as-agent` / `git-as-agent` wrappers, heredoc + file-backed body patterns, template-substitution gotcha, committing `~/.claude` changes |
| [`references/label-workflow.md`](references/label-workflow.md) | Labels are coordinator-only — every other persona posts a summary comment and stops |
| [`references/agent-memory-conventions.md`](references/agent-memory-conventions.md) | What/what-not to save, MEMORY.md size limit, four memory types, frame-review pattern |
| [`references/scope-of-work.md`](references/scope-of-work.md) | Dispatch contract: only work on assigned issues, raise drive-bys as new issues, triage notifications are informational |
| [`references/github-workflow.md`](references/github-workflow.md) | GitHub App limits, GitHub Projects PAT, marking draft PRs ready, bulk-rollout safety (extends `agent-github-identity.md`) |
| [`references/docker-conventions.md`](references/docker-conventions.md) | Container naming, volumes, env vars, networking, healthcheck gotchas |
| [`references/circleci-conventions.md`](references/circleci-conventions.md) | Standard CI config templates, CircleCI API access |
| [`references/info-endpoint-spec.md`](references/info-endpoint-spec.md) | `/_info` endpoint fields, tiers, and example |
| [`references/github-config.md`](references/github-config.md) | CodeQL, Dependabot, auto-merge workflow, PEM key formatting |
| [`references/ssh-production.md`](references/ssh-production.md) | SSH conventions, host list, safety warnings, read-only commands |
| [`references/monitoring-loganne.md`](references/monitoring-loganne.md) | Monitoring API schema, Loganne read/write, planned maintenance events |
| [`references/network-topology.md`](references/network-topology.md) | Production host layout, routing, inter-service comms, **no internal trusted network** |
| [`references/triage-procedure.md`](references/triage-procedure.md) | Full coordinator triage procedure: steps 1–3, central label controller |
| [`references/specialist-routing.md`](references/specialist-routing.md) | When triage should consult architect / SRE / security / UX before approving |
| [`references/implementation-assignment.md`](references/implementation-assignment.md) | Choosing the `owner:*` label, including the UX-vs-developer rule |
| [`references/priority-labels.md`](references/priority-labels.md) | `priority:*` assignment, re-assessment, override rules |
| [`references/label-colours.md`](references/label-colours.md) | Colour scheme for creating new agent-workflow / status / owner / priority labels |
| [`references/audit-finding-handling.md`](references/audit-finding-handling.md) | Audit-finding issue lifecycle: when to close, re-raise rule, false-positive handling |
| [`references/lucos-repos-api.md`](references/lucos-repos-api.md) | `lucos_repos` API: `/api/sweep` (full audit) and `/api/rerun` (ad-hoc convention recheck) |
| [`references/issue-creation.md`](references/issue-creation.md) | How to create a new GitHub issue: duplicate check, writing, `gh-as-agent` command, project board |
| [`references/raising-follow-up-issues.md`](references/raising-follow-up-issues.md) | Choosing between `/dispatch` and `/estate-rollout` when raising follow-up issues from design or implementation work |
| [`references/incident-reporting.md`](references/incident-reporting.md) | SRE incident-report process: drafting, parallel verification, PR shape, team notification |
| [`references/architectural-review.md`](references/architectural-review.md) | Architect persona's repo-review template, file naming, and CLAUDE.md critique guidance |
| [`python-testing.md`](python-testing.md) | FastAPI + SQLAlchemy testing patterns and gotchas |

### Workflow files

Step-by-step procedures loaded by personas at the start of a trigger live under `agents/workflows/`. They are referenced from each persona's Triggers section:

| File | Trigger | Used by |
|---|---|---|
| [`agents/workflows/implement-issue.md`](agents/workflows/implement-issue.md) | `"implement issue {url}"` | architect, developer, security, site-reliability, system-administrator, ux |
| [`agents/workflows/inline-triage-consultation.md`](agents/workflows/inline-triage-consultation.md) | inline coordinator consultation during triage | architect, developer, security, site-reliability, system-administrator, ux |
| [`agents/workflows/review-pr.md`](agents/workflows/review-pr.md) | `"review PR {url}"`, `"review any open PRs"` | code-reviewer |
| [`agents/workflows/production-change-verification.md`](agents/workflows/production-change-verification.md) | any production system change | site-reliability (plus any persona that touches production) |

For the full three-layer model — what belongs in personas vs. workflows vs. references, and how to add new content — see [`docs/agent-structure.md`](docs/agent-structure.md).
