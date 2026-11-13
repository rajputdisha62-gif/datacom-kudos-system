# Datacom Kudos System

A responsive Kudos application built from the approved Forage Task 2 specification. The code uses React and TypeScript, Express, PostgreSQL, and Prisma.

## Local simulation identity

Datacom SSO credentials are not available in this simulation. In development only, the API exposes a fixed allowlist of four demo identities (three employees and one administrator). The selected subject is looked up in the seeded employee table; the server issues a signed, eight-hour, HTTP-only, SameSite Strict cookie. The browser cannot submit or change its own role. The development login routes are not registered when NODE_ENV=production. This simulation is not a production SSO integration.

## Prerequisites

- Node.js 26 LTS (or compatible Node 20.19+)
- PostgreSQL 15+ and a local database/user matching .env.example

Copy .env.example to .env, set a random SESSION_SECRET of at least 32 characters, and adjust DATABASE_URL for local PostgreSQL. Create the database before applying migrations.

## Setup and run

1. Run npm install.
2. Run npm run db:generate.
3. Run npm run db:deploy.
4. Run npm run db:seed.
5. Run npm run dev.
6. In a second terminal run npm run client and open the Vite URL shown. The development client proxies API calls to port 3000.

For a production build, run npm run build and npm start with NODE_ENV=production, a strong session secret, and a reachable PostgreSQL database. Integrate production SSO through a trusted identity adapter; demo login is disabled in production.

## Tests

Run npm test for unit and API access-control tests. They use a mocked service and do not need a live PostgreSQL instance. Runtime migration and seeding require PostgreSQL; Prisma client generation is local.

## Security notes

- Data APIs require a signed session, and employee/admin authorization is enforced server-side.
- Mutating requests require a same-origin Origin header; session cookies are HTTP-only and SameSite Strict.
- React renders messages as escaped text.
- Employee feed/search queries filter status=PUBLISHED in the database; administrators use separately authorized moderation routes.
- Idempotency, normalized duplicate checks, atomic per-employee rate counters, uniqueness constraints, and transactions prevent duplicate effects.
- Configure TLS, host allowlists, secrets management, backups, retention, and monitoring before any production deployment.
