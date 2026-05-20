# wrtnlabs/agentica

- URL: https://github.com/wrtnlabs/agentica
- Category: tool-use
- Stars snapshot: 1,022 via GitHub REST API on 2026-05-20
- Reviewed commit: dc91f4307a3f2ee25e1ee07cf48777fcd13b6b0d
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong TypeScript reference for compiler-derived tool schemas, operation registries, validation feedback, selector/caller/describer orchestration, and HTTP/MCP/class controller unification. Do not copy its weak permission model, fail-open listener behavior, or under-modeled MCP history/event types without hardening.

## Why It Matters

Agentica is directly useful for Agentic Coding Lab because it treats tool use as the primary programming model, not as a small addon. It turns TypeScript classes, Swagger/OpenAPI documents, and MCP tools into one operation collection, then runs a multi-agent function-calling path over that collection.

The main reusable pattern is the strict split between schema construction, candidate selection, argument validation, actual execution, result description, and transcript events. That split maps well to coding-agent workflows where tool schemas, permissions, validation, execution, and evidence need separate boundaries.

## What It Is

Agentica is a TypeScript monorepo centered on `@agentica/core`. The core package provides `Agentica` and `MicroAgentica` facades, controller builders for HTTP and MCP, operation composition, prompt assets, orchestration agents, events, histories, token accounting, and error types.

`Agentica` uses internal agents for initialize, cancel, select, call, and describe. `MicroAgentica` skips the selector and directly exposes every operation to the caller, making it suitable only for small tool sets. Companion packages add benchmark runners, vector-based tool selection, WebSocket/RPC wrappers, a CLI scaffold, React chat UI, examples, and documentation.

## Research Themes

- Token efficiency: `Agentica` can divide large operation lists by `capacity`, select candidates in parallel groups, and optionally run an eliticism pass over selected candidates. The vector selector extracts search queries, retrieves only top matching tool names/descriptions, and feeds those candidates to the selector.
- Context control: Histories are explicitly typed as user, assistant, select, cancel, execute, and describe records. `decodeHistory` reinjects select/cancel/execute events as assistant tool calls plus tool messages, while describe histories are not re-expanded into future prompts.
- Sub-agent / multi-agent: The runtime is a fixed internal pipeline rather than arbitrary graph orchestration: initializer, canceler, selector, caller, and describer. Benchmarks clone agents per scenario and run repeated trials concurrently.
- Domain-specific workflow: Controller descriptions and DTO comments are first-class. The docs push compiler-derived TypeScript class schemas, generated OpenAPI, and detailed function/property comments as the domain workflow substrate.
- Error prevention: Typia/OpenAPI validators parse and validate tool arguments, malformed JSON is fed back to the model, select/cancel validate referenced function names, and validation feedback is retried before execution. Execution failures become structured `execute` events.
- Self-learning / memory: No long-term self-learning memory. State is conversation history, operation stack, token usage, and vector-selector embedding caches keyed by operation collection hash.
- Popular skills: Compiler-derived function schemas, OpenAPI-to-LLM schema conversion, MCP tool import, validation repair prompts, operation selection, tool-call evidence events, vector tool search, benchmark scenario reporting.

## Core Execution Path

`new Agentica(props)` composes controllers into an `AgenticaOperationCollection` using `AgenticaOperationComposer.compose`. Operations are stored as an array, a flat name map, a controller/function group map, and optional divided groups when `config.capacity` is set. Function names stay original when globally unique; otherwise names are prefixed with `_<controllerIndex>_` to avoid collisions.

`Agentica.conversate(content)` creates a user-message event, dispatches it, builds an `AgenticaContext`, and runs the configured executor. The default executor first initializes the agent if needed, then cancels previously selected candidates, runs selection, and loops through call/describe until the candidate stack is empty or no execution happened.

`initialize` asks the model whether function calling is needed by exposing a synthetic `getApiFunctions` tool. If the model calls it, `ctx.initialize()` marks the agent ready and emits an initialize event.

`select` presents a compact list of candidate function names, descriptions, and HTTP method/path/tags, then exposes one synthetic `selectFunctions` tool. The returned JSON is leniently parsed, validated with typia, checked against existing operation names, and retried with parse or validation feedback. Valid references are pushed into `ctx.stack` and emitted as `select` events.

`cancel` mirrors `select` for the current stack. It validates that referenced functions are actually cancellable before removing them and emitting `cancel` events.

