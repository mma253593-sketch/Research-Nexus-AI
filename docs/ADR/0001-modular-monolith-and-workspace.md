# ADR-0001: Modular monolith in a pnpm workspace

Status: Proposed
Date: 2026-11-23

## Context
The PRD (§6, §7) asks for an API-first modular monolith in NestJS/TypeScript with a Next.js frontend and a background worker, and explicitly rules out starting with microservices. The pilot team is small, and the module boundaries (identity, skills, evidence, credentials, consent) aren't yet validated by real usage.

## Decision
- One pnpm workspace containing `apps/api` (NestJS), `apps/web` (Next.js), `packages/contracts` (Zod schemas, DTO types, permission matrix, error codes) and `packages/config`.
- The worker is a second entrypoint (`worker.ts`) in `apps/api`, sharing modules and the deployment image and started with a different command. It becomes `apps/worker` only if its dependencies or scaling profile diverge.
- Module boundaries inside `apps/api` are enforced by a dependency lint rule in CI: modules import only each other's public services and DTOs, and never each other's repositories or tables.
- Node.js 22 LTS (installed: v22.23.5) and pnpm 10 (installed: 10.28.0) are pinned via `engines` and `packageManager`.

## Consequences
- One deployable, one migration stream, simple local setup.
- The boundary lint is what keeps "modular" true. If it's disabled, the design decays into an ordinary monolith.
- `packages/contracts` is shared by API and web, so validation rules are written once.

## Alternatives considered
- **Microservices:** rejected by the PRD and unjustified at pilot scale.
- **Separate `apps/worker` from day one:** adds a package and build without a current need.
- **Separate `shared-types` and `validation` packages (PRD §9):** merged, because a Zod schema already defines its type.
