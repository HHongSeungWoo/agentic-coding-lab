# neo4j-labs/agent-memory

- URL: https://github.com/neo4j-labs/agent-memory
- Category: memory
- Stars snapshot: 281 (GitHub REST API repository search, captured 2026-05-29 in `research/index.md`; GitHub page checked 2026-05-29)
- Reviewed commit: 208733c1aa229b07011ce7afe310fc82d72b47e1
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong graph-native memory reference for the index, especially for typed memory schema, message-to-entity ingestion, reasoning/tool provenance, MCP integration, and Neo4j persistence. Treat the Python Bolt backend as the canonical implementation; the hosted NAMS and TypeScript paths expose a smaller surface and are less useful as full memory-system references.

## Why It Matters

This repo is a concrete implementation of agent memory as a property graph, not just vector recall. It models conversations, messages, entities, preferences, facts, reasoning traces, reasoning steps, tool calls, users, audit records, and consolidation runs as connected Neo4j data. That makes it relevant to coding-agent research where useful recall is often relational: which task touched which file or domain object, which tool call produced an observation, which user or session owns the memory, and which earlier traces are similar enough to reuse.

The repo also matters because it exposes the memory through agent-facing APIs: a Python SDK, MCP tools, framework adapters, and a TypeScript SDK for the hosted backend. It is a good candidate to mine for schema patterns and agent integration boundaries, with clear caveats around privacy defaults, hosted-backend feature gaps, and vector-search dependence.

## What It Is

`agent-memory` is an async Python package plus hosted-backend clients for storing short-term, long-term, and reasoning memory in Neo4j. Short-term memory stores `Conversation` and `Message` nodes with ordered message relationships. Long-term memory stores entities, preferences, facts, and relationships. Reasoning memory stores traces, steps, tools, tool calls, outcomes, metrics, and `TOUCHED` edges from reasoning steps to entities.

The Python `MemoryClient` chooses the Bolt backend by default, or the NAMS hosted backend when configured with an API key. Bolt mode sets up Neo4j schema, vector indexes, extractors, resolvers, geocoding, enrichment, buffered writes, consolidation, eval, and read-only Cypher access. NAMS mode maps to HTTP APIs for conversations, entities, observations, reflections, flat reasoning steps, feedback, history, and provenance, while several Bolt-only features intentionally raise `NotSupportedError`.

## Research Themes

- Token efficiency: Provides `get_context()` aggregation and an MCP observer that produces observations/reflections after large conversations, but the Bolt observer is in-memory and not a durable compression layer.
- Context control: Strong fit. Memory is split into short-term, long-term, reasoning, user, audit, and consolidation regions, and MCP profiles gate core versus extended tools.
- Sub-agent / multi-agent: Useful primitives exist through user scoping, session scoping, reasoning traces, tool-call records, and touched-entity edges, but there is no dedicated multi-agent coordination model.
- Domain-specific workflow: Strong. The graph schema supports POLE+O-style entity types plus custom labels, existing-graph adoption, geospatial fields, enrichment, and framework integrations.
- Error prevention: Reasoning traces persist `success`, `error_kind`, metrics, tool status, and touched entities, which can support failure-memory retrieval and postmortems.
- Self-learning / memory: Primary theme. Entity deduplication, preference supersedence, fact confidence, consolidation jobs, and provenance APIs make the repo directly relevant.
- Popular skills: The most reusable patterns are `memory_get_context`, `memory_store_message`, `memory_add_entity`, `memory_add_preference`, `memory_start_trace`, `memory_record_step`, `memory_complete_trace`, read-only graph query, and explicit touched-entity recording.

## Core Execution Path

The main Bolt path starts in `MemoryClient.connect()`: it opens a Neo4j driver, creates the managed schema, validates vector dimensions, wires the embedder/extractor/resolver/geocoder/enrichment services, then exposes `short_term`, `long_term`, `reasoning`, `users`, `buffered`, `consolidation`, `eval`, and `query`.

Short-term ingestion calls `short_term.add_message(session_id, role, content, ...)`. It ensures a `Conversation`, embeds the message when an embedder is configured, writes the `Message`, links it into the conversation order, and optionally extracts entities and relationships from content. Extraction can be automatic, skipped, or explicit via caller-provided entity refs. Automatic extraction writes `MENTIONS` and relation edges; the richer `EXTRACTED_FROM` and `EXTRACTED_BY` provenance APIs live in long-term memory and need explicit use.

Long-term ingestion calls `long_term.add_entity`, `add_preference`, `add_fact`, or `create_relationship`. Entities are normalized, optionally resolved, embedded, deduplicated, geocoded, enriched, and then stored as `Entity` nodes with type/subtype labels. Preferences can be scoped to a `User`, linked to entities with `APPLIES_TO`, and superseded with `SUPERSEDED_BY`. Facts store subject/predicate/object, validity windows, embeddings, and confidence.

