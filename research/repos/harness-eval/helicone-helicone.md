# Helicone/helicone

- URL: https://github.com/Helicone/helicone
- Category: harness-eval
- Stars snapshot: 5,641 (GitHub REST API, captured 2026-05-11 in research/index.md)
- Reviewed commit: 3f4bd44b85f9837feb4a696cce4bba6c99fbdc7e
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: conditional
- Verdict: Strong LLM observability and gateway platform with useful trace, cost, prompt-version, dataset, and online-eval patterns. It is not a deterministic coding-agent harness by itself, but it is a good telemetry and evaluation substrate for one.

## Why It Matters

Helicone sits on the hot path of LLM calls, so it captures the data that a coding-agent lab usually reconstructs after the fact: request body, response body, provider, model, usage, latency, time to first token, cost, prompt version, session path, properties, and scores. The value is not a benchmark runner. The value is the production-grade capture layer around a gateway: model/provider routing, fallback attempts, prompt resolution, asynchronous logging, body storage, ClickHouse analytics, datasets, and online evaluators.

For agentic coding, this maps cleanly to run observability. A Codex or SWE-agent-like system can tag each model/tool call with a session id, session path, repo, task id, branch, step type, and evaluator scores, then later query costs, failures, latency, and quality by workflow segment. Helicone already has a Codex AI Gateway integration, which makes it directly relevant as an instrumentation layer for coding agents even though it does not orchestrate agents.

## What It Is

Helicone is an open-source LLM observability and AI Gateway monorepo. The main runtime pieces are a Cloudflare Worker proxy/gateway, a Next.js web app, a Jawn API/log consumer service, Supabase/Postgres metadata storage, ClickHouse analytics storage, and S3/Minio raw body storage. Shared packages provide model registry, cost calculation, prompt helpers, filters, and provider mappers.

The gateway accepts OpenAI-compatible traffic and can route a single requested model across BYOK provider keys and Helicone managed "pass through billing" credits. It converts request and response formats across providers, logs every attempt, and later feeds the captured log through a Jawn handler chain that enriches request/response bodies, computes usage and cost, runs online evaluators, writes ClickHouse rows, and triggers webhooks or analytics sinks.

The eval surface is mostly observability-native: persisted evaluators, LLM-as-judge, Python-code evaluators, online sampled scoring, request scores, datasets built from request logs, and experiments/replays around prompt versions. It is closer to Langfuse/Opik production eval telemetry than to OpenAI Evals or SWE-bench style deterministic harnessing.

## Research Themes

- Token efficiency: Token-limit exception handlers support truncation, middle-out trimming, and fallback model selection. The cost registry tracks prompt cache read/write tokens, audio tokens, reasoning tokens, and per-provider pricing. This is useful for token/cost monitoring, but it is not a context-packing strategy for coding agents.
- Context control: Prompt management supports prompt ids, version ids, production/staging/development environments, S3-stored prompt bodies, partial prompt references, and typed input substitution. Session headers and custom properties give a lightweight control plane for grouping agent runs and steps.
- Sub-agent / multi-agent: Helicone does not orchestrate subagents. Its session path hierarchy can represent sub-agent traces, tool calls, and multi-step workflows if the caller provides stable `Helicone-Session-Id` and `Helicone-Session-Path` values.
- Domain-specific workflow: The core domain is LLM gateway, observability, cost monitoring, prompt management, datasets, and eval scoring. The Codex integration shows the gateway can be dropped in front of a coding agent with minimal config.
- Error prevention: The gateway uses provider fallbacks, BYOK/PTB attempt ordering, PTB payload validation, rate limits, disallow lists, prompt security/moderation hooks, cache controls, HQL read-only query constraints, and online evaluators. These reduce production failure modes but do not replace deterministic test execution.
- Self-learning / memory: Datasets and scores can turn production traces into eval sets or fine-tuning data. There is no autonomous memory update loop or self-improving coding-agent policy.
- Popular skills: Gateway routing, trace capture, prompt versioning, online evals, score storage, dataset curation, cost/latency analytics, privacy controls, and provider abstraction.

## Core Execution Path

