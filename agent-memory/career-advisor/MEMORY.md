# career-advisor Memory

## User

- [User profile](user_profile.md) — Luke Blaney, job hunting, blended SWE/cyber/leadership target, pragmatic
- [User skills inventory](user_skills_inventory.md) — defensible languages/DBs/methodologies and what Luke won't claim. Check before asking gap-fill tech questions.
- [User role framing](user_role_framing.md) — level-positioning, manager-vs-IC tilts, career-break voice. Check before drafting Summary paragraphs.
- [User cover-letter patterns](user_cover_letter_patterns.md) — boilerplate problem, civil-service-statement-holds-the-gold, what's working and what isn't in his existing letters

## Active projects

- [CV rebuild](project_cv_rebuild.md) — pandoc + markdown source-of-truth pipeline for lukeblaney_cv (started 2026-05-19)
- [Cover-letter rebuild](project_cover_letter_rebuild.md) — building-block library + worked example + /tailor-cover-letter skill (started 2026-05-20)

## External references

- [Ashby job-board API](reference_ashby_job_board_api.md) — public posting-api endpoint pattern for fetching Ashby JD content (also notes on Greenhouse, Lever, Workday)
- [Repo access check](reference_repo_access_check.md) — try the operation, don't infer from `gh-as-agent` API permissions metadata; SSH-key access and GitHub App permissions don't always agree

## Feedback (standing rules)

- [CV commit discipline](feedback_cv_commit_discipline.md) — small targeted commits, source-only, gitignore artefacts
- [CV copy-editing scope](feedback_cv_copy_editing_scope.md) — mechanical edits ok without asking, copy changes need consultation
- [CV dialect preference](feedback_cv_dialect_preference.md) — no Americanisms; Northern Hiberno-English default; London-comprehensible
- [CV variant content rule](feedback_cv_variant_content_rule.md) — default drop Earlier Career & Positions in submissions; pull forward entries directly relevant to the target employer/industry
- [CV application privacy](feedback_cv_application_privacy.md) — default-deny on employer names in any public artefact (commits, memory files, public repo content); private `lukeblaney_cv_tailored` repo is the safe place for live drafts
- [Overlap years claim](feedback_overlap_years_claim.md) — sum of "[N] years of [domain]" claims in one document mustn't exceed Luke's actual years working, even if each claim is locally defensible
- [Luke voice](feedback_luke_voice.md) — banned words ("leverage", "AI Native", corporate jargon) and tone rules; never claim passions Luke doesn't have
- [Cover letter standalone](feedback_cover_letter_standalone.md) — assume the reader has NOT seen the CV; no sentences that require CV-derived facts to parse
- [Circle-artifacts URL truncation](feedback_circle_artifacts_url_truncation.md) — never paste raw circle-artifacts.com URLs; they get truncated where they wrap and break the link
- [Cover letter upload field](feedback_cover_letter_upload_field.md) — probe the application form first (per-ATS API); don't assume file-upload vs textarea vs per-question split. Includes disjoint-content rule for multi-textarea forms.
- [Textarea URL scheme](feedback_textarea_url_scheme.md) — include `https://` on URLs in any plain-text textarea submission; bare-host URLs are unreliable there. Rendered .docx / .pdf can still display the bare host.
- [Python in-place write perms](feedback_python_inplace_write_perms.md) — `tempfile.mkstemp` + `shutil.move` leaves files 0600; chmod explicitly when downstream readers (Docker, other users, hooks) need access
- [Tailored variant freeze](feedback_tailored_variant_freeze.md) — sweeping changes apply to all of lukeblaney_cv; for lukeblaney_cv_tailored only the actively-worked items. Historic / submitted variants stay frozen by default, no need to ask.
- [Check evidence recency](feedback_check_evidence_recency.md) — for senior IC variants, flag any headline evidence story ≥5 years old proactively before showing Luke a draft; look for absorption / continuity bridges
- [CV page count](feedback_cv_page_count.md) — hard limit 3, target ~2; verify against the .docx (via LibreOffice round-trip) not the LaTeX-PDF
- [CV skills section](feedback_cv_skills_section.md) — target ~5 categories; single-paragraph layout with hard line breaks (`\` at line end) to avoid inter-paragraph spacing bloat
- [Write tool flattens NBSP](feedback_write_tool_nbsp_flattening.md) — U+00A0 gets normalised to ASCII space through the Write tool; use Python post-write or Bash heredoc to write nbsp content reliably
- [Submission memory sweep](feedback_submission_memory_sweep.md) — when Luke says an application is submitted, batch all durable memory updates at that point alongside notes.md; don't wait for end-of-session prompt
- [AskUserQuestion phrasing](feedback_askuserquestion_phrasing.md) — use clear "tick to approve" semantics with multi-select; never use ambiguous "any objections" framings
- [Opinion textarea drafting](feedback_opinion_textarea_drafting.md) — for textareas asking Luke's *views* (not evidence), elicit first or draft with: specific observation > abstract categories, concrete primitives > concept-names, tied to platform-engineering craft
