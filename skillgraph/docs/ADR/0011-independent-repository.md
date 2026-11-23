# ADR-0011: SKILLGRAPH in its own GitHub repository

Status: **Accepted** (owner Decision 1, 2026-11-23). Executing the migration still needs the owner's repository setup and approval (REPOSITORY_MIGRATION.md §2).
Date: 2026-11-23
Supersedes: [ADR-0008](0008-repository-isolation-from-research-nexus.md) (SKILLGRAPH inside a `skillgraph/` folder of Research-Nexus-AI)

## Context
ADR-0008 kept SKILLGRAPH in a subfolder of the Research-Nexus-AI repository. It needed two edits to Research Nexus configuration and left repository-level permissions, secrets and CI shared between the two products. The owner decided that SKILLGRAPH must have its own repository named `SKILLGRAPH`, that Research Nexus AI must be preserved completely (no source, configuration or history changes), and that existing SKILLGRAPH work and history should be preserved where practical.

## Decision
1. SKILLGRAPH lives in its own repository, `SKILLGRAPH`, with the structure in ARCHITECTURE §16. The SKILLGRAPH workspace is the repository root.
2. Existing Phase 0 commits are carried over with `git filter-repo` path extraction in a throwaway clone (REPOSITORY_MIGRATION.md). A dry run proved content equality and the absence of any Research Nexus file.
3. **Research Nexus AI is not modified.** The two isolation edits proposed in ADR-0008 (A-1) are **withdrawn**: they're no longer needed.
4. The SKILLGRAPH branch in Research-Nexus-AI is retired only after the new repository is verified, and only with the owner's explicit approval.

## Consequences
- Real security boundary: separate repository permissions, branch protection, Actions secrets and environments, CODEOWNERS and audit log.
- No coexistence risk: no TypeScript or Tailwind interference, no shared CI, and no exposure to Google AI Studio syncing the Research Nexus repository (former question A-3).
- Commit IDs of the two Phase 0 commits change in the new repository. The old→new map is recorded in the new repository.
- Until the new repository exists, SKILLGRAPH documents remain on the Research-Nexus-AI side branch as a temporary holding place (never on `main`).

## Alternatives considered
- **Keep the subfolder (ADR-0008):** rejected by the owner.
- **Start the new repository without history (copy files only):** simpler, but loses the Phase 0 history, which the owner asked to preserve where practical. It stays as the fallback if `filter-repo` can't be used.
- **Fork Research-Nexus-AI and delete its files:** rejected. It would carry the whole Research Nexus history into SKILLGRAPH.
