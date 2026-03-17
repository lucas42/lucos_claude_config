---
name: Docker healthcheck tool availability notes
description: Common gaps when adding Docker healthchecks — tools missing from final image stages
type: reference
---

When adding healthchecks, verify the probe tool is installed in the **final** image stage (not just the build stage). Common gaps found across the estate (2026-03-13):

- `debian:trixie` minimal final stage — no `wget` by default; add to `apt-get install`
- `alpine` + `postfix` — no `nc`; add `busybox-extras`
- `alpine` + `busybox-extras` — still no `pgrep`; `pgrep` needs `procps` (not a BusyBox applet)
- `docker:dind` Alpine — no `nc`; add `busybox-extras`
