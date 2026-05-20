# TengHu/ActionWeaver

- URL: https://github.com/TengHu/ActionWeaver
- Category: tool-use
- Stars snapshot: 328 (GitHub repository page, 2026-05-20)
- Reviewed commit: 0edfe602989e90de1387e40490844bd740372687
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: conditional
- Verdict: Useful lightweight reference for Python-first function calling: decorators turn ordinary functions into schema-bearing actions, `wrap` and `patch` hide the OpenAI/Azure function loop, `orch` narrows or forces the next visible action set, and `ExceptionHandler` gives callers a recovery hook. It is not a safe execution substrate for coding agents because actions run arbitrary Python in-process with no permission model, sandbox, approval gate, loop cap, durable ledger, or default host-side argument validation.

## Why It Matters

ActionWeaver is valuable because it shows the smallest useful shape of a tool-use framework: function signature plus docstring becomes a model-visible tool schema, a chat-completion wrapper manages tool-call replay, and an orchestration map changes the tool set after each call. That is directly relevant to Agentic Coding Lab because it isolates several reusable control surfaces without pulling in a large agent framework.

The repo also makes an important design tradeoff visible. It treats Python functions as the authority boundary: once the model chooses a tool and emits JSON arguments, the host calls the function directly. This makes tool addition pleasant, but it shifts safety, validation, idempotency, and side-effect control to the application author. For a coding agent, that split is a useful cautionary example: tool schema ergonomics are not the same as tool execution safety.

## What It Is

ActionWeaver is a small Python package for OpenAI and Azure OpenAI function/tool calling. It depends mainly on `openai` and `pydantic`. The current package version in `pyproject.toml` is `0.0.32`.

The public surface is centered on `@action`, `Action`, `wrap`, and `patch`. A developer decorates a function with `@action(name=...)`; ActionWeaver creates an `Action` object that stores a callable, a Pydantic model generated from the function signature or supplied directly, a docstring-derived description, optional decorators, and a `stop` flag. The caller then passes `actions=[...]` and optionally `orch={...}` to an ActionWeaver-wrapped chat-completion call.

The primary runtime path is `actionweaver/llms/openai/tools/chat_loop.py`, used by `actionweaver/llms/wrapper.py` for regular OpenAI clients. Azure uses `actionweaver/llms/azure/chat_loop.py` and the older `functions` parameter shape. `actionweaver/llms/openai/tools/chat.py` and `actionweaver/llms/azure/chat.py` provide patchable client classes with mostly duplicated loop logic. `actionweaver/llms/general/action_processor.py` is a separate non-OpenAI helper that parses JSON text into a tool name plus parameters.

## Research Themes

- Token efficiency: Moderate pattern value. `orch` can reduce visible tools after a call and can force a single next action through `tool_choice`, which avoids sending a flat full registry every turn. `TokenUsageTracker` can raise when total usage exceeds a budget. There is no automatic context trimming, summarization, schema compression, retrieval, or tool search.
- Context control: Strong small pattern, weak full system. The caller owns `messages`, while the loop mutates that same list by appending assistant tool calls and tool results. The orchestration map controls which tools are exposed on each subsequent model call. Final assistant text is not appended by the core loop, so durable conversation memory is application-managed.
- Sub-agent / multi-agent: Low. There are no subagents, worker pools, queues, handoff protocols, or shared state machines. The closest reusable pattern is chaining tools through `orch`.
- Domain-specific workflow: Moderate. The framework lets domain code stay as ordinary Python functions and can wrap LangChain tools with `action_from_tool`. Notebook examples show file, search, extraction, mapping, and planning tasks, but these are demos rather than framework-level domain workflows.
- Error prevention: Conditional. The loop rejects raw `tools`/`tool_choice` or `functions`/`function_call` kwargs, validates `orch` keys are strings, parses model arguments as JSON, checks tool names against `ActionHandlers`, and supports user-defined `ExceptionHandler` recovery. It lacks built-in permission checks, argument validation for normal actions, retry policy, loop limits, cancellation, sandboxing, and typed tool risk metadata.
- Self-learning / memory: Low. There is no memory subsystem. The stateful-agent notebook stores `self.messages` and a `self.times` list in user code, and `utils/output.py` can append streamed assistant output to messages, but core memory/context policy is absent.
- Popular skills: Good source for skills around Python function-to-tool schemas, scoped tool visibility, forced tool calls, structured extraction through Pydantic models, exception-to-observation retries, and lightweight trace wrappers.

