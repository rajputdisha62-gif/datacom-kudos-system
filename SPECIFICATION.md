# Datacom Kudos System Specification

**Status:** Consolidated draft for review; implementation not started  
**Version:** 1.1  
**Date:** 2026-11-13

## 1. Purpose and scope

Provide authenticated Datacom employees an internal application for recognizing colleagues with public Kudos. Employees can select a colleague, submit a message, browse and search the shared feed, like posts, receive in-app notifications, and report inappropriate content. Administrators can review reports, hide or delete Kudos, and inspect moderation history.

The initial release excludes comments, private Kudos, categories, leaderboards, gamification, a new password/account system, email/SMS/push notifications, editing published messages, analytics, and organization-wide performance ranking.

## 2. User stories and permissions

1. As an authenticated employee, I can select another eligible colleague from a directory-backed list.
2. As an authenticated employee, I can write and submit a message of appreciation within the 500-character limit.
3. As an authenticated employee, I can view a recent shared feed and search by sender or recipient name.
4. As an authenticated employee, I can like/unlike Kudos, receive notifications addressed to me, and report inappropriate content.
5. As an administrator, I can review reports, inspect hidden Kudos, hide/delete inappropriate content, and inspect moderation history.
6. As an employee using desktop, tablet, or mobile, I can operate the application with keyboard and assistive technology.

### Permissions

- **Employee:** View/search published Kudos; select a valid recipient; create Kudos; like/unlike; view own notifications; report published Kudos.
- **Administrator:** All employee capabilities; view/manage reports; hide/delete Kudos; inspect moderation history and hidden Kudos.

All users authenticate through company SSO. The server derives employee identity and role from a trusted SSO/authorization source. Role assignment is controlled by an approved company mechanism; employees cannot grant themselves administrator access. Authorization and record ownership are enforced server-side on every protected API request.
## 3. Functional requirements

### FR-1: Identity and access

1. Require an authenticated company SSO session for all application data and operations.
2. Resolve a stable employee identifier and trusted Employee/Administrator role on the server.
3. Deny unauthenticated requests and deny employees administrator operations even when invoked directly by API.
4. Limit employee access to their own notifications and report-submission confirmations; only administrators can access the report queue and moderation history.

### FR-2: Recipient selection and Kudos creation

1. Employees select recipients from the approved employee directory. The recipient must be a valid employee distinct from the sender.
2. Messages must contain at least one non-whitespace character and no more than 500 characters. Trim surrounding whitespace; render content as text, never executable markup.
3. Reject invalid submissions with a clear error and create neither a Kudos nor a notification.
4. A successful Kudos is public to all authenticated employees and appears newest first in the feed.
5. Feed loading is bounded through cursor pagination or an equivalent approach; do not load all history at once.
6. Hidden and deleted Kudos are excluded from all employee-facing feed and search results. Hidden Kudos remain reviewable by authorized administrators. Hidden/deleted Kudos cannot be liked or otherwise interacted with by employees. Deleted content is unavailable to employees; physical purge versus restricted retention follows approved policy.

### FR-3: Employee search

1. Employees search Kudos by employee name; match both sender and recipient names.
2. Employee search returns published Kudos only and follows the feed visibility rules. Hidden/deleted posts must not leak through filters, counts, cursors, or alternate API routes.
3. Search does not disclose employee/post data to unauthenticated users. Administrator review access to hidden content is separately authorized.

### FR-4: Likes

1. Authenticated employees can like a published Kudos and remove their own like.
2. Enforce at most one active like per employee per Kudos; display count and current employee's like state.
3. Reject likes on hidden or deleted Kudos.

### FR-5: Notifications

1. On successful publication, create an in-app notification for the recipient identifying the sender and linking to the Kudos.
2. A failed/rejected/duplicate submission must not create another notification. Persist Kudos and notification atomically.
3. Employees can view and mark read only their own notifications. Read state does not change the Kudos.

### FR-6: Reports

1. An employee can report a published Kudos. The report references the post and reporting employee, requires a reason, and may include optional detail.
2. Confirm report submission to the reporter. The report does not automatically hide/delete a post.
3. Administrators can view report and the identities/post context needed for review, and transition reports among pending, under review, resolved, and dismissed.
4. Employees cannot inspect other employees' reports or the administrator queue.

### FR-7: Moderation

