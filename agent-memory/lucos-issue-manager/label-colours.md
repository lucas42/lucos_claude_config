# Label Colour Scheme

All labels created or managed by lucos-issue-manager should use consistent colours across all repositories. This file is the canonical reference.

## Agent workflow labels

| Label | Colour (hex) | Visual | Rationale |
|---|---|---|---|
| `agent-approved` | `0e8a16` | Green | Signals "good to go" / ready for work |
| `needs-refining` | `d93f0b` | Orange | Signals "not ready" / needs attention |

## Notes

- When creating a label, always set the colour explicitly using the API's `color` field
- If a new label is needed in future, pick a colour that is visually distinct from existing labels and document it here
- GitHub's default label colour is `ededed` (light grey) -- avoid using this as it provides no visual signal
