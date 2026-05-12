# AgentOps-AI/agentops

- URL: https://github.com/AgentOps-AI/agentops
- Category: harness-eval
- Stars snapshot: 5,541 (GitHub REST API, captured 2026-05-12)
- Reviewed commit: a855a92dfaa7fd4423f9a68b1ba0295a3a72da80
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: conditional
- Verdict: Strong agent observability and replay substrate, especially for OpenTelemetry traces, sessions, LLM spans, tool calls, costs, logs, and dashboard debugging. It is not yet a first-class evaluation harness: evals are mostly roadmap, DSPy callback spans, validation helpers, prompt-injection checks, and examples rather than dataset/judge/job scoring infrastructure.

## Why It Matters

AgentOps is a useful counterpoint to heavier eval platforms because its core implementation is centered on agent trace capture and inspection. The Python SDK makes a session into an OpenTelemetry root span, instruments LLM/provider/framework calls, records tool and agent spans, exports spans through OTLP with project-scoped JWT auth, and renders traces in a dashboard waterfall/tree/graph interface.

For an agentic coding lab, the strongest value is the trace model: sessions as root spans, agent/workflow/task/tool/LLM span kinds, automatic framework integrations, cost/token metrics, log uploads, public trace APIs, and an MCP server wrapper for querying traces from coding tools. The weaker fit is evaluation: the repository markets evals and has roadmap items, but the reviewed implementation does not provide the durable dataset, run, judge, score, or regression lifecycle expected from a harness-eval system.

## What It Is

AgentOps is an open-source AI-agent observability product with three main pieces:

- `agentops`: Python SDK, decorators, OpenTelemetry setup, exporters, semantic conventions, provider instrumentation, framework instrumentation, validation helpers, and legacy session/event compatibility.
- `app/api`: FastAPI backend for auth, legacy event ingestion, v3 JWT token exchange, v4 trace/log/object APIs, public read-only APIs, Supabase metadata, ClickHouse trace querying, and storage upload.
- `app/dashboard`: Next.js dashboard for trace lists, drilldown drawers, waterfall/session replay, graph/tree views, logs, agents, tasks, metrics, raw JSON export, and older time-travel UI.

Modern tracing uses OpenTelemetry spans. Legacy `Session`, `LLMEvent`, `ToolEvent`, and `ErrorEvent` types are still present, but much of the current behavior maps to root trace spans and auto-instrumented child spans rather than explicit event submission.

## Research Themes

- Token efficiency: Captures prompt/completion/cache/reasoning token counts and costs, but it does not reduce coding-agent prompt tokens. Useful pattern: token and cost metrics are stored as span attributes and aggregated in ClickHouse, so optimization can be measured without changing the runtime.
- Context control: Strong trace/session boundaries. Root spans hold tags and project resource attributes; child spans capture operation/tool/LLM context; public APIs and dashboard filters make trace-level context queryable.
- Sub-agent / multi-agent: Good observability fit. OpenAI Agents, CrewAI, AG2, Agno, ADK, DSPy, LangGraph, and other integrations map agents, handoffs, workflows, tools, and LLM calls into spans. It observes multi-agent runs; it does not orchestrate them.
- Domain-specific workflow: Strong for agent monitoring. The workflow is SDK init -> trace/session root -> instrumented agent/tool/LLM spans -> OTLP export -> ClickHouse storage -> dashboard/API/MCP inspection.
- Error prevention: Moderate. It records errors, status codes, exceptions, prompt-injection flags through PromptArmor in legacy paths, validation helpers for LLM spans, protected exporter headers, JWT auth, Sentry sanitization, and access checks. It lacks strict CI-style failure policy.
- Self-learning / memory: Conditional. Historical traces, logs, metrics, and public APIs can act as a memory/debug corpus. There is no built-in learning loop, policy update mechanism, or memory compaction strategy for coding agents.
- Popular skills: No skill marketplace. Reusable "skills" are observability primitives: decorators, auto-instrumentors, trace validation, public API/MCP trace lookup, session replay, tool-span rendering, and framework-specific span processors.

## Core Execution Path

