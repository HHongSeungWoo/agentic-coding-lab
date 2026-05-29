# trustgraph-ai/trustgraph

- URL: https://github.com/trustgraph-ai/trustgraph
- Category: agent-support-systems
- Stars snapshot: 2,118 (GitHub REST API, captured 2026-05-29)
- Reviewed commit: dcee84245525f08f0c64156ac536e628704616a2
- Reviewed at: 2026-05-29 (Asia/Seoul)
- Status: reviewed
- Scope fit: conditional
- Verdict: Strong reference for graph-backed agent runtime architecture, provenance, and workflow orchestration. It is more useful as a pattern library for context graphs and auditable retrieval than as a direct coding-agent dependency, because the platform is broad, operationally heavy, and some integration surfaces are still drifting.

## Why It Matters

TrustGraph is one of the clearer open-source examples of an agent-support platform that treats context as a graph-backed runtime substrate rather than as a prompt string, vector index, or chat transcript alone. It combines RDF-style knowledge graphs, vector indexes, document storage, flow orchestration, agent tools, GraphRAG, DocRAG, IAM, and MCP/tool-service integration.

For Agentic Coding Lab, the repo is relevant because coding agents need the same primitives: scoped memory, source provenance, answer explainability, retrieval over structured and unstructured project knowledge, tool orchestration, tenant/workspace boundaries, and workflow state that can survive beyond a single prompt. TrustGraph exposes those primitives as running service code with deployment, gateway, and storage choices.

The main research value is architectural. The repo shows how to wire graph extraction, chunking, document storage, vector search, agent decision traces, and capability-checked APIs into one runtime. The caveat is that it is a distributed data platform, not a small library, so adoption would require selective extraction and local hardening.

## What It Is

TrustGraph is a Python-based agent runtime platform powered by context graphs. The public surface includes a gateway, IAM service, config service, flow service, agent orchestrator, GraphRAG and DocRAG services, extraction processors, chunkers, graph/vector stores, a librarian document service, Workbench UI, and a separate MCP server package.

The runtime is built around workspaces, collections, flows, processors, message topics, and config records. A flow blueprint expands into processor-specific config entries and topic bindings. Processors subscribe to config updates, create per-workspace or per-flow resources, and communicate through pub/sub request-response topics. Storage backends include Cassandra/Scylla-style tables for RDF quads and metadata, Qdrant and other vector stores, object storage for documents, and optional graph/vector alternatives.

The most distinctive feature is provenance. Extraction processors emit source-layer PROV-O triples for document, page, chunk, and extracted subgraph lineage. Retrieval and agent processors emit query-time explainability triples for GraphRAG, DocRAG, ReAct, plan, and supervisor patterns.

## Research Themes

- Token efficiency: Moderate. TrustGraph retrieves graph neighborhoods, source documents, chunks, and tool results on demand instead of feeding all prior context to the model. It has many numeric limits for GraphRAG traversal and result selection, but the reviewed paths do not expose a coding-agent-oriented token budgeter or prompt packer.
- Context control: Strong. Workspaces, collections, flows, named graphs, vector collections, tool groups, applicable states, retrieval limits, and ontology-guided extraction all provide useful scoping handles. Actual control depends on consistent config and on provenance triples being present.
- Sub-agent / multi-agent: Useful but incomplete. The orchestrator supports ReAct, plan, and supervisor patterns, including fan-out subagent requests and synthesis. The supervisor aggregator is in-memory, so process restarts lose in-flight fanout state.
- Domain-specific workflow: Strong. Flow blueprints, config-driven processors, ontology-guided extraction, dynamic tools, tool services, and knowledge cores can model domain workflows without changing the core runtime.
- Error prevention: Useful as support infrastructure. Provenance, explainability events, capability checks, tool filtering, and source-document tracing can reduce blind use of retrieved facts. They do not verify extracted facts against source code by themselves.
- Self-learning / memory: Strong as graph/document memory infrastructure. The platform can ingest documents, derive pages/chunks/subgraphs, store embeddings, and query graph-backed context. It is not a small per-agent memory block system.
- Popular skills: Context graph construction, GraphRAG, PROV-O provenance, flow orchestration, dynamic tool routing, MCP/tool-service bridging, IAM-gated runtime APIs, and portable "Context Core" packaging.

