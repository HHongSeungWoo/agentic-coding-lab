# funnycups/Toolify

- URL: https://github.com/funnycups/Toolify
- Category: tool-use
- Stars snapshot: 257 (GitHub repository page, captured 2026-05-29; index row confirmed but left unchanged per request)
- Reviewed commit: b934c9c218f5f400aecca61e26f2b83783c47812
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: conditional
- Verdict: Useful as a narrow reference for translating OpenAI tool schemas into prompt-mediated XML function calls for upstream models that do not support native tools. It is not a tool execution substrate: tools are request-local, execution stays with the client, `tool_choice` is mostly prompt-only, tests are absent, and security depends heavily on trusted clients, trusted upstreams, and careful deployment.

## Why It Matters

Toolify sits at a different layer than most tool-use libraries in this index. Instead of wrapping Python or TypeScript functions, it acts as an OpenAI-compatible `/v1/chat/completions` proxy. A client sends normal OpenAI `tools`; Toolify removes those tools from the upstream request, injects a system prompt that teaches the model to emit a random trigger plus XML, parses the upstream text back into OpenAI-style `tool_calls`, and returns those calls to the client.

That makes the repo useful for Agentic Coding Lab as a reference for prompt-level tool-call emulation, streaming detection, retry-on-malformed-tool-output, and schema-to-prompt rendering. It is also a clear reminder that function-calling compatibility is not the same thing as governed tool execution.

## What It Is

Toolify is a small FastAPI service with a single large `main.py`, a Pydantic/YAML `config_loader.py`, README files, Docker packaging, and one GitHub Actions workflow for building/publishing a container image.

The service supports multiple upstream OpenAI-compatible providers, model-name routing, optional model/key passthrough, client API-key allowlisting, conversion of `developer` messages to `system`, conversion of prior assistant `tool_calls` and `tool` results into upstream-readable text, non-streaming and streaming chat completions, token usage estimation with `tiktoken`, upstream retry for connection/timeouts, and optional function-call parse retry by asking the upstream model to correct or continue malformed XML.

It does not define or execute tools itself. The "registry" is the `tools` array on each client request. The "execution" result is an OpenAI-compatible response containing tool call names and JSON arguments that the caller must execute outside Toolify.

## Research Themes

- Token efficiency: Mixed. It can estimate usage and uses only the tail of truncated malformed function-call output during continuation retry, but every tool schema is rendered into a verbose injected system prompt on every tool-enabled request. There is no tool retrieval, schema compaction, prompt budget enforcement, or dynamic top-k tool selection.
- Context control: Moderate at the proxy boundary. Tool results are rewritten with tool name, original arguments, and result text so upstream models can see prior tool context. `developer` can be converted to `system`, `<think>` blocks are ignored for trigger parsing, and assistant `tool_calls` are serialized back into the same XML format. There is no durable transcript, memory policy, or injection defense around tool outputs.
- Sub-agent / multi-agent: None. There are no subagents, worker pools, delegation protocols, or multi-agent state.
- Domain-specific workflow: Moderate. The domain is specifically "OpenAI-compatible tool calling for models/APIs without native tool support." Model routing and aliasing make it practical for proxying several providers behind one endpoint.
- Error prevention: Conditional. Pydantic models validate basic request/config shape; generated prompts validate required schema keys; parsed tool calls are checked against allowed tool names and a best-effort JSON Schema subset; malformed XML can trigger model correction retries. Gaps include prompt-only `tool_choice`, no duplicate tool-name rejection, partial JSON Schema support, no tests, and several validation failures that are logged but not enforced.
- Self-learning / memory: None. There is no persistent memory, learned tool selection, feedback loop, or telemetry store beyond logs.
- Popular skills: Prompt-mediated function-call emulation, XML/CDATA function-call format, request-local tool registry, schema-to-prompt rendering, streaming trigger detection outside `<think>` blocks, model-assisted parse repair, OpenAI-compatible error envelopes, and multi-provider proxy routing.

## Core Execution Path

Startup loads `config.yaml` through `config_loader.load_config()`, builds model-to-service mappings, an alias map, a default upstream service, the allowed client-key set, and a process-global trigger signal such as `<Function_AB1c_Start/>`.

