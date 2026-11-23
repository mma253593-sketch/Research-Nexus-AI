# ADR-0012: SKILLGRAPH-issued API keys

Status: **Accepted** for the requirements (owner Decision 5, 2026-11-23). **Open sub-decisions:** authentication mode (U-6a) and expiry and grace defaults (U-6b). Implementation is scheduled for Phase 3 (PRD roadmap: Developer Infrastructure); the data model is reserved now.
Date: 2026-11-23

## Context
Organisations integrate external systems (LMS, HR, verifiers) with SKILLGRAPH. The owner decided that SKILLGRAPH issues and manages its own API keys, which must support: secure generation, hashed secret storage, scopes and permissions, expiration, rotation, revocation, usage tracking and rate limiting. The PRD also asks for OAuth 2.0 client credentials "where appropriate" (§13). 1EdTech specifications used in this market (e.g. OneRoster 1.2, LTI Advantage, Open Badges 3.0 API) use the OAuth 2.0 client-credentials pattern. That's background for the format choice; this ADR claims no 1EdTech conformance.

## Decision

### 1. Key format and generation
- An API key = a public **key ID** + a **secret**:
  `sgk_<env>_<keyId>.<secret>`
  - `env` ∈ {`live`, `test`}: test keys are rejected by production and vice versa.
  - `keyId`: 16 random bytes, base32. Public, used for lookup and shown in the UI.
  - `secret`: **32 random bytes (256 bits) from the operating system CSPRNG** (`crypto.randomBytes`), base64url.
- The fixed `sgk_` prefix makes leaked keys detectable by secret scanners (registration with GitHub secret scanning is a later option) and by log redaction.

### 2. Storage
- Only `HMAC-SHA-256(pepper, secret)` is stored, plus the last 4 characters for display. The pepper is a 256-bit key in AWS Secrets Manager, never in the database, and is versioned (`pepper_version`) so it can be rotated.
- **Why HMAC rather than Argon2:** the secret is 256-bit random, so brute force is infeasible and a slow hash adds latency and a denial-of-service surface without adding security. The pepper protects against an offline attack using a database-only leak. (Human passwords aren't stored at all; ADR-0009.)
- Comparison in constant time. The full key is **shown once**, at creation or rotation, and never logged. The logger redacts the pattern `sgk_[a-z]+_[A-Za-z0-9]+\.[A-Za-z0-9_-]+`.

### 3. Authentication mode (U-6a)
- **Recommended: OAuth 2.0 client-credentials exchange.** The integrator sends key ID and secret (HTTP Basic) to `POST /api/v1/oauth/token` and receives an **opaque access token valid for 15 minutes**, bound to the key's scopes. API calls carry only the short-lived token, so the long-lived secret crosses the network once per 15 minutes instead of on every call.
- Alternative (not recommended for the MVP): the key directly as `Authorization: Bearer sgk_…` on every request. Simpler for integrators, but more exposure. It can be added later on the same key record without a schema change.

### 4. Scopes and permissions
- A fixed, versioned scope catalogue in `packages/contracts`. Initial set:
  - `skills:read`
  - `frameworks:read`
  - `credentials:verify`
  - `credentials:read` (issuer's own records)
  - `evidence:metadata:read` and `profiles:read`. These are **always additionally subject to the data subject's consent grant**; a scope alone never grants access to personal data.
- Each key belongs to exactly **one organisation**, and authorization is evaluated as that organisation (tenant isolation and RLS apply as for users).
- **No privilege escalation:** the person creating a key can grant only scopes their own role permits within that organisation. Scopes can be narrowed later but never widened; widening requires a new key.

### 5. Expiration (U-6b)
- `expires_at` is **required**. Proposed default 90 days, maximum 365 days.
- Owners get email reminders 14 days and 3 days before expiry (worker job). Expired keys stop working at once; there's no silent extension.

### 6. Rotation
- A key may have **up to two active secrets**. Rotating creates a new secret and gives the old one a short expiry (proposed grace 24 hours, maximum 7 days), so integrations can switch without downtime. Rotation is audited.

### 7. Revocation
- Revoking a key, or a single secret, takes effect **immediately**. Every token exchange and every token use re-checks key status; there's no cache in the pilot. Access tokens already issued from a revoked key are invalidated too.
- Revocation records who, when and why. Organisation admins and platform admins can revoke; a suspected leak can be revoked from the UI or the API.

### 8. Usage tracking
- Per request, structured logs record `key_id`, organisation, route group, status, latency and request ID.
- Aggregates go into `api_key_usage_daily` (requests, errors, rate-limited count per key, day and route group), retained 13 months. `last_used_at` is updated at most once per minute per key.
- Organisation admins see usage per key in the developer dashboard (Phase 3).
- Creation, rotation, scope narrowing, revocation and expiry are **audit events**.

### 9. Rate limiting
- Buckets per key and per organisation, with limits taken from the key's `rate_limit_tier` (e.g. `sandbox`, `standard`), using the PostgreSQL-backed store (ADR-0006).
- Stricter buckets for `/oauth/token` and for failed authentication, by key ID and by source IP, to stop brute-force and credential-stuffing attempts.
- Responses: `429` with `Retry-After`, plus `RateLimit-Limit`, `RateLimit-Remaining` and `RateLimit-Reset` headers.

### 10. Management
- Create, list, rotate, narrow scopes and revoke through `/api/v1/developer/api-clients…` (PRD §14 paths: create, list, `rotate-secret`, delete = revoke). Allowed for `org_admin` and `api_developer` members, and requires **MFA step-up** (ADR-0009 §5).
- Listing never returns secrets or hashes.

## Data model (reserved; migrations in Phase 3)
- `api_keys`: `id`, `organization_id`, `name`, `key_id` UNIQUE, `environment`, `scopes text[]`, `status` (`active | revoked | expired`), `rate_limit_tier`, `created_by`, `created_at`, `expires_at` NOT NULL, `revoked_at`, `revoked_by`, `revocation_reason`, `last_used_at`
- `api_key_secrets`: `id`, `api_key_id`, `secret_hmac`, `pepper_version`, `last4`, `created_at`, `expires_at`, `revoked_at` (at most 2 active per key, enforced by a trigger)
- `api_access_tokens`: `token_hash` PK, `api_key_id`, `api_key_secret_id`, `scopes`, `expires_at`, `created_at`
- `api_key_usage_daily`: PK (`api_key_id`, `day`, `route_group`), `request_count`, `error_count`, `rate_limited_count`

## Consequences
- A leaked database alone doesn't reveal usable keys (pepper held outside the DB). A leaked pepper and database together still need the 256-bit secret's HMAC preimage, which is infeasible for random secrets.
- Token exchange adds one call per 15 minutes for integrators. Client libraries and examples are part of the Phase 3 developer docs.
- Test coverage required in Phase 3:
  - scope enforcement and no-escalation;
  - cross-tenant denial;
  - expiry;
  - rotation overlap;
  - immediate revocation (including issued tokens);
  - rate-limit headers;
  - redaction of keys in logs.
