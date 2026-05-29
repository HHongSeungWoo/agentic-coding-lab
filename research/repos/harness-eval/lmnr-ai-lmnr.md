# lmnr-ai/lmnr

- URL: https://github.com/lmnr-ai/lmnr
- Category: harness-eval
- Stars snapshot: 2,958 (GitHub REST API repository search, captured 2026-05-29; from research/index.md)
- Reviewed commit: f02af8e5005a5019d745a5cba75f10fcc654c729
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: conditional
- Verdict: Strong candidate for agent observability, trace storage, eval result storage, safe SQL access, and MCP-based debugging patterns. Conditional because this repository is the Laminar platform and UI, not a small standalone coding-agent harness; the client SDKs and CI runner surface mostly live outside this checkout.

## Why It Matters

Laminar is an open-source observability platform for AI agents. For the Agentic Coding Lab, its highest-value contribution is the end-to-end path from OpenTelemetry spans to durable trace, eval, dataset, search, and realtime inspection state. The codebase treats LLM calls, tools, evaluators, human evaluators, browser events, costs, tokens, tags, metadata, and errors as queryable runtime facts rather than ad hoc logs.

The repo also contains unusually relevant patterns for coding-agent debugging. It exposes a project-scoped SQL API, a stateless MCP server with trace-query tools, an AI trace chat that reads compressed span structures before fetching detail, and LLM-based "signals" that classify behavior from large traces using prompt summaries and drop rules. Those pieces are directly useful for a lab that wants coding agents to inspect their own failures and regressions.

## What It Is

Laminar is a Rust, Next.js, and Python platform for AI observability and evaluation. The reviewed checkout includes:

- `app-server`: Rust HTTP/gRPC backend for trace ingestion, eval and dataset APIs, SQL/MCP APIs, queue workers, ClickHouse/Postgres/Quickwit integration, data-plane routing, and signal processing.
- `frontend`: Next.js app for traces, evals, datasets, dashboards, playgrounds, debugger sessions, auth, settings, and self-host management.
- `query-engine`: Python gRPC service that validates and rewrites user SQL before ClickHouse execution.
- Docker Compose files for lightweight and full self-hosted deployments.

The core runtime model is:

- Traces and spans from OpenTelemetry HTTP/gRPC ingest.
- ClickHouse rows for spans, traces, evaluation datapoints, datasets, logs, browser events, and signal events.
- Postgres rows for projects, workspaces, API keys, eval metadata, datasets, queues, signals, and configuration.
- Quickwit indexes for full-text span and event search.
- RabbitMQ in full mode, or in-process Tokio queues in lite mode.
- Optional hybrid data-plane routing for customer-owned trace storage.

## Research Themes

- Token efficiency: Strong fit for observability-time compression. Signal and trace-agent code builds compact trace skeletons, extracts and references repeated system prompts, omits repeated LLM inputs on repeated paths, deduplicates tool inputs that already appeared in LLM output, truncates large payloads with explicit markers, and applies cached drop rules before LLM classification.
- Context control: Strong fit. The SQL validator rewrites allowed logical tables into project-scoped table functions, MCP exposes only project-authenticated trace context and SQL tools, trace compression keeps span ids and paths stable, and evaluation queries preserve group, trace, score, and dataset links.
- Sub-agent / multi-agent: Moderate-to-strong fit. The trace view and signal code use span paths, prompt hashes, system prompt summaries, and main-agent fingerprints to identify agent boundaries. This is not a scheduler, but it is useful for analyzing multi-agent or subagent-heavy traces.
- Domain-specific workflow: Strong fit for AI-agent observability. The natural loop is ingest trace -> inspect/search/query -> link eval datapoints and datasets -> compare scores -> run signals -> debug with trace chat or MCP.
- Error prevention: Strong infrastructure patterns include hashed project API keys, ingest-only API key restrictions, usage-limit checks, queue payload caps, readonly ClickHouse query paths, SQL validation that blocks writes and dangerous functions, and separation between frontend membership checks and backend project API key checks.
- Self-learning / memory: Conditional fit. Laminar stores historical traces, trace chats, datasets, eval results, signal clusters, prompt summaries, and signal drop-rule caches. That can support learning loops, but the repo does not implement autonomous policy updates or long-term coding-agent memory.
- Popular skills: No skill marketplace. Reusable "skills" for the lab are OpenTelemetry instrumentation, trace compression, eval-result ingestion, dataset versioning, SQL/MCP debugging, signal authoring, and self-hosted observability operations.

