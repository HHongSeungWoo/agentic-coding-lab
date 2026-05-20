# memgraph/memgraph

- URL: https://github.com/memgraph/memgraph
- Category: memory
- Stars snapshot: 4,009 (GitHub REST API repository search, captured 2026-05-11 in the research index)
- Reviewed commit: c2ffa84d72af1ffb3d46b1e94e0a9efeeef30aae
- Reviewed at: 2026-05-19
- Status: reviewed
- Scope fit: conditional
- Verdict: Strong graph database substrate for GraphRAG and long-term agent memory, but not itself an agent memory system. Agentic Coding Lab should copy the graph-plus-hybrid-retrieval execution patterns and operational guardrails, not the full database engine, in-process extension model, or in-database LLM calling style.

## Why It Matters

Memgraph is a production graph database that has moved directly into the AI-memory and GraphRAG framing: graph relationships are the durable memory substrate, text/vector indexes provide semantic retrieval, Cypher handles graph expansion, and query modules expose retrieval and embedding utilities. That combination maps closely to agent memory needs where a flat vector store loses provenance, relationships, permissions, and update semantics.

The repo is valuable because it shows the real machinery behind a graph memory backend: query planning, index readiness, MVCC snapshots, stream ingestion, storage durability, per-database memory tracking, auth checks, and recovery tests. Those are the parts most lightweight agent-memory designs under-specify.

## What It Is

Memgraph is a C++ graph database with Bolt/Cypher query access, in-memory transactional and analytical storage modes, optional on-disk storage through RocksDB, snapshots and WAL, replication/HA support, query modules in C++ and Python, and the MAGE algorithm library now included in-tree.

For AI memory, the relevant features are:

- Native graph model for entities, observations, relationships, labels, edge types, and properties.
- Vector indexes backed by USearch and exposed through `vector_search` query-module procedures.
- Text indexes backed by Tantivy and exposed through `text_search` query-module procedures.
- Python MAGE procedures for schema-to-prompt output, embeddings, direct LLM completion, node2vec, and Temporal Graph Networks.
- Kafka/Pulsar streams and `LOAD CSV`/`LOAD JSONL`/`LOAD PARQUET` ingestion paths.
- Auth, role checks, tenant/database boundaries, memory limits, audit hooks, stream ownership, snapshots, WAL, and replication controls.

It does not implement agent memory policy. There is no built-in notion of episodic versus semantic memory, recency/importance scoring, summarization, forgetting, conflict resolution, or prompt budget allocation.

## Research Themes

- Token efficiency: Cypher pushes filtering, traversal, ranking, and aggregation into the database before context assembly. `llm_util.schema` can emit prompt-ready graph schema text, and README examples describe single-query GraphRAG flows, but there is no prompt budget manager or compression policy.
- Context control: Labels, edge types, properties, graph traversal, text/vector indexes, active index snapshots, and transactions give precise retrieval boundaries. The control is database-level and query-level, not agent-level memory scoping or summarization.
- Sub-agent / multi-agent: Memgraph does not orchestrate agents. Its useful patterns are multi-database/tenant isolation, RBAC, stream owner checks, and concurrent query execution, which can map to multiple coding agents writing or reading separated memory spaces.
- Domain-specific workflow: Cypher is the domain workflow language. A memory workflow can be expressed as entity lookup, semantic candidate search, relationship expansion, provenance fetch, and result formatting in one query plan.
- Error prevention: MVCC, plan-cache validation against ready indexes, commit/abort callbacks, index recovery, WAL/snapshots, memory accounting, auth checks, and stream retry logic prevent stale reads, partial index use, unauthorized ingestion, and unbounded resource use.
- Self-learning / memory: Vector/text indexes, embeddings, node2vec, and TGN modules support retrieval and learned graph representations. They do not provide automatic durable memory lifecycle, trust calibration, or learning-from-agent-feedback loops.
- Popular skills: Graph modeling, Cypher retrieval, hybrid text/vector search, streaming ingestion, schema-to-prompt generation, MGP query module extension, operational memory budgeting, and index lifecycle management.

## Core Execution Path

The server starts in `src/memgraph.cpp`. It builds database configuration from flags, chooses storage mode, configures snapshots/WAL, constructs auth and DBMS handlers, sets up the interpreter context, loads query modules from the configured modules directory, restores triggers and streams, and starts the Bolt server and optional metrics/telemetry services. In HA mode, transactional in-memory data instances require WAL and snapshots, which is an important durability guard for memory stores.

