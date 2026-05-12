# getzep/graphiti

- URL: https://github.com/getzep/graphiti
- Category: agent-support-systems
- Stars snapshot: 25,936 (GitHub REST API, captured 2026-05-12)
- Reviewed commit: c427615044678f4bde026745d8d28a16504868c5
- Reviewed at: 2026-05-12 (Asia/Seoul)
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong candidate for a temporal knowledge graph memory substrate for agents. The architecture is worth adapting, but production use needs explicit auth, retention, model-provider, and "current fact only" retrieval policies.

## Why It Matters

Graphiti is an open-source temporal knowledge graph memory engine built for AI agents that need durable, queryable, evolving facts rather than flat chat-history recall. It models raw events as episodic provenance, extracted entities as nodes, and factual relations as temporal edges with validity windows and contradiction handling.

That makes it directly relevant to coding-agent memory. Repository facts, user preferences, architecture decisions, prior failures, dependency constraints, task state, and environment quirks can be represented as time-scoped facts with source episodes.

The repo is also unusually useful for research because it exposes the full memory stack: extraction prompts, entity and edge deduplication, invalidation logic, graph drivers, hybrid retrieval, MCP/server integrations, tests, and eval scaffolding.

## What It Is

Graphiti is the open-source Python engine behind temporal graph memory for agents. It ingests text, message, JSON, or fact-triple episodes, stores each raw source event as an `EpisodicNode`, extracts entities and relation facts through LLM calls, resolves them against an existing graph, and stores durable facts as `EntityEdge` records with provenance and temporal metadata.

The default stack uses Neo4j plus OpenAI LLM, embedding, and reranking clients. It also supports FalkorDB, Kuzu, and Neptune drivers, OpenAI-compatible local or hosted model endpoints, optional custom entity and edge schemas, an experimental MCP server, and a FastAPI service.

## Research Themes

- Token efficiency: Graphiti reduces prompt load by retrieving fact edges, entity summaries, episodes, and communities on demand instead of replaying whole histories. It still needs caller-side budget control because search recipes return bounded result sets, not token-budgeted prompt packs.
- Context control: Strong. Retrieval can be scoped by `group_id`, result limits, search filters, edge types, node labels, date ranges, center nodes, BFS origin nodes, and reranking recipes. Current-versus-historical fact semantics are available through filters but are not automatic.
- Sub-agent / multi-agent: Conditional. The MCP server exposes shared memory tools and the queue service processes writes per group, but the repo does not implement multi-agent coordination, claims, permissions, or conflict policy.
- Domain-specific workflow: Strong. Custom Pydantic entity and edge schemas let a coding-agent deployment model repositories, files, APIs, tasks, decisions, commands, bugs, and preferences instead of relying on generic entities.
- Error prevention: Useful as support infrastructure. Temporal provenance and contradiction handling can prevent stale-memory reuse, and tests cover query safety and label validation. It does not verify extracted coding facts against source files by itself.
- Self-learning / memory: Core fit. The system is explicitly designed for long-lived, incrementally updated memory with entity/relation extraction, node summaries, fact invalidation, and provenance.
- Popular skills: Temporal fact memory, episodic provenance, schema-guided extraction, hybrid retrieval, contradiction-aware updates, graph-scoped memory, MCP memory tools, and source-backed context formatting.

## Core Execution Path

The main ingestion path is `Graphiti.add_episode` in `graphiti_core/graphiti.py`.

1. Validate entity types, excluded entity types, source type, and `group_id`.
2. Retrieve prior episodes for context, usually the latest relevant window unless explicit previous episode UUIDs are provided.
3. Build and save an `EpisodicNode` for the raw source event.
4. Extract candidate entities from the episode with source-specific prompts for message, text, or JSON.
5. Resolve extracted entities through semantic candidate search, exact/fuzzy deterministic helpers, and LLM dedupe.
6. Extract relation facts constrained to the resolved entity list, preserving source/target names, fact text, relation type, episode references, and temporal fields.
7. Resolve extracted edges against existing graph edges, including duplicate detection and contradiction/invalidation checks.
8. Extract or update entity attributes and summaries from new facts.
9. Create episode-to-entity `MENTIONS` edges, generate embeddings, and persist nodes and edges through the configured graph driver.
10. Optionally update communities and saga summaries.

