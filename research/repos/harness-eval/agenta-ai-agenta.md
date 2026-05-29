# Agenta-AI/agenta

- URL: https://github.com/Agenta-AI/agenta
- Category: harness-eval
- Stars snapshot: 4,163 (GitHub REST API repository search, captured 2026-05-29; from `research/index.md`)
- Reviewed commit: 6c46b8edf931f58751a98eb47abce5a661eeb654
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: conditional
- Verdict: Strong LLMOps reference for eval runs, prompt/config versioning, trace-backed datasets, online evaluation, and human/auto annotation queues. It is conditional for Agentic Coding Lab because it is a full application platform rather than a lightweight coding-agent harness; the reusable value is in the entity model, run graph, trace links, dataset flow, and worker/queue mechanics.

## Why It Matters

Agenta shows a mature closed loop around LLM application quality: prompt/config revisions feed applications, applications emit traces, traces can seed testsets or online evaluations, evaluators produce linked annotation results, and metrics/queues make the loop reviewable. That shape is directly relevant to agentic coding systems, where regressions usually come from changes in prompts, tool policies, context selection, model settings, or evaluator criteria.

The repo is not a SWE-bench-style coding harness. Its value is as an operational reference for building a durable eval substrate: versioned prompts/configs, testset revisioning, trace-linked evaluator outputs, production sampling, SDK-driven CI evaluation, and human review queues.

## What It Is

Agenta is an open-source LLMOps platform with a Python/FastAPI backend, web app, Python SDK, worker processes, OpenTelemetry ingestion, prompt/config management, evaluation workflows, and self-hosting assets. The main backend stores workflows as application/evaluator artifacts with variants and revisions, deploys revisions into environments, ingests spans, queries traces, and runs batch or live evaluations.

For evaluation, users can create testsets, define applications and evaluators, run evaluations through the UI/API or Python SDK, evaluate production traces continuously, and route items into human annotation queues. Evaluators can be built in, LLM-as-judge, custom code, webhook-backed, or human/manual depending on origin and workflow type.

## Research Themes

- Token efficiency: Conditional. Agenta captures token usage, costs, latency, cached-token fields, and supports trace sampling/rate filtering, but it does not provide a context compression or token-budgeting strategy for coding agents.
- Context control: Strong. The artifact/variant/revision/environment model versions prompts and arbitrary config, while evaluation run steps record references and mappings between inputs, invocations, and annotations.
- Sub-agent / multi-agent: Indirect. Traces can represent tool and agent workflows, and docs list integrations such as LangGraph, OpenAI Agents, PydanticAI, DSPy, Agno, and LlamaIndex, but there is no native multi-agent scheduler or coding-agent planner.
- Domain-specific workflow: Strong for LLMOps. It has purpose-built flows for prompt engineering, testsets, batch eval, online eval, human review, trace analytics, and config deployment/rollback.
- Error prevention: Strong for prompt/application regressions. Testsets, SDK evaluation, online evaluation, metrics, and queues provide repeatable checks, though CI failure thresholds are left to the caller.
- Self-learning / memory: Conditional. Production traces, annotations, and feedback can be promoted into testsets or evaluator inputs, but the repo does not implement autonomous memory update policy or self-improving agent behavior.
- Popular skills: No skill marketplace. Reusable primitives include `aevaluate`, `SimpleEvaluationsService`, `SimpleQueuesService`, `TracingService`, `WorkflowsService`, environment deployment, and SDK tracing decorators.

## Core Execution Path

The SDK path starts in `sdks/python/agenta/sdk/evaluations/preview/evaluate.py`. `aevaluate()` parses inline or referenced testsets, applications, and evaluators; upserts needed entities; creates an evaluation run; iterates testcases; logs testset inputs; invokes the application through the local SDK runtime; polls for the invocation trace; invokes each evaluator with testcase inputs, outputs, and trace data; logs evaluator results; refreshes scenario/run metrics; closes the run; and prints the Agenta URL.

The backend batch path starts with the FastAPI evaluation routes, then `SimpleEvaluationsService.create()` builds an `EvaluationRun` from simple evaluation specs. `_make_evaluation_run_data()` resolves query, testset, application, and evaluator revisions into explicit run steps and mappings. `start()` activates the run and dispatches the correct Taskiq worker based on topology: testset plus application plus evaluators, invocation-only runs, query-based runs, or live online evaluation.

