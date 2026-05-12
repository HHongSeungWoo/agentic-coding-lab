# mem0ai/mem0

- URL: https://github.com/mem0ai/mem0
- Category: agent-support-systems
- Stars snapshot: 55,433 (GitHub REST API, captured 2026-05-12)
- Reviewed commit: 54a03cc7217c22afdc6153a9e61cc6413416001f
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong in-scope reference for agent long-term memory. The useful parts are the v3 ADD-only extraction pipeline, scoped vector storage, hybrid semantic/BM25/entity ranking, entity-link side index, server auth model, and filter discipline. Do not adopt wholesale without a local privacy policy, retention model, and verification harness because docs and examples still carry stale graph-memory behavior, telemetry is on by default, and benchmark claims are not fully reproduced by this repo.

## Why It Matters

`mem0ai/mem0` is one of the most direct examples of a production-oriented memory layer for agents. It answers a practical question for coding agents: how should an agent turn chat or work traces into durable memories, retrieve the right memories later, update or delete them, and keep identity scopes separate?

For Agentic Coding Lab, the repo matters less as a dependency and more as a design study. It shows a concrete memory lifecycle with extraction prompts, vector stores, metadata filters, history logging, entity linking, hosted and self-hosted clients, auth, telemetry, tests, and evaluation scripts. Those pieces map closely to persistent project memory, user preference memory, run memory, and agent-specific recall.

## What It Is

Mem0 is an open-source Python and TypeScript memory SDK plus a FastAPI self-hosted server. The Python package exposes `Memory` and `AsyncMemory`; the hosted client exposes `MemoryClient`; the server wraps a configurable memory instance behind authenticated HTTP endpoints; and `mem0-ts` mirrors the OSS memory behavior for JavaScript/TypeScript users.

The current open-source memory architecture is v3. It stores memories in a vector database, keeps a rolling message/history database in SQLite or server storage, and creates a parallel entity vector collection for entity-based boosts. Older graph-store support was removed from the OSS core. Some docs and examples still mention `graph_store`, but the current migration docs say graph memory was replaced by entity linking.

## Research Themes

- Token efficiency: Strong. The add path uses recent messages plus a small set of existing memories, then performs single-pass ADD-only extraction instead of repeatedly asking the LLM to decide add/update/delete operations. README benchmark tables claim roughly 6.7K to 7.0K tokens on major memory benchmarks, but the repo points the full benchmark framework to a separate `mem0ai/memory-benchmarks` repo.
- Context control: Strong. Memory operations require identity scope through `user_id`, `agent_id`, or `run_id`, and search/get-all require those identities inside `filters`. The SQLite message window keeps only the last 10 messages per session scope. Metadata filters support equality, ranges, membership, string contains, and logical operators.
- Sub-agent / multi-agent: Moderate. `agent_id`, `run_id`, `actor_id`, assistant-authored facts, and an agent-scoped prompt suffix are useful for multi-agent systems. The repo has multi-agent examples, but it is not an orchestrator or scheduler.
- Domain-specific workflow: Moderate. Custom instructions and prompt overrides let teams shape extraction. The server includes an instruction-generation endpoint. Examples cover support agents, personal assistants, GitHub research agents, and framework integrations, but domain workflow remains mostly application code around the memory layer.
- Error prevention: Good. The core validates empty and whitespace-polluted identity values, rejects top-level identity parameters on search/get-all, redacts secrets in config handling, degrades when optional BM25/entity dependencies are missing, and tests extraction failure, actor preservation, scoring, entity extraction, telemetry sampling, and vector-store filters.
- Self-learning / memory: Strong. This is the core purpose of the repo: extracting facts from interactions, storing them as scoped memories, retrieving them by semantic and structured signals, and preserving history for audit/update/delete operations.
- Popular skills: Relevant surfaces include the `mem0` Codex skill, `mem0-cli`, `mem0-vercel-ai-sdk`, `mem0-integrate`, and `mem0-test-integration`. I treated these as integration evidence, not as the core architecture.

## Core Execution Path

The central path is `Memory.add()`, `Memory.search()`, `Memory.update()`, and `Memory.delete()` in `mem0/memory/main.py`.

For `add(..., infer=True)`, Mem0 builds scoped metadata from `user_id`, `agent_id`, and `run_id`; reads the last 10 messages for that scope; embeds the new message text; searches existing memories; and sends a compact prompt to the LLM asking for new memories only. The current v3 prompt is ADD-only: it does not ask the LLM to classify UPDATE or DELETE. Parsed memories are batch-embedded, exact-deduplicated by MD5 hash, inserted into the vector store, written to history, linked to extracted entities, and the raw messages are saved to the rolling message table.

