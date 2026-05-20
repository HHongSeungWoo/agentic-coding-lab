# safishamsi/graphify

- URL: https://github.com/safishamsi/graphify
- Category: ai-coding-workflow
- Stars snapshot: 49,968 stars, 5,420 forks from GitHub REST API on 2026-05-20
- Reviewed commit: 6939494b3e76ba94a52d1da6ff1e467206444f72
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong candidate to mine for codebase graph/context extraction, query-first agent instructions, incremental graph maintenance, and graph-aware review planning. Reuse patterns, not implementation shape: the repo has useful workflow primitives but much of the production surface is concentrated in large dispatcher modules.

## Why It Matters

Graphify is a concrete implementation of a "read the graph before reading the repo" workflow for coding agents. It turns source, docs, papers, images, videos, SQL schemas, and assistant memory notes into a persistent `graphify-out/graph.json`, then gives agents scoped commands such as `graphify query`, `graphify path`, and `graphify explain` instead of asking them to repeatedly grep or reread whole files.

For Agentic Coding Lab, the most reusable idea is not the HTML visualization. The useful pattern is a compact, auditable context layer between the codebase and the agent: deterministic AST extraction for code, LLM-assisted semantic extraction for non-code artifacts, confidence-tagged edges, community detection, and small query surfaces that fit inside context budgets. The repo also demonstrates how to push that layer into day-to-day workflows through `AGENTS.md`/`CLAUDE.md`/`GEMINI.md`, MCP tools, post-commit hooks, PR impact analysis, and query-first install text.

## What It Is

Graphify is a Python package and AI assistant skill published as `graphifyy`, with CLI command `graphify`. It installs skill/instruction files for Claude Code, Codex, OpenCode, Cursor, Gemini CLI, Copilot, Aider, Kiro, and other agents. The core pipeline is:

`detect -> extract -> build -> cluster -> analyze -> report -> export`

The outputs are `graphify-out/graph.json`, `graphify-out/GRAPH_REPORT.md`, and optional `graph.html`, wiki, Obsidian vault, GraphML, SVG, Neo4j, global graph, and callflow HTML exports. Code is parsed locally with tree-sitter. Documents, papers, and images are semantically extracted through the host assistant or configured LLM backend. Video/audio is transcribed locally before entering the semantic path.

## Research Themes

- Token efficiency: Persistent graph plus `query`/`path`/`explain` creates small scoped context instead of raw-file rereads. `serve.py` enforces token budgets, IDF-weighted seed selection, hub-skipping traversal, and optional context filters such as `call` or `import`. `benchmark.py` measures estimated query-token reduction.
- Context control: `.graphifyignore`, sensitive-file skipping, corpus-size gates, cache checks, graph query budgets, wiki/callflow exports, and install-time "query first" instructions all reduce agent context sprawl. The strongest context-control pattern is making graph lookup a first action before grep for architecture questions.
- Sub-agent / multi-agent: Skill files split semantic extraction into chunks and dispatch parallel subagents for docs/papers/images while AST extraction runs separately. Headless `graphify extract` uses direct backend calls with chunk packing, concurrency knobs, and adaptive retry.
- Domain-specific workflow: The system is explicitly tuned for AI coding: AST calls/imports, code rationale comments, SQL schema relationships, PR blast-radius mapping, graph-aware review queue triage, post-commit rebuilds, and MCP tools for codebase questions.
- Error prevention: Confidence labels (`EXTRACTED`, `INFERRED`, `AMBIGUOUS`), schema validation, edge direction preservation, shrink checks before overwrite, chunk failure requeueing, sensitive-file detection, SSRF/path/XSS protections, and broad tests reduce silent graph corruption.
- Self-learning / memory: `save-result` writes Q&A results into `graphify-out/memory/`, and `detect()` explicitly includes that memory directory in future scans. `global_graph.py` composes multiple project graphs with repo-prefixed node IDs.
- Popular skills: The skill-install layer is reusable: per-platform skill files plus persistent project instructions teach agents when to consult graph tools, how to refresh the graph after code changes, and when to use broad reports versus scoped queries.

## Core Execution Path

For an assistant-invoked workflow, `graphify/skill*.md` drives the process. It detects supported files, summarizes corpus size, runs local AST extraction for code, checks semantic cache, splits non-code files into chunks, dispatches semantic extraction agents, merges cached and fresh chunks, builds a NetworkX graph, clusters it, labels communities, writes report/JSON/HTML, and optionally exports wiki, Obsidian, SVG, GraphML, or Neo4j artifacts.

