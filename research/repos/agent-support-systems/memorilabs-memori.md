# MemoriLabs/Memori

- URL: https://github.com/MemoriLabs/Memori
- Category: agent-support-systems
- Stars snapshot: 14,314 (GitHub REST API, captured 2026-05-12)
- Reviewed commit: 78f8f65474f90369a15e3c82fece69b74b6ff57f
- Reviewed at: 2026-05-12 (Asia/Seoul)
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong in-scope memory infrastructure reference for LLM-agnostic agents, especially the SDK interception model, BYODB schema, Rust retrieval core, scoped recall, and coding-agent integrations. The main caution is that BYODB storage is local, but Advanced Augmentation extraction still calls Memori's hosted API by default; this is not a fully local memory system unless that service is replaced or self-hosted.

## Why It Matters

Memori is directly relevant to agent-support systems because it treats memory as infrastructure around an existing LLM client rather than as a model-specific feature. The repo shows how to intercept LLM calls, persist conversations, extract structured memories, store facts and knowledge graph triples, retrieve scoped context, and inject that context back into future prompts.

For coding agents, the most useful parts are not the quickstart chat examples. The useful parts are the actual memory loop: attribution by entity/process/session, raw turn capture, asynchronous augmentation, exact-deduped fact storage, vector retrieval with lexical reranking, short-term conversation replay, explicit agent recall tools, and integrations for MCP-like coding workflows through OpenClaw, Hermes, and documented Codex MCP setup.

## What It Is

Memori is a monorepo containing a Python SDK, a TypeScript SDK, a shared Rust native engine, storage drivers, docs, tests, examples, and agent integrations. It supports two operating modes:

- Cloud mode: no local database connection is supplied, and SDK calls go to hosted Memori APIs for conversation persistence, recall, and augmentation.
- BYODB mode: a user supplies a database connection, local SDK code stores conversations and extracted memories in that database, and the Rust/Python/TypeScript runtime handles local embeddings and retrieval.

The repo does not include the hosted Memori Cloud or MCP server implementation. It includes clients and integration code that call endpoints such as `cloud/conversation/messages`, `cloud/recall`, `sdk/augmentation`, `agent/conversation/turn`, `agent/augmentation`, `agent/recall`, and `agent/recall/summary`. Server behavior beyond those client contracts and docs is not independently reviewable from this repo.

## Research Themes

- Token efficiency: Strong directionally. Memori stores compact facts, semantic triples, and summaries, then injects only top recalled context. Docs report 81.95% LoCoMo accuracy with 1,294 added tokens per query, but the benchmark path depends on notebooks, external data, gated Hugging Face models, and hosted augmentation outputs rather than a small reproducible unit test.
- Context control: Good. Python recall defaults to five facts, a 0.1 relevance threshold, and a 1,000-embedding candidate cap. Retrieval is scoped by entity; conversations are scoped by entity/process/session; cloud agent recall adds project, session, date, source, and signal filters. BYODB facts are shared across all processes for an entity, which is useful but can surprise multi-agent deployments.
- Sub-agent / multi-agent: Good as memory substrate, not as orchestrator. `process_id`, `project_id` in cloud agent paths, explicit tools, and OpenClaw/Hermes integrations support multiple agents. There is no claim/lock protocol, memory conflict resolution policy, or per-agent authority model.
- Domain-specific workflow: Moderate. The cloud agent APIs and integrations model sources/signals such as constraint, decision, execution, failure, result, and verification. BYODB core stores generic facts, triples, process attributes, summaries, and conversations; it does not expose custom coding schemas for files, symbols, commits, issues, or tests.
- Error prevention: Useful plumbing. It strips injected history before persisting new messages, sanitizes malformed tool history for OpenAI-compatible replay, retries network/transaction failures, hashes entity/process IDs in augmentation payload metadata, validates some IDs, and has broad tests. It does not verify extracted memories against source files or command output.
- Self-learning / memory: Core fit. The system continuously captures turns, extracts durable facts and summaries, updates fact/triple frequency counters, and recalls across sessions.
- Popular skills: Memori provides or documents agent skills for MCP usage, OpenClaw behavior, and Hermes memory-provider behavior. These are relevant because they encode when to recall, when to augment, and what not to store.

## Core Execution Path

Python BYODB starts in `Memori(conn=...)`. The constructor creates `Config`, sets `cloud=False` and `byodb=True`, starts `StorageManager`, starts `AugmentationManager`, and lazily enables `RustCoreAdapter` when the native extension is available. `mem.llm.register(client)` monkey-patches supported LLM clients or framework clients through provider-specific wrappers.