`call` sends the selected operations as OpenAI tools. For each returned tool call, it parses JSON with the operation-specific parser, validates with the operation-specific validator, retries correction on JSON/type errors, and only then executes the operation. Execution dispatch is protocol-specific: class methods run on the provided object or callback, HTTP operations call a custom executor or `HttpLlm.propagate`, and MCP operations call `client.callTool`.

`describe` sends the execute histories back to the model for a natural-language result summary. `MicroAgentica.conversate` uses the same call/describe functions but bypasses select/cancel and passes every operation directly to `call`.

## Architecture

The central abstraction is `IAgenticaController`, a discriminated union:

- `protocol: "class"` wraps a typia `ILlmApplication` and either a target class instance or callback executor.
- `protocol: "http"` wraps an `IHttpLlmApplication`, `IHttpConnection`, and optional custom HTTP executor.
- `protocol: "mcp"` wraps an MCP client and an `ILlmApplication` synthesized from MCP `tools/list`.

HTTP controllers use `assertHttpController` or `validateHttpController`, which assert/validate Swagger/OpenAPI input, upgrade it to emended OpenAPI, and convert it to an LLM application with `HttpLlm.application`. MCP controllers request `tools/list`, validate the returned tools as `IMcpTool[]`, convert input schemas through OpenAPI and `LlmSchemaConverter`, and attach `LlmJson.parse`, `validate`, and `coerce` handlers to each function.

The runtime context is intentionally small: operation collection, config, histories, selected stack, current prompt, abort signal, event dispatch, LLM request function, and initialize callback. `getChatCompletionFunction` wraps the OpenAI-compatible client, emits request/response events, supports streaming/non-streaming, aggregates token usage, passes `AbortSignal`, and can enforce vendor request concurrency with `Semaphore`.

Events are the main extension surface. `call` events expose mutable arguments before validation/execution; `execute` events expose mutable result values before describe; `request` events expose mutable OpenAI request bodies. The RPC package forwards these events over WebSocket and lets remote listeners mutate call arguments.

The benchmark package clones agents, runs scenario repetitions under a semaphore, records prompts/token usage/success/failure/error, and has a predicate DSL for expected operation sequences (`standalone`, `array`, `anyOf`, `allOf`). The vector-selector package plugs in as a custom selector executor backed by Cohere embeddings plus SQLite or a connector-retrieval/Postgres service.

## Design Choices

Compiler-derived schema is treated as the safety foundation. TypeScript class schemas come from `typia.llm.application`, HTTP schemas come from generated OpenAPI, and MCP schemas are converted into the same `ILlmFunction` shape. Each function carries `parameters`, `parse`, `validate`, and `coerce`.

Selection is separated from calling. `select` sees only names/descriptions plus a few HTTP metadata fields, not full parameter schemas. `call` sees full tool schemas only for selected operations. This is the strongest token-control pattern in the repo.

Validation feedback is host-side, not prompt-only. The host parses and validates model arguments, then injects exact parse/validation failures back into the next tool-call attempt. Select/cancel also validate runtime function existence so hallucinated names are not silently dropped.

The stack is stateful across turns. A function selected in one turn can remain pending until the caller gets enough user information, and cancel can remove selected functions before the next call pass.

Event mutability is deliberate. Docs show `call` listeners filling human-side file/upload arguments and `execute` listeners redacting sensitive return values. This is useful for UI or policy hooks, but it is not a guaranteed permission boundary because listener errors are swallowed.

The default execute prompt explicitly tells the model to execute immediately once required information exists and not ask for permission unless the function description requires confirmation. That keeps demos fast but means safety policy must live in function descriptions, listener hooks, or an external wrapper.

Vector selector is implemented as an optional replacement for the normal selector. It embeds operation descriptions once per operation collection, extracts 2-3 sentence search queries from the user turn, searches top tools, and then asks the model to choose from only those candidates.

## Strengths

- Clean controller union for class, HTTP, and MCP tools with one operation registry.
- Operation composition provides array, flat map, controller group map, collision-safe names, and capacity-based grouping.
- Selector/caller split reduces full-schema exposure and gives a natural place to add tool search or permission filtering.
- Argument parsing, type validation, JSON repair, validation repair, and runtime function-existence checks are concrete host-side controls.
- Event stream is rich enough for UI, audit, transcript replay, token accounting, redaction, and benchmark evidence.
- Request wrapper supports streaming, non-streaming, token aggregation, abort signals, backoff strategy, and concurrency limits.
- Benchmarks test both selection-only and full call paths with repeated trials, concurrency control, consent follow-ups, and expected-operation predicates.
- MCP integration imports real MCP tools into the same operation path instead of creating a second agent loop.

