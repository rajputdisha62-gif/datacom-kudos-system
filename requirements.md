# Datacom Kudos System — Requirements Specification

**Status:** Draft for review  
**Version:** 1.0  
**Date:** 2026-11-13

## 1. Purpose

Provide Datacom employees with an authenticated internal application for publicly recognizing colleagues. Employees can publish Kudos, view and search the shared feed, react to posts, receive notifications, and report inappropriate content. Administrators can review reports and moderate posts.

## 2. Goals

- Make it straightforward for an authenticated employee to recognize another employee.
- Make published Kudos visible to all authenticated employees.
- Give employees a simple way to find, like, and report posts.
- Give administrators the ability to review reports and hide or delete inappropriate posts.
- Reuse company authentication and employee identity rather than creating a separate account system.

## 3. Users and permissions

| Role | Permissions |
|---|---|
| Employee | View the published feed; search Kudos by employee name; create Kudos; like and unlike Kudos; receive notifications for Kudos addressed to them; report a Kudos. |
| Administrator | All employee capabilities, plus view and manage reports, hide or delete Kudos, and review moderation history. |

Users must be authenticated through the existing company SSO. Authorization must be enforced by the server, not just by hiding controls in the user interface. Administrator role assignment is managed by an approved company identity/authorization mechanism; the application must not let employees grant themselves that role.

## 4. Scope

### In scope for the initial release

- Public Kudos messages in a shared dashboard feed.
- Recipient selection from the company employee directory.
- Message validation: non-empty and no more than 500 characters.
- Employee-name search across Kudos senders and recipients.
- One like per employee per Kudos, with the ability to remove that like.
- In-app notification to the recipient when a Kudos is published.
- Employee reporting of potentially inappropriate Kudos.
- Administrator review of reports and hide/delete moderation actions.
- Duplicate-submission and repeated-submission protection.

### Out of scope for the initial release

- Comments, private Kudos, categories, leaderboards, and gamification.
- A new authentication system or locally managed employee passwords.
- Email, SMS, or push notifications.
- Editing a published message, unless a later approved requirement adds it.
- Analytics or organization-wide performance ranking.

## 5. Functional requirements

### FR-1: Sign-in and access

1. The application must require an authenticated company SSO session.
2. Unauthenticated users must not be able to access the feed, employee search, Kudos, reports, or notification data.
3. The application must identify the signed-in employee and their Employee or Administrator role from a trusted source.
4. The application must deny employee access to administrator-only operations, including when those operations are called directly through an API.

### FR-2: Create and display Kudos

1. An employee can select another employee as the recipient and submit a message.
2. The recipient must be a valid employee distinct from the sender.
3. Messages must contain at least one non-whitespace character and be at most 500 characters.
4. The system must reject invalid submissions and explain the validation error without creating a Kudos.
5. A successfully published Kudos is public to all authenticated employees and appears in the main feed, newest first.
6. Hidden and deleted Kudos must not appear in employee-facing feeds or employee search results. Hidden Kudos must remain available to administrators in moderation review, subject to administrator authorization. Deleted Kudos must be unavailable to employees; retention for restricted audit purposes follows the applicable retention policy.
7. The feed must support pagination or an equivalent bounded-loading approach; it must not require loading the entire history at once.

### FR-3: Search

1. Employees can search Kudos using an employee name.
2. Search matches the sender's or recipient's employee name.
3. Search results must obey the same visibility rules as the main feed.
4. Search must not expose employee or post data to unauthenticated users. Hidden and deleted Kudos must be excluded from employee search results; hidden Kudos remain available to authorized administrators for moderation review.

### FR-4: Reactions

1. An authenticated employee can like a published Kudos and remove their own like.
2. The system must allow at most one active like per employee per Kudos.
3. The feed must display a like count and whether the current employee has liked the Kudos.
4. Likes must not be allowed on hidden or deleted Kudos.

### FR-5: Notifications

1. When a Kudos is successfully published, the recipient receives an in-app notification identifying the sender and linking to the Kudos.
2. A notification must not be created for a failed or rejected submission.
3. An employee can view only their own notifications.
4. Notifications should provide a read/unread state; marking a notification read must not change the Kudos.

### FR-6: Reports

1. An authenticated employee can report a published Kudos to administrators.
2. A report must reference the reported Kudos and the reporting employee. The report form must collect a reason; optional detail may be provided.
3. The employee must receive confirmation that the report was submitted.
4. Employees can view only their own report-submission confirmation, not other employees' reports or the administrator review queue.
5. A report does not automatically hide or delete its Kudos.

### FR-7: Administration and moderation