Before an LLM call, `Invoke.invoke()` runs recall injection, then conversation-history injection. Recall extracts the latest user query, resolves the entity, embeds the query, retrieves relevant facts through Rust core when available or Python FAISS/BM25 fallback otherwise, filters by relevance threshold, and appends a `<memori_context>` block to provider-specific system/instructions fields. Conversation history is also prepended from the current session, with tool messages and malformed assistant tool-call placeholders stripped for OpenAI-compatible providers.

After the LLM call, `handle_post_response()` normalizes the request/response into conversation messages, excludes Memori-injected history via `_memori_injected_count`, and calls `MemoryManager.execute()`. In BYODB this writes entity, process, session, conversation, and conversation-message rows. In cloud mode it posts conversation messages to the hosted API and may persist a local copy when a driver exists.

Augmentation then runs asynchronously. In BYODB with Rust core, `RustCoreAdapter.submit_augmentation()` sends a job to the native engine. The Rust worker builds an augmentation payload and calls the Memori API unless `use_mock_response` is set in tests. In the pure Python fallback, `AdvancedAugmentation.process()` also calls `Api.augmentation_async()`. The returned facts/triples/summaries become write operations for entity facts, knowledge graph triples, process attributes, and conversation summary updates.

Retrieval reads recent fact embeddings from `memori_entity_fact`, parses binary or JSON embeddings, runs cosine similarity with FAISS or Rust, over-fetches candidates, fetches fact text and summaries by ID, computes BM25-style lexical scores over the candidate pool, combines dense and lexical scores, then returns ranked facts. Updates are mostly upsert-style: exact fact hashes and triple uniqueness increment `num_times` and `date_last_time`; there is no local contradiction handling, per-fact invalidation, or LLM-driven update/delete policy. BYODB exposes `delete_entity_memories()` for entity facts and knowledge graph rows while preserving conversations.

TypeScript mirrors the same pattern through Axon hooks. `Memori` registers before/after hooks for recall, persistence, and augmentation. With a local connection, `NativeEngine` bridges Rust callbacks to the TypeScript `StorageManager`; without local storage, it calls hosted cloud APIs. The TypeScript BYODB path writes conversation messages through a `conversation_message.create` batch and uses Rust for retrieval and augmentation queueing.

Agent integrations use a different, explicit recall model. OpenClaw and Hermes capture completed turns in the background, including tool traces where available, and expose `memori_recall`, `memori_recall_summary`, quota, signup, and feedback tools. The documented MCP flow also expects explicit `recall` before answering and `advanced_augmentation` after responding.

## Architecture

The core architecture has five layers.

1. SDK interception layer: Python monkey-patches OpenAI, Anthropic, Google, xAI, Bedrock/LangChain, Agno, and Pydantic AI clients; TypeScript uses `@memorilabs/axon` hooks.
2. Storage layer: adapters detect DB-API, SQLAlchemy, Django, MongoDB, and TypeScript database clients; drivers support SQLite, PostgreSQL, MySQL/MariaDB, TiDB, Oracle, MongoDB, CockroachDB, OceanBase, and related providers.
3. Memory schema: tables/collections include entity, process, session, conversation, conversation message, entity fact, entity fact mention, process attribute, subject, predicate, object, and knowledge graph.
4. Retrieval layer: local embeddings, dense similarity, lexical reranking, summaries attached through fact mentions, cloud recall normalization, and provider-specific prompt injection.
5. Augmentation layer: background queues submit raw conversation messages plus metadata to Memori's augmentation API, then persist returned facts, triples, attributes, and summaries.

The Rust core is the shared performance and queueing layer. `EngineOrchestrator` owns a sentence-transformers embedder, bounded worker runtimes for postprocess and augmentation jobs, and an optional host storage bridge. It exposes embedding, retrieval, recall formatting, augmentation submission, queue flushing, and shutdown to Python and Node bindings. Python additionally has a pure-Python fallback path.

The important privacy architecture distinction is BYODB storage versus hosted extraction. BYODB keeps final rows in the user's database and local retrieval runs in-process, but the default augmentation path still transmits conversation content to Memori's hosted augmentation API. Entity and process IDs are SHA-256 hashed in augmentation metadata, but message content is not locally redacted by the Python BYODB core.

## Design Choices

Memori chooses transparent LLM client wrapping for general SDK use. This minimizes application code changes, but makes provider adapters and request/response normalization a large compatibility surface.

