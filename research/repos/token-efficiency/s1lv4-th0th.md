# S1LV4/th0th

- URL: https://github.com/S1LV4/th0th
- Category: token-efficiency
- Stars snapshot: 133 (GitHub repo page, captured 2026-05-12; local index also recorded 133 on 2026-05-11)
- Reviewed commit: 1df41189ca14bad80da9e61f921fee7858e96eff
- Reviewed at: 2026-05-12T12:16:00+09:00
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong in-scope reference for coding-assistant semantic retrieval and context budgeting. th0th combines local indexing, hybrid vector and keyword search, a symbol graph, project memories, MCP/Claude/OpenCode integrations, and an optimized-context endpoint. The architecture is directly relevant, but several token-compression claims are stronger than the implementation: compression is mostly structural summarization and exact line dedupe, token estimates are heuristic, some advanced strategies are pass-through, and search filters are applied after retrieval.

## Why It Matters

th0th is a concrete, code-heavy attempt to reduce coding-agent context costs without removing the agent workflow. It is not just a prompt-compression script. It supplies a local API, MCP tools, editor/assistant plugins, file upload/indexing, semantic and lexical retrieval, memory storage, symbol navigation, session cache reuse, and benchmark scaffolding.

For this repository's agentic-coding research, it is useful as a system design case study: it shows how much token reduction can come from retrieval scope control, previews, session-aware file caching, and code-structure extraction before any LLM summarizer is involved.

## What It Is

th0th is a Bun/TypeScript monorepo for AI-assistant codebase navigation:

- `apps/tools-api` exposes an Elysia HTTP API for indexing, search, optimized context, memory, workspace status, analytics, and events.
- `apps/mcp-client` exposes MCP tools such as `th0th_index`, `th0th_search`, `th0th_compress`, `th0th_optimized_context`, `th0th_remember`, and symbol-graph tools.
- `packages/core` contains the indexing pipeline, hybrid search, compression, memories, vector stores, symbol graph, hooks, jobs, and tools.
- `packages/shared` contains config, token estimation, sanitization, metrics, logging, and shared types.
- `apps/claude-plugin`, `apps/opencode-plugin`, and `skills/th0th-memory` adapt the same retrieval model to coding-assistant workflows.

The default posture is local-first: Ollama embeddings, SQLite vector/FTS/symbol/memory stores, and project-local upload staging. OpenAI, Mistral, and Postgres/pgvector are supported alternatives.

## Research Themes

- Token efficiency: High relevance. The main savings mechanisms are search result previews, optimized context budgets, session file cache references, code-structure compression, and selective `Read(file,lineStart,lineEnd)` follow-up.
- Context control: High relevance. The API exposes `maxTokens`, `maxResults`, memory budget ratio, graph prefiltering, search filters, line ranges, and response modes, although final token caps are not strictly enforced after compression.
- Sub-agent / multi-agent: Medium relevance. Claude command docs define a `th0th-navigator` subagent pattern for code exploration so the parent conversation keeps less raw context.
- Domain-specific workflow: High relevance for coding assistants. The stack is specialized for source files, definitions, references, imports, PageRank-like file centrality, code query boosts, and line-targeted reads.
- Error prevention: Medium relevance. It encourages exact file/line retrieval before edits and provides symbol tools, but relation extraction is mostly heuristic and does not prove semantic correctness of edits.
- Self-learning / memory: High relevance. It stores memories with embeddings, FTS, level/type metadata, temporal/access scoring, redundancy filtering, and hooks that can capture search-session summaries.
- Popular skills: Relevant as an example skill/plugin package. It ships a `th0th-memory` skill plus Claude and OpenCode integrations rather than a broad skill marketplace.

## Core Execution Path

