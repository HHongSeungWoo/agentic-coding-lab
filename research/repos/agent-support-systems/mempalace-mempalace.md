# MemPalace/mempalace

- URL: https://github.com/MemPalace/mempalace
- Category: agent-support-systems
- Stars snapshot: 51,972 (GitHub REST API, captured 2026-05-12)
- Reviewed commit: 68319dc0d00ce1633563ba660e24991693178980
- Reviewed at: 2026-05-12T11:32:57+09:00
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong in-scope local-first memory layer for agents. Best ideas are raw-evidence storage, bounded wake-up context, hybrid retrieval with compact source-level hints, query contamination cleanup, explicit write audit logs, and coding-agent hooks. Do not treat the benchmark headlines as production-path proof without checking each harness.

## Why It Matters

MemPalace is directly relevant to agent memory research because it tries to solve the practical problem coding agents keep hitting: useful prior context lives in old chats, tool output, project files, decisions, and facts, but dumping all of that into the prompt is too expensive and too noisy.

The repo is useful because it is not only a prompt convention. It has a Python package, CLI, Chroma-backed memory store, MCP server, knowledge graph, coding-agent hooks, benchmark harnesses, tests, and operational repair/sync paths. The core design preference is also clear: preserve raw/verbatim source evidence first, then layer optional structure and compact recall on top.

For Agentic Coding Lab, the strongest value is the combination of capture, retrieval, and context budgeting: mine project and conversation data locally, expose search and write tools over MCP, inject small wake-up context, and let an agent query deeper only when needed.

## What It Is

MemPalace is a Python package (`mempalace` 3.3.5 at the reviewed commit) for local-first AI memory. It stores drawers as original text chunks in a ChromaDB collection, stores compact closet lines in a second Chroma collection, and stores temporal relationship facts in SQLite through `KnowledgeGraph`.

The main surfaces are:

- `mempalace` CLI commands for init, mining, searching, wake-up context, sync, repair, and MCP setup.
- File and conversation miners for project files, Claude/Codex/Gemini/ChatGPT/Slack exports, and plain text.
- An MCP server exposing memory search, drawer add/update/delete/list/get, taxonomy/status, knowledge graph operations, diary operations, hook settings, and reconnect/status tools.
- Hook scripts and Python hook handlers for Claude Code and Codex stop/precompact/session-start style memory capture.
- Benchmark harnesses for LongMemEval, LoCoMo, ConvoMem, MemBench, and small-model routing/extraction evals.

The repo positions itself as "zero API calls" for the raw retrieval path. That is true for the default local Chroma retrieval and heuristic extractors. Some init/refinement and reranking paths can call local Ollama, OpenAI-compatible endpoints, or Anthropic when the user enables them.

## Research Themes

- Token efficiency: The memory stack is explicitly layered. L0 identity is a small text file, L1 "essential story" is capped around a few thousand characters, L2 is scoped room recall, and L3 is deeper semantic search. Closets are compact source-level pointer lines used as ranking hints, not full context dumps. MCP search caps limits and returns snippets plus metadata instead of all memory.
- Context control: Wings, rooms, halls, people/projects, source files, timestamps, and knowledge graph filters create multiple scoping axes. `wake_up` returns bounded L0/L1 context, while `search_memories` can filter by wing/room and uses closet boosts plus direct drawer retrieval. Query sanitization trims polluted agent prompts back toward the actual question before retrieval.
- Sub-agent / multi-agent: This is not a multi-agent orchestrator. It supports agent workflows by exposing MCP tools, agent diary capture, hook-based transcript mining, and an "AAAK"/Palace Protocol telling agents to search before responding and save after sessions. There is no durable agent registry or coordination protocol comparable to a task scheduler.
- Domain-specific workflow: The project maps memory into wings/rooms/halls, supports per-project `mempalace.yaml`, detects rooms through keywords and optional LLM refinement, and has a draft source-adapter plugin spec. Coding-agent support is concrete: Claude Code and Codex JSONL normalization, tool-use/tool-result capture, stop/precompact hooks, and transcript backfill commands.
- Error prevention: The code has many defensive seams: path/name sanitizers, per-palace locks, deterministic IDs, idempotent mining, Chroma HNSW corruption checks, SQLite/BM25 fallback when vector indexes are unhealthy, MCP stdout protection, WAL logging for writes, protocol-version handling, and tests for prompt-contaminated queries. Correctness of extracted memories and facts still depends on heuristics or LLM output where those paths are used.
- Self-learning / memory: This is the core fit. The system stores raw drawers, optional extracted general memories, compact closets, temporal KG triples, daily diary entries, and known-entity registries. Updates are explicit: drawer update/delete tools, sync prune for gitignored/missing files, KG invalidation, and repair/rebuild flows.
- Popular skills: MCP memory tools, local RAG, agent diary writing, transcript mining, prompt contamination sanitization, temporal facts, local-first privacy claims, LongMemEval/LoCoMo-style retrieval evaluation, and hook-driven coding-agent memory.

