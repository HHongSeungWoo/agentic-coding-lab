# NousResearch/Hermes-Function-Calling

- URL: https://github.com/NousResearch/Hermes-Function-Calling
- Category: tool-use
- Stars snapshot: 1,355 (GitHub REST API, captured 2026-05-20)
- Reviewed commit: ea3c4723e4cefdac760d483ccac6c8a428c95ab8
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: conditional
- Verdict: Useful as a compact reference for model-facing tool-call grammar, JSON-schema prompting, recursive tool execution, and validation-repair loops. Not production-ready as an agent runtime because execution is unsandboxed, parsing is brittle, tools are demo-grade, and there is no eval harness or permission model.

## Why It Matters

This repo captures the practical prompt and adapter layer around Hermes function-calling models: how to serialize tools, how to ask for calls, how to parse `<tool_call>` blocks, how to feed `<tool_response>` observations back, and how to retry after invalid output. For Agentic Coding Lab, the transferable value is not the finance/demo tools; it is the explicit contract between prompt, schema, validator, executor, and recursive repair loop.

It is especially relevant to local/open-weight agents because the examples show the same tool protocol across Hugging Face Transformers, Ollama OpenAI-compatible APIs, llama.cpp, LocalAI, Instructor, Outlines, and hand-written chat templates.

## What It Is

Hermes-Function-Calling is a small Python/Jupyter repository for running Hermes Pro models in function-calling and structured-output modes. The Python scripts provide a local inference path using `transformers`, a prompt manager, OpenAI-style tool schema generation from LangChain helpers, XML-delimited tool calls, JSON schema validation, and recursive retries.

The repo also contains notebooks that demonstrate alternate runtimes and adapters: Ollama recursive tool calls through the OpenAI client, llama.cpp prompt formatting, LocalAI function calling, Instructor response models, Outlines constrained JSON generation, CrewAI integration, and chat-template experiments.

## Research Themes

- Token efficiency: Uses compact XML sentinels and a minimal `FunctionCall` schema, but often serializes full OpenAI-style tool definitions and few-shot examples into the system prompt. The one-function-at-a-time instruction reduces tool fan-out cost but may increase turns.
- Context control: Separates available tools in `<tools>`, tool calls in `<tool_call>`, and observations in `<tool_response>`. The system prompt explicitly tells the model not to assume tool results before receiving tool-response tags.
- Sub-agent / multi-agent: The Instructor query-decomposition notebook turns a question into sub-questions, runs per-query agents in a `ThreadPoolExecutor`, wraps answers in `<agent>` blocks, and synthesizes a final answer. It is an illustrative pattern, not a hardened multi-agent framework.
- Domain-specific workflow: Default tools focus on finance, search/scrape, weather, time, and local code execution. The schema flow is domain-agnostic and can be reused for coding tools, but the included functions are demos.
- Error prevention: Validates tool-call shape, required arguments, JSON types, enum values, and structured JSON outputs before accepting model responses. Invalid parse/schema/execution results are fed back as tool responses for bounded self-repair.
- Self-learning / memory: No persistent memory or learning loop. The recursive loop keeps only conversation state and running observations inside the prompt.
- Popular skills: Tool schema serialization, XML-delimited tool-call parsing, Pydantic/JSON Schema validation, recursive tool-use repair, local-model chat-template construction, structured output generation, query decomposition.

## Core Execution Path

`functioncall.py` is the main runtime. It loads a Hermes model/tokenizer, attaches a fallback chat template if the tokenizer lacks one, builds an OpenAI-style tool list from `functions.get_openai_tools()`, and asks `PromptManager` to assemble a system prompt from `prompt_assets/sys_prompt.yml`.

The first user message is augmented with an explicit note that no tool results exist yet. The model generates an assistant message, `utils.get_assistant_message()` extracts the latest assistant turn by chat-template-specific regex, and `utils.validate_and_extract_tool_calls()` wraps the text in a root XML element, finds `<tool_call>` tags, and parses each block as JSON with an `ast.literal_eval` fallback.