1. Administrators may hide a Kudos, making it invisible and non-interactive to employees while retaining it for administrator moderation review.
2. Administrators may delete a Kudos, making its message unavailable to employees. Physical purge or restricted audit retention is governed by Datacom retention policy.
3. Every hide and delete action must create a durable audit record with administrator employee ID, action type, timestamp, and moderation reason when supplied. Audit records are restricted to authorized administrators.
4. Moderation endpoints enforce administrator authorization on the server. Moderation history must identify the action, actor, time, target, and supplied reason.

### FR-8: Duplicate, replay, and spam controls

1. Prevent simultaneous duplicate submits from one UI form action.
2. Require an idempotency key for create requests. Reuse the key on network retries; replay returns the original result and must not create another Kudos or notification. Detect key reuse with a different request fingerprint and return a conflict.
3. Additionally reject a repeated sender, recipient, and normalized message within a configurable duplicate window. Proposed default: 60 seconds.
4. Enforce an atomic, per-employee creation limit across API instances. Proposed default: 5 Kudos per employee per minute, configurable. Return a clear rate-limit response with retry guidance.
5. Rejected duplicate or rate-limited requests create no Kudos or notification. Do not silently collapse a distinct request into success.

### FR-9: Responsive and accessible interface

1. Work correctly at desktop, tablet, and mobile screen sizes. Forms, feed cards, search controls, and moderation interfaces adapt to available screen size.
2. Support keyboard navigation throughout; provide accessible labels for every form control and appropriate screen-reader support for content, controls, status changes, and validation/errors.

## 4. Non-functional requirements

- **Security:** Validate all inputs; use parameterized database access; explicitly map accepted request fields; enforce authorization on every protected operation; protect cookie sessions against CSRF; secure token/session handling; use TLS, safe errors, request-size limits, CORS allowlists, and security headers; do not expose secrets.
- **Privacy:** Store only employee identifiers/display data needed for recognition, search, notifications, and moderation. Never expose SSO tokens or unnecessary directory attributes to the browser. Avoid routine logging of messages, report detail, tokens, or sensitive identity data.
- **Consistency:** Kudos and recipient notification commit atomically. Database uniqueness and idempotency prevent duplicate effects under concurrent requests.
- **Performance:** Index feed ordering, sender/recipient lookup, notifications, and report status. Paginate feed/search. Agree expected volumes and service targets before production; caching may be introduced only with visibility-safe invalidation.
- **Usability/accessibility:** Clear validation, permission, duplicate, and rate-limit messages. Meet the responsive and keyboard/screen-reader requirements above.
- **Maintainability/operations:** Typed documented stack, migrations, automated tests, environment-specific configuration, monitoring, backups, recovery and retention procedures aligned with Datacom standards.
- **Auditability:** Durable restricted moderation audit; privacy-conscious operational logs.

## 5. Acceptance criteria

1. Signed-out users cannot access protected pages or APIs; an authenticated employee can use employee features.
2. Employee can select a different valid colleague and publish a valid message; it appears once in the newest-first feed.
3. Empty, whitespace-only, over-500-character, invalid-recipient, and self-addressed messages are rejected without a Kudos or notification.
4. Search by sender or recipient name finds published posts; hidden/deleted posts are absent from employee feeds and search, including pagination and direct lookup paths.
5. An authorized administrator can locate and review hidden Kudos; an employee cannot retrieve or interact with hidden/deleted Kudos. Deleted content is not employee-accessible.
6. Repeated like requests do not increase a user's count more than once; unlike removes that user's like; hidden/deleted posts reject likes.
7. A recipient receives an in-app notification only after successful creation and can access only their own notifications/read state.
8. An employee can report a published post and receive confirmation; other employees cannot inspect the report. Reporting alone does not change visibility.
9. Administrators can review and transition reports and hide/delete a post. Employees calling the same admin endpoints are denied.
10. Each hide/delete action records administrator ID, action type, timestamp, and supplied reason; authorized admins can inspect moderation history.
11. Same-key retries return the original create outcome without another post/notification; mismatched key reuse is rejected. Rapid duplicate content is rejected according to configured window.
12. Requests above the configured creation limit are rejected with retry guidance and create no post/notification, including under concurrent load.
13. Forms, cards, search, and moderation screens remain usable and adapt at desktop, tablet, and mobile sizes.
14. Keyboard-only users can operate the application; form controls have accessible labels; screen readers receive meaningful content, control names, statuses, and errors.
15. Validation and authorization failures do not leak protected record existence or internal details; routine logs do not contain full message text, tokens, or unnecessary sensitive data.

## 6. Technical design

### 6.1 Proposed architecture and stack

