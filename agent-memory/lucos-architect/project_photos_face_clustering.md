---
name: project-photos-face-clustering
description: lucos_photos face-grouping quality (#618/#620/#622/#623) — chaining fixed by gate+eps not min_samples; confirmed is 92-98% prename tier 1; #622 design posted; re-measured on finished table 2026-11-01
metadata:
  type: project
---

Re-measured 2026-11-01, after the migration in lucas42/lucos_photos#577 closed (10-29). The table is near-static now. Decisions still with lucas42 on #618.

- **Cause (#618):** `det_thresh=0.5` with no gate produces dense junk. BOTH assignment paths are single-linkage: step 2 copies the single nearest face's person, `cluster_faces` is DBSCAN `min_samples=1`. Junk seeded in March, import amplified about 70×.
- **`min_samples>1` does NOT fix it — I proposed that and measured it wrong.** All 10 junk groupings are one connected component at eps 0.5 (9,009 of 9,022), still 8,790 at min_samples 10. What breaks it: `det_score>=0.7` AND eps 0.4–0.45 (largest 172 / 446). Whole-table sim: eps 0.4 keeps labelled people 82% together with 45% noise; 0.45 gives 89% / 38%. Both 231s at 2 threads; eps 0.5 unmeasured (overran). Dry run shows both; lucas42 picks.
- **Gate:** `det_score` alone. Pixel threshold adds almost nothing; embedding norm is no better. Pairwise diameter does NOT discriminate (clean people 43–82% of pairs >0.5) — always needed a control.
- **`person_confirmed` is now 9,963, 92–98% prename tier 1** (not 830). Sources: assign, bulk move, tier 1, `merge_people` (confirms ALL loser faces, reviewed or not), reprocess re-apply. A single face's high score does NOT show it's wrong — likely-human corrections score worst (selection). Person-level coherence is the better signal: 40 of 175 persons have median confirmed distance >0.7. Five sent to lucas42 for a visual check.
- **Tier 2 isn't robust:** it uses the confirmed centroid, so bad tier 1 steers it. Centroids need a coherence check first.
- **Provenance:** the ledger never recorded faces and was deleted. Exact source = `lucos_photos_postgres_data.2026-10-28` (15:36, before prename) — pruned from 2026-11-04 per `toKeep()`. Takeout archives on avalon are the last per-photo copy of Google names.
- **Unassigned faces have no UI route to tagging:** the only assignment call in templates is the bulk move from a person page. `DELETE /faces/.../person` has no caller at all.
- **#622 design (posted 2026-11-01):** `face.not_a_face_at` column + `face_person_rejection` table (two relations, two shapes). Face ids are NOT stable — `detect_and_save_faces` deletes and reinserts, so labels need snapshot+reapply. `cluster_faces` only creates persons, so it can't violate "not P". Merge must move labels and detach conflicts. Only real #618 interaction: dissolve cascades labels away, so repair first or spec an exemption. Label endpoints don't delete emptied persons: `person.emptied_at` plus a 7-day worker cleanup, so undo works (singletons are 78% of persons).
- **#620:** replace `photo_person` with a view. Gap now 15%, not a third.
- **#623 scoring:** sampled numpy, threshold 0.7, unconfirmed only (so all of tier 1 is outside it).

**How to apply:** check what lucas42 decided on #618 before speccing matching or repair tickets. Worker logs are lost on container restart. Run measurement scripts with `docker exec c timeout N python -`: faster-to-fail guards matter on avalon, and my one overrun left a process running in the worker until I killed it.
- **Write cost (#647 → #654, 2026-11-08):** any change to `person_id` is a non-HOT update and reinserts into the 257MB HNSW index, at about 3.3s per row on avalon's HDD. The fix, #654, moves the embedding into a `face_embedding` side table, and it's a hard prerequisite for the #618 repair. Deploy trap: an api-entrypoint migration that runs longer than about 45s is restarted by the orb's unhealthy loop, so raise `start_period`. Set `maintenance_work_mem` to 512MB and workers to 0, because `/dev/shm` is 64MB.
- **#622 body consolidated 2026-11-08** (no review view; schema left open to one later). **#618 questions reframed** into product P1–P5 and technical T1–T6 (comment 6721586639).
