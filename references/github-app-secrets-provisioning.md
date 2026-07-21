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

## The same corruption class also hits lucos_creds-stored App PEMs

The "space-flattened PEM" failure mode isn't unique to repo secrets — it can also land in a `GITHUB_APP_PEM` stored directly in lucos_creds (e.g. a service's own dev/prod credentials for authenticating as a GitHub App, distinct from the CI Dependabot secrets above). Confirmed on `lucos_repos/development/GITHUB_APP_PEM` (lucas42/lucos_repos#456, 2026-07-11): every newline had been replaced with a single space before storage, leaving a syntactically PEM-shaped but unparseable value. Symptom at the consuming service was a **live GitHub API 401** (`GitHub API returned 401 fetching installations`) rather than a local parse error — a malformed/garbage JWT still gets sent and GitHub rejects it with 401, which reads identically to "wrong/rotated key." Don't assume 401 means the key is stale; check formatting first.

**Diagnose:** fetch the `.env` via `scp -P 2202 "creds.l42.eu:<system>/<environment>/.env" .` (read-only; write access needs SSH exec — see below), extract the quoted `GITHUB_APP_PEM` value with the same `re.DOTALL` pattern as above, and check for real newlines (`pem.count('\n')`) vs. spaces at regular ~64-char intervals. Regularly-spaced single spaces (not scattered) is the signature of flattening — the base64 body itself is usually intact.

**Reconstruct, don't regenerate:** if the corruption is pure newline-flattening, the key material is still valid — do not ask the App owner to regenerate a private key. Split out the header/footer (`-----BEGIN ...-----` / `-----END ...-----`, which themselves contain legitimate internal spaces between words — don't blindly replace *every* space) and restore newlines only in the base64 body. Verify with `openssl rsa -in <file> -check -noout`.

**Verify the fix is actually correct — don't stop at "openssl parses it."** A syntactically valid PEM can still be a stale/wrong key. Mint a real JWT (`PyJWT` + the app's numeric ID as `iss`) and call `GET https://api.github.com/app` (confirms App ID + key match) and `GET https://api.github.com/app/installations` (confirms the exact call path the failing service makes at startup) — a live 200 is the only real proof. Both `cryptography` and `PyJWT` were already available in the sandbox's system Python, no install needed.

**Writing the fix back to lucos_creds:** SSH exec write (`ssh -p 2202 creds.l42.eu "<system>/<environment>/<KEY>=<value>"`) preserves real embedded newlines correctly when the value is passed as a single shell argument containing literal `\n` bytes. No special escaping needed; don't hand-flatten the PEM to fit it "on one line" — that's what caused this in the first place.

**CORRECTED (2026-07-22, lucos_creds#474): do NOT build that argument via bash `$(cat file)` or any other command substitution.** Command substitution unconditionally strips *trailing* newlines from its output — internal newlines survive, but a key's final `\n` (e.g. right after `-----END OPENSSH PRIVATE KEY-----`) silently vanishes. The stored value then looks intact (right length, right header/footer, `openssl ... -check` on an RSA PEM may not even notice) but `ssh-keygen -l -f` reports "not a key file" on an OpenSSH-format key, and a real SSH client refuses to load it locally (`Load key: error in libcrypto`) before ever reaching the server — masquerading as a "wrong/revoked key" auth failure. This is exactly how the `lucos_creds_configy_sync` key got corrupted after #471. **Byte-safe alternative:** read the file in binary mode and pass it to `subprocess.run([...])` (list form, no shell) as a literal argv element, e.g.:
```python
with open(path, 'rb') as f:
    key_bytes = f.read()
cmd = f"{system}/{environment}/{KEY}=".encode() + key_bytes
subprocess.run(["ssh", "-p", "2202", "creds.l42.eu", cmd.decode()], check=True)
```
Then always re-fetch and confirm `ssh-keygen -l -f` returns a real fingerprint (or `openssl rsa -check` for RSA PEMs) — don't just diff string content, since a length-1 discrepancy is easy to miss by eye.

**Clean up key material afterwards** — `shred -u` any temp files holding the extracted PEM once verification is done; this is a live App's private key, not a disposable scratch value.

**Scope limit:** agents can only read/write the `development` environment. If the same corruption is suspected in `production`, it must be checked and fixed by lucas42 directly — flag it, don't assume prod inherited the same bug just because dev had it (they may have been set through different processes).

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