For `add(..., infer=False)`, each non-system message is stored directly as a memory. Role and message `name` can become `role` and `actor_id`, which is useful for assistant-generated facts and multi-actor records.

For `search()`, the caller must provide filters containing at least one of `user_id`, `agent_id`, or `run_id`. The query is embedded, lemmatized for keyword search, and optionally parsed for entities. Mem0 over-fetches semantic vector results, asks the vector store for BM25 keyword results when supported, searches the entity collection for matching entities, then fuses semantic score, BM25 score, and entity boost. BM25 and entity signals change ranking, but the migration docs and implementation make clear they do not expand recall beyond the semantic candidate set.

For `update()`, Mem0 fetches the existing memory, preserves created time and actor metadata, re-embeds the new text, writes an UPDATE history row, removes stale entity links, and links entities from the new text. `delete()` removes the vector record, writes DELETE history, and cleans entity links. `delete_all()` requires at least one identity filter before deleting scoped memories.

The hosted `MemoryClient` calls platform endpoints and uses `Authorization: Token <api_key>`. The self-hosted FastAPI server wraps the local `Memory` object with dashboard JWT auth, refresh tokens, per-user API keys, request logging, config endpoints, and memory CRUD/search endpoints.

## Architecture

The core Python architecture has four runtime stores:

1. Vector store: the primary memory database. Qdrant is the default local provider, but the factory supports Chroma, pgvector, Milvus, Upstash Vector, Azure AI Search, Pinecone, MongoDB, Redis, Valkey, Elasticsearch, OpenSearch, Supabase, Weaviate, FAISS, S3 vectors, Cassandra, Neptune Analytics, Turbopuffer, and others.
2. Entity store: a parallel vector collection named from the memory collection plus `_entities`. Entities link to memory IDs and are used for retrieval boosts. This is not a queryable knowledge graph in current OSS v3.
3. History/message store: SQLite in the SDK. It stores add/update/delete events and a rolling message window per session scope.
4. LLM/embedder providers: pluggable factories construct the extractor LLM and embedding model. Python defaults to OpenAI with `gpt-5-mini` in the LLM adapter and `text-embedding-3-small` for embeddings; the server default config uses `gpt-4.1-nano-2025-04-14` and `text-embedding-3-small`.

The Qdrant implementation is the most important vector-store reference. It creates dense vectors and, when available, a named sparse vector slot for BM25. It lazily initializes FastEmbed BM25, creates indexes for remote identity fields, supports advanced filters, inserts both dense and sparse vectors, and offers native batch search. If an existing collection lacks the BM25 vector slot or the sparse embedder is unavailable, keyword search is disabled with warnings.

The server architecture adds production concerns around the SDK. `server/main.py` requires `JWT_SECRET` unless `AUTH_DISABLED=true`, restricts CORS to `DASHBOARD_URL`, redacts sensitive config fields, classifies provider/datastore errors, and adds request IDs. `server/auth.py` handles bcrypt password hashes, HS256 JWT access/refresh tokens, consumed refresh-token JTIs, API key creation with stored bcrypt hashes, key prefixes, revocation, and legacy admin-key comparison.

The TypeScript OSS memory mirrors the Python v3 shape, including scoped add/search, entity store, and hybrid ranking. It uses different field casing in some storage payloads, which matters if teams try to share collections across Python and TypeScript implementations.

## Design Choices

The most important design choice is ADD-only extraction. Mem0 avoids asking the LLM to decide whether a fact should update or delete an existing memory during ingestion. It instead extracts new durable facts, deduplicates exact text, and leaves explicit update/delete to later API calls.

The second design choice is strict identity scoping. Search and get-all reject top-level `user_id`, `agent_id`, and `run_id`, forcing callers to use `filters`. The SDK still accepts top-level identity values for add. This separation reduces accidental cross-user search, and tests explicitly cover the rejection behavior.

The third design choice is entity linking without a graph database. Entity extraction uses spaCy when available, writes entity nodes into a vector collection, and links each entity to memory IDs. Retrieval then boosts memories connected to matched entities. Current OSS does not expose graph relationships, traversal, or relation triples as a first-class graph API.

