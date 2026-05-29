# DeusData/codebase-memory-mcp

- URL: https://github.com/DeusData/codebase-memory-mcp
- Category: mcp
- Stars snapshot: 2,779 (GitHub REST API, captured 2026-05-29)
- Reviewed commit: 90e85bb10c405558623daffc3c309ac99f1ed282
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong reference for a local codebase-memory MCP: broad tree-sitter indexing, LSP-assisted graph construction, SQLite persistence, explicit project-scoped retrieval tools, and practical context controls. Treat it as an architecture and test-source candidate, not as code to copy wholesale, because it combines a very large vendored parser surface, shell-based helper paths, direct SQLite page writing, installer side effects, and some schema/implementation drift.

## Why It Matters

This repo is one of the most directly relevant candidates for agentic coding support. It is not a thin MCP wrapper over ripgrep. It builds a persistent local knowledge graph over a repository, stores it in SQLite, and exposes retrieval tools that let an agent ask structural questions about functions, classes, routes, call paths, architecture, ADRs, and cross-repository links.

The important lesson is the product shape: codebase memory works best when indexing, graph storage, retrieval, snippet extraction, and context limiting are separate contracts. The MCP tools mostly require an explicit `project`, query a prebuilt graph, and avoid returning entire files by default. That gives the assistant a stable memory surface without turning every prompt into a fresh repository scan.

It also matters as a risk reference. The repo shows how much engineering burden appears once codebase memory moves beyond grep: parser corpora, generated grammars, incremental hashes, direct database writers, shell escape boundaries, installer permissions, optional watcher behavior, artifact import/export, and schema compatibility all become part of the trusted path.

## What It Is

`codebase-memory-mcp` is a C MCP server for local codebase indexing and retrieval. The default binary starts a stdio JSON-RPC MCP server. It also has a `cli <tool> <json>` path for invoking the same tool handlers from tests or scripts, plus install, update, configuration, watcher, artifact, and optional localhost UI paths.

The server builds a graph from repository files using a discovery stage, tree-sitter parsing, language-specific extraction, LSP-style cross-file resolution, route/config/Kubernetes detectors, semantic/similarity passes, and SQLite persistence. The README describes support for 155 tree-sitter languages, local-only processing, persistent caches under `~/.cache/codebase-memory-mcp/`, and optional team artifacts under `.codebase-memory/`.

The MCP surface exposes indexing, project management, graph search, code search, graph traversal, change detection, Cypher-like graph querying, schema discovery, architecture summaries, ADR management, and trace ingestion. The package metadata in `server.json` publishes the MCP server under `io.github.DeusData/codebase-memory-mcp` with platform-specific stdio binaries.

## Research Themes

The repo is a high-signal example for a persistent codebase memory service.

- Tree-sitter/indexing: broad grammar registration in `internal/cbm/lang_specs.c`, thread-local parsers, parser progress timeouts, retained parse trees for follow-up passes, and aggressive file discovery exclusions.
- Knowledge graph: graph-buffer construction with node/edge deduplication, qualified-name lookup, route nodes, call/data-flow edges, cross-service edges, semantic vectors, similarity links, Kubernetes/import relationships, and optional cross-repo intelligence.
- Retrieval: project-scoped graph search, FTS-backed code and node search, Cypher subset queries, BFS call tracing, architecture summaries, snippets by qualified name, and semantic query rescoring.
- Persistence: per-project SQLite databases, file hashes for incremental indexing, FTS5, vectors/token vectors, project summaries, optional compressed team artifacts, and a custom direct SQLite writer.
- MCP schemas: tool definitions are fairly explicit about required project names, limit/offset controls, query modes, and truncation behavior.
- Root/path safety and permissions: realpath containment for snippet reads, file-list based grep, symlink skipping during discovery, shell-argument validation, SQLite authorizer checks, non-TTY-safe install prompts, and opt-in auto-indexing.
- Context control: the strongest pattern is to make retrieval narrow by construction: explicit project, structured filters, limits, paginated graph search, trace depth, and snippets instead of whole-file dumps.

The CLI install path also installs or updates agent instructions for multiple clients, including Codex, Claude, Gemini, OpenCode, VS Code, and related tools. That is useful as prior art for distribution, but it expands the permissions and side-effect surface beyond the core MCP memory service.

## Core Execution Path

