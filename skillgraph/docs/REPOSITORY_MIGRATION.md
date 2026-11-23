# SKILLGRAPH: Independent Repository Migration Plan

**Status:** Proposed, awaiting owner approval. **Nothing in this plan has been executed against GitHub.** The only thing done so far is a local dry run in a throwaway clone (§4).
**Date:** 2026-11-23
**Decision:** Owner Decision 1 (2026-11-23): SKILLGRAPH gets its own GitHub repository named `SKILLGRAPH`. Research Nexus AI is preserved completely. See [ADR-0011](ADR/0011-independent-repository.md).

---

## 1. Current state (verified 2026-11-23)

| Item | State |
|---|---|
| Research Nexus AI `main` | `c268948` "feat: add multi-language support". **No SKILLGRAPH commit has ever been merged into it.** Its history and files are untouched. |
| SKILLGRAPH work | Exists only on branch `claude/skillgraph-infrastructure-ubvh4x` of `mma253593-sketch/Research-Nexus-AI`, as commits on top of `c268948`: `df969bf` (Phase 0 docs, in `docs/`), `acf4519` (moved into `skillgraph/`), plus the commit containing this plan. |
| Research Nexus files changed on that branch | **None.** Only `docs/` (first commit, later moved) and `skillgraph/` were ever touched. |
| `SKILLGRAPH` repository | **Does not exist or isn't visible to this session.** A repository search for "skillgraph" returned nothing. |
| Side effect to note | While the branch had root-level `docs/`, Research Nexus's Tailwind build picked up two unused CSS classes (FEASIBILITY_REPORT §6.2). This affected **only that branch**, never `main`, and it disappears from Research Nexus entirely once the branch is retired (§5, step 7). |

## 2. What the owner needs to create or authorize (before any migration step)

1. **Create an empty GitHub repository** named `SKILLGRAPH` under the account `mma253593-sketch` (or an organisation you prefer):
   - **Leave it completely empty.** Don't add a README, `.gitignore` or licence on GitHub, otherwise the imported history and GitHub's initial commit become unrelated histories.
   - **Visibility:** private is recommended (decision U-4).
2. **Give the Claude GitHub App access to the new repository.** Go to https://github.com/apps/claude/installations/select_target → your account → *Configure* → *Repository access*, and add `SKILLGRAPH`. Write access is needed for the import push. This is the step that failed earlier with 403 for Research-Nexus-AI until the app had access.
3. **Tell me the repository is ready.** I'll then attach it to this session (read and push access) and verify that it's empty before pushing anything.
4. **Approve the default branch import (U-2).** The first push must create `main`, because an empty repository has no branch to open a pull request against. After that, all work goes through branches and pull requests.
5. **Later, separately: decide what happens to the old branch in Research-Nexus-AI (U-3).** This is the only destructive step, and it's done only after the new repository has been verified.

**Future sessions:** a Claude Code session's repositories are chosen when it starts. After migration, start Phase 1 sessions with the `SKILLGRAPH` repository selected.

## 3. Target layout

The extraction rewrites paths so that `skillgraph/…` becomes the repository root:

| On the Research-Nexus-AI branch | In the `SKILLGRAPH` repository |
|---|---|
| `docs/…` (commit `df969bf` only) | `docs/…` |
| `skillgraph/docs/…` | `docs/…` |
| `skillgraph/scripts/…` | `scripts/…` |
| `skillgraph/README.md`, `skillgraph/.gitignore` | `README.md`, `.gitignore` |
| Every Research Nexus file (`src/`, `public/`, `package.json`, …) | **not present** |

