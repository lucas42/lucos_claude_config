---
name: bash-command-substitution-strips-trailing-newline
description: bash $(cat file) silently drops trailing newlines — corrupted an SSH private key written to lucos_creds via SSH exec
metadata:
  type: project
---

Bash command substitution (`$(...)`) unconditionally strips *trailing* newlines from its output, no matter how it's invoked (`$(cat file)`, `$(ssh ...)`, etc.). Internal newlines are untouched — only the tail is trimmed.

**Why this matters:** OpenSSH-format private keys end with `-----END OPENSSH PRIVATE KEY-----\n`. Building an SSH-exec-write argument like `PRIVKEY=$(cat file); ssh ... "KEY=$PRIVKEY"` silently drops that final `\n`. The stored value is still full-length and looks structurally intact (right header/footer, same char count minus one), so a casual diff or length check misses it. But `ssh-keygen -l -f` reports "not a key file", and a real SSH client refuses to load it locally (`Load key: error in libcrypto`) *before* ever reaching the server — presenting as "wrong/revoked key" rather than a formatting bug.

**Confirmed root cause of lucos_creds#474**: I generated a valid keypair for lucos_creds#458/#471, wrote the private key to `lucos_creds/development/CONFIGY_SYNC_PRIVATE_SSH_KEY` using exactly this `$(cat file)` pattern (which [[github-app-secrets-provisioning]]'s prior text incorrectly endorsed as safe — corrected in that file 2026-07-22), and it silently corrupted the key. Went undetected because my #471 verification only checked "does the stored value match modulo a trailing newline" and treated that as harmless — it isn't, for this failure mode.

**Fix pattern — never build a byte-exact secret argument through a bash variable.** Read the file in binary mode in Python and pass it directly as a `subprocess.run([...])` list argv element (no shell, no `$()`):
```python
with open(path, 'rb') as f:
    key_bytes = f.read()
cmd = f"{system}/{environment}/{KEY}=".encode() + key_bytes
subprocess.run(["ssh", "-p", "2202", "creds.l42.eu", cmd.decode()], check=True)
```

**Verification must include a load test, not just a string/length compare.** `ssh-keygen -l -f <file>` returning a real `SHA256:...` fingerprint (not "not a key file") is the check that actually catches this class of corruption. A byte-length-modulo-one diff is *not* automatically harmless — prove it with the tool that will actually consume the value.

See also [[github-app-secrets-provisioning]] for the corrected reference-file text and the related PEM-flattening corruption class (a different mechanism, same "looks fine, doesn't parse" symptom).
