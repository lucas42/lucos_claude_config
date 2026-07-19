---
name: risk-lucos-agent-docker-group-root-equivalent
description: lucos-agent's only supplementary group on avalon/xwing/salvare is `docker` — root-equivalent access already, dwarfs any log-read privilege question
metadata:
  type: project
---

**`lucos-agent`'s SSH user is already root-equivalent on all three production hosts** (avalon, xwing, salvare) via `docker` group membership — verified live 2026-07-18:

```
avalon:  groups=994(docker),100(users)
xwing:   groups=985(docker),100(users)
salvare: groups=992(docker),100(users)
```

`/var/run/docker.sock` is `root:docker`, `srw-rw----` on all three. One `docker run --rm -v /:/host -it alpine chroot /host sh` = full root shell on the bare host: every co-located service's secrets/volumes, not just the one that triggered a compromise (these hosts are multi-tenant).

**Why:** This is legitimate and deliberate — `references/ssh-production.md` tells agents to use `docker ps`/`docker logs`/`docker exec`/`docker compose ps` for production troubleshooting, which requires docker-group access. But as far as I could find (searched org-wide), this tradeoff was never treated as a conscious privilege decision the way lucos_agent_coding_sandbox#21 treated the much smaller apt-sudo grant. Raised as lucas42/lucos_agent_coding_sandbox#102 (2026-07-18, open, awaiting triage) with options: (1) document/accept as the standing risk model, (2) narrow via a docker-socket-proxy allowing only read endpoints, (3) do nothing beyond writing it down.

**How to apply:** This is now the dominant fact for evaluating *any* further privilege-expansion question for `lucos-agent` on production hosts (e.g. lucos_agent_coding_sandbox#99's adm/systemd-journal log-access question — my assessment there: none of adm/systemd-journal/narrow-sudoers grant genuine new *capability* beyond what docker already provides; the real question is standing-grant convenience/blast-radius, not raw ceiling). Don't evaluate a new grant to `lucos-agent` on avalon/xwing/salvare as if it were a low-privilege user — it isn't, unless/until #102 lands a fix. Check #102's resolution before assuming this is still the live state.

See also [[risk-unattended-upgrades-origin-scope]] — same three hosts, another standing config-drift pattern worth cross-checking when reviewing lucos-agent's production footprint.

**Analysis update (2026-07-19):** lucas42 rejected Options 1/3 (accept-and-document, do-nothing) and asked whether narrowing is achievable via native Linux/Docker permissions alone, no proxy. Researched and confirmed: **no.** Unix socket perms are connect-only (no verb/path awareness); Docker's own docs state the out-of-the-box authorization model is "all or nothing." The only Docker-native finer-grained mechanism (authorization plugins) requires a separate daemon-restart-registered plugin process — same shape as a proxy, doesn't clear his "no helper daemon" bar. Rootless Docker is orthogonal (daemon's own privilege, not client-side verb granularity) and would be a major re-platforming of already-rootful multi-tenant hosts — out of scope. Verified live: all three hosts run standard rootful dockerd (avalon 29.3.0/Debian12/apparmor+seccomp, xwing 29.4.0/seccomp only, salvare 29.3.0/seccomp only — no SELinux anywhere). Posted full analysis + command-survival table as a comment on lucas42/lucos_agent_coding_sandbox#102 (2026-07-19): converts cleanly to Option 2, concretely a `docker-socket-proxy`-style container (Tecnativa's has a granular `EXEC` flag distinct from `POST`) — `docker ps`/`logs`/`compose ps` survive cleanly as GET-only allowlist, `docker exec` is the one open value-call (allow = keeps documented incident flow but retains lateral-movement-via-exec risk scaled to other containers' own mounts/caps; deny = fully closes root-equivalence but breaks the documented mid-incident shell step). Left as an explicit open question for lucas42, not defaulted. If Option 2 proceeds, deployment specifics need `lucos-system-administrator`.

**How to apply:** Any future "can we narrow docker-group access natively" question estate-wide has the same answer — don't re-research, cite this. The live open question is exec-allow-vs-deny in the eventual proxy policy, not whether a native path exists.
