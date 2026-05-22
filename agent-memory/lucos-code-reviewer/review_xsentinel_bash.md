---
name: review-xsentinel-bash
description: The x-sentinel bash trick only works when the comparison variable has no trailing newlines — if $VAR ends with \n, use printf + cmp instead
metadata:
  type: feedback
---

`[ "$(cmd)x" = "${VAR}x" ]` prevents command substitution from stripping trailing newlines from `cmd` output **only when `$VAR` itself has no trailing `\n`**. If `$VAR` ends with `\n`, the right side becomes `…\nx` while the left is `…x` — never equal.

For comparing a file against a heredoc-style variable that ends with `\n`, use:
```bash
printf '%s' "$VAR" | cmp -s "$FILE" -
```

**Why:** Gave wrong fix in lucos_agent_coding_sandbox PR #71 — suggested x-sentinel but `DESIRED_CONTENT` ended with `\n`.
