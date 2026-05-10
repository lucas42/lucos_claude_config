# Implementation Assignment

When marking an issue `agent-approved`, also assign an `owner:*` label to indicate who will implement it.

**Default:** `owner:lucos-developer`. Exceptions below.

---

## Owner routing

| Domain | Owner |
|---|---|
| Architecture Decision Records (ADRs) and architectural documentation | `owner:lucos-architect` |
| Purely infrastructure changes (Docker config, deployment, server setup with no application code) | `owner:lucos-system-administrator` |
| Purely monitoring/logging/pipeline work (deployment pipelines, alerting, observability with no application code) | `owner:lucos-site-reliability` |
| **Investigation and diagnosis of production failures** (connection errors, timeouts, resource exhaustion, unexplained crashes — issues that say "investigation needed" or require checking logs / infrastructure / resource usage) | `owner:lucos-site-reliability` |
| Incident management (response, reporting, post-mortems, tracking) | `owner:lucos-site-reliability` |
| Purely security work (authentication setup, vulnerability remediation with no application code) | `owner:lucos-security` |
| Frontend / UX work (see below) | `owner:lucos-ux` |
| Workflow and process documentation (issue/label conventions, triage process, agent workflow docs) | `owner:lucos-issue-manager` |
| Mixed work (infra + backend, security + backend, substantial frontend + substantial backend, etc.) — with relevant specialist consulted first | `owner:lucos-developer` |
| If unclear | `owner:lucos-developer` |

**Investigation note:** do not default production-failure investigations to the developer just because a code fix might eventually be needed — the SRE is better equipped to diagnose root cause first.

---

## Frontend / UX rule

**Owner = where the dominant lines of code will live, not where the user impact lands.** A ticket is `owner:lucos-ux` only if the bulk of the work is in user-facing markup, styles, or copy. A ticket can be "about UX" at the concept level while its implementation is dominantly engineering — in that case the owner is `lucos-developer` (or another specialist) with UX consultation, NOT `lucos-ux`.

### Patterns that ARE `owner:lucos-ux`

- **Layout and styling bug fixes.** "X overlaps Y", "footer floats wrong", wrong spacing, wrong colour, broken layout, screenshots of visual bugs. CSS work regardless of what backend language the project uses.
- **Server-rendered template work** in PHP / EJS / Jinja / Go templates / ERB / etc. where the controllers are thin framework boilerplate fetching data and handing it to a view. Test: "is the design question about what the user sees, or about how data flows?"
- **"Show a clearer error message when X fails"** tickets where the dominant concern is message wording and visual presentation, and the backend detection is a trivial property check or branch (~5–10 lines). Non-trivial detection (new model fields, async logic, retry policies) → backend ticket.
- **HTML / CSS / frontend JavaScript** where the JS is presentation-level (DOM manipulation, form validation, simple interaction state) rather than business logic.
- **Accessibility implementation**, UI form layouts and field interactions, copywriting on user-facing surfaces, UX audits, information architecture scoped to a UI.

### Patterns that are NOT `owner:lucos-ux` (go to `lucos-developer` or specialist; UX consulted on user-facing surface area)

- **Admin framework customisations** — Django admin (`admin.py`), Flask-Admin, ActiveAdmin, Wagtail admin, and similar. "User-facing pages" but the implementation is entirely in the framework's configuration language (Python class attributes, decorators, model registrations); the framework generates the markup. UX consulted on field labels and destructive-action confirmation copy.
- **Web Platform infrastructure** — service workers, IndexedDB / Cache API, fetch interception, offline plumbing, WebSocket plumbing, push notifications. Engineering plumbing that enables user-facing behaviour but isn't implemented in UI code. UX consulted on user-visible surfaces (offline indicators, fallback messaging, permission-prompt copy).
- **Frontend JavaScript that is dominantly business logic**, data sync, or state management rather than presentation.
- **Backend endpoints that serve data to a UI.**

See the full Scope of Work in `agents/lucos-ux.md`. When unsure, default to `owner:lucos-developer` and add a UX consultation for the user-facing surface area.
