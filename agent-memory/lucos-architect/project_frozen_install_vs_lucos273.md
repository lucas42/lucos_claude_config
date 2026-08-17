---
name: frozen-install-vs-lucos273
description: Why the frozen-install convention stays separate from lucas42/lucos#273 and sequences before it; current decision state as of 2026-08-18
metadata:
  type: project
---

# Frozen install vs lucas42/lucos#273 — separate, and sequence frozen install first

Recommended to team-lead 2026-08-18 in the `lucas42/lucos_backups#392` consultation. Not yet decided by lucas42.

**Why:** these look adjacent but solve different problems, and merging them would hide a risk neither one covers alone.

- **lucas42/lucos#273 is a *detection* thesis** — "CI validates an artifact we don't ship, and `/_info` probes other people's services rather than our own." Its defences are runtime assertions.
- **Frozen install is a *visibility/gating* problem** — the estate cannot see what it ships.

The decisive argument: **the dominant risk here is invisible to every defence lucas42/lucos#273 proposes.** A backdoored dependency's whole purpose is to *not* break anything — boot the image, assert `/_info`, run the suite in the shipped image, and all of it goes green while the code runs on the host holding SSH creds for avalon, xwing, salvare, aurora. Symmetrically, lucas42/lucos#273's own incidents were *visible* changes (a Dependabot PR editing `FROM`, reviewed and merged), which frozen installs do nothing about. Neither is a subset of the other.

**The one genuine coupling, and its direction matters:** lucas42/lucos#273's acceptance criteria gate each rollout stage on *re-introducing a known-bad bump and observing it stopped*. Frozen install is a **precondition for that verification being sound**, not a component of its programme.

⚠️ **State this carefully — my first version was falsified.** I claimed the criteria "cannot be verified" on a re-resolving repo. Wrong: `lucas42/lucos_backups#394` (merged) did exactly that on lucos_backups in its re-resolving state. A **static** pre-release check reads the Dockerfile and never resolves a dependency, so re-resolution is irrelevant to it; and the detective half worked too. The correct claim, from lucos-site-reliability:

> not **deterministically** verifiable, and not verifiable **at all** once upstream moves on — until frozen install lands.

The reproduction works only while PyPI still serves a `charset_normalizer` whose cp315 wheel breaks on alpha 2; when a compatible wheel ships it passes and the test silently stops testing anything. Frozen install makes it durable (pin `charset-normalizer==3.5.1`). This is the *stronger* argument — a silently-decaying acceptance criterion has no discovery path, whereas an impossible one is caught by the first person who tries it. Corrections: `lucas42/lucos#273` comment 5321590647, `lucas42/lucos_repos#488` comment 5321592908.

**How to apply:** progress frozen install separately and first — it's cheap, mechanical, has no open decision, and can move while lucas42/lucos#273 waits on lucas42. **Do not let a completed frozen-install rollout read as progress against lucas42/lucos#273** — it does not reduce its urgency (Priority Critical, Awaiting Decision). Rollout must tier by remediation cost, not by package manager (tier 3 — repos with no lockfile — cannot take `npm ci` at all).

**Live ticket: `lucas42/lucos_repos#488`** (filed by lucos-site-reliability; my scope-correcting fold-in is comment 5321557255). Do NOT open a second estate ticket. `lucas42/lucos_backups#392` is the per-repo fix and stays Ready.

**Open decisions belonging to lucas42** (written as options A1–A3 / B1–B2 on #488): (1) tier 3's initial lockfile freezes whatever is current, unreviewed — unavoidable, but do it deliberately with a human reading the dependency list; (2) whether lucos_backups goes further to `pip install -r requirements.txt --require-hashes`, dropping pipenv from the image entirely — strongest control on the highest-value target.

Mechanism and estate sweep: [[frozen-install-build-integrity]].