The fourth design choice is graceful degradation. If spaCy is missing, entity extraction returns no entities. If Qdrant BM25 support is unavailable, semantic search still works. If batch insert/history/entity operations fail, the code often falls back to individual operations.

The fifth design choice is broad provider support behind factories. This makes Mem0 easy to wire into existing infrastructure, but it also creates a large compatibility surface and uneven feature support across vector stores.

## Strengths

Mem0 has a real end-to-end memory lifecycle rather than only prompts or diagrams. The add/search/update/delete paths are concrete, tested in parts, and structured around agent identity scopes.

The v3 architecture is simpler than the old graph-memory design. Entity linking provides a useful retrieval signal without requiring a graph database, relation extraction, or graph traversal to work correctly.

The retrieval stack is pragmatic. Semantic search is always available, BM25 is used when the vector store supports sparse text, and entity matches add another ranking signal. The scoring code is explicit and small enough to audit.

The server has meaningful security defaults. Auth is enabled by default, API keys are hashed, refresh token reuse is blocked, dashboard CORS is narrow, request IDs are returned, and provider errors are mapped into safer responses.

The tests cover several agent-memory failure modes: malformed LLM JSON, custom prompts, no-inference writes, actor preservation, entity cleanup on update/delete, client filter migration, scoring behavior, Qdrant filters, and telemetry sampling.

## Weaknesses

Docs and examples are not fully aligned with current code. `docs/migration/oss-v2-to-v3.mdx` says graph memory was removed, but older docs, `AGENTS.md`, `LLM.md`, Dockerfile extras, and graph demo notebooks still mention `graph_store` and `mem0ai[graph]`. That can mislead implementers.

BM25 and entity matching are ranking boosts, not recall expanders. If the semantic over-fetch misses a memory, keyword/entity signals cannot recover it. This is fine if documented, but it should not be described as full hybrid search recall.

Deduplication is exact text hash based. Near duplicates, paraphrases, contradictions, and stale memories can accumulate unless callers build explicit update/reconciliation policies.

The privacy posture needs local hardening. SDK telemetry is enabled by default, a local user ID is created under `~/.mem0`, and memory extraction can persist sensitive conversation facts automatically. Telemetry filters hash identity values, but application teams still need consent, retention, redaction, and deletion policy.

Benchmark evidence is split. The repo includes an older `evaluation/` tree for LOCOMO-style experiments, but the current docs say the benchmark framework lives in `mem0ai/memory-benchmarks` and that platform results include proprietary optimizations. Treat headline scores as directional unless reproduced locally.

The provider matrix is wide enough that behavior differs by backend. BM25, filters, batch search, payload indexing, and local locking behavior are not uniform across stores. Qdrant is the clearest reference implementation.

Python and TypeScript storage payload casing differs in places. That is a practical migration risk for teams trying to use both SDKs against the same collection.

## Ideas To Steal

Use a single-pass ADD-only extraction prompt for long-term memory writes. It is easier to reason about than LLM-driven add/update/delete classification.

Require explicit identity scope for every retrieval. A coding-agent memory system should make project/user/agent/run scope impossible to forget.

Keep a small rolling message window outside the vector store. It gives extraction enough recent context without replaying full chat history.

Use a side entity index as a retrieval signal instead of adopting graph storage as the default. It gives some entity awareness while preserving a simpler operational model.

Separate manual update/delete APIs from automatic extraction. Human or policy-driven update paths are easier to audit than silent LLM reconciliation.

Expose advanced metadata filters, but keep their syntax consistent across SDK, server, and vector-store adapters.

Add request IDs, API-key hashing, token replay protection, secret redaction, and provider-error classification to any self-hosted memory service.

## Do Not Copy

Do not copy the stale graph-store docs or examples as current architecture. In current OSS v3, graph memory is gone and entity linking is the replacement.

Do not enable telemetry by default in an internal coding-agent lab without an explicit local policy and opt-in/out UX.

Do not treat BM25/entity boosts as a complete hybrid retrieval system. If exact keyword recall matters, build a true keyword candidate source or widen recall deliberately.

Do not persist every extracted fact automatically. Coding-agent memory should distinguish user preferences, project facts, transient run state, secrets, and speculative model inferences.

Do not inherit the full provider matrix unless there is a real need. Qdrant or pgvector plus one embedding provider is a better starting scope for a lab system.

Do not rely on external benchmark numbers without a reproducible local eval harness and task-specific checks.

Do not share Python and TypeScript collections casually until field casing and payload compatibility are tested.

## Fit For Agentic Coding Lab