## Core Execution Path

Trace ingestion enters through `app-server/src/api/v1/traces.rs` for HTTP OTLP and `app-server/src/traces/grpc_service.rs` for gRPC OTLP. Both authenticate project API keys, enforce usage limits, decode OpenTelemetry spans, and call the shared producer path. `app-server/src/traces/producer.rs` maps OTLP spans into internal `Span` values, filters spans that should not be saved, rejects oversized queue payloads, and sends batches either to RabbitMQ, an in-process lite queue, or a hybrid data-plane queue.

Workers in `app-server/src/traces/consumer.rs` and `app-server/src/traces/processor.rs` batch spans, parse attributes, compute model usage and cost, build trace aggregations, update Postgres and ClickHouse trace stats, insert spans into ClickHouse, publish realtime updates, enqueue Quickwit indexing, update autocomplete caches, and trigger signal checks only after spans have landed in ClickHouse. This gives the platform a clean split between low-latency ingestion and heavier enrichment, indexing, and alert work.

The internal span model in `app-server/src/traces/spans.rs` recognizes LLM, pipeline, executor, evaluator, human evaluator, evaluation, tool, cached, and default spans. It parses OpenTelemetry GenAI attributes, AI SDK prompts and tool calls, LiteLLM and Traceloop conventions, manual `lmnr.span.input` and `lmnr.span.output`, events, tags, metadata, status, prompt hashes, and meta-only tracing. `app-server/src/ch/spans.rs` then persists compact but rich ClickHouse rows with ids, timing, costs, tokens, model/provider, input/output payloads or payload URLs, events, attributes, trace metadata, trace type, and tags.

Evaluations enter through `app-server/src/api/v1/evals.rs`. Clients create an evaluation, then write datapoint results with data, target, metadata, executor output, trace id, dataset link, group, and score map. `app-server/src/evaluations/mod.rs` stores those records in ClickHouse, supports updates through a ReplacingMergeTree-style insert/select merge, preserves prior fields, and merges score JSON. The frontend evaluation actions and query builder let users compare eval groups by datapoint index, inspect score distributions, filter/query datapoints, and open linked traces.

Datasets enter through `app-server/src/api/v1/datasets.rs`. The API supports dataset lookup, datapoint insertion by dataset name or id, optional dataset creation, SQL-based datapoint retrieval, and parquet export from object storage. ClickHouse migrations version dataset datapoints and expose latest-version views. That makes datasets usable for regression records even though the external SDK/runner code is not part of this repository.

Agent-accessible debugging is exposed through `app-server/src/api/v1/sql.rs` and `app-server/src/api/v1/mcp.rs`. User SQL is validated by the Python query engine before execution, then routed to cloud ClickHouse or a hybrid data plane. The MCP endpoint offers `query_laminar_sql` and `get_trace_context`, giving a coding agent a constrained way to inspect traces, evals, datasets, signals, and logs.

## Architecture

The backend is centered on a Rust Actix/Tonic server. It can run as a producer, consumer, or combined service. Producer mode exposes ingestion and API routes. Consumer mode runs queue workers and server-sent-event realtime endpoints. The server initializes Sentry when configured, OpenTelemetry tracing/logging, Postgres, ClickHouse, Redis or in-memory cache/pubsub, RabbitMQ or in-process lite queues, object storage or mock storage, Quickwit, the query-engine client, and worker pools for spans, data-plane spans, logs, browser events, signals, clustering, reports, notifications, and indexing.