Client queries enter through Bolt in `src/glue/SessionHL.cpp`. Authentication resolves the user, role, resource monitoring, and current database. Parse and prepare convert Bolt parameters to internal values, parse Cypher, record audit information in Enterprise builds, call the query interpreter, and check authorization before execution. `Pull` streams results back as Bolt values.

Cypher parsing and planning live in `src/query/cypher_query_interpreter.cpp`. Queries are normalized for AST caching, parameters are resolved from user and server scopes, `LOAD CSV` is rejected when disabled, privileges are extracted, and a logical plan is produced. Cached plans are only reused after `UsedIndexChecker` and `CheckIndicesAreReady` confirm referenced indexes are still valid and ready. That protects retrieval from stale or half-built index plans.

Transaction setup in `src/query/interpreter.cpp` creates storage accessors under `DbArenaScope`, applies timeouts, wraps storage in `DbAccessor`, and connects trigger contexts. The same file handles stream commands such as `CREATE`, `START`, `STOP`, `DROP`, `SHOW`, and `CHECK` for Kafka and Pulsar streams. Stream transformations return rows with `query` and `parameters`; each transformed query is prepared, checked against the stream owner permissions, executed in a transaction, and retried on serialization conflicts.

Storage access flows through `src/dbms/database.cpp`, `src/storage/v2/storage.hpp`, and the in-memory implementation in `src/storage/v2/inmemory/storage.cpp`. A `Database` owns storage, triggers, streams, plan cache, memory trackers, and per-database arena state. Transactions capture timestamps, isolation level, active index snapshots, constraints, point-index change collectors, and commit/abort callbacks. Recovery reconstructs vertices, edges, indices, constraints, schema info, TTL state, and timestamps from snapshots and WAL.

Hybrid retrieval is exposed at two layers. Query modules such as `query_modules/vector_search_module.cpp` and `query_modules/text_search_module.cpp` provide Cypher-callable procedures. The storage implementations in `src/storage/v2/indices/vector_index.cpp` and `src/storage/v2/indices/text_index.cpp` maintain the underlying USearch and Tantivy indexes and handle graph mutations, recovery, search sessions, and drop semantics.

## Architecture

The architecture separates user-facing query execution, storage access, index state, extension modules, and operational controls.

The query layer speaks Cypher over Bolt. It authenticates users, parses queries, plans execution, checks privileges, and streams typed results. This is the layer an agent-memory service would call through a driver or embed behind a retrieval API.

The storage layer is MVCC-oriented and index-aware. `Storage` exposes accessors for vertex/edge scans, label/property lookups, counts, text search, vector search, index creation, constraints, and transaction control. Active index snapshots let transactions see a consistent view of indexes even while background or concurrent index operations proceed.

The index layer uses specialized engines. Tantivy stores text documents with `gid`, `all`, and JSON `data` fields, supports property-specific, regex, and all-property search, and caches searchers per transaction. USearch stores numeric vector properties, supports multiple metrics and scalar kinds, tracks embedding memory, and maintains node and edge indexes through label/property change hooks.

The procedure layer embeds extensions. `include/mgp.hpp` exposes C++ APIs for text/vector search and index operations, while `include/mgp.py` exposes Python decorators for read/write procedures and functions. MAGE modules such as `llm_util.py`, `embeddings.py`, `llm.py`, `node2vec.py`, and `tgn.py` use this layer.

The ingestion layer supports direct file and network loads plus streaming systems. CSV loading can read local files, HTTP/FTP URLs, and S3; JSONL and Parquet have their own readers and S3-aware parsing paths; Kafka/Pulsar streams persist metadata, restore on startup, and execute transformation-produced Cypher under owner authorization.

The operations layer includes flags, auth, tenant/resource monitoring, snapshots, WAL, replication, Raft coordination, audit logging, memory limits, and per-database memory tracking. These controls are not secondary in a memory backend; they define whether memories survive restarts, stay isolated, and remain bounded.

## Design Choices

Memgraph treats graph structure as the primary source of truth and indexes as accelerators. Vector values are properties on graph elements; vector indexes and text indexes are maintained from graph mutations rather than serving as separate stores with separate identity systems. This keeps retrieval results attached to graph nodes and edges.