## Core Execution Path

The main path starts with `actionweaver/actions/factories/function.py`. `action(name=...)` returns a decorator. When applied, it constructs an `Action` with a Pydantic model from `create_pydantic_model_from_func`, unless the caller passed `pydantic_model`. `Action.__init__` requires a docstring or explicit description, preserves metadata, optionally wraps the callable in caller-supplied decorators, and optionally wraps it in `telemetry.traceable`.

An `Action` has two different identities. For prompting, `get_function_details()` returns `name`, `description`, and `parameters` from `pydantic_model.model_json_schema()`. For execution, `Action.__call__` invokes `self.function(*args, **kwargs)` directly. This means generated schemas are model-facing by default; they do not automatically validate or coerce arguments before ordinary action execution. Host-side validation happens only if the function itself is decorated, for example with `pydantic.validate_call`, or if the action was built by `action_from_model`, whose generated function calls `model.model_validate(kwargs)`.

Callers can use `wrap(OpenAI())`, which returns `ActionWeaverLLMClientWrapper`. For OpenAI clients, the wrapper installs a closure returned by `create_chat_loop(client.chat.completions.create)`. For Azure clients, it installs the Azure loop. `patch(client)` instead mutates `client.chat.completions.create` in place for supported sync OpenAI and Azure clients; async clients raise `NotImplementedError`.

In the OpenAI tools loop, `new_create(actions=[], orch=None, token_usage_tracker=None, ...)` first runs `argument_check`: `messages` and `model` must be present, and raw `tools` or `tool_choice` are rejected because the wrapper wants `actions` to be the only tool surface. `build_orch` creates an `ActionHandlers` mapping from names to `Action` objects, injects `DEFAULT_ACTION_SCOPE` when missing, and sets each action's missing follow-up expression back to the default scope. `Tools.from_expr(orch[DEFAULT_ACTION_SCOPE])` then turns the current expression into OpenAI API kwargs: a list maps to `tools=[...]` plus `tool_choice="auto"`, a single `Action` maps to one tool plus forced `tool_choice`, and `None` means no tools.

The loop then calls the original chat-completion method. If tools are visible, it passes `tools` and `tool_choice`; otherwise it makes a plain chat call. Non-streaming responses add usage into `TokenUsageTracker`. Streaming responses branch: if the first chunk is content, the wrapper returns the stream iterator immediately; if the first chunk is a tool call, it buffers the rest of the stream and merges deltas into one synthetic message before continuing the tool loop.

When a response contains `message.tool_calls`, `invoke_tool` appends the assistant message to the caller's `messages` list. For each tool call, it converts OpenAI SDK objects to dictionaries when needed, reads `function.name` and JSON string arguments, decodes the arguments, verifies the name exists in `ActionHandlers`, invokes `action_handler[name](**arguments)`, and appends a `role="tool"` message with stringified output and the original tool-call id. Tool calls are executed sequentially in the Python process; async tool invocation is explicitly left unimplemented in the source comments.

After tool execution, orchestration determines the next visible tools. If exactly one tool name was called, the loop uses `orch[name]`, or the default scope if the expression is `DEFAULT_ACTION_SCOPE`. If multiple distinct tool names were called in one assistant message, it ignores orchestration and `stop` and keeps the same tool set for the next model call. If the called action has `stop=True`, the loop returns the raw tool response list instead of calling the model again.

When a response has normal assistant content and finish reason `stop`, the loop returns the OpenAI API response. It intentionally does not append that final assistant message to `messages`; only intermediate tool-call messages are added. `utils/output.process_and_display_output` is a separate helper that can append displayed output to messages, but it is not part of the wrapped loop.

