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
