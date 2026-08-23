---
name: lucos-agent-coding-sandbox-no-deploy-path
description: lucos_agent_coding_sandbox's pi-hosts/avalon-host scripts have no deploy path — a merge doesn't apply the change to the live host
metadata:
  type: project
---

`lucos_agent_coding_sandbox`'s `pi-hosts/` and `avalon-host/` scripts provision production hosts (xwing, salvare, avalon) but the repo has no CI/deploy pipeline for them — merging to `main` only updates the script in git. `lucos-agent` has no passwordless sudo on any of the three hosts (confirmed repeatedly via `sudo -n true`), so applying the change live requires a human with root/pi-user access to run the script by hand.

**Why it matters:** a PR with a closing keyword auto-closes the originating issue on merge, but the actual deliverable (the host's running config) is still unchanged. This has stranded two merged fixes so far: PR #103 (apt timer stagger, closing #101) and PR #106 (unattended-upgrades origin coverage, closing #100) — both needed a manual follow-up that risked being lost once the issue closed.

**How to apply:** whenever implementing an issue that touches `pi-hosts/` or `avalon-host/` scripts:
1. Check `sudo -n true` on the affected host(s) before assuming you can apply the change yourself.
2. If you can't, say so explicitly in the PR body ("Manual follow-up needed") with the exact commands to run — don't just merge and move on.
3. Once the PR merges and the issue auto-closes, don't let the manual step live only as a comment on a closed issue — file (or ask the dispatcher to route) a proper tracking issue with the exact commands, so it survives past the closed issue.
4. When asked to check whether an older merged-but-possibly-unapplied script was ever run, it's a read-only check (e.g. `systemctl list-timers`, `cat` the drop-in file) — safe to do without confirming first.

The dispatcher (team-lead) has separately noted it now treats a merge in this repo as NOT completable-unattended for exactly this reason — don't assume PR-merged == done for scripts in this repo.
