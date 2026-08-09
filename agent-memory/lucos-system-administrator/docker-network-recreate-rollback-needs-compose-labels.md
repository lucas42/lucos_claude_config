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

## Companion lesson: probe the self-hostname AND wait out the settling window — both halves are real

`lucos-site-reliability` initially reported (2026-08-09, ~23:5x) that `lucos_monitoring`
couldn't poll itself post-recreate — a hairpin through NAT66 blowing the fetcher's 1s budget —
then **partially retracted**: the self-poll recovered on its own ~4 minutes after the
container restarted (2144/5699/3431ms measured during the scare → 26-95ms fifteen minutes
later, forced-IPv6, same command). Most likely ordinary post-network-creation settling (NDP,
NAT66 conntrack, the router learning the new subnet), not a code defect.

**Both halves of the original lesson are still true — only the sequencing was wrong.** SRE's
own follow-up correction: deleting the self-hostname point (my first pass at editing this
note) would have thrown out the real gap it identified — both my dual-stack probes that night
went to `cloudflare.com`, generic external egress, and a hairpin or self-resolution problem is
genuinely invisible to that. What was wrong was running that probe *immediately* after the
recreate, inside the settling window, where it reproduces scary-looking transient numbers that
have nothing to do with whether the change actually worked.

**The composed, correct lesson**: after any Docker network recreate —
1. Verify **immediately** what is immediately true and non-timing-sensitive: container
   healthy, network's live config matches its declaration. Both were correct within seconds
   here.
2. **Wait out a settling window** (a few minutes) before trusting any *behavioural* probe —
   latency, dual-stack fetch, self-referential health check.
3. Once past that window, **do** probe the service's own self-hostname specifically, not just
   generic external egress — a hairpin/self-resolution failure is a distinct failure mode a
   generic dual-stack probe cannot see.
4. If a behavioural probe looks wrong right after a recreate, measure twice with a gap before
   believing it (and especially before rolling back a change that's actually fine) — running
   the self-hostname probe in the first minute here would have reproduced the alarming numbers
   and made a working change look broken.

Now captured as an instruction in `production-change-verification.md`, not just a memory note.
