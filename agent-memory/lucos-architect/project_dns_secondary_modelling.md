---
name: project-dns-secondary-modelling
description: DNS secondary modelling review — configy's one-system/one-domain/one-host assumption vs heterogeneous multi-host; ADR lucos#213
metadata:
  type: project
---

# DNS secondary modelling review (2026-06-05)

lucas42 halted the secondary-DNS work (lucos_dns#79, PR lucos_dns#95, configy PR #208) over two modelling problems. I reviewed; both well-founded, one root cause.

**Root cause:** configy assumes **one system → one domain → one host**. Load-bearing in: `lucos_dns/sync/config-sync.py` (`hosts[0]` for the `dns` A record), `/systems/subdomain/{root}` endpoint, and the `domain.is_some() ⇒ hosts.len()<=1` validation invariant. Homogeneous multi-host systems (lucos_firewall, lucos_docker_health) fit because they have **no domain** and run identically per host, keyed only on `HOSTDOMAIN`. DNS secondary is **heterogeneous**: same image, two roles (primary/secondary), two hostnames (dns/dns2.l42.eu), per-host config — the model doesn't support it.

**Why concern #1 (configy PR #208) is right:** gating the invariant on `http_port` couples "speaks HTTP" to "may be multi-homed on a domain" (unrelated). Makes configy data false (asserts lucos_dns serves dns.l42.eu on xwing; xwing serves dns2). Has no functional effect — config-sync uses `hosts[0]` + a **hardcoded `'xwing' in host_domain_lookup` special-case** for dns2 glue, not the hosts list. PR #208 only satisfies the `circleci-system-deploy-jobs` check.

**Why concern #2 (PR #95) is right — fatal flaw:** deploy orb keys the prod envfile on `CIRCLE_PROJECT_REPONAME` (`deploy.yml`: `scp …:$CIRCLE_PROJECT_REPONAME/production/.env`). Both deploy-avalon and deploy-xwing read the SAME `lucos_dns/production/.env`. **Only per-host var injected is `HOSTDOMAIN`** (`export HOSTDOMAIN=<<host-domain>>`) — exactly lucas42's named exception. So `DNS_MODE`/`COMPOSE_PROFILES` differing per host is impossible. `TSIG_SECRET` is fine (same value both sides).

**Recommendation — two systems, one repo, one image:** distinct system codes `lucos_dns` (avalon/dns.l42.eu/primary) + secondary (xwing/dns2.l42.eu), both from lucos_dns repo / lucas42/lucos_dns_bind image. Each gets own creds namespace ⇒ per-host config for free. Restore (don't weaken) the invariant — revert #208's validation change. dns2 becomes a real configy domain ⇒ config-sync drops the xwing hardcode + hosts[0] fragility. Redundancy modelled at DNS protocol layer (two NS, two failure domains).

**Real cost:** one repo can't deploy as two system codes today (creds path is REPONAME-keyed). Needs a new orb `deploy` param (likely `creds-system`, default `CIRCLE_PROJECT_REPONAME`) so the secondary job fetches its own namespace while pulling the shared image. This is why it's an ADR, not a PR fix.

**Alternatives recorded:** (1) role-from-HOSTDOMAIN in one system — no pipeline change but hardcodes topology into image, promotion=image change, leaves dns2 problem; rejected. (2) generalise configy to per-host roles `hosts:[{host,role,domain}]` — most expressive but touches every consumer for a 2-instance case; deferred until a 3rd heterogeneous multi-host system appears.

**Vehicle:** ADR raised at **lucas42/lucos#213** (proposed home lucas42/lucos, sibling to ADR-0003 / lucos#110; flagged configy as alt home). Assessment comment on lucos_dns#79. All three implementation artifacts on hold pending the ADR. Owner: lucos-architect.

Related: [[reference_no_onhost_source_of_truth]], ADR-0003 DNS redundancy (lucos#110), [[project_firewall_rollout]] (firewall is the other multi-host internal-infra consumer of public_ports).
