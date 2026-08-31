---
name: pattern-optimistic-cache-of-remote-process-state
description: A cache recording what we ASKED a remote process for, treated as what it HAS — dropped commands poison it permanently. Seen in lucos_media_linuxplayer volume (issue 139); includes the mplayer slave-mode dead window after loadfile.
metadata:
  type: pattern
---

When code writes a command to another process (a pipe, a socket, a slave-mode CLI) and then
records the requested value as the applied value, a silently-dropped command poisons the cache
**permanently** — every later identical request short-circuits and the value is never re-asserted.

**Tell:** a `if (cached === requested) return;` guard immediately followed by a fire-and-forget
write, with the cache assigned on the *write* rather than on any acknowledgement.

**Symptom shape:** "X is wrong when the thing starts, but changing X during operation fixes it."
Changing it produces a *different* value, which passes the guard and lands at a moment when the
receiver can act on it. That user-reported shape is close to diagnostic on its own.

**Diagnostic:** count how many times the command was actually emitted vs how many times it should
have been. lucos_media_linuxplayer: 2 `Volume at …%` lines in a 35,927-line, 5-day log covering
~30 track changes. A near-zero emission count against a busy service is the confirmation.

## mplayer slave mode specifically (lucos_media_linuxplayer, xwing)

- After `loadfile`, mplayer has **no audio output** for a median 2.14 s (min 0.74 s, max 5.58 s,
  measured over 46 track starts) — it's opening the stream and filling the 16 MB cache to 80% first.
- **The 16 MB cache did NOT create that dead window** (checked 2026-08-31 when lucas42 asked whether
  the volume bug was a regression from 5e01626, 2026-05-13). Without the cache flags, audio output is
  still ~0.92 s away — dominated by the **TLS handshake to private.l42.eu, measured at 253/292/333 ms
  from xwing**. The code writes `volume` at +0.12 s, so it missed by ~800 ms before the cache change
  too. The cache widened the miss from ~0.9 s to ~2.3 s; it didn't cause it. `setVolume()` is
  byte-identical since 2024-09-04; the poisoning short-circuit dates from 2022-06-26.
- mplayer wants the audio chain up **before** the command, with margin: sending level with audio init
  (+1.0 s vs AO at 1.01 s) is still dropped; +1.5 s applies.
- A `volume N 1` written into that window is **silently discarded**: no error, no warning, no
  non-zero anything. Reproduced 2026-08-22 in `debian:bookworm` + mplayer: same command at
  +0.12 s → `ANS_volume=90.909088` (ignored), at +5 s → `ANS_volume=42.000000` (applied).
- `mplayer.stdin.write()` returns a **boolean**, not a promise. `await`ing it looks like ordering
  is guaranteed; it isn't. All queued commands hit stdin within ~120 ms.
- Reliable "mplayer is genuinely playing now" marker: the first `A: <time>` status line for the new
  track. Those only appear once the audio chain exists. `Playing <url>.` is emitted *before* the
  stream is opened and is far too early.
- At `-msglevel cplayer=4` (warn) the informative lines (`Starting playback...`, `AO: [alsa] …`)
  are suppressed. On xwing the per-track `AO: [pulse] Init failed` warning is the only available
  audio-init timestamp — pulse isn't running there, and `/etc/mplayer/mplayer.conf` sets
  `ao=pulse,alsa,sdl:aalib`, so it always fails through to alsa. Handy accidental instrumentation.
- `lucos-agent` is not in the host `audio` group and the container has no `amixer`, so the ALSA
  mixer level cannot be read from either side without installing packages on production. Don't.

See [[feedback-verify-root-cause-by-reproduction]] — reproducing the timing in a throwaway
container upgraded this from "plausible race" to proven in about two minutes.
