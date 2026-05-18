---
name: java-mockito-auth
description: When refactoring auth checks in Java controllers, all mock helpers must be updated — checkNotAllowed is easy to miss
metadata:
  type: feedback
---

When refactoring auth checks in Java controllers, ALL mock-creating helpers must be updated:
- `compareRequestResponse` — mock helper, needs auth setup
- `checkNotAllowed` — separate mock helper, easy to miss

If switching from `hasAuthorizationHeader() && !isAuthorised()` (Phase 1) to `!isAuthorised()` (Phase 3), add `when(request.isAuthorised()).thenReturn(true)` to BOTH helpers.

**Why:** Missing `checkNotAllowed` causes tests to pass with the wrong auth expectation — only caught at integration time.

**How to apply:** Any time Java controller auth logic is changed, grep for all `Mock()` / test helper patterns in the test file before committing.
