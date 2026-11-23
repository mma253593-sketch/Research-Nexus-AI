# SKILLGRAPH CORE — Data Model

**Status:** Proposed (Phase 0). Implemented as numbered SQL migrations in Phase 1/2. Nothing in this document exists in a database yet.

Conventions:

- PostgreSQL 16. Primary keys are `uuid` with default `gen_random_uuid()` (pgcrypto). They are non-guessable; IDs are never sequential.
- All timestamps are `timestamptz`, stored in UTC; columns are named `*_at`.
- Enumerations are `text` columns with `CHECK` constraints, not PostgreSQL `ENUM` types. Adding values to an `ENUM` is awkward inside migrations, and check constraints are easy to evolve.
- `created_at` / `updated_at` on mutable tables; `updated_at` is maintained by trigger.
- Foreign keys use `ON DELETE RESTRICT` unless stated. Personal data is removed by an explicit deletion workflow, never by cascading surprises.
- **[PRD]** marks entities from PRD §10. **[ADDED]** marks additions that the PRD's requirements imply; each one gives its reason.

---

## 1. Identity

### users [PRD]
| Column | Type | Notes |
|---|---|---|
| id | uuid PK | |
| email | citext UNIQUE NULL | NULL after account deletion (tombstone) |
| email_verified_at | timestamptz NULL | |
| display_name | text | 1–100 chars |
| preferred_language | text | `CHECK (preferred_language IN ('th','en'))` |
| account_status | text | `pending_verification | active | suspended | deleted` |
| created_at, updated_at | timestamptz | |

`password_hash` is moved to `user_credentials` so that the most-read table never carries secrets.

### user_credentials [ADDED, split from users]
`user_id` PK/FK, `password_hash` (Argon2id PHC string), `password_changed_at`.

### external_identities [ADDED]
`id`, `user_id`, `provider`, `subject`, UNIQUE(`provider`, `subject`). This holds the PRD's "external_identity_reference" for future OIDC federation.

### sessions [ADDED]
`id`, `user_id`, `token_hash` (SHA-256, UNIQUE), `created_at`, `last_seen_at`, `idle_expires_at`, `absolute_expires_at`, `revoked_at`, `mfa_verified_at`, `user_agent_summary`, `ip_prefix`.
*Reason:* PRD §19 requires session revocation.

### auth_tokens [ADDED]
`id`, `user_id`, `purpose` (`email_verification | password_reset | org_invitation`), `token_hash` UNIQUE, `expires_at`, `consumed_at`. Single use.

### mfa_factors [ADDED]
`id`, `user_id`, `type` (`totp`), `secret_encrypted` (application-level envelope encryption; key from the secret manager), `confirmed_at`, `last_used_step`, plus hashed recovery codes.

### platform_role_assignments [ADDED]
`user_id`, `role` (`platform_admin`), `granted_by`, `granted_at`, `revoked_at`.
*Reason:* platform roles aren't organisation-scoped and must not live on `organization_members`.

## 2. Organizations

### organizations [PRD]
`id`, `name`, `organization_type` (`vocational_college | university | training_center | assessment_body | employer | other`), `country_code` (ISO 3166-1 alpha-2), `website`, `verification_status` (`unverified | pending | verified | rejected`), **`issuer_status`** (`none | requested | approved | suspended`) [ADDED; PRD §25 issuer review], `created_at`, `updated_at`.

### organization_members [PRD]
`id`, `organization_id`, `user_id`, `role`, `membership_status` (`invited | active | suspended | removed`), `created_at`. UNIQUE(`organization_id`, `user_id`).

**Deviation:** the PRD has a single `role` column, but one person can be both instructor and assessor. Proposal: `roles text[]` with a check that every element is in (`org_admin`, `instructor`, `assessor`, `credential_issuer`, `api_developer`), and at least one element. *(decision D-8)*

### organization_invitations [ADDED]
`id`, `organization_id`, `email`, `roles`, `invited_by`, `token_hash`, `expires_at`, `accepted_at`, `revoked_at`.
*Reason:* FR-08 "invite staff".

## 3. Skills, ontology, frameworks

