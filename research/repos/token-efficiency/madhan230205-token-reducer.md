# Madhan230205/token-reducer

- URL: https://github.com/Madhan230205/token-reducer
- Category: token-efficiency
- Stars snapshot: 25 (GitHub REST API, captured 2026-05-29)
- Reviewed commit: 1a0a11dfc8fc8645e465abbd505d46addc025ccb
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong local-first implementation candidate for coding-agent context compression, with real Python code for SQLite FTS5 indexing, hash/ML/ONNX embeddings, adaptive vector fallback, context packets, query cache, session memory, and Claude Code command/skill packaging. The useful core is the FTS-first top-K retrieval and compression path. Do not copy the advertised "LSP-killer" layer or broad settings surface uncritically: import graph and 2-hop symbol expansion functions exist but are not wired into the main indexing/retrieval path, many `settings.json` toggles are not consumed, and the diff applicator needs stronger sandboxing before agent use.

## Why It Matters

Token Reducer addresses a common coding-agent failure mode: agents read too many files, paste too much raw text into the conversation, and then keep resending bloated history. It tries to move that work into a local pre-context pipeline: collect candidate files, clean and chunk them, rank chunks with BM25 and optional vectors, summarize only the top few chunks, and return a compact context packet with citations and token-savings telemetry.

The repo matters for Agentic Coding Lab because it is not just a prompt pack. It includes executable retrieval/compression code, a Claude Code slash command, a Codex/Claude-style skill, prompt-submit hook guardrails, tests, benchmark commands, and local state management. That makes it a practical reference for an agent-side context compressor that can run before implementation work.

Its main research value is the conservative policy shape: FTS first, vectors only when useful, small final top-K, relevance floor before summarization, and local fallback when optional ML dependencies are absent. Its main caution is the gap between the advertised feature list and the wired runtime path.

## What It Is

Token Reducer is a Claude Code plugin and Python CLI named `claude-token-reducer`, version `1.4.0` in the reviewed checkout. The public surfaces are:

- `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`: Claude plugin metadata.
- `commands/token-reducer.md`: slash-command wrapper around `scripts/context_pipeline.py run`.
- `skills/token-reducer/SKILL.md`: workflow instructions for using the compressor before large-context work.
- `hooks/userprompt_guard.py` and `hooks/hooks.json`: `UserPromptSubmit` guard that warns, transforms, or blocks oversized raw prompts.
- `scripts/token_reducer/`: Python package for chunking, SQLite storage, embeddings, ANN lookup, retrieval, compression, benchmarking, and CLI commands.
- `src/lib.rs`: optional PyO3 Rust acceleration for tokenization, token estimation, char n-grams, and text chunking.
- `tests/`: unit and CLI integration tests for core Python behavior.

The repo is local-first by design. Hash embeddings and regex chunking work without heavy optional dependencies. Better vector search and AST-aware chunking require optional packages such as `sentence-transformers`, `onnxruntime`, `hnswlib`, `faiss-cpu`, and `tree-sitter` grammars.

## Research Themes

- Token efficiency: Primary theme. The runtime builds compact context packets from a ranked chunk pool, enforces small default top-K and word budgets, reports selected-token and candidate-pool savings, caches repeated queries, and includes a prompt guard for raw-paste bypass prevention.
- Context control: Strong in the core path. File filters, max file size, minified detection, query length validation, adaptive retrieval tiers, relevance floors, session IDs, and citation-rich packets all give the agent levers before source text enters the LLM context.
- Sub-agent / multi-agent: Light. The repo ships three small Claude agent instruction files for chunking, retrieval, and compression, plus an orchestration agent. These are guidance stubs rather than a multi-agent runtime.
- Domain-specific workflow: Strong for local coding work. Code files use tree-sitter or regex function/class chunk boundaries, prose uses line-window chunking, and compression handles code signatures differently from prose sentences.
- Error prevention: Moderate. Query guards reject pasted corpora, file collection skips common noisy artifacts, CLI tests cover many happy paths, and `apply_diff.py` stages per-file transactions. Gaps remain around path sandboxing, prompt injection in recalled/indexed content, and untested diff application.
- Self-learning / memory: Limited but useful. The pipeline writes `session_memory.json` next to the DB with recent queries and sources. This is continuity state, not learned project memory or durable semantic memory.
- Popular skills: The reusable skill pattern is "run compact retrieval first, then reason from a packet." The strongest pieces to borrow are the slash command, prompt guard, packet schema, and local cache/session telemetry.