Bulk ingestion follows the same broad sequence but saves all episodes first, uses a shorter rolling episode window, resolves nodes and edges across the batch, then saves the resulting graph changes together.

The basic search path starts at `Graphiti.search` or `Graphiti.search_`, selects a recipe from `search_config_recipes.py`, computes query embeddings if needed, runs edge/node/episode/community search methods concurrently, reranks results, and can format them into context strings. Supported retrieval methods include BM25/full-text search, vector similarity search, BFS graph expansion, reciprocal rank fusion, maximal marginal relevance, node-distance reranking, episode-mentions reranking, and cross-encoder reranking.

## Architecture

The core graph model is compact and agent-friendly:

- `EpisodicNode`: raw source event with source type, source description, content, valid time, and related entity edge UUIDs.
- `EntityNode`: durable entity with labels, name, summary, name embedding, and custom attributes.
- `EntityEdge`: factual relation with source/target entity UUIDs, fact text, fact embedding, provenance episodes, custom attributes, validity times, expiration time, and reference time.
- `CommunityNode` and `CommunityEdge`: optional graph clustering and summary layer.
- `SagaNode`, `HasEpisodeEdge`, and `NextEpisodeEdge`: sequential episode chains and rolling saga summaries.

Extraction lives mainly in `graphiti_core/utils/maintenance/node_operations.py`, `edge_operations.py`, `combined_extraction.py`, and `graph_data_operations.py`. Prompts under `graphiti_core/prompts/` drive entity extraction, edge extraction, dedupe, contradiction detection, node summaries, and saga summaries. The prompts explicitly discourage generic entities, pronouns, abstract concepts, and date-only entities, and relation extraction is constrained to the known entity list.

Retrieval is recipe-based. `graphiti_core/search/search_config.py` defines search methods and rerankers; `search_config_recipes.py` combines them into default recipes; `search.py` executes configured searches; and `search_utils.py` implements BM25/full-text search, vector search, BFS expansion, Lucene sanitization, group ID validation, reranking, and context formatting.

Persistence is abstracted through `GraphDriver`. Neo4j is the default async driver with graph indexes and constraints. FalkorDB stores per-group graph namespaces and stringifies datetimes. Kuzu adapts around missing edge full-text support by materializing relation edges as nodes. Neptune support combines Neptune Database/Analytics with OpenSearch Serverless for full-text search.

The MCP server wraps Graphiti as assistant memory tools: `add_memory`, `search_nodes`, `search_memory_facts`, deletion tools, status, and health checks. It also includes a per-group queue service so writes for the same group are serialized. The FastAPI server provides similar ingestion and retrieval endpoints, including a `/get-memory` route that builds a query from recent messages.

## Design Choices

Graphiti chooses temporal edges over destructive overwrites. When a new fact contradicts an older fact, the older edge can remain in the graph with `invalid_at` or `expired_at` set. This preserves historical knowledge while allowing current-state retrieval if callers filter correctly.

It separates raw episodes from extracted facts. This gives agents both compact fact recall and provenance lookup, which is important when memory is used to justify actions.

It uses structured extraction with optional domain schemas. Custom entity and edge types make the system adaptable to coding-agent domains, but extraction quality depends on schema design and model behavior.

It combines deterministic and LLM-based resolution. Exact and fuzzy helpers handle obvious dedupe cases; semantic search narrows candidates; LLM calls handle ambiguous names and relation conflicts.

It keeps retrieval configurable instead of prescribing one memory answer. Search recipes can favor fact edges, nodes, episodes, graph neighborhoods, or communities depending on the calling agent's context need.

It treats graph backends as pluggable. This makes the design portable, but backend differences are real and need direct testing because full-text support, datetime handling, transactions, and schema constraints differ.

