---
name: python-test-stubs
description: sys.modules stubbing patterns and pitfalls for Python test suites across lucos repos
metadata:
  type: feedback
---

When stubbing modules via `sys.modules` before importing a server module in tests:
- **Always pop stubs after import** (`sys.modules.pop(mod_name, None)`) if other test files in the same pytest session import the real module — stale stubs cause `ImportError` on real module attributes.
- **waitress**: must stub `waitress` with `stub.serve = lambda *a, **kw: None` for WSGI servers using waitress.
- **Pattern** (for pytest files): save stub names list before import, pop after import.
- **CRITICAL: pop the server module too** before installing stubs if multiple test files all use `sys.modules` stubs and import the same server module. If test_auth.py imports server (caching it in sys.modules with its empty stubs bound to globals), then test_webhook.py's stubs will NOT bind — server.py's module globals still point to test_auth.py's stubs. Fix: `sys.modules.pop("server", None)` at the top of test_webhook.py before stub setup. Failing to do this causes `KeyError` on `live_systems[event["source"]]` and similar (values are `{}` from the earlier stub).
- **Stub must include ALL functions imported in server.py** — missing one (e.g. `merge_items_in_triplestore`) causes `ImportError` before cleanup code runs, leaving ALL stubs in `sys.modules` and cascading failures into subsequent test files.
