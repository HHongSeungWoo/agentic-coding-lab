# rizerphe/local-llm-function-calling

- URL: https://github.com/rizerphe/local-llm-function-calling
- Category: tool-use
- Stars snapshot: 438 stars (GitHub repository page, captured 2026-05-20)
- Reviewed commit: eb6d7576759614cfc43b2cb8664ff12a698d5330
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: conditional
- Verdict: Useful as a compact pattern for local constrained tool-call generation: keep tool choice and argument generation separate, validate each token against a constraint, and leave execution to a separate boundary. Not a complete agent runtime because it has no permission model, sandbox, durable registry, retries, or execution layer.

## Why It Matters

This repo shows the smallest useful version of OpenAI-style function calling for local models. Its value for Agentic Coding Lab is not the prompt text or model adapters; it is the execution shape: represent tools as schemas, choose one allowed tool name under an enum constraint, then generate JSON arguments under a JSON-schema constraint before any external side effect can occur.

For coding agents, that pattern is reusable wherever a model proposes a structured operation but another layer owns execution. It reduces malformed calls before execution, makes tool-choice gating explicit, and creates a clean place to add policy checks between "model selected tool" and "tool runs".

## What It Is

`local-llm-function-calling` is a Python library for generating function-call objects with local LLM backends. Public users instantiate `Generator` with a list of OpenAI-like function schemas and a model adapter. `Generator.generate()` returns `{"name": ..., "arguments": ...}`; it does not call the function.

The library supports Hugging Face causal language models through `HuggingfaceModel`, optional llama.cpp models through `LlamaModel`, and model-specific prompt assembly through `TextPrompter` implementations. The core constrained decoding loop lives in `Constrainer`, which repeatedly asks the model for next-token logits sorted by probability and accepts the first candidate whose decoded text remains valid under the active constraint.

## Research Themes

- Token efficiency: Compact schemas are embedded directly in prompt text. There is no retrieval, schema compression, caching, or prompt-budget management beyond choosing between function-summary prompts and argument prompts.
- Context control: The design narrows context by phase. Function selection sees names and descriptions, while argument generation sees only the selected function's schema. The CodeLlama chat prompter can include prior user, assistant, and function messages, but has no pruning strategy.
- Sub-agent / multi-agent: No sub-agent or multi-agent orchestration exists. The transferable idea is a single-purpose constrained decoder that another orchestrator could call as a tool-call planner.
- Domain-specific workflow: Function schemas follow a simplified OpenAI-style shape with `name`, optional `description`, and object `parameters`. This makes it directly relevant to tool-use and coding-action planning.
- Error prevention: The main prevention mechanism is token-level validation with `EnumConstraint` and `JsonSchemaConstraint`. It catches invalid partial generations before they become completed calls, but does not validate semantic safety or execution permissions.
- Self-learning / memory: No persistent memory, feedback loop, or self-learning exists. Chat history support is prompt-only and caller-managed.
- Popular skills: Relevant skill pattern is "constrained local tool-call planner": schema registry in, validated tool-call proposal out, no execution side effects.

## Core Execution Path

1. Caller creates a list of function schemas and initializes `Generator(functions, model, prompter)` or `Generator.hf(functions, model, tokenizer, prompter)`.
2. `Generator.generate(prompt, function_call=None, ...)` calls `choose_function()` unless the caller already forced a function name.
3. Function choice builds a prompt with `prompter.prompt(prompt, functions)` and constrains decoding with `EnumConstraint([function["name"] + suffix, ...])`.
4. `_generate_allowed_in_enum()` delegates to `Constrainer.generate()`, then maps the generated enum value back to the raw function name.
5. `generate_arguments()` builds a second prompt with `prompter.prompt(prompt, functions, function_call)`, creates `JsonSchemaConstraint(selected_function["parameters"])`, and constrained-decodes JSON argument text.
6. The generated JSON string is truncated to the schema validator's `end_index` when available, then returned as `{"name": function_name, "arguments": arguments}`.
7. `respond()` adds an optional decision branch for prompters that support non-function responses: `should_call()` enum-constrains the choice between call marker strings and non-call marker strings, then returns either a function call or `natural_language()`.