For headless CI/script usage, `graphify.__main__` command `extract` implements the same path directly: `detect()` or `detect_incremental()`, tree-sitter AST extraction with `ProcessPoolExecutor`, semantic extraction through `llm.extract_corpus_parallel`, cache save, merge, `build()`, `cluster()`, `god_nodes()`, `surprising_connections()`, JSON/report sidecars, manifest update, and optional global graph registration.

For agent context retrieval, `graphify query` loads `graph.json`, scores matching nodes, selects seeds, traverses BFS or DFS with hub suppression and optional context filters, then renders compact `NODE` and `EDGE` lines under a token budget. `path` finds shortest paths between concepts. `explain` prints node metadata and top neighbors. The MCP server exposes the same primitives plus PR-impact tools.

For graph freshness, `graphify update` and `watch.py` re-extract code without LLM calls, preserve semantic nodes from the previous graph, evict changed/deleted source-file nodes, recluster, preserve labels when possible, and avoid rewriting outputs when topology is unchanged. Git hooks launch background code-only rebuilds after commits and branch switches with a per-repo lock.

## Architecture

The core modules are strongly pipeline-shaped:

- `detect.py`: file classification, `.graphifyignore`/`.graphifyinclude`, sensitive-file skipping, Google Workspace and Office sidecar conversion, manifest and incremental change detection.
- `extract.py`: tree-sitter and regex extraction across many languages; file/function/class/import/call/rationale/SQL nodes and edges; AST cache; cross-file call/import resolution.
- `llm.py`: direct semantic extraction backends, prompt schema, token estimation, directory-aware chunk packing, ThreadPool concurrency, context-overflow retry, and cache-aware merge support.
- `build.py`: schema canonicalization, validation, path normalization, node/edge merge, deduplication, directed-edge preservation, global graph prefix/prune helpers.
- `cluster.py`, `analyze.py`, `report.py`, `export.py`, `wiki.py`, `callflow_html.py`: community detection, god-node/surprise analysis, human-facing summaries, graph serialization, and navigable artifacts.
- `serve.py`: MCP stdio server and query helpers that convert graph slices into small text contexts for agents.
- `watch.py`, `hooks.py`, `manifest.py`, `global_graph.py`, `prs.py`: workflow integration around incremental rebuilds, git hooks, cross-project graph memory, and graph-aware PR triage.

The shared data model is deliberately simple: node/edge dictionaries flow between stages, then NetworkX becomes the in-memory graph. Edge attributes carry relation, confidence, confidence score, source file, source location, context, and weight. Graph JSON uses NetworkX node-link format with compatibility handling for `links`/`edges`.

## Design Choices

The best design choice is separating deterministic code structure from expensive semantic extraction. Code files are parsed locally and cached. Non-code context goes through LLM/subagent extraction only when needed. This keeps routine `graphify update` cheap and makes the LLM boundary visible.

The second strong choice is confidence-tagged graph edges. Graphify does not treat all relationships as equal: imported/called relationships can be `EXTRACTED`, cross-file label matches can be `INFERRED`, and uncertain semantic links can be `AMBIGUOUS`. The report, wiki, MCP output, and surprising-connection ranking preserve that audit trail.

The third strong choice is query-first agent installation. The generated project instructions tell agents to run `graphify query`, `graphify path`, or `graphify explain` when a graph exists, and to read `GRAPH_REPORT.md` only for broad architecture context. That is a practical context-efficiency policy, not just a tool.

The fourth choice is source-aware incremental maintenance. Hash manifests, AST/semantic cache namespaces, changed-path pruning, node-count shrink refusal, stable-ish community remapping, and label preservation all target the same failure mode: stale graph output becoming worse than no graph.

The riskiest choice is implementation concentration. `extract.py` and `__main__.py` carry many responsibilities and platform-specific edge cases. That may be reasonable for a fast-moving OSS tool, but Agentic Coding Lab should copy the pipeline boundaries and file contracts, not the monolithic dispatch style.

## Strengths

Graphify treats context as an artifact, not a one-off prompt. The graph persists across sessions, can be queried in bounded slices, can be updated after commits, and can be shared with multiple assistant clients.

