# openlit/openlit

- URL: https://github.com/openlit/openlit
- Category: error-prevention
- Stars snapshot: 2,454 on 2026-05-19 via GitHub API
- Reviewed commit: 7ca59852f63177cdfd8f5b40924b6126c7b37fcc
- Reviewed at: 2026-05-19
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong source for trace-first LLM error prevention patterns: instrumentation, guard phases, offline/automatic evals, prompt and rule control, agent version fingerprints, and controller-managed rollout safeguards. Do not adopt the full platform wholesale unless the lab needs a complete observability/control plane.

## Why It Matters

OpenLIT is an open-source AI engineering platform around observability, evaluations, guardrails, prompt management, secrets, and collector/controller operations. For Agentic Coding Lab, its value is not a better coding agent loop; it is the safety layer around agent execution: capture what happened, fingerprint the agent configuration, apply preflight/postflight guards, attach context and eval policy by rule, and preserve enough telemetry to debug bad tool calls or regressions.

The repository is useful because the prevention path is executable and end-to-end. SDKs instrument real LLM/framework calls, server APIs resolve prompts/secrets/rules/evals with API-key auth, and the controller has concrete safeguards for auto-instrumenting live workloads.

## What It Is

OpenLIT provides Python, TypeScript, and Go SDKs plus a Next.js/Prisma/ClickHouse application, a Go controller, and an OpAMP server. The SDKs initialize OpenTelemetry traces, metrics, and events, dynamically wrap supported LLM providers and agent frameworks, and optionally install guard pipelines. The server stores and serves prompts, vault secrets, rule-engine entities, evaluation configuration, and controller actions. The controller discovers workloads and can inject OpenLIT/OTel instrumentation into Python services with rollback-aware runtime operations.

The Python and TypeScript SDKs are the most relevant paths for agent error prevention. The Go SDK is narrower: OTel-native instrumentation for OpenAI and Anthropic plus rule-engine support, but not parity for all guard/eval/prompt/vault behavior.

## Research Themes

- Token efficiency: Tracks prompt/completion tokens, total tokens, cost, time-to-first-token, and inter-token timing. It helps identify waste and regressions but does not implement compression, summarization, or context packing.
- Context control: Rule engine maps trace/request attributes to contexts, prompt versions, and evaluation configs. Prompt Hub versions prompt text, compiles `{{variable}}` replacements, and records download metadata. SDK capture controls and max-content truncation bound telemetry size and sensitivity.
- Sub-agent / multi-agent: SDKs expose agent context, agent version context, agent invocation metrics, and tool-error metrics. Instrumentors cover OpenAI Agents, LangGraph, CrewAI, MCP, and related frameworks, but OpenLIT observes agents rather than orchestrating them.
- Domain-specific workflow: Strong AI operations workflow: LLM/provider traces, MCP/tool telemetry, eval result storage, guard results, prompt/version metadata, Vault-backed provider credentials, controller actions, and collector management.
- Error prevention: Core fit. Prevention comes from preflight/postflight guards, schema checks, PII/prompt-injection/moderation/topic guards, offline and auto evals, exception/status capture, rule-selected context/eval policy, prompt versioning, and controlled instrumentation rollout.
- Self-learning / memory: Stores traces, eval results, feedback, prompt downloads, and rule context, but does not implement autonomous learning or durable agent memory retrieval beyond explicit rule/context entities.
- Popular skills: Observability, eval harnesses, guardrails, prompt management, secret retrieval, controller-managed instrumentation, safe rollout/rollback, MCP and agent telemetry.

## Core Execution Path

Application code calls `openlit.init()` in Python or `Openlit.init()` in TypeScript. Config is merged from explicit options and environment variables such as OTLP endpoint, service name, disabled instrumentors, message capture, controller mode, and custom attributes. The SDK sets up OTel tracing/events/metrics, fetches pricing data when configured, and loads instrumentors for installed modules. Missing modules are skipped; instrumentation failures are logged instead of stopping the app.