Reasoning ingestion starts a trace, appends steps, records tool calls, and completes the trace. `record_tool_call()` creates `ToolCall` and `Tool` data, updates usage stats, and can materialize `TOUCHED` edges from a reasoning step to entities. `complete_trace()` persists structured outcomes including `success`, `error_kind`, metrics, and related entities.

Retrieval is centered on `MemoryClient.get_context()`, which combines recent conversation context, relevant long-term knowledge, and similar reasoning traces. Search APIs lean heavily on Neo4j vector indexes for messages, entities, preferences, facts, reasoning steps, and task traces, with limited non-vector fallback paths.

## Architecture

The graph architecture is explicit and broad. Schema setup creates constraints for conversations, messages, entities, preferences, facts, reasoning traces, reasoning steps, tools, tool calls, users, consolidation runs, and read audits. It creates regular indexes for session, role, timestamp, entity type/name/canonical name, preference category, reasoning trace session/success/error kind, tool-call status, and consolidation/audit kinds. It also creates vector indexes for messages, entities, preferences, facts, tasks, and reasoning steps, plus a point index for entity location.

The memory modules map cleanly to graph regions. `short_term.py` owns conversations and messages. `long_term.py` owns entities, preferences, facts, relations, provenance, and deduplication. `reasoning.py` owns traces, steps, tools, tool calls, outcomes, and touched edges. `buffered.py` supplies optional queued writes. `consolidation.py` supplies dry-runnable hygiene jobs and read-audit records. `users.py` owns user nodes and user-scoped edges.

Agent integration is layered above these modules. The MCP server exposes core and extended tool profiles with instructions that tell agents to retrieve context, store important facts/preferences/entities, and trace complex tasks. Framework adapters use a `MemoryIntegration` wrapper that converts agent events into memory writes and catches memory errors as structured return values.

The backend split is material. Bolt is the full graph-memory implementation. NAMS uses an HTTP transport with API-key auth, retry/backoff in Python, and REST mappings for hosted conversations/entities/observations/reflections and flat reasoning. TypeScript targets NAMS by default and mirrors the hosted surface rather than the full Bolt surface.

## Design Choices

The most valuable design choice is making graph edges first-class memory. Messages mention entities, users own conversations/preferences/traces, preferences apply to entities, preferences supersede older preferences, reasoning steps use tools, tool calls instantiate tools, reasoning steps touch entities, and audit nodes record sensitive reads when call sites opt in.

The repo uses managed schema creation rather than requiring users to hand-author Cypher. It validates vector-index dimensions at connection time and raises a specific embedding-dimension mismatch error for managed indexes. Dynamic entity labels are sanitized before being used in Cypher, which keeps custom types practical without making label injection easy.

Ingestion is intentionally configurable. Callers can turn extraction off, pass explicit mentions, run batch message loading, defer embeddings, use a buffered writer, adopt an existing graph by attaching the `Entity` super-label, or run dry-run consolidation jobs before mutating memory. This makes the system usable both for online agents and migration/maintenance workflows.

The privacy and audit posture is explicit but conservative. Multi-tenant guardrails can require `user_identifier` on affected writes. Audit records are callsite-explicit rather than transparent. Message-content encryption is represented by a protocol and a `NoOpEncrypter`, not a shipped cipher.

## Strengths

- Rich graph schema that covers conversation memory, semantic memory, user scoping, reasoning traces, tool use, audit, and consolidation.
- Practical ingestion modes: automatic extraction, explicit mentions, batch messages, existing-graph adoption, buffered writes, geocoding, and enrichment hooks.
- Strong retrieval composition through `get_context()` plus vector indexes and graph export/query APIs.
- Useful provenance and conflict primitives: extractor registration, entity-source links, `SAME_AS`, pending duplicate review, merge, preference supersedence, `TOUCHED` edges, consolidation runs, and read-audit nodes.
- Broad agent surface through MCP tools, MCP instructions, Python SDK, framework integrations, and hosted/TypeScript clients.
- Tests cover important system behavior including schema validation, query-builder sanitization, deduplication, provenance tracking, touched edges, buffered writes, multi-tenant guardrails, privacy docs paths, MCP tools, and NAMS unsupported methods.

## Weaknesses

- The full feature set is Bolt-only. NAMS and the TypeScript hosted path lack or synthesize important features such as full traces, preferences/facts in several flows, relationship writes, list traces, similar traces, user memory, buffered writes, and consolidation.
- Retrieval depends heavily on embeddings and Neo4j vector indexes. If embeddings are disabled or indexes are unavailable, many search paths return empty results or fall back only to narrow filters.
- Automatic message extraction writes `MENTIONS` relationships but does not automatically attach the richer `EXTRACTED_FROM` and `EXTRACTED_BY` provenance links from long-term memory.
- Conflict handling is useful but partial. Entity merges transfer selected relationships and aliases, while relationship families such as extracted-from, applies-to, and arbitrary domain edges need careful review in production use.
- Audit and privacy controls are opt-in. There is no default redaction layer, no default encryption implementation, and no transparent read auditing.
- Multi-tenant conversation scoping still depends on disciplined session IDs: tests document that reusing the same `session_id` under two users can attach both users to the same conversation.
- The read-only Cypher guard and MCP `graph_query` filter are heuristic, so production deployments should restrict tool exposure and credentials rather than relying on string filtering alone.