Startup begins in `src/main.c`. Without special subcommands, the process initializes the store, loads configuration, optionally starts a localhost UI, optionally detects and registers a current working directory project, then enters the MCP stdio loop through `cbm_mcp_server_run_stdio`. There is also a CLI route that parses a JSON argument and calls the same tool dispatcher used by MCP clients.

Tool registration and dispatch live in `src/mcp/mcp.c`. The `tools/list` response declares schemas for `index_repository`, `index_status`, `list_projects`, `delete_project`, `search_graph`, `search_code`, `trace_path` and `trace_call_path`, `detect_changes`, `query_graph`, `get_graph_schema`, `get_architecture`, `manage_adr`, `ingest_traces`, and `get_code_snippet`. The dispatcher maps tool names to handlers and aliases `trace_path` and `trace_call_path`.

Indexing starts at `index_repository`, which resolves the requested repository path, chooses a mode, and invokes the pipeline. `src/discover/discover.c` walks files while skipping VCS metadata, dependency folders, generated/build/cache folders, binary suffixes, symlinks, `.gitignore` rules, nested `.gitignore` rules, and `.cbmignore`. Fast and moderate modes add broader exclusions for examples, docs, generated folders, assets, testdata, migrations, `third_party`, and similar high-noise paths.

The parser/extraction layer is centered in `internal/cbm/cbm.c`. Workers reuse thread-local `TSParser` instances, set parse timeout callbacks through tree-sitter parse options, and keep parse trees in file results for later LSP-style passes. Extraction collects definitions, imports, calls, usages, unified language facts, channel/events, Kubernetes resources, and language-specific LSP relationships.

The graph pipeline in `src/pipeline/pipeline.c` coordinates sequential and parallel passes. The pass list includes definitions, Kubernetes, cross-file LSP, calls, usages, semantic metadata, route extraction, decorator/config links, route matching, similarity, and semantic edges. For larger repositories, it uses parallel extract and parallel resolve stages, then merges results into a graph buffer before dumping to SQLite.

Retrieval reopens project databases through `resolve_store` in `src/mcp/mcp.c`. Query tools require a `project` argument and open `<cache>/<project>.db` in read/write query mode without creating missing DBs. Integrity checks verify the database shape and project record before query execution. Graph search, Cypher queries, traces, snippets, and architecture tools then use store APIs over the SQLite-backed graph.

## Architecture

The architecture has five clear layers.

1. MCP and CLI boundary: `src/mcp/mcp.c` and `src/main.c` parse JSON-RPC or CLI JSON, validate tool arguments, choose stores, and format JSON results. This layer owns the context-control contract exposed to agents.
2. Discovery and parsing: `src/discover/discover.c`, `internal/cbm/cbm.c`, and the language specification tables determine what files are eligible, which language grammar parses them, and which syntactic facts are extracted.
3. Graph construction: `src/pipeline/*` and `src/graph_buffer/*` build normalized nodes and edges, merge parallel worker output, deduplicate relationships, add route/config/semantic/similarity edges, and prepare records for persistence.
4. Storage and query: `src/store/store.c`, `src/cypher/cypher.c`, and `internal/cbm/sqlite_writer.c` define the durable graph model, FTS/vector support, Cypher-like query execution, traversal, and indexing metadata.
5. Operations and distribution: installer/update/config code, `server.json`, artifact import/export, watcher support, UI support, and security test scripts package the memory service for actual agent environments.

The SQLite schema is simple enough to reason about: `projects`, `file_hashes`, `nodes`, `edges`, `project_summaries`, FTS tables, and vector/token-vector tables. Nodes are unique by `(project, qualified_name)`. Edges are unique by `(source_id, target_id, type)`, and route URL paths are indexed via a generated column over edge properties. This is a useful minimal graph-storage model for agent memory because it keeps graph traversal close to SQL while avoiding a separate graph database dependency.

The graph model is richer than a definition index. It represents functions, methods, classes, routes, Kubernetes resources, config relationships, semantic tags, test relationships, call/data-flow edges, route handlers, HTTP/gRPC/GraphQL/tRPC links, async/channel-style links, and cross-repo matches. That makes it relevant to agent tasks that need to answer "what changes if I touch this function?" instead of only "where is this symbol defined?"

The largest architectural tradeoff is self-containment. The project vendors SQLite, yyjson, xxhash, mimalloc, zstd, tree-sitter runtime/grammars, and other dependencies. That improves distribution and avoids runtime setup, but it creates a large supply-chain and generated-code review surface. Any lab borrowing this pattern should separate "core memory architecture" from "vendored parser corpus" in its own review plan.

