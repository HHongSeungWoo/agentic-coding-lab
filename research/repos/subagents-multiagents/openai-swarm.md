# openai/swarm

- URL: https://github.com/openai/swarm
- Category: subagents-multiagents
- Stars snapshot: 21,513 via GitHub REST API on 2026-05-20
- Reviewed commit: 6af0b4caf37dca4526dfd98e9fbd8ce36e7eeb22
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: in-scope
- Verdict: High-signal educational reference for small, client-side multi-agent handoffs, `Result`-based state updates, context-variable injection, and function-call evals. Do not use it as production runtime: the repo now points production users to OpenAI Agents SDK, tools execute as raw in-process Python, error handling is thin, examples have drift, and there is no durable trace, sandbox, permission model, or memory layer.

## Why It Matters

Swarm is useful because it shows the smallest viable shape of multi-agent orchestration. The core package is only a few Python files, so the handoff semantics are easy to inspect: an agent exposes functions as Chat Completions tools, a tool can return another `Agent`, and the host loop swaps the active system prompt while keeping conversation history.

For Agentic Coding Lab, the value is not the package itself. The value is the precise contract between model-selected tool calls, host-executed functions, handoff by return value, and caller-owned state. Swarm also exposes the limits of this design: if the host does not own sandboxing, retries, audit, structured errors, and durable state, a clean handoff primitive is not enough for safe coding-agent work.

## What It Is

Swarm is an experimental, educational Python framework from OpenAI Solutions for lightweight multi-agent orchestration. The README now says Swarm has been replaced by the OpenAI Agents SDK for production use cases. It is powered by Chat Completions, not Assistants, and it does not store state between calls.

The public package exports `Swarm`, `Agent`, and `Response`. `Agent` is a Pydantic model with `name`, `model`, `instructions`, `functions`, `tool_choice`, and `parallel_tool_calls`. `Result` is the richer return type that can carry a tool result value, a next agent, and context-variable updates. `Swarm.run()` owns the loop that calls the active agent, executes tool calls, updates context, switches agents, and returns only the newly generated messages plus the final agent and context.

The repo includes examples for bare-minimum calls, function calling, agent handoff, context variables, triage, weather, airline customer service routines, support bots, personal shopping, and a separate customer-service-streaming experiment. Tests focus on the small core and function-schema conversion, with additional example evals that inspect proposed tool calls.

## Research Themes

- Token efficiency: Only the active agent's `instructions` become the system prompt on each model call. Context variables are hidden from the tool schema and injected host-side when a function asks for them. `Response.messages` returns new messages only, so the caller can decide what history to retain. There is no token budgeter, compactor, retrieval layer, or cost tracker; full caller-supplied history is passed back into each turn.
- Context control: The caller owns `messages` and `context_variables`. Instructions can be a callable that receives context variables, and tools can receive the same private context through a reserved `context_variables` parameter. Handoff changes the active system prompt while preserving chat history. There is no explicit untrusted-context boundary, source labeling, context provenance, or memory isolation.
- Sub-agent / multi-agent: A handoff is just a tool function returning an `Agent`, or a `Result` with `agent` set. Agents can represent people, workflow steps, task phases, or policy traversals. There is no parallel subagent execution; `parallel_tool_calls` is passed to the model, but returned tool calls are executed sequentially in Python, and the last agent returned by multiple handoff calls wins.
- Domain-specific workflow: The airline example models routines as prompt-only policy traversals plus allowed functions and transfer functions. Triage routes to flight modification or lost baggage; flight modification routes to cancel or change; policy agents call side-effect-like functions such as refund, flight credits, baggage search, or `case_resolved`.
- Error prevention: Useful controls are minimal: `execute_tools=False` interrupts before tool execution, `max_turns` bounds the loop, active-agent function lists act as a narrow allowlist, and missing tool names produce an error tool message. Function argument errors, `json.loads` failures, and function exceptions are not broadly caught despite README language saying function-call errors are appended so agents can recover.
- Self-learning / memory: Swarm has no built-in memory. Continuity comes from the caller passing back `response.messages`, `response.agent`, and `response.context_variables` into later runs. Example logs are generated artifacts, not runtime memory primitives.
- Popular skills: Handoff tools, `Result` return envelopes, context-variable injection, callable instructions, active-agent-only system prompts, dry-run tool-call evals with `execute_tools=False`, prompt-policy routines, and REPL-style caller-owned state.