Fit is strong. Mem0 is directly relevant to agent memory extraction, scoped storage, retrieval, update, deletion, and server-side access control. It belongs in `agent-support-systems`.

The best adoption path is selective. Agentic Coding Lab should borrow the scoped memory lifecycle, rolling context window, entity side index, hybrid scoring shape, and security patterns. It should add stricter privacy rules for source code, secrets, user instructions, and project state. It should also add a local eval suite that asks whether retrieved memories actually improve coding tasks without leaking unrelated project/user context.

For coding agents, the most useful memory classes would be user preferences, repo-specific conventions, recurring build/test commands, durable architecture decisions, and tool quirks. The system should avoid storing raw secrets, raw large file contents, failed guesses, or temporary chain-of-thought-like reasoning.

## Reviewed Paths

- `/tmp/myagents-research/mem0ai-mem0/README.md`
- `/tmp/myagents-research/mem0ai-mem0/pyproject.toml`
- `/tmp/myagents-research/mem0ai-mem0/AGENTS.md`
- `/tmp/myagents-research/mem0ai-mem0/LLM.md`
- `/tmp/myagents-research/mem0ai-mem0/docs/migration/oss-v2-to-v3.mdx`
- `/tmp/myagents-research/mem0ai-mem0/docs/core-concepts/memory-evaluation.mdx`
- `/tmp/myagents-research/mem0ai-mem0/docs/core-concepts/memory-operations/add.mdx`
- `/tmp/myagents-research/mem0ai-mem0/docs/core-concepts/search.mdx`
- `/tmp/myagents-research/mem0ai-mem0/docs/open-source/python-quickstart.mdx`
- `/tmp/myagents-research/mem0ai-mem0/docs/open-source/features.mdx`
- `/tmp/myagents-research/mem0ai-mem0/docs/open-source/configuration.mdx`
- `/tmp/myagents-research/mem0ai-mem0/mem0/memory/main.py`
- `/tmp/myagents-research/mem0ai-mem0/mem0/memory/storage.py`
- `/tmp/myagents-research/mem0ai-mem0/mem0/memory/telemetry.py`
- `/tmp/myagents-research/mem0ai-mem0/mem0/memory/setup.py`
- `/tmp/myagents-research/mem0ai-mem0/mem0/configs/base.py`
- `/tmp/myagents-research/mem0ai-mem0/mem0/configs/vector_stores/base.py`
- `/tmp/myagents-research/mem0ai-mem0/mem0/configs/prompts.py`
- `/tmp/myagents-research/mem0ai-mem0/mem0/utils/factory.py`
- `/tmp/myagents-research/mem0ai-mem0/mem0/utils/scoring.py`
- `/tmp/myagents-research/mem0ai-mem0/mem0/utils/entity_extraction.py`
- `/tmp/myagents-research/mem0ai-mem0/mem0/utils/lemmatization.py`
- `/tmp/myagents-research/mem0ai-mem0/mem0/vector_stores/base.py`
- `/tmp/myagents-research/mem0ai-mem0/mem0/vector_stores/qdrant.py`
- `/tmp/myagents-research/mem0ai-mem0/mem0/vector_stores/neptune_analytics.py`
- `/tmp/myagents-research/mem0ai-mem0/mem0/client/main.py`
- `/tmp/myagents-research/mem0ai-mem0/mem0/client/types.py`
- `/tmp/myagents-research/mem0ai-mem0/server/main.py`
- `/tmp/myagents-research/mem0ai-mem0/server/auth.py`
- `/tmp/myagents-research/mem0ai-mem0/server/models.py`
- `/tmp/myagents-research/mem0ai-mem0/server/server_state.py`
- `/tmp/myagents-research/mem0ai-mem0/server/routers/auth.py`
- `/tmp/myagents-research/mem0ai-mem0/server/routers/api_keys.py`
- `/tmp/myagents-research/mem0ai-mem0/server/routers/entities.py`
- `/tmp/myagents-research/mem0ai-mem0/server/README.md`
- `/tmp/myagents-research/mem0ai-mem0/server/docker-compose.yml`
- `/tmp/myagents-research/mem0ai-mem0/mem0-ts/src/oss/src/memory/index.ts`
- `/tmp/myagents-research/mem0ai-mem0/mem0-ts/src/oss/src/memory/storage.ts`
- `/tmp/myagents-research/mem0ai-mem0/mem0-ts/src/oss/src/types/index.ts`
- `/tmp/myagents-research/mem0ai-mem0/tests/memory/test_main.py`
- `/tmp/myagents-research/mem0ai-mem0/tests/utils/test_entity_extraction.py`
- `/tmp/myagents-research/mem0ai-mem0/tests/utils/test_scoring.py`
- `/tmp/myagents-research/mem0ai-mem0/tests/memory/test_memory_utils.py`
- `/tmp/myagents-research/mem0ai-mem0/tests/vector_stores/test_qdrant.py`
- `/tmp/myagents-research/mem0ai-mem0/tests/test_client.py`
- `/tmp/myagents-research/mem0ai-mem0/tests/test_server_auth.py`
- `/tmp/myagents-research/mem0ai-mem0/tests/test_telemetry_sampling.py`
- `/tmp/myagents-research/mem0ai-mem0/evaluation/README.md`
- `/tmp/myagents-research/mem0ai-mem0/evaluation/run_experiments.py`
- `/tmp/myagents-research/mem0ai-mem0/evaluation/evals.py`
- `/tmp/myagents-research/mem0ai-mem0/evaluation/generate_scores.py`
- `/tmp/myagents-research/mem0ai-mem0/evaluation/metrics/llm_judge.py`
- `/tmp/myagents-research/mem0ai-mem0/evaluation/src/memzero/add.py`
- `/tmp/myagents-research/mem0ai-mem0/evaluation/src/memzero/search.py`
- `/tmp/myagents-research/mem0ai-mem0/evaluation/src/langmem.py`
- `/tmp/myagents-research/mem0ai-mem0/evaluation/src/rag.py`
- `/tmp/myagents-research/mem0ai-mem0/evaluation/src/zep/`
- `/tmp/myagents-research/mem0ai-mem0/examples/misc/strands_agent_aws_elasticache_neptune.py`
- `/tmp/myagents-research/mem0ai-mem0/examples/multiagents/llamaindex_learning_system.py`
- `/tmp/myagents-research/mem0ai-mem0/examples/graph-db-demo/`
- `/tmp/myagents-research/mem0ai-mem0/mem0-plugin/skills/`
- `/tmp/myagents-research/mem0ai-mem0/skills/`

