# comet-ml/opik

- URL: https://github.com/comet-ml/opik
- Category: harness-eval
- Stars snapshot: 19,268 (GitHub API, 2026-05-12)
- Reviewed commit: dd93e82dfa46642ad54fea40128042d2afd1a735
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong reference for LLM evaluation and observability architecture. Steal the trace-linked experiment model, dataset and prompt versioning, online scoring loop, SDK resiliency, and agent step metrics. Do not copy the whole platform unless operating at Opik-like scale.

## Why It Matters

Opik is one of the most complete open-source examples of a production LLM evaluation harness: it joins tracing, datasets, experiments, prompt tracking, online scoring, guardrails, alerts, and dashboards in one loop. For coding agents, the important idea is not the UI; it is the lifecycle. Capture each run as traces and spans, promote failures into datasets, replay them under pinned prompts and metrics, then monitor production attempts with the same score model.

## What It Is

Opik is an Apache-2.0 LLM observability and evaluation platform from Comet. The stack includes a Java Dropwizard backend, ClickHouse analytics storage, MySQL state storage, Redis streams, Python and TypeScript SDKs, a Python evaluator backend, a guardrails backend, frontend, docs, and deployment packaging. It ingests traces through SDKs, REST, and OpenTelemetry, supports offline and online evaluation, and integrates with agent and LLM frameworks such as LangChain, LangGraph, OpenAI Agents, ADK, LiteLLM, Vercel AI SDK, and OpenTelemetry.

## Research Themes

- Token efficiency: Opik has several context-control mechanisms rather than one global token optimizer. Trace reads support slim/truncated fields, online LLM scoring compresses large traces into full/medium/skeleton summaries, the test-suite judge path caps prompt fields and exposes read/jq/search tools, and dataset compression sends metadata plus samples with drill-down hints. SDK batching and offline replay reduce observability overhead.
- Context control: The core model is trace, span, and thread, scoped by project. Datasets have immutable version records and latest tags, prompts have commit-like version IDs, experiments store dataset and prompt version links, and online scoring rules use OQL filters plus explicit variable mappings from JSONPath or literals.
- Sub-agent / multi-agent: Opik is not a multi-agent orchestrator, but it models agent work well through nested spans, thread IDs, graph metadata, trajectory metrics, tool-correctness metrics, and integrations with agent frameworks. A coding-agent harness can map planner, editor, shell, test, and review steps to spans.
- Domain-specific workflow: The intended loop is observability first, then trace-to-dataset curation, offline experiments, prompt comparison, online scoring, human or automatic feedback, alerts, and dashboards. PyTest integration and MCP-oriented docs make the same loop available inside developer workflows.
- Error prevention: Prevention surfaces include offline eval gates, `llm_unit` tests, LLM-as-judge and heuristic metrics, guardrails, anonymizers, feedback score monitoring, alerts, permission/rate/usage limits, and SDK offline fallback. The platform emphasizes catching regressions through repeated scored traces.
- Self-learning / memory: Opik is not an autonomous memory system. It provides the substrate for human-in-the-loop improvement: production traces become datasets, scored datasets guide prompt changes, and prompt versions/experiments record what improved.
- Popular skills: Useful patterns include `@track` decorators, trace/span/thread IDs, dataset snapshots, prompt commits, custom `BaseMetric` scoring, `task_span` metrics, OQL search, guardrail spans, online scoring rules, and feedback score provenance.

## Core Execution Path

1. An application or agent emits traces, spans, threads, prompt links, and feedback through the Python SDK, TypeScript SDK, REST API, or OpenTelemetry. The SDK batches messages, applies configured anonymizers, and can store failed messages in local SQLite for later replay.
2. The backend authenticates and rate-limits the request, resolves or creates the project, strips attachments for separate handling, writes analytics records to ClickHouse and state records to MySQL, then emits creation or update events.
3. Datasets are created from SDK calls, CSV, UI flows, traces, or spans. Dataset item services can enrich items with nested spans, tags, usage, metadata, comments, and feedback. Versioning records snapshots and latest tags; the Python SDK dedupes inserted items by content hash.
4. `evaluate()` creates an experiment linked to a dataset version and prompt versions, runs the task for each item and trial under tracing, records task output, computes metrics, logs feedback scores to traces, writes experiment items, and computes experiment-level aggregates.
5. Online scoring listens for completed trace, span, or thread events, filters them by rule OQL and sampling rate, enqueues Redis stream messages, renders judge prompts or calls Python metric code, parses structured score output, and stores feedback scores.
6. Monitoring and alerts read the same trace, span, thread, cost, latency, error, and feedback score data. Guardrails can validate inputs or outputs and log auditable guardrail spans; anonymizers can redact data before storage.

## Architecture

The backend is a Dropwizard service assembled with Guice modules for auth, rate limits, Redis, LLM providers, datasets, experiments, prompts, jobs, alerts, and scoring. It uses MySQL for stateful resources such as projects, prompt versions, dataset versions, and feedback definitions, while ClickHouse stores high-volume traces, spans, experiment items, feedback scores, usage, and aggregates. Redis streams carry asynchronous online scoring work.