The Azure path mirrors this structure using legacy `functions` and `function_call` kwargs. It processes one function call at a time, appends `role="assistant"` plus `function_call`, then appends `role="function"` output. Its `Functions.from_expr` has the same expression shape as OpenAI `Tools.from_expr`.

`Action.invoke(client, force=True, ...)` is a convenience path for forced execution. For an `OpenAI`, `AzureOpenAI`, or ActionWeaver wrapper, it calls the wrapped create method with `actions=[self]` and, when `force=True`, `orch={DEFAULT_ACTION_SCOPE: self, self.name: None}`. That exposes exactly one forced tool first, then no tools after the tool runs.

## Architecture

The architecture is intentionally small and library-shaped.

`actionweaver/actions/action.py` defines `Action`, `InstanceAction`, `ActionHandlers`, and `ActionException`. `Action` is both a descriptor for instance methods and a callable wrapper around the original function. `ActionHandlers` is the runtime name registry. It is a simple dictionary with overwrite semantics; duplicate action names are not rejected.

`actionweaver/actions/factories/` contains schema and composition helpers. `function.py` builds actions from Python functions. `pydantic_model_to_action.py` builds extraction actions from Pydantic models. `combine.py` creates one action whose schema nests several action models and invokes all of them. `repeat.py` creates an action that accepts a list of one action's parameter model and reduces repeated results. `langchain.py` adapts a LangChain tool by wrapping `tool._run` and ignoring `run_manager` in the generated schema. `instructor.py` is empty in this snapshot.

`actionweaver/llms/openai/tools/` is the current OpenAI tool-call implementation. `tools.py` serializes an action expression into OpenAI `tools` kwargs. `chat_loop.py` is the wrapper used by `wrap`. `chat.py` is the older class-based patch path with duplicated logic and tests.

`actionweaver/llms/azure/` is the Azure implementation. It uses `Functions.from_expr` and the older OpenAI `functions` API shape. It is mostly parallel to the OpenAI tools code.

`actionweaver/llms/general/` is a lightweight generic path. `ActionProcessor` accepts a list of actions and an optional extractor. By default it parses text as JSON with keys `function` and `parameters`, maps the function to a registered action name, invokes it, and returns `(response, ok, error)`.

`actionweaver/utils/` holds schema, streaming, caching, token, and output helpers. `pydantic_utils.py` builds dynamic Pydantic models from signatures and supports ignored or overridden parameters. `cache.py` preserves signatures around cache decorators. `stream.py` merges streamed chunks. `tokens.py` tracks aggregate usage and optional token budget.

`actionweaver/telemetry/helpers.py` provides a local `traceable` decorator inspired by LangSmith. It uses a context variable to link parent and child run ids and logs structured dictionaries with inputs, outputs, errors, timestamps, and metadata.

## Design Choices

ActionWeaver keeps tool authoring as close to normal Python as possible. Function annotations and docstrings are the schema source. Extra decorators can be applied after schema capture through the `decorators=[...]` argument, which lets callers add tracing or validation without changing the prompt-visible model shape.

Tool visibility is controlled by expressions, not by a graph object. `orch` maps action names to one of three expression types: a list of actions for model choice, one action for forced next call, or `None` for no follow-up tools. The default scope is a sentinel key, `"_default_action_scope_"`. This is easy to reason about and cheap to serialize, but it gives limited validation and no graph introspection.

The runtime chooses mutation over a separate transcript object. The same `messages` list passed by the caller becomes the working loop transcript. This is convenient for stateful agents, but it mixes caller-owned history with internal tool-call state and does not create a replay/audit boundary.

Error handling is caller-extensible rather than framework-prescribed. The new wrapper catches exceptions and, if an `ExceptionHandler` exists, calls `handle_exception(e, ChatLoopInfo(context={...}))`. The handler returns `Continue(functions=...)` to keep looping or `Return(content=...)` to terminate. Cookbook examples use this to append validation errors as tool messages and let the model retry.

