# seqis/AI-grep

- URL: https://github.com/seqis/AI-grep
- Category: token-efficiency
- Stars snapshot: 77 (GitHub REST API repository search in `research/index.md`, captured 2026-05-11)
- Reviewed commit: b512548cf3ae90983631d0d2ca359a183b25d87c
- Reviewed at: 2026-05-12T12:28:58+09:00
- Status: reviewed
- Scope fit: in-scope
- Verdict: Useful in-scope reference for a small local retrieval CLI that teaches agents to orient, locate, then fetch exact line ranges instead of reading whole files. Best patterns are `relevant` as paths-plus-scores, `get --lines`, `context --line`, `outline`, `toc`, auto incremental indexing, and JSON outputs. Do not copy the implementation as-is: document extraction is not wired into the indexer, mounted sources are recorded but not searched, `.searchignore` is created in a path the indexer does not read, `--force` is parsed but ignored, root-level files can appear twice in combined results, and there is no test suite.

## Why It Matters

AI-grep targets a concrete coding-agent failure mode: an assistant burns context by opening broad file sets before it knows which files matter. The repo's workflow is exactly the right shape for token efficiency: first get coarse stats and a table of contents, then rank candidate files, then read specific lines or sections.

For Agentic Coding Lab, this is most valuable as a small-tool interaction pattern rather than a mature retrieval backend. It shows how far a local SQLite FTS5 plus ripgrep CLI can go before semantic embeddings or an MCP server are needed.

## What It Is

AI-grep is a single-file Python CLI (`ai-grep`) plus local modules under `vault_lib/`. It is meant to be copied into a project, run from that project root, and initialize a local `SEARCH/` directory containing a SQLite database, config file, manifest, and ignore file.

The CLI exposes setup, indexing, status, search, line retrieval, context retrieval, file listing, stats, timeline, tags, outline, table of contents, TF-IDF related-file search, duplicate detection, link validation, symbol references, mount/source commands, export, clipboard, editor open, query history, diff, grep-context, and `relevant`.

There is no root `pyproject.toml`, `setup.py`, package manifest, tests directory, or example fixture directory. The executable imports modules directly by inserting its own directory into `sys.path`.

## Research Themes

- Token efficiency: High relevance. The core idea is not compression but retrieval scoping: `stats`, `toc`, `relevant`, snippets, line ranges, context windows, outlines, and exact symbol refs reduce raw file reads.
- Context control: Medium to high relevance. Agents can choose `--top`, `--limit`, `--lines`, `--around`, raw versus JSON output, and outline-only views. There is no hard token budget, tokenizer-aware counting, or output byte cap.
- Sub-agent / multi-agent: Low relevance. The repo has no subagent protocol. It could be used by a navigator subagent, but the implementation does not model delegation or handoff.
- Domain-specific workflow: Medium relevance for coding and note vaults. Python, JavaScript, TypeScript, Markdown, shell, JSON, YAML, HTML, and CSS get basic type labels and outlines. Symbol refs are regex word-boundary matches, not AST references.
- Error prevention: Medium relevance. The line-range retrieval path encourages exact inspection before edits, and `validate` checks DB setup. There is no edit verification loop, no test harness, and no source provenance beyond file paths and line numbers.
- Self-learning / memory: Low relevance. The repo defines query history storage, but the reviewed CLI never calls `log_query` from search, so history is not active in the main path.
- Popular skills: Low relevance as a skill system. The README includes assistant-instruction snippets that tell agents to use AI-grep before reading files, but the repo does not ship a Codex/Claude skill package.

## Core Execution Path

1. `./ai-grep setup` calls `run_setup(Path.cwd())`, checks dependencies, creates `SEARCH/.vault.db`, `SEARCH/config.json`, `SEARCH/.vault-manifest.json`, and `SEARCH/.searchignore`, then runs `index_files()` unless `--no-index` is supplied.
2. `index_files(root_path, db_path)` creates the manifest table, merges default excludes, a root-level `.searchignore` if present, and config exclude rules, then scans `root_path.rglob("*")`.
3. For each non-excluded file, the indexer hashes bytes, compares against existing DB hashes, and inserts only added or changed files. Content is read as UTF-8 or Latin-1 text, stored in `files.content`, indexed into `files_fts`, and section metadata is extracted into `file_sections`.
4. `./ai-grep search <query>` checks whether the manifest is older than five minutes. If stale, it silently re-runs incremental indexing and then calls `search_combined()`.
5. `search_combined()` runs SQLite FTS5 BM25 search and ripgrep JSON search, deduplicates by a path suffix heuristic, merges scores with 60% FTS, 40% ripgrep, and a 0.2 bonus when both sources match.
6. `./ai-grep relevant <query> --top N` calls the same combined search and strips results down to `filepath` and `score`. This is the tightest token-saving command.
7. `./ai-grep get <file> --lines N-M` and `./ai-grep context <file> --line N --around M` read content from the SQLite DB and return only requested slices.
8. `outline`, `toc`, `refs`, `related`, `duplicates`, and `links` run over indexed DB content. They are useful discovery tools, but they are heuristic and not parser-grade.
9. `mount`, `sources`, and `unmount` manage a `sources` table, but the CLI index/search path still uses `Path.cwd()` and does not call `get_all_source_paths()` or set `source_id`, so mounted directories are not actually part of the main search path.