A TypeScript modular monolith: React + TypeScript + Vite web client, Node.js + TypeScript + Express REST API, PostgreSQL, and Prisma ORM/migrations. Integrate the existing company SSO (prefer OIDC if available) and approved employee directory. These are proposals pending Datacom engineering standards. Adopt mandated internal frameworks, gateways, databases, hosting, or identity adapters where required; do not create parallel identity infrastructure.

### 6.2 Components

- **Web client:** Dashboard/feed, recipient lookup and Kudos form, employee search, like controls, report form, notification list/read state, administrator queue, report status controls, and hide/delete actions. Client validation improves usability but is not authoritative. Responsive and keyboard/screen-reader accessible.
- **REST API:** Authenticates each request, maps trusted subject/role, applies validation and visibility/ownership rules, handles idempotency/rate limiting, and coordinates persistence.
- **PostgreSQL:** Durable relational records, foreign keys, uniqueness/check constraints, visibility-filtered queries, indexes, transactions.
- **SSO/directory adapters:** Server-trusted identity and role; approved directory supplies eligible recipients and display names. Define behavior for revocation, directory outages, and stale records before implementation.

### 6.3 Data model

Logical schema; exact Prisma types and physical names are implementation details.

- **Employee:** `id` internal key, unique `sso_subject`, `display_name`, minimal required directory metadata, trusted role, timestamps.
- **Kudos:** `id`, `sender_id`, `recipient_id`, `message` (max 500, nonblank), `status` (`PUBLISHED`, `HIDDEN`, `DELETED`), `created_at`, optional moderation metadata. `status` is the single authoritative visibility state and replaces a separate `is_visible` boolean to avoid contradictory state. `PUBLISHED` corresponds to visible; `HIDDEN`/`DELETED` are not employee-visible. If the selected database needs a boolean for query/index optimization, it must be derived/maintained transactionally from `status`, never independently writable.
- **KudosLike:** `kudos_id`, `employee_id`, `created_at`; unique `(kudos_id, employee_id)`.
- **Report:** `id`, `kudos_id`, `reporter_id`, `reason`, optional `detail`, `status` (`PENDING`, `UNDER_REVIEW`, `RESOLVED`, `DISMISSED`), timestamps, reviewer/resolution metadata.
- **Notification:** `id`, `recipient_id`, `kudos_id`, type, `created_at`, `read_at`; uniqueness preventing duplicate received notification for a Kudos/recipient.
- **ModerationAudit:** `id`, `administrator_id`, `kudos_id`, optional `report_id`, action (`HIDE`, `DELETE`; optionally report status transition if approved), `reason` nullable, `created_at`. Append an audit row in the same transaction as each hide/delete state change. Preserve historical rows when status changes again.
- **IdempotencyRecord:** employee, key, request fingerprint, resulting Kudos ID, created/expiry times; unique `(employee_id, key)`.
- **CreationRateWindow** or approved shared rate-limit store: employee, window start, request count; atomic update across instances.

Use foreign keys and constraints for valid sender/recipient, non-self recipient, message bounds, unique SSO subject, unique likes, and idempotency. Index status/feed order, sender/recipient, names used for search, notification owner/order, and report status/order. Employee queries must include `status = PUBLISHED` in database query constraints; do not fetch hidden/deleted rows and rely only on UI filtering. Admin moderation queries have separate server-authorized visibility rules. Test direct-ID, count, search, pagination, and interaction paths for leaks.

### 6.4 API proposal

All routes require an authenticated employee unless marked admin; role/ownership checks happen server-side. JSON schemas and error envelope are standardized before implementation.

| Method and path | Purpose | Access |
|---|---|---|
| `GET /api/me` | Minimal current employee profile/role | Employee |
| `GET /api/employees?query=...` | Search eligible recipients | Employee |
| `GET /api/kudos?cursor=...&employee=...` | Cursor-paginated published feed/search by sender or recipient | Employee; published only |
| `POST /api/kudos` | Create Kudos; idempotency key required | Employee |
| `POST /api/kudos/{id}/likes` | Like published post | Employee |
| `DELETE /api/kudos/{id}/likes/me` | Remove own like | Employee |
| `GET /api/notifications?cursor=...` | List own notifications | Employee; own rows only |
| `PATCH /api/notifications/{id}` | Mark own notification read | Employee; own rows only |
| `POST /api/kudos/{id}/reports` | Report a published post | Employee |
| `GET /api/admin/reports?status=...` | Report review queue and relevant context | Administrator |
| `PATCH /api/admin/reports/{id}` | Transition report status | Administrator |
| `GET /api/admin/kudos?status=HIDDEN...` | Moderation lookup including hidden posts | Administrator |
| `POST /api/admin/kudos/{id}/hide` | Hide with optional reason | Administrator |
| `DELETE /api/admin/kudos/{id}` | Delete with optional reason | Administrator |
| `GET /api/admin/moderation-audit?...` | Review restricted moderation history | Administrator |