## Weaknesses

- No central permission model, sandbox, tool risk labels, approval gate, or destructive-operation policy. Safety mostly depends on tool descriptions, external controller behavior, and user-provided hooks.
- Listener errors are swallowed. A failed approval, redaction, or request mutation listener can fail open unless wrapped outside Agentica.
- Function execution has no timeout wrapper. LLM requests accept `AbortSignal`, but class/HTTP/MCP executors can hang unless their underlying implementations enforce timeouts.
- `Agentica` records failed executions as `execute` histories but does not throw by default. `MicroAgentica` throws on failed execution unless `config.throw === false`, so failure semantics differ between the two facades.
- Unknown tool calls in `call` are ignored rather than reported back to the model. Select/cancel now validate names, but caller-stage hallucinated names do not get an explicit repair event.
- MCP event/history types are under-modeled: runtime supports `protocol: "mcp"`, but `AgenticaExecuteEvent` and `AgenticaExecuteHistory` are typed mainly as class/http with casts. JSON operation types include MCP, so replay works better than the TypeScript surface suggests.
- Vector selector validation appears inconsistent: `Tools.select_functions` declares an object with `function_list`, the processing path expects that object, but the validation reducer checks for a top-level array. That path needs tests and hardening before reuse.
- Most behavioral tests require live LLM credentials, MCP packages, networked services, or connector infrastructure, so hermetic local assurance is limited.

## Ideas To Steal

Use a two-layer tool exposure path: cheap selection over names/descriptions first, full schemas only after candidate narrowing.

Represent each tool as an operation with protocol, controller, function schema, runtime name, and `toJSON`. Keep flat and grouped indexes so policy, replay, and controller-specific filtering are cheap.

Keep parse/validate/coerce functions attached to tool schemas. The caller should never execute raw model JSON without host-side validation.

Feed validation failures back as tool messages with exact `path`, `expected`, `value`, and `description`. Treat validation feedback as stronger than the static schema because runtime policy can narrow valid options.

Add runtime existence checks for model-selected tool names. This prevents silent drops from hiding hallucination or stale tool visibility.

Expose event hooks before execution and before result description, but make policy hooks explicit and fail-closed in Agentic Coding Lab instead of using best-effort listeners.

Adopt the benchmark shape: clone an agent, run repeated scenarios under a semaphore, record full histories/token usage/errors, and score selected/executed operation sequences with composable predicates.

Use vector search only as a selector plugin, not as the main executor. Tool retrieval should return candidate names plus enough metadata for selection, then defer to the normal validated call path.

## Do Not Copy

Do not rely on prompt instructions or function descriptions as the only permission layer. Coding agents need host-side allowlists, side-effect labels, user approval gates, timeouts, and audit logs.

Do not swallow listener failures for security-sensitive hooks. Approval, redaction, request filtering, and policy checks must fail closed.

Do not expose MCP stdio command launch as a casual controller setup. MCP process start should be privileged and governed by command allowlists, environment filtering, working-directory policy, and lifecycle monitoring.

Do not keep MCP as a TypeScript cast around class/http histories. A lab runtime should model MCP executions explicitly in events, histories, tests, and replay.

Do not use the vector-selector validation path as-is. Fix the `function_list` schema/validation mismatch and replace ad hoc `JSON.parse` with the same typed parse/validate approach used in core.

Do not let remote RPC clients mutate call arguments without authentication, authorization, validation, and provenance logging.

## Fit For Agentic Coding Lab

High fit as a tool-use architecture reference. Agentica should not be adopted wholesale as the lab runtime, but several pieces translate well into smaller artifacts:

- A typed operation registry unifying local functions, HTTP/OpenAPI actions, and MCP tools.
- A selector-before-caller loop with optional capacity grouping or vector search.
- A validation-feedback runner for JSON parse errors, type errors, runtime availability errors, and policy narrowing.
- An event/history transcript that can replay tool-call context without dumping every describe message back into the prompt.
- A benchmark harness for operation-selection and operation-execution reliability.

The lab should add what Agentica leaves open: explicit permissions, sandbox/timeout controls, fail-closed hooks, typed MCP execution records, sanitized error envelopes, and hermetic tests for schema conversion and repair loops.

## Reviewed Paths