## Architecture

The architecture is intentionally small and local:

- `ai-grep`: CLI entrypoint, argument parser, setup/index/search dispatch, JSON printing, and command handlers.
- `vault_lib/setup.py`: dependency checks, optional installation prompts, SQLite schema creation, config and ignore file creation, setup validation.
- `vault_lib/index.py`: incremental rglob scanning, exclusion checks, content hashes, text reads, FTS writes, manifest writes, section extraction.
- `vault_lib/search.py`: FTS5 search, ripgrep search, combined ranking, snippets, date/section context enrichment, diff, grep-context, and `relevant`.
- `vault_lib/analysis.py`: stats, timeline, tags, outline, table-of-contents extraction.
- `vault_lib/similarity.py`: pure-Python TF-IDF related files, duplicate checks, wiki/Markdown link validation, regex symbol refs.
- `vault_lib/sections.py`: section detection for Markdown, text, logs, and common code files.
- `vault_lib/sources.py`: schema and commands for mounted directories, currently not integrated into indexing.
- `vault_lib/export.py`: JSON/CSV/Markdown export, clipboard copy, editor launch, and query history helpers.
- `vault_lib/file_extract.py`: docx/xlsx/pdf/text extraction utilities. The main indexer does not use this module, so its richer extraction path is dead in normal CLI use.

## Design Choices

The strongest design choice is workflow framing. The README teaches an agent to orient with `stats` and `toc`, locate with `relevant` and `refs`, retrieve with `get --lines` and `context`, and analyze with `related` and `outline`. That maps cleanly to token-efficient coding-agent behavior.

The tool stores full file content in SQLite. That makes later line-range reads fast and independent of filesystem reads, but it duplicates source content and can store secrets unless exclude rules are correct.

Search uses both FTS5 and ripgrep. FTS gives ranked lexical search with stemming; ripgrep gives exact/regex recall and works when FTS has problems. Combining the two is pragmatic, but the dedupe key uses the last two path components, which fails for root-level files because relative `README.md` and absolute `/tmp/project/README.md` produce different keys.

Incremental indexing is content-hash based and simple to reason about. The auto-sync threshold makes search mostly self-maintaining, but it is time-based rather than filesystem-event based.

Output shaping is command-specific rather than globally budgeted. `relevant` is compact; `search` returns snippets plus rich section metadata; `get` and `bundle` can return full content; `grep-context` can return many matches. There is no global maximum character or token cap.

Setup treats optional document dependencies as required for success. In the reviewed environment, `python-docx`, `openpyxl`, and `PyPDF2` were missing, so `setup.py --check` failed even though the core text-code search path can run without them.

## Strengths

- Clear agent-facing retrieval ladder: overview, ranking, exact slice, relationship helpers.
- `relevant` is a good primitive for token-efficient file selection because it returns only paths and scores.
- `get --lines` and `context --line` preserve exact source text while avoiding full-file reads.
- SQLite plus ripgrep keeps deployment local, cheap, and understandable.
- Incremental hashing avoids re-indexing unchanged files in normal runs.
- JSON outputs are easy for an agent or wrapper to parse.
- `outline` and `toc` provide structure without full content.
- Section metadata can attach headers, dates, and nearby context to search results, useful for notes and logs.
- The code is small enough to audit quickly and adapt into a project-local tool.

## Weaknesses

- No tests, examples, or fixtures are present. A smoke run found real drift that a small test suite would catch.
- `vault_lib/file_extract.py` supports docx/xlsx/pdf, but `index_files()` reads files through `_read_file_content()` instead, so the advertised document extraction path is not active.
- `SEARCH/.searchignore` is created by setup, but `index_files()` reads `root_path / ".searchignore"`. The generated ignore file is not used unless copied to the project root.
- Default index excludes are sparse. They skip `.git`, `SEARCH`, `__pycache__`, pyc files, and DB files, but not common media or archives. Latin-1 fallback can turn binary-ish files into garbage text instead of rejecting them.
- `./ai-grep index --force` is documented and parsed, but `cmd_index()` never passes force behavior to `index_files()`.
- Mounted sources are not searched by the main CLI path. `mount` writes metadata only; indexing still scans the current working directory.
- Combined search can duplicate root-level files because FTS stores relative paths and ripgrep returns absolute paths.
- Partial path matching in `get`, `bundle`, `context`, and helpers can select the first ambiguous match without warning.
- Query history is imported but not logged by `cmd_search`, so `history` is mostly disconnected from the search workflow.
- There is no hard token budget, byte cap, model tokenizer, or progressive truncation policy across commands.
- Security controls are limited to ignore patterns. There is no secret scanner, no prompt-injection handling for recalled text, and no privacy warning before storing full source content in SQLite.

## Ideas To Steal

