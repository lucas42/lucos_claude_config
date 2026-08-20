---
name: convention-catalogue
description: lucos_repos generated convention catalogue + the enforced-vs-guidance boundary (ADR-0007, MERGED)
metadata:
  type: reference
---

**lucos_repos ADR-0007 — MERGED/Accepted 2026-06-22** (PR #437, closed lucos_repos#436). Establishes the single source of truth for enforced conventions and the governing boundary.

**The catalogue:** `lucos_repos/docs/conventions.md` is **generated** from the `Convention` registry by `conventions.RenderCatalogue()`, emitted via the `conventions` subcommand (`go run ./src conventions > docs/conventions.md`). `TestConventionCatalogueIsCurrent` (golden-file, in the existing `go test ./...` job — zero new CI) fails the build if it drifts; `TestAllConventionsHaveRequiredFields` guards Description/Rationale/Guidance. Mirrors the ADR-0006 C4 generate-from-source pattern but simpler (in-process data, no fetches).

**The governing boundary (the load-bearing rule):** documentation must NOT paraphrase an enforced convention — for any rule defined in `conventions/*.go`, docs **link the catalogue**; only genuinely un-enforceable guidance (templates, runbooks, gotchas, incident history) is hand-written, in demarcated sections. Drift was the failure class behind the bogus `_app` rename (lucos_repos#154) and the dropped build serial-group (lucos_repos#177). The docs are a *superset* of enforced rules, so drift only happens at the overlap; removing the hand-written copy of an enforced rule removes the drift surface.

**Residual risk (honest):** the golden-file test can't police prose, so a future editor could still paraphrase a rule inside a "guidance" section — the ADR + demarcation are the only guard there.

**What the Docker/CI checks actually cover** (the recurring trap — verified in-source 2026-08-20, and the source of two incidents): `container-naming` audits the *pattern* of a `container_name` **only where one is set** — its Check returns early on an empty value — and it never inspects `image:`. It passes a bare `lucos_<project>` as readily as `lucos_<project>_<role>`, so "the `_<role>` suffix is mandatory" is an over-reading (that's lucos_repos#154's bogus `_app` rename). There is **no** volume-related convention at all: `git grep -i volume` over `conventions/*.go` returns nothing (validated against a known-positive `healthcheck` grep). Explicit volume declaration, `volumes.yaml` registration, image naming, `container_name` presence, `env_file` avoidance and the healthcheck `127.0.0.1` rule are all **guidance**, not enforced.

**A `Description` can overstate its own `Check` — don't read the headline as the rule** (raised 2026-08-20 as lucos_repos#493). `container-naming`'s Description claims `lucos_{project}_{role}`; its Check requires only repo-name-or-repo-name-underscore-prefix. Milder unstated-exclusion cases in `docker-healthcheck-on-built-services` (skips test-profile services) and `env-var-passthrough`; the other 25 are unswept. Post-ADR-0007 this matters more, because other docs now *link* the headline instead of restating rules. Mechanics: Descriptions are safe to change (audit issues match on the `[Convention] <id>:` prefix, deliberately — `src/github_issues.go`), but the catalogue must be regenerated in the same commit. Only `ID` is immutable.

**Downstream:** lucos_claude_config#120 refactors `~/.claude/references/circleci-conventions.md` + `docker-conventions.md` to link the catalogue instead of paraphrasing **DONE** — PR lucas42/lucos_claude_config#139 merged 2026-08-20. Persona files still carry the same paraphrase: lucas42/lucos_claude_config#140 (coordinator-owned).