### skills [PRD]
| Column | Notes |
|---|---|
| id | uuid PK, stable forever |
| canonical_code | text UNIQUE, `^[A-Z0-9-]{3,64}$`, immutable after publish (trigger) |
| category | text, FK → `skill_categories.code` [ADDED small lookup table] |
| status | `draft | published | deprecated | retired` |
| version | integer ≥ 1, incremented on every published change |
| source_type | `platform_curated | framework_import | institution_contributed` |
| source_reference | text NULL (citation/URL) — PRD FR-02 "source attribution" |
| created_by, created_at, updated_at | |

**Parent / related / prerequisite skills (FR-02)** are *not* stored as columns on `skills`. They're `skill_relationships` rows (`IS_A`/`PART_OF` for parent, `REQUIRES` for prerequisite, `RELATED_TO` for related). This keeps one source of truth for the graph. The API still returns `parentSkills`, `prerequisites` and `relatedSkills` as convenience projections.

### skill_translations [PRD]
`id`, `skill_id`, `language_code` (`th | en`; extensible), `name`, `description`, `alternative_names text[]`, **`search_text`** (generated: normalised name + alternative names) [ADDED], GIN `gin_trgm_ops` index on `search_text`. UNIQUE(`skill_id`, `language_code`). A published skill must have an `en` translation *(D-10: or `th`?)*.

### skill_revisions [ADDED]
`id`, `skill_id`, `version`, `snapshot jsonb` (the skill plus all its translations at that version), `changed_by`, `changed_at`, `change_note`. Append-only.
*Reason:* MVP acceptance requires "supports versioning". A version number alone doesn't let anyone see what changed.

### skill_relationships [PRD]
| Column | Notes |
|---|---|
| id, source_skill_id, target_skill_id | |
| relationship_type | `IS_A | PART_OF | REQUIRES | RELATED_TO | SPECIALIZATION_OF | TRANSFERABLE_TO | EQUIVALENT_TO` |
| origin | [ADDED] `curated | framework_import | ai_suggested | institution_proposed` |
| confidence | numeric(4,3) NULL, 0–1; **required** when `origin = 'ai_suggested'` |
| evidence_basis | text NULL — FR-03 "evidence basis" |
| source_reference | text |
| review_status | `suggested | approved | rejected | superseded` |
| reviewed_by, reviewed_at | [ADDED] required when `review_status ∈ (approved, rejected)` |
| version | integer |
| created_by, created_at | |

Constraints:

1. `CHECK (source_skill_id <> target_skill_id)`. No self-loops; the PRD gives no use case for them.
2. A **trigger or DB constraint**: a row with `origin = 'ai_suggested'` can be inserted only as `suggested`. Approving it requires a `reviewed_by` user who holds `platform_admin` (FR-03).
3. A partial UNIQUE index on (`source_skill_id`, `target_skill_id`, `relationship_type`) `WHERE review_status IN ('suggested','approved')`.
4. **Acyclicity** for the hierarchical types (`IS_A`, `PART_OF`, `SPECIALIZATION_OF`, `REQUIRES`) is checked by the Ontology service on approval, using a bounded reachability query, and the approval is rejected if it would create a cycle. This isn't a DB constraint because the check is expensive; it's covered by tests instead.
5. Symmetric types (`RELATED_TO`, `EQUIVALENT_TO`) are stored once, with the lower UUID as the source (check constraint), and queried in both directions.

### competency_frameworks [PRD]
`id`, `name`, `provider`, `version`, `source_url`, `license_reference`, **`attribution_text`** [ADDED; rule 4], `imported_at`, `imported_by`. UNIQUE(`provider`, `name`, `version`).

### framework_skills [ADDED]
`id`, `framework_id`, `external_skill_code`, `preferred_label`, `labels jsonb` (per language), `description`, `raw jsonb`. UNIQUE(`framework_id`, `external_skill_code`).
*Reason:* `GET /frameworks/{id}/skills` must list a framework's skills even before they're mapped. The PRD only stores mappings.

### framework_skill_mappings [PRD]
`id`, `framework_id`, `external_skill_code` (FK → framework_skills), `internal_skill_id`, `mapping_type` (`exact | close | broad | narrow | related`, the SKOS mapping vocabulary), `confidence`, `mapping_status` (`suggested | approved | rejected`), `mapping_source` (`manual | import | ai_suggested`), `reviewed_by`, `reviewed_at`, `source_metadata jsonb`.
Rule: **name similarity never creates an `approved` mapping** (FR-04); automated matching can only produce `suggested` mappings.