## Core Execution Path

Default project-file ingest starts in the CLI `mine` path and routes to `mempalace/miner.py`. The miner loads `mempalace.yaml` if present, scans readable files while respecting `.gitignore`, skips symlinks and large files, detects wing/room/hall metadata, chunks files deterministically, purges stale chunks for changed sources, and upserts drawers in batches. It also builds closet lines from source text and upserts those into the closet collection.

Conversation ingest uses `mempalace/convo_miner.py` plus `mempalace/normalize.py`. Normalization supports Claude Code JSONL, OpenAI Codex CLI JSONL, Gemini CLI JSONL, Claude.ai JSON, ChatGPT `conversations.json`, Slack export JSON, and plain text. Claude/Codex tool blocks are preserved or serialized into transcript text, while known system-reminder and hook-output noise is stripped using line-anchored patterns. The conversation miner chunks user/assistant exchanges, can run a heuristic general-memory extractor, purges stale drawers, and writes deterministic IDs.

The message-granular sweeper in `mempalace/sweeper.py` is a second ingest path for Claude Code JSONL. It writes one drawer per user/assistant message keyed by `(session_id, message_uuid)`, uses max timestamp per session as a cursor, and handles same-timestamp crash recovery by reprocessing the cursor boundary and deduping by deterministic ID. Its own comments note an important gap: primary miners do not universally stamp `session_id` and timestamp metadata, so sweeper dedupe does not span all ingest modes.

Search runs through `mempalace/searcher.py`. Direct drawer vector search is the floor. Optional hybrid ranking combines vector similarity and BM25 over candidates. Closet search is used as a source-level boost; it cannot hide a directly relevant drawer. If a boosted source is found, the code can hydrate the best keyword chunk plus neighboring chunks from the same source. When Chroma/HNSW is unhealthy or vector search is disabled, a SQLite FTS/BM25 fallback can return usable results without opening the vector index.

MCP access runs through `mempalace/mcp_server.py`. Requests are JSON-RPC over stdio, stdout is protected so accidental prints do not corrupt protocol output, tool arguments are filtered/coerced against schemas, and write tools log to a local WAL. Search sanitizes queries, validates taxonomy filters, caps limits, and retries transient index errors. Drawer `get` strips full source paths down to basenames before returning metadata.

Knowledge graph operations use `mempalace/knowledge_graph.py`. Facts are triples with temporal validity (`valid_from`, `valid_to`) and provenance fields. Adds are idempotent for matching current triples, invalidation closes old triples, and timeline/stat/query helpers expose current and historical facts. This graph is separate from Chroma and stored in SQLite.

Hook integration mines active coding-agent sessions. Shell hooks and Python handlers trigger on stop/precompact/session-start style events, count human turns, validate transcript paths, and mine transcript directories in conversation mode. In verbose mode a stop hook can block and ask the agent to write a diary; in silent mode it mines in the background.

## Architecture

The storage model has four main layers:

- Drawers: ChromaDB documents containing source chunks or explicit memory entries. Metadata includes wing, room, hall, source file, chunk index, timestamps, ingest mode, and sometimes entities.
- Closets: compact pointer lines in a second Chroma collection. They summarize topics/entities and point back to drawer IDs or source files. Current search uses them as ranking boosts and hydration hints.
- Knowledge graph: SQLite entities and temporal triples with provenance. It handles explicit relationship facts and invalidation rather than general text retrieval.
- Local config/state: JSON config under `~/.mempalace`, known entity registries, hook state, WAL logs, diary state, and optional per-project config files.

The backend contract is deliberately pluggable. `mempalace/backends/base.py` defines typed collection/backend operations and `mempalace/backends/registry.py` discovers entry points. The built-in Chroma backend adds practical hardening: per-path client cache invalidation, HNSW stale-metadata quarantine, safe unpickling for Chroma index metadata, single-threaded HNSW metadata, BLOB sequence migration checks, and capacity-status probes.

The context stack in `mempalace/layers.py` is intentionally separate from search. `wake_up` reads identity and essential-story context without forcing deep retrieval. L2 room recall and L3 semantic search are available but not stuffed into every session by default.

