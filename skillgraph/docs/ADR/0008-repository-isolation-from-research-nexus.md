# ADR-0008: SKILLGRAPH lives in `skillgraph/`, isolated from Research Nexus AI

Status: Proposed. Direction approved by the owner (D-1, 2026-11-23). **The two isolation edits to the existing app (§Decision 3) still require owner approval.**
Date: 2026-11-23
Supersedes: the root-level layout in ARCHITECTURE §16 (original Phase 0 version)

## Context
The owner decided (D-1) that the existing **Research Nexus AI** application must be preserved unchanged in function, and that SKILLGRAPH is a separate product with its own application logic, API, database schema, deployment configuration and security boundaries, in a clearly separated structure within this repository if technically appropriate.

Facts measured on 2026-11-23 (details in FEASIBILITY_REPORT §6):

1. Research Nexus AI occupies the repository root: `package.json` (npm, no lockfile), `vite.config.ts`, `tsconfig.json`, `index.html`, `src/`, `public/`, `metadata.json`, `.env.example`. It was built for Google AI Studio deployment (`metadata.json`, `.env.example`).
2. **Baseline:** `npm install` fails with a pre-existing peer-dependency conflict (`esbuild@^0.25` declared vs. `vite@8` peer `esbuild ^0.27 || ^0.28`). With `--legacy-peer-deps`, `npm run lint` (`tsc --noEmit`) exits 0 and `npm run build` exits 0.
3. **Conflict A (type-check):** root `tsconfig.json` has no `include`, so `tsc` compiles every `.ts`/`.tsx` file under the root. A probe file `skillgraph/apps/api/src/probe.ts` importing `@nestjs/common` made Research Nexus `npm run lint` fail (`TS2307`).
4. **Conflict B (CSS):** Tailwind v4 (`@import "tailwindcss"` in `src/index.css`) auto-detects class names in every non-ignored file of the project. A probe `skillgraph/apps/web/app/probe.tsx` using `bg-[#123457]` added that class to the Research Nexus CSS bundle. The Phase 0 Markdown docs (commit `df969bf`) **already** added two unused classes, `.container` and `.table` (+293 bytes), to that bundle. Neither class name is used in `src/`, so there is no visual change, but the build output did change.
5. With the two edits in Decision 3 applied (tested, then reverted), lint exits 0 and the CSS bundle is **byte-identical** to the bundle built without any SKILLGRAPH files present.

## Decision
1. All SKILLGRAPH files live under `skillgraph/`: its own pnpm workspace (`skillgraph/pnpm-workspace.yaml`, `skillgraph/package.json`, `skillgraph/pnpm-lock.yaml`), its own `.env.example`, `docker-compose.yml`, migrations, OpenAPI, tests and docs. Nothing SKILLGRAPH-specific is added to the repository root.
2. **Isolation rules**
   - No imports across the boundary in either direction. CI fails if any file under `skillgraph/` imports from `../src` or vice versa (a grep or dependency-cruiser rule).
   - Separate environment files: SKILLGRAPH reads only `skillgraph/.env` (or real environment variables). The root `vite.config.ts` calls `dotenv.config()` on the root `.env`; SKILLGRAPH never reads or writes it. The root `.gitignore` already ignores `.env*` (except `.env.example`) at every depth, which covers `skillgraph/.env`.
   - Separate deployment: SKILLGRAPH has its own container images, infrastructure code (`skillgraph/infra/`), domains and secrets. It is never served on the Research Nexus origin. Research Nexus uses `/api/chat` on its own dev server; SKILLGRAPH's `/api/v1` is on a different host.
   - Separate CI: path-filtered workflows (`skillgraph/**` vs. everything else). On every SKILLGRAPH PR, a **Research Nexus regression guard** job runs the existing app's lint and build and checks that its CSS bundle hash is unchanged by `skillgraph/` content.
3. **Two minimal edits to the existing app are required** for the folder to coexist safely. **Owner approval is needed before they are made.**
   - `tsconfig.json`: add `"exclude": ["node_modules", "dist", "skillgraph"]`.
   - `src/index.css`: add `@source not "../skillgraph";` directly after `@import "tailwindcss";`.

   Neither line changes Research Nexus behaviour. The second line also **removes** the two stray classes the Phase 0 docs introduced.
4. The pre-existing `esbuild`/`vite` peer conflict belongs to Research Nexus and is **not** changed by SKILLGRAPH work. The regression guard installs with `--legacy-peer-deps` to reproduce the current state. Fixing it is the owner's call (decision A-2).

## Consequences
- One repository and one history, with the two products clearly separated.
- **Security boundary caveat:** GitHub permissions, branch protection and repository-level Actions secrets apply to the whole repository. Anyone with write access to Research Nexus also has write access to SKILLGRAPH. Mitigations: GitHub *Environments* with required reviewers for SKILLGRAPH deploy secrets, CODEOWNERS for `skillgraph/`, and OIDC federation from GitHub Actions to AWS (no long-lived cloud keys).
- If a full security boundary is required later (separate access control or a separate audit trail), `skillgraph/` can be extracted into its own repository with history (`git filter-repo --subdirectory-filter skillgraph`) without code changes.
- **Open risk (A-3):** if Google AI Studio is still used to edit Research Nexus and pushes to this repository, it could overwrite or delete `skillgraph/`. This must be confirmed before Phase 1 code is committed.

## Alternatives considered
- **Separate repository now:** the cleanest security boundary, and the owner's instruction allows it. Not chosen because the owner preferred a single repository "if technically appropriate", and it is (given Decision 3). It remains the fallback if A-3 shows AI Studio would overwrite the repository.
- **Convert the root into a monorepo (move Research Nexus into `apps/research-nexus`):** rejected. It would modify and risk breaking the existing app and its AI Studio deployment.
