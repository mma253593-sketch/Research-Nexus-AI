# Final Unresolved Decisions and Risks (before Phase 1)

**Date:** 2026-11-23 · **Owner approval required for every "Decision" row.** Recommendations are engineering opinions, not decisions.

## 1. Decided by the owner (2026-11-23)
| # | Decision | Recorded in |
|---|---|---|
| 1 | SKILLGRAPH in its own repository `SKILLGRAPH`; Research Nexus AI untouched | ADR-0011, REPOSITORY_MIGRATION.md |
| 2 | PostgreSQL + Kysely + version-controlled SQL migrations | ADR-0003 (Accepted) |
| 3 | Managed OIDC; no locally stored user passwords; SKILLGRAPH owns roles, permissions, organisations and API keys; **provider not finalized** | ADR-0009 |
| 4 | AWS Singapore as preferred candidate; **no paid provisioning yet** | ADR-0010, COST_ESTIMATE.md |
| 5 | SKILLGRAPH-issued API keys with the full lifecycle | ADR-0012 |
| 6 | Real OIDC integration tests in isolated environments; no fake authentication | ADR-0009 §11 |
| 7 | PDPA and cross-border requirements documented; legal review before the real-user pilot | PRIVACY_AND_DATA_TRANSFER.md |

## 2. Open decisions

| ID | Decision needed | Recommendation | Blocks |
|---|---|---|---|
| **U-1** | Create the empty `SKILLGRAPH` repository (no README, licence or .gitignore) and give the Claude GitHub App access | — (owner action) | M0 |
| **U-2** | Approve the migration procedure and the import of history to `main` of the new repository | Approve | M0 |
| **U-3** | After verification: delete the SKILLGRAPH side branch in Research-Nexus-AI, or keep it as an archive | Delete after M0 verification (Research Nexus `main` is unaffected either way) | Nothing; housekeeping |
| **U-4** | Repository visibility and licence | Private; no open-source licence until decided (all rights reserved) | M0 |
| **U-5** | Identity provider: **ZITADEL Cloud vs Amazon Cognito** (IDP_COMPARISON.md), then create an isolated **test tenant** | Decide after reading the comparison. Main trade-off: Cognito = Singapore residency, lowest pilot cost, highest lock-in; ZITADEL = native B2B orgs, self-host exit, no Singapore region | L2 OIDC tests, S-6 |
| **U-6a** | API key authentication mode | OAuth 2.0 client-credentials exchange (15-minute tokens); no direct key on every request in the MVP | Phase 3 design |
| **U-6b** | API key defaults | Expiry default 90 days, maximum 365; rotation grace 24 h, maximum 7 days | Phase 3 |
| **U-7** | AWS provisioning approval (when), account structure (separate prod/staging/test accounts recommended), network design (public subnets vs NAT, +$29.65/month), WAF (yes), staging always-on ($135) vs scheduled (~$76) | No-NAT design, WAF on, scheduled staging. Approve provisioning only when M1.7 is reached | M1.7 apply |
| **U-8** | Engage Thai counsel; answer the legal questions L-1 to L-4 (PRIVACY doc §6) | Start during Phase 1, so the gate doesn't delay Phase 4 | Real-user pilot (Phase 4) |
| **U-9** | Accept the Phase 1 defaults for D-3, D-6, D-7, D-8, D-10, D-13 and D-14 (PHASE_1_PLAN §2), and the scope trade-off to fit 4–6 weeks | Accept defaults; choose the scope trade-off | M1.0 |
| **U-10** | Optional: allow `zitadel.com` and `aws.amazon.com` in this environment's network policy, so official pages can be read directly instead of through search results | Allow, if official-page verification before U-5 matters | Better evidence for U-5 |

Still open from Phase 0 but **not needed for Phase 1**: D-9 (malware scanning), D-11 (consent maximum duration), D-12 (credential records after account deletion; legal), D-15 (issue vs register credentials), D-16 (ESCO/O\*NET data and licences; the hosts are blocked here).

### Legal questions (for counsel, U-8)
- **L-1:** Minors. Many vocational students are under 20 (age of majority); consent and guardian rules under the PDPA.
- **L-2:** Is a Data Protection Officer required?
- **L-3:** Controller/processor roles of SKILLGRAPH vs pilot institutions.
- **L-4:** Which legal entity operates SKILLGRAPH and where it is established (also affects Singapore PDPA and GDPR applicability).

## 3. Risks

| Risk | Likelihood / impact | Mitigation |
|---|---|---|
| New repository not created, or app not authorized (as happened with the earlier 403) | Medium / blocks M0 | Clear setup steps (REPOSITORY_MIGRATION §2); verify access and emptiness before any push |
| History extraction mistake | Low / medium | Dry run done (tree hashes identical); fresh extraction plus hash re-check; plain push only; source branch kept until verified |
| Identity provider facts based on search snippets, not pages read directly | Medium / medium | Labelled evidence; S-6 hands-on verification; U-10 |
| Cognito lock-in (hashes and MFA secrets not exportable), if chosen | Certain if chosen / high at exit | Favour institution SSO and passkeys; keep the adapter boundary; documented re-linking runbook |
| ZITADEL overage price unpublished and no Singapore region, if chosen | Certain if chosen / medium | Get a written quote; transfer register entry; self-host option |
| Cost estimate based on assumed usage | High / low–medium | Verified unit prices; reproducible model; re-run with Phase 4 load-test data; AWS Budgets alerts at provisioning |
| PDPA: minors and cross-border transfers unresolved | High / blocks the pilot | Legal gate (PRIVACY §6); demonstration data only until it's passed |
| Phase 1 estimate (≈ 34.5 days) exceeds the PRD's 4–6 weeks | High / schedule | Scope trade-off (U-9) |
| A single engineer owns the security-critical code (OIDC RP, RLS, API keys) | Medium / high | ASVS L2 tests, real OIDC tests, external penetration test before the pilot |
| Thai search quality with trigrams only | Medium / medium | S-1 relevance set with real queries; alternative-name curation |
