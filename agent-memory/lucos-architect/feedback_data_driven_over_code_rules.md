---
name: data-driven-over-code-rules
description: When a federation-layer ingestor needs to apply a source-system priority rule, express it as a directional RDF predicate the source systems emit, not as hardcoded if/else in the ingestor
metadata:
  type: feedback
---

When designing rules that determine how a federation layer (arachne ingestor, search-index builder, anything that consumes data from multiple source systems) should resolve priority among sources — e.g. "which URI wins as the primary identifier for a merged document" — express the rule **in the data the source systems emit**, not as code in the federation layer.

**Why:** code in the federation layer that says "if URI starts with `https://eolas.l42.eu/`, prefer it" has three hardcoded assumptions: the eolas namespace, the contacts namespace, and the priority between them. Adding a third source system means editing federation-layer code. Changing the priority means editing federation-layer code. Lucas42 pushed back on this in arachne#539 (2026-05-17) and was right: the federation layer should be domain-agnostic at the *data-loading* layer.

**Note:** lucas42 is fine with system-specific mapping in the *search-index ingestor* layer (the view layer for consumers). What he objected to was implying it was in the *triplestore ingestor*. The two layers have different domain-agnosticism requirements. Even so, expressing priority in the data is the cleaner design at either layer because it scales to multiple source systems and to per-type rules without code changes.

**How to apply:**
- When a rule depends on "which source system the URI came from," propose an asymmetric RDF predicate that the source system emits to declare its own preference. Example: `<contact_uri> :preferredIdentifier <eolas_uri>` (contacts pointing at the canonical URI it wants the federation to prefer).
- The federation layer walks the predicate generically (e.g. "follow `preferredIdentifier` chains to the terminal URI") with no knowledge of which source emitted what.
- Fall back to a deterministic choice (lexicographic etc.) when no preference is declared — keeps indexes reproducible.
- Be explicit about layer placement in tickets — name the triplestore vs search-index ingestor distinction so reviewers can check whether the system-specific logic is in an acceptable layer.
- Predicate URIs must be dereferencable. Reuse the existing lucos vocabulary service at `https://eolas.l42.eu/ontology/` rather than inventing a new namespace — namespace prefixes are local; only the URI matters.

See also [[apply-frame-review-to-own-reasoning]] — lucas42's question "why does arachne need to know this?" is exactly the kind of frame review I should apply to my own designs before posting. The original "eolas-wins in arachne code" framing went straight from my head into a ticket without me re-asking "is this in the right layer?"
