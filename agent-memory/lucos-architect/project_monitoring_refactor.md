---
name: monitoring-refactor
description: lucos_monitoring structural refactor (#307) — the four-concern split of monitoring_state_server.erl, its measured seam, and how it sequences against the ten open issues
metadata:
  type: project
---

`lucos_monitoring#307` (filed 2026-08-31, originated by lucas42) proposes a **move-only** split of `monitoring_state_server.erl` into four modules, plus moving the JSON encoders out of `server.erl`. Ahead of `lucos-ux` reimplementing `lucos_monitoring#296` on the new structure. PR `lucos_monitoring#306` is being discarded rather than merged.

**Why:** lucas42 found the codebase hard to follow. The top-level layering (fetchers → state server → view/server → HTTP) is **sound** — the problem is three leaks: JSON rendering sits in `server.erl` (150 lines below a comment saying view logic lives in `view.erl`), output shaping sits in the state server, and one module holds four unrelated concerns.

**The seam, and why it's a fact rather than taste:** nothing below line 317 of `monitoring_state_server.erl` constructs or destructures the server's state tuple — all ten sites are between lines 60 and 309. Deliberately *not* framed as "the bottom half is pure": it still has 10 `logger:` calls, 3 `erlang:system_time` reads, and the notifier dispatch. The movable property is **free of the server's state**, not free of effects. (Checked with a known-positive control before citing.)

**Measured baseline (2026-08-31):** 2,281 lines = 822 prod + 1,459 inline eunit; 44% of the repo's Erlang, 34% of its production code. `updateSystem` clause = lines 62–209, 13 levels of nesting. `rebar3 do eunit` → **263 tests, 0 failures**.

**Key design judgements worth keeping:**
- `depends_on` gets its own module at only ~60 lines because **two ADRs (0002, 0004) govern a concept with no module**, and `lucos_monitoring#296` walks straight into it. Module size is the wrong metric when ADR count says the concept is load-bearing.
- ADR-0001 constrains the **interface** (one fetch, callers don't re-derive), *not* the file layout — so moving `build_system_list` out of the state server preserves it. Stated explicitly in the ticket so nobody reads the move as a reversal.
- The acceptance property that makes "zero functional changes" checkable: **no test body may differ** except by file location and `module:` qualification. Any assertion edit = the move wasn't a move.
- Honest limit recorded: the split only halves the worst file (2,281 → ~1,140), because ~840 lines of gen_server integration tests legitimately stay.

**Why the state-tuple→record step is separable:** its own precedent is 30 lines above it in the same file (`#system_state{}` was introduced with "safe to add future fields without touching every read/write site"). Costs ~48 mechanical sites (10 prod + ~38 test literals). `lucos_monitoring#299` adds a 6th field, so it pays back — but it's the one step to drop if "simple" is the binding constraint.

**How to apply:** if asked to sequence monitoring work — land #307 before `lucos_monitoring` #295/#296/#299/#301/#303; it doesn't touch #294 (`email.erl`), #297 (`fetcher_info.erl`) or #300 (docs), which run in parallel.

Related: [[adr-standard]], [[cross-project-patterns]]
