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
- When *summarising* a code-reviewer report for lucas42, strip the "needs `@dependabot recreate`" framing unless the teammate has explained what changed since the original PR.
- Recreate is only valid *after* an input has been deliberately changed — e.g. lucas42 has manually edited package.json and wants Dependabot to pick that up. It is never the fix on its own.

Companion instruction update lives in `~/.claude/agents/lucos-code-reviewer.md` once the code-reviewer commits it — see [[feedback_no_unverified_endorsement]] for the parallel rule about not endorsing unverified analysis.
