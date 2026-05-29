# cased/kit

- URL: https://github.com/cased/kit
- Category: context-control
- Stars snapshot: 1,291 (GitHub REST API `stargazers_count`, captured 2026-05-29)
- Reviewed commit: 80009db2e11dc405d0c9e170fa1641cdedf811a3
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: in-scope
- Verdict: High-fit code-intelligence toolkit for coding-agent context engineering. The strongest pieces are the `Repository` facade, tree-sitter symbol extraction, compact MCP file-tree and lazy symbol-code tools, grep/text search, dependency graph summaries, and explicit generated-file deprioritization. Do not copy it as a complete context-control runtime: context assembly is minimal, semantic/docstring search needs external services, several MCP/tool-schema paths diverge from docs, and some repository/path boundaries need stricter enforcement before use in hostile or multi-tenant settings.

## Why It Matters

`kit` is directly aimed at the problem Agentic Coding Lab cares about: giving AI devtools structured, scoped, inspectable codebase context instead of dumping whole files into prompts.

The repo is useful because it implements the mid-level primitives most coding agents keep rebuilding: repository opening, file-tree enumeration, symbol extraction, literal and regex search, AST pattern search, semantic/vector search, docstring-summary indexing, dependency graph extraction, multi-repo search, REST endpoints, MCP tools, CLI commands, and a PR-review consumer that combines diff context with symbols, usages, and dependencies.

The most transferable lesson is the separation between cheap discovery and expensive context expansion. MCP `get_file_tree` defaults to compact newline paths with pagination. MCP `extract_symbols` is designed to omit full source by default. `get_symbol_code` is a lazy expansion tool for one chosen symbol. That is the right shape for an agent context loop: map, search, select, then read exact code.

The caution is that `kit` is a toolkit, not an opinionated agent memory or prompt runtime. It offers parts for context retrieval and assembly, but it does not maintain a context ledger, enforce budgets across turns, rank evidence by task, prove sufficiency, or validate final answers against retrieved code.

## What It Is

`cased/kit` is a Python package named `cased-kit` with CLI command `kit` and MCP command `kit-dev-mcp`. The reviewed checkout is version `3.5.1` in `pyproject.toml`.

The core public API is `kit.Repository`. It can point at a local path or clone a GitHub URL, then expose file tree, file content, symbol extraction, text search, fixed-string grep, symbol usage search, context extraction around a line, chunking by lines or symbols, vector search, summary search, dependency analyzers, and git metadata.

The repository also ships:

- A tree-sitter based multi-language symbol extractor with built-in query files for Python, JavaScript, TypeScript, TSX, Go, Rust, Haskell, HCL/Terraform, C, C++, C#, Ruby, Java, Dart, Kotlin, and Zig.
- Dependency analyzers for Python, JavaScript/TypeScript, Go, Rust, and Terraform.
- `VectorSearcher` and `DocstringIndexer` wrappers over Chroma local/cloud backends.
- FastAPI endpoints for repository registration, file tree, file content, search, grep, symbols, usages, index, summaries, dependencies, git info, and batch file content.
- MCP server logic for code search, compact file trees, symbol extraction, lazy symbol-code retrieval, AST search, package documentation research, package-source search, and AI diff review.
- A TypeScript client that shells out to the Python CLI.
- A PR reviewer that demonstrates using repository intelligence to build review prompts without blindly embedding full file contents.

## Research Themes

