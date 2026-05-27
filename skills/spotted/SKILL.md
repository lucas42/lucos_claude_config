---
name: spotted
description: Add a role to lukeblaney_cv_tailored/applications/spotted.md from a JD URL. Fetches the JD, derives Company/Role/Location/Comp, asks for the discovery Source via multi-choice, appends the entry and commits.
disable-model-invocation: false
---

# /spotted

Fast-capture skill — drops a row into the spotted queue in seconds. Not a research skill: no per-org `notes.md` is created here. Deep company research happens later when `/tailor` runs for an application.

The JD URL is the first argument (e.g. `/spotted https://...`). If no URL is provided, ask for one before proceeding.

## Step 0: Routing

This is career-advisor work — uses the career-advisor GitHub identity for commits.

- **If you are the career-advisor agent**: follow the steps below directly.
- **If you are any other agent**: send a message to the `career-advisor` teammate (`"spotted {url}"`) and wait for the result. Do not perform the work yourself.

## Step 1: Load the standing rules

Read before starting:

- `~/.claude/agent-memory/career-advisor/project_applications_tracker.md` — tracker layout and entry conventions.
- `~/.claude/agent-memory/career-advisor/feedback_source_vs_ats.md` — Source = discovery channel, not the ATS. Never conflate.

## Step 2: Fetch the JD

WebFetch the URL. Extract:

- **Company name** (used to derive the org slug).
- **Role title** — exact posted title.
- **Location** — as listed.
- **Comp band** — only if explicitly disclosed in the JD. Do not infer.
- **Closing date** — only if explicitly stated.

If a field can't be reliably extracted, leave it out of the entry — don't write "not disclosed" boilerplate.

## Step 3: Determine the org slug

The org slug is the kebab-case company name matching the existing `orgs/{slug}/` convention (e.g. `airbnb`, `funding-circle`, `rail-delivery-group`).

Check whether `~/sandboxes/lukeblaney_cv_tailored/orgs/{slug}/` already exists. The Notes link in the entry points at `../orgs/{slug}/notes.md` either way — if the folder doesn't exist yet, it'll be created on first tailoring.

## Step 4: Ask for the Source

Use AskUserQuestion with these four options (Other is auto-provided):

1. **LinkedIn**
2. **Direct (company careers page)**
3. **Recruiter outreach** (note in-house vs third-party in the entry if known)
4. **Referral**

## Step 5: Append the entry

In `~/sandboxes/lukeblaney_cv_tailored/applications/spotted.md`, append the new entry above the `_None at the moment._` placeholder (remove the placeholder when adding the first entry; add it back if the file is emptied later).

Schema — include only the fields with known values:

```markdown
### {Company} — {Role}

- **Source:** {selected option}
- **JD:** <{url}>
- **Spotted:** {today's date YYYY-MM-DD}
- **Location:** {as listed}
- **Comp:** {band if disclosed}
- **Closing date:** {date if known}
- **Notes:** [orgs/{slug}/notes.md](../orgs/{slug}/notes.md)
```

## Step 6: Commit

```bash
cd ~/sandboxes/lukeblaney_cv_tailored && \
  git add applications/spotted.md && \
  ~/sandboxes/lucos_agent/git-as-agent --app career-advisor commit -m "spotted: add {Company} — {Role}" && \
  git push origin main
```

## Step 7: Report

One-line confirmation back to Luke: Company, Role, Source, slug. No need to recap the JD.
