# QwenLM/Qwen-Agent

- URL: https://github.com/QwenLM/Qwen-Agent
- Category: tool-use
- Stars snapshot: 16,366 via GitHub API on 2026-05-20
- Reviewed commit: 31a4d36d123688581a9e9744427272b33ce940e0
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong reusable reference for tool schema normalization, MCP-to-tool bridging, RAG-as-memory, and bounded tool loops. Production adoption needs stricter permissioning, tool error contracts, and sandbox hardening.

## Why It Matters

Qwen-Agent is a mature, popular Python framework where tool use is not a side feature: the central `Assistant` path combines function calling, MCP, code execution, RAG, browser/web tools, multimodal file/image inputs, and benchmarked planning tasks. It is especially relevant for Agentic Coding Lab because it shows how to turn heterogeneous tools into one model-visible schema surface while keeping the agent loop small and inspectable.

## What It Is

The package provides base agents, LLM adapters, registered tools, MCP adapters, RAG memory, code execution, browser-facing utilities, examples, tests, and DeepPlanning benchmarks. The main single-agent path is `Assistant -> FnCallAgent -> Agent -> BaseChatModel -> BaseTool`. `Assistant` prepends retrieved knowledge, `FnCallAgent` handles model tool calls, and `BaseTool` validates and executes tool arguments.

The repo also includes ReAct-style agents, router/group-chat agents, a TIR math agent, a Chrome/browser application, and standalone DeepPlanning benchmark agents. Those extra paths are useful context, but the core design is the compact function-call loop plus tool registry.

## Research Themes

- Token efficiency: Rough context truncation removes old turns first, compresses or omits older function results, drops middle tool steps, and only then truncates current user/assistant content. RAG caps reference material with `max_ref_token` and chunks documents by `parser_page_size`.
- Context control: Message schema separates `content`, `reasoning_content`, `function_call`, and `extra`. Tool-call history can be converted back to user text when `function_choice='none'`, preventing accidental extra calls.
- Sub-agent / multi-agent: Router and GroupChat wrap agents with names/descriptions and route to selected agents. Useful pattern: sub-agent delegation is just another agent run over managed messages, not a separate runtime.
- Domain-specific workflow: DeepPlanning defines domain tools with strict schemas, explicit "do not fabricate" descriptions, max call budgets, trajectories, and evaluation stages for travel/shopping tasks.
- Error prevention: JSON Schema validation, required-parameter checks, max LLM call caps, model retry limits, Docker-based code interpreter timeout, MCP config validation, and exact role/content validation via Pydantic.
- Self-learning / memory: `Memory` is primarily file/RAG memory, not user preference memory, though MCP examples can attach external memory servers.
- Popular skills: Function calling, parallel tool-call parsing, MCP server import, code interpreter, document QA/RAG, web extraction/search, image search/zoom, weather/image generation examples.

## Core Execution Path

`Agent.run` deep-copies messages, normalizes dicts into `Message`, detects language, prepends the system message, and delegates to subclass `_run`.

`Assistant._run` first asks `Memory` to process attached/system files. `Memory` extracts supported files from messages, optionally asks an LLM to generate retrieval keywords, calls the `retrieval` tool, and returns JSON snippets. `Assistant` formats those snippets as a knowledge-base system prompt and then calls `FnCallAgent._run`.

`FnCallAgent._run` loops up to `MAX_LLM_CALL_PER_RUN` (default 20). Each iteration calls the LLM with `[tool.function for tool in function_map.values()]`, streams model output, appends assistant messages, detects every returned `function_call`, executes each tool through `_call_tool`, appends `FUNCTION` messages with `function_id`, yields intermediate state, and stops when no tool was used.

`BaseChatModel.chat` handles retries, cache lookup, max input truncation, function-choice validation, multimodal formatting, raw OpenAI-compatible tool mode, prompt-based function calling, and postprocessing back into structured `Message(function_call=...)` objects.

## Architecture

Tool registration uses a global `TOOL_REGISTRY` plus `@register_tool`. A tool exposes `name`, `description`, and `parameters`; parameters can be a legacy list or OpenAI-compatible JSON Schema. `BaseTool._verify_json_format_args` validates string/dict arguments before execution.

LLM adapters share `BaseFnCallModel`. The default `nous` prompt emits `<tool_call>{...}</tool_call>` and parses one or more calls; the older `qwen` prompt uses `✿FUNCTION✿`, `✿ARGS✿`, `✿RESULT✿`, and supports explicit parallel-call formatting. Raw API mode converts Qwen-Agent messages into OpenAI `tool_calls`.

