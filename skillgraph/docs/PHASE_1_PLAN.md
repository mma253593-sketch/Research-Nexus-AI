# Phase 1 — Core Foundation: Final Implementation Plan

**Status:** Awaiting the owner's explicit approval. **No Phase 1 code is written until the owner approves this plan and the approvals in §1.**
**Date:** 2026-11-23
**PRD Phase 1 exit criterion:** *a real user can create, manage, and query skills.*
**Based on:** decisions D-1, D-2, D-4, D-5 and ADR-0001 … ADR-0010.

---

## 1. Approvals needed before Phase 1 starts

| ID | Question | Recommendation | Blocks |
|---|---|---|---|
| **A-1** | May two one-line isolation edits be made to the **existing Research Nexus AI app**? (1) `tsconfig.json`: add `"exclude": ["node_modules","dist","skillgraph"]`. (2) `src/index.css`: add `@source not "../skillgraph";` | **Yes.** Without them, SKILLGRAPH code breaks Research Nexus `npm run lint`, and SKILLGRAPH CSS classes leak into its bundle (both proven, FEASIBILITY §6.2). With them, Research Nexus output is byte-identical to a build without SKILLGRAPH. They also remove the two stray classes the Phase 0 docs already added. | Any SKILLGRAPH code in this repo (M1.0) |
| **A-2** | Research Nexus has a **pre-existing** install failure (`esbuild@^0.25` vs Vite 8). Fix it or leave it? | **Leave it** (out of SKILLGRAPH scope). The regression guard installs with `--legacy-peer-deps`, exactly as it works today. The owner may ask for a separate fix. | Nothing |
| **A-3** | Is Research Nexus still edited in **Google AI Studio** with changes pushed to this repository? | If yes, an AI Studio sync could overwrite or delete `skillgraph/`. In that case, move SKILLGRAPH to its own repository (ADR-0008 fallback) **before** writing code. | M1.0 |
| **A-4** | Identity provider: **ZITADEL Cloud** (recommended) or **Amazon Cognito** (if same-region SG residency is mandatory). The owner must also create a development tenant. | ZITADEL Cloud, free tier for development. The client secret is provided through the cloud environment's secret settings, **never pasted in chat**. | Real-IdP testing (M1.1, part of M1.2 exit) |
| **A-5** | Machine-to-machine API clients: issued by **SKILLGRAPH** (recommended) or by the IdP? | SKILLGRAPH-issued client credentials (Phase 3), so the design survives a provider change | Phase 3 design (recorded now) |
| **A-6** | May automated tests use a real **in-process OIDC server** (`oidc-provider`) as a test-only fixture, with the real provider used in dev and staging? | **Yes.** It's a genuine OIDC implementation with real signatures, not a mock or bypass, and it never ships in the application. | M1.2 tests |
| **A-7** | Hosting: **AWS ap-southeast-1** (recommended) or Google Cloud asia-southeast1? When will an AWS account and a GitHub→AWS OIDC role be available for staging? | AWS. Without an account, M1.7 delivers validated IaC (`tofu validate` / `plan`) but no running staging. | M1.7 apply only |
| **A-8** | Commission **PDPA legal review** (cross-border transfer to SG/AU, legal basis, DPAs) before pilot users' real data is processed | Start before Phase 4 | Phase 4 (not Phase 1: demo data only) |

## 2. Defaults for still-open Phase 0 decisions (apply unless the owner changes them)

| ID | Default used in Phase 1 |
|---|---|
| D-3 Pilot skill scope | Demonstration seed only: ~30 skills in PLC Programming, Sensor Integration and Electrical Troubleshooting, **labelled as demonstration data**. The real taxonomy comes from the pilot institution. |
| D-6 Email | `EmailTransport` with Mailpit (local) and Amazon SES ap-southeast-1 (staging/prod). Used only for organisation invitations in Phase 1. |
| D-7 OpenAPI version | OpenAPI **3.1**, validated in CI. Move to 3.2.x when the validator and docs renderer support it. |
| D-8 Roles | "Institution Administrator" = "Organization Administrator" = `org_admin`. Members hold `roles[]`. |
| D-10 Languages | UI default `th`; publishing a skill requires **both** `th` and `en`. |
| D-13 Security target | OWASP ASVS 5.0.0 Level 2 |
| D-14 Session timeouts | Privileged 30 min idle; others 7 days idle; 30 days absolute; step-up window 15 min |
| D-9, D-11, D-12, D-15, D-16 | Not needed in Phase 1 (evidence, consent, deletion, credentials and framework import are Phase 2+) |

