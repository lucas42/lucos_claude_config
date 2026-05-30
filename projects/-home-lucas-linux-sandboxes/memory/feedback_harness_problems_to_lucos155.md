---
name: feedback_harness_problems_to_lucos155
description: "Claude Code harness/product-layer problems outside our control are tracked on lucas42/lucos#155"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 9dec23f5-2604-4ec2-a4fa-ad772fae61b5
---

# Out-of-our-control Claude Code harness problems → lucas42/lucos#155

When an investigation surfaces a problem that is a **Claude Code harness / product-layer limitation** (not fixable in our infra, `~/.claude` config, hooks, MCP servers, or slash commands), the finding belongs on **lucas42/lucos#155** ("Ideation: bespoke agent harness for lucos-specific multi-agent workflows"). Add a comment there capturing the evidence, framed as further motivation for that ideation, and link back to whatever ticket surfaced it.

**Why:** lucas42 set this as the standing default (2026-05-30, when closing lucos_agent_coding_sandbox#85). #155 already collects this class — it cites the 2026-05-14 phantom-teammate-message incident. Leaving harness limitations stranded on per-repo tickets (e.g. a sandbox ticket) fragments the evidence and implies they're locally fixable when they aren't.

**How to apply:** When triaging/investigating, split findings by ownership. Infra/config-fixable → normal ticket on the relevant repo (e.g. the swap fix went to lucos_agent_coding_sandbox#86). Harness/model-layer → comment on lucos#155. The originating investigation ticket can then close (assessment is the record) with the actionable fix carried forward as its own ticket. This is the **default for all personas** — when sysadmin (or anyone) reports a product-layer finding, route it to #155 rather than letting it sit. Examples of this class: fabricated/confabulated tool output on empty results, phantom messages, Bash stdout batching/out-of-order, intermittent Write/Read failures. Related: [[feedback_phantom_teammate_messages]].
