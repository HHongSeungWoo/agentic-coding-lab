# empower-ai/empower-functions

- URL: https://github.com/empower-ai/empower-functions
- Category: tool-use
- Stars snapshot: 220 (GitHub REST API, captured 2026-05-29)
- Reviewed commit: 1c1d52cf0bcb28daa81228563cbfeabc47eaf47a
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: conditional
- Verdict: Useful as a local/open-weight function-calling model and prompt-adapter reference, especially for OpenAI-compatible tool schemas, lightweight call/content tags, BFCL-style baselines, and llama.cpp serving. Not a strong coding-agent runtime by itself because it has no eval harness, no training data release, no sandbox or permission model, brittle local server patches, and limited local feature coverage.

## Why It Matters

Empower Functions is relevant to Agentic Coding Lab because it is a concrete open-model attempt to make tool calling feel like a drop-in OpenAI chat-completions path. The repository is not a full agent framework; its value is the combination of model-facing grammar, OpenAI-shaped tool schemas, local GGUF inference, and examples for single-turn, multi-turn, clarification, parallel, sequential, streaming, and built-in thinking modes.

For coding agents, the transferable idea is a small local baseline: take a Llama 3.1 function-calling model, serialize tools as JSON schema, make the model choose between `<f>` function-call output and `<c>` conversation output, and adapt that back into provider-style `tool_calls`. This is useful for comparing local model tool-selection behavior against hosted models without building a full agent runtime.

## What It Is

The repo contains docs, examples, a PyPI package, and assets around the Empower Functions model family. The model weights are hosted on Hugging Face, not vendored in the repository. The reviewed v1.1 assets include an 8B Llama 3.1 small model, a small GGUF package with Q4_K_M and f16 files, and a 70B Llama 3.1 large model. The small GGUF path is the only documented local-running target; the large model and API-only features depend on Empower-hosted service or larger infrastructure.

The Python package exposes two primary pieces: `prompt_messages()` for converting OpenAI-like messages and function definitions into the model prompt format, and `EmpowerFunctionsCompletionHandler` for `llama-cpp-python` chat completion integration. A local server path monkey-patches `llama-cpp-python` server loading and chat-completions routing so `--chat_format empower-functions` can return OpenAI-style responses.

## Research Themes

- Token efficiency: The model uses compact sentinel tags (`<f>`, `<c>`, `<r>`, `<u>`) after the first turn, but the first user prompt embeds the full JSON function list with pretty indentation. Built-in thinking is advertised as enabled by a short internal instruction, but generated thinking still adds output tokens. Docs say the model was optimized around up to 10 functions even though the API schema can accept larger lists.
- Context control: The prompt adapter reduces everything to user/assistant roles, places system instructions plus serialized functions in the first user message, prefixes later user turns with `<u>`, groups tool results under `<r>`, and rewrites assistant tool calls as `<f>` JSON. There is no tool retrieval, context pruning, or registry selection layer.
- Sub-agent / multi-agent: None. Parallel calling means multiple tool calls in one assistant response, not delegated agents.
- Domain-specific workflow: The repo is domain-general. Examples cover weather, customer support, vehicle diagnostics, medical-center scheduling, and clarification. The pattern can be reused for coding tools, but no coding-specific tools, patch workflow, test runner, or code-review loop is included.
- Error prevention: Model training claims include clarification behavior and DPO to reduce hallucinated values from schema examples. The code validates input schema shape and message alternation, but output parsing trusts JSON from the model, has no repair loop, no unknown-argument policy, and no permission gate.
- Self-learning / memory: No persistent memory, self-learning, or trace store. Multi-turn state is only the caller-provided chat history.
- Popular skills: Function-calling fine-tuning, BFCL comparison, OpenAI-compatible tool schemas, llama.cpp chat handler, local GGUF serving, JSON call formatting, clarification prompts, parallel/sequential tool-call examples, built-in thinking toggle.

## Core Execution Path

The direct prompt path starts in `empower_functions.prompt.prompt_messages()`. The caller passes OpenAI-style messages and a list of function definitions shaped as `{name, description, parameters}`. The function checks basic schema fields, merges consecutive user messages, groups consecutive tool messages, parses tool-result content as JSON when possible, and converts the conversation into the Empower prompt format.

