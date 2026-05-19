---
name: codeql-dismissal-capability
description: lucos-security can dismiss CodeQL alerts directly via API — confirmed working, no approval workflow enforced
metadata:
  type: reference
---

## CodeQL Alert Dismissal via lucos-security[bot]

**Confirmed 2026-05-19** on lucos_media_metadata_api alert #1 (go/request-forgery, PR #244).

### Permissions
`lucos-security` GitHub App has `security_events: write`, which grants access to:
- `GET /repos/{owner}/{repo}/code-scanning/alerts` — list/read alerts
- `PATCH /repos/{owner}/{repo}/code-scanning/alerts/{number}` — dismiss alerts

### How to query PR alerts
CodeQL analyses on PRs are indexed under `refs/pull/{N}/merge`, **not** the head SHA or `refs/pull/{N}/head`. Always use:
```
GET /repos/{owner}/{repo}/code-scanning/alerts?ref=refs/pull/{N}/merge
```

### How to dismiss
```bash
BODY_FILE=$(mktemp)
cat > "$BODY_FILE" <<'EOF'
{"state":"dismissed","dismissed_reason":"false positive","dismissed_comment":"...max 280 chars..."}
EOF
gh-as-agent --app lucos-security repos/{owner}/{repo}/code-scanning/alerts/{number} \
    --method PATCH \
    --input "$BODY_FILE"
rm "$BODY_FILE"
```

Valid `dismissed_reason` values: `false positive`, `won't fix`, `used in tests`.

**`dismissed_comment` has a 280 character limit.** Keep it tight.

### Approval workflow
`dismissal_approved_by` field is present on alerts but null — **no approval workflow enforced** in the lucos estate as of 2026-05-19. Dismissals take effect immediately.

### Governance note
No documented convention on whether security should self-dismiss. Current practice: dismiss false positives directly when the code has been manually reviewed and the mitigation confirmed in place. Always include a comment pointing to the review (PR comment, issue, etc.) for audit trail.

### Wait for the fix before dismissing
If the alert might be cleared automatically once the code is fixed, wait for the developer to push the fix and re-run CI before dismissing. Dismissing against unfixed code masks whether the fix actually resolved it.
