# Identity Provider Comparison: ZITADEL Cloud vs Amazon Cognito

**Status:** Factual comparison for owner decision U-5. **No provider is selected.** (Owner Decision 3: managed OIDC approved; ZITADEL not finalized.)
**Date of research:** 2026-11-23

## How to read the evidence labels
| Label | Meaning |
|---|---|
| **[PL]** | Verified from the **official AWS Price List** bulk file `AmazonCognito` for `ap-southeast-1` (publication 2026-11-19), parsed directly. Extract in `docs/cost/aws-price-snapshot-2026-11.txt`. |
| **[OFF]** | From an official vendor page or documentation, **seen through web-search results** (titles and snippets). The page itself couldn't be opened: `zitadel.com` and `aws.amazon.com` are blocked by this environment's network policy. |
| **[3P]** | Third-party source (blog or aggregator). Lower confidence. |
| **[UNV]** | Not verified; no reliable source found. |

Neither provider was tested hands-on. That's spike S-6, which needs an account with the chosen provider.

## Context that narrows the decision
SKILLGRAPH manages its **own** organisations, roles, permissions and API keys (owner Decisions 3 and 5). The identity provider is used only for: sign-in (OIDC), MFA, email verification and recovery, and federation with institution SSO. IdP "organisation" features therefore matter mainly for **per-institution SSO routing and branding**, not for authorization.

## Comparison

