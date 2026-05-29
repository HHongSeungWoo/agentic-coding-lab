# MinishLab/semble

- URL: https://github.com/MinishLab/semble
- Category: mcp
- Stars snapshot: 4,512 (GitHub REST API, captured 2026-05-29)
- Reviewed commit: e6afc1d7abe6e0d730f7fcb95d338973bc75f930
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong reference for an agent-oriented code-search MCP and CLI. The core ideas to reuse are hybrid chunk retrieval, search-before-read workflow guidance, recursive ignore handling, local cache validation, token-savings accounting, and a tiny two-tool MCP surface. Main cautions are broad local-path read authority, no MCP roots enforcement, remote URL caches that are not commit-revalidated, and JSON-string outputs rather than typed structured MCP content.

## Why It Matters

Semble targets a common agent failure mode: exploratory codebase work starts with broad grep, full-file reads, and large context windows. It offers a local code-search runtime that returns compact chunks by semantic or symbol query, with both MCP and CLI entrypoints so agents can search first and read full files only when chunks are insufficient.

For Agentic Coding Lab, this is directly relevant as a code-search MCP pattern. It is small enough to audit end to end, runs locally on CPU, does not require a hosted service, and explicitly optimizes token use for coding agents rather than for general document RAG.

## What It Is

The repository is a Python package named `semble`. It exposes:

- A stdio MCP server with `search` and `find_related` tools.
- A CLI with `search`, `find-related`, `init`, and `savings`.
- A Python library centered on `SembleIndex.from_path()`, `SembleIndex.from_git()`, `search()`, and `find_related()`.
- Agent snippets for Claude, Copilot, Cursor, Gemini, Kiro, and OpenCode.
- Benchmarks comparing retrieval quality, speed, and token efficiency against grep-style and embedding baselines.

The runtime indexes local directories or git repositories. It chunks files, builds dense static embeddings plus a BM25 index, fuses results with Reciprocal Rank Fusion, reranks with code-specific heuristics, and returns chunk text plus file path and line range.

## Research Themes

- Token efficiency: Strong. Search returns bounded chunks instead of full files, tracks estimated token savings against a read-whole-files baseline, and encourages search-before-read workflows in README and bundled agent files.
- Context control: Strong for retrieval shape, conditional for permissions. The result unit is a repo-relative chunk with location metadata, content types can be limited to code/docs/config, and ignore rules reduce corpus noise. The MCP server does not use MCP roots or per-project allowlists for local path boundaries.
- Sub-agent / multi-agent: Conditional. The repo ships a `semble-search` sub-agent prompt for several harnesses, but the runtime itself is not a multi-agent coordinator.
- Domain-specific workflow: Strong. Retrieval is tuned for code through tree-sitter chunking, identifier tokenization, symbol-aware weighting, file-stem boosts, definition boosts, and penalties for tests, examples, legacy shims, and declaration stubs.
- Error prevention: Strong for search quality and cache freshness on local paths; weaker for runtime authorization. Tests cover empty queries, path errors, unsafe git schemes in MCP, cache invalidation, symlink skipping, and watcher rebuild behavior.
- Self-learning / memory: Weak. It has durable search indexes and usage stats, but no durable agent memory or learned preferences.
- Popular skills: Strong. The generated agent snippets encode a practical workflow: use search, select docs/config when needed, inspect full files only after chunks, use `find-related`, and fall back to grep only for exhaustive literal checks.

## Core Execution Path

MCP startup flows through `semble.cli.main()`. If the first argument is not a CLI subcommand, `_mcp_main()` parses an optional startup path, optional git ref, and content types, checks that MCP extras are installed, then calls `semble.mcp.serve()`.

`serve()` creates an `_IndexCache`, starts a background task that loads the Model2Vec model, optionally pre-indexes the startup path, and starts a file watcher for local startup paths. It then registers a FastMCP server named `semble` and opens stdio immediately, so the client can initialize while model loading continues.

The MCP server exposes two tools:

- `search(query, repo=None, top_k=5)`: gets or builds an index, runs hybrid retrieval, and returns JSON with `query` and `results`.
- `find_related(file_path, line, repo=None, top_k=5)`: resolves a prior result location to a chunk, then returns semantically similar chunks, filtered to the source chunk language when possible.

Index lookup is handled by `_get_index()`. A tool-supplied git URL is accepted only when it starts with `https://` or `http://`; `ssh://`, `file://`, and SCP-style git URLs are rejected in MCP tests. Local directory paths are accepted as strings and resolved by `SembleIndex.from_path()`. If no `repo` is supplied, the server uses the startup default source.

