# ENTERPILOT/GoModel

- URL: https://github.com/ENTERPILOT/GoModel
- Category: error-prevention
- Stars snapshot: 884 captured 2026-05-19 via GitHub REST API
- Reviewed commit: c9a42717cbd1f39713c24fa9874ea102288f4c71
- Reviewed at: 2026-05-19
- Status: reviewed
- Scope fit: conditional
- Verdict: Strong source of practical gateway patterns for preventing LLM call failures, policy drift, runaway cost, and audit gaps. Use it as a design reference for Agentic Coding Lab request envelopes, workflow caps, guardrail hashing, fallback gates, budget checks, and contract replay tests; do not copy its unsafe default exposure patterns or its full gateway/admin surface.

## Why It Matters

GoModel puts most LLM failure controls in one request path: auth, user-path scoping, workflow selection, guardrails, response caching, usage logging, budgets, fallback, retry, circuit breaking, audit capture, and streaming observers. That is useful for Agentic Coding Lab because coding agents fail less from one missing check than from inconsistent enforcement across model calls, tool calls, retries, caches, and streams.

The repo is not an agent framework. Its value is architectural: it shows how to make every model request carry enough metadata to explain who sent it, which policy governed it, what provider/model actually ran, whether guardrails modified it, whether cache/fallback was used, and how cost was recorded.

## What It Is

GoModel is an OpenAI-compatible AI gateway written in Go. It exposes `/v1/chat/completions`, `/v1/responses`, `/v1/embeddings`, `/v1/models`, file and batch endpoints, provider-native passthrough routes under `/p/{provider}/...`, admin APIs, a dashboard, `/health`, and optional Prometheus metrics. It supports OpenAI, Anthropic, Gemini, Groq, xAI, OpenRouter, Z.ai, Azure OpenAI, Oracle, Ollama, vLLM, Bedrock, DeepSeek, and Vertex-style providers through a router and adapter layer.

The actual protection path is server middleware plus gateway orchestration. Requests are captured, semantically enriched where possible, authenticated, matched to a workflow, optionally patched by guardrails, checked against cache and budgets, dispatched to a provider, observed for audit/usage, and normalized into OpenAI-style errors.

## Research Themes

- Token efficiency: Exact and semantic response caching reduce repeated LLM calls; usage extraction and pricing resolve token/cost records. It does not implement coding-agent prompt compaction or token budgeting beyond cache, pricing, and spend limits.
- Context control: `user_path`, auth keys, model authorization, workflow scopes, request snapshots, `WhiteBoxPrompt`, and guardrail patching create a controlled request context before provider dispatch.
- Sub-agent / multi-agent: No multi-agent runtime. The internal LLM-based guardrail call is the closest pattern: an auxiliary model call with an origin flag, separate user path, and recursion prevention.
- Domain-specific workflow: Gateway domain, not coding workflow. The workflow model maps well to lab policies for experiments, teams, repos, or model classes.
- Error prevention: Strong fit. Auth, body limits, request IDs, model access checks, guardrails, fallback gates, retries, circuit breakers, budget rejection, redaction, and replay tests are all prevention-oriented.
- Self-learning / memory: No self-learning loop. Operational memory appears as caches, audit logs, usage records, model metadata, workflows, guardrail definitions, and budget state.
- Popular skills: Not a skill repository. Useful transferable skills are workflow-scoped feature flags, fallback matrices, guardrail configs, request envelopes, and contract replay fixtures.

## Core Execution Path

`cmd/gomodel/main.go` loads dotenv/config, initializes logging, registers provider factories, optionally installs Prometheus hooks, builds `app.New`, and starts the HTTP server with graceful shutdown.

`internal/app/app.go` wires the runtime: provider registry/router, storage-backed audit logs, usage logs, budgets, batch/file stores, model aliases, model overrides, pricing overrides, guardrails, workflows, auth keys, admin handlers, response cache, and the server. It disables budget management if usage tracking is off, because budgets depend on recorded spend.

`internal/server/http.go` installs the hot path middleware: base-path stripping, request logging/recovery, body size limit, request ID, write deadlines for model interactions, request snapshot capture, optional passthrough semantic enrichment, audit middleware, auth middleware, workflow resolution, and route handlers.