1. A client calls `th0th_index`. The MCP client collects files locally, applies extension and size limits, excludes common generated/vendor/secret paths, and uploads accepted files to the API.
2. The API writes files under `~/.rlm/uploads/<projectId>` after project ID sanitization and path traversal checks, then starts an async indexing job.
3. `IndexProjectTool` runs an ETL pipeline: discover files, parse chunks/symbols/imports, resolve imports and FQNs, then load vector documents and symbol data.
4. Discovery merges default ignores and `.gitignore`, hashes content with SHA-256, skips unchanged fingerprints from `symbol_files`, and prioritizes central files, recent files, then path order.
5. Parsing uses `smartChunk`, provider-specific embedding char limits, regex-based code symbol extraction for TypeScript/JavaScript/Python/Dart, and import extraction.
6. Loading writes chunks to the vector store and definitions/import graph data to SQLite symbol tables, then recomputes workspace status and PageRank centrality after completion.
7. Search runs vector search and FTS5 keyword search in parallel, fuses them with reciprocal-rank fusion, applies code-query keyword boosts, blends fused rank and raw vector score, boosts central files, adds previews, caches results, and tracks analytics.
8. Optimized context optionally uses graph prefiltering, retrieves semantic code results and memories in parallel, allocates token budgets, applies session file cache references or diffs, and calls structural compression if the rough budget is exceeded.

## Architecture

The retrieval architecture has four main indexes.

The vector index is either SQLite or Postgres/pgvector. SQLite stores Float32 embedding blobs and scans with cosine similarity. It warns above 10k documents and can use recency prefiltering above 5k documents, which improves latency at a possible recall cost. Postgres dynamically chooses tables by embedding dimension. For dimensions up to 2000 it uses HNSW over vector cosine distance. For higher dimensions it builds a binary quantized HNSW index and exact-reranks candidates.

The keyword index uses SQLite FTS5 with Porter stemming and `unicode61`. Query strings are sanitized before FTS search. Scores are normalized around BM25 and then fused with vector results.

The symbol graph is stored in SQLite. It tracks files, definitions, imports, references, import edges, workspace status, and PageRank-style centrality. The ETL pipeline currently derives references mostly from imports. Tool docs mention richer reference types such as calls, type refs, extends, and implements, but the reviewed path did not show robust AST-level extraction for those relations.

The memory index stores raw memory content, metadata, embeddings, and FTS data. Search combines semantic similarity, temporal decay, access frequency, and memory-type priors. A search-session hook can automatically store lightweight memories about queries and top files. A co-retrieval hook can be enabled, but the SQLite repository path skips it because the needed method is not present there.

Compression is a separate service layer. `code_structure` extracts imports, interfaces, classes, function signatures, and exports with line regexes, dropping most implementations. `semantic_dedup` is exact normalized-line dedupe, not embedding-level semantic dedupe. `conversation_summary` and `hierarchical` are accepted tool strategies but pass through unchanged in the core compressor switch.

## Design Choices

- Local-first defaults reduce privacy exposure and make the system deployable for private codebases without sending source to an external embedding provider.
- Search defaults to `responseMode: summary`, returning previews and line ranges rather than full chunks. Full content is available only when requested.
- The optimized context endpoint uses a coarse token allocator: memory budget defaults to 20 percent of `maxTokens`, code gets the remainder, and working memory defaults to 80 percent of the code budget.
- Session file caching is simple and practical. Unchanged chunks become short `[CACHED: file:lines]` references, changed chunks become positional diffs, and cached sessions are in-memory with a four-hour TTL.
- Chunking is deliberately code-aware but not parser-grade. TypeScript/JavaScript/Dart use brace-counting; Python falls back to fixed chunks; Markdown/JSON/YAML have structure-aware paths.
- The chunker prefixes chunks with file labels and repeats labels on larger chunks to bias embeddings toward path-aware retrieval.
- Hybrid search uses RRF with `RRF_K=60`, keyword boost for code-like queries, a 70/30 normalized rank and raw vector blend, and centrality boosts. This is easy to reason about and tune.
- Include/exclude filters exist at the API boundary, but in the reviewed search controller they are applied after retrieval. That can miss relevant files outside the initial candidate set.
- The project upload path has explicit path traversal defenses and size/file limits, while the API itself is open by default unless `TH0TH_API_KEY` is set.

