---
name: feedback-edit-tool-smart-quotes
description: Edit tool can introduce smart/typographic quotes (U+2018/U+2019) in JS string literals, causing SyntaxErrors — use Python byte-level writes instead
metadata:
  type: feedback
---

Do not use the Edit tool for JS string literal content that contains apostrophes or is quote-adjacent. The Edit tool's text input path can substitute typographic curly quotes (U+2018 `'` / U+2019 `'`) for straight ASCII `'`, which causes a `SyntaxError: Invalid or unexpected token` that silently breaks the entire `<script>` block.

**Why:** Discovered when PR #211 (lucos_aithne) merged with U+2018/U+2019 used as JS string delimiters on a `msg.textContent` line. The Edit input had `won't` (apostrophe) nearby and the tool substituted curly quotes.

**How to apply:** For any JS string literal in an HTML template or `.js` file — especially one containing `won't`, `don't`, `it's`, or any apostrophe — use Python to write the correct bytes instead of the Edit tool:

```python
# Safe: write exact ASCII bytes
path = '/path/to/file.html'
with open(path, 'rb') as f:
    data = f.read()
old = b"msg.textContent = 'OLD STRING';"
new = b"msg.textContent = 'NEW STRING';"
data = data.replace(old, new, 1)
with open(path, 'wb') as f:
    f.write(data)
```

Also: after any JS template edit, run `grep -Pn "[\x{2018}\x{2019}]" file.html` (or `cat -A file.html | grep 'M-bM-^@'`) to check for inadvertent smart quotes before committing.

Note: U+2018/U+2019 inside a JS string as **content** (e.g. typographic quotes around variables in an error message) is valid and intentional — only fix them when they appear in **delimiter** position.
