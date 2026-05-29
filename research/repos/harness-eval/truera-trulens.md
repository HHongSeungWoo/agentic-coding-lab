# truera/trulens

- URL: https://github.com/truera/trulens
- Category: harness-eval
- Stars snapshot: 3,350 (GitHub REST API repository search, captured 2026-05-29; confirmed from `research/index.md`)
- Reviewed commit: `5e1a42d2f7a06d6639a760674ed8c0e07c232887`
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: conditional
- Verdict: Strong reference for trace-first LLM app evaluation and observability. It is not a coding-agent harness, but its OTel event model, selector-scoped feedback functions, run metadata, trace compression, and agent/tool evaluators are directly useful for designing coding-agent eval storage and regression workflows.

## Why It Matters

TruLens is one of the more complete open implementations of LLM-app observability as an evaluation harness. The reviewed codebase has moved heavily toward OpenTelemetry spans as the shared substrate for records, feedback computation, agent traces, graph nodes, MCP tools, guardrails, and batch run metadata. That makes it useful for Agentic Coding Lab because coding-agent evaluation has the same core problem: preserve enough execution evidence to score behavior after the fact without coupling every evaluator to every agent implementation.

The project is especially relevant where a lab needs to compare app versions, replay or ingest existing traces, compute LLM-judge and custom metrics, and keep score provenance tied to the exact spans that supplied each metric argument. Its weak fit is that most built-in semantics target RAG, LangGraph, LLM calls, and tool use, not repo diffs, shell commands, test logs, permission boundaries, or patch correctness.

## What It Is

TruLens is a Python monorepo containing `trulens-core`, `trulens-feedback`, dashboard code, framework integrations, provider adapters, OpenTelemetry semantic conventions, and storage connectors. The main public objects are `TruSession`, `TruApp`, framework wrappers such as `TruGraph`, `TruChain`, and `TruLlama`, `RunConfig` and `Run` for batch experiments, `Metric` for feedback definitions, and `Selector` for binding metric arguments to span attributes or trace-level content.

In OTel mode, app calls produce event rows for spans. Record root spans hold input, output, errors, app identity, run name, input id, and optional ground-truth output. Evaluations are emitted as `eval_root` and `eval` spans with metric names, scores, explanations, argument provenance, and cost. Storage can be local SQLAlchemy/SQLite/Postgres or Snowflake event tables, with Snowflake adding server-side run orchestration and metric computation.

## Research Themes

- Token efficiency: Trace compression preserves plans, tool execution evidence, execution flow, agent interactions, and metadata before sending trace-level content to LLM judges. It is not a general context-packing system, but the compression policy is a good model for retaining high-signal evidence for agent evaluation.
- Context control: `Selector` decouples metric definitions from app internals by choosing span type, span name, function name, span attribute, or full trace. The OTel semantic convention gives records stable ids, run names, input ids, span groups, record-root fields, graph/task/tool/MCP fields, and eval provenance.
- Sub-agent/multi-agent: LangGraph instrumentation captures graph nodes, graph tasks, state snapshots, latest messages, and MCP/tool spans. Agentic feedback providers include logical consistency, execution efficiency, plan adherence, plan quality, tool selection, tool calling, and tool quality. The repo observes multi-agent workflows rather than orchestrating them.
- Domain-specific workflow: The strongest built-in domains are RAG, LangGraph, LlamaIndex, LangChain, MCP tools, text-to-SQL style custom metrics, Snowflake AI Observability, and batch app-version comparisons. Coding-agent workflows would need a thin domain adapter.
- Error prevention: Guardrails can block input, block output, or filter retrieval contexts using the same metric abstraction. Batch runs expose statuses such as invocation/computation in progress, completed, partial, failed, and cancelled. Selector validation and metric config tests catch some malformed evaluator definitions.
- Self-learning/memory: The persisted trace, run, dataset, app-version, feedback, and cost history could serve as a learning memory substrate, but the repo does not implement autonomous improvement loops or policy updates.
- Popular skills: There is no skill marketplace. Reusable primitives worth copying are instrumentation wrappers, `Metric` plus `Selector`, trace-level agentic rubrics, trace compression, run metadata, OTel eval spans, and guardrail decorators.

