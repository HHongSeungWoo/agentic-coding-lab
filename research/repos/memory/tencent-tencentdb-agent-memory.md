# Tencent/TencentDB-Agent-Memory

- URL: https://github.com/Tencent/TencentDB-Agent-Memory
- Category: memory
- Stars snapshot: 4,424 (GitHub REST API, captured 2026-05-29)
- Reviewed commit: 438869bec84711fb09b12185d46702d98eeaf90e
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong local-first long-term memory architecture for agents. The L0 raw log, L1 structured memories, L2 scene blocks, and L3 persona stack is worth reusing as a pattern, especially with hybrid retrieval and cache-aware recall injection. Do not adopt wholesale without stronger privacy defaults, hard tool budgets, and more visible core test coverage.

## Why It Matters

TencentDB-Agent-Memory is one of the more complete public examples of local long-term agent memory. It does more than vector search over chat history: it preserves raw evidence, extracts typed memories, consolidates scenes into Markdown, evolves a persona profile, exposes active search tools, and can run through OpenClaw or a Hermes HTTP gateway. For an agentic coding lab, the useful part is the memory lifecycle design, not the specific OpenClaw integration.

## What It Is

The project is a TypeScript npm package and OpenClaw plugin named `@tencentdb-agent-memory/memory-tencentdb`, plus a Python Hermes provider that talks to a local Gateway. The core is host-neutral `TdaiCore`, with adapters for OpenClaw and Hermes. The default backend is local SQLite using `node:sqlite`, FTS5, and optional `sqlite-vec`; an optional Tencent VectorDB backend provides server-side dense embedding, BM25 sparse vectors, and native hybrid search. LLM calls are used for L1 extraction, L1 deduplication, L2 scene maintenance, and L3 persona generation.

## Research Themes

- Token efficiency: It separates dynamic L1 recall from stable persona and scene navigation. Per-turn memories are inserted into `prependContext`, while persona, scene navigation, and the memory tool guide go into `appendSystemContext` for better prompt-cache behavior. Version 0.3.6 also added recall character budgets. The optional offload subsystem compresses short-term tool context into Mermaid task graphs with node IDs that can drill back into raw refs.
- Context control: Recall is automatic before prompt build, persisted recall tags are stripped before message write, and the agent gets explicit tools for L1 memory and L0 conversation search. Scene navigation points the model at curated Markdown files instead of dumping all summaries. The documented "max 3 memory searches" is only advisory in tool text, so a host-level budget would still be needed.
- Sub-agent / multi-agent: This is not a multi-agent orchestrator. It has host adapters, per-session state, agent IDs, and filters that skip internal memory sessions, OpenClaw subagents, temporary sessions, and automation-style triggers.
- Domain-specific workflow: The integration is tailored for coding agents that need persistent user preferences, task facts, tool conventions, and project-specific working memory. It does not build a code-symbol index or semantic source-code graph.
- Error prevention: The implementation uses checkpoint locks, split runner and pipeline state, background-task draining before shutdown, L2/L3 backups before LLM file edits, retention safety guards, config validation, and degraded fallback paths when vector search or embedding is unavailable.
- Self-learning / memory: The main contribution is the progressive L0 -> L1 -> L2 -> L3 lifecycle. L0 is raw conversation evidence, L1 is typed durable facts, L2 is scene-level narrative memory, and L3 is a compact persona/profile view. Deduplication can store, update, merge, or skip extracted memories.
- Popular skills: Reusable skill ideas include "search durable memory before answering", "promote raw evidence into typed facts", "consolidate facts into scene notes", "update persona from scene evidence", and "drill down from summaries to raw conversation evidence".

## Core Execution Path

OpenClaw calls `before_prompt_build`, which caches the clean prompt, lazily warms embedding, and calls `TdaiCore.handleBeforeRecall`. Auto-recall searches L1 memories with keyword, embedding, or hybrid strategy, then injects dynamic `<relevant-memories>` plus stable persona, scene navigation, and tool guidance. `before_message_write` removes recall tags so injected memories are not persisted as user text.

After a successful agent turn, `agent_end` calls `handleTurnCommitted`. Auto-capture writes L0 conversation records through an atomic checkpoint lock, indexes them into the store, and notifies the pipeline scheduler. The scheduler triggers L1 extraction by warmup thresholds, every-N turns, or idle timers. L1 extraction reads new L0 messages with background context, asks the LLM for typed memories, deduplicates against existing records, writes append-only JSONL, and updates the searchable store.

L2 consolidation reads new L1 memories and lets a sandboxed LLM create, update, merge, or soft-delete Markdown scene blocks under `scene_blocks/`. It refreshes `.metadata/scene_index.json` and scene navigation. L3 persona generation periodically reads changed scenes, edits `persona.md`, and appends updated scene navigation. Agent-callable tools can search either L1 memories or L0 conversations on demand, and the Gateway exposes similar recall, capture, and search endpoints for Hermes.

