# Privacy, PDPA and Cross-Border Data Transfer Requirements

**Status:** Engineering requirements document for owner Decision 7 (2026-11-23). **This isn't legal advice.** Section references come from secondary sources (law-firm and compliance publications, listed below) and must be confirmed by qualified Thai counsel.
**Gate:** **Legal review must be completed before the real-user pilot** (Phase 4). Phase 1–3 development uses demonstration data only. No real personal data is processed until the gate in §6 is passed.

---

## 1. Why this applies
- SKILLGRAPH processes personal data about individuals: identity, skill claims, assessments, evidence, credentials and consent records. The pilot market is Thai vocational education, so **Thailand's Personal Data Protection Act B.E. 2562 (2019) (PDPA)** applies to processing of Thai data subjects' data.
- Hosting is planned in **Singapore** (ADR-0010), and the identity provider may sit in Singapore (Cognito) or elsewhere (ZITADEL Cloud: AU, EU, US or CH). **Storing Thai users' data outside Thailand is a cross-border transfer** under PDPA Sections 28–29.
- A global market means other laws may apply later: Singapore's PDPA (depending on where the operating entity is established), and the EU GDPR if EU residents are targeted. They're out of scope for the pilot, but the design must not prevent compliance.

## 2. PDPA obligations that drive engineering (to be confirmed by counsel)

| Topic (PDPA section as commonly cited) | Engineering requirement | Where handled |
|---|---|---|
| Lawful basis (s.24; consent s.19) | Record a **lawful basis per processing activity**. Don't assume consent is always the basis (PRD §22). `consent_grants.legal_basis` and a processing register | DATA_MODEL §6; RoPA (§6 below) |
| Sensitive data (s.26) | Don't collect sensitive categories (health, biometrics, criminal records, religion and others). Evidence uploads must warn users not to upload such data. Counsel to advise on assessment content | Evidence UX (Phase 2) |
| **Minors** (s.20) | Many vocational students are **under 20, the age of majority under Thai civil law**. The PDPA has special rules for consent from minors. **Counsel must define age handling, guardian consent and the evidence required** before the pilot. Engineering reserves a `date_of_birth`/age-band and guardian-consent model, pending advice | Open legal question L-1 |
| Data subject rights (ss.30–36: access, portability, objection, erasure, restriction, rectification) | Self-service export (machine-readable), deletion workflow including deletion at the IdP (ADR-0009 §7), rectification via profile, consent withdrawal | FR-01, FR-10; Phase 2 |
| Security and **breach notification** (s.37) | Notify the PDPC Office **without delay and, where feasible, within 72 hours** of awareness, unless the breach is unlikely to pose a risk; notify individuals where the risk is high. Requires an incident runbook, audit logs and detection | SECURITY.md; incident runbook (Phase 4) |
| **Records of processing** (s.39) | Maintain a Record of Processing Activities (RoPA): categories, purposes, retention, recipients, transfers | §6 deliverable |
| **Processors** (s.40) | Data processing agreements with every processor (AWS, the IdP vendor, email, any error-monitoring vendor) | §4 |
| DPO (s.41) | Sources disagree on the triggers (large-scale systematic monitoring or sensitive data vs. a numeric threshold). **Counsel decides whether a DPO is required** | Open legal question L-2 |
| **Cross-border transfer** (ss.28–29; PDPC notifications in force since 24 March 2024) | No PDPC adequacy list had been published as of the sources reviewed, so each transfer needs a **Section 29 safeguard** (e.g. standard contractual clauses, BCRs) or a Section 28 exception. Transfer register per destination (§4) | §4 |

## 3. Data inventory (planned)

| Category | Examples | Personal? | Stored where (planned) |
|---|---|---|---|
| Public reference data | Skill definitions, frameworks, approved relationships | No | RDS, Singapore |
| Identity | `issuer`/`sub`, email, display name, language | Yes | RDS Singapore **and** the IdP (region depends on U-5) |
| Authentication | Password, MFA factors, login events | Yes | **IdP only** (SKILLGRAPH stores no passwords) |
| Sessions and audit | Session metadata, truncated IP, audit events | Yes | RDS Singapore; CloudWatch Logs Singapore |
| Capability | Skill claims, assessments, assessor notes | Yes | RDS Singapore |
| Evidence | Metadata; uploaded files | Yes (may be sensitive) | RDS + S3, Singapore |
| Credentials | Credential records, holder linkage, verification logs | Yes | RDS Singapore |
| Consent | Grants, purposes, legal basis | Yes | RDS Singapore |
| Email | Invitations, notifications | Yes (address, content) | Amazon SES Singapore |
| Source code and CI | Code, docs | **Must contain no personal data** | GitHub (US-based service) |