1. A client sends an OpenAI-compatible request to a Helicone host such as `ai-gateway.helicone.ai`, `gateway.helicone.ai`, `oai.helicone.ai`, or a provider-specific proxy host.
2. `worker/src/index.ts` wraps the request in `RequestWrapper`, adjusts environment variables for path/region, selects the worker type from hostname/path, and builds the router.
3. For AI Gateway traffic, `worker/src/routers/aiGatewayRouter.ts` authenticates the Helicone API key, sets the request referrer to `ai-gateway`, applies Responses API body mapping when needed, and constructs `SimpleAIGateway`.
4. `SimpleAIGateway` parses the JSON body, resolves a model from `model` or `prompt_id`, compiles prompt bodies through `PromptManager`, parses comma-separated fallback models and `!provider` exclusions, applies plugins, builds attempts, validates PTB payloads, and loops through attempts until success or final error.
5. `AttemptBuilder` expands a requested model into BYOK and PTB attempts using provider keys, deployment ids, registry endpoints, priorities, explicit-provider routing, and pass-through support for unknown BYOK deployments.
6. `AttemptExecutor` prepares provider-specific request bodies, auth headers, target URLs, wallet escrow for PTB, provider timing spans, and calls `gatewayForwarder`.
7. The general proxy path uses `ProxyForwarder` and `ProxyRequestHandler` to apply cache/rate-limit/moderation checks, call the provider, wrap streams with time-to-first-token tracking, and return `Helicone-Id`, `Helicone-Status`, and AI Gateway metadata headers.
8. `DBLoggable` reads raw request/response bodies, extracts basic timing/usage where possible, stores raw bodies in S3 when enabled, and sends a log message through Kafka, SQS, or HTTP via `HeliconeProducer`.
9. Jawn consumes the log through `LogManager`: auth, rate limit, S3 body read, request body parsing, response body parsing, prompt handling, online eval handling, integrations, and final logging.
10. `LoggingHandler` writes request/response metadata to Postgres and ClickHouse. Small bodies can be stored directly in ClickHouse; larger bodies stay in S3. ClickHouse rows power cost, latency, session, user, prompt, score, and HQL analytics.

## Architecture

The monorepo has a clear split between edge proxy, API/consumer, UI, shared packages, and storage schemas.

- `worker/`: Cloudflare Worker proxy and gateway. It handles auth, routing, request conversion, response conversion, wallet escrow, caching, rate limiting, logging handoff, and DataDog gateway timing.
- `valhalla/jawn/`: Express/Tsoa API and log consumer. It owns controllers, managers, online evals, datasets, traces, scores, HQL, ClickHouse queries, and the log handler chain.
- `web/`: Next.js dashboard. It exposes the UI for prompts, evals, datasets, sessions, requests, providers, and analytics. I sampled only paths needed to confirm user-facing concepts.
- `packages/cost/`: Model registry, provider endpoints, pricing, request construction, usage processors, and cost calculation.
- `packages/prompts/`, `sdk/typescript/`, `sdk/python/`: Prompt pulling/compilation helpers shared between gateway and direct SDK usage.
- `docs/` and `bifrost/`: Product docs, integration guides, gateway docs, prompt docs, session docs, security docs, and examples.
- `supabase/`: Postgres migrations for prompts, evaluators, datasets, provider keys, experiments, scores, and app metadata.
- `clickhouse/`: Analytics schema migrations for request/response logs, sessions, costs, storage location, body mapping, and token fields.
- `e2e/` and `worker/test/`, `valhalla/jawn/src/**/__tests__`, `valhalla/jawn/src/lib/db/test/`: Tests for gateway behavior, token-limit handling, HQL isolation, request controllers, body processors, and stores.

The most important architectural choice is that the Worker stays on the latency-sensitive provider path, while Jawn performs heavier processing asynchronously after the response path. This is exactly the split an agent lab should want: low-overhead capture during a run, deeper enrichment and evaluation after the fact.

## Design Choices

Helicone uses headers as a control plane. Omit flags, session ids, session paths, custom properties, prompt metadata, rate-limit policy, cache settings, body mapping, and auth all flow through headers or gateway body fields. This makes instrumentation cheap for arbitrary clients, including coding agents, but puts discipline on the caller to provide stable metadata.

AI Gateway routing is attempt-based. Each attempt records source, auth type, provider, endpoint, provider key, deployment target, priority, and PTB escrow state. Explicit provider routes lock behavior; no-provider routes expand through the registry; comma-separated models preserve user fallback order; `!provider` syntax excludes providers globally.