## Core Execution Path

The runtime starts with config and flow expansion. `FlowConfig.start-flow` resolves blueprint parameters, substitutes values such as workspace and flow ID, pre-creates topics, and writes one `processor:<processor>` config entry per processor plus a `flow` record. `FlowProcessor` instances subscribe to those config entries and start or stop per-workspace/per-flow `Flow` objects.

Each flow instantiates concrete producers, consumers, parameters, request-response clients, and librarian clients from specs. Consumers subscribe to topic names derived from the workspace, flow, processor ID, and consumer name. Request-response calls use correlation IDs in message properties.

Document ingestion commonly flows through the librarian and extraction services:

1. The librarian stores document metadata in Cassandra and document bytes in object storage.
2. A PDF or text decoder fetches the source document, emits page or source-child documents, and writes source-layer provenance triples.
3. A chunker splits text, stores chunk child documents, emits chunk provenance, and forwards chunk messages.
4. Relationship or ontology extraction processors call prompts, convert model output into RDF triples, and emit both extracted triples and subgraph provenance.
5. Triple storage writes quads into the entity-centric Cassandra graph store, while embedding stores write document or graph embeddings into vector backends.
6. GraphRAG extracts concepts from a question, embeds concepts, retrieves candidate entities, traverses graph neighborhoods, asks an LLM to score and reason over candidate edges, traces selected facts back to source documents through provenance triples, synthesizes an answer, saves answer documents, and emits query-time explainability triples.
7. The agent orchestrator can call GraphRAG, DocRAG, text completion, prompts, MCP tools, structured queries, row embeddings, or custom tool services inside ReAct, plan, or supervisor patterns.

## Architecture

The runtime base classes are centered on long-lived async processors. `AsyncProcessor` wires pub/sub, config fetch, config push subscriptions, metrics, and lifecycle retry behavior. `WorkspaceProcessor` tracks active workspaces. `FlowProcessor` tracks active flows and creates runtime `Flow` objects from config.

Configuration is a first-class runtime control plane. The config service stores values in Cassandra, pushes change notifications, provisions new workspaces from a `__template__` workspace, and avoids pushing reserved internal workspaces. Flow start/stop is also config-driven. Stop deletes processor config and only cleans up flow-owned parameterized topics that are no longer referenced by live flows, which avoids deleting shared literal topics.

The knowledge graph store is entity-centric. `EntityCentricKnowledgeGraph` writes RDF quads into `quads_by_entity` partitions for subject, predicate, object, and graph roles plus a `quads_by_collection` table. This makes entity-neighborhood lookup efficient for GraphRAG, while all-collection scans remain possible. Literal objects do not get object partitions, and some query patterns rely on application-side filtering.

Document storage is handled by the librarian. It stores document rows, processing rows, upload sessions, RDF metadata triples, object IDs, parent IDs, document types, and binary content in object storage. The document tree supports source documents, pages, chunks, generated answers, and processing metadata.

Vector storage is pluggable. The reviewed Qdrant document embedding path lazily creates dimension-specific collections named from workspace, collection, and embedding dimension, stores chunks by random UUID with `chunk_id` payloads, and deletes matching collections by prefix when a collection is removed.

Agent orchestration sits above retrieval and tools. `agent-orchestrator` uses a meta-router to choose ReAct, plan, or supervisor patterns from `agent-pattern` and `agent-task-type` config. Tool implementations include knowledge query, text completion, MCP tool, prompt, structured query, row-embedding query, and generic tool service calls.

The gateway and IAM layer protect external APIs. The gateway uses an operation registry mapping endpoints to capabilities and resource extractors. It accepts API keys and JWTs through IAM, locally verifies JWTs with the IAM signing public key, caches auth decisions briefly, fills default workspaces from identity where appropriate, and rejects unknown workspaces.

## Design Choices

TrustGraph chooses a pub/sub microservice runtime over an in-process library. That makes flows composable and backend-agnostic, but it also means a production deployment needs message brokers, storage services, config coordination, and observability.

It treats graph facts and source provenance as separate but linked graphs. Extracted triples can live in collection graphs, while provenance and query traces use named graphs such as source and retrieval graphs. This is a useful model for agent answers that need to explain why a fact appeared.

