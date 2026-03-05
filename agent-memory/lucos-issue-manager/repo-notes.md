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
- **Labels created**: `agent-approved`, `needs-refining` (created 2026-02-26); triage labels created 2026-03-02
- **Default labels present**: bug, documentation, duplicate, enhancement, good first issue, help wanted, invalid, question, wontfix
- **Known context**: Orb defines build and deploy jobs; deploy command is in `src/commands/deploy.yml`; uses custom image tagging (issue #2 proposes switching to docker manifests)
- **Open issue**: #8 (CircleCI access for SRE agent) -- awaiting lucas42 decision on security concerns raised by lucos-security

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
- **Architecture**: API + worker + Postgres + Redis (Qdrant replaced by pgvector per #29)
- **Known context**: Early stage, no photos processed yet; ADR-0001 decided pgvector over Qdrant
- **Key decision (2026-03-02)**: Worker is allowed to call Loganne directly (#24 approved); constraint that only API emits external domain events has been lifted
- **Split issues**: #25 split into #39 (pg_isready retry) and #40 (wrap engine creation) -- both agent-approved
- **Cleanup needed**: Orphaned Qdrant container and volume still running on production (#76); collation version mismatch in Postgres (#77)

## lucos_configy

- **Purpose**: Configuration management service for lucos systems (systems, volumes, hosts)
- **Labels created**: `agent-approved`, `needs-refining` (colour fixed 2026-03-01)
- **Known context**: `needs-refining` label had wrong colour (ededed instead of d93f0b), fixed 2026-03-01

## lucos_agent

- **Purpose**: Agent workflow scripts (get-token, gh-as-agent, get-issues-for-triage, get-issues-for-persona, personas.json)
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

## lucos_eolas

- **Language**: Node.js
- **Purpose**: Knowledge/information service in the lucos ecosystem
- **Labels created**: All triage labels created 2026-03-03 (was missing `agent-approved` previously)

## lucos_time

- **Language**: JavaScript (Node.js)
- **Purpose**: Time-related service; currently serves `/now` endpoint
- **Labels created**: `needs-refining` (existed); `status:awaiting-decision`, `owner:lucas42` created 2026-03-04 (colours fixed from default grey)
- **Known context**: Very thin service (~105 lines, raw http.createServer); issue #70 proposes adding temporal objects endpoint integrating with lucos_eolas

## lucos_locations

- **Purpose**: Location tracking service using MQTT (mosquitto)
- **Labels created**: `agent-approved`, `needs-refining`, `owner:lucos-system-administrator`, `owner:lucas42`, `status:ideation`, `priority:medium`, `priority:low`, `owner:lucos-developer` (colours fixed 2026-03-04)
- **Known context**: mosquitto currently runs as root; issue #7 to switch to non-root user in certreaders group (low priority, lucos_locations not actively worked on)

## lucos_photos_android

- **Language**: Java (Android)
- **Purpose**: Android app for lucos_photos
- **Labels created**: `agent-approved`, `needs-refining`, `owner:lucos-developer`, `owner:lucas42`, `owner:lucos-system-administrator`, `status:ideation`, `priority:high` (created 2026-03-04)
- **Known context**: Needs human-facing installation documentation (README.md); #14 is high priority per lucas42

## lucos_comhra

- **Language**: Python
- **Purpose**: Agent/chat service (new repo, first issue opened 2026-03-05)
- **Labels created**: `agent-approved`, `owner:lucos-developer`, `priority:low` (created 2026-03-05, colours fixed same day)
- **Known context**: Cookie injection vulnerability in `agent/auth.py` (#1)

## lucos_contacts_fb_import

- **Language**: Python
- **Purpose**: Facebook contacts import tool
- **Labels created**: `agent-approved`, `owner:lucos-developer`, `priority:low` (created 2026-03-05, colours fixed same day)
- **Known context**: Clear-text logging of PII (#17)

## lucos_media_metadata_manager

- **Language**: JavaScript (Node.js)
- **Purpose**: Media metadata management; track metadata, search, bulk updates
- **Labels created**: `agent-approved`, `needs-refining`, triage labels (created 2026-03-02)
- **Known context**: Search currently uses SQLite LIKE queries; #51 proposes switching to lucos_arachne search index; #8 (whitespace trimming) proposed to be closed in favour of #51
- **Related repos**: lucos_media_manager, lucos_eolas, lucos_arachne, lucos_search_component
