---
name: review-try-except-refactor-variable-drop
description: When a PR refactors a try/except block (e.g. bare except: to an explicit check), verify every variable assignment inside the original try block is preserved in the refactored version.
metadata:
  type: feedback
---

Missed instance: lucos_backups PR #62 dropped `project = labels[...]` (originally inside the `try`) when consolidating the error check. The variable was still used downstream, causing a `NameError` on every labelled volume — required an emergency fix in PR #63.
