# vectorize-io/hindsight
- URL: https://github.com/vectorize-io/hindsight
- Category: agent-support-systems
- Stars snapshot: 13,073 (GitHub REST API, captured 2026-05-12)
- Reviewed commit: 2471f01107d90c2b13410bf929050cd67072d281
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong reference architecture for agent memory that learns from traces and outcomes, especially via `experience` facts, observation consolidation, and MCP/coding-agent hooks. Use as a design source, not as a direct dependency, unless we are willing to operate a PostgreSQL plus LLM memory service and harden defaults.

## Why It Matters

Hindsight is one of the more complete open source examples of a trace-learning memory system for agents. It does not only store embeddings over transcripts. Its core path extracts structured facts from conversations and documents, separates general world facts from the agent's own experiences, builds entity/time/causal/semantic links, consolidates raw memories into evidence-backed observations, and lets a reflect agent answer with cited evidence.

The repository is directly relevant to coding agents. It has OpenAI Codex CLI and Claude Code integrations that hook session start, user prompt submission, and stop/session end events; auto-recall memories into hidden context; auto-retain full or chunked transcripts; preserve structured tool calls; strip injected memory blocks to avoid feedback loops; and derive per-project/per-agent/per-session memory banks. The extraction prompt explicitly treats first-person debugging, code changes, decisions, and user interactions as `experience` memories.

## What It Is

Hindsight is a Python API service plus MCP server, clients, integrations, docs, and an optional control-plane UI. The main service lives under `hindsight-api-slim/hindsight_api`. It exposes `retain`, `recall`, `reflect`, bank management, memory browsing, directives, documents, async operations, mental models, tags, audit logs, and MCP tools.

The memory engine is built around PostgreSQL-style storage with vector search, full-text search, JSONB metadata, entity tables, relationship tables, and async operations. The documented default is PostgreSQL with pgvector; docs also describe pg0 embedded development mode, pgvectorscale/DiskANN, vchord BM25, pg_textsearch, and Oracle AI Database support. The project deliberately does not use a generic storage abstraction.

## Research Themes

- Token efficiency: Recall exposes `max_tokens`, `budget`, `types`, `include_chunks`, and separate chunk/source-fact budgets. The engine overfetches internally, then truncates returned facts by token count. The reflect agent has a proactive max-context guard and final-answer token cap. Coding-agent integrations cap recall query size and recall result tokens before injecting context.
- Context control: Banks isolate memory stores; tags and tag groups filter recall and consolidation; observation scopes decide how facts become scoped observations; bank missions and retain missions steer extraction; directives act as hard rules in reflect; per-bank config controls enabled MCP tools and retrieval behavior.
- Sub-agent / multi-agent: The core service is not a subagent orchestrator, but it supports multiple agents through banks, dynamic bank IDs, tenant schemas, MCP single-bank endpoints, and additional-bank recall. The Claude Code plugin adds subagents with memory through a `create-agent` skill and per-agent knowledge pages.
- Domain-specific workflow: `retain_mission`, `observation_mission`, entity label vocabularies, bank mission, directives, and mental models let teams specialize what the memory system extracts and synthesizes. The tool-learning cookbook shows feedback-driven learning for ambiguous tools.
- Error prevention: Reflect forces a mental-model -> observation -> raw-recall search order and validates `done` citations against actually retrieved IDs. Retain uses document row locks, content hashes, stale-request detection, operation checkpoints, and retry/split behavior. Tests cover tool errors, unknown tool recovery, context overflow, tag filters, SQL qualification, and trace visibility.
- Self-learning / memory: Raw trace facts become `world` and `experience` memories; consolidation converts them into observations with `source_memory_ids`, proof counts, history, and freshness; mental models are refreshed from observations; reflect consumes this hierarchy.
- Popular skills: Not primarily a skill collection, but it ships coding-agent integrations, a Claude Code `create-agent` skill, MCP `agent_knowledge_*` tools, and framework integrations for LiteLLM, OpenAI Agents, LangGraph, CrewAI, Agno, LlamaIndex, Pydantic AI, AutoGen, and others.

## Core Execution Path