## Architecture

The architecture has a small core facade, host adapters, storage backends, and a file-backed memory layout. `src/core/tdai-core.ts` coordinates initialization, recall, capture, search, session flushing, and shutdown. `index.ts` wires that core into OpenClaw hooks and tools. `src/gateway/server.ts` exposes the same operations over HTTP for Hermes clients.

The memory tiers are explicit. L0 stores raw conversations in `conversations/YYYY-MM-DD.jsonl` and in the store table `l0_conversations`. L1 stores structured records in `records/YYYY-MM-DD.jsonl` and `l1_records`, with memory types such as `persona`, `episodic`, and `instruction`. L2 stores human-readable scene files in `scene_blocks/*.md` plus `.metadata/scene_index.json`. L3 stores `persona.md` with appended scene navigation.

The store abstraction supports vector search, FTS search, native hybrid search, sparse vectors, L0 and L1 upserts, profile sync, and reindexing. SQLite is the local default and can still store metadata plus FTS when embedding is disabled. Tencent VectorDB is the optional remote backend and supports server-side embedding, sparse BM25 vectors, and native reciprocal-rank hybrid retrieval.

## Design Choices

The project keeps raw evidence at the bottom and more compressed, human-readable summaries at the top. This makes L2 and L3 inspectable while still allowing drill-down into L1 and L0 evidence. JSONL remains a local backup/source trail, while SQLite or Tencent VectorDB handles retrieval.

Retrieval degrades by capability. If embeddings are configured, SQLite can run vector search and hybrid fusion with FTS. If embeddings are disabled, it still supports metadata and FTS. Tencent VectorDB can do native hybrid search in one backend call. L1 dedup now relies on vector or FTS candidates and no longer does an O(N) JSONL scan.

The pipeline is intentionally asynchronous and guarded. L1, L2, and L3 queues are serialized, checkpoint writes are locked and atomic, scheduler state is separated from runner state, and shutdown drains background tasks before closing the store. L2 and L3 file-writing LLMs operate with backups and path restrictions, then the system normalizes and indexes their output.

## Strengths

- The tiered lifecycle is clear and reusable: raw evidence, typed facts, scene narratives, and persona profile each have a different retention and retrieval role.
- Local-first operation is credible. SQLite, FTS5, and file artifacts work without a hosted memory service, and vector search is optional rather than required for basic recall.
- Hybrid retrieval is treated as a first-class path, including FTS, dense vectors, Tencent VectorDB native hybrid, and recall budgets.
- The implementation includes practical reliability work: checkpoint locks, backup restore, scheduler gates, background task tracking, cleanup guardrails, and degraded modes.
- Upper-tier Markdown files are inspectable and editable, which is useful for debugging agent memory and explaining why something was recalled.
- The active search tools let the agent request more memory only when needed, instead of relying entirely on automatic context injection.

## Weaknesses

- Zero-config embedding is disabled through `provider: none`, and the user-facing config treats `local` as disabled despite local embedding code still existing. Without remote embedding or Tencent VectorDB, recall is mostly FTS-based.
- Privacy boundaries are weak for shared deployments. The default user identity is effectively `default_user`, raw L0/L1 content is plaintext, and there is no built-in encryption or redaction policy for secrets and personal data.
- Gateway security is opt-in. Bearer auth and CORS allow lists exist, but an unset API key leaves routes open, with warnings rather than enforcement.
- Prompt-injection detection exists in utilities but is commented out in the L1 extraction gate. A malicious user message can still be promoted into durable memory unless a host adds stronger filtering.
- The memory search tool budget is described in guidance but not enforced in code, so repeated tool calls need host-level limits.
- L2 and L3 depend on LLM-authored Markdown. Backups and sandboxes reduce damage, but schema correctness and semantic consistency are less deterministic than a typed upper-tier store.
- The visible test suite is thin for the TypeScript core. The checkout has Vitest configs and changelog references to TS tests, but no matching TS test files; only Hermes Python tests were present.

## Ideas To Steal

- Use an explicit four-tier memory contract: L0 evidence log, L1 typed facts, L2 task or project scene cards, and L3 compact persona or working profile.
- Split recall into dynamic facts and stable profile/navigation so frequently changing memory does not invalidate all cached system context.
- Keep a drill-down path from summaries to evidence: L3 persona -> L2 scene -> L1 source IDs -> L0 conversation search.
- Store metadata and keyword indexes immediately, then attach embeddings in the background. This keeps capture fast and makes recall useful before vector indexing is complete.
- Put L2 scene count pressure into the prompt and index: merge first, create last, track heat and summaries, and avoid unbounded scene sprawl.
- Wrap LLM file-writing stages with backups, path restrictions, normalization, and post-write indexing.
- Treat memory cleanup as a guarded lifecycle operation with minimum-retain safety checks and explicit retention defaults.