The repo supports two generations of OpenAI APIs at once. OpenAI uses `tools`; Azure still uses `functions`. There is also a deprecated OpenAI `functions` class that prints a deprecation warning. This helps migration, but it creates duplicated behavior and some stale docs.

Validation is deliberately optional. Pydantic is used strongly for schema generation and model extraction actions, but ordinary function actions trust the model arguments once JSON decoding succeeds. The docs recommend `pydantic.validate_call` when execution-time validation matters.

## Strengths

The function-to-action path is compact and reusable. A future Agentic Coding Lab prototype could adopt the core shape: function, description, Pydantic schema, stop policy, and decorators as a single tool object.

Scoped tool exposure is a practical token and control pattern. The `orch` map can make a root tool reveal a narrower sub-tool set, force an exact next tool, or close the tool surface before final response.

The forced invocation path is clear. `Action.invoke(..., force=True)` uses the same runtime as normal tool calls but sets default scope to exactly one action, then ends the tool sequence. That is useful for structured extraction and deterministic "ask model to fill this schema" workflows.

The exception handler contract is small but expressive. Passing response, tools/functions, messages, model, and orchestration into a handler lets applications convert validation failures into observations, retry with the same tools, or return a fallback.

The composition helpers are worth mining. `action_from_model` turns Pydantic models into extraction tools. `combine` creates a composite schema that invokes several actions. `repeat` creates a repeated-call schema for one action. These are simple examples of schema-level tool transformation.

Tests cover key happy paths for schema generation, decorator signature preservation, Pydantic model extraction, combine/repeat helpers, generic action processing, and OpenAI tool-loop behavior for one tool, chained orchestration, and parallel tool calls. The tests are mocks rather than integration tests, but they document intended transcript mutations and `tool_choice` behavior.

Local telemetry is also useful. The `traceable` helper logs nested runs with parent ids and captures both normal outputs and stack traces. It is not a full tracing backend, but the shape maps well to tool-call ledgers.

## Weaknesses

There is no permission or sandbox boundary. Any decorated function is arbitrary Python running in the host process. The docs and notebooks include file-reading and Google Search examples, but there is no approval gate, path policy, network policy, credential mediation, side-effect tagging, or process isolation.

Ordinary action arguments are not validated by the generated Pydantic model at execution time. The model schema helps the LLM produce arguments, but `Action.__call__` invokes the function directly. This is fine for convenience, but dangerous if developers assume Pydantic validation is automatic.

The chat loop has no maximum iteration count. It stops only when the model returns content with finish reason `stop`, a `stop=True` action fires, token budget raises, or an exception escapes/handler returns. A model that repeatedly calls tools can run indefinitely until external limits intervene.

The exception-handler path appears fragile if the underlying API call raises before `api_response` is assigned. The `except` block includes `"response": api_response` in the handler context, but `api_response` is not initialized before the try block in the new OpenAI and Azure loops.

Orchestration validation is shallow. `validate_orch` checks only that keys are strings. `ActionHandlers.check_orchestration_expr_validity` exists but is not called by `build_orch`. Invalid values fail later in `Tools.from_expr` or `Functions.from_expr`, and duplicate action names silently overwrite earlier actions.

Streaming support is brittle. Content-first streams are returned to the caller without tool-loop handling. Tool-call streams are fully buffered and merged. Empty streams or unexpected chunk shapes are not robustly handled.

Parallel tool calls are supported but not parallel. Multiple tool calls in a single assistant message execute sequentially, and when multiple distinct tool names appear, the code ignores `orch` and `stop` for that round. The orchestration notebook explicitly warns that orchestration is limited to a single action invoked per API call.

Core memory is absent. The stateful-agent notebook relies on user-managed `self.messages`, and the loop does not append final assistant messages. There is no history compaction, memory namespace, provenance, retention, or injection defense.

Some docs are stale relative to the reviewed package. `docs/source/getting_started/concepts.md` and the `ReAct.ipynb` notebook reference `ActionHandlerMixin`, `SelectOne`, `RequireNext`, and older import paths that are not exported by the current `actionweaver/__init__.py`. Treat docs as examples, not authoritative runtime description.

