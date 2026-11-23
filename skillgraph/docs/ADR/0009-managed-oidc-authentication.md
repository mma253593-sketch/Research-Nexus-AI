# ADR-0009: Managed OIDC identity provider behind a replaceable adapter

Status: Proposed. Direction approved by the owner (D-4, 2026-11-23). **Provider choice (A-4), machine-to-machine design (A-5) and test-IdP approach (A-6) still require owner approval.**
Date: 2026-11-23
Supersedes: ADR-0004 (first-party password authentication)

## Context
The owner chose a managed, standards-based OIDC provider instead of building password infrastructure. The integration must be modular so the provider can be replaced, and must not be faked.

Requirements still in force: email verification, account recovery, MFA for privileged roles, session revocation (PRD §19); OIDC-compatible user authentication and OAuth 2.0 client credentials for integrations (PRD §13); organisation-scoped roles enforced by SKILLGRAPH (PRD §20).

## Provider evaluation (research date 2026-11-23)

Sources are listed at the end. Figures from third-party aggregators are marked ³ and must be confirmed on the vendor's own page and in a sales quote before commitment. **Nothing in this table was tested hands-on**; that's spike S-6.

| Criterion | ZITADEL Cloud | Amazon Cognito | Auth0 (Okta) | Microsoft Entra External ID | WorkOS AuthKit |
|---|---|---|---|---|---|
| Standards | OpenID Foundation certified OP ("Basic OP")³; OIDC, SAML | OIDC/OAuth2, SAML federation | OIDC/OAuth2, SAML; mature | OIDC/OAuth2, SAML | OIDC/OAuth2, SAML SSO |
| Security / compliance | SOC 2 Type 2, ISO 27001 (vendor page) | AWS compliance programmes | Mature, widely audited | Microsoft compliance programmes | Not reviewed |
| Multi-tenant B2B orgs | **Native** organisations; unlimited on free tier | No native org model (groups, attributes, or pool per tenant) | Organizations feature; free tier capped at 5 orgs³ | Customer-focused; B2B org model not native | Native organisations, unlimited |
| MFA | TOTP, passkeys, OTP | TOTP, SMS, email OTP, passkeys (Essentials) | Yes; some enterprise MFA is an add-on³ | Yes; SMS billed separately | Yes |
| Institution SSO (per-org IdP) | Yes, per organisation | Yes; **federated users: 50 free MAU, then billed per MAU**³ | Enterprise connections at ~$100/month each beyond plan³ | Yes | Per-connection pricing (~$65–125/month)³ |
| Pricing basis | Free: 100 **daily** active users; Pro from **$100/month incl. 25k DAU** (vendor page) | 10k MAU free (official page); ~$0.015/MAU after³ | Free 25k MAU; B2B Essentials from ~$150/month for 500 MAU³ | 50k MAU free; ~$0.03/MAU after (official FAQ) | Free to 1M MAU (vendor page) |
| Data residency | EU, US, CH, **AU** (no Singapore listed) | **Singapore (ap-southeast-1)**, same region as hosting | US, UK, EU, AU, JP, CA public cloud; Singapore unclear | Location fixed at tenant creation; Go-Local AU/JP only | Not confirmed (US; EU reported³) |
| Lock-in / exit | **Lowest:** open-source core (AGPL-3.0), can self-host the same product in AWS Singapore | **Highest:** password hashes **cannot be exported** (AWS guidance); users must reset passwords or migrate just-in-time | Medium: hash export via support process (to verify) | Medium–high | Medium (not reviewed) |

### Recommendation: **ZITADEL Cloud**, with self-hosted ZITADEL in Singapore as the exit and residency path
- **Best fit for the domain.** Institutions are first-class organisations with their own SSO connections, which matches FR-08 directly.
- **Lowest vendor lock-in.** Because the core is open source, the same system can later run self-hosted in `ap-southeast-1` if data residency or cost requires it, without changing the OIDC integration.
- **Predictable cost.** The free tier is probably enough for a closed pilot; Pro is a flat $100/month up to 25k DAU, per the vendor page.
- **Trade-offs.**
  - The nearest listed cloud region is **Australia, not Singapore**, so identity data (email, name, MFA factors) would sit in AU while application data sits in SG.
  - For Thai users, **both are cross-border transfers under Thailand's PDPA anyway** (see §PDPA below), so this doesn't create a new category of legal risk. It does add a second processor and a second location to the DPA.
  - Daily-active-user billing behaves differently from MAU billing for frequent users.
