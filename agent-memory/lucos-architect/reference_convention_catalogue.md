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

**Downstream:** lucos_claude_config#120 refactors `~/.claude/references/circleci-conventions.md` + `docker-conventions.md` to link the catalogue instead of paraphrasing (unblocked once #437 merged; I own it).