The SDK entry point is `agentops.init()`. `agentops/client/client.py` builds config from arguments and environment, initializes the API client, starts async auth against `/v3/auth/token`, sets the v4 JWT once returned, initializes tracing, optionally installs import-time auto-instrumentation, and optionally auto-starts a session trace. The config defaults to `instrument_llm_calls=True` and `auto_start_session=True`.

`agentops/sdk/core.py` creates an OpenTelemetry `TracerProvider`, attaches a `BatchSpanProcessor` with `AuthenticatedOTLPExporter`, adds an internal span processor, configures metrics, and exposes `start_trace`, `end_trace`, `make_span`, and `finalize_span`. A session or trace is a root span; non-session decorators create child spans in the current context. Trace URLs are logged as dashboard session replay links.

Decorators in `agentops/sdk/decorators/factory.py` and `utility.py` turn `@session`, `@agent`, `@workflow`, `@task`, `@operation`, `@tool`, and related wrappers into spans. They handle sync, async, sync generator, async generator, class, and method forms. Inputs and outputs are JSON-serialized into span attributes with a 1 MB limit. Tool decorators can set `gen_ai.usage.total_cost`. Session decorators end traces as `Success` or `Indeterminate`, while errors become span exceptions and error statuses.

Automatic instrumentation in `agentops/instrumentation/__init__.py` hooks Python imports, detects provider packages and agentic frameworks, and installs the relevant instrumentor. Provider instrumentation wraps OpenAI, Anthropic, Google GenAI, IBM watsonx, and Mem0 calls. Agentic framework instrumentation handles libraries such as OpenAI Agents, CrewAI, AG2, ADK, Agno, LangGraph, Smolagents, xpander, and Haystack. It avoids double instrumentation by preferring one active agentic framework over raw provider wrapping when needed.

OpenAI instrumentation wraps chat completions, Responses API calls, streaming, assistants, embeddings, and image paths. It extracts model, prompt, completion, tool definitions, tool calls, usage tokens, reasoning/cache tokens, streaming timing, and cost attributes. For OpenAI chat tool calls it may create tool-call spans from model-requested calls; those represent requested/planned calls and are not always the same thing as the actual external tool execution unless another decorator/framework span captures that execution.

OpenAI Agents SDK integration uses the Agents tracing processor interface. The AgentOps processor receives trace and span start/end events, the exporter creates OTel spans, tracks active spans by original IDs, preserves parent-child hierarchy, and maps AgentSpanData, FunctionSpanData, GenerationSpanData, ResponseSpanData, HandoffSpanData, and GuardrailSpanData into agent/tool/LLM/handoff/guardrail attributes.

On the backend, the SDK exchanges API keys for JWTs through v3 auth. OTLP trace export targets the collector endpoint, where `app/opentelemetry-collector/config` uses JWT auth, injects project id into resource attributes, batches telemetry, and writes traces/logs/metrics to ClickHouse. The main table is `otel_traces`; migrations derive `project_id` from `ResourceAttributes['agentops.project.id']`, index trace/span/project fields, and provide model-cost UDFs/dictionaries.

The v4 trace API queries ClickHouse. `TraceListView` checks project membership, applies time/search/pagination filters, calls `TraceListModel`, computes cost/token metrics, and returns trace summaries. `TraceDetailView` fetches all spans for a trace, checks project access, nests OTel attributes for the dashboard, and attaches span metrics for LLM-like spans. Public read-only endpoints expose project, trace, trace metrics, span, and span metrics after API-key-to-JWT exchange.

The dashboard calls `/v4/traces/list/{projectId}` and `/v4/traces/detail/{traceId}`. Trace drilldown exposes session replay waterfall, tree view, graph view, agents view, tasks view, metrics, logs, raw trace export, and framework-specific span visualizers. The MCP docs describe an external `agentops-mcp` package that mirrors the public API as tools for auth, trace lookup, span lookup, and complete trace lookup.

## Architecture

The architecture is split between runtime SDK, telemetry ingestion/storage, and product UI.

