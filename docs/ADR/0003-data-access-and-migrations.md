# ADR-0003: Data access layer and SQL-first migrations

Status: Proposed — **requires owner approval** (deviates from the PRD's first-named option, Prisma; the PRD allows "or an equivalent migration-managed ORM")
Date: 2026-11-23

## Context
The data model depends on PostgreSQL features that must live in migrations, not in application code:

- Row-Level Security policies with `FORCE ROW LEVEL SECURITY`, and `SECURITY DEFINER` helper functions;
- triggers (append-only audit, credential status transitions, immutable `canonical_code`);
- check constraints, partial unique indexes, GIN `gin_trgm_ops` indexes, generated columns;
- per-transaction `set_config('app.*', …, true)` so that RLS sees the principal;
- recursive CTEs for graph traversal.

Facts observed on 2026-11-23: the npm `latest` dist-tag of `prisma` points to a pre-release (`8.0.0-rc.34`; last stable is `7.10.1`). `drizzle-orm` is at `0.45.4`, which is pre-1.0.

## Decision (proposed)
- **Migrations are hand-reviewed SQL files** in `database/migrations/NNNN_description.sql`, applied by a small migration runner (e.g. `node-pg-migrate` in SQL mode, or a minimal in-repo runner with a `schema_migrations` table and checksums). Migrations are forward-only; every file carries a `-- rollback:` note describing the manual reversal.
- **Query layer: Kysely** (type-safe SQL query builder on `pg`). Types are generated from the live schema after migration (`kysely-codegen`) and committed, so code and schema can't drift silently.
- Every request-scoped query runs inside `withPrincipal(principal, tx => …)`, which opens a transaction and sets the RLS context before anything else. A lint rule forbids using the raw pool outside this helper and the migration runner.

## Consequences
- RLS, triggers and constraints are first-class and reviewable in one place.
- There's no ORM-level relation loading; joins are written explicitly. That's more code but predictable SQL, which suits authorization-heavy queries.
- Developers need SQL fluency. Mitigation: a migration checklist in CONTRIBUTING.

## Alternatives considered
- **Prisma (PRD's first-named option).** Its schema language can't express RLS policies, triggers or `gin_trgm_ops` indexes, so those would need hand-edited SQL migrations anyway. Setting a per-transaction RLS context requires interactive transactions or client extensions on every query. Its current `latest` tag is a pre-release. Prisma is viable, but the RLS requirement (PRD §21) makes it fight the design. **If the owner prefers Prisma for team familiarity, this ADR will be rewritten and RLS implemented via raw SQL migrations plus a Prisma client extension.**
- **Drizzle ORM + drizzle-kit.** Viable; schema in TypeScript with SQL migration generation. Pre-1.0, and RLS/trigger support still ends up as custom SQL. A reasonable second choice.
- **TypeORM.** Weaker type safety; migration generation is unreliable for advanced features.