Cost is registry-first. Worker-side gateway logging parses provider usage early for PTB settlement, and Jawn-side `ResponseBodyHandler` calculates `CostBreakdown` with registry usage processors. `LoggingHandler` writes cost as an integer using `COST_PRECISION_MULTIPLIER`. For new AI Gateway requests with a provider model id, missing registry cost becomes zero instead of falling back to legacy cost. That avoids wrong fallback estimates but can hide unsupported-model spend.

Latency is captured at multiple levels. Worker `GatewayMetrics` tracks prompt-request, pre-request, provider-request, post-request, total gateway latency, and provider 429 counts. Proxy stream handling tracks time to first token and total delay. ClickHouse stores latency and `time_to_first_token`, with managers for model comparison and time-series metrics.

Raw bodies are staged through object storage. The Worker can store raw request/response bodies to S3/Minio and emit a message; Jawn reads those bodies, parses them, and decides whether ClickHouse stores body text or just metadata and a storage location. This keeps ClickHouse analytics fast while retaining large raw payloads outside the hot table.

Prompt versions use metadata plus external body storage. `prompts_2025` and related tables track prompt id, model, environments, major/minor versions, production version, and input records. Prompt bodies live in S3, and the Worker caches resolved prompt bodies and versions with AES-GCM protected cache entries.

Online evals run inside the log pipeline. `OnlineEvalHandler` loads enabled evaluators, applies sample rate and property filters, skips evaluator/experiment recursion, runs evaluators, and inserts scores into the processed log before `LoggingHandler` writes ClickHouse. That makes evals first-class telemetry rather than a separate batch-only tool.

Security is layered but content-sensitive. Provider keys are role-gated through the Vault API and decrypted through server-side views for gateway use. Provider-bound requests strip all `helicone-*` headers. HQL is feature-flagged, SELECT-only, table-allowlisted, organization-scoped through ClickHouse settings, readonly, and covered by injection/isolation tests. Omit-log headers prevent long-term body storage but still send content through Helicone's backend for proxy integrations.

## Strengths

- Complete observable gateway path: request routing, provider attempt metadata, response mapping, streaming, cost, latency, TTFT, cache, session, prompt, and scores are all represented in the log model.
- Good agent trace primitive: sessions and session paths can express a full agent run, step hierarchy, tool calls, retries, and sub-agent branches without requiring Helicone to own orchestration.
- Practical provider abstraction: BYOK first, PTB fallback, explicit providers, custom deployments, unknown BYOK passthrough, provider exclusions, and response/body mapping cover real gateway use cases.
- Prompt versions are tied to runtime calls: prompt id, version id, environment, inputs, and compiled bodies flow through the gateway and logs, making prompt changes traceable to request outcomes.
- Cost and latency monitoring are detailed enough for coding-agent lab accounting: prompt/completion/cache/audio/reasoning tokens, cost precision, TTFT, total latency, provider latency, cache hits, provider/model breakdowns, and session cost rollups.
- Online eval design is reusable: sample rates, property filters, recursion avoidance, evaluator-specific managers, score maps, and delayed score writes are good patterns for production scoring.
- Dataset curation comes from real traces: requests can be copied into datasets with body preservation from S3 or ClickHouse, then exported or replayed for eval/fine-tune workflows.
- Security work is visible in code and tests: HQL guardrails, org isolation, provider header stripping, role-gated vault endpoints, encrypted cache entries, and omit-log handling are implemented rather than only documented.

## Weaknesses

- It is not a deterministic harness. There is no built-in coding task runner, repository sandbox, patch grading, unit-test executor, or reproducible benchmark protocol. Helicone observes and scores calls; another system must run the tasks.
- Evals and experiments straddle old and new prompt systems. New `prompts_2025` tables are well designed, but `ExperimentV2Manager` and related experiment paths still reference legacy prompt/input records. This increases migration risk for prompt-eval workflows.
- OTEL trace ingestion flattens spans and replaces the incoming trace id with a random UUID in `TraceManager.processOtelSpans`, which can break correlation with upstream traces and parent-child relationships.
- Python code evaluators execute user code through a sandbox pool with temp files and a timeout. This is powerful but high-risk; it needs strong isolation, resource limits, and operational scrutiny before copying.
- Omit-log headers are easy to misunderstand. Docs correctly state that proxy omit headers still send content to Helicone's backend, and the code still needs raw bodies in memory or transient storage for parts of processing. For highly sensitive coding-agent data, async logging with content tracing disabled is safer.
- The reviewed commit removes raw request/response body debug logs after they caused large CloudWatch ingestion and full payload logging. This is a concrete reminder that observability systems can accidentally become sensitive-data exfiltration sinks.
- Cost zeroing for AI Gateway when registry parsing fails avoids legacy mispricing, but a zero can look like free traffic unless dashboards distinguish unsupported cost from actual zero cost.
- Some HQL/system-table security tests are skipped, and controller tests include older expectations around multi-statement behavior. The main production guardrails are present, but the test story is not perfectly crisp.

