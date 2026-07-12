---
name: lucos_worlds_page_excerpt_fix
description: Outcome of lucas42/lucos_worlds#52/#53 — Page::getExcerpt() stops at first newline
metadata:
  type: project
---

Fixed 2026-07-12: BookStack `Page` has no manually-authored description (unlike Book/Chapter/Bookshelf) — it's always derived from the page's own plain-text content (`PageContent::toPlainText()` → `text` column). A page opening with a short summary paragraph immediately followed by a list/table had that list/table content bleed into the truncated excerpt/`og:description`, because `HtmlToPlainText` puts only one newline between block-level elements.

**Why:** lucas42 wanted authors to be able to write a one-line opening paragraph and have it reliably become the page's description, with no bleed-through.

**Fix, for future similar asks:** override `getExcerpt()` on `Page` specifically (not the shared `Entity::getExcerpt()` used by Book/Chapter/Bookshelf, whose `description` field is manually authored and may legitimately be multi-line) — truncate to the first `\n` before applying the existing length limit. Point every "page description" call site (there were two independent ones: list/grid excerpt AND the page's own `og:description` meta tag, which had its own separate `Str::limit()`) at the one method so they can't drift apart again. Leave `SearchResultsFormatter`'s query-context search-preview snippets alone — they need the full text, not just the first line.

Shipped as a third patched BookStack file via [[lucos_worlds]]'s existing patch mechanism (ADR-0002 precedent), with its own unit test suite and live docker-compose verification (created a real page, checked rendered HTML). Code-reviewer approved and it auto-merged immediately (unsupervised repo) — no further action needed.
