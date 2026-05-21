---
name: write-tool-nbsp-flattening
description: The Write tool flattens U+00A0 non-breaking spaces to ASCII spaces. Use Python post-write for nbsp content.
metadata:
  type: feedback
---

The Write tool flattens Unicode non-breaking spaces (U+00A0) to ASCII spaces (U+0020) somewhere on the tool boundary. Confirmed 2026-05-21 when I attempted to write a 16-nbsp indent into a cover-letter source file: byte inspection of the written file showed all 16 chars were 0x20, not the expected 0xC2 0xA0 UTF-8 sequence for U+00A0.

**Why:** the tool's text-handling appears to normalise whitespace at the input-output boundary. Likely affects other special-width / zero-width characters too (zero-width joiner, em-space, en-space, etc.) — haven't confirmed individually.

**How to apply:**

- When writing a file that needs literal U+00A0 (or other non-ASCII whitespace), don't try to type it directly through the Write tool. Two reliable approaches:
  1. **Write the file with ASCII placeholder content via the Write tool, then run a Python post-write to substitute the nbsp.** This is what worked for the most recent cover-letter variant's 16-char first-line indent.
  2. **Use the Bash tool with a heredoc-fed Python script that writes the file directly.** Bash preserves UTF-8 bytes through heredocs (when the delimiter is quoted: `<<'PYEOF'`).

- **Always verify** by reading the file as bytes and checking codepoints — don't assume the tool preserved what you typed.

**Example** (placing a 16-char nbsp indent at the start of paragraph 1 in a cover letter):

```python
NBSP = ' '
old = ' ' * 16 + "I'm interested"
new = NBSP * 16 + "I'm interested"
content = content.replace(old, new)
```

This came up because Luke's whitespace conventions require nbsp in cover-letter source files for the first-line indent. The sentence-end double-spaces problem is handled differently (the render-tailored.sh pre-processor converts ASCII `.  ` to `. \xa0` before pandoc), but the indent is still written into the source by hand and so always needs this workaround. A worked example sits in one of the variants under `lukeblaney_cv_tailored/orgs/` (the private repo); look at any recent cover-letter.md for the `<nbsp>×16` opening run.

Related: [[luke-voice]] (whitespace conventions), [[cover-letter-rebuild]].