It separates raw conversations from extracted memory. Raw user/assistant messages are stored in conversation tables, while extracted facts and triples are stored separately for retrieval. Fact mentions link facts back to conversation summaries, which gives recalled facts some provenance-like narrative context.

It uses exact deduplication and frequency counters. Fact uniqueness is based on a hash of fact text; semantic triples dedupe on entity, subject, predicate, and object. Repeated facts increment `num_times` and update last-seen timestamps. This is simple and auditable, but it does not merge paraphrases or mark stale contradictions.

It makes entity memory shared across processes. This lets one user's different agents reuse stable facts, but process isolation only applies to process attributes and conversation history, not entity facts.

It prioritizes asynchronous augmentation. Memory creation happens after the response and is queued, so user-facing latency is low. Short-lived scripts must call `mem.augmentation.wait()` to drain work.

It keeps recall injection conservative. Facts below threshold are skipped, recalled facts are wrapped in a clear XML-ish block, and the prompt says to use context only if relevant.

It offers both automatic and agent-controlled recall. SDK wrappers inject automatically; OpenClaw, Hermes, and MCP docs push explicit agent tools. For coding agents, the explicit model is safer because the agent can choose when memory matters.

## Strengths

The repo exposes a complete memory loop: interception, persistence, extraction, storage, retrieval, injection, manual recall, deletion, and examples across Python and TypeScript.

LLM provider support is broad, and the memory layer is mostly independent of provider choice. OpenAI Chat Completions and Responses, Anthropic, Gemini, Bedrock, xAI, Agno, LangChain, and Pydantic AI paths are represented.

BYODB schema is practical. It gives teams direct database ownership, SQL-queryable graph tables, fact frequency counters, conversation summaries, and direct deletion of entity memories.

The Rust bridge is a useful pattern for shared performance-sensitive memory code across Python and TypeScript. It centralizes embedding, retrieval, bounded background queues, and storage callbacks while keeping language bindings thin.

Recall combines dense similarity with lexical reranking over an over-fetched candidate pool. This is more useful for coding-agent facts than pure vector similarity, especially for short queries and exact tool/library names.

Agent integrations are unusually relevant to coding-agent workflows. OpenClaw captures tool calls/results and exposes recall tools; Hermes provides a memory provider with explicit system-prompt guidance; docs include Codex MCP setup and a reusable skill file.

Tests are broad. Reviewed coverage includes Python memory recall, augmentation scheduling, DB writer batching, storage drivers, LLM adapters, conversation injection, Rust-core callbacks and ONNX handling, TypeScript storage/engines, OpenClaw tools, and Hermes provider/install behavior.

## Weaknesses

BYODB is not fully local by default. Both Python and Rust augmentation paths send conversation messages to Memori's hosted augmentation API. That conflicts with a casual reading of docs saying BYODB data stays on your infrastructure.

The hosted cloud/MCP server implementation is absent. The repo documents and calls server endpoints, but auth, authorization, tenant isolation, retention, secret filtering, and ranking internals for hosted agent memory cannot be audited here.

Local update semantics are shallow. Exact duplicate facts and triples are counted, but there is no local stale-fact invalidation, contradiction handling, merge policy, manual per-fact update API, or temporal validity window.

Privacy controls are incomplete in the local code. System messages are stripped from persisted payloads and augmentation metadata hashes IDs, but raw conversation content can be stored locally and sent remotely; OpenClaw's sanitizer removes wrappers/timestamps but does not visibly redact secrets. A skill doc claims backend secret filtering, but that is hosted behavior outside this repo.

Documentation has drift. BYODB docs mention `all-mpnet-base-v2` and 768-dimensional embeddings, while Python config defaults to `all-MiniLM-L6-v2`. Knowledge-graph docs show column names like `mention_count`, `last_mentioned_at`, and `predicate.name`, while migrations use `num_times`, `date_last_time`, and `predicate.content`.

Automatic conversation replay can grow within a session. It reads all messages for the active conversation and prepends them unless provider-specific sanitization removes malformed tool turns. There is no explicit token-budget allocator in the reviewed core.

The benchmark claim is promising but not self-contained. Benchmark notebooks depend on external augmented memory data, a gated embedding model, OpenAI API calls, and a separate paper. The repo has a small recall eval harness, but not a one-command reproduction of headline LoCoMo numbers.

Some provider edges are unfinished or brittle. Anthropic streamed response parsing raises "REQUEST FOR CONTRIBUTION"; provider monkey-patching depends on SDK object internals and registration order.

