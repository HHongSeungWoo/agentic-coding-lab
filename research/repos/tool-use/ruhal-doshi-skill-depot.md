# Ruhal-Doshi/skill-depot

- URL: https://github.com/Ruhal-Doshi/skill-depot
- Category: tool-use
- Stars snapshot: 3 (GitHub REST API, captured 2026-05-31; index row also recorded 3 captured 2026-05-29)
- Reviewed commit: f33790d02fc7a0c457ecbd591a7911d793fd9b1b
- Reviewed at: 2026-05-31
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strongly aligned with runtime-skill-routing as a compact local prototype: it replaces always-loading skill descriptions with MCP-mediated search, preview, and full-read tools over local Markdown skills. It is not yet production-grade for 10,000-skill routing because ranking is shallow, indexing is file-level, budget enforcement is advisory, and permissions/trust/evaluation are minimal.

## Why It Matters

`skill-depot` directly targets the failure mode behind huge skill libraries: agents that start every session with all skill frontmatter in context. Its useful move is to move the skill corpus behind an MCP server and expose only a small search result first, then an overview, then full Markdown only when the agent asks for it. That is closer to a runtime skill router than the marketplace/install repos because selection happens during the agent session.

For Agentic Coding Lab, this is a practical small-system reference for "10,000 skills" work: keep a local index, provide a narrow search tool, return compact snippets, and force full content through an explicit second call. The repo also shows how this can coexist with existing agent skill directories by importing skills and optionally removing symlinks from agent-visible paths to reduce startup context.

## What It Is

This is a TypeScript CLI and MCP server for storing agent skills as Markdown files with YAML frontmatter, indexing them in SQLite plus `sqlite-vec`, and retrieving them through semantic search. It uses `@xenova/transformers` with `Xenova/all-MiniLM-L6-v2` for 384-dimensional local embeddings and falls back to a hashed BM25-style vector when transformer embedding fails.

The storage model has a global home directory, `~/.skill-depot`, plus optional project directories at `<project>/.skill-depot`. In the current implementation, both global and project records live in the global SQLite database, with project filtering done through a `project_path` column. The CLI can initialize directories, discover skills from common agent locations, add/list/search/remove/reindex skills, run an MCP stdio server, and integrate with the `skills` package by indexing `~/.agents/skills/<name>/SKILL.md`.

## Research Themes

- Token efficiency: Strong theme. Search returns name, description, tags, scope, a short snippet, `hasOverview`, and score instead of loading every skill body. `skill_preview` returns heading-level summaries before `skill_read` loads the full raw Markdown.
- Context control: Strong theme. The design makes skill content opt-in at runtime and includes cleanup prompts for agent-directory symlinks that would otherwise keep skills in the agent's automatic context. It does not enforce a hard token budget or prevent an agent from reading too many skills.
- Sub-agent / multi-agent: Weak theme. The server is agent-agnostic and can be used by Claude Code, Codex, Cursor, Gemini, OpenClaw, or any MCP-compatible host, but it does not orchestrate multiple agents or isolate per-agent skill views beyond scope/cwd filtering.
- Domain-specific workflow: Moderate theme. Skills are plain Markdown, with `tags`, `keywords`, `related`, and headings used for search/preview, so domain workflows can be encoded as skill files. There is no domain ontology, task taxonomy, negative trigger schema, or workflow validator.
- Error prevention: Moderate theme. The system avoids one class of context error by not loading irrelevant skills, tracks stale file references in `doctor`, and hashes content for reindex skipping. It lacks permission policy, provenance checks, untrusted-skill sandboxing, and activation-quality tests.
- Self-learning / memory: Moderate theme. `skill_learn` lets the agent create or append lessons to Markdown skills, merge tags/keywords/related fields, regenerate embeddings, and persist the result. It has no review gate, dedupe beyond exact name/hash behavior, or forgetting/pruning policy.
- Popular skills: Activity scoring is implemented through `read_count` and `last_read_at`, with retrieval score blended as 90% vector similarity and 10% read-frequency boost. This is a simple popularity signal, not a robust personalized or project-conditioned skill ranking model.

## Core Execution Path

The main runtime path starts with `skill-depot serve`, which creates an MCP server over stdio. On startup it ensures global directories exist and opens `~/.skill-depot/index.db`. Agents call `skill_search` with `query`, `cwd`, optional `context`, `topK`, and `scope`. The search code concatenates context and query, embeds that text, runs a KNN query through `sqlite-vec`, filters records by global/project scope and current working directory, overfetches at `max(topK * 10, 100)`, and returns only the top `topK` compact results.

If a result looks relevant, the agent can call `skill_preview(name, cwd)` to get a generated overview: each Markdown heading plus the first sentence beneath it, skipping fenced code blocks. If the agent needs executable detail, it calls `skill_read(name, cwd)`, which resolves project-scoped skills before global ones, reads the original file, increments the read count, and returns full raw Markdown with metadata and related skill names.