Each parsed call is checked by `validator.validate_function_call_schema()` against the available OpenAI-style signatures. The validator confirms the call matches a known function name, checks present argument types, verifies required arguments, and handles enum values. Valid calls are dispatched through `getattr(functions, function_name)` and results are wrapped as JSON-like content inside `<tool_response>`.

The tool response is appended as a `tool` role and the model is called again. Parse errors, schema errors, and execution exceptions are also converted into tool-response messages that ask the model to retry with corrected syntax or arguments. Recursion stops when the assistant emits no tool calls or when `max_depth` is reached.

`jsonmode.py` mirrors the repair-loop idea for structured output: a Pydantic model is serialized into JSON schema, the schema is placed inside `<schema>`, model output is validated with `jsonschema`, and failures are returned as tool-response feedback for another attempt.

## Architecture

The architecture is a thin local harness:

- `prompt_assets/sys_prompt.yml` defines the function-calling contract: role, objective, tool envelope, optional examples, `FunctionCall` schema, and tool-call formatting rules.
- `prompter.py` loads the YAML prompt, injects date/tools/examples/schema, and returns ChatML-style messages.
- `schema.py` defines Pydantic models for `FunctionCall`, `FunctionDefinition`, and `FunctionSignature`.
- `functions.py` defines demo tools and converts them with `langchain_core.utils.function_calling.convert_to_openai_tool`.
- `validator.py` validates function calls and structured JSON output.
- `utils.py` handles chat-template loading, assistant-turn extraction, XML tool-call extraction, JSON-from-markdown extraction, and inference logging.
- `chat_templates/*.j2` provide simple ChatML, Zephyr, and Vicuna templates.
- `template_tests/` experiments with richer tool-use templates for Hugging Face and Ollama, including multiple tool calls, tool-response grouping, and `<scratch_pad>` planning blocks.
- `examples/` contains runtime-specific notebooks rather than a unified library API.

There is no long-running agent service, scheduler, registry, sandbox, persistent memory, benchmark suite, or CI-backed eval path.

## Design Choices

The strongest design choice is a clear, model-visible grammar: tools live in `<tools>`, calls live in `<tool_call>`, observations live in `<tool_response>`, and structured-output schemas live in `<schema>`. This makes the contract easy to port across local inference backends that do not implement native tool calling.

The repo uses OpenAI-compatible function schemas as the interchange format even when the backend is local. That gives a practical bridge between Python functions, LangChain conversion helpers, Ollama-compatible OpenAI clients, Hugging Face chat templates, and LocalAI.

The YAML prompt pushes operational discipline into the model: do not invent results before a tool response exists, call one function at a time, keep a running summary, do not stop until the task is done or iteration limit is reached, and emit valid double-quoted JSON.

Validation is placed between model output and tool execution. Invalid model output does not immediately crash the loop; the runtime converts errors into observations and lets the model repair itself. This is a useful pattern for coding agents because tool-call mistakes are common and can often be fixed from concrete parser/schema errors.

The repo deliberately includes several template variants. The Hermes-3 examples add `<scratch_pad>` with Goal, Actions, Observation, and Reflection sections before the tool call. The Ollama Go template and Hugging Face notebook show how to serialize assistant tool calls back into chat history and how to group multiple tool responses.

The largest risky choice is the generic `code_interpreter` fallback in the prompt and tool list. It gives the model a broad escape hatch when no declared function matches, but executes arbitrary Python with `exec()` and no sandbox.

## Strengths

The prompt contract is concrete and portable. A coding-agent project could reuse the envelope design with different tools and runtimes without depending on Hermes-specific code.

The validation-repair loop is small but useful. It turns malformed XML/JSON, missing arguments, wrong types, and execution exceptions into structured feedback, then retries within a bounded recursion depth.

The repo demonstrates adapter symmetry: the same conceptual protocol appears in direct Transformers inference, OpenAI-compatible Ollama calls, llama.cpp prompts, LocalAI, Instructor, and Outlines.

Pydantic and JSON Schema are used as a shared language between Python types, model prompts, validators, and constrained generation examples.

