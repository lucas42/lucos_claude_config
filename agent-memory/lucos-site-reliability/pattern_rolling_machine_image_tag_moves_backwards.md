---
name: pattern-rolling-machine-image-tag-moves-backwards
description: CircleCI exit 127 after a successful pip install = ubuntu-2204:current rolling tag moved BACKWARDS to an older image; diagnose via the Spin up environment log, fix with a venv not an image pin
metadata:
  type: project
---

**A CircleCI job that fails `exit 127` (command not found) on a binary whose install step just reported "Successfully installed" = the console script isn't resolving on PATH, and the usual cause is the machine image changing under you — including moving BACKWARDS.**

**2026-07-14, lukeblaney_co_uk#68.** `check-links` red 8h, blocking `deploy-avalon`. `python3 -m pip install linkchecker` → "Successfully installed linkchecker-10.6.0" → `linkchecker ...` → **exit 127**. Repo unchanged; the Dependabot merge (#67) that "triggered" it only touched GitHub Actions pins — a red herring.

**Diagnosis — read the `Spin up environment` step, not the failing step.** It prints the resolved image:

```
job 448 (2026-06-16, PASS): machine-agent ... (image: "ubuntu-2204:2026.05.1")   python 3.14 → cp314 wheels
job 461 (2026-07-14, FAIL): machine-agent ... (image: "ubuntu-2204:2025.09.1")   python 3.13 → cp313 wheels
```

`ubuntu-2204:current` is a **rolling tag and it rolled BACKWARDS** — eight months older. Don't assume rolling tags only move forward. A fast corroborating tell without reading image logs: the wheel ABI tags in the pip output (`cp314` vs `cp313`) reveal the interpreter changed.

**Cheap invalidation of "it's a flake": re-run from failed.** Job 466 reproduced exit 127 identically on the same image ⇒ deterministic. **A re-run can never clear this class** — which matters because the ops-checks CI rule says to re-run failures. Re-run once to test the hypothesis "the third party fixed it"; when it reproduces, stop re-running and fix the config.

**Fix = make the job not care about the image's PATH, don't pin the image.** Installing into an explicit venv and invoking by absolute path is guaranteed by Python packaging, not by image config:

```yaml
python3 -m venv /tmp/linkchecker-venv
/tmp/linkchecker-venv/bin/pip install --quiet linkchecker
/tmp/linkchecker-venv/bin/linkchecker --no-status --no-warnings http://localhost:8080/
```

Pinning forward to the last-known-good (`2026.05.1`) targets an image the rolling tag has already moved *away from* — plausibly withdrawn, and you'd discover that during a future deploy. Pinning to the current-actual just freezes you on the old image. The venv survives the tag moving in *either* direction.

**Verify on the BROKEN image.** Push the fix to a branch and confirm the green job's `Spin up environment` still shows the bad tag (`2025.09.1`). Otherwise you can't distinguish "my fix worked" from "the vendor quietly repaired the alias mid-investigation" — and you'd bank a false lesson.

**Estate exposure (checked 2026-07-14):** only 2 repos use `ubuntu-2204:current` — `lukeblaney_co_uk` (fixed) and `lucos_deploy_orb/.circleci/test-deploy.yml` (docker commands only, no pip/PATH-dependent installs ⇒ not exposed). Deliberately filed NO estate-wide "pin all rolling tags" issue: zero evidence of impact elsewhere, so it fails the impact-vs-effort bar.

See also [[pattern-baseimage-bump-runtime-break]] (same family: an image/dep bump that builds fine and breaks later), [[feedback-check-recent-fixes-before-filing]].
