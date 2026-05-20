---
name: reference-escape-hatch-design-pattern
description: The deviceSwitch pattern (low-friction switch between alternative implementations) is a deliberate reliability affordance — preserve and replicate it
metadata:
  type: reference
---

# Escape-hatch affordances as a design pattern

## The principle

When a user-facing system has multiple alternative implementations or backends (multiple playback devices, multiple input methods, multiple storage backends), expose a **low-friction switch** between them as a first-class affordance — not as a buried configuration option, and not only as an automatic fallback.

The user's ability to **manually move the work to a different implementation** is a reliability affordance independent of any individual implementation's reliability. It pays off precisely when the failure is silent or unmodelled — exactly the case where automatic fallback can't trigger because the system doesn't realise it has failed.

## Worked example

`lucos_media_manager` exposes `deviceSwitch` — playback can be moved between seinn (browser), phone, Galactica, etc. with one user action. During the 2026-05-19 and 2026-05-20 seinn cache-thrash incidents, this was the resolution path on both days: the user noticed music had stopped, switched playback to a different device, recovery was immediate. The underlying seinn bug was silent (no error to the page, no signal to the server), so no automatic recovery could fire. The manual escape hatch is what brought the incident in under 30 minutes.

## When to cite this

When reviewing or designing:

- Any system with multiple interchangeable backends/devices/implementations for the same user-facing function.
- Any "auto-fallback" mechanism — ask whether a *manual* fallback affordance is also exposed for the silent-failure case.
- Any UI that consolidates onto a single implementation by default — make sure the user can still pick a different one when the default is misbehaving.

Resist arguments of the form "the auto-fallback covers this" when the actual failure mode is silent or undetected.

## Anti-pattern

The escape hatch buried three levels deep in settings, or only accessible via a CLI / config file edit, doesn't count. The affordance has to be reachable at the moment the user notices the failure — typically one or two clicks from wherever they were when the failure happened.

## See also

`docs/incidents/2026-05-19-seinn-cache-thrash-music-outages.md` in `lucas42/lucos`.