Index construction flows through `SembleIndex.from_path()` or `SembleIndex.from_git()`. Local paths are checked for existence and directory type, then compared against a persisted cache. Git paths are cloned with `git clone --depth 1 -- [url] [tmp_dir]`, using `--` to prevent the URL from being parsed as a git option. Optional `ref` is available through library and MCP startup mode, but not through the per-call MCP tool schema.

`create_index_from_path()` walks the tree, reads valid files, chunks each source file, embeds chunks, builds BM25 documents, and stores a `SelectableBasicBackend` vector index. The file walker honors `.gitignore` and `.sembleignore` recursively, skips symlinks, skips known non-source/cache/build directories, and can force-include non-default extensions through negated ignore patterns.

Search uses `semble.search.search()`. It embeds the query for dense retrieval, tokenizes identifiers for BM25, over-fetches `top_k * 5` candidates from each retriever, converts each score list to RRF scores, fuses with an adaptive alpha, and reranks code results by multi-chunk file coherence, symbol/definition/stem boosts, path penalties, and file saturation decay.

Output is compact but not typed as structured MCP content. Both MCP tools return a JSON string; each result contains the chunk content, repo-relative `file_path`, `start_line`, `end_line`, `language`, `location`, and score.

## Architecture

The package is organized around a small search core:

- `src/semble/cli.py`: command dispatch, MCP startup, CLI search/find-related/init/savings, content-type parsing, and agent-file installation.
- `src/semble/mcp.py`: FastMCP server, tool schemas, in-memory LRU index cache, background model load, local watcher, and repo-source validation.
- `src/semble/index/index.py`: `SembleIndex` lifecycle, local/git indexing, cache load/save, search, related search, stats, filters, and persistence.
- `src/semble/index/create.py`: indexing pipeline from files to chunks, embeddings, BM25, and vector backend.
- `src/semble/index/file_walker.py`: `.gitignore`/`.sembleignore` loading, default ignored directories, symlink skipping, recursive traversal, and extension allow rules.
- `src/semble/index/files.py`: extension-to-language map, content type grouping, file-size limit, empty-file skipping, UTF-8 replacement reads, and mtime status.
- `src/semble/chunking/`: tree-sitter parser caching, AST-aware chunk boundaries, fallback line chunking, and fixed desired chunk size.
- `src/semble/search.py`: dense search, BM25 search, RRF fusion, adaptive weighting, and top-k assembly.
- `src/semble/ranking/`: path penalties, symbol detection, definition boosts, file-stem boosts, file coherence, and alpha selection.
- `src/semble/cache.py`: OS cache directory resolution, path hashing, metadata validation, local file manifest/mtime checks, and cache clearing.
- `src/semble/stats.py`: JSONL search telemetry and token-savings report formatting.

The main runtime dependency stack is `model2vec`, `vicinity`, `bm25s`, `tree-sitter`, `tree-sitter-language-pack`, `pathspec`, `orjson`, and optional `mcp`/`watchfiles`.

## Design Choices

The API is intentionally narrow. The MCP surface has only `search` and `find_related`, while content type selection and default repo setup are command-line configuration choices. That keeps tool choice easy for agents.

The retrieval stack is hybrid by design. Dense static embeddings handle semantic intent, BM25 handles identifiers and API names, and RRF avoids raw-score calibration problems. Symbol-looking queries get lower semantic weight, while natural-language queries stay balanced.

The ranker encodes code priors directly. It boosts definitions, stem/path matches, embedded CamelCase symbols, and files with multiple relevant chunks. It down-ranks test files, examples, compatibility/legacy paths, `__init__.py` re-export barrels, and TypeScript `.d.ts` stubs.

Cache validation favors speed. Local indexes store model path, content type, write time, and a file manifest; local reuse is invalidated when relevant files are newer, added, or removed. Git URL indexes skip file checks and are keyed only by URL or URL plus `ref`.

File selection is extension-based plus ignore-based. Supported languages are inferred from suffixes, docs/config/code are partitioned by language groups, files above 1 MB are skipped, empty files are skipped, and text is read as UTF-8 with replacement.

The CLI and agent snippets are first-class integration points. `semble init` writes a dedicated search sub-agent file for multiple coding harnesses, and the README includes an AGENTS.md-style workflow.

## Strengths

The code-search execution path is easy to inspect. There is no hidden service for indexing; the main behavior is in roughly five thousand lines of Python plus focused tests.

