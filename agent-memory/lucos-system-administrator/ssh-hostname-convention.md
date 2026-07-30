---
name: ssh-hostname-convention
description: Production SSH uses *.s.l42.eu hostnames with user lucos-agent — not *.l42.eu, not lucas, not the bare shortname
metadata:
  type: feedback
---

Production hosts are reached via `<host>.s.l42.eu` (e.g. `avalon.s.l42.eu`), **not** `<host>.l42.eu` and **not** the bare shortname (`avalon`).

- `avalon.l42.eu` → NXDOMAIN. The DNS search domain `s.l42.eu` makes the *short* name `avalon` resolve correctly, but the *full FQDN* `avalon.l42.eu` does not exist.
- `avalon` (bare, no domain) → resolves fine (via the DNS search domain) but is a **trap**: `~/.ssh/config` only has a `Host *.s.l42.eu` stanza, which the bare shortname does *not* match. SSH silently falls through to defaults — local shell user (`lucas`) + default key list (`id_rsa`, `id_ecdsa`, `id_ed25519`, none provisioned on the host) — and fails with a convincing `lucas@avalon: Permission denied (publickey)`. This looks exactly like a broken key/access grant on the host side; it isn't — confirm with `ssh -G avalon` vs `ssh -G avalon.s.l42.eu` (compare the `user`/`identityfile` lines) before assuming host-side access is broken.
- Correct full hostname: `avalon.s.l42.eu` (and similarly for other hosts).

**SSH user:** `~/.ssh/config` specifies `User lucos-agent` for `*.s.l42.eu`. Never override with an explicit `user@hostname` using `lucas` or any other username — it bypasses the config and gets rejected.

**Safe pattern:** just `ssh avalon.s.l42.eu` — no explicit username, no bare shortname, let the config apply.

**Why:** The SRE agent used `lucas@avalon.l42.eu` during the 2026-05-30 session degradation investigation and got `Permission denied (publickey)` throughout. Both the hostname and the username were wrong. The SSH key itself was fine. Separately, lucos-architect hit the bare-shortname trap on 2026-07-30 (`ssh avalon` from a fresh instruction, not copied from this memory) — `references/ssh-production.md` used to claim shortname and full domain were "interchangeable", which was false and is now corrected.

**How to apply:** When instructing any agent to SSH to a production host, always give the full `<host>.s.l42.eu` form and omit the username (let `~/.ssh/config` supply `lucos-agent`). See [[hosts-ipv4-nat]] for the NAT/direct-IP distinction.