Index readiness is explicit. The concurrent index creation ADR describes register, populate, and publish phases. Queries do not use an index until it is published and ready, and cached plans are invalidated or rejected when they reference unavailable indexes. Agent memory systems should copy this distinction between "memory exists" and "memory is retrievable through this index version."

Retrieval procedures have stable, narrow shapes. `vector_search.search` takes an index name, result size, and query vector, returning node, distance, and similarity. `text_search.search` takes an index name, query, optional limit, and selected properties, returning node and score. These are good API shapes for memory retrieval because they expose ranking evidence and keep the caller aware of the retrieval surface.

Durability is tied to storage mode. Transactional in-memory mode uses WAL and snapshots; analytical mode changes constraints and snapshot behavior. The system is explicit about mode transitions and recovery. Agent memory should be similarly explicit about volatile scratch memory versus durable memory.

Query modules are powerful and risky. They allow Python and C++ procedures inside the database process, which is convenient for embeddings and graph algorithms but expands the failure and trust boundary. The repo contains stronger sandboxing patterns for auth modules than for general query modules, so the extension mechanism should be treated as privileged.

MAGE AI modules are utilities, not a memory layer. `llm_util.schema` converts graph schema to raw or prompt-ready text. `embeddings.py` writes embeddings to nodes using local SentenceTransformer or remote LiteLLM providers. `llm.py` calls a configured LLM directly from a database function. `tgn.py` and node2vec modules compute graph embeddings. None of these decide which agent facts should be remembered, merged, decayed, or forgotten.

## Strengths

Memgraph unifies graph traversal, semantic vector search, and full-text search under Cypher-callable procedures. That is the most relevant strength for an agent memory system that needs both similarity and relationships.

The execution path is transactionally serious. MVCC snapshots, active index snapshots, commit/abort callbacks, WAL, snapshots, recovery tests, and plan-cache validation all reduce the chance of retrieval observing inconsistent memory state.

The ingestion story is broad. CSV, JSONL, Parquet, S3, HTTP/FTP sources, Kafka, and Pulsar cover both batch memory import and live event streams. Streams run transformed queries under an owner permission context, which is a useful model for agent-generated memory ingestion.

Operational controls are mature. RBAC, fine-grained label and edge permissions, multi-tenant role mappings, user impersonation controls, memory limits, database-specific memory tracking, auditing, and HA/replication are directly relevant when multiple agents or teams share a memory backend.

The tests and stress workloads exercise memory-adjacent behavior: text index durability, vector index memory accounting, parallel correctness, edge and node vector search, index recovery, HA restart behavior with vector-valued properties, and MAGE embedding failure cases.

## Weaknesses

The repo is a full database, so most implementation complexity is irrelevant if the lab needs a lightweight memory layer. Copying storage engines, allocators, Raft, RocksDB integration, jemalloc tracking, or full Cypher planning would be disproportionate.

Agent memory policy is absent. There is no built-in scoring for usefulness, source trust, recency, conflict handling, retention, summarization, prompt packing, or memory review. Those policies must be designed above Memgraph.

In-process query modules create a broad trust boundary. Python and C++ modules can run near database state and process resources. That is powerful for controlled deployments but not a good default for untrusted agent-generated code or third-party memory tools.

Direct LLM calls from `llm.py` couple database execution to provider availability, environment secrets, API bases, and model behavior. This makes query execution less deterministic and increases the blast radius of prompt or provider failures.

Several AI modules keep process-local model or training state. TGN and embedding caches are useful for graph ML, but process-global ML state is not the same as durable agent memory and can be difficult to reason about across restarts, replicas, and permissions.

The prompt-ready schema utility can be verbose for large databases. It is useful as a proof of graph introspection, but a coding agent needs bounded, task-specific schema summaries.

## Ideas To Steal

Represent durable memory as a typed graph: tasks, files, symbols, decisions, failures, fixes, owners, timestamps, and evidence should be nodes and edges, not only text chunks.

Use one retrieval transaction shape: semantic candidate search, text search, graph expansion, authorization filtering, ranking, and prompt assembly should run against one consistent memory snapshot.

