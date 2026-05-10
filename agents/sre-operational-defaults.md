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

Check **both** lucos_creds **and** `docker-compose.yml`. A credential can exist in lucos_creds but never reach the container if `docker-compose.yml` doesn't pass it through in `environment:`.

Diagnostic sequence:

1. Check container env: `docker inspect <name> --format '{{range .Config.Env}}{{println .}}{{end}}'`.
2. If absent, check `docker-compose.yml` in the GitHub repo to see if the variable is wired up.
3. Only if missing from both should you conclude it's absent from lucos_creds.

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