The legacy batch worker path in `api/oss/src/core/evaluations/tasks/legacy.py` creates scenarios per testcase, logs input results, invokes the application service, fetches invocation traces, links evaluator results to invocation traces, skips human/custom evaluator steps as pending, supports cached/split/repeated runs, computes metrics, and finishes the run as success, errors, running, failure, or cancelled.

The online evaluation path in `api/oss/src/core/evaluations/tasks/live.py` queries traces using a stored query revision, time window, and rate sampling, then runs auto evaluators against trace root spans. This is the production-monitoring path: traces become the evaluation source rather than a static testset.

The trace ingestion path accepts OTLP binary protobuf spans through the API, converts them to internal span DTOs, infers trace/span types and metrics, publishes them into a Redis stream, consumes them in the asyncio tracing worker, and upserts spans into Postgres. Query and analytics APIs then power dashboards, online eval, queues, and SDK evaluation trace lookup.

## Architecture

The OSS backend under `api/oss` is organized around FastAPI routers, core services, Postgres DAOs, Taskiq evaluation workers, and an asyncio tracing stream worker. Evaluation state is represented by run/scenario/result/metric DTOs plus JSON run data containing steps, mappings, repeats, and references.

Prompt and config management are built on a generic workflow layer. Applications and evaluators wrap workflows; workflows have artifacts, variants, and revisions; environments are revisioned reference maps used to deploy or roll back a specific application revision. The same revision machinery handles prompt templates, model config, evaluator definitions, and service URI metadata.

Testsets are stored as artifact/variant/revision entities backed by testcase blobs. Testset revisions persist canonical testcase IDs, while reads can populate full testcase objects or return windows of IDs. Delta commits can add, replace, or remove columns and rows while preserving order.

Observability is built around OpenTelemetry-compatible spans, Agenta SDK decorators, Redis streams, and Postgres span storage. Spans carry references, links, hashes, metadata, token/cost/latency metrics, and typed attributes; the storage layer indexes JSONB fields and supports trace-focused filtering, sampling, analytics, and full-text search.

CI coverage is broad. Reusable GitHub workflows run unit tests for API, SDK, services, and web; Railway preview workflows run unit, integration, and acceptance layers; styling workflows run Ruff and TypeScript checks; web E2E tests have metadata filters for scope, coverage, feature, entitlement, permission, lens, case, and speed.

## Design Choices

- Git-like entities give prompts/configs/testsets/environments immutable revisions while keeping variants and deployments easy to reason about.
- Evaluation runs are modeled as an explicit graph of `input`, `invocation`, and `annotation` steps with typed origins (`auto`, `human`, `custom`) and column mappings.
- Evaluators are workflows, so the same revision/deployment mechanics apply to judge prompts, custom evaluators, and application services.
- Trace links connect evaluator outputs back to invocation traces, which makes provenance inspectable and enables cache/reuse patterns.
- Online evaluation treats trace queries as first-class sources, not just dashboard filters.
- Testsets persist testcase IDs separately from testcase blob contents, which keeps revision identity stable while allowing paged reads.
- Redis streams and Taskiq locks separate ingestion/evaluation durability from request handling, with heartbeat and mutation locks around long-running jobs.
- SDK evaluation is intentionally compact and local-friendly, but it delegates pass/fail policy to the caller rather than baking in threshold gates.

## Strengths

- Closed-loop workflow from prompt/config revision to application invocation, trace capture, evaluation, metrics, and human review.
- Strong prompt/config versioning with variants, immutable revisions, environments, deploy, and rollback.
- Trace data is rich enough for agent-style observability: inputs, outputs, costs, tokens, latency, references, links, metadata, tool-like spans, and sampled trace queries.
- Testsets can come from CSV/manual data, inline SDK data, or production/playground traces, which is the right direction for regression coverage.
- Human annotation and feedback queues are not bolted on; they share the same scenario/result/metric model.
- The Python SDK supports CI-style evaluation with inline data and local application/evaluator functions.
- The repo tests important platform layers, including eval API behavior, queues, metrics, tracing adapters, SDK tracing decorators, and web ETL logic.

## Weaknesses