- Token efficiency: Strong at the retrieval-tool boundary. Compact file tree output, pagination, `extract_symbols(include_code=false)`, `get_symbol_code`, file prioritization, symbol limits, line/file size guards, and generated-file skips all reduce context. The in-process `ContextAssembler` is much thinner and leaves most budget policy to callers.
- Context control: Strong for codebase mapping and source retrieval primitives. The repo provides map/search/select/read building blocks, git ref support, dependency summaries, package-source search, and REST/MCP interfaces. It does not provide a full turn-level context manager or evidence ledger.
- Sub-agent / multi-agent: Low to medium. `MultiRepo` supports cross-repo search and dependency audits, but there are no subagent contracts, handoff schemas, worker isolation rules, or multi-agent orchestration.
- Domain-specific workflow: Strong for AI coding tools. The library understands files, symbols, imports, diffs, PR files, package source, and language-specific parsers instead of treating code as generic text.
- Error prevention: Medium. There are many tests and several safety controls: path traversal checks, MCP path resolving, API URL sanitization, optional repo URL allowlists, safe git-ref validation in local review, grep timeouts, and generated-file filters. Gaps remain around absolute-path validation in lower-level APIs, stale clone caches, schema drift, and advisory docs.
- Self-learning / memory: Low. Caches are performance caches, not agent memory. Incremental symbol analysis, Chroma indexes, registry persistence, and summary caches help repeated operations but do not learn durable preferences or task state.
- Popular skills: Repository facade, progressive code discovery, compact tool responses, lazy source expansion, tree-sitter symbol queries, generated-file filtering, dependency graph summaries, tool schemas, MCP packaging, and PR-review context construction.

## Core Execution Path

The main local execution path starts with `Repository(path_or_url, ref=None)`.

For a local path, `Repository` stores an absolute path, optionally checks out a git ref, then constructs a `RepoMapper`, `CodeSearcher`, `ContextExtractor`, and optional vector searcher. For a remote HTTP(S) URL, it clones into a cache directory under `tempfile.gettempdir()/kit-repo-cache`, using `KIT_GITHUB_TOKEN` or `GITHUB_TOKEN` when available.

A typical context loop is:

1. Call `repo.get_file_tree()` to get files and directories. `RepoMapper` uses the Rust `ignore` walker through `ignore-python`, respects gitignore/git excludes in the fast file-tree path, and returns path/name/size/is_dir records.
2. Call `repo.extract_symbols(file_path)` for a selected file or `repo.extract_symbols()` for a repo-wide scan. `RepoMapper` reads supported files, runs `TreeSitterSymbolExtractor.extract_symbols`, adds file paths, and caches repo-wide symbol maps by mtime.
3. Call `repo.search_text(query, file_pattern)` for regex text search. `CodeSearcher` prefers ripgrep JSON output, falls back to Python regex scanning, and can include bounded context lines.
4. Call `repo.grep(pattern, ...)` for fixed-string grep. This path uses system `grep -F`, excludes common generated/vendor/cache directories, supports include/exclude globs, directory scoping, hidden-directory control, max results, and timeout.
5. Call `repo.extract_context_around_line(file, line)` or `repo.chunk_file_by_symbols(file)` to expand only the relevant function, class, or nearby code.
6. Optionally call dependency analyzers, semantic search, or docstring search to broaden retrieval.
7. Use `ContextAssembler` or caller-specific prompt logic to format diff, file snippets, and search results.

The MCP execution path wraps those primitives in `KitServerLogic` and `LocalDevServerLogic`. `open_repository` returns an in-memory repo id. `get_file_tree` can return compact newline-separated paths with pagination metadata. `extract_symbols` is advertised as code-free by default in the call handler. `get_symbol_code` expands one named symbol. `grep_ast` runs `ASTSearcher` in a small thread pool. `deep_research_package` combines Context7-like docs, Chroma package search, and optional LLM synthesis. Package search tools call Chroma's remote package-source MCP API.

The REST path registers repositories through a persistent `~/.kit/registry.json` map, creates deterministic ids, and reconstructs `Repository` objects through an LRU cache. It exposes file tree, file content, search, grep, symbols, usages, index, summaries, dependencies, git info, and batch file content.

The PR-review path shows a concrete consumer. `PRReviewer.analyze_pr_with_kit` gets the diff, maps line numbers, prioritizes files, extracts symbols for priority files, searches usages for the first few symbols, generates dependency context, summarizes repo size, and builds an LLM review prompt with diff plus structured repository intelligence.

## Architecture

The architecture is a layered toolkit.

The repository facade is `src/kit/repository.py`. It owns clone/ref handling, git metadata, cache invalidation, and high-level methods that delegate to narrower helpers.