Translated `/v1/chat/completions` and `/v1/responses` requests flow through `internal/server/translated_inference_service.go`: decode the canonical body, prepare model/workflow state, apply guardrail patching, try response cache, enforce budget on cache miss, dispatch to the gateway orchestrator, optionally fallback, then write audit, usage, response snapshots, and cache inserts. Cache hits return before budget enforcement and do not count as provider spend.

`internal/gateway/inference_prepare.go` and `internal/gateway/request_model_resolution.go` resolve aliases, provider/model selectors, model authorization, workflows, guardrails, and cache metadata. `internal/providers/router.go` then routes to a provider by qualified selector, provider type, provider instance, or dynamic model registry entry.

`internal/gateway/inference_execute.go` performs provider calls. Non-streaming calls can use retry/fallback and log usage after success. Streaming calls avoid retries, wrap SSE bytes with observers, and only use fast passthrough for compatible providers when no body rewrite, usage enforcement, or fallback path is needed.

Provider HTTP behavior lives in `internal/llmclient`. `DoRaw` retries retryable non-stream requests, `DoStream` does not retry streams, and the circuit breaker trips on retryable/5xx style failures while avoiding local request-build errors. Metrics hooks observe logical requests, not individual retry attempts.

Passthrough requests under `/p/{provider}/...` use `internal/server/passthrough_service.go`: the gateway authenticates first, enriches semantics when possible, checks model authorization and budgets when a model is known, strips inbound credentials and hop-by-hop headers, injects server-side provider credentials, and streams native responses through audit/usage observers.

## Architecture

The server layer owns HTTP boundaries, middleware ordering, auth, request snapshots, route registration, response writing, and error normalization.

The gateway layer owns translated request preparation, model resolution, workflow application, provider dispatch, fallback decisions, and usage logging.

The provider layer owns adapter registration, model registry refresh, provider availability checks, provider-specific clients, native file/batch/response lifecycle support, and passthrough routing.

The policy layer is split across workflows and guardrails. Workflows are immutable active versions selected by user path, provider, and model. Guardrails compile into a normalized message pipeline and are referenced by workflow policy.

The observability layer is composed from audit logs, live dashboard events, usage/cost records, response snapshots, Prometheus metrics, request IDs, and normalized gateway errors.

The storage layer supports sqlite/postgres/mongo-style backends for audit, usage, budget, workflow, auth key, alias, pricing override, model override, file, batch, and response snapshot state.

## Design Choices

Workflows are request-scoped runtime projections of persisted immutable policy versions. Process-level feature switches are hard caps over workflow features, so deployment config can disable cache, audit, usage, budget, guardrails, or fallback without rewriting stored policies.

`RequestSnapshot` preserves the transport input, while `WhiteBoxPrompt` is best-effort semantic extraction. This lets policy and audit work for both translated OpenAI-compatible routes and partial/opaque passthrough routes without pretending every payload has the same schema.

Guardrails run before provider dispatch and operate on normalized messages. Internal guardrail-origin calls disable guardrails on the derived workflow, preventing recursive guardrail calls.

Response cache runs after workflow and guardrail patching. Exact cache keys include path, final body, execution mode, provider type, and resolved model. Semantic cache keys also include guardrail hash, invariant conversation context, output parameters, tools, response format, reasoning, stream options, and embedder identity.

Fallback is deliberately narrow. It applies to translated chat and responses routes, not embeddings, and only after upstream 5xx, 429, model unavailable, unsupported, not found, deprecated, retired, or disabled style failures. It skips unauthorized fallback candidates.

Usage-backed budgets reject requests when matching user-path budgets are already exhausted. Budget errors return 429 with retry timing. Cache hits are excluded from provider spend.

Streaming is treated as a raw-byte preservation problem. Observers parse SSE events for audit and usage, but the proxy path writes the original stream frames and flushes each chunk.

## Strengths

The strongest pattern is the single request lifecycle. A model call can be traced from inbound request ID and auth key through workflow version, guardrail hash, cache result, provider/model resolution, fallback result, usage, cost, and audit log.

Failure classification is practical. Client errors and semantic request errors are not hidden by fallback; availability and rate-limit failures can be retried or rerouted.

The test strategy matches the risk surface: unit/E2E tests, DB-state integration tests, and contract replay tests with recorded provider payloads and golden outputs. Contract tests exercise adapter parsing and streaming conversion without network calls.

Security hygiene exists in the execution path: body limits, constant-time master key comparison, managed key user-path override, sensitive header redaction, inbound provider credential stripping on passthrough, request ID propagation, and generic auth errors to clients.