Incoming `/v1/chat/completions` requests are parsed into `ChatCompletionRequest`. `verify_api_key` checks the `Authorization` bearer token against configured `allowed_keys`, unless `key_passthrough` is enabled, in which case Toolify skips the allowlist and forwards the client's key upstream.

`find_upstream()` selects the upstream service. In normal mode it maps the requested model to a configured service, randomly chooses one concrete model when a model alias maps to several entries, and falls back to the default service if the model is unknown. In model-passthrough mode it sends every request to the service named `openai` while preserving the requested model name.

`preprocess_messages()` rewrites conversation history before proxying. Prior assistant `tool_calls` are turned into XML-like assistant content using the same trigger signal. `tool` messages are turned into `user` messages that include the tool name, original arguments, and execution result. Optional `developer` messages become `system` messages.

When function calling is enabled and the request has `tools`, `generate_function_prompt()` renders each client-supplied tool schema into a large system prompt. It validates that `properties` is an object, `required` is a list of strings, and all required keys exist in `properties`. It then lists descriptions, summaries, required parameters, nested types, enums, defaults, examples, constraints, `additionalProperties`, and `anyOf`/`oneOf`/`allOf` structure. `safe_process_tool_choice()` appends extra natural-language instructions for `none`, `required`, or a specific tool. Toolify then deletes `tools` and `tool_choice` before forwarding the request upstream.

For non-streaming responses, Toolify posts to the upstream `/chat/completions` endpoint with retry on connection and timeout errors. It estimates/preserves usage fields. If tool calling is active, it takes the upstream assistant content and calls `attempt_fc_parse_with_retry()`. That path parses the XML with `parse_function_calls_xml()`, validates the parsed calls against the request-local tools with `validate_parsed_tools()`, and optionally asks the upstream model to rewrite or continue malformed output. Successful parsed calls are converted to OpenAI `tool_calls` with generated `call_...` ids and `finish_reason: "tool_calls"`.

For streaming responses, `stream_proxy_with_fc_transform()` reads upstream SSE lines. `StreamingFunctionCallDetector` forwards normal content until it sees the trigger signal outside `<think>` blocks, then buffers tool-call XML. Once a closing `</function_calls>` appears or the stream ends, it parses and validates the buffered content, emits synthetic OpenAI streaming chunks containing `tool_calls`, and sends `[DONE]`. If parsing fails and retry is enabled, it performs a non-streaming correction call before emitting tool calls or falling back to text.

## Architecture

The architecture is deliberately flat. `main.py` contains the FastAPI app, token counter, tool schema models, prompt builder, XML parser, streaming detector, retry helpers, message preprocessing, request routing, response conversion, and HTTP error mapping. `config_loader.py` owns typed YAML config models and helper methods for model/service mapping.

There is no package structure, plugin system, MCP adapter, local function registry, permission service, sandbox, approval layer, trace database, or formal test harness. Deployment is via Python directly or Docker Compose, with a GitHub Actions workflow that builds and pushes container images for `main` and tags.

The public interface is the OpenAI-compatible HTTP API, not a library API. The most reusable code-level units are `generate_function_prompt()`, `parse_function_calls_xml()`, `validate_parsed_tools()`, `StreamingFunctionCallDetector`, and the message-preprocessing functions.

## Design Choices

Toolify chooses prompt translation instead of SDK integration. It does not require upstream providers to support OpenAI `tools`; it teaches the upstream model to output one trigger line followed by `<function_calls><function_call>...`.

The trigger signal is random, but it is generated once at process startup and reused for all requests. That reduces accidental collisions versus a fixed marker, but it is not a per-request nonce and can become known through prompt leakage, logs, or model behavior.

Arguments prefer `<args_json>` with JSON object payloads, optionally wrapped in CDATA. The parser also supports a legacy `<args><k>...</k></args>` fallback. XML parsing uses `xml.etree.ElementTree` first, then a regex fallback for malformed XML.

Validation is intentionally best-effort. `validate_parsed_tools()` rejects unknown tools, missing names, non-object arguments, and a subset of JSON Schema violations. It covers common object/string/array/combinator cases, but not full JSON Schema semantics such as numeric bounds, string formats, dependencies, conditional schemas, `$ref`, or unevaluated properties.

`tool_choice` is converted to prompt text rather than a hard execution rule. A specific tool choice is validated against the request tool list before forwarding, but parsed model output is not checked to ensure that the chosen tool was the only emitted tool. `tool_choice="none"` similarly depends on the model following instructions.