The mapping layer is `src/kit/repo_mapper.py` plus `src/kit/tree_sitter_symbol_extractor.py` and `src/kit/queries/**/tags.scm`. `RepoMapper` handles file-tree construction and repo-wide symbol scanning. The extractor owns language registration, query loading, parser/query caching, tree-sitter API compatibility, HCL resource naming, code span extraction, and duplicate symbol removal.

The search layer is split by search type. `CodeSearcher` handles regex text search with ripgrep fallback. `Repository.grep` handles literal grep with broad generated/vendor/cache excludes. `ASTSearcher` provides simple/pattern structural search, though full tree-sitter query mode is not implemented. `VectorSearcher`, `DocstringIndexer`, and `SummarySearcher` add embedding and LLM-summary search through Chroma.

The context layer is small. `ContextExtractor` chunks files by lines or symbols and extracts the Python function/class around a line, falling back to a ten-line window for other languages. `ContextAssembler` formats diff, full files, and search results with optional file size/line guards.

The dependency layer is `src/kit/dependency_analyzer/**`. It normalizes graph operations behind `DependencyAnalyzer`, then implements language-specific import/reference extraction and LLM-friendly dependency summaries.

The integration layer includes `src/kit/cli.py`, `src/kit/api/app.py`, `src/kit/api/registry.py`, `src/kit/mcp/dev_server.py`, `src/kit/tool_schemas.py`, and `clients/typescript/**`. These expose the primitives to terminals, HTTP services, MCP clients, LLM tool schemas, and Node callers.

The applied workflow layer is `src/kit/pr_review/**`. It is not the core context engine, but it is an important example of how the primitives can feed an AI review loop with prioritized files, symbols, usages, dependencies, diff mapping, cost tracking, and review validation.

## Design Choices

The best design choice is a single `Repository` object as the boundary. Agents and tool adapters do not have to know whether a repository is local, remote, ref-pinned, Python, TypeScript, or Terraform. They ask the same object for structure, content, symbols, search hits, dependencies, summaries, and git metadata.

The second strong choice is progressive disclosure in MCP. The file tree is compact by default. Symbols can be listed without code. Code expansion is moved to `get_symbol_code`. This directly prevents "symbol search accidentally returns every function body" context blowups.

The multi-language symbol system is pragmatic. It uses tree-sitter queries instead of regexes for structure, caches parsers and queries, supports additional query files, and has plugin hooks for new or extended languages. This gives Agentic Coding Lab a clear pattern for pluggable language intelligence.

The repo separates exact search, structural search, semantic search, and summary search. That distinction matters. Literal grep is cheap and reliable for known strings. Tree-sitter symbols give navigation. AST search catches structural patterns. Embeddings and LLM docstrings are optional discovery aids with higher cost and weaker determinism.

Generated and low-value files are explicitly deprioritized in several places. `Repository.grep` excludes common cache/build/vendor directories. `.gitignore` excludes Python build, env, coverage, cache, editor, Claude, and Next.js artifacts. `FilePrioritizer` skips lockfiles, generated/minified/bundle/source-map files, `node_modules`, caches, and `.git`.

The system treats git state as part of context identity. `Repository` exposes SHA, branch, tags, dirty state, and remote URL; API registry ids include ref/worktree state; local review validates git refs; PR review uses head SHA for line links. This is useful for reproducible context if callers pin refs deliberately.

The tests are broad for a toolkit. The checkout includes tests for symbol extraction across languages, tree-sitter compatibility, code search, grep, path validation, API security, MCP tools, package search, dependency analyzers, vector search, docstring indexing, local review, PR review, CLI behavior, and large-codebase cache warming.

## Strengths

`Repository` is the right abstraction level for agentic coding context. It is high-level enough for agents and integrations, but still exposes structured primitives rather than a black-box "answer this codebase question" API.

The tree-sitter symbol extractor is the strongest reusable subsystem. It supports many languages, extracts code spans, start/end lines, symbol names and types, deduplicates duplicate captures, and can be extended through plugins and query files.

