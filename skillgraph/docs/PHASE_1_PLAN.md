# Phase 1 — Core Foundation: Implementation Plan (revision 2)

**Status:** Awaiting the owner's approval of the new repository setup and the final architecture. **No Phase 1 code is written, and no paid cloud resource is provisioned, until the owner explicitly approves.**
**Date:** 2026-11-23 (revised after owner Decisions 1–7)
**PRD Phase 1 exit criterion:** *a real user can create, manage, and query skills.*
**Open decisions referenced as U-n:** [`DECISIONS_AND_RISKS.md`](DECISIONS_AND_RISKS.md)

---

## 1. Entry conditions

| # | Condition | Blocks |
|---|---|---|
| E-1 | `SKILLGRAPH` repository created empty by the owner, and the Claude GitHub App given access (U-1) | M0 |
| E-2 | Owner approves the migration procedure and the import to `main` (U-2) | M0 |
| E-3 | Owner approves this plan and the architecture documents | M1.0 onwards |
| E-4 | Identity provider selected and an isolated **test tenant** created (U-5) | L2 OIDC tests (M1.1, part of the M1.2 exit). Not blocking M1.0–M1.2 development |
| E-5 | Explicit approval to provision AWS resources, plus an AWS account and access (U-7) | M1.7 *apply* only. Without it: validate/plan only |

**Removed from revision 1:** the two isolation edits to Research Nexus AI (former A-1) and the Research Nexus regression guard. They aren't needed now that SKILLGRAPH has its own repository (ADR-0011).

## 2. Defaults for still-open Phase 0 decisions (used unless the owner changes them; U-9)

| ID | Default |
|---|---|
| D-3 Pilot skill scope | Demonstration seed only: ~30 skills (PLC Programming, Sensor Integration, Electrical Troubleshooting), labelled as demonstration data |
| D-6 Email | `EmailTransport`: Mailpit locally; Amazon SES ap-southeast-1 later (provisioning only after U-7) |
| D-7 OpenAPI | 3.1, validated in CI |
| D-8 Roles | Institution Administrator = Organization Administrator = `org_admin`; members hold `roles[]` |
| D-10 Languages | UI default `th`; publishing a skill requires `th` **and** `en` |
| D-13 Security target | OWASP ASVS 5.0.0 Level 2 |
| D-14 Session timeouts | Privileged 30 min idle; others 7 days idle; 30 days absolute; step-up window 15 min |

## 3. Scope

**In Phase 1:** repository migration and bootstrap; workspace foundation; database and migrations; OIDC identity; organisations, RBAC and RLS; skill registry with Thai/English search; ontology with bounded graph; admin and public web UI; deployment foundation (IaC validated, applied only with approval).

**Not in Phase 1:** evidence and uploads, credentials, consent, capability profile and personal graph, data export and deletion workflows (Phase 2); **API keys** (Phase 3, design fixed in ADR-0012, tables reserved); ESCO/O\*NET import; billing.

## 4. Milestones

Every milestone follows PRD §32. The report lists files changed, commands run, **actual** test output, and remaining risks. Nothing is reported as passing unless it was run.

### M0 Repository migration and bootstrap (≈ 1 day; after E-1 and E-2)
- Execute [`REPOSITORY_MIGRATION.md`](REPOSITORY_MIGRATION.md) §5, steps 1–6: freeze the source, verify the target is empty, extract with `filter-repo`, run the secret scan, push plainly to `main`, verify by tree hash, commit the commit map.
- Bootstrap on a branch plus pull request: `README.md`, `.gitignore`, `.editorconfig`, `.nvmrc`, `CODEOWNERS`, PR template, Dependabot config, and the CI skeleton (docs link check, secret scan).
- Owner applies or approves the repository settings in ARCHITECTURE §16: branch protection, secret scanning and push protection, Environments.
- **Acceptance:** the `SKILLGRAPH` tree equals the frozen source `skillgraph/` tree; no Research Nexus files are present; the history keeps both Phase 0 commits; Research-Nexus-AI `main` is still `c268948`.
- **Step 7** (retiring the old branch) happens only on the owner's separate approval (U-3).

### M1.0 Workspace foundation (≈ 3.5 days)
- pnpm workspace; `packages/config` and `packages/contracts`; `apps/api` (NestJS: `main.ts`, `worker.ts`).
- Fail-fast config validation (Zod), structured logging with redaction (including the `sgk_` key pattern), request IDs, the PRD §16 error envelope, `/api/v1/health` and `/api/v1/ready`.
- **Migration runner:** SQL files, checksums, `schema_migrations`, advisory lock. Roles `skillgraph_migrator` (owner) and `skillgraph_app` (no `BYPASSRLS`). Kysely with generated types. The `withPrincipal` transaction helper that sets the RLS context.
- `docker-compose.yml` (postgres 16, minio, mailpit); `.env.example` with placeholders only; module-boundary lint.
- CI: lint, typecheck, unit, and integration against a PostgreSQL 16 service container.
- **Acceptance:** CI passes; migrations apply to an empty database reproducibly and running them twice is a no-op; `/ready` returns 503 when the database is down (test); the app role can't bypass RLS (test).

### M1.1 Identity provider verification spike S-6 (≈ 2 days; needs E-4)
Against the isolated test tenant, verify: discovery and PKCE; `amr`/`acr` after MFA; `sid` and back-channel logout; the admin APIs for delete and export; per-organisation SSO; region; and which data can be exported. Results go into `IDP_COMPARISON.md` and ADR-0009. **Without E-4, this is reported as blocked**, and M1.2 continues with L1 tests only.

