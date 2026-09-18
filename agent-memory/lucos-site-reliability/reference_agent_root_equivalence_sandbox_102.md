---
name: reference-agent-root-equivalence-sandbox-102
description: lucos-agent is root-equivalent on production hosts via the docker group (lucas42/lucos_agent_coding_sandbox#102), so "the agent can read X on a host" is almost never a new security finding
metadata:
  type: reference
---

`lucos-agent` is in the `docker` group on production hosts (`id` on xwing: `groups=985(docker)`), which makes it root-equivalent there. This is tracked in **lucas42/lucos_agent_coding_sandbox#102**, open; lucas42 wants the access narrowed.

**Why:** on 2026-09-18 I reported "the agent can read and decrypt the prod creds store from world-readable backups on xwing" to team-lead as new, saying "nothing covers backup readability". I had searched lucos_creds and lucos_backups, not the repo where the *access* problem lives. The avalon incident report, which I wrote, already cited #102 in its Sensitive Findings. I had to retract.

**How to apply:** before raising anything of the form "the agent can read/modify X on a host", check #102 first. Only the part that doesn't depend on docker-group access is potentially new, such as file modes exposed to *non*-docker accounts, and then only after checking which such accounts exist. Search the repo where the *capability* lives, not the one where the *data* lives. Related: `lucos_creds_store` backups contain `data_key` next to `creds.sqlite`, so they decrypt on their own. That's the property that made the 09-14 rescue possible (lucas42/lucos#301 analysis).
