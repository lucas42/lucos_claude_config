---
name: GitHub API timestamps are UTC; VM is BST
description: GitHub API returns timestamps in UTC. The VM runs in BST (UTC+1). Always convert when comparing GitHub timestamps to local time — a run at 14:10 UTC is 15:10 locally.
type: feedback
---

GitHub API timestamps (workflow runs, PR comments, commits, etc.) are always in UTC.

The coding sandbox VM runs in **BST (UTC+1)** during summer time.

**Why:** Failed to convert timezones when polling for workflow runs, concluded that dispatches were being dropped (permissions error) when the runs had actually appeared — just outside the UTC filter window I was using. Sent a false alarm to team-lead about missing permissions.

**How to apply:** Whenever filtering GitHub API results by timestamp, convert local time to UTC first. Run `date -u` if unsure of the current UTC time. A run that appears "too early" is probably just UTC vs BST confusion.
