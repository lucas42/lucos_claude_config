---
name: Grep for old name before renaming
description: When renaming an exported symbol, always grep the whole repo for the old name before committing
type: feedback
---

Always `grep -r "old_name" .` across the entire repo before committing any rename of an exported symbol (function, variable, constant).

**Why:** PR #267 renamed `systems_to_graphs` → `live_systems` in `triplestore.py` but missed the import in `server.py`. The resulting `ImportError` caused the ingestor to crash-loop, which cascaded to the web container via `service_healthy` dependencies. SRE had to fix it in a hotfix PR (#280).

**How to apply:** Any time you rename a symbol that other modules may import — check every reference, not just the file you're editing. Tests won't catch this if the broken module isn't covered; grep is the only reliable check.
