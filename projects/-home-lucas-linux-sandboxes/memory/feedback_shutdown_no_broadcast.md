---
name: SendMessage has no broadcast mechanism
description: Setting to:"broadcast" or to:"*" goes to a phantom inbox, not the team — always send individual messages, one per teammate
type: feedback
originSessionId: 061afd69-ccf3-4111-8b35-6aba5d24e6a8
---
There is no broadcast mechanism in the SendMessage tool. Setting `to: "broadcast"`, `to: "*"`, or any similar wildcard does NOT multiplex to all teammates — the system creates an inbox for that literal name and the message sits there with no readers. The response "Message sent to broadcast's inbox" is the system literally putting it in a phantom inbox, not confirming a team-wide delivery. The only structured message types are `shutdown_request`, `shutdown_response`, and `plan_approval_response`.

To reach multiple teammates (post-incident broadcast, shutdown sequence, estate-wide notice, anything else), send **individual SendMessage calls, one per teammate**, all in a single response (parallel tool calls). The recipient list is the canonical persona names: lucos-architect, lucos-code-reviewer, lucos-developer, lucos-security, lucos-site-reliability, lucos-system-administrator, lucos-ux — minus the sender and the coordinator if appropriate.

**Why:** The trap has bitten twice — once on shutdown_request "broadcasts" returning errors, and once on 2026-05-09 when SRE sent a post-incident broadcast via `to: "broadcast"` that nobody received. The latter was particularly subtle because SendMessage returned a success-shaped response. The reference doc that prompted SRE's attempt (`references/incident-reporting.md`) was itself wrong and has now been fixed (commit `288d946`); but the same mistake can still be made anywhere SendMessage is invoked, so this memory is the durable guardrail.

**How to apply:** Whenever you need to "broadcast" anything — at shutdown, on incident report merge, on estate-wide rollout completion — fan out via individual SendMessage calls. If a teammate or doc tells you they "sent a broadcast", verify the actual mechanism they used; "Message sent to broadcast's inbox" is a red flag, not a confirmation. Apply this lesson immediately on first sign of broadcast-shaped wording, not retrospectively after another agent has already accepted it.