1. A client calls `retain` through HTTP, MCP, an SDK, LiteLLM wrapper, Codex hook, Claude Code hook, or another integration.
2. `MemoryEngine.retain_batch_async` authenticates the request context, applies the optional operation validator, resolves bank config, chunks large input, and sends content to the retain orchestrator.
3. The retain orchestrator extracts structured facts with an LLM, maps `assistant` facts to stored `experience` facts, embeds augmented fact text, resolves entities, and writes facts, entities, temporal links, semantic links, and causal links. Streaming retain uses document row locks, content hashes, checkpoints, chunk hashes, and a final semantic-link pass.
4. Background consolidation groups unconsolidated facts by tag scope, recalls related observations with strict tag matching, asks an LLM to create/update/delete observations, stores observations as `memory_units` with `fact_type='observation'`, and may refresh mental models.
5. `recall` embeds the query, runs semantic vector, BM25 keyword, temporal, and graph/link-expansion retrieval, merges candidates with reciprocal-rank fusion, reranks with a cross encoder, applies recency/temporal/proof-count boosts, fetches optional chunks/source facts, and returns facts that fit the token budget.
6. `reflect` runs an agentic loop with tools for mental models, observations, raw recall, and expansion. It enforces evidence before final answer, validates cited IDs, returns `based_on`, and can expose a trace.
7. Coding-agent hooks call recall before each prompt and retain after responses. The integrations inject `<hindsight_memories>` context, strip those tags before retain, preserve structured tool calls when configured, and use session/project/agent/user metadata for bank IDs and tags.

## Architecture

The central data model is a graph-like memory store in SQL:

- `memory_units` holds world facts, experience facts, and observations.
- `documents` and `chunks` support long document/session retention and source chunk return.
- `entities` and `unit_entities` support entity resolution and query-time graph expansion.
- `memory_links` stores semantic, temporal, and causal relationships.
- `mental_models` stores synthesized knowledge pages that can refresh after consolidation.
- `directives` stores hard instructions used by reflect.
- `async_operations`, audit logs, bank config, and webhooks support operational workflows.

Retain is a multi-phase ingestion pipeline. It performs LLM fact extraction, embedding, pre-resolution reads outside the write transaction, transactional fact/link insertion, and best-effort visualization links after commit. For large documents it streams extraction and DB insertion concurrently while guarding against stale writes with content hashes and document locks.

Retrieval is hybrid. Semantic and BM25 search are run in a combined SQL path; temporal retrieval detects date constraints and expands from date-ranked/similarity-ranked seeds; graph retrieval expands from semantic seeds through shared entities, semantic links, and causal links. RRF merges the four channels and the reranker normalizes scores before small multiplicative boosts.

Learning happens in consolidation. Observations are not just summaries; they are stored memories with source IDs, proof counts, history, tags, and source facts. Consolidation avoids cross-scope leakage by grouping by exact tag sets before LLM calls and using strict tag matching for related observations.

MCP is a first-class transport. The API exposes `/mcp/` for multi-bank tools and `/mcp/{bank_id}/` for single-bank scoped tools. Tool sets can be limited by bank config and narrowed by an operation validator. The Claude Code integration also runs a local stdio MCP server for knowledge-page tools.

## Design Choices

- Store extracted facts, not only raw transcript chunks. This makes memory easier to retrieve, consolidate, and cite.
- Treat the agent's own actions as first-class `experience` facts. The extraction prompt names debugging, code changes, discoveries, user interactions, and decisions.
- Use PostgreSQL as the system boundary instead of abstracting storage. This keeps vector, text, relational, JSONB, and graph-like traversals in one place, at the cost of portability.
- Keep observation consolidation evidence-grounded. Observations carry source IDs and proof counts and are updated/deleted as new facts arrive.
- Use scoped memory primitives everywhere: banks, tenant schemas, tags, tag groups, observation scopes, and per-bank config.
- Put hard context limits around agentic reflect and recall. The system overfetches internally but returns a bounded fact list and optional bounded chunks/source facts.
- Prefer extension points over forks: tenant extensions, operation validators, config resolver, MCP tool filtering, audit logging, and webhooks.
- Let coding-agent integrations be mostly hook scripts. They degrade gracefully on errors, avoid blocking the host agent, and keep injected memories out of retained transcripts.

## Strengths

- End-to-end learning loop from traces to extracted facts, observations, mental models, and evidence-based reflection.
- Retrieval is genuinely hybrid and includes temporal and graph signals, not only vector similarity.
- Strong context-control surface through banks, tags, observation scopes, missions, directives, budgets, and per-bank MCP tool filters.
- Good coding-agent applicability: Codex and Claude Code integrations capture sessions, tool calls, project-derived bank IDs, and final transcripts.
- Provenance is central. Observations reference source memories, reflect validates cited IDs, and recall can include chunks/source facts.
- Operational rigor is above average for a research candidate: row locks, stale write checks, retries, async operations, audit logs, webhooks, metrics, traces, and broad test coverage.
- Test suite covers meaningful failure modes: extraction quality, coding-agent experience classification, consolidation, recall scoring/filters, trace output, MCP routing/tool filtering, tag visibility, schema safety, tenant auth, and reflect error recovery.

## Weaknesses

