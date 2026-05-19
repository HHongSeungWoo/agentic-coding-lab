# Portkey-AI/gateway

- URL: https://github.com/Portkey-AI/gateway
- Category: error-prevention
- Stars snapshot: 11,672 (GitHub REST API repository search, captured 2026-05-11)
- Reviewed commit: d2ea41f4e17c65112b6289a939014bd6b1df62da
- Reviewed at: 2026-05-19
- Status: reviewed
- Scope fit: conditional
- Verdict: Strong reference for LLM error-prevention mechanics: config-driven retries, fallbacks, timeouts, guardrails, response validation, trace headers, and local logs. Conditional fit because it is a production LLM gateway, not an agent-coding framework; borrow the workflow patterns, not the broad provider surface.

## Why It Matters

Portkey's gateway places failure policy outside application code. A request carries a config envelope that can add retries, fallback targets, load balancing, conditional routing, cache settings, request timeouts, input guardrails, output guardrails, and provider-specific overrides. That is directly relevant to Agentic Coding Lab because coding agents need the same separation: "what to do if the model/tool/check fails" should be declarative, logged, and reusable instead of hidden in ad hoc loops.

The most useful design is the actual execution path: validate config early, normalize it into a recursive target tree, execute pre-request checks, transform the request for a provider, apply cache and budget validators, retry transient failures, validate the response, optionally retry on guardrail failure, and emit traceable outcome headers/logs.

## What It Is

Portkey Gateway is a TypeScript/Hono service for routing OpenAI-compatible requests to many LLM providers. It supports Node and Cloudflare Workers entrypoints, provider adapters, a config schema, recursive routing strategies, hook-based guardrails, request/response transformations, local cache middleware, and a local log console.

The reviewed repo includes open-source gateway code plus many cookbook examples. Several README claims point to hosted or enterprise features such as RBAC, virtual-key management, semantic cache, and MCP Gateway. In this checkout, those are mostly external to the reviewed execution path; the visible open-source path provides the routing, retry, guardrail, provider, cache, and local logging mechanisms.

## Research Themes

- Token efficiency: Indirect. Cache support can avoid repeat calls, and response transforms normalize usage fields, but the gateway does not solve context compression or code-agent token budgets.
- Context control: Strong for request/response envelopes. Hooks receive structured request JSON, response JSON, text extraction, metadata, provider, request type, and headers; mutators can transform the active request/response context.
- Sub-agent / multi-agent: Weak as a direct pattern. The target tree can inspire routing among models/tools/subagents, but there is no multi-agent planner.
- Domain-specific workflow: Strong provider/domain adapter pattern. Each provider maps a common request shape into provider-specific headers, endpoints, request bodies, and response transforms.
- Error prevention: Primary fit. Early schema validation, SSRF-conscious custom-host validation, retry policies, fallback trees, request timeouts, guardrails, plugin checks, cache bypass lists, and trace headers all reduce or expose failure.
- Self-learning / memory: Limited. Cache backends exist, but no self-improving memory or feedback loop was found in the core gateway path.
- Popular skills: Routing configs, retry/fallback policy, guardrail checks, webhook checks, regex/redaction mutators, JSON schema validation, model allow rules, metadata requirements, JWT verification, cache status, and traceable logs.

## Core Execution Path

`src/start-server.ts` starts the Node server, optional static local console, SSE log stream, and WebSocket realtime route. `src/index.ts` builds the Hono app, attaches compression, pretty JSON, local logging on Node, hooks, optional memory cache, global error handling, route handlers, and proxy fallbacks.

For standard routes such as `/v1/chat/completions`, a request first passes `requestValidator`. The validator rejects unsupported content types, missing `x-portkey-config`/`x-portkey-provider`, invalid provider names, invalid JSON config, unsupported old config shape, recursive config schema errors, unsafe custom hosts, and recursive forwarding of the forward-header control header. The custom-host validator is notably defensive: it blocks unsafe schemes, credentials, Portkey API hosts, cloud metadata endpoints, private/reserved IPs, alternative IP forms, suspicious hostname characters, excessive subdomain depth, internal TLDs, and invalid ports unless explicitly trusted.

