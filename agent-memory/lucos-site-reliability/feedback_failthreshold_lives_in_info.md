---
name: checks (not just thresholds) live in /_info, not lucos_monitoring
description: Per-system checks — declaration, `ok` evaluation, thresholds, failThreshold, dependsOn — all live in the service's own `/_info`. lucos_monitoring is a polling/aggregation layer with no system-specific logic except three synthetic cross-cutting checks.
type: feedback
---

Per-system checks belong **entirely** in the service's own `/_info` response, not in lucos_monitoring config. lucos_monitoring is a polling/aggregation layer — it holds no system-specific logic, no per-system thresholds, and no per-system `ok` evaluation. Each service declares both:

- its **metrics** in `/_info.metrics` (raw values + `techDetail`), and
- its **checks** in `/_info.checks` (`ok: bool` already evaluated by the service's own handler, plus `techDetail`, optional `failThreshold`, optional `dependsOn`).

lucos_monitoring just polls `/_info`, reports `ok: false` as alerts, and applies `failThreshold` / `dependsOn` suppression per what the `/_info` itself declared. The check's *evaluation logic*, *threshold value*, and *suppression policy* are all the service's own — none of them are configurable from lucos_monitoring's side.

**Why I keep getting this wrong:**

Two distinct corrections from lucas42:

- 2026-05-05: I proposed raising a `failThreshold` issue against lucos_monitoring. lucas42: "the failThreshold config comes from the /_info endpoint, so it'll need to be raised against [the service] — we don't hold any system-specific logic in lucos_monitoring." That corrected the *threshold* layering — the original wording of this memory.
- 2026-05-22: I filed `lucos_loganne#484` with a section titled "Proposed monitoring-side check" — i.e. I put the *entire check evaluation* on the wrong layer, not just the threshold. lucas42 (via team-lead): "The framing of lucos_loganne#484 is wrong. lucos_monitoring doesn't hold per-system check config. Those need to be exposed as checks in `/_info`, not just metrics." That corrected the *check itself* layering.

The second correction generalises the first: the principle isn't just about thresholds, it's about *anything system-specific in the monitoring path*.

**How to apply:**

When proposing any per-system observability or alerting change, decide layering by this question: *is this signal specific to the service, or is it a generic cross-cutting probe?*

- **Service-specific signal** (anything that names the service's internal state, its data model, its own thresholds, etc.) → declare it in the service's own `/_info`, as both a metric (raw value) and a check (`ok` evaluated against the threshold inside the service's `/_info` handler). The issue goes against the **service repo**.
- **Generic cross-cutting probe** (something that applies identically to *every* monitored system regardless of what it does) → goes in lucos_monitoring. The current three are `fetch-info`, `tls-certificate`, `circleci`. The issue goes against **`lucos_monitoring`**.

The shape of a service-side check in `/_info`:

```json
{
  "checks": {
    "my-check-name": {
      "ok": true,
      "techDetail": "Latest value 42 vs threshold 100",
      "failThreshold": 2,
      "dependsOn": "lucos_some_dependency"
    }
  }
}
```

The `ok` field is evaluated by the service's `/_info` handler against whatever logic it likes — threshold comparison, set-membership, recent-error-rate, etc. lucos_monitoring just receives the boolean.

**Exception — monitoring-synthesised checks:** Three checks are NOT declared by services; lucos_monitoring stamps them onto every system itself: `fetch-info` and `tls-certificate` (in `src/fetcher_info.erl` lines 43-46) and `circleci` (in `src/fetcher_circleci.erl`). For these three names, `failThreshold` IS configured inside lucos_monitoring — the in-file precedent is the existing `maps:put(<<"failThreshold">>, 2, ...)` pattern. PR lucos_monitoring#195 added it for fetch-info/tls-certificate; the same shape applies to circleci (issue #226 2026-05-12).

**Exception — monitoring-generated synthetic checks:** Three checks are NOT declared by services; lucos_monitoring stamps them onto every system itself: `fetch-info` and `tls-certificate` (in `src/fetcher_info.erl` lines 43-46) and `circleci` (in `src/fetcher_circleci.erl`). For these three names, `failThreshold` IS configured inside lucos_monitoring — the in-file precedent is the existing `maps:put(<<"failThreshold">>, 2, ...)` pattern. PR lucos_monitoring#195 added it for fetch-info/tls-certificate; the same shape applies to circleci (issue #226 2026-05-12).

**The pre-filing check — DO NOT SKIP:** Before drafting any "raise failThreshold on `X-check`" issue, run both of these:

1. `curl -s https://<service>.l42.eu/_info | jq '.checks | keys'` — does the service declare it?
2. `grep -n '<<\"X-check\">>' ~/sandboxes/lucos_monitoring/src/fetcher_*.erl` — does monitoring synthesise it?

If (1) is yes → file on the service repo. If (2) is yes and (1) is no → file on `lucos_monitoring` and cite the existing `fetcher_info.erl` precedent. If both are no, you've misnamed something. Skipping this on 2026-05-12 led to lucos_monitoring#226 getting rejected with "completely misunderstands the model" — the original body conflated the two populations and falsely implied services could override the circleci check.

**Related fix-shape rule:** When a service-specific check is flapping during a known-good transient state, the cleanest fix is usually inside the service's `/_info` handler — refining the check's `ok` semantics so that the transient state isn't reported as a fault in the first place. Example (lucos_media_manager#239): `empty-queue` reports `ok: true` while a fetcher thread is alive, because "queue is empty but being repopulated" is intended behaviour. Smaller diff than tweaking thresholds, doesn't mask real faults.