1. An administrator can view submitted reports and the associated Kudos and employee identities needed for review.
2. An administrator can mark a report as under review, resolved, or dismissed.
3. An administrator can hide a Kudos so employees cannot see or interact with it.
4. An administrator can delete a Kudos so its message is no longer available to employees.
5. Moderation actions must be restricted to administrators. Every hide and delete action must record the acting administrator’s employee ID, action type, and timestamp, plus the moderation reason when one is provided.
6. The system must retain the minimum information required to support report review and moderation audit. The retention and purge period is a deployment/policy decision.

### FR-8: Duplicate and spam protection

1. The client must prevent multiple simultaneous submissions from one form action.
2. The API must handle retried submissions idempotently so a network retry does not create another Kudos.
3. The system must reject a rapid repeat with the same sender, recipient, and normalized message within a configurable duplicate-detection window.
4. The system must apply a per-employee request limit to Kudos creation and return a clear retry response when exceeded.
5. Rejected duplicate or rate-limited requests must not create Kudos or recipient notifications.

## 6. Non-functional requirements

- **Security:** Validate and sanitize input; use parameterized database access; enforce authorization on every protected API operation; protect against CSRF where cookie-based authentication is used; secure session/token handling; avoid exposing internal errors or secrets.
- **Privacy:** Limit employee data to what is needed for recognition, search, notifications, and moderation. Do not expose SSO tokens or private identity attributes to the browser.
- **Availability and consistency:** A successful create operation must persist the Kudos and notification reliably. Duplicate submissions must not cause duplicate records or notifications.
- **Usability:** Provide clear validation, permission, duplicate, and rate-limit messages. The application must work correctly on desktop, tablet, and mobile screen sizes; forms, feed cards, search controls, and moderation interfaces must adapt to each size.
- **Accessibility:** Support keyboard navigation throughout the application, provide accessible labels for all form controls, and include appropriate screen-reader support for content, status, errors, and interactive controls.
- **Maintainability:** Use a documented, typed application stack, database migrations, automated tests, and configuration through environment-specific settings.
- **Performance:** Feed and search must be paginated and indexed for expected employee and post volumes. Performance targets should be agreed before production rollout.
- **Auditability:** Record every hide and delete action with the administrator employee ID, action type, timestamp, and reason when provided. Avoid logging message contents, identity tokens, or other sensitive values unnecessarily.

## 7. Acceptance criteria

1. A signed-out visitor cannot load protected pages or call protected APIs; a signed-in employee can.
2. An employee can publish a valid message to another employee and see it in the public feed.
3. Empty, whitespace-only, over-500-character, or self-addressed submissions are rejected with no persisted Kudos or notification.
4. A sender can be found through search by either sender or recipient name; hidden/deleted posts are absent.
5. Repeated likes by the same employee do not increase the count more than once; unlike reverses that employee's like.
6. A recipient gets an in-app notification only after successful creation and can see only their own notifications.
7. An employee can submit a report; another employee cannot inspect it.
8. An administrator can review a report and hide or delete its post; an employee calling the same moderation API is denied.
9. A retried or rapid duplicate submission does not create an extra Kudos or notification.
10. Requests over the configured creation limit are rejected without creating a Kudos.
11. Hidden Kudos are excluded from employee feeds and search results, but an administrator can still access them in moderation review; employees cannot interact with them.
12. Each hide and delete action produces an audit record containing the administrator ID, action type, and timestamp, and includes the reason when provided.
13. The application remains usable at desktop, tablet, and mobile screen sizes, with forms, feed cards, search controls, and moderation interfaces adapting to the available screen size.
14. All application functions are operable by keyboard, form controls have accessible labels, and screen readers receive appropriate content, status, error, and control information.

## 8. Assumptions and decisions to confirm

- The existing SSO can provide a stable employee identifier and a trusted way to determine administrator authorization.
- An approved directory lookup is available for recipient selection and sender/recipient name search. The application will store only the employee identifiers and display data it needs.
- Notifications are in-app only for the initial release.
- Employee-name search includes both sender and recipient; this interprets “search Kudos by employee name” broadly.
- “Delete” means the post is removed from employee-facing views and interactions. Whether its content is physically purged or retained in restricted audit storage must follow Datacom retention policy.
- Initial duplicate detection will use the same sender, recipient, and normalized message within a short configurable window (proposed: 60 seconds), in addition to idempotency keys. The duplicate window should be validated with product stakeholders to avoid blocking legitimate recognition.
- Initial creation rate limit is proposed as 5 Kudos per employee per minute, configurable for rollout.
- No organization-specific compliance, hosting, or technology constraints were provided. These must be checked before implementation and deployment.

## 9. Open questions for approval

1. Which SSO integration contract and employee-directory API should the application use?
2. How is the Administrator role assigned and kept in sync?
3. Are the proposed 60-second duplicate window and 5-per-minute limit acceptable?
4. What is the required moderation-content and audit retention period?
5. Does the portal require an in-app embed, or should this be a standalone internal web application?
