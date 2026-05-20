# galatolofederico/microchain

- URL: https://github.com/galatolofederico/microchain
- Category: tool-use
- Stars snapshot: 291 (GitHub REST API repository metadata, captured 2026-05-20)
- Reviewed commit: b931f1afb21b601dfd8e1e8b343fe3ab39462164
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: in-scope
- Verdict: Small but useful reference for Python-string tool calling without `eval`: registered `Function` objects expose prompt-visible signatures and examples, `Engine.execute()` parses model output with `ast`, and `Agent.step()` retries with tool error feedback. Reuse the compact AST-gated execution pattern and self-documenting tool base class; do not copy the missing permission layer, weak runtime type validation, shared mutable defaults, or stacktrace-to-model error surface.

## Why It Matters

Microchain is a minimal implementation of the classic "LLM emits one valid Python function call" agent loop. That makes it valuable for Agentic Coding Lab because the whole tool path fits in a few files: tool declaration, registry, prompt documentation, parsing, execution, retry feedback, history update, and stop control are all visible.

The strongest lesson is that a coding agent can avoid exposing raw `eval` while still letting the model write familiar function-call syntax. `Engine.execute()` accepts only one `ast.Call`, rejects variables and expressions, maps constants into Python args/kwargs, and calls only functions explicitly registered in `Engine.functions`. That is a clean baseline for a small local tool gateway.

## What It Is

`microchain` is a lightweight Python package for function-calling agents. Users subclass `Function`, implement `description`, `example_args`, and `__call__`, register instances into an `Engine`, build a prompt with `engine.help`, then run an `Agent` over an `LLM` wrapper.

The package includes OpenAI-compatible text/chat generators, a Replicate Llama 3.1 chat generator, Hugging Face and Vicuna-style prompt templates, token/cost tracking, two built-in functions (`Reasoning`, `Stop`), examples for calculator and tic-tac-toe agents, and unit tests for engine parsing and agent retry behavior.

It is not an MCP server, tool marketplace, sandbox runtime, or production permission system. It is best read as a concise tool-use runtime skeleton.

## Research Themes

- Token efficiency: Moderate. Tool docs are plain text built from signatures/descriptions/examples, and `Agent` carries only alternating assistant tool calls and user tool outputs. There is no retrieval, summarization, context pruning, per-turn budget, or output truncation.
- Context control: Moderate. `engine.help` is an explicit prompt inclusion gate, `bootstrap` seeds initial tool calls, `transient_history` can add ephemeral messages to one step, and templates separate chat-history formatting from generation. Context policy remains caller-authored prompt text.
- Sub-agent / multi-agent: Low. One `Agent` owns one `Engine` and one history. Hooks can observe iterations, but there is no worker dispatch, delegated agents, queue, or inter-agent memory.
- Domain-specific workflow: Medium. Domain tools are simple Python classes sharing `engine.state`; examples show calculator and tic-tac-toe workflows. There is no domain DSL beyond Python function signatures and examples.
- Error prevention: Medium. AST parsing blocks arbitrary expressions and unregistered names; retry feedback loops model errors back into the next call; max tries bound retries. Runtime types, permissions, side effects, secrets, and tool result size are not enforced.
- Self-learning / memory: Low. `Engine.state` is an in-memory mutable dict shared by tools, useful for board state or scratch state. There is no persistence, provenance, scoring, compaction, or memory review flow.
- Popular skills: Function-as-tool schema generation, prompt-visible tool registry, AST-gated command parsing, one-call-per-step agent loop, retry with structured error messages, bootstrap examples, host-controlled stop function, shared state injection into tools.

## Core Execution Path

Tool definition path:

1. A user subclasses `Function`.
2. `Function.__init__()` inspects the subclass `__call__` signature and requires every parameter to have a type annotation.
3. `Function.example` binds `example_args` against that signature and renders a concrete call such as `Sum(a=2, b=2)`.
4. `Function.signature`, `Function.help`, and `Function.error` derive prompt-facing documentation and retry guidance from the signature, description, and example.

Registry and prompt path:

1. `Engine.__init__()` creates `state`, `functions`, `help_called`, and an optional bound `agent`.
2. `Engine.register(function)` stores the tool under `function.name`, which is the class name, then calls `function.bind(state=self.state, engine=self)`.
3. `Function.bind()` gives each tool access to shared state and the owning engine. If Langfuse is enabled on the bound agent, it wraps `__call__` with tracing.
4. `Engine.help` flips `help_called = True` and joins all registered `f.help` strings. `Engine.execute()` refuses to run if the prompt never accessed help, making tool documentation an enforced setup step.