The Python SDK owns most local developer ergonomics: decorators, nested trace context, dataset and prompt APIs, evaluation engines, metrics, integrations, anonymizers, guardrails, batching, and offline replay. The TypeScript SDK mirrors the key tracing, prompt, dataset, and evaluation APIs. A separate Python evaluator backend executes user-defined metric code either in local processes or Docker sandboxes. The guardrails backend runs PII and topic validation services. The frontend is useful operationally, but the harness architecture is mostly in SDKs, backend resources, services, and storage models.

## Design Choices

Opik makes traces the primitive unit. Experiment items link to traces, dataset items can be created from traces or spans, online scores attach to traces/spans/threads, and custom metrics can inspect the recorded task span. Feedback scores are first-class records with source and author information, allowing SDK, UI, and online scoring results to coexist.

Reproducibility is handled through dataset version IDs, prompt version IDs, experiment config, and trace links. Prompt versions are immutable for template content and receive short commit IDs derived from UUIDv7 version IDs. Dataset versions support latest tags and immutable snapshots, though the backend still has a backwards-compatible path that mutates latest when no batch group is supplied.

Online scoring is event driven. Samplers only score completed SDK-origin traces by default, apply enabled rules, OQL filters, selected rule IDs, and sampling rates, then enqueue LLM-as-judge or Python metric jobs. The scorer stores results back as feedback scores, which makes offline metrics, online rules, human annotations, and dashboards share one scoring surface.

Security and reliability are explicit design concerns. The SDK has batching, flush, rate-limit handling, offline SQLite replay, and anonymizer hooks. The backend has auth, permissions, usage limits, workspace/project scoping, and sanitized scorer logs. The Docker evaluator disables network by default, runs as a non-root user, removes pip tooling, sets resource limits, and enforces timeouts. The default process executor is operationally simpler but is a weaker isolation boundary.

## Strengths

- Unified trace, dataset, prompt, experiment, metric, monitoring, and alert loop.
- Strong reproducibility through dataset versions, prompt versions, experiment config, and trace-linked experiment items.
- Agent-specific support through `task_span` metrics, tool correctness, trajectory accuracy, conversation/thread evaluation, graph logging, and agent framework integrations.
- Flexible scoring: heuristic metrics, LLM-as-judge metrics, custom Python metrics, experiment-level metrics, and conversation metrics.
- Production-grade plumbing: ClickHouse storage, Redis scoring queues, rate and usage limits, alerts, SDK batching, and offline replay.
- Good safety surfaces: anonymizers, guardrails, feedback score provenance, and a Docker sandbox option for custom metric code.
- Developer workflow hooks through PyTest `llm_unit`, MCP-oriented prompt/trace docs, and OpenTelemetry ingestion.

## Weaknesses

- The platform is large and expensive to transplant into a smaller research harness.
- Dual databases, Redis streams, evaluator service, guardrails service, frontend, and deployment stack add significant operational complexity.
- LLM-as-judge quality depends on prompt design, provider behavior, variable mapping, and structured-output parsing.
- Online scoring is asynchronous and sampled; incomplete traces are skipped, and thread scoring has cooldown/delay semantics.
- Dataset version behavior has a compatibility path that can mutate latest, which is risky for strict reproducibility unless clients consistently use versioned batch groups.
- The process-based Python metric executor is weaker isolation than Docker and should not be used for untrusted code.
- Guardrails are useful but limited by model constraints, token limits, language support, latency, and separate service operation.
- ClickHouse ReplacingMergeTree dedupe and aggregate table behavior is powerful but can surprise small systems that expect immediate row-level consistency.

## Ideas To Steal

- Treat every agent attempt as a trace, every tool call or reasoning step as a span, and every long conversation as a thread.
- Link each evaluation item to the trace produced by the task run, then allow metrics to inspect the recorded task span.
- Store dataset version ID, prompt version IDs, model settings, and metric config on every experiment.
- Use one feedback score model across SDK logs, online scoring, manual review, and experiment results.
- Let production traces and spans become dataset items with optional nested spans, tags, feedback, comments, usage, and metadata.
- Implement online scoring rules as filter plus sampling plus variable mapping plus structured score schema.
- Add manual reruns of online rules over historical traces and threads.
- Keep a local SQLite replay queue in SDKs so observability failures do not lose evaluation data.
- Compress large traces for judges with full/medium/skeleton tiers and optional drill-down tools.
- Turn coding-agent PyTest or integration tests into trace-linked experiments.
- Redact before storage with anonymizer hooks and log guardrail checks as spans.

## Do Not Copy

