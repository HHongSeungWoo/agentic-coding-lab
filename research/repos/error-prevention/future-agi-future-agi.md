# future-agi/future-agi

- URL: https://github.com/future-agi/future-agi
- Category: error-prevention
- Stars snapshot: 918 (GitHub REST API repository search, captured 2026-05-11)
- Reviewed commit: a07f982a83d2b569009951502dab0af70b2e2362
- Reviewed at: 2026-05-19
- Status: reviewed
- Scope fit: conditional
- Verdict: Strong reference for an error-prevention platform and LLM gateway, especially guardrail orchestration, trace-driven evals, and typed tool execution. It is too broad to copy wholesale, and several defaults are permissive enough that Agentic Coding Lab should lift the patterns, not the exact policy posture.

## Why It Matters

Future AGI is useful because it puts several error-prevention layers on the same execution path: an OpenAI-compatible gateway, pre/post/stream guardrails, tool policies, model validation, retries/failover, tracing, eval tasks, trace scanners, error clustering, MCP tools, and a Temporal-backed graph executor. For coding agents, the interesting lesson is not a single scanner. It is the combination of inline gates, structured runtime metadata, delayed evals, and trace-derived feedback loops.

The repo also shows common failure modes in these systems: safety features disabled or fail-open by default, safety bypass through cache ordering, broad MCP tool exposure, and sandbox code paths that look safer than they are. Those are valuable anti-patterns for our lab.

## What It Is

The repository is a self-hostable AI operations platform. The README describes a lifecycle of simulate, evaluate, protect, monitor, and optimize. The implementation is split across a Django backend (`futureagi/`), a Go gateway (`agentcc-gateway/`), a React frontend (`frontend/`), and runtime services such as PostgreSQL, ClickHouse, Redis, RabbitMQ, Temporal, MinIO, and a code-executor container.

The error-prevention surface is mostly in:

- `agentcc-gateway`: OpenAI-compatible LLM proxy with auth, RBAC, rate limits, budgets, cache, tool policy, validation, cost tracking, guardrails, routing, retries, failover, circuit breakers, MCP, and A2A.
- `futureagi/evaluations`: eval registry and unified eval runner for deterministic evals, custom code evals, prompt-based evals, and agent evals.
- `futureagi/tracer`: trace ingestion, inline evals, eval tasks, alert monitors, trace scanning, error analysis, and error clustering.
- `futureagi/ai_tools` and `futureagi/mcp_server`: typed platform tools exposed to LLMs through internal API and MCP transports.
- `futureagi/agent_playground` plus `futureagi/tfc/temporal/agent_playground`: graph execution, schema-validated port routing, dependency skip logic, and Temporal orchestration.

## Research Themes

- Token efficiency: The gateway has exact/semantic cache controls, token and cost metadata, and a rough model validation plugin. Trace/eval builders cap agent context for spans, traces, sessions, and nested span lists. This is more spend/latency control than context compression.
- Context control: Eval request builders map explicit observation attributes and cap span/trace/session context. Prompt versions snapshot model/config/messages. MCP and AI tools publish Pydantic schemas. Gateway model DB validation, tool policy, provider locks, org overrides, and guardrail policy metadata constrain request shape and routing.
- Sub-agent / multi-agent: The repo has graph/module execution, MCP, A2A support in the gateway, and LLM-powered error analysis/eval agents. It is not a coding-agent swarm framework; the multi-agent pieces are platform/runtime orchestration.
- Domain-specific workflow: The workflow is AI app quality operations: instrument traces, run evals, scan traces, cluster errors, monitor alerts, tune prompts, and protect live requests through gateway guardrails.
- Error prevention: Best-fit theme. It has inline request/response guardrails, streaming checks, tool permissions, model validation, retries/failover, trace scanners, eval tasks, annotation validation, PII scrubbers, structured tool errors, and graph dependency failure propagation.
- Self-learning / memory: Trace scan results, EvalLogger rows, error clusters, prompt versions, and optimization hooks can feed improvement loops. There is no compact autonomous memory layer to copy directly.
- Popular skills: Guardrail pipeline design, eval harness design, LLM-as-judge wiring, typed tool execution, MCP auth/rate limits, trace-based debugging, graph execution, sandboxed custom evals, and cost-aware routing.

