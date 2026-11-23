# SKILLGRAPH — Product Requirements Document

| Field | Value |
|---|---|
| Version | 1.0 |
| Project | SKILLGRAPH |
| Product | SKILLGRAPH CORE |
| Category | Human Capability Infrastructure / Skills Intelligence |
| Initial market | Vocational Education & Technical Skills |
| Business model | Hybrid B2C + B2B + API |
| Status | Initial Product Specification |
| Primary objective | Build a real, secure, interoperable, production-oriented software foundation |

> This file is the product owner's specification, recorded in the repository as the source of truth.
> Engineering interpretations, refinements and open questions are kept in separate documents
> (`ARCHITECTURE.md`, `DATA_MODEL.md`, `SECURITY.md`, `PHASE_0_PLAN.md`, `ADR/`) so that the
> original requirements stay distinguishable from engineering decisions.

---

## Part 1 — Product Requirements

### 1. Product Vision

SKILLGRAPH is an interoperable infrastructure platform for representing, connecting, managing, and verifying human capabilities.

The platform must enable people and organizations to use a consistent structure for describing skills, competencies, evidence, qualifications, and relationships between capabilities.

SKILLGRAPH is **not** intended to become another professional social network. Its primary purpose is to provide infrastructure that other platforms, educational institutions, training providers, and organizations can integrate into their existing systems.

**Mission:** Make human capabilities understandable, structured, portable, and verifiable across platforms.

**Long-term vision:** Become a trusted capability-data infrastructure that can connect individuals, vocational institutions, universities, training providers, employers, HR systems, Learning Management Systems, assessment providers, digital credential platforms, and government and industry organizations.

### 2. Initial Market Strategy

The initial market is vocational education and technical skills. The first pilot domain should focus on technical occupations where practical competency can be demonstrated.

Suggested initial skill domains: Industrial Automation, PLC Programming, Electrical Systems, Sensor Integration, HMI Development, SCADA Systems, Industrial Networking, Electrical Troubleshooting, Mechanical Maintenance, Robotics Fundamentals.

The initial pilot should use a manageable set of skills rather than attempting to model every occupation worldwide.

**Target users**

- Individual users: vocational students, technical students, technicians, self-taught learners, early-career professionals.
- Institutional users: vocational colleges, universities, training centers, assessment organizations, technical employers.
- Developer users: HR platforms, LMS providers, education technology companies, assessment software vendors.

### 3. Product Scope

The first release is **SKILLGRAPH CORE**. It must include:

1. Skill Registry
2. Skill Ontology
3. Skill Relationship Graph
4. Competency Framework Mapping
5. Evidence Metadata
6. Credential Registry
7. Organization and Institution Management
8. Identity and Consent Management
9. REST API
10. Developer Documentation
11. Admin Dashboard
12. Basic Personal Skill Profile

**Important product boundary.** SKILLGRAPH CORE must support credential metadata and verification integration, but it must not claim to be an accredited certification authority. It must distinguish between:

- A skill definition
- A self-reported skill
- An assessed skill
- An evidence-backed skill
- An institution-issued credential
- A cryptographically verifiable credential

A cryptographically valid credential does not automatically prove that its holder has real-world competence. The issuer, assessment method, criteria, and evidence must remain visible.

### 4. Functional Requirements

#### FR-01: User Accounts

Users must be able to register, log in, log out, verify email, recover accounts, manage their profile, view their data, request data export, and request account deletion.

Roles: Individual, Institution Administrator, Instructor, Assessor, Credential Issuer, Organization Administrator, API Developer, Platform Administrator.

Role permissions must be enforced on the backend.

#### FR-02: Skill Registry

Administrators must be able to create and manage skill records. Each skill must include: unique identifier, canonical name, alternative names, description, skill category, language, parent skill, related skills, prerequisite skills, skill framework references, version, status, source attribution, created and updated timestamps.

Skill records must support multiple languages. Initial interface languages: Thai, English.

The canonical skill identifier must remain stable even when names or translations change.

#### FR-03: Skill Ontology

Supported relationship types: `IS_A`, `PART_OF`, `REQUIRES`, `RELATED_TO`, `SPECIALIZATION_OF`, `TRANSFERABLE_TO`, `EQUIVALENT_TO`.

Every relationship must contain: source skill, target skill, relationship type, confidence or evidence basis where applicable, source, version, approval status.

AI-generated relationships must remain suggestions until reviewed or validated by an authorized process.

#### FR-04: Competency Framework Mapping

