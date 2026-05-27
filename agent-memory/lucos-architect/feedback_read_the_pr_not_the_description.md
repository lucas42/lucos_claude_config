---
name: Read the PR not the description of it
description: When an argument rests on characterising the behaviour of a referenced PR/commit/artifact, read the artifact itself before publishing — not the report or summary that references it.
metadata:
  type: feedback
---

When building an argument that rests on what a specific PR / commit / file does (especially when the argument is critical of its design), **read the artifact directly before publishing the argument** — don't take the description in a report, ticket, or teammate message as your source of truth.

**Why:** 2026-05-27, seinn playback-thrash incident report (lucas42/lucos_media_seinn#482, PR #483). The SRE incident report described #483 as "a third sliding-window detector watching `playTrack` catch blocks directly". I built an argument to lucos-site-reliability around the framing that the seinn detectors were "categorising by cause" and proposed an effect-keyed circuit-breaker as the better architecture. SRE pressure-tested it: PR #483 is **already** effect-keyed — `recordPlaybackError()` is wired into the unified `playTrack` catch block and fires on any error, regardless of cause. I'd read "decode/fetch error loops" in the PR title as describing the *detector keying* when it was just describing the *errors observed today*. My argument was built on a misread of one paraphrasing.

The teammate's report wasn't wrong — but it wasn't the source of truth for the PR's behaviour either. The PR was the source of truth.

**How to apply:**

- **When critiquing the design of a referenced PR or implementation:** open the PR (or read the modified file at the referenced lines) before publishing the critique. The 30 seconds to `gh-as-agent ... pulls/N` or `git show` is always cheaper than retracting a misframed argument.
- **Treat report-phrasing as a pointer to the artifact, not a substitute for it.** Incident reports, ADRs, and tickets describe artifacts for context. They are not the artifact. When an argument hinges on a property of the artifact, verify against the artifact.
- **The tell: an argument that contradicts a recently-shipped fix.** If my framing implies that a fresh PR didn't do something that the implementers obviously cared about, that's a strong prior that I'm misreading the PR. The implementers had the same context I do; if they shipped a "wrong" fix, more likely I've misread it. Read the PR.
- **Related but distinct from `verify-teammate-quote` and `verify-past-tense-work-claims`** — those cover quoting or relaying a teammate's claim. This covers building my own load-bearing argument on top of a teammate's description of an external artifact.

This is also a special case of [[feedback_mechanical_check_before_publishing]] — the artifact-to-check here isn't a scope list, but the principle is the same: derive from the authoritative source, don't reconstruct from a description of it.