The execution boundary is clear: model output stops at a structured function-call object. The repo never dispatches the named function, never touches external systems on behalf of the model, and never decides permissions.

## Architecture

The architecture has four small layers.

`prompter.py` defines typed function-schema shapes and prompt protocols. `CompletionModelPrompter` and `InstructModelPrompter` turn a natural language prompt plus function list into plain text. `prompters/llama_function_calling.py` adds a chat-aware CodeLlama prompter with user, assistant, and function message roles.

`generator.py` orchestrates tool selection, argument generation, optional should-call gating, and natural-language fallback. It owns the function registry as an in-memory list on each `Generator` instance.

`constrainer.py` owns validation-aware decoding. `EnumConstraint` validates function names or sentinel responses. `JsonSchemaConstraint` wraps `json-schema-enforcer` and converts each generated prefix into `(is_valid, is_complete)`.

`model/common.py`, `model/huggingface.py`, and `model/llama.py` isolate model-specific token handling behind `Model` and `Generation` protocols. Hugging Face and llama.cpp adapters both expose `start_generation(prefix)`, `get_sorted_tokens()`, `register_token(token)`, and `get_generated(candidate)`.

## Design Choices

The best design choice is separating tool selection from argument generation. Function choice is an enum problem; arguments are a schema problem. Treating them separately keeps constraints simpler and gives an agent runtime a policy hook after tool selection but before argument generation or execution.

The second strong choice is making model adapters yield sorted token candidates instead of letting the model sample freely. `Constrainer.gen_next_token()` scans candidates in probability order and accepts the first candidate that keeps the partial output valid. This greedy strategy is easy to reason about and works across backends, though it can get stuck without backtracking.

The schema registry is deliberately minimal: just a list passed to `Generator`. That keeps integration friction low, but it means no namespacing, capability metadata, permission labels, versioning, ownership, or audit trail.

Prompting is protocol-based. A custom `TextPrompter` can change prompt format without changing `Generator` or `Constrainer`. This is worth copying for Agentic Coding Lab: make prompt assembly pluggable, but keep validation and execution boundaries outside prompt strings.

## Strengths

- Very small core: the reusable path is easy to audit in `generator.py` and `constrainer.py`.
- Strong boundary before side effects: output is a proposed function call, not executed code.
- Token-level validation prevents many malformed enum and JSON-schema outputs before they complete.
- Backend abstraction is narrow enough to support both Hugging Face and llama.cpp without changing orchestration.
- Supports caller-forced function selection, which can be reused when a planner already chose the tool and only needs constrained argument filling.
- `EnumConstraint` rejects values that are prefixes of each other, and `Generator` exposes a suffix workaround for prefix collisions in function names.

## Weaknesses

- No real execution sandbox, permission system, allow/deny policy, confirmation gate, or audit log. A downstream runtime must supply all of that.
- No durable tool registry. Function definitions are plain in-memory lists without capability classes, risk levels, versioning, or provenance.
- Error handling is thin. Invalid schemas raise `InvalidSchemaError`, impossible constraints raise `NoValidTokensError`, and unknown forced function names can fall through to list indexing errors rather than typed tool errors.
- `SequenceTooLongError` is caught inside `gen_next_token()` and treated as completion, which can silently return truncated output.
- `Generator.generate()` passes `max_new_tokens` and `max_length` to `generate_arguments()` in swapped order, so caller limits can apply to the wrong dimension.
- The constrained decoder is greedy and has no beam search, backtracking, repair pass, or retry policy when a high-probability valid prefix leads to a dead end.
- `CodeLlamaFunctionCallingPrompter._chat_prompt()` mutates the first chat message by prepending the system prompt, so repeated calls on the same chat object can duplicate system text.
- Tests are effectively absent; `tests/__init__.py` is empty.

## Ideas To Steal

