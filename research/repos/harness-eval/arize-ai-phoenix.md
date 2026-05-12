# Arize-ai/phoenix

- URL: https://github.com/Arize-ai/phoenix
- Category: harness-eval
- Stars snapshot: 9,613 (GitHub REST API, captured 2026-05-12)
- Reviewed commit: a5c27f8be6423e63525d52e789fa3bdc87d6a432
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong in-scope reference for trace-first LLM and agent observability, dataset versioning, prompt tracking, retrieval evaluation, and experiment scoring. It is a platform rather than a coding-agent harness, so copy the data model and workflows, not the full server, UI, and deployment footprint.

## Why It Matters

Phoenix is a mature example of an AI observability and evaluation loop built around OpenTelemetry and OpenInference. It captures agent and LLM work as traces and spans, promotes traces into versioned datasets, runs experiments against those datasets, stores prompt versions and tags, and records evaluator outputs back as trace/span/document/session annotations or experiment-run annotations.

For coding agents, the transferable idea is the closed loop: instrument each agent attempt, inspect failures through span queries, curate regression datasets from real traces, run prompt or policy experiments, evaluate retrieval/tool/answer quality, and keep evaluator traces so the judge behavior is itself debuggable.

## What It Is

Phoenix is an AI observability and evaluation platform with a Python server, SQLAlchemy persistence for SQLite/Postgres, FastAPI REST routes, Strawberry GraphQL, OTLP HTTP and gRPC ingestion, Python and TypeScript clients, OpenTelemetry wrappers, an evals package, an MCP server, a CLI, documentation, tutorials, and a React UI.

The main primitives are projects, traces, spans, sessions, annotations, datasets, dataset versions and examples, experiments, experiment runs, prompts, prompt versions, prompt tags, evaluators, model providers, and secrets. The repo supports framework-agnostic tracing through OpenTelemetry/OpenInference and built-in evaluation workflows for LLM outputs, RAG retrieval, tool use, and prompt iteration.

## Research Themes

- Token efficiency: Phoenix stores prompt, completion, total, cached, reasoning, and cumulative token counts on spans, traces, sessions, and projects, and calculates span costs from model metadata. Its query APIs let agents pull narrowed span fields instead of full transcripts. It does not compress coding-agent context directly, but it gives the data needed to find token-heavy tools, prompts, and retrieval steps.
- Context control: Strong. Projects, sessions, traces, span kinds, OpenInference attributes, prompt versions, dataset versions, experiment snapshots, splits, tags, and JSONPath input mappings all create explicit context boundaries. SpanQuery can select, filter, explode retrieval documents, and concatenate context for downstream evals.
- Sub-agent / multi-agent: Phoenix is not an orchestrator, but its span schema includes AGENT, TOOL, CHAIN, LLM, RETRIEVER, RERANKER, GUARDRAIL, and EVALUATOR. That maps naturally to planner/editor/tester/reviewer coding-agent steps or multi-agent frameworks.
- Domain-specific workflow: Very strong for LLM/RAG/agent evaluation. The intended loop is trace collection, error analysis, dataset creation, prompt/version iteration, experiment execution, evaluator scoring, annotation review, and production monitoring.
- Error prevention: Prevention comes from evals, experiments, human and code annotations, deterministic built-in evaluators, LLM-as-judge evaluators, structured tool-call judge output, retry/concurrency executors, permission checks, storage locks, redaction/encryption for secrets, and tests for datasets, prompts, evals, spans, auth, and RAG helpers.
- Self-learning / memory: Phoenix is not an autonomous memory system. It can serve as the memory substrate: production traces, notes, annotations, prompt versions, dataset revisions, and experiment results can be used by humans or agents to build future regression items and prompt updates.
- Popular skills: The repo ships `.agents/skills/phoenix-cli`, `.agents/skills/phoenix-evals`, and `.agents/skills/phoenix-tracing`, plus `@arizeai/phoenix-cli` and `@arizeai/phoenix-mcp`. These are directly aimed at Claude Code, Cursor, Codex, Gemini CLI, and similar coding-agent workflows.