## Ideas To Steal

- Use a simple header contract for agent traces: `Session-Id`, `Session-Path`, run name, step type, repo, task id, branch, model policy, and evaluator metadata.
- Model gateway routing as ordered attempts with explicit provider/model/auth/source fields. This makes fallback traces auditable instead of burying routing in conditionals.
- Put online evals in the log ingestion path, after request/response parsing and before final analytics write. Scores then become queryable alongside cost and latency.
- Store request/response bodies separately from analytics rows, and record `storage_location` and body size. This keeps analytics cheap while retaining deep-debug payloads when policy allows.
- Record prompt id, prompt version, prompt environment, and prompt inputs on every call that uses a managed prompt. This is the minimum viable audit trail for prompt changes.
- Treat cost and latency as first-class schema fields, not derived dashboard-only metrics. Add TTFT, cache tokens, reasoning tokens, audio tokens, and precision-scaled cost early.
- Maintain a provider/model registry with request builders, auth builders, endpoint builders, usage processors, context lengths, and pricing in one package.
- Add recursion guards to eval scoring so judge calls and experiment calls do not recursively trigger more online evals.

## Do Not Copy

- Do not copy the split between legacy prompt experiments and new prompt versions. A coding-agent lab should use one current prompt/run schema and migrate old data behind a compatibility layer.
- Do not randomize incoming OTEL trace ids if upstream trace correlation matters. Preserve original trace id/span id and generate an internal id separately if needed.
- Do not run arbitrary Python evaluators without a hardened sandbox, filesystem/network policy, CPU/memory limits, timeout enforcement, and audit logs.
- Do not let unsupported cost calculation silently look like true zero cost. Use an explicit `cost_status` or `cost_supported` field.
- Do not rely on debug logging discipline for privacy. Add automated redaction, structured log allowlists, and tests that fail if raw body fields are logged.
- Do not make evals UI-only or production-only. For coding agents, production telemetry should complement deterministic offline replay, repository fixtures, and test-result grading.
- Do not assume omit headers mean content never reaches the observability provider. Make the transport, transient processing, and storage guarantees explicit.

## Fit For Agentic Coding Lab

Fit is conditional and useful. Helicone should not be the primary harness for coding-agent evaluation, because it does not clone repos, run agents, execute tests, compare patches, or grade task success. It should be considered as an observability and eval-telemetry layer around such a harness.

Best application: route all coding-agent LLM calls through a gateway or manual logger and attach a stable run schema. Example dimensions: task id, repo, commit, branch, agent name, model policy, attempt number, tool name, session path, prompt version, verifier result, reviewer score, and final outcome. Helicone-like storage then answers questions that a harness usually struggles with: which workflow segment spent the most, which prompt version regressed, which model provider caused latency spikes, which fallback chain saved runs, and which evaluator score predicts test failures.

For Agentic Coding Lab, the most reusable subsystem is the trace and scoring pipeline: Worker-like low-latency capture, Jawn-like asynchronous enrichment, ClickHouse-like analytics, prompt version metadata, online eval scores, and dataset export. The harness, sandbox, replay, and grading pieces should remain separate and deterministic.

## Reviewed Paths