If tools are present, the first prompted user message contains the system instruction, a pretty-printed JSON function list, and the first user message. Later tool responses become user-role messages beginning with `<r>`, later user messages begin with `<u>`, assistant natural-language messages begin with `<c>`, and assistant tool-call history is serialized as `<f>` plus JSON function calls.

The `EmpowerFunctionsCompletionHandler` installs a Llama 3 chat template through Jinja, converts legacy `function_call` into `tool_choice`, extracts `tools[*].function`, calls `prompt_messages()`, and then invokes `llama.create_completion()`. After generation, it separates optional thinking text if a `</thinking>` tag exists. If the remaining output starts with `<f>`, it parses the trailing JSON and returns OpenAI-style `tool_calls`; if it starts with `<c>`, it returns a normal assistant message.

The server path in `empower_functions.server` replaces `LlamaProxy.load_llama_from_model_settings` so the `empower-functions` chat format uses `EmpowerFunctionsCompletionHandler`. `empower_functions.monkey_patch.app.patch_app()` removes the default llama-cpp `/v1/chat/completions` route and registers a patched route with an extra `include_thinking` request field.

The model assets are outside the repo. The README points to Hugging Face v1.1 models based on Llama 3.1 8B and 70B. The 8B GGUF variant is the practical local baseline, with README hardware guidance claiming a 4-bit GGUF minimum around 7.56 GB RAM and tested local use on a MacBook M2 Pro.

## Architecture

The architecture is a thin adapter around a fine-tuned model family:

- `README.md` introduces model variants, local/API usage, hardware assumptions, training summary, and BFCL screenshot claims.
- `docs/model-prompt.md` documents the model-facing prompt grammar: only user/assistant roles, JSON function definitions, `<r>` tool responses, `<u>` user turns, `<f>` function calls, and `<c>` normal conversation.
- `docs/inference/*.md` provides examples for single-turn flow, clarification, multi-turn, parallel calling, sequential calling, streaming, and built-in chain-of-thought.
- `empower_functions/prompt.py` is the prompt serializer and light validator.
- `empower_functions/chat_handler.py` is the llama-cpp chat-completion adapter and OpenAI tool-call converter.
- `empower_functions/server.py` monkey-patches llama-cpp server model loading.
- `empower_functions/monkey_patch/app.py` monkey-patches chat-completions routing and adds `include_thinking`.
- `examples/*.py` show direct llama-cpp, local OpenAI-client, and raw Transformers prompt usage.
- `assets/*.png` are demo and benchmark screenshots, not machine-readable eval data.

There is no registry service, planner, executor, sandbox, approval layer, trace database, benchmark runner, regression suite, or CI configuration in the checked-out tree.

## Design Choices

The most important design choice is to train the model on a simple output grammar rather than wrapping a generic chat model with heavy parsing prompts. The model decides between function mode (`<f>`) and conversation mode (`<c>`), which gives the adapter a narrow branch for constructing OpenAI-compatible responses.

The prompt format uses OpenAI-compatible JSON Schema for tool definitions but strips provider-specific message roles down to user and assistant. This makes it easier to run on standard Llama chat templates while preserving the tool-schema shape that application developers already know.

Tool results are reintroduced as user messages under `<r>` rather than relying on a native tool role. That is practical for base chat templates, but it means the host must maintain the true tool-call IDs and ensure model-visible results are not confused with user instructions.

The docs emphasize real-world behaviors that matter for agent workflows: auto mode, clarification when required parameters are missing, multi-turn context, parallel calls, sequential calls with dependencies, and streaming of function arguments. Those are the right task-design axes for a tool-use model benchmark.

The local integration choice is pragmatic but fragile. Instead of a stable plugin interface, the package monkey-patches llama-cpp server internals. That creates a convenient OpenAI-compatible local endpoint, but it is sensitive to upstream llama-cpp-python API changes and imports.

## Strengths

The model-facing contract is small, readable, and portable. `<f>`/`<c>` and JSON function calls are easier to inspect than large provider-specific traces.

The local baseline story is credible for research: a small Llama 3.1 8B model, GGUF quantization, llama-cpp serving, and OpenAI-compatible client examples are enough to compare local tool-selection behavior.

The docs cover the important task-design variants for function calling: missing required parameters, multiple calls in one turn, multi-turn state, sequential dependencies, streaming, and optional thinking.

The model assets are accessible on Hugging Face and advertise Apache-2.0 metadata there. The GGUF repository includes both Q4_K_M and f16 files, which is useful for local quality/cost sweeps.