## Core Execution Path

1. A traced application or agent emits OpenTelemetry/OpenInference spans through `arize-phoenix-otel`, `@arizeai/phoenix-otel`, framework instrumentation, the Python/TS clients, OTLP HTTP `/v1/traces`, OTLP gRPC, or JSON span logging.
2. The FastAPI app starts REST, GraphQL, gRPC, static UI, DML events, bulk insertion, trace sweeping, experiment sweeping, span cost calculation, model store, and experiment runner services. Auth, redaction, CSRF origin validation, and storage-lock checks are wired at this boundary.
3. OTLP spans are decoded into internal `Span` objects with OpenInference semantic attributes. The project is resolved from the `x-project-name` header, resource attributes, or default project.
4. `BulkInserter` drains queued spans, operations, and annotations. Span insertion creates or updates projects, traces, sessions, spans, cumulative token/error metrics, and cost records; late child spans update ancestor cumulative values.
5. Users, SDKs, CLI, MCP, or UI query traces/spans via REST, GraphQL, or the SpanQuery DSL. They can attach trace, span, document, or session annotations and notes with LLM/CODE/HUMAN provenance.
6. Datasets are uploaded from JSON, JSONL, CSV, PyArrow, DataFrames, dicts, or traced spans. The server diffs examples by external id or content hash, creates dataset versions with CREATE/PATCH/DELETE revisions, records splits, and links examples to span row ids when possible.
7. Experiments snapshot a dataset version and optional splits, create a dedicated experiment project, run tasks over examples and repetitions, record experiment runs with trace ids, and upsert evaluations by experiment run and evaluator name.
8. Evaluators run either client-side through `phoenix-evals` or server-side through dataset evaluator configuration. LLM evaluators map inputs with JSONPath/literals, format prompt versions, call a judge model with structured tool output, parse labels/scores/explanations, and persist annotations plus evaluator traces.
9. Prompt management stores prompt names, versions, model providers, models, chat templates, template formats, invocation parameters, tools, response formats, custom providers, metadata, and tags so experiments and evaluators can refer to stable prompt definitions.

## Architecture

The server is a Python FastAPI application with REST v1 routers, Strawberry GraphQL, an OTLP gRPC service, middleware, and background daemons. REST covers traces, spans, datasets, experiments, experiment runs, experiment evaluations, prompts, sessions, projects, annotations, users, and secrets. GraphQL covers richer UI and mutation workflows, including prompt and evaluator management.

Persistence is SQLAlchemy over SQLite or Postgres. The model layer makes traces, spans, annotations, datasets, dataset revisions, experiments, prompt versions, and evaluator definitions first-class relational rows while storing LLM-specific payloads as JSON. Span attributes follow OpenInference conventions, so retrieval documents, messages, tool calls, token counts, metadata, and model settings stay portable.

Ingestion is asynchronous by default. HTTP/gRPC requests queue spans or operations, and `BulkInserter` commits batches while publishing DML events. Queue-based annotation inserters support eventual insertion when referenced spans or traces arrive later. Experiment running has its own daemon/job model for prompt tasks, eval-only jobs, rate limits, retries, heartbeats, and stopped/error/completed statuses.

The client surface is broad. Python `arize-phoenix-client` supports datasets, experiments, prompts, traces, spans, sessions, annotations, and helper DataFrames. `arize-phoenix-evals` provides evaluator abstractions, model adapters, structured LLM judging, concurrency, and built-in metrics. `arize-phoenix-otel` wraps OpenTelemetry setup and exporters. TypeScript packages mirror client, otel, evals, CLI, and MCP workflows.

## Design Choices