## Strengths

- End-to-end assistant integration is stronger than most standalone retrieval demos: MCP tools, REST API, Claude commands, OpenCode plugin, memory skill, and status/event routes all point at one retrieval backend.
- Indexing has practical incremental behavior through file hashes, default ignores, project namespaces, async jobs, status reporting, and per-project concurrency serialization.
- The token-efficiency mechanisms are compositional. Summary search, targeted read ranges, graph prefiltering, optimized context budgets, session cache references, and structural compression can stack.
- The local privacy story is credible for default use: Ollama plus SQLite keeps code and memories on the machine, and `.env` plus generated/vendor paths are ignored by default.
- Postgres vector support is unusually thoughtful for embedding dimension changes, high-dimensional embeddings, and orphaned chunks.
- The benchmark scaffolding includes needle-in-haystack fixtures and BEIR evaluation scripts, giving future maintainers a place to measure recall instead of relying only on claims.
- The memory subsystem is more than a key-value store. It has semantic search, FTS, decay, access weighting, type priors, redundancy filtering, and consolidation jobs.

## Weaknesses

- README and implementation drift in embedding defaults. Shared config mentions `nomic-embed-text:latest` with 768 dimensions, core embedding config defaults to `bge-m3` with 1024 dimensions, and README tables mention other defaults. This matters because vector schema and orphan handling depend on dimensions.
- Compression target ratios are not honored directly. `CompressContextTool` accepts `targetRatio`, but the compressor does not use it to drive output size.
- Advanced compression strategy names overpromise. `conversation_summary` and `hierarchical` are accepted but do not perform summarization in the reviewed compressor.
- Token counting is a rough character heuristic, not model-specific tokenization. It is good for budget approximation but not for hard context-window guarantees.
- Optimized context can still exceed `maxTokens` after compression because there is no final hard clamp.
- Search filters are post-search in the main controller path. Include-only searches can lose relevant results if they were not in the first hybrid candidate set.
- Symbol references are mostly import-derived, while API/tool names imply richer semantic reference tracking.
- Some symbol snippet readers resolve relative paths from process cwd rather than the indexed project root, so snippets can fail or drift when the API is launched elsewhere.
- The OpenCode plugin's optimized-context tool does not pass a `sessionId`, so the session file cache is not activated even though the shipped skill recommends always passing one.
- If `TH0TH_API_KEY` is not set, most API routes are intentionally open. That is acceptable for localhost development but risky if the service is exposed.

## Ideas To Steal

- Make summary search the default and require explicit full-content escalation.
- Pair semantic retrieval with exact line-range read tools so coding agents can verify before editing.
- Add a session file cache for optimized context, with stable references for unchanged chunks and compact diffs for changed chunks.
- Use graph prefiltering before semantic search when the query looks like a symbol name.
- Track token savings as first-class metrics and break them down by session cache, compression, and memory/context selection.
- Keep a local-first default path with optional cloud embeddings rather than making external providers mandatory.
- Store file fingerprints and centrality so indexing can skip unchanged files and prioritize important files.
- Provide dogfooding needle fixtures that encode known retrieval invariants from the project itself.

## Do Not Copy

- Do not expose advanced compression strategy names unless they are implemented and verified.
- Do not apply include/exclude filters only after retrieval for assistant-critical searches.
- Do not rely on character heuristics when the product needs hard model-window enforcement.
- Do not let plugin integrations silently skip session IDs when session caching is part of the token-efficiency story.
- Do not claim call/reference graph precision from regex import extraction.
- Do not run an unauthenticated API with open CORS outside a clearly local-only deployment.
- Do not let README defaults diverge from code defaults for embedding model and dimensions.

## Fit For Agentic Coding Lab