Observability is decoupled from provider code. Prometheus hooks are installed through the provider factory and observe logical requests, while audit and usage observers attach at server/gateway boundaries.

## Weaknesses

The repo is infrastructure-heavy for Agentic Coding Lab. Copying it whole would import provider adapters, storage systems, admin surfaces, dashboard code, and deployment concerns that are not needed for coding-agent research.

Defaults and docs contain dangerous exposure paths. If no `GOMODEL_MASTER_KEY` is configured, model APIs are unauthenticated. Admin API bootstrap and dashboard/static routes can be reachable without browser-side auth. If pprof is enabled, pprof routes are skipped by auth middleware. The quickstart's first docker command also demonstrates running with body/header logging flags and no master key before later docs recommend a key.

LLM-based altering guardrails fail open for per-message auxiliary model errors other than context cancellation/deadline. That is reasonable for best-effort anonymization but unsafe for hard policy enforcement.

Same-order guardrails run concurrently on the same input, and modification outputs do not compose; the pipeline applies the last successful same-order result in registration order. That can surprise operators who expect parallel guardrail rewrites to merge.

Budget enforcement is pre-request and based on already-recorded usage. Concurrent in-flight requests can overshoot a limit before usage records catch up.

Audit, usage, and cache writes are intentionally asynchronous or buffered in places. That is good for latency but means dropped writes are possible and should not be treated as a strict compliance ledger.

The passthrough documentation says native errors/status are proxied, but the implementation parses upstream non-2xx responses into normalized gateway errors in the copied response path. That mismatch matters for clients depending on exact provider error payloads.

Cache partitioning is not by `user_path` alone. Tenant isolation needs scoped workflows, differing final bodies, or explicit policy boundaries; relying on path labels alone would be unsafe.

## Ideas To Steal

Use a request envelope for every model call: `request_id`, auth key id, effective user path, workflow version id, workflow feature flags, guardrail hash, requested model, resolved provider/model, cache type, fallback target, usage id, and audit id.

Adopt workflow feature caps. Let stored policies request cache/audit/usage/budget/guardrail/fallback behavior, but let process config disable those features globally for a lab run.

Put guardrail identity into cache/eval keys. A response generated after prompt rewriting or policy injection should not share a cache bucket with an unguarded response.

Add an internal-call origin flag. Guardrail, judge, summarizer, and evaluator subcalls should be traceable and should avoid recursively applying the same policy stack unless explicitly intended.

Gate fallback by failure class. Retry or fallback on availability, rate limit, and model availability failures; do not hide bad prompts, invalid tool schemas, auth errors, or policy rejections behind another model.

Use bounded request snapshots. Preserve enough raw input for audit and semantic routing without forcing large or opaque bodies into memory.

Build contract replay tests around provider adapters and stream parsers. Recorded/golden payloads are a better guard against silent protocol drift than only mocking high-level success objects.

Make streaming observers non-mutating. Audit, cost extraction, and cache validation should observe SSE without changing the bytes delivered to the caller.

## Do Not Copy

Do not copy unauthenticated operation as a default. For a lab control plane, admin/API/dashboard/debug routes should require explicit auth unless bound to a local-only test harness.

Do not use fail-open LLM alteration for mandatory policy. Best-effort PII rewriting is different from a hard guardrail that must block on uncertainty.

Do not copy last-wins parallel guardrail modification semantics without making them explicit. If multiple same-step policies rewrite context, define merge, priority, or reject-on-conflict behavior.

Do not treat async audit/usage/cache writes as proof-grade records. Use synchronous durable writes or a transactional outbox when a lab result depends on exact accounting.

Do not assume user-path labels partition cache entries. Include policy, tenant, repo, task, and guardrail identity directly in cache keys where isolation matters.

Do not import the dashboard/admin/provider surface when the research goal is agent error prevention. The reusable part is the control envelope and execution ordering.

## Fit For Agentic Coding Lab

Conditional fit. GoModel is a strong reference for error-prevention infrastructure around LLM requests, especially if Agentic Coding Lab needs a model-call gateway, reproducible experiment policies, cost controls, or auditability across provider changes.

The best lab pattern is a smaller version of its pipeline: capture request snapshot, resolve policy, enforce auth/scope, patch or block with guardrails, check cache with policy hash, enforce spend/token budget, dispatch, fallback only on allowed failure classes, observe stream/usage/audit, and store enough metadata to replay or explain the run.

