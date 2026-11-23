# ADR-0004: First-party authentication with server-side sessions; OAuth 2.0 client credentials for integrations

Status: **Rejected / superseded by [ADR-0009](0009-managed-oidc-authentication.md).** The owner chose a managed OIDC provider (decision D-4, 2026-11-23). This record is kept for history; don't implement it.
Date: 2026-11-23

## Context
PRD §13 and §19 require "OIDC-compatible user authentication", Argon2id hashing, email verification, password reset, MFA for privileged roles, session revocation, OAuth 2.0 client credentials for integrations, and short-lived, rotatable credentials. The PRD also forbids bypassing authentication for convenience.

There are two realistic paths:

| | A. First-party (proposed) | B. External IdP (e.g. Keycloak self-hosted, or a managed provider) |
|---|---|---|
| Control over data residency | Full | Depends on provider and region |
| Extra infrastructure | None | IdP service (self-hosted) or vendor contract |
| Build effort | Higher (~1–1.5 weeks of Phase 1) | Lower for login flows; integration and RBAC mapping still needed |
| MFA, reset, verification | Must be built and tested | Provided |
| Institution SSO later | Needs OIDC relying-party code (planned via `external_identities`) | Usually built-in federation |

## Decision (proposed)
Option **A** for the pilot:

- Argon2id password hashes (`@node-rs/argon2`), opaque random session tokens stored as SHA-256 hashes, `__Host-` cookies, idle and absolute expiry, revocation per session and globally.
- Email verification and reset via single-use hashed tokens (24 h and 30 min).
- TOTP MFA required for privileged roles, enforced by step-up before privileged actions.
- API integrations: `POST /api/v1/oauth/token` implementing the client-credentials grant (RFC 6749 §4.4). Client secrets are Argon2id-hashed and shown once. Access tokens are opaque, last 15 minutes and are scope-bound. No refresh tokens for client credentials.
- "OIDC-compatible" means: the identity schema supports federated identities (`external_identities`), so institution SSO via OIDC can be added as a relying party without a migration. SKILLGRAPH does not act as an OIDC provider in the MVP.

## Consequences
- No external dependency or vendor lock-in; all identity data stays in the primary database under the chosen residency.
- The team owns security-critical code. Mitigation: well-reviewed libraries for primitives (argon2, TOTP via `otplib` or equivalent), ASVS V6/V7 test coverage, and an external penetration test before the pilot.

## Alternatives considered
Option B is reasonable if the owner prefers to outsource identity, or if pilot institutions require SSO from day one. Switching later is feasible, because sessions are already behind an `AuthenticationService` interface.
