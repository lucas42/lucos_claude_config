---
name: feedback_dr_bespoke_correction_data
description: When assessing recreate_effort, check whether the DB stores bespoke corrections to external data — those corrections are the irreplaceable part, not the raw data
metadata:
  type: feedback
---

When a database stores corrections or improvements to externally-sourced data (e.g. ID3 tags, third-party imports), the **corrections** are the irreplaceable part — not the raw data, which can be reimported.

Do not assume a volume is reconstructable just because the underlying source data (e.g. media files on a NAS) still exists. If the DB contains bespoke human fixes to bad/incomplete source data, or manually curated relationships that were never in the source (e.g. track→eolas `about`/`mentions` predicate links), those are irreplaceable regardless of what the source can be reimported from.

**Why:** Downgraded `lucos_media_metadata_api_db` from `huge` to `considerable` on the reasoning that track records are "largely reconstructable from the NAS". lucas42 correctly pointed out that many tracks have bespoke metadata corrections for incomplete/incorrect ID3 tags, and that the track→eolas predicate links are purely manual. Neither is recoverable from a NAS rescan. The correct classification stays `huge`.

**How to apply:** Before downgrading a volume's recreate_effort based on "source data still exists elsewhere", explicitly check: does the DB contain human corrections to that source data, or manual annotations built on top of it? If yes, the corrections/annotations are the value — the existence of the original source is irrelevant to recoverability.