It makes flows declarative. Blueprints can define processors, parameters, queues, defaults, and topic ownership. The flow service expands this into processor config rather than requiring each processor to know the whole topology.

It separates source-document provenance from query-time explainability. Extraction processors describe how facts came from documents, pages, chunks, and extraction activities. Retrieval and agent processors describe how questions, grounding, exploration, tool calls, findings, plans, and synthesis were produced.

It uses a mixed trust model. External traffic is meant to cross the gateway/IAM boundary. Internal processors and direct pub/sub topics assume a more trusted runtime environment, especially for tool services and MCP backends.

It exposes tools dynamically through config. That makes agent capabilities extensible, but it also moves policy correctness into configuration fields such as tool groups, applicable states, service queues, and MCP auth tokens.

## Strengths

- Context graph architecture is concrete: RDF quads, named graphs, entity-centric indexes, vector stores, document blobs, and collection/workspace scoping all exist in running code.
- Provenance is unusually strong. The repo includes extraction-time document/page/chunk/subgraph lineage and query-time GraphRAG, DocRAG, ReAct, plan, and supervisor traces.
- GraphRAG is source-aware. It can trace selected graph edges back through `tg:contains` and `prov:wasDerivedFrom` chains to source documents before synthesis.
- Flow orchestration is explicit and inspectable. Blueprints expand into processor config, topic bindings, and lifecycle records instead of being hidden inside one monolithic agent loop.
- Agent tool routing is broad. The orchestrator can combine graph retrieval, document retrieval, prompts, structured query, MCP, row embeddings, and custom tool-service calls.
- IAM/gateway code is substantive. It has API keys, JWTs, roles, capability checks, workspace defaulting, operation registry routing, and fail-closed IAM error behavior.
- Context Cores are a useful packaging idea: ontology, graph, embeddings, manifests/provenance, and retrieval policy can be treated as portable context bundles.
- Tests cover important auth and integration edges, including IAM rejection of anonymous users and MCP authorization-header behavior.

## Weaknesses

- The platform is operationally large. A useful coding-agent deployment would need to run or replace config, broker, gateway, IAM, Cassandra/Scylla, object storage, vector stores, model providers, and multiple processors.
- The separate `trustgraph-mcp` package appears out of sync with the current gateway. The MCP socket client uses a query `token`/legacy `GATEWAY_SECRET` style, while the gateway websocket mux requires a first-frame auth message. Several MCP tool functions also call `get_socket_manager(ctx, "trustgraph")` even though the helper accepts only `ctx`.
- The MCP server itself exposes powerful config, flow, document, and query tools over streamable HTTP without an obvious front-door auth layer in the reviewed package. That is risky if bound outside a trusted local network.
- The supervisor pattern keeps fan-out aggregation in memory. Process restarts, multiple orchestrator replicas, or duplicate completions can lose or confuse subagent state unless a durable coordinator is added.
- Security depends on staying behind the gateway. Direct internal topics, tool-service queues, and processor configs are trusted surfaces. The no-auth IAM handler grants anonymous admin behavior and is only suitable for development.
- Secrets and credentials need hardening. IAM signing private keys are stored in Cassandra, API keys are hash-stored, MCP auth tokens are static service-level config, and the MCP bearer-token design is explicitly single-tenant rather than per-user.
- Tool filtering has documentation/config drift risk. The implementation uses `applicable-states`, while reviewed tool-group documentation examples also mention `available_in_states`.
- Entity-centric graph storage favors neighborhood retrieval but can create large partitions for high-degree entities or reified subgraphs. The tech spec relies on application-level limits to contain those reads.

## Ideas To Steal

- Use a first-class context graph rather than treating retrieval as vector search alone.
- Store extraction provenance as triples next to extracted facts, including document, page, chunk, extraction activity, model, component, and subgraph links.
- Emit query-time provenance for agent decisions, tool calls, retrieval grounding, findings, plan steps, errors, and final synthesis.
- Package reusable context as a bundle of ontology, graph, embeddings, manifests, and retrieval policy.
- Drive workflow topology from declarative flow blueprints that expand into concrete processor config and topic ownership.
- Keep retrieval source-aware by tracing selected answer facts back to original documents before final synthesis.
- Separate external gateway authorization from internal processor APIs, and make the gateway operation registry declarative.
- Filter dynamic tools by group and state so agents can have narrow tool surfaces for different workflow phases.

