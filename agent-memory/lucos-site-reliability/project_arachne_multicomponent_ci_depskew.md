---
name: arachne-multicomponent-ci-depskew
description: lucos_arachne CI co-installs mcp/+ingestor/ requirements in one pip resolve → shared-dep (pytest) version skew deadlocks main CI; dependabot.yml tracking regression from #633
metadata:
  type: project
---

lucos_arachne is a multi-component repo (mcp/, ingestor/, triplestore/, search/, web/, explore/). The CircleCI `test` job installs mcp + ingestor into ONE Python environment in a single `pip install -r mcp/requirements.txt -r mcp/requirements-test.txt -r ingestor/requirements-test.txt` resolve, then runs `cd mcp && pytest` / `cd ingestor && pytest` separately.

**Failure mode:** Dependabot bumps one directory at a time, so a shared dep (e.g. pytest) pinned differently across mcp/ and ingestor/ → `ResolutionImpossible` → main CI red → because `deploy-avalon requires: [test]`, ALL arachne deploys are gated until a human hand-syncs both files. Hit 2026-06-17 (#635 ingestor + #650 mcp pinned pytest 9.0.3 vs 9.1.0; manual fix #651).

**Decision (lucos_arachne#652, 2026-06-17):** Option 3 — decouple CI install into per-component venvs (skew then structurally can't deadlock; mirrors prod where mcp/ingestor are separate containers). Rejected: cross-dir Dependabot grouping (manages not removes coupling) and shared constraints (`-c` handling unreliable → risks silently stopping bumps).

**Why:** the co-resolution is a CI artifact, not a real dependency — the components share no runtime.

**How to apply:** if arachne CI deadlocks on a Dependabot dep bump again before #652 ships, it's this; the workaround is a manual coordinated PR bumping both files. After #652 ships, each component resolves independently.

**Adjacent dependabot.yml regression (verified from diff):** PR #633 (2026-06-15, "Remove dead Python prerelease Dependabot ignore globs") silently deleted the entire `pip /mcp` + `docker /mcp` blocks. docker survived via a duplicate `/./mcp` entry (added by #626); `pip /mcp` had no `/./` counterpart → mcp's Python deps (incl runtime requirements.txt) UNTRACKED by Dependabot since 2026-06-15. Config also carries redundant duplicate docker entries (`/x` + `/./x`). LESSON: a "cleanup" PR can euthanise a whole tracker — squint at what a dependabot.yml diff actually deletes. #652's PR restores pip/mcp + dedupes. Related: [[feedback_dependabot_recreate_deterministic]].