It is less useful for direct coding-agent behavior such as repository planning, tool orchestration, context compaction, memory synthesis, or multi-agent coordination. Use it underneath those systems, not as the agent brain.

## Reviewed Paths

- `README.md`
- `docs/getting-started/quickstart.mdx`
- `docs/dev/api-examples.md`
- `docs/dev/prometheus-metrics.md`
- `docs/TESTING_STRATEGY.md`
- `tests/contract/README.md`
- `docs/features/failover.mdx`
- `docs/features/cache.mdx`
- `docs/features/budgets.mdx`
- `docs/features/user-path.mdx`
- `docs/features/passthrough-api.mdx`
- `docs/advanced/resilience.mdx`
- `docs/advanced/guardrails.mdx`
- `docs/advanced/workflows.mdx`
- `docs/advanced/configuration.mdx`
- `docs/advanced/config-yaml.mdx`
- `docs/advanced/admin-endpoints.mdx`
- `docs/guides/codex.mdx`
- `docs/adr/0002-ingress-frame-and-semantic-envelope.md`
- `docs/adr/0003-policy-resolved-workflow.md`
- `docs/adr/0006-semantic-response-cache.md`
- `config/*.go`
- `config/config.example.yaml`
- `cmd/gomodel/main.go`
- `internal/app/app.go`
- `internal/server/http.go`
- `internal/server/auth.go`
- `internal/server/request_snapshot.go`
- `internal/server/translated_inference_service.go`
- `internal/server/passthrough_service.go`
- `internal/server/passthrough_support.go`
- `internal/server/passthrough_semantic_enrichment.go`
- `internal/server/error_support.go`
- `internal/server/budget_support.go`
- `internal/server/stream_support.go`
- `internal/gateway/inference_prepare.go`
- `internal/gateway/request_model_resolution.go`
- `internal/gateway/inference_execute.go`
- `internal/gateway/fallback.go`
- `internal/gateway/usage.go`
- `internal/gateway/workflow_policy.go`
- `internal/providers/router.go`
- `internal/providers/registry.go`
- `internal/providers/init.go`
- `internal/providers/config.go`
- `internal/llmclient/client.go`
- `internal/llmclient/circuit_breaker.go`
- `internal/guardrails/*.go`
- `internal/workflows/*.go`
- `internal/budget/*.go`
- `internal/usage/*.go`
- `internal/auditlog/*.go`
- `internal/responsecache/*.go`
- `internal/streaming/observed_sse_stream.go`
- `internal/observability/metrics.go`
- `internal/core/errors.go`
- `tests/e2e/*`
- `tests/integration/*`
- `tests/contract/*`

## Excluded Paths

- `cmd/gomodel/docs/docs.go` and `docs/openapi.json`: generated Swagger/OpenAPI output. Route behavior was reviewed from handlers, config, and docs instead.
- `internal/admin/dashboard/static/**`, `internal/admin/dashboard/templates/**`, `docs/dashboard.gif`, `docs/**/*.png`, `docs/**/*.jpg`, `docs/logo.svg`, `docs/wordmark-*.svg`, and `docs/brand/*.svg`: dashboard UI and visual assets. Dashboard auth/exposure behavior was reviewed through server/admin docs and tests, but UI implementation details were not part of the error-prevention execution path.
- `helm/**`, `Dockerfile`, `docker-compose.yaml`, and `prometheus.yml`: deployment packaging. Config boundaries were reviewed, but chart/container mechanics were outside the request-control path.
- `docs/2026-03-23_benchmark_scripts/**` and `docs/about/benchmark-tools/**`: benchmark utilities. They are useful for performance comparison, not for guardrails, fallback, cost tracking, auth, or streaming correctness.
- `tests/contract/testdata/**`: recorded/golden payload fixtures. The contract replay strategy and representative parser paths were reviewed, but each generated or recorded fixture was not manually audited.
- Provider-specific adapter internals under every `internal/providers/*` subdirectory: shared router, registry, provider initialization, config, and HTTP client behavior were reviewed. Individual provider translation edge cases were left to the repo's contract tests because the assignment focus was gateway/router/observability/guardrails/cost/streaming/error-prevention design.
- `vendor/**`, `node_modules/**`, `dist/**`, and `build/**`: no such dependency/vendor/build directories were present in the reviewed tree.
