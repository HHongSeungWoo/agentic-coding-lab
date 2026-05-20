# raga-ai-hub/RagaAI-Catalyst

- URL: https://github.com/raga-ai-hub/RagaAI-Catalyst
- Category: subagents-multiagents
- Stars snapshot: 16,163 (GitHub REST API, captured 2026-05-20)
- Reviewed commit: ab67893310891140211280a496402003e52cdab5
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: conditional
- Verdict: Strong observability/evaluation pattern source for multi-agent workflows, especially trace/span/metric schemas and timeline generation. Do not adopt wholesale: runtime is tightly coupled to the RagaAI hosted backend, uses global monkey patching, captures sensitive payloads by default, and has weak local governance semantics.

## Why It Matters

RagaAI Catalyst is not a subagent orchestration framework. It is a tracing, evaluation, prompt, dataset, guardrail, and upload SDK around agentic applications. That makes it useful for Agentic Coding Lab as a governance substrate candidate: it shows how to normalize heterogeneous agent runs into agent, LLM, tool, network, file, and user-interaction spans; attach local and model-executed metrics; preserve source-code provenance; and render a chronological workflow timeline.

For subagent governance, the valuable part is the observability contract. A coding-agent system could borrow the component tree, workflow event stream, metric hooks, ground-truth/context attachments, and upload/status ideas without copying the hosted-platform dependency or broad monkey patches.

## What It Is

RagaAI Catalyst is a Python SDK for LLM project management and agent observability. The public API exports `RagaAICatalyst`, `Tracer`, `init_tracing`, `trace_agent`, `trace_llm`, `trace_tool`, `trace_custom`, `current_span`, `Evaluation`, `PromptManager`, `GuardrailsManager`, `GuardExecutor`, and red-teaming helpers.

Its agentic tracing stack has two paths:

- Explicit decorators for custom code: `@trace_agent`, `@trace_tool`, `@trace_llm`, and `current_span()` route through a global tracer and context variables.
- Framework auto-instrumentation: `Tracer(tracer_type="agentic/<framework>")` configures OpenInference/OpenTelemetry instrumentors for LangGraph, LangChain, CrewAI, LlamaIndex, Haystack, Smolagents, OpenAI Agents, AutoGen, and provider-level LLM calls.

The SDK writes trace JSON, source-code zip hashes, metrics, and workflow interactions locally first, then submits uploads to a background future-based uploader.

## Research Themes

- Token efficiency: Tracks LLM token usage and cost per span plus aggregate trace metadata. It does not optimize prompt/context size or budget future calls.
- Context control: Supports `current_span().add_context(...)`, `add_gt(...)`, prompt templates, and prompt-version retrieval. Context is recorded for audit/eval, not actively selected or compressed.
- Sub-agent / multi-agent: Agent spans can contain nested agent, tool, LLM, and custom children. Framework examples cover LangGraph state machines, CrewAI sequential crews, Smolagents tool agents, and a custom travel-agent hierarchy.
- Domain-specific workflow: Strong platform workflow around projects, datasets, metrics, prompt management, guardrails, synthetic data, and red-teaming. Useful as a model for attaching eval artifacts to traces.
- Error prevention: Captures exceptions as span `error` objects, can run metric evaluations and guardrails, and records job status. It mostly observes failures after they happen; it does not enforce tool permissions or task-state transitions.
- Self-learning / memory: No reusable agent memory layer. Durable learning is platform-side via datasets, prompt versions, traces, and metric results.
- Popular skills: Trace schema design, OpenTelemetry conversion, explicit decorators, `current_span` metric/ground-truth/context API, workflow timeline extraction, code provenance hashing, masking post-processors, and guardrail input/output checks.

## Core Execution Path

