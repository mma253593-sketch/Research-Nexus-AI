# Architecture Decision Records

Format: lightweight MADR. Each ADR has a **Status** of `Proposed`, `Accepted`, `Superseded by ADR-xxxx` or `Rejected`. An ADR becomes `Accepted` only after the product owner reviews it. Until then, implementation may not depend on it.

| ADR | Title | Status (2026-11-23) |
|---|---|---|
| [0001](0001-modular-monolith-and-workspace.md) | Modular monolith in a pnpm workspace | Proposed (location now `skillgraph/`, see 0008) |
| [0002](0002-postgresql-edge-tables-for-skill-graph.md) | PostgreSQL edge tables for the skill graph (no graph DB) | Proposed |
| [0003](0003-data-access-and-migrations.md) | Kysely + SQL-first migrations | **Accepted** (D-2) |
| [0004](0004-authentication.md) | First-party password authentication | **Superseded by 0009** (D-4) |
| [0005](0005-object-storage.md) | Object storage abstraction with S3 and filesystem drivers | Proposed |
| [0006](0006-postgres-backed-jobs-and-rate-limits.md) | PostgreSQL-backed jobs and rate limiting for the pilot | Proposed |
| [0007](0007-credential-verification.md) | Credential verification reports separate facts | Proposed (proof formats need owner input, D-15) |
| [0008](0008-repository-isolation-from-research-nexus.md) | SKILLGRAPH isolated in `skillgraph/` beside Research Nexus AI | Proposed; direction approved (D-1). **Two edits to the existing app need approval (A-1)** |
| [0009](0009-managed-oidc-authentication.md) | Managed OIDC provider behind a replaceable adapter | Proposed; direction approved (D-4). **Provider (A-4), M2M (A-5), test IdP (A-6) need approval** |
| [0010](0010-hosting-aws-singapore.md) | Hosting on AWS ap-southeast-1, portable cells | Proposed; direction approved (D-5). **Provider (A-7) needs approval** |

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