## Strengths

- Temporal facts are first-class through `valid_at`, `invalid_at`, `expired_at`, and `reference_time`.
- Provenance is explicit because facts keep source episode UUIDs.
- Ingestion is incremental and does not require full re-indexing for every new event.
- Retrieval is hybrid across BM25, embeddings, graph traversal, and reranking.
- Custom schemas support domain-specific agent memory rather than generic note storage.
- The MCP server gives assistant clients a practical tool surface for add/search/delete/status workflows.
- Query-safety work is visible in code and tests: group IDs and node labels are validated, Lucene queries are sanitized, and tests cover validation bypass attempts.
- Examples cover quickstart ingestion, graph-distance reranking, e-commerce preference memory, LangGraph integration, local model setup, and larger text ingestion.

## Weaknesses

- Privacy defaults need tightening for sensitive agent memory. The default stack uses OpenAI for LLM calls, embeddings, and reranking, and `store_raw_episode_content=True` persists raw content unless changed.
- Telemetry is opt-out by default. The implementation sends provider/backend/version-style metadata through PostHog with an anonymous local ID; the README says it does not send content, API keys, IP addresses, or personally identifiable information.
- The MCP and FastAPI servers are memory tools, not full security boundaries. The reviewed server code does not provide built-in auth or authorization.
- `group_id` is a useful namespace and retrieval partition, but it is not a complete tenant isolation or authorization model.
- Default search does not inherently mean "only current facts." Date filters exist in `SearchFilters`, but callers must apply valid/invalid time filters deliberately.
- The basic `Graphiti.search` method mutates the selected global recipe object's `limit`, which is a shared-state risk in concurrent or mixed-use callers.
- Dense content chunking helpers and tests exist, and an example describes automatic chunking for dense content, but the reviewed `Graphiti.add_episode` path does not appear to invoke those helpers.
- Extraction quality depends heavily on LLM behavior and prompt/schema design. The included tests check many mechanics, but production memory quality still needs domain-specific evals.

## Ideas To Steal

- Store every memory as an episode plus extracted facts, not as a summary alone.
- Give facts validity windows and expiration state so stale knowledge can remain auditable without being treated as current.
- Keep provenance episode IDs on every fact and retrieve source episodes when confidence matters.
- Combine BM25, vector search, graph traversal, and reranking instead of selecting one retrieval primitive.
- Use schema-specific entity and edge extraction for coding-agent domains.
- Resolve memory updates through candidate search plus deterministic and LLM dedupe instead of blindly appending.
- Expose memory through explicit tools for adding, searching, deleting, and inspecting facts.
- Serialize writes by memory namespace or task group to reduce race conditions during concurrent agent work.

## Do Not Copy

- Do not expose the MCP or FastAPI server directly without auth, authorization, rate limits, and network controls.
- Do not treat `group_id` as sufficient access control.
- Do not send private source, secrets, or user data to default model providers without an explicit data policy.
- Do not store raw episodes by default for sensitive codebases unless retention and redaction rules are clear.
- Do not assume search results are current facts unless valid/invalid time filters are applied.
- Do not rely on generic extraction schemas for coding agents; repository, file, task, symbol, command, bug, and decision entities need explicit modeling.
- Do not copy backend abstractions without backend-specific tests for transactions, indexes, datetime behavior, and full-text behavior.
- Do not rely on LLM extraction as verification of source-code truth; coding facts still need source-file or command-based confirmation.

## Fit For Agentic Coding Lab

Graphiti is a high-fit research candidate for long-horizon coding-agent memory. It directly addresses persistent memory, provenance, temporal invalidation, domain schemas, and retrieval-time context shaping. The most useful adaptation would be a coding-specific memory layer on top of Graphiti-style primitives, not a raw drop-in of the default server.

A practical lab integration would model episodes such as repo scans, user instructions, issue context, reviewed files, command outcomes, dependency decisions, failed attempts, successful fixes, and final summaries. Entity types should include repository, branch, file, symbol, package, task, user preference, decision, bug, command, environment, and external service. Retrieval should be scoped by workspace/repo/task, use date filters for current facts, center graph-distance search on known repository or file nodes, and include source episodes for high-risk recommendations.

