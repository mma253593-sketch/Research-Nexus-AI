# SKILLGRAPH CORE — Security Baseline

**Status:** Proposed (Phase 0). This states *planned* controls. **No control described here exists yet in code.** Each control gets a "Verified by" test reference as it's implemented, and an unchecked control must not be described as in place.

Baselines (PRD §18): **OWASP ASVS 5.0.0** for verification and the **OWASP API Security Top 10 (2023)** as a threat checklist. A per-requirement ASVS mapping (`docs/security/ASVS_MAPPING.md`) is produced in Phase 1. ASVS Level 2 is proposed as the target for the pilot *(decision D-13)*.

---

## 1. Assets and data classification

| Class | Examples | Handling |
|---|---|---|
| Public | Published skill definitions, frameworks, approved relationships, issuer names | Readable anonymously; integrity matters (curated writes are audited) |
| Personal | Profile, skill claims, evidence metadata, credential holder linkage, consent grants | Owner and consented recipients only; RLS; audited access |
| Sensitive personal | Evidence files, assessment notes, exports | Private storage, signed URLs ≤ 5 min, file access audited |
| Secrets | Password hashes, MFA secrets, API client secrets, session/API tokens, signing keys | Hashed or encrypted; never logged; never returned after issuance |
| Organisational | Member lists, assessment records, API clients, org audit logs | Tenant isolation (app check + RLS) |

## 2. Trust boundaries

1. Browser ↔ web/API (internet; untrusted input).
2. External API clients ↔ API (internet; authenticated by client credentials).
3. API ↔ PostgreSQL and object storage (private network; least-privilege roles).
4. API/worker ↔ external hosts: credential status lists, issuer key documents, SMTP. **Outbound traffic is restricted to an allow-list.** User-supplied URLs are never fetched in the MVP, which removes the main SSRF path (OWASP API7). If issuer-key fetching is added in Phase 2, it goes through a guarded fetcher that blocks private, link-local and metadata IP ranges after DNS resolution, enforces HTTPS only, caps size and time, and allows no redirects to new hosts.

## 3. OWASP API Security Top 10 (2023) — planned controls

| Risk | Planned control | Verified by (to be written) |
|---|---|---|
| API1 Broken Object Level Authorization | Resource-level `AuthorizationService.assert` after load; RLS as second layer; 404 on denial | `tests/security/bola.spec.ts`, `tenant-isolation.spec.ts` |
| API2 Broken Authentication | Argon2id; opaque hashed tokens; session expiry and revocation; MFA for privileged roles; generic auth errors; rate limit on auth routes | `auth.*.spec.ts` |
| API3 Broken Object Property Level Authorization | Strict Zod schemas rejecting unknown keys (no mass assignment of `status`, `role`, `owner`); explicit response DTOs per access path | `property-authz.spec.ts` |
| API4 Unrestricted Resource Consumption | Page size ≤ 50/100; graph depth ≤ 3 and node cap; upload size cap; rate limits; import and export as jobs; statement timeout on DB role | `limits.spec.ts` |
| API5 Broken Function Level Authorization | Deny-by-default guard; every route declares a permission or `@Public()`; CI check that no route lacks a declaration | route-inventory test |
| API6 Unrestricted Access to Sensitive Business Flows | Rate limits on registration, verification, consent creation and invitations; invitation tokens single-use | `abuse.spec.ts` |
| API7 SSRF | No user-supplied URL fetching; allow-listed egress (§2) | egress tests (Phase 2) |
| API8 Security Misconfiguration | Helmet headers; CORS allow-list; no stack traces in responses; production refuses to start with insecure config (dev transports, missing secrets, `DEBUG`) | config tests |
| API9 Improper Inventory Management | OpenAPI contract is the inventory; CI fails if an implemented route is undocumented or vice-versa; only `/api/v1` exposed | contract test |
| API10 Unsafe Consumption of APIs | External credential documents and framework imports are treated as untrusted: schema-validated, size-limited, never executed, never displayed as HTML | import tests |

## 4. Authentication specifics

- Argon2id parameters at least the current OWASP Password Storage Cheat Sheet recommendation (e.g. m = 19 MiB, t = 2, p = 1), configurable and stored in the PHC string so hashes can be upgraded on login.
- Password policy: minimum 12 characters, maximum 128; checked against a local breached/common-password list (no external calls); no composition rules (ASVS / NIST SP 800-63B guidance).
- Session cookie: `__Host-` prefix, `Secure`, `HttpOnly`, `SameSite=Lax`, `Path=/`. Idle timeout 30 min for privileged sessions and 7 days for others; absolute timeout 30 days. Values are configurable *(D-14)*.
- The session token is rotated on login and on privilege elevation (MFA step-up).
- Account enumeration: registration, login and reset return the same responses and similar timings for existing and unknown emails.

## 5. Secrets and configuration

- All configuration comes from environment variables and is validated at startup with a Zod schema; the process exits on invalid config.
- `.env.example` documents every variable with **placeholder values only**.
- Production secrets come from the hosting provider's secret manager *(D-5)*. Secrets are never put in frontend bundles: the web app only receives `NEXT_PUBLIC_*` values, and CI asserts that none of them match secret patterns.
- Secret scanning (e.g. gitleaks) runs in CI and as a pre-commit hook. **Existing repository note:** the current `.env.example` contains only placeholders (`MY_GEMINI_API_KEY`), and `.gitignore` excludes `.env*`. No secrets were found in the files inspected during Phase 0; a full-history scan is a Phase 1 task.

## 6. Supply chain

- pnpm lockfile committed; `pnpm install --frozen-lockfile` in CI.
- `pnpm audit` and an SCA tool run in CI. Critical and high findings block merge unless a written risk acceptance exists.
- Minimal dependency policy: each new runtime dependency is justified in the PR description.
- Container images are pinned by digest and run as a non-root user.

## 7. Logging and privacy

- No passwords, tokens, secrets, file contents or full email addresses in logs. Pino redaction is unit-tested.
- IP addresses are stored as truncated prefixes in audit logs (data minimisation).
- Privacy engineering references: NIST Privacy Framework; Thailand PDPA. **Legal basis per processing activity, retention periods, cross-border transfer and DPA templates require qualified legal review before commercial launch.** Engineering doesn't decide these.

## 8. Security gate (PRD §28)

A release is blocked if any of these is true:

- an open critical or high finding;
- failing authorization or tenant-isolation tests;
- unreviewed critical or high dependency advisories;
- secret-scan hits;
- an implemented route missing from the OpenAPI contract.

## 9. Known gaps at Phase 0

| Gap | Plan |
|---|---|
| No malware scanning provider | Interface plus `scan_status`; owner decision D-9 |
| No email provider | D-6; production refuses to start without one |
| No cryptographic credential verification | ADR-0007; reports `not_supported` until implemented and tested against official vectors |
| No penetration test | Required before pilot launch (Phase 4) |
| No ASVS mapping yet | Phase 1 deliverable |