## Core Execution Path

`Swarm.__init__` accepts an injected client for tests or creates `OpenAI()`. `Swarm.run()` deep-copies `messages` and `context_variables`, records the initial message count, sets `active_agent`, and loops while generated history length is below `max_turns`.

For each iteration, `get_chat_completion()` builds a system message from the active agent's instructions. If `instructions` is callable, it is called with `context_variables`; otherwise the string is used directly. The active system message is prepended to the caller-supplied history. Each active-agent function is converted into a Chat Completions tool schema with `function_to_json()`.

`context_variables` is a reserved hidden argument. After schema generation, `get_chat_completion()` removes the `context_variables` property from each tool schema and removes it from `required`, so the model cannot fill it. If the agent has tools, `parallel_tool_calls` is passed through from the `Agent`.

The completion response's assistant message is tagged with `sender = active_agent.name` and appended to local history as JSON. If the message has no tool calls, or `execute_tools=False`, the loop stops and returns a `Response`.

When tool calls exist and execution is enabled, `handle_tool_calls()` maps available functions by `__name__`, then processes model-specified calls in order. Missing function names append a `role: tool` message with `Error: Tool <name> not found.` and continue. Found calls parse JSON arguments, inject `context_variables` when the function's local variable names include that reserved parameter, then invoke the Python function directly.

`handle_function_result()` normalizes function returns. Returning `Result` preserves value, next agent, and context updates. Returning an `Agent` becomes `Result(value='{"assistant": "<agent name>"}', agent=<agent>)`. Any other value is cast to `str`. The tool result message is appended, returned context updates are merged into the copied context, and the final returned agent in that batch becomes the next `active_agent`.

`run_and_stream()` follows the same high-level path but streams chunks, merges partial content/tool-call deltas with `merge_chunk()`, yields `{"delim": "start"}` and `{"delim": "end"}` around each active-agent response, then yields a final `{"response": Response(...)}` object.

## Architecture

The architecture is deliberately tiny. `swarm/core.py` contains the orchestration loop, tool execution, streaming aggregation, handoff processing, and context merging. `swarm/types.py` defines Pydantic models for `Agent`, `Response`, and `Result`, and imports OpenAI SDK chat types. `swarm/util.py` contains debug printing, streaming merge helpers, and Python-function-to-JSON-schema conversion. `swarm/repl/repl.py` provides a caller loop that extends message history and keeps the returned active agent between turns.

`function_to_json()` uses `inspect.signature()` and a small type map for `str`, `int`, `float`, `bool`, `list`, `dict`, and `None`. It uses the function docstring as the tool description and marks parameters without defaults as required. It does not parse per-parameter docstrings into JSON Schema descriptions, and it does not model nested objects, enums, unions, literals, Pydantic models, or side-effect metadata.

The primary runtime boundary is each agent's `functions` list. The model can request only functions exposed by the active agent, and the host maps names back to Python callables. This is a useful allowlist shape, but it is not a sandbox: the function body runs with the Python process authority.

Examples add domain patterns on top of the same primitive. `examples/triage_agent/agents.py` creates transfer functions for sales/refunds and backlinks to triage. `examples/airline/configs/agents.py` uses triage and policy traversal agents, with `parallel_tool_calls=False` on flight modification to avoid simultaneous cancel/change routing. `examples/airline/data/routines/*.py` keeps policies as prompt text. `examples/support_bot/customer_service.py` shows retrieval and side-effect tools around Qdrant, OpenAI embeddings, email, and tickets. `examples/customer_service_streaming/src/**` is a separate experimental engine with JSON configs, planner prompts, dynamic tool-handler imports, optional human-input flags, and Assistants/Local backends rather than the main `swarm/core.py` loop.

