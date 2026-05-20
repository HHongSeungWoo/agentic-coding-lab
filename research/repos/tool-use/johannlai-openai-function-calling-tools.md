# JohannLai/openai-function-calling-tools

- URL: https://github.com/JohannLai/openai-function-calling-tools
- Category: tool-use
- Stars snapshot: 308 (GitHub repository page, captured 2026-05-20)
- Reviewed commit: 45f7f247e0fa2459f2da5a2ab949fe49795c1eba
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: in-scope
- Verdict: Useful small reference for a TypeScript function-calling tool factory: Zod input schemas become OpenAI function schemas, handlers stay as host callables, and examples show the manual call/observe loop. Do not adopt it as a runtime foundation; registry, permissions, sandboxing, async error handling, URL/file policy, output validation, and tests are too thin for Agentic Coding Lab.

## Why It Matters

This repo is a compact example of the old OpenAI `functions` pattern: each tool is packaged as a callable plus a JSON Schema description, user code gives the schema to the model, the model returns a function name and JSON arguments, and host code executes the matching callable.

For Agentic Coding Lab, the useful part is the small boundary between model-facing schema and host-owned execution. The code is simple enough to audit end to end: `Tool` wraps a Zod schema, factories hide credentials in closures, examples keep a plain `functions` object for dispatch, and tool results are appended back into chat as `function` messages. That makes it a good negative-and-positive reference for designing a stricter registry.

## What It Is

`openai-function-calling-tools` is a JavaScript/TypeScript package exposing ready-made OpenAI function-calling tools: calculator, clock, web page text extraction, search APIs, Mapbox geocoding/map image helpers, generic HTTP request, AI plugin spec fetcher, and host-provided file read/write adapters.

The repository is not a full agent framework. It has no central tool registry, MCP adapter, planner, memory, multi-agent orchestration, permission service, sandbox process, or trace store. It is a library of factory functions plus examples that show how an application can wire those factories into the OpenAI Chat Completions API.

## Research Themes

- Token efficiency: Low. Schemas are compact, and search/browser tools trim external responses, but there is no schema pruning, top-k tool discovery, result budget, summarization policy, or context compression.
- Context control: Moderate at the tool boundary. Zod-to-JSON-Schema keeps parameters explicit, and callers choose which schemas to expose per request. There is no registry-level visibility policy or dynamic selection.
- Sub-agent / multi-agent: None. No worker isolation, delegation, queues, or multi-agent state.
- Domain-specific workflow: Moderate. Individual factories cover common domains: search, browser extraction, time, map/geocode, HTTP, OpenAPI spec discovery, filesystem adapters, and calculator.
- Error prevention: Low-to-moderate. Zod validates input shape before execution, and some tools catch local failures. Missing pieces include unknown-tool checks, guarded `JSON.parse`, async rejection normalization, URL/file policies, output validation, timeouts, retries, and typed errors.
- Self-learning / memory: None. The package has no memory store, feedback loop, usage telemetry, or learned tool selection.
- Popular skills: Zod-backed tool factories, schema/callable pairing, manual function registry, function-call loop examples, credential closure pattern, file-store adapter boundary, AI plugin/OpenAPI spec discovery, and simple web/search adapters.

## Core Execution Path

The core library path is `tools/tool.ts`. A factory defines a Zod parameter schema, a model-visible `name`, a `description`, and an `execute` function. `new Tool(...).tool` returns a two-item tuple:

- A bound `run(params)` function that calls `paramsSchema.parse(params)` and then `execute(validatedParams)`.
- A schema object shaped for legacy OpenAI Chat Completions `functions`: `{ name, description, parameters: zodToJsonSchema(paramsSchema) }`.

The example agent path is manual. User code creates one or more factories, stores returned handlers in a plain object such as `{ calculator, googleCustomSearch, clock }`, passes returned schemas as `functions: [...]` to `openai.createChatCompletion`, checks whether `finish_reason === "function_call"`, extracts `message.function_call.name` and `arguments`, runs `JSON.parse(args)`, dispatches `functions[fnName](parsedArgs)`, then appends an assistant `function_call` message and a `role: "function"` result message before calling the model again.

The external-tool path keeps secrets in factory closures. Search and Mapbox factories require API keys when created, but the model-facing schema only sees a query or coordinate shape. During execution the handler performs `fetch`, maps the remote response to a smaller JSON object/string, and returns that result to the loop.

The AI plugin path in `tools/aiplugin.ts` is a two-step discovery pattern. `createAIPlugin` fetches an `ai-plugin.json` manifest, fetches the linked OpenAPI spec at creation time, then exposes a no-argument tool whose result is the spec text plus instructions telling the model to generate a client or call `request` separately. This is useful as a pattern for progressive API discovery, but the implementation has no size cap, trust policy, spec validation, or endpoint allowlist.

Filesystem tools in `tools/fs.ts` are adapter-based. The package defines a `BaseFileStore` interface and creates `read_file`/`write_file` tools against a caller-provided store. That is the right boundary shape: the package does not directly import Node `fs`, so the host can decide path scope. The current library does not enforce that policy itself.

