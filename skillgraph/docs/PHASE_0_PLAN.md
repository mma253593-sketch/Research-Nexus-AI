# Phase 0 — Discovery & Technical Validation Plan

**Duration (PRD):** 2–3 weeks
**Exit criterion (PRD):** at least one realistic institutional pilot workflow is documented and reviewed.
**Engineering exit criterion (added):** every decision in §2 is answered, and every ADR is `Accepted` or rewritten. No Phase 1 application code is written before this.

---

## 1. What was done in this first step

| PRD §34 step | Result |
|---|---|
| 1. Inspect development environment | Done. See `FEASIBILITY_REPORT.md` §1–3 |
| 2. Confirm runtime versions | Done. Node 22.23.5, pnpm 10.28.0, PostgreSQL 16.15, Docker 29.10 (daemon unreliable) |
| 3. Inspect database and infrastructure | Done. PostgreSQL 16 starts locally with pgcrypto and pg_trgm. No object storage, no email, ESCO/O\*NET hosts blocked |
| 4. Technical feasibility report | `FEASIBILITY_REPORT.md` |
| 5. Assumptions requiring approval | §2 below |
| 6. Minimal repository structure | `ARCHITECTURE.md` §16 |
| 7. Initial architecture documents | `ARCHITECTURE.md`, `DATA_MODEL.md`, `SECURITY.md`, `ADR/0001–0007` |
| 8. Phase 0 plan | This document |

No application code was written, and the existing "Research Nexus AI" code wasn't modified.

## 1a. Decision status (updated 2026-11-23)

| ID | Status | Owner direction → engineering result |
|---|---|---|
| D-1 | **Decided** | Preserve Research Nexus AI; SKILLGRAPH separate. **ADR-0008:** `skillgraph/` folder. Two isolation edits to the existing app are pending approval (A-1) |
| D-2 | **Decided** | Kysely + SQL migrations, PostgreSQL. **ADR-0003 Accepted** |
| D-4 | **Decided (direction)** | Managed OIDC provider. **ADR-0009:** recommend ZITADEL Cloud (runner-up Cognito). Provider choice pending (A-4) |
| D-5 | **Decided (direction)** | Global market; Singapore as initial candidate. **ADR-0010:** recommend AWS ap-southeast-1, cost estimated from the AWS price list. Pending (A-7) |
| D-3, D-6–D-16 | Open | See §2 below; defaults for Phase 1 are proposed in `PHASE_1_PLAN.md` §2 |

New approvals raised by this review (A-1 … A-8) are listed in `PHASE_1_PLAN.md` §1.

**Second review (2026-11-23):** owner Decisions 1–7 replace D-1/D-4/D-5 directions and A-1…A-8. SKILLGRAPH moves to its own repository (ADR-0011; A-1 and A-3 withdrawn). The IdP isn't finalized (U-5). API keys are SKILLGRAPH-issued (ADR-0012). AWS is the preferred candidate with no provisioning yet. The current open list is [`DECISIONS_AND_RISKS.md`](DECISIONS_AND_RISKS.md). **Phase 1 implementation doesn't start until the owner explicitly approves the finalized architecture.**

## 2. Decisions required from the product owner (original Phase 0 list)

Each decision shows a **recommendation**. "Blocks" says what can't start until it's answered.