Previous tool-call context is reconstructed from the message list rather than server state. This is a good stateless proxy choice, but it means every request must carry the relevant assistant tool-call message before any matching `tool` result.

## Strengths

The proxy idea is practical. A client can keep using OpenAI-compatible SDK calls while Toolify adapts models that only produce text. This is valuable when testing non-native function-calling models behind an existing agent runtime.

The code distinguishes tool-call parsing from reasoning content and `<think>` blocks. Both non-streaming and streaming paths try to ignore trigger strings inside think blocks, which reduces accidental tool-call conversion for reasoning-heavy models.

Schema-to-prompt rendering is more complete than a simple list of names. It includes nested property details, required fields, enums, defaults, examples, constraints, `additionalProperties`, arrays, and basic combinators, which gives weak tool-calling models more concrete instructions.

The tool-call validator is a useful middle layer. Even though it is not full JSON Schema, it catches unknown tool names and many malformed argument shapes before returning `tool_calls` to the client.

The parse-retry mechanism is a useful design pattern. It diagnoses missing tags or invalid JSON, classifies truncated versus syntactically malformed tool output, and asks the model either to continue from the cutoff or rewrite the call.

The service is stateless with respect to tool execution. That makes it easier to deploy as a middleware proxy and limits direct side effects: Toolify itself does not read files, run shell commands, or call arbitrary user tools.

## Weaknesses

There are no tests in the reviewed repository. The only automation is Docker image publishing. For a parser/proxy whose value depends on malformed XML handling, streaming edge cases, schema validation, auth behavior, and retry logic, the absence of unit and integration tests is the largest practical risk.

The effective tool registry is only the current request body. There is no persistent registry, capability metadata, risk classification, approval gate, idempotency model, output schema, result redaction, or execution ledger.

`tool_choice` is not enforced after parsing. Toolify can tell the model "do not use tools" or "only use this tool," but if the model still emits valid XML for another allowed tool, the validator does not reject it based on `tool_choice`.

Duplicate tool names are not rejected. `validate_parsed_tools()` builds a dict keyed by tool name, so later duplicate definitions silently overwrite earlier schemas. That can make prompt text and validation disagree when clients send conflicting tool definitions.

JSON Schema support is partial and handwritten. Numeric bounds, `format`, `$ref`, conditional keywords, object property count constraints, tuple validation semantics, and many advanced cases are not enforced. The prompt displays some constraints that validation does not actually check.

The process-global trigger signal is weaker than a per-request nonce. It is only four random alphanumeric characters inside a fixed tag format and is reused for the server lifetime. If it leaks, prompt injection into upstream responses becomes easier.

Message validation is advisory in the main request path. `validate_message_structure()` can return false, but `chat_completions()` logs the failure and continues processing.

Config validation has an ordering hazard. `AppConfig.validate_upstream_services()` tries to inspect `features.model_passthrough`, but `features` is declared after `upstream_services`, so field-level validation cannot reliably see the configured feature value. This can make model-passthrough validation behave like default normal routing.

Dependencies are unpinned, and README claims Python 3.8+ even though the code uses `tuple[...]` type syntax and Pydantic v2 `field_validator`, which do not fit a conservative Python 3.8 deployment story.

## Ideas To Steal

Use a compatibility proxy as an adapter layer when evaluating models without native tool calling. This keeps the downstream agent runtime stable while varying the upstream provider.

Render tool schemas into a human-readable prompt that preserves exact parameter keys, especially keys with punctuation such as CLI-style `-i` and `-C`. That is directly relevant to coding-agent tools.

Use a trigger plus a strict structured block instead of asking the model for arbitrary JSON in normal prose. CDATA-wrapped `args_json` is a practical way to avoid XML escaping failures for JSON arguments.

Validate model-emitted tool calls against the request-visible tool set before returning them to the caller. Even a partial validator catches many dangerous or useless outputs.

Treat malformed tool-call output as a recoverable model error. A retry prompt that includes structured diagnostics can improve reliability, especially for small `max_tokens` or weak instruction-following models.

Carry prior tool name and arguments alongside tool result content when converting histories for models that do not understand `role=tool`. This helps the model avoid duplicate calls and reason about observations.