LLM/provider wrappers create spans and metrics around real calls. OpenAI paths capture model, provider, request parameters, token usage, cost, streaming timings, tool definitions, tool calls, system instructions, and errors. Content capture is controlled by config; when enabled it records prompt/response content, and when disabled it still records structured metadata such as version hashes and tool schema information. Exceptions are recorded on spans, `error.type` is set, and metrics include error dimensions.

Guard integration is installed after normal instrumentors. For supported provider methods, OpenLIT extracts input text, runs preflight guards, optionally rewrites redacted request fields, calls the provider, extracts output text, then runs postflight guards and optionally rewrites response content. `deny` short-circuits with `GuardDeniedError`; `warn` records events; `redact` mutates text; `allow` passes through. `fail_open` defaults to true, so guard failures allow traffic unless strict mode is chosen.

SDK feature calls use the OpenLIT URL and API key. `get_prompt()` posts to `/api/prompt/get-compiled`, `get_secrets()` posts to `/api/vault/get-secrets`, `evaluate_rule()` posts to `/api/rule-engine/evaluate`, and offline evals post to `/api/evaluation/offline`. Server routes map the bearer API key to a database config, validate input, and delegate to platform libraries. The rule engine evaluates active rules against supplied attributes, returns matching contexts/prompts/evaluation entities, and can compile prompt versions. The eval engine combines requested/default eval types, rule-matched context, and provider-backed LLM-as-judge calls, then stores results in ClickHouse when enabled.

The controller path runs separately. The Go controller polls `/api/controller/poll`, reports discovered services and states, receives actions, and can inject Python SDK instrumentation. It performs duplicate OTel/OpenLIT preflight checks, sets controller-specific env vars, disables duplicate-prone instrumentors, patches Kubernetes or Docker workloads, and reports success/failure back to the server.

## Architecture

The SDK layer is a set of OTel-first wrappers plus feature clients. Python uses dynamic instrumentor discovery from `_instrumentors.py` and shared config/context helpers. TypeScript mirrors the model with wrapper modules and async initialization. Go is OTel-native but narrower. Shared concepts are service identity, deployment environment, message capture controls, pricing, token/cost metrics, agent attributes, and rule/eval/prompt/vault clients.

The platform layer is a Next.js application with API routes under `src/client/src/app/api`, domain logic under `src/client/src/lib/platform`, Prisma for application metadata, ClickHouse for traces/rules/eval data, and Vault encryption utilities. Middleware separates session-protected UI routes from API-key-protected SDK routes. The evaluation stack calls configured model providers using Vault-resolved secrets.

The operations layer includes `openlit-controller` and `src/opamp-server`. The controller discovers workloads, manages SDK injection, lifecycle actions, and OBI integration. The OpAMP server manages collector connections and in production can require TLS and client certificates.

## Design Choices

Instrumentation is fail-soft. If an instrumentor cannot load or a pricing fetch fails, the app keeps running and logs the issue. This is good for deployability but means safety-critical deployments must enable strict guard behavior and verification externally.

OpenLIT treats observability metadata as prevention input. Agent version hashes are computed from system prompt, tools, primary model, and decoding parameters, giving later evals and incident analysis a stable fingerprint for "which agent shape produced this behavior."

Guards are phase-aware and composable. Preflight and postflight are explicit, severity determines final action, deny short-circuits, redaction can chain, and fail-open/fail-closed is a first-class pipeline option. The built-in guards are intentionally local and simple: regex PII/secrets, prompt-injection patterns, moderation terms, sensitive topics, topic restriction classifier hooks, custom predicates, and JSON/schema validation.

Rule engine and evals are externalized from code. A request can supply primitive trace fields, and active rules can return contexts, prompts, or evaluation configs. This lets a lab route different repos, languages, agents, or risk classes to different prompts and eval checks without redeploying the agent runtime.

Controller-managed instrumentation is guarded by preflight and rollback logic. It blocks or adopts existing OpenTelemetry/OpenLIT setups depending on duplicate policy, marks managed workloads with annotations/config hashes, preserves workload identity for stop/start actions, and defers action completion if important lifecycle snapshots fail to persist.

## Strengths