## Design Choices

The strongest design choice is requiring project identity for retrieval. `search_graph`, `query_graph`, `trace_path`, `search_code`, `get_architecture`, `manage_adr`, and related tools all require or derive an explicit project scope rather than silently searching every indexed repository. That makes context boundaries visible to the agent and reduces accidental leakage between projects.

The tool schemas encode retrieval shape. `search_graph` supports text, label, name, qualified-name, file, relationship, degree, semantic, limit, and offset filters. The description warns about truncation and pagination. `query_graph` has a max row ceiling and expects an explicit Cypher-like query. `trace_path` has depth, direction, mode, risk, and test filters. `search_code` allows regex and context lines but routes searches through indexed file lists where possible.

The discovery layer makes noise reduction a first-class indexing concern. It excludes VCS metadata, dependency directories, build outputs, coverage, caches, generated folders, vendored folders, binary/media/docs suffixes, and symlinks. It also honors `.gitignore`, nested `.gitignore`, and `.cbmignore`. These choices are directly reusable for context hygiene: codebase memory is only as useful as the files it refuses to index.

The pipeline favors a derived graph over raw chunks. The repo builds qualified names, route nodes, call/data-flow relationships, imports, semantic tags, and summary records before serving retrieval. That gives downstream agents a compact structural surface and supports questions that are hard to answer with text embeddings alone.

Persistence is deliberately local and portable. Per-project SQLite databases live in a cache directory, while optional `.codebase-memory/graph.db.zst` artifacts can bootstrap teams. This is a good compromise for coding agents because the default state stays machine-local, but repositories can choose to carry a compressed graph artifact when they want reproducible context.

The risky design choice is using shell helpers in selected paths while relying on custom validation. `search_code`, `detect_changes`, and artifact helpers use shell commands such as grep, git, sort, and zstd-related flows. The code has validation and tests, but the trusted boundary is broader than a pure `execve`/argv implementation. Another high-complexity choice is the direct SQLite writer, which is valuable for performance but increases the amount of storage-engine correctness the project must own.

## Strengths

- Real codebase-memory scope: it indexes definitions, calls, routes, config links, Kubernetes resources, semantic vectors, similarity, and cross-repo service links instead of presenting only text search.
- Explicit MCP retrieval contracts: tools require project scope, include structured filters, impose limits, and describe truncation/pagination behavior.
- Practical context controls: discovery exclusions, indexed-file search lists, depth-limited traces, snippet extraction by qualified name, and graph filters all reduce prompt bloat.
- Persistence model is understandable: SQLite tables for projects, nodes, edges, hashes, FTS, vectors, and summaries are easy to inspect and back up.
- Root/path safety receives real attention: symlink skipping, realpath containment for snippets, shell-argument validation, authorizer checks against SQLite attach/detach, and security tests are present.
- Incremental and operational features are mature for a candidate repo: file hashes, watcher registration, artifact import/export, install/update paths, server manifest, and broad platform packaging are all implemented.

## Weaknesses

- The trusted surface is large. The repo vendors a major parser and C dependency corpus, includes generated grammar shims, has installer/update flows, optional UI code, shell helper paths, and direct SQLite page writing.
- Some MCP schema claims drift from implementation. `detect_changes` declares `scope` and `since`, but the handler treats `scope` mainly as output mode (`files` versus impact/symbols) and does not implement `since`; path-prefix scoping advertised in examples is not the behavior visible in the handler.
- Shell-based helpers remain important. `search_code`, `detect_changes`, artifact metadata, and git integration rely on shell command construction guarded by `cbm_validate_shell_arg` and quoting. The project has tests, but this remains an audit hotspot for any deployment with untrusted repository paths or branch names.
- Persistence and artifact behavior can write inside user repositories. `manage_adr` and artifact export/update flows write under `.codebase-memory`, and install/config flows write agent/client configuration. These are useful features, but MCP clients should treat them as permissioned mutations, not ordinary read-only memory queries.
- The direct SQLite writer is hard to independently verify. It improves bulk dump speed, but any bug could corrupt graph databases in ways ordinary SQL insert code would avoid. This design demands strong fixture, migration, and cross-version testing.
- Security tests are present but not exhaustive for the highest-risk paths. There are tests for shell metachar rejection, Cypher injection, authorizer-related parser rejection, containment logic, and no-shell execution helpers, but end-to-end tests for every shell path, artifact mutation, installer permission branch, and schema drift would be needed before treating it as a hardened component.