Model step path:

1. `Agent.run()` requires either `prompt` or `system_prompt`, resets history unless resuming, builds initial messages, executes bootstrap commands, then loops for `iterations`.
2. `Agent.step()` calls `llm(self.history + transient_history + temp_messages, stop=self.stop_list)`.
3. `Agent.clean_reply()` strips whitespace, unescapes `\_`, and truncates after the last `)`. This trims trailing natural-language text and turns no-parenthesis replies into an empty retry case.
4. Empty replies append `assistant: ...` and `user: Error: please provide a valid function call` to temporary retry messages.
5. Non-empty replies go to `Engine.execute()`. On error, the bad reply and engine error output are appended to temporary retry messages, so the retry sees its own failed command and the correction hint.
6. On success, `Agent.run()` appends the assistant command and user tool output to durable history. `Stop.__call__()` invokes `engine.stop()`, which sets `agent.do_stop = True`.

Command execution path:

1. `Engine.execute(command)` requires a bound agent and prior `engine.help` access.
2. It parses the command with `ast.parse(command)`.
3. It accepts exactly one top-level expression, and that expression must be an `ast.Call` whose function is an `ast.Name`.
4. It rejects positional args unless each is `ast.Constant`.
5. It rejects keyword args unless each value is `ast.Constant`.
6. It extracts raw Python constant values, verifies the function name exists in `self.functions`, checks total arg count equals the function signature arity, and calls `Function.safe_call(args, kwargs)`.
7. `Function.safe_call()` catches exceptions. `TypeError` and `SyntaxError` become the tool's format error; all other exceptions return a stacktrace string to the model as `Error inside function call: ...`.

Model adapter path:

1. `LLM.__call__()` applies each configured template in order, then calls the generator.
2. `OpenAIChatGenerator` expects a list of OpenAI chat messages and calls `client.chat.completions.create(...)`.
3. `OpenAITextGenerator` expects a string prompt and calls `client.completions.create(...)`.
4. `HFChatTemplate` converts chat messages to a generation string with `tokenizer.apply_chat_template(...)`; `VicunaTemplate` renders a simple `User:`/`Assistant:` transcript.
5. `ReplicateLlama31ChatGenerator` applies a tokenizer chat template, streams Replicate prediction output, joins events, and updates token usage from tokenizer counts.

## Architecture

The architecture has three layers:

- Tool layer: `Function` subclasses define callable tools, examples, descriptions, and optional access to shared `state` plus `engine`.
- Execution layer: `Engine` is a registry and parser. It owns allowed tool names and rejects model output that is not a single constant-only function call.
- Orchestration layer: `Agent` owns chat history, retry messages, iteration hooks, bootstrap calls, stop state, and the LLM adapter.

The package keeps model I/O separate from tool execution. `LLM` and generator classes do not know about registered tools; tools are exposed only through prompt text and the `Agent` loop. This is simple and provider-agnostic, but it means there is no native function-calling schema sent to OpenAI or Replicate.

`engine.state` is the only shared memory surface. It lets tools coordinate, as in tic-tac-toe where `State` and `PlaceMark` both read/write the same board object. This is useful for local stateful workflows, but it is not isolated per tool and has no schema or concurrency protection.

## Design Choices

- Python function-call syntax as the model protocol. The model is told to output valid Python calls, but host code parses with `ast` instead of evaluating the string.
- Class-name registry. A tool's callable name is `type(self).__name__`, so subclass names are the user-facing command names.
- Prompt docs from code. Signatures, annotations, descriptions, and examples are assembled automatically into `engine.help`.
- Help-before-execute guard. `Engine.execute()` refuses execution until `engine.help` has been accessed, preventing accidental prompts without available function docs.
- Constant-only arguments. Args and kwargs must be literals represented by `ast.Constant`, blocking variables, arithmetic expressions, attribute access, list/dict construction, and nested function calls.
- Single command per turn. Multiple expressions or non-call output are rejected, keeping action boundaries easy to audit.
- Error-as-observation retry. Engine/tool errors are written into temporary chat history, giving the model a bounded chance to repair malformed calls without contaminating durable history until success.
- Bootstrap calls. `Agent.bootstrap` executes real tool calls before the LLM loop and appends their results to history, showing the model examples grounded in actual tool output.
- Host-controlled stop. `Stop` is just another function, but it reaches back through `self.engine.stop()` to end the loop.
- Optional tracing wrappers. Agent, function, and generator methods can be wrapped with Langfuse decorators when enabled.