- End-to-end traceability for LLM, agent, tool, MCP, vector DB, and provider calls, with exception capture and `error.type` dimensions.
- Agent version fingerprints connect behavior to prompt/tools/model/temperature changes, which is directly useful for regression triage.
- Guard pipeline has practical semantics: preflight/postflight phases, warn/redact/deny actions, short-circuit deny, metrics, span events, and configurable fail-open/fail-closed behavior.
- Offline and auto eval APIs allow prompt/response pairs and trace spans to be judged using the same configured eval types and contexts.
- Rule engine links runtime attributes to contexts, prompts, and eval policy, which is a useful pattern for repo-specific or task-risk-specific prevention.
- Vault-backed provider credentials and prompt version metadata reduce ad hoc secret and prompt sprawl.
- Controller code shows mature operational safety patterns: duplicate instrumentation detection, rollback attempts, snapshot-before-stop, stable workload keys, and explicit conflict status.

## Weaknesses

- Built-in guard accuracy is shallow. Prompt-injection and moderation checks are mostly regex/keyword based unless the user supplies classifier callbacks. These are useful tripwires, not robust adversarial defenses.
- `guard_fail_open` defaults to true in the Python SDK. That is reasonable for availability, but unsafe as the default posture for high-risk actions unless the lab wraps it with stricter policy.
- Streaming postflight guards are explicitly skipped because chunks are not reassembled. Preflight still runs, but unsafe generated streaming output can bypass postflight checks.
- Evaluation is LLM-as-judge and not on the serving path by default. `runEvaluation()` asks for JSON and parses model output, but it does not use constrained decoding, schema enforcement, or repair loops.
- Prompt compilation is simple string replacement of `{{variable}}`; there is no missing-variable failure mode, typed prompt contract, escaping policy, or canary/rollback semantics.
- API keys appear stored as plaintext values in Prisma, with no hashing, expiry, or fine-grained scopes in the reviewed path.
- Controller poll has a bootstrap convenience mode that allows unauthenticated polling when no API keys exist. Useful for first setup, but risky if exposed before onboarding is complete.
- Cron route protection checks for presence of `X-CRON-JOB` rather than a shared secret value, and the auto-evaluation route contains a note to verify cron job requests.
- Default message content capture is on. The SDK has controls to disable capture and truncate content, but sensitive deployments need an explicit redaction and retention posture.
- OpAMP documentation/defaults are inconsistent: the integrated Docker path sets production-style TLS defaults, while code defaults to development unless env overrides are present and the standalone README says no TLS by default.

## Ideas To Steal

- Add an agent-run fingerprint that hashes system prompt, tool definitions, model, provider, temperature/top-p, and max tokens, then attach it to every trace, eval, and incident.
- Treat guard output as structured telemetry, not just a thrown error: record guard name, phase, action, severity, latency, matched labels, and redaction counts.
- Split guard phases into preflight and postflight and make streaming limitations explicit in code and UI.
- Use a rule engine to choose repo-specific context, prompts, and eval suites from run attributes such as repo, language, risk class, agent version, branch, and command type.
- Make evals reusable across offline datasets and production traces. Store source, trace/span IDs, context IDs, rule IDs, score, verdict, model, and cost.
- Build controller operations with preflight conflict detection, managed annotations, config hashes, stable workload keys, snapshot-before-stop, and retryable completion.
- Keep observability fail-soft but policy fail-closed for high-risk tool calls. OpenLIT exposes both patterns; Agentic Coding Lab should choose by action risk.

## Do Not Copy

- Do not rely on regex prompt-injection detection as the primary barrier for autonomous code-editing agents.
- Do not use plaintext API key storage for lab credentials; hash keys, add scopes, and support rotation/expiry.
- Do not copy naive prompt variable replacement for critical prompts. Use typed templates, missing-variable failures, and escaping rules.
- Do not allow unauthenticated controller bootstrap behavior on exposed networks.
- Do not use header-presence cron authentication for sensitive jobs; require a secret or platform-native signed scheduler identity.
- Do not assume postflight checks protect streaming output unless chunks are buffered and checked before user/tool release.
- Do not leave message content capture enabled by default for sensitive repositories without PII/secret redaction and retention limits.

