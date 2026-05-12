# Label Colour Scheme

Reference for creating new labels on lucos repositories. Consulted only when *creating* a label — routine triage uses project board fields (Status, Priority, Owner) rather than labels.

When creating labels, always set the colour explicitly. GitHub's default is `ededed` (grey).

## Special-purpose labels

These labels remain in use as labels (not project board fields) after the workflow migration:

| Label | Colour | Purpose |
|---|---|---|
| `audit-finding` | `e4e669` (light olive) | Applied by the `lucos_repos` audit tool; exempt from migration |

All other workflow state (owner, priority, status, approval) is managed via the **lucOS Issue Prioritisation** project board fields. See [`triage-reference-data.md`](triage-reference-data.md) for field IDs and option IDs.
