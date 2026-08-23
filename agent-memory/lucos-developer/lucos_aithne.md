---
name: lucos-aithne
description: Structure and review-process notes for lucos_aithne (auth service)
metadata:
  type: project
---

- **Always-review by `lucos-security`, regardless of triviality.** Confirmed on PR #326 (a one-line static-file route addition): `lucos-security` posted a mandatory APPROVED review alongside `lucos-code-reviewer`'s, before merge. Don't assume a trivial aithne PR skips the security sign-off step — it's required on every PR to this repo, not just auth-logic changes.
- **Static file serving pattern**: `serveStaticFile(fsys fs.FS, path string) http.HandlerFunc` in `main.go`, backed by `//go:embed static` (`staticFS`). Register new static routes with `mux.HandleFunc("/path", serveStaticFile(staticFS, "static/file"))`, mirroring the existing `favicon.svg`/`aithne.css`/`aithne.js` entries. `http.ServeFileFS` sets `Content-Type` from the file extension.
- **Local build/test requires a gitignored `scopes.yaml`** — fetch it via `./scripts/fetch-scopes.sh` (pulls from the `lucas42/lucos_auth_scopes` image pinned in the Dockerfile) before `go build`/`go test`. `Dockerfile`'s `COPY . .` already covers new files under `static/`, no Dockerfile change needed for a new static asset.
- **Minimum env vars for a local smoke-test run**: `PORT`, `SYSTEM`, `APP_ORIGIN`, `SIGNING_KEK` (any string — SHA-256'd internally), `DB_PATH` (defaults to `/data/aithne.db`, override to a writable path), `LUCOS_CONTACTS_ORIGIN`, `KEY_LUCOS_CONTACTS`. Missing ones cause `log.Fatalf` at startup, not silent failure.