- Standards-first tracing: Phoenix uses OpenTelemetry transport and OpenInference semantic attributes instead of inventing a closed trace schema.
- Trace storage favors analysis: spans keep parent/trace links, span kind, raw attributes, events, status, input/output helper properties, retrieval document counts, token counts, cumulative counts, and cost records.
- Async ingestion with backpressure: queues decouple collection from database writes, capacity checks can reject overloaded ingestion, and duplicate span ids are ignored or rejected depending on endpoint.
- Datasets are versioned by revisions: each dataset version is a set of example revisions, not a mutable table dump. `CREATE`, `PATCH`, and `DELETE` revisions make idempotent update and append behavior explicit.
- Experiments snapshot datasets: experiment examples are crosswalked to a dataset version and split selection, so later dataset changes do not silently change the experiment.
- Evaluators are observable: server-side LLM evaluation creates a trace with `EVALUATOR`, `Input Mapping`, `Prompt`, `LLM`, and `Parse Eval Result` spans, including error spans when mapping, provider, or parser failures happen.
- Prompt tracking is database-native: prompt versions store templates, model config, tool schemas, response formats, invocation parameters, custom providers, metadata, and tags. Evaluators can label and reuse prompts instead of keeping judge prompts as untracked strings.
- RAG evaluation is span-native: retriever spans carry `retrieval.documents`; SpanQuery can explode document rows, compute relevance per document, and log document/span annotations such as relevance, NDCG, precision, and hit.
- Security is layered but opt-in depends on deployment: auth, API keys, roles, read-only/viewer restrictions, admin-only secrets, Fernet encryption, redacted secret transport, gRPC bearer interceptors, TLS/mTLS options, CSRF trusted origins, and sanitized experiment errors are present. Installations without a strong `PHOENIX_SECRET` rely on trusted-environment assumptions.

## Strengths

- Excellent trace, span, dataset, prompt, experiment, and annotation data model for LLM/agent systems.
- OpenTelemetry and OpenInference support make it usable with many frameworks and languages.
- Strong RAG workflow: retriever spans, document explosion, document annotations, relevance evaluators, ranking metrics, and response faithfulness/correctness evaluators.
- Prompt versions and tags are first-class and can be tied to evaluator and experiment workflows.
- Evaluator failures are inspectable because judge calls are traced, not hidden behind a score row.
- Python and TypeScript clients, MCP, CLI, and bundled agent skills make trace/dataset/eval workflows usable from coding agents rather than only from the UI.
- Tests cover span ingestion/retrieval, dataset versioning and span links, experiment spans and retries, prompt serialization, evaluator validation/tracing/errors, RAG helpers, secret encryption, redaction, and auth.

## Weaknesses

- It is a large observability platform, not a minimal harness. Server, UI, GraphQL, REST, clients, daemons, docs, examples, and deployment packaging are expensive to transplant.
- Async ingestion and queued operations create eventual consistency. That is fine for observability but needs explicit waiting or sync modes for CI-style regression gates.
- LLM-as-judge quality still depends on judge model behavior, prompt design, tool-call support, variable mapping, and calibration against human labels.
- Span ids are globally unique in the database, which is simple but can be awkward for multi-source imports if upstream systems do not guarantee uniqueness.
- Query/filter power comes with parser complexity. The SpanQuery filter path validates a restricted Python AST before `eval`, but this is still more attack surface and maintenance burden than a small typed query builder.
- Sensitive prompt, trace, tool, and repository contents can be stored or sent to judge models. Phoenix has auth, redaction, and secret controls, but application-level masking and provider data policy still matter.
- It does not provide a sandbox or permission model for executing coding agents. It observes and evaluates runs; another system must enforce shell/file/network policy.
- Server-side evaluator/provider integration adds credential and secret-management risk. Production use needs a strong `PHOENIX_SECRET`, rotation planning, and clear rules for judge data egress.

## Ideas To Steal