The MCP context-saving pattern is very strong. Compact file trees, `include_code=false`, lazy symbol-code expansion, and `warm_cache` are directly reusable for Agentic Coding Lab tools.

The grep implementation has good operational defaults. Fixed-string search is often safer for agent tools than regex, and the default exclusions cover the directories most likely to waste context or time.

The dependency analyzers provide a useful bridge from raw code to architecture context. Even if the graphs are approximate, `generate_llm_context()` produces a compact summary of central nodes, external/internal counts, and cycles.

The PR reviewer is a concrete example of context assembly under budget pressure. It prioritizes files, avoids full file contents, extracts symbols, counts usages, adds dependency context, and reports skipped files for transparency.

The API security work is better than many small devtool repos. URL sanitization, allowlist support, structured security logs, path traversal tests, and git ref validation are all useful patterns.

The docs explain retrieval tradeoffs well. The search overview separates text, symbol, semantic, and docstring search by setup cost, speed, and query type, which is good vocabulary for future context-control docs.

## Weaknesses

The public `validate_relative_path` helper does not reject absolute paths. `base_path / "/etc/passwd"` resolves to the absolute path, and the helper only reasons about `..` parts. MCP single/multiple file content does an additional `.resolve().is_relative_to(repo_path)` check, but lower-level `Repository.get_file_content`, `get_abs_path`, `ContextExtractor`, and `RepoMapper` paths depend on the weaker helper.

Remote repository caching can return stale default-branch code. `_clone_github_repo` returns an existing cached repo immediately when no `ref` is requested, without fetching. For agent context, stale code is worse than slow code unless the caller pins a commit or opts into refresh behavior.

Local `Repository(path, ref=...)` checks out the requested ref in the user's working tree. That is a surprising mutation for a read-oriented context tool and should not be copied into a lab agent without worktree isolation or explicit confirmation.

The MCP advertised tool list and the handler/docs do not fully agree. `KitServerLogic.list_tools()` advertises core tools such as `open_repository`, `grep_code`, `get_file_tree`, `extract_symbols`, `find_symbol_usages`, `review_diff`, `grep_ast`, `get_symbol_code`, and `warm_cache`. The handler also has branches for `search_code`, `get_file_content`, `get_multiple_file_contents`, `get_code_summary`, and `get_git_info`, while `docs/core-concepts/tool-calling-with-kit.mdx` says `get_tool_schemas()` exposes several of those. Agents relying on tool schemas may never see important retrieval tools.

Some MCP parameters are advisory or ignored. `KitServerLogic.extract_symbols` accepts `symbol_type` but returns all symbols. `find_symbol_usages` ignores both `symbol_type` and `file_path`. The call handler passes `file_path` into the `symbol_type` slot for usage lookup, then the method discards it. `get_symbol_code` matches only by symbol name, so duplicate names in a file are ambiguous.

`ASTSearcher` advertises `mode="query"` through the MCP schema, but `ASTPattern.matches` returns `False` for query mode and the implementation is unfinished. This is a tool-contract gap for agents that expect native tree-sitter query search.

Context assembly is intentionally lightweight. `ContextAssembler` concatenates diff, full files, and search hits with simple guards, but it does not rank files, budget sections, preserve provenance beyond headings, compress tool results, or verify that final context is sufficient.

Repo-wide symbol scanning and file-tree walking use different ignore behavior. The fast file-tree path uses the `ignore` walker with gitignore/git-exclude support, while `scan_repo()` uses `rglob()` plus a root `.gitignore` pathspec check. Nested ignore files or `.ignore` behavior can therefore diverge.

The REST API has useful security controls but should be treated as trusted-local by default. It has no built-in auth, URL allowlists are opt-in, explicit `github_token` in the REST request model is not passed into `registry.get_repo`, and the registry writes global state under `~/.kit/registry.json`.

