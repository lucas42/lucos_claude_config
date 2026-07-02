# Specialist Routing for Triage

When the coordinator needs another agent's input during triage, this file decides which agent and at what point. Inline consultation replaces the old "label and wait for a separate review phase" pattern — the goal is to resolve as much as possible in a single triage pass.

---

## Domains requiring specialist consultation before setting Status = Ready

Check each of these trip-wires. If any apply, consult the named specialist first and wait for their comment on the issue before setting Status = Ready. Do these sequentially so each specialist sees prior comments. **An unnecessary consult is cheap; a missed one is unbounded.**

### Security — consult `lucos-security`

Touches **authentication, authorisation, data protection, secret management, credentials, or other security topics**.

Concrete trip-wires (consult — do not skip "because the change looks like a security improvement" or "is only in CI"):

- Changes authentication mode (trust ↔ password, mTLS, OAuth flow).
- Adds/removes/rotates credentials or env vars holding secrets.
- Touches `auth`/`login`/`session` code paths.
- Changes how a database accepts connections.
- Changes who can read or write a resource.

This rule was extended after setting `lucos_eolas#164` (CI trust auth → password auth) to Status = Ready without consulting security.

### Reliability / observability — consult `lucos-site-reliability`

Touches **monitoring, logging, observability, reliability, or incident management**.

### Architecture — consult `lucos-architect`

- **Introduces a new data model / entity type, or makes a significant change to an existing one** (e.g. new Django model, new knowledge-base entity class, schema migration that changes relationships).
- **Changes how systems authenticate to each other, or changes an inter-service contract** — a shared auth *mechanism* / token scheme (e.g. static bearer keys ↔ M2M / OAuth `client_credentials` tokens) or the request/response contract between services. This sets estate-wide patterns, so it is an architectural decision, **not** a routine change — **even when the issue is framed as a "bug fix."** The tell: the *fix* changes the *mechanism* by which services authenticate (or the cross-service contract), rather than correcting a value / parse error *within* the existing mechanism. Consult the architect before Ready, and surface the premise to lucas42 (Awaiting Decision) if it would change an estate-wide convention — do **not** let it flow straight to Ready/dispatch as a bug. Security review at PR time is necessary but **not sufficient** here: it checks the code for vulnerabilities, not whether the estate *should* change its inter-service auth model.

### Frontend / UX — handled differently from the others

Will make a **significant change to user journeys on a frontend system** — new pages, navigation changes, form flows, interaction patterns, error states, or anything that meaningfully affects how users move through a system.

- If the ticket is **dominantly** frontend/UX work, set Owner = lucos-ux on the project board as implementer — no separate consultation step.
- If the ticket also has **substantial backend work**, keep Owner = lucos-developer and consult `lucos-ux` for triage input.
- Pure frontend/UX work should NOT be routed through this consultation path — set Owner = lucos-ux directly. See [`implementation-assignment.md`](implementation-assignment.md).

**Keep triage-phase UX input narrow.** When `lucos-ux` is consulted during triage, they should flag only (a) items that genuinely block implementation, (b) scope questions needing a decision from lucas42, and (c) fundamental design concerns. Detailed implementation guidance (specific HTML/CSS/copy/a11y) is implementation-phase output. If a triage UX review is going deep into implementation detail, either (i) accept it but recognise it's the wrong shape for triage, or (ii) reassign the ticket to Owner = lucos-ux on the board so the detail can be applied during implementation.

---

## Verification of security claims

When any agent makes a statement about a security-related process — how Dependabot behaves, how secrets are rotated, how auth tokens expire — do not take it at face value. Send the claim to `lucos-security` for verification before acting on it or relaying it to the user.

## Security input on security-related decisions

When you need a steer on a matter with security implications — whether to close vs merge dependency update PRs, how to handle exposed credentials, **how to resolve a CodeQL or other security-tool alert (dismiss vs inline-suppress vs restructure), whether an alert is a genuine finding vs false positive, where suppression rationale should live in the codebase** — consult `lucos-security` and include their input in your summary to the user.

**CHECKPOINT — before presenting alert-resolution paths to lucas42:** Whenever a CodeQL alert (or any other security-tool finding) is surfaced, STOP — **this fires whether or not the alert blocks a PR, and whether the resolution is a formal proposal or just a passing remark in review telemetry** (e.g. a code-reviewer aside that "it's a false positive" or that "lucas42 can dismiss it from the Security tab"). A non-blocking alert mentioned in passing is the easy one to miss — it still routes to security. The implementer and the code-reviewer are not the security authority on whether the finding is genuine or where the rationale should live — `lucos-security` is. **A security-tool alert is never a lucas42 action item (and must not be carried onto his queue as "dismiss these") until `lucos-security` has assessed it and either dispositioned it themselves or told you the precise step that genuinely requires lucas42's permission.** Send the alert, the agents' proposed paths, and the codebase context to `lucos-security` and wait for their assessment before relaying any options to lucas42. The fact that the implementer's rationale "sounds technically correct" is not sufficient — security judgement on the codebase's policy for these findings is what's needed, and that belongs to the security persona.

**CHECKPOINT — never instruct `lucos-security` to take a specific security action.** Consultation messages to `lucos-security` must ask for assessment and recommendation, not dictate an action. Specifically, **never** write "dismiss this alert", "suppress this finding", "ignore this", "mark as false positive", or any other action-prescribing instruction to security. The decision to dismiss, suppress, restructure, or escalate is theirs as the security authority for the codebase — even when the action looks obvious from the coordinator's perspective. The coordinator's job is to surface the question with full context; the security teammate's job is to choose the action. This is the security-specific instance of the persona's "delegate the problem, not the solution" rule, but the friction has hit specifically here, so the rule needs to be explicit.

---

## Mid-lifecycle escalations

All consultation rules above also apply mid-lifecycle: if a specialist concern surfaces in an agent's comment during consultation, consult the relevant specialist next before approving.
