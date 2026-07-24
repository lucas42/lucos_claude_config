---
name: review-gh-body-at-sign
description: gh-as-agent --field body="..." treats a leading @word as "read from file" even inside a heredoc — wrap package names starting with @ (e.g. `@types/node`) in backticks in review body text.
metadata:
  type: feedback
---

Even with a heredoc (so bash has already substituted the value), if the final body string starts with `@`, `gh` interprets it as a file path and fails with "no such file or directory". Confirmed failure: tfluke#332 — body starting with `@types/node patch bump` triggered this. Fix: wrap in backticks (`` `@types/node` ``).