The BFCL screenshot gives at least a public benchmark target. It claims Empower Functions Large ranked first and Small ranked sixth in the captured table, with separate AST, execution, irrelevance, and relevance columns.

The prompt utility is compact enough to port into an eval harness. It can generate raw model prompts without the server path, which is useful for controlled local experiments.

## Weaknesses

The repo does not contain a reproducible evaluation harness. Benchmark support is limited to screenshots and README claims; there are no BFCL scripts, datasets, score parsers, regression tests, or pinned commands for reproducing the reported numbers.

The training data is described but not released. README claims more than 100k curated function-calling conversations plus DPO for harder cases, but the repo gives no dataset, annotation schema, data filters, or ablation evidence.

The local runtime has brittle code paths. `chat_handler.py` assumes `tools` is iterable when `functions is None`, so a plain chat request without functions can fail before `tool_choice == "none"` is applied. It asserts that `tool_choice != "any"`, matching the docs' local-only auto limitation.

The server monkey patch has apparent runtime hazards. `monkey_patch/app.py` uses `partial` in the streaming response path but does not import it. `server.py` references `llama_tokenizer` and `llama_speculative` when those optional settings are used, but those names are not imported in the file.

The prompt validator raises strings in several branches of `prompt.py`; in Python that raises a `TypeError`, not the intended validation message. This weakens diagnostics for malformed tool specs.

There is no parser repair, schema enforcement, permission gate, sandbox, timeout, or side-effect policy. The adapter trusts model JSON, converts arguments to strings, and leaves all execution safety to the caller.

Some docs/examples are rough: the local GGUF download link in the README is unfinished, the streaming example uses an `index` variable that is commented out, and the clarification doc includes an API-key-shaped string instead of a neutral dummy value.

The repository has no explicit `LICENSE` file even though package metadata says Apache Software License and Hugging Face model cards report Apache-2.0. Reuse should verify license terms from the model repositories and package distribution.

## Ideas To Steal

Use a tiny explicit model grammar for tool-use fine-tuning: one branch token for tool calls, one for conversation, one for tool results, and one for later user turns. This makes local traces inspectable and easy to replay.

Keep OpenAI-compatible JSON Schema as the application-facing tool schema, but compile it into model-specific prompt text. That lets Agentic Coding Lab run the same tool catalog against hosted models, local models, and synthetic evals.

Benchmark tool-use models on behavior classes, not just single-call accuracy: clarification, irrelevant tool rejection, parallel calls, sequential dependencies, multi-turn carryover, and streaming argument assembly.

Treat the 8B GGUF model as a cheap local baseline for tool-choice and argument-generation tests. It is especially useful for offline comparisons where hosted API variability is undesirable.

Separate model prompt formatting from execution. `prompt_messages()` is simple enough to become a golden-test fixture generator without importing the server or model runtime.

Record BFCL-like subscore categories in local eval reports: AST/schema validity, executable arguments, parallel-call accuracy, irrelevance rejection, and relevance selection.

Consider a model-level thinking toggle only as an eval condition. It may improve decisions, but coding-agent traces should decide whether thinking is user-visible, hidden, stored, or stripped before tool execution.

## Do Not Copy

Do not copy the llama-cpp server monkey-patch approach as a long-term integration boundary. Prefer a stable adapter layer or a small dedicated server where route behavior, streaming, and imports are owned locally.

Do not trust `<f>` JSON directly. Parse it into a typed call envelope, reject unknown tools and arguments, validate JSON Schema, enforce permissions, and return typed repair feedback when parsing fails.

Do not expose raw tool results as user-role content without an injection policy. Tool outputs need provenance, result typing, truncation, and clear separation from user instructions.

Do not rely on benchmark screenshots as evidence. Reproducible scripts, pinned model revisions, input fixtures, and machine-readable reports are required before adopting reported scores into a lab baseline.

Do not use broad function lists without retrieval or task-scoped filtering. The docs themselves say performance was optimized around small tool sets, and coding environments can easily exceed that.

Do not copy API-key-like strings into examples. Even fake-looking secrets make downstream secret scanning and trust review harder.

Do not treat local model support as feature parity. The docs state local mode only supports `auto`, while streaming and JSON mode are API-only in the README.

## Fit For Agentic Coding Lab

Fit is conditional and baseline-oriented. Empower Functions is worth indexing because it provides a practical local function-calling model family, prompt grammar, and llama-cpp adapter that can support low-cost tool-use experiments. It is not a runtime substrate for coding agents.

