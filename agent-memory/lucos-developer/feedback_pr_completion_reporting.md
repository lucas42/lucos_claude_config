---
name: Reporting PR completion: just say approved
description: After PR approval, report "PR approved" + URL only — do not determine or report supervised/unsupervised status
type: feedback
---

After a PR is approved, report back to team-lead with just the PR URL and that it has been approved. Do not add "awaiting lucas42", "auto-merging", or any supervised/unsupervised language.

**Why:** Four incidents of wrong reporting on supervised/unsupervised status (lucos_monitoring#133, lucos_media_manager#194, lucos_arachne#350/#353, lucos_repos#347). The coordinator always runs check-unsupervised itself — this is not the developer's job.

**How to apply:** After code-reviewer approval, compose the report as: "PR {url} is approved." Stop there.
