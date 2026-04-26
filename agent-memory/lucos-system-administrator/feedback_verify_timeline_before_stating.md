---
name: Verify timeline before stating root cause
description: When proposing root cause theories involving dates, check the chronology is internally consistent first
type: feedback
---

When constructing a root cause explanation that involves dates and commit timelines, explicitly verify the chronology is consistent before stating it. Don't present a theory that requires an impossible date order.

**Why:** During lucos_backups#208 investigation, I stated "the April 22-24 files were created before the March 20 fix" — a claim that is chronologically impossible (April comes after March). The team-lead had to point this out. The correct conclusion was: "I cannot determine the root cause from code analysis alone."

**How to apply:** Before stating a timeline-based theory, write out the key dates explicitly and confirm the sequence makes sense (e.g. "fix merged March 20 → files dated April 22 → April is after March → files cannot predate the fix"). If the theory depends on an event X causing Y, and Y's date is before X's date, the theory is wrong. When you can't construct a consistent timeline, say "I can't determine the root cause from code analysis alone" rather than proposing a theory that doesn't hold up.

**The honest fallback:** "I can't determine the definitive root cause without access to the actual logs from those dates" is a correct and acceptable answer. It's far better than a plausible-sounding but chronologically impossible explanation.