## Core Execution Path

The main runtime starts through `scripts/context_pipeline.py`, which delegates to `token_reducer.cli`.

1. `index`, `run`, or `sync` opens a local SQLite DB under `.cache/token-reducer/index.db` by default.
2. Input paths are expanded by `collect_input_files()`. It accepts configured text/code extensions, skips `.git`, virtualenvs, `node_modules`, build outputs, lockfiles, minified bundles, SVGs, oversized files above 512 KB, and files with very long lines.
3. Each file is read with UTF-8/UTF-16/Latin-1 fallback, cleaned by removing boilerplate/blank/duplicate lines, then chunked.
4. Code chunking first tries tree-sitter for supported languages, then regex top-level boundary patterns, then plain text chunking. Prose chunking uses line windows with overlap.
5. `upsert_document()` stores raw text, cleaned text, chunks, FTS rows, and one embedding per chunk in SQLite. Hash embeddings are always available; ONNX and sentence-transformer backends fall back to hash on runtime failure.
6. For large indexes, the CLI can build HNSW artifacts under the DB directory. Vector retrieval also has FAISS and brute-force scan fallback paths.
7. Query execution validates that the query is not a pasted corpus, cleans expired query-cache rows, and creates a cache key from query parameters, session ID, and an index fingerprint.
8. Retrieval always runs FTS5/BM25 first. Adaptive tiers skip vectors for small indexes, use fallback behavior for medium/large indexes, and skip vector retrieval entirely when using hash embeddings unless configured otherwise in code.
9. FTS and vector hits are merged. If vector hits exist, reciprocal rank fusion can rank them; otherwise weighted FTS, vector, and query-overlap scores produce final scores.
10. The compressor merges adjacent chunks, drops chunks below the relevance floor, extracts code signatures/docstrings for code, uses TextRank plus query overlap for prose, and enforces a word budget.
11. `build_packet()` emits `CONTEXT_PACKET_START` / `CONTEXT_PACKET_END`, retrieval metadata, estimated savings, bullets, candidate summaries, session memory, and cache metadata.
12. Repeated identical queries can return from `query_cache`, then update the lightweight session memory.

The `UserPromptSubmit` hook is a separate guard path. It counts words/lines in the submitted prompt, warns on large raw prompts, attempts local `compress-raw` transformation above a hard-truncate threshold, and can reject very large prompts. It also tracks per-session turn counts and emits compact/reset reminders.

The advertised import graph and 2-hop symbol path is not part of this main execution path at the reviewed commit. `index_file_dependencies()`, `index_symbols()`, `fetch_imported_context()`, and `expand_symbols_two_hop()` exist, but `index_corpus()`, `upsert_document()`, `run_retrieval_pipeline()`, and `build_packet()` do not call them.

## Architecture

The architecture has four layers.

First, plugin integration. `.claude-plugin/plugin.json`, marketplace metadata, `commands/token-reducer.md`, `skills/token-reducer/SKILL.md`, small agent instruction files, `.mcp.json`, and hook metadata make the tool installable and usable from Claude Code-style workflows. The command invokes the Python pipeline through `CLAUDE_PLUGIN_ROOT`.

Second, local retrieval storage. `db.py` creates `documents`, `chunks`, `chunks_fts`, `chunk_embeddings`, `query_embeddings`, `query_cache`, `file_dependencies`, and `symbol_index` tables. The active path uses documents, chunks, FTS, embeddings, query embeddings, query cache, and session memory. The dependency and symbol tables are present but not populated by the normal indexing path.