SKILLGRAPH must support external skill frameworks. Initial integration candidates: ESCO, O\*NET, institution-specific competency frameworks.

Every external mapping must store: external framework name, external identifier, external version, mapping type, mapping confidence, mapping source, review status.

Do not silently merge two skills merely because their names look similar.

#### FR-05: Evidence Registry

Users and authorized institutions must be able to register evidence associated with skills.

Evidence types: project, practical assessment, examination, work experience, training completion, portfolio, institution assessment, external credential.

Evidence metadata must include: evidence identifier, owner, related skills, evidence type, issuer or assessor, assessment date, evidence description, evidence storage reference, visibility, verification status.

Evidence files must be stored in private object storage, not directly in public database records.

#### FR-06: Credential Registry

The system must support registration and verification of credentials.

Credential statuses: Pending, Issued, Active, Expired, Revoked, Suspended, Invalid.

Credential records must contain: issuer, holder, related skills, issued date, expiration date (if applicable), credential identifier, credential format, verification method, revocation status, evidence references.

Design for W3C Verifiable Credentials Data Model 2.0 and 1EdTech Open Badges 3.0 interoperability. Do not claim standards certification until formal conformance requirements have been fulfilled.

#### FR-07: Skill Graph

Users must be able to view a visual graph of: their skills, related skills, prerequisite skills, evidence-backed skills, skills with missing evidence, learning opportunities (when available).

Graph nodes must be clickable. Graph relationships must be inspectable.

The graph must not imply that a person possesses a skill simply because the skill is connected to another skill.

#### FR-08: Organization Management

Institutions must be able to register an organization, create institution profiles, invite staff, assign roles, manage competency frameworks, issue credentials if authorized, review assessment records, and manage organization API keys.

Organization boundaries must be strictly enforced.

#### FR-09: Developer API

Provide versioned REST APIs for: skill search, skill retrieval, skill relationship queries, framework mapping, credential lookup, credential verification, evidence metadata access, authorized capability profile access.

API documentation must be generated from OpenAPI specifications.

#### FR-10: Consent and Data Sharing

Individuals must control which personal capability records are shared. The system must support: private records, shared records, organization-specific access, time-limited access grants, revocable access, audit history.

A public skill definition is not personal data. An individual's skill profile and evidence may be personal data and must have separate access controls.

### 5. Non-Functional Requirements

**Performance (initial engineering targets, not measured claims)**

- Standard API requests: p95 < 500 ms under agreed pilot load
- Skill search: p95 < 500 ms
- Graph queries: p95 < 1,000 ms for bounded queries
- Paginated endpoints must enforce maximum page size
- Large imports must use background jobs

**Reliability**

- Automated database backups; documented restore procedure
- Health checks; structured logging; error monitoring
- Migration rollback strategy where feasible
- Initial service objective: 99.5% monthly availability for the pilot, excluding documented maintenance

**Scalability:** multiple organizations, multiple languages, versioned skill frameworks, increasing numbers of skills, increasing API clients, future mobile applications.

**Accessibility:** target WCAG 2.2 AA for the web application.

**Localization:** Thai, English; UTC timestamps internally; localized display dates; Unicode-safe search.

---

## Part 2 — System Architecture

### 6. Architecture Principles

1. API-first
2. Modular monolith initially
3. PostgreSQL as the primary database
4. Standards-first interoperability
5. Privacy by design
6. Backend-enforced authorization
7. Explicit versioning
8. No fake APIs or simulated verification
9. No unnecessary blockchain dependency
10. No AI-generated facts presented as verified evidence

### 7. Recommended Technology Stack

- **Frontend:** Next.js, TypeScript, responsive web application, Tailwind CSS, accessible component system, React-based graph visualization. Web-first; must work on Android and desktop browsers. A dedicated Android app may follow once the core API and workflows are stable.
- **Backend:** Node.js, TypeScript, NestJS or an equivalent structured framework, REST API, OpenAPI 3.2.1. One backend application divided into clearly separated modules. Do not start with microservices.
- **Database:** PostgreSQL; Prisma ORM or an equivalent migration-managed ORM. Relational tables for identity, organizations, credentials, evidence metadata, access grants. Skill graph as relational edge tables initially; no separate graph database until measured query requirements justify it.
- **Storage:** private object storage for evidence files, assessment attachments, credential artifacts, export files. Metadata and object references in PostgreSQL. Short-lived signed URLs for authorized downloads.
- **Infrastructure:** containerized application, managed PostgreSQL, private object storage, HTTPS, background worker, centralized logging, error monitoring, CI/CD pipeline. Provider selection must consider data residency, security controls, backup capabilities, and operating cost.

