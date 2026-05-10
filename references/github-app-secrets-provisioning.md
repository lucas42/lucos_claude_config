# GitHub App secrets — provisioning and verification

How to set GitHub App private keys (PEM secrets) on lucas42 repositories, and how to verify they are actually working after provisioning. Owned by `lucos-system-administrator` operationally — but the gotchas matter to anyone touching CI app tokens.

## Setting GitHub Repository Secrets (PEM keys)

When setting secrets that contain PEM private keys (e.g. `CODE_REVIEWER_PRIVATE_KEY`), the key must have **real newlines** — not the space-flattened format used by lucos_creds. lucos_creds stores PEM keys with newlines replaced by spaces and wrapped in double quotes. The `actions/create-github-app-token@v2` action (and most consumers) need a properly-formatted PEM with actual `\n` characters.

Conversion procedure:

1. Source the key from `~/sandboxes/lucos_agent/.env` (variable name follows `LUCOS_{APP_NAME}_PEM`, e.g. `LUCOS_CODE_REVIEWER_PEM`).
2. Convert spaces back to newlines: `echo "$LUCOS_CODE_REVIEWER_PEM" | tr ' ' '\n'`.
3. Verify the result starts with `-----BEGIN RSA PRIVATE KEY-----` and ends with `-----END RSA PRIVATE KEY-----`, with base64 content on separate lines between them.
4. Encrypt using the repo's libsodium public key and set via the GitHub API.

**Do not** store the space-flattened format directly as a repository secret — it will cause `InvalidCharacterError` in the `atob()` call during token generation.

## Post-provisioning verification: Dependabot secrets

**After provisioning any Dependabot secrets (`LUCOS_CI_APP_ID`, `LUCOS_CI_PRIVATE_KEY`, etc.), verify that the values are non-empty — not just that the names are present.** The GitHub secrets API never exposes secret values. The `lucos_repos` convention check only verifies name presence. A secret set with an empty value (e.g. due to an unset env var during provisioning) will pass both checks while silently causing every Dependabot auto-merge to fall back to `GITHUB_TOKEN`. Happened 2026-04-21 (lucos_creds, lucos_agent).

Verification procedure:

1. Wait for the next Dependabot PR to trigger `dependabot-auto-merge.yml` on each provisioned repo, **or** manually trigger a test PR.
2. In the workflow run logs, check the "Generate GitHub App token" step:
   - **`success`** → secret values are non-empty and valid. ✓
   - **`skipped`** → secret values are empty. The "Check if App token secrets are available" step output `has_app_token=false`. Re-provision with correct values immediately.
3. Do not close or report provisioning as complete until at least one repo shows `success` (not `skipped`) on the token generation step.

**Why `skipped` means empty:** the reusable workflow checks `[ -n "$APP_ID" ] && [ -n "$APP_KEY" ]` and sets `has_app_token=false` if either is empty. The subsequent token generation step is conditional on `has_app_token == 'true'`. A name-only provisioning pass will always look clean until a real workflow run exposes it.

## Why this is its own reference

Both sections describe operational gotchas that are easy to get wrong silently — a mis-formatted PEM or an empty-valued secret will pass every visible check while breaking auto-merge. Keeping the procedures together (rather than scattered across persona files) means the next person provisioning these secrets — agent or human — finds both the "set it" and "verify it actually works" steps in one place.