The code/doc split is pragmatic. Local AST extraction gives cheap, repeatable structure for code; semantic extraction is reserved for rationale, docs, papers, images, and transcripts where AST cannot help.

The agent-facing query layer is compact. `serve.py` returns line-oriented graph context with budgets, seed ranking, traversal mode, context filters, and hub skipping. This is much easier for an agent to consume than a giant report or visualization artifact.

The workflow reaches planning and verification. `prs.py` maps changed files to graph communities and affected nodes, which turns graph data into review priority, merge-risk, and duplicate-work signals.

The repo has substantial regression coverage across extraction, language support, cache, query, security, hooks, install strings, wiki export, PR analysis, and pipeline behavior. The tests encode many lessons from real edge cases: path normalization, direction preservation, context filters, manifest drift, and generated/noise filtering.

## Weaknesses

The codebase graph is only as useful as the extractor precision. Cross-file call resolution still relies partly on labels and import evidence; the changelog shows repeated fixes for spurious inferred edges, duplicate filenames, generic labels, cross-language pollution, and direction flips. Agentic users must preserve confidence and provenance instead of treating graph answers as ground truth.

Search is graph traversal seeded by lexical matching, not full semantic retrieval. IDF scoring and seed selection help, but a question can miss relevant nodes when labels do not share terms with the query. The repo itself tracks embedding-based search as future direction.

The skill and CLI surfaces duplicate workflow knowledge across many platform files. That gives broad compatibility, but it also creates drift risk. The root `AGENTS.md` in the reviewed checkout still used older report-first guidance, while generated install sections in `__main__.py` and tests enforce query-first wording.

Large modules raise maintenance cost. `extract.py` is a multi-language framework plus many extractors plus cache/cross-file resolution; `__main__.py` is installer, query CLI, exporter, extractor, and integration router. A smaller lab artifact should keep adapter code isolated from core graph contracts.

HTML/visual exports are useful demos but not the main value for coding agents. The reusable asset is the machine-queryable graph and workflow integration; copying the UI-heavy surface would add complexity without improving agent context.

## Ideas To Steal

Build a first-class "context graph" artifact with three commands every agent can use: `query(question, budget, filters)`, `path(a, b)`, and `explain(node)`. Make these tools preferred before broad source scans when a graph exists.

Split extraction by trust/cost: deterministic local AST for code; semantic/LLM extraction only for docs, rationale, diagrams, papers, transcripts, and human notes. Cache them separately so code-only updates never trigger semantic re-extraction.

Attach confidence and provenance to every edge. Agents should see whether a dependency is explicit, inferred, or ambiguous, plus source file/location. This enables planning with uncertainty instead of pretending the graph is perfect.

Use graph communities as planning units. A PR or task touching files can map to communities, affected nodes, and cross-community edges. That gives agents a useful "blast radius" before editing and a focused verification target afterward.

Install query-first guidance as project instructions, not only as docs. The pattern should live where agents read it: `AGENTS.md`, skill files, hooks, or MCP metadata.

Make graph freshness cheap and visible. Preserve semantic nodes, re-run AST on changed code, prune deleted sources, refuse suspicious graph shrinkage unless forced, and mark non-code changes as requiring semantic refresh.

Add a small agent memory feedback loop. Saving answered questions into a graph-scanned memory directory is a simple way to let repeated decisions become searchable project context without inventing a full memory database.

## Do Not Copy

Do not copy the monolithic extractor/CLI layout. Use Graphify's pipeline contracts, but keep language adapters, semantic extraction, CLI routing, installer logic, and exports behind separate interfaces.

Do not make graph traversal the only retrieval mode. Lexical seed search is brittle for intent-level questions; pair graph traversal with embeddings or another semantic seed finder if the lab needs natural-language discovery.

Do not hide inferred edges. The graph becomes dangerous if agents consume `INFERRED` relationships as equivalent to import/call facts.

Do not make background hooks mutate graph artifacts without clear ownership. Graphify has locks and shrink checks, but any lab adaptation should define whether graph outputs are committed, ignored, regenerated in CI, or treated as local cache.

Do not overinvest in visualization before agent APIs. HTML, SVG, GraphML, and Obsidian are useful secondary products; the key interface is a small bounded context response that an agent can reason over.

Do not let platform instruction copies drift. Generate them from one source or test them aggressively, as Graphify does with install-string tests.

## Fit For Agentic Coding Lab