## Ideas To Steal

- Make repository memory a graph-first service with explicit MCP tools for indexing, graph search, code search, call tracing, schema discovery, architecture summaries, and snippets.
- Require a `project` on retrieval tools and make "which codebase am I querying?" part of every agent turn that touches persistent memory.
- Use aggressive discovery exclusions as a correctness feature, not just a performance feature. Include VCS metadata, dependency folders, generated files, caches, binary/media suffixes, symlinks, and local ignore files.
- Store compact structural facts in SQLite: projects, file hashes, nodes, edges, summaries, FTS, and optional vectors are enough to support many agent workflows without adding a graph database.
- Return small, navigable context: qualified names, files, line ranges, relationship counts, paginated result sets, trace depth limits, and snippets on demand.
- Keep a graph schema tool. Agents need to know which labels, edge types, and properties exist before they can write useful structural queries.
- Add artifact import/export as an optional team optimization, but keep local indexing as the default.
- Treat route/service edges as first-class memory objects. HTTP, gRPC, GraphQL, tRPC, async, and Kubernetes relationships are often what coding agents need for impact analysis.
- Keep an explicit test suite for security boundaries: path traversal, shell metacharacters, query injection, authorizer behavior, install output validation, and network-egress assumptions.

## Do Not Copy

- Do not copy the vendored parser/dependency corpus into another project without a dedicated provenance, license, update, and generated-code review process.
- Do not copy shell command construction as the default process model. Prefer argv-based subprocess APIs; if shell use is unavoidable, isolate it and test every interpolation point.
- Do not expose mutating tools such as ADR updates, artifact export, install/config rewrites, or watcher registration without a clear permission model in the client.
- Do not adopt direct SQLite page writing unless performance requires it and the project can maintain deep storage-format tests across SQLite versions and target platforms.
- Do not rely on README/schema examples as the source of truth. This repo already shows drift around `detect_changes` fields, so consumers should test handlers directly.
- Do not index generated, vendored, cache, build, package-manager, or UI-bundle paths when evaluating the codebase-memory behavior. They are noise for the research objective and materially change conclusions about parser quality and graph quality.

## Fit For Agentic Coding Lab

Fit: high. This is a strong candidate for the lab's MCP and codebase-memory track because it implements the whole lifecycle: discovery, parsing, graph construction, persistence, retrieval, context control, and operational packaging. It is especially useful for studying how a local agent can move from raw repository text to structured memory that supports impact analysis.

The best parts to adapt are the contracts, not necessarily the implementation. A lab implementation should borrow the explicit project-scoped MCP schemas, graph labels/edge categories, discovery exclusion discipline, SQLite-backed durable facts, and small-context retrieval patterns. Those ideas transfer well to other languages and runtimes.

The repo is less attractive as a direct dependency for a minimal agent stack. Its C implementation, vendored grammar surface, generated code, installer breadth, optional UI, artifact writer, and direct SQLite writer all increase review cost. For experiments, it may be better to build a smaller compatibility prototype that mirrors the schema and retrieval flows while using safer subprocess and storage primitives.

Verification emphasis for future work should include end-to-end MCP contract tests, path traversal tests against real temp repositories, branch/path shell-injection tests, artifact write permission tests, Cypher read-only guarantees, vector/FTS pagination behavior, and schema drift checks that compare `tools/list` against handler behavior.

## Reviewed Paths

