---
name: incident-2026-06-07-dns-outage
description: lucos_dns 15-min estate-wide outage — BIND restarted against invalid generated zone (dns2 CNAME+A conflict); lessons for future DNS ops
metadata:
  type: project
---

## Incident: 2026-06-07 estate-wide DNS outage (~23:33–23:48Z)

**Root cause**: Old config-sync.py generated a broken l42.eu zone (dns2 appeared as both `A 178.32.218.44` hardcoded AND `CNAME xwing.s` from the generic system loop). BIND refused the apex zone on restart. No in-memory fallback.

**Trigger**: PR #102 deploy restarted BIND containers; the stale zone file was in the `generatedzones` volume.

**Recovery**: Forced `docker exec lucos_dns_sync python /app/config-sync.py` to regenerate the valid zone; BIND reloaded. PR #103 (TSIG key-name fix) deployed cleanly after.

## Key lessons for future DNS ops

**BIND restart risk**: Until lucos_dns#104 (validate-before-install guard) ships, ANY avalon BIND restart is high-risk if the generated zone files haven't been validated with `named-checkzone`. Always run `docker exec lucos_dns_bind named-checkzone <zone> <file>` before triggering a restart or redeploy.

**rndc unusable in container during incident**: The rndc key regenerates on each fresh container start (stored in the volume but key material changes). If rndc gives "bad auth", fall back to `docker kill --signal SIGHUP lucos_dns_bind` to reload zones without restarting the container.

**Circular failure (filed as #106)**: config-sync defaults to `CONFIGY_ENDPOINT=https://configy.l42.eu`. When l42.eu DNS is down, configy.l42.eu can't resolve → config-sync can't regenerate the zone → DNS stays down. Workaround: `docker exec lucos_dns_sync python /app/config-sync.py` manually. Fix: set `CONFIGY_ENDPOINT=http://lucos_configy:8034` in docker-compose.yml.

**CNAME+A conflict pattern**: If a subdomain can appear in multiple codepaths (hardcoded branch + generic system loop), both may fire simultaneously and generate incompatible record types. Zone loads silently in memory but fails hard on restart. Check with named-checkzone after any config-sync code changes.

**Why**: SRE incident report at lucas42/lucos blob/main/docs/incidents/2026-06-07-estate-wide-dns-outage.md
