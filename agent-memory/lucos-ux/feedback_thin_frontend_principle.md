---
name: Thin frontend over API
description: lucos frontend-manager projects should be thin clients — API does the heavy lifting, no bespoke frontend logic for ordering/sorting/transforms
type: feedback
---

lucos frontend projects that sit over an API (e.g. `lucos_media_metadata_manager` over `lucos_media_metadata_api`) should be thin pass-throughs: take API responses, put them in a template, render. No bespoke frontend ordering, sorting, filtering, or data reworking between the API call and the template.

**Why:** Stated as a general principle by the user during UX review of lucos_media_metadata_manager#213 (albums UI). Specifically, on the question of whether to sort tracks alphabetically when the API doesn't define an order, the answer was "render in the order it gets it from the API" — and if that order turns out to be unhelpful, raise a ticket on the API project, don't fix it on the frontend. This keeps behaviour consistent across any consumer of the API and avoids duplicated logic.

**How to apply:**
- When reviewing or implementing frontend-manager projects, flag any in-memory sorting/filtering/rearranging of API data as a smell. Push that logic down to the API.
- If an API returns an order that's unhelpful for users, the right fix is to raise an issue on the API repo, not patch it on the frontend.
- Pagination page size, field ordering, default sorts, etc. should all come from the API.
- The manager's job is: API call → template. Anything more complicated needs justification.