Handlers parse the body, call `constructConfigFromRequestHeaders`, and then call `tryTargetsRecursively`. Config is converted from snake_case to camelCase while preserving selected nested keys. If config omits a provider/targets, the handler injects provider and API key from headers. The recursive router supports `fallback`, `loadbalance`, `conditional`, and `single` strategy modes. Fallback iterates targets and stops on success or on gateway exceptions; loadbalance chooses by weight; conditional routing evaluates metadata, params, or URL path with operators such as `$eq`, `$ne`, `$gt`, `$in`, and `$regex`; single unwraps its first target.

Leaf execution happens in `tryPost`. It creates a `RequestContext`, normalizes retry settings, builds a `HooksService` span, validates provider existence through `ProviderContext`, creates a log object, and computes the provider URL. Synchronous before-request hooks run first. A denying guardrail returns status `446` with `hook_results`; a mutating hook updates the request JSON before provider transformation.

The request is transformed through provider configs, headers are built with selected forwarded headers, cache is checked, and an injected `preRequestValidator` can stop the request for hosted features such as budgets or virtual-key limits. The actual provider call goes through `retryRequest`, which retries configured status codes, can honor provider retry-after headers with a 60 second cap, and converts request timeout aborts into status `408`.

After the provider response, `responseHandler` maps provider responses back to the gateway shape, including streaming, audio, image, text, binary, and JSON paths. Synchronous after-request hooks validate or mutate the mapped response. Hard denials return `446`; soft hook failures on successful responses return status `246`. If the after-hook response status is configured as retriable, `recursiveAfterRequestHookHandler` retries the provider call and re-runs after hooks. `ResponseService` adds headers for retry attempts, trace ID, last-used target path, cache status, and provider. `LogObjectBuilder` stores request/response/cache/hook metadata for local log streaming.

## Architecture

The gateway is organized around small services that keep cross-cutting failure logic explicit:

- Hono app and route handlers: parse request bodies and invoke the shared recursive target executor.
- Config schema and header parser: validate and normalize the external policy envelope.
- Recursive target tree: represent nested single, fallback, loadbalance, and conditional routing in one execution function.
- RequestContext: centralize params, overrides, retry defaults, cache settings, metadata, forwarding, custom host, timeout, streaming, strict compliance, and hook lists.
- ProviderContext and provider registry: isolate provider URL/header/body/response differences from routing policy.
- HooksManager and plugins: execute guardrails/mutators with structured context and produce stable hook results.
- Retry handler: isolate timeout, retry status, provider retry-after, and retry exhaustion accounting.
- Response service and log service: attach outcome headers and collect traceable request/response records.
- Cache service: avoid provider calls on cache hits and explicitly exclude side-effect endpoints.

## Design Choices

Portkey treats reliability policy as data. `retry`, `cache`, `request_timeout`, `forward_headers`, `custom_host`, guardrails, and target strategies are inherited down nested target groups with child values overriding parent values. This keeps complex routing readable without duplicating every setting on every leaf.

Guardrails are split into before-request and after-request hooks. Before hooks can block unsafe input before spend occurs; after hooks can validate generated output and trigger a retry if the user configured hook-failure status codes as retriable. The `deny` flag separates "record failure" from "stop the request."

The gateway distinguishes gateway exceptions from provider failures. `GatewayError` paths add `x-portkey-gateway-exception: true`, and fallback stops on that header. This prevents a malformed local config or unsupported endpoint from being hidden by fallback to another model.

Response metadata is first-class. Every response gets retry-attempt count, trace ID, last-used option path, optional cache status, and provider. This is a practical pattern for debugging opaque model/tool behavior.

Provider adapters use declarative parameter maps with defaults, min/max clamping, required defaults, endpoint builders, header builders, request handlers, and response transforms. This makes provider-specific failures local instead of spreading conditionals through the gateway.

## Strengths

The strongest pattern is the full lifecycle: validate, route, guard, transform, cache, budget-check, retry, response-map, output-guard, retry-on-validation, log. That is the kind of end-to-end error-prevention loop coding agents usually lack.

The config validator catches many bad requests before reaching provider code. The custom-host validator is unusually thorough for a gateway feature that accepts user-configured URLs.

The guardrail result model is transparent. Responses can include before/after hook results, check-level data, execution times, transformed flags, and failure explanations. This makes policy failure inspectable rather than a generic "blocked" error.

Retries are bounded and observable. Timeout becomes a structured `408`, provider retry-after is capped, and exhausted retries are represented with `x-portkey-retry-attempt-count: -1`.

