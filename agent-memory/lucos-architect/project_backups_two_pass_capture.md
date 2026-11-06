---
name: backups-two-pass-capture
description: lucos_backups#463 — nightly pause of photos postgres trips db-reachable; proposed two-pass rsync capture instead of suppression; awaiting lucas42
metadata:
  type: project
---

lucos_backups#463 (2026-11-05): proposed a two-pass capture for paused `full-snapshot` volumes. An unpaused rsync seeds a local mirror, a second rsync runs under pause, then the mirror is tarred unpaused. The pause then scales with churn, not volume size. APPROVED by lucas42 (👍, 2026-11-06). Follow-ups filed: backups#466 (impl), backups#467 (ADR-0002 amendment, mine; supervised repo → normal PR), photos#632 (SRE: stranded threads vs host contention; the 11-05 data favours contention). Timeout bump backups#465 (180/240) stays.

**Why:** the pause grew to 57s, because the photos DB volume grew ~16× in the migration. ADR-0002's pause amendment names planned-maintenance suppression as the fallback; I argued against it, because it hides a real stall that keeps growing and adds a backups→monitoring coupling.

**How to apply:**
- Pass 2 needs `rsync --modify-window=-1`. The default quick-check (whole seconds) missed a same-second, same-size rewrite 5/5 times locally.
- Churn measurement: an alpine `:ro` container on the volume (`sudo -n` on avalon needs a password).
- Follow-ups (now filed):
  1. backups: implement the two-pass capture.
  2. backups: third ADR-0002 amendment (mine), separate from #434.
  3. photos#632, filed.