Tests use an injected `MockOpenAIClient` rather than live API calls. `tests/test_core.py` covers simple assistant messages, one tool call, `execute_tools=False`, and a handoff. `tests/test_util.py` covers basic and typed function-schema conversion. Example evals for triage/weather/airline use live-style model calls and assert expected function names or LLM-judged success.

## Design Choices

Swarm makes handoff a normal tool result instead of a separate orchestration API. A transfer function can be as small as `return sales_agent`. This keeps the mental model simple: agents are switched by executing model-requested functions whose return values are interpreted by the host.

`Result` is the key compositional object. It lets one function return content to the model, transfer to another agent, and update context variables in one envelope. That is the repo's most reusable state contract.

Context variables are host-private by convention. The model sees whatever the active instructions decide to include, but it does not see `context_variables` as a tool parameter. Function injection is automatic based on a reserved parameter name, which is ergonomic but implicit.

The active agent's instructions are the only system prompt for a turn. On handoff, Swarm changes the system prompt while leaving prior user, assistant, and tool messages in history. This makes "agent" closer to "workflow step with a prompt and tools" than a durable actor.

Tool execution is sequential and synchronous. Even when the model is allowed to emit parallel tool calls, Swarm loops over them in order, merges all context updates, and uses the last returned handoff agent. The airline example disables parallel tool calls on a triage sub-step where multiple simultaneous handoffs would be confusing.

`execute_tools=False` is a deliberate observation boundary. The examples use it to test whether the model would call `transfer_to_sales`, `transfer_to_refunds`, or `get_weather` without executing the function. This is a strong eval pattern for coding agents: inspect proposed tool calls before side effects.

The framework is stateless by design. `Response` returns updated messages, final agent, and context variables; callers must pass them back in. That keeps the library simple and testable, but it leaves persistence, compression, privacy, and replay to the application.

## Strengths

- Very small core makes the actual orchestration contract easy to audit.
- Handoff-by-return-value is simple, composable, and readable in examples.
- `Result` cleanly combines tool output, agent transfer, and context updates.
- Callable instructions plus context-variable injection support lightweight personalization and private state.
- Context variables are stripped from tool schemas, so the model is not asked to fabricate private context arguments.
- Active-agent tool lists provide a natural per-agent function allowlist.
- `execute_tools=False` is useful for evals, approval gates, and dry-run side-effect review.
- The README accurately frames agents as workflow/task primitives, not only personas.
- Airline routines show a compact policy-traversal pattern: strict prompt policy, allowed tools, `case_resolved`, and transfer back to triage.
- Core tests are fast and client-injected, so the main loop can be tested without live OpenAI calls.
- The REPL helper demonstrates caller-owned continuity by extending history and preserving returned agent.

## Weaknesses

- The repo is explicitly educational and now superseded by OpenAI Agents SDK for production use cases.
- Tools execute as arbitrary in-process Python with no sandbox, path scope, command policy, network policy, approval gate, timeout, or audit log.
- README says wrong arguments and function errors are appended so agents can recover, but `handle_tool_calls()` only handles missing tool names. JSON parsing errors, Python argument mismatches, and function exceptions can propagate.
- `max_turns` is a coarse loop guard based on generated history length, not a strong model-call, tool-call, token, cost, or wall-clock budget.
- `parallel_tool_calls=True` by default can produce multiple stateful calls in one assistant message, but execution is sequential and the last handoff wins. That is risky for stateful routines unless disabled per agent.
- Function schemas are shallow. They miss nested structures, enums, literals, unions, parameter descriptions, read/write labels, idempotency, side-effect level, and return schema.
- Tool results are plain strings in the core loop. Dict returns are cast with Python `str()`, not serialized as structured JSON unless the tool author does it manually.
- Context-variable injection is based on a magic parameter name found in `func.__code__.co_varnames`, not an explicit annotation or wrapper contract.
- There is no durable trace object tying model call, tool call, tool result, context update, and handoff together.
- There is no built-in retry, rate-limit handling, cancellation, model-fallback policy, token accounting, or usage recording.
- Examples have drift. `examples/support_bot/customer_service.py` has an unfinished-work comment, `examples/personal_shopper/main.py` imports `swarm.agents.create_triage_agent` even though no such package path exists in this checkout, and that example passes `description` instead of the core `Agent.instructions` field.
- `examples/customer_service_streaming` is a separate experimental framework with dynamic handler imports, bare `except` blocks, and broad file writes; it should not be confused with the clean core package.
- Many example logs and article JSON files are generated or stale data snapshots, not maintained runtime fixtures.