### 8. Logical Architecture

External systems (vocational institutions, LMS providers, HR systems, credential issuers, individual users) connect through the SKILLGRAPH API gateway / backend.

Core modules: Identity, Organization, Skill Registry, Ontology, Framework Mapping, Evidence, Credential, Consent, Graph Query, Developer API, Audit, Billing (future release).

The database and object storage are private infrastructure services. All personal data access must pass authorization and consent checks.

### 9. Suggested Repository Structure

```
skillgraph/
├── apps/{web,api,worker}/
├── packages/{shared-types,validation,api-client,config}/
├── database/{schema,migrations,seeds}/
├── docs/{PRD,ARCHITECTURE,DATA_MODEL,API_SPECIFICATION,SECURITY,TEST_PLAN}.md, docs/ADR/
├── openapi/skillgraph-v1.yaml
├── scripts/
├── tests/{integration,e2e,security,load}/
├── docker-compose.yml
├── .env.example
├── README.md
└── package.json
```

---

## Part 3 — Data Model

### 10. Core Entities

- **users**: id (UUID), email, password_hash or external_identity_reference, display_name, preferred_language, account_status, created_at, updated_at. Never store plaintext passwords.
- **organizations**: id, name, organization_type, country_code, website, verification_status, created_at, updated_at.
- **organization_members**: id, organization_id, user_id, role, membership_status, created_at. Unique (organization_id, user_id).
- **skills**: id, canonical_code, category, status, version, source_type, created_at, updated_at.
- **skill_translations**: id, skill_id, language_code, name, description, alternative_names. Unique (skill_id, language_code).
- **skill_relationships**: id, source_skill_id, target_skill_id, relationship_type, confidence, source_reference, review_status, version, created_at. Prevent invalid self-referencing relationships unless explicitly supported by a defined use case.
- **competency_frameworks**: id, name, provider, version, source_url, license_reference, imported_at.
- **framework_skill_mappings**: id, framework_id, external_skill_code, internal_skill_id, mapping_type, confidence, mapping_status, source_metadata.
- **evidence_records**: id, owner_user_id, organization_id (nullable), evidence_type, title, description, storage_reference, visibility, verification_status, created_at, updated_at.
- **evidence_skills**: evidence_id, skill_id, assessment_level (nullable), relationship_notes.
- **credentials**: id, credential_identifier, issuer_organization_id, holder_user_id, credential_type, issued_at, expires_at (nullable), status, credential_format, verification_reference, created_at.
- **credential_skills**: credential_id, skill_id.
- **consent_grants**: id, subject_user_id, recipient_type, recipient_id, scope, purpose, granted_at, expires_at, revoked_at, consent_version.
- **audit_logs**: id, actor_user_id, organization_id (nullable), action, resource_type, resource_id, timestamp, request_id, metadata. Append-only for normal application users.
- **api_clients**: id, organization_id, client_name, client_identifier, hashed_secret_reference, permitted_scopes, status, created_at, last_used_at. Raw API secrets must never be stored or returned after initial issuance.

### 11. Important Data Model Rules

1. All primary identifiers must be UUIDs or other non-guessable identifiers.
2. Skill identifiers must remain stable across translation changes.
3. Framework versions must be recorded.
4. Imported framework records must retain source attribution.
5. Evidence must not automatically create verified skill claims.
6. Credential revocation must be represented explicitly.
7. Personal records must have ownership and visibility information.
8. Organization data must have tenant isolation.
9. Every sensitive write must generate an audit event.
10. Schema migrations must be version-controlled.

### 12. Skill Competency Model

Do not treat skill proficiency as a single universally comparable number. Initially support: Not assessed, Self-reported, Knowledge assessed, Practically demonstrated, Expert assessed.

Assessment frameworks may define their own levels. If numerical proficiency is used, store the scale definition and framework reference. Never compare two numeric levels from different frameworks without a documented mapping.

---

## Part 4 — API Specification

### 13. API Standards

Base URL `/api/v1`. JSON, HTTPS only, UTF-8, OpenAPI 3.2.1, ISO 8601 timestamps, UUID identifiers.

Authentication: OIDC-compatible user authentication; OAuth 2.0 client credentials for organization integrations where appropriate; short-lived access tokens; rotatable API credentials. All endpoints must implement server-side authorization.

