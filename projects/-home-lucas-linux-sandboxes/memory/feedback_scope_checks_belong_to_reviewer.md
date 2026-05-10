---
name: Scope checks belong to the reviewer
description: PR scope-vs-issue verification is lucos-code-reviewer's job, not the coordinator's post-completion handling
type: feedback
originSessionId: 4595a1b0-a470-4c5f-8870-6b813937dcbd
---
PR-scope-versus-issue-scope verification is `lucos-code-reviewer`'s responsibility, not the coordinator's. The coordinator should rely on the reviewer's approval covering both code quality and scope alignment, rather than re-reading the diff to check it matches the issue body.

**Why:** The reviewer reads every line of the diff during their normal review work; the coordinator's role is workflow orchestration. Asking the coordinator to verify scope on completion duplicates the reviewer's work and lets the reviewer's failures pass unaddressed. (Lesson from 2026-05-11 on lucos_contacts PR #702: PR diff brought back ~+787 lines of the closed #698 implementation alongside the +320-line journey-test scaffolding that was the actual #699 scope; reviewer approved it without flagging. I proposed adding a coordinator-side scope check; lucas42 corrected that this belongs to the reviewer.)

**How to apply:** When a PR slips through with a scope mismatch (e.g. surplus code from a rejected predecessor PR), route the correction to the reviewer with a request to update their own review workflow — not to your dispatch skill. Do not add diff-vs-issue-body verification to the dispatch skill's post-completion handling. The coordinator's relevant follow-up is to ensure the reviewer's persona gets the instruction update so the same miss can't recur.