The test suite covers important paths: retry status handling, timeout behavior, before-hook denial, after-hook retry, request mutation through hooks, cache hit/miss headers, and non-cacheable endpoints.

## Weaknesses

Several marketed features are outside the reviewed open-source execution path. MCP Gateway, RBAC, hosted virtual-key governance, semantic cache behavior, and analytics mostly appear as README/docs claims or injected callbacks, not as complete local code in the gateway path.

The config schema accepts hook objects with broad catchall shapes, so many check parameter mistakes are found only at runtime. Also, check execution errors do not necessarily fail the request unless the check config opts into failure behavior.

The source contains repeated provider comments noting that maximum-token enforcement is not implemented in many provider configs. For coding-agent safety, provider parameter maps alone are not enough as hard quota guards.

Local logging is useful but risky as a pattern. Log objects include transformed request bodies, headers, original responses, provider options, and cache keys. A lab adaptation needs redaction by default.

Fallback and load balancing are simple. There is no deterministic routing seed for reproducible evaluations, and health/circuit-breaker behavior is only exposed through optional context callbacks rather than a visible complete mechanism.

The default webhook guardrail validates URL syntax but does not appear to reuse the stricter custom-host SSRF validation. Any adaptation that lets users configure external checks should enforce the same network policy everywhere.

Local cache middleware is simple in-memory caching. The docs discuss semantic cache, but this checkout's directly reviewed middleware does not implement semantic similarity.

## Ideas To Steal

Use a declarative failure-policy envelope for agent runs. A coding task could carry `{retry, fallback_tools, timeout, input_checks, output_checks, cache, trace_id}` instead of scattering those decisions through tool wrappers.

Represent model/tool/subagent fallback as a recursive target tree. Leaf nodes run an executor; interior nodes describe fallback, weighted canary routing, conditional routing, and inherited constraints.

Adopt two-phase guardrails. Before-run checks block or mutate risky inputs; after-run checks validate outputs and can request a retry with more constrained context.

Keep hard and soft policy failures distinct. Portkey uses `446` for hard denial and `246` for soft hook failure. Agentic Coding Lab should use typed outcomes rather than these exact non-standard HTTP statuses, but the distinction is valuable.

Add trace headers/fields to every agent step: trace ID, retry count, last-used target path, cache status, policy result, and provider/tool ID. This makes failure triage cheap.

Make hook results structured artifacts. Each check should return verdict, error, data, transformed flag, execution time, and failure explanation so reviewers can see exactly why a run continued or stopped.

Use a central RequestContext equivalent. Compute overrides, metadata, timeout, cache mode, provider/tool ID, strictness, and hook lists once, then pass an immutable context through the run.

Copy the "gateway exception stops fallback" idea. Local configuration errors, unsupported tool calls, and sandbox violations should not be hidden by falling back to another model.

Apply the custom-host validation pattern to any user-supplied MCP/tool/webhook endpoint. Block metadata hosts, private IPs, alternative IP encodings, unsafe schemes, credentials, and suspicious hostnames by default.

Exclude side-effect actions from cache by explicit allow/deny list. Portkey refuses cache for file upload, batch, finetune, and similar endpoints; agent tools need the same discipline.

## Do Not Copy

Do not copy the broad provider matrix as a goal. The useful piece is the adapter contract, not the number of integrations.

Do not rely on non-standard HTTP statuses directly in agent internals. Use typed validation outcomes, then map to transport status only at boundaries.

Do not accept arbitrary guardrail configs without per-check schemas. Broad catchall config is flexible, but it pushes many mistakes into runtime.

Do not let plugin/check errors silently pass by default in high-stakes coding workflows. Agent verification should declare fail-open or fail-closed explicitly.

Do not expose raw request headers, API keys, prompts, patches, or provider responses in local logs without redaction controls.

Do not treat README-level enterprise claims as reusable implementation evidence. The open-source reviewed path supports many reliability patterns, but some governance and MCP claims are external.

Do not use random load balancing for evaluations that need reproducibility. Add deterministic routing seeds or explicit target selection.

## Fit For Agentic Coding Lab

Fit is conditional but high-value. Portkey is not a coding-agent system, but its gateway pattern maps cleanly onto agent error prevention: put policy in a validated config, run checks before and after expensive actions, retry only declared failures, keep fallback from hiding local configuration errors, and emit structured telemetry on every step.

