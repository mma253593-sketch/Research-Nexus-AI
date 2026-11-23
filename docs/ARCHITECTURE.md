# SKILLGRAPH CORE — Architecture

**Status:** Proposed (Phase 0). Items marked *(decision D-n)* depend on an owner decision listed in `PHASE_0_PLAN.md`.
**Related:** `DATA_MODEL.md`, `SECURITY.md`, `ADR/`.

---

## 1. Context

```
 Individuals ──┐                                   ┌── Vocational institutions / employers
 (browser)     │                                   │   (browser: org dashboards)
               ▼                                   ▼
        ┌────────────────────────────────────────────────┐
        │  apps/web  (Next.js, server-rendered, i18n)    │
        └───────────────┬────────────────────────────────┘
                        │ same-origin /api/v1 (session cookie)
 External systems ──────┤ HTTPS /api/v1 (OAuth2 client-credentials bearer token)
 (LMS, HR, verifiers)   ▼
        ┌────────────────────────────────────────────────┐
        │  apps/api  (NestJS modular monolith)           │──── SMTP provider (D-6)
        │  + worker entrypoint (same code, pg-boss jobs) │──── Credential status lists /
        └───────┬──────────────────────────┬─────────────┘     issuer keys (allow-listed egress)
                ▼                          ▼
        PostgreSQL 16 (private)     Object storage (private bucket)
```

Only the API process talks to PostgreSQL and object storage. The web app never holds database credentials or storage keys.

## 2. Architectural style

- **One deployable backend** (`apps/api`) with strict internal module boundaries (PRD §6.2). There are two process entrypoints: `main.ts` (HTTP) and `worker.ts` (background jobs). They are the same code base and image with different commands. A separate `apps/worker` is created only if the worker's dependencies diverge (ADR-0001).
- **Module boundary rules**, enforced by lint rules (`eslint-plugin-boundaries` or `dependency-cruiser`, checked in CI):
  - A module exposes a public `*.service.ts` facade and DTO types. Other modules may import only those.
  - Modules don't read each other's tables directly. Cross-module reads go through the owning module's service. This keeps a later split possible without having to plan for it.
  - `Audit`, `Authorization` and `Config` are cross-cutting. Every module may depend on them; they depend on no domain module.

### 2.1 Modules

| Module | Owns (tables) | Key responsibilities |
|---|---|---|
| Identity | users, user_credentials, sessions, auth_tokens, mfa_factors | Registration, login, email verification, reset, MFA, session revocation, account deletion and export requests |
| Organization | organizations, organization_members, organization_invitations | Org lifecycle, membership, org roles, issuer authorisation status |
| Skill Registry | skills, skill_translations, skill_revisions | CRUD, publish workflow, versioning, search |
| Ontology | skill_relationships | Relationship validation, review workflow, AI suggestions kept as `suggested` |
| Framework Mapping | competency_frameworks, framework_skills, framework_skill_mappings, proficiency_scales | Framework import (background jobs), mappings with review status |
| Graph Query | *(no tables; read-only over Ontology and Capability)* | Bounded traversal, personal-graph overlay |
| Capability | skill_claims, assessments | A person's skill claims and their basis (self-reported, assessed, evidence-backed, credential-backed) |
| Evidence | evidence_records, evidence_skills, evidence_files | Metadata, uploads, signed downloads, visibility |
| Credential | credentials, credential_skills, credential_evidence, credential_status_events, credential_verifications | Registration, status machine, revocation, verification |
| Consent | consent_grants | Grants, expiry, revocation, and the access-decision function used by other modules |
| Developer API | api_clients, api_tokens | Client registration, secret rotation, client-credentials token endpoint, scopes |
| Audit | audit_logs | Append-only audit trail |
| Platform | jobs (pg-boss schema), rate_limit_counters, idempotency_keys | Health, readiness, jobs, rate limiting, idempotency |
| Billing | — | Not built before Phase 5 (PRD §29 rule) |

