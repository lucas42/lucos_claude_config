---
name: Volume removal pre-check — verify image content before removing masking volumes
description: When removing a named volume as part of a "let the image handle it now" refactor, always verify the image actually contains the correct content first
type: feedback
---

Before removing any named volume that is being superseded by content baked into a new image, **verify the new image actually contains what the volume had** — do not assume the build-time step succeeded correctly.

**Why:** In the 2026-04-29 eolas/contacts incident, `collectstatic` in the new image was silently shipping incomplete content. The named volumes (`lucos_eolas_staticfiles`, `lucos_contacts_staticfiles`) were masking the broken image for hours. Once the volumes were correctly removed, the broken image content became user-visible immediately. The volume removal itself was correct; the image verification step was skipped.

**How to apply:**
1. Before any ticket that removes a named volume in a "remove the volume so the new image's contents take over" pattern, add a pre-step: compare volume contents to the image at the same path using:
   ```bash
   # What the volume currently contains:
   docker run --rm -v <project>_<volname>:/in alpine ls -la /in/<subpath>
   # What the new image will provide:
   docker run --rm <image>:latest ls -la /path/in/image/<subpath>
   ```
   If the image-side path is empty or significantly shorter than the volume, **do not remove the volume** — there's a build-step bug to fix first.
2. If the image content cannot be verified locally, insist the image is deployed to a non-production environment and checked before the volume-removal PR lands.
3. Do not approve volume removal tickets that assume image content is correct without evidence.

Incident: 2026-04-29-eolas-contacts-styling-lost (SRE report in lucos/docs/incidents/)
Source issues: lucos_eolas#217, lucos_contacts#671
