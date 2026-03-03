# Label Colour Scheme

All labels created or managed by lucos-issue-manager should use consistent colours across all repositories. This file is the canonical reference.

## Agent workflow labels

| Label | Colour (hex) | Visual | Rationale |
|---|---|---|---|
| `agent-approved` | `0e8a16` | Green | Signals "good to go" / ready for work |
| `needs-refining` | `d93f0b` | Orange | Signals "not ready" / needs attention |

## Status labels (why an issue is blocked)

| Label | Colour (hex) | Visual | Rationale |
|---|---|---|---|
| `status:ideation` | `c5def5` | Light blue | Goal/scope still being explored; low priority, park until relevant |
| `status:needs-design` | `fbca04` | Yellow | Goal clear but implementation details need fleshing out by an agent |
| `status:awaiting-decision` | `b60205` | Red | Options discussed; waiting for lucas42 to make a final call |
| `status:blocked` | `1d76db` | Blue | Well-defined but blocked by another issue |

## Owner labels (who should look at this next)

| Label | Colour (hex) | Visual | Rationale |
|---|---|---|---|
| `owner:lucas42` | `e4e669` | Light olive | Waiting for input from lucas42 |
| `owner:lucos-architect` | `d4c5f9` | Light purple | Needs architectural review |
| `owner:lucos-system-administrator` | `bfdadc` | Light teal | Needs infrastructure/ops review |
| `owner:lucos-site-reliability` | `fef2c0` | Cream | Needs SRE review |
| `owner:lucos-security` | `f9d0c4` | Light pink | Needs cybersecurity input |
| `owner:lucos-developer` | `c2e0c6` | Light green | Implementation work assigned to developer |

## Priority labels (relative importance)

| Label | Colour (hex) | Visual | Rationale |
|---|---|---|---|
| `priority:high` | `b60205` | Red | High impact; pick up soon |
| `priority:medium` | `fbca04` | Yellow | Standard priority; normal queue order |
| `priority:low` | `c5def5` | Light blue | Nice to have; pick up when queue is clear |

## Notes

- When creating a label, always set the colour explicitly using the API's `color` field
- If a new label is needed in future, pick a colour that is visually distinct from existing labels and document it here
- GitHub's default label colour is `ededed` (light grey) -- avoid using this as it provides no visual signal
