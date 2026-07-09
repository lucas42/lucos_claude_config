---
name: feedback-no-comments-explaining-absence
description: lucas42 doesn't want code comments explaining something that ISN'T happening (a removed check, an intentionally-absent behavior) — that rationale belongs in the commit message only
metadata:
  type: feedback
---

Don't leave a comment in the source explaining why a check/behavior is absent (e.g. "principal_class is no longer validated here because…"). Lucas42's exact words on lucos_media_metadata_manager PR #366: "We don't need a comment for something that's not happening. This sort of thing is fine in the commit message, but shouldn't be in the code."

**Why:** a comment describing removed/absent behavior has no code it's anchored to — it reads as documentation of history, not of the code as it exists. That's what commit messages are for; a future reader of the source only needs to understand what the code *does*, not the story of what it used to do.

**How to apply:** when removing a check/branch (e.g. the principal_class-allowlist-removal rollout), don't leave an explanatory comment in its place justifying the removal or describing the old behavior. Put that reasoning in the commit message instead (as full prose, with issue links) and leave the source clean — just the code that actually runs, with ordinary comments only for things the code *is currently doing* that aren't obvious. Applies to every "remove X because policy Y" style change across the estate (e.g. the principal_class allowlist removal rollout — lucos_backups#368 already shipped with an explanatory comment before this feedback arrived; don't repeat the pattern on remaining/future consumers in that rollout or elsewhere).