The source adapter abstraction under `mempalace/sources/` is scaffolding rather than the current ingest engine. RFC 002 defines source references, route hints, privacy classes, provenance, and transformation declarations, but the first-party miners still run through their older paths. This is a useful design direction but not yet the actual production execution path.

## Design Choices

MemPalace chooses raw evidence over lossy summaries. The README says it stores verbatim text, and the implementation generally backs that up for drawers: project chunks and conversation chunks preserve source text or normalized transcript text. The caveat is important: conversation normalization strips selected system/tool chrome, Slack roles can be positional, and RFC 002 documents transformations such as invalid UTF-8 replacement and tool-chrome removal.

Closets are treated as hints, not gates. This is the right choice for coding-agent memory because compact summaries can be wrong or incomplete. Tests explicitly cover the case where misleading closets must not suppress a direct drawer hit.

Local-first is the default, not an absolute guarantee. The raw path uses local Chroma embeddings and local files. Optional LLM init/refinement/rerank providers can send content away, so the CLI prints an external-API warning and requires consent when an env-sourced API key would be used against an external endpoint.

Writes are auditable but not reversible by default. MCP add/update/delete/sync operations write WAL events with sensitive fields redacted. That helps review and recovery workflows, but delete is still exposed as an irreversible operation at the tool surface.

Operational health is treated as part of memory quality. Repair, sync, HNSW capacity checks, vector-disabled flags, SQLite fallback, locks, and idempotent IDs show awareness that long-lived memory stores fail in boring ways.

The benchmark story is intentionally retrieval-centric. The repo reports recall and NDCG over retrieval tasks, not end-to-end answer quality for a coding agent. The docs are sometimes careful about that distinction; some historical benchmark docs are looser and should not be repeated unqualified.

## Strengths

The raw-first architecture is practical. Keeping source evidence searchable avoids many problems caused by over-compressed "memories" that lose the exact quote, code snippet, tool output, or decision wording.

The context layering maps well to coding agents. A small wake-up pack plus on-demand search is a better shape than full session replay.

Hybrid retrieval is implemented defensibly. Direct drawers remain visible, BM25 helps exact terms, closets provide source-level boosts, and SQLite fallback gives degraded service when vector search is unhealthy.

The MCP server is substantial. It covers read, write, update, deletion, taxonomy, status, KG facts, timelines, diaries, and reconnect behavior, with stdio protection and schema-based argument filtering.

The privacy posture is better than many memory repos. Config files get restrictive permissions where possible, external LLM use is warned/gated, WAL redacts content/query fields, `tool_get_drawer` strips full source paths, and path/name sanitizers are tested.

The test suite targets real failure modes: contaminated agent prompts, HNSW/index failures, MCP protocol behavior, stdout pollution, idempotent sweeps, same-timestamp crash recovery, KG invalidation, gitignore-aware sync, hook path validation, and external-provider consent.

The benchmark artifacts are reproducible enough to inspect. Harness code and committed result files make it possible to distinguish raw Chroma recall, heuristic hybrid recall, held-out results, and LLM rerank results.

## Weaknesses

The "verbatim always" story has caveats. Project chunks are close to raw, but conversation normalization strips selected noise and can serialize tool blocks. RFC 002 is more honest than the marketing copy: transformations exist and should be declared.

Raw storage creates privacy risk. Claude/Codex tool payloads and transcript text can include secrets, credentials, proprietary code, stack traces, and user data. The repo has local-first defaults and some redaction in WAL, but I did not find a robust default secret/PII redaction pass for stored drawers.

The benchmark harnesses are not the same as the production memory path. LongMemEval raw mode builds a fresh Chroma collection per question over benchmark sessions. Hybrid modes add dataset-specific boosts, temporal/name heuristics, synthetic preference docs, and in v4 explicitly targeted final misses. These are useful retrieval experiments, not proof that the CLI miner plus MCP search will get the same numbers on arbitrary coding-agent memory.

Some docs are stale or inconsistent. `docs/CLOSETS.md` still describes closet-first behavior that differs from current search code, `docs/schema.sql` does not match the current KG database shape, and README/module docs disagree on MCP tool count. Website docs are sometimes more accurate than root/docs pages.

The source adapter spec is ahead of implementation. The contract is good, especially around privacy classes and transformation declarations, but first-party miners have not been migrated to it.

L1 "essential story" quality depends on metadata that is often absent. In `layers.py`, missing importance-like fields default to the same score, so ordering can become arbitrary for raw-mined memories.

Knowledge graph extraction and fact checking are conservative but shallow. The KG itself supports temporal facts, but automatic relationship parsing and contradiction checks use narrow regex/heuristic surfaces unless a separate LLM-assisted flow adds better structure.

