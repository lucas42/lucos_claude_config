---
name: CodeQL Supported Languages
description: Do not raise CodeQL coverage issues for languages CodeQL does not support — PHP specifically is not supported
type: feedback
---

Do not raise CodeQL coverage issues (or suggest adding CodeQL) for repos whose primary language is not supported by CodeQL.

**CodeQL supported languages (exhaustive):** C/C++, C#, Go, Java/Kotlin, JavaScript/TypeScript, Python, Ruby, Swift.

**Not supported:** PHP and anything else not on the above list.

**Why:** Raised lucas42/lucos_media_metadata_manager#171 suggesting CodeQL for the PHP backend — the sysadmin attempted it and hit a hard blocker. PHP is simply not a supported CodeQL language. The issue was closed as not_planned.

**How to apply:** During ops checks (Check 3) and any ad-hoc security review, only recommend CodeQL for repos with a supported language. If a repo's primary language is unsupported, skip it. If PHP static analysis coverage is ever wanted, suggest PHPStan or Psalm instead — but only if asked.
