---
name: Don't introduce asserted/inferred class distinctions for user-facing facts
description: When a system surfaces inferred facts to the user as equal-status, don't propose a data-model split that elevates one class over another — even for "principled" reasons
type: feedback
---

When a user sees inferred relationships (or any inferred user-facing facts) as equally real to asserted ones, don't propose splitting them into classes — `is_asserted` flags, "asserted vs entailed" UX, etc. — even when it cleans up the data model. The split itself is the harm: it creates a hierarchy the user finds ethically objectionable.

**Why:** lucos_contacts#53 (2026-05-07). I proposed adding `is_asserted` to `Relationship` so deletion behaviour could be principled. lucas42 pushed back: "if I say someone is my cousin and the system infers their 4 siblings are also my cousin, then all five are equally my cousin. That's a complete no-go on ethical grounds." The data-model cleanup would have made certain family members second-class citizens in the database. I should have seen that when proposing it.

**How to apply:** When reasoning about data models that touch user-meaningful relationships (people, contacts, family, anything social), check whether the fix introduces a *visible class distinction* between facts the user sees as equivalent. If yes, the fix is wrong — find one that preserves equivalence. Better alternatives exist: in this case, "deletion is refused if the row would be re-inferred from the rest of the graph" achieves data consistency without needing to label some rows as second-class. Apply this lens to any system where humans are the data subjects.
