---
name: Developer processes messages out of order under load
description: When multiple messages are sent to lucos-developer in quick succession, they may act on earlier instructions before reading later corrections — leading to wasted work and repeated status reports
type: feedback
---

When sending corrections or stand-down instructions to the developer, don't send follow-up dispatch messages until the developer has explicitly acknowledged the correction. In this session, the developer started implementing monitoring#62 with the wrong design (SUPPRESS_TOKEN instead of CLIENT_KEYS), and despite being told to stand down, submitted PRs before reading the correction. Multiple messages in quick succession get processed out of order.

**Why:** The developer agent processes messages sequentially but may already be mid-task when a correction arrives. Sending "stop" followed quickly by "now go" results in the "go" being acted on before the "stop" is fully processed.

**How to apply:** After sending a stand-down or correction message, wait for an explicit acknowledgment before dispatching new work. Don't stack messages — let the developer catch up first.