Storage is mixed intentionally. Postgres holds configuration and lower-volume relational state such as workspaces, projects, API keys, datasets, eval records, labeling queues, signals, and signal triggers. ClickHouse stores high-volume spans, traces, eval datapoints, dataset datapoints, browser events, logs, signal events, and cluster records. Quickwit indexes selected span inputs/outputs and events for full-text search with retention and partitioning. Object storage holds payloads and exports when configured.

The SQL boundary is split out into `query-engine`, a Python gRPC service using `sqlglot`. It only allows `SELECT`, blocks dangerous functions and external table access, rejects direct `project_id` access, validates logical tables and columns, rewrites allowed tables to project-scoped table functions, adds trace time filters when needed, and strips settings. The Rust server then applies execution limits and can route the query to a hybrid data plane.

The frontend is a Next.js app using server actions and React views for traces, evals, datasets, signals, dashboards, playgrounds, debugger sessions, alerts, settings, and auth. Auth uses NextAuth with common SSO providers plus self-host email credentials in non-production/self-host configurations. Middleware protects project and workspace APIs by session membership, while backend API routes use project API keys for SDK/agent traffic.

## Design Choices

- OpenTelemetry-first ingest: Laminar accepts OTLP over HTTP and gRPC, maps common GenAI conventions into a domain span model, and avoids requiring every runtime to use a proprietary event shape.
- Async trace processing: API paths push serialized span batches to a queue, while workers enrich, aggregate, index, trigger signals, and publish realtime events.
- ClickHouse as eval and trace substrate: spans, traces, datasets, eval datapoints, and signal outputs are all queryable with SQL-style analytics rather than living only in JSON blobs.
- Search as a side index: Quickwit indexes LLM spans and smaller non-LLM spans for text search, while ClickHouse remains the source of truth for structured filtering and detail.
- Project-scoped SQL rather than raw database access: user queries are validated, rewritten, and limited before ClickHouse execution, with dangerous functions and direct tenant columns blocked.
- MCP as a debugging API: coding agents can use trace context and SQL tools through a constrained project API key instead of scraping the UI.
- Signal runs are trace-aware LLM jobs: large traces are compressed, system prompts are summarized, stable main-agent fingerprints are computed, and structured tool-call output is used for classification.
- Self-hosting supports lite and full modes: lite removes RabbitMQ for simpler deployment, while full mode uses RabbitMQ and separate service roles for production-like throughput.

## Strengths

- End-to-end trace path is concrete and production-oriented: OTLP ingest, queueing, enrichment, ClickHouse writes, Postgres aggregates, Quickwit indexing, realtime publication, and usage accounting are all implemented.
- The span model is agent-aware enough to represent LLM calls, tools, evaluator spans, human evaluator spans, costs, tokens, prompts, tags, events, and trace metadata.
- Evaluation datapoints are first-class storage records with trace links, grouped comparisons, score maps, dataset links, and frontend comparison workflows.
- Dataset storage supports versioned datapoints and latest-version views, which is a useful regression-testing primitive.
- SQL and MCP boundaries are unusually relevant for coding agents because they turn observability data into safe, queryable tools.
- Signal compression and prompt-summary code is a useful pattern for analyzing very large agent traces without sending full transcripts to a judge model.
- Security posture is better than a quick demo app: API keys are hashed, provider and data-plane secrets are encrypted, ingest-only keys are constrained, and SQL validation has focused tests.
- Hybrid data-plane support shows how to separate control-plane UI/configuration from customer-owned trace storage.

## Weaknesses