- `README.md`, `AGENTS.md`, `DEVELOPER_README.md`, `DIAGRAMS.md`, `INTEGRATE_PROVIDER_TO_GATEWAY.md`: Monorepo structure, local architecture, service boundaries, provider integration workflow, and generated-file rules.
- `worker/src/index.ts`, `worker/src/routers/*`: Host/path routing, Worker type selection, EU environment switching, AI Gateway entrypoint, OpenAI proxy route, generic gateway route, and target URL handling.
- `worker/src/lib/ai-gateway/ARCHITECTURE.md`, `SimpleAIGateway.ts`, `AttemptBuilder.ts`, `AttemptExecutor.ts`, `GatewayMetrics.ts`, `PluginHandler.ts`, `types.ts`: Actual AI Gateway request lifecycle, attempt construction, PTB escrow, provider forwarding, metrics, plugins, and error priority.
- `worker/src/lib/HeliconeProxyRequest/ProxyForwarder.ts`, `ProxyRequestHandler.ts`, `RequestWrapper.ts`, `ResponseBuilder.ts`, `worker/src/lib/models/HeliconeHeaders.ts`, `HeliconeProxyRequest.ts`: Proxy handling, cache/rate-limit/moderation hooks, streaming response interception, Helicone headers, body mapping, and provider header stripping.
- `worker/src/lib/dbLogger/DBLoggable.ts`, `worker/src/lib/managers/AsyncLogManager.ts`, `worker/src/lib/clients/ProviderClient.ts`, `worker/src/lib/clients/producers/HeliconeProducer.ts`, `worker/src/lib/managers/RequestResponseManager.ts`, `worker/src/lib/db/RequestResponseStore.ts`: Worker-side raw body capture, S3 storage, producer handoff, and provider fetch behavior.
- `valhalla/jawn/src/lib/handlers/*`, especially `HandlerContext.ts`, `LoggingHandler.ts`, `RequestBodyHandler.ts`, `ResponseBodyHandler.ts`, `S3ReaderHandler.ts`, `OnlineEvalHandler.ts`: Log ingestion pipeline, body parsing, cost calculation, storage policy, online scoring, ClickHouse row mapping, and integration fanout.
- `clickhouse/migrations/schema_30_request_response_versioned_merge_tree.sql`, `schema_41_request_response_replacing_merge_tree.sql`, `schema_49_sessions.sql`, `schema_50_sessions_mv.sql`, `schema_52_add_cost_to_request_response_rmt.sql`, `schema_74_add_ai_gateway_body_mapping.sql`, `schema_75_storage_location.sql`, `schema_76_size.sql`, `schema_78_reasoning_tokens.sql`: Analytics schema for requests, sessions, cost, body mapping, storage location, body size, and reasoning tokens.
- `worker/src/lib/managers/PromptManager.ts`, `worker/src/lib/db/PromptStore.ts`, `packages/prompts/HeliconePromptManager.ts`, `sdk/typescript/helpers/prompts/prompts.ts`, `sdk/python/helpers/helicone_helpers/prompt_manager.py`, `valhalla/jawn/src/controllers/public/prompt2025Controller.ts`, `valhalla/jawn/src/managers/prompt/PromptManager.ts`: Prompt version resolution, environment selection, body compilation, partial substitution, input recording, and SDK parity.
- `supabase/migrations/20250619011938_prompts_2025.sql`, `20250708225024_prompt_inputs.sql`, `20250731232202_prompt_environments.sql`, `20250731232203_prompt_environments_migration.sql`, `20260107000000_prompt_multi_environments.sql`: Current prompt schema and environment/version evolution.
- `valhalla/jawn/src/controllers/public/traceController.ts`, `traceManager.ts`, `customTraceManager.ts`, `types/customTrace.ts`, `utils/trace.proto`, `docs/features/sessions.mdx`, `docs/guides/cookbooks/ai-agents.mdx`: OTEL/custom trace ingestion, session path semantics, agent monitoring docs, and manual tool logging.
- `valhalla/jawn/src/controllers/public/evalController.ts`, `evaluatorController.ts`, `managers/eval/EvalManager.ts`, `managers/evaluator/EvaluatorManager.ts`, `pythonEvaluator.ts`, `lib/clients/LLMAsAJudge/LLMAsAJudge.ts`, `lib/stores/OnlineEvalStore.ts`, `lib/handlers/OnlineEvalHandler.ts`, `managers/score/ScoreManager.ts`: Score analytics, evaluator definitions, LLM-as-judge, Python evaluator, online eval sampling/filtering, and score writes.
- `valhalla/jawn/src/controllers/public/heliconeDatasetController.ts`, `managers/dataset/HeliconeDatasetManager.ts`, `controllers/public/experimentDatasetController.ts`, `managers/dataset/DatasetManager.ts`, `controllers/public/experimentV2Controller.ts`, `managers/experiment/ExperimentV2Manager.ts`, `lib/experiment/run.ts`: Dataset creation/query/export, S3 body copying, legacy dataset paths, and experiment/replay architecture.
- `supabase/migrations/20240813035740_helicone-dataset-row.sql`, `20241008213149_evaluator.sql`, `20241212204905_online_evaluators.sql`, `20241123205152_evaluators-experiments-v3.sql`, `20240412000067_prompts-experiments.sql`, `20250101215229_evals.sql`: Dataset, evaluator, online eval, and experiment persistence.
- `valhalla/jawn/src/controllers/public/vaultController.ts`, `valhalla/jawn/src/managers/VaultManager.ts`, `worker/src/lib/db/ProviderKeysStore.ts`, `worker/src/lib/util/cache/secureCache.ts`, `valhalla/jawn/src/controllers/public/heliconeSqlController.ts`, `valhalla/jawn/src/managers/HeliconeSqlManager.ts`, `valhalla/jawn/src/lib/db/ClickhouseWrapper.ts`: Provider key access, encrypted caches, HQL query validation, org scoping, and ClickHouse security settings.
- `docs/gateway/overview.mdx`, `provider-routing.mdx`, `prompt-integration.mdx`, `integrations/codex.mdx`, `docs/guides/cookbooks/cost-tracking.mdx`, `docs/references/how-we-calculate-cost.mdx`, `docs/references/latency-affect.mdx`: Product-facing gateway, Codex, cost, and latency docs cross-checked against code.
- `docs/features/datasets.mdx`, `docs/guides/cookbooks/helicone-evals-with-ragas.mdx`, `docs/features/advanced-usage/prompts/overview.mdx`, `docs/features/advanced-usage/prompts/sdk.mdx`, `docs/features/advanced-usage/omit-logs.mdx`, `docs/faq/how-encryption-works.mdx`: Dataset, external eval, prompt, omit-log, and encryption docs.
- `worker/test/ai-gateway/test-framework.ts`, `prompt-model.spec.ts`, `prompt-model-extensive.spec.ts`, `byok-ptb-priority.spec.ts`, `provider-ignore.spec.ts`, `ptb-validation.spec.ts`, `map-responses.spec.ts`, `bail-429.spec.ts`, `worker/test/token-limit-exception/tokenLimitException.spec.ts`: Gateway test harness, prompt model resolution, fallback ordering, provider exclusion, PTB validation, Responses API mapping, rate-limit bail behavior, and token-limit strategies.
- `valhalla/jawn/src/lib/db/test/hqlSecurityTests.test.ts`, `TestClickhouseWrapper.ts`, `valhalla/jawn/src/controllers/public/__tests__/heliconeSqlController.test.ts`, `valhalla/jawn/src/lib/handlers/__tests__/HandlerContext.test.ts`, body processor tests: HQL isolation/injection/resource tests and representative Jawn request/log processing tests.