## Architecture

The architecture is flat. `index.ts` re-exports factory functions from `tools/*` and the generic `Tool` class. There is no loader, registry service, config file, provider abstraction, permission middleware, or runtime orchestrator.

The package targets CJS and ESM builds through TypeScript configs, with published entrypoints under `dist/cjs` and `dist/esm`. The reviewed source snapshot did not include generated `dist` output.

The dependency surface is small and direct: `zod` and `zod-to-json-schema` for schemas, `expr-eval` for calculator expressions, `moment-timezone` for clock, `cheerio` for HTML text extraction, `openai` v3 for examples, and fetch-based calls for HTTP/search/Mapbox tools.

Tests are colocated with tool files and use Vitest. They validate calculator, clock, request, AI plugin, Mapbox geocode/map helpers, and a few factory failure cases, but several tests depend on live network services or secrets.

## Design Choices

The main design choice is the `[handler, schema]` tuple. It makes call sites obvious and keeps model-facing schema and executable function paired without adding a framework.

Zod is the source of truth for input parameters. That gives the host both runtime parsing and schema emission from one definition. The repo does not use Zod for output validation, effect metadata, or policy checks.

Dispatch is deliberately left to the application. Examples build a plain object and trust `function_call.name` to index it. This is simple, but it means every app must remember to guard unknown names, invalid JSON, async failures, and risky tools.

Credential-bearing tools hide API keys in closures. That prevents the model from receiving keys in schemas, but some outputs can leak secrets, especially `showPoisOnMap`, which returns a Mapbox Static API URL containing the access token.

The calculator avoids JavaScript `eval` by using `expr-eval`. The commented-out JavaScript interpreter used `vm2` with a timeout, but it is not exported from `index.ts`; the example that imports `createJavaScriptInterpreter` is stale.

The generic `request` and `webbrowser` tools prioritize convenience over safety. Both accept model-provided URLs with no allowlist, internal-address blocklist, timeout, response-size cap, or content provenance metadata.

## Strengths

The source is small enough that the whole tool-use path can be reviewed quickly. There is little framework magic between schema definition, model exposure, and handler execution.

Zod-to-JSON-Schema is a good base pattern. It avoids duplicating parameter contracts in TypeScript and OpenAI schema JSON.

Factory closures are a useful secret-handling pattern. API keys are configured by the host and not described to the model as parameters.

The file-store adapter is the strongest boundary in the package. It lets a host provide a scoped filesystem implementation instead of letting the tool directly choose disk access.

Examples show the complete observe-act loop, including pushing the model's function call and the tool result back into the message list. That is useful for teaching provider-level function calling mechanics.

`aggregatedSearch` demonstrates a reusable orchestration shape: run several search providers in parallel, parse each provider result, then return a combined object. It needs better export status, error isolation, and policy controls, but the pattern is useful.

## Weaknesses

There is no central registry or execution gateway. Tool name lookup, permission checks, trace logging, retries, result limits, and user approvals are all outside the package.

`Tool.run` is not async-aware. It catches synchronous Zod/execute errors, but async handler rejections return as rejected promises. Several async tools rethrow inside `catch`, so examples can crash unless caller code adds its own `try/catch`.

The model-call examples do not guard `JSON.parse(args)` or `functions[fnName]`. Malformed arguments or an unexpected function name can fail outside the tool wrapper.

Input schemas are shallow. URLs are plain strings, paths are plain strings, coordinates have no range checks, query strings have no length limits, HTTP methods include side-effecting verbs, and unknown side effects are not labeled.

Output handling is inconsistent. Some tools return JSON strings, some return objects, some return plain error strings, and some throw. There is no common envelope like `{ ok, data, error, metadata }`.

Network and filesystem boundaries are weak. `request` can call arbitrary URLs with arbitrary headers and methods; `webbrowser` can fetch arbitrary URLs; file tools rely entirely on the caller-provided store; Mapbox/search tools have no timeout or cancellation path.

Tests are not hermetic. Several tests call live third-party services, require environment secrets, or can fail due to time/network drift. The clock test compares second-precision timestamps around live execution.

Documentation and source drift. README lists JavaScript interpreter and SQL tools, but the interpreter implementation/export is commented out and no SQL tool exists in the source. Examples use legacy OpenAI `functions` and older models rather than current `tools`/`tool_calls` APIs.

## Ideas To Steal

Pair every tool handler with one schema-emitting factory. This keeps local execution and model-facing contract close enough to review together.

Use Zod or an equivalent runtime schema as the internal source of truth, then project it into provider schemas, MCP schemas, TypeScript docs, and tests.

Make tool exposure explicit at each model call. The examples manually choose `functions: [schema...]`; Agentic Coding Lab can keep that shape but automate it through a policy-aware registry.

Keep secrets in host closures, not model-visible parameters. Add output scrubbers so returned URLs and errors cannot leak those secrets.

Copy the file-store adapter shape, but make the store enforce workspace roots, path normalization, read/write permissions, audit logs, and atomic writes.