## Ideas To Steal

- Model agent memory as connected graph regions instead of only vector collections: conversation history, semantic facts, preferences, reasoning traces, tool calls, and touched domain objects.
- Add explicit `TOUCHED` edges from reasoning/tool steps to entities so future agents can ask which prior actions interacted with a project, file, customer, package, or incident.
- Use `get_context()` as a single high-level retrieval contract that composes short-term, long-term, and reasoning memory behind one agent call.
- Validate vector dimensions for managed indexes at startup and fail with a targeted migration error rather than silently returning poor retrieval.
- Offer an explicit mention mode for agents that already know the relevant entities, avoiding unnecessary LLM extraction on structured tool outputs.
- Support dry-run consolidation and existing-graph adoption so memory can evolve without forcing a destructive migration.
- Keep memory tools profiled: a small core set for most agents and an extended set for inspection, graph export, trace operations, and Cypher reads.

## Do Not Copy

- Do not assume a hosted REST memory surface can stand in for the full graph backend unless the feature contract is narrowed and documented.
- Do not expose unrestricted graph query tools to coding agents; combine read-only credentials, allowlisted query shapes, and deployment-level isolation.
- Do not make provenance optional for automatically extracted memories if the downstream system needs auditability or rollback.
- Do not rely on in-memory reflections as durable compression for long-running coding agents.
- Do not treat user-edge scoping alone as tenant isolation; use tenant-aware session IDs and database/credential boundaries for stronger isolation.
- Do not ship a `NoOpEncrypter` as an implied privacy solution; it is only an integration seam.

## Fit For Agentic Coding Lab

This repo is highly relevant as a memory-system reference. For Agentic Coding Lab, the best adaptation would map coding artifacts into graph entities: repositories, files, modules, branches, issues, plans, tests, tools, commands, errors, dependencies, and users. Reasoning traces and `TOUCHED` edges are especially applicable to coding agents because they can record which files, tests, packages, or architectural concepts were affected by each tool call.

The repo is less compelling as a direct drop-in for the lab without a backend decision. A Neo4j-backed lab memory could borrow the Bolt schema, startup validation, explicit memory tools, and trace model. A lightweight local index should borrow the contracts and graph semantics, but not the Neo4j-specific operational assumptions. The hosted NAMS/TypeScript surface should be treated as an integration example rather than the complete memory architecture.

## Reviewed Paths

- `README.md`
- `pyproject.toml`
- `src/neo4j_agent_memory/__init__.py`
- `src/neo4j_agent_memory/config/settings.py`
- `src/neo4j_agent_memory/graph/schema.py`
- `src/neo4j_agent_memory/graph/client.py`
- `src/neo4j_agent_memory/graph/query_builder.py`
- `src/neo4j_agent_memory/graph/queries.py`
- `src/neo4j_agent_memory/memory/short_term.py`
- `src/neo4j_agent_memory/memory/long_term.py`
- `src/neo4j_agent_memory/memory/reasoning.py`
- `src/neo4j_agent_memory/memory/buffered.py`
- `src/neo4j_agent_memory/memory/consolidation.py`
- `src/neo4j_agent_memory/memory/users.py`
- `src/neo4j_agent_memory/extraction/base.py`
- `src/neo4j_agent_memory/extraction/pipeline.py`
- `src/neo4j_agent_memory/extraction/factory.py`
- `src/neo4j_agent_memory/extraction/llm_extractor.py`
- `src/neo4j_agent_memory/mcp/server.py`
- `src/neo4j_agent_memory/mcp/_tools.py`
- `src/neo4j_agent_memory/mcp/_instructions.py`
- `src/neo4j_agent_memory/mcp/_observer.py`
- `src/neo4j_agent_memory/nams/`
- `typescript/src/`
- `docs/modules/ROOT/pages/reference/schema-objects.adoc`
- `docs/modules/ROOT/pages/how-to/privacy-and-audit.adoc`
- `docs/modules/ROOT/pages/how-to/multi-tenancy.adoc`
- `tests/unit/test_query_builder.py`
- `tests/unit/test_index_validate.py`
- `tests/unit/test_entity_deduplication.py`
- `tests/unit/test_provenance_tracking.py`
- `tests/unit/test_buffered_writer.py`
- `tests/unit/nams/test_unsupported.py`
- `tests/integration/test_multi_tenant_scoping.py`
- `tests/integration/test_touched_edges.py`

## Excluded Paths

I excluded generated assets, diagrams, packaging metadata that did not affect the memory design, broad documentation pages that duplicate the reviewed API details, and most framework/demo examples after confirming the integration pattern through README and MCP/SDK code. I also did not run the upstream repo's Neo4j-backed integration suite because this review only required repository inspection and the local research validation script.