Before production use, the lab would need auth, per-user/repo authorization, retention policy, audit logging, telemetry controls, local or contracted model-provider configuration, redaction, and deterministic verification for extracted coding facts.

## Reviewed Paths

- `README.md`: project positioning, temporal graph model, ingestion/retrieval overview, requirements, telemetry note, and quickstart.
- `SECURITY.md` and `OTEL_TRACING.md`: security reporting and observability/tracing notes.
- `graphiti_core/graphiti.py`: main ingestion, search, triplet insertion, deletion, and saga summarization entry points.
- `graphiti_core/nodes.py` and `graphiti_core/edges.py`: graph primitives for episodes, entities, communities, sagas, facts, mentions, and temporal metadata.
- `graphiti_core/utils/maintenance/node_operations.py`, `edge_operations.py`, `graph_data_operations.py`, `community_operations.py`, `saga_operations.py`, and `combined_extraction.py`: extraction, deduplication, contradiction handling, persistence helpers, and optional combined extraction.
- `graphiti_core/prompts/`: entity extraction, edge extraction, dedupe, node summaries, saga summaries, and invalidation prompts.
- `graphiti_core/search/`: search config, recipes, execution, utilities, filters, rerankers, full-text safety, context formatting, and query expansion.
- `graphiti_core/driver/`: Neo4j, FalkorDB, Kuzu, Neptune, query builders, driver abstraction, and index/constraint behavior.
- `graphiti_core/llm_client/`, `embedder/`, and `cross_encoder/`: default OpenAI clients, generic OpenAI-compatible clients, Voyage/Gemini/Ollama-related support, and local embedding options.
- `graphiti_core/telemetry.py`: opt-out telemetry implementation and anonymous ID behavior.
- `mcp_server/README.md`, `mcp_server/config/config.yaml`, `mcp_server/src/graphiti_mcp_server.py`, and `mcp_server/src/services/queue_service.py`: MCP setup, default entity types, memory tools, per-group queueing, and health/status behavior.
- `server/`: FastAPI ingestion/retrieval routers, queueing, entity-edge operations, and service entry points.
- `examples/quickstart/`, `examples/ecommerce/`, `examples/langgraph-agent/`, `examples/podcast/`, `examples/wizard_of_oz/`, `examples/local_rag/`, and `examples/product_search_demo/`: examples for ingestion, search recipes, graph-distance reranking, agent integration, local models, and data loading.
- `tests/`: unit and integration coverage for extraction, dedupe, edge resolution, search security, label validation, triplet insertion, content chunking helpers, drivers, and eval harnesses.
- Repository docs note: there is no top-level `docs/` directory at the reviewed commit. Documentation was reviewed from README files, root docs, MCP docs, examples, and source-level structure.

## Excluded Paths

- `.git/`: clone metadata, not project architecture.
- `images/` and image assets under examples: screenshots and visual material; not relevant to memory architecture except where README referenced them.
- `uv.lock`, `server/uv.lock`, and `mcp_server/uv.lock`: generated dependency lockfiles; dependency presence was inferred from `pyproject.toml` and source imports instead.
- `tests/evals/data/longmemeval_data/longmemeval_oracle.json`: large external evaluation corpus; reviewed eval code and dataset provenance rather than line-by-line dataset content.
- `examples/podcast/*.txt` and `examples/wizard_of_oz/woo.txt`: sample ingestion corpora; reviewed parsers/runners and ingestion shape instead of raw text in full.
- `.github/`, badges, CLA/code-of-conduct/legal files, Docker/deployment scaffolding, and signatures: skimmed for verification and maintenance signals, but excluded from deep architecture analysis.
- UI/demo-only presentation details in `examples/product_search_demo/`: reviewed for memory/search integration, not frontend behavior.
- No vendored source snapshots were found that needed deep review beyond lockfiles and external sample/eval data.
