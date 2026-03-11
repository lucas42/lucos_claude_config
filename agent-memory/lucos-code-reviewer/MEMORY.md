# Persistent Memory — lucOS Code Reviewer

## Cross-Repo Review Rules

### Docker Healthchecks — `localhost` vs `127.0.0.1`
- **Always flag `localhost` in healthcheck URLs as a blocking issue.** On Alpine-based containers, `localhost` can resolve to `::1` (IPv6) rather than `127.0.0.1` (IPv4). If the service binds only IPv4, the healthcheck will fail silently.
- The correct pattern is `http://127.0.0.1:<port>/_info`.
- This was confirmed as a real failure mode via lucos_arachne#91. A missed instance in lucos_contacts PR #533 required a follow-up issue (#534).

## Repo-Specific Review Rules

### lucos_repos
- If a PR adds or changes a convention definition, compare it against the "Checklist for reviewing convention PRs" in `docs/convention-guide.md` in that repo.
- **`RepoTypeScript` is NOT about the TypeScript language.** It refers to repos in configy's *scripts* list (tools designed to run locally). Do not confuse the two when raising issues or reviewing convention PRs.

## Recently Mentioned Reptiles

- Thorny devil (2026-03-07)
- Green iguana (2026-03-07)
- Common snapping turtle (2026-03-07, 2026-03-10)
- Gila monster (2026-03-07, 2026-03-10)
- Slow worm (2026-03-07)
- Leatherback sea turtle (2026-03-07)
- Nile crocodile (2026-03-07)
- Veiled chameleon (2026-03-07)
- Blue-tongued skink (2026-03-07, 2026-03-09, 2026-03-10) — DO NOT USE
- Green tree python (2026-03-07)
- Tokay gecko (2026-03-07)
- Black mamba (2026-03-10)
- Inland taipan (2026-03-10)
- Malagasy leaf-tailed gecko (2026-03-10)
- Pancake tortoise (2026-03-10) — COMPLETELY BANNED, massively overused
- Panther chameleon (2026-03-10) — DO NOT USE AGAIN SOON