The Python SDK owns runtime capture. It uses OpenTelemetry as the internal representation, semantic-convention modules for AgentOps/GenAI/tool attributes, decorators for explicit spans, import monitoring for automatic instrumentation, and a JWT-injecting OTLP exporter. It also keeps legacy API compatibility through `agentops.legacy`, where old session/event classes mostly wrap or no-op around the new tracing path.

The self-hosted app uses FastAPI for API routes, Supabase/Postgres for users/orgs/projects/API keys and legacy session tables, ClickHouse for OTel traces/logs/metrics, an OpenTelemetry Collector for ingestion, S3-compatible Supabase storage for uploaded objects and logs, and Next.js for the dashboard. v1/v2 routes support legacy session/event/log/time-travel behavior. v3 exchanges API keys for JWTs. v4 is the current trace, log, object, and metrics surface.

ClickHouse is the high-volume trace store. `SpanModel` maps raw `otel_traces` rows into typed spans. `TraceModel` aggregates spans into one trace. `TraceSummaryModel` groups by `TraceId`, picks root-ish names/tags with `argMin`, computes start/end/duration/span counts/error counts, and sums stored or calculated costs. `SpanMetricsMixin` and `TraceMetricsMixin` derive token and cost metrics from GenAI span attributes.

The dashboard is presentation-heavy but semantically important. It reconstructs span hierarchy from `parent_span_id`, infers span type from nested attributes and framework conventions, renders tool/agent/LLM details, exposes logs linked by trace id, and lets users export/copy raw trace JSON. This is closer to "debugger" than "benchmark harness": it is built around inspecting one run or a filtered run set.

## Design Choices

- OpenTelemetry-first trace model: AgentOps avoids inventing a wholly custom event protocol for the modern path and stores spans in standard OTel-shaped ClickHouse tables.
- Sessions as root spans: `session` and `trace` are not separate durable entities in the modern path; they are root spans plus tags/resource attributes.
- Decorators plus auto-instrumentation: users can manually mark agent/workflow/task/tool boundaries while common providers/frameworks are captured automatically.
- Fail-soft SDK behavior: auth, export, URL logging, async HTTP, and instrumentation errors are generally logged or swallowed so user agent execution continues.
- Dynamic JWT exporter: the OTLP exporter calls a token provider at export time and protects critical headers from user-supplied overrides.
- Project id injected by collector: the collector validates JWT and upserts `agentops.project.id` into resources before ClickHouse storage, reducing reliance on client-supplied project attributes.
- Backward compatibility: legacy v1/v2 sessions/events/logs/time-travel APIs coexist with OTel v4 traces, which helps migration but adds conceptual load.
- Dashboard inference over normalized types: span type and framework-specific views are often inferred from span names/attributes rather than a single stable backend enum.
- Public API/MCP read path: trace data is deliberately exposed through read-only APIs and an MCP wrapper, which makes observability data available to coding assistants.

## Strengths

- Clean transferable model for agent observability: root session trace, child agent/workflow/task/tool/LLM spans, tags, status, metrics, and dashboard replay.
- Good framework coverage for real agent stacks, including OpenAI Agents, CrewAI, AG2, Agno, ADK, DSPy, LangGraph, provider SDKs, and streaming LLM calls.
- Tool visibility is practical: decorators capture actual tool executions, OpenAI Agents maps function spans to tools, and OpenAI provider wrappers capture model tool-call requests.
- Trace metrics are useful for coding-agent debugging: prompt/completion/cache/reasoning tokens, total tokens, costs, status splits, latency, errors, and logs.
- The dashboard provides multiple debugging lenses over the same trace: waterfall, tree, graph, agents, tasks, tool viewers, logs, terminal output, metrics, and raw JSON.
- Public API and MCP shape are valuable for agentic coding tools that need to fetch failing traces and reason over them without screen scraping.
- Security has several concrete controls: JWT auth, project membership checks, Sentry variable redaction, upload size limits, trace-log access checks, protected OTLP headers, and collector-side auth resource injection.
- Unit tests cover important SDK behavior: decorator nesting, async/generator handling, tool costs, exporter failure modes, protected headers, OpenAI/OpenAI Agents attribute extraction, validation helpers, storage/log permissions, public API auth, and ClickHouse query generation.