| ID | Decision | Recommendation | Blocks |
|---|---|---|---|
| **D-1** | The repository currently contains an unrelated app ("Research Nexus AI": Vite, React, Gemini). What happens to it? | Remove it from the working tree in the first Phase 1 commit (git history preserves it), or move it to its own repository if it's still wanted. Building SKILLGRAPH alongside it would mix two products. | Phase 1 scaffolding |
| **D-2** | Data access and migrations: Kysely + SQL migrations (ADR-0003) or Prisma? | Kysely + SQL migrations, because of the RLS and trigger requirements | Phase 1 |
| **D-3** | Pilot skill scope: which 2–3 of the 10 suggested domains, and roughly how many skills (e.g. 40–80)? | Start with PLC Programming, Sensor Integration and Electrical Troubleshooting, which can be practically assessed. Confirm with the pilot institution. | Taxonomy work, demo seed |
| **D-4** | Authentication: first-party (ADR-0004) or external IdP? Do pilot institutions need SSO at launch? | First-party for the pilot; OIDC federation later | Phase 1 identity |
| **D-5** | Hosting provider and data residency (Thailand? region?), managed PostgreSQL, object storage, secret manager | Owner decision. Requirements: Thai data residency if pilot contracts require it, managed PostgreSQL 16 with UTF-8 locale and PITR backups, S3-compatible private storage. Verify regional availability with the chosen provider. | Deployment, staging |
| **D-6** | Transactional email provider (verification and reset) | Any SMTP-capable provider with a region-appropriate DPA | Production email; dev is unaffected |
| **D-7** | OpenAPI version. The PRD says 3.2.1; tooling support isn't verified. | Author the contract by hand in the highest version our validator and docs renderer support (3.1 minimum). Move to 3.2.x once tooling is confirmed. | Contract file format |
| **D-8** | Roles: (a) are "Institution Administrator" and "Organization Administrator" the same role? (b) can one member hold several org roles (e.g. instructor + assessor)? | (a) Same role (`org_admin`). (b) Yes: `roles[]` per membership. | Permission matrix |
| **D-9** | Malware scanning for uploaded evidence: provider, or accept the documented limitation for the pilot? | Accept the limitation for the closed pilot (owner-only download of unscanned files); require a scanner before public launch | Evidence sharing |
| **D-10** | Languages: default UI locale, and which translation is mandatory for publishing a skill | Default UI `th`; require **both** `th` and `en` for skills published in the pilot domain | Skill publish rule |
| **D-11** | Maximum duration of a consent grant | Required expiry, 12 months maximum, renewable | Consent module |
| **D-12** | On account deletion, what happens to credential records issued to that person (issuer's legal record vs. erasure)? | Needs **legal review** (PDPA). Engineering default until then: keep the issuer's record and unlink the holder's personal data. | Deletion workflow |
| **D-13** | Security verification target | OWASP ASVS 5.0.0 Level 2 for the pilot | Security test plan |
| **D-14** | Session timeouts | 30 min idle for privileged sessions, 7 days for others, 30 days absolute | Identity config |
| **D-15** | Credentials: register externally issued credentials only, or also *issue* signed VCs or Open Badges? Which formats do pilot institutions use? | Register and verify first (ADR-0007 Phase 2a); decide signing after the institution interviews | Phase 2 scope |
| **D-16** | ESCO / O\*NET data: provide dataset files and licence texts, or allow the hosts in the environment's network policy? | Either. The licence review must be read from the official texts, not assumed. | Framework import |

## 3. Phase 0 workstreams

### 3.1 Product & domain (owner-led; engineering supports)

| # | Task | Output |
|---|---|---|
| P-1 | Identify 1–2 prospective pilot institutions and interview them (assessment practice, current records, credential formats, SSO, languages) | Interview notes in `docs/discovery/` |
| P-2 | Write the pilot workflow end-to-end (the PRD's 11-step E2E flow adapted to the real institution) | `docs/discovery/PILOT_WORKFLOW.md`: **the PRD exit criterion** |
| P-3 | Draft the initial taxonomy for the chosen domains (D-3): codes, Thai and English names, relationships, sources | `database/seeds/pilot/taxonomy.csv` (format defined by engineering in E-4) |
| P-4 | ESCO / O\*NET licence and attribution review (D-16) | `docs/discovery/LICENSING.md` |
| P-5 | Confirm MVP acceptance criteria against the pilot workflow | Annotated PRD §28 checklist |

### 3.2 Engineering (validation spikes; throwaway code kept out of `apps/`)

| # | Spike / task | Success measure |
|---|---|---|
| S-1 | **Thai and English skill search:** load ~10k translated skill names; test trigram search correctness (Thai substrings, mixed Thai/English such as "PLC", alternative names) | Relevant results in the top 5 for a 30-query test set written with the domain owner |
| S-2 | **Search latency** at 10k skills, local PostgreSQL 16 | Record p95; indicative only, not a production claim |
| S-3 | **Graph traversal latency:** 10k skills, 100k edges, depth 2 and 3 with caps (ADR-0002) | Record p95 against the 1,000 ms target; decide caps |
| S-4 | **RLS prototype:** `skillgraph_app` role, `withPrincipal` transaction context, one org-owned and one personal table, cross-tenant negative tests | Cross-tenant reads return zero rows even when the application check is deliberately removed |
| ~~S-5~~ | ~~Argon2id install and parameter timing~~ **Dropped:** no password hashing for people after D-4 (managed OIDC). Replaced by **S-6** (IdP verification, `PHASE_1_PLAN.md` M1.1) | — |
| E-1 | OpenAPI contract skeleton for Phase 1 endpoints (health, skills, relationships, auth, organizations), validated by a linter | Lint passes (D-7) |
| E-2 | Permission matrix draft (roles × actions) | Reviewed by owner (D-8) |
| E-3 | Test plan (`docs/TEST_PLAN.md`) mapping PRD §27 and §28 to concrete suites | Reviewed |
| E-4 | Taxonomy import format (CSV/JSON schema) and validation rules | Schema plus a validator script |

The spikes run against the locally installed PostgreSQL 16. Results go into the ADRs with the commands used and the hardware they ran on.

## 4. Proposed Phase 1 milestone breakdown (after Phase 0 approval)

> **Superseded (2026-11-23)** by [`PHASE_1_PLAN.md`](PHASE_1_PLAN.md), which reflects D-1, D-2, D-4 and D-5. The original list is kept below for history.

Each milestone follows the PRD §32 workflow (inspect, plan, implement, lint and types, tests, report actual results, risks).

1. **M1.1 Workspace foundation:** pnpm workspace, config validation, lint and type-check, CI, docker-compose, migration runner, `/health` and `/ready`, error envelope, request IDs, structured logs.
2. **M1.2 Identity:** registration, email verification (dev transport), login/logout, sessions, password reset, MFA enrolment, audit events.
3. **M1.3 Organizations:** create org, invitations, roles, RLS for org tables, cross-tenant tests.
4. **M1.4 Skill registry:** skills, translations, revisions, search (trigram), publish workflow, public read API.
5. **M1.5 Ontology:** relationships, review workflow, acyclicity check, bounded graph endpoint.
6. **M1.6 Admin dashboard (web):** skill management and relationship review, Thai/English, accessibility checks.

Phase 1 exit (PRD): *a real user can create, manage, and query skills.*

## 5. Risks

| Risk | Impact | Mitigation |
|---|---|---|
| No pilot institution confirmed | Phase 0 exit criterion can't be met; taxonomy and credential scope would be guessed | P-1 is the critical path; engineering spikes proceed in parallel |
| Thai search quality with trigrams alone (no word segmentation) | Poor search for short Thai queries | S-1 with real queries; alternative-name curation; a Thai segmenter (e.g. ICU) as a later option |
| Credential cryptography scope creep | Phase 2 overruns | ADR-0007 split into 2a/2b; D-15 |
| PDPA / legal basis questions unresolved | Launch blocker (PRD §22) | Model `legal_basis` explicitly now; schedule legal review before Phase 4 |
| Docker unreliable in the development container | Container builds and S3 driver can't be verified here | Native PostgreSQL for tests here; CI verifies containers and MinIO |
| First-party auth is security-critical code | Vulnerabilities | Proven primitives, ASVS L2 tests, external pen test before pilot |