"Capability" is an addition to the PRD's module list. The PRD's data model has no table for "user U claims skill S at level L on basis B", yet FR-07, §12 and the E2E workflow (step 6, "instructor assesses a skill") all need one. See `DATA_MODEL.md` §3.

## 3. Request pipeline (HTTP)

Every request passes through these steps in order:

1. **Request ID.** Accept a well-formed inbound `X-Request-Id` only from trusted proxies; otherwise generate a UUID. Echo it in the response and in logs, and include it in every error body.
2. **Security headers / CORS.** Strict CORS allow-list (the web origin only). API clients don't need CORS.
3. **Rate limit**, keyed by IP and by principal, with per-route classes: `auth`, `search`, `upload`, `export`, `verify`, `default`.
4. **Authentication.** Resolve the principal from:
   - a session cookie (web users): opaque random token, looked up by its SHA-256 hash in `sessions`; or
   - `Authorization: Bearer` (API clients): opaque access token issued by `/oauth/token`, looked up by hash.
   No principal means anonymous, which is allowed only on routes explicitly marked `@Public()`.
5. **CSRF check** for cookie-authenticated, state-changing requests (synchronizer token + `SameSite=Lax` cookie + `Origin` check).
6. **Validation.** Zod schemas from `packages/contracts`. Unknown properties are **rejected**, not silently dropped, to prevent mass assignment and OWASP API3 issues. Page size is capped.
7. **Authorization.** A route guard checks the coarse permission (role/scope). The service layer then makes the **resource-level decision** after loading the resource, through `AuthorizationService.assert(principal, action, resource)` (see §5).
8. **Transaction with tenant context.** The service runs inside a DB transaction that first executes `set_config('app.principal_id', …, true)` and related settings, so RLS policies apply (§6).
9. **Audit.** Sensitive writes call `AuditService.record(...)` **inside the same transaction**, so the change can't commit without its audit row.
10. **Response serialisation** through explicit response DTOs. Entities are never returned directly, so internal fields such as `password_hash` or `storage_key` can't leak.
11. **Error mapping.** Domain errors map to the PRD §16 envelope. Unknown errors become `INTERNAL_ERROR` with the request ID; details go to logs only.

## 4. Authentication design (summary; full detail in ADR-0004)

- **Web users:** first-party accounts with Argon2id password hashes (OWASP-recommended parameters, recorded in config). Server-side sessions in an `HttpOnly; Secure; SameSite=Lax` cookie, with idle and absolute timeouts. Sessions are revocable per device and globally on password change.
- **Email verification and password reset:** single-use random tokens stored only as hashes. Expiry 24 h (verification) and 30 min (reset). Responses don't reveal whether an email address exists.
- **MFA:** TOTP, mandatory for Platform Administrator, Organization Administrator, Institution Administrator and Credential Issuer roles before any privileged action. WebAuthn is a later enhancement.
- **API clients:** OAuth 2.0 client-credentials grant at `POST /api/v1/oauth/token`. Client secrets are hashed with Argon2id and shown once at creation and rotation. Access tokens are opaque, last 15 min and are scope-bound.
- **"OIDC-compatible" (PRD §13):** in Phase 1 this means the identity model has an `external_identity` link table, so external OIDC providers (institution SSO) can be federated later without a schema change. SKILLGRAPH does **not** run as an OIDC provider in the MVP. *(decision D-4)*

## 5. Authorization model

Authorization combines **RBAC** (what a role may do in general) with **resource policies** (whether *this* principal may do it to *this* object).

```
assert(principal, action, resource):
  1. Platform-level deny lists (account suspended, org suspended)             → DENY
  2. Function-level: does any of the principal's roles/scopes grant `action`?  → else DENY
  3. Object-level, by resource kind:
     - org-owned resource:  principal is an active member of resource.org with a role granting action
     - personal resource:   principal is the owner
                            OR an active, unexpired, unrevoked consent grant covers
                               (recipient = principal or principal's org, scope ⊇ action, purpose)
                            OR a documented non-consent legal basis applies (e.g. the issuing org
                               reading its own credential records) — modelled explicitly, never implied
     - public resource:     resource.status = published
  4. Property-level: response DTO is chosen by the access path (owner sees full; consent recipient
     sees only the fields in the granted scope).
```

