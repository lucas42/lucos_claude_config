---
name: project-photos-face-clustering
description: lucos_photos face-grouping quality (#618/#620/#623, 2026-10-28) — single-linkage chaining + permissive detection; confirmed≠human-verified; measured scoring costs
metadata:
  type: project
---

Snapshot as of 2026-10-28 (the migration in lucas42/lucos_photos#577 was still running; counts were moving).

- **Cause (#618):** detection has `det_thresh=0.5` and no minimum face size, so it produces dense junk. BOTH assignment paths are single-linkage: step 2 of detection copies the person of the single nearest face (ML-assigned faces count as anchors), and `cluster_faces` uses DBSCAN with `min_samples=1`, so nothing is ever treated as noise. That gave 37.7k persons for 98.5k faces. The Google import amplified the effect about 70×, but the junk clusters themselves were seeded in March, before the import.
- **Two failure modes:** junk sinks (small, low-confidence detections) are caught by a quality gate. Chained real strangers are high-quality faces, so only robust matching (a k-NN vote) catches them. The repair adds step 5b: detach a face by its median distance to the rest of its cluster.
- **Durability of corrections:** move/assign sets `person_confirmed=True` and is durable. Unassign only nulls `person_id`, so the face gets re-clustered and re-attached. There is no negative label ("not this person").
- **`person_confirmed` mixes human corrections with prename tier-1 confirmations.** 187 confirmed faces in the largest person score >0.75. This undermines "never touch confirmed"; suggested a `confirmed_by` provenance field.
- **#620:** `photo_person` was a stored copy of a derivation, missing about a third of rows. Decided: replace it with a view over `face` (the homepage query goes from 87ms to 240–333ms).
- **#623 scoring:** median distance to a seeded sample of 500 cluster faces, computed in numpy in the API (0.05s on 6.4k faces). The pgvector SQL version timed out at 20s. The API image has no numpy. Threshold 0.7, not 0.6, because median-to-cluster distance runs higher than pairwise distance.

**How to apply:** check the decisions lucas42 made on #618 before speccing the matching or repair tickets. The worker's logs are lost on every container restart, so provenance cannot be recovered from logs.