## Core Execution Path

1. `TruSession` enables OTel tracing and configures either the local TruLens exporter or the Snowflake exporter.
2. An app is wrapped with `TruApp` or a framework-specific wrapper. `OtelRecordingContext` adds baggage such as app name/version/id, run name, input id, ground-truth output, and input record count.
3. Decorated or auto-instrumented functions emit spans only inside a TruLens recording context. Span attributes include function kwargs/return/error, record-root input/output, generation/retrieval/tool/MCP details, graph node state, cost, and user-defined attributes.
4. The exporter filters TruLens spans and writes them as `Event` rows through the configured connector, or uploads protobuf batches to a Snowflake stage for ingestion into the account event table.
5. Feedback computation reads events by record or span group. `Selector` objects extract metric arguments from span attributes or full trace trees. `compute_feedback_by_span_group` runs the feedback function, emits `eval_root` and child `eval` spans, and records score, explanation, cost, and argument-to-span provenance.
6. Batch `Run.start()` invokes rows from a dataframe or table, or creates virtual spans in `LOG_INGESTION` mode from an existing dataset. `Run.compute_metrics()` splits server-side Snowflake metric names from client-side `Metric` or `MetricConfig` instances and records computation metadata.

## Architecture

- Core package: app wrappers, sessions, OTel recording contexts, metrics, selectors, run metadata, database models, and connector interfaces.
- Feedback package: LLM providers, judge prompts, agentic evaluators, custom metrics, endpoint pacing, cost tracking, and feedback span computation.
- OTel semantic convention package: shared `ai.observability.*` attribute names for record roots, eval roots, eval steps, calls, retrieval, generation, graph nodes, graph tasks, workflows, agents, tools, MCP calls, rerankers, guardrails, and inline eval controls.
- Framework integrations: LangGraph, LangChain, LlamaIndex, GEPA, and NeMo wrappers map framework-specific execution into common spans.
- Storage boundary: SQLAlchemy stores apps, records, feedback definitions/results, ground truth, datasets, runs, and events locally. Snowflake uses event tables, external-agent objects, staged span ingestion, and Snowflake system functions for run operations.
- UI boundary: Dashboard code reads the normalized event/record/feedback views, but the evaluation data model does not depend on the dashboard.

## Design Choices

- OTel spans are the canonical observation format in the newer path. Legacy records and feedback rows still exist, but OTel mode treats evaluations as spans instead of inserting legacy feedback rows.
- Feedback functions are serializable definitions with optional aggregators, examples, criteria, score ranges, temperature, and trace-compression settings.
- Selectors make evaluation definitions portable across instrumented apps by binding function arguments to semantic span attributes rather than Python object paths.
- Agentic evaluators are trace-level judges with rubrics for plan quality, plan adherence, execution efficiency, logical consistency, and tool behavior.
- Batch runs separate invocation from metric computation and support app-version comparisons through `app_name`, `app_version`, `run_name`, `input_id`, and dataset specs.
- Runtime safety uses the same feedback abstraction for guardrails and inline evaluations, which avoids a separate policy engine but constrains guardrails to numeric feedback outputs.
- Snowflake support is treated as a first-class backend rather than a generic export sink; local OSS mode has simpler run metadata and fewer server-side metric features.

## Strengths