Separate memory identity from retrieval indexes. Store canonical facts in the graph, then maintain text/vector indexes as derived views with explicit readiness and versioning.

Expose retrieval APIs with scores and provenance. A coding agent should receive memory item, path/symbol/task provenance, retrieval reason, score, and graph neighbors rather than opaque text snippets.

Adopt index lifecycle states. Newly ingested memories should not be used by semantic retrieval until the relevant index build or update is ready; fallback graph lookup can still see the canonical write.

Track memory cost by category. Memgraph's storage, embedding, and query memory split suggests a useful lab metric: durable memory size, index size, and per-request retrieval working set.

Use stream ingestion as an owner-checked transform. Agent events can be transformed into parameterized memory writes, but each transformed write should run under the originating agent or user permissions.

Generate compact schema/context prompts from metadata. `llm_util.schema` is the right direction, but the lab should emit bounded, role-specific summaries such as "available memory node types" and "allowed retrieval predicates."

## Do Not Copy

Do not copy the whole database architecture for an agent-memory prototype. MVCC internals, WAL formats, RocksDB integration, Raft, custom allocators, and full Cypher planning are only justified if the project is building a database.

Do not run untrusted agent extensions inside the memory process. The query module model is useful for a controlled database, but agent-authored memory tools need a stricter sandbox or out-of-process execution boundary.

Do not make LLM calls from the durable storage layer. Keep provider calls in the agent/application layer so retries, redaction, model choice, tracing, and prompt policy remain explicit.

Do not treat graph embeddings as memory semantics. Node2vec and TGN can enrich retrieval, but they cannot replace source records, explicit relationships, timestamps, and reviewable memory decisions.

Do not expose full schema dumps to prompts by default. Large prompt-ready schema strings can waste context and leak structure irrelevant to the current task.

Do not copy the broad MAGE algorithm surface into the lab. Most algorithms are useful for graph analytics, not day-to-day coding memory retrieval.

Do not ignore index drop/update memory costs. The vector index drop path must reconstruct property values and checks memory limits; a lighter system still needs accounting for reindexing and compaction spikes.

## Fit For Agentic Coding Lab

Memgraph is conditionally in scope. It is a strong reference implementation for graph-backed memory, hybrid retrieval, index lifecycle, ingestion, and operational safety. It is not a drop-in model for the lab's own memory semantics.

The best fit is as a design source for a compact memory service: typed graph schema, canonical fact storage, derived text/vector indexes, consistent retrieval snapshots, owner-aware ingestion, and bounded context assembly. If the lab later needs a production graph backend, Memgraph could be evaluated as an optional backend behind the same memory API.

The lab should not depend on Memgraph-specific Cypher or MGP procedures as the core abstraction. The portable abstraction should be "write reviewed memory fact," "retrieve task-relevant memory with provenance," "expand related graph context," "mark index version ready," and "enforce scope and budget."

## Reviewed Paths

