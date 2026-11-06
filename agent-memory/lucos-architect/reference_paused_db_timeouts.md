---
name: paused-db-timeouts
description: Which DB timeouts fire against a docker-paused postgres (only client-side connect_timeout); to_thread+wait_for strands threads
metadata:
  type: reference
---

Tested 2026-11-06, locally: postgres:16-alpine, `docker pause` for 8s, psycopg2 2.9.11.
- On an **existing** connection, `statement_timeout`, `tcp_user_timeout` and keepalives (all set to 1s) did **not** fire, and `SELECT 1` blocked the full 7.9s. statement_timeout is server-side, so a frozen server can't enforce it; the kernel ACKs for a paused process, which defeats the TCP options.
- On a **new** connection, `connect_timeout=2` fired at 2.0s. It is the only client-side bound, and pooled connections bypass it.
- Caveat: the test went via docker-proxy on a published port, not a container-to-container bridge.

`asyncio.wait_for(asyncio.to_thread(...))` cancels the await, not the thread. Blocked threads fill the default executor (min(32, cpu+4)) and starve unrelated checks. Confirmed by SRE on lucos_photos#632 (redis failed from the 5th poll, as predicted).

**How to apply:** for any health check or "bound the DB call" proposal, a cancellation-free client means bounding the *number* of blocked threads (single-flight per probe key, plus a dedicated executor sized to the number of keys), not their duration. Fix chosen on lucos_photos#632.
