---
name: pattern-multiline-secret-truncated-at-first-line
description: A multi-line secret whose stored value is short, CR-terminated and stops at the header line = CRLF key truncated by a line-based .env parser at write time; surfaces only on container recreation
metadata:
  type: reference
---

**Signature:** a multi-line secret (SSH private key, PEM cert) whose stored value is implausibly short, contains exactly **1 CR and 0 LFs**, starts with the PEM header and *ends* at the end of that header line.

That is a **CRLF-formatted secret truncated at its first line break by a line-based `.env` parser** — the `\n` terminated the env var, the `\r` stayed welded to the header, and the rest of the key was silently discarded at write time. Not "the key has stray CRs in it"; the key body is *gone*.

**Measure, don't print.** Diagnose without dumping key material:

```bash
docker inspect <container> --format '{{range .Config.Env}}{{println .}}{{end}}' \
  | grep '^<VAR>=' | python3 -c "…print(len(v), chr(13) in v, v.count(chr(10)), v[:30])"
```

Report length / CR count / LF count / header-match — never the value.

**Latency trap (the important bit):** a container only re-reads its env **on recreation**. A secret mangled at write time stays invisible until the next deploy or restart — potentially weeks. So "the job ran successfully recently" does **not** prove the *store* was good recently; it proves the *old container's* copy was good. Don't date the bad write from the last successful run. If the previous container is gone, its env is gone with it, and the write time is genuinely unknowable from the host — hedge it and ask whoever wrote the secret.

**Blast radius is wider than the one service.** A crash-looping container fails `docker compose up --wait`, which fails the CircleCI deploy job, which reds that repo's `circleci` check *and* the host's `docker_health` check. Two red systems, one fault. Check for a shared container before treating simultaneous reds as two incidents.

**Grounding:** 2026-07-19, `lucos_creds_configy_sync` on avalon (lucas42/lucos_creds#474). Prod `CONFIGY_SYNC_PRIVATE_SSH_KEY` stored as 36 chars — header + CR only. Rotation was required by lucas42/lucos_creds#471; #471's diff was correct, the stored value was not. The `startup.sh` CR guard (from 2026-05-11) fail-closed correctly and made this trivial to diagnose — a good argument for cheap startup assertions on secret shape.

Related: [[pattern-container-restart-log-buffer-artifact]], [[pattern-three-stage-env-var-wiring]], [[feedback-snapshot-indirection]].
