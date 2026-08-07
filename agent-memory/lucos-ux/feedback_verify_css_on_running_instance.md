---
name: verify_css_on_running_instance
description: For CSS specificity/cascade/dark-mode claims, run docker compose up and check the real browser cascade — reading the theme's own CSS (or even the vendor's static compiled CSS) is not enough; use document.styleSheets/element.matches() for ground truth, not text grep
metadata:
  type: feedback
---

Across four consecutive lucos_worlds tickets in one session (#70, #76, #79, #80/#81), every real bug found was found by running the actual stack — never by reading source, however carefully.

**Concrete catches this pattern found:**
- A new `<summary>` background colour matching BookStack's default focus-`outline-color` custom property → invisible focus ring. Only visible by keyboard-focusing the live element and screenshotting before/after.
- Removing a CSS `:not(.dark-mode)` qualifier and rewriting to a bare `:root` looked like "makes the rule unconditional" by every plausible reading — but BookStack renders its own competing `:root`/`:root.dark-mode` custom-property block inline in every page's `<head>` (a Blade partial, not in the compiled static CSS at all), at higher specificity than a bare `:root`. Static analysis of the theme file, and even of BookStack's *compiled* `styles.css`, cannot find this — it only exists as server-rendered HTML.
- **A plain-text `grep` of BookStack's compiled CSS truncated a compound selector** (`html.dark-mode .card` matched by a grep pattern of `\.dark-mode \.card`, silently dropping the leading `html`), leading to a wrong specificity conclusion (looked like a tie, was actually a clear loss). Ground truth came from `document.styleSheets` + `element.matches(rule.selectorText)` in a live Playwright session — iterate every stylesheet, find every rule whose selector matches the live element, print the *exact* selector text. Do this instead of grepping compiled CSS whenever a specificity claim matters.
- Given a claim like "these N rules were all collapsed the same way and are now safe," don't assume they all behave alike — check each one individually via the CSS-OM method above. In one case 3 of 5 nominally-identical rules were broken and 2 were fine; assuming uniformity either way would have been wrong.

**How to apply:** for any lucos_worlds (or other BookStack-adopting) theme CSS change involving specificity, cascade order, or "unconditional now" claims — `docker compose up -d --build` locally (dev creds via `scp -P 2202 creds.l42.eu:{repo}/development/.env .`, `AUTH_METHOD=standard`, seeded `admin@admin.com`/`password`), create real content via `php artisan tinker` if the WYSIWYG editor is fragile to automate, force the state in question via `page.evaluate(() => document.documentElement.classList.add(...))` (exactly mirrors what server-rendered markup would produce), then read `getComputedStyle()` and/or enumerate `document.styleSheets` for ground truth. A specificity/cascade claim is a hypothesis until checked this way, not a fact from reading either side's source.
