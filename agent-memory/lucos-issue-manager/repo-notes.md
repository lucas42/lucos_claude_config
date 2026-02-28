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