1. User creates `RagaAICatalyst` credentials and a `Tracer(project_name, dataset_name, tracer_type=...)`. The tracer constructor calls the RagaAI API to validate project and dataset, then stores project id, trace metadata, pipeline metadata, upload timeout, and auto-instrumentation flags.
2. For `agentic/<framework>` tracer types, `Tracer._setup_agentic_tracer` builds a `DynamicTraceExporter`, creates an OpenTelemetry provider, registers a simple span processor, and instruments the selected OpenInference packages.
3. `RAGATraceExporter` buffers exported OpenTelemetry spans by trace id. When the root span or shutdown arrives, it converts spans with `trace_json_converter.convert_json_format`, builds nested agent/tool/LLM/custom spans, computes token/cost metadata, formats a `workflow` event list, adds system/resource info and source-code hash, writes JSON to `/tmp`, and submits an upload task.
4. For explicit decorators, `init_tracing(catalyst, tracer)` stores a process-global tracer. `trace_agent`, `trace_tool`, and `trace_llm` set context variables and call mixin methods that execute user functions, capture start/end time, input/output, memory, errors, parent id, child spans, metrics, interactions, and network calls.
5. `BaseTracer.stop()` stops resource tracking, rewrites span ids, fills agent input/output from children, deduplicates spans, extracts aggregate cost/tokens, formats workflow interactions, writes trace JSON, runs an optional post-processor/masking function, and submits upload work.
6. Upload processing creates/updates trace dataset schema, uploads trace metrics, uploads trace JSON to a presigned URL, inserts trace metadata, and uploads the zipped source hash.

## Architecture

The tracer facade is `ragaai_catalyst.tracers.tracer.Tracer`, which subclasses `AgenticTracing`. `AgenticTracing` combines `BaseTracer`, `LLMTracerMixin`, `ToolTracerMixin`, `AgentTracerMixin`, and `CustomTracerMixin`, plus `NetworkTracer` and `UserInteractionTracer`.

The manual tracing data model is component-based. A component has `id`, `hash_id`, `source_hash_id`, `type`, `name`, `start_time`, `end_time`, `parent_id`, `info`, `data`, `metrics`, `feedback`, `network_calls`, `interactions`, and `error`. Specialized components exist for LLM, agent, and tool spans, but they share the same base shape.

Task ownership is held in context variables: current agent id/name, current tool name/id, current LLM call name, current component id, and agent children. Nested calls append child components to the active agent. Root components are stored in `self.components`.

The OpenTelemetry path is separated through `DynamicTraceExporter` and `RAGATraceExporter`. That path consumes OpenInference span attributes like `openinference.span.kind`, `input.value`, `output.value`, `llm.model_name`, invocation parameters, and token counts, then maps them into the same RagaAI component schema.

The evaluation layer is separate from tracing. `Evaluation.add_metrics` validates metric names, schema mappings, target columns, provider/model config, and starts backend metric-evaluation jobs. `BaseTracer.add_metrics` handles trace-level user scores. `SpanAttributes.execute_metrics` stores local metric execution requests, and `BaseTracer.get_formatted_metric` calls `calculate_metric` during component creation.

Guardrails are also separate. `GuardExecutor` runs input guardrails, stores a current guardrail execution id as `current_trace_id`, calls an LLM, then runs output guardrails with the response. This is a useful input/output gate pattern, but it is not integrated as a first-class tracing span or permission engine.

## Design Choices

- Uses a small normalized vocabulary: `agent`, `llm`, `tool`, and `custom` spans.
- Keeps both tree and timeline views: parent/child span hierarchy plus chronological `workflow` events such as `agent_call_start`, `llm_call_end`, `tool_call_start`, `network_call`, `file_read`, and `file_write`.
- Supports both framework-level instrumentation and explicit decorators so custom agents can be traced without depending on a framework.
- Treats metrics as span/trace attachments rather than a separate afterthought. Metrics may be user-provided scores or server-executed evaluations with model/provider/mapping config.
- Records source-code provenance by tracking files, zipping unique source files, and storing a code hash in trace metadata.
- Uses optional post-processing for masking before upload, but capture happens before masking.
- Upload is asynchronous and status-addressable, but it is not a durable local event log.

## Strengths