Use consistent `400` validation, `401` unauthenticated, `403` unauthorized, `404` unavailable/not found, `409` duplicate/idempotency conflict, and `429` rate-limit responses. Avoid leaking whether restricted IDs exist. Success/error payloads, cursor semantics, reason length, and audit query filters are implementation contracts to finalize before coding.

### 6.5 Create and moderation transaction rules

For create: authenticate sender; validate directory recipient and message; atomically claim idempotency key; check rapid duplicate; increment shared rate counter; write Kudos and recipient notification in one transaction; return stable result. Define transaction/order semantics so a rate-limited or duplicate request cannot leave a partial idempotency record or notification. Same-key retry returns stored outcome; same key with different fingerprint returns `409`.

For hide/delete: authorize admin; update post status and insert audit row in one transaction. Hidden content remains retrievable through admin review only. Delete behavior (soft delete versus purge and whether minimal tombstone/audit references survive) follows retention approval. Employee feed/search/report/like operations must check published status in database predicates.

### 6.6 Security, errors, and logging

Validate all path/query/body fields server-side; map allowed fields explicitly; parameterize SQL via ORM. Validate OIDC issuer, audience, signature, expiry and trusted role claims or equivalent gateway assertions. For cookies use secure, HTTP-only, same-site settings and CSRF defense. For bearer tokens validate server-side and never store long-lived credentials in browser local storage. Apply TLS, CORS allowlists, security headers, request limits, safe error responses, least privilege, and secrets management. Log request IDs, outcome, latency, throttling, and moderation event references as appropriate; exclude message bodies, report details, tokens, and unnecessary personal data.

### 6.7 Performance, accessibility, and deployment

Use cursor pagination and indexes for feed/search/admin queue. Agree expected employee/post volumes, latency/availability targets, and any cache policy before rollout; caches must not make hidden/deleted content visible. Verify responsive behavior and WCAG target with Datacom accessibility owners. Use environment-specific configuration, migrations, backups, restore procedures, monitoring, and retention controls under Datacom deployment standards.

## 7. Implementation plan (deferred until approval)

No source code is authorized or started by this specification. The phases below describe future work. Documented choices and unavailable Datacom details use the simulation assumptions in Section 8. No implementation begins until the user explicitly approves this final specification.

### Phase 0 — Final specification approval

1. Review this consolidated specification and its simulation assumptions.
2. Treat the listed architecture, limits, integrations, and policy placeholders as the working assumptions for this Forage simulation.
3. Begin implementation only after the user explicitly approves this final specification.

**Exit:** The user has explicitly approved the final specification. External Datacom confirmations are not prerequisites for this simulation; replace assumptions with actual standards if the project moves beyond the simulation.

### Phase 1 — Foundation and identity

1. Set up approved client/API project, TypeScript checks, linting, test runner, and environment config.
2. Integrate company SSO and map trusted identity/role server-side.
3. Add protected routes and authorization middleware; verify employee/admin separation and role revocation.

**Exit:** Protected entry and role enforcement are verified.

### Phase 2 — Persistence and core Kudos

1. Create migrations/schema for employee references, Kudos, idempotency, notifications, constraints and indexes.
2. Integrate approved recipient directory lookup.
3. Implement creation validation, idempotency, duplicate detection, and atomic shared rate limiting.
4. Persist Kudos + notification transactionally; implement cursor feed/search with database visibility predicates.

**Exit:** Employee can create a valid Kudos once and see it once with one notification; invalid/replayed/duplicate/rate-limited cases leave no extra effects.

### Phase 3 — Employee interactions

1. Implement like/unlike and uniqueness enforcement.
2. Implement reports and ownership-limited confirmation.
3. Implement notification listing/read state with ownership checks.
4. Complete responsive accessible employee UI.

**Exit:** Employee workflows and visibility/ownership rules meet acceptance criteria.

### Phase 4 — Administration and moderation

1. Implement admin report queue and status transitions.
2. Implement admin-only hidden-content review, hide/delete, and transactional audit records.
3. Verify hidden/deleted exclusions across every employee feed, search, detail and interaction route.

**Exit:** Admin moderation works and unauthorized users are denied; each hide/delete is audited.

### Phase 5 — Quality and release readiness

