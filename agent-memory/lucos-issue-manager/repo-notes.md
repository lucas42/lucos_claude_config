# Per-repo notes

## lucos_backups

- **Purpose**: Backup service for lucos infrastructure; backs up Docker volumes across hosts
- **Labels created**: `agent-approved`, `needs-refining` (created 2026-02-26)
- **Known context**: Startup resilience already fixed (Jan 2026); backup/prune scripts still need host-down resilience

## lucos_creds

- **Language**: Go
- **Purpose**: Credential manager for lucos systems
- **Credential types**: "simple" (key-value) and "linked" (references to other credentials)
- **Labels created**: `agent-approved`, `needs-refining` (created 2026-02-26)
- **Default labels present**: bug, dependencies, docker, documentation, duplicate, enhancement, github_actions, go, good first issue, help wanted, invalid, javascript, python, question, wontfix

## lucos_media_manager

- **Language**: Java
- **Purpose**: Media playback manager; manages playlists, devices, and long-polling for state changes
- **Labels created**: `agent-approved`, `needs-refining` (created 2026-02-26)
- **Default labels present**: bug, dependencies, docker, duplicate, enhancement, github_actions, invalid, java, question, wontfix
- **Related repos**: lucos_media_seinn (client), lucos_media_metadata_api (metadata backend)
- **Known context**: CollectionList fetches from media_metadata_api at startup; NPE and retry issues filed (Feb 2026, #140 and #141)

## Archived repos (read-only, cannot modify issues)

- lucos_contacts_googlesync
- lucos_core_legacy
- lucos_lanscan
- lucos_services
- lucos_speak
- lucos_systems

## lucos_deploy_orb

- **Purpose**: CircleCI orb for building and deploying lucos services
- **Labels created**: `agent-approved`, `needs-refining` (created 2026-02-26)
- **Default labels present**: bug, documentation, duplicate, enhancement, good first issue, help wanted, invalid, question, wontfix
- **Known context**: Orb defines build and deploy jobs; deploy command is in `src/commands/deploy.yml`; uses custom image tagging (issue #2 proposes switching to docker manifests)

## lucos_media_seinn

- **Language**: JavaScript (Node.js)
- **Purpose**: Media player client; connects to lucos_media_manager for playback state
- **Labels created**: `agent-approved`, `needs-refining` (created 2026-02-26)
- **Default labels present**: bug, dependencies, docker, duplicate, enhancement, github_actions, help wanted, invalid, javascript, question, security, wontfix
- **Related repos**: lucos_media_manager (backend)
- **Known context**: `/_info` endpoint calls `v3/poll` (a long-poll endpoint) on media_manager; timeout fix needed (#171)

## lucos_claude_config

- **Purpose**: Git-tracked `~/.claude` directory; persona files, CLAUDE.md, agent memory
- **Labels created**: `agent-approved`, `needs-refining` (created 2026-03-01)
- **Known context**: CLAUDE.md refactoring planned (#5, approved by lucas42); rename `infrastructure-conventions.md` to `lucos-conventions.md` per lucas42 preference

## lucos_photos

- **Language**: Python (FastAPI + SQLAlchemy)
- **Purpose**: Personal photo library with upload, face detection, and people management
- **Labels created**: `agent-approved`, `needs-refining` (created 2026-02-28)
- **Architecture**: API + worker + Postgres + Redis (Qdrant being replaced by pgvector per #29)
- **Known context**: Early stage, no photos processed yet; ADR-0001 decided pgvector over Qdrant; several architectural issues awaiting lucas42 decisions (#24, #25, #26)

## lucos_configy

- **Purpose**: Configuration management service for lucos systems (systems, volumes, hosts)
- **Labels created**: `agent-approved`, `needs-refining` (colour fixed 2026-03-01)
- **Known context**: `needs-refining` label had wrong colour (ededed instead of d93f0b), fixed 2026-03-01

## lucos_agent

- **Purpose**: Agent workflow scripts (get-token, gh-as-agent, get-issues-for-review, personas.json)
- **Labels created**: `agent-approved`, `needs-refining` (created 2026-02-28)

## lucos_agent_coding_sandbox

- **Purpose**: VM provisioning repo for the agent coding environment (lima.yaml, setup scripts)
- **Labels created**: `agent-approved`, `needs-refining` (created 2026-02-28)
- **Known context**: Global git identity removal agreed (Option A, #4); need separate ticket for general-purpose dev persona

## lucos_monitoring

- **Language**: Erlang
- **Purpose**: Monitoring service for lucos infrastructure; checks health of services including CircleCI build status
- **Labels created**: `agent-approved`, `needs-refining` (already existed)
- **Known context**: CircleCI check uses deprecated v1.1 API (#25, approved); v2 migration would improve signal quality by filtering for deploy job outcomes

## lucos (cross-cutting concerns repo)

- **Purpose**: Top-level repo for cross-cutting conventions and decisions
- **Labels created**: `agent-approved` (colour fixed from ededed to 0e8a16, 2026-03-01), `needs-refining` (correct colour)
- **Known context**: Architectural review storage convention decided (#24) -- reviews go in `docs/reviews/` as committed Markdown, not as GitHub issues; Security Advisory practice proposed (#25, needs-refining, awaiting lucas42 decisions)
