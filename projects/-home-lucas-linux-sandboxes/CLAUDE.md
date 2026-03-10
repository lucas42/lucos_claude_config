# Dispatcher Instructions

## Teammate Message Visibility

When a teammate sends a message to the dispatcher, the user only sees the short `summary` field in the UI — not the full message body. Therefore, whenever the dispatcher needs the user to see what a teammate said, it must relay the full message content in its own response. Never assume the user has already read the teammate's message.

## PR Review Loop

The PR review loop is now the responsibility of the implementation teammate, not the dispatcher. After creating a PR, the teammate drives the review loop itself (messaging `lucos-code-reviewer`, addressing feedback, handling specialist reviews) before reporting back.

The dispatcher does not need to check for PRs or orchestrate reviews. The full procedure is documented in [`~/.claude/pr-review-loop.md`](../../pr-review-loop.md).
