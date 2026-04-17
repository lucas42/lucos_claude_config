---
name: crane --platform flag — no comma-separated lists in v0.4
description: crane v0.4 does not accept comma-separated platform lists in --platform; flag each platform separately or omit for all
type: feedback
---

`crane copy --platform=linux/amd64,linux/arm64` is **invalid in crane v0.4**. The tool treats the entire comma-separated string as a single literal platform name and fails with "no child with platform linux/amd64,linux/arm64 in index".

**Why:** crane v0.4 only accepts a single platform per `--platform` flag invocation. Comma separation is a common convention in other tools (Docker, buildx) but not supported here.

**How to apply:** If a PR adds `--platform` to a `crane copy` command with multiple platforms as a comma-separated value, flag it as incorrect. The correct approaches are:
- Omit `--platform` to copy all platforms (with retry to handle concurrent session exhaustion on large manifests)
- Specify `--platform linux/amd64` and `--platform linux/arm64` as separate flags (one flag per platform)

Confirmed failure: lucas42/.github PR #52 — 39/39 images failed after `--platform=linux/amd64,linux/arm64` was added.
