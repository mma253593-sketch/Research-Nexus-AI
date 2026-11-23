# ADR-0006: PostgreSQL-backed jobs and rate limiting for the pilot

Status: Proposed
Date: 2026-11-23

## Context
The PRD requires background jobs (imports, exports, deletion) and rate limiting on auth, search, uploads, exports and verification. Pilot load targets are modest: 100 concurrent users and 50 API clients (PRD §27). Every extra infrastructure component adds backup, security and operations work.

## Decision
- **Jobs:** `pg-boss` on the primary PostgreSQL, in its own schema. Jobs are idempotent with singleton keys, and failed jobs use retry with backoff and a dead-letter state visible in the admin "System Health" screen.
- **Rate limiting:** a fixed-window counter in an `UNLOGGED` PostgreSQL table, keyed by (bucket, subject, window), updated with a single `INSERT … ON CONFLICT … RETURNING`. Behind a `RateLimitStore` interface so Redis can replace it without touching call sites.
- **Revisit trigger:** if load tests (Phase 4) show rate-limit writes above ~5% of DB CPU or p95 impact above 20 ms, switch the store to Redis (Redis 7 is installed in the dev environment, so the switch is testable).

## Consequences
- The pilot runs on PostgreSQL plus object storage only.
- Rate-limit counters are lost on crash (`UNLOGGED`). That's acceptable: the failure mode is briefly relaxed limits, not data loss.

## Alternatives considered
- Redis/BullMQ from day one: a proven option, but an extra stateful service with no measured need yet.
- In-memory rate limiting: wrong as soon as there's more than one API instance.