### 14. Initial Endpoints

| Area | Endpoints |
|---|---|
| Health | `GET /health`, `GET /ready` |
| Skills | `GET /skills`, `GET /skills/{skillId}`, `POST /skills`, `PATCH /skills/{skillId}`, `GET /skills/{skillId}/relationships`, `GET /skills/{skillId}/framework-mappings` |
| Skill Graph | `GET /skills/{skillId}/graph?depth=2`, `GET /users/me/skill-graph` |
| Evidence | `POST /evidence`, `GET /evidence/{evidenceId}`, `PATCH /evidence/{evidenceId}`, `DELETE /evidence/{evidenceId}`, `POST /evidence/{evidenceId}/skills` |
| Credentials | `POST /credentials`, `GET /credentials/{credentialId}`, `GET /credentials/{credentialId}/verify`, `POST /credentials/{credentialId}/revoke` |
| Frameworks | `GET /frameworks`, `GET /frameworks/{frameworkId}`, `GET /frameworks/{frameworkId}/skills`, `POST /frameworks/{frameworkId}/mappings` |
| Personal profiles | `GET /users/me`, `GET /users/me/capabilities`, `PATCH /users/me`, `GET /users/me/consents`, `POST /users/me/consents`, `DELETE /users/me/consents/{consentId}` |
| Organizations | `POST /organizations`, `GET /organizations/{organizationId}`, `GET /organizations/{organizationId}/members`, `POST /organizations/{organizationId}/members`, `PATCH /organizations/{organizationId}/members/{memberId}` |
| Developer API | `POST /developer/api-clients`, `GET /developer/api-clients`, `POST /developer/api-clients/{clientId}/rotate-secret`, `DELETE /developer/api-clients/{clientId}` |

- Public read access may be permitted for published skill definitions; creation and modification require authorized administrative roles.
- Graph depth must be limited; the API must prevent unbounded graph traversal.
- Private evidence must never become public by default.
- Credential issuance and revocation require issuer authorization.
- Access to another person's profile requires explicit authorization and an appropriate consent or legal basis.

### 15. API Example: Skill Record