## Core Execution Path

The live request path starts in `agentcc-gateway/cmd/agentcc/main.go` and `agentcc-gateway/internal/server/handlers.go`. Config is loaded, provider secrets are resolved, Redis-backed or in-memory stores are initialized, and the gateway builds a plugin chain. Depending on config, that chain includes IP ACL, auth, RBAC, budgets, quota, guardrails, tool policy, cache, rate limits, validation, cost, credits, logging, audit, alerting, Prometheus, and OpenTelemetry.

For chat completions, handlers limit body size, decode JSON, validate basic model/messages shape, resolve auth/org/workspace metadata, apply org overrides, resolve routing/provider policy, set request timeout, then call the pipeline engine. Non-streaming requests run pre-plugins, the provider call, then post-plugins. Streaming requests run pre-plugins, stream from the provider, apply a stream guardrail checker at intervals and at finalization, then run post-plugins in a background context.

Guardrails flow through `agentcc-gateway/internal/guardrails/engine.go` and `plugin.go`. Rules are split by stage, wrapped with per-rule timeouts and panic recovery, and can run in strict, log-only, or disabled policy modes. Built-ins include PII, moderation, keyword blocklists, input validation, prompt injection, secret detection, topic/language restriction, system prompt protection, hallucination, and data leakage checks. Dynamic guardrails include webhook, expression, Future AGI eval API, tool permission, MCP security, and external vendor adapters. Streaming checks accumulate output text and can stop the stream or append a disclaimer.

Offline evaluation starts at `futureagi/evaluations/engine/runner.py`. `run_eval` resolves an eval class from the registry, prepares type-specific runtime config, runs it, and returns a structured `EvalResult` with value, reason, failure, runtime, model, metrics, metadata, output type, cost, and token usage. Callers own persistence and billing, which keeps the eval core easier to test.

Trace-driven prevention is in `futureagi/tracer/utils/inline_evals.py`, `eval_tasks.py`, `eval.py`, `trace_scanner.py`, and `tasks/error_analysis.py`. Inline evals use transactions and `select_for_update(skip_locked=True)`. Eval tasks compute a drain state so historical evals are not marked complete before dispatched rows finish. Trace scanning samples and deduplicates traces, builds span trees, writes failed scan results to avoid re-scanning loops, and clusters related errors through embeddings. Error analysis records cost and refunds on failure.

LLM-facing platform tools start with `futureagi/ai_tools/base.py`. Each tool parses JSON-ish params, validates with a Pydantic input model, sets user/org/workspace context, and returns a structured `ToolResult`. Validation failures include schema hints and raw params; execution exceptions become typed tool errors instead of uncaught exceptions. `futureagi/mcp_server/mcp_app.py` exposes those tools through FastMCP with OAuth or API-key authentication, rate limiting, usage records, and session counters.

Graph execution is Temporal-backed. `futureagi/tfc/temporal/agent_playground/client.py` creates a `GraphExecution`, then starts `GraphExecutionWorkflow`. The workflow analyzes graph topology, injects inputs, launches ready nodes in parallel up to a concurrency cap, marks nodes skipped when upstream dependencies fail and no default exists, detects deadlocks, recursively runs subgraphs as child workflows, collects valid graph outputs, and finalizes status. Activities call the engine modules in `futureagi/agent_playground/services/engine`: DAG validation, schema-validated data routing, node runner registry, readiness checks, and LLM prompt execution.

## Architecture

The Go gateway is the inline protection plane. It owns request shaping, auth, policy, routing, provider fallback, observability headers, and guardrails. Its plugin engine uses priorities and pre/post phases. Guardrails are a plugin but also have their own rule engine and dynamic policy layer.