- **Runner-up: Amazon Cognito in `ap-southeast-1`**, if the owner requires all personal data in one Singapore region from day one. Costs: no native organisation model (SKILLGRAPH's own `organizations` table would be the only one, which is fine because SKILLGRAPH is authoritative anyway), per-MAU charges for federated institution SSO, and the strongest password lock-in. Mitigate the lock-in by preferring passkeys and institution SSO over passwords.
- Not recommended: **Auth0**, whose B2B pricing escalates quickly with organisations and enterprise connections; **Entra External ID**, whose residency options don't include SG and which has no native B2B organisations; **WorkOS**, whose residency is unconfirmed; and **self-hosted Keycloak**, which isn't managed and contradicts D-4.

## Decision (integration design; provider-neutral)
1. **Protocol.** OIDC Authorization Code flow with PKCE. SKILLGRAPH's API acts as a confidential client (backend-for-frontend). Library: `openid-client` (v6.9.1 at review). The provider is configured by issuer URL (discovery), client ID and client secret only.
2. **No IdP tokens in the browser.** After the callback, the API validates the ID token (signature via JWKS, `iss`, `aud`, `exp`, `nonce`) and creates **its own server-side session** in an opaque `__Host-` cookie. The browser never holds IdP access, refresh or ID tokens. IdP refresh tokens are not stored. When a SKILLGRAPH session expires, the user is redirected to the IdP, whose own SSO session makes this seamless.
3. **Identity linking.** Users are keyed by (`issuer`, `sub`) in `external_identities`. Email is copied from claims only when `email_verified = true`, and is **never** used to link accounts automatically, which prevents takeover via a re-used email at another IdP.
4. **Authorization stays in SKILLGRAPH.** Roles, organisation membership, issuer approval and consent live in SKILLGRAPH's database. Nothing authorization-relevant is stored as IdP metadata, so changing provider doesn't change permissions.
5. **MFA for privileged roles.** The IdP performs MFA. Before a privileged action, SKILLGRAPH checks the session's authentication context (`amr` and/or `acr` from the ID token, plus `auth_time`). If it's insufficient, SKILLGRAPH triggers step-up re-authentication (`acr_values` / `max_age` / `prompt=login`). *Whether the chosen provider emits these claims reliably is verified in spike S-6. If it doesn't, the fallback is an IdP policy requiring MFA for every user, which is less fine-grained.*
6. **Logout and revocation.** Local session revocation (one session or all), RP-initiated logout at the IdP `end_session_endpoint`, and support for OIDC Back-Channel Logout, so a user disabled at the IdP loses SKILLGRAPH sessions.
7. **Provider-specific code is confined to one adapter.** `IdentityProviderAdmin` handles: delete user (account deletion workflow), fetch profile (data export), and optionally provision an organisation's SSO connection. One implementation per provider, behind an interface. Login itself is generic OIDC.
8. **Switching providers** means new client configuration plus a new admin adapter plus a re-linking procedure (`sub` values change). That procedure is documented as a runbook: users sign in with the new provider, then link via a verified-email check under an audited, time-boxed migration flag. It's never automatic in normal operation.
9. **Email.** The IdP sends its own verification, recovery and MFA emails. SKILLGRAPH sends only application email (organisation invitations, notifications) through `EmailTransport`. This narrows D-6: recommendation Amazon SES in `ap-southeast-1`.
10. **Machine-to-machine (A-5).** Organisation API clients use OAuth 2.0 client credentials issued by **SKILLGRAPH's Developer API module** (ARCHITECTURE §4), not by the IdP. Reasons: credentials are tenant-scoped resources with SKILLGRAPH scopes; M2M pricing differs between IdPs; and the design survives a provider change. This isn't human password infrastructure: secrets are random, hashed, shown once, and rotatable. *Alternative if the owner prefers:* IdP-issued machine credentials (ZITADEL service users), with SKILLGRAPH mapping the client to an organisation.
11. **No fake authentication (A-6).** There is no "dev login", no bypass flag, and no hard-coded user.
    - Automated integration tests run a **real OIDC authorization server** in-process: `oidc-provider` (v9.15.1 at review, by the author of `openid-client`). It uses real signatures and JWKS and is configured as a test fixture only. It lives under `test/`, is never bundled into the application, and production config validation rejects non-HTTPS issuers.
    - Manual development and staging use a **real tenant of the chosen provider**. Its client secret is supplied through the environment's secret store.
    - The PRD's E2E workflow is run against the real provider tenant in staging before Phase 1 exit.

## Consequences
- The ADR-0004 tables `user_credentials`, `auth_tokens` (verification/reset purposes) and `mfa_factors` are removed from the data model (DATA_MODEL §1).
- Phase 1 depends on the owner creating a provider account and development tenant (A-4). Until that exists, the identity milestone can be built and tested only against the test IdP, and that limitation is reported.
- Session timeouts (D-14) still apply to SKILLGRAPH sessions; the IdP's SSO session length is configured to match.

## PDPA note (not legal advice)
As of the sources reviewed, Thailand's PDPC has **not published an adequacy list**. Transfers abroad, including to Singapore or Australia, need a Section 28 exception or Section 29 safeguards (e.g. contractual clauses or BCRs). Hosting in Singapore therefore doesn't avoid the cross-border question for Thai users. Qualified legal review is required before the pilot handles real personal data (PRD §22).

## Sources
- ZITADEL pricing and regions: https://zitadel.com/pricing, https://zitadel.com/zitadel-cloud. Licence: https://zitadel.com/opensource. Self-hosting: https://zitadel.com/self-hosted
- Amazon Cognito pricing: https://aws.amazon.com/cognito/pricing/. Migration and hash export: https://aws.amazon.com/blogs/security/approaches-for-migrating-users-to-amazon-cognito-user-pools, https://workos.com/docs/migrate/aws-cognito.md. Hash import (Jul 2026): https://aws.amazon.com/about-aws/whats-new/2026/07/amazon-cognito-password-hash-import/
- Auth0 regions: https://auth0.com/platform/cloud-deployment. Pricing (third-party): https://ssojet.com/blog/auth0-pricing-growth-penalty, https://www.casdoor.com/blog/auth0-pricing
- Entra External ID pricing: https://www.microsoft.com/en-us/security/pricing/microsoft-entra-external-id. Residency: https://learn.microsoft.com/en-us/entra/fundamentals/data-residency
- WorkOS pricing: https://workos.com/pricing, https://workos.com/authkit
- PDPA transfers: https://www.louisgrouplaw.com/en/insight/thailand-pdpa-compliance-guide/, https://rouse.com/insights/news/2025/data-localisation-and-transfer-issues-in-southeast-asia-what-businesses-need-to-know
