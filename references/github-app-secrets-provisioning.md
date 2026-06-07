# GitHub App secrets — provisioning and verification

How to set GitHub App private keys (PEM secrets) on lucas42 repositories, and how to verify they are actually working after provisioning. Owned by `lucos-system-administrator` operationally — but the gotchas matter to anyone touching CI app tokens.

## Setting GitHub Repository Secrets (PEM keys)

**Use the provisioning script** — `~/.claude/scripts/provision-repo-ci-secrets.sh <repo-name>`. This sets both `LUCOS_CI_APP_ID` and `LUCOS_CI_PRIVATE_KEY` correctly in one step and is mechanically safe. Run it instead of constructing the API calls by hand.

```bash
~/.claude/scripts/provision-repo-ci-secrets.sh lucos_dns_secondary
```

**Why the script exists:** `grep | cut -d'"' -f2` silently truncates multiline values to the first line. The PEM private key spans ~27 lines; `cut` returns only the 32-char header (`-----BEGIN RSA PRIVATE KEY-----`). The secret is then non-empty (so `has_app_token=true` and the token step runs) but invalid (PEM can't be parsed → step `failure`). The script uses Python with `re.DOTALL` which handles multiline values correctly, and includes a sanity check (20+ newlines) before touching any API.

**Manual procedure (if script can't be used):**

1. Extract the PEM with Python — `re.search(r'LUCOS_CI_PEM="((?:[^"\\]|\\.)*)"', content, re.DOTALL)` — never `grep | cut`.
2. Verify: 1600+ chars, 20+ newlines, starts with `-----BEGIN RSA PRIVATE KEY-----`.
3. Encrypt with PyNaCl `SealedBox` against the repo's public key; PUT to the secrets API.

**Do not** store a truncated or space-flattened PEM as a repository secret — a truncated key causes `failure` on the token generation step (non-empty but invalid); space-flattened causes `InvalidCharacterError`.

## Post-provisioning verification: Dependabot secrets

**After provisioning any Dependabot secrets (`LUCOS_CI_APP_ID`, `LUCOS_CI_PRIVATE_KEY`, etc.), verify that the values are non-empty — not just that the names are present.** The GitHub secrets API never exposes secret values. The `lucos_repos` convention check only verifies name presence. A secret set with an empty value (e.g. due to an unset env var during provisioning) will pass both checks while silently causing every Dependabot auto-merge to fall back to `GITHUB_TOKEN`. Happened 2026-04-21 (lucos_creds, lucos_agent).

Verification procedure:

1. Wait for the next Dependabot PR to trigger `dependabot-auto-merge.yml` on each provisioned repo, **or** manually trigger a test PR.
2. In the workflow run logs, check the "Generate GitHub App token" step:
   - **`success`** → secret values are non-empty and valid. ✓
   - **`skipped`** → secret values are empty (`has_app_token=false`). Re-provision with correct values immediately.
   - **`failure`** → secret values are non-empty but **malformed** — typically a truncated PEM (only the header line was set) or a space-flattened PEM. Re-provision using the Python extraction procedure above.
3. Do not close or report provisioning as complete until at least one repo shows `success` (not `skipped` or `failure`) on the token generation step.

**Why `skipped` means empty:** the reusable workflow checks `[ -n "$APP_ID" ] && [ -n "$APP_KEY" ]` and sets `has_app_token=false` if either is empty. A name-only provisioning pass always looks clean until a real workflow run exposes it.

**Why `failure` means malformed (not missing):** the step runs but the PEM can't be parsed — most likely `grep | cut` truncation (only the 32-char header) or space-flattened format. Use Python extraction to fix.

## Why this is its own reference

Both sections describe operational gotchas that are easy to get wrong silently — a mis-formatted PEM or an empty-valued secret will pass every visible check while breaking auto-merge. Keeping the procedures together (rather than scattered across persona files) means the next person provisioning these secrets — agent or human — finds both the "set it" and "verify it actually works" steps in one place.