Best-fit artifacts:

- A local open-weight tool-calling baseline using `llama3-empower-functions-small-gguf-v1.1`.
- Golden tests for prompt serialization across first turn, later user turns, assistant tool calls, tool responses, and normal assistant content.
- A behavior matrix for tool-use evals: auto/no-tool decision, missing-parameter clarification, multiple parallel calls, sequential call chains, multi-turn carryover, and irrelevant request rejection.
- A provider-neutral tool-call envelope that can map `<f>` JSON, OpenAI `tool_calls`, and local model outputs into one validated representation.
- A comparison target for BFCL-style AST and executable-call scoring.

Required hardening before reuse:

- Replace monkey patches with a controlled adapter.
- Add strict parsing, schema validation, and repair feedback.
- Add permission classes for coding tools and external APIs.
- Add a reproducible eval harness with pinned model revisions.
- Add tests for no-tool chat, `tool_choice` modes, malformed output, streaming, and thinking-mode responses.

## Reviewed Paths

- `README.md`: model family, local/API usage, hardware notes, training summary, BFCL screenshot, and documented local/API feature split.
- `docs/model-prompt.md`: two-role prompt format, JSON function schema, `<r>` tool responses, `<u>` user turns, `<f>` function calls, and `<c>` conversation messages.
- `docs/inference/introduction.md`: general tool-use flow, documented limitations, `tools`, `tool_choice`, and single-call example.
- `docs/inference/clarification.md`: missing-parameter clarification behavior and example.
- `docs/inference/multi-turn.md`: customer-support multi-turn flow and tool-result carryover.
- `docs/inference/parallel-calling.md`: multiple tool calls in one assistant response.
- `docs/inference/sequential-calling.md`: dependent tool-call loop example.
- `docs/inference/streaming.md`: API-only streaming behavior and chunk assembly example.
- `docs/inference/built-in-cot.md`: thinking-mode rationale, `include_thinking` parameter, and response splitting.
- `examples/llama_cpp_inference.py`: direct local GGUF use through `llama-cpp-python` and `EmpowerFunctionsCompletionHandler`.
- `examples/openai_client.py`: local OpenAI-compatible server client shape with previous assistant tool calls and tool results.
- `examples/prompt.py`: raw Transformers prompt path using `prompt_messages()`.
- `empower_functions/prompt.py`: prompt serialization, message merging, tool result grouping, and light schema validation.
- `empower_functions/chat_handler.py`: llama-cpp chat handler, tool extraction, model invocation, `<f>`/`<c>` parsing, thinking separation, and OpenAI-style response conversion.
- `empower_functions/server.py`: llama-cpp server model-loading monkey patch and `empower-functions` chat format hookup.
- `empower_functions/monkey_patch/app.py`: patched `/v1/chat/completions` route and `include_thinking` body field.
- `empower_functions/monkey_patch/types.py`: request type extension for thinking mode.
- `pyproject.toml` and `setup.py`: package metadata, dependencies, and license classifier.
- `assets/bfcl.png` and `assets/eval_result.png`: benchmark-result screenshots reviewed as non-reproducible evaluation artifacts.
- Hugging Face model API metadata for `empower-dev/llama3-empower-functions-small-v1.1`, `empower-dev/llama3-empower-functions-small-gguf-v1.1`, and `empower-dev/llama3-empower-functions-large-v1.1`: model revisions, asset files, license tags, and storage footprint.

## Excluded Paths

- `.git/`: repository metadata only; used only to identify reviewed commit and branch state.
- `assets/logo.png`, `assets/demo_screenshot.png`, and `assets/demo_thinking_screenshot.png`: branding/product screenshots with no reusable execution, schema, evaluation, or safety logic.
- `MANIFEST.in` and `empower_functions/MANIFEST.in`: packaging include files with no agent-design behavior.
- `docs/contact.md`: contact information only.
- Exhaustive benchmark-image pixel analysis: excluded because images are screenshots, not machine-readable eval artifacts. I inspected the visible benchmark tables enough to assess research value and reproducibility limits.
- Live hosted demo behavior: not exercised because the repo review target is the GitHub source and local assets; hosted API quality can change independently of the reviewed commit.
- Model-weight internals: not downloaded or inspected because the task is a repo deep review, and the large files are hosted externally. I reviewed published model metadata and repository integration points instead.
