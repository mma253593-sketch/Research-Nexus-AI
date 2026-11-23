# SKILLGRAPH — Documentation

**Status (2026-11-23, second review):** owner Decisions 1–7 recorded. **Awaiting owner approval of the new repository setup and the final architecture.** No application code exists; no cloud resources are provisioned.

## Start here
| Document | Purpose |
|---|---|
| [DECISIONS_AND_RISKS.md](DECISIONS_AND_RISKS.md) | **Open decisions (U-1…U-10) and risks** |
| [REPOSITORY_MIGRATION.md](REPOSITORY_MIGRATION.md) | What the owner must create and authorize; safe migration procedure; dry-run results |
| [PHASE_1_PLAN.md](PHASE_1_PLAN.md) | Entry conditions, milestones M0–M1.7, exit criteria |

## Decision support
| Document | Purpose |
|---|---|
| [IDP_COMPARISON.md](IDP_COMPARISON.md) | ZITADEL Cloud vs Amazon Cognito: pricing, organisations, MFA, regions, migration, lock-in (evidence-labelled) |
| [COST_ESTIMATE.md](COST_ESTIMATE.md) | AWS Singapore cost breakdown, separating verified prices from assumptions ([cost/](cost/)) |
| [PRIVACY_AND_DATA_TRANSFER.md](PRIVACY_AND_DATA_TRANSFER.md) | PDPA and cross-border transfer requirements; pre-pilot legal gate |

## Architecture and requirements
| Document | Purpose |
|---|---|
| [PRD.md](PRD.md) | Product requirements (owner's specification) |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Modules, request pipeline, OIDC, API keys, authorization, RLS, search, graph, storage, credentials, consent, repository structure, deployment |
| [DATA_MODEL.md](DATA_MODEL.md) | Proposed schema and additions to the PRD model |
| [SECURITY.md](SECURITY.md) | Security baseline, OWASP API Top 10 control plan, known gaps |
| [ADR/](ADR/README.md) | Architecture Decision Records 0001–0012 |
| [FEASIBILITY_REPORT.md](FEASIBILITY_REPORT.md) | Measured environment facts (§6–7: decision reviews) |
| [PHASE_0_PLAN.md](PHASE_0_PLAN.md) | Original Phase 0 decisions (D-1…D-16) and status |
