# Technical Feasibility Report — Phase 0

**Date:** 2026-11-23
**Scope:** PRD §34 "First Task": environment inspection, runtime versions, available infrastructure, feasibility, and constraints.
**Method:** Every finding below comes from a command run in the development container on this date. Where something could not be checked, it is labelled **NOT VERIFIED**.

---

## 1. Repository state

| Item | Finding |
|---|---|
| Repository | `Research-Nexus-AI`, branch `claude/skillgraph-infrastructure-ubvh4x` (clean, 4 commits from `main`) |
| Existing code | A Vite + React 19 single-page app called **"Research Nexus AI"** (scientific research workspace: papers, hypotheses, experiments, a Gemini-backed chat companion). About 1,800 lines of TSX/TS. |
| Relation to SKILLGRAPH | **None.** No shared domain model, no backend, no database, no tests. It uses `src/data/mockData.ts` and a Gemini API key proxied through a Vite dev-server plugin. |
| Reusable parts | Not as a code base. A few UI ideas (language context, Tailwind setup) are generic and easy to rebuild in Next.js. |
| Consequence | SKILLGRAPH has to be a new code base. What to do with the existing app is a **decision for the owner** (see `PHASE_0_PLAN.md`, decision D-1). These Phase 0 documents add only `docs/` and don't touch the existing app. |

## 2. Runtime and tooling versions (measured)

| Tool | Version | Notes |
|---|---|---|
| Node.js | v22.23.5 | Node 22 LTS line; suitable for NestJS 11/12 and Next.js 16 |
| npm | 10.9.9 | |
| pnpm | 10.28.0 | Proposed workspace manager |
| yarn | 1.22.22 | Not proposed |
| bun | 1.4.4 | Not proposed for production runtime |
| TypeScript (existing app) | ^7.0.2 declared | The new code base will pin its own version |
| PostgreSQL server | 16.15 (Ubuntu package, binaries in `/usr/lib/postgresql/16/bin`) | No service is running by default; started manually (see §3) |
| psql client | 16.15 | |
| Redis server | 7.0.15 | Installed but not proposed for the pilot (see ADR-0006) |
| Docker | Engine 29.10.0, Compose v5.7.1 | Daemon not running by default; see §3 |
| Python | 3.13.18 | Only for tooling, if needed |
| Git | 2.43.0 | |
| Host | Linux x86_64, 4 vCPU, 15 GiB RAM | Development container only, **not** representative of production |

Latest versions of the proposed packages on the npm registry, as of the check: `@nestjs/core` 12.6.0, `next` 16.4.6, `drizzle-orm` 0.45.4, `@node-rs/argon2` 2.2.2. **`prisma`'s `latest` dist-tag points to a pre-release, `8.0.0-rc.34`**; the last stable line is `7.10.1` (tag `prev`). This is one of the inputs to ADR-0003.

## 3. Infrastructure available in this environment

### 3.1 PostgreSQL — available (verified)

- A throwaway cluster was initialised (`initdb`, UTF-8, locale `C.UTF-8`) and started on a non-default port.
- `CREATE EXTENSION pgcrypto` and `CREATE EXTENSION pg_trgm` both succeeded.
- **Thai text search check:**
  - `show_trgm('การเขียนโปรแกรม PLC')` produces trigrams for the Thai characters.
  - `word_similarity('โปรแกรม', 'การเขียนโปรแกรม PLC') = 0.75`.
  - `to_tsvector('simple', 'การเขียนโปรแกรม PLC')` returns `'การเขียนโปรแกรม':1 'plc':2`, so the whole Thai phrase becomes **one token**.
  - **Conclusion:** PostgreSQL built-in full-text search can't segment Thai. Skill search must use **trigram (pg_trgm) indexes** on normalised names and alternative names, with prefix/`ILIKE` matching. This is a design constraint (see `ARCHITECTURE.md` §7). Trigram behaviour depends on the database's `LC_CTYPE`, so the managed production database must use a UTF-8 locale and be re-checked (**NOT VERIFIED** for any specific cloud provider).

### 3.2 Docker — unreliable in this environment

- `dockerd` is installed and can be started manually. One image pull (`postgres:16-alpine`) partially completed. A second pull failed with `failed to copy: failed to send write: EOF`, and the daemon was no longer running afterwards.
- **Conclusion:** `docker-compose.yml` will be provided for developer machines and CI. Automated tests in *this* container will run against the natively installed PostgreSQL 16. Container image builds can't be verified here; CI must verify them.

