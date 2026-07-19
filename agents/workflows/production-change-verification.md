# Workflow: production change verification

This workflow runs whenever a teammate makes a change to a production system — stopping or starting containers, removing volumes, modifying config, deploying, restarting services. Owned by `lucos-site-reliability` operationally, but the procedure is general — any persona that touches production should follow it. Substitute your own persona name where this file uses `<persona>`.

Read this file in full before making any production change. The five steps are not optional.

## Why this workflow exists

Production changes routinely surface alerts that look like they were caused by the change but were already there (false positives from stale health checks, orphaned monitoring config). Conversely, real regressions get masked by the noise of an in-progress incident. A baseline-and-compare check catches both: it tells you exactly what your change did to the monitoring picture, with everything else held constant.

## The procedure

1. **Before:** fetch `https://monitoring.l42.eu/api/status` and record the current state as your baseline.

2. **Make the change.** Whatever the actual operation is — container restart, volume swap, config push, deploy.

3. **Wait 2 minutes** for monitoring to pick up the new state. Don't skip the wait — most checks are not real-time.

   A foreground `sleep` is blocked by the harness, so wait one of these two ways instead:
   - **Monitor** with an until-loop that exits on the condition you actually want (preferred — it ends as soon as the state converges): `Monitor({command: 'until curl -sf https://monitoring.l42.eu/api/status | grep -q "<expected>"; do sleep 10; done', ...})`.
   - **Bash with `run_in_background: true`** for a plain timed wait when there's no crisp condition to poll: `sleep 120 && echo waited`.

   Do not chain shorter foreground sleeps to work around the block, and do not skip step 3 because the wait is awkward to express.

4. **After:** fetch monitoring again and compare against your baseline.

5. **If new alerts appeared:** investigate immediately. Your change may have caused a regression (e.g. a health check referencing a removed service, or a downstream consumer that didn't reconnect cleanly). Fix it before moving on. Don't declare the change complete until the alert picture matches the baseline or has been explained.

## What this catches

- False-positive alerts caused by stale health checks or orphaned monitoring config.
- Real regressions introduced by the change (typical: health-check references that survive a service rename or removal).
- Downstream propagation that wasn't visible until the change actually fired.

## Persona-specific extensions

Personas may layer on top:

- **lucos-site-reliability** — incident-response priority order: restore service first, then verify per this workflow, then root-cause, then write the incident report (see [`references/incident-reporting.md`](../../references/incident-reporting.md)).
- **lucos-system-administrator** — additionally re-check `lucos_repos` audit status if the change touched anything that affects estate-wide conventions.

Persona-specific guidance must not contradict the five steps above.
