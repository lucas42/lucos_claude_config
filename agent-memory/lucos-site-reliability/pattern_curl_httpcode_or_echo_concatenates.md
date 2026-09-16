---
name: pattern-curl-httpcode-or-echo-concatenates
description: "`code=$(curl -w '%{http_code}' ... || echo \"000\")` yields 000000 on a refused connection, so a `!= \"000\"` reachability test passes and the probe declares a dead endpoint reachable. Found in lucos_deploy_orb's registry-mirror probe (orb#188) during the 2026-09-15 avalon rebuild."
metadata:
  type: pattern
---

# A `curl -w` probe with an `|| echo` fallback double-prints on failure

`curl -sS -o /dev/null -w '%{http_code}' --max-time 5 URL 2>/dev/null || echo "000"`

On a **refused connection** curl does two things: it prints its own `000` for the failed request via `-w`, *and* it exits non-zero. So the `|| echo "000"` fires as well, and the two concatenate with no separator:

```
$ curl -sS -o /dev/null -w '%{http_code}' http://127.0.0.1:1/ 2>/dev/null || echo "000"
000000
```

A downstream `[ "$CODE" != "000" ]` then reads `"000000" != "000"` as **true**, so the probe reports the endpoint as reachable. The failure surfaces later and less clearly, at whatever step actually uses the endpoint.

**Live instance:** `lucos_deploy_orb` `src/commands/publish-docker.yml`, the "Configure BuildKit registry mirror" step. When `docker.l42.eu` was fully down during the avalon rebuild, the probe logged "Mirror is reachable (HTTP 000000)", `Docker Login (mirror)` then hit a real connection-refused, and the whole build hard-failed instead of falling back to Docker Hub — blocking fresh builds estate-wide. Mechanism and repro by lucos-system-administrator on lucas42/lucos_deploy_orb#188 (which also asks for the login step to fail open); probe code confirmed on `lucos_deploy_orb` `main`.

**Why it hides:** a *degraded* endpoint (502, timeout) returns a real code and the probe behaves correctly. Only a refused connection triggers the double-print, so the bug stays invisible until the endpoint is fully down — which is exactly when the fallback was supposed to save you. Note the failure mode is asymmetric: it only ever produces false *reachable*, never false unreachable.

**How to write it instead:** capture curl's own exit status rather than string-matching its output.

```sh
code=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 5 "$url" 2>/dev/null); rc=$?
[ "$rc" -ne 0 ] && code="unreachable(curl=$rc)"
```

**How to apply:** grep for `-w '%{http_code}'` alongside `|| echo` in any probe, healthcheck, or CI step before trusting its reachability verdict. The same shape appears wherever a command both writes a default value and exits non-zero. Related: [[feedback_verify_check_claim_against_underlying_store]] (read the artefact, not its name) and [[pattern_probe_measures_then_discards_latency]] (a probe that measures something and throws the number away).