1. Run unit, integration/API, browser acceptance, and regression checks mapped to acceptance criteria.
2. Run type/lint, security/dependency checks, accessibility review, and responsive verification.
3. Validate pagination/search, concurrent idempotency/duplicates, rate limits, and transaction behavior.
4. Verify privacy-safe logging, session/CSRF/CORS settings, migrations, backups/restore, monitoring, and deployment/retention procedures.
5. Conduct stakeholder acceptance and resolve findings before release.

**Exit:** Acceptance criteria and Datacom security, operational, and deployment reviews are complete.

### Test strategy

- **Unit:** Validation/normalization, visibility predicates, role/ownership checks, idempotency, duplicate window, rate limit.
- **Integration:** Foreign keys/constraints, transaction consistency, notification uniqueness, audit atomicity, concurrent create/retry behavior, SSO/directory adapters with approved fixtures.
- **Authorization/API:** Signed-out rejection, employee ownership boundaries, admin routes, hidden/deleted data isolation, direct-ID and pagination leakage checks.
- **End-to-end:** Sign-in, recipient selection, create/feed/search, like/unlike, notification/read, report, admin review/hide/delete/audit.
- **Accessibility/responsive:** Keyboard-only use, labels and screen-reader announcements, desktop/tablet/mobile layouts.
- **Operational:** Config validation, migrations, recovery, retention, privacy-safe monitoring in non-production.

### Dependencies and risks (simulation assumptions)

| Dependency/risk | Simulation handling |
|---|---|
| SSO contract and trusted role source unknown | Use the trusted OIDC/equivalent assumption in Section 8; validate with identity owners before production use. |
| Directory contract unknown | Use the directory adapter and minimal-data assumptions in Section 8; validate the real contract before production use. |
| Portal embedding affects auth/session/CSRF | Use standalone deployment as the simulation baseline; revisit if actual portal embedding is required. |
| Duplicate/rate defaults may block legitimate recognition | Use configurable 60-second and 5-per-minute simulation defaults; adjust if the simulation needs it. |
| Delete/audit retention policy unknown | Apply the stated hide/delete semantics; production retention must be validated with policy owners. |
| Scale/accessibility/SLO targets unspecified | Treat accessibility and performance goals as simulation acceptance checks; define numeric production targets before deployment. |

## 8. Simulation assumptions and final approval gate

Actual Datacom contracts and policies are unavailable for this Forage simulation. The following are explicit working assumptions, not verified facts:

1. **Identity:** Company SSO is represented by an OIDC-compatible provider or trusted equivalent. It supplies a stable employee subject. Administrator status comes from a trusted server-validated role claim or authorization service; employees cannot self-assign it. The simulation assumes role changes/revocation are reflected by that trusted source.
2. **Directory:** An approved employee-directory service is represented as available for eligible-recipient selection and display-name lookup for sender/recipient search. Store only the minimum identifier/display data required.
3. **Architecture:** React/TypeScript/Vite, Node.js/TypeScript/Express, PostgreSQL, and Prisma are the simulation stack. Assume standalone deployment unless portal integration is later specified. These choices yield to actual Datacom platform standards outside the simulation.
4. **Duplicate and rate controls:** Use a configurable 60-second duplicate window and 5 Kudos per employee per minute as simulation defaults.
5. **Moderation and retention:** Hide is reversible/non-destructive and preserves the post for administrator review. Delete removes the post from employee access; whether content is physically purged or retained in restricted audit storage is policy-dependent. Every hide/delete audit includes admin ID, action, timestamp, and supplied reason.
6. **Accessibility and performance:** Responsive desktop/tablet/mobile behavior, keyboard operation, accessible labels, and screen-reader support are required. A specific WCAG conformance level, load profile, latency objective, and availability target are not supplied; assume these are verified against the selected simulation environment before any production use.
7. **API details:** The listed REST paths, status codes, cursor pagination, and JSON behavior are proposed contracts. Exact request/response schemas and report-status audit behavior can be finalized during implementation planning; they do not weaken required visibility, ownership, or hide/delete audit rules.
8. **Operations:** Assume TLS, environment-managed secrets, migrations, backups, restore procedures, privacy-conscious monitoring, and deployment controls are available in the chosen simulation environment.

### Explicit approval gate

This specification is ready for the user's final review and approval. **Do not begin implementation until the user explicitly approves this final specification.** Approval authorizes proceeding with this specification's simulation assumptions; it does not claim the assumptions have been confirmed by Datacom. If the work is later intended for actual Datacom production, validate the assumptions with the relevant identity, platform, accessibility, security, and data-retention owners first.