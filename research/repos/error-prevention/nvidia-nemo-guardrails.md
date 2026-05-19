# NVIDIA-NeMo/Guardrails

- URL: https://github.com/NVIDIA-NeMo/Guardrails
- Category: error-prevention
- Stars snapshot: 6,155 (GitHub REST API repository metadata, captured 2026-05-19 KST)
- Reviewed commit: b0853f6a3affb9ba79bbec322d471d9c66181aa5
- Reviewed at: 2026-05-19
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong reference for programmable error-prevention gates around LLM conversations, RAG context, and tool calls. The best reusable patterns are event-based rail checkpoints, config-time validation of guard flows/prompts/models, path-specific rail categories, explicit refusal versus exception modes, output mapping for action results, and separate tool-call/tool-result rails. Fit is high for Agentic Coding Lab, but copy the guard boundary pattern rather than the whole conversational DSL/runtime.

## Why It Matters

NeMo Guardrails is one of the clearest open-source implementations of "put programmable policy between the app and the model." It does not rely on a single system prompt. A request becomes events; Colang flows and Python actions can inspect or modify user input, retrieved chunks, generated bot messages, tool calls, and tool results before those artifacts reach the next stage.

For coding agents, the relevant lesson is stage-specific interception. A coding agent has many unsafe transitions: user request to plan, plan to shell command, command to execution, tool output to model context, model output to patch, patch to commit, and summary to user. Guardrails shows how to make those transitions explicit, configurable, observable, and failable.

## What It Is

NeMo Guardrails is a Python package, CLI, FastAPI server, actions server, and Colang DSL for controlling LLM-based conversational applications. Users load a `RailsConfig`, create `LLMRails` or the newer top-level `Guardrails` wrapper, then call `generate`, `generate_async`, `stream_async`, `check`, or event-processing APIs.

The repo supports five rail families:

- Input rails for user text before model/dialog processing.
- Dialog rails for canonical intent, flow control, and generated next steps.
- Retrieval rails for RAG chunks before those chunks enter prompts.
- Execution rails, represented in current config as `tool_output` and `tool_input`, for tool-call parameters and tool-result messages.
- Output rails for model/bot responses before returning to users.

It ships built-in rails for self-check input/output/facts/hallucination, content safety, topic safety, jailbreak detection, sensitive-data masking/detection, injection detection, Llama Guard, Guardrails AI, Patronus, Pangea, Clavata, CrowdStrike AIDR, AI Defense, Fiddler, Trend Micro, Private AI, regex, and other integrations.

## Research Themes

- Token efficiency: Moderate. Input/output rails can run sequentially or in parallel. `IORails` adds an optimized OpenAI-compatible path, non-streaming work queues, streaming semaphores, model caches, and speculative input-rail generation. The default `LLMRails` path can still make multiple LLM calls for intent, next-step, response, and rail checks.
- Context control: Strong. `RailsConfig.from_path()` loads `config.yml`, `.co` files, prompts, actions, `kb/` docs, import paths, and `.railsignore` exclusions. `LLMRails` turns message history into events and context variables, then rails can mutate `$user_message`, `$bot_message`, `$relevant_chunks`, `$tool_calls`, and related state.
- Sub-agent / multi-agent: Limited. This is not a multi-agent framework. The remote actions server and LangChain/LangGraph integrations provide distributed action/tool boundaries, but there is no subagent scheduler.
- Domain-specific workflow: Strong for conversational safety and RAG. Colang lets teams encode domain flows such as topic refusal, support SOPs, authentication-like paths, and special-purpose rails. Custom Python actions make external systems part of those flows.
- Error prevention: Very strong for prompt/response/tool-context checkpoints. It validates configured flow names, missing prompts, referenced model types, API key environment variables, public state shape, unsafe content, jailbreaks, sensitive data, tool-call parameters, and tool outputs. It is weaker as a coding-agent sandbox because it does not control filesystem, process, network, or git operations.
- Self-learning / memory: Limited. It has event history caches, thread replay in the server, context updates, generation logs, tracing, and metrics, but no autonomous long-term learning loop.
- Popular skills: Not a skill-pack repo. Reusable "skills" are the rail categories, Colang flow snippets, built-in rail catalog, `@action` decorator, action server, OpenAI-compatible API server, and tests demonstrating blocking behavior.

## Core Execution Path

The standard local path starts with `RailsConfig.from_path()` or `RailsConfig.from_content()`. Directory loading walks config files, skips `.railsignore` matches, loads YAML, collects `.co` files, ingests markdown docs from `kb/`, resolves `import_paths`, parses Colang 1.0 or 2.x, and validates prompt/model references. Missing input/output/retrieval flows, missing self-check prompts, incompatible passthrough plus single-call mode, bad jailbreak endpoint shapes, and unset model API-key env vars are caught before runtime.

`LLMRails.__init__()` adds default Colang 1.0 flows from `nemoguardrails/rails/llm/llm_flows.co`, loads all built-in library `.co` files, marks configured rail flows as system subflows, loads config-local `config.py` modules, creates a Colang 1.0 or 2.x runtime, calls any `init(app)` hook, initializes main and action-specific LLMs, creates model caches, initializes the knowledge base, registers `kb`, `llm`, `llms`, caches, and other action parameters, then reports telemetry.

`LLMRails.generate_async()` converts OpenAI-style messages to events. User messages become `UtteranceUserActionFinished`; assistant text becomes bot action events; assistant tool calls become `BotToolCalls`; tool messages can become grouped `UserToolMessages`; context and system messages become their own events. The runtime processes events until `Listen` for Colang 1.0 or processes a live `State` for Colang 2.x.

The default Colang 1.0 flow sequence is the central design. `process user input` runs configured input rails before creating `UserMessage`. `run dialog rails` either bypasses dialog rails per generation options or generates the user intent. `generate next step` and `generate bot message` perform dialog and response generation. Before response generation, `retrieve_relevant_chunks` updates RAG context; configured retrieval rails can then inspect or alter `$relevant_chunks`. After `BotMessage`, configured output rails inspect or alter `$bot_message` before `StartUtteranceBotAction` is emitted.

Tool-call handling is split. `process bot tool call` sees `BotToolCalls`, runs `tool_output` rails against `$tool_calls`, then emits `StartToolCallBotAction`. `process user tool messages` sees grouped tool responses, runs `tool_input` rails for each tool message, and can block or sanitize before the LLM sees tool results.

Actions are the bridge between Colang and Python. The `@action` decorator records name, system-action status, async behavior, and output mapping. The runtime injects context, config, events, LLM task manager, LLMs, `kb`, and registered params for local actions. If `actions_server_url` is configured, non-system actions can be posted to `/v1/actions/run`; system actions still run locally because they need trusted in-process state.

`IORails` is a newer optimized engine behind the `Guardrails` wrapper and optional `NEMO_GUARDRAILS_IORAILS_ENGINE` alias. It supports a narrower set: input content safety, topic safety, jailbreak detection model, and output content safety. It uses `EngineRegistry`, `ModelEngine`, `APIEngine`, `RailsManager`, retries, explicit queue/semaphore concurrency limits, tracing, metrics, sequential or parallel rails, and optional speculative input rails. Unsupported configs fall back to `LLMRails` unless `require_iorails=True`.

## Architecture

- `nemoguardrails/rails/llm/config.py`: Pydantic config schema, rail sections, model/prompt validation, `.co` and YAML loading, imports, knowledge-base config, jailbreak/content-safety/sensitive-data integration config, tracing and metrics config.
- `nemoguardrails/rails/llm/llmrails.py`: primary public runtime, message/event conversion, LLM and cache initialization, generation, streaming, check API, state validation, tool-message conversion, and output-rail streaming.
- `nemoguardrails/rails/llm/llm_flows.co`: default Colang execution graph for input, dialog, retrieval, output, tool-output, and tool-input rails.
- `nemoguardrails/colang/v1_0/runtime/runtime.py`: event-loop runtime, next-step computation, local/remote action execution, parallel rail execution, internal-error events, action result/context update handling.
- `nemoguardrails/colang/v2_x/runtime/runtime.py` and `statemachine.py`: state-machine runtime for Colang 2.x, active flows, local actions, async actions, instant actions, and event processing.
- `nemoguardrails/actions/`: action decorator, dispatcher, LLM generation actions, LLM call wrappers, output mappings, built-in retrieval, validation helpers, and lazy action loading.
- `nemoguardrails/library/**`: built-in guardrail flows and actions. This is where self-check, content safety, jailbreak, sensitive data, injection, fact checking, hallucination, and third-party rails live.
- `nemoguardrails/guardrails/**`: optimized `IORails` engine, engine registry, HTTP model/API clients, rail action template, rail manager, telemetry, and concurrency controls.
- `nemoguardrails/server/**` and `actions_server/**`: FastAPI OpenAI-compatible server, config discovery, config/model overrides, state checks, thread persistence hook, SSE formatting, optional Chainlit UI, and remote action execution.
- `docs/**`, `examples/**`, and `tests/**`: user guides, guardrail catalog, server docs, Colang examples, RAG examples, tool integration, and behavioral tests for config validation, rails, tool rails, streaming, and failure handling.

## Design Choices

Guardrails separates policy by lifecycle stage. Input, dialog, retrieval, tool output, tool input, and output rails are configured separately, so a policy author can say exactly which artifact is being guarded.

Colang flows are the policy language, while Python actions are the effectful implementation. This keeps high-level control logic readable and lets checks call LLMs, classifiers, Presidio, YARA rules, external APIs, or custom Python.

Rail actions can mutate context, not only block. Input rails can rewrite `$user_message`, output rails can rewrite `$bot_message`, retrieval rails can mask chunks, and tool-input rails can sanitize tool results.

Failure semantics are explicit. Built-in rails usually return a refusal message, but `enable_rails_exceptions` switches many rails to typed exception events such as `InputRailException`, `OutputRailException`, `JailbreakDetectionRailException`, and `FactCheckRailException`.

Output mappings convert action returns into block decisions. For example, `self_check_output` returns safe/unsafe while its `output_mapping` maps false to blocked; fact checking maps scores below `0.5` to blocked. This separates validation computation from runtime blocking semantics.

Config validation is used as an error-prevention layer. The runtime checks referenced rail flows, prompts, model types used in `$model=...`, API key env vars, and state shapes before deeper execution.

`IORails` chooses a smaller but more operational path: OpenAI-compatible HTTP clients, retries, timeouts, queue admission, streaming load shedding, telemetry spans, and fail-closed rail action errors. It gives production shape at the cost of only supporting a subset of rails.

The server intentionally validates public state. Colang 1.0 accepts transcript state with an `events` list; Colang 2.x public serialized dict state is rejected over HTTP and in `generate_async()` because safe continuation is not implemented there.

## Strengths

Stage-specific rails are directly reusable for agent error prevention. The design maps cleanly to pre-command, post-command, pre-patch, post-patch, pre-commit, and pre-response gates.

The default execution path is inspectable. `llm_flows.co` makes the rail order explicit rather than burying every policy in Python callbacks.

Config-time checks prevent common silent failures. Missing rail flows and required prompts fail fast; `$model=` rail references must point at configured model types.

Tool rails are a valuable recent addition. Tests show `tool_output` rails can block dangerous tool-call parameters and `tool_input` rails can block or sanitize tool results before those results influence the model.

ActionResult is a good contract. One action can return a value, emit events, and update context, which is useful for RAG and guardrail pipelines.

Parallel rail support short-circuits on stops. In both `LLMRails` and `IORails`, parallel paths can cancel remaining checks when one rail blocks, reducing latency for high-risk content.

Failure handling has practical coverage. Action-not-found and action-error paths produce internal-error responses; internal errors add stop events to avoid continuing into main LLM generation; streaming errors are converted to JSON error chunks.

Server path handles real deployment needs: OpenAI-compatible chat completions, config discovery, model override from request model name, CORS opt-in, thread storage hooks, SSE conversion, and development auto-reload.

## Weaknesses

The framework is not a sandbox. It can decide whether to call or trust a tool, but it does not isolate shell commands, filesystem writes, git operations, browser automation, credentials, or network side effects.

`LLMRails` can be expensive and complex. A single user turn can involve intent generation, flow retrieval, next-step generation, bot-message generation, input rails, retrieval rails, output rails, and multiple action/model calls.

There are two engines with different capabilities. `LLMRails` is broad and Colang-driven; `IORails` is operationally tighter but supports only selected safety rails. Users must understand fallback behavior.

Tool-call behavior requires care. Output rails are intentionally skipped for tool-call-only responses to preserve tool calls. The newer `tool_output` rails are the right place to validate tool calls, but an integration that only configures output rails can still let tool calls through.

Blocked tool calls may still be present in the returned message in tests while the content says the request was blocked. A downstream tool executor must key off the rail result/refusal, not blindly execute any returned `tool_calls`.

The tool integration docs still state that tool messages bypass input rails and recommend output rails; the current code adds `tool_input` rails. That doc/code mismatch is easy for adopters to miss.

Remote actions server is a trust boundary. It loads local Python actions and exposes `/v1/actions/run` and `/v1/actions/list`; production deployments need authentication, network isolation, and strict action registration policy.

Some built-in rails depend on external services or heavyweight local dependencies: NIMs, OpenAI-compatible endpoints, Presidio plus spaCy model, YARA rules, third-party APIs, or local jailbreak models. Failure/cost/reproducibility depends on those services.

Streaming output rails are weaker than full-output checks. Buffered chunks can be streamed before validation when `stream_first=True`; parallel streaming rail errors can be logged and allow processing to continue in some paths.

## Ideas To Steal

Represent agent workflow stages as named rail phases, not as one monolithic "safety prompt." Suggested phases: input, plan, command, command_output, file_patch, retrieval_context, tool_call, tool_result, final_response.

Use a small DSL or declarative config for rail composition, with Python hooks only for checks that need real execution. Keep the stage graph readable like `llm_flows.co`.

Validate configuration before running agents. Fail fast when a named guard, prompt, model, tool, checker, path, or env var is missing.

Make every guard return both a machine-readable result and a user-facing fallback. Refusal and exception modes should be configurable per deployment.

Adopt `ActionResult`-style returns for coding-agent tools: `return_value`, emitted events, and context updates. This makes RAG evidence, test results, modified files, and validation metadata first-class.

Add tool-output and tool-input gates. Validate tool-call names/arguments before execution, then validate/sanitize tool results before putting them back into model context.

Support parallel guard checks with first-failure cancellation. For agent commands, run path-scope, destructiveness, secret, and policy checks concurrently when possible.

Keep optimized fast paths separate from the general DSL. A narrow production path for common checks can have stronger timeout/retry/concurrency semantics than the full programmable runtime.

Expose a `check()` API. Agents often need "validate this artifact now" without running a full generation loop.

Log activated rails, internal events, LLM calls, and stop reasons. Agent recovery logic needs to know whether a failure was content-blocked, parser failure, missing config, tool failure, or internal error.

## Do Not Copy

Do not treat conversational refusals as sufficient protection for coding-agent tools. A refused message with still-present tool calls is unsafe if the executor ignores the refusal.

Do not use output rails as the only tool safety mechanism. Tool-call arguments need pre-execution validation, and tool results need pre-context validation.

Do not expose an unauthenticated actions server on a broad network. Remote action execution is remote code capability by design.

Do not rely on model self-check rails where deterministic checks exist. Use parsers, AST checks, allowlists, path scopes, typecheckers, tests, secret scanners, and sandbox policy for coding-agent artifacts.

Do not stream high-risk content before validation unless the UI and user accept that risk. For dangerous domains, prefer `stream_first=False` or validate complete output before release.

Do not copy the full Colang runtime if a repo-local policy format would be simpler. Agentic Coding Lab likely needs a smaller stage policy language tied to files, commands, and test gates.

Do not assume optimized and general engines have identical semantics. A production guard layer needs explicit capability negotiation and tests for fallback behavior.

## Fit For Agentic Coding Lab

Fit is high for `error-prevention`. NeMo Guardrails is not an agent framework, but it is an excellent pattern library for programmable gates around unreliable model behavior.

Best adaptations:

- A rail graph for coding-agent stages, with explicit pre/post boundaries around commands, edits, tests, tool calls, and final summaries.
- Config-time validation for every named checker, prompt, tool adapter, model, MCP server, writable path, and required env var.
- Tool-call and tool-result guards as mandatory layers for any action-capable agent.
- `ActionResult`-style events/context updates for tests, diffs, retrieval evidence, and safety verdicts.
- Refusal versus exception modes so interactive use can be user-friendly while CI/harness use can fail hard.
- Optimized built-in checks for common deterministic gates, plus programmable hooks for repo-specific policy.

The main caveat is that coding-agent errors are often pre-action rather than post-response. NeMo Guardrails should inspire the rail architecture, but Agentic Coding Lab still needs sandbox permissions, command approval, file path enforcement, diff review, test execution, and rollback-safe workflows.

## Reviewed Paths

- `README.md`: scope, rail types, usage API, configuration shape, server CLI, and guardrail catalog summary.
- `docs/about/how-it-works.md`, `docs/about/rail-types.md`: high-level execution model and rail taxonomy.
- `docs/configure-rails/overview.md`, `docs/configure-rails/configuration-reference.md`: config folder layout, YAML schema, rail sections, model types, prompts, jailbreak/content-safety/sensitive-data/injection config, streaming, tracing, and import paths.
- `docs/configure-rails/actions/*.md`: `@action` authoring, registration methods, output mapping, system actions, async actions, and actions server docs.
- `docs/configure-rails/exceptions.md`: exception events, `enable_rails_exceptions`, and exception response shape.
- `docs/integration/tools-integration.md`: LangChain tool integration and documented tool-message risk.
- `docs/run-rails/using-python-apis/**` and `docs/run-rails/using-fastapi-server/**`: Python API, generation options, streaming, server modes, model override env vars, CORS, and Chat UI warnings.
- `nemoguardrails/__init__.py`: public exports and optional `NEMO_GUARDRAILS_IORAILS_ENGINE` alias behavior.
- `nemoguardrails/rails/llm/config.py`: config schema, loading, validation, import handling, Colang parsing, model/prompt checks, and rail classes.
- `nemoguardrails/rails/llm/llmrails.py`: main generation, message-to-event conversion, state validation, check API, streaming output rails, tool message handling, LLM/model/cache init, and KB init.
- `nemoguardrails/rails/llm/llm_flows.co`: default flow order for input, dialog, retrieval, output, tool-output, and tool-input rails.
- `nemoguardrails/colang/v1_0/**` and `nemoguardrails/colang/v2_x/**`: Colang parsers, runtimes, state machine, flow config loading, action execution, and event processing.
- `nemoguardrails/actions/**`: action decorator, action dispatcher, LLM generation actions, LLM call utilities, output mapping, retrieval action, validation helpers, and action loading.
- `nemoguardrails/library/**`: built-in rail flows and actions for self-checks, content safety, jailbreak, topic safety, sensitive data, injection detection, hallucination, fact checking, and third-party safety providers.
- `nemoguardrails/guardrails/**`: `Guardrails` wrapper, `IORails`, `RailsManager`, `RailAction`, `EngineRegistry`, `ModelEngine`, `APIEngine`, retry/timeout behavior, concurrency limits, tracing, and metrics.
- `nemoguardrails/server/api.py`, `server/app.py`, `actions_server/actions_server.py`, `server/schemas/**`, `server/datastore/**`: server config discovery, chat completions, streaming SSE, state/thread validation, model listing/override, optional UI, action server, and datastore boundary.
- `examples/bots/hello_world/**`, `examples/configs/sample/**`, `examples/configs/content_safety/**`, `examples/configs/nemoguards_v2/**`, `examples/configs/rag/custom_rag_output_rails/**`, `examples/configs/sensitive_data_detection_v2/**`, and selected integration examples: Colang flows, input/output/retrieval rails, NIM guard configs, and custom RAG context updates.
- `tests/test_config_validation.py`, `test_guardrail_exceptions.py`, `test_action_error.py`, `test_internal_error_parallel_rails.py`, `test_output_rails_tool_calls.py`, `test_tool_calls_event_extraction.py`, `test_input_tool_rails.py`, `test_sensitive_data_detection.py`, `test_regex_detection.py`, `test_actions_server.py`, and selected IORails/model/cache tests: behavioral coverage for failure paths, config errors, tool rails, streaming, parallel rails, and built-in rails.
- `pyproject.toml`, `pytest.ini`, and `tox.ini`: package entrypoints, supported Python versions, dependencies, extras, and test/lint configuration.

## Excluded Paths

- `docs/_static/**`, `docs/_templates/**`, `docs/_extensions/search_assets/**`, images, screenshots, PlantUML PNGs, and CSS/JS assets: presentation assets, not execution-path logic.
- `examples/notebooks/**` and rendered notebook outputs: useful tutorials, but duplicated by docs/examples/code paths and too output-heavy for source-level design review.
- `vscode_extension/**`, Chainlit UI-only rendering behavior, and other editor/UI surfaces: not central to guardrail execution, except server UI warnings reviewed in docs/server app.
- `benchmark/**`, `qa/**`, and large eval/performance fixtures: relevant to performance/evaluation, not needed for the error-prevention architecture note.
- `poetry.lock`, generated docs metadata, release changelog detail, badges, and CI boilerplate: dependency/build metadata rather than runtime design; `pyproject.toml` was sufficient.
- Binary/model/test fixture assets, static HTML reports, tokenizer/model files, images, and other non-source artifacts: not inspectable design material for rails execution.
- Broad provider-specific integrations not on the main guard path, after sampling representative built-ins and configs: reviewed enough to understand integration pattern without listing every third-party API wrapper.
- `.git/**`, `.github/**`, `.devcontainer/**`, `.vscode/**`, contribution files, license files, and maintenance scripts: repository operations rather than guardrail runtime behavior.
