# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) for all projects in this environment.

## Commit Messages

Do not add `Co-Authored-By` trailers to git commits. The bot identity on each commit already makes authorship clear.

**Always use `git-as-agent`** (not raw `git`) for all git operations — commits, rebases, cherry-picks, etc. This ensures commits are attributed to the correct bot identity. See [`references/github-workflow.md`](references/github-workflow.md) for details.

## Learning from Mistakes

When you fail to follow an instruction, do not apologise. Instead, suggest a concrete improvement to the instructions or environment that would prevent the same mistake from happening again. There is nothing wrong with making mistakes — but we should always learn from them.

When a routine operation hits a **hard error due to a structural constraint** (e.g. a tool limitation, API restriction) that will recur in future runs, fix the relevant instructions immediately — don't just work around it and move on. The first occurrence is the right time to fix it, not the third.

**Trigger — hard tool errors:** Whenever a tool call returns a hard error (`Blocked:`, `InputValidationError`, permission denied, invalid input, etc.), **stop before retrying or working around it** and ask: *was this call prescribed by an instruction file (skill, persona, routine doc)?* If yes, the instruction is what needs fixing — update it first, then retry. A local workaround without an instruction fix guarantees the next session hits the same wall. Helpful error messages that suggest a workaround (e.g. "use run_in_background: true") are especially dangerous — they make it easy to patch the symptom and forget the cause.

When a mistake occurs in a routine task (ops checks, triage, issue review, etc.), prefer updating the relevant instruction files — persona files, skill files, triage procedures — rather than only updating agent memory. Memory is session context that may not persist reliably across conversations; instructions are what agents actually follow every run. If a mistake reveals a gap in a persona's standing instructions, fix the instructions.

**Writing a feedback memory is not a complete fix.** After saving a memory about a mistake, always ask: "does this also need an instruction update in a skill file, persona file, or other standing instruction?" If yes, make that update (or delegate it to the appropriate teammate) before considering the fix complete. A feedback memory records what went wrong; an instruction update prevents it from happening again. Do both. **Do not consider a mistake resolved until the instruction update has been made** — if you catch yourself saving a memory and moving on, stop and find the instruction to update.

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
- Contacts API: `LUCOS_CONTACTS_URL`

### What goes where

- **Hardcode in `docker-compose.yml`**: non-sensitive values that never vary between environments (internal service URLs, fixed usernames, database names)
- **lucos_creds (`.env`)**: sensitive values and anything that varies between dev and production

### Writing to lucos_creds

Agents have read and write access to the `development` environment in lucos_creds. For all other environments (e.g. `production`), **only lucas42 can write credentials**. Never ask any agent to store credentials in a non-development environment — route that step back to lucas42.

Avoid constructing compound values (e.g. `DATABASE_URL`) in docker-compose using variable interpolation — the CI build step only has access to a dummy `PORT` and will fail if other variables are referenced. Instead, construct them in application code at startup (e.g. SQLAlchemy's `URL.create()`).

---

## GitHub Workflow

For GitHub API calls (`gh-as-agent`, `git-as-agent`, GitHub App limitations, marking draft PRs ready), cross-repository issue references, the full issue workflow (starting comments, branching, PR creation, closing keywords), post-PR review loop, and bulk cross-repo operation guidelines, see [`references/github-workflow.md`](references/github-workflow.md).

---

## Reference Files

Detailed conventions are documented in `~/.claude/references/`. Consult these when working on the relevant infrastructure:

| File | Contents |
|---|---|
| [`references/github-workflow.md`](references/github-workflow.md) | `gh-as-agent`, `git-as-agent`, GitHub App limits, issue workflow, PR creation, bulk rollouts |
| [`references/docker-conventions.md`](references/docker-conventions.md) | Container naming, volumes, env vars, networking, healthcheck gotchas |
| [`references/circleci-conventions.md`](references/circleci-conventions.md) | Standard CI config templates, CircleCI API access |
| [`references/info-endpoint-spec.md`](references/info-endpoint-spec.md) | `/_info` endpoint fields, tiers, and example |
| [`references/github-config.md`](references/github-config.md) | CodeQL, Dependabot, auto-merge workflow, PEM key formatting |
| [`references/ssh-production.md`](references/ssh-production.md) | SSH conventions, host list, safety warnings, read-only commands |
| [`references/monitoring-loganne.md`](references/monitoring-loganne.md) | Monitoring API schema, Loganne read/write, planned maintenance events |
| [`references/network-topology.md`](references/network-topology.md) | Production host layout, routing, inter-service comms, **no internal trusted network** |
| [`references/triage-procedure.md`](references/triage-procedure.md) | Full coordinator triage procedure: steps 1–3, specialist routing, implementation assignment, priority labels |
| [`references/audit-finding-handling.md`](references/audit-finding-handling.md) | Audit-finding issue lifecycle: when to close, re-raise rule, false-positive handling |
| [`references/lucos-repos-api.md`](references/lucos-repos-api.md) | `lucos_repos` API: `/api/sweep` (full audit) and `/api/rerun` (ad-hoc convention recheck) |
| [`references/issue-creation.md`](references/issue-creation.md) | How to create a new GitHub issue: duplicate check, writing, `gh-as-agent` command, project board |
| [`python-testing.md`](python-testing.md) | FastAPI + SQLAlchemy testing patterns and gotchas |