- `README.md`: product positioning, GraphRAG/AI memory claims, hybrid search, MAGE, schema introspection, ingestion, and enterprise controls.
- `mage/README.md`: MAGE integration, query module loading, available algorithms and AI modules.
- `ADRs/001_tantivy.md`, `ADRs/003_rocksdb.md`, `ADRs/004_concurrent_index_creation.md`, `ADRs/005_usearch.md`, `ADRs/005_multi_tenant_rbac.md`, `ADRs/007_db_specific_memory_tracking.md`: text/vector/storage/index/RBAC/memory-tracking design choices.
- `src/memgraph.cpp`: server bootstrap, storage/auth/interpreter/module/stream setup, HA durability checks.
- `src/glue/SessionHL.cpp`: Bolt session authentication, parsing, preparation, authorization, and result streaming.
- `src/query/cypher_query_interpreter.cpp`: AST cache, parameter handling, `LOAD CSV` guard, privilege extraction, plan cache, and index readiness checks.
- `src/query/interpreter.cpp`: transaction setup, vector index config parsing, Kafka/Pulsar stream command handling, stream execution flow.
- `src/query/db_accessor.cpp`: query-layer delegation for text and vector search.
- `src/dbms/database.hpp`, `src/dbms/database.cpp`: database-owned storage, streams, triggers, plan cache, memory trackers, and background shutdown.
- `src/storage/v2/storage.hpp`, `src/storage/v2/storage.cpp`, `src/storage/v2/transaction.hpp`, `src/storage/v2/inmemory/storage.cpp`: storage accessors, transaction state, active indices, recovery, snapshots, WAL, and storage modes.
- `src/storage/v2/indices/vector_index.cpp`, `src/storage/v2/indices/vector_index_utils.hpp`: USearch vector index creation, mutation maintenance, search, serialization, memory tracking, and drop safeguards.
- `src/storage/v2/indices/text_index.cpp`: Tantivy text index creation, recovery, transaction search sessions, mutation tracking, and deferred drop.
- `query_modules/vector_search_module.cpp`, `query_modules/text_search_module.cpp`: Cypher-callable retrieval procedures and result shapes.
- `include/mgp.hpp`, `include/mgp.py`, `src/query/procedure/module.hpp`, `src/query/procedure/module.cpp`: extension APIs and query module loading/reloading.
- `mage/python/llm_util.py`, `mage/python/embeddings.py`, `mage/python/llm.py`, `mage/python/node2vec.py`, `mage/python/tgn.py`, `query_modules/node2vec_online_module/node2vec_online.py`: AI-adjacent schema, embedding, LLM, and graph-embedding modules.
- `src/csv/parsing.cpp`, `src/query/jsonl/reader.cpp`, `src/query/arrow_parquet/reader.cpp`, `src/query/frontend/ast/cypher_main_visitor.cpp`, `src/query/stream/streams.cpp`: batch and streaming ingestion paths.
- `config/flags.yaml`: operational defaults for storage, memory, query modules, loading, schema metadata, indexes, logging, and security-sensitive toggles.
- `src/glue/auth_checker.cpp`, `src/auth/models.hpp`, `src/query/trigger_privilege_context.hpp`, `src/auth/module.cpp`: auth/RBAC, trigger privilege context, and auth-module sandboxing contrast.
- `tests/unit/text_index.cpp`, `tests/unit/cpp_api.cpp`, `tests/e2e/durability/durability_with_text_index.py`, `tests/e2e/memory/db_memory_tracking.py`, `tests/e2e/memory/vector_index_memory.py`, `tests/e2e/drop_queries/drop_all_indexes.py`, `tests/e2e/parallel/test_parallel_correctness.py`: focused text/vector/memory/index behavior tests.
- `tests/mgbench/workloads/vector_search_index.py`, `tests/mgbench/workloads/vector_search_edge_index.py`, `tests/mgbench/workloads/text_search_index.py`, `tests/mgbench/workloads/text_search_edge_index.py`: benchmark query patterns for retrieval.
- `tests/stress/ha/workloads/rag/workload.py`, `tests/stress/vector_index_concurrent_ops`, `tests/stress/vector_index_recovery`, `tests/stress/vector_edge_index_recovery`: HA and vector-index stress behavior relevant to durable memory retrieval.
- `mage/tests/e2e/embeddings_test`, `mage/tests/e2e/llm_util_test`: embedding and schema utility behavior, including remote-provider and failure cases.

## Excluded Paths

- Generated build outputs, local build directories, and binary artifacts were not reviewed because they do not define memory architecture or execution behavior.
- Vendored or third-party dependency material such as `libs`, `licenses/third-party`, Conan recipes, package-manager lock detail, and bundled external code was excluded except where ADRs identify the design reason for choosing Tantivy, USearch, or RocksDB.
- Release, packaging, CI, Docker, environment, and installer paths were excluded except for configuration implications already visible in `config/flags.yaml`; they affect deployment shape more than agent-memory design.
- UI, marketing, screenshots, cloud/lab/playground surfaces, and external documentation links were excluded because this review focuses on server-side memory, retrieval, ingestion, indexing, and safety paths.
- Broad MAGE algorithm modules unrelated to memory retrieval or learned graph context, such as graph coloring, routing, community algorithm wrappers, GPU wrappers, and general analytics examples, were excluded after confirming the relevant AI/memory modules were `llm_util`, `embeddings`, `llm`, `node2vec`, `node2vec_online`, and `tgn`.
- Large exhaustive test matrices were sampled by behavior area rather than line-by-line. The reviewed tests covered text/vector retrieval, durability, memory accounting, index dropping, parallel correctness, MAGE embedding/schema behavior, and HA/vector stress paths, which are the parts relevant to agent memory.