- `/tmp/myagents-research/deusdata-codebase-memory-mcp/README.md` for product claims, MCP tool list, cache/artifact behavior, local-only positioning, and usage examples.
- `/tmp/myagents-research/deusdata-codebase-memory-mcp/server.json` for MCP server metadata, package schema, versions, and platform binaries.
- `/tmp/myagents-research/deusdata-codebase-memory-mcp/Makefile.cbm` for build composition and major source/dependency boundaries.
- `/tmp/myagents-research/deusdata-codebase-memory-mcp/src/main.c` for server startup, CLI tool mode, installer/update entry points, auto-index behavior, and UI/watcher wiring.
- `/tmp/myagents-research/deusdata-codebase-memory-mcp/src/mcp/mcp.c` for MCP schemas, tool dispatch, project store resolution, graph/code search handlers, snippet containment, change detection, ADR handling, architecture summaries, and context-control behavior.
- `/tmp/myagents-research/deusdata-codebase-memory-mcp/src/discover/discover.c` for repository walking, ignore handling, symlink behavior, mode-specific skip rules, generated/vendor/cache exclusions, and suffix filtering.
- `/tmp/myagents-research/deusdata-codebase-memory-mcp/internal/cbm/cbm.c` and `/tmp/myagents-research/deusdata-codebase-memory-mcp/internal/cbm/lang_specs.c` for parser lifecycle, tree-sitter language registration, extraction passes, and LSP reuse of parse results.
- `/tmp/myagents-research/deusdata-codebase-memory-mcp/src/pipeline/pipeline.c`, `/tmp/myagents-research/deusdata-codebase-memory-mcp/src/pipeline/pipeline.h`, and selected `src/pipeline/pass_*.c` files for definitions, calls, usages, routes, Kubernetes, config links, similarity, semantic edges, cross-repo edges, and parallel indexing.
- `/tmp/myagents-research/deusdata-codebase-memory-mcp/src/graph_buffer/graph_buffer.h` for in-memory graph representation, deduplication, qualified-name lookup, merge behavior, incremental delete support, and dump interfaces.
- `/tmp/myagents-research/deusdata-codebase-memory-mcp/src/store/store.c` for SQLite schema, FTS/vector tables, indexes, authorizer behavior, project integrity checks, query APIs, BFS traversal, and search pagination.
- `/tmp/myagents-research/deusdata-codebase-memory-mcp/src/cypher/cypher.c` for the read-oriented Cypher subset, parser restrictions, query planning, and row ceilings.
- `/tmp/myagents-research/deusdata-codebase-memory-mcp/internal/cbm/sqlite_writer.c` for direct SQLite database generation and performance-oriented persistence risks.
- `/tmp/myagents-research/deusdata-codebase-memory-mcp/src/pipeline/artifact.c` for `.codebase-memory` graph artifact import/export, git-head metadata, compression, and repository mutation behavior.
- `/tmp/myagents-research/deusdata-codebase-memory-mcp/src/foundation/str_util.c` for shell-argument validation rules.
- `/tmp/myagents-research/deusdata-codebase-memory-mcp/tests/test_security.c`, `/tmp/myagents-research/deusdata-codebase-memory-mcp/tests/test_cypher.c`, and related tests for security, query, and persistence verification coverage.
- `/tmp/myagents-research/deusdata-codebase-memory-mcp/SECURITY.md` for the project's stated hardening model, audit scripts, network-egress expectations, and threat assumptions.

## Excluded Paths

- `/tmp/myagents-research/deusdata-codebase-memory-mcp/.git/**` was excluded as VCS metadata.
- `/tmp/myagents-research/deusdata-codebase-memory-mcp/vendored/**` was excluded except for dependency-boundary awareness because it contains third-party libraries such as SQLite, yyjson, xxhash, mimalloc, mongoose, zstd, vector data, and related vendored code.
- `/tmp/myagents-research/deusdata-codebase-memory-mcp/internal/cbm/vendored/**` was excluded because it contains the tree-sitter runtime and vendored grammar sources rather than project-specific memory logic.
- `/tmp/myagents-research/deusdata-codebase-memory-mcp/internal/cbm/grammar_*.c` was excluded as generated tree-sitter grammar shim code; only the language registration surface was reviewed.
- `/tmp/myagents-research/deusdata-codebase-memory-mcp/internal/cbm/lsp/generated/**` was excluded as generated language/stdlib data.
- `/tmp/myagents-research/deusdata-codebase-memory-mcp/graph-ui/**` was excluded from deep review because it is optional UI surface, not the MCP indexing/retrieval core.
- `/tmp/myagents-research/deusdata-codebase-memory-mcp/docs/index.html`, screenshots, sitemap, robots files, and generated documentation assets were excluded as website/documentation artifacts.
- `/tmp/myagents-research/deusdata-codebase-memory-mcp/graph-ui/package-lock.json` and other package lock or generated build metadata were excluded as dependency-resolution artifacts.
- `/tmp/myagents-research/deusdata-codebase-memory-mcp/pkg/**` and release packaging wrappers were excluded except for awareness that platform packaging exists.
- `/tmp/myagents-research/deusdata-codebase-memory-mcp/tools/tree-sitter-*` grammar tooling and fixtures were excluded because the research focus is the MCP memory service, not grammar generation internals.