## 3. Scope

**In Phase 1:** isolation and workspace foundation; database and migrations; identity (OIDC); organisations, RBAC and RLS; skill registry with Thai/English search; ontology with bounded graph; admin and public web UI; deployment foundation.

**Not in Phase 1** (later phases, per PRD §Roadmap): evidence and file uploads; credentials and verification; consent; personal capability profile and personal graph; developer API clients and token endpoint; ESCO/O\*NET import; data export and account deletion workflows (the IdP adapter interface is defined now, implemented in Phase 2); billing.

## 4. Milestones

Every milestone follows PRD §32. The milestone report lists files changed, commands run, **actual** test output, and remaining risks. A milestone isn't "done" until its acceptance checks have been run and have passed.

### M1.0 Isolation and workspace foundation (≈ 4 days)
- Apply the A-1 edits. Add the **Research Nexus regression guard**: a script plus CI job that runs the existing app's `lint` and `build` and compares its CSS bundle against a build with `skillgraph/` removed.
- `skillgraph/` pnpm workspace: `packages/config`, `packages/contracts`, and `apps/api` (NestJS skeleton with `main.ts` and `worker.ts`).
- Config validation (Zod, fail-fast), structured logging with redaction, request IDs, PRD §16 error envelope, `/api/v1/health` and `/api/v1/ready`.
- **Migration runner** (SQL files, checksums, `schema_migrations`, advisory lock). Database roles `skillgraph_migrator` (owner) and `skillgraph_app` (no `BYPASSRLS`). Kysely with generated types. The `withPrincipal` transaction helper.
- `docker-compose.yml` (postgres, minio, mailpit), `.env.example` with placeholders only, gitleaks, module-boundary lint, cross-product import check.
- CI: `skillgraph` workflow (lint, typecheck, unit, integration against a PostgreSQL 16 service) and the Research Nexus guard workflow, both path-filtered.
- **Acceptance:**
  - Both workflows pass.
  - Research Nexus lint and build pass and its CSS is unchanged.
  - Migrations apply to an empty database reproducibly; running them twice is a no-op.
  - `/ready` returns 503 when the database is unreachable (test).

### M1.1 Spike S-6: identity provider verification (≈ 2 days; needs the A-4 tenant)
Against the real development tenant, verify:
- discovery, PKCE, ID-token claims;
- `amr`/`acr` after MFA;
- `sid` and Back-Channel Logout;
- user-deletion and profile APIs;
- per-organisation SSO configuration;
- data region and data export.

Record the results in ADR-0009 and mark it Accepted or revise it. **If no tenant is available, this is reported as blocked, and M1.2 proceeds against the test IdP only.**

### M1.2 Identity via OIDC (≈ 5 days)
- Login, callback and logout (BFF), SKILLGRAPH sessions, provisioning by (`issuer`, `sub`), MFA step-up guard, back-channel logout endpoint, auth-route rate limits, audit events.
- Platform-admin bootstrap as an **audited CLI command** granting the role to an existing (`issuer`, `sub`). No hard-coded or seeded admin accounts.
- `IdentityProviderAdmin` interface, with the ZITADEL (or Cognito) adapter implemented only to the extent S-6 verified.
- **Tests** (integration, against the `oidc-provider` fixture):
  - successful login;
  - wrong `aud`, wrong `iss`, bad signature, expired token, `nonce` mismatch, `state` replay;
  - open-redirect attempt;
  - session idle and absolute expiry;
  - revocation;
  - step-up required;
  - back-channel logout.
- **Acceptance:** all of the above pass. A manual or scripted smoke login against the real IdP tenant passes, or is reported as blocked.

### M1.3 Organisations, RBAC and Row-Level Security (≈ 5 days)
- Organisations, members (`roles[]`), invitations (email through `EmailTransport`; single-use hashed tokens).
- Permission matrix in `packages/contracts`, with exhaustive unit tests.
- RLS policies with `FORCE ROW LEVEL SECURITY` on organisation tables. Audit log is append-only (privileges plus trigger).
- Spike S-4 folded in: cross-tenant tests run **with the application-level check disabled**, to prove RLS alone blocks access.
- **Acceptance:** the cross-tenant suite passes (org A member gets 404 or zero rows for org B resources on every endpoint and table); privilege-escalation tests pass; audit `UPDATE`/`DELETE` is rejected.

