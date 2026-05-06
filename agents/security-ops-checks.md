# Security Ops Checks

**4 checks total — you MUST run all 4. See the completion manifest at the bottom.**

Check `ops-checks.md` in your agent memory at the start of each run to determine which checks are due. Update it after each check. If a check is skipped because it is not yet due, note this explicitly.

**Duplicate prevention**: Before raising any issue, always search for existing open issues in the target repo that cover the same problem. Also check your memory for previously accepted risks or known issues:

```bash
~/sandboxes/lucos_agent/gh-as-agent --app lucos-security \
  "search/issues?q=repo:lucas42/{repo}+is:issue+is:open+{search_terms}"
```

Also scan the 10 most recent open issues in the target repo to catch issues filed by other agents using different terminology:
```bash
~/sandboxes/lucos_agent/gh-as-agent --app lucos-security \
  "search/issues?q=repo:lucas42/{repo}+is:issue+is:open+sort:created-desc&per_page=10"
```
If you find an existing issue that covers the same root cause, comment on that issue with any new information rather than filing a duplicate.

**One issue per alert — never bundle**: File exactly one GitHub issue per security alert. Never combine multiple unrelated alerts into a single issue. Each alert has its own root cause, its own fix, and its own remediation timeline. The only exception is Check 4 (GitHub Actions audit), which files one issue per repo listing all findings within that repo.

---

## Every Run (2 checks)

### Check 1: Dependabot Alerts

```bash
~/sandboxes/lucos_agent/get-dependabot-alerts
```

The script returns all open dependabot alerts with information about any associated PRs. For each alert:

**If there IS an associated PR with recent activity** (opened or commented on in the last 5 minutes, or any checks have status "in progress"):
- No action needed — skip this alert.

**If there IS an associated PR but it is stalled:**

A PR is stalled if either:
- It has no recent activity (not opened or commented on in the last 5 minutes, and no checks "in progress"), OR
- It has been open for 2+ days with a failing required check and no new commits pushed since the failure (a PR that keeps failing CI is stalled even if Dependabot has recently re-run checks on it)

When a PR is stalled:
1. Check the PR's check runs to identify which check is failing and why. Read the check run output.
2. If it's a simple fix you can handle inline (e.g. re-triggering a flaky check, pushing a trivial fix), do it and comment on the PR.
3. Otherwise, raise an issue on the affected repo describing: the stalled PR number, which check is failing, and what you found in the check output. Do not raise an issue if one already exists for the same stall. Route ownership based on the failure type:
   - **CodeQL / code analysis failure** → `owner:lucos-developer` (fix is typically a code or config change)
   - **CI infrastructure failure** (flaky check, workflow misconfiguration, timeout) → `owner:lucos-site-reliability`
   - **Genuine security concern** with the new dependency version → handle yourself or raise as a security issue
4. If the problem is systemic (e.g. no auto-merge workflow configured for dependabot PRs), raise an issue on that repository (unless one already exists about this).

**If there is NO associated PR:**
- Investigate why (e.g. review dependabot run logs).
- If you can find a reasonable workaround (e.g. adding an override/resolution in package.json), implement it yourself.
- If it's trickier (e.g. need to totally replace a library), raise a ticket on that repository if there isn't already one about it. **Raise one issue per alert — do not bundle.**
- If there's already an issue about the potential fix but it doesn't mention this specific alert, add a comment to the issue explaining it would fix the alert.

---

### Check 2: CodeQL and Secret-Scanning Alerts

```bash
~/sandboxes/lucos_agent/get-security-scanning-alerts
```

The script returns a JSON object with two arrays: `code_scanning` (CodeQL findings) and `secret_scanning` (exposed credentials). Repos where these features are disabled are silently skipped.

**For each CodeQL alert (`code_scanning`):**

**Step 1 — Check for a recently closed prior issue before raising anything.**

Search for closed issues in the same repo that tracked the same alert (by rule ID, alert number, or description). If you find one:

- Read what fix was implemented (check the issue comments and the closing PR).
- Check whether the CodeQL workflow ran *after* the fix was merged:
  ```bash
  ~/sandboxes/lucos_agent/gh-as-agent --app lucos-security \
    "repos/lucas42/{repo}/actions/runs?event=push&per_page=3" \
    --jq '[.workflow_runs[] | select(.name == "CodeQL") | {status, conclusion, created_at}]'
  ```
  Compare the most recent CodeQL run timestamp against the fix merge timestamp. If the scan ran *before* the fix merged, the alert may just be stale — **do not raise a new issue yet**; wait for the next scan or note the pending state.
- If the scan ran *after* the fix merged and the alert is gone: do nothing. Fixed.
- If the scan ran *after* the fix merged and the **alert persists**: read the current code at the flagged location to confirm the mitigation is in place. If it is, this is a confirmed false positive — **dismiss immediately** (see Step 3 below). Do not raise a "wait and see" issue.

**Step 2 — Raise an issue only when no prior fix exists.**

If there is no prior closed issue, or the prior issue was closed but the alert has genuinely re-triggered on unfixed code (no mitigation visible in the current source), raise a new issue. Include the rule ID, severity, affected file/line, and a plain-English explanation of what an attacker could do with it.

- **Raise one issue per CodeQL alert.** Do not bundle multiple CodeQL findings into a single issue.
- Apply the advisory routing decision: most CodeQL findings are not immediately exploitable without other access, so they go as normal public issues. Only escalate to a private advisory if the finding is immediately exploitable by a network-accessible attacker with no prior access (and not yet fixed).

**Step 3 — Dismissal.**

Use the correct `dismissed_reason` depending on the situation:

- **False positive** (mitigation is in place; CodeQL doesn't recognise the custom sanitiser/guard):
  ```bash
  ~/sandboxes/lucos_agent/gh-as-agent --app lucos-security "repos/lucas42/{repo}/code-scanning/alerts/{number}" \
      --method PATCH \
      -f state="dismissed" \
      -f dismissed_reason="false positive" \
      -f dismissed_comment="Mitigation in place — see #{issue_number}. CodeQL does not model the custom sanitiser."
  ```
  Note: dismissed_comment has a **280-character limit** — keep it short.

- **Risk accepted** (tracking issue closed as `not_planned` after conscious decision not to fix):
  ```bash
  ~/sandboxes/lucos_agent/gh-as-agent --app lucos-security "repos/lucas42/{repo}/code-scanning/alerts/{number}" \
      --method PATCH \
      -f state="dismissed" \
      -f dismissed_reason="won't fix" \
      -f dismissed_comment="Risk accepted — see #{issue_number}."
  ```

**If an alert's state is `fixed`:** close its tracking issue as `completed` if it is still open. A fixed alert means CodeQL itself detected the resolution — no manual dismissal needed.

**For each secret-scanning alert (`secret_scanning`):**
- These are always high priority. A `validity: active` token is an emergency — treat it as a potential incident and escalate immediately.
- Check whether an issue already exists tracking this specific alert.
- If not, raise one. Even `validity: inactive` or `validity: unknown` tokens should be rotated and the commit history noted.
- **Raise one issue per secret-scanning alert.** Do not bundle multiple exposed secrets into one issue.
- An active secret that can be used immediately without any other access meets the threshold for a private advisory. Inactive or unknown-validity secrets go as normal public issues.

---

## Monthly (2 checks)

### Check 3: Missing CodeQL Coverage

Check `ops-checks.md` for `codeql-coverage` last_run date; skip if less than a month ago.

Identify repos with supported languages (Python, JavaScript/TypeScript, Java) but no CodeQL workflow. A repo with no SAST coverage is a blind spot — you won't get alerts even if vulnerable code is committed.

**Scope: core lucos estate only.** Exclude forked repositories — these are forks of upstream open source libraries and are maintained externally. Use the `fork` field from the GitHub API to filter them out.

**CodeQL supported languages (exhaustive list):** C/C++, C#, Go, Java/Kotlin, JavaScript/TypeScript, Python, Ruby, Swift. Do NOT raise CodeQL coverage issues for any other language — PHP in particular is not supported. If a repo's primary language is unsupported, skip it silently.

```bash
~/sandboxes/lucos_agent/gh-as-agent --app lucos-security \
  "/users/lucas42/repos?per_page=100" --jq '[.[] | select(.archived == false and .fork == false) | .name]'
```

For each active non-fork repo, check whether `.github/workflows/codeql-analysis.yml` (or equivalent) exists. Also check the primary language via the repo metadata (`language` field). Raise an issue on any repo that has Python, JavaScript, TypeScript, or Java as a primary language but lacks a CodeQL workflow — unless an issue already exists requesting it.

After completing, update `codeql-coverage` in `ops-checks.md` with today's date.

---

### Check 4: GitHub Actions Workflow Audit

Check `ops-checks.md` for `github-actions-audit` last_run date; skip if less than a month ago.

**Scope: core lucos estate only.** Exclude forked repositories — these are forks of upstream open source libraries maintained externally and are not in scope. Filter using `select(.archived == false and .fork == false)` when fetching the repo list.

For each active non-fork lucas42 repo, fetch `.github/workflows/*.yml` and check for:

1. **Unpinned third-party actions** — any `uses:` reference to a non-GitHub-owned action (i.e. not `actions/*`, `github/*`) that uses a mutable tag (e.g. `v1`, `main`, `latest`) rather than a full commit SHA. Mutable tags are a supply chain risk: the tag can be silently repointed to malicious code.
2. **Overly broad permissions** — workflows that omit the top-level `permissions` key entirely (GitHub defaults to broad read-write for the `GITHUB_TOKEN`) or grant more than the job actually needs.
3. **Secrets passed to untrusted contexts** — workflows that pass repository secrets (via `secrets.*`, `env:`, or `-e` flags) to steps running third-party actions or user-supplied code (e.g. PR branch code, `run:` steps that consume untrusted input).

**Severity:**
- Default: **P3** (supply chain hygiene, defence in depth)
- **P2** if a repository secret is being passed to an unpinned third-party action — that's an actual credential-exfiltration path

**Issue format:** raise **one issue per repo** (not per finding), listing all findings found in that repo. Do not raise an issue for a repo that has no findings.

After completing, update `github-actions-audit` in `ops-checks.md` with today's date.

---

## Frequency Tracking

Track last run dates in `ops-checks.md`:

```
dependabot_alerts: YYYY-MM-DD
codeql_secret_scanning: YYYY-MM-DD
codeql_coverage: YYYY-MM-DD
github_actions_audit: YYYY-MM-DD
```

Checks 1 and 2 run every time. Checks 3 and 4 run monthly.

---

## Completion Manifest

After completing your ops checks run, output a table like this:

| Check | Frequency | Status | Notes |
|---|---|---|---|
| 1. Dependabot Alerts | Every run | Done | N alerts reviewed, N actions taken |
| 2. CodeQL & Secret-Scanning | Every run | Done | N code_scanning, N secret_scanning alerts reviewed |
| 3. Missing CodeQL Coverage | Monthly | Done / Skipped (not due) | — |
| 4. GitHub Actions Workflow Audit | Monthly | Done / Skipped (not due) | — |

**Do not skip any row in this table.** If a check was not run, say why ("not due — last run YYYY-MM-DD"). This table is the audit trail that confirms all 4 checks were considered.