Turn the AI plugin spec pattern into controlled API discovery: fetch manifest/spec out of band, validate and index it, expose only selected operations, and let the model request details through a bounded schema browser.

Use parallel aggregation for independent tools. `aggregatedSearch` is a simple example of fan-out/fan-in that can become a richer execution primitive with per-provider errors and budgets.

## Do Not Copy

Do not copy the legacy OpenAI `functions` API or old `gpt-3.5-turbo-0613` examples as current integration guidance. Use current provider `tools`/`tool_calls` semantics and keep adapters versioned.

Do not expose generic `request` or `webbrowser` tools without URL policy, method policy, SSRF defenses, timeouts, byte limits, content-type handling, and approval gates for side effects.

Do not return credential-bearing URLs to the model or user. Mapbox static URLs should be proxied, signed with short-lived scoped credentials, or redacted.

Do not normalize errors as arbitrary strings. Use typed, structured failures with retryability, safe user messages, raw cause storage, and trace IDs.

Do not depend on live network tests for core tool behavior. Mock provider responses and reserve integration tests for opt-in suites with clear secrets.

Do not rely on a prompt-visible schema as a permission model. Schema validation says the arguments are shaped correctly; it does not say the action is allowed.

Do not leave disabled/stale tool examples in the public surface. Coding agents copy examples literally, so dead exports and README drift become runtime failures.

## Fit For Agentic Coding Lab

Fit is strong as a pattern source and weak as a dependency. The repo is directly in the `tool-use` category, but its implementation is a lightweight helper library, not a governed execution layer.

The best Agentic Coding Lab artifact to build from this review is a stricter TypeScript tool registry:

- Tool definition uses runtime schemas as source of truth.
- Registry stores name, schema, description, effect type, risk level, required permissions, timeout, retry policy, output schema, and redaction rules.
- Model-facing adapters can emit OpenAI tools, MCP tools, or local function-call schemas from the same definition.
- Dispatcher validates tool name, parses JSON safely, validates input, checks permissions, executes with timeout/cancellation, validates output, redacts secrets, and writes a structured trace.
- Filesystem, HTTP, browser, shell, and API tools live behind separate policy adapters rather than generic unrestricted handlers.

This repo is most useful as the "minimum viable wrapper" baseline. Agentic Coding Lab should keep the ergonomic factory shape and replace almost every execution boundary around it.

## Reviewed Paths

- `README.md`: stated tool catalog, supported environments, function-calling examples, and documentation drift.
- `package.json`, `.nvmrc`, `tsconfig.json`, `tsconfig.cjs.json`, and `tsconfig.esm.json`: package entrypoints, scripts, dependency surface, Node version, and build shape.
- `index.ts`: public export surface and disabled `createJavaScriptInterpreter` export.
- `tools/tool.ts`: generic Zod validation, JSON Schema projection, tuple contract, and error handling.
- `tools/calculator.ts`, `tools/clock.ts`, `tools/fs.ts`, `tools/request.ts`, `tools/webbrowser.ts`: local utility, filesystem adapter, HTTP, and browser execution paths.
- `tools/googleCustomSearch.ts`, `tools/bingCustomSearch.ts`, `tools/serpApiCustomSearch.ts`, `tools/serperCustomSearch.ts`, `tools/serpApiImageSearch.ts`, `tools/serperImagesSearch.ts`, and `tools/aggregatedSearch.ts`: search adapters, result normalization, credential closures, and parallel fan-out/fan-in.
- `tools/reverseGeocode.ts` and `tools/showPoisOnMap.ts`: Mapbox execution path and token-leaking map URL result.
- `tools/aiplugin.ts`: AI plugin manifest/OpenAPI spec discovery path.
- `tools/javaScriptInterpreter.ts`: commented-out interpreter implementation and stale public example relationship.
- `tools/*.test.ts`: Vitest coverage shape, live-network dependencies, env-secret assumptions, and error expectations.
- `examples/*.js`: manual OpenAI function-call loop, function map dispatch, message update pattern, and stale interpreter import.
- `.github/workflows/mr.yml` and `.github/workflows/npm-publish.yml`: CI/release posture, coverage/build commands, and secret-dependent test environment.
- `legacy/functionSchemaPlugin.js`: legacy TypeScript AST/schema injection experiment; reviewed as non-runtime context.

## Excluded Paths

- `assets/logo.png` and `assets/javascript.png`: image/README assets, not tool schema, execution, validation, or orchestration logic.
- `pnpm-lock.yaml`: generated dependency lockfile. Dependency categories were reviewed through `package.json`; lockfile rows were not needed for tool-use design.
- `legacy/webpack.config.js`: old build-plugin wiring for the legacy schema experiment, not part of the exported runtime path.
- `LICENSE` and `.gitignore`: repository metadata. They did not affect tool execution beyond confirming no generated `dist/` or vendored `node_modules/` paths were present in the reviewed checkout.
- Absent/generated/vendor paths such as `dist/`, `node_modules/`, coverage output, and npm package artifacts: not present in the source snapshot and not needed for execution-path review.
