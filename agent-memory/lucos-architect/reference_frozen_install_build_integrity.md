---
name: frozen-install-build-integrity
description: Docker builds across the estate re-resolve dependencies at build time; the pipenv mechanism, reproduced, plus the full estate sweep of unfrozen installs by package manager
metadata:
  type: reference
---

# Unfrozen dependency installs in estate Dockerfiles

Established 2026-08-17/18 by container rehearsal against `origin/main`, for `lucas42/lucos_backups#392`. Full write-up: `lucas42/lucos_backups#392` comment 5321500401.

## The pipenv mechanism (reproduced, all links verified)

1. `RUN pip install pipenv` is **unpinned** — the build gets whatever pipenv is current that day.
2. The committed `Pipfile.lock`'s `_meta.hash` does not match what that pipenv computes from the committed `Pipfile`.
3. `pipenv install` (no `--deploy`) reads a hash mismatch as "lock is stale" and **silently re-locks**, resolving the whole graph fresh from PyPI at build time. **Exit code 0, no warning.**
4. A later `COPY src /usr/src/app` (after the install) restores the committed lock over the re-locked one — so the shipped image carries a lockfile describing *neither* what pipenv resolved *nor* what is installed. That's why the image looks self-contradictory.
5. `--deploy` turns step 3 into `ERROR:: Aborting deploy`.

**`--deploy` is NOT a drop-in.** It failed immediately on lucos_backups' committed lock. Any repo adopting it must regenerate the lock in the same PR — and the regenerated lock pulls newer versions, so the diff needs a human read.

**The hash skew is long-standing, not from one commit.** pipenv 2026.7.1 computed a different hash from the committed one for the *previous* Pipfile too. Neither lock ever matched. Cause of the skew unconfirmed (likely Dependabot's own pipenv version); the effect is reproduced.

## Why this is a convention and not a sweep

The defect is **latent and state-dependent**: repos are correct only by coincidence of which pipenv version the build installs, and flip silently with no signal. Correct-by-coincidence + silently reversible + invisible until it bites = audit-convention profile.

The estate **already holds this principle**: `lucos_repos`' `reusable-workflow-pinned` rationale ("a mutable ref means any upstream commit is picked up by all consumers") is verbatim this argument one layer down, with a worse blast radius (upstream is public and unowned). `lucos_repos` also already has Dockerfile-content conventions (`dockerfile-copy-from-blind`, `dockerfile-version-arg`) — machinery proven, not speculative.

**State the convention as the property, not the flag:** *"Dependency installation in a Dockerfile must install exactly what is committed, and fail loudly when it cannot."* Stated that way, Go/`composer install`/`lucos_schedule_tracker` **pass** rather than needing exceptions — which is the test that the abstraction is right.

## Estate sweep (2026-08-18; all 66 Dockerfiles in the 48 estate repos that have one)

- **pipenv without `--deploy` — 8 repos.** Mismatched *today*: lucos_backups, lucos_contacts, lucos_eolas. In sync today (drop-in): lucos_arachne/ingestor, lucos_contacts_googlesync_import, lucos_creds/configy_sync, lucos_media_import, lucos_media_weightings.
- **`npm install` with a lockfile — 9 repos.** Same failure mode: honours the lock only while `package.json` agrees, then re-resolves and rewrites it.
- **`npm install` with NO lockfile — 3 repos:** lucos_time, lucos_media_metadata_manager, lucos_locations/otfrontend. **`npm ci` errors out here** — a blind install→ci rollout breaks these builds.
- **Unpinned `requirements.txt`** — lucos_photos api (15/15), worker (6/10), lucos_comhra/agent (3/4).
- **Not closed by any of this:** unpinned `apk add`/`apt-get install` (23 repos — Alpine drops old versions, impractical) and `FROM <tag>` rather than digest (all 66).

## lucos_repos machinery — two things already handled (don't rebuild them)

Checked 2026-08-18 while correcting the scope of `lucas42/lucos_repos#488`. Both were reported to me as gaps a new check would need to close; **both already exist**, and asserting them as gaps would have caused duplicated work:

- **Archived repos are already skipped unconditionally** — `src/audit.go:250`. So a bad table listing archived repos is a *scope/impact* error in the ticket, not a defect the check inherits. No new exclusion logic needed.
- **Subdirectory Dockerfiles are already discovered** — `conventions/dockerfile-version-arg.go`'s `dockerfilePathForBuild` resolves a service's Dockerfile from its compose `build:` stanza (string and mapping forms; `context: foo` → `foo/Dockerfile`). `dockerfile-copy-from-blind.go` uses the same discovery. Reuse it.
- **The real limitation is narrower:** discovery is via `docker-compose.yml`, so **a Dockerfile no compose service references is invisible**. Verified all 8 pipenv repos' affected Dockerfiles *are* reachable from a `build:` stanza, so it's fine today — but state it as a limitation of any new Dockerfile convention.

## The wider family: build integrity

Frozen install is one instance of a larger property — **the shipped artefact is fully determined by what is committed**. Siblings found so far, each a distinct *property* even though they share a mechanism (a static Dockerfile check):

- **Which dependencies ship** — frozen install (this file).
- **Which *stage* ships** — `lucos_backups` `buildx bake` uses a bare `build: .` with no `target:`, so the Dockerfile's *last* stage is what ships. Appending a test stage at the end would ship pytest to production. The guarantee is currently **a comment saying "keep production last"**, not anything that fails when it stops holding. code-reviewer proposed a CI grep asserting the final `FROM ... AS production`; routed to team-lead 2026-08-18.

**Don't fold the sibling into frozen install.** Shared mechanism ≠ decision coupling (see [[new-consideration-gets-own-adr]]). Same family, own convention. The family name is the useful thing: it tells you where the next check belongs.

## Verifying a deployed lucos_backups image (from lucos-site-reliability, 2026-08-18)

Re-verify **at the moment of citing**, not in advance — a point-in-time infra fact goes stale between verification and citation.

```
ssh avalon.s.l42.eu "docker inspect -f 'image={{.Config.Image}} health={{.State.Health.Status}} restarts={{.RestartCount}}' lucos_backups"
ssh avalon.s.l42.eu "docker run --rm --entrypoint sh lucas42/lucos_backups:<ver> -c 'ls /root/.local/share/virtualenvs/*/lib/*/site-packages/ | grep -c \"^pytest\"'"
```

Zero pytest packages proves `buildx bake` resolved the `production` target **on the published artefact**, not merely in the branch.

## Method notes

- **GitHub code search missed 3 repos** (lucos_media_import for pipenv; lucos_authentication and `frontend` for npm). Sweep off clones — as `lucos_repos` already does. See [[github-codesearch-lossy-for-sweeps]].
- Deploy model verified: the orb runs `docker compose pull` then `up -d --no-build`, so **prod runs the CI-built tagged image** — CI's artifact IS the shipped artifact.

Related: [[base-image-bump-incident-class]], [[frozen-install-vs-lucos273]].