Fit is high for an AI coding workflow research track. Graphify demonstrates a reusable architecture for compressing codebase context into an auditable graph, querying it cheaply, updating it incrementally, and connecting it to planning/review workflows.

Best adaptation path:

1. Define a minimal graph schema for code entities, files, tasks, decisions, tests, and PRs.
2. Implement deterministic extractors first, with confidence/provenance fields mandatory.
3. Add a semantic extraction lane only for design docs, ADRs, issue notes, and assistant memory.
4. Expose graph slices through MCP/CLI with strict token budgets and filters.
5. Add graph freshness checks to the verification harness so agents know whether they can trust graph context.

The main caution is operational: a graph layer helps only if it is fresh enough, queryable enough, and honest about uncertainty. Graphify's cache, manifest, hooks, confidence labels, and shrink checks are all responses to that problem.

## Reviewed Paths

- `README.md`: product surface, install flow, supported file types, command reference, privacy model, benchmark claims, development workflow.
- `ARCHITECTURE.md`: pipeline contract, module responsibilities, extraction schema, confidence labels, testing guidance.
- `docs/how-it-works.md`: three-pass extraction model, community detection, confidence scoring, token benchmark, parallel extraction, SHA256 cache, graph format.
- `pyproject.toml`: package metadata, CLI entry point, dependencies, optional extras, test configuration.
- `graphify/__main__.py`: CLI dispatch, platform install sections, query/path/explain, extract/update/cluster/export/global workflows.
- `graphify/detect.py`: file classification, skip rules, sensitive-file patterns, ignore/include handling, Office/Google conversion, manifest and incremental detection.
- `graphify/extract.py`: tree-sitter extraction framework, language configs, rationale extraction, SQL extraction, AST cache, parallel extraction, cross-file resolution.
- `graphify/llm.py`: semantic extraction prompt schema, supported backends, chunk packing, token budgeting, concurrency, adaptive retry, local/Ollama handling.
- `graphify/build.py`: validation/canonicalization, directed-edge preservation, path normalization, dedup path, global graph helpers.
- `graphify/cluster.py`, `graphify/analyze.py`, `graphify/report.py`, `graphify/export.py`, `graphify/wiki.py`, `graphify/callflow_html.py`: graph interpretation and export surfaces.
- `graphify/serve.py`: MCP tools, graph query rendering, IDF seed scoring, BFS/DFS traversal, context filters, shortest path, PR impact tools.
- `graphify/watch.py`, `graphify/hooks.py`, `graphify/cache.py`, `graphify/manifest.py`, `graphify/global_graph.py`, `graphify/prs.py`: freshness, cache, hook, memory, cross-project, and PR workflows.
- `graphify/skill.md`, `graphify/skill-codex.md`, `graphify/skill-opencode.md`, platform skill variants: assistant orchestration and query-first behavior.
- `SECURITY.md`: threat model and mitigations for URL fetch, path traversal, XSS/prompt injection, symlinks, corrupted graph JSON.
- `tests/test_pipeline.py`, `tests/test_query_cli.py`, `tests/test_serve.py`, `tests/test_cli_export.py`, `tests/test_install*.py`, `tests/test_hooks.py`, `tests/test_incremental.py`, `tests/test_wiki.py`, and related language/security/cache tests: regression coverage for graph construction, querying, install guidance, update behavior, and exports.
- `.github/workflows/ci.yml`: CI presence and test entry point.
- `CHANGELOG.md`: recent fixes and features used to identify operational pain points around stale graphs, direction bugs, manifests, false merges, query seeding, and hook behavior.

## Excluded Paths

- `docs/translations/*.md`: generated or translation-only documentation; excluded because it duplicates README content across locales and does not add workflow architecture.
- `docs/logo-*.svg` and badge/logo assets: UI/branding-only.
- `worked/**`: example output corpora and generated graph artifacts; skimmed names only, excluded from architectural conclusions except as evidence that worked examples exist.
- `tests/fixtures/graphify-out/cache/*.json`: generated cache fixtures; not representative source.
- Binary/media-style artifacts and generated HTML outputs such as `worked/rsl-siege-manager/graph.html`: UI/demo artifacts, not core workflow code.
- `.github/FUNDING.yml`, `LICENSE`, and routine repository metadata: reviewed only for context, excluded from pattern analysis.
- No vendored dependency directories were present in the reviewed checkout; dependency code is declared through `pyproject.toml` rather than committed vendor trees.