## Fit For Agentic Coding Lab

OpenLIT is in-scope as an error-prevention reference. It is not a coding-agent framework, but it supplies practical patterns around the agent: trace-first evidence, guard phases, eval storage, rule-selected policy, prompt/version control, secret retrieval, and safe runtime instrumentation.

The best fit is selective adoption. Agentic Coding Lab should borrow the instrumentation schema, agent fingerprinting, guard pipeline semantics, rule-to-eval/context matching, and controller preflight/rollback ideas. It should avoid adopting the whole platform unless the lab needs a full observability UI, ClickHouse-backed trace store, and controller management plane.

For a coding-agent lab, the most direct adaptation is: every agent run emits a version hash and structured trace; risky actions go through fail-closed preflight guards; generated patches and command outputs go through postflight/eval checks; rule metadata selects repo-specific policies; and failures produce stored evidence suitable for regression tests.

## Reviewed Paths

- `README.md`: product scope, SDK initialization, feature list, supported integrations, and evaluation/guard/prompt/vault positioning.
- `sdk/python/src/openlit/__init__.py`: public SDK API, initialization path, instrumentor loading, guard setup, and feature clients.
- `sdk/python/src/openlit/_instrumentors.py`: provider/framework module map and dynamic instrumentation strategy.
- `sdk/python/src/openlit/_config.py`, `sdk/python/src/openlit/cli/config.py`, `sdk/python/src/openlit/cli/bootstrap/sitecustomize.py`: environment config, CLI bootstrap, controller mode, capture controls, and fail-soft startup.
- `sdk/python/src/openlit/__helpers.py`: exception handling, context attributes, agent version hashing, content truncation, pricing fetch, MCP metrics.
- `sdk/python/src/openlit/otel/tracing.py`, `sdk/python/src/openlit/otel/metrics.py`: OTel provider setup and core LLM/agent/guard metrics.
- `sdk/python/src/openlit/instrumentation/openai/openai.py`, `sdk/python/src/openlit/instrumentation/openai/utils.py`: representative provider wrapper for spans, token/cost metrics, streaming timings, tool calls, errors, and content capture.
- `sdk/python/src/openlit/guard/_base.py`, `sdk/python/src/openlit/guard/_pipeline.py`, `sdk/python/src/openlit/guard/_integration.py`: guard model, pipeline execution, provider integration, deny/redact/warn behavior, and streaming caveat.
- `sdk/python/src/openlit/guard/*.py`: PII, prompt-injection, moderation, schema, sensitive-topic, topic-restriction, and custom guard implementations.
- `sdk/python/src/openlit/evals/offline.py`, `sdk/python/src/openlit/evals/_types.py`: offline eval client behavior, retries, auth errors, batch validation, and result semantics.
- `sdk/python/tests/test_guard_integration.py`, `sdk/python/tests/test_offline_eval.py`: guard/eval behavior coverage.
- `sdk/typescript/src/index.ts`, `sdk/typescript/src/config.ts`, `sdk/typescript/src/instrumentation/openai/wrapper.ts`, `sdk/typescript/src/instrumentation/base-wrapper.ts`: TypeScript SDK init, config, representative instrumentation, error handling, and version metadata.
- `sdk/typescript/src/guard/base.ts`, `sdk/typescript/src/guard/pipeline.ts`, `sdk/typescript/src/guard/integration.ts`, `sdk/typescript/src/guard/__tests__/*.ts`: TypeScript guard model, provider wrappers, and pipeline tests.
- `sdk/typescript/src/evals/offline.ts`, `sdk/typescript/src/evals/types.ts`, `sdk/typescript/src/features/rule-engine.ts`, `sdk/typescript/src/features/__tests__/rule-engine.test.ts`: TypeScript offline eval and rule-engine clients.
- `sdk/go/README.md`, `sdk/go/openlit.go`, `sdk/go/config.go`, `sdk/go/rule_engine.go`: Go SDK scope, config, and rule-engine support.
- `src/client/src/app/api/evaluation/offline/route.ts`, `src/client/src/lib/platform/evaluation/index.ts`, `src/client/src/lib/platform/evaluation/run-evaluation.ts`, `src/client/src/lib/platform/evaluation/config.ts`, `src/client/src/constants/evaluation-types.ts`: server-side eval execution, provider choice, config, storage, and auto-eval flow.
- `src/client/src/app/api/rule-engine/evaluate/route.ts`, `src/client/src/lib/platform/rule-engine/evaluate.ts`, `src/client/src/types/rule-engine.ts`, `src/client/src/helpers/server/rule-engine.ts`: rule input validation, ClickHouse evaluation, entity retrieval, and preview semantics.
- `src/client/src/app/api/prompt/get-compiled/route.ts`, `src/client/src/lib/platform/prompt/compiled.ts`, `src/client/src/helpers/server/prompt.ts`: prompt retrieval, API-key auth, metadata, and compile behavior.
- `src/client/src/app/api/vault/get-secrets/route.ts`, `src/client/src/lib/platform/vault/index.ts`, `src/client/src/utils/crypto.ts`, `src/client/src/lib/platform/api-keys/index.ts`: secret retrieval, encryption, CORS, and API-key handling.
- `src/client/src/middleware.ts`, `src/client/src/middleware/check-auth.ts`, `src/client/src/middleware/check-csrf.ts`, `src/client/src/constants/route.ts`, `src/client/src/lib/auth.ts`: route protection, public SDK endpoints, cron checks, CSRF exemptions, and session auth.
- `src/client/src/app/api/controller/poll/route.ts`: controller polling, API-key/bootstrap auth, service/action state, lifecycle snapshot persistence, and completion semantics.
- `openlit-controller/cmd/controller/main.go`, `openlit-controller/internal/config/config.go`, `openlit-controller/internal/openlit/client.go`: controller configuration, polling loop, HTTP client, and action dispatch.
- `openlit-controller/internal/engine/engine.go`, `openlit-controller/internal/engine/python_sdk.go`, `openlit-controller/internal/engine/python_sdk_runtime.go`, `openlit-controller/internal/engine/lifecycle.go`: workload discovery, Python SDK injection, duplicate detection, rollback, and lifecycle stop/start safeguards.
- `openlit-controller/internal/engine/*_test.go`: controller behavior tests for injection, lifecycle, and event flows.
- `OPAMP_DEPLOYMENT.md`, `env.example`, `docker-compose.yml`, `src/opamp-server/config/config.go`, `src/opamp-server/server/server.go`, `src/opamp-server/certman/*.go`: OpAMP deployment security, TLS/mTLS config, and cert validation.
- `examples/`: sample apps for provider, agent, Kubernetes, Linux, and SDK usage were skimmed to confirm usage patterns rather than core logic.