- The OTel data contract is broad enough to represent agent traces, graph execution, tool calls, MCP calls, guardrails, costs, records, and evaluation results in one stream.
- Metric argument provenance is explicit: eval spans can record which source span and attribute supplied each feedback argument.
- The `Run` API provides a useful experiment boundary for regression suites: dataset, app version, invocation status, metric status, concurrency knobs, and log-ingestion mode.
- Trace-level agentic judges are aligned with agent review needs: they score planning, adherence, efficiency, consistency, and tool use rather than only final-answer quality.
- Client-side metrics and custom `MetricConfig` allow deterministic or task-specific evaluators to coexist with provider-backed LLM judges.
- Snowflake and local SQLAlchemy backends show two useful deployment shapes: lightweight local experiments and managed event-table ingestion for production observability.
- Tests cover OTel recording, feedback computation, virtual/log-ingestion runs, custom metrics, guardrails, inline evals, and parallel run settings, and the repo documents known OTel isolation hazards.

## Weaknesses

- The product surface is large for a research harness. Dashboard, Snowflake, legacy compatibility, provider adapters, and framework wrappers make the architecture heavier than most coding-agent labs need.
- The legacy and OTel paths coexist, which creates conceptual overhead around `Record`, `Event`, feedback rows, feedback spans, and dashboard reconstruction.
- Built-in semantics do not cover coding-agent artifacts such as file diffs, patch hunks, shell commands, command exit codes, test logs, sandbox approvals, or repo state.
- Trace-level LLM judges are useful but need calibration against deterministic checks; coding-agent regression should not rely on judge scores alone.
- Local OSS run DAO support is thinner than Snowflake: server-side string metrics are not supported locally, source-table fetch is connector-dependent, and ingestion is simplified.
- OTel export and testing have concurrency sharp edges. The repo notes background span processor races with database reset and relies on process isolation for some OTel tests.
- Some validation is pragmatic rather than strict. For example, dataset spec normalization is more permissive than its comments suggest, and duplicate same-name metrics can be ambiguous in reconstructed views.

## Ideas To Steal

- Represent every coding-agent run as OTel-like spans, with record roots for task input/output and child spans for model calls, file reads/writes, shell commands, tests, tool calls, approvals, and errors.
- Store evaluation results as spans with metric name, score, explanation, higher-is-better, cost, and argument provenance, instead of keeping eval output in a disconnected table.
- Build a selector API over semantic span attributes so metrics can be reused across different agent implementations.
- Keep a `Run` abstraction with dataset, app/agent version, input id, run name, invocation status, metric status, and separate invocation/metric concurrency controls.
- Support log-ingestion mode so externally captured agent runs can be evaluated without replaying them.
- Compress traces for LLM judges by preserving plans, tool execution evidence, error points, and execution flow first.
- Reuse one metric definition for offline evaluation, inline feedback, and guardrails when the metric contract is simple enough.

## Do Not Copy

- Do not copy the full product stack for a coding-agent research harness. Start with the trace/eval/run contract and add UI, Snowflake, and provider breadth only when needed.
- Do not rely on broad LLM-judge rubrics without deterministic checks for build success, tests, diffs, lint, static analysis, and task-specific assertions.
- Do not inherit the dual legacy-plus-OTel model if starting fresh; one event model will be easier to reason about.
- Do not expose generic AI-observability span names alone for coding agents. Add first-class coding spans for repository state, file edits, patch application, command execution, test outcomes, dependency changes, and sandbox decisions.
- Do not accept silent partial evaluation in CI. Agent regression should fail loudly when required traces or metric inputs are missing.
- Do not use background trace export in tests without explicit flush and isolation strategy.

## Fit For Agentic Coding Lab

Fit is conditional but high-value. TruLens should be indexed as an observability and evaluation substrate reference, not as a direct coding-agent benchmark runner. Its best contribution is the combination of OTel-style trace records, selector-bound feedback functions, eval spans with provenance, run metadata, app-version comparison, and trace-level agentic rubrics.

For Agentic Coding Lab, the practical path would be to adapt these ideas into a narrower coding-agent harness: define coding-specific semantic spans, record terminal and filesystem evidence, run deterministic regression checks, then layer LLM judges over compressed traces for qualitative behaviors such as planning, tool choice, and recovery from failed tests.

## Reviewed Paths