## Ideas To Steal

Use attribution as a first-class schema: entity for the remembered subject, process for the agent/workflow, session for the conversation, and project for coding-agent workspace scope.

Separate short-term conversation replay from long-term facts. The current session can be replayed from conversation messages, while durable facts remain compact and retrievable.

Attach summaries to recalled facts through fact mentions. A coding-agent memory can return both "repo uses uv" and the summary of the session where that convention was established.

Use asynchronous augmentation with an explicit `wait()` drain for scripts and tests. It avoids latency while still making deterministic examples possible.

Keep a host-storage bridge between native retrieval code and language SDKs. This lets Python/TypeScript own database adapters while Rust owns embedding/search/queue mechanics.

Expose explicit memory tools for agents rather than relying only on automatic injection. For coding agents, targeted recall by project/source/signal is safer than injecting memory on every turn.

Preserve a "do not store" policy in agent skills. The Memori MCP skill's skip list for secrets, logs, stack traces, temporary debugging, and routine task progress is directly reusable.

Use lexical reranking as a small but important addition to vector recall. Exact package names, commands, file names, and frameworks often matter in coding tasks.

## Do Not Copy

Do not copy the BYODB privacy story without clarifying remote augmentation. If source code, secrets, or proprietary task logs may be included, either self-host/replace extraction or add an explicit consent and redaction layer.

Do not automatically persist all coding-agent turns. Store durable preferences, project conventions, decisions, verified failures, and stable environment facts; skip raw logs, one-off progress, command output, temp credentials, and speculative inferences.

Do not rely on exact fact hashes for long-lived coding memory. Add reconciliation for paraphrases, superseded decisions, stale dependency versions, and contradictions.

Do not treat entity/process/session scoping as authorization. It is memory partitioning, not an access-control system.

Do not adopt provider monkey-patching without compatibility tests for every supported SDK version and streaming mode.

Do not present benchmark numbers as proven for coding agents. Build a repo-task eval that measures whether recalled memory improves edits, prevents repeated mistakes, and avoids cross-project leakage.

Do not copy docs blindly. Reconcile docs with schema, embedding defaults, cloud versus BYODB behavior, and hosted versus open-source components first.

## Fit For Agentic Coding Lab

Fit is strong. Memori belongs in `agent-support-systems` because it is a concrete memory layer for agent applications, not merely a prompt pack or chat client. It shows a usable design for persistent memory around existing LLM clients and agent tools.

The best Agentic Coding Lab adaptation would be selective. Borrow the attribution model, fact/summary split, local storage schema, Rust retrieval bridge, explicit recall tools, and agent skill policy. Add coding-specific schemas and filters for repo, branch, file, command, test, failure, fix, convention, and user preference. Treat recalled memory as evidence, not instruction.

Before production use, the lab would need stronger local privacy controls, a redaction pipeline, retention and deletion policy, per-user/repo authorization, deterministic verification of extracted coding facts, and a clear choice between hosted augmentation and local extraction.

## Reviewed Paths

