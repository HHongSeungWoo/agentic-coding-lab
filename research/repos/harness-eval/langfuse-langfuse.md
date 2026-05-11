# langfuse/langfuse

- URL: https://github.com/langfuse/langfuse
- Category: harness-eval
- Stars snapshot: 26,978 (GitHub REST API, captured 2026-05-11; from research/index.md)
- Reviewed commit: dc44c5f854166b63f8cbc794e3fd7af45fd3c6ef
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: conditional
- Verdict: Strong observability and evaluation platform primitives for agent traces, datasets, prompt versions, and judge scores. It is too broad to copy as a coding-agent harness, but several backend patterns are worth adopting.

## Why It Matters

Langfuse is one of the most complete open-source LLM observability stacks: traces, observations, scores, datasets, prompt versions, experiments, and LLM-as-judge evaluation rules are all first-class entities. For an agentic coding lab, the main value is not the product UI, but the way it turns messy runtime events into replayable, queryable, scored, and versioned evaluation artifacts.

The repo also shows what a production-grade eval loop needs beyond a benchmark runner: durable ingestion, async processing, score schemas, dataset item versioning, prompt dependency/version tracking, judge execution traces, retry policy, rate limits, RBAC, SSRF controls, and tests for OpenTelemetry framework mappings.

## What It Is

Langfuse is a TypeScript monorepo for an LLM engineering platform. The reviewed codebase includes a Next.js web app and public API, worker queues, shared domain/repository packages, ClickHouse and Prisma schemas, OpenTelemetry ingestion, prompt management, datasets, experiment execution, and evaluator configuration/execution.

The core runtime model separates:

- Traces: top-level user or agent runs.
- Observations: spans, generations, tools, agents, chains, retrievers, events, evaluators, embeddings, and guardrails under a trace.
- Scores: numeric, categorical, boolean, correction, and text evaluations attached to traces, observations, sessions, or dataset run items.
- Datasets: versioned items and run snapshots for experiments and regression checks.
- Prompts: versioned prompt records with labels, tags, config, commit messages, and dependency graph resolution.
- Evals: templates and job configurations that schedule LLM-as-judge scoring for traces, datasets, observations, and experiments.

## Research Themes

- Token efficiency: Langfuse does not optimize coding-agent prompt tokens directly, but its event schema stores compact model usage, cost details, prompt names, prompt versions, and truncated query paths. The `events_core` / `events_full` split is the most relevant pattern: query small, truncated rows first, then fetch full input/output only for selected records.
- Context control: Strong fit. Traces, observations, dataset item versions, prompt versions, environment, release, tags, user/session ids, and metadata filters create explicit context boundaries for evaluation and replay.
- Sub-agent / multi-agent: Indirect fit. Observation types include `AGENT`, `TOOL`, `CHAIN`, and related span structure, so multi-step or multi-agent runs can be represented, but there is no native agent scheduler or coordination layer.
- Domain-specific workflow: Strong fit for LLM app evaluation. The workflow is trace ingestion -> dataset or live event selection -> evaluator template/rule -> judge execution -> score ingestion -> dashboards/API queries.
- Error prevention: Strong production patterns: schema validation, versioned dataset items, score config validation, retry classification, eval-loop guards, outbound URL validation, rate limits, RBAC, and extensive OTel/eval/dataset tests.
- Self-learning / memory: Conditional fit. Langfuse stores historical traces, feedback, scores, datasets, prompts, and eval results, which can become a memory substrate, but it does not implement autonomous learning policy updates.
- Popular skills: No coding-agent skill marketplace. Relevant reusable "skills" are operational primitives: trace capture, dataset construction, prompt versioning, judge score generation, experiment execution, and eval rule management.

## Core Execution Path

Ingestion starts at `web/src/pages/api/public/ingestion.ts`. The public route authenticates API keys, rate limits, validates batch input, checks project ingestion state, then calls `processEventBatch`. That shared ingestion path validates every event with project scope and access-level rules, sorts create/update events, groups by ClickHouse entity and object id, writes each group to S3, and enqueues a BullMQ ingestion job keyed by project and entity id.

`worker/src/queues/ingestionQueue.ts` downloads grouped S3 event files, de-duplicates recently processed event ids through Redis, and passes the collected events to `IngestionService.mergeAndWrite`. `worker/src/services/IngestionService/index.ts` merges incoming trace, observation, score, and dataset-run-item events with existing ClickHouse rows. It preserves immutable keys, computes usage/cost for observations, looks up prompt references, validates scores, writes ClickHouse rows, snapshots dataset run item fields, and schedules trace-based eval creation when active configs exist.