The Django app is the control plane and offline quality plane. It stores orgs, workspaces, projects, traces, eval configs, prompt versions, annotations, MCP connections, graph versions, executions, scan results, and error clusters. Temporal handles long-running graph/eval workflows. ClickHouse is used for traces, analytics, and vectors. Redis/cache back rate limiting and transient OAuth/session state.

The frontend is the management UI, not the prevention runtime. The SDKs named in the README (`traceAI`, `futureagi-sdk`, `ai-evaluation`, `agent-opt`, `simulate-sdk`, `agentcc`) are mostly external repos; this review does not treat those README claims as local implementation.

## Design Choices

The gateway puts policy and observability in a plugin chain so the provider call stays small. This makes it easy to add checks, but the priority order becomes security-critical. In this commit, cache priority is before guardrails, tool policy, validation, rate limits, and budgets, so cache hits can bypass checks that should arguably still run.

The guardrail engine defaults to disabled and fail-open. That is pragmatic for a gateway that must avoid accidental outages, but it is not the right default for destructive coding-agent actions. Async guardrails are best-effort and can be dropped when the bounded semaphore is full.

Eval execution centralizes class lookup and result formatting. Runtime overrides are allowlisted in `futureagi/evaluations/engine/instance.py`, which is a good pattern: local config can tune evals without letting arbitrary kwargs leak into every evaluator.

Trace evals emphasize idempotency and delayed correctness. Pending inline evals are locked before processing. Eval tasks check drain progress and missing rows instead of assuming dispatch means completion. This is directly useful for coding-agent postcondition checks that may finish asynchronously.

The MCP and AI tool layer favors typed schemas and structured failures. That helps an LLM recover from bad tool calls. The direct MCP tool-call view checks enabled tool groups per connection, but the streamable FastMCP registration path appears to register all AI tools and does not apply the same `get_enabled_tools(connection)` filter before `tool.run`. That mismatch matters for a tool-rich coding agent.

The graph executor prevents graph-level classes of errors before and during execution: activation validates nodes/ports, graph reference cycles are rejected, runtime DAG cycles are detected, port data is JSON-schema validated, upstream failures propagate to skips, and pending deadlocks are converted to terminal skipped nodes.

## Strengths

- Real inline prevention path: request guardrails, response guardrails, streaming checks, tool policy, model validation, budgets, quotas, cost tracking, and auth all sit on the gateway path.
- Per-org and per-key policy layering: org config, key metadata, request override headers, provider ACLs, and routing overrides are all represented explicitly.
- Strong trace/eval loop: eval tasks, inline evals, trace scanners, monitors, and error clustering form a practical feedback system instead of a dashboard-only story.
- Eval core has a clean contract: `EvalRequest` in, `EvalResult` out, with persistence/cost handled by callers.
- Tool execution is LLM-repairable: schema errors and execution failures are returned as structured tool results.
- Graph execution has concrete safety rails: topology analysis, cycle rejection, valid-data-only routing, skip cascades, deadlock escape, retries, and child workflow isolation.
- Provider availability controls are mature enough to study: retry jitter, failover, circuit breakers, per-model timeouts, provider locks, model fallback chains, and routing metadata.
- PII scrubbing is lazy and fail-open, which protects startup availability when Presidio or spaCy is not installed.

## Weaknesses