- This is a full observability platform, not a small harness library. Reusing it requires understanding Rust services, Next.js actions, ClickHouse migrations, Postgres state, Quickwit, RabbitMQ/lite queues, and Python SQL validation.
- The repo does not include the main external SDKs as source, so the CI/eval runner story must be inferred from APIs and UI rather than copied as a complete local harness.
- Prompt management is partial. There are playground prompts, signal prompts, stored prompt hashes, render templates, and prompt summaries, but not a dedicated versioned prompt registry comparable to a prompt-management product.
- Self-hosting is operationally heavy. The full stack uses Postgres, ClickHouse, Quickwit, RabbitMQ, query-engine, app-server, frontend, and optional object storage/data-plane services.
- The committed quickstart `.env` uses fixed demo secrets and passwords, and Docker Compose pulls some `latest` images. That is convenient for local setup but unsafe as a production baseline.
- Render templates compile user JSX in an iframe with `unsafe-eval`/`unsafe-inline` style allowances. This is useful for flexible visualization, but it assumes a trusted-user or carefully isolated self-host posture.
- Signal quality depends on model behavior, trace compression choices, and cached drop rules. This is powerful for observability, but less deterministic than strict CI regression checks.

## Ideas To Steal

- Use OpenTelemetry as the common ingestion format, then normalize LLM/tool/evaluator conventions into a small internal span model.
- Store trace and eval facts in an analytic database so agents, dashboards, and CI checks can ask the same questions.
- Keep eval datapoints linked to trace ids, dataset ids, group ids, executor outputs, and score JSON so regression failures can be inspected down to the run trace.
- Add a project-scoped SQL validator and expose it to agents through MCP. This is more flexible than hard-coding every dashboard query.
- Build trace-context tools that return compact span trees first, then let the agent fetch full span data only when needed.
- Extract and hash system prompts to identify subagents and repeated agent paths without repeatedly storing or prompting on the full text.
- Use LLM-based signals as asynchronous observability classifiers, but keep their prompts, inputs, outputs, and trace references inspectable.
- Offer a lite self-host mode that reduces queue dependencies for local labs, while keeping the production path queue-backed.

## Do Not Copy

- Do not copy the whole SaaS-shaped platform into a coding-agent lab. The transferable pieces are trace ingestion, eval storage, SQL/MCP access, dataset versioning, and compression, not the entire product surface.
- Do not treat demo Compose secrets as acceptable defaults for shared or production deployments.
- Do not rely on LLM signals as the only regression gate. CI should still have deterministic pass/fail checks and clear artifacts.
- Do not expose raw ClickHouse to agents. The query-engine validation and project-scoped rewrite are essential parts of the pattern.
- Do not make prompt tracking depend only on span attributes if the lab needs reviewed, versioned prompt releases.
- Do not allow arbitrary render-template code in an untrusted multi-tenant setting without a stronger sandbox story.

## Fit For Agentic Coding Lab

Laminar is a conditional but high-value source. It is not a SWE-bench runner, not an agent framework, and not a compact eval harness. Its best fit is as a reference architecture for observability-backed evaluation: capture detailed coding-agent traces, normalize tool and LLM spans, store eval and dataset records beside traces, expose safe SQL/MCP access, and build compression tools that let agents and judges inspect large runs.

For an Agentic Coding Lab, the most reusable patterns are the OTLP ingest pipeline, ClickHouse span/eval/dataset schemas, SQL validator, MCP trace tools, eval datapoint grouping, signal trace compression, and trace-chat skeleton/detail split. The least reusable parts are the broad product UI, deployment complexity, and prompt/render-template surfaces that are not central to coding-agent regression testing.

## Reviewed Paths

