---
name: review-shell-scripts-undefined-vars
description: When reviewing shell scripts, flag undefined variable references (shellcheck SC2154 class) as a concrete issue, not a nice-to-have
metadata:
  type: feedback
---

When reviewing shell scripts, actively check for undefined variable references (shellcheck SC2154: variable referenced but not assigned).

**Why:** lucos_arachne incident 2026-05-21 — two typo'd variable names (`$EXISTING_SYSTEMS_JSON`, `$TYPESENSE_ADMIN_SYSTEM`) in `search/entrypoint.sh` had been latent since 2025-09-21. The path only ran when orphan Typesense keys existed, which first happened after lucos_comhra decommissioning. ~23 min production outage. Shellcheck would have caught both at PR time.

**How to apply:** When reviewing any `.sh` file, scan for `$VAR` references and cross-check that the variable is defined somewhere in the script (either assigned, exported, or a known env var). If a variable name in a curl/command call looks inconsistent with how similar variables are named elsewhere in the file, flag it as a probable typo. Don't rely on CI to catch this — most lucos repos don't run shellcheck (lucos_arachne#558 is tracking adding it to that repo).