- Gateway guardrails are disabled and fail-open by default. That is acceptable for an ops gateway, but too permissive for high-impact coding actions.
- Cache can short-circuit before guardrails, tool policy, validation, rate limits, and budgets. For Agentic Coding Lab, cached outputs should still pass current policy and quota checks.
- Async guardrails are best-effort. If the guardrail semaphore is full, the check is dropped.
- The Future AGI guardrail adapter returns pass when API credentials or eval IDs are missing. Missing policy config becomes silent allow.
- The code-executor service uses nsjail but allows network access and executes raw Python with normal builtins. If nsjail is unavailable, fallback execution is a raw subprocess in `/tmp`. That is not a safe general-purpose coding-agent sandbox.
- The direct MCP API applies enabled-tool filtering, but the streamable FastMCP handler appears broader. Default tool groups also include many platform capabilities.
- Redis/cache unavailability falls back to in-memory state in several places. That weakens rate limits, quotas, and shared enforcement in multi-replica deployments.
- Model validation lets unknown models pass through to the provider, and token checks use rough estimates. This is useful sanity checking, not a hard tokenizer-level gate.
- LLM-as-judge error analysis and scanner output are mostly offline. They should not be treated as inline guarantees unless wired to a blocking gate.
- The repo is very large and explicitly positioned as nightly/early testing, so implementation consistency varies across gateway, backend, MCP, and Temporal surfaces.

## Ideas To Steal

- Use one typed result object for evals, with value, reason, failure, runtime, model, metrics, metadata, cost, and token usage.
- Keep eval execution side-effect-light; let callers own persistence, billing, retries, and idempotency.
- Add an allowlist for per-eval runtime overrides so config can vary without arbitrary evaluator kwargs.
- Record drain state for asynchronous eval batches: dispatched count, completed rows, missing rows, stalled age, and final status.
- Use `select_for_update(skip_locked=True)` for parallel workers processing pending eval rows.
- Store guardrail results in request metadata and surface compact response headers for provider, model, cost, cache, fallback, routing, timeout, and guardrail status.
- Run pre, post, and streaming guardrails. Streaming checks should have interval and final checks, plus an explicit fail action.
- Make tool errors structured and include schema hints so an LLM can repair the next call.
- Layer tool policy globally, per org, and per key; give deny rules precedence and choose between strip, reject, and audit modes.
- Build capped trace/span/session context for evaluator agents instead of passing full traces blindly.
- Separate global provider credentials from org provider credentials; do not let ordinary tenant keys silently fall back to global providers.
- Treat graph execution as a DAG with schema-validated ports, skip cascades, deadlock termination, and child workflow isolation.

## Do Not Copy

- Do not put cache hits before current safety, tool, validation, rate, and budget checks.
- Do not use fail-open as the default for destructive or externally visible coding-agent actions.
- Do not treat nsjail plus network-enabled raw `exec` as a complete sandbox for untrusted agent code.
- Do not expose broad MCP tool groups without enforcing the same allowlist in every transport.
- Do not depend on offline LLM error analysis as the only correctness gate.
- Do not use in-memory fallback counters for safety-critical quotas in multi-worker deployments.
- Do not import the whole platform shape into Agentic Coding Lab; the useful pieces are smaller contracts and execution patterns.
- Do not trust README counts of scanners/adapters without checking which ones are local, external, or configuration-only.

## Fit For Agentic Coding Lab

This is a conditional fit. It is not a coding-agent framework, but it is a strong source of platform patterns for preventing agent errors:

- Inline gate: pre/post/stream guardrails plus tool policy and model validation around every model call.
- Offline gate: traces feed eval tasks, scanners, monitors, and clustered errors.
- Repair loop: structured tool errors and EvalLogger-style records become inputs for future fixes.
- Execution safety: graph dependencies, typed ports, and failure propagation map well to multi-step coding workflows.
- Observability: headers and metadata make each prevention decision inspectable after the fact.

The lab should copy the contracts and ordering discipline, then make defaults stricter: fail-closed for risky actions, policy checks after cache hits, all transports sharing tool allowlists, and sandbox execution that is isolated enough for repository-modifying code.

## Reviewed Paths

