# SRE — Operational defaults

Investigation-and-debugging defaults for `lucos-site-reliability`. Read on demand when diagnosing an incident or investigating a runtime symptom.

## Diagnostic order during an incident

When something is wrong, work in this order:

1. **Logs** — `docker compose logs --tail=100 <service>`.
2. **`/_info` endpoints** on the affected service.
3. **Recent Loganne events** to identify recent deployments or data changes that may correlate.
4. **Container health** (`docker ps`, healthcheck output).

Fetch recent Loganne events with:

```bash
source ~/sandboxes/lucos_agent/.env && \
  curl -s -H "Authorization: Bearer $KEY_LUCOS_LOGANNE" "https://loganne.l42.eu/events"
```

## Investigating missing env vars in a container

The chain from a secret to a running container has **four** links, and any one of them can independently be the gap:

1. **lucos_creds** holds the value per environment (development / production).
2. **CI build / scp** writes the `.env` file into the deployment directory at deploy time.
3. **`docker-compose.yml`** must reference the var (typically as a bare name under `environment:`) so the compose env-file → container-env passthrough fires.
4. **Container** sees the var at runtime.

When you observe link 4 is empty (`docker exec printenv NAME` returns empty), **verify all the preceding links before concluding which one is the gap** — never jump from "container env empty" straight to "lucos_creds is missing the value". The most common cause of an empty link 4 is actually link 3 (var not in `docker-compose.yml`'s `environment:` block), not link 1 — and a missing link 3 is a code-repo change anyone can do via PR, whereas a missing link 1 needs lucas42 to write a production credential. Misrouting these wastes a creds-write ask.

Diagnostic sequence:

1. **Container env (link 4):** `ssh <host> "docker exec <name> sh -c 'echo \${VAR_NAME:+set} \${#VAR_NAME}'"` (avoid printing the value).
2. **Compose passthrough (link 3):** `grep VAR_NAME ~/sandboxes/<service>/docker-compose.yml`. If the var is not listed under `environment:`, this is the gap — file a one-line PR to add it. **Stop here.**
3. **.env at deploy time (link 2):** harder to inspect directly; usually inferable from CI build logs. If link 3 is fine and link 1 is fine but link 4 is still empty, this is the next place to look.
4. **lucos_creds (link 1):** only conclude this is the gap when 2 and 3 have been verified present. Writing production creds requires lucas42 — so be sure before routing there.

The same fix-once-fail-everywhere pattern lives in the [pattern_three_stage_env_var_wiring.md](../agent-memory/lucos-site-reliability/pattern_three_stage_env_var_wiring.md) memory; use this as the live checklist when symptoms match.

## Investigating "which lucos service is sending these requests?"

Read the `User-Agent` header in the receiver's access logs **before** forming any hypothesis about the client. Indirect cues — env var names, URL-joining-style guesses, "which container is hosting this binary" — are easy to over-fit and produce a confident-but-wrong guess. The user-agent is direct evidence and rules out wrong suspects in seconds.

ADR-0001 (`lucas42/lucos/docs/adr/0001-user-agent-strings-for-inter-system-http-requests.md`) requires lucos services to identify themselves by system name in their user-agent, so a bare runtime name (`node`, `python-requests/X.Y`, `Go-http-client`) is itself a compliance gap worth flagging.

**Broader rule:** read the direct evidence first (user-agent, request body, stack trace, actual config value, response headers) before reasoning from circumstantial cues.

## Investigating "deployed code doesn't behave as expected"

A code change is in source / git / container, but runtime behaviour proves it isn't running. Before forming any elaborate hypothesis about minifier optimisations, build caches, service-worker staleness, or other complex causes:

**Verify the file containing the change is actually reachable from a live entry point.** Read the imports/exports/call chain end-to-end from the application's entry. Bundlers (webpack, esbuild, rollup, vite, etc.) silently drop unreachable code regardless of whether the source map shows the original file.

A common failure mode in lucos: two implementations of the same component live side by side (e.g. `web-player.js` vs `audio-element-player.js` in `lucos_media_seinn`), and the change was made to the unused one. Bit me 2026-05-06 on `lucas42/lucos#126`.

## When raising or filing a GitHub issue

- Be technically specific.
- Include reproduction steps or observed symptoms.
- Suggest a direction for the fix.
- Never silently work around a problem — always document it.

When you make a direct fix commit, follow it immediately with a GitHub issue or comment documenting what happened and why.
