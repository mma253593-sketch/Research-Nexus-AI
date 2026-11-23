# Architecture Decision Records

Format: lightweight MADR. Each ADR has a **Status** of `Proposed`, `Accepted`, `Superseded by ADR-xxxx` or `Rejected`. An ADR becomes `Accepted` only after the product owner reviews it. Until then, implementation may not depend on it.

| ADR | Title | Status (2026-11-23, second review) |
|---|---|---|
| [0001](0001-modular-monolith-and-workspace.md) | Modular monolith in a pnpm workspace | Proposed (workspace = `SKILLGRAPH` repo root, see 0011) |
| [0002](0002-postgresql-edge-tables-for-skill-graph.md) | PostgreSQL edge tables for the skill graph (no graph DB) | Proposed |
| [0003](0003-data-access-and-migrations.md) | PostgreSQL + Kysely + version-controlled SQL migrations | **Accepted** (owner Decision 2) |
| [0004](0004-authentication.md) | First-party password authentication | **Superseded by 0009** |
| [0005](0005-object-storage.md) | Object storage abstraction with S3 and filesystem drivers | Proposed |
| [0006](0006-postgres-backed-jobs-and-rate-limits.md) | PostgreSQL-backed jobs and rate limiting for the pilot | Proposed |
| [0007](0007-credential-verification.md) | Credential verification reports separate facts | Proposed (proof formats need owner input, D-15) |
| [0008](0008-repository-isolation-from-research-nexus.md) | SKILLGRAPH in a subfolder of Research-Nexus-AI | **Superseded by 0011** (edits to Research Nexus withdrawn) |
| [0009](0009-managed-oidc-authentication.md) | Managed OIDC behind a replaceable adapter; real OIDC tests in isolated environments | **Accepted** for the approach (owner Decisions 3 and 6). **Provider not selected (U-5)** |
| [0010](0010-hosting-aws-singapore.md) | AWS ap-southeast-1, portable cells | **Accepted as preferred candidate** (owner Decision 4). **No provisioning until approved (U-7)** |
| [0011](0011-independent-repository.md) | SKILLGRAPH in its own `SKILLGRAPH` repository | **Accepted** (owner Decision 1). Migration execution pending setup and approval (U-1–U-3) |
| [0012](0012-api-keys.md) | SKILLGRAPH-issued API keys | **Accepted** for the requirements (owner Decision 5). Sub-decisions U-6a and U-6b open |

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