OpenTelemetry uses a parallel entry point at `web/src/pages/api/public/otel/v1/traces/index.ts`. It accepts JSON or protobuf OTLP payloads, stores raw resource spans to S3, and queues `OtelIngestionQueue`. `packages/shared/src/server/otel/OtelIngestionProcessor.ts` maps spans into Langfuse observations or direct event records with trace/span ids, model usage, prompt metadata, tools, experiment fields, and framework-specific attributes. The worker decides whether to use the newer direct event-write path based on ingestion headers or SDK versions; otherwise it converts spans into legacy ingestion events.

Evaluation is asynchronous. Web/API code creates evaluator templates and job configurations with target, filters, variable mapping, sampling, delay, and time scope. Workers receive trace, dataset, observation, or experiment events, filter candidate configs, create `JobExecution` rows, and enqueue LLM-as-judge execution. Judge execution compiles the prompt, calls an LLM with structured output, records an internal execution trace, converts the model output into score ingestion events, uploads score events to S3, and queues them back through the normal ingestion path.

Dataset experiments execute active dataset items against prompt/model configs, emit deterministic trace and dataset-run-item events, and then schedule dataset or experiment evals. This gives Langfuse a closed loop: run, trace, score, compare, and inspect.

## Architecture

The monorepo is split into `web`, `worker`, and `packages`. `web` owns Next.js routes, TRPC routers, public API behavior, UI-adjacent server services, RBAC checks, and request validation. `worker` owns BullMQ processors for ingestion, OpenTelemetry, eval job creation, judge execution, experiments, entity-change automations, and cleanup jobs. `packages/shared` owns domain types, repositories, ClickHouse helpers, Prisma schema, ingestion helpers, LLM provider integration, outbound URL safety, score validation, dataset repositories, and OpenTelemetry mapping.

Storage is deliberately mixed. Postgres/Prisma holds configuration and relational state such as projects, API keys, prompts, eval templates, job configurations, job executions, datasets, dataset items, and dataset runs. ClickHouse holds high-volume trace, observation, score, dataset-run-item, and event records. S3/blob storage acts as a durable queue payload store for raw ingestion batches, OTel spans, and eval score events. Redis is used for caching, queue coordination, recent-event de-duplication, prompt cache epochs, and no-eval-config caches. BullMQ coordinates async ingestion, eval creation, eval execution, and experiment execution.

ClickHouse has both legacy entity tables (`traces`, `observations`, `scores`, `dataset_run_items_rmt`) and the newer `events_full` / `events_core` tables. `events_full` keeps full input, output, metadata, prompt, model, tool, and experiment fields. `events_core` is populated through a materialized view with truncated input/output/metadata for fast filtering and listing. Repository code first queries `events_core`, then fetches full rows from `events_full` only when full payloads are required.

## Design Choices

- Durable async ingestion: API routes write validated grouped events or raw OTel spans to S3 before worker processing. This makes ingestion replayable and limits request latency.
- Merge-by-entity semantics: workers merge event lists with existing ClickHouse records, preserve immutable fields, and support create/update ordering rather than treating every SDK event as an append-only final row.
- First-class score schema: scores have source, data type, config, ranges/categories, target ids, trace/session/dataset relations, and validation before ClickHouse writes.
- Eval jobs are data, not callbacks: `JobConfiguration` and `JobExecution` encode evaluator template, target, filters, sampling, delay, status, retries, output score id, and execution trace id.
- Judge calls are observable: LLM-as-judge executions use internal trace sink parameters and deterministic execution trace ids, so evaluator behavior itself can be inspected.
- Prompt versions are graph-aware: prompt creation validates type consistency, labels, dependency references, max nesting depth, and cycles, then invalidates a project-scoped prompt cache epoch.
- Dataset items are versioned: versioned upserts close the old `validTo` and create a new row; dataset run items snapshot item/run fields into ClickHouse for stable experiment comparisons.
- Security is layered: API auth scopes, RBAC, rate limiting, outbound URL validation, redirect validation, connection-time IP checks, secret encryption, ingestion masking, and internal environment guards are separate controls.

## Strengths

- Mature observability data model for real LLM/agent workloads, including nested spans, tools, prompts, usage, costs, scores, datasets, and experiments.
- Evaluation loop is integrated with production traces and dataset experiments instead of living as a disconnected benchmark script.
- Strong replay and audit story: raw ingestion payloads live in S3, job executions persist status/errors/output score ids, and judge executions can emit internal traces.
- ClickHouse design supports both heavy payload storage and fast query paths through `events_full` and `events_core`.
- Prompt/version tracking is practical: labels, tags, commit messages, dependency rows, cache invalidation, and prompt change automations are all represented.
- Test coverage is broad around ingestion merging, eval scheduling/execution, OTel framework mapping, dataset comparisons, prompt cache/dependencies, and outbound security.
- OpenTelemetry support makes the platform applicable to many SDKs and frameworks without forcing every runtime to use a Langfuse-specific client.

