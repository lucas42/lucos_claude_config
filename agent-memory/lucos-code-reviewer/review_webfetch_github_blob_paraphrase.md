---
name: review-webfetch-github-blob-paraphrase
description: WebFetch on a GitHub blob URL returns a lossy paraphrase, not literal text — use gh-as-agent's contents API when exact numbers/wording matter
metadata:
  type: reference
---

`WebFetch` on a `github.com/{owner}/{repo}/blob/{branch}/{path}` URL runs the fetched page through a small summarizer model and answers your `prompt` against it — it does **not** return the file's literal content, even when the prompt asks for "the full raw content verbatim." Confirmed instance (2026-08-08, lucos-site-reliability's incident-report draft review): the WebFetch result dropped the report's central statistic (29 alerts / 24 manufactured) entirely and invented framing not present in the source ("8.5 hours... unreachable" as if it were the headline finding).

**For any review task where exact numbers, quotes, or wording matter** (re-deriving quantitative claims, checking a teammate's cited figures, quoting verbatim), fetch the actual file instead:

```bash
~/sandboxes/lucos_agent/gh-as-agent --app lucos-code-reviewer \
  'repos/{owner}/{repo}/contents/{path}?ref={branch}' --jq '.content' | base64 -d
```

WebFetch remains fine for genuine "what does this page say, roughly" questions (e.g. characterising a third-party doc's stance) where paraphrase-level fidelity is acceptable — just not for anything where a specific number or sentence needs to survive intact.
