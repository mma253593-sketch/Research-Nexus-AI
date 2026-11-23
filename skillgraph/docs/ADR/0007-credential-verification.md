# ADR-0007: Credential verification reports separate facts; unsupported proofs are never "valid"

Status: Proposed — **supported proof formats require owner approval**
Date: 2026-11-23

## Context
FR-06 and PRD §24 require verification of credentials designed for interoperability with W3C Verifiable Credentials Data Model 2.0 and 1EdTech Open Badges 3.0, without claiming conformance, and a UI that keeps signature validity, issuer trust, status, evidence availability and methodology as **separate facts**. PRD rules 3 and 10 forbid fake verification results and unearned compliance claims.

## Decision
1. **Phase 2a (registry):** credentials are registered with `credential_format` and `verification_method`. The verification endpoint performs the checks that SKILLGRAPH can honestly perform:
   - status (from its own status machine);
   - expiry;
   - issuer trust (organisation `issuer_status = 'approved'`);
   - evidence availability;
   - methodology known (linked assessment with a `methodology_reference`).

   `signature` is reported as `not_supported` (or `not_present` for `skillgraph_record`). The UI wording is: "Signature not checked."
2. **Phase 2b (cryptographic proofs), proposed scope:** verify W3C VC 2.0 credentials secured with **Data Integrity `eddsa-rdfc-2022`** and/or **VC-JOSE-COSE (JWT)**, plus status via **Bitstring Status List**, using maintained libraries. A proof suite is enabled only after it passes the official test vectors for that suite; until then it stays `not_supported`.
3. **Issuing** signed VCs or Open Badges 3.0 from SKILLGRAPH requires key management (KMS-held issuer keys and DID or HTTPS key publication). That's a separate ADR, and it's out of scope until the pilot institution confirms it needs SKILLGRAPH to sign credentials, as opposed to registering credentials issued elsewhere.
4. Neither the API nor the UI ever returns an aggregate `verified: true`. The PRD forbids implying assessment validity from a signature.
5. The documentation says "designed for interoperability with W3C VC 2.0 and Open Badges 3.0". Any claim of conformance or certification needs 1EdTech or W3C conformance test results on file.

## Consequences
- Verification is honest from the first release, even before any cryptography is implemented.
- Integrators get a stable response shape. New proof suites change only `signature.result` values, not the schema.

## Open questions (owner)
- Which formats do the pilot institutions actually issue or need? This determines whether Phase 2b is needed in the MVP at all.
- Should SKILLGRAPH *issue* signed credentials in the MVP, or only *register and verify* them?
