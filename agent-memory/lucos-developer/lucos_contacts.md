---
name: lucos-contacts
description: Django structure, test runner wiring, and migration workflow for lucos_contacts
metadata:
  type: project
---

- **Django app**. Tests run via `docker compose --profile test up test --build --exit-code-from test`.
- **Test runner wiring**: new test files must be added to `app/agents/tests/__init__.py` as `from .module import *` — Django's test runner discovers via `__init__.py` only; new files that aren't imported there are dead code and never run.
- **Admin Loganne pattern**: capture old field value in `save_model` (DB read before `super().save_model()`), store on request (`request._saved_foo`), compare vs new value in `response_change` to emit the correct event.
- **Migration workflow**: `docker compose up -d --build app` → `docker compose exec app python manage.py makemigrations` → `docker cp lucos_contacts_app:/usr/src/app/agents/migrations/ app/agents/`.