## Ideas To Steal

Use return values as handoff contracts. A tool returning `Agent` is easy to teach; a tool returning `Result(agent=..., context_variables=..., value=...)` is the richer version worth copying.

Keep active-agent prompts and tools narrow. A coding workflow can represent "triage", "implementation", "review", "test diagnosis", and "handoff summary" as agents with distinct tools and instructions.

Hide host context from model-authored tool arguments. Let tools request private context through an explicit reserved parameter, then strip that parameter from the model-facing schema.

Make dry-run tool-call capture a first-class eval mode. `execute_tools=False` maps well to "would this agent call the right tool or delegate to the right subagent?" tests before any side effects occur.

Use prompt-policy routines with narrow tool sets for procedural workflows. The airline example's policy text plus allowed functions is a good starting shape for coding routines such as "bug report triage", "test failure diagnosis", or "release checklist".

Return only new messages from each run. This forces the caller to own state retention and makes it possible to add host-side compression, artifact references, or privacy filters before the next run.

Expose a final `Response` containing generated messages, final active agent, and context updates. That is a compact resumability envelope for higher-level orchestration.

Use simple mocked model clients for core loop tests. The mock-client pattern is enough to test handoff, tool-call interruption, and context updates without network calls.

## Do Not Copy

Do not execute arbitrary Python functions as if a model-facing tool allowlist were a security boundary. Coding agents need host-enforced permissions, workspace scopes, approvals, timeouts, structured logging, and sandboxed execution.

Do not rely on magic parameter names for private context injection without an explicit function wrapper or schema marker. It is ergonomic, but it hides a powerful data path.

Do not use shallow function signatures as a complete tool schema. Production coding tools need argument validation, return schemas, side-effect classification, and provenance.

Do not let parallel tool calls mutate shared context or trigger handoffs unless the runtime has clear merge semantics and tests. For state-machine workflows, default to one routing tool call at a time.

Do not treat string-cast tool results as enough. Use typed result envelopes with status, content, artifacts, errors, retryability, side-effect summary, and safety labels.

Do not copy the README's graceful-error claim without implementing it. Missing tools, malformed JSON, wrong arguments, and handler exceptions need separate recoverable error messages.

Do not depend on the example apps as maintained production samples. Several are educational sketches, have unfinished-work markers, or have broken imports in this commit.

Do not add hidden memory under this design without exposing it in the response/trace. Swarm's simplicity depends on caller-owned state; hidden memory would make behavior harder to audit.

## Fit For Agentic Coding Lab

Swarm is a strong pattern source and a poor drop-in dependency. Its best fit is as a minimal reference for host-mediated subagent handoff and context-variable state, especially for teaching or prototyping.

Agentic Coding Lab should steal the `Agent` plus `Result` contract, `execute_tools=False` eval mode, and active-agent-only prompt/tool narrowing. The lab should replace the unsafe parts with typed tool schemas, explicit context injection, deterministic routing where possible, durable traces, side-effect policies, sandboxed execution, structured errors, and artifact-backed handoff state.

A useful lab artifact would be a "Swarm-hardened handoff loop": function-return handoffs, `Result` state updates, dry-run tool proposals, and per-agent tool lists, backed by policy checks, command/file scopes, approval gates, and replayable event logs. Another artifact would be a routine evaluator that checks whether a triage agent selects the expected handoff/tool without executing it.