Best artifact candidates are a `RunPolicy` schema, recursive `TargetGroup` executor for tools/models/subagents, hook-result schema, guardrail plugin interface, redacted trace log format, timeout/retry helper, and SSRF-safe endpoint validator for MCP or webhook tools.

## Reviewed Paths

- `README.md`: product scope, quickstart, routing/guardrail examples, reliability feature claims, MCP/enterprise boundaries.
- `cookbook/getting-started/automatic-retries-on-failures.md`, `writing-your-first-gateway-config.md`, `resilient-loadbalancing-with-failure-mitigating-fallbacks.md`, `enable-cache.md`: user-facing retry, fallback, loadbalance, config, trace, and cache examples.
- `cookbook/integrations/vercel/app/examples/generate-text/{guardrails,fallback,conditional-routing}.ts`: compact examples of config objects used from an app integration.
- `package.json`, `conf.json`, `conf.example.json`, `initializeSettings.ts`: runtime scripts, plugin/cache configuration, and self-hosted integration settings shape.
- `src/start-server.ts`, `src/index.ts`: Node and Hono entrypoints, middleware order, routes, local console, SSE logs, realtime WebSocket route, proxy fallback.
- `src/middlewares/requestValidator/index.ts`, `src/middlewares/requestValidator/schema/config.ts`: content type, provider/config validation, schema validation, custom-host SSRF checks, forward-header recursion guard.
- `src/handlers/chatCompletionsHandler.ts`, representative sibling handlers, and `src/handlers/handlerUtils.ts`: config construction, recursive strategy execution, inherited config, fallback/loadbalance/conditional routing, leaf `tryPost` path.
- `src/handlers/retryHandler.ts`, `src/handlers/responseHandlers.ts`: timeout, retry-after handling, retry exhaustion, response mapping, hard/soft hook failure responses.
- `src/handlers/services/{requestContext,providerContext,hooksService,cacheService,logsService,preRequestValidatorService,responseService}.ts`: context, provider lookup, hooks, cache, logging, pre-request stop point, response headers.
- `src/middlewares/hooks/*`: hook span context, check execution, sequential/parallel guardrails, mutators, deny semantics, skip rules.
- `src/middlewares/cache/index.ts`, `src/shared/services/cache/*`: local memory cache path, cache backends, Redis rate limiter support.
- `src/middlewares/log/index.ts`, `src/shared/utils/logger.ts`: local request log collection and streaming.
- `src/providers/index.ts`, `src/providers/types.ts`, `src/providers/utils.ts`, `src/services/transformToProviderRequest.ts`: provider registry, adapter contract, error response helpers, request transformation.
- `plugins/README.md`, `plugins/build.ts`, `plugins/index.ts`, selected default plugins (`contains`, `jsonSchema`, `modelRules`, `allowedRequestTypes`, `jwt`, `requiredMetadataKeys`, `webhook`, `regexReplace`, `addPrefix`) and representative partner plugin entries: guardrail/mutator extension model.
- `tests/unit/src/handlers/services/*.test.ts`, `tests/integration/src/handlers/tryPost.test.ts`, `tests/integration/src/handlers/requestBuilder.ts`: behavioral evidence for retry, timeout, guardrail denial, after-hook retry, mutation, cache, and request-building paths.

## Excluded Paths

- `package-lock.json`, generated dependency metadata, and patch-package files: dependency management artifacts, not gateway execution patterns.
- `docs/images/**`, screenshots, GIFs, icons, audio fixtures, and other binary/media files: visual assets and fixtures that do not change the reliability design.
- `cookbook/**/*.ipynb`: notebook examples, mostly integration demos; Markdown and TypeScript examples were enough for config behavior.
- `cookbook/integrations/vercel/components/**`, `public/**`, CSS, Next/Vercel UI files, and `src/public/index.html`: UI-only or demo-console code. `src/public/index.html` was skimmed only to confirm it is not core gateway logic.
- Most provider-specific modules under `src/providers/<provider>/**`: repetitive adapter implementations. The registry, provider types, shared transform utilities, and representative error-transform patterns were reviewed instead.
- `.github` localized READMEs and deployment-only manifests/docs: translations or infrastructure instructions with little bearing on request-path error prevention.
- Live-provider integration details requiring external credentials: tests were read for intended behavior, not executed against providers.
