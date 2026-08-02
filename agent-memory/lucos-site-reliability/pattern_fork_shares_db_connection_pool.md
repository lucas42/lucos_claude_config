---
name: pattern-fork-shares-db-connection-pool
description: "Postgres wire desync ('lost synchronization with server', 'insufficient data in D message') = a forked child inheriting the parent's live pooled sockets; look for fork() + a background DB thread, not for a network fault"
metadata:
  type: reference
---

`psycopg2.OperationalError: insufficient data in "D" message` / `lost synchronization with server: got message type "0", length <absurd>` is **not** a network or Postgres fault. It means two processes are writing to one Postgres TCP socket. The length is garbage because the client is reading the middle of someone else's frame.

**Cause:** `fork()` duplicates the parent's file descriptors. A SQLAlchemy `QueuePool` in a module global holds *live, open* sockets after `session.close()` (close returns the connection to the pool, it does not close the socket). So any child forked after the pool has been used inherits usable connections and can race the parent on them.

**Where to look, in order:**
1. Does the process fork? RQ's default `Worker.work()` forks a work horse per job (and a scheduler process when `with_scheduler=True`). Gunicorn with `preload_app` forks after import. Celery prefork likewise.
2. Is there a *background thread in the parent* that touches the DB? That's what turns "inherited connection" into "concurrent use". In lucos_photos it was `run_sweep_loop` on a 60s timer.
3. Correlate timestamps: parent DB work within ~1s of a child job starting is the signature.

**Non-causes — don't chase these:**
- `pool_pre_ping=True` doesn't help. It proves the socket is alive; being alive *is* the problem.
- `pool_recycle` doesn't help. A wall-clock timer is not a fork barrier.
- Threads are innocent. `QueuePool` is thread-safe and hands each thread its own connection.

**Fix (one line, covers every fork site including future ones):**
```python
os.register_at_fork(after_in_child=lambda: _engine.dispose(close=False))
```
`close=False` abandons the inherited connection records without touching the sockets the parent still owns.

**Why it deserves a ticket even when it self-heals:** the observed shape (clean `OperationalError` + a retry that succeeds) is the *lucky* one. The same shared socket can deliver one process's result rows into the other's cursor with no exception at all — silent wrong data.

First seen 2026-08-02 ops checks → lucas42/lucos_photos#500 (`lucos_photos_worker`, 2026-07-31 17:08:30).
Related: [[pattern_db_error_line_is_not_app_failure]] (the inverse — a DB `ERROR:` line that is *not* an app failure).
