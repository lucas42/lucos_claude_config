---
name: pattern-db-error-line-is-not-app-failure
description: Postgres logs handled constraint violations at ERROR level — check whether the app catches the exception before counting DB ERROR lines as a finding
metadata:
  type: feedback
---

A database `ERROR:` line in container logs is **not** evidence that anything failed at the application level. Postgres logs every constraint violation at ERROR severity, including ones the application catches, rolls back, and turns into a clean HTTP response.

**Before reporting DB errors as a finding, find the write site in the code and check for an exception handler.**

**Why:** 2026-07-27 ops checks, `lucos_photos_postgres`. I found 25 × `ERROR: duplicate key value violates unique constraint "person_contact_id_key"` on `UPDATE person SET contact_id=…` and was one step from filing "silent failures invisible to `/_info`". They were the app's *designed* conflict path: `api/app/routers/people.py:254-266` catches `IntegrityError`, checks `pgcode == '23505'`, rolls back, looks up the conflicting row and raises `HTTPException(409, {"message": …, "existingPersonId": …})`. The constraint was correctly rejecting a genuinely invalid action (linking one contact to two people — contact_id 70 attempted 3×). Working as intended, loudly.

**How to apply:**
- Grep the codebase for the column/table in the failing statement, find the write site, look for `except IntegrityError` / `pgcode` / `23505` / `UNIQUE constraint failed` handling.
- Check whether it's **ongoing** — a burst confined to one 20-minute window 8 days ago is a user session, not a live defect.
- Repeated values in the DETAIL line (same key attempted several times) point at a human retrying in a UI, not an automated loop.
- Same discipline in reverse: raw SQL in the logs that is **absent from the codebase** is an ad-hoc psql query, not a broken code path. On the same run, a single `relation "photo" does not exist` turned out to be someone hand-typing a query with the wrong table name — the app is SQLAlchemy ORM throughout.

Related: [[feedback_verify_root_cause_by_reproduction]], [[pattern_info_endpoint_boundary]], [[feedback_treat_empty_tool_output_as_unknown]].
