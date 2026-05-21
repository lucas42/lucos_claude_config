---
name: feedback-dependabot-recreate-deterministic
description: "`@dependabot recreate` is deterministic — never relay or endorse it as a fix to a failing Dependabot PR without first verifying that an input has changed."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: a23edcc7-37e5-4107-a650-cc9771a7273d
---

`@dependabot recreate` is deterministic. It regenerates the PR using the same inputs (manifest + registry state). Unless one of those inputs has demonstrably changed since the original PR was opened (manifest edited, new version published, yanked version unyanked, etc.), recreate produces the same lockfile and the same CI failure.

**Why:** Agents (notably code-reviewer) have a recurring pattern of recommending `@dependabot recreate` as a fix for stuck Dependabot PRs, without diagnosing the actual root cause. lucas42 has run recreate on their say-so multiple times and wasted attention on it. The 2026-05-20 incident on `lucos_media_seinn#452` was the latest example — code-reviewer reported the lockfile resolving to `mocha@^11.3.0` while package.json specified `mocha@^11.7.5`, and recommended recreate; recreate did nothing because the resolution was already deterministic from the existing inputs.

**How to apply:**

- When a teammate's stuck-PR report ends with "the fix is `@dependabot recreate`" (or similar), do NOT relay that recommendation to lucas42 verbatim. Push back to the teammate first: ask them to diagnose why CI is red and identify what concrete change would alter the resolution.
- When *summarising* a code-reviewer report for lucas42, strip the "needs `@dependabot recreate`" framing unless the teammate has explained what changed since the original PR **AND** I have independently verified that change is real. The teammate's claim "package.json changed" is not sufficient — fetch commits via `~/sandboxes/lucos_agent/gh-as-agent repos/lucas42/{repo}/commits?path=package.json` and confirm at least one commit's `commit.author.date` is after the PR's `created_at`. The PR's lockfile diverging from main's lockfile is NOT evidence of a manifest change. If the verification fails or I haven't done it, strip the recreate framing the same way as if no explanation had been given. (Lesson from 2026-05-21 on `lucos_media_seinn#461`: I relayed the reviewer's "package.json changed" explanation verbatim; the reviewer later self-corrected — the manifest hadn't changed, and the PR was a stale regression requiring close, not recreate.)
- Recreate is only valid *after* an input has been deliberately changed — e.g. lucas42 has manually edited package.json and wants Dependabot to pick that up. It is never the fix on its own.

Companion instruction update lives in `~/.claude/agents/lucos-code-reviewer.md` once the code-reviewer commits it — see [[feedback_no_unverified_endorsement]] for the parallel rule about not endorsing unverified analysis.
