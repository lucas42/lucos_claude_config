---
name: Test-scaffolding issues must scope assertions against existing code
description: When writing a test-harness / test-infrastructure ticket, every assertion in the body must be reachable against the code currently on main. Assertions requiring production code not yet on main contradict the harness-only intent and force the implementer to bring in that production code.
type: feedback
---

When writing a "test scaffolding" / "test infrastructure" / "test harness" ticket as a deliberate split from a larger piece of work, every test assertion mentioned in the body must be runnable against the code currently on main. Assertions that exercise behaviour from a sibling not-yet-landed ticket contradict the harness-only framing and will force the implementer to cherry-pick the production code from the sibling to make the tests pass — defeating the whole point of the split.

**Why:** lucos_contacts close-and-split, 2026-05-10. PR #698 (relationship deletion semantics) was closed for journey breakage. The plan was to split into:
- #699 = test harness only
- #700 = admin journey, redesigned
- #701 = engine refactor, redesigned

The #699 body I wrote specified journey tests that asserted on ADR-0001 behaviour (non-empty supporting-path list, sibling-group expansion through to deletion, Loganne emission on admin delete). Those assertions required `RelationshipAdmin.delete_view`, the closure logic, and the Loganne wiring — none of which were on main. The developer correctly read the assertion list and cherry-picked the entire #698 production diff into PR #702 to make the tests runnable. lucas42 closed PR #702 and confirmed that was the opposite of the split intent. Root cause: the body of #699 and the close-and-split intent contradicted each other.

**How to apply:**
- Before writing assertions into a test-harness ticket, list each one and ask: "is the code being asserted on currently on main?"
- If no, the assertion belongs in the sibling ticket that brings in that code.
- Express the harness ticket's deliverable as "the test infrastructure plus a small set of sanity tests that prove the harness works against the code currently on main" — not as "the test suite for the upcoming feature".
- Add an explicit out-of-scope section listing the assertions that move to which sibling ticket. Without this, the implementer cannot tell whether they have license to bring in production code.
- Add an explicit "no production code changes" acceptance criterion. Confirm scope with the raiser before any small refactor needed to make a model admin-testable.
- Remove cherry-pick-from-prior-PR language from the harness ticket — that wording is what licensed the contamination in the original case.
- For each sibling ticket, name explicitly which journey/integration tests it owns. Split by what code each sibling brings in: journey-shape tests with the journey ticket, engine-semantics tests with the engine ticket. Don't leave "journey tests from #N continue to pass" hanging without saying which subset where.