`GET /api/v1/skills/550e8400-e29b-41d4-a716-446655440000`

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "canonicalCode": "SKILL-PLC-PROGRAMMING",
  "translations": {
    "en": { "name": "PLC Programming", "description": "Programming industrial programmable logic controllers." },
    "th": { "name": "การเขียนโปรแกรม PLC", "description": "การเขียนและพัฒนาโปรแกรมสำหรับควบคุม PLC ในระบบอุตสาหกรรม" }
  },
  "category": "industrial_automation",
  "status": "published",
  "version": 1
}
```

Illustrative schema only. Production responses must be generated from the actual database and validation layer.

### 16. API Error Format

```json
{ "error": { "code": "FORBIDDEN", "message": "You do not have permission to access this resource.", "requestId": "request-uuid" } }
```

Do not expose database errors, stack traces, secrets, or internal infrastructure details.

### 17. API Requirements

Pagination on collection endpoints; maximum page size; rate limiting; request validation; idempotency where retries could cause duplicate writes; consistent error responses; API versioning; request IDs; audit logging for sensitive operations; scope-based API authorization; automated OpenAPI validation.

---

## Part 5 — Security Design

### 18. Security Objectives

The platform handles sensitive personal capability records, educational records, credentials, and evidence. Security is a foundational requirement. Use **OWASP ASVS 5.0.0** as the application security verification baseline and the **OWASP API Security Top 10** as an API threat checklist.

### 19. Authentication

Argon2id (or appropriately configured equivalent) password hashing; email verification; password reset with short-lived tokens; secure session management; token expiration; refresh-token rotation where applicable; MFA for privileged roles; session revocation. Never place privileged secrets in frontend code.

### 20. Authorization

RBAC combined with resource-level authorization; roles alone are insufficient. Every request must verify: who is making the request; which organization owns the resource; who owns the personal data; what operation is requested; whether the role permits it; whether an appropriate consent or legal basis exists. Prevent Broken Object Level Authorization. Never trust a client-supplied object ID as proof of access rights.

### 21. Multi-Tenant Security

Organization-owned records must be isolated by organization. Every organization-scoped query must enforce organization authorization. Use PostgreSQL Row-Level Security as an additional defense where appropriate. Test cross-tenant access explicitly.

### 22. Data Protection

HTTPS for all external traffic; encryption at rest; private evidence storage; short-expiry signed URLs; secret manager for production secrets; data minimization; retention policies; account deletion workflow; data export workflow; consent records; audit logging; database backups; tested restore process.

Design privacy controls with reference to the NIST Privacy Framework and applicable data protection laws, including Thailand's PDPA. Do not assume consent is the appropriate legal basis for every processing activity. Obtain qualified legal review before commercial launch.

### 23. API Security

Protect against: Broken Object Level Authorization, Broken Authentication, Broken Object Property Level Authorization, Unrestricted Resource Consumption, Broken Function Level Authorization, SSRF, Security Misconfiguration, Improper API Inventory Management, Unsafe Third-Party API Consumption. Use strict request validation and outbound network restrictions. Rate-limit authentication, search, uploads, exports, and verification.

### 24. Credential Security

Verify issuer identity; validate cryptographic proof; check credential status, expiration, revocation; validate credential schema; record verification time; preserve issuer attribution.

A successful cryptographic verification must not be displayed as proof that the underlying assessment was academically or professionally valid. The UI must distinguish, as separate facts: **signature valid**, **issuer trusted**, **credential active**, **assessment evidence available**, **assessment methodology known**.

---

## Part 6 — User Experience

### 25. Initial Web Application Screens

- **Public:** landing page, product overview, skill directory, developer documentation, pricing, login, registration.
- **Individual dashboard:** overview, my skills, skill graph, evidence, credentials, sharing and consent, account settings.
- **Organization dashboard:** overview, members, skill frameworks, credential records, assessment records, API clients, audit history, organization settings.
- **Platform administration:** skill management, relationship review, framework imports, organization review, credential issuer review, system health, audit monitoring.

### 26. UX Principles

Mobile responsive; Thai and English; clear status labels; accessible controls; explain why a skill is considered verified or unverified; never imply that an unassessed skill is verified; provide data export and sharing controls; avoid misleading numerical scores.

---

## Part 7 — Test Strategy

### 27. Test Categories

- **Unit:** skill validation, relationship validation, permission rules, credential status, consent expiration, framework mapping, data transformation.
- **Integration:** database persistence, organization isolation, authentication, API authorization, credential verification, evidence upload, data export, consent revocation.
- **End-to-end workflow:**
  1. Individual registers.
  2. User creates a skill profile.
  3. User adds evidence.
  4. Institution creates an organization.
  5. Institution invites an instructor.
  6. Authorized instructor assesses a skill.
  7. Institution issues a credential.
  8. User receives the credential.
  9. An external verifier checks it.
  10. User revokes a sharing permission.
  11. The previously authorized recipient can no longer access private data.
- **Security:** cross-user access, cross-organization access, privilege escalation, token expiration, credential tampering, upload restrictions, SQL injection, XSS, CSRF where applicable, rate limiting, SSRF, sensitive data leakage.
- **Performance (initial scenarios, not capacity claims):** 100 concurrent users, 50 concurrent API clients, 10,000 skill records, 100,000 relationship records, bounded graph queries, concurrent credential verification.

---

## Part 8 — Acceptance Criteria

### 28. MVP Definition of Done

The MVP is accepted only when all critical criteria pass.

- **Skill Registry:** create, update, search, retrieve skills; Thai and English translations; stable identifiers; source attribution; versioning.
- **Skill Graph:** create relationships; retrieve related skills; enforce relationship rules; limit traversal depth; does not infer user possession from graph connectivity.
- **Identity and Organization:** registration, login, email verification, role authorization, organization isolation work; unauthorized access is denied.
- **Evidence:** register metadata; upload permitted files; files private by default; authorized users can retrieve; unauthorized users cannot.
- **Credentials:** register credentials; check status; distinguish expired vs revoked; validate supported cryptographic proofs when implemented; never mark unsupported credentials as verified.
- **API:** OpenAPI spec exists; all documented endpoints implemented; validation, pagination, rate limiting, API scopes work; automated integration tests pass.
- **Operations:** migrations work; backup and restore tested; health checks work; logging works; no production secrets committed; deployment instructions complete.
- **Security gate:** no known unresolved critical/high findings; cross-tenant and authorization tests pass; dependency vulnerabilities reviewed; secret scanning passes.

No production launch if a critical security requirement is failing.

---

## Part 9 — Roadmap

| Phase | Duration | Deliverables | Exit criteria |
|---|---|---|---|
| 0 — Discovery & Technical Validation | 2–3 weeks | Confirm first vocational use cases; initial skill taxonomy; ESCO/O\*NET licensing & attribution review; confirm standards and credential format; interview prospective institutions; MVP acceptance criteria; architecture decisions | At least one realistic institutional pilot workflow documented and reviewed |
| 1 — Core Foundation | 4–6 weeks | Repository, database, authentication, organization module, skill registry, translations, relationships, admin dashboard, initial REST API | A real user can create, manage, and query skills |
| 2 — Evidence & Credentials | 4–6 weeks | Evidence registry, private file storage, credential registry, status management, issuer permissions, verification workflow, audit events | An authorized institution can register an assessment record and issue a supported credential record |
| 3 — Developer Infrastructure | 3–5 weeks | OpenAPI docs, API key management, OAuth where appropriate, API scopes, rate limiting, developer dashboard, integration tests | An external application can use documented APIs to search skills and verify authorized credentials |
| 4 — Pilot & Validation | 4–8 weeks | Pilot institution onboarding, real vocational framework, Thai/English data, pilot feedback, performance & security testing, backup/restore validation, docs | At least one pilot institution completes a real end-to-end workflow |
| 5 — Commercial Readiness | Based on pilot | Billing, metering, institutional & developer plans, SLOs, support workflow, DPAs, privacy docs, production operations | — |

Do not implement commercial billing before the product's real value and willingness to pay have been validated.

---

## Part 10 — Business Model

### 29. Hybrid Revenue Strategy

- **Individual — Free:** personal profile, basic skill graph, basic evidence records, basic credential wallet. **Pro:** advanced graph analytics, advanced exports, expanded evidence management, additional personal insights.
- **Institutions — Paid:** organization management, staff and learner management, credential issuance workflows, assessment records, API access, reports, administrative controls.
- **Developers:** free sandbox with strict limits; paid plans for API usage, higher rate limits, production integrations, advanced verification features, enterprise support.

Do not charge users merely to access their own personal data or export their own records.

### 30. Commercial Validation Metrics

Active institutions; active individuals; published skills; verified issuers; issued credentials; successful verification requests; active API clients; API retention; monthly active organizations; pilot-to-paid conversion; customer acquisition cost; institutional renewal rate.

Downloads and registrations alone are not evidence of product-market fit.

---

## Part 11 — Development Rules

### 31. Engineering Instructions

1. Build a real working application, not a static prototype.
2. Do not create fake APIs.
3. Do not create fake verification results.
4. Do not invent credentials or institution approvals.
5. Do not hardcode sample users as real accounts.
6. Do not store secrets in frontend code.
7. Do not bypass authentication for convenience.
8. Do not silently weaken authorization.
9. Do not claim a feature is complete unless it has been implemented and tested.
10. Do not claim standards compliance without completing the relevant conformance requirements.
11. Write migrations for all database schema changes.
12. Use environment variables for configuration.
13. Maintain `.env.example` without real secrets.
14. Provide automated tests.
15. Provide setup and deployment instructions.
16. Record significant architecture decisions in ADR files.
17. Use real database persistence.
18. Use real file storage.
19. Use explicit error handling.
20. Preserve user data and migrations during upgrades.

### 32. Required Development Workflow

Work in small, verifiable milestones. For each milestone: inspect the repository; report current state; identify missing prerequisites; define the plan; implement; run lint and type checks; run unit tests; run integration tests where applicable; fix all failures; report files changed, commands executed, and actual test results; document remaining risks.

Do not claim tests passed unless they were actually executed. If a service, API, or cloud credential is unavailable, report the limitation and stop the affected integration rather than inventing a working response.

### 33. Required Project Deliverables

Working frontend; working backend; database migrations; seed data clearly marked as demonstration data; authentication; organization isolation; skill registry; skill graph; evidence registry; credential registry; API documentation; automated tests; security documentation; deployment instructions; `.env.example`; README; ADRs; known limitations report.

### 34. First Task

Before writing application code: inspect the development environment; confirm installed runtime versions; inspect available database and infrastructure; create a technical feasibility report; identify assumptions requiring user approval; propose a minimal repository structure; create the initial architecture documents; present the Phase 0 plan. Do not start implementing all modules before the architecture and Phase 0 assumptions have been reviewed.

### Final Product Principle

SKILLGRAPH must become a trustworthy infrastructure platform. Its value is not the number of skills displayed or the complexity of its AI, but the quality, interoperability, provenance, and verifiability of capability data. Build the foundation correctly before expanding the ecosystem.