- `/tmp/myagents-research/MemoriLabs-Memori/README.md`: positioning, quickstarts, LoCoMo claims, MCP/OpenClaw/Hermes overview, attribution, session management, supported providers.
- `/tmp/myagents-research/MemoriLabs-Memori/pyproject.toml`, `setup.py`, `setup.cfg`, `Makefile`, `Dockerfile`, `docker-compose.yml`: package metadata, dependency shape, native extension packaging, and dev/test surfaces.
- `/tmp/myagents-research/MemoriLabs-Memori/SECURITY.md`: vulnerability reporting policy.
- `/tmp/myagents-research/MemoriLabs-Memori/docs/memori-byodb/`: architecture, how memory works, advanced augmentation, multi-user support, knowledge graph, async patterns, database docs, LLM docs, and quickstarts.
- `/tmp/myagents-research/MemoriLabs-Memori/docs/memori-cloud/`: benchmark docs, MCP docs, agent skills, OpenClaw docs, Hermes docs, dashboard/API-key docs, and support pages.
- `/tmp/myagents-research/MemoriLabs-Memori/memori/__init__.py`, `_config.py`, `_network.py`, `agent.py`, `_rust_core.py`: Python SDK entrypoint, configuration, hosted API client, agent endpoints, and Rust bridge.
- `/tmp/myagents-research/MemoriLabs-Memori/memori/llm/`: client registration, direct/framework adapters, invoke wrappers, recall injection, conversation injection, post-invoke persistence, serialization, query extraction, and provider adapters.
- `/tmp/myagents-research/MemoriLabs-Memori/memori/memory/`: memory manager, writer, recall, augmentation manager, handler, runtime, DB writer, models, message/input structs, and Memori augmentation implementation.
- `/tmp/myagents-research/MemoriLabs-Memori/memori/search/` and `/tmp/myagents-research/MemoriLabs-Memori/memori/embeddings/`: FAISS search, BM25 lexical scoring, ranking core, parsing, sentence-transformers embedding, TEI support, chunking, and DB formatting.
- `/tmp/myagents-research/MemoriLabs-Memori/memori/storage/`: registry, adapters, builder, migrations, SQLite/PostgreSQL/MySQL/MongoDB/Oracle/TiDB/OceanBase/Cockroach-related drivers and tests.
- `/tmp/myagents-research/MemoriLabs-Memori/core/README.md`, `core/docs/architecture.md`, `core/src/`: Rust orchestrator, runtime, storage bridge, retrieval, search, augmentation, embeddings, network, bindings, and contract tests.
- `/tmp/myagents-research/MemoriLabs-Memori/memori-ts/src/`: TypeScript SDK entrypoint, Axon engines, native engine bridge, storage manager/drivers/migrations, cloud network client, integrations, and tests.
- `/tmp/myagents-research/MemoriLabs-Memori/integrations/openclaw/`: OpenClaw README, sanitizer, augmentation handler, Memori client wrapper, recall/summary/feedback/quota/signup tools, skills, config, and tests.
- `/tmp/myagents-research/MemoriLabs-Memori/integrations/hermes/`: Hermes README, memory provider, client, tool schemas, installer, plugin manifests, and tests.
- `/tmp/myagents-research/MemoriLabs-Memori/examples/`: Python and TypeScript SQLite/PostgreSQL/MySQL/CockroachDB/MongoDB/TiDB/Neon/OceanBase/DigitalOcean/Nebius/Agno examples, including Rust-core SQLite example.
- `/tmp/myagents-research/MemoriLabs-Memori/tests/`, `/tmp/myagents-research/MemoriLabs-Memori/memori-ts/tests/`, `/tmp/myagents-research/MemoriLabs-Memori/core/tests/`, and integration tests under OpenClaw/Hermes: verification surface for recall, storage, augmentation, providers, native bridge, agent tools, and installers.
- `/tmp/myagents-research/MemoriLabs-Memori/benchmarks/` and benchmark docs: LoCoMo evaluation notebooks and claimed results.

## Excluded Paths

- `/tmp/myagents-research/MemoriLabs-Memori/.git/`: VCS internals; exact reviewed commit captured separately.
- `/tmp/myagents-research/MemoriLabs-Memori/.github/`: CI/release automation and issue workflow metadata; useful maintenance context but not memory execution path.
- `/tmp/myagents-research/MemoriLabs-Memori/core/Cargo.lock`, `/tmp/myagents-research/MemoriLabs-Memori/memori-ts/package-lock.json`, `/tmp/myagents-research/MemoriLabs-Memori/integrations/openclaw/package-lock.json`, and other lockfiles: generated dependency snapshots; reviewed package manifests and source imports instead.
- `/tmp/myagents-research/MemoriLabs-Memori/benchmarks/*.ipynb`: notebook outputs and large executable research artifacts; reviewed benchmark README/docs and test harness instead of cell-by-cell output.
- Images and static assets referenced from docs, README badges, and hosted `images.memorilabs.ai` assets: presentation material, not runtime logic.
- `/tmp/myagents-research/MemoriLabs-Memori/docs/memori-cloud/dashboard/` and dashboard how-to pages beyond API-key handling: product UI documentation, not memory infrastructure internals.
- `/tmp/myagents-research/MemoriLabs-Memori/docs/memori-cloud/support/` and `/tmp/myagents-research/MemoriLabs-Memori/docs/memori-byodb/support/`: troubleshooting copy; skimmed for operational caveats but excluded from architecture analysis.
- Database-provider example variants not named individually in findings: repetitive connection setup; representative SQLite, PostgreSQL, TypeScript, and Rust-core examples reviewed.
- Build scripts such as `scripts/bump-versions.js`, `scripts/sync-native.js`, native package boilerplate, and CLI banner/display helpers: packaging/support code, not memory lifecycle design.
- No vendored third-party source or binary model files were present in the reviewed checkout; ONNX Runtime is downloaded at runtime with checksum verification rather than vendored in the repo.