## Weaknesses

- Evaluation is not first-class in the reviewed implementation. There is no durable dataset/run item model, judge job lifecycle, score schema, leaderboard, regression gate, or CI harness comparable to a true harness-eval system.
- "Session replay" is trace replay in the observability sense: waterfall/detail reconstruction. It is not deterministic execution replay of an agent process.
- Time Travel Debugger exists as alpha/legacy UI around LLM completion editing and cache-based reruns, but the reviewed code shows commented or thin integration and v2 `ttd` retrieval rather than a current OTel replay system.
- Modern and legacy models overlap. Sessions/events/actions/llms/tools/errors, v1/v2 routes, OTel spans, v4 traces, and dashboard legacy interfaces can make the architecture harder to reason about.
- SDK fail-soft behavior is good for production agents but weak for strict harnesses; export/auth/instrumentation failures can disappear as warnings or `None` responses instead of failing the run.
- Trace content can include prompts, completions, tool arguments, tool results, host/resource data, and logs by default. There is size limiting but no general SDK-side secret redaction policy in the reviewed paths.
- The v4 trace list accepts `order_by` and `sort_order` query strings and passes them into ClickHouse ORDER BY text. Tests document query generation, but an in-code comment says this should be restricted to an enum.
- Object/log upload client and server contracts look easy to misuse: server upload views stream raw request bodies, while the SDK v4 client sends `json={"body": body}` for uploads.
- Dashboard span typing depends heavily on framework/name/attribute heuristics, which will require fixture maintenance as provider and framework conventions change.

## Ideas To Steal

- Model every coding-agent run as a root trace with explicit child spans for planner, editor, shell command, file patch, test run, LLM call, and tool call.
- Keep OpenTelemetry-compatible spans as the common capture format, but add a narrow coding-agent semantic layer for patches, commands, tests, reviews, and failures.
- Use decorators or context managers for explicit agent/tool/task boundaries, then supplement them with automatic instrumentation where reliable.
- Preserve both requested tool calls and actual tool executions as distinct span types; this helps debug hallucinated or skipped tool usage.
- Expose trace reads through a small MCP server so coding assistants can fetch failed-run traces, span details, logs, and metrics during debugging.
- Store logs as trace-linked objects and enforce trace/project membership before retrieval.
- Inject trusted project/resource attributes server-side during telemetry ingestion, not only in the SDK.
- Add validation helpers that poll for a trace, check expected span kinds, verify token/cost metrics, and fail loudly in CI.
- Build trace UI around hierarchy, waterfall, raw attributes, logs, tool arguments/results, and cost/tokens before building broad product dashboards.
- Use framework-specific processors only when they can map to a stable common schema; keep raw attributes available for unknown frameworks.

## Do Not Copy

- Do not copy the whole SaaS surface: billing, org management, marketing pages, self-host deployment machinery, and broad dashboard chrome are not required for a coding-agent lab.
- Do not treat roadmap eval claims as implemented architecture. Build datasets, run items, scorers, judge jobs, score schemas, and regression gates explicitly.
- Do not let a harness fail open on missing telemetry. In CI/eval mode, missing spans, auth failures, upload failures, and validation errors should be hard failures.
- Do not conflate LLM tool-call requests with actual tool execution. Coding-agent harnesses need both, with clear labels.
- Do not rely on name heuristics alone for critical span typing. Coding-agent spans should carry stable typed attributes.
- Do not collect repository contents, prompts, tool args, shell output, and logs without a redaction and retention policy.
- Do not inherit legacy v1/v2 session/event/time-travel tables unless backward compatibility is a real requirement.
- Do not expose free-form SQL order fields from API query parameters; use explicit enums and server-side mapping.

## Fit For Agentic Coding Lab

Conditional fit. AgentOps is best used as an observability/debugging reference, not as the evaluation harness itself. Its span schema, SDK ergonomics, OpenTelemetry export path, ClickHouse metrics, dashboard replay views, public API, and MCP access are highly relevant to coding-agent traces.