## Excluded Paths

- `web/` UI pages and components were not deeply reviewed except where needed to understand prompts, evals, datasets, sessions, providers, and generated API types. The review focus was backend architecture and execution path, not dashboard UX.
- `bifrost/` marketing/docs app implementation was not deeply reviewed. Relevant docs content under `docs/` was reviewed directly; static site rendering is UI-only for this task.
- `docs/images/`, `web/public/`, `bifrost/public/`, videos, screenshots, and other static media were excluded as binary or presentation assets.
- Generated API/type outputs called out by repo instructions were excluded: `valhalla/jawn/src/tsoa-build/`, `web/lib/clients/jawnTypes/`, `bifrost/lib/clients/jawnTypes/`, `supabase/database.types.ts`, `worker/supabase/database.types.ts`, and `web/db/database.types.ts`.
- Dependency and build artifacts were excluded: `node_modules/` if present, package manager caches, `.next/`, build outputs, and lockfile-level dependency expansion. `yarn.lock` was not read beyond recognizing dependency management.
- Broad provider registry data under `packages/cost/models/` was not exhaustively enumerated. I reviewed the registry integration points and tests rather than every provider price row.
- Most dashboard-only tests and end-to-end browser tests were excluded. I reviewed gateway, token-limit, HQL, and handler tests because they validate execution/security behavior relevant to observability and eval architecture.
- Infrastructure-only paths such as `docker/`, `replicas/`, deployment manifests, local seed data, and non-core scripts were excluded unless they explained storage topology. The deep review centered on runtime request, trace, eval, prompt, cost, and logging behavior.
- Legacy or unrelated app areas such as broad customer/admin/reporting views, marketing content, and non-LLM product copy were excluded unless their managers directly consumed request, score, session, or cost data.