## 4. Transfer register (to be completed with counsel and vendor DPAs)

| Destination | Recipient (role) | Data | Transfer mechanism (to confirm) | Status |
|---|---|---|---|---|
| Singapore (AWS ap-southeast-1) | AWS (processor) | All application data, logs, backups, email | s.29 safeguards via AWS DPA and contractual clauses | **To review** |
| IdP region: Singapore (Cognito) **or** AU/EU/US/CH (ZITADEL Cloud) | IdP vendor (processor) | Identity, authentication, MFA | Vendor DPA and s.29 safeguards | **Depends on U-5** |
| United States | GitHub (processor for code only) | **No personal data allowed** (enforced by policy, secret and PII scanning, and synthetic test data) | Not a personal-data transfer if the policy holds | Policy |
| TBD | Error-monitoring vendor, if any | Must be configured to strip personal data; prefer a Singapore or Thailand region | Vendor DPA | Not selected |
| Institutions (controllers in their own right, or joint controllers) | Pilot institution | Learner assessment and credential data | Controller-to-controller agreement; roles to be defined by counsel | **Open legal question L-3** |

## 5. Engineering controls already in the architecture
- Data minimisation: no passwords and no unnecessary identifiers; IP addresses truncated in audit logs.
- Encryption in transit (TLS) and at rest (RDS and S3 with KMS).
- Private evidence storage; signed URLs valid ≤ 5 minutes.
- Consent records with purpose, scope, expiry and revocation; access re-checked on every request.
- Append-only audit log; deletion workflow that tombstones users while keeping audit integrity.
- `home_region` on users and organisations, so a future Thailand or other regional cell can keep data in-country if counsel or institutions require it (ADR-0010 portability).

## 6. Pre-pilot legal gate (all must be complete before real users)
1. Counsel engaged; PDPA applicability and the **controller/processor roles** of the SKILLGRAPH operating entity and pilot institutions defined (L-3). This includes **which legal entity operates SKILLGRAPH and where it is established** (L-4), which also determines whether Singapore's PDPA applies.
2. Record of Processing Activities with a lawful basis per activity.
3. Privacy notice in Thai and English, and the consent texts (versioned `consent_version`).
4. Minors: age handling and guardian consent approach defined (L-1).
5. DPO decision (L-2).
6. Transfer register completed, with signed DPAs and safeguards for every destination in §4.
7. Breach response runbook tested (72-hour PDPC notification path).
8. Retention schedule approved (audit logs, verification logs, evidence, backups).
9. Data subject request procedures tested end to end (export, deletion including IdP, rectification, consent withdrawal).

## Sources (secondary; to be confirmed against the official PDPA text and PDPC publications)
- [Tilleke & Gibbins: cross-border transfer regulations](https://www.tilleke.com/insights/thailand-unveils-regulations-for-cross-border-personal-data-transfer)
- [Herbert Smith Freehills Kramer: new legislation on cross-border transfer](https://www.hsfkramer.com/notes/data/2024-01/thailands-new-legislation-on-cross-border-transfer-of-personal-data)
- [Clyde & Co: international data transfer notifications](https://www.clydeco.com/en/insights/2024/01/thailand-personal-data-protection-regulation-notif)
- [KPMG Thailand legal news, issue 27](https://kpmg.com/th/en/insights/2024/04/legal-news-update-issue-27.html)
- [Louis Group: PDPA compliance 2026](https://www.louisgrouplaw.com/en/insight/thailand-pdpa-compliance-guide/)
- [Rouse: data localisation in Southeast Asia](https://rouse.com/insights/news/2025/data-localisation-and-transfer-issues-in-southeast-asia-what-businesses-need-to-know)
- [Lex Bangkok: 72-hour breach notification](https://lexbangkok.com/data-breach-notification-thailand/)
- [Anglo Siam Law: DPO, DPA and breach notification](https://anglosiamlaw.com/blog/pdpa-implementation-dpo-dpa-breach-notification-thailand)
- [law.asia: data privacy law comparison, Thailand](https://law.asia/comparison-data-privacy-laws-thailand/)