- Security defaults are risky for a memory service. The default tenant extension does no auth, docs say MCP is open by default, and production use depends on enabling API-key or tenant extensions.
- Privacy exposure is high if observability is enabled carelessly. Tracing can export full LLM prompts and completions; audit logging stores request/response JSON; webhook secrets are placed in async task payloads.
- The architecture is heavy. Running it well means operating PostgreSQL/pgvector or equivalent, LLM extraction, embedding, reranking, consolidation workers, and optional MCP/control-plane pieces.
- LLM extraction and consolidation are quality-critical. The tests include useful live quality checks, but learned memory can still reflect extraction mistakes, model drift, or prompt regressions.
- Some implementation comments/docs are stale. `MemoryEngine._search_with_retries` claims an MMR diversity step, but the searched implementation did not show active MMR ranking.
- The UI, client generation, integrations, and deployment files create a large repo surface that can obscure the smaller core memory ideas.
- Tags default modes can include untagged memories unless strict matching is selected. That is useful ergonomically but must be configured deliberately for privacy boundaries.

## Ideas To Steal

- Model coding-agent logs as `experience` memories separate from general world facts.
- Strip injected memory blocks before retaining transcripts to avoid self-reinforcing memory loops.
- Preserve structured tool calls and tool outputs in retained traces, with output caps.
- Use observation consolidation with source IDs, proof counts, history, and scoped tag grouping.
- Force reflect to consult synthesized knowledge, then observations, then raw facts, and validate final citations against retrieved IDs.
- Run hybrid retrieval with RRF and a final rerank, then apply only conservative recency/temporal/proof-count boosts.
- Separate recall budget, returned fact token budget, chunk budget, and source-fact budget.
- Support per-project/per-agent/per-session bank IDs for coding agents, plus optional per-user tags.
- Add an operation-validator extension point that can inject tags/tag groups and narrow allowed MCP tools.
- Use content hashes, document locks, and chunk checkpoints so repeated retain of long sessions is idempotent and resumable.

## Do Not Copy

- Do not ship open MCP or no-auth tenant behavior as a default for private coding-agent memory.
- Do not export full prompts, completions, tool outputs, or retained transcripts to traces/audit logs without redaction and retention policy.
- Do not import the whole service stack if a smaller repo-local memory note system can satisfy the use case.
- Do not rely on LLM extraction alone for critical lessons; pair it with deterministic metadata, tests, and human-reviewable notes.
- Do not let untagged memories leak into scoped recall where the scope is a privacy boundary.
- Do not copy generated SDKs, UI scaffolding, deployment manifests, or changelog/blog machinery into an agentic coding lab.

## Fit For Agentic Coding Lab

High fit as a reference system. The strongest transferable pattern is: capture traces and tool outcomes, extract explicit `experience` facts, consolidate repeated facts into evidence-backed observations, retrieve with strict scope and token budgets, and require cited evidence before using memory in planning or final answers.

For this repository, I would not adopt Hindsight wholesale unless the goal is to run a dedicated shared memory service. The direct implementation footprint is too large for a lightweight agent-support layer. A narrower design could borrow the trace schema, experience/world split, observation consolidation, per-project banks, tag scoping, and recall budget controls while storing notes in repo-local markdown/SQLite and using existing review workflows for verification.

## Reviewed Paths