- Use an "orient -> locate -> retrieve -> analyze" command taxonomy in agent instructions.
- Add a `relevant`-style command that returns only `{path, score}` for first-pass file selection.
- Make exact line-range retrieval the normal follow-up after broad ranking.
- Provide `outline` and `toc` so agents can inspect structure before opening implementations.
- Auto-refresh stale indexes before search, but report indexing warnings separately from search results.
- Store lightweight section metadata during indexing so search results can include the containing header or dated entry.
- Keep the first version local-first with SQLite and ripgrep before adding embeddings or server infrastructure.
- Include a smoke fixture that asserts no duplicate files in combined results, generated ignore paths are honored, and mounted sources actually appear in search.

## Do Not Copy

- Do not claim Office/PDF extraction unless the indexer uses the extractor in the main path.
- Do not create ignore files in one directory and read them from another.
- Do not expose `--force` or multi-source commands before they affect execution.
- Do not dedupe by a short path suffix when mixing relative and absolute paths.
- Do not treat regex symbol refs as semantic code navigation.
- Do not store full indexed source content without explicit secret and privacy boundaries.
- Do not rely on README token-savings percentages without a reproducible fixture and token counter.
- Do not make optional dependencies block core text/code indexing.

## Fit For Agentic Coding Lab

Fit is high as an interaction-design reference and medium as implementation source. AI-grep is exactly about reducing needless repository reads, and the CLI vocabulary is easy for coding agents to follow.

The best local adaptation is a hardened project search helper with the same workflow: compact file ranking, structure-only overview, exact line reads, and bounded snippets. Before adoption, fix the extractor integration, ignore-file path, force indexing, source mounting, duplicate handling, output caps, and tests.

This repo is also a useful caution: small token-efficiency tools need behavioral tests for every advertised scope-control knob. Otherwise the agent-facing docs can drift faster than the execution path.

## Reviewed Paths

- `/tmp/myagents-research/seqis-ai-grep/README.md`: public workflow, command reference, token-savings claims, integration instructions, configuration, deployment strategies, troubleshooting, and platform support.
- `/tmp/myagents-research/seqis-ai-grep/TECHNICAL_NOTES.md`: architecture notes, schema description, indexing/search strategy, limitations, extension points, and suggested testing approach.
- `/tmp/myagents-research/seqis-ai-grep/CHANGELOG.md`: release scope and command inventory for v1.0.0.
- `/tmp/myagents-research/seqis-ai-grep/ai-grep`: CLI entrypoint, command dispatch, setup/index/search/get/context/list handlers, analysis/content/source/export/history/diff/relevant surfaces, and parser behavior.
- `/tmp/myagents-research/seqis-ai-grep/vault_lib/setup.py`: dependency checks, config and ignore defaults, SQLite schema, FTS triggers, section table, validation, and setup workflow.
- `/tmp/myagents-research/seqis-ai-grep/vault_lib/index.py`: actual incremental index path, exclusion behavior, hash comparison, text reading, DB writes, manifest/staleness, and unused force implications.
- `/tmp/myagents-research/seqis-ai-grep/vault_lib/search.py`: FTS search, ripgrep search, result scoring/deduplication, section/date context enrichment, diff, grep-context, and `cmd_relevant`.
- `/tmp/myagents-research/seqis-ai-grep/vault_lib/file_extract.py`: richer text/docx/xlsx/pdf extraction path, reviewed to confirm it is not used by `index_files()`.
- `/tmp/myagents-research/seqis-ai-grep/vault_lib/analysis.py`: stats, timeline, tags, outline, and table-of-contents output shaping.
- `/tmp/myagents-research/seqis-ai-grep/vault_lib/similarity.py`: TF-IDF related-file search, duplicate detection, link validation, and regex symbol references.
- `/tmp/myagents-research/seqis-ai-grep/vault_lib/sections.py`: section and date extraction for Markdown, text, logs, and code.
- `/tmp/myagents-research/seqis-ai-grep/vault_lib/sources.py`: mount/source schema and commands, reviewed to verify integration gap with indexing.
- `/tmp/myagents-research/seqis-ai-grep/vault_lib/export.py`: export, clipboard, editor open, and query history helpers.
- `/tmp/myagents-research/seqis-ai-grep/vault_lib/__init__.py`: package metadata and stated module responsibilities.
- Local smoke check with a temporary two-file project: direct module setup/index/search path worked for text files, but combined search returned both relative and absolute entries for root-level `README.md`, confirming the dedupe issue.
- Absence checks for tests/specs/package metadata: no dedicated test files, example fixture directory, root package manifest, or lockfile were present.

## Excluded Paths

- `/tmp/myagents-research/seqis-ai-grep/.git/`: VCS internals. Used only to record reviewed commit and recent history.
- `/tmp/aigrep-smoke-*`: temporary smoke-test directories generated during review. Excluded because they are not source files from the repository.
- Generated runtime `SEARCH/` directories: excluded as runtime database/config output rather than source. The source code that creates and reads them was reviewed.
- Vendor/dependency trees such as `node_modules`, virtualenvs, or vendored packages: none were present in the reviewed checkout.
- Binary/media/UI-only assets: none were present in the reviewed checkout.