Semantic search and docstring search are powerful but operationally heavy. They require embedding functions, Chroma local/cloud setup, optional LLM API keys, cache directories inside repos, and sometimes model downloads. Multi-repo semantic search sorts by higher `score`, while Chroma distance scores are usually lower-is-better, so ranking semantics need checking before adoption.

I did not run the upstream test suite in this worker. A direct source import failed because raw-checkout dependencies such as `pathspec` are not installed in the environment. This note is based on code, docs, tests, and repository metadata review, plus the project research verification script.

## Ideas To Steal

Use a `Repository`-like facade as the central context primitive. Keep the interface stable: file tree, file content, symbols, search, grep, dependency summary, git metadata, and context snippets.

Make context retrieval progressive by construction: compact file tree first, symbols without source second, single-symbol source expansion third, full file only when required.

Expose `include_code=false` as the default for symbol tools. Pair it with a lazy `get_symbol_code(repo_id, file_path, symbol_name)` expansion tool.

Return compact file-tree output for agents. A header with total count, offset, limit, and `has_more` plus newline paths is a good high-signal response shape.

Keep fixed-string grep and regex search separate. Agents often need exact strings, and exact grep can be faster, safer, and easier to budget.

Use tree-sitter query files as language plugins. Store one query directory per language, cache parsers/queries, and provide a small registration API for custom languages or local extensions.

Add generated/vendor/cache exclusion lists in every high-volume search/review path, not just `.gitignore`. Include lockfiles, minified files, bundles, source maps, caches, build outputs, env dirs, and dependency directories.

Generate LLM-friendly dependency summaries from graph data. Central nodes, internal/external counts, and cycles are more prompt-useful than raw graph dumps.

Use file prioritization before expensive model calls. The PR reviewer pattern of filtering generated files, ranking by source/config/test importance, and reporting skipped files is a good review-context pattern.

Treat package-source search as a separate context plane. `package_search_grep`, `package_search_hybrid`, and `package_search_read_file` show how an agent can inspect dependency source without vendoring it into the repo context.

Use optional cache-warming tools for large repositories. `warm_cache` is a good explicit operation because it lets the agent trade time for smoother later calls.

Carry git SHA/ref metadata through every repository id and final answer. Context from code is only reliable when the exact commit is known.

## Do Not Copy

Do not let a read-oriented repository object mutate the user's local checkout to satisfy `ref`. Use a detached clone or worktree.

Do not use weak path validation as a shared security boundary. Reject absolute paths, resolve symlinks, and verify the final path remains under the repository root.

Do not advertise tool parameters that the server ignores. Tool schemas are agent contracts; stale or partially implemented fields cause bad plans.

Do not expose handler-only tools without listing them in `list_tools()` and `get_tool_schemas()`. Agents that rely on discovery will never call invisible tools.

Do not label AST search as full semantic or query search until native query mode is implemented and tested.

Do not assume Chroma distance scores, local scores, and multi-repo merged scores all have the same direction. Normalize ranking before presenting merged semantic results to agents.

Do not use root `.gitignore` checks as the only exclusion layer for repo-wide scans. Use one ignore implementation consistently across file tree, symbol extraction, search, vector indexing, and dependency analysis.

Do not expose the REST server across trust boundaries without auth, path policy, URL allowlist, rate limits, and secret filtering. The current API is better suited to local or controlled deployments.

Do not make LLM-generated docstring indexes the only retrieval plane. They are useful for intent search, but exact grep, symbols, and direct code reads remain the verification path.

Do not copy the PR-review prompt assembly wholesale. The valuable parts are file prioritization, symbol/usage/dependency enrichment, line-link mapping, and skipped-file transparency; the exact prompt should be smaller and task-specific.

## Fit For Agentic Coding Lab

Fit is high as a pattern source and possible dependency candidate for context-control work. It is especially relevant to codebase mapping, symbol extraction, search APIs, language plugins, MCP response shaping, package-source retrieval, generated-file exclusion, and dependency context summaries.

Best adaptation for Agentic Coding Lab:

