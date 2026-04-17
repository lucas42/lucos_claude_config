---
name: Docker memswap_limit default
description: Docker memswap_limit default is 2x mem_limit, not equal — always set explicitly to prevent unintended swap
type: feedback
---

**Docker's `memswap_limit` default is 2× `mem_limit`, not equal to it.**

When `mem_limit` is set but `memswap_limit` is not, Docker allows the container to use up to 2× `mem_limit` in total memory (RAM + swap). This means the container can consume up to `mem_limit` of additional swap on top of its RAM limit.

**Why:** Got this wrong in lucos_photos#317 — initially left `memswap_limit` unset believing it defaulted to equal `mem_limit`. Code reviewer caught it.

**How to apply:** Whenever setting `mem_limit` on a container where the intent is to prevent swap usage beyond the RAM limit, always set `memswap_limit` explicitly equal to `mem_limit`. Example:
```yaml
mem_limit: 3g
memswap_limit: 3g  # prevents swap beyond RAM limit; default would allow 6g total
```

If swap is acceptable (e.g. cold-start tolerance), can leave `memswap_limit` unset — but document the intent.