- Good multi-agent trace schema. Agent spans can own nested agents, tools, LLM calls, errors, metrics, context, ground truth, interactions, and network calls.
- Broad adapter coverage through OpenInference instrumentors plus manual decorators for custom code.
- `current_span()` gives a simple API for subagent-local metrics, ground truth, and context annotations.
- Workflow timeline extraction is directly reusable for audit views: it turns nested execution into ordered start/end events with error fields.
- Cost, token, memory, CPU, disk, and network metadata create useful governance signals for budgets and runaway-agent detection.
- Source-code hash and zip upload pattern gives trace-to-code provenance, useful for reproducing agent behavior.
- Guardrail executor shows a pragmatic pattern for linking input checks, LLM execution, output checks, alternate responses, and guardrail execution ids.

## Weaknesses

- Hosted-backend coupling is deep. `Tracer` and `Evaluation` constructors validate projects/datasets over the RagaAI API and require `RAGAAI_CATALYST_TOKEN`, so local/offline governance is not first-class.
- Global monkey patches are broad. The tracer replaces `builtins.print`, `builtins.input`, `builtins.open`, `requests.Session.request`, `urllib`, `http.client`, and `socket.create_connection`. That is risky in multi-agent coding runs where unrelated libraries may be active.
- Privacy defaults are unsafe for coding-agent governance. Network request/response headers and bodies, file contents, prompts, and model outputs can be captured before optional masking.
- Span attributes are keyed by span name rather than a stable span instance id. Concurrent or repeated subagents with the same name can collide or consume each other's metrics/context before reset.
- Manual `trace_llm` decorator depends on `self.llm_data` populated by inner LLM instrumentation and adds components in `finally`, which can duplicate or stale-link spans when no inner auto-instrumented LLM call occurs.
- Upload status is optimistic. `process_upload` logs schema, metrics, trace, and code upload errors but continues and marks the task completed unless an outer exception escapes.
- Error objects are captured and exceptions are re-raised, but there is no structured retry policy, task-state transition model, permission denial type, or governance decision record.
- Trace IDs are fragmented across systems: guardrail `current_trace_id`, OpenTelemetry trace id, RagaAI trace id, and component ids are not unified into one local control-plane identity.

## Ideas To Steal

- Use a normalized span schema for `agent`, `llm`, `tool`, and `custom` with `parent_id`, `children`, `metrics`, `error`, `network_calls`, `interactions`, `context`, and `gt`.
- Generate both nested execution trees and chronological workflow events. Governance needs both: tree for ownership, timeline for audits.
- Give every subagent/tool a `current_span()`-style handle for adding metric scores, eval mappings, ground truth, context, tags, and feedback.
- Attach token, cost, duration, memory, and network summaries to spans and aggregate them at trace level for budget enforcement.
- Add code provenance to traces through a source-file tracker and code hash, but make file inclusion explicit and reviewable.
- Keep framework adapters separate from the trace schema. OpenInference-style adapters can feed a common internal event model.
- Provide a masking/post-processing hook, then make it mandatory and pre-capture for sensitive coding-agent environments.
- Model guardrails as input and output checks with alternate responses, but integrate them into the same trace and task-state model.

## Do Not Copy

- Do not globally monkey patch builtins and network libraries as a default tracing strategy.
- Do not capture raw file contents, HTTP bodies, headers, prompts, and responses before policy-based redaction.
- Do not require a hosted backend to create a tracer, validate a dataset, or inspect a local trace.
- Do not key active span annotations only by human-readable names.
- Do not mark asynchronous upload work as completed when required substeps logged errors.
- Do not use tracing as the only governance layer. Observation needs explicit task state, tool policy, permission checks, and enforcement outcomes.
- Do not copy the manual `trace_llm` pattern that relies on shared `self.llm_data` side effects.

## Fit For Agentic Coding Lab

Conditional fit as an observability and evaluation pattern source. The best reusable ideas are the component schema, workflow timeline, span-local metric/context/ground-truth API, source provenance, and evaluator attachment points.

For Agentic Coding Lab, the adapted version should be local-first and policy-aware:

