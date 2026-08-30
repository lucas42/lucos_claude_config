---
name: spec-text-is-interface-only
description: lucas42 rejects spec wording that describes derivation mechanism or consumer behaviour — a spec states the interface contract and stops
metadata:
  type: feedback
---

When writing or amending an estate **specification** (as opposed to an ADR), the text states the system-to-system interface and nothing else. Specifically, keep out:

- **how a system derives/forms the value** (build-arg, env var, ldflags, git-tag shape, pre-release suffixes)
- **what clients do with the value** (display only, must-not-parse, normalisation rules)

Both are implementation detail on one side of the interface or the other.

**Why:** lucas42's words on lucas42/lucos#250 (2026-07-09), rejecting my second draft — *"You've put a load of unnecessary detail about how the version is formed, which means a spec change is required if any of that changes in future. Then you specified an opaque display string, meaning there's no value in that level of detail."* Two costs: baked-in derivation detail forces a spec revision every time any system changes its derivation, and declaring a value opaque throws away a future client's ability to parse it for no gain.

Prefer naming an **external standard** over describing a format. `version` became "a [semver 2.0.0](https://semver.org) string" — one clause, parseable, and the format's evolution is somebody else's document.

**How to apply:** before publishing spec wording, delete every clause that answers "how is this produced?" or "what should the reader do with it?". If a clause survives only because it's *interesting*, it doesn't belong. Contrast [[new-consideration-gets-own-adr]] — an **ADR** exists precisely to record derivation and rationale; this rule is about spec documents, and the two must not be written in the same register.

Note the error direction: both my rejected drafts erred toward *more* detail. Thoroughness is the failure mode here, not omission.
