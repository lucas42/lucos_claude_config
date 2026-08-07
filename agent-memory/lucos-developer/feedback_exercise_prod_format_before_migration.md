---
name: feedback-exercise-prod-format-before-migration
description: When a PR changes an on-disk/persisted state format, reconstruct the actual live production content and run the new code against it before claiming backward compatibility — don't rely on a synthetic unit-test fixture alone
metadata:
  type: feedback
---

When a PR changes the schema of any persisted state a live production instance already has on disk (a checkpoint file, a cache, a config file on a durable volume), reconstruct the **exact real production content** (not just a plausible-looking synthetic fixture) and run the actual new code against it, then report the concrete output — not just "the diff looks backward-compatible" or "there's a unit test for that".

**Why:** team-lead (lucos_media_import#173/PR#188) asked specifically for this — a `checkpoint.py` schema change interacted with a live on-disk checkpoint on production (15 completed directories from an interrupted run) that the merge-triggered auto-deploy would not clear. Reading the diff or citing my own unit test (which used a made-up old-format fixture, not the literal real content) wouldn't have caught a real discrepancy between what I assumed the prod file looked like and what it actually was — asking me to reconstruct the literal file content and exercise it is a materially stronger check than an abstract "should be fine" or even a same-shape-but-not-identical unit test.

**How to apply:** whenever a PR touches deserialization of an existing persisted format that a live system holds data in, get the real content (ask the persona with access/context, e.g. SRE/sysadmin, or read it directly if you have access) and run the new code against a reconstruction of it, not just a fixture you invented. Report the literal command output as evidence, not just "confirmed". This generalizes beyond checkpoints — any migration of a durable on-disk/DB format for a system already holding real data warrants the same treatment before merge.