## Weaknesses

- The useful eval architecture is embedded in a large SaaS product. Extracting it requires understanding web routes, shared repositories, workers, queues, Prisma, ClickHouse, Redis, and S3 together.
- Legacy and new event paths coexist: traces/observations/scores tables, OTel legacy conversion, direct event writes, dual staging, and `events_full` / `events_core` migration code add complexity.
- Eval behavior is distributed across routers, shared domain code, worker services, queues, and tests. There is no small harness module that can be lifted out cleanly.
- Public evaluator/rule APIs are explicitly unstable in the reviewed paths, especially around event and experiment targets.
- OTel mapping is powerful but high-maintenance because it depends on many vendor and framework conventions.
- Some production choices, such as silently skipping invalid score records inside mixed ingestion batches, are less suitable for a strict CI harness where failures should be loud.

## Ideas To Steal

- Store raw or grouped event payloads durably before async processing, then make workers idempotent with event ids and recent-event caches.
- Use a compact query table plus a full payload table for high-volume traces. Agent eval dashboards often need filters and summaries far more often than full transcripts.
- Treat eval scores as normal ingestion events with source, data type, config, metadata, and execution trace id, so human feedback, API scores, and judge scores share one path.
- Represent evaluator execution as persisted jobs with deterministic ids, retry state, user-facing errors, output score ids, and internal traces.
- Snapshot dataset item input, expected output, metadata, and version into run items to keep experiment comparisons stable after dataset edits.
- Make prompt references explicit and versioned, including dependency graph validation and cache invalidation by project epoch.
- Add environment guards so traces generated by evaluators do not recursively trigger new evaluations.
- Test OTel/framework mappings with realistic fixture traces, not only schema-level unit tests.
- Validate outbound URLs at save time, redirect time, and connection time, and strip sensitive headers on cross-origin redirects.

## Do Not Copy

- Do not copy the whole SaaS surface for a coding-agent lab. Billing, dashboards, broad provider integrations, UI routes, and enterprise features are not required to get the eval loop benefit.
- Do not inherit dual-write and migration complexity unless there is a real long-lived data migration to support.
- Do not let invalid eval scores disappear silently in CI-style evaluation. Agent regressions should fail loudly with clear diagnostics.
- Do not adopt broad vendor-specific OTel heuristics without committing to fixture maintenance.
- Do not run LLM judges as opaque side effects. Require stored prompts, output schemas, model config, execution traces, and score events.
- Do not use fail-open masking for sensitive coding-agent traces that may include secrets, repository contents, or credentials.

## Fit For Agentic Coding Lab

Conditional but high-value. Langfuse is not a SWE-bench-style coding-agent harness and does not orchestrate agents. Its best fit is as an observability and evaluation backend for coding agents: capture traces, normalize tool/generation spans, attach prompt versions and dataset items, run judge evaluations asynchronously, and query score trends across experiments.

For this repository, the most transferable pieces are the trace/observation/score schema, dataset item versioning, judge-job lifecycle, prompt version graph, and ClickHouse query split. A smaller lab should implement those patterns in a narrower service before considering the full Langfuse stack.

## Reviewed Paths

