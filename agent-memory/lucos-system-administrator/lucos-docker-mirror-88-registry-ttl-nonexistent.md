---
name: lucos-docker-mirror-88-registry-ttl-nonexistent
description: distribution/distribution registry:2 (2.8.3) has no proxy.ttl config field — recorded decision on lucos_docker_mirror#88 was a no-op, caught before implementing
metadata:
  type: project
---

`lucos_docker_mirror`#88's recorded decision (Option 2, `proxy.ttl: 0` in `config.yml`) was **not implementable as specified** — verified against source before implementing, per house rule.

**Fact, source-verified 2026-08-31:** `distribution/distribution` tag `v2.8.3` (what `registry.Dockerfile`'s `FROM registry:2` actually pins, confirmed by the container's own log line `version=2.8.3`) has a `Proxy` config struct (`configuration/configuration.go`) with only `RemoteURL`/`Username`/`Password` — **no `TTL` field**. The 168h eviction period is a hardcoded Go constant (`repositoryTTL` in `registry/proxy/proxymanifeststore.go`), not config-driven. Config parsing (`configuration/parser.go`) uses plain `yaml.Unmarshal`, not strict mode, so an unrecognized `proxy.ttl` key parses fine but is silently dropped — zero runtime effect, error keeps firing.

`TTL *time.Duration` (`yaml:"ttl,omitempty"`, "if set to zero, will never expire cache") **was added later**, confirmed present in `v3.1.1`. So the option's reasoning was correct for a different major version of the same codebase — just not the one actually deployed. A major-version image bump (`registry:2`→`registry:3`) is the only way `proxy.ttl` becomes real for this service, and that's materially bigger than the one-line tweak the ticket was scoped as.

**Why:** two specialists (security + coordinator) recorded a specific config key/value as the fix without checking it existed in the pinned image version — an assumption baked into an "agreed direction" is still an assumption. The acceptance criteria (no more `OnExpire` errors) would have silently failed to be met by a merged, closed PR.

**How to apply:** any config-key-based "fix" proposed in a ticket — especially one inherited from a prior triage/security pass — needs its existence verified against the *actual pinned version's config schema* before implementing, not just plausibility from general knowledge of the tool. Non-strict YAML unmarshalling (common in Go configs) makes wrong keys fail silently rather than loudly, so there's no runtime signal that would have caught this later either. See also [[feedback_read_before_theorising]].

Status as of 2026-08-31: posted verified findings as a comment on lucas42/lucos_docker_mirror#88, did not open a PR, flagged back to team-lead for re-decision. Real options against the current pinned image: Option 1 (`storage.delete.enabled: true`, already rejected on security grounds) or Option 3 (accept the log noise) or a new registry:3 upgrade path (bigger, unassessed).