- Model one coding-agent run as a trace and each planner, editor, shell, test, retrieval, tool call, and review step as an OpenInference span.
- Use cumulative token and error counts on traces/sessions so the harness can rank expensive or failure-heavy runs without loading every span.
- Promote real failing spans or traces into versioned datasets with stable external ids, content hashes, splits, and optional links back to source spans.
- Store prompt versions, tool schemas, response formats, invocation parameters, model provider/name, and tags as first-class records.
- Snapshot dataset version and split selection for every experiment, and link each experiment run back to the trace produced by that run.
- Trace evaluator execution itself, including input mapping, rendered prompt, judge LLM call, parser step, and errors.
- Support both deterministic code evaluators and structured LLM judges, then normalize their outputs as annotations with label, score, explanation, metadata, source, and annotator kind.
- Add SpanQuery-like helpers for RAG and coding-agent debugging: explode retrieval documents, concatenate context, filter by tool/error/status/span kind, and join annotations.
- Provide CLI and MCP tools that let coding agents fetch recent traces, annotate spans, inspect datasets, inspect experiments, and retrieve prompts without depending on UI screenshots.
- Keep human notes separate from machine annotations but store both on the same trace/span/session surfaces.

## Do Not Copy

- Do not copy the full platform if a narrower local harness can store traces, datasets, prompt versions, and scores in SQLite files.
- Do not make a coding-agent regression gate depend on eventual background insertion unless the test harness has sync APIs and polling semantics.
- Do not send raw repository contents, secrets, command output, or customer data to LLM judges without masking, allowlists, and provider-policy review.
- Do not use a broad Python-expression DSL if a typed query API is sufficient; the AST validation and SQL compilation are substantial complexity.
- Do not treat LLM judge scores as ground truth without human calibration datasets and disagreement analysis.
- Do not rely on UI-only workflows for agent debugging; Phoenix's CLI/MCP/SDK path is the part to emulate.
- Do not store provider credentials with weak deployment secrets or no rotation story.
- Do not copy global span-id uniqueness if the target harness needs to merge multiple OTLP sources that may collide.

## Fit For Agentic Coding Lab

Phoenix is a strong reference architecture for a coding-agent evaluation lab. The best fit is to borrow its trace-first schema, OpenTelemetry/OpenInference conventions, dataset revision model, prompt versioning, evaluator tracing, annotations, RAG helpers, CLI/MCP surface, and experiment linkage.

It should not be treated as a drop-in coding-agent harness. It does not orchestrate agents, sandbox tools, enforce filesystem/network policy, or define SWE-bench-like task execution. It is best as the observability and evaluation layer under such a harness, or as a design source for a smaller purpose-built implementation.

## Reviewed Paths