### proficiency_scales [ADDED]
`id`, `framework_id` NULL, `name`, `levels jsonb` (ordered list of {code, label, description}), `version`.
*Reason:* PRD §12: "If numerical proficiency is used, store the scale definition and framework reference."

## 4. Capability (a person's skills) [ADDED module]

### skill_claims [ADDED]
*Reason:* FR-07, §12 and E2E steps 2 and 6 all need "person P has skill S at level L because of basis B". The PRD data model has no such entity. Without it, possession would have to be inferred from evidence or credentials, which rules 5 and FR-07 forbid.

| Column | Notes |
|---|---|
| id, user_id, skill_id | |
| claim_level | `self_reported | knowledge_assessed | practically_demonstrated | expert_assessed` ("not assessed" = no row) |
| basis_type | `self | assessment | credential` |
| assessment_id | FK NULL, required when `basis_type = 'assessment'` |
| credential_id | FK NULL, required when `basis_type = 'credential'` |
| visibility | `private | shared | public_profile`, default `private` |
| created_at, updated_at, withdrawn_at | |

Rules:

- `basis_type = 'self'` ⇒ `claim_level = 'self_reported'` (check constraint). A user can't self-assert an assessed level.
- One user can hold several claims for the same skill on different bases. The UI shows the strongest claim and why.
- Linking evidence to a skill (`evidence_skills`) **does not** create or upgrade a claim (rule 5).

### assessments [ADDED]
`id`, `subject_user_id`, `skill_id`, `organization_id`, `assessor_user_id`, `method` (`practical | written | oral | portfolio_review | workplace_observation | other`), `methodology_reference` (text/URL; feeds the "assessment methodology known" check), `proficiency_scale_id` NULL, `level_code` NULL, `outcome` (`competent | not_yet_competent | inconclusive`), `assessed_at`, `notes`, `created_at`.
Constraints: the assessor must be an active member of `organization_id` with the `assessor` or `instructor` role, checked by the service and an RLS policy. The PRD's "Assessment Records" screen reads from this table.

## 5. Evidence and credentials

### evidence_records [PRD]
`id`, `owner_user_id`, `organization_id` NULL, `evidence_type` (`project | practical_assessment | examination | work_experience | training_completion | portfolio | institution_assessment | external_credential`), `title`, `description`, `issuer_name` NULL / `assessor_user_id` NULL [FR-05], `assessment_date` NULL, `visibility` (`private | shared | organization`) **DEFAULT 'private'**, `verification_status` (`unverified | institution_confirmed | disputed`) DEFAULT `unverified`, `deleted_at`, `created_at`, `updated_at`.

**Deviation:** the PRD has a single `storage_reference` column. One piece of evidence often has several files, so files move to `evidence_files`.

### evidence_files [ADDED]
`id`, `evidence_id`, `storage_key` (random; never user-supplied), `original_filename` (display only, sanitised), `content_type` (detected from magic bytes), `size_bytes`, `sha256`, `scan_status` (`pending | clean | infected | not_scanned`), `uploaded_at`, `deleted_at`.

### evidence_skills [PRD]
`evidence_id`, `skill_id`, `assessment_level` NULL, `relationship_notes`. PK(`evidence_id`, `skill_id`).

### credentials [PRD]
| Column | Notes |
|---|---|
| id | |
| credential_identifier | text UNIQUE (e.g. `urn:uuid:…`, the VC `id`) |
| issuer_organization_id, holder_user_id | |
| credential_type | e.g. `certificate | badge | micro_credential | license | other` |
| title, description | [ADDED] |
| issued_at, expires_at NULL | `CHECK (expires_at IS NULL OR expires_at > issued_at)` |
| status | `pending | issued | active | expired | revoked | suspended | invalid` |
| credential_format | `skillgraph_record | w3c_vc_2_0 | open_badges_3_0 | external_pdf | other` |
| verification_method | `none | data_integrity_proof | vc_jose | external_lookup` |
| verification_reference | text NULL (status list URL, external lookup URL, …) |
| signed_document | jsonb NULL (the credential as issued, if a structured format) |
| artifact_storage_key | text NULL (PDF or image in private storage) |
| revoked_at, revocation_reason | explicit revocation (rule 6) |
| created_at, updated_at | |