## Do Not Copy

- Do not adopt the whole distributed platform as a default coding-agent memory layer. The useful ideas can be smaller than the runtime.
- Do not expose the MCP server directly without authentication, authorization, network controls, audit logs, and a current gateway-auth-compatible client.
- Do not rely on static MCP bearer tokens for multi-user coding-agent environments.
- Do not treat internal pub/sub topics or tool-service queues as secure boundaries.
- Do not assume LLM-extracted graph facts are verified source-code truth. Coding facts still need source-file citations and command-backed checks.
- Do not keep supervisor or long-running agent state only in process memory if runs need to survive restarts or scale horizontally.
- Do not copy the entity-centric graph layout without testing high-degree entities, collection deletion, and provenance-heavy workloads.
- Do not let config field drift decide security policy; tool-group/state schemas need one canonical field set and tests.

## Fit For Agentic Coding Lab

Fit is conditional but valuable. TrustGraph is most useful as a reference architecture for graph-backed context, provenance, auditable retrieval, and declarative workflow orchestration. It is less suitable as a direct dependency for the lab's default coding-agent runtime because the operational footprint and trust assumptions are much larger than most coding-agent tasks require.

The most valuable adaptation would be a smaller context-graph service for repositories and tasks. It could store source-backed facts about files, symbols, commands, errors, architectural decisions, user preferences, dependency constraints, and task outcomes; attach every fact to a source document or command result; and emit query-time traces when an agent uses that memory.

A practical lab design should borrow the Context Core idea, extraction/query provenance model, declarative tool surfaces, and source tracing. It should replace or reduce the distributed flow runtime unless multi-tenant deployment or high-throughput ingestion requires it.

Before production use, the lab would need durable run coordination, per-user credential propagation, secret encryption policy, stricter MCP/tool-service boundaries, explicit retention rules, source-code verification for extracted facts, and local tests for every chosen storage backend.

## Reviewed Paths