The final structure is in [ARCHITECTURE.md §16](ARCHITECTURE.md#16-repository-structure-independent-skillgraph-repository-adr-0011).

## 4. Dry run already performed (non-destructive, local only)

In a throwaway clone in the session scratch area, never pushed:

```bash
git clone --no-local --single-branch --branch claude/skillgraph-infrastructure-ubvh4x <Research-Nexus-AI> sg-dryrun
cd sg-dryrun && git remote remove origin
git filter-repo --force --path docs/ --path skillgraph/ --path-rename skillgraph/:
```

Results (`git-filter-repo` 2.47.0):

| Check | Result |
|---|---|
| Commits kept | 2 (both SKILLGRAPH commits). All 4 Research Nexus commits were dropped, because they touch none of the selected paths. |
| Files in the result | Only `docs/` (8 files) and `docs/ADR/` (11 files) |
| Research Nexus paths anywhere in the extracted history | None |
| Content equality | Extracted root tree `78a3c86f…` **=** source `HEAD:skillgraph` tree `78a3c86f…`. First commit's `docs/` tree `8f33c123…` **=** source `df969bf:docs` `8f33c123…` |
| Authors and messages | Preserved. Commit IDs change; expected and unavoidable when extracting history. |

## 5. Migration procedure (runs only after §2 is complete and the owner approves)

Each step has a check. If any check fails, **stop**, report, and change nothing on GitHub.

| # | Step | Command / action | Check | Destructive? |
|---|---|---|---|---|
| 1 | Freeze the source | Record the final SHA of `claude/skillgraph-infrastructure-ubvh4x`. No further commits to it. | `git ls-remote` shows the recorded SHA | No |
| 2 | Verify the target is empty | `git ls-remote https://github.com/<owner>/SKILLGRAPH` | No refs returned | No |
| 3 | Fresh extraction | Fresh `--no-local` clone of the frozen branch, then the `filter-repo` command from §4 | Same checks as §4: tree hash equals `HEAD:skillgraph`; no Research Nexus paths; expected commit count | No (local) |
| 4 | Pre-push safety scan | Secret scan of the full extracted history (gitleaks, or a pattern scan if gitleaks can't be installed); `git fsck --full` | Zero findings; fsck clean | No |
| 5 | Import | `git branch -M main`, `git remote add origin <SKILLGRAPH url>`, `git push -u origin main` (**plain push, never `--force`**) | Push accepted; `git ls-remote` shows `main` at the extracted HEAD | Writes only to the new, empty repository |
| 6 | Verify on GitHub | Fresh clone of `SKILLGRAPH`, then compare its tree hash with step 3. Commit the `filter-repo` old→new commit map as `docs/migration/commit-map.txt`, on a branch with a pull request. | Hashes equal; files readable on GitHub | No |
| 7 | Retire the SKILLGRAPH branch in Research-Nexus-AI (**only with separate explicit approval, U-3**) | Option A (recommended): delete the remote branch `claude/skillgraph-infrastructure-ubvh4x`. Option B: keep it untouched as an archive. | Research-Nexus-AI `main` still at `c268948`; `git log origin/main` unchanged | Option A deletes a branch only. It doesn't rewrite `main` or any history of Research Nexus AI. |

**What is never done:** force-push to any branch; any change to Research-Nexus-AI `main`, its files or its configuration; `git filter-repo` run inside the real Research-Nexus-AI checkout (it runs only in a throwaway clone); deleting the source branch before step 6 passes.

## 6. Rollback

- **Before step 5:** nothing has changed anywhere; discard the throwaway clone.
- **After step 5, before step 7:** the source branch is intact. If the new repository is wrong, the owner can delete and recreate `SKILLGRAPH`, and the procedure is repeated.
- **After step 7 (option A):** the commits remain recoverable from the new repository, which has the full SKILLGRAPH history. A copy of the original branch can also be kept as a `git bundle` attached to the migration record before deletion, if the owner wants a byte-exact copy of the original commit IDs.

## 7. Where this plan is stored until then

The `SKILLGRAPH` repository doesn't exist yet. This session can only commit to the branch above, so this plan and the updated architecture docs are committed there, inside `skillgraph/`, as a temporary holding place. They move to the new repository with the rest of the history in step 5. Nothing is committed to Research Nexus `main`.