| Dimension | ZITADEL Cloud | Amazon Cognito (user pools) |
|---|---|---|
| **Pricing model** | Daily active users (DAU). A user counts once per day they sign in or refresh a token; monthly usage is the **sum of daily counts** [3P] | Monthly active users (MAU) [PL] |
| **Free tier** | Free plan: 100 DAU, 1 instance, 3 identity providers [OFF] | **10,000 MAU** free on Lite/Essentials (`Global-CognitoFreeTierMAU` 0–10,000) [PL]. No free tier on Plus [OFF] |
| **Paid prices** | Pro: **US$100/month incl. 25,000 DAU**, custom domain, 3 enterprise/social IdPs [OFF]. Overage price per DAU **not published** [3P]. Enterprise: custom [OFF] | Singapore per MAU: **Lite $0.0055** (0–90k; tiered down to $0.0025); **Essentials $0.015**; **Plus $0.020** [PL] |
| **Institution SSO (federated users)** | Included IdP connections: 3 on Pro [OFF]; price per additional connection [UNV] | **50 federated MAU free, then $0.015 per federated MAU** (`CognitoEnterpriseMAU`) [PL] |
| **Machine-to-machine** | Service users [OFF] | M2M token requests, tier 1: 0.00225 USD per unit [PL] (the file doesn't say whether a unit is 1 or 1,000 requests). **Not needed:** SKILLGRAPH issues its own API keys (ADR-0012) |
| **Organisation support** | **Native organisations** (multi-tenant B2B), unlimited on the free tier [OFF/3P]; per-organisation IdPs and branding [OFF] | No native organisation object. AWS documents four multi-tenancy patterns: **pool per tenant, app client per tenant, group per tenant, custom attribute** [OFF]. Quotas are shared per account and region [OFF]. A local user's session cookie works across all app clients in the same pool [OFF]. Custom attributes are fixed at pool creation, max 50 [OFF] |
| **MFA / passwordless** | MFA and passwordless on all plans, no paywall for OTP or passwordless [3P]. Exact factor list (TOTP, passkeys, SMS, email) **not confirmed from the official page** [UNV] | Lite: classic features [OFF]. **Essentials:** managed login, passwordless with **passkeys, email or SMS** [OFF]. **Plus:** risk-based adaptive auth, compromised-credential detection, auth event export [OFF]. SMS is billed separately [UNV amount] |
| **Regions / data residency** | Cloud regions: **EU, US, Switzerland, Australia** [OFF]. **No Singapore** region found | Runs in **ap-southeast-1 (Singapore)**: Singapore prices exist in the official price list [PL]. Identity data can sit in the same region as application data |
| **Compliance** | SOC 2 Type 2, ISO 27001 [OFF]. OpenID Foundation certified "Basic OP" [3P] | Covered by AWS compliance programmes [UNV for Cognito specifically] |
| **SLA** | Pro 99.5% [OFF/3P]; Enterprise up to 99.99% [OFF] | [UNV] |
| **Migration into the provider** | Import API accepts password hashes in Modular Crypt Format; **bcrypt** works [OFF]; Argon2 import reported failing [3P community] | CSV import **with password hashes** announced July 2026 (bcrypt, PBKDF2-SHA256 reported) [OFF via search]; older docs say otherwise. Just-in-time migration via Lambda trigger [OFF] |
| **Migration out (exit)** | Self-hosting the same open-source product (AGPL-3.0 core) keeps APIs and data under your control [OFF]. Exporting **password hashes from ZITADEL Cloud** [UNV] | **Password hashes and MFA secrets can't be exported** [OFF AWS security blog; WorkOS migration doc]. Exit means users reset passwords, or a just-in-time migration that keeps the old pool running [OFF] |
| **Vendor lock-in** | **Lower:** open-source core and a self-host option; standard OIDC/SAML | **Higher:** non-exportable hashes and MFA secrets; AWS-specific configuration (Lambda triggers, pool settings) |
| **Fit with AWS Singapore hosting** | Separate vendor and processor; identity data in AU, EU, US or CH, so an **additional cross-border transfer** (PRIVACY doc) | Same account, region and DPA as the application; one transfer destination for everything |
| **Local and CI testing (owner Decision 6)** | The OSS ZITADEL container can run in CI as the **same product** in an isolated network [OFF: self-host docs] | No official local emulator. Real tests need a **dedicated test user pool** in an isolated AWS account; protocol-level tests use a standards OIDC server [UNV for emulator options] |

## Indicative IdP cost for pilot scenarios
Cognito figures are computed from [PL] prices. ZITADEL figures use [OFF] plan prices only; overage can't be computed, because the per-DAU price isn't published.

| Scenario | Cognito Essentials (SG) | ZITADEL Cloud |
|---|---|---|
| Pilot: 500 MAU, of which 300 use institution SSO | 500 MAU within free tier = $0; federated: (300 − 50) × $0.015 = **$3.75/month** | Free plan only if daily actives stay ≤ 100 [OFF]. Otherwise **Pro $100/month** (25k DAU covers e.g. 500 users × 20 active days = 10k) |
| Growth: 20,000 MAU, none federated | (20,000 − 10,000) × $0.015 = **$150/month** | 20,000 users × 5 active days = 100k DAU-days, **above** the 25k included. **Cost unknown** (overage unpublished) |
| Growth: 20,000 MAU, all via institution SSO | (20,000 − 50) × $0.015 = **$299.25/month**\* | Same as above: unknown |

\* Assumes federated users are billed only at the federated rate. Whether they *also* count toward the Essentials MAU charge isn't stated in the price file **[UNV]**. Confirm in the AWS Pricing Calculator.

## Summary of trade-offs (no recommendation is final)
- **Choose Cognito if:**
  - single-region Singapore residency for *all* personal data matters most;
  - you want to consolidate on AWS;
  - you want the lowest pilot cost.

  Accept higher exit cost (non-exportable hashes) and do multi-tenant SSO routing in SKILLGRAPH. Mitigate lock-in by favouring institution SSO and passkeys over passwords.
- **Choose ZITADEL Cloud if:**
  - institution-SSO-heavy B2B onboarding matters;
  - a credible exit path (self-hosting) matters;
  - you want to run the same product in CI.

  Accept an extra processor in Australia, Europe or the US (no Singapore region), DAU-based billing with unpublished overage, and a lower pilot cost certainty.

## What must be verified hands-on before finalizing (spike S-6)
1. The official pricing pages, read directly. This needs `zitadel.com` and `aws.amazon.com` allowed in the session network policy, or the owner reading them.
2. `amr`/`acr` claims after MFA, used for SKILLGRAPH step-up checks.
3. Back-channel logout and the `sid` claim.
4. Admin APIs for user deletion and profile export (data-subject requests).
5. Per-organisation SSO configuration, including the Thai-language login UI.
6. Data export: what can actually be taken out, including password hashes (ZITADEL Cloud) and MFA enrolment.

## Sources
- AWS Price List bulk API, `AmazonCognito/current/ap-southeast-1` (publication 2026-11-19)
- [Amazon Cognito pricing](https://aws.amazon.com/cognito/pricing/)
- [Cognito user pool feature plans](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-sign-in-feature-plans.html)
- [Cognito Plus plan features](https://docs.aws.amazon.com/cognito/latest/developerguide/feature-plans-features-plus.html)
- [Announcing Essentials and Plus tiers](https://aws.amazon.com/about-aws/whats-new/2024/11/new-feature-tiers-essentials-plus-amazon-cognito)
- [Cognito multi-tenant application best practices](https://docs.aws.amazon.com/cognito/latest/developerguide/multi-tenant-application-best-practices.html)
- [Cognito user-pool multi-tenancy](https://docs.aws.amazon.com/us_en/cognito/latest/developerguide/bp_user-pool-based-multi-tenancy.html)
- [Cognito custom-attribute multi-tenancy](https://docs.aws.amazon.com/cognito/latest/developerguide/custom-attribute-based-multi-tenancy.md)
- [AWS Security Blog: SaaS identity with Cognito](https://aws.amazon.com/blogs/security/saas-authentication-identity-management-with-amazon-cognito-user-pools)
- [AWS: approaches for migrating users to Cognito](https://aws.amazon.com/blogs/security/approaches-for-migrating-users-to-amazon-cognito-user-pools)
- [WorkOS: migrating from Cognito](https://workos.com/docs/migrate/aws-cognito.md)
- [AWS what's new: Cognito password hash import (Jul 2026)](https://aws.amazon.com/about-aws/whats-new/2026/07/amazon-cognito-password-hash-import/)
- [ZITADEL pricing](https://zitadel.com/pricing)
- [ZITADEL Cloud](https://zitadel.com/zitadel-cloud)
- [ZITADEL self-hosted](https://zitadel.com/self-hosted)
- [ZITADEL open source](https://zitadel.com/opensource)
- [ZITADEL user migration guide](https://zitadel.com/docs/guides/migrate/users)
- [ZITADEL import human user API](https://zitadel.com/docs/apis/mgmt/management-service-import-human-user)
- [ZITADEL community: hash import question](https://questions.zitadel.com/m/1386700095466242110)
- [Casdoor on ZITADEL pricing (3P)](https://www.casdoor.com/blog/zitadel-pricing)
- [agentdeals ZITADEL free tier (3P)](https://agentdeals.dev/vendor/zitadel-cloud)
- [Authgear: Keycloak vs ZITADEL (3P)](https://www.authgear.com/post/keycloak-vs-zitadel)
