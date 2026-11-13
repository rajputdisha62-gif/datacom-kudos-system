# Datacom Kudos System — Technical Design

**Status:** Draft for review; no implementation has been started  
**Version:** 1.0  
**Date:** 2026-11-13

## 1. Design overview

Build a small, responsive internal web application as a TypeScript modular monolith. The browser UI calls a server-side REST API. The API uses PostgreSQL for durable application state and integrates with Datacom's existing SSO and employee directory. No separate password or account service is introduced.

### Proposed stack

| Area | Proposal | Rationale |
|---|---|---|
| Web UI | React with TypeScript and Vite | Familiar component-based UI; straightforward deployment as static assets. |
| API | Node.js with TypeScript and Express | Small REST service with a broad ecosystem and low operational complexity. |
| Persistence | PostgreSQL | Relational constraints suit employee relationships, likes, reports, and notifications. |
| Database access | Prisma ORM and migrations | Typed access and repeatable schema evolution. |
| Identity | Existing company SSO, preferably OIDC; validate sessions/tokens server-side | Reuses the mandated company identity system. Exact integration depends on Datacom's available contract. |
| Tests | Vitest for unit/API tests; browser-level tests with the repository's chosen runner | Supports focused validation of business rules and core user flows. |

These are proposals, not assumptions about existing infrastructure. Confirm them against Datacom standards before implementation. If the internal portal mandates a framework, API gateway, database, or authentication adapter, adopt that standard rather than adding a parallel platform.

## 2. Components and responsibilities

1. **Web client**
   - Dashboard feed, employee lookup, create-Kudos form, likes, report form, recipient notifications, and administrator report/moderation screens.
   - Performs friendly client-side validation but treats the API as authoritative.
   - Does not hold SSO secrets or determine authorization by itself.
2. **REST API**
   - Authenticates each request using the approved SSO integration.
   - Resolves a trusted employee identifier and Employee/Administrator role.
   - Enforces business validation, access controls, duplicate detection, and rate limits.
   - Reads/writes Kudos, reactions, reports, notifications, and audit records.
3. **PostgreSQL**
   - Stores application records with foreign keys, uniqueness constraints, and indexes.
   - Stores an employee reference keyed by the stable SSO subject; retain only necessary directory fields.
4. **SSO and employee directory**
   - SSO authenticates employees; a trusted claim or authorization service supplies roles.
   - Directory lookup supplies eligible recipients and names for search. Do not trust employee identifiers or roles asserted only by client input.

## 3. Request and data flows

### 3.1 Sign-in and authorization

The browser obtains or uses the existing portal session. Every API request is authenticated server-side. The API maps the trusted SSO subject to an employee record and role. A centralized authorization middleware protects administrator routes; services also enforce ownership and record-visibility rules.

If the portal uses cookies, configure secure, HTTP-only, same-site cookies and CSRF protection appropriate to the integration. If it uses bearer tokens, validate signature, issuer, audience, expiry, and relevant claims on the server. Never store long-lived credentials in browser local storage.

### 3.2 Create Kudos

The client submits recipient ID, message, and an idempotency key. The API authenticates the sender, validates recipient eligibility and message length/content, applies duplicate and rate-limit checks, then persists the Kudos and recipient notification in one database transaction. A request replay with the same idempotency key returns the original result. A rapid content duplicate or rate-limit violation returns a conflict or too-many-requests response and does not create data.

### 3.3 Feed, search, and likes

The feed API returns published Kudos newest first using cursor pagination. Search uses employee display names for either sender or recipient and returns only published records. Likes use a unique `(kudos_id, employee_id)` constraint; a repeated like is idempotent. Only a published Kudos can be liked.

### 3.4 Reports and moderation

An employee report creates a report record without changing post visibility. The administrator queue returns reports and associated post/employee context to administrators only. Hide/delete operations update visibility and create an audit record in a transaction. Hiding or deleting prevents subsequent employee feed, search, like, and report interactions. Report and audit access must remain restricted.

## 4. REST API proposal

All endpoints require an authenticated employee unless stated otherwise. Exact payload and error schemas should be standardized during implementation.

| Method and path | Purpose | Authorization |
|---|---|---|
| `GET /api/me` | Return current employee's minimal profile and role | Employee |
| `GET /api/employees?query=...` | Search eligible recipients | Employee |
| `GET /api/kudos?cursor=...&employee=...` | Paginated published feed, optionally searched by sender or recipient | Employee |
| `POST /api/kudos` | Create Kudos; require idempotency key | Employee |
| `POST /api/kudos/{id}/likes` | Like a published Kudos | Employee |
| `DELETE /api/kudos/{id}/likes/me` | Remove current employee's like | Employee |
| `GET /api/notifications?cursor=...` | List current employee's notifications | Employee, own records only |
| `PATCH /api/notifications/{id}` | Mark current employee's notification read | Employee, own records only |
| `POST /api/kudos/{id}/reports` | Report a published Kudos | Employee |
| `GET /api/admin/reports?status=...` | Review report queue | Administrator |
| `PATCH /api/admin/reports/{id}` | Set report review status | Administrator |
| `POST /api/admin/kudos/{id}/hide` | Hide a Kudos, with optional reason | Administrator |
| `DELETE /api/admin/kudos/{id}` | Delete a Kudos, with optional reason | Administrator |

