# SKILLGRAPH

Interoperable infrastructure for representing, connecting, managing and verifying human capabilities: skills, competencies, evidence and credentials. The initial market is vocational and technical education (Thai and English).

> **Status: Phase 0 complete, Phase 1 not started.** This repository currently contains architecture and planning documents only. There is no application code yet, and nothing is deployed.
>
> **Temporary location:** until the independent `SKILLGRAPH` GitHub repository exists, this folder is held on a side branch of Research-Nexus-AI. It will be extracted with its history, and `skillgraph/` becomes the repository root ([docs/REPOSITORY_MIGRATION.md](docs/REPOSITORY_MIGRATION.md)). SKILLGRAPH has no code or configuration relationship with Research Nexus AI.

## Start here
- [docs/README.md](docs/README.md): documentation index
- [docs/PHASE_1_PLAN.md](docs/PHASE_1_PLAN.md): next implementation steps (awaiting approval)
- [docs/DECISIONS_AND_RISKS.md](docs/DECISIONS_AND_RISKS.md): open decisions and risks

## Planned stack (approved direction)
- Backend: Node.js 22, TypeScript, NestJS modular monolith; worker in the same codebase
- Database: PostgreSQL 16 with Kysely and version-controlled SQL migrations; Row-Level Security for tenant isolation
- Frontend: Next.js, Tailwind, Thai and English
- Identity: managed OIDC provider (to be selected; no passwords stored by SKILLGRAPH)
- API access: SKILLGRAPH-issued API keys with scopes, expiry, rotation, revocation, usage tracking and rate limits
- Hosting: AWS Singapore (ap-southeast-1) as the preferred candidate; nothing provisioned yet

## Tools in this repository today
- `scripts/cost/aws_cost_model.py`: reproducible AWS cost estimate (`python3 scripts/cost/aws_cost_model.py`)