- Roles are **scoped**. Org roles (`org_admin`, `instructor`, `assessor`, `credential_issuer`, `api_developer`) live on `organization_members`. Platform roles (`platform_admin`) live on a separate `platform_role_assignments` table. "Individual" is the default for every account and isn't a stored role.
- PRD roles "Institution Administrator" and "Organization Administrator" map to the same `org_admin` role; `organization_type` distinguishes institutions. *(decision D-8, to confirm)*
- The action/role matrix is one code-level table (`packages/contracts/src/permissions.ts`), unit-tested exhaustively, and rendered into `SECURITY.md`.
- Credential issuance needs **both** the `credential_issuer` org role **and** `organizations.issuer_status = 'approved'`, set by a platform admin after issuer review (PRD §25 "Credential Issuer Review").

## 6. Multi-tenancy and Row-Level Security

- The application connects as `skillgraph_app`, a role that **does not own tables and does not have `BYPASSRLS`**. Migrations run as `skillgraph_migrator`, the owner.
- Per transaction, the API sets these with `set_config(..., is_local => true)`:
  - `app.principal_kind` (`user` | `api_client` | `anonymous` | `system`)
  - `app.principal_id`
  - `app.org_ids` (comma-separated UUIDs where the principal is an active member, or the client's org)
- RLS policies (defence in depth; the application-level check in §5 remains primary):
  - **Org-owned tables** (`organization_members`, `organization_invitations`, `api_clients`, `assessments`, `credential_status_events`, org-scoped `audit_logs` reads): `organization_id = ANY(current_org_ids())`.
  - **Personal tables** (`evidence_records`, `skill_claims`, `consent_grants`): owner = principal, **or** an org- or issuer-relationship policy, **or** `has_active_consent(subject, scope)`. This is implemented as a `STABLE SECURITY DEFINER` SQL function with a fixed `search_path`.
  - **Public tables** (`skills`, `skill_translations`, approved `skill_relationships`): readable by all. Writes need the platform-admin flag, which is set from a server-verified role and never from client input.
- `FORCE ROW LEVEL SECURITY` is set on every protected table, so even the owner role is subject to the policies outside migrations.
- **Background jobs** run as principal `system` with a separate, narrowly granted role per job type where practical. Every system access is audited.
- Cross-tenant tests (`tests/security/tenant-isolation.spec.ts`) run each endpoint as a member of org A against resources of org B and expect 404. Hiding existence is the default for object-level denials, so IDs can't be enumerated.

## 7. Skill search (Thai and English)

- The Thai measurement in `FEASIBILITY_REPORT.md` §3.1 rules out PostgreSQL full-text search for Thai.
- Each `skill_translations` row stores a normalised search text: NFKC, case-folded, whitespace-collapsed, covering name and alternative names. A **GIN `gin_trgm_ops`** index sits on that column.
- Query: `search_text ILIKE '%' || q || '%'` (index-assisted), ranked by `word_similarity(q, search_text)` and then exact-prefix match. Matches can come from any language; results are returned with the requested language's translation, falling back to English.
- Queries shorter than 2 characters are rejected (they can't use trigrams efficiently). Page size is capped at 50.
- The query has to be served p95 < 500 ms at 10k skills (PRD §5). This is **unmeasured**; the Phase 0 spike S-2 measures it.

## 8. Graph queries

- The skill graph is stored as an edge table, `skill_relationships`. There's no graph database (PRD §7; ADR-0002).
- Traversal uses a recursive CTE with:
  - a **depth cap**: request `depth` ∈ [1, 3], default 2 (server-enforced maximum 3);
  - a **node cap** (default 200) and edge cap; the response reports `truncated: true` when a cap is hit;
  - **cycle prevention** through a visited-path array;
  - **filters**: only `review_status = 'approved'` edges by default (suggested and rejected edges are visible only to reviewers), and an optional relationship-type filter.
- **Personal graph** (`GET /users/me/skill-graph`) = the user's own skill claims as anchor nodes + the bounded neighbourhood of those skills. Every node carries a `possession` field, computed **only** from the user's own claims (`none | self_reported | knowledge_assessed | practically_demonstrated | expert_assessed`), plus `evidenceCount` and `credentialCount`. Neighbour nodes reached through edges always have `possession: none`. This is how FR-07's "no inference from connectivity" rule is enforced, and it gets a dedicated test.
- `EQUIVALENT_TO`, `RELATED_TO` and `TRANSFERABLE_TO` are stored as directed rows; symmetric types are queried in both directions. See DATA_MODEL §4.3 for the constraints.

## 9. Evidence and object storage

- `ObjectStorage` interface with `putObject`, `getSignedDownloadUrl(key, ttl ≤ 5 min)`, `deleteObject` and `headObject`. Drivers: `s3` and `filesystem` (ADR-0005).
- **Upload flow:**
  1. The client POSTs metadata.
  2. The API returns an upload intent.
  3. The client uploads through the API, with a streaming size limit (initially 25 MB, configurable).
  4. The API checks the allow-listed MIME type by magic bytes (not just the extension), computes SHA-256, and stores the file under a random key: `evidence/{uuid}`, never a user-supplied name.
  5. The `evidence_files` row is created with `scan_status = 'pending'`.
- **Malware scanning:** the interface is defined, but no scanner is configured in the MVP *(decision D-9)*. Downloads of `pending` files are allowed only for the owner until a scanner is configured. This is a documented limitation.
- **Downloads:** after authorization, the API returns a short-lived signed URL. For the filesystem driver, the URL points to an API route that validates an HMAC signature and expiry.
- Evidence is `private` by default, and the default is enforced in the database (`DEFAULT 'private'` plus a check constraint).

## 10. Credentials and verification (summary; ADR-0007)

- The credential status machine is enforced in the domain service **and** a DB trigger:

  ```
  pending → issued → active ⇄ suspended
                       │          │
                       ├→ revoked ←┘   (terminal)
                       ├→ expired      (derived/time-based; terminal unless re-issued)
  any non-terminal → invalid           (e.g. failed integrity check; terminal)
  ```

  Every transition appends a `credential_status_events` row with actor, reason and time.
- **Verification** returns separate facts, never a single "verified" boolean (PRD §24):

  ```json
  {
    "credentialId": "…", "checkedAt": "2026-…Z",
    "checks": {
      "signature":      { "result": "valid | invalid | not_supported | not_present" },
      "issuerTrusted":  { "result": "approved_issuer | unknown_issuer", "issuer": { "id": "…", "name": "…" } },
      "status":         { "result": "active | suspended | revoked | expired | pending | invalid" },
      "expiry":         { "result": "not_expired | expired | no_expiry" },
      "schema":         { "result": "valid | invalid | not_supported" },
      "evidenceAvailable":          { "result": true },
      "assessmentMethodologyKnown": { "result": false }
    }
  }
  ```

- Until a proof suite is implemented and tested against official test vectors, `signature.result` is `not_supported` for every credential. The UI then says "Signature not checked by SKILLGRAPH". Every verification is recorded in `credential_verifications`.

## 11. Consent

- A `consent_grants` row authorises a recipient (`organization` | `user` | `api_client`) to access a defined **scope** of the subject's data for a stated **purpose**, until `expires_at`. It can be revoked at any time.
- Scopes (initial): `profile.basic`, `capabilities.read`, `evidence.metadata.read`, `evidence.files.read`, `credentials.read`. An optional `resource_ids` list narrows a grant to specific records.
- Revocation takes effect immediately, because every access re-evaluates `has_active_consent` and there are no cached grants. Signed URLs issued before revocation remain valid for at most their TTL (≤ 5 min). This is a documented, bounded exposure.
- Whether consent or another legal basis applies to each processing activity is a **legal question** (PRD §22). The model stores `legal_basis` explicitly so that non-consent bases are visible rather than implied.

## 12. Audit

- `audit_logs` is append-only. The application role has `INSERT` and `SELECT` only. A trigger rejects `UPDATE` and `DELETE` for all roles except a dedicated retention role used by an approved retention job.
- Every sensitive write records an event: auth events, role changes, consent changes, evidence access, credential issue/revoke, API client creation and rotation, exports, deletions. Metadata never contains secrets or file contents.
- When an account is deleted, the user row is anonymised (tombstone) rather than removed, so audit foreign keys stay valid without retaining PII. See DATA_MODEL §6.

## 13. Background jobs

Background jobs use **pg-boss** (a PostgreSQL-backed queue; ADR-0006). Initial jobs: framework import, data export (zip to private storage plus a signed link), account deletion, credential expiry sweep, consent expiry notifications, token cleanup. Jobs are idempotent and keyed by business identifiers.

## 14. Observability and operations

- Structured JSON logs (pino) with request ID, principal kind and route. Redaction rules cover `authorization`, `cookie`, `password`, `secret`, `token` and email addresses.
- `GET /api/v1/health` is liveness and needs no dependencies. `GET /api/v1/ready` checks the DB, migrations applied, and storage reachable.
- Error monitoring through an interface. The provider (e.g. Sentry) is an owner decision; the default is a no-op that only logs.
- Migrations are forward-only SQL files committed to git, each with a written rollback note. Backups and restore drills are part of the deployment runbook; the restore drill is in the Phase 4 exit criteria.

## 15. Web application

- Next.js (App Router) with TypeScript and Tailwind. Routes are localised with `/th` and `/en` prefixes using next-intl, with Thai as the default for the pilot *(D-10)*. Dates are formatted per locale; the API always returns UTC ISO-8601.
- The web app calls the API **same-origin** (reverse proxy or Next rewrite to `/api/v1`), so the session cookie stays first-party and CORS stays closed.
- Components are accessible by construction: Radix-based primitives and visible focus. Every status label has text, not colour alone.
- **Graph view:** React Flow (`@xyflow/react`) for the visual graph, with a **mandatory list/table alternative** of the same nodes and edges for keyboard and screen-reader users (WCAG 2.2 AA). The visual graph isn't accessible on its own.

## 16. Proposed repository structure (minimal)

The PRD §9 layout, trimmed to what Phase 1 needs. Folders are added when they gain content, not up front.

```
/
├── apps/
│   ├── api/                 NestJS app: src/modules/*, src/platform/*, main.ts, worker.ts
│   │   └── test/            unit + integration tests (real PostgreSQL)
│   └── web/                 Next.js app
├── packages/
│   ├── contracts/           Zod schemas, DTO types, permission matrix, error codes (shared by api & web)
│   └── config/              eslint/tsconfig presets
├── database/
│   ├── migrations/          numbered SQL migrations (forward-only, reviewed)
│   └── seeds/demo/          demonstration data, clearly labelled, never loaded in production
├── openapi/skillgraph-v1.yaml
├── tests/{e2e,security,load}/
├── docs/                    PRD, ARCHITECTURE, DATA_MODEL, SECURITY, FEASIBILITY_REPORT, PHASE_0_PLAN, ADR/
├── docker-compose.yml       postgres, minio, mailpit (developer machines / CI)
├── .env.example
├── pnpm-workspace.yaml
└── package.json
```

Differences from PRD §9:

- `shared-types` and `validation` are merged into `contracts`: a Zod schema *is* the type.
- `api-client` is deferred until the OpenAPI contract stabilises in Phase 3, then generated.
- `worker` is an entrypoint inside `apps/api` (ADR-0001).
- `database/schema` is unnecessary when migrations are the source of truth (ADR-0003).