## Do Not Copy

- Do not ship a local memory gateway with open auth by default, especially if it may bind outside loopback.
- Do not persist raw conversations as plaintext without a redaction, encryption, and retention story.
- Do not rely on advisory tool-use limits in prompt text when hard budgets are required.
- Do not disable prompt-injection filtering in the durable-memory promotion path.
- Do not make LLM-authored Markdown the only source of upper-tier truth for high-stakes memory without typed validation.
- Do not couple the memory architecture to OpenClaw or Hermes if the goal is a general coding-agent substrate.
- Do not assume Tencent VectorDB or remote embedding is acceptable for projects that require fully local, private operation.

## Fit For Agentic Coding Lab

This is in scope as a memory-design reference. The best fit is to reuse the lifecycle pattern and selected operational guards, not the full implementation. A coding-agent lab could adapt it into a smaller file-first memory system: L0 raw evidence shards, L1 typed project/user facts, L2 project or workflow scene notes, and L3 compact agent operating preferences. The lab version should add stronger secret redaction, per-workspace and per-user scoping, encryption or explicit plaintext warnings, enforced search budgets, and tests around capture, promotion, retrieval, cleanup, and prompt-injection resistance.

## Reviewed Paths

- `README.md`, `CHANGELOG.md`, `package.json`, `openclaw.plugin.json`: product claims, version scope, configuration surface, dependencies, plugin tools, and release notes.
- `index.ts`, `src/core/tdai-core.ts`, `src/adapters/*`, `src/gateway/server.ts`, `src/gateway/config.ts`: host integration, lifecycle, Gateway API, shutdown, and auth/CORS behavior.
- `src/config.ts`: defaults for capture, extraction, recall, embedding, BM25, cleanup, pipeline, persona, Tencent VectorDB, and offload.
- `src/core/store/types.ts`, `factory.ts`, `sqlite.ts`, `tcvdb.ts`, `embedding.ts`, `bm25-local.ts`: storage contract, local SQLite/FTS/vector behavior, Tencent VectorDB behavior, embedding options, and sparse retrieval.
- `src/core/hooks/auto-recall.ts`, `auto-capture.ts`, `src/core/conversation/l0-recorder.ts`: automatic recall, prompt injection placement, L0 capture, L0 indexing, and duplicate prevention.
- `src/core/record/l1-extractor.ts`, `l1-dedup.ts`, `l1-writer.ts`, `src/core/prompts/l1-extraction.ts`: L1 memory extraction, deduplication, merge/update semantics, and record writing.
- `src/core/scene/*`, `src/core/persona/*`, `src/core/prompts/scene-extraction.ts`, `src/core/prompts/persona-generation.ts`: L2 scene files, scene index/navigation, L3 persona generation, backups, and tool-scoped file edits.
- `src/core/tools/memory-search.ts`, `conversation-search.ts`, `src/core/seed/*`: active retrieval tools, seeding, filters, and recall limits.
- `src/utils/pipeline-manager.ts`, `pipeline-factory.ts`, `checkpoint.ts`, `session-filter.ts`, `memory-cleaner.ts`, `sanitize.ts`, `backup.ts`, `manifest.ts`: scheduler, state persistence, locking, cleanup, filtering, sanitization, backups, and drift detection.
- `src/offload/index.ts`, `state-manager.ts`, `after-tool-call.ts`, `l2-mermaid.ts`: reviewed only for reusable short-term context offload patterns and interaction with long-term memory.
- `hermes-plugin/memory/memory_tencentdb/client.py`, `provider.py`, `supervisor.py`, `tests/*.py`, `vitest.config.ts`, `vitest.e2e.config.ts`: Hermes adapter behavior, shutdown tests, and visible test coverage.

## Excluded Paths

- `assets/images/**`: UI and documentation images only; not relevant to memory architecture.
- `README_CN.md` and duplicated prose docs: useful for language comparison, but the English README and changelog covered the implementation claims reviewed here.
- `docker/opensource/**`: deployment packaging, not core memory behavior.
- `bin/*.mjs` and package launch wrappers: operational entrypoints only; core behavior is in `index.ts`, Gateway, and `src/**`.
- `scripts/migrate-sqlite-to-tcvdb/**`, `scripts/export-tencent-vdb/**`, `scripts/read-local-memory/**`, and `scripts/bugfix-20260423/**`: migration, export, inspection, and compatibility utilities; noted but not deep-reviewed because the focus was memory architecture and lifecycle.
- Full `src/offload/**` internals beyond the selected files listed above: offload is a symbolic short-term context-compression feature, not the primary local long-term memory system.
- Generated, vendor, and build-output paths such as `dist/**`, `node_modules/**`, caches, and Python bytecode: excluded even where absent from the reviewed checkout.
