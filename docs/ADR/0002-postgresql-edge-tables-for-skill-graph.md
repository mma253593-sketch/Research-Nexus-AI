# ADR-0002: PostgreSQL edge tables for the skill graph (no graph database)

Status: Proposed
Date: 2026-11-23

## Context
FR-03 and FR-07 need typed relationships between skills and bounded traversals (depth ≤ 3). The PRD (§7) says not to introduce a graph database until measured query requirements justify it. The pilot targets are 10,000 skills and 100,000 relationships (PRD §27).

## Decision
- Store relationships in `skill_relationships` (DATA_MODEL §3), indexed on (`source_skill_id`, `relationship_type`) and (`target_skill_id`, `relationship_type`).
- Traverse with recursive CTEs that have a depth cap (max 3), a node cap (default 200), path-array cycle detection, and an `approved`-only filter by default.
- Check acyclicity of hierarchical types in the Ontology service before approving an edge.
- **Phase 0 spike S-3:** generate 10k skills and 100k edges in a local PostgreSQL 16 and measure p95 latency of depth-2 and depth-3 traversals. Record the numbers in this ADR. If depth-3 misses the 1,000 ms target, first try bounded breadth plus caching before considering a graph database.

## Consequences
- One database and one consistency model. Relationships participate in the same transactions, RLS and backups as everything else.
- Deep or unbounded analytics (e.g. "all transitive prerequisites across the whole ontology") are deliberately not supported online. They would be offline jobs.

## Alternatives considered
- **Neo4j or another graph DB:** a second datastore with its own backup, security and consistency story, unjustified by any measurement.
- **Apache AGE extension:** usually not available on managed PostgreSQL offerings; adds operational risk.
- **ltree materialised paths:** fits single-parent trees only. Skills have multiple parents and non-hierarchical edges.
