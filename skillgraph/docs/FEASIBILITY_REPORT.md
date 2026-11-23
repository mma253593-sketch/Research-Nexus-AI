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
| Consequence | SKILLGRAPH has to be a new code base. What to do with the existing app is a **decision for the owner** (see `PHASE_0_PLAN.md`, decision D-1). **Resolved (D-1, 2026-11-23):** keep Research Nexus AI unchanged; SKILLGRAPH lives in `skillgraph/` (ADR-0008). See §6. |

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

- No SMTP credentials or provider. Email verification and password reset (FR-01) need one. *(Update after D-4: the managed IdP sends verification and recovery email; SKILLGRAPH only needs email for invitations and notifications. See ADR-0009.)*
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
| Authentication (Argon2id, sessions, MFA) | Yes | *Superseded by D-4:* managed OIDC provider (ADR-0009). Protocol testing is feasible here with an in-process OIDC server. Real-provider testing needs a provider tenant from the owner (**NOT VERIFIED**). |
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

---

## 6. Addendum — decision review, 2026-11-23

Re-checked after owner decisions D-1, D-2, D-4 and D-5. Every result below comes from a command run in this container on 2026-11-23. Temporary files used for probing were removed afterwards, and the working tree was confirmed clean.

### 6.1 Existing Research Nexus AI baseline
| Check | Result |
|---|---|
| `npm install` (as the repo is) | **Fails:** `ERESOLVE`. `devDependencies.esbuild@^0.25.0` conflicts with `vite@8.3.8` peer `esbuild ^0.27.0 \|\| ^0.28.0`. **Pre-existing; not caused by SKILLGRAPH.** |
| `npm install --legacy-peer-deps` | Succeeds (181 packages) |
| `npm run lint` (`tsc --noEmit`) | Exit 0, 0 errors |
| `npm run build` (`vite build`) | Exit 0 (warning only: a chunk > 500 kB) |

### 6.2 Coexistence conflicts (probe files under `skillgraph/`, then removed)
| Conflict | Evidence | Fix (tested, then reverted; needs approval A-1) |
|---|---|---|
| Root `tsconfig.json` has no `include`, so `tsc` compiles SKILLGRAPH files | `npm run lint` failed with `TS2307: Cannot find module '@nestjs/common'` from `skillgraph/apps/api/src/probe.ts` | Add `"exclude": ["node_modules","dist","skillgraph"]`. Lint returns to exit 0 |
| Tailwind v4 scans the whole project for class names | Probe class `bg-[#123457]` appeared in the Research Nexus CSS bundle | Add `@source not "../skillgraph";` to `src/index.css`. CSS becomes **byte-identical** to a build without any SKILLGRAPH files |
| **Already happened:** the Phase 0 Markdown docs (commit `df969bf`) are scanned too | The CSS bundle with docs present gained `.container` and `.table` (65,120 vs 64,827 bytes). Neither class is used anywhere in `src/` (grep), so there's no visual change, but the bundle did change | Same `@source not` line, after the docs moved to `skillgraph/docs/` (done in this revision) |
| Root `.env` loaded by `vite.config.ts` (`dotenv.config()`) | Read of config | SKILLGRAPH uses only `skillgraph/.env`; the root `.gitignore` already covers `.env*` at any depth |
| Same `/api` prefix in dev | Research Nexus serves `/api/chat` from its Vite dev server | Separate origins/deployments; no shared host |
| AI Studio origin | `metadata.json` and `.env.example` reference Google AI Studio and Cloud Run | **Unknown whether AI Studio still writes to this repo.** Owner to confirm (A-3) |

### 6.3 Thai search under managed-database locales
Managed PostgreSQL typically uses `en_US.UTF-8`, while the earlier test used `C.UTF-8`. Both were tested in separate PostgreSQL 16.15 clusters:

| Test | C.UTF-8 | en_US.UTF-8 |
|---|---|---|
| `word_similarity('เซ็นเซอร์', 'การติดตั้งเซ็นเซอร์อุตสาหกรรม')` | 0.778 | 0.778 |
| `word_similarity('ซ่อมบำรุง', 'งานซ่อมบำรุงเครื่องกล')` | 0.70 | 0.70 |
| `ILIKE '%โปรแกรม%'` on 20,001 rows with a GIN `gin_trgm_ops` index | Bitmap Index Scan, 1 correct row | Bitmap Index Scan, 1 correct row |

Conclusion: trigram search for Thai behaves identically under both locales, and substring queries use the index. Re-check on the real RDS instance once it exists (it's in M1.7).

### 6.4 Prices and versions
- AWS public price list for `ap-southeast-1` (publication 2026-11-20) was downloaded and parsed. Results are in ADR-0010. NAT gateway prices weren't in the parsed files and are **NOT VERIFIED**.
- Library versions on npm at review: `openid-client` 6.9.1, `oidc-provider` 9.15.1, `kysely` 0.29.9, `kysely-codegen` 0.20.0, `pg` 8.23.1, `pg-boss` 12.39.0, `@nestjs/core` 12.6.0, `next` 16.4.6, `next-intl` 4.15.3, `@xyflow/react` 13.0.2, `zod` 4.6.7, `@aws-sdk/client-s3` 3.1175.0.
- Identity provider and non-AWS hosting facts come from web research (sources in ADR-0009 and ADR-0010). **None of the providers was tested hands-on**; that's spike S-6, and it needs a provider account.

---

## 7. Addendum — second decision review, 2026-11-23

| Check | Result |
|---|---|
| `SKILLGRAPH` repository visible to this session | **No.** A repository search for "skillgraph" returned an empty list. The owner must create it (REPOSITORY_MIGRATION §2) |
| Research-Nexus-AI `main` | `c268948`, unchanged; no SKILLGRAPH commit ever merged |
| History extraction dry run (`git-filter-repo` 2.47.0, throwaway clone) | 2 commits kept; only `docs/`; no Research Nexus paths; tree hashes identical to source (REPOSITORY_MIGRATION §4) |
| AWS Price List bulk files, ap-southeast-1 | Downloaded and parsed: Cognito, Data Transfer, CloudWatch, Secrets Manager, ECR, SES, WAF, CloudTrail, EC2 (NAT gateway now **verified**: $0.059/h, $0.059/GB). KMS and Route 53 hosted-zone prices weren't found in usable form, so they're marked as assumptions |
| Official vendor pages (`zitadel.com`, `aws.amazon.com`) | **Blocked by the environment's network policy** (proxy 403 / DNS failure). Vendor statements are taken from search results and labelled as such in IDP_COMPARISON.md |