For this repository, the most transferable pieces are: session-as-root-trace, typed spans for agents/tasks/tools/LLMs, automatic instrumentation plus manual decorators, trace-linked logs, cost/token aggregation, public trace APIs, and validation helpers. The missing pieces to add for harness-eval are dataset definitions, expected outputs, scorer configuration, judge execution traces, score storage, regression comparison, and CI failure semantics.

## Reviewed Paths

- `README.md`, `pyproject.toml`: product scope, quickstart, integrations, roadmap claims, packaging, dependencies, and distribution exclusions.
- `docs/v2/concepts/traces.mdx`, `docs/v2/concepts/spans.mdx`, `docs/v2/usage/manual-trace-control.mdx`: modern trace/span concepts, decorator model, trace states, tags, hierarchy, and manual trace control.
- `docs/v2/usage/public-api.mdx`, `docs/v2/usage/mcp-server.mdx`: read-only trace/span APIs, JWT auth, metrics endpoints, and MCP trace-query shape.
- `agentops/__init__.py`, `agentops/client/client.py`, `agentops/config.py`: public SDK API, client lifecycle, config/env behavior, auth, auto-start sessions, and instrumentation setup.
- `agentops/sdk/core.py`, `sdk/decorators/factory.py`, `sdk/decorators/utility.py`, `sdk/exporters.py`, `sdk/processors.py`, `sdk/attributes.py`: tracing core, span lifecycle, decorators, serialization, authenticated OTLP export, root-span log upload, and resource/span attributes.
- `agentops/semconv/span_kinds.py`, `span_attributes.py`, `tool.py`: AgentOps, GenAI, and tool semantic attributes.
- `agentops/instrumentation/__init__.py`, `instrumentation/common/*`: import-time instrumentor registration, provider/framework selection, common wrapper behavior, streaming helpers, and token counting.
- `agentops/instrumentation/providers/openai/*`: OpenAI chat, Responses API, streaming, assistants, tool-call, prompt/completion, and token/cost extraction.
- `agentops/instrumentation/agentic/openai_agents/*`: OpenAI Agents trace processor, exporter, span hierarchy, agent/function/tool/LLM/handoff/guardrail mappings, docs, and tests.
- `agentops/integration/callbacks/dspy/callback.py`: DSPy callback spans, including module/tool/evaluate hooks and auto-session behavior.
- `agentops/legacy/__init__.py`, `agentops/legacy/event.py`: backward-compatible sessions, event classes, `record` behavior, and old LLM/tool/error fields.
- `agentops/validation.py`: public API polling, LLM span checks, trace metric validation, and retry behavior.
- `app/README.md`, `app/api/README.md`: self-host architecture, services, ports, auth assumptions, and API surface.
- `app/opentelemetry-collector/config/*`, `app/clickhouse/migrations/*`: OTLP receiver, JWT auth extension, project-id resource injection, ClickHouse exporters, OTel tables, indexes, TTLs, and cost UDFs.
- `app/api/agentops/app.py`, `api/app.py`, `public/app.py`, `public/routes.py`: FastAPI app structure, route mounts, CORS, Sentry, middleware, and public API registration.
- `app/api/agentops/api/auth.py`, `public/v1/auth.py`, `public/v1/base.py`, `public/v1/traces.py`, `public/v1/spans.py`: API-key-to-JWT exchange, JWT verification, project scoping, public trace/span access, and metrics reads.
- `app/api/agentops/api/routes/v1.py`, `routes/v2.py`, `routes/v3.py`, `api/event_handlers.py`, `api/promptarmor.py`: legacy session/event ingestion, old logs/time-travel routes, JWT token exchange, event classification, and PromptArmor checks.
- `app/api/agentops/api/routes/v4/traces/*`, `api/models/traces.py`, `api/models/span_metrics.py`, `api/db/clickhouse/models.py`, `api/db/clickhouse_client.py`: trace list/detail views, response models, OTel attribute nesting, trace/span metrics, query generation, and ClickHouse clients.
- `app/api/agentops/api/routes/v4/objects.py`, `routes/v4/logs.py`, `api/storage.py`: object/log uploads, size limits, trace id filename validation, storage URLs, and log retrieval authorization.
- `app/dashboard/hooks/useTraces.ts`, `hooks/queries/useTraceDetail.ts`, `lib/api-client.ts`, `types/ITrace.ts`: dashboard API client behavior, trace list/detail fetching, retry behavior, and trace/span types.
- `app/dashboard/app/(with-layout)/traces/page.tsx`, `_components/trace-drilldown-drawer.tsx`, `_components/session-replay.tsx`, `_components/spans-gantt-chart.tsx`, `_components/span-processing.ts`, `_components/log-trace-viewer.tsx`, `_components/trace-export.ts`: trace list UX, drilldown tabs, waterfall/tree/graph views, span type inference, log viewer, and JSON export.
- `app/dashboard/app/(with-layout)/traces/_components/event-visualizers/*`, `_components/agents-viewer/*`, `_components/tasks-viewer.tsx`: tool/agent/task visualizers and framework-specific processors.
- `app/dashboard/components/time-travel/*`, `app/dashboard/app/(with-layout)/timetravel/*`, `app/supabase/migrations/*ttd*`: alpha/legacy time-travel UI, branch snapshot UI, ttd table, and v2 retrieval path.
- `tests/unit/sdk/*`, `tests/unit/instrumentation/openai_core/*`, `tests/unit/instrumentation/openai_agents/*`, `tests/unit/instrumentation/common/*`, `tests/unit/test_session.py`, `tests/unit/test_events.py`, `tests/unit/test_validation.py`, `tests/unit/client/*`: SDK, decorators, exporter, instrumentation, session, legacy event, validation, and client behavior tests.
- `tests/benchmark/*`, `tests/core_manual_tests/benchmark.py`, `tests/integration/*`, `tests/fixtures/recordings/*`: available benchmarks, integration tests, and provider VCR fixtures.
- `app/api/tests/v3/*`, `app/api/tests/v4/*`, `app/api/tests/public/test_public_api.py`, `app/api/tests/interactors/test_span_handlers.py`, `app/api/tests/common/*`, `app/api/tests/db/clickhouse/test_model_query_builder.py`, `app/api/tests/test_sentry_sanitizer.py`: server-side auth, storage/logs, public API, span classification, OTel nesting, free-plan truncation, ClickHouse query generation, and security sanitization tests.