Async clients are explicitly unsupported for patching, and async tool invocation is not implemented. Long-running or blocking tools have no cancellation path.

## Ideas To Steal

Use a small `Action` object as the internal tool unit: stable name, callable, schema, description, stop policy, and optional wrappers. Keep the model-facing schema and host-execution callable linked but separately auditable.

Add scoped tool visibility as a first-class tool registry feature. A simple default scope plus action-name follow-up map is enough to build hierarchies and chains without a full planner.

Expose forced actions for structured extraction. Setting tool choice to one action and then closing the tool surface is a clean pattern for "return this Pydantic model" tasks.

Make exception handlers return loop actions, not booleans. `Continue` and `Return` are good minimal primitives. Agentic Coding Lab could extend them with `RetryAfter`, `EscalateForApproval`, `AbortTool`, or `SwitchToolSet`.

Support schema transforms such as `combine`, `repeat`, and `action_from_model`. These are useful for reducing tool-call chatter and turning repeated model calls into one structured call.

Preserve function signatures through wrappers. The `decorators=[...]` argument and `utils/cache.py` helpers show why schema capture and runtime decoration order matter.

Track token budget in the runtime. `TokenUsageTracker` is simple, but the idea belongs in any tool loop that may iterate.

Use local trace metadata around every tool and LLM call. Parent run ids, inputs, outputs, errors, and timestamps are a practical base for replayable tool-call ledgers.

## Do Not Copy

Do not execute arbitrary coding-agent tools by direct Python call without a policy layer. Add command allowlists, filesystem scopes, network controls, approval prompts, timeouts, cancellation, and audit records.

Do not assume OpenAI JSON schema compliance is validation. Validate or coerce arguments at the host boundary before side effects. For Python, use `pydantic.validate_call`, explicit model validation, or a generated adapter that always validates.

Do not run an unbounded model-tool loop. Add max turns, per-tool limits, budgets, cancellation, and clear terminal states.

Do not mutate caller message history as the only loop ledger. Keep an internal transcript, append final assistant output consistently, and write structured events for tool calls, retries, errors, approvals, and observations.

Do not rely on monkey patching as the only integration style. `wrap` is cleaner than `patch`; a coding-agent runtime should prefer explicit adapters over mutation of SDK clients.

Do not use stale docs as API truth. Verify exported symbols and import paths from package code and tests before reusing cookbook patterns.

Do not treat multiple model-requested tools as safe parallelism. Tool calls need dependency checks, independent failure handling, cancellation, and side-effect ordering before true parallel execution.

## Fit For Agentic Coding Lab

Fit is conditional. ActionWeaver should not be adopted as a runtime foundation, but it is a good design reference for a narrow "tool-use ergonomics" module.

The best reusable pieces are the function-to-schema action object, the action-name registry, `orch` as scoped visibility, forced single-tool extraction, exception handlers that can inject observations, and schema-level transforms such as Pydantic extraction and repeat/combine actions.

For Agentic Coding Lab, these patterns need stronger boundaries: validated adapters around every action, risk metadata, permission checks before execution, process or command sandboxing for code tools, deterministic loop limits, token and time budgets, durable event logs, replay fixtures, final-message handling, and cancellation.

This repo is most useful as a contrast case: it shows how little framework code is needed to make tool calling pleasant, and exactly what must be added before tool calling is safe enough for agentic coding.

## Reviewed Paths