The notebooks make tool history formatting explicit: append assistant tool calls, append tool-role observations with `{name, content}`, and call the model again for synthesis.

## Weaknesses

Tool execution is not safe. `code_interpreter` runs arbitrary Python through `exec()`, web scraping and finance calls run directly from model-selected arguments, and there is no permission gate, sandbox, timeout, resource limit, or audit policy.

Parsing is fragile. XML parsing requires valid wrapper-compatible text, regex assistant extraction depends on chat template names, and `ast.literal_eval` accepts Python-literal output even when the prompt demands JSON. The code does not defend against prompt injection inside scraped pages or tool responses.

Function dispatch is demo-grade. `execute_function_call()` calls `function_to_call(*function_args.values())`, which can misbind arguments if order changes. Several tools return pandas DataFrames or objects that are not reliably JSON serializable. Network tools lack robust timeout/rate-limit/error handling.

The repo has examples, not measurements. There are no benchmark datasets, eval scores, regression tests, CI checks, or systematic comparisons of prompt variants.

The prompt encourages continuing tool calls until the task is done, but completion is judged by the model. There is no external task-state machine or verifier to decide whether enough evidence has been gathered.

Some notebooks include local install commands, long generated package-install outputs, dummy API-key strings, and exploratory traces. They are useful examples but not clean reusable modules.

## Ideas To Steal

Define a tool-use wire contract independent of provider APIs: XML sentinels around JSON calls and observations, with one canonical Pydantic schema for calls. This would let Agentic Coding Lab keep tool-use traces stable across Codex, local models, and test harnesses.

Insert a strict validation gate before every tool execution. Parse, schema-check, required-argument-check, enum-check, and permission-check should all happen before dispatch. Feed exact validation failures back as observations for a bounded repair turn.

Use a typed result envelope for every tool response: `{ "name": "...", "content": ... }`, plus optional `tool_call_id`, status, duration, and error fields. This makes traces easier to replay and evaluate.

Teach the model observation discipline in the system prompt: no assumed tool results, no final answer before required observations, and no hidden state outside conversation/tool responses.

Keep a runtime-visible iteration budget. The repo uses `max_depth`; Agentic Coding Lab can extend that into per-tool budgets, cost budgets, approval budgets, and stop reasons.

Separate prompt assets from code. The YAML prompt makes it easier to diff and test changes to tool-use policy without editing runtime code.

Borrow the chat-template test mindset. A small golden-output suite for tool-use serialization would catch regressions in assistant tool-call history, tool response grouping, and final assistant generation prompts.

Use structured-output libraries selectively. Instructor/Outlines examples show when to push JSON validity into client-side response models or constrained decoding rather than relying only on post-hoc parsing.

## Do Not Copy

Do not expose a generic `exec()` tool without sandboxing, explicit user approval, filesystem/network policy, timeouts, and result-size limits.

Do not dispatch by positional `dict.values()`. Dispatch by named arguments after schema validation, and reject extra or unknown arguments unless the tool explicitly allows them.

Do not use broad web scraping as an untrusted observation source without prompt-injection filtering, allowlists, robots/rate-limit policy, and provenance metadata.

Do not treat model self-recursion as sufficient task control. Use explicit external state, verifier checks, and deterministic stop criteria for coding tasks.

Do not rely on notebooks as tests. Convert the useful cases into small fixtures that assert prompt serialization, parser behavior, validation errors, and repair-loop outcomes.

Do not accept Python-literal fallbacks in a JSON-only protocol unless compatibility with older model outputs is more important than strictness. For agent tooling, strict JSON plus repair feedback is easier to reason about.

Do not copy the finance/demo tools into coding workflows. Replace them with least-privilege coding tools such as read-only search, patch application, test execution, dependency inspection, and review emitters.

## Fit For Agentic Coding Lab

Fit is conditional and pattern-level. This repo is not a full agent framework, but it is a useful reference for local/open-model tool-use contracts and for testing how much of a tool protocol can live in prompt/template/schema files.

Best fit artifacts for Agentic Coding Lab:

- A reusable `tool_call` envelope spec with XML sentinels and strict JSON payloads.
- A validation-and-repair middleware that turns parser/schema/permission errors into bounded model feedback.
- Golden tests for chat-template serialization across normal turns, assistant tool calls, multiple tool responses, and final answer turns.
- A tool-result envelope standard with name, content, status, error, provenance, and call id.
- A prompt section that explicitly prevents assumed observations and requires final answers to cite tool results.

Poor fit areas:

- Runtime security model, because the repo has none.
- Evaluation methodology, because the repo offers examples but no benchmark harness.
- Production tool registry, because tools are directly imported functions and demo notebooks.

## Reviewed Paths

- `README.md`: install/use instructions, function-calling prompt format, Hermes-3 scratch-pad variant, tool-response loop, and JSON-mode schema format.
- `functioncall.py`: model loading, prompt generation, assistant extraction, recursive tool-call execution, validation, error-feedback loop, and max-depth stop.
- `jsonmode.py`: structured-output schema prompt, JSON validation, and retry-on-validation-error loop.
- `functions.py`: demo tool catalog, OpenAI tool schema conversion, finance/search/code/weather-style tool patterns, and unsafe code interpreter.
- `schema.py`: Pydantic models for function calls and tool signatures.
- `validator.py`: call/schema matching, required argument checks, type/enum validation, and structured JSON validation.
- `utils.py`: chat-template loading, assistant regex extraction, XML tool-call parsing, JSON/markdown extraction, and runtime logging.
- `prompter.py`: YAML prompt loading, variable injection, few-shot inclusion, and ChatML message assembly.
- `prompt_assets/sys_prompt.yml`: core model instructions for recursive function calling and tool-response discipline.
- `prompt_assets/few_shot.json`: two few-shot function-call examples.
- `chat_templates/chatml.j2`, `chat_templates/zephyr.j2`, `chat_templates/vicuna.j2`: backend prompt-format variants.
- `template_tests/hermes_template_test.ipynb`: rich Jinja tool-use template, multiple tool-call rendering, tool-response grouping, and parser experiments.
- `template_tests/hf_chat_template.ipynb`: Hugging Face `tool_use` template, parser, named tool execution, and recursive loop.
- `template_tests/ollama_template.go`: Go template for Ollama-style Hermes-3 tool prompts with `<scratch_pad>`, `<tool_call>`, and `<tool_response>`.
- `examples/ollama_openai_tools_recursive.ipynb`: OpenAI-compatible Ollama recursive tool loop with tool-call IDs and tool-role observations.
- `examples/ollama_openai_tools.ipynb`, `examples/ollama-multiple-fn.ipynb`, `examples/lllama-cpp-multiple-fn.ipynb`, `examples/localai_api_fn_calling.ipynb`: alternate local runtime and multiple-function-call patterns.
- `examples/instructor_ollama.ipynb`, `examples/instructor_query_decomposition_agent.ipynb`: structured-output and query-decomposition patterns.
- `examples/outlines_llama-cpp-python_knowledge-graph-extraction.ipynb`, `examples/outlines_llama-cpp-python_Q_and_A_with_citations.ipynb`, `examples/outlines_llama-cpp-python_chain_of_thought.ipynb`: constrained JSON generation and schema-prompt patterns.
- `examples/crewai_agents.ipynb`: brief CrewAI/Ollama integration example, mostly exploratory.
- `requirements.txt` and `LICENSE`: dependency and license context.

## Excluded Paths

- `.git/`: repository metadata only; used only to identify reviewed commit.
- `icons/*.svg`: UI/README icon assets with no tool-use or agent-runtime logic.
- `examples/__init__.py`: empty package marker.
- Notebook generated outputs, package-install transcripts, local warning traces, and displayed result cells: treated as generated/execution artifacts. I read source cells and relevant outputs only where they exposed tool-call behavior or limitations.
- Runtime log directory `inference_logs/`: created by `utils.py` during inference, not present as source and not reviewed as a design asset.
- Vendored, binary, or generated source snapshots: none found in the checked-out tree.
