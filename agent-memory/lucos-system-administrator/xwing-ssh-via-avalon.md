---
name: xwing-ssh-via-avalon
description: Sandbox runs on xwing — direct SSH to xwing fails; must jump via avalon
metadata:
  type: feedback
---

The coding sandbox runs ON xwing (outgoing IP = 152.37.104.10 = xwing's own public NAT IP). Direct `ssh xwing.s.l42.eu` fails with "Not allowed at this time" — the host blocks connections from its own public IP.

**Fix:** Use avalon as a jump host:
```bash
ssh -J avalon.s.l42.eu xwing.s.l42.eu "<command>"
```

For salvare (IPv6-only, no direct IPv4): jump via xwing:
```bash
ssh -J xwing.s.l42.eu salvare.s.l42.eu "<command>"
```

Since xwing direct is broken, reach salvare through avalon→xwing if needed:
```bash
ssh -J avalon.s.l42.eu,xwing.s.l42.eu salvare.s.l42.eu "<command>"
```

**Why:** Discovered 2026-06-11 when attempting `docker image prune` on xwing. SSH key was fine; the issue is source IP = destination IP.

**How to apply:** Always use jump host pattern for any xwing or salvare direct-host commands. Never retry a failed `ssh xwing.s.l42.eu` bare without the jump.