### M1.4 Skill registry and Thai/English search (≈ 5 days)
- Skill categories, skills, translations, revisions (snapshots), publish workflow (`th` + `en` required), immutable `canonical_code`, source attribution, versioning.
- Normalised `search_text` with a GIN trigram index; `GET /skills` (search, pagination, max page size); `GET /skills/{id}`; admin `POST`/`PATCH`.
- OpenAPI contract updated, with a contract test checking routes against the spec.
- Demonstration seed (refused when `NODE_ENV=production`).
- Spikes S-1/S-2: a 30-query Thai/English relevance set and p95 at 10k skills, both recorded. The numbers are indicative, from local hardware.
- **Acceptance:**
  - create, update, search and retrieve skills work;
  - Thai and English translations work;
  - IDs stay stable across renames;
  - revision history is recorded;
  - non-admin writes are refused (all PRD §28 Skill Registry items).

### M1.5 Ontology and bounded graph (≈ 4 days)
- Relationships with all constraints (no self-loops; uniqueness; symmetric types stored once).
- Review workflow: AI-suggested edges can only enter as `suggested`; approval is by platform admin only.
- Acyclicity check for hierarchical types.
- `GET /skills/{id}/relationships` and `GET /skills/{id}/graph?depth=` (≤ 3, node cap, `truncated` flag).
- Spike S-3: p95 at 10k skills and 100k edges, recorded in ADR-0002.
- **Acceptance:** PRD §28 Skill Graph items, with depth over 3 rejected, cycles rejected, and unapproved edges hidden from the public.

### M1.6 Web application (≈ 6 days)
- `skillgraph/apps/web` (Next.js, App Router), `th`/`en` routes, sign-in through the API.
- Public skill directory and search, and a skill detail page showing a graph (React Flow) **plus an accessible list alternative**.
- Admin: skill create/edit/translate/publish, relationship review.
- Organisation admin: members and invitations (minimal).
- Playwright E2E and axe accessibility checks.
- **Phase 1 E2E scenario:**
  1. A user signs in through the IdP.
  2. That user is granted platform admin via the CLI.
  3. They create a skill in Thai and English and publish it.
  4. They add and approve a relationship.
  5. An anonymous visitor searches in Thai and finds the skill and its graph.
  6. A non-admin attempting an edit is refused.

### M1.7 Deployment foundation (≈ 3 days; *apply* needs A-7)
- Dockerfiles (non-root, pinned base images).
- `infra/` OpenTofu: VPC, ALB, ECS Fargate (web, api, worker), RDS PostgreSQL Multi-AZ, S3, Secrets Manager, CloudWatch.
- GitHub Actions deploy through AWS OIDC, behind an Environment with required reviewers; migration task before rollout.
- Runbooks: deploy, rollback, backup and restore.
- **Acceptance with an account:** staging is deployed; the Phase 1 E2E scenario passes on staging against the real IdP; a restore drill is recorded; the Thai search check is repeated on RDS. **Without an account:** `tofu validate` and `plan` succeed, and the deployment is reported as not done.

**Estimate:** ≈ 34 engineering days, roughly 6–7 weeks for one engineer. That's above the PRD's 4–6 weeks. To fit 4–6 weeks, defer the organisation-admin web screens and the staging *apply* to early Phase 2. Owner's choice.

## 5. Phase 1 exit criteria
1. PRD exit: a real user signed in through the real IdP can create, manage and query skills (M1.6 scenario on staging, or locally if staging is blocked, stated explicitly).
2. All Phase 1 automated suites pass in CI: unit, integration, security (cross-tenant, authorization, auth negatives), contract, E2E and accessibility.
3. The Research Nexus regression guard passes: no change to its lint, build or CSS.
4. No open critical or high findings; dependency advisories reviewed; secret scan clean.
5. Documentation updated: README (setup), `.env.example`, ADR statuses, a known-limitations report and an IdP configuration record.

## 6. Risks for Phase 1
| Risk | Mitigation |
|---|---|
| No IdP tenant from the owner | The test IdP covers protocol correctness; real-IdP checks are reported as blocked, never assumed |
| AI Studio overwrites the repository (A-3) | Confirm first; fall back to a separate repository |
| The chosen IdP doesn't emit `amr`/`acr` reliably | S-6 finds out early; fallback is an IdP-wide MFA policy for privileged users |
| Estimate exceeds the PRD window | Deferral options in §4 |
| Shared-repository permissions | CODEOWNERS, protected Environments, no stored cloud keys (ADR-0008) |