- Use a two-step planner: enum-constrained tool name first, schema-constrained arguments second. Put policy checks between the two steps and before execution.
- Treat every tool-call schema as an executable boundary contract. The model can propose only outputs accepted by a validator; execution code still owns side effects.
- Implement a small `Generation` protocol for model backends: sorted candidates, register token, inspect candidate output. This keeps constrained decoding independent from the LLM provider.
- Add suffix or delimiter handling for tool names so enum-constrained selection can distinguish names that share prefixes.
- Let callers bypass tool selection and request constrained arguments for a known tool. This fits multi-stage agents where one planner selects a command and a second component fills safe arguments.
- Support prompt strategies as replaceable adapters while keeping schema validation in shared runtime code.

## Do Not Copy

- Do not rely on prompt text as a permission boundary. This repo does not execute functions, so it does not solve command safety.
- Do not use a plain list of function schemas as the only registry for a coding agent. Agentic Coding Lab needs richer metadata: owner, risk, read/write classification, sandbox requirements, confirmation policy, and examples.
- Do not silently finish on context overflow. A coding agent should return a typed truncation error or retry with smaller context.
- Do not mutate caller-owned chat history during prompt assembly.
- Do not ship without focused tests for prefix-collision tool names, invalid schemas, unknown forced functions, max-token limits, no-valid-token paths, and schema truncation.
- Do not copy the greedy decoder as the only strategy for high-stakes actions; add retry, backtracking, or repair around constrained generation failures.

## Fit For Agentic Coding Lab

Fit is conditional and pattern-level. This repo is not an agent framework and should not be adopted as a runtime dependency for coding-agent orchestration. It is useful as a reference implementation for constrained local tool-call proposal.

Most reusable for Agentic Coding Lab:

- a tool-call planner that cannot emit non-registered tool names;
- a schema-constrained argument filler for command templates;
- a policy insertion point between selected tool and generated arguments;
- a backend-neutral constrained decoding interface;
- a strict distinction between "propose call" and "execute call".

Missing pieces Agentic Coding Lab would need to add:

- permission and sandbox enforcement;
- typed execution results and retryable errors;
- registry metadata for tool risk and scope;
- context pruning for large tool catalogs;
- verification hooks after tool proposal and after execution;
- audit events for tool choice, argument validation, denial, execution, and result.

## Reviewed Paths

- `README.md`: project overview, example function schemas, Hugging Face usage, custom constraints.
- `docs/quickstart.md`, `docs/generation.md`, `docs/constraining.md`, `docs/api.rst`: public usage paths, llama.cpp usage, prompter customization, constraint API.
- `pyproject.toml`: package metadata and dependency surface (`transformers`, `torch`, `json-schema-enforcer`, optional `llama-cpp-python`).
- `local_llm_function_calling/generator.py`: orchestration for choosing tools, generating arguments, should-call gating, and natural-language fallback.
- `local_llm_function_calling/constrainer.py`: enum and JSON-schema constraints plus token-by-token constrained decoding loop.
- `local_llm_function_calling/prompter.py`: schema types and default completion/instruct prompt builders.
- `local_llm_function_calling/prompters/llama_function_calling.py`: chat/function-message prompt adapter for finetuned CodeLlama function-calling models.
- `local_llm_function_calling/model/common.py`: model and generation protocols.
- `local_llm_function_calling/model/huggingface.py`: Hugging Face token candidate adapter.
- `local_llm_function_calling/model/llama.py`: llama.cpp logits wrapper, prompt adapters, generation adapter, and natural-language generation path.
- `local_llm_function_calling/__init__.py`, `local_llm_function_calling/model/__init__.py`, `local_llm_function_calling/prompters/__init__.py`, `local_llm_function_calling/exceptions.py`: public exports and typed exception names.
- `LICENSE`: MIT license.

## Excluded Paths

- `poetry.lock`: dependency lock snapshot; reviewed only as dependency context through `pyproject.toml`, not as implementation.
- `tests/__init__.py`: empty package marker with no behavioral tests to inspect.
- `docs/Makefile`, `docs/make.bat`, `docs/conf.py`, `docs/requirements.txt`, `.readthedocs.yaml`: documentation build plumbing, not part of runtime behavior.
- `.gitignore`: repository hygiene only.
- No generated source, vendored library code, binary model files, or UI-only implementation paths are present in this checkout.