- A local `repo_context` tool layer with `open_repo`, `file_tree`, `symbols`, `grep`, `ast_search`, `symbol_code`, `read_files`, `dependency_summary`, and `git_info`.
- A strict context contract where every tool response includes source repo id, commit SHA/ref, path, and truncation/pagination metadata.
- A retrieval workflow skill: map the repo, search exact strings, inspect symbols, expand only selected definitions, read full files only when symbols are insufficient, then cite paths in the final answer.
- A generated/vendor/cache exclusion policy shared by all scans and tests.
- A `context budget` wrapper around `ContextAssembler` that ranks sections, records why each file was included, and refuses to silently include oversized files.
- A schema test that compares advertised MCP tools against handler branches, docs, and actual parameter behavior.

`kit` should not be adopted as a complete agent runtime. It should influence the lab's context tools and validators, while the lab adds stricter boundaries, worktree-safe ref handling, evidence accounting, budgeted assembly, and verification gates.

## Reviewed Paths

- `/tmp/myagents-research/cased-kit/README.md`: reviewed for project purpose, install paths, Python API, CLI, capabilities, MCP positioning, PR review features, and context-engineering claims.
- `/tmp/myagents-research/cased-kit/pyproject.toml`: reviewed for package metadata, version, dependencies, optional ML extras, CLI entrypoints, and test/lint configuration.
- `/tmp/myagents-research/cased-kit/.gitignore`: reviewed for generated, vendor, cache, build, environment, editor, Claude, and Next.js artifact exclusions.
- `/tmp/myagents-research/cased-kit/src/kit/repository.py`: reviewed for central API, clone/cache/ref behavior, git metadata, file content, search, grep, vector search, summarizer, dependency analyzer, symbol usage, exports, cache invalidation, and incremental analysis integration.
- `/tmp/myagents-research/cased-kit/src/kit/repo_mapper.py`: reviewed for file-tree walking, gitignore handling, subpath support, repo-wide symbol scanning, mtime caching, and single-file symbol extraction.
- `/tmp/myagents-research/cased-kit/src/kit/tree_sitter_symbol_extractor.py` and `src/kit/queries/**/tags.scm`: reviewed for supported languages, parser/query caching, plugin extension, query loading, tree-sitter API compatibility, HCL naming, symbol spans, code extraction, and deduplication.
- `/tmp/myagents-research/cased-kit/src/kit/code_searcher.py`, `src/kit/ast_search.py`, and `src/kit/context_extractor.py`: reviewed for ripgrep/Python regex search, context-line handling, AST structural search, query-mode gap, line/symbol chunking, and line-neighborhood extraction.
- `/tmp/myagents-research/cased-kit/src/kit/llm_context.py`: reviewed for prompt assembly behavior, diff/file/search-result formatting, and simple size guards.
- `/tmp/myagents-research/cased-kit/src/kit/vector_searcher.py`, `src/kit/docstring_indexer.py`, and `src/kit/summaries.py`: reviewed for Chroma local/cloud backends, vector index building, summary indexing, embedding flow, LLM provider configs, token guards, and cache metadata.
- `/tmp/myagents-research/cased-kit/src/kit/incremental_analyzer.py`: reviewed for file metadata/hash cache, symbol cache persistence, LRU eviction, changed-file filtering, statistics, cleanup, and finalization.
- `/tmp/myagents-research/cased-kit/src/kit/dependency_analyzer/**`: reviewed for base graph interface, LLM context generation, Python import analysis, JavaScript/TypeScript import parsing, Go module import analysis, Rust/Terraform analyzers at source level, and cycle/dependent APIs.
- `/tmp/myagents-research/cased-kit/src/kit/api/app.py` and `src/kit/api/registry.py`: reviewed for FastAPI routes, repository registry persistence, URL sanitization, allowlist matching, error handling, file/symbol/search/dependency endpoints, and auth/boundary behavior.
- `/tmp/myagents-research/cased-kit/src/kit/mcp/dev.py`, `src/kit/mcp/dev_server.py`, and `src/kit/tool_schemas.py`: reviewed for MCP entrypoint, parameter models, tool listing, handler routing, compact file tree, symbol code suppression, lazy symbol-code loading, package research, package-source search, prompt support, and schema exposure.
- `/tmp/myagents-research/cased-kit/src/kit/package_search.py`: reviewed for Chroma package-source grep, hybrid search, file read, SSE/JSON-RPC response parsing, and API-key boundary.
- `/tmp/myagents-research/cased-kit/src/kit/multi_repo.py`: reviewed for cross-repo text search, semantic search, symbol search, dependency audit, and summary behavior.
- `/tmp/myagents-research/cased-kit/src/kit/cli.py`: reviewed for user-facing commands around cache, chunking, context extraction, dependencies, search, semantic search, package search, PR review, summaries, and commit messages.
- `/tmp/myagents-research/cased-kit/src/kit/pr_review/base_reviewer.py`, `file_prioritizer.py`, `local_reviewer.py`, and `reviewer.py`: reviewed for diff retrieval, repo caching, generated-file prioritization, safe local git ref handling, symbol/usage/dependency context assembly, LLM review prompts, and validation hooks.
- `/tmp/myagents-research/cased-kit/clients/typescript/**`: reviewed for TypeScript CLI wrapper shape, typed return contracts, temp-file use for file-tree JSON, repo-scoped helper pattern, and shell-out boundary.
- `/tmp/myagents-research/cased-kit/docs/src/content/docs/**`: sampled and reviewed for overview, usage guide, repository API, search approaches, symbol search, docstring indexing, incremental analysis, LLM context best practices, tool-calling docs, and MCP tool docs.
- `/tmp/myagents-research/cased-kit/tests/**`: sampled and reviewed for repository, search, symbol extraction, tree-sitter languages, path validation, API security, MCP server behavior, tool schemas, context assembler, dependency analyzers, vector search, docstring indexing, large-codebase cache warming, local review, and PR review coverage.
- Git metadata and GitHub REST metadata: reviewed default branch checkout state, exact commit, clean status, star/fork/issue/license/language/default-branch snapshot, and pushed/updated timestamps.

