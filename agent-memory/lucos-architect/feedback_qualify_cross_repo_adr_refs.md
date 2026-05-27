---
name: qualify-cross-repo-adr-refs
description: ADR numbers are unique within a repo, not globally — qualify any cross-repo ADR reference with the repo name
metadata:
  type: feedback
---

ADR numbers are unique *within a repo*, not globally. `lucos_arachne` ADR-0004 ("Subclass-aware filtering") and `lucos` ADR-0004 ("Scheduled-jobs monitoring architecture") are two different documents. When referencing an ADR from outside its home repo — in a ticket body, PR description, comment, or anywhere — write it as `lucos_arachne ADR-0004` / `lucos ADR-0006`, not bare `ADR-0004`. Within the same repo as the ADR, bare form is fine because context disambiguates.

**Why:** lucas42 flagged this on 2026-05-27 after I filed three implementation tickets for `lucos_arachne` ADR-0004 (subclass-aware filtering). Two of them — `lucos_eolas#268` and `lucos_search_component#173` — were in different repos but said "Per ADR-0004 §2" without naming which ADR. A reader hitting those tickets cold would have no way to disambiguate from `lucos` ADR-0004 or any other ADR-0004 in the estate. The links to the PR/file disambiguate, but the prose still creates ambiguity that skim-readers will trip on.

**How to apply:**
- Cross-repo reference (writing in repo A about an ADR in repo B): `{repo-of-ADR} ADR-NNNN`. Example: "per `lucos_arachne` ADR-0004".
- Same-repo reference (writing in the same repo the ADR lives in): bare `ADR-NNNN` is fine.
- Link form: even when using a Markdown link `[ADR-NNNN](url)`, qualify the link text: `[lucos_arachne ADR-0004](…)`. Tooltips aren't always followed.
- This also applies to memory file names and descriptions — when storing a reference memory about an ADR, include the home repo in the description or first line of the body.
- See also the [[verify-teammate-quote]] principle of being explicit about provenance — same shape of mistake, different domain.

The rule lives in the architect persona's "Code Contributions" section as well; this memory is the reasoning behind it.
