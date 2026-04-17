---
name: GitHub Actions SHA pinning — always verify via API
description: Never write action SHAs from memory; always look them up via the GitHub tags API to avoid transposition errors
type: feedback
---

**Always verify action SHAs via the GitHub API before writing them into a workflow file.** Never construct or recall SHAs from memory — SHA strings are long, look similar, and transposition errors are silent until the workflow runs.

**Why:** A transposed-digit typo in `imjasonh/setup-crane@v0.4` (`...4b80...` instead of `...4b60...`) caused the GHCR mirror workflow to fail on first manual run (lucas42/.github#50, 2026-04-17). The error only appeared at runtime: "Unable to resolve action, unable to find version".

**How to apply:** Before pinning any action SHA, look it up:
```bash
curl -s "https://api.github.com/repos/{owner}/{repo}/git/refs/tags/{version}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['object']['sha'])"
```
Or check the tags list:
```bash
curl -s "https://api.github.com/repos/{owner}/{repo}/tags" | python3 -c "import sys,json; [print(t['name'], t['commit']['sha']) for t in json.load(sys.stdin)]"
```

Copy-paste the SHA directly from the API response — never type it by hand.