The indexing path is `init`, `add`, `reindex`, MCP `skill_save`, MCP `skill_update`, MCP `skill_learn`, or `skill-depot skills import/add`. Each path parses frontmatter with `gray-matter`, derives an indexable text from name, description, tags, keywords, and headings, generates a snippet and overview, computes a SHA-256 content hash, generates an embedding, and upserts a `skills` row plus a vector row.

## Architecture

The architecture is intentionally compact:

- `src/mcp/server.ts` registers MCP tools for `skill_search`, `skill_preview`, `skill_read`, `skill_learn`, `skill_save`, `skill_update`, `skill_delete`, `skill_reindex`, and `skill_list`.
- `src/core/database.ts` owns SQLite schema, `sqlite-vec` setup, upsert/update/delete, scope filtering, vector search, and read-count tracking.
- `src/core/search.ts` wraps embedding generation, vector search, score blending, and result shaping.
- `src/core/frontmatter.ts` parses/serializes skill Markdown and creates indexable text, snippets, and previews.
- `src/core/embeddings.ts` lazy-loads the local transformer model and provides the BM25-style fallback vector.
- `src/discovery/detector.ts` scans known global/project agent directories for Markdown skills.
- `src/commands/skills.ts` indexes the `skills.sh` canonical store and can remove symlinks from agent directories.

The database has one `skills` table and one `skill_vectors` virtual table. Skill records store name, description, tags, keywords, content hash, file path, scope, project path, snippet, overview, indexable text, related names, read count, and timestamps. The vector table stores one 384-dimensional embedding per skill record.

## Design Choices

The strongest design choice is the three-level disclosure contract:

- L0: `skill_search` returns compact metadata and snippet.
- L1: `skill_preview` returns generated outline plus first sentences.
- L2: `skill_read` returns full Markdown.

That contract is the repo's main answer to runtime context budget pressure. It gives the agent a way to inspect relevance before paying for full content, while keeping skill files human-editable.

The repo also chooses local-first dependencies: SQLite, `sqlite-vec`, and a local transformer model cached under `~/.skill-depot/models`. This avoids cloud embedding APIs and makes the router deployable as a local MCP tool. The fallback embedding keeps the system usable when the transformer path fails, although quality will drop.

For project behavior, the implementation stores project skills in the same global DB and filters by exact `cwd`/`project_path`. This is simpler than one DB per project and makes global+project search easy, but it relies on stable absolute paths and can miss parent/child project relationships.

The indexable text is intentionally short: frontmatter and headings only, not the entire body. That reduces indexing noise and keeps embeddings focused on routing signals, but it can miss useful details buried in skill bodies. The `related` field is stored and returned by full reads, but it is not used for graph expansion, reranking, or auto-loading.

## Strengths

- Direct runtime answer to context bloat: skills move behind MCP tools instead of being always present in the model prompt.
- Progressive content loading is explicit and simple enough for agent instructions to follow.
- Local-first indexing avoids API keys, cloud dependency, and privacy leakage from skill text.
- Markdown frontmatter keeps skills compatible with Claude/Codex-style skill files and easy to edit.
- Global/project scope support gives a useful first pass at context narrowing.
- Activity scoring provides a simple feedback loop from actual usage into retrieval ranking.
- `skill_learn` turns successful work into persisted, searchable skill memory.
- Discovery and `skills.sh` import create a migration path from flat agent-visible skill folders to indexed retrieval.
- Tests cover parsing, database operations, search behavior, lifecycle flows, discovery, and `skills.sh` import helpers without needing the transformer model.

## Weaknesses

- Ranking is a single-vector topK search plus a 10% read-count boost. There is no lexical+dense hybrid search, cross-encoder reranking, uncertainty handling, query rewriting, decomposition, or negative example filtering.
- The system does not enforce context budgets. `topK` defaults to 5, previews are generated, and full reads are explicit, but the agent can still repeatedly call `skill_read` and flood its context.
- File-level indexing is coarse. Long multi-topic skills become one embedding and one preview, which makes retrieval brittle and can hide the exact section needed for a task.
- Project scoping is exact-path based. A skill indexed for one absolute project path will not automatically match work in a subdirectory, symlinked checkout, renamed folder, or related workspace.
- `skill_read`, `skill_update`, and `skill_delete` resolve by name and current project first, then global; there is no namespace or stable ID exposed to the agent, so collisions and ambiguous names remain a risk.
- Trust and provenance are mostly absent. Imported Markdown can contain arbitrary instructions, but there is no signature, source URL, package pin, allowlist, maturity label, or policy scan.
- Permission boundaries are not encoded per skill. Skills can recommend tools or dangerous actions, but the router has no metadata for required tools, risk level, sandbox needs, or human-approval requirements.
- `related` skills are stored but not used for retrieval expansion, shortlist diversity, or dependency loading.
- Activity scoring can create popularity bias. A frequently read but only loosely relevant skill can get boosted, and there is no decay, per-project usage, or success/failure signal.
- The model cache path check is shallow, and fallback embedding can silently change retrieval quality while keeping the system running.

## Ideas To Steal