- The platform is large to adopt wholesale: API, web app, SDK, runtime services, Postgres, Redis, worker queues, and deployment config all matter.
- SDK evaluation did not show a built-in threshold or process-exit failure policy; a CI caller must assert metrics and fail the job explicitly.
- Trace export and ingestion are asynchronous. The SDK evaluation path polls for traces, and strict regression gates need timeout/failure handling around missing traces.
- The OTLP ingestion route accepts binary protobuf rather than JSON, skips malformed individual spans, and can return success for partial ingestion.
- The custom OTLP exporter has asynchronous/fail-open behavior that may hide export problems unless callers add their own checks.
- LLM-as-judge and webhook evaluators introduce cost, latency, credential, and network variability that can make CI non-deterministic.
- The model is LLM app/platform centered, not repository-task centered; coding-agent concepts such as checkout state, tool sandbox permissions, patch diffs, and deterministic test commands would need an additional schema.

## Ideas To Steal

- Represent every evaluation as a versioned run graph with explicit input, invocation, and annotation steps.
- Use traces and testsets as interchangeable evaluation sources, then allow production traces to become regression testsets.
- Link evaluator traces/results to invocation traces so every score has provenance.
- Version prompts, model settings, evaluator definitions, and deploy targets with the same artifact/variant/revision/environment abstraction.
- Keep human review queues in the same data model as automated evaluation so manual labels are regression artifacts.
- Provide a simple SDK `evaluate` API for CI, but require callers to configure metric thresholds and failure policy.
- Use trace query sampling for online eval instead of evaluating every production call.
- Persist testcase IDs in testset revisions and store testcase bodies separately for stable revision diffs and paged reads.

## Do Not Copy

- Do not import the full SaaS-style stack when a narrow coding-agent harness only needs the run graph, trace schema, and thresholded CI runner.
- Do not rely on async tracing as a hard CI gate without polling, exporter error visibility, and clear timeout behavior.
- Do not let human/custom pending results count as passing automated regression checks.
- Do not run custom code, webhook, or LLM-judge evaluators with unrestricted secrets, filesystem, network, or tool access.
- Do not assume generic OpenTelemetry adapter heuristics capture coding-agent semantics; repository state, command results, patch diffs, and sandbox decisions need explicit fields.
- Do not use dashboards or UI-visible metrics as the only regression gate; provide machine-readable pass/fail outputs.

## Fit For Agentic Coding Lab

Agenta is a conditional, high-value reference. It should not become a direct dependency for the lab's harness layer, but its data model is worth mining. The strongest transferable pieces are the revisioned config registry, evaluation run graph, trace-linked evaluator provenance, production trace sampling, testset revision flow, and human annotation queue design.

For coding agents, the lab would need to add coding-specific entities: repository snapshot, task prompt, context bundle, tool-call transcript, shell command result, sandbox/approval decision, generated patch, unit-test result, and evaluator threshold. With those additions, Agenta's closed-loop architecture maps well to regression prevention for prompt, model, and context changes.

## Reviewed Paths