The search design is well matched to coding-agent exploration. It combines semantic retrieval, lexical retrieval, path signals, definition signals, and noise penalties instead of relying on embeddings alone.

The local file boundary has practical corpus hygiene. Recursive `.gitignore` plus `.sembleignore`, default ignored directories, no symlink following, file-size limits, and content-type filters reduce accidental indexing of dependencies, builds, caches, and generated outputs.

The cache model is pragmatic for local repos. It avoids re-indexing unchanged trees, persists indexes under the OS cache folder, and has tests for metadata mismatch, newer files, deleted files, added files, incomplete indexes, and legacy metadata.

MCP startup is agent-friendly. Stdio opens while the model loads in a background task; tool calls wait on model readiness and report model/index errors rather than crashing the server.

The test suite covers the important runtime boundaries: MCP tool output and error paths, unsafe git scheme rejection, LRU eviction, watcher rebuilds, CLI dispatch, content-type parsing, chunker fallbacks, search filters, ranking heuristics, git clone failures, and cache validation.

The benchmark documentation is unusually transparent for a small MCP candidate. It describes quality, speed, token-efficiency methodology, dataset shape, ablations, and excluded baselines.

## Weaknesses

MCP local path access is broad. A tool caller can pass any local directory path visible to the server process; there is no MCP roots negotiation, workspace allowlist, or root-relative path schema.

Remote git freshness is weak. Git indexes are cached by URL or URL plus `ref`, and cache validation returns immediately for git URLs. If a branch head moves, a cached URL-only index can remain stale until the cache is cleared or a different ref/key is used.

Remote clone permission is still broad despite scheme filtering. MCP rejects `ssh://`, `file://`, and SCP-style URLs, but permits arbitrary `http://` and `https://` hosts, including potentially internal hosts if the server environment can reach them.

The per-call MCP schema does not expose `ref`, content type, language filters, path filters, alpha, or rerank controls. That keeps the tool simple, but agents cannot pin remote commits or switch docs/config indexing per query unless the server was started with the right content options.

Outputs are JSON strings rather than typed structured MCP content. Agents can parse them, but the server does not give clients a native schema for result items, paging, truncation metadata, or follow-up handles beyond `file_path` and `line`.

`top_k` has only a lower bound. A client can request a very large result count, causing bigger over-fetching, output payloads, and token use. The fixed chunk size also is not configurable.

The embedding model is local but downloaded/loaded by name through `StaticModel.from_pretrained()`. Environments without pre-cached model access can fail or require network/model cache setup; the repo does not vendor model artifacts.

## Ideas To Steal

Use a two-tool code-search MCP surface: intent search first, related-code expansion second.

Represent retrieval output as repo-relative chunks with file path, line range, language, content, and score.

Combine dense embeddings with BM25 and RRF instead of choosing only semantic or lexical search.

Add code-specific reranking signals: symbol definition boosts, identifier splitting, file-stem matches, multi-chunk file coherence, test/example/legacy penalties, and per-file saturation.

Honor both `.gitignore` and tool-specific ignore files, and make generated/vendor/model artifacts explicit exclusions.

Persist indexes with metadata that includes model identity, content type, file manifest, and write time.

Open MCP stdio immediately while heavier model/index warmup runs in the background.

Ship CLI and sub-agent instructions alongside the MCP server so the intended agent workflow is encoded in artifacts, not just prose.

Track token savings locally to give users feedback on whether the retrieval tool is actually reducing context load.

## Do Not Copy

Do not expose arbitrary local path indexing in a hardened agent without roots or an allowlist.

Do not cache remote branch indexes by URL alone if reproducibility or freshness matters. Prefer commit SHA keys, remote HEAD validation, or explicit ref/commit parameters.

Do not return unbounded result payloads to agents. Add a maximum `top_k`, byte budget, or pagination layer for production use.

Do not treat search chunks as sufficient verification. The bundled workflow is right: inspect full files when the chunk lacks enough context.

Do not rely on static ignore defaults alone for generated code. Projects still need `.sembleignore` rules for repo-specific generated, vendored, large, secret-like, or model-output paths.

Do not assume a local embedding runtime is zero setup in restricted environments. Model download/cache behavior needs operational documentation.

## Fit For Agentic Coding Lab

Fit is in-scope and strong. Semble is one of the cleanest candidates for a coding-agent code-search MCP because it directly reduces search/read token load while preserving local execution and simple tool choice.