### M1.2 Identity via OIDC (≈ 5 days)
- BFF login, callback and logout; SKILLGRAPH sessions; provisioning by (`issuer`, `sub`); MFA step-up guard; back-channel logout endpoint; rate limits on auth routes; audit events.
- Platform-admin bootstrap as an **audited CLI command** that grants the role to an existing (`issuer`, `sub`). No seeded or hard-coded admin accounts.
- `IdentityProviderAdmin` interface. The adapter for the selected provider is implemented only to the extent S-6 verified.
- **Real OIDC integration tests (owner Decision 6, ADR-0009 §11):**
  - **L1** on every PR, against a real OIDC server in an ephemeral CI network (the ZITADEL OSS container if ZITADEL is chosen; otherwise `oidc-provider`). Cases: successful login; wrong `aud`/`iss`; bad signature; expired token; `nonce` mismatch; `state` replay; open redirect; idle and absolute expiry; revocation; step-up required; back-channel logout.
  - **L2** nightly, against the isolated provider test tenant, with synthetic users created and deleted by the harness. Reported as blocked until E-4.
- **Acceptance:** L1 suite passes; L2 passes, or is explicitly reported as blocked with the reason.

### M1.3 Organisations, RBAC and Row-Level Security (≈ 5 days)
- Organisations (with `home_region`), members with `roles[]`, invitations (single-use hashed tokens; email through Mailpit locally).
- Permission matrix in `packages/contracts`, with exhaustive unit tests.
- `FORCE ROW LEVEL SECURITY` policies; append-only audit log (privileges plus trigger).
- **Acceptance:** the cross-tenant suite passes **with the application-level check disabled** (RLS alone blocks access); privilege-escalation tests pass; audit `UPDATE`/`DELETE` is rejected.

### M1.4 Skill registry and Thai/English search (≈ 5 days)
- Categories, skills, translations, revision snapshots, publish workflow (`th` + `en`), immutable `canonical_code`, source attribution.
- Trigram search on normalised `search_text`; pagination with a maximum page size.
- Public read endpoints and admin write endpoints; OpenAPI 3.1 contract and contract test; demonstration seed (refused in production).
- Spikes S-1/S-2: a 30-query Thai/English relevance set and p95 latency at 10k skills, recorded as indicative local measurements.
- **Acceptance:** all PRD §28 Skill Registry items.

### M1.5 Ontology and bounded graph (≈ 4 days)
- Relationship constraints; review workflow (AI-suggested edges start as `suggested`; approval by platform admin only); acyclicity check for hierarchical types.
- `GET /skills/{id}/relationships`; `GET /skills/{id}/graph?depth=` (≤ 3, node cap, `truncated` flag).
- Spike S-3: p95 latency at 10k skills and 100k edges, recorded in ADR-0002.
- **Acceptance:** all PRD §28 Skill Graph items.

### M1.6 Web application (≈ 6 days)
- Next.js `th`/`en`; sign-in through the API; public directory, search and skill detail with a graph (React Flow) **and an accessible list alternative**.
- Admin: skill management, translation, publishing, relationship review. Organisation admin: members and invitations (minimal).
- Playwright E2E and axe accessibility checks.
- **Phase 1 E2E scenario:**
  1. Sign in through the real IdP test tenant (or the L1 server if E-4 is pending, stated explicitly).
  2. The user is granted platform admin via the CLI.
  3. They create a skill in Thai and English and publish it.
  4. They add and approve a relationship.
  5. An anonymous visitor searches in Thai and finds the skill and its graph.
  6. A non-admin attempting an edit is refused.

### M1.7 Deployment foundation (≈ 3 days)
- Dockerfiles (non-root, pinned base images).
- `infra/` OpenTofu for the topology in ARCHITECTURE §17 and COST_ESTIMATE (NAT vs. no-NAT per U-7).
- Deploy workflow using AWS OIDC behind protected Environments; migration task; runbooks for deploy, rollback, backup and restore.
- **Without provisioning approval:** `tofu validate` and `tofu plan` against a mock or empty backend only. Reported as **not deployed**.
- **With approval:** deploy staging; run the E2E scenario on staging; record a restore drill; repeat the Thai search check on RDS.

**Estimate:** ≈ 34.5 engineering days, roughly 6–7 weeks for one engineer, which is above the PRD's 4–6 weeks. To fit 4–6 weeks, defer the organisation-admin web screens and the staging deployment to early Phase 2 (owner's choice; U-9).

## 5. Phase 1 exit criteria
1. A real user signed in through a real OIDC provider can create, manage and query skills. Staging plus the real IdP tenant if E-4 and E-5 are met; otherwise local plus the L1 OIDC server, stated explicitly.
2. All Phase 1 suites pass in CI: unit, integration, security (cross-tenant, authorization, auth negatives), contract, L1 OIDC, E2E and accessibility. L2 passes, or is reported as blocked.
3. No open critical or high findings; dependency advisories reviewed; secret scan clean.
4. Documentation updated: README (setup), `.env.example`, ADR statuses, a known-limitations report and an IdP configuration record.
5. Research-Nexus-AI is unchanged (`main` still `c268948`). No paid resources exist without approval.