- Do not copy the whole platform if a local file-based or SQLite-backed harness will satisfy the research loop.
- Do not adopt ClickHouse, Redis streams, and dual storage before the volume requires them.
- Do not keep mutable latest dataset behavior if the goal is strict eval reproducibility.
- Do not execute arbitrary Python metric code without Docker-like isolation, disabled network, resource limits, and timeouts.
- Do not trust LLM-as-judge scores without calibration datasets, golden tests, and failure handling for malformed output.
- Do not force coding-agent users through UI-only workflows when CLI, file, and IDE artifacts are better feedback surfaces.
- Do not silently treat missing or unparsable judge scores as acceptable in regression gates.

## Fit For Agentic Coding Lab

Opik is highly applicable as a reference architecture, not as a dependency to embed wholesale. The best fit is a smaller trace-first harness: record one coding-agent task as a trace, model shell commands, file edits, tests, planning, and review as spans, promote failures into versioned datasets, pin prompts and tool policies by version, run offline metrics over traces, and use online or manual scoring for production attempts.

The most useful borrowed pieces are trace-linked experiments, `task_span`-style metric access, prompt/dataset version pins, feedback score provenance, and production-to-dataset curation. This directly supports verification loops for coding agents: failing runs can become regression items, scoring can inspect whether the agent used tools correctly, and prompt or policy changes can be compared against the same dataset.

## Reviewed Paths

- `README.md` and repository metadata for scope, license, integrations, and product claims.
- `apps/opik-documentation/documentation/fern/docs/**` and `apps/opik-documentation/documentation/fern/docs-v2/**` for tracing, datasets, experiments, prompt library, prompt playground, metrics, online scoring, alerts, monitoring, guardrails, anonymizers, PyTest, MCP, and agent evaluation workflows.
- `apps/opik-backend/src/main/java/com/comet/opik/OpikApplication.java` and `OpikConfiguration.java` for service composition and runtime configuration.
- `apps/opik-backend/src/main/java/com/comet/opik/api/resources/v1/priv/TracesResource.java`, `SpansResource.java`, `DatasetsResource.java`, `ExperimentsResource.java`, and `PromptResource.java` for API shape.
- `apps/opik-backend/src/main/java/com/comet/opik/domain/TraceService.java`, `SpanService.java`, dataset services, experiment services, prompt services, online scoring services, compressors, and DAOs for actual ingestion, storage, scoring, and version behavior.
- Relevant `apps/opik-backend/src/main/resources/liquibase/**` migrations for traces, spans, feedback scores, dataset items, dataset versions, experiments, experiment items, guardrails, prompts, and prompt versions.
- `apps/opik-python-backend/src/opik_backend/evaluator.py`, executor implementations, process worker, Docker executor, and related tests for custom Python metric execution.
- `apps/opik-sandbox-executor-python/Dockerfile`, `scoring_runner.py`, and requirements for sandbox behavior.
- `apps/opik-guardrails-backend/opik_guardrails/**` validation engine, routes, schemas, PII validator, topic validator, and tests for guardrail flow.
- `sdks/python/src/opik/**` tracing decorators, context, message processing, batching, replay, datasets, prompts, evaluation engine, metrics, thread evaluation, guardrails, anonymizers, PyTest plugin, and integrations.
- `sdks/python/tests/**` for tracing, datasets, experiments, evaluation, `task_span`, scoring functions, failed message replay, anonymization, guardrails, prompt tests, PyTest integration, and framework integrations.
- `sdks/typescript/src/opik/**` client, batch queue, prompt, dataset, evaluation, and metric code sampled for parity with the Python SDK.
- `sdks/typescript/tests/**`, `tests_end_to_end/**`, and `tests_load/**` sampled for coverage signals and workflow confidence.

## Excluded Paths

- `apps/opik-frontend/**`: UI implementation excluded except behavior inferred from docs and E2E names; the review target is harness/eval architecture rather than React UI code.
- `apps/opik-documentation/documentation/static/**`, screenshots, images, and `readme-thumbnail-new.png`: static or binary documentation assets.
- Localized `readme_*.md` files: translations of the canonical README, not separate architecture.
- `sdks/code_generation/fern/**` and generated REST clients such as `sdks/python/src/opik/rest_api/**` and `sdks/typescript/src/opik/rest_api/**`: generated API plumbing; reviewed behavior through resources, services, and SDK call sites instead.
- `deployment/**`: Helm, Docker Compose, Terraform, and packaging were noted for self-host shape but not deeply reviewed because they are not core tracing/evaluation logic.
- `scripts/**`, CI, build, release, and formatting utilities: operational glue outside the requested architecture focus.
- `extensions/**`: IDE plugin and MCP implementation mostly excluded; MCP docs were reviewed for the user-facing coding-agent workflow idea.
- Most Liquibase history outside the specific trace, span, feedback, dataset, experiment, guardrail, and prompt tables: unrelated schema churn was not needed.
- Demo data, notebooks, cookbooks, and examples: tutorial-level duplication of docs and SDK behavior.
- UI-only Playwright page objects and full load-test internals: useful for confidence but not necessary to understand eval/tracing design.
- Vendor, cache, binary, generated, or compiled artifacts such as `node_modules`, `.pyc`, images, screenshots, and build outputs if present.
