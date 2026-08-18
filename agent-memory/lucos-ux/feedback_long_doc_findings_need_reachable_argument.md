---
name: long-doc-findings-need-reachable-argument
description: In long technical documents, a finding mentioned early (header/summary) is not the same as its argument being reachable — use a standalone callout, not reordering, when later sections have internal dependencies
metadata:
  type: feedback
---

When reviewing a long technical document (incident report, design doc, RFC) for whether its most important finding gets read: check not just "is it mentioned early" but "can a reader get the actual argument without reading everything before it." A finding named in a header table or summary sentence can still be functionally buried if the reasoning for it only appears in a late section, behind several other dense sections a skimming reader won't clear.

**Why:** Confirmed on the 2026-08-17 `lucos_backups` incident report (lucas42/lucos#289). The SRE's "detection worked, response didn't" finding was named in the header table and the Summary's closing line, but its argument lived in Stage 6 of 6, after five sequential technical stages (CPython ABI internals, pipenv hash re-resolution, Go source review). Diagnosed that as burial despite early mentions; SRE confirmed they'd been treating "mentioned early" as sufficient and hadn't distinguished it from "reachable."

**How to apply:** When the surrounding sections have real internal dependencies (stage 2 needs stage 1's setup, etc.), don't recommend reordering to promote the buried finding — that can cost more clarity than it buys, and reordering decisions like this get silently reversed by someone tidying up later unless the reasoning is written down (the SRE put it in the commit message for exactly that reason). Instead recommend a short standalone callout (2-3 sentences) placed early — right after the summary — that states the finding and its argument on its own, then points to the full section for detail. Leaves the dependent structure intact while making the headline actually reachable without reading the whole document.

Also worth checking in the same pass: does the document's own summary paragraph's *ordering* match what the author says is most important? Caught a case here where the author told me directly which finding mattered most, but their own Summary listed it second in a "two things worth attention" sentence — an internal inconsistency between stated intent and actual emphasis, distinct from the burial issue but caught by the same read-through.