- `README.md`, `packages/phoenix-client/README.md`, `packages/phoenix-evals/README.md`, `packages/phoenix-otel/README.md`, `js/packages/phoenix-cli/README.md`, and `js/packages/phoenix-mcp/README.md` for scope, packages, tracing, eval, prompt, CLI, MCP, and coding-agent claims.
- `docs/phoenix/evaluation/llm-evals.mdx`, `docs/phoenix/tracing/how-to-tracing/importing-and-exporting-traces/extract-data-from-spans.mdx`, `docs/phoenix/prompt-engineering/overview-prompts/prompt-management.mdx`, and `docs/phoenix/cookbook/evaluation/evaluate-rag.mdx` for evaluator tracing, span queries, prompt management, and RAG eval workflow.
- `src/phoenix/server/app.py`, `grpc_server.py`, `authorization.py`, `bearer_auth.py`, `redaction.py`, `encryption.py`, `telemetry.py`, and `retention.py` for server startup, auth, ingestion, redaction, encryption, security, and daemons.
- `src/phoenix/server/api/routers/v1/traces.py`, `spans.py`, `datasets.py`, `experiments.py`, `experiment_runs.py`, `experiment_evaluations.py`, `prompts.py`, `secrets.py`, `sessions.py`, and `projects.py` for REST behavior.
- `src/phoenix/server/api/mutations/prompt_mutations.py`, `evaluator_mutations.py`, `prompt_version_tag_mutations.py`, and related GraphQL auth/input types for prompt and evaluator lifecycle.
- `src/phoenix/db/models.py`, `bulk_inserter.py`, `insertion/span.py`, `insertion/dataset.py`, helpers, and DB type modules for trace/span/dataset/experiment/prompt/evaluator schema and insertion behavior.
- `src/phoenix/trace/otel.py`, `trace/schemas.py`, `trace/dsl/query.py`, `trace/dsl/filter.py`, `metrics/retrieval_metrics.py`, and client RAG helpers for span encoding, querying, filtering, and retrieval metrics.
- `src/phoenix/server/api/evaluators.py`, `builtin_evaluator_sync.py`, and evaluator helper modules for built-in and LLM evaluator execution, input mapping, prompt rendering, structured output parsing, and annotation conversion.
- `packages/phoenix-client/src/phoenix/client/**` resources for datasets, experiments, prompts, spans, traces, sessions, annotations, and client guard/version behavior.
- `packages/phoenix-evals/src/phoenix/evals/**` for `Evaluator`, `Score`, `LLMEvaluator`, evaluator decorators, DataFrame evaluation, executors, LLM wrappers, prompt formatting, tracing, document relevance, faithfulness, correctness, tool evaluators, regex/exact match, and precision/recall metrics.
- `packages/phoenix-otel/src/**` and README-level API for OpenTelemetry registration, exporter defaults, batching, auth headers, decorators, and project naming.
- `js/packages/phoenix-mcp/src/**` and `js/packages/phoenix-cli/src/**` sampled for coding-agent tool coverage: traces, spans, sessions, datasets, experiments, prompts, annotation configs, profiles, auth, and docs fetch.
- `.agents/skills/phoenix-cli/SKILL.md`, `.agents/skills/phoenix-evals/SKILL.md`, `.agents/skills/phoenix-tracing/SKILL.md`, and `.agents/skills/README.md` for agent-facing workflows.
- `tests/integration/client/test_spans.py`, `test_datasets.py`, `test_experiments.py`, `test_prompts.py`, `test_rag_helpers.py`, `test_secrets.py`, `tests/integration/auth/test_redaction.py`, `tests/unit/db/insertion/test_dataset.py`, `tests/unit/db/test_models.py`, `tests/unit/server/api/helpers/test_evaluators.py`, `tests/unit/server/api/mutations/test_evaluator_mutations.py`, and `packages/phoenix-evals/tests/**` for verification signals.

## Excluded Paths

- `app/src/**` React UI, styling, charts, icons, navigation, generated GraphQL code, and page components: excluded except behavior inferred through server/API/docs because the review target is harness/eval architecture, not UI implementation.
- `app/src/**/__generated__`, `packages/phoenix-client/src/phoenix/client/__generated__`, and `packages/phoenix-evals/src/phoenix/evals/__generated__`: generated API/config code; reviewed source call sites, metric classes, and schemas instead.
- `api_reference/**`, generated OpenAPI/schema artifacts, sitemap files, and static docs assets: generated or presentation material.
- `tutorials/**/*.ipynb`, cookbook notebooks, screenshots, GIFs, logos, and binary/media files: tutorial or binary artifacts, useful for examples but not for understanding core architecture.
- `helm/**`, `kustomize/**`, broad Docker/deployment packaging, and release automation: noted for self-hosting shape but excluded from deep review because they do not define trace/eval semantics.
- `scripts/**`, broad CI, formatting, changelog, release, migration utility scripts, and lockfiles such as `uv.lock` and JS lockfiles: operational or dependency metadata outside the requested architecture focus.
- `src/phoenix/vendor/json_canonicalization_scheme/**`: vendored code, not Phoenix-specific design.
- Broad provider integration examples and framework cookbooks outside the traced/eval paths: integrations are useful evidence of compatibility, but the harness patterns are in the server, clients, eval package, and tests.
- UI-only Playwright tests and visual regression fixtures: excluded unless they validated API-visible prompt/eval/dataset behavior.
- Unrelated admin/product surfaces such as billing-like docs, marketing pages, community links, and static website content: not relevant to traces, spans, datasets, evals, prompt tracking, retrieval evals, security, or coding-agent applicability.