Keep streaming and non-streaming behavior aligned. Toolify is valuable because it attempts the same parse/validate/convert contract in both modes, even though the streaming path needs more tests.

## Do Not Copy

Do not treat prompt instructions as policy enforcement. `tool_choice`, tool allowlists, side-effect approval, and execution permissions should be enforced after parsing and before execution.

Do not use a process-global short trigger for adversarial settings. Use per-request nonces, avoid exposing them to untrusted outputs when possible, and reject tool calls that do not correspond to the current request state.

Do not hand-roll only a small subset of JSON Schema if the system needs strict validation. Use a mature JSON Schema validator or make the supported subset explicit in the API contract and tests.

Do not silently accept duplicate tool names. Reject them at request validation time and keep prompt rendering, validation, and returned tool calls aligned.

Do not let untrusted tool descriptions or tool results become privileged prompt text without a security model. Tool descriptions, schema descriptions, prior results, and error-retry prompts are all prompt-injection surfaces.

Do not ship a parser-heavy proxy without fixtures. XML parsing, CDATA splitting, regex fallback, malformed JSON, streaming chunk boundaries, `<think>` nesting, and retry behavior need deterministic tests.

Do not copy the unpinned dependency and Python-version story. Agentic Coding Lab artifacts should pin major dependencies, declare realistic Python support, and run CI against the supported versions.

## Fit For Agentic Coding Lab

Fit is conditional. Toolify belongs in the `tool-use` category because it handles OpenAI-compatible tool schemas and tool-call outputs, but it is a compatibility proxy rather than a function-calling helper library or governed executor.

The best reuse is design-level: a model adapter that can emulate tool calls through prompt/XML when native function calling is absent, plus a parser/validator/retry boundary that returns normal provider-shaped tool calls to the rest of the agent.

For Agentic Coding Lab, the missing surrounding layer matters more than the proxy itself. A production-quality tool-use stack would pair this adapter with a real registry, duplicate-name checks, strict JSON Schema validation, `tool_choice` enforcement, per-request trigger state, policy metadata, sandboxed execution, redaction, replayable traces, and deterministic parser tests.

This repo is a useful candidate to cite as "tool-call emulation middleware." It should not be adopted as the canonical tool registration or execution model.

## Reviewed Paths

- `README.md`: project scope, claimed features, setup, configuration, and OpenAI SDK usage pattern.
- `README_zh.md`: Chinese README checked for parity with the English docs; no additional runtime design beyond the English README.
- `config.example.yaml`: server timeout/retry settings, upstream model routing, alias examples, client authentication, feature flags, custom prompt templates, and retry-prompt configuration.
- `config_loader.py`: Pydantic config models, validators, model alias mapping, default service selection, allowed client keys, and model-passthrough validation hazard.
- `main.py`: FastAPI endpoints, auth dependency, model routing, message preprocessing, tool schema prompt rendering, XML parser, JSON Schema subset validator, function-call retry, streaming detector, upstream retry, token usage estimation, and error response mapping.
- `requirements.txt`: dependency surface and lack of version pins.
- `Dockerfile` and `docker-compose.yml`: deployment path, Python 3.10 container base, mounted `config.yaml`, and service exposure.
- `.github/workflows/docker-publish.yml`: automation posture, limited to container build/publish rather than test or lint verification.
- `LICENSE`: GPL-3.0-or-later license, relevant if code is copied rather than only mined for design patterns.
- Repository-wide searches for tests, CI, validation, retry, auth, tool choice, JSON Schema, streaming, and Docker paths to confirm coverage and missing areas.

## Excluded Paths

- `.dockerignore`: packaging exclusion metadata only; it did not affect tool schema handling, parsing, validation, auth, or execution design.
- `LICENSE` legal text beyond license identification: reviewed only for reuse constraints, not line-by-line legal analysis.
- Git metadata and cloned repository history beyond the reviewed HEAD commit: the research note is tied to commit `b934c9c218f5f400aecca61e26f2b83783c47812`.
- Generated runtime artifacts such as `__pycache__`, local `config.yaml`, virtual environments, coverage output, and `node_modules`: not present in the source snapshot and not relevant to the tool-use design.
- External upstream services, Docker registry state, and live model behavior: not executed during review. The analysis is based on repository source, documentation, and static behavior.