- `README.md`: product scope, observability/eval/prompt/dataset claims, quickstart tracing, and telemetry policy.
- `package.json`, `pnpm-workspace.yaml`: monorepo shape, package manager/runtime constraints, test/build scripts, dependency release-age and build allowlist controls.
- `web/src/pages/api/public/ingestion.ts`: public ingestion API boundary, auth, rate limiting, request schema, and batch processing call.
- `packages/shared/src/server/ingestion/processEventBatch.ts`: ingestion validation, event grouping, S3 upload, queueing, authorization, sorting, and sampling.
- `worker/src/queues/ingestionQueue.ts`: worker-side S3 download, de-duplication, secondary queue routing, and ingestion service call.
- `worker/src/services/IngestionService/index.ts`: trace, observation, score, dataset-run-item merge/write logic, cost usage calculation, prompt lookup, eval scheduling, and direct-event staging.
- `web/src/pages/api/public/otel/v1/traces/index.ts`, `packages/shared/src/server/otel/OtelIngestionProcessor.ts`, `worker/src/queues/otelIngestionQueue.ts`: OTLP ingestion, raw span storage, mapping, masking, SDK-version direct write gating, and eval scheduling from spans.
- `packages/shared/src/server/clickhouse/schema.ts`, `packages/shared/clickhouse/migrations/*traces*`, `*observations*`, `*scores*`, `*dataset_run_items*`, and `packages/shared/clickhouse/scripts/dev-tables.sh`: trace/observation/score/dataset/event table design.
- `packages/shared/src/server/repositories/events.ts`, `packages/shared/src/server/repositories/eventsQueryBuilder.ts`: `events_core` versus `events_full` query behavior.
- `packages/shared/src/domain/traces.ts`, `observations.ts`, `scores.ts`, `dataset-run-items.ts`, `prompts.ts`: domain models relevant to traces, spans, scores, datasets, and prompt versions.
- `packages/shared/prisma/schema.prisma`: relational model for prompts, prompt dependencies, datasets, dataset items, dataset runs, eval templates, job configurations, job executions, and API keys.
- `web/src/features/evals/server/router.ts`, `unstable-public-api/evaluator-service.ts`, `unstable-public-api/evaluation-rule-service.ts`: evaluator templates, public evaluator/rule APIs, mapping validation, filters, time scopes, and job configuration creation.
- `worker/src/features/evaluation/evalService.ts`, `evalRuntime.ts`, `evalScoreEvent.ts`, `evalExecutionDeps.ts`, `worker/src/queues/evalQueue.ts`: trace/dataset eval job creation, judge execution, structured output parsing, score event generation, retries, and error handling.
- `worker/src/features/evaluation/observationEval/scheduleObservationEvals.ts`, `observationEvalProcessor.ts`: event and experiment observation-level eval scheduling/execution.
- `web/src/features/datasets/server/service.ts`, `dataset-router.ts`, `packages/shared/src/server/repositories/dataset-items.ts`, `packages/shared/src/server/services/DatasetService/DatasetItemValidator.ts`, `web/src/features/public-api/server/dataset-runs.ts`, `dataset-run-items.ts`, and dataset public API routes: dataset item validation/versioning, run creation, run item querying, and UI enrichment.
- `worker/src/features/experiments/experimentServiceClickhouse.ts`, `web/src/features/evals/server/addDatasetRunItemsToEvalQueue.ts`: prompt experiment execution and dataset eval scheduling.
- `packages/shared/src/server/services/PromptService/index.ts`, `web/src/features/prompts/server/actions/createPrompt.ts`, `web/src/pages/api/public/prompts.ts`, `worker/src/features/entityChange/promptVersionProcessor.ts`: prompt versioning, dependency resolution, cache invalidation, public API, and prompt-change automations.
- `web/src/features/public-api/server/createAuthedProjectAPIRoute.ts`, `apiAuth.ts`, `withMiddlewares.ts`, `web/src/features/rbac/utils/checkProjectAccess.ts`: API auth, access levels, RBAC, rate limits, and error handling.
- `packages/shared/src/server/llm/fetchLLMCompletion.ts`, `baseUrlValidation.ts`, `packages/shared/src/server/outbound-url/*`, `packages/shared/src/server/webhooks/validation.ts`, `packages/shared/src/server/ee/ingestionMasking/applyIngestionMasking.ts`, `SECURITY.md`: LLM call safety, SSRF defenses, webhook validation, ingestion masking, and security reporting.
- Tests under `worker/src/__tests__`, `worker/src/services/IngestionService/tests`, `worker/src/features/evaluation/**/*.test.ts`, `worker/src/queues/__tests__`, `web/src/__tests__/server/api/otel`, `web/src/__tests__/server/dataset-service.servertest.ts`, `web/src/__tests__/server/prompts*.servertest.ts`, and outbound/security tests: verification surface for ingestion, evals, OTel mappings, datasets, prompts, and security controls.

## Excluded Paths

- `docs/`: no top-level `docs` directory existed at reviewed commit; documentation-equivalent material was reviewed through `README.md`, API routes, Fern API definitions where relevant, and implementation code.
- `README.cn.md`, `README.ja.md`, `README.kr.md`: translated README files duplicate product-level content from `README.md`.
- `web/src/pages/api/public/otel/otlp-proto/generated/root.ts`: generated protobuf bindings; reviewed callers and mapping logic instead.
- `node_modules`, `.turbo`, `.next`, coverage, build outputs, lockfile internals, binary/media/static assets, and vendored/generated artifacts: not useful for understanding observability/eval architecture.
- UI-only React components, icons, charts, layout pages, marketing assets, screenshots, and styling files: excluded unless they directly exposed route/server behavior or dataset/eval semantics.
- Billing, support, cloud-account, organization administration, auth UI, and unrelated product-management paths: excluded because they do not change trace ingestion, datasets, evals, scoring, prompt versions, security controls, or coding-agent applicability.
- Enterprise-only paths under `ee` except ingestion masking and security-relevant integrations: excluded to keep the review focused on open eval/observability architecture.
- Broad provider-specific LLM adapter details beyond shared safety, retry, tracing, and structured-output behavior: the important harness pattern is the judge execution contract, not each provider implementation.
