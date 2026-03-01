# Architect Memory

## lucos_photos

- Reviewed Feb 2026 (commit c3be2c0). Summary issue: lucas42/lucos_photos#27
- Architecture: FastAPI API + Python worker + Postgres + Redis, 4 containers (Qdrant removed per ADR-0001)
- ADR-0001: Use pgvector instead of Qdrant for face embeddings (decided #23, implementation #29)
- ADRs live in `docs/adr/` with format `NNNN-short-description.md`
- Key open decision: job queue library (recommended RQ in #5 comment)
- Key open decision: how API learns about worker processing completion (#24)
- database.py has module-level engine creation -- fragile pattern (#25)
- No docker-compose healthchecks on any container -- reliability gap noted in #27
- PhotoPerson join table alongside Face table could create data consistency issues

## Cross-project patterns

- Module-level side effects in shared packages (database connections, env var reads) are a recurring fragility pattern. Watch for this in other projects.
- The lucos convention of hardcoding auth domain as `https://auth.l42.eu` is sometimes expressed as a compose env var (`LUCOS_AUTHENTICATION_URL`), which is confusing. Better to hardcode in application code.

## Infrastructure notes

- `lucos/build-amd64` CI orb builds and pushes Docker images; large images (>1GB) significantly impact build/deploy times
- `depends_on` in compose does not wait for service readiness, only container start. Projects with Postgres should have startup retry logic.

## Claude Code setup review (Mar 2026)

Reviewed all 3 repos: `lucos_claude_config` (~/.claude), `lucos_agent`, `lucos_agent_coding_sandbox`.

Key issues filed:
- lucas42/lucos_agent#8: Persona identity scattered across 5+ locations in 3 repos. Root cause of "adding a persona is cumbersome". Recommended: single personas.json registry.
- lucas42/lucos_agent#9: get-token has no caching; generates fresh token per API call. Latency and rate-limit concern.
- lucas42/lucos_claude_config#3: Three persona files have wrong memory paths (/Users/lucas/ instead of /home/lucas.linux/)
- lucas42/lucos_claude_config#4: No mechanism to auto-commit agent memory changes
- lucas42/lucos_claude_config#5: CLAUDE.md too large, mixes reference docs with agent instructions. Recommend factoring out.
- lucas42/lucos_agent_coding_sandbox#4: Global git identity creates silent fallback when persona forgets -c flags
- lucas42/lucos_agent_coding_sandbox#5: README has wrong bot user ID (uses App ID)

Overall assessment: well-designed isolation model (Lima VM, no host mounts, dedicated SSH key). Main weakness is identity data sprawl and lack of automation for config repo maintenance.