- `README.md` for project scope, public examples, `wrap`, `action`, `invoke`, `orch`, `stop`, and exception-handler claims.
- `pyproject.toml` for package version and dependency surface.
- `actionweaver/__init__.py` and `actionweaver/llms/__init__.py` for exported public API.
- `actionweaver/actions/action.py` for `Action`, `InstanceAction`, `ActionHandlers`, `Action.invoke`, schema details, descriptors, and direct execution.
- `actionweaver/actions/factories/function.py` for decorator-to-action construction.
- `actionweaver/actions/factories/pydantic_model_to_action.py` for structured extraction actions and host-side `model_validate`.
- `actionweaver/actions/factories/combine.py`, `repeat.py`, and `langchain.py` for tool composition and external tool adaptation.
- `actionweaver/actions/factories/instructor.py` to confirm it is empty in this snapshot.
- `actionweaver/llms/wrapper.py` and `patch.py` for explicit wrapper vs monkey-patch integration.
- `actionweaver/llms/openai/tools/chat_loop.py` for the main OpenAI `tools` loop, `argument_check`, `build_orch`, `invoke_tool`, streaming handling, exception handler context, and final return behavior.
- `actionweaver/llms/openai/tools/tools.py` for action-expression serialization to OpenAI `tools` and `tool_choice`.
- `actionweaver/llms/openai/tools/chat.py` for class-based patch implementation and behavior covered by tests.
- `actionweaver/llms/azure/chat_loop.py`, `chat.py`, and `functions.py` for Azure `functions` path.
- `actionweaver/llms/openai/functions/chat.py` and `functions.py` for deprecated OpenAI `functions` implementation.
- `actionweaver/llms/general/action_processor.py` and `tools.py` for generic JSON extractor and action dispatch.
- `actionweaver/llms/exception_handler.py` and `loop_action.py` for `ExceptionHandler`, `ChatLoopInfo`, `Continue`, `Return`, and `Unknown`.
- `actionweaver/utils/pydantic_utils.py`, `cache.py`, `stream.py`, `tokens.py`, `output.py`, and `action_scope.py` for schema creation, signature preservation, streaming merge, token budget, output appending, and default scope.
- `actionweaver/telemetry/helpers.py` for local tracing and parent run id propagation.
- `actionweaver/mixins/examples/langchain.py`, `folium.py`, and `openai.py` for optional demo mixins and side-effect examples.
- `tests/actions/test_action.py`, `tests/actions/factories/*.py`, `tests/utils/test_pydantic_utils.py`, `tests/llms/general/test_action_processor.py`, `tests/llms/openai/tools/test_chat.py`, and Azure tests for expected schema and loop behavior.
- `docs/source/getting_started/introduction.md`, `concepts.md`, `docs/source/blogpost/function_validation.md`, `langsmith.md`, and selected cookbook notebooks for usage examples, stale APIs, stateful-agent patterns, exception retries, orchestration caveats, and parallel-tool behavior.
- Repository-wide search for `sandbox`, `permission`, `ExceptionHandler`, `TokenUsageTracker`, `DEFAULT_ACTION_SCOPE`, `ActionHandlerMixin`, `SelectOne`, `RequireNext`, `memory`, and `stateful` to confirm safety and context features.

## Excluded Paths

- `poetry.lock`: generated lockfile. It was not used for design analysis beyond acknowledging dependency pinning exists.
- `docs/figures/*.png`, `docs/source/notebooks/cookbooks/figures/*.png`, README badge images, and logo assets: static visual documentation, not execution logic.
- `.readthedocs.yaml`, `docs/Makefile`, `docs/requirements.txt`, `docs/source/conf.py`, and `docs/source/index.rst`: documentation build configuration, not tool-use runtime.
- Notebook output cells in `docs/source/notebooks/cookbooks/*.ipynb`: reviewed only where they revealed runtime examples or import failures; generated outputs were not treated as source of truth.
- `tests/notebooks/run.py`: notebook runner metadata, not framework behavior.
- `actionweaver/mixins/examples/openai.py`: entirely commented image-generation demo, not active runtime.
- `actionweaver/actions/factories/instructor.py`: empty file in reviewed snapshot.
- `LICENSE`, `docs/source/community/contact.md`, and contribution/community metadata: not relevant to execution paths, validation, orchestration, memory, sandboxing, or error handling.
- No vendored dependency tree, build artifact directory, or UI-only app source was present in the reviewed snapshot. The repository is Python source, docs, notebooks, tests, and generated documentation/media assets.