Hooks are useful but not a complete governance boundary. They validate paths and avoid obvious shell injection patterns, but once a transcript is considered valid the system can persist raw tool results and assistant/user text.

## Ideas To Steal

Use raw evidence as the durable base layer. Store exact snippets with provenance, then add summaries, graphs, and compact indexes as secondary aids.

Make compact indexes advisory. Closet-like source hints should boost and hydrate results, never be the only route to relevant memory.

Adopt a layered wake-up protocol. Identity, essential facts, scoped recall, and deep search should be separate context budgets with separate triggers.

Sanitize agent queries before retrieval. Long tool outputs, system prompts, and chat wrappers can drown out the real question; the query sanitizer is small and high-leverage.

Keep write logs for memory mutations. A redacted WAL around MCP writes is a practical minimum for debugging agent-created memory and accidental deletion/update events.

Build degraded retrieval paths. Vector indexes fail; a SQLite/FTS/BM25 fallback and index health probes make memory more dependable than pure Chroma calls.

Use deterministic IDs and idempotent ingest. This is especially important for hooks, transcript backfills, and crash recovery.

Treat external LLM endpoints as a data-flow decision. The endpoint-locality heuristic plus env-key consent gate is a useful pattern for privacy-sensitive init/refinement flows.

## Do Not Copy

Do not repeat the benchmark numbers as agent-memory accuracy. Say "retrieval recall under this harness" and keep the raw, hybrid, held-out, and LLM-rerank paths separate.

Do not copy dataset-specific hybrid boosts into a coding-agent product without measuring generalization. Name/quote/preference/temporal heuristics can help, but v4's history shows how easily they become benchmark-tuned.

Do not store raw tool outputs by default without secret scanning, retention policy, and scoped deletion. Local storage still leaks if the local memory store is compromised or later exposed through MCP.

Do not rely on agent compliance with the Palace Protocol for safety. Agents may forget to search, may write bad memories, and may expose irrelevant results unless the tool layer enforces budgets and policy.

Do not embed compressed AAAK diary text as-is. The code itself notes compressed diary entries hurt search quality and should be expanded before embedding.

Do not let stale docs become the contract. The actual code should be treated as source of truth for closets, KG schema, MCP tool count, and current agent features.

Do not use raw regex entity extraction as authoritative memory. It is fine for hints and bootstrapping, not for critical facts.

## Fit For Agentic Coding Lab

Fit is high. MemPalace is one of the closer matches to a coding-agent memory substrate because it has local transcript capture, Codex/Claude normalization, hooks, MCP tools, bounded wake-up context, raw provenance, and retrieval benchmarks.

The most applicable architecture for this repo would be a smaller version:

- Raw project/chat/tool evidence with deterministic IDs and source provenance.
- Compact, ID-addressable context packs at session start.
- Explicit search protocol for deeper recall.
- Advisory source-level indexes like closets.
- Temporal facts for decisions, preferences, project constraints, and "changed because" relationships.
- Secret/PII policy at ingest before raw storage.
- Per-repo/per-branch/per-task scoping rather than one global palace.

MemPalace is less useful as a drop-in dependency if the goal is strict governance. It lacks built-in authorization, encryption, default secret redaction, and a mature source-adapter privacy contract in the actual ingest path. It is very useful as a pattern library for memory lifecycle, context budgeting, agent hooks, and retrieval fallback.

## Reviewed Paths