## Excluded Paths

- `uv.lock`, `app/dashboard/bun.lock`, `app/dashboard/package-lock.json`, `docs/package-lock.json`: lockfile internals were excluded; dependency shape was reviewed through manifests and code paths.
- `docs/images`, `docs/public`, dashboard static images/icons/logo assets, screenshots, videos, SVG/PNG/JPEG/GIF files, and notebook output blobs: binary/static or media-only content unrelated to trace/eval architecture.
- Most `docs/v0` and `docs/v1`: sampled only where legacy behavior mattered; v2 docs and implementation are the current trace model.
- Most `examples/*` and `.ipynb` notebooks: useful as demos but not authoritative architecture; only search results were used to confirm eval examples versus product eval infrastructure.
- Provider integrations beyond OpenAI/OpenAI Agents/Common/DSPy were not deeply line-reviewed because the important harness pattern is the shared span schema and instrumentation lifecycle, not every vendor wrapper.
- Billing, Stripe, org/project admin, welcome survey, marketing pages, deployment product UI, support flows, and unrelated dashboard layout/theme components: not relevant to trace/session/tool/eval/debug/security architecture except where tests or auth boundaries touched them.
- `app/deploy/jockey`, Kubernetes/deploy scripts, Docker orchestration internals, and self-host convenience scripts: operationally useful, but not central to agent observability or harness-eval semantics.
- Generated, vendored, cache, build, and coverage artifacts: excluded as non-source or reproducible output.
- Large provider VCR recordings under `tests/fixtures/recordings/*`: existence and purpose noted, but raw cassette payloads were not read because they are generated test fixtures with sensitive/noisy HTTP data.
- UI-only React components outside trace/time-travel/log/agent/task views: excluded unless they changed runtime trace semantics, API behavior, replay/debugging, or access control.
