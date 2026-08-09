---
name: mosquitto-password-file-ownership-check
description: What mosquitto's "owner is not root" password-file warning actually checks, and the verified fix for lucos_locations_mosquitto
metadata:
  type: project
---

Root-caused lucos_locations#109 (2026-08-09) by cloning `eclipse-mosquitto` at tag `v2.0.22` and reading the source directly, rather than guessing.

**The check (`lib/misc_mosq.c`, `mosquitto__fopen()`, called with `restrict_read=true`) does NOT require root ownership.** It compares the file's owner uid/gid to `getuid()`/`getgid()` of **whichever process is opening the file right now** — a self-referential "you must own your own credential file" check, not a fixed root requirement. The warning text substitutes in the *current process's* resolved username, which is why it says "owner is not root" only when the reading process itself happens to be root at that moment. This explains upstream's community confusion (e.g. eclipse-mosquitto/mosquitto#2925) — people read it literally, `chown root` the file, and then their non-root broker can't open it at all. That's a misreading, not a real conflict.

**Two distinct call sites, only one is actually a problem for us:**
- The broker (`src/mosquitto.c`) calls `drop_privileges()` (line 526) *before* `mosquitto_security_init()` (line 556, which loads the password file via `security_default.c:758`) — so by the time the broker reads the password file it has already dropped to `user mosquitto`, matching our `chown mosquitto:mosquitto`. No mismatch, no warning, from the broker itself.
- `mosquitto_passwd` CLI (`apps/mosquitto_passwd/mosquitto_passwd.c:614/625`) uses the same restricted-read wrapper. Our `mosquitto/startup.sh` invokes `mosquitto_passwd -b ...` directly as part of the container's root-run CMD (no `USER` directive anywhere in the chain), against a file already chowned to `mosquitto:mosquitto` one line earlier — uid mismatch (root vs 1883) → this is the actual source of the warning, once per credential provisioned (RECORDER/OT/HEALTHCHECK = 3x).

**Not cosmetic forever**: immediately after each warning there's a `#if 0 / return NULL / #endif` block marked "Future version" — when upstream enables it, `mosquitto_passwd -b` will fail to open the file outright, breaking credential provisioning at container startup. Broker unaffected either way.

**Fix mechanism confirmed available in the actual image**: `eclipse-mosquitto:2.0.22` has `/bin/su` (BusyBox) but no `su-exec`/`gosu`. Wrap the three `mosquitto_passwd -b` calls in `su -s /bin/sh mosquitto -c "..."` so they run as the file's owner. Real quoting hazard to flag for the implementer: passwords come from `lucos_creds` and could contain shell metacharacters — needs `su -s /bin/sh mosquitto -c '...' -- "$VAR1" "$VAR2"` style arg-passing, not naive string interpolation through the extra `su -c` layer.

General lesson: **when a mosquitto/Alpine-image ownership or permission warning looks contradictory, check which process actually triggers it (root-run provisioning script vs. the already-privilege-dropped daemon) before assuming the daemon's own config needs to change.**