## Excluded Paths

- `/tmp/myagents-research/cased-kit/.git/**`: excluded as version-control internals. Git commands were used instead to capture commit and checkout state.
- Generated, vendor, dependency, and cache paths named by `.gitignore` or runtime defaults: `__pycache__/`, `.pytest_cache/`, `.ruff_cache/`, `.mypy_cache/`, `.cache/`, `.kit/`, `.kit_cache/`, `.venv/`, `venv/`, `.tox/`, `.nox/`, `build/`, `dist/`, `*.egg-info/`, `node_modules/`, `.next/`, `coverage/`, and `test-results/`. These are not maintained source or context-control logic.
- Lockfiles and dependency-resolution artifacts such as `uv.lock`, `docs/package-lock.json`, and `clients/typescript/package-lock.json`: checked only as dependency metadata, not deeply reviewed for context-engineering behavior.
- `docs/public/**`, docs fonts, `docs/favicon.svg`, `kit-mcp-site/public/**`, UI icons, and image/font assets: excluded as presentation/static media rather than codebase mapping or context-control logic.
- Most `docs/src/components/**`, `docs/src/styles/**`, `kit-mcp-site/app/**`, `kit-mcp-site/components/**`, and UI component libraries: reviewed only at a high level because they are documentation/product UI surfaces, not the retrieval/runtime context-control path.
- `src/kit/pr_review/example_reviews/**`: excluded as example output artifacts. The PR-review implementation and tests were reviewed instead.
- `tests/fixtures/**`, `tests/sample_code/**`, `tests/examples/**`, and golden files: sampled where useful to understand test coverage, but not treated as production implementation.
- `benchmarks/**` and one-off scripts such as release/format/manual MCP inspector helpers: excluded from deep review because they are performance, release, or manual-development support rather than the primary agent context path.
- External services and documentation sites linked by the repo, including `kit.cased.com`, `kit-mcp.cased.com`, Chroma package search, and Context7/Upstash providers: reviewed only through local code/docs references because this note is scoped to the checked-out repository implementation.