## Excluded Paths

- `/tmp/myagents-research/mem0ai-mem0/.git/`: VCS internals; exact reviewed commit captured separately.
- `/tmp/myagents-research/mem0ai-mem0/.github/`: CI and issue/PR automation, not memory architecture.
- `/tmp/myagents-research/mem0ai-mem0/.agents/`, `/tmp/myagents-research/mem0ai-mem0/.claude-plugin/`, `/tmp/myagents-research/mem0ai-mem0/.cursor-plugin/`: assistant/plugin packaging surfaces; skimmed for coding-agent relevance but excluded from core runtime analysis.
- `/tmp/myagents-research/mem0ai-mem0/server/dashboard/`: dashboard UI implementation; server auth/API paths reviewed instead.
- `/tmp/myagents-research/mem0ai-mem0/openmemory/`: separate OpenMemory application surface around Mem0; useful product context, but not the core SDK/server memory architecture assigned for this review.
- `/tmp/myagents-research/mem0ai-mem0/embedchain/`: legacy/separate RAG package in the monorepo; excluded to keep focus on Mem0 memory extraction/storage/retrieval.
- `/tmp/myagents-research/mem0ai-mem0/cookbooks/`: recipe content and integration walkthroughs; representative examples reviewed instead.
- `/tmp/myagents-research/mem0ai-mem0/examples/*` not named above: broad app demos, UI demos, and integration snippets; excluded unless they clarified agent memory architecture.
- `/tmp/myagents-research/mem0ai-mem0/examples/graph-db-demo/*.ipynb`: reviewed only as evidence of stale graph guidance; excluded as a current architecture source because v3 removed graph stores.
- `/tmp/myagents-research/mem0ai-mem0/vercel-ai-sdk/`: framework adapter surface; relevant to integrations but not core memory lifecycle.
- `/tmp/myagents-research/mem0ai-mem0/cli/`: command-line wrapper behavior; lower priority than SDK/server internals for this review.
- `/tmp/myagents-research/mem0ai-mem0/poetry.lock`, `/tmp/myagents-research/mem0ai-mem0/pnpm-lock.yaml`, and package-manager lockfiles: generated dependency snapshots.
- Images, videos, fonts, PDFs, notebook outputs, and static assets under docs/examples/UI directories: binary or presentation assets, not implementation logic.
