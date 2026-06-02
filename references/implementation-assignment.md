# Implementation Assignment

When approving an issue (setting Status = Ready on the project board), also set the Owner field to indicate who will implement it.

**Default:** `lucos-developer`. Exceptions below.

---

## Owner routing

| Domain | Owner |
|---|---|
| Architecture Decision Records (ADRs) and architectural documentation | `lucos-architect` |
| Purely infrastructure changes (Docker config, deployment, server setup with no application code) | `lucos-system-administrator` |
| Purely monitoring/logging/pipeline work (deployment pipelines, alerting, observability with no application code) | `lucos-site-reliability` |
| **Investigation and diagnosis of production failures** (connection errors, timeouts, resource exhaustion, unexplained crashes — issues that say "investigation needed" or require checking logs / infrastructure / resource usage) | `lucos-site-reliability` |
| Incident management (response, reporting, post-mortems, tracking) | `lucos-site-reliability` |
| Purely security work (authentication setup, vulnerability remediation with no application code) | `lucos-security` |
| Frontend / UX work (see below) | `lucos-ux` |
| Workflow and process documentation (issue/label conventions, triage process, agent workflow docs) | `lucos-issue-manager` |
| Mixed work (infra + backend, security + backend, substantial frontend + substantial backend, etc.) — with relevant specialist consulted first | `lucos-developer` |
| If unclear | `lucos-developer` |

**Investigation note:** do not default production-failure investigations to the developer just because a code fix might eventually be needed — the SRE is better equipped to diagnose root cause first.

**`lucos-code-reviewer` is never an implementation Owner.** It is a review-only persona (triggers: `review PR {url}`, `review any open PRs`) and cannot take an `implement issue {url}` dispatch. When an issue's work touches the code-reviewer's *own* artifacts — its stuck-PR detection guide, its `review-pr` workflow, the scripts it invokes — do **not** set Owner = lucos-code-reviewer on the theory that "it owns those files." Set Owner = `lucos-developer` (the implementation lands as a PR), and the code-reviewer reviews that PR through its normal trigger — so changes to its own instructions still pass under its eyes. (Lesson from 2026-06-02, `lucas42/.github#65`: Owner = lucos-code-reviewer couldn't be actioned because the persona has no implement trigger.)

Use the option IDs from [`triage-reference-data.md`](triage-reference-data.md) when setting the Owner field via `updateProjectV2ItemFieldValue`.

---

## Frontend / UX rule

**Owner = where the dominant lines of code will live, not where the user impact lands.** A ticket is `lucos-ux` only if the bulk of the work is in user-facing markup, styles, or copy. A ticket can be "about UX" at the concept level while its implementation is dominantly engineering — in that case the owner is `lucos-developer` (or another specialist) with UX consultation, NOT `lucos-ux`.

### Patterns that ARE `lucos-ux`

- **Layout and styling bug fixes.** "X overlaps Y", "footer floats wrong", wrong spacing, wrong colour, broken layout, screenshots of visual bugs. CSS work regardless of what backend language the project uses.
- **Server-rendered template work** in PHP / EJS / Jinja / Go templates / ERB / etc. where the controllers are thin framework boilerplate fetching data and handing it to a view. Test: "is the design question about what the user sees, or about how data flows?"
- **"Show a clearer error message when X fails"** tickets where the dominant concern is message wording and visual presentation, and the backend detection is a trivial property check or branch (~5–10 lines). Non-trivial detection (new model fields, async logic, retry policies) → backend ticket.
- **HTML / CSS / frontend JavaScript** where the JS is presentation-level (DOM manipulation, form validation, simple interaction state) rather than business logic.
- **Accessibility implementation**, UI form layouts and field interactions, copywriting on user-facing surfaces, UX audits, information architecture scoped to a UI.

### Patterns that are NOT `lucos-ux` (go to `lucos-developer` or specialist; UX consulted on user-facing surface area)

- **Admin framework customisations** — Django admin (`admin.py`), Flask-Admin, ActiveAdmin, Wagtail admin, and similar. "User-facing pages" but the implementation is entirely in the framework's configuration language (Python class attributes, decorators, model registrations); the framework generates the markup. UX consulted on field labels and destructive-action confirmation copy.
- **Web Platform infrastructure** — service workers, IndexedDB / Cache API, fetch interception, offline plumbing, WebSocket plumbing, push notifications. Engineering plumbing that enables user-facing behaviour but isn't implemented in UI code. UX consulted on user-visible surfaces (offline indicators, fallback messaging, permission-prompt copy).
- **Frontend JavaScript that is dominantly business logic**, data sync, or state management rather than presentation.
- **Backend endpoints that serve data to a UI.**

See the full Scope of Work in `agents/lucos-ux.md`. When unsure, default to `lucos-developer` and add a UX consultation for the user-facing surface area.