- `/tmp/myagents-research/agenta-ai-agenta/README.md`
- `/tmp/myagents-research/agenta-ai-agenta/docs/docs/evaluation/03-concepts.mdx`
- `/tmp/myagents-research/agenta-ai-agenta/docs/docs/evaluation/evaluation-from-sdk/02-managing-testsets.mdx`
- `/tmp/myagents-research/agenta-ai-agenta/docs/docs/evaluation/evaluation-from-sdk/05-running-evaluations.mdx`
- `/tmp/myagents-research/agenta-ai-agenta/docs/docs/evaluation/configure-evaluators/01-overview.mdx`
- `/tmp/myagents-research/agenta-ai-agenta/docs/docs/evaluation/online-evaluation/01-quick-start.mdx`
- `/tmp/myagents-research/agenta-ai-agenta/docs/docs/observability/01-overview.mdx`
- `/tmp/myagents-research/agenta-ai-agenta/docs/docs/prompt-engineering/02-concepts.mdx`
- `/tmp/myagents-research/agenta-ai-agenta/docs/docs/prompt-engineering/managing-prompts-programatically/03-create-and-commit.mdx`
- `/tmp/myagents-research/agenta-ai-agenta/docs/docs/prompt-engineering/managing-prompts-programatically/04-deploy.mdx`
- `/tmp/myagents-research/agenta-ai-agenta/docs/docs/prompt-engineering/integrating-prompts/02-fetch-prompt-programatically.mdx`
- `/tmp/myagents-research/agenta-ai-agenta/docs/docs/tutorials/rag-to-production/05-end-to-end-evaluation-sdk.mdx`
- `/tmp/myagents-research/agenta-ai-agenta/api/oss/src/apis/fastapi/evaluations/router.py`
- `/tmp/myagents-research/agenta-ai-agenta/api/oss/src/core/evaluations/types.py`
- `/tmp/myagents-research/agenta-ai-agenta/api/oss/src/core/evaluations/service.py`
- `/tmp/myagents-research/agenta-ai-agenta/api/oss/src/core/evaluations/tasks/legacy.py`
- `/tmp/myagents-research/agenta-ai-agenta/api/oss/src/core/evaluations/tasks/live.py`
- `/tmp/myagents-research/agenta-ai-agenta/api/oss/src/tasks/taskiq/evaluations/worker.py`
- `/tmp/myagents-research/agenta-ai-agenta/api/oss/src/core/evaluations/runtime/locks.py`
- `/tmp/myagents-research/agenta-ai-agenta/api/oss/src/dbs/postgres/evaluations/utils.py`
- `/tmp/myagents-research/agenta-ai-agenta/api/oss/src/dbs/postgres/evaluations/dao.py`
- `/tmp/myagents-research/agenta-ai-agenta/api/oss/src/core/workflows/service.py`
- `/tmp/myagents-research/agenta-ai-agenta/api/oss/src/core/applications/service.py`
- `/tmp/myagents-research/agenta-ai-agenta/api/oss/src/core/evaluators/service.py`
- `/tmp/myagents-research/agenta-ai-agenta/api/oss/src/apis/fastapi/applications/router.py`
- `/tmp/myagents-research/agenta-ai-agenta/api/oss/src/core/environments/service.py`
- `/tmp/myagents-research/agenta-ai-agenta/api/oss/src/core/testsets/service.py`
- `/tmp/myagents-research/agenta-ai-agenta/api/oss/src/core/testcases/service.py`
- `/tmp/myagents-research/agenta-ai-agenta/api/oss/src/apis/fastapi/otlp/router.py`
- `/tmp/myagents-research/agenta-ai-agenta/api/oss/src/core/tracing/service.py`
- `/tmp/myagents-research/agenta-ai-agenta/api/oss/src/core/tracing/streaming.py`
- `/tmp/myagents-research/agenta-ai-agenta/api/oss/src/tasks/asyncio/tracing/worker.py`
- `/tmp/myagents-research/agenta-ai-agenta/api/oss/src/dbs/postgres/tracing/dao.py`
- `/tmp/myagents-research/agenta-ai-agenta/api/oss/src/dbs/postgres/tracing/dbes.py`
- `/tmp/myagents-research/agenta-ai-agenta/sdks/python/agenta/sdk/evaluations/preview/evaluate.py`
- `/tmp/myagents-research/agenta-ai-agenta/sdks/python/agenta/sdk/decorators/tracing.py`
- `/tmp/myagents-research/agenta-ai-agenta/sdks/python/agenta/sdk/engines/tracing/tracing.py`
- `/tmp/myagents-research/agenta-ai-agenta/sdks/python/agenta/sdk/engines/tracing/exporters.py`
- `/tmp/myagents-research/agenta-ai-agenta/api/oss/tests/pytest/unit/otlp/test_vercelai_adapter.py`
- `/tmp/myagents-research/agenta-ai-agenta/api/oss/tests/pytest/unit/otlp/test_openinference_adapter.py`
- `/tmp/myagents-research/agenta-ai-agenta/.github/workflows/11-check-code-styling.yml`
- `/tmp/myagents-research/agenta-ai-agenta/.github/workflows/12-check-unit-tests.yml`
- `/tmp/myagents-research/agenta-ai-agenta/.github/workflows/44-railway-tests.yml`
- `/tmp/myagents-research/agenta-ai-agenta/web/tests/README.md`
- `/tmp/myagents-research/agenta-ai-agenta/web/packages/agenta-entities/src/etl/__tests__/README.md`

## Excluded Paths

- `.git`, lockfiles, package-manager metadata, generated caches, generated API artifacts, and build outputs.
- Enterprise-only `ee/` implementation beyond noting the OSS/EE split where quota checks appear in OSS code paths.
- UI-only React pages, screenshots, icons, stories, and styling files except where web test or ETL docs helped understand eval data flow.
- Image assets, docs screenshots, blog material, and marketing content.
- Example applications were sampled through docs and file layout, but not audited line by line.
- Most provider-specific integration wrappers and individual built-in evaluator implementations were not reviewed line by line.
- Billing, organization, account, invitation, auth, and admin paths were excluded unless they directly affected eval, trace, prompt/config, or testset mechanics.
- Repository-local agent instructions and development meta files were excluded from the harness evaluation.
