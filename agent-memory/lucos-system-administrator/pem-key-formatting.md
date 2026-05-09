---
name: PEM key formatting for GitHub Actions secrets
description: How to convert lucos_creds space-flattened PEM keys before setting them as GitHub Actions secrets
type: reference
---

PEM keys in lucos_creds (and `~/sandboxes/lucos_agent/.env`) are stored with **newlines replaced by spaces** and wrapped in double quotes. `actions/create-github-app-token@v2` calls `atob()`, which requires valid PEM with actual `\n` characters. Spaces cause `DOMException [InvalidCharacterError]: Invalid character`.

**Python conversion pattern:**
```python
val = val.replace('-----BEGIN RSA PRIVATE KEY----- ', '-----BEGIN RSA PRIVATE KEY-----\n')
val = val.replace(' -----END RSA PRIVATE KEY-----', '\n-----END RSA PRIVATE KEY-----')
parts = val.split('\n')
body = parts[1].replace(' ', '\n')
pem = parts[0] + '\n' + body + '\n' + parts[2]
```

Then encrypt with PyNaCl using the repo's public key (`repos/{owner}/{repo}/actions/secrets/public-key`) and PUT to `repos/{owner}/{repo}/actions/secrets/{SECRET_NAME}`.

Repos affected: lucos_photos and lucos_repos (2026-03-04 and 2026-03-05).

See also the CLAUDE.md section "Setting GitHub Repository Secrets (PEM Keys)" for the full procedure including verification.
