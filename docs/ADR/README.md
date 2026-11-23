# Architecture Decision Records

Format: lightweight MADR. Each ADR has a **Status** of `Proposed`, `Accepted`, `Superseded by ADR-xxxx` or `Rejected`. An ADR becomes `Accepted` only after the product owner reviews it. Until then, implementation may not depend on it.

| ADR | Title | Status |
|---|---|---|
| [0001](0001-modular-monolith-and-workspace.md) | Modular monolith in a pnpm workspace | Proposed |
| [0002](0002-postgresql-edge-tables-for-skill-graph.md) | PostgreSQL edge tables for the skill graph (no graph DB) | Proposed |
| [0003](0003-data-access-and-migrations.md) | Data access layer and SQL-first migrations | Proposed — **needs owner approval (deviates from PRD's first-named option, Prisma)** |
| [0004](0004-authentication.md) | First-party authentication with server-side sessions; OAuth2 client credentials for integrations | Proposed — needs owner approval |
| [0005](0005-object-storage.md) | Object storage abstraction with S3 and filesystem drivers | Proposed |
| [0006](0006-postgres-backed-jobs-and-rate-limits.md) | PostgreSQL-backed jobs and rate limiting for the pilot | Proposed |
| [0007](0007-credential-verification.md) | Credential verification reports separate facts; unsupported proofs are never "valid" | Proposed — proof formats need owner approval |

New ADRs: copy the structure below, use the next number, and keep the old ADR when superseding it.

```
# ADR-NNNN: Title
Status: Proposed | Accepted | Superseded by ADR-XXXX | Rejected
Date: YYYY-MM-DD
## Context
## Decision
## Consequences
## Alternatives considered
```
