---
name: pattern-capturing-large-container-logs
description: Python container logs go to STDERR, so `docker logs X 2>&1 > file` silently dumps the whole log to your terminal; use `> file 2>&1`, then histogram message shapes before grepping.
metadata:
  type: reference
---

**`docker logs X 2>&1 > file` does NOT capture the log.** Redirections apply left to right: `2>&1` first points stderr at the *current* stdout (your terminal), and only then is stdout moved to the file. Python's `logging` module writes to **stderr**, so for any Python container almost the entire log bypasses the file and lands in your context.

Correct order — file first, then merge:

```bash
docker logs <container> > /tmp/wlog.txt 2>&1
```

Cost of getting it wrong, 2026-09-16: a 70MB / 471k-line `lucos_photos_worker` log blew past the 64MB persist limit in one tool call.

## Then histogram before you grep

Never read a large log linearly. Collapse identifiers and count shapes first — it tells you what the service actually spent its time doing, which is usually the finding:

```bash
sed -E 's/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/<UUID>/g;
        s/[0-9a-f]{64}/<SHA>/g; s/[0-9]+/<N>/g' /tmp/wlog.txt |
  sort | uniq -c | sort -rn | head -25
```

That one command is what revealed 62.5% of the photos worker's log was its own sweep bookkeeping (lucas42/lucos_photos#528). Counting **distinct** subjects (`grep -oE 'key:[0-9a-f-]{36}' | sort -u | wc -l`) separates "N events" from "N things", which is usually the number that matters.

## Two standing cautions

- **Establish the log window first**: `docker inspect <c> --format '{{.State.StartedAt}} -> {{.State.FinishedAt}} restarts={{.RestartCount}}'`. A restart clears the buffer, so the earliest line is not an onset — see [[pattern_container_restart_log_buffer_artifact]]. On 2026-09-16 the window was only 6.5h, which meant the logs could not speak to anything before the rebuild.
- **Clean up the temp file and verify by listing**, not by exit code. avalon's `/tmp` is a 3.9G tmpfs (roomy); xwing's is 454MB on a 906MB host and will destabilise the box — see the persona's blast-radius rule.
