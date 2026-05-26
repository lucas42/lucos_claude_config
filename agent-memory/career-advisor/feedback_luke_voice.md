---
name: luke-voice
description: Banned words and tone rules for any text I draft in Luke's voice — including covering letters, CV summaries, LinkedIn, application form answers
metadata:
  type: feedback
---

Style and tone rules to apply when drafting anything in Luke's voice.

## Banned words and phrases

- **"leverage"** (as a verb or noun). Hard ban. Luke's stated take: "the only time I'd say leverage is when trying to open something with a crowbar, or taking the piss out of corporate jargon." Stated 2026-05-20. Use specific verbs instead: "use", "apply", "draw on", "build with", "put X to work for Y".
- **"AI Native"** — Luke's voice deliberately avoids this. If a JD uses it, engage with the underlying ambition (e.g. "transform engineering processes", "make GenAI part of how the team works") rather than parroting the phrase.
- **"transformational change"**, **"synergies"**, **"step change"**, **"unlock value"** — corporate-jargon family. Same reasoning.
- **Hyphenated "principal-engineer"** (as a compound adjective, e.g. "principal-engineer-level technical direction"). Luke prefers "Principal Engineer" treated as a noun phrase, capitalised as a job title, with no hyphen. Stated 2026-05-21 during a hospitality-marketplace Staff IC draft review. If the compound-adjective construction is needed, rewrite to a noun-noun construction instead ("Principal Engineer technical direction" rather than "principal-engineer-level technical direction").
- **"signals"** (when referring to a job advert's contents). Luke's stated take 2026-05-26 during the Capgemini Invent DevEx cover-letter review: doesn't like referring to "signals" in the context of what a job ad contains. Replacements: "the mix it calls for", "what it asks for", "the things named in it", "what you're looking for". Use these constructions to introduce JD-derived bullet lists in cover-letter para 1 openers.
- **"unusually"** (especially as an intensifier in cover-letter prose, e.g. "unusually live", "unusually relevant"). Luke's stated take 2026-05-26 (and previously flagged): "unusually" can carry negative connotations — implies abnormality / oddness rather than the intended "particularly current / particularly relevant" meaning. Just drop the word and say what you meant: "is timely", "is current", "is a topic every engineering org is wrestling with". If a particularness needs flagging, find a non-"unusually" word for it (e.g. "particularly", "notably", or restructure to let the specifics carry the emphasis).
- **Em-dashes are exception, not default, in external-facing prose.** Hard limit: at most one em-dash per rendered document (CV body content, cover letter body content); anything above that needs trimming. Stated 2026-05-21 after I'd added 193 em-dashes across the CV/letter source files. A git-blame audit showed Luke's own usage rate in CV/letter prose is exactly **zero**: every em-dash in the system was mine. Luke describes the rule as "I'm partial to the occasional one, it can make me look sophisticated, but too many of them rings AI-slop alarm bells." So one occasional one for sophistication is fine; piling them up reads as LLM tic. **Replacement palette** when removing an em-dash:
  - When the second clause expands or elaborates on the first → **colon** (`microservices — the central spine` becomes `microservices: the central spine`)
  - For parenthetical asides bracketed by em-dashes → **commas** or **parentheses** (`travel the world — dozens of countries — and what I enjoyed` becomes `travel the world, dozens of countries, and what I enjoyed`)
  - Between two distinct sentences → **full stop** (then start a new sentence)
  - For a casual / informal break → **hyphen** with surrounding spaces (`discuss this - happy to share`); this is Luke's choice for the closing-line break in particular

  **Don't reflexively reach for the colon when removing an em-dash.** Stated 2026-05-26 during a Principal Product Security IC consultation, after I'd dropped from 4 colons to 2 across a cover letter and Luke called out two more in P2 as colon-overuse. The palette options are alternatives, not a hierarchy with colon at the top. Picking rule:
  - If the elaboration is long enough to stand as its own sentence, prefer the **full stop** and split. (One specific failure mode: a colon following a long subordinate clause stretches the sentence further when the cleaner move is to split — e.g. "As Cyber Security Director I took on enterprise-wide technical standards governance, an area that had previously lacked ownership: deprecated a substantial number of obsolete standards..." reads better split at the colon into two sentences.)
  - If the "X: Y" preamble doesn't add anything beyond the list/clause that follows (e.g. "The hands-on side: SAST, SCA, secret-scanning..."), drop the preamble entirely rather than colon-rescuing it.
  - Aim for at most ~2 prose colons per cover letter as a rough ceiling. If you're at 3+, audit — odds are you're reflexively substituting for em-dashes rather than picking the colon deliberately.
  - URL colons (`https:`) don't count toward the ceiling.

  **Scope of the rule**: external-facing prose only. That means:
  - **Apply the rule to** the prose that ends up in the rendered .docx / .pdf: CV body content (Summary, Skills, role descriptions, bullets, Career Break section); cover-letter body (paragraphs 1–4, salutation, close); the example opener / evidence-story / current-focus prose in the library blocks because that's the prose that gets pasted into letters.
  - **Don't apply the rule to** internal commentary that never reaches a recipient: library `**Tags**:` / `**Gaps**:` lines, "Pairs with" notes, framing-decision discussion, instructional bullets in `template.md`, `What to avoid` lists, README files, voice-memory files (including this one). Em-dashes there are fine and don't need trimming.

  Stated 2026-05-21 after I trimmed em-dashes from every line of `evidence-stories.md` including the Gaps/Tags/Pairs-with commentary, when Luke only needed the external prose trimmed. Luke's clarification: "you went full-on there. Didn't need you to remove emdashes from your own internal notes. Just external facing copy." For future sweeps, ask "would this text appear verbatim in a rendered letter/CV?" before applying the rule. If no, leave it alone.

## Tone rules

- **Don't claim passions Luke doesn't have.** If I write "I find X genuinely motivating" or "I'm passionate about Y", the claim has to be true. Luke explicitly does NOT find SME credit access motivating (stated 2026-05-20). When I have no input from Luke on whether he genuinely cares about a company's mission, **default to writing about the role rather than the mission**. "What caught my attention about this role is…" is honest; "Acme Lending's mission around SME credit access is genuinely motivating to me" is fluff.
- **No saccharine framing.** Words like "genuinely", "deeply", "truly" applied to feelings about a company are signals of overclaiming. Use them sparingly and only when Luke has confirmed the underlying claim.
- **Measured, dry, slightly understated.** Luke's settled voice is calm and direct. Not enthusiastic-corporate, not breathless. The open-knowledge-non-profit and public-service-broadcaster letters in his existing library have this tone naturally; reach for that register.
- **Honest gap notes are welcome.** When Luke doesn't have something the JD asks for, say so plainly with adjacent evidence — see the regulated-pensions cover-letter pattern. Don't dress up gaps.
- **Don't conflate companies with domains.** Domains are business areas (travel, hospitality, fintech, publishing, media); companies are companies. Stated 2026-05-21 during a hospitality-marketplace Staff IC draft after I wrote "[Company] is a domain I'd be glad to work in" — the correct construction is "travel is a domain I'd be glad to work in" or "[Company] is a company I'd be glad to work for". Pay attention to the antecedent of "it" in any "this is a domain I'd…" sentence — if "it" refers to the company rather than the business area, the sentence is wrong.
- **Don't claim greenfield design on pre-existing systems Luke inherited.** Be specific about which work was greenfield vs which was ongoing architectural ownership of existing systems. Stated 2026-05-21 after I wrote "Designed an event-driven architecture using Apache Kafka…" for the UPP role — the Kafka backbone pre-dated Luke's Architect-Content tenure. Known greenfield work at the FT: the metadata management APIs (Architect-Content); the cloud-native zero-downtime deployment pipeline (Integration Engineer, Strategic Products). Known inherited systems where Luke's contribution was ongoing architectural decision-making rather than greenfield design: the UPP Kafka backbone. Use "Made architectural decisions on…" / "Worked on…" / "Worked within…" for inherited systems; reserve "Designed…" / "Architected…" for greenfield.
- **Don't assert current FT tooling state without verification.** Luke left the Financial Times in March 2025 and has no visibility into changes since.  Stated 2026-05-26 during the Capgemini Invent DevEx cover-letter review, after I wrote that the Reliability Engineering team's tooling output ("monitoring aggregation platform, tech migration tracker, change management system") was "still in use across the company" — the tech migration tracker had been replaced before Luke left, and the rest is unknown.  **Rule**: don't claim "still in use", "still operating", "still the company's X", or any current-state claim about FT-owned systems / tools / processes Luke contributed to.  Use past-tense framings — "was used across the company", "the team delivered", "I built" — which describe Luke's contribution without asserting current state.  Applies to all FT-related claims in cover letters, CV bullets, and prose.
- **Don't use a pronoun for "data" / "data sets" / "metrics".** Luke's stated take 2026-05-26: "act on it" sounds odd when the subject is data (technically plural — "act on them" also sounds odd in English).  Instead, restructure so the verb takes a non-pronoun object: "individual team leaders had reliable information to act upon", "team leaders could act on the figures", "team leaders had something they could act on".  Or use a different noun: replace "data" with "information", "metrics", "figures" where appropriate.  Applies broadly to any prose construction where Luke's contribution to data infrastructure / measurement work needs an action verb on the data itself.
- **Don't position one piece of evidence as "most directly relevant".** Phrases like "Most directly relevant:", "The most directly relevant of these:", "Most pertinent to this role:" overclaim the relative weight of one story versus everything else Luke has done. Stated 2026-05-23 after I opened a cover-letter paragraph 2 with "Most directly relevant: I led the FT's company-wide migration of Single Sign-On…" and Luke pushed back: "Happy to mention the migration, but don't say it's more relevant than anything else I've done. Especially when it's from years and years ago." Use neutral framings that introduce a story without ranking it: "On the identity and access management side, I led…" / "One example: I led…" / just dive in without a preamble. The reader will infer relevance from the JD-matching content; don't editorialise. The rule is sharper when the story is older — a 5-years-ago story claimed as "most directly relevant" reads as either "I haven't done anything recently" or as overclaiming.

## HR / talent-acquisition acronyms

Stated 2026-05-21.

**Avoid "JD"** (job description) in anything Luke writes that might be read by a hiring manager or wider audience. JD is fine when the document or message is explicitly only for a recruiter / talent acquisition team — but cover letters, application-form answers, and any other writing that might land in front of an engineering leader's eyes should use the full phrase.

**Replacements**:
- "JD" → "job description", "job posting", "role description", "the posting"
- Often you can elide it entirely: "an unusual combination to see spelled out in a JD" → "an unusual combination to see spelled out in a job description", or restructure to "an unusual combination to see called out so explicitly"

**Why**: JD is HR / TA jargon. Hiring managers and engineering leaders aren't HR people, and using HR acronyms back at them reads as either inside-baseball or distancing.

**Scope**: applies to anything I write in Luke's voice for external audiences. Doesn't apply when I'm talking *to* Luke about a job description in our working conversation — that's fine.

Related: [[user-cover-letter-patterns]].

## Whitespace conventions

Stated 2026-05-21. Apply to all of Luke's external-facing prose.

1. **Double spaces between sentences.** Typewriter convention. Applies to all external-facing prose: cover letters, CV Summary, CV role-intro lines, CV Career Break section, application-form free-text answers, anywhere Luke's prose appears to a recipient. Source the markdown with `.  ` (period + two ASCII spaces) between sentences. The `render-tailored.sh` pre-processor automatically converts each sentence-end run of ASCII spaces to `<space><U+00A0>` before pandoc runs (added 2026-05-21), so the convention survives into rendered docx/pdf without any manual intervention. The source file stays clean and readable; just type two regular spaces between sentences and let the renderer handle the conversion.

2. **First-line indent on paragraph 1 after a salutation** (letters only — CVs have no salutation). The indent should visually align with the position of the comma in the greeting line above. When platform-specific font/spacing makes precise alignment impossible, fall back to a tab or two of indent. **Technical implementation in pandoc-markdown source**: a leading tab on a fresh paragraph line triggers a code block, so don't use a literal tab in the source. Instead write a run of Unicode non-breaking spaces (U+00A0) at the start of the first line of paragraph 1 — pandoc preserves these into both docx and pdf outputs. Roughly 16-20 of them approximates "Dear hiring team," width in Calibri 11pt; adjust per salutation length. The indent is NOT automated by the render-tailored pre-processor (since "this is the first paragraph after a salutation" is hard to detect reliably); write the nbsp run into the source by hand. If the Write tool flattens the nbsp to ASCII (which it does on tool boundaries), follow up with a Python one-liner that does `re.sub(r' {N,}I', NBSP*N+'I', content)` or similar — see any recent cover-letter.md in the private `lukeblaney_cv_tailored` repo for a worked example.

## How to apply

Before showing Luke any drafted prose, scan for: "leverage", "AI Native", "synergies", "transformational", "genuinely motivating", "deeply passionate", "step change", "unlock", "principal-engineer" (hyphenated compound). If any appear, revise *before* showing. If a JD requires engaging with one of these concepts, rephrase the engagement into Luke's voice — don't parrot the phrase to score keyword points.

Also scan for: any sentence where a company name is the antecedent of "it" in "is a domain I'd…" / "is a domain I haven't worked in…" — if the antecedent is a company rather than a business area, rewrite.

For any sentence claiming Luke "designed" / "architected" a system at the FT: verify the system was greenfield work during the role being described. If inherited, soften to "made architectural decisions on…" / "worked on…" / "worked within…".

Related: [[user-role-framing]], [[user-cover-letter-patterns]], [[cv-dialect-preference]], [[cover-letter-standalone]].