- `README.md`: positioning, local-first claims, architecture overview, quickstart, benchmark claims, MCP and KG feature summary.
- `mempalace/README.md`: module map, runtime architecture, CLI/miner/search/MCP/KG/layers descriptions.
- `pyproject.toml`: package version, scripts, dependencies, backend entry points, dev/test configuration.
- `SECURITY.md`: supported versions and vulnerability reporting policy.
- `mempalace/config.py`: default paths, config permissions, env overrides, name/path/content sanitizers, topic and hall defaults.
- `mempalace/cli.py`: init/mine/search/wake-up/repair/sync command flow, external LLM warning and consent gate.
- `mempalace/miner.py`: project-file scanning, gitignore behavior, chunking, room/hall/entity metadata, stale purge, deterministic upsert, closet creation.
- `mempalace/convo_miner.py` and `mempalace/normalize.py`: conversation export normalization, exchange chunking, source format support, noise stripping, raw/tool-content handling.
- `mempalace/sweeper.py`: message-granular Claude JSONL ingest, cursoring, crash recovery, deterministic IDs, known dedupe limitation.
- `mempalace/palace.py`: collection access, closet line construction/upsert, mined-file checks, palace and source locks.
- `mempalace/searcher.py`: drawer search, hybrid vector/BM25 ranking, closet boosts, neighbor hydration, SQLite/BM25 fallback.
- `mempalace/layers.py`: L0/L1/L2/L3 wake-up and recall context stack.
- `mempalace/mcp_server.py`: MCP tools, JSON-RPC handling, schema filtering, query sanitization, WAL logging, vector-health fallback, KG/diary/drawer operations.
- `mempalace/knowledge_graph.py`: SQLite temporal entity/triple store, provenance, invalidation, timeline/stats/query behavior.
- `mempalace/diary_ingest.py`: daily diary ingest, state tracking, closet rebuild behavior.
- `mempalace/backends/base.py`, `mempalace/backends/chroma.py`, `mempalace/backends/registry.py`: backend interface, Chroma hardening, entry-point discovery.
- `mempalace/query_sanitizer.py`, `mempalace/general_extractor.py`, `mempalace/fact_checker.py`, `mempalace/embedding.py`, `mempalace/sync.py`, `mempalace/repair.py`, `mempalace/llm_client.py`: contamination cleanup, heuristic memory extraction, conservative contradiction checks, embedding provider selection, gitignore-aware pruning, Chroma repair, provider privacy classification.
- `mempalace/sources/base.py` and `docs/rfcs/002-source-adapter-plugin-spec.md`: draft adapter model, privacy classes, route hints, and transformation declarations.
- `docs/CLOSETS.md`, `docs/schema.sql`, `website/concepts/memory-stack.md`, `website/concepts/knowledge-graph.md`, `website/concepts/agents.md`, `website/reference/benchmarks.md`: conceptual docs, benchmark docs, and noted doc drift.
- `hooks/README.md`, `hooks/mempal_save_hook.sh`, `hooks/mempal_precompact_hook.sh`, `examples/mcp_setup.md`: coding-agent hook setup, stop/precompact behavior, MCP setup.
- `benchmarks/longmemeval_bench.py`, `benchmarks/locomo_bench.py`, `benchmarks/convomem_bench.py`, `benchmarks/membench_bench.py`, `benchmarks/BENCHMARKS.md`, `benchmarks/model_eval/*`: retrieval/eval harnesses, committed result summaries, small-model routing/extraction eval design.
- Representative committed benchmark results: LongMemEval raw, LongMemEval hybrid held-out, LongMemEval hybrid+LLM rerank, LoCoMo raw/hybrid, ConvoMem raw, and MemBench hybrid result files were aggregated rather than read row-by-row.
- Tests sampled across `tests/test_hybrid_search.py`, `tests/test_mcp_server.py`, `tests/test_query_sanitizer.py`, `tests/test_knowledge_graph.py`, `tests/test_mcp_stdio_protection.py`, `tests/test_config.py`, `tests/test_config_extra.py`, `tests/test_sweeper.py`, `tests/test_sync.py`, `tests/test_hooks_cli.py`, `tests/test_llm_client.py`, and privacy-related sections of `tests/test_corpus_origin_integration.py`.

## Excluded Paths

- `.git/`: repository metadata, not implementation or documentation.
- `.github/`: CI/workflow and repository automation. Not needed to understand memory architecture or benchmark claims.
- `uv.lock`: generated dependency lockfile. Dependency intent was reviewed in `pyproject.toml`.
- `assets/*.png`, `assets/*.svg`, `website/public/*`, `website/static/*`, video/media files, logos, screenshots, and icons: binary or UI/media assets, not memory execution logic.
- `landing/**` and website UI implementation files: marketing/presentation layer. I reviewed relevant website concept/reference markdown content, not the UI shell.
- Large benchmark result JSON/JSONL/CSV/report files: treated as generated outputs. I aggregated the key committed result files for metrics and read harness code/docs rather than every row.
- `benchmarks/model_eval/results/**` and generated benchmark reports: output artifacts. The model-eval README, datasets README, runner, metrics, and task design were reviewed instead.
- `mempalace/i18n/*.json`: localization data. Relevant behavior was covered in code/tests, not translated strings.
- `integrations/openclaw/SKILL.md`: adjacent integration guidance, not core MemPalace memory architecture.
- Long fixtures and sample corpora under tests/benchmarks/examples: reviewed representative tests and harnesses, not every sample datum.
- Build, packaging, and release metadata such as `CHANGELOG.md`, `MISSION.md`, `ROADMAP.md`, `MANIFEST.in`, and legal/governance files beyond `SECURITY.md`: useful project context but not needed for the assigned technical review focus.
