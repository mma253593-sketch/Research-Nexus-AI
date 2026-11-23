# ADR-0005: Object storage abstraction with S3 and filesystem drivers

Status: Proposed
Date: 2026-11-23

## Context
FR-05 and PRD §7 require private object storage, metadata in PostgreSQL, and short-lived signed URLs. PRD rule 18 requires real file storage. The Phase 0 environment has no MinIO, `dl.min.io` is blocked, and Docker is unreliable (FEASIBILITY_REPORT §3.2–3.3). The production provider is undecided (D-5).

## Decision
- An `ObjectStorage` interface with `putObject(stream, {contentType, sha256, maxBytes})`, `headObject`, `deleteObject` and `getSignedDownloadUrl(key, ttlSeconds ≤ 300)`.
- **S3 driver** (AWS SDK v3, path-style optional), for MinIO in docker-compose, AWS S3, or any S3-compatible provider. The bucket must block public access; the driver never sets public ACLs.
- **Filesystem driver**, for development and tests. It writes real files under a configured directory outside the web root, with `0600` permissions. Signed URLs point to `GET /api/v1/files/{key}?exp=…&sig=…`, where `sig` = HMAC-SHA256(key‖exp) with a secret from config. Signatures are compared in constant time, and expired or invalid requests return 404.
- The production configuration refuses the filesystem driver unless `STORAGE_ALLOW_FILESYSTEM_IN_PRODUCTION=true` is set explicitly. It's off by default, because it doesn't survive container replacement.
- Object keys are random UUIDs; user-supplied file names are metadata only.

## Consequences
- Development and CI tests exercise real writes and reads without a cloud account.
- The S3 driver's integration tests require MinIO (CI with Docker) and are skipped, with a visible reason, where it isn't available. Skips are reported, never counted as passes.

## Alternatives considered
- Storing files in PostgreSQL `bytea`: violates FR-05 ("not directly in public database records") and bloats backups.
- An S3 emulator from npm (e.g. `s3rver`): unmaintained; MinIO in CI is a more faithful target.
