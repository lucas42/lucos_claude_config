---
name: Check before chasing
description: Don't repeatedly ask user to merge PRs — check the PR state or system status first
type: feedback
---

When waiting on the user to merge a PR or take an action, don't keep asking them about it on every idle notification. Instead, after a reasonable wait, proactively check whether the action has already been taken (e.g. check PR state via the API, check monitoring status) before sending another reminder. The user doesn't want to have to confirm every merge — that's tedious.