Use consistent `400` validation, `401` unauthenticated, `403` unauthorized, `404` unavailable/not found, `409` duplicate/idempotency conflict, and `429` rate-limit responses without leaking restricted record existence.

## 5. Data model

Suggested logical tables; exact Prisma/schema types are implementation details.

- **Employee**: `id` (internal key), `sso_subject` (unique), `display_name`, optional directory metadata needed for lookup, `role`, timestamps.
- **Kudos**: `id`, `sender_id`, `recipient_id`, `message`, `status` (`PUBLISHED`, `HIDDEN`, `DELETED`), `created_at`, moderation timestamps/actor where useful.
- **KudosLike**: `kudos_id`, `employee_id`, `created_at`; unique `(kudos_id, employee_id)`.
- **Report**: `id`, `kudos_id`, `reporter_id`, `reason`, optional `detail`, `status` (`PENDING`, `UNDER_REVIEW`, `RESOLVED`, `DISMISSED`), timestamps, reviewer and resolution metadata.
- **Notification**: `id`, `recipient_id`, `kudos_id`, type, `created_at`, `read_at`; unique constraint for one Kudos-received notification per Kudos recipient.
- **ModerationAudit**: `id`, `administrator_id`, `kudos_id`, optional `report_id`, action, reason, `created_at`.
- **IdempotencyRecord**: employee, idempotency key, request fingerprint, resulting Kudos ID, creation/expiry timestamps; unique `(employee_id, key)`.
- **CreationRateWindow** (or approved shared rate-limit store): employee, window start, request count; atomic updates enforce the configured limit across API instances.

Use database constraints as a second line of defense: message length/non-empty checks where practical, valid foreign keys, unique SSO subject, unique likes, and idempotency uniqueness. Add indexes for feed ordering, sender/recipient joins, employee names, notification listing, and report status. Use cursor pagination to avoid increasingly expensive offsets.

## 6. Validation, duplicate detection, and spam controls

- Trim surrounding whitespace and reject empty messages. Enforce the 500-character limit consistently in client and API; the API is authoritative.
- Render messages as text, not executable markup. Apply output encoding in the UI and avoid accepting HTML.
- Generate an idempotency key per form attempt and reuse it for network retries. Prevent concurrent submit actions in the UI.
- Additionally compare a normalized message, sender, and recipient against recent submissions within the configurable duplicate window (proposed 60 seconds). Return a clear duplicate response; do not silently treat an unrelated request as success.
- Enforce the proposed per-employee 5-per-minute create limit using an atomic, shared counter. Prefer an existing gateway/shared rate-limit facility; otherwise use the database-backed window. Return `429` and a retry indication.
- Do not log full message text, SSO tokens, or report detail in routine request logs.

## 7. Moderation and deletion semantics

- `PUBLISHED` is visible and interactive for employees.
- `HIDDEN` is not visible or interactive to employees; administrators may inspect it during moderation.
- `DELETED` is not visible or interactive to employees. Retention of the message body in restricted audit storage versus physical purge must be determined by Datacom policy.
- Every administrative hide/delete and report decision records actor, time, action, and supplied reason. Do not allow moderation through client-side role checks alone.

## 8. Security, privacy, and operations

- Use TLS in transit and the approved company secret-management mechanism.
- Validate SSO issuer/audience/signature and use least-privilege authorization.
- Apply CSRF defenses for cookie sessions, CORS allowlists, security headers, safe error responses, and request size limits.
- Use ORM parameterization; validate all path, query, and body input. Prevent mass assignment by mapping accepted fields explicitly.
- Restrict employee and report data to authenticated users and relevant roles. Avoid returning internal identifiers or directory attributes without a need.
- Use database backups and migrations through the organization's standard deployment process. Configure credentials and SSO endpoints outside source control.
- Monitor API errors, latency, throttling, and moderation activity with privacy-conscious logs. Define deployment, backup, recovery, and retention standards before launch.

## 9. Assumptions and unresolved design inputs

- The company provides an OIDC-compatible SSO integration or an equivalent trusted identity gateway.
- Directory lookup and role claims/API are available to the application. Their exact contracts, lifecycle, and failure behavior are not known.
- Initial notifications are persisted in-app notifications; email delivery is not included.
- The standalone React client plus API deployment is acceptable. Portal embedding may change routing, session, and CSRF details.
- PostgreSQL and the proposed TypeScript stack are acceptable under Datacom engineering standards.
- Duplicate window and rate limit values in `requirements.md` are proposed defaults requiring stakeholder approval.
- Data retention, hosting region, accessibility target, expected usage, and production service-level objectives remain to be agreed.
