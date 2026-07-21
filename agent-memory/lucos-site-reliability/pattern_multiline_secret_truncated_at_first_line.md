---
name: pattern-multiline-secret-truncated-at-first-line
description: Diagnosing corrupted multi-line secrets (SSH/PEM) in containers — CRLF-truncation-at-first-line, the docker-inspect first-line measurement artifact, validate-don't-infer, and the false-green when a fixed-length-but-invalid key leaves a cron path dead while monitoring is green
metadata:
  type: reference
---

**Signature:** a multi-line secret (SSH private key, PEM cert) whose stored value is implausibly short, contains exactly **1 CR and 0 LFs**, starts with the PEM header and *ends* at the end of that header line.

That is a **CRLF-formatted secret truncated at its first line break by a line-based `.env` parser** — the `\n` terminated the env var, the `\r` stayed welded to the header, and the rest of the key was silently discarded at write time. Not "the key has stray CRs in it"; the key body is *gone*.

**Measure INSIDE the container, not via `docker inspect` on the host.** ⚠️ `docker inspect --format '{{range .Config.Env}}{{println .}}{{end}}' | grep '^VAR='` only captures the value's **FIRST LINE** — a multi-line env var spills across output lines and the grep keeps line one. So a full 419-byte multi-line key reads as its 35–36-char header, and you will wrongly conclude "truncated". This bit me on #474: I put a wrong "36-char fragment" reading in a GitHub comment because of it. Instead `docker exec` and measure the real value:

```bash
docker exec <container> sh -c 'printenv VAR | wc -c; printenv VAR | wc -l'   # true bytes + lines
docker exec <container> sh -c 'ssh-keygen -l -f /path/to/key'               # VALIDITY, not shape
```

Report length / line count / CR count / **validity** — never the value.

**Length + framing + no-CRs does NOT mean valid.** A key can be full-length, LF-only, with correct `-----BEGIN-----`/`-----END-----` and zero CRs, and STILL be cryptographically invalid (`ssh-keygen -l -f` → "not a key file") — the base64 body was mangled. Never infer validity from length or header/footer; run `ssh-keygen -l -f` (or a test SSH). A "fix" (re-store, line-ending conversion) can swap one corruption (CRLF-truncation) for another (full-length-but-invalid). **Fixing a stored credential is not done until the stored value is validated with the real tool.** Discriminating test for transport-vs-store: check a sibling key on the SAME deploy (e.g. `lucos_creds_ui`'s key) — if it's valid, transport is fine and the specific stored value is corrupt.

**Latency trap (the important bit):** a container only re-reads its env **on recreation**. A secret mangled at write time stays invisible until the next deploy or restart — potentially weeks. So "the job ran successfully recently" does **not** prove the *store* was good recently; it proves the *old container's* copy was good. Don't date the bad write from the last successful run. If the previous container is gone, its env is gone with it, and the write time is genuinely unknowable from the host — hedge it and ask whoever wrote the secret.

**Blast radius is wider than the one service.** A crash-looping container fails `docker compose up --wait`, which fails the CircleCI deploy job, which reds that repo's `circleci` check *and* the host's `docker_health` check. Two red systems, one fault. Check for a shared container before treating simultaneous reds as two incidents.

**False-green while a cron/sync path is dead.** Once the CR-corrupted value was replaced with a full-length-but-invalid one, the container cleared its startup guard and went `running/healthy` — monitoring flipped **all-green** while every sync run still auth-failed (`error in libcrypto` → `Permission denied (publickey)`). Container health ≠ sync working; and the scheduled-job check stayed green because a job that crashes before reporting to schedule-tracker just stops POSTing → forgotten-job green. **Verify cron/sync paths by an actual run outcome (logs / a triggered run / schedule-tracker), never by `/_info` or container health.** Monitor the thing that must change (here: on-disk key *validity*), not a proxy that can read healthy while broken.

**Grounding:** 2026-07-19→22, `lucos_creds_configy_sync` on avalon (lucas42/lucos_creds#474). First state: prod `CONFIGY_SYNC_PRIVATE_SSH_KEY` was CRLF-corrupted → the deploy `.env` parser truncated it at line 1 → crash-loop on the `startup.sh` CR guard (guard from 2026-05-11 fail-closed correctly — a good argument for cheap startup assertions). Second state (after a re-store + line-ending conversion): full-length LF key, correct framing, no CRs, but `ssh-keygen` → "not a key file"; container healthy, monitoring green, sync still dead. `lucos_creds_ui`'s key on the same deploy was valid, proving transport fine. Rotation was required by #471; #471's diff was correct, the stored value was not.

Related: [[pattern-container-restart-log-buffer-artifact]], [[pattern-three-stage-env-var-wiring]], [[feedback-snapshot-indirection]], [[feedback-healthcheck-depth-varies]], [[pattern-reconcile-silent-success-masking]].