### credential_skills [PRD]
PK(`credential_id`, `skill_id`).

### credential_evidence [ADDED]
PK(`credential_id`, `evidence_id`). FR-06 "evidence references".

### credential_status_events [ADDED]
`id`, `credential_id`, `from_status`, `to_status`, `actor_user_id`, `reason`, `occurred_at`. Append-only. Every status change writes one; a trigger rejects any status change made without it.

### credential_verifications [ADDED]
`id`, `credential_id`, `requested_by_kind`, `requested_by_id` NULL, `checks jsonb` (the full result, ARCHITECTURE §10), `checked_at`.
*Reason:* PRD §24 "record verification time".

## 6. Consent, audit, platform

### consent_grants [PRD]
`id`, `subject_user_id`, `recipient_type` (`organization | user | api_client`), `recipient_id`, `scope text[]` (from the fixed scope list, ARCHITECTURE §11), `resource_ids uuid[]` NULL [ADDED], `purpose` (text, required, shown to the user), **`legal_basis`** [ADDED] (`consent` for user-created grants), `granted_at`, `expires_at` **NOT NULL** *(D-11: maximum duration?)*, `revoked_at`, `consent_version` (version of the consent text shown).
`CHECK (expires_at > granted_at)`.

### audit_logs [PRD]
`id`, `occurred_at`, `actor_kind` (`user | api_client | system | anonymous`), `actor_id` NULL, `organization_id` NULL, `action` (dotted verb, e.g. `credential.revoked`), `resource_type`, `resource_id`, `request_id`, `ip_prefix`, `metadata jsonb` (no secrets, no file contents).
The PRD column `timestamp` is renamed to `occurred_at`, because `timestamp` is a SQL type name.
Append-only enforcement: privileges plus a trigger (ARCHITECTURE §12). Indexes on (`resource_type`, `resource_id`), (`organization_id`, `occurred_at`) and (`actor_id`, `occurred_at`).

### api_clients [PRD]
`id`, `organization_id`, `client_name`, `client_identifier` (public, random, UNIQUE), `secret_hash` (Argon2id; the PRD's `hashed_secret_reference`), `secret_last4` (for display), `permitted_scopes text[]`, `status` (`active | revoked`), `created_by`, `created_at`, `last_used_at`, `secret_rotated_at`.

### api_tokens [ADDED]
`id`, `api_client_id`, `token_hash`, `scopes`, `expires_at` (≤ 15 min), `created_at`. Expired rows are purged by a job.

### idempotency_keys [ADDED]
`principal_id`, `key`, `request_hash`, `response_status`, `response_body jsonb`, `created_at`, `expires_at`. PK(`principal_id`, `key`). Used by `POST /credentials`, `POST /evidence`, `POST /organizations` and `POST /developer/api-clients` (PRD §17).

### data_requests [ADDED]
`id`, `user_id`, `type` (`export | deletion`), `status`, `requested_at`, `completed_at`, `result_storage_key` NULL, `expires_at`. FR-01 "request data export / account deletion".

## 7. Deletion and retention (summary)

- **Account deletion:**
  - Evidence files are deleted from storage, and evidence, claims and consent records are deleted.
  - Sessions and tokens are deleted.
  - The `users` row is tombstoned: `email = NULL`, `display_name = 'Deleted user'`, `account_status = 'deleted'`.
  - Credentials issued *to* the user: the issuer's record remains, as the issuer's own legal record. Holder linkage is retained or anonymised according to a policy that **requires legal review** *(D-12)*.
  - Audit rows are retained; they hold IDs, not PII.
- Retention periods for audit logs, verification logs and expired tokens are configuration values. Their numbers are an owner/legal decision.

## 8. Demonstration data

`database/seeds/demo/` holds demonstration skills (PLC Programming, Sensor Integration, …), one demo framework, and an organisation named "Demo Institution (demonstration data)". Every demo row carries `source_reference = 'DEMONSTRATION DATA — not an official taxonomy'`. The seed command refuses to run when `NODE_ENV=production`. No demo user accounts are created automatically; demo users are created only via `pnpm seed:demo --with-users` and are clearly labelled.
