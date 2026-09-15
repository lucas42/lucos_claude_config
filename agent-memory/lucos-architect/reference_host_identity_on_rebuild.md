---
name: host-identity-on-rebuild
description: When a lucos host is rebuilt (disk swap / reinstall), reuse the hostname and old SSH host keys; which clients pin avalon's key and which don't; lucos_creds's SSH key is separate
metadata:
  type: reference
---

Advised on lucas42/lucos#296 (2026-09-15), the avalon rebuild after the lucas42/lucos#294 disk failure. Status on that ticket: lucas42's decision is pending. Re-fetch it before citing any outcome.

**Hostname.** Estate hostnames name *physical machines*: `virgon-express` is kept in configy as "physically disconnected", and `aurora` is a LAN box. A disk replaced in the same chassis leaves the machine the same, so the name stays. A different physical server is the flip condition. Even then, keep the name through an outage and rename later as a planned migration. A new name is not free:
- it touches every CI config for a system on that host (34 systems were on avalon)
- the orb's `deploy-<host>` job
- `lucos_router/scripts/fetch-domainsets.sh`, which special-cases `avalon`
- hand-maintained CNAMEs
- the backup archive, which is keyed `host/<name>/`

The one "benefit" of a new name, dodging the changed-host-key warning, is illusory: `accept-new` trusts an unseen name silently. That swaps a visible discontinuity for an invisible one.

**Who notices a host-key change** (checked in code):
- CircleCI deploys: no. The orb keyscans on every run (`lucos_deploy_orb/src/commands/deploy.yml`).
- `lucos-backups`: yes. It uses `StrictHostKeyChecking=accept-new`, and the `lucos_backups` README has the fix recipe.
- Humans and `lucos-agent`: yes.
- **`creds.l42.eu:2202` has its own SSH key**, in the `lucos_creds_store` volume (`/var/lib/creds_store/server_key`). It comes back with the volume restore, whatever is decided about the OS host keys.

**Host-key reuse** should follow one judgement about the old disk *as a whole*, never a standalone "fresh keys are safer" instinct. Check what else from that disk is already being restored before recommending that only the OS keys be rotated.

**My error on this ticket:** I inferred the full key set on the host from `known_hosts`. That only shows keys clients negotiated; the disk also held a DSA key. To know what's *on* a host, read the host, not a client's cache (see [[feedback-grep-and-conclude-anti-pattern]]).

Related: [[no-onhost-source-of-truth]] (recovery = CI redeploy per ADR-0008).
