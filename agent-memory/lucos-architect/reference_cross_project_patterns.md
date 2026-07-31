---
name: cross-project-patterns
description: Estate-wide architectural patterns, naming/repo conventions, and the architectural-review convention (lucos#24) — the standing background for any lucos design or review
metadata:
  type: reference
---

## Architectural review convention (lucas42/lucos#24)

Reviews are committed Markdown in the reviewed repo's `docs/reviews/`, named `YYYY-MM-DD-review.md`. They are **separate from ADRs**, raised via PR, and do **not** get a summary issue. A "Sensitive findings" section is mandatory (state "None" if so). lucas42/lucos#25 tracks Security Advisory practice for findings that shouldn't be public.

Process detail lives in `~/.claude/references/architectural-review.md`.

## Cross-project patterns

- **Module-level side effects in shared packages** are a recurring source of fragility across the estate.
- **Auth origin** is env-varying `AITHNE_ORIGIN` (lucas42/lucos_aithne#148). `lucos_authentication` was decommissioned 2026-06-29.
- **Always specify sequencing dependencies** for cross-repo infra changes. lucas42 prefers multi-concern issues split apart.
- **`git fetch` before reviewing EACH repo.** The *fetch* is the load-bearing step, not the checkout. Read source from a fresh `origin/main` worktree or `git show origin/main:file` — never the shared `~/sandboxes` tree, which is routinely stale and dirty. A refuting grep on a stale tree is worse than no grep at all, because it manufactures false confidence. (Fix landed in implement-issue Step 4.)
- **One service per repo**; naming `lucos_{subsystem}_{qualifier}`.
- **User-Agent** for inter-system HTTP = the `SYSTEM` env value (`lucos` ADR-0001).
- **Bearer auth migration** (lucas42/lucos#74): key→Bearer in 3 phases — server dual-accept → client switch → drop key.
- **claude_config** ADR-0001 (instruction compliance: short task files, explicit counts, completion manifests, 200-line max) and ADR-0002 (agent-teams / SendMessage). The `lucos-issue-manager` role was merged into `team-lead` on 2026-04-02.
