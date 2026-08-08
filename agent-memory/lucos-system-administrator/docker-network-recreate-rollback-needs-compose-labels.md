---
name: docker-network-recreate-rollback-needs-compose-labels
description: A plain `docker network create --subnet X <name>` rollback after deleting a compose-managed network fails — compose refuses to reuse it without the right labels
metadata:
  type: reference
---

Same root class of bug as [[docker-volume-restore-label-preservation]] (bare `docker run`
into a fresh volume drops the compose labels `lucos_backups` relies on) — now confirmed for
networks too, via a rehearsal on a throwaway project on avalon (2026-08-09, lucas42/lucos#278
network-recreation work, prompted by `lucos-architect`'s ask to test the rollback path before
trusting it under pressure).

**The failure**: if a compose-managed network is deleted and you restore it with a bare
`docker network create --subnet <recorded> <name>` (the natural-looking rollback recipe —
this is what `lucos-site-reliability` had proposed and I'd agreed to), the next
`docker compose up` refuses it outright:

```
a network with name <name> exists but was not created by compose.
Set `external: true` to use an existing network
network <name> was found but has incorrect label com.docker.compose.network set to ""
(expected: "default")
```

Exit code 1 — the service stays down, and now you're debugging an unfamiliar compose error
in the middle of recovering from an outage, which is a worse place to be than where you
started.

**The fix**: recreate with the compose labels the project expects:

```
docker network create --ipv6 --subnet <recorded-subnet> --driver bridge \
  --label com.docker.compose.network=default \
  --label com.docker.compose.project=<compose-project-name> \
  --label com.docker.compose.version=<any-value> \
  <network-name>
```

Confirmed via rehearsal that with these labels present, `docker compose up -d` accepts the
manually-recreated network and attaches the container cleanly — **the network ID changing is
not a problem** (compose resolves by name, not ID, matching the expectation architect flagged
as unverified). The value of `com.docker.compose.version` did not seem to matter for
acceptance in the rehearsal (tested with a value that didn't match the host's actual compose
version and it still worked) — only `network` and `project` were load-bearing in this test;
don't over-generalise that to "version never matters" without checking a newer compose
release.

**Where this matters**: any future network-recreation runbook (this came up for lucas42/lucos#278/#279)
must write the rollback recipe with labels, not a bare `docker network create`. The bare
version looks correct, is what most people would type from muscle memory
(`docker network create --subnet X name` mirrors the "just fix the IP config" mental model),
and only fails when you actually need it — exactly the "untested safety step" failure mode
architect was warning about. Rehearsing it once on a disposable project, in parallel with
whatever real deploy you're also waiting on, is cheap and turns a hypothesis into a fact.

Practical note: get the exact `com.docker.compose.project` value from the target network's
own labels before deleting it (`docker network inspect <net> --format '{{json .Labels}}'`) —
it's usually the compose project name (often the repo name minus `lucos_` prefix quirks, but
don't assume, just read it), not something to guess.

## Companion lesson: post-change verification must probe the self-referential path, not just generic egress

Found by `lucos-site-reliability` immediately after this same #278 work (2026-08-09): both my
dual-stack post-recreate probes (xwing dns_secondary, avalon monitoring) hit `cloudflare.com`
as the IPv6/IPv4 control — generic external egress, confirmed working both times. What that
missed: `lucos_monitoring` fetching **its own** hostname (`monitoring.l42.eu`) now hairpins
container → NAT66 → avalon's global IPv6 → router → back into the same container, and that
path is *slow-but-successful* (2-6s observed) rather than failing outright. The consumer
(`fetcher_info.erl`, `{ipfamily, inet6fb4}`) only falls back to IPv4 on IPv6 **failure**, not
on IPv6 **slowness**, so a working-but-slow hairpin blows its 1s budget every time — invisible
to any check that doesn't specifically fetch the self-hostname.

Generalise: after any network-level change to a service, the verification probe should include
the service fetching **itself** by its public hostname (not just an arbitrary external target)
whenever the service's own code does that (self-health-checks, self-referential `/_info`
calls, etc.) — a hairpin is a distinct failure mode from general egress and a generic dual-stack
probe will not catch it.
