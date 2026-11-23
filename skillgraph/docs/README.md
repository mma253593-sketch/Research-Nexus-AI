# SKILLGRAPH — Documentation

SKILLGRAPH is a separate product that lives in `skillgraph/` in this repository. The repository root is the existing **Research Nexus AI** app, which SKILLGRAPH doesn't change or depend on (ADR-0008).

**Status (2026-11-23):** Phase 0 architecture revised after owner decisions D-1, D-2, D-4 and D-5. **Phase 1 is awaiting the owner's explicit approval.** No SKILLGRAPH application code exists yet.

| Document | Purpose |
|---|---|
| [PHASE_1_PLAN.md](PHASE_1_PLAN.md) | **Start here:** approvals needed (A-1…A-8), defaults, milestones M1.0–M1.7, exit criteria |
| [PRD.md](PRD.md) | Product requirements (owner's specification, source of truth) |
| [FEASIBILITY_REPORT.md](FEASIBILITY_REPORT.md) | Measured environment facts; §6 covers the Research Nexus baseline, coexistence conflicts and the Thai locale test |
| [PHASE_0_PLAN.md](PHASE_0_PLAN.md) | Phase 0 decisions (D-1…D-16) and their status |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Modules, request pipeline, OIDC authentication, authorization, tenancy/RLS, search, graph, storage, credentials, consent, deployment |
| [DATA_MODEL.md](DATA_MODEL.md) | Proposed schema, including additions to the PRD model and why |
| [SECURITY.md](SECURITY.md) | Security baseline, OWASP API Top 10 control plan, known gaps |
| [ADR/](ADR/README.md) | Architecture Decision Records 0001–0010 |