Third, retrieval and compression. `retriever.py` handles FTS query building, BM25 result construction, vector retrieval through HNSW/FAISS/scan, RRF/weighted reranking, and cached query embeddings. `compressor.py` handles TextRank, code signature extraction, adjacent-chunk merging, budget enforcement, packet formatting, and token metrics.

Fourth, optional acceleration. `embeddings.py` supports hash, sentence-transformer, and ONNX embeddings. `ann.py` supports HNSW and FAISS artifacts keyed by backend, dimensions, model, and index fingerprint. `src/lib.rs` provides optional Rust replacements for Python tokenizer/chunker primitives.

The test architecture is focused but real: unit tests cover chunking, DB/cache/session memory, embeddings, and CLI integration; the CLI suite exercises `benchmark`, `run`, `run --json`, `index`, and error handling with hash embeddings.

## Design Choices

The strongest design choice is FTS-first retrieval. BM25 handles precise code identifiers and keywords cheaply, and vector work is reserved for cases where FTS recall is weak or the user forces `hybrid_mode=always`. This is a good default for coding agents because many code queries are lexical.

The second important choice is graceful degradation. Missing tree-sitter falls back to regex chunking; missing ONNX or sentence-transformer runtimes fall back to hash embeddings; missing ANN packages fall back to scan. That makes the tool usable in constrained local environments.

The third choice is small final context. Settings default to 3 final contexts and a 150-word compression budget, and the compressor stops packing when the candidate score falls below the relevance floor. This reduces the common failure where summarizers fill a budget with low-relevance material just because space remains.

The fourth choice is local state. The DB stores raw and cleaned text, FTS rows, embeddings, query embeddings, query result cache, and optional ANN files. Session continuity lives in `session_memory.json`. This improves repeated-query speed but creates a privacy surface that needs explicit retention and deletion policy.

The fifth choice is code/prose-specific compression. Code summaries prefer signatures, docstrings, or first lines; prose summaries use extractive sentence scoring. This is better than one summarizer for all input, although the resulting code bullets can still be awkward and lossy.

The sixth choice is prompt-bypass prevention. The hook recognizes that native file reads and pasted logs bypass any retrieval compressor, so it warns, compresses, truncates, or blocks oversized prompts before the model sees them.

The biggest weak design choice is over-broad configuration. `settings.json` exposes many knobs, but `plugin_settings.py` only reads chunk size, overlap, word budget, default top-K, and relevance floor into CLI defaults. Settings such as embedding backend/model, hybrid mode, ANN tuning, semantic clustering, TextRank toggles, LSP feature toggles, max file size, and scoring weights are either hardcoded, unused, or only manually configurable through function calls that the CLI does not invoke.

## Strengths

The core is executable and easy to inspect. Unlike many token-efficiency repos, this one has a full local pipeline rather than only agent instructions or marketing diagrams.

The dependency fallback story is practical. A user can get value with hash embeddings and SQLite FTS5, then add tree-sitter, ONNX, HNSW, or FAISS later.

The SQLite schema is a good fit for local coding-agent retrieval. It keeps provenance, chunks, FTS text, embeddings, query caches, and stats in one inspectable local store.

The adaptive retrieval tier is sensible. Small codebases avoid vector overhead, medium indexes use fallback behavior, and large indexes can use ANN artifacts when available.

The prompt guard addresses a real cost leak: users and agents can accidentally paste raw corpora or load huge files after the compressor was supposed to help.

The packet telemetry is useful. It exposes FTS/vector hit counts, vector path, selected chunks, source count, estimated savings, candidate-pool reduction, cache hits, and candidate scores.