The best adaptation would be a hardened project-local version: root-bound indexing only, commit-aware remote indexing, maximum result budgets, structured MCP output, explicit generated/vendor/model exclusions, and a workflow rule that search is the first step for unfamiliar code but not the final verification step.

Semble is especially useful as a reference for future Agentic Coding Lab artifacts around search-before-read, codebase triage, token-saving telemetry, and MCP tools that return compact evidence instead of whole files.

## Reviewed Paths

- `/tmp/myagents-research/minishlab-semble/README.md`
- `/tmp/myagents-research/minishlab-semble/CONTRIBUTING.md`
- `/tmp/myagents-research/minishlab-semble/pyproject.toml`
- `/tmp/myagents-research/minishlab-semble/src/semble/cli.py`
- `/tmp/myagents-research/minishlab-semble/src/semble/mcp.py`
- `/tmp/myagents-research/minishlab-semble/src/semble/cache.py`
- `/tmp/myagents-research/minishlab-semble/src/semble/search.py`
- `/tmp/myagents-research/minishlab-semble/src/semble/stats.py`
- `/tmp/myagents-research/minishlab-semble/src/semble/tokens.py`
- `/tmp/myagents-research/minishlab-semble/src/semble/types.py`
- `/tmp/myagents-research/minishlab-semble/src/semble/utils.py`
- `/tmp/myagents-research/minishlab-semble/src/semble/index/index.py`
- `/tmp/myagents-research/minishlab-semble/src/semble/index/create.py`
- `/tmp/myagents-research/minishlab-semble/src/semble/index/dense.py`
- `/tmp/myagents-research/minishlab-semble/src/semble/index/sparse.py`
- `/tmp/myagents-research/minishlab-semble/src/semble/index/file_walker.py`
- `/tmp/myagents-research/minishlab-semble/src/semble/index/files.py`
- `/tmp/myagents-research/minishlab-semble/src/semble/index/types.py`
- `/tmp/myagents-research/minishlab-semble/src/semble/chunking/core.py`
- `/tmp/myagents-research/minishlab-semble/src/semble/chunking/chunking.py`
- `/tmp/myagents-research/minishlab-semble/src/semble/ranking/boosting.py`
- `/tmp/myagents-research/minishlab-semble/src/semble/ranking/penalties.py`
- `/tmp/myagents-research/minishlab-semble/src/semble/ranking/weighting.py`
- `/tmp/myagents-research/minishlab-semble/src/semble/agents/claude.md`
- `/tmp/myagents-research/minishlab-semble/src/semble/agents/copilot.md`
- `/tmp/myagents-research/minishlab-semble/benchmarks/README.md`
- `/tmp/myagents-research/minishlab-semble/tests/test_mcp.py`
- `/tmp/myagents-research/minishlab-semble/tests/test_cli.py`
- `/tmp/myagents-research/minishlab-semble/tests/test_cache.py`
- `/tmp/myagents-research/minishlab-semble/tests/test_file_walker.py`
- `/tmp/myagents-research/minishlab-semble/tests/test_git.py`
- `/tmp/myagents-research/minishlab-semble/tests/test_search.py`
- `/tmp/myagents-research/minishlab-semble/tests/test_ranking.py`
- `/tmp/myagents-research/minishlab-semble/tests/index/test_index.py`

## Excluded Paths

- `/tmp/myagents-research/minishlab-semble/.git/`: VCS internals; reviewed commit captured separately.
- `/tmp/myagents-research/minishlab-semble/assets/images/`: generated/static benchmark and logo images; not runtime logic.
- `/tmp/myagents-research/minishlab-semble/uv.lock`: dependency lock artifact; dependency families reviewed through `pyproject.toml`.
- `/tmp/myagents-research/minishlab-semble/benchmarks/results/*.json`: generated benchmark outputs; methodology reviewed through benchmark code/docs, not every result artifact.
- `/tmp/myagents-research/minishlab-semble/benchmarks/annotations/*.json`: benchmark dataset labels; relevant to benchmark claims but not MCP/runtime execution path.
- `/tmp/myagents-research/minishlab-semble/benchmarks/baselines/`: baseline runner implementations were not line-reviewed because the task focus was Semble MCP/runtime paths.
- `/tmp/myagents-research/minishlab-semble/.github/`: CI/project metadata, not search runtime.
- Vendored dependencies: none present in the repository.
- Model artifacts: none vendored. The default model is resolved as `minishlab/potion-code-16M` and loaded through `StaticModel.from_pretrained()` at runtime.
