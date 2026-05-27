---
name: opinion-textarea-drafting
description: For textareas asking Luke's views (not his evidence), don't draft prescriptive opinions from inferred-views; if drafting, lead with a specific observation Luke's grappling with, use concrete engineering primitives, tie to his existing craft tradition
metadata:
  type: feedback
---

For application form textareas asking Luke's *views* on a topic (as distinct from textareas asking for his *evidence* or his *experience*), don't draft prescriptive opinion pieces from inferred-views.  Opinion content is best either elicited from Luke first or, if drafting is appropriate, drafted with the specific shape below.

**Why:** an opinion-style textarea draft I produced from inferred-views (current-focus library, the lucos_agent blog post) read as a generic survey of abstract categories rather than Luke's actual current thinking.  When Luke rewrote it, his version was sharper, shorter, more grounded in concrete engineering primitives, and tied to his existing craft tradition (platform engineering) rather than treating the topic as detached discourse.

**How to apply** — when drafting any opinion-piece textarea content in Luke's voice:

1. **Lead with a specific observation Luke is currently grappling with**, not a survey of abstract categories.  "The tendency to keep adding complexity rather than simplifying things" lands; "auditability / scoped authority / culture" reads as textbook.
2. **Reach for concrete engineering primitives over abstract concept-names.**  "Configuration Management, least-privilege permissions, instructions in source control, ADRs" signals hands-on grounding; "scoped authority / audit trails / governance" signals having read the discourse.
3. **Tie to Luke's existing craft tradition** (platform engineering, reliability, architecture) rather than treating the topic as generic discourse.  Anchor the opinion in the engineering tradition he's worked in, not in detached abstract terms.
4. **Shorter and sharper beats longer and surveying.**  A 150-word answer with two specific observations lands harder than a 220-word answer with three abstract categories.

**For known opinion-style topics**, the cover-letter library has reusable blocks under `~/sandboxes/lukeblaney_cv/cover-letters/blocks/`.  When JD-triggered drafting surfaces a new reusable opinion piece (Luke-authored or Luke-signed-off), add it to a topic-named block file there.

**Out of scope:** this rule is about opinion-style textareas (views, perspectives, "what do you think about X").  For evidence-style textareas (concrete past stories), use `evidence-stories.md` blocks and CAR/STAR framing.

Related: [[user-cover-letter-patterns]], [[luke-voice]], [[cover-letter-standalone]].