## Excluded Paths

- `src/client/src/clickhouse/seed-data/*`: dashboard seed JSON and generated UI query/layout data; not core prevention logic.
- UI-only pages/components under `src/client/src/app` and `src/client/src/components`: visual dashboard and management surfaces were excluded except API routes and platform libraries that execute eval/rule/prompt/vault/controller behavior.
- `docs/images`, `assets/*`, logos, screenshots, and other static media: binary/static documentation assets, not execution paths.
- `sdk/typescript/tsconfig.tsbuildinfo`: generated TypeScript build cache.
- `openlit-controller/controller`, `src/opamp-server/opamp-server`, and other built binaries: generated build artifacts.
- `openlit-controller/.obi-src` and vendored/patch material such as `patches/*.patch`: external or generated instrumentation source not needed for the OpenLIT error-prevention design review.
- Exhaustive per-provider instrumentation wrappers beyond representative OpenAI and shared base paths: most provider wrappers repeat the same span/metric/error pattern; module maps and tests were enough to assess coverage.
- `opentelemetry-gpu-collector`: infrastructure/GPU telemetry is useful operationally but not central to LLM/agent error prevention.
- Governance and repository process files such as `.github`, `CODE_OF_CONDUCT.md`, `CONTRIBUTING.md`, and `SECURITY.md`: relevant to project process, not runtime prevention behavior.
