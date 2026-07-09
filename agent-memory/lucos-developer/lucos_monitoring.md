---
name: lucos-monitoring
description: Erlang/rebar3 structure, EUnit test commands, and Erlang gotchas for lucos_monitoring
metadata:
  type: project
---

- **Language**: Erlang, built with rebar3. Key logic in `src/fetcher.erl`.
- **Tests**: EUnit tests in each `.erl` file inside `-ifdef(TEST)` block. Run with `PATH="/home/lucas.linux/.kerl/installs/otp29/bin:$PATH" rebar3 do eunit --cover, cover`. Erlang IS available locally via kerl at `/home/lucas.linux/.kerl/installs/otp29/bin/erl`.
- **CircleCI check**: Uses v2 API — fetches pipeline via `/project/{slug}/pipeline?branch=main`, then workflows via `/pipeline/{id}/workflow`. Auth via `Circle-Token` header (not query param like v1.1).
- **Workflow statuses**: `failed` → red, `success`/`running`/`on_hold` → green.
- **`checkWorkflowStatuses/4`**: Pure function, fully unit-testable without HTTP mocks.
- **Erlang string pitfalls**: `re:replace(..., {return, list})` returns an iolist (nested list), not a flat string. Always wrap with `lists:flatten/1` before using `++`. Similarly, `lists:join/2` returns an iolist — use `string:join/2` instead when a flat list is needed for `++` concatenation.
- **`httpc` status matching**: status code is an integer (e.g. `200`), not a partial pattern. Use a guard: `when StatusCode >= 200, StatusCode < 300` — not `{_, 2, _}`.