MCP integration is an adapter layer: `MCPManager` starts MCP clients in a background event loop, connects stdio/SSE/streamable HTTP servers, converts MCP `inputSchema` into OpenAI-compatible tool parameters, registers names as `<server>-<tool>`, and exposes resources through synthetic `list_resources` and `read_resource` tools.

RAG is implemented as normal tools plus a special `Memory` agent. `SimpleDocParser` extracts files, `DocParser` chunks and caches parsed docs, `KeywordSearch` uses BM25, `FrontPageSearch` boosts early pages for single docs, `HybridSearch` merges ranks, and optional `VectorSearch` uses DashScope embeddings through LangChain/FAISS.

## Design Choices

The core agent loop is intentionally simple and synchronous: tool calls are parsed in parallel-capable format but executed sequentially in returned order. This preserves predictable message ordering and avoids needing concurrent tool state handling.

The framework normalizes all tool results to strings unless a tool returns multimodal `ContentItem`s. This makes LLM reinjection easy, but weakens typed downstream handling.

MCP is not a separate planning surface. MCP tools become ordinary `BaseTool` instances, so prompts, `function_map`, call loop, and error handling stay unified.

Code execution has two tiers. `code_interpreter` is registered by default and runs a Jupyter kernel inside a Docker container with a mounted working directory. `PythonExecutor` is deliberately not registered by default because it is not sandboxed; TIR math uses it directly for controlled benchmark-style execution.

The benchmark path uses independent lightweight agents rather than the main framework in places. That keeps DeepPlanning reproducible across providers, but it means benchmark tool patterns are not all reusable package abstractions.

## Strengths

- Clear `BaseTool` contract with schema validation and registry-based discovery.
- Tool loop is small enough to audit and easy to adapt.
- MCP adapter imports external tools/resources into the same function-call path.
- Supports prompt-based and native API function calling without changing agent code.
- RAG is composable: document parsing, storage, search, and memory are separate pieces.
- Code interpreter includes Docker isolation, timeout wrapper, image capture, and process cleanup hooks.
- Tests cover assistant/tool flows, doc parsing/search, router delegation, ReAct formatting, and function-choice combinations.
- DeepPlanning benchmark adds concrete domain examples of strict tool descriptions, trajectories, call budgets, and post-run evaluation.

## Weaknesses

- Tool execution permissioning is mostly delegated to tool/server configuration; there is no central allow/deny policy, user approval gate, or capability risk model.
- Tool errors are often returned as plain strings, making automated retry/recovery brittle.
- Sequential execution means "parallel function calls" reduce prompt turns but do not actually run tools concurrently.
- MCP subprocesses may be unsandboxed; docs explicitly warn against untrusted production use.
- Docker code interpreter still mounts a host working directory and exposes container ports; it is isolation, not a full security boundary.
- `PythonExecutor` blocks `input()` and `os.system()` but still uses Python `exec`; it is explicitly unsafe outside local/testing scenarios.
- RAG search is lightweight and practical, but default BM25/front-page ranking can miss semantic matches unless optional vector search is configured.
- Some tests depend on external services, API keys, network access, Docker, or remote documents, so CI reliability depends on environment setup.

## Ideas To Steal

- Treat every tool source, including MCP, built-ins, and custom classes, as one `BaseTool` surface with `name`, `description`, `parameters`, and `call`.
- Keep agent loop bounded and inspectable: `LLM -> parse tool calls -> execute tools -> append function results -> repeat`.
- Preserve `function_id`/tool-call IDs through assistant and function messages so native API tool calls can round-trip.
- Add a `function_choice='none'` mode that rewrites previous tool calls/results into plain text when the next turn should not call tools.
- Implement RAG as a memory preprocessor that injects retrieved snippets into system context before normal tool planning.
- Wrap MCP resources as synthetic discovery/read tools; this gives models a way to enumerate context sources without custom protocol handling.
- Separate safe-ish sandboxed code execution from local raw Python execution, and make the unsafe executor opt-in rather than globally registered.
- Record complete benchmark trajectories and final artifacts; they are better debugging material than aggregate scores alone.

## Do Not Copy