The tests are meaningful for the core Python path. In an isolated venv with pure Python dependencies and `PYTHONPATH=scripts`, `143 passed in 4.11s`; the built-in self-test also passed and confirmed BM25, cache hit on repeat, selected-chunk limits, compressed-token bounds, and session memory.

The repo is small enough to adapt. Most runtime behavior sits in straightforward modules rather than a framework-heavy service.

## Weaknesses

The "LSP-killer" features are mostly not wired. Dependency extraction, symbol indexing, imported-context fetching, and 2-hop symbol expansion have functions and some tests, but normal indexing does not populate those tables and normal packet generation does not include imported context or referenced symbols.

The settings surface overstates configurability. Many `settings.json` fields are not read by the CLI path. Notably, the file says `embeddingBackend: "ml"` and a Jina code model, while `config.py` defaults to `onnx` and `sentence-transformers/all-MiniLM-L6-v2`; `plugin_settings.py` does not reconcile that mismatch.

Some documented features are dead or aspirational in the reviewed runtime. `cluster_chunks_semantically()` exists but is not called. `textRankEnabled`, `textRankDamping`, `textRankIterations`, `semanticClusteringEnabled`, `pageRankEnabled`, `compressionMaxSelectedRatio`, `embeddingCache`, and `lspFeatures` toggles do not drive the main pipeline.

The benchmark evidence is self-referential and mostly lexical. `BENCHMARK.md` reports strong savings on the token-reducer codebase with hash embeddings and zero vector hits, which validates BM25-plus-extractive compression more than semantic retrieval. The cost estimates use a fixed price assumption and should not be treated as current provider economics.

The generated code-context bullets can lose too much structure. A local hash-mode query returned useful retrieval metadata, but one bullet was a partial assignment sequence and another repeated docstrings/signatures. This is acceptable as a hint packet, not as a substitute for exact file reads before edits.

The diff applicator needs hardening before agent use. `apply_diff.py` resolves block file paths against a working directory but does not enforce that the resolved target stays under that directory, so `../` or absolute paths can escape the intended patch root. There are no tests for `apply_diff.py`.

Local privacy is better than remote APIs but not complete. The DB stores raw file text and cleaned text, query cache payloads, embeddings, query embeddings, and session history. There is garbage collection for stale DB records, but no policy layer for sensitive-file exclusion, redaction, retention windows, encryption, or prompt-injection treatment of recalled content.

Packaging has friction. The project build backend is `maturin`, so `pip install -e .` attempts Rust-extension metadata/build work. In this sandbox that failed when Rust setup tried to write under a read-only home cache. The pure Python path ran fine after installing runtime dependencies manually, which suggests the Rust extension should be optional in packaging as well as runtime.

Claude Code install naming may be confusing. README install examples use `token-reducer@Madhan230205-token-reducer`, while plugin metadata names the plugin `claude-token-reducer`. That may be harmless depending on marketplace resolution, but it is an integration risk worth verifying.

## Ideas To Steal

Use FTS5/BM25 as the first retrieval layer for coding context. It is cheap, deterministic, and strong for identifiers, filenames, APIs, and error strings.

Gate vector retrieval by index size and FTS recall. A context compressor should not pay semantic-search cost when a small local FTS index already returns enough hits.

Keep a tiny final packet by default. Top-3 chunks, a relevance floor, and a short word budget are good defaults for pre-reasoning context.

Include packet telemetry every time. Agents need to know whether vectors ran, how many chunks were selected, how much context was dropped, and whether a cache hit occurred.

Use local query caches keyed by query parameters plus index fingerprint. This avoids stale context reuse when the indexed corpus changes.

Separate code and prose compression. Code should preserve signatures, names, and traceable snippets; prose can tolerate extractive sentence ranking.

Add a prompt-submit guard for raw-paste bypass. Compression tools need a guardrail at the point where users or agents can still dump the whole corpus into the chat.

Make optional dependencies truly optional. Hash embeddings, regex chunking, and scan fallback are valuable for quick local adoption.

## Do Not Copy