- `README.md`: product scope, tracing/evals/datasets/signals/dashboard claims, SDK references, and self-host quickstart posture.
- `CONTRIBUTING.md`, `docker-compose.yml`, `docker-compose-full.yml`, `docker-compose.local-*.yml`, `.env`: local development, lite/full self-host topology, service dependencies, ports, and default secrets.
- `.github/workflows/backend-build-and-test.yml`, `.github/workflows/fe-build-check.yml`, `.github/workflows/query-engine-tests-check.yml`: build/test coverage for Rust backend, frontend build, and query-engine validation.
- `app-server/Cargo.toml`, `app-server/src/main.rs`: backend dependencies, service modes, runtime initialization, queue/cache/pubsub/storage/query-engine setup, and route registration.
- `app-server/src/api/v1/traces.rs`, `app-server/src/traces/grpc_service.rs`, `app-server/src/traces/producer.rs`, `app-server/src/traces/consumer.rs`, `app-server/src/traces/processor.rs`, `app-server/src/traces/spans.rs`: OTLP ingestion, authentication, queueing, worker processing, span normalization, cost calculation, and indexing hooks.
- `app-server/src/ch/spans.rs`, `app-server/src/ch/traces.rs`, `app-server/src/ch/datapoints.rs`, `app-server/src/ch/evaluation_datapoints.rs`, `frontend/lib/clickhouse/migrations/*.sql`: ClickHouse schema behavior for spans, traces, datasets, eval datapoints, and migrations.
- `app-server/src/api/v1/evals.rs`, `app-server/src/evaluations/mod.rs`, `frontend/lib/actions/evaluation/*`, `frontend/components/evaluation/*`: evaluation creation, datapoint writes/updates, score storage, grouped comparison, query builder, and trace-linked UI.
- `app-server/src/api/v1/datasets.rs`, `frontend/lib/actions/datasets/*`, `frontend/components/dataset*`: dataset metadata, datapoint insertion, versioned views, querying, export, and UI workflows.
- `query-engine/src/*`, `query-engine/tests/test_validation.py`, `app-server/src/sql/*`, `app-server/src/api/v1/sql.rs`: SQL validation, rewrite, ClickHouse execution limits, readonly behavior, data-plane routing, and tests.
- `app-server/src/api/v1/mcp.rs`: MCP tools for project-scoped Laminar SQL and trace context retrieval.
- `app-server/src/signals/*`, `app-server/src/db/signals.rs`, `frontend/lib/actions/signals/*`: signal definitions, triggers, trace compression, prompt summaries, drop rules, structured classification, and signal stats.
- `frontend/lib/actions/trace/agent/*`, `frontend/components/traces/*`: trace-agent chat, span skeleton/detail retrieval, subagent grouping, trace side panels, and trace inspection behavior.
- `frontend/lib/actions/debugger-sessions/*`, `app-server/src/routes/rollouts.rs`: debugger sessions, rollout run requests, trace linkage, and realtime session updates.
- `frontend/lib/db/migrations/schema.ts`, `frontend/lib/auth.ts`, `frontend/proxy.ts`, `frontend/lib/authorization/*`, `frontend/lib/crypto.ts`, `app-server/src/auth/*`, `app-server/src/project_api_keys/*`, `app-server/src/data_plane/*`: relational model, session auth, middleware membership checks, secret encryption, project API keys, ingest-only keys, and hybrid data-plane authentication.
- `frontend/components/playground/*`, `frontend/lib/actions/playground*`, `frontend/lib/actions/render-template/*`, `frontend/lib/template-renderer/*`: playground prompts, model/tool settings, trace side panel integration, and render-template sandbox caveats.
- `frontend/lib/quickwit/indexes/*.yaml`, `app-server/src/quickwit/*`, `app-server/src/search/*`: full-text indexing, preprocessing, retention, span/event search, and ClickHouse enrichment.

## Excluded Paths

- `images/`, `frontend/public/*`, blog/static/marketing assets, screenshots, fonts, and icons: not relevant to trace/eval architecture or coding-agent applicability.
- Generated protobuf bindings and generated API/client artifacts: reviewed callers and mapping logic instead of generated code.
- Lockfiles, package-manager cache artifacts, build outputs, and dependency metadata: not useful for architectural review.
- Broad UI primitives, styling, layout wrappers, and chart presentation details: excluded unless they directly exposed trace, eval, dataset, signal, playground, or debugger behavior.
- Billing, pricing, invitation email templates, organization administration, and unrelated settings pages: not part of agent observability, eval storage, datasets, prompt management, self-host security, or CI regression fit.
- Provider-specific model option minutiae beyond auth, encryption, prompt/playground storage, and trace/eval interactions: the review focused on reusable harness and observability patterns.
- External SDK package implementations referenced by the README: they are not vendored in this repository, so API contracts and platform paths were reviewed instead.
