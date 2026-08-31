---
name: mosquitto-password-file-ownership-check
description: mosquitto's "owner is not root" warning checks the calling process's own uid, not literally root — fix by running mosquitto_passwd as the target user
metadata:
  type: reference
---

mosquitto's `mosquitto__fopen()` (restricted-read file wrapper, `lib/misc_mosq.c`) compares a file's owner uid to `getuid()` of **whichever process is opening it right now** — not a fixed "must be owned by root" rule. The warning text substitutes the current process's own resolved username, so "owner is not root" only means "root happened to be the process reading it," not a requirement.

**`lucos_locations_mosquitto`** (`lucos_locations`#109, RESOLVED 2026-09-01, PR #118): the broker itself was never affected — it calls `drop_privileges()` before loading the password file, so its uid already matches. The warning came from `mosquitto_passwd -b` in `startup.sh`, run as root (container default, no `USER` directive) against a file already `chown`'d to `mosquitto:mosquitto`.

**Fix:** wrap `mosquitto_passwd -b` in `su -s /bin/sh mosquitto -c '...'` (image has BusyBox `su`, not `su-exec`/`gosu`).

**BusyBox `su` gotcha, verified against `eclipse-mosquitto:2.0.22` — not GNU su:** the form is `su -s SH USER -c 'CMD' ARG0 ARGS...` — the first extra positional arg after `-c CMD` becomes `$0` inside `CMD`, not `$1`. A naive `-- "$USER" "$PASS"` (as the issue's own analysis originally suggested) silently shifts everything by one — `$1` gets the password, `$2` is empty. Need a placeholder ARG0 first: `su -s /bin/sh mosquitto -c 'cmd "$1" "$2"' placeholder "$USER" "$PASS"`. Also: BusyBox `su` does NOT treat `--` as an end-of-options marker the way GNU `su` does — passing `-- "$USER" "$PASS"` just makes `"--"` itself the ARG0.

**Verification pattern:** built the real image, tested with a deliberately hostile password (`$()`, backticks, quotes, `;`) passed as a positional arg (never interpolated into the `-c` string) — round-tripped losslessly through `mosquitto_passwd` and authenticated correctly via `mosquitto_pub`. Confirms args-not-interpolation actually prevents injection, not just in theory.
