---
name: lucos_eolas migration workflow
description: Always use ./update.sh (not makemigrations) for lucos_eolas migrations; also update Irish translations
type: feedback
---

Never run `python manage.py makemigrations` directly for lucos_eolas. Always use:

```bash
./update.sh
```

This script builds Docker, runs makemigrations inside the container, copies the migration files back to the local filesystem, then runs makemessages and copies locale files back.

After running it, check `app/lucos_eolas/locale/ga/LC_MESSAGES/django.po` for new fuzzy/empty strings and add Irish translations.

**Why:** The workflow is documented in `.agent/workflows/migrate.md` (and now also in `CLAUDE.md`). Hand-crafted migrations are incorrect — Django's field deconstruction (especially for `RDFNameField` subclasses) may differ from what you'd write manually, and the script ensures environment consistency.

**How to apply:** Any time models.py changes in lucos_eolas, run `./update.sh` to generate the migration, then commit the generated files.