### 3.3 Object storage — none installed

- No MinIO binary; `dl.min.io` is not reachable through the network policy.
- PRD rule 18 requires real file storage. Proposal (ADR-0005): one `ObjectStorage` interface with two real implementations:
  1. **S3-compatible driver** (AWS SDK v3), used with MinIO in docker-compose and with the chosen provider in production;
  2. **Local filesystem driver** for development and tests: files are really written to a private directory, and downloads go through an HMAC-signed, short-lived URL served by the API.
- The S3 driver's integration tests need MinIO or a real bucket, so they run in CI, not here.

### 3.4 Email delivery — not available

- No SMTP credentials or provider. Email verification and password reset (FR-01) need one.
- Proposal: an `EmailTransport` interface. Development uses Mailpit (docker-compose) or a file-capture transport **only enabled when `NODE_ENV != production`**. Production needs a provider chosen by the owner (decision D-6). The application must refuse to start in production without a configured transport.

### 3.5 External sources

| Host | Result | Impact |
|---|---|---|
| `registry.npmjs.org` | Reachable (HTTP 200) | Dependencies can be installed |
| `registry-1.docker.io` | Reachable (HTTP 401, the normal anonymous response) | Image pulls are possible in principle; see 3.2 |
| `esco.ec.europa.eu` | **Not reachable** (blocked by network policy) | The ESCO dataset and its licence can't be downloaded or reviewed from here |
| `www.onetcenter.org` | **Not reachable** | Same for O\*NET |
| `dl.min.io` | **Not reachable** | See 3.3 |

The ESCO/O\*NET licence review (Phase 0 deliverable) is therefore **NOT DONE**. Engineering understanding, *to be confirmed against the official licence texts*: ESCO is published by the European Commission for free reuse with attribution, and the O\*NET database is published under a Creative Commons Attribution licence. Either the owner supplies the dataset files and licence texts, or the environment's network policy is extended to allow these hosts.

## 4. Feasibility assessment by PRD area

| Area | Feasible here? | Notes / risks |
|---|---|---|
| Modular monolith (NestJS + TypeScript) | Yes | Standard; no blockers |
| PostgreSQL persistence, migrations, RLS | Yes | Verified server; RLS needs a non-owner application role (ARCHITECTURE §6) |
| Skill registry with Thai/English | Yes | Search must be trigram-based (§3.1) |
| Bounded graph traversal | Yes | Recursive CTE with depth and node caps; performance at 100k edges is **not yet measured**. Proposed Phase 0 spike. |
| Authentication (Argon2id, sessions, MFA) | Yes | Argon2id via `@node-rs/argon2` (prebuilt binaries; install **NOT VERIFIED** yet) |
| Email verification / reset | Partially | Code can be built and tested; real delivery needs a provider (D-6) |
| Private object storage | Yes (filesystem driver); S3 driver needs CI/MinIO | §3.3 |
| Background jobs | Yes | Postgres-backed queue (pg-boss) avoids extra infrastructure (ADR-0006) |
| Rate limiting | Yes | Postgres-backed counters for the pilot; revisit with measured load |
| OpenAPI 3.2.1 | **Uncertain** | The PRD asks for 3.2.1. The NestJS Swagger module emits OpenAPI 3.0.x. Whether a 3.2.1 specification exists, and whether validators support it, is **NOT VERIFIED**. Proposal: hand-written contract in the highest version the chosen validator supports (3.1 minimum), with CI checking that implemented routes match it (decision D-7). |
| W3C VC 2.0 / Open Badges 3.0 verification | Feasible, but a real cryptography project | Phase 2. Until a proof suite is implemented, verification must report `signature: not_supported`, never "valid" (ADR-0007). |
| ESCO / O\*NET import | Blocked here | §3.5 |
| Production hosting, backups, data residency | Not assessable here | Owner decision (D-5); no cloud credentials in this environment |
| Performance targets | Not measurable yet | Load tests are Phase 4; this container's numbers would not be representative |

## 5. Overall conclusion

The proposed stack can be built and tested in this environment: Node 22, NestJS, PostgreSQL 16 with RLS and pg_trgm, and Next.js. The real blockers come from outside the code: email delivery, production hosting and residency, ESCO/O\*NET data and licences, the credential proof formats to support, and the owner's decision on the existing Research Nexus AI code. These are listed as decisions in `PHASE_0_PLAN.md` and need answers before Phase 1 scaffolding starts.