Do not copy advertised feature flags unless they are wired into the runtime path and covered by tests. Unused knobs create false confidence for agents.

Do not claim import graph or 2-hop symbol expansion until indexing populates dependency/symbol tables and packet generation actually consumes them.

Do not expose an apply-diff tool to agents without path containment, dry-run previews, backups or patches, and tests for traversal, ambiguity, and multi-block rollback.

Do not store raw workspace text, prompt-cache payloads, and session memory without explicit privacy controls, retention, deletion, and sensitive-file defaults.

Do not treat hash-embedding or FTS-only benchmarks as proof of semantic retrieval quality. They prove lexical relevance and compression value, not broad semantic recall.

Do not make Rust compilation mandatory for a Python tool whose runtime has pure Python fallbacks. Optional acceleration should not block editable installs or CI in minimal environments.

Do not rely on compressed code bullets for edits. Use packets to find likely files/functions, then inspect exact source before changing anything.

## Fit For Agentic Coding Lab

Fit is high as an implementation reference for a local token-efficiency subsystem. The best reusable pattern is a compact, local, FTS-first retrieval packet that agents run before expensive exploration. This maps directly to Agentic Coding Lab goals around reducing file-read bloat and preserving context for longer workflows.

The repo should not be adopted as-is. The compression core is worth borrowing, but the LSP-like claims, configuration loader, diff protocol, packaging, privacy policy, and benchmark methodology need tightening. A local adaptation should keep the SQLite/FTS/cache/session architecture, then add stronger config plumbing, source-aware privacy filters, prompt-injection handling for retrieved content, and invariant tests that prove exact code/tool/error spans are preserved when needed.

The most useful artifact candidate is a project-local `context-packet` tool: index selected paths, run BM25-first retrieval with optional vectors, produce top-3 cited chunks plus telemetry, and force exact file reads for final edits. A second artifact candidate is a prompt guard that detects raw pasted corpora and redirects the user or agent to the packet tool.

## Reviewed Paths