- `/tmp/myagents-research/trustgraph-ai-trustgraph/README.md`: project positioning, runtime components, storage/backend list, Workbench surface, and Context Core framing.
- `/tmp/myagents-research/trustgraph-ai-trustgraph/trustgraph-flow/pyproject.toml`: service entry points, package boundaries, and backend dependencies.
- `/tmp/myagents-research/trustgraph-ai-trustgraph/trustgraph-base/trustgraph/base/async_processor.py`, `workspace_processor.py`, `flow_processor.py`, `flow.py`, `consumer_spec.py`, `producer_spec.py`, and `request_response_spec.py`: async processor lifecycle, config subscriptions, flow instantiation, topic binding, and request-response correlation.
- `/tmp/myagents-research/trustgraph-ai-trustgraph/trustgraph-flow/trustgraph/config/service.py`, `config/config.py`, and `flow/service/flow.py`: config storage, workspace provisioning, flow expansion, parameter substitution, topic ownership, and flow stop cleanup.
- `/tmp/myagents-research/trustgraph-ai-trustgraph/docs/tech-specs/entity-centric-graph.md` and `trustgraph-flow/trustgraph/direct/cassandra_kg.py`: entity-centric RDF quad schema, collection metadata, query patterns, graph roles, and collection deletion behavior.
- `/tmp/myagents-research/trustgraph-ai-trustgraph/trustgraph-flow/trustgraph/storage/triples/cassandra/write.py` and `query/triples/cassandra/service.py`: triple write/query services, collection config handling, and streaming query behavior.
- `/tmp/myagents-research/trustgraph-ai-trustgraph/trustgraph-flow/trustgraph/storage/doc_embeddings/qdrant/write.py` and `query/doc_embeddings/qdrant/service.py`: Qdrant document embedding storage, collection naming, upsert payloads, and query flow.
- `/tmp/myagents-research/trustgraph-ai-trustgraph/trustgraph-flow/trustgraph/librarian/librarian.py`, `tables/library.py`, and `blob_store.py`: document metadata, blob storage, upload sessions, processing records, parent-child documents, and cascade deletion behavior.
- `/tmp/myagents-research/trustgraph-ai-trustgraph/docs/tech-specs/extraction-time-provenance.md`, `docs/tech-specs/agent-explainability.md`, `specs/ontology/trustgraph.ttl`, and `trustgraph-base/trustgraph/provenance/`: source-layer and query-time provenance design, vocabulary bootstrapping, URI patterns, and PROV-O triple builders.
- `/tmp/myagents-research/trustgraph-ai-trustgraph/trustgraph-flow/trustgraph/decoding/pdf/pdf_decoder.py`, `chunking/recursive/chunker.py`, `extract/kg/relationships/extract.py`, and `extract/kg/ontology/extract.py`: document decoding, chunk provenance, relationship extraction, ontology-guided extraction, and subgraph provenance.
- `/tmp/myagents-research/trustgraph-ai-trustgraph/trustgraph-flow/trustgraph/retrieval/graph_rag/rag.py`, `retrieval/graph_rag/graph_rag.py`, and `retrieval/document_rag/rag.py`: GraphRAG and DocRAG request lifecycle, concept extraction, graph traversal, edge scoring, source tracing, synthesis, explainability, and answer documents.
- `/tmp/myagents-research/trustgraph-ai-trustgraph/trustgraph-base/trustgraph/base/agent_service.py` and `trustgraph-flow/trustgraph/agent/orchestrator/`: agent request loop, meta-router, ReAct, plan, supervisor, pattern base, aggregation, tool filtering, and tool implementations.
- `/tmp/myagents-research/trustgraph-ai-trustgraph/docs/tech-specs/tool-group.md`, `docs/tech-specs/tool-services.md`, `docs/tech-specs/mcp-tool-bearer-token.md`, `trustgraph-flow/trustgraph/agent/mcp_tool/service.py`, and `agent/react/tools.py`: dynamic tool grouping, custom tool services, MCP bearer-token model, and tool invocation behavior.
- `/tmp/myagents-research/trustgraph-ai-trustgraph/trustgraph-flow/trustgraph/gateway/`: gateway auth, operation registry, endpoint manager, capability mapping, websocket mux, and workspace/resource enforcement.
- `/tmp/myagents-research/trustgraph-ai-trustgraph/trustgraph-flow/trustgraph/iam/`: IAM service, no-auth handler, bootstrap behavior, roles/capabilities, users, API keys, signing keys, and workspace checks.
- `/tmp/myagents-research/trustgraph-ai-trustgraph/trustgraph-flow/tests/unit/test_iam/`, `tests/unit/test_gateway/`, and `tests/unit/test_agent/test_mcp_tool_auth.py`: sampled auth and MCP-related tests for reviewed security claims.
- `/tmp/myagents-research/trustgraph-ai-trustgraph/trustgraph-mcp/`: MCP server package, websocket client, exposed tools, and auth drift against the current gateway.

## Excluded Paths

- `/tmp/myagents-research/trustgraph-ai-trustgraph/.git/`: clone metadata; exact reviewed commit is captured above.
- `/tmp/myagents-research/trustgraph-ai-trustgraph/workbench/`, `docs/ui/`, screenshots, images, and static visual assets: UI presentation and Workbench screens; reviewed only where README or docs clarified runtime surfaces.
- `/tmp/myagents-research/trustgraph-ai-trustgraph/packages/`, generated clients, and SDK wrapper surfaces not reached by gateway/runtime review: useful for product integration but lower value for architecture analysis.
- `/tmp/myagents-research/trustgraph-ai-trustgraph/docker/`, `k8s/`, Helm/manifests, deployment samples, and compose files: operational packaging; sampled for platform scope but not line-by-line.
- `/tmp/myagents-research/trustgraph-ai-trustgraph/tests/` outside the sampled IAM, gateway, MCP, and provenance-adjacent tests: broad coverage exists, but the review focused on runtime architecture and security boundaries rather than full test audit.
- `/tmp/myagents-research/trustgraph-ai-trustgraph/docs/` pages unrelated to context graph, provenance, tools, flow, storage, gateway, IAM, or agent orchestration: documentation was sampled by relevance to the assigned research focus.
- Lockfiles, generated build artifacts, caches, examples with sample documents, and binary fixtures: dependency/output material rather than primary architecture.