- `README.md`: product overview, memory types, retain/recall/reflect model, memory banks, and high-level retrieval strategies.
- `hindsight-api-slim/README.md`: API service overview, MCP endpoint, PostgreSQL/pgvector positioning, and environment model.
- `hindsight-api-slim/hindsight_api/engine/memory_engine.py`: main retain/recall/reflect orchestration, auth flow, budget handling, tool callbacks, and evidence validation.
- `hindsight-api-slim/hindsight_api/engine/retain/orchestrator.py`: retain pipeline, streaming ingestion, entity/link writes, document locks, stale request handling, and checkpoints.
- `hindsight-api-slim/hindsight_api/engine/retain/fact_extraction.py`: extraction prompt, fact typing, coding-agent `experience` classification, temporal parsing, entity labels, and causal relations.
- `hindsight-api-slim/hindsight_api/engine/retain/types.py`: retained content and processed fact data structures.
- `hindsight-api-slim/hindsight_api/engine/search/retrieval.py`: semantic/BM25/temporal retrieval, parallel multi-fact-type retrieval, date constraints, and result limits.
- `hindsight-api-slim/hindsight_api/engine/search/link_expansion_retrieval.py`: graph expansion through entities, semantic links, causal links, and observation source facts.
- `hindsight-api-slim/hindsight_api/engine/search/fusion.py`: reciprocal-rank fusion implementation.
- `hindsight-api-slim/hindsight_api/engine/search/reranking.py`: cross-encoder reranking and combined scoring with recency, temporal, and proof-count boosts.
- `hindsight-api-slim/hindsight_api/engine/query_analyzer.py`: dateparser-based temporal query extraction.
- `hindsight-api-slim/hindsight_api/engine/consolidation/consolidator.py`: observation creation/update/delete, strict tag grouping, source memory validation, and mental-model refresh trigger.
- `hindsight-api-slim/hindsight_api/engine/consolidation/prompts.py`: consolidation rules and anti-merge guidance.
- `hindsight-api-slim/hindsight_api/engine/reflect/agent.py`: reflect tool loop, forced evidence order, max-context guard, tool normalization, and `done` validation.
- `hindsight-api-slim/hindsight_api/mcp_tools.py`: shared MCP tool registry and request-context propagation.
- `hindsight-api-slim/hindsight_api/api/mcp.py`: HTTP MCP routing, single-bank versus multi-bank mode, auth middleware, and tool filtering.
- `hindsight-api-slim/hindsight_api/mcp_local.py`: local MCP/API entrypoint with pg0 default.
- `hindsight-api-slim/hindsight_api/config.py` and `config_resolver.py`: credential filtering, per-bank configurable fields, provider settings, and fail-open permission note.
- `hindsight-api-slim/hindsight_api/extensions/builtin/tenant.py`, `extensions/builtin/supabase_tenant.py`, and `extensions/operation_validator.py`: auth, tenant schema, request validation, tag injection, and tool filtering extension points.
- `hindsight-api-slim/hindsight_api/engine/audit.py`, `webhooks/manager.py`, `tracing.py`, and `metrics.py`: audit, webhook, tracing, and metrics surfaces relevant to privacy/security.
- Developer docs under `hindsight-docs/versioned_docs/version-0.6/developer/retain.md`, `retrieval.md`, `observations.mdx`, `reflect.mdx`, `configuration.md`, `storage.md`, `mcp-server.md`, and `monitoring.md`: documented architecture and operational behavior.
- Coding-agent docs and examples: `hindsight-integrations/codex/README.md`, `hindsight-integrations/claude-code/README.md`, `hindsight-docs/src/pages/changelog/integrations/codex.md`, `hindsight-docs/src/pages/changelog/integrations/claude-code.md`, and tool-learning cookbook pages.
- Coding-agent hook source: `hindsight-integrations/codex/scripts/recall.py`, `retain.py`, `scripts/lib/content.py`, `hindsight-integrations/claude-code/scripts/recall.py`, `retain.py`, `scripts/lib/content.py`, and `scripts/mcp_server.py`.
- Tests: `test_fact_extraction_quality.py`, `test_fact_extraction_agent_experience.py`, `test_consolidation.py`, `test_reflect_agent.py`, `test_recall_config.py`, `test_combined_scoring.py`, `test_search_trace.py`, `test_recall_time_range.py`, `test_tracing_spans_verification.py`, `test_mcp_tools.py`, `test_mcp_endpoint_routing.py`, `test_mcp_tool_filtering.py`, `test_sql_schema_safety.py`, `test_tags_visibility.py`, `test_audit_log.py`, and `test_supabase_tenant.py`.

## Excluded Paths

- `hindsight-control-plane/`: excluded as UI/admin console implementation. It may be useful for product workflows, but it is not needed to understand trace-learning memory architecture.
- `hindsight-control-plane/src/components/ui/`, page components, CSS, and visual assets: excluded as UI-only surface.
- `hindsight-clients/typescript/generated/`, large generated Go client files under `hindsight-clients/go/`, OpenAPI generator artifacts, and `hindsight-clients/go/openapi-generator-cli.jar`: excluded as generated/vendored client output.
- `hindsight-docs/static/`, favicon files, image assets, and generated site content: excluded as binary/static documentation assets.
- `hindsight-docs/src/pages/blog/` and most changelog pages outside Codex/Claude Code memory integrations: excluded as marketing/release content unrelated to memory internals.
- `helm/`, `docker/`, Kubernetes/deployment manifests, and most monitoring dashboard JSON: excluded as deployment/ops packaging; reviewed monitoring docs and tracing source instead for security implications.
- Lock files and package-manager metadata such as `uv.lock`, `deno.lock`, `package-lock.json`, and generated build metadata: excluded as dependency resolution artifacts.
- Non-coding framework integrations beyond a repository inventory pass, including most of `agno`, `crewai`, `langgraph`, `llamaindex`, `openai-agents`, `pydantic-ai`, `autogen`, and similar wrappers: excluded because they mostly adapt the same retain/recall primitives to framework APIs.
- Integration binaries/assets such as Dify icon files, n8n images/SVGs, and plugin package assets: excluded as non-core.
- Full Alembic migration history: excluded from deep review because the schema concepts were visible in engine code and tests; migration ordering itself was not central to the research question.