- `README.md`: product scope, lifecycle, components, architecture, SDK boundaries, telemetry note.
- `INSTALLATION.md`: runtime stack, code-executor service, gateway role, production config posture.
- `TESTING.md` and sampled test directories: gateway, graph execution, data router, MCP, and guardrail test coverage shape.
- `agentcc-gateway/cmd/agentcc/main.go`: config load, provider setup, plugin chain, guardrail registry, dynamic guardrail factory.
- `agentcc-gateway/config.example.yaml`: guardrail defaults, routing, tool policy, model DB validation, MCP, privacy, and Redis fallback settings.
- `agentcc-gateway/internal/config/config.go`: defaults and policy surface.
- `agentcc-gateway/internal/pipeline/*`: pre/post execution, short-circuiting, cache skip behavior, streaming finalization hooks.
- `agentcc-gateway/internal/server/handlers.go`: chat completion request path, streaming path, org overrides, provider resolution, headers, fallbacks.
- `agentcc-gateway/internal/plugins/auth`, `toolpolicy`, `validation`, `cache`: auth/key policy, tool filtering, model validation, cache behavior.
- `agentcc-gateway/internal/guardrails/*`: engine, plugin, stream checker, built-ins, Future AGI adapter, MCP security, tool permission, external adapters.
- `agentcc-gateway/internal/routing/*`: retry, failover, circuit breaker, model fallback, routing, complexity routing.
- `futureagi/evaluations/engine/*`: eval registry, eval runner, eval instance config preparation.
- `futureagi/agentic_eval/core_evals/fi_utils/*`: sandbox dispatch, code execution fallback, restricted execution.
- `futureagi/code-executor/server.py`: nsjail/raw subprocess execution path.
- `futureagi/tracer/utils/inline_evals.py`, `eval_tasks.py`, `eval.py`, `trace_scanner.py`, `pii_scrubber.py`, `annotation_validation.py`: trace/eval/error prevention utilities.
- `futureagi/tracer/tasks/error_analysis.py`: error analysis cost, refund, failure marking, embedding ingestion.
- `futureagi/tracer/queries/error_clustering.py`, `trace_scanner.py`: scan result persistence and append-only error clustering.
- `futureagi/ai_tools/base.py`, `registry.py`, `views.py`, and representative tools under `futureagi/ai_tools/tools/*`: typed LLM-facing platform tools.
- `futureagi/mcp_server/mcp_app.py`, `views/transport.py`, `usage_helpers.py`, `rate_limiter.py`, `oauth_provider.py`, `oauth_utils.py`, `constants.py`: MCP auth, tool registration, enabled groups, rate limits, usage records, OAuth.
- `futureagi/agent_playground/utils/graph_validation.py`, `services/engine/*`, `services/dataset_bridge.py`: graph validation, DAG analysis, readiness, data routing, LLM prompt runner, dataset execution.
- `futureagi/tfc/temporal/agent_playground/*`: Temporal graph workflow, activities, type contracts, client helpers, e2e workflow tests.

## Excluded Paths

- `frontend/**`: UI-only dashboards and forms; useful for understanding product surface, not core prevention execution.
- `.github/assets/**`, static images, logos, GIFs, and binary media: documentation assets only.
- `**/migrations/**`: schema history; current models, views, and services were reviewed instead.
- Lockfiles and dependency metadata such as `go.sum`, frontend package locks, generated build artifacts, and vendored dependency content: not design-bearing for error prevention.
- Generated protobuf/grpc-style code and similar generated files: contracts are relevant only where called by reviewed service code.
- Exhaustive provider adapters and all external guardrail vendor wrappers: sampled enough to understand adapter shape; central registry/engine behavior is the relevant pattern.
- Full frontend trace/prompt/simulation dashboards and CRUD views: excluded where they only expose existing backend records.
- Exhaustive `futureagi/ai_tools/tools/*` CRUD implementations: reviewed base/registry/MCP and representative tracing/eval/simulation/prompt tools; repeated CRUD patterns were not line-read.
- Enterprise-only imports under `ee.*` that are stubbed or absent in the OSS checkout: noted as boundary, not reviewed as executable local code.
- Deployment and local convenience scripts beyond install/testing/config docs: not part of the agent error-prevention execution path.