- `README.md`: project scope, controller protocols, setup, playgrounds, function-calling strategy, validation feedback, and selector claims.
- `packages/core/src/Agentica.ts`, `MicroAgentica.ts`: facade construction, conversation flow, context creation, history handling, semaphores, dispatch behavior, and failure semantics.
- `packages/core/src/structures/*.ts`: props, config, vendor, executor, controller, MCP tool, and system-prompt types.
- `packages/core/src/context/*.ts` and `packages/core/src/context/internal/AgenticaOperationComposer.ts`: operation registry, grouping, capacity division, selected stack, token usage, and context shape.
- `packages/core/src/functional/assertHttpController.ts`, `validateHttpController.ts`, `assertMcpController.ts`, `validateMcpController.ts`, `createMcpLlmApplication.ts`: HTTP/OpenAPI and MCP schema conversion boundaries.
- `packages/core/src/orchestrate/execute.ts`, `initialize.ts`, `select.ts`, `cancel.ts`, `call.ts`, `describe.ts`, and `orchestrate/internal/*.ts`: default internal-agent pipeline, selection/cancel validation, call validation repair, protocol execution, and stack mutation.
- `packages/core/src/factory/events.ts`, `factory/histories.ts`, `transformers/transformHistory.ts`, `json/*.ts`, `events/*.ts`, `histories/*.ts`: event/history serialization, transcript replay, mutable call/execute/request events, and MCP type gaps.
- `packages/core/src/utils/request.ts`, `__retry.ts`, `assertExecuteFailure.ts`, `StreamUtil.ts`, `ChatGptCompletion*`, `AgenticaTokenUsage*`: LLM request wrapper, backoff, streaming, abort handling, token aggregation, and execution failure conversion.
- `packages/core/src/errors/*.ts` and `packages/core/prompts/*.md`: validation/json parse error types and model-facing repair/system prompts.
- `packages/vector-selector/src/*.ts` and `packages/vector-selector/src/strategy/*.ts`: query extraction, candidate tool search, SQLite/Cohere and connector retrieval strategies, hash-based embedding cache, and selector mismatch risk.
- `packages/benchmark/src/*.ts` and `packages/benchmark/src/internal/*.ts`: selection/call benchmark runners, concurrency controls, reports, expected-operation predicate DSL, and consent follow-up detection.
- `packages/rpc/src/*.ts`: WebSocket/RPC service wrappers, event forwarding, and remote call-argument mutation.
- `test/src/features/test_base_work.ts`, `test_validate_correction.ts`, `test_base_mcp_work_describe.ts`, `test_micro_agentica.ts`, benchmark tests, and vector-selector utility tests: exercised paths and coverage gaps.
- `website/content/docs/concepts/*.mdx`, `website/content/docs/core/controller/*.mdx`, `website/content/docs/core/event.mdx`, and plugin/vector-selector docs: design rationale, controller usage, event mutability, validation feedback, and orchestration docs.

## Excluded Paths

- `packages/chat/**`: React chat UI, movies, playground applications, and Vite build files. Useful for demos, not core tool-use runtime.
- `website/app/**`, `website/components/**`, `website/public/**`, icons, fonts, screenshots, and Next/Nextra build files: documentation website/UI assets. I reviewed relevant MDX content only.
- `packages/cli/**`, `packages/create-agentica/**`, and generated project templates: setup/scaffold UX, not the runtime execution path for tool schemas or calls.
- `assets/**`, `docs/*.png`, `website/public/articles/**`, `articles/**`, badges, images, fonts, PowerPoint, and other media/static files: marketing, docs, or binary assets with no tool execution semantics.
- `packages/core/src/constants/AgenticaSystemPrompt.ts`: generated by `packages/core/build/prompt.js` from `packages/core/prompts/*.md`; the generated file was absent in the fresh checkout, so I reviewed source prompts and generator instead.
- `packages/*/tsconfig*.tsbuildinfo`, lockfiles, Rollup/Vite/Next configs, eslint configs, build/deploy scripts, `bump.config.ts`, `deploy/**`, and release plumbing: build metadata or packaging, not agent tool-use behavior.
- `benchmark/vector-selector-benchmark/**` and `packages/core/examples/benchmarks/**`: benchmark data and reports. I sampled benchmark architecture from `packages/benchmark` and tests rather than generated result artifacts.
- External dependencies referenced through `@typia`, `@typia/utils`, `@modelcontextprotocol/sdk`, `@wrtnlabs/connector-hive-api`, OpenAI SDK, and Cohere SDK: treated as boundaries; I reviewed Agentica's adapter code, not vendored dependency internals.
