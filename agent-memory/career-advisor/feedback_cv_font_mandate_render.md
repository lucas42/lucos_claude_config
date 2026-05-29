---
name: cv-font-mandate-render
description: How to render a tailored CV/cover-letter in a mandated font (e.g. Arial 12pt) — post-render theme1.xml swap; the standard template is Calibri/Cambria.
metadata:
  type: feedback
---

Some employers mandate a specific CV format (font, size, page count) in the posting. The standard `render-tailored.sh` pipeline renders **Calibri 12pt body / Cambria headings** (theme-referenced fonts; body `sz=24` half-points = 12pt already). To meet a different mandated font without rebuilding the baked-in docx reference template:

**Technique — post-render theme swap.** After `render-tailored.sh` produces the `.docx`, rewrite `word/theme/theme1.xml` inside the zip, replacing the major/minor `<a:latin typeface="...">` values (default `Calibri` and `Cambria`, plus `Calibri Light`) with the mandated font. All body and heading text inherits the theme (pandoc output uses `asciiTheme="minorHAnsi"` / `majorHAnsi`), so a single theme edit flips the whole document. Body text is already 12pt, so an "Arial 12pt" mandate only needs the font swap, not a size change. The `Consolas` code style in `styles.xml` is defined but unused (no code spans in a CV/letter), so it can be left alone — verify with a `VerbatimChar`/`SourceCode` grep on `document.xml` to confirm no body text uses it.

**Why:** `render-tailored.sh` hardcodes `--reference-doc=/pandoc-docx-reference.docx.template` baked into the docker image, so you can't pass a different reference per-application. The in-place theme swap is the cheapest deterministic fix and preserves all the brand-purple heading/hyperlink styling.

**How to apply:** when a posting mandates a font, do the standard render then run the theme-swap Python (zip → replace in theme1.xml → rewrite zip, `chmod 0o664` per [[python-inplace-write-perms]]). Verify with: (a) `grep '<a:latin typeface=' theme1.xml` shows only the mandated font; (b) `grep 'w:ascii=' document.xml` shows no explicit non-mandated fonts (pandoc body output has none); (c) LibreOffice round-trip still meets the page-count mandate. **Page-count caveat:** the container's LibreOffice substitutes Liberation Sans for Arial (metric-compatible), so the round-trip page count is reliable; true Arial renders in Word on Luke's machine. Arial runs slightly wider than Calibri, so a font-mandated 2-page CV needs harder content cuts than a default 3-page variant.

Related: [[cv-page-count]], [[python-inplace-write-perms]], [[cv-rebuild]].