- `README.md`
- `pyproject.toml`
- `.azure_pipelines/ci-eval-pr.yaml`
- `.azure_pipelines/templates/run-tests.yaml`
- `Makefile`
- `docs/component_guides/evaluation/agentic_evaluations.md`
- `docs/component_guides/evaluation/feedback_anatomy.md`
- `docs/component_guides/evaluation/batch_evaluation.md`
- `docs/component_guides/evaluation/feedback_selectors/selecting_components.md`
- `docs/component_guides/runtime_evaluation/inline_evals.md`
- `docs/component_guides/runtime_evaluation/guardrails.md`
- `docs/component_guides/instrumentation/index.md`
- `docs/component_guides/instrumentation/langgraph.md`
- `docs/component_guides/instrumentation/mcp.md`
- `docs/component_guides/logging/where_to_log/log_in_postgres.md`
- `docs/component_guides/logging/where_to_log/log_in_snowflake.md`
- `docs/otel/semantic_conventions.md`
- `src/core/trulens/core/app.py`
- `src/core/trulens/apps/app.py`
- `src/core/trulens/core/session.py`
- `src/core/trulens/core/run.py`
- `src/core/trulens/core/dao/run.py`
- `src/core/trulens/core/dao/default_run.py`
- `src/core/trulens/core/metric/metric.py`
- `src/core/trulens/core/feedback/selector.py`
- `src/core/trulens/core/feedback/endpoint.py`
- `src/core/trulens/core/feedback/custom_metric.py`
- `src/core/trulens/core/guardrails/base.py`
- `src/core/trulens/core/otel/instrument.py`
- `src/core/trulens/core/otel/recording.py`
- `src/core/trulens/core/schema/event.py`
- `src/core/trulens/core/schema/record.py`
- `src/core/trulens/core/schema/feedback.py`
- `src/core/trulens/core/database/orm.py`
- `src/core/trulens/core/database/base.py`
- `src/core/trulens/core/database/sqlalchemy.py`
- `src/core/trulens/core/database/connector/base.py`
- `src/core/trulens/core/utils/trace_compression.py`
- `src/core/trulens/core/utils/trace_provider.py`
- `src/core/trulens/experimental/otel_tracing/core/session.py`
- `src/core/trulens/experimental/otel_tracing/core/exporter/connector.py`
- `src/core/trulens/experimental/otel_tracing/core/exporter/utils.py`
- `src/feedback/trulens/feedback/computer.py`
- `src/feedback/trulens/feedback/llm_provider.py`
- `src/feedback/trulens/feedback/templates/agent.py`
- `src/otel/semconv/trulens/otel/semconv/trace.py`
- `src/apps/langgraph/trulens/apps/langgraph/tru_graph.py`
- `src/apps/langgraph/trulens/apps/langgraph/inline_evaluations.py`
- `src/apps/langgraph/trulens/apps/langgraph/trace_provider.py`
- `src/connectors/snowflake/trulens/connectors/snowflake/connector.py`
- `src/connectors/snowflake/trulens/connectors/snowflake/dao/run.py`
- `src/connectors/snowflake/trulens/connectors/snowflake/otel_exporter.py`
- `tests/unit/OTEL_TESTS.md`
- `tests/unit/test_client_side_custom_metrics.py`
- `tests/unit/test_virtual_run.py`
- `tests/unit/test_run_parallel.py`

## Excluded Paths

- Dashboard UI implementation details, except where database reconstruction affects the evaluation model.
- Notebook examples and generated documentation assets.
- Provider-specific endpoint implementations beyond the shared `LLMProvider` behavior and agentic evaluator methods.
- Legacy `trulens_eval` compatibility modules beyond recognizing that they exist as compatibility surface.
- Snowflake Streamlit-in-Snowflake dashboard artifacts and packaging assets.
- Full e2e test suites and optional provider tests that require external credentials.
- Release, build, lock, benchmark, and generated package metadata not needed to understand the harness/eval architecture.
