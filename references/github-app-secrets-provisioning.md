# GitHub App secrets — provisioning and verification

How to set GitHub App private keys (PEM secrets) on lucas42 repositories, and how to verify they are actually working after provisioning. Owned by `lucos-system-administrator` operationally — but the gotchas matter to anyone touching CI app tokens.

## Setting GitHub Repository Secrets (PEM keys)

When setting secrets that contain PEM private keys (e.g. `CODE_REVIEWER_PRIVATE_KEY`), the key must have **real newlines** — not the space-flattened format used by lucos_creds. lucos_creds stores PEM keys with newlines replaced by spaces and wrapped in double quotes. The `actions/create-github-app-token@v2` action (and most consumers) need a properly-formatted PEM with actual `\n` characters.

Conversion procedure:

1. Extract the PEM using Python — **do not use `grep | cut -d'"' -f2`**, which only returns the first line of a multiline value and silently truncates the key to just the header:

```python
import re, json

with open('/home/lucas.linux/sandboxes/lucos_agent/.env', 'r') as f:
    content = f.read()

# Handles both real-newline and space-flattened PEM formats
match = re.search(r'LUCOS_CI_PEM="((?:[^"\\]|\\.)*)"', content, re.DOTALL)
pem = match.group(1)
# If space-flattened (spaces instead of newlines in body), convert:
# pem = pem.replace(' ', '\n')  # only if needed — verify first
print(f"Length: {len(pem)}, newlines: {pem.count(chr(10))}")
print(pem[:50])
```

2. Verify: must start with `-----BEGIN RSA PRIVATE KEY-----`, end with `-----END RSA PRIVATE KEY-----`, and have 20+ newlines. A 32-char result means only the header was extracted — re-extract.
3. Encrypt using the repo's libsodium public key (PyNaCl) and set via the GitHub API:

```python
from nacl.encoding import Base64Encoder
from nacl.public import PublicKey, SealedBox

pub_key = PublicKey(repo_pub_key_b64, encoder=Base64Encoder)
encrypted = SealedBox(pub_key).encrypt(pem.encode('utf-8'), encoder=Base64Encoder)
# PUT to repos/lucas42/{repo}/actions/secrets/LUCOS_CI_PRIVATE_KEY
# with {"encrypted_value": encrypted.decode(), "key_id": key_id}
```

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