- stable trace id, run id, task id, subagent id, tool-call id, and parent-child ids;
- explicit task states such as `planned`, `running`, `blocked`, `needs_approval`, `failed`, `verified`, and `completed`;
- tool boundary records with requested tool, allowed/denied decision, reason, input hash, output hash, and redacted preview;
- pre-capture redaction and allowlisted file/network capture;
- local JSONL or SQLite event log before optional export;
- eval hooks that can run offline checks and attach scores to spans;
- upload/export status that fails closed when required governance artifacts are missing.

RagaAI Catalyst is valuable for showing what rich agent observability can look like, but its runtime assumptions are better suited to a managed LLM observability platform than to a strict coding-agent governance harness.

## Reviewed Paths

- `README.md`
- `Quickstart.md`
- `docs/agentic_tracing.md`
- `docs/trace_management.md`
- `docs/prompt_management.md`
- `ragaai_catalyst/__init__.py`
- `ragaai_catalyst/tracers/__init__.py`
- `ragaai_catalyst/tracers/tracer.py`
- `ragaai_catalyst/tracers/distributed.py`
- `ragaai_catalyst/tracers/agentic_tracing/README.md`
- `ragaai_catalyst/tracers/agentic_tracing/data/data_structure.py`
- `ragaai_catalyst/tracers/agentic_tracing/tracers/base.py`
- `ragaai_catalyst/tracers/agentic_tracing/tracers/main_tracer.py`
- `ragaai_catalyst/tracers/agentic_tracing/tracers/agent_tracer.py`
- `ragaai_catalyst/tracers/agentic_tracing/tracers/tool_tracer.py`
- `ragaai_catalyst/tracers/agentic_tracing/tracers/llm_tracer.py`
- `ragaai_catalyst/tracers/agentic_tracing/tracers/network_tracer.py`
- `ragaai_catalyst/tracers/agentic_tracing/tracers/user_interaction_tracer.py`
- `ragaai_catalyst/tracers/agentic_tracing/utils/span_attributes.py`
- `ragaai_catalyst/tracers/agentic_tracing/utils/trace_utils.py`
- `ragaai_catalyst/tracers/agentic_tracing/upload/trace_uploader.py`
- `ragaai_catalyst/tracers/agentic_tracing/upload/upload_agentic_traces.py`
- `ragaai_catalyst/tracers/exporters/dynamic_trace_exporter.py`
- `ragaai_catalyst/tracers/exporters/ragaai_trace_exporter.py`
- `ragaai_catalyst/tracers/utils/trace_json_converter.py`
- `ragaai_catalyst/evaluation.py`
- `ragaai_catalyst/guard_executor.py`
- `examples/custom_agents/travel_agent/main.py`
- `examples/custom_agents/travel_agent/agents.py`
- `examples/custom_agents/travel_agent/tools.py`
- `examples/langgraph/personal_research_assistant/research_assistant.py`
- `examples/crewai/scifi_writer/scifi_writer.py`
- `examples/smolagents/most_upvoted_paper/most_upvoted_paper.py`
- `tests/test_catalyst/test_base_tracer_add_metrics.py`
- `tests/test_catalyst/test_base_tracer_metrics.py`
- `tests/examples/test_utils/get_trace_data.py`
- `tests/examples/test_utils/get_components.py`

## Excluded Paths

- `docs/img/**`: documentation screenshots/GIFs; UI-only assets.
- `examples/**/data/**`, `tests/**/data/**`, `*.pdf`, `*.png`: sample datasets, binary docs, and screenshots; not execution-path source.
- `ragaai_catalyst/tracers/agentic_tracing/tests/*.ipynb` and `ragaai_catalyst/redteaming/tests/*.ipynb`: notebooks excluded as interactive/generated review artifacts.
- `ragaai_catalyst/tracers/agentic_tracing/utils/model_costs.json` and `ragaai_catalyst/tracers/utils/model_prices_and_context_window_backup.json`: large static model-pricing data; reviewed only as dependency signal, not line-by-line.
- `test_report_20250407_183101.txt`, `tests/table_result.png`: generated test/report artifacts.
- `.github/**`, packaging metadata beyond `pyproject.toml`, and unrelated issue templates/workflows: not relevant to agent observability/evaluation design.