## Reviewed Paths

- `README.md`: project positioning, replacement by OpenAI Agents SDK, install, main loop, agent fields, callable instructions, function semantics, handoffs, `Result`, context variables, function schema rules, streaming, and eval guidance.
- `setup.cfg` and `pyproject.toml`: package metadata, dependency posture, Python version, and build shape.
- `swarm/__init__.py`: public exports.
- `swarm/core.py`: `Swarm` client setup, chat completion construction, hidden context-variable schema stripping, tool execution loop, return normalization, handoff handling, context merging, streaming delimiters, and response assembly.
- `swarm/types.py`: `Agent`, `Response`, `Result`, default fields, and OpenAI chat type imports.
- `swarm/util.py`: debug logging, streaming merge helpers, and function-to-JSON-schema conversion.
- `swarm/repl/repl.py`: command-line loop, message printing, streaming handling, caller-side history extension, and active-agent persistence.
- `tests/test_core.py`, `tests/test_util.py`, and `tests/mock_client.py`: core unit coverage, mocked OpenAI client behavior, tool-call interruption, handoff assertion, and schema tests.
- `examples/basic/README.md`, `agent_handoff.py`, `context_variables.py`, `function_calling.py`, and `simple_loop_no_helpers.py`: minimal handoff, context, function, and loop examples.
- `examples/triage_agent/agents.py`, `evals.py`, and `README.md`: triage/backlink handoffs and `execute_tools=False` function-call evals.
- `examples/weather_agent/agents.py`, `evals.py`, and `README.md`: simple function-calling agent and positive/negative weather tool evals.
- `examples/airline/README.md`, `main.py`, `configs/agents.py`, `configs/tools.py`, `data/routines/prompts.py`, `data/routines/flight_modification/policies.py`, `data/routines/baggage/policies.py`, `evals/function_evals.py`, and `evals/eval_utils.py`: policy-routine prompts, transfer functions, context-variable injection, side-effect stubs, function-call eval harness, and generated eval outputs by reference.
- `examples/support_bot/README.md` and `customer_service.py`: retrieval/tool example, Qdrant/OpenAI embedding boundary, transfer to help center, and unfinished-work status.
- `examples/personal_shopper/README.md`, `main.py`, and `database.py`: customer-service shopping/refund intent design, SQLite side effects, and example drift around missing `swarm.agents`.
- `examples/customer_service_streaming/src/swarm/*.py`, `src/swarm/engines/*.py`, `src/tasks/task.py`, `src/runs/run.py`, `configs/prompts.py`, and `src/swarm/tool.py`: separate experimental local/Assistants engines, planner prompt, dynamic handler import, human-input flag, task/eval structure, and context passing.
- `SECURITY.md`: disclosure-policy pointer only; no runtime security controls.

## Excluded Paths

- `assets/**`: logos and diagrams, useful for docs but not runtime behavior.
- `logs/**`, `examples/customer_service*/logs/**`, and `tests/test_runs/**`: generated conversation/test logs reviewed only by path inventory because they are outputs rather than source contracts.
- `examples/support_bot/data/**` and `examples/customer_service_streaming/data/**`: large help-center article snapshots treated as retrieval corpus data, not orchestration logic.
- `examples/airline/evals/eval_results/**`: generated eval result JSON reviewed only as evidence that examples store outputs.
- `examples/customer_service_streaming/configs/tools/*/tool.json` and `handler.py` files beyond tool-boundary spot checks: simple demo handlers and schemas; core boundary was represented by `Tool`, `LocalEngine`, and `AssistantsEngine`.
- `examples/customer_service_streaming/docker-compose.yaml`, `examples/support_bot/docker-compose.yaml`, `Makefile`, `requirements.txt`, `.gitignore`, and setup plumbing: operational support for demos, not multi-agent semantics.
- Binary/image files and external services such as Qdrant, OpenAI API, Chat Completions, Assistants, embeddings, SQLite runtime files, and Docker services: treated as boundaries; reviewed only through Swarm's adapter code and examples.