- Do not rely on prompt text alone for destructive or filesystem/network tool safety. Add policy checks and user approval before calling risky tools.
- Do not flatten all tool results to strings if later workflow stages need typed state, diffs, or structured verification.
- Do not label sequential execution as true parallelism in UX or guarantees.
- Do not expose arbitrary MCP stdio commands without a launcher policy, path allowlist, environment filtering, and process cleanup monitoring.
- Do not use raw `exec`-based Python execution for coding agents except in tightly controlled eval harnesses.
- Do not make remote/API-key tests mandatory for local validation; keep hermetic unit tests for parser/schema/loop logic.

## Fit For Agentic Coding Lab

High fit as a tool-use pattern library. The best reusable pieces are the unified tool schema, MCP-to-tool conversion, bounded loop, RAG memory preprocessor, code execution split, and trajectory-first benchmark design.

For Agentic Coding Lab, the immediate adaptation would be a stricter `ToolRuntime` around this shape: schema-normalized tools, central permission categories, structured tool result envelopes, deterministic transcript records, and verification hooks after code/file tools. Qwen-Agent shows the ergonomic path; the lab should add stronger safety and audit controls.

## Reviewed Paths

- `README.md`: project scope, installation extras, function calling, MCP, code interpreter, long-document RAG, and safety disclaimer.
- `qwen-agent-docs/website/content/en/guide/core_moduls/*.md`: agent, tool, MCP, RAG, context, and schema docs.
- `qwen_agent/agent.py`: base message normalization, system prompt insertion, `_call_llm`, `_call_tool`, tool initialization, MCP import, and function-call detection.
- `qwen_agent/agents/fncall_agent.py`, `assistant.py`, `react_chat.py`, `tir_agent.py`: main tool loop, RAG assistant, ReAct path, and tool-integrated reasoning.
- `qwen_agent/llm/base.py`, `function_calling.py`, `schema.py`, `qwen_dashscope.py`, `oai.py`, `fncall_prompts/*.py`: message schemas, context truncation, prompt/native function calling, streaming aggregation, retries, and tool-call parsing.
- `qwen_agent/tools/base.py`, `__init__.py`, `mcp_manager.py`, `code_interpreter.py`, `python_executor.py`, `retrieval.py`, `doc_parser.py`, `simple_doc_parser.py`, `search_tools/*.py`, `web_search.py`, `web_extractor.py`, `image_search.py`, `storage.py`: tool registry, validation, MCP, execution, RAG, browser/web, and storage implementations.
- `qwen_agent/memory/memory.py`: file extraction, keyword generation, retrieval, and knowledge injection path.
- `examples/function_calling.py`, `function_calling_in_parallel.py`, `assistant_add_custom_tool.py`, `assistant_mcp_sqlite_bot.py`, `assistant_qwen3.py`, `assistant_qwen3_coder.py`, `assistant_rag.py`, `tir_math.py`, `qwen2vl_assistant_tooluse.py`: representative usage and custom tool patterns.
- `tests/tools/*`, `tests/agents/*`, `tests/llm/test_function_content.py`, `tests/memory/test_memory.py`: test coverage for tool calls, RAG/search, assistant loops, router, ReAct, and function-choice behavior.
- `benchmark/deepplanning/**/README.md`, travel/shopping tool schemas, travel `ToolsFnAgent`, shopping prompts/evaluation notes: benchmark tool contracts, call budgets, trajectories, and verification patterns.
- `setup.py`: optional dependency boundaries for minimal tools, RAG, MCP, code interpreter, Python executor, and GUI.

## Excluded Paths

- `qwen-agent-docs/website/app`, `src`, `public`, `package-lock.json`, and Next.js config: documentation website implementation, not agent/tool runtime. I reviewed Markdown content under `content/en`.
- `qwen_agent/gui/**`, `qwen_server/css/**`, `qwen_server/js/**`, and most `qwen_server/**`: UI/server presentation layer for demos, not core tool-use semantics. I only used browser/server docs for context.
- `browser_qwen/**`: Chrome extension UI/client code; reviewed `browser_qwen.md` for browser assistant behavior but excluded extension implementation from deep analysis.
- `assets/**`, `examples/resource/**`, `qwen_agent/gui/assets/**`, `browser_qwen/img/**`, and image/PDF/CSV binaries: demo media and binary fixtures, not reusable control logic.
- `qwen_agent/utils/qwen.tiktoken`, font files, screenshots, downloaded benchmark databases, and generated result folders: tokenizer/binary/generated data, not source design.
- `benchmark/code_interpreter/**`: separate benchmark harness for code interpreter evaluation; useful for eval context but not the package execution path requested here.
- Large DeepPlanning data JSON files: sampled only via README/schema references because they are benchmark cases rather than framework design.
