---
name: media-manager-domain-mapping
description: Two confusingly-named media systems and their domains; lucos_configy/config/systems.yaml is the canonical domain↔system map
metadata: 
  node_type: memory
  type: reference
  originSessionId: 2557587a-674d-403d-ae41-92b3642a8ffb
---

`lucos_configy/config/systems.yaml` is the canonical source for which lucos system runs on which domain. Verify against it before claiming a domain or link is stale / needs migrating.

Easy trap (caused a wrong developer suggestion on 2026-05-31 during media-metadata→eolas migration close-out):

- `lucos_media_metadata_manager` → `media-metadata.l42.eu` (the metadata/tagging manager)
- `lucos_media_manager` → `ceol.l42.eu` (a *different* system)

Similarly named but distinct; `media-metadata.l42.eu` is NOT an "old" domain. Related: [[project_v3_migration]].