## Strengths

- Very small readable implementation. The relevant tool-use path is concentrated in `function.py`, `engine.py`, and `agent.py`.
- Avoids `eval`/`exec` for model commands. AST parsing plus registry lookup is a useful safety baseline for string-based tool calls.
- Tool documentation is hard to forget. The `help_called` guard forces prompt construction to reference `engine.help` before execution.
- Tool examples are executable-looking and generated from the same signature that execution uses.
- Retry behavior is concrete. The model sees the exact malformed call and a precise correction hint, while the main history only records successful steps.
- Bootstrap examples are real commands, not static prompt samples. This lets examples also initialize state.
- Shared state is simple and effective for small domains where multiple tools need one mutable object.
- Tests cover binding requirements, missing help, syntax errors, non-call output, expression rejection, unknown functions, argument arity, successful calls, empty replies, max tries, and quoted string examples.

## Weaknesses

- No permission or sandbox layer. Any registered `Function` runs in the host process with normal Python authority. The AST gate constrains the model command string, not tool side effects.
- Runtime type validation is weak. Annotations are required for documentation, but execution does not enforce types before calling the tool; Python functions receive whatever literal values the AST produced.
- Supported argument shapes are narrow. Only `ast.Constant` values pass, so lists, dicts, structured objects, enums, and nested schemas are unavailable without encoding them as strings.
- Function names collide silently. Registering two classes with the same class name overwrites the earlier entry in `Engine.functions`.
- Shared mutable defaults exist. `Engine(state=dict())`, `Agent(stop_list=["\n"])`, `Agent.step(transient_history=[])`, `Agent.run(transient_history=[])`, `LLM(templates=[])`, and generator defaults such as `TokenTracker()` can share objects across instances.
- Tool exceptions can leak internals. Non-`TypeError` exceptions return full stacktraces to the model, which may expose paths, values, or secrets.
- Provider errors collapse to `"Error: timeout"`. OpenAI API errors are caught broadly and returned as timeout text, losing status, retryability, rate-limit, auth, and network distinctions.
- Token tracking is observability only. It has a static price table, no hard budget, and no automatic context trimming.
- No durable trace or audit ledger. Console prints are the main trace, with optional Langfuse wrappers if installed.
- No concurrency model. Shared state and mutable defaults make concurrent or multi-agent use unsafe without caller discipline.

## Ideas To Steal

- Use an AST-gated command parser for simple local coding tools. Accept one call, reject expressions, and map only registered tool names.
- Generate tool docs from code artifacts: name, typed signature, description, and a bound example. This keeps prompt docs aligned with tool handlers.
- Add a setup guard that refuses execution if the tool registry documentation was not included in context.
- Keep failed retries in transient history until a tool call succeeds. Durable histories stay cleaner, while the model still gets repair feedback.
- Make bootstrap examples actual tool calls. They both teach the model call format and initialize state through the same execution path as normal steps.
- Treat `Stop` as a registered capability. Agent loop termination becomes visible and auditable instead of a hidden parser convention.
- Expose lifecycle hooks around iteration start, step, and end. Hooks are enough for lightweight tracing or UI updates without coupling them into the core loop.
- Keep provider adapters thin and behind a single `LLM(messages, stop=...)` interface so orchestration is not tied to one model API.

## Do Not Copy

- Do not treat AST parsing as a full sandbox. It only protects against direct expression execution; registered tools still need side-effect policy, approval gates, and process/filesystem/network boundaries.
- Do not rely on annotations as validation. Add schema validation before tool execution and report typed validation errors.
- Do not expose full stacktraces to the model by default. Store detailed traces in a private log and return sanitized, retry-useful diagnostics.
- Do not use shared mutable defaults for state, histories, stop lists, templates, or token trackers.
- Do not collapse provider failures into `"Error: timeout"`. Preserve error class, retryability, status code, and user-safe message.
- Do not build production tool registries from class names alone. Use stable explicit names, duplicate detection, versioning, descriptions, risk tags, and ownership metadata.
- Do not allow arbitrary host-power tools without permission metadata and audit logs, even if the model can only call them with constants.
- Do not make prompt text the only policy layer. Enforce max iterations, budgets, allowed tools, argument schemas, output limits, and approval requirements in code.

## Fit For Agentic Coding Lab

Fit is high as a small reference implementation for a tool-use lab module. The repo demonstrates the minimum viable mechanics of a local function-call loop without hiding behavior behind a large framework.

Best adaptation for Agentic Coding Lab:

- Start with Microchain's `Function` pattern: one base class that introspects a callable and emits prompt docs.
- Replace class-name registration with explicit `ToolSpec` metadata: name, version, owner, args schema, result schema, side-effect class, permission requirement, and examples.
- Keep the AST-gated one-call parser for a "simple mode", but extend validation to structured literals or switch to JSON Schema when tools need arrays/objects.
- Keep transient retry history, but return structured errors such as `{code, message, retryable, field_errors, safe_detail}`.
- Put registered tools behind a gateway that enforces filesystem/network/shell permissions and records a tool-call ledger.
- Use `engine.state` idea only for scoped session state with schema, provenance, reset behavior, and locking.
- Add private trace storage for stacktraces and public sanitized observations for the model.
- Add tests around duplicate tools, type mismatches, permission denials, secret redaction, output limits, and max-budget termination.

This repo should not be adopted as a dependency for Agentic Coding Lab. Its value is as a compact teaching and design reference for string-call parsing, self-documenting tools, and retry orchestration.

## Reviewed Paths

- `README.md`: package purpose, installation, OpenAI/text/chat setup, `Function` authoring pattern, `Engine` registration, prompt construction with `engine.help`, bootstrap examples, and calculator run trace.
- `microchain/__init__.py`: public package exports for generators, templates, `LLM`, `Function`, `FunctionResult`, `Engine`, `Agent`, and `StepOutput`.
- `microchain/engine/function.py`: `Function` signature introspection, annotation requirement, example binding, help/error rendering, engine/state binding, Langfuse wrapping, and exception-to-result handling.
- `microchain/engine/engine.py`: registry, agent binding, stop delegation, help guard, AST parse/validation path, constant-only argument extraction, function lookup, arity check, and safe-call dispatch.
- `microchain/engine/agent.py`: history lifecycle, prompt/system prompt construction, bootstrap execution, reply cleanup, retry loop, transient retry messages, max tries, hooks, stop handling, and durable history writes.
- `microchain/functions.py`: built-in `Reasoning` scratchpad function and `Stop` loop-control function.
- `microchain/models/llm.py`: provider-independent wrapper that applies templates then calls a generator.
- `microchain/models/openai_generators.py`: OpenAI-compatible chat/text generator setup, stop parameter forwarding, OpenAI error catch, token usage update, and usage printing.
- `microchain/models/llama_generators.py`: Replicate Llama 3.1 chat generator, tokenizer template usage, streaming output join, Langfuse wrapper, and token tracking.
- `microchain/models/templates.py`: Hugging Face chat template adapter and Vicuna-style transcript renderer.
- `microchain/models/token_tracker.py`: accumulated prompt/completion token counts and hard-coded model price lookup.
- `examples/calculator.py`: calculator tool definitions, environment-driven OpenAI text generator, HF template, tool registration, prompt docs, bootstrap reasoning call, and `agent.run()`.
- `examples/tic-tac-toe.py`: shared `engine.state` board, state-reading tool, side-effecting move tool, opponent simulation, stop on game over, and stateful prompt workflow.
- `examples/README.md`: sample calculator and tic-tac-toe traces showing model-visible tool calls and tool observations.
- `tests/test_engine.py`: expected errors for unbound engines, missing help, syntax/non-call/expression failures, unknown tools, arity errors, and successful execution.
- `tests/test_agent.py`: prompt requirement, bootstrap error propagation, empty reply retries, and max-tries abort behavior.
- `tests/test_str_args.py`: quoted string example generation.
- `tests/test_openai.py`: OpenAI generator error path for wrong API key, including the broad `"Error: timeout"` behavior.
- `setup.py`, `requirements.txt`, and `requirements_dev.txt`: package name/version, dependency surface, Python/package scope, and test dependencies.
- `.github/workflows/pr-check.yaml` and `.github/workflows/pypi.yaml`: CI/publish tests were skimmed to understand verification posture.

## Excluded Paths

- `.git/`: cloned repository metadata, not source design.
- `LICENSE`, `.gitignore`, and repository metadata fields in `setup.py`: reviewed only enough to understand packaging and ignored artifacts; they do not define agent execution behavior.
- `.github/workflows/*.yaml`: CI and publishing automation. Skimmed for verification posture, excluded from design analysis because it does not affect runtime tool execution.
- `requirements*.txt`: dependency manifests. Reviewed for dependency surface only; no behavior beyond imports and optional integrations.
- Generated/vendor paths: no vendored dependency directory, lockfile, generated source, or model artifact is present in the reviewed snapshot.
- UI-only paths: none present in the reviewed snapshot.