- Use an MCP router layer with `search`, `preview`, and `read` tools so the model sees only a small shortlist first.
- Store full skill bodies out of prompt and make `read_skill` an explicit action with telemetry.
- Generate and persist a compact overview at index time, not at prompt time.
- Build indexable text from routing-oriented metadata plus headings, then keep full content lazy.
- Add read-count telemetry as an initial ranking signal, but separate it from success telemetry in our design.
- Provide a cleanup/migration command that removes or disables old agent-visible skill symlinks after importing into the router.
- Keep a local-first mode with SQLite/vector index so private project skills do not need external embedding APIs.
- Let agents create/append learned skills, but put review, dedupe, and maturity gates around that ability.
- Expose both global and project scopes, but add workspace-root normalization and ancestor matching before copying this pattern.

## Do Not Copy

- Do not rely on vector similarity alone for large-scale skill routing. At 10,000+ skills, use deterministic filters, lexical search, dense retrieval, reranking, diversity, and confidence thresholds.
- Do not make context-budget behavior purely conventional. A production router should meter returned tokens, cap total loaded skill content, and summarize or reject excessive reads.
- Do not index only one vector per skill if skills can be long or multi-topic. Chunk or section-level retrieval is needed for precision.
- Do not leave skill identity as just `name`. Use stable IDs, namespaces, source package, version/ref, and scope in API responses.
- Do not let self-learning append indefinitely to a Markdown file. Require structured memories, compaction, dedupe, and review status.
- Do not treat read count as success. Add outcome feedback, recency decay, project-local telemetry, and negative activation logs.
- Do not import untrusted skill files without provenance, integrity metadata, and policy scanning.
- Do not assume exact `cwd` is enough for project scoping across monorepos, worktrees, symlinks, and nested packages.

## Fit For Agentic Coding Lab

This repo is a good prototype reference for the runtime-skill-routing layer we want, especially the MCP interface shape and progressive disclosure contract. It demonstrates a concrete replacement for loading all skill descriptions into initial context, and it gives enough code to see the whole lifecycle from skill file to search result to full read.

It should not be adopted as-is for high-scale routing. The Agentic Coding Lab version should treat `skill-depot` as the minimal baseline and add:

- a compact machine index with richer routing metadata;
- deterministic prefilters for project, language, file globs, host, tools, risk, and task type;
- hybrid retrieval and reranking;
- section-level retrieval;
- hard token budgets per search session;
- telemetry for activation, read, success, failure, and stale skills;
- provenance/trust fields and validation;
- stable skill IDs and namespacing;
- lifecycle gates for learned skills before they become globally routable.

## Reviewed Paths

- `README.md`: product framing, usage, storage architecture, MCP tool list, skill format, context-saving claims.
- `package.json`: package metadata, dependencies, scripts, runtime requirements.
- `src/cli.ts`: command surface for init, serve, daemon lifecycle, add/remove/list/search/reindex/doctor, and `skills` integration.
- `src/mcp/server.ts`: MCP tool schemas and handlers for search, preview, read, save, learn, update, delete, reindex, and list.
- `src/core/database.ts`: SQLite schema, `sqlite-vec` setup, upsert/update/delete behavior, scope filtering, read-count telemetry, vector search.
- `src/core/search.ts`: query/context embedding, vector result shaping, score blending.
- `src/core/embeddings.ts`: local transformer embedding, cache path, BM25-style fallback.
- `src/core/frontmatter.ts`: Markdown parsing, serialization, indexable text, snippets, generated overviews.
- `src/core/file-manager.ts`: Markdown file IO, recursive listing, hashing, skill-name fallback.
- `src/core/storage.ts`: global/project storage path conventions.
- `src/discovery/detector.ts`: scanning rules for skills.sh, Claude Code, Codex, OpenClaw, Gemini, and project directories.
- `src/discovery/symlink-cleaner.ts`: detection/removal of agent-directory symlinks that point to `~/.agents/skills`.
- `src/commands/init.ts`, `src/commands/add.ts`, `src/commands/search.ts`, `src/commands/list.ts`, `src/commands/reindex.ts`, `src/commands/doctor.ts`, `src/commands/skills.ts`: CLI indexing, discovery, health, search, and migration flows.
- `tests/core/*.test.ts`, `tests/integration/mcp-tools.test.ts`, `tests/commands/*.test.ts`, `tests/discovery/*.test.ts`: behavior coverage for parser, storage, search, database, MCP-like lifecycle, discovery, and skills.sh import helpers.

## Excluded Paths

- `pnpm-lock.yaml`: dependency lockfile reviewed only for package-manager context, not line-by-line.
- `LICENSE`: standard MIT license; no architectural content.
- `tsup.config.ts`, `vitest.config.ts`, `tsconfig.json`, `pnpm-workspace.yaml`: checked for build/test shape but not deeply reviewed because routing behavior lives in `src/` and tests.
- Generated output and installed dependencies: none present in the checkout, and no vendored source snapshots were reviewed.
- Upstream test execution: attempted `rtk pnpm test:run` and `rtk pnpm lint`, but this environment does not have `pnpm` installed, so upstream tests were not executed. Project-local research verification was run separately from this repo.