- `/tmp/myagents-research/madhan230205-token-reducer/README.md`: positioning, install paths, feature claims, config examples, zero-dependency mode, architecture summary, and local-first/privacy claims.
- `/tmp/myagents-research/madhan230205-token-reducer/pyproject.toml`: package metadata, build backend, optional extras, CLI script entrypoint, pytest/ruff/mypy settings, and dependency surface.
- `/tmp/myagents-research/madhan230205-token-reducer/settings.json`: runtime/default claims, token budgets, retrieval knobs, prompt guard settings, LSP feature flags, ANN settings, and cache settings.
- `/tmp/myagents-research/madhan230205-token-reducer/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`: Claude plugin and marketplace metadata.
- `/tmp/myagents-research/madhan230205-token-reducer/commands/token-reducer.md`: slash command contract, primary command, allowed tools, retrieval/compression policy, and notes.
- `/tmp/myagents-research/madhan230205-token-reducer/skills/token-reducer/SKILL.md` and `skills/token-reducer/references/*.md`: token-reducer workflow, tuning guidance, self-test command, and Context7 integration note.
- `/tmp/myagents-research/madhan230205-token-reducer/agents/*.md`: context-compressor, hybrid-retriever, noise-chunker, and se-ops-delegate agent instruction stubs.
- `/tmp/myagents-research/madhan230205-token-reducer/hooks/userprompt_guard.py` and `hooks/hooks.json`: prompt-size guard, auto-compression path, turn reminders, hook registration, and local state handling.
- `/tmp/myagents-research/madhan230205-token-reducer/scripts/context_pipeline.py`: backward-compatible CLI entrypoint.
- `/tmp/myagents-research/madhan230205-token-reducer/scripts/token_reducer/cli.py`: Typer commands for index, query, run, compress-raw, self-test, benchmark, benchmark-full, sync, gc, and stats.
- `/tmp/myagents-research/madhan230205-token-reducer/scripts/token_reducer/config.py` and `plugin_settings.py`: constants, extension filters, retrieval thresholds, scoring weights, and actual settings loader behavior.
- `/tmp/myagents-research/madhan230205-token-reducer/scripts/token_reducer/chunker.py`: file collection, noise filtering, text/code chunking, tree-sitter integration, regex fallback, import/call extraction, and Rust fallback hooks.
- `/tmp/myagents-research/madhan230205-token-reducer/scripts/token_reducer/db.py`: SQLite schema, indexing, query/session caches, file dependency and symbol functions, stats, sync helpers, and garbage collection.
- `/tmp/myagents-research/madhan230205-token-reducer/scripts/token_reducer/embeddings.py`: hash, sentence-transformer, ONNX embedding paths and fallback behavior.
- `/tmp/myagents-research/madhan230205-token-reducer/scripts/token_reducer/ann.py`: HNSW/FAISS build/query artifacts and index fingerprint validation.
- `/tmp/myagents-research/madhan230205-token-reducer/scripts/token_reducer/retriever.py`: adaptive retrieval tiers, FTS/BM25 retrieval, vector retrieval, RRF/weighted reranking, and query embedding cache.
- `/tmp/myagents-research/madhan230205-token-reducer/scripts/token_reducer/compressor.py`: TextRank, code signature extraction, chunk merging, budget packing, packet construction, and token metrics.
- `/tmp/myagents-research/madhan230205-token-reducer/scripts/token_reducer/models.py`: packet, candidate, retrieval, cache, session memory, and hash/path models.
- `/tmp/myagents-research/madhan230205-token-reducer/scripts/apply_diff.py`: SEARCH/REPLACE and AST-targeted patch protocol, transaction behavior, and path-handling risk.
- `/tmp/myagents-research/madhan230205-token-reducer/src/lib.rs` and `Cargo.toml`: optional PyO3 acceleration crate.
- `/tmp/myagents-research/madhan230205-token-reducer/tests/*.py`: unit and CLI integration coverage for chunking, DB/cache/session, embeddings, indexing/querying, benchmark, and CLI error handling.
- `/tmp/myagents-research/madhan230205-token-reducer/evals/evals.json`: two lightweight expected-output scenarios for packet generation and cache/session telemetry.
- `/tmp/myagents-research/madhan230205-token-reducer/BENCHMARK.md`, `CHANGELOG.md`, `Makefile`, `requirements-optional.txt`, `.mcp.json`, and `.github/workflows/*.yml`: benchmark claims, release history, dev commands, optional dependency list, Context7 MCP config, CI/publish metadata.
- Git metadata from the local checkout: main branch, clean status before local verification, remote URL, last five commits, exact reviewed commit, and latest commit message/date.
- `https://api.github.com/repos/Madhan230205/token-reducer`: current repository metadata, stars, forks, license, topics, open issues, default branch, creation/update/push timestamps, and description.

## Excluded Paths

- `/tmp/myagents-research/madhan230205-token-reducer/.git/`: VCS internals. Used only through Git commands for commit, branch, remote, log, and status evidence.
- `/tmp/myagents-research/madhan230205-token-reducer/Cargo.lock`: dependency lockfile for the optional Rust extension. Reviewed only enough to confirm it exists; dependency source internals were not audited.
- Runtime artifacts created during local verification under `/tmp/myagents-research`, including `token-reducer-venv`, `pip-cache`, `token-reducer-review-run.db`, ANN/cache directories, `.pytest_cache`, and `__pycache__`: generated verification state, not source.
- Binary or vendored dependency internals: none were present in the tracked source tree. Optional third-party packages installed into the temporary venv were not reviewed as source.
- GitHub issue bodies and release-intro prose under `.github/issue-bodies/` and `.github/release-intro.md`: release/project-management copy, not runtime token-efficiency behavior.
- Full legal analysis of `LICENSE`: license type was recorded as MIT from repo metadata; legal text was not reviewed beyond that.