Fit is high. th0th is directly about reducing the amount of code context a coding assistant has to carry while preserving navigability and verification. Its best patterns for this lab are the combination of summary-first retrieval, line-targeted exact reads, token-budgeted context assembly, session cache references, and memory-aware recall.

The most reusable design is not the specific compression implementation. It is the control loop: retrieve narrow candidates, expose paths and line ranges, let the agent request exact slices, cache repeated context, and record savings. That can be adapted to existing coding agents without adopting the full API or storage stack.

For production use in this project, I would copy the workflow model and measurement hooks first, then redesign the compression and filtering pieces with stronger guarantees.

## Reviewed Paths

- `README.md`, `package.json`, workspace config, setup scripts, Docker files, and release/config references for install model, defaults, and public claims.
- `apps/mcp-client/src/tool-definitions.ts`, `index.ts`, `api-client.ts`, `file-collector.ts`, and config helpers for MCP tool surfaces, local collection limits, upload/index behavior, retries, and API-key handling.
- `apps/tools-api/src/index.ts`, middleware, and routes for project upload, search, optimized context, memory, file, workspace, analytics, events, and health behavior.
- `packages/shared/src/config/*`, `env.ts`, and utilities for default config, environment loading, token estimation, sanitization, rate limiting, logging, and metrics.
- `packages/core/src/tools/*` for indexing, search, optimized context, compression, file reads, memory tools, symbol tools, and project status.
- `packages/core/src/controllers/search-controller.ts`, `context-controller.ts`, and `memory-controller.ts` for request-level behavior and budget composition.
- `packages/core/src/services/etl/**` for discover, parse, resolve, load, progress, jobs, and incremental indexing behavior.
- `packages/core/src/services/search/**` for contextual search, smart chunking, ignore patterns, scoring, cache, analytics, and indexing helpers.
- `packages/core/src/services/compression/code-compressor.ts`, `context/session-file-cache.ts`, `metrics/token-metrics.ts`, and embedding services for token reduction and context reuse.
- `packages/core/src/data/vector/**`, `data/sqlite/keyword-search*`, `data/sqlite/symbol-*`, memory repositories, graph repositories, Prisma schema, and selected migrations for persistence semantics.
- `packages/core/src/services/memory/**`, hooks, graph services, jobs, workspace manager, events, health, and symbol graph services for memory and assistant workflow integration.
- Tests covering context controller budget logic, scoring pipeline, search controller filters/previews, session file cache, SQLite and Postgres vector stores, concurrent indexing, memory consolidation, graph queries, graph store, relation extraction, auth, hooks, and related core services.
- `benchmarks/needles/**`, `packages/core/src/scripts/beir-benchmark.ts`, `create-sicad-beir-fixture.ts`, and symbol benchmark scripts for evaluation scaffolding.
- `skills/th0th-memory/SKILL.md`, `apps/claude-plugin/**`, and `apps/opencode-plugin/src/index.ts` for assistant-specific usage patterns and integration gaps.

## Excluded Paths

- `.git/`: used only to record the exact reviewed commit and recent history; VCS internals are not part of the architecture.
- `bun.lock`: generated dependency lockfile. It was not needed to understand retrieval, compression, indexing, or assistant integration behavior.
- Generated or vendored output such as `node_modules`, `dist`, coverage output, and package-generated clients: excluded because source files and schemas show the behavior.
- Full migration-by-migration review under Prisma and package migration folders: skimmed for storage concepts, but detailed migration chronology was not relevant beyond schema/vector/symbol/memory implications.
- Docker and WSL setup scripts beyond configuration/security claims: operational packaging, not core retrieval or compression logic.
- Checkpoint/task snapshot services: adjacent workflow persistence, but not part of semantic search, context compression, token budgeting, or memory retrieval.
- Benchmark reports under generated report paths: excluded because they are generated outputs and no committed result set was needed for architectural review.
- Local binary/media/UI-only assets: no meaningful tracked UI-only or binary asset path affected the reviewed retrieval architecture.
