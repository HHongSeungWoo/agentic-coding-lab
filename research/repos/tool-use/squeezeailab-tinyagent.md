# SqueezeAILab/TinyAgent

- URL: https://github.com/SqueezeAILab/TinyAgent
- Category: tool-use
- Stars snapshot: 484 (GitHub REST API, captured 2026-05-20)
- Reviewed commit: cc45c0e842f5d163c3df1c8f41d60e90e005867d
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: conditional
- Verdict: Useful pattern source for edge/local tool-use agents, especially app-gated tool registries, ToolRAG prompt narrowing, streamed LLMCompiler planning, and sub-agent-backed tools. Do not treat it as a production safety reference: tool execution is in-process, Mac automation is prompt-mediated, permissions mostly rely on app toggles and OS prompts, validation is thin, and several concurrency/error paths are demo-grade.

## Why It Matters

TinyAgent is a compact example of a tool-use agent that tries to run useful personal automation with smaller/local models rather than a large hosted model. For Agentic Coding Lab, the value is not the Mac desktop use case itself; it is the shape of the runtime:

- A fixed tool enum is mapped from user-enabled apps into a runtime registry.
- A planner emits a small textual LLMCompiler plan with numbered calls and `$id` dependencies.
- A scheduler executes independent calls concurrently and feeds normalized observations to a joiner/replanner.
- ToolRAG reduces the prompt to likely tools and examples before planning.
- Some tools call smaller specialist sub-agents for email composition, notes, and PDF summaries.

Those are reusable tool-use patterns for coding agents: discover/select tools, keep the execution layer separate from the prompt layer, stream partial plans into execution, and route domain-heavy operations to narrower agents.

## What It Is

TinyAgent is an EMNLP 2024 demo repository for a Mac-oriented personal assistant. It exposes a FastAPI server that accepts text or voice input, loads a local JSON config from `~/Library/Application Support/TinyAgent/Configuration.json`, builds a `TinyAgent` instance, streams planner tokens to the UI, and runs tool calls against macOS applications, Zoom, local files, and LLM sub-agents.

The shipped tool set covers Contacts, Mail, SMS, Calendar, Maps, Notes, Reminders, Spotlight/file opening, PDF summarization, and Zoom meeting creation. The core agent path reuses the repository's bundled LLMCompiler implementation. Planner output is a textual program such as `1. get_email_address("Sid")`, `2. compose_new_email(["$1"], ...)`, then `join()`. The runtime parses those lines into tasks, infers dependencies from `$id` references, runs executable tasks, and asks a joiner LLM to finish or replan.

The repo also includes a binary desktop app zip, one PNG, a pickled ToolRAG embedding cache, copied/simplified LangChain-style chain/agent/executor helpers, and no obvious automated test suite.

## Research Themes

- Token efficiency: Moderate to high. ToolRAG retrieves a smaller tool/example set, LLMCompiler can execute independent tool calls without serial ReAct turns, and sub-agents keep specialist prompts separate. The main weakness is that observations, previous plans, and PDF/note/email context are still concatenated text with limited compression.
- Context control: High concept, mixed implementation. `ClassifierToolRAG` predicts relevant tools and retrieves examples from `embeddings.pkl`, then `TinyAgent.arun` replaces the planner prompt. However, it only updates `planner.system_prompt`; the parser/tool allowlist and replan prompt remain from the original full tool set.
- Sub-agent / multi-agent: Medium. There is one planner, one joiner, and three specialist sub-agents (`ComposeEmailAgent`, `NotesAgent`, `PDFSummarizerAgent`). They are tool helpers, not autonomous workers with separate memory or lifecycle.
- Domain-specific workflow: High. Tool descriptions encode concrete Mac workflow rules: get addresses before email, get phone numbers before SMS, create a Zoom link before calendar/email use, use ISO dates, fill every argument, and call `join()` last.
- Error prevention: Medium. Unknown tool names in streaming mode become a join observation that asks for correction, tool exceptions become observations with "try again", and the joiner can request one replan. There is no strict plan schema, approval system, sandbox, per-tool timeout, side-effect policy, or audit-grade trace.
- Self-learning / memory: Low. Persistent state is limited to user config, custom instructions, ToolRAG embeddings, and transient cached PDF summary output. There is no durable session memory or learning loop.
- Popular skills: Tool enum to registry mapping, app-gated tool availability, retrieved examples near tool descriptions, textual `$id` dataflow, streamed plan parsing, sub-agent-backed tools, and recoverable error observations.

## Core Execution Path

`run_tiny_agent_server.py` starts a FastAPI app on `127.0.0.1:50001`. `/generate` empties the global `streaming_queue`, validates the query, loads config, constructs `TinyAgent`, starts `tiny_agent.arun(query)` as an async task, and streams tokens from `streaming_queue` until a sentinel or error token arrives. After generation, it awaits the task and appends the final answer. `/voice` transcribes raw PCM audio with either OpenAI Whisper or a local whisper.cpp server. `/quit` sends `SIGTERM` to the process.

`TinyAgent.__init__` builds the main LLM, streaming planner LLM, and sub-agent LLM from OpenAI, Azure, or local OpenAI-compatible endpoints. It constructs a `Computer` facade, creates email/notes/PDF sub-agents, maps enabled apps to `TinyAgentToolName` values, builds concrete `Tool` objects with `get_tiny_agent_tools`, and initializes `LLMCompiler` with `planner_stream=True`, `max_replans=2`, default examples, tool-specific planner instructions, and joiner prompts.

`TinyAgent.arun` optionally runs `ClassifierToolRAG`. ToolRAG classifies the user query into tool labels, filters to app-enabled tools, loads matching in-context examples from the pickled embedding cache, retrieves top examples by embedding similarity, rebuilds the tool subset, and replaces the planner system prompt with descriptions and examples for that subset. Then `compose_email_agent.query` is set to the original query and `LLMCompiler.arun` is invoked. If the final result is the sentinel `Summary`, TinyAgent returns the cached PDF summary from the PDF sub-agent.

`LLMCompiler._acall` is the main planner/executor loop. In streaming mode it starts `Planner.aplan` in the background and calls `TaskFetchingUnit.aschedule`. `LLMCompilerCallback` receives new LLM tokens, sends them to the UI queue, buffers complete lines, parses `Thought:` and numbered tool calls, and pushes parsed `Task` objects into the scheduler queue. When `join()` appears, it pushes a `None` sentinel.

`LLMCompilerPlanParser` and `instantiate_task` parse tool calls with regex, parse arguments with `ast.literal_eval` when possible, look up tool names in the registry, and infer dependencies by scanning arguments for `$1` or `${1}` markers. A `join` task depends on all earlier task IDs.

`TaskFetchingUnit` keeps `tasks`, `tasks_done` events, and `remaining_tasks`. It schedules tasks whose dependencies are done, substitutes `$id` placeholders with previous observations, calls the tool coroutine, catches exceptions into error observations, and marks the task complete. The joiner then receives a thought/action/observation scratchpad and returns `Action: Finish(...)` or `Action: Replan(...)`. Replanning appends previous plans and joiner thought into `inputs["context"]` for the next planner iteration.

Actual tool side effects happen in `src/tiny_agent/tools/*`: AppleScript through `osascript`, Spotlight/`open`/`mdfind`, browser URL opens, Zoom REST calls, PDF text extraction, and LLM sub-agent calls.

## Architecture

The architecture has five layers:

- Server boundary: `run_tiny_agent_server.py` owns HTTP endpoints, streaming token relay, voice transcription, and shutdown.
- Configuration/model layer: `src/tiny_agent/config.py`, `models.py`, and `src/utils/model_utils.py` load provider settings, API keys, context lengths, app toggles, and model clients.
- Tool registry layer: `TinyAgentToolName`, `APPS_TO_TOOL_NAMES`, and `get_tiny_agent_tools` map enabled apps into concrete `Tool` objects with names, async functions, descriptions, and stringify rules.
- Planning/execution layer: `src/llm_compiler/*` owns planner prompts, streaming parse callbacks, plan parsing, dependency inference, task scheduling, joiner prompts, replanning, and observation scratchpads.
- Native/app adapter layer: `Computer` exposes Calendar, Contacts, Mail, Maps, Notes, Reminders, SMS, SpotlightSearch, and Zoom. Sub-agents hang off tools as helper LLMs for content generation.

ToolRAG is a cross-cutting context-control layer. It does not own execution. It changes what the planner sees, not what the scheduler is capable of executing.

## Design Choices

The tool registry is fixed and explicit. `TinyAgentToolName` is the canonical list, and app toggles determine which enum values become active tools. This is a good small-agent pattern because the model sees a stable vocabulary and the host has one place to attach metadata.

Tool descriptions are treated as planner contracts. The repo does not expose JSON schemas to the planner; instead each tool description includes a signature-like line plus prose constraints. Additional global and tool-specific rules are appended by `get_planner_custom_instructions_prompt`.

The execution IR is textual rather than JSON. It is easy for fine-tuned small models to emit and easy for humans to inspect, but validation is weaker than a typed schema. Argument count/type errors surface only when the Python function is called.

ToolRAG narrows the prompt, not the authority boundary. After retrieval, `TinyAgent.arun` sets a new prompt using `new_tools`, but `self.agent.planner.tools` and `self.agent.planner.output_parser.tools` still point at the original tools. A model is less likely to call unshown tools, but execution is not hard-filtered by ToolRAG.

Sub-agents are wrapped as normal tools. Email composition, note formatting, and PDF summarization are not separate top-level workflows; they are callable helpers inside tool execution. This keeps the planner's tool vocabulary small while still using specialist prompts.

Most risky actions open drafts or UI state rather than silently sending. Mail compose/reply/forward and SMS open drafts/windows. Calendar events, reminders, notes, file opens, map URLs, and Zoom meetings do create or open real resources.

The server constructs a new `TinyAgent` per `/generate` request. That keeps per-request state simple but reloads models/tool clients repeatedly and shares one global streaming queue across requests.

## Strengths

The app-gated registry is concrete and reusable. Enabling apps maps to exact tool names, and the planner prompt is generated from only those available tools.

ToolRAG directly targets small-model tool confusion. Classify tools first, retrieve examples second, and regenerate the planner prompt with a smaller tool surface.

The streamed LLMCompiler path reduces latency. Tool execution can start when complete plan lines arrive, before the planner finishes the entire output.

Error observations are planner-readable. Unknown tools and tool exceptions are formatted into observations that the joiner can classify as fixable and send into the replanner.

Sub-agent-backed tools are a strong decomposition pattern. A coding equivalent could route "write changelog", "summarize trace", or "draft migration note" through small specialist agents while the main planner handles workflow.

The native tools make side effects explicit in code. Every app adapter is a small file, so it is easy to audit which operations read contacts, compose mail, create calendar events, open files, or call Zoom.

Context-length checks exist for sub-agents. Compose email and PDF summarization attempt to truncate long contexts against configured tokenizers before calling the sub-agent LLM.

The repo is small enough to study end to end. The main execution path crosses a handful of files rather than a full platform.

## Weaknesses

ToolRAG is not an execution allowlist. Replacing only the planner prompt means the scheduler/parser can still execute any originally enabled tool if the model emits it, and the replan prompt is not refreshed with the retrieved subset.

Tool schemas are mostly prose. `src/tools/base.py` can infer Pydantic schemas for `StructuredTool`, but TinyAgent's concrete tools are plain `Tool` objects with manual signature strings. There is no runtime schema validation before side-effecting calls.

The permission model is coarse. User app toggles and macOS TCC prompts are the main boundaries. There is no per-call confirmation, read/write/network classification, dry-run mode, or high-risk approval step.

Several tools interpolate user/model text into AppleScript strings with partial escaping. Quotes are sometimes escaped, but newlines, braces, AppleScript-sensitive content, and HTML are not consistently sanitized. This is not a robust injection boundary.

Global streaming state is not concurrency-safe. `streaming_queue` is module-level; `/generate` empties it at request start and all planner callbacks write into it. Concurrent requests can mix or consume each other's tokens.

Background planner tasks are weakly supervised. `LLMCompiler._acall` creates `Planner.aplan` without retaining or awaiting the task. Some LLM errors go to the UI queue rather than the scheduler queue, so the HTTP stream can error while the response task is still alive.

Scheduler validation is thin. Missing dependencies, duplicate task IDs, future `$id` references, cycles, oversized plans, and unavailable join steps are not prevalidated. Some malformed plans can leave placeholders unresolved or fail inside scheduling.

There are no per-tool timeouts or cancellation budgets. A stuck AppleScript, local model call, PDF parse, or HTTP request can stall the agent path.

Zoom handling is incomplete. It opens an `aiohttp.ClientSession()` without an `async with`, does not check HTTP status, and assumes `join_url` exists in the JSON response.

Some input fallback logic has bugs. `create_reminder` computes `due_date_args` but then calls `datetime.fromisoformat(due_date)` again, so invalid or missing dates can still fail. `NotesAgent` computes a truncated context but rebuilds messages with the original `content`.

ToolRAG loads a repo-local pickle with `pickle.load`. That is acceptable only for a trusted installed artifact; it should not be copied as a pattern for untrusted registry data.

No tests are shipped. There are no visible unit tests for parser behavior, ToolRAG empty results, AppleScript escaping, scheduler failure modes, server concurrency, or tool side effects.

## Ideas To Steal

Use an enum-backed tool registry. Keep stable tool IDs separate from prompt descriptions and app/domain groupings.

Generate planner prompts from enabled tools only. Tool descriptions should carry signatures, side-effect notes, argument rules, and known misuse patterns.

Add a hard execution filter after retrieval. ToolRAG should return a prompt subset and an execution allowlist, and the parser should reject tools outside that subset for the current turn.

Use retrieval in two phases: tool classification first, example retrieval second. This avoids retrieving examples that require disabled or irrelevant tools.

Represent tool plans as inspectable numbered calls with `$id` dependencies. For coding workflows, this maps cleanly to file reads, searches, tests, formatters, and synthesis.

Stream complete plan lines into a scheduler. Independent repository reads and searches can begin before full planning completes.

Wrap specialist agents as tools. A main coding planner can call specialist agents for commit-message drafting, test-log summarization, migration notes, or doc synthesis without making them full orchestrators.

Normalize tool errors into observations for replanning. Include `tool`, `args`, `error_kind`, `message`, and `retryable` instead of only a string.

Separate "shown to model" from "allowed to execute" as two explicit objects. TinyAgent shows why the distinction matters.

Keep side-effect adapters small. One file per app/service makes policy review easier.

## Do Not Copy

Do not rely on prompt narrowing as a permission boundary. A retrieved tool subset must also constrain parser lookup and execution.

Do not execute side-effecting desktop automation without an approval and audit layer. Calendar, reminders, notes, file opens, and network calls need visible policy metadata.

Do not interpolate model-controlled strings into AppleScript or shell-adjacent commands without structured escaping or a safer API.

Do not share one global stream queue across concurrent requests. Use per-request queues, task ownership, and cancellation.

Do not load tool/example registries from pickle unless the file is fully trusted and versioned. Prefer JSON, SQLite, safetensors, or another non-code data format.

Do not leave planner tasks unawaited. Execution should track planner task state, propagate failure into the scheduler, and cancel running tool tasks on request failure.

Do not treat function signature text as validation. Add typed schemas, arity checks, enum validation, date parsing, and side-effect policies before tool invocation.

Do not copy the unauthenticated `/quit` endpoint into a broader service. It is local-demo acceptable only because the server binds localhost.

Do not assume draft-opening tools are harmless. Drafts still expose private content, attachments, and recipient choices, and UI automation can focus the wrong window.

## Fit For Agentic Coding Lab

TinyAgent is conditionally useful for Agentic Coding Lab as a compact pattern mine, not as a runtime dependency.

Best adaptations:

- `ToolName` enum plus category mapping for repo tools, shell tools, docs tools, browser tools, and memory tools.
- ToolRAG-like tool shortlist before planning, backed by hard per-turn execution allowlists.
- LLMCompiler-style textual plan IR for parallelizable coding tasks.
- Sub-agent tools for narrow content generation or summarization, not broad autonomous workers.
- Side-effect adapter files with explicit metadata: read/write/network/shell, timeout, approval needed, output schema, and redaction policy.
- Planner-readable structured failure observations for retry/replan.

Required changes before reuse:

- Replace prose signatures with schemas.
- Add plan validation before execution.
- Add per-tool timeouts, cancellation, retries, max tasks, and max concurrency.
- Use per-request queues and trace IDs.
- Make ToolRAG update both prompt and parser/executor state.
- Add tests around parser errors, missing dependencies, retrieved allowlists, side-effect policy, and concurrent runs.

For coding-agent work, the most valuable idea is "small retrieved tool surface plus executable dependency plan." The part to avoid is mixing context reduction with authority control.

## Reviewed Paths

- `README.md` for project scope, Mac app behavior, supported tools, ToolRAG claims, local/OpenAI/Azure provider setup, model claims, and customization instructions.
- `run_tiny_agent_server.py` for FastAPI endpoints, `/generate` streaming flow, config loading, queue handling, voice transcription, and shutdown behavior.
- `src/tiny_agent/tiny_agent.py` for model construction, `Computer`/sub-agent wiring, app-enabled tool registry creation, LLMCompiler setup, ToolRAG prompt replacement, and summary sentinel handling.
- `src/tiny_agent/config.py` and `src/tiny_agent/models.py` for config parsing, provider validation, app toggles, model dataclasses, tool enum, global streaming queue, and TinyAgent data model.
- `src/tiny_agent/prompts.py` for default planner examples, tool-specific planner rules, custom instruction injection, joiner finish/replan rules, and final prompt behavior.
- `src/tiny_agent/tiny_agent_tools.py` for concrete tool construction, app-to-tool mapping, argument normalization, contact/email/file formatting, Zoom setup, and tool descriptions/stringify rules.
- `src/llm_compiler/llm_compiler.py`, `planner.py`, `output_parser.py`, `task_fetching_unit.py`, and `constants.py` for planner prompt generation, streaming callbacks, plan parsing, dependency inference, scheduling, error observation, joiner parsing, replanning, and UI token streaming.
- `src/tools/base.py` for LangChain-style `Tool` and `StructuredTool`, schema inference support, tool invocation behavior, and how concrete TinyAgent tools bypass structured schema validation.
- `src/tiny_agent/tool_rag/base_tool_rag.py`, `classifier_tool_rag.py`, and `simple_tool_rag.py` for classifier-based tool retrieval, embedding example retrieval, available-tool filtering, prompt assembly, and pickle loading.
- `src/tiny_agent/computer.py` and `src/tiny_agent/tools/*.py` for app adapter boundaries: AppleScript, Contacts, Mail, Calendar, Notes, Reminders, SMS, Spotlight, Maps, and Zoom REST calls.
- `src/tiny_agent/sub_agents/sub_agent.py`, `compose_email_agent.py`, `notes_agent.py`, and `pdf_summarizer_agent.py` for specialist LLM prompts, context trimming, cached PDF summary behavior, and HTML/email generation.
- `src/tiny_agent/transcription.py` for OpenAI Whisper and whisper.cpp client boundaries, resampling, local HTTP call shape, and voice endpoint behavior.
- `src/utils/model_utils.py`, `data_utils.py`, `plan_utils.py`, `graph_utils.py`, `logger_utils.py`, and `callbacks/callbacks.py` for provider clients, plan/eval helpers, graph comparison, logging, stats, and token accounting.
- `requirements.txt` for dependency footprint and host/runtime assumptions.

## Excluded Paths

- `TinyAgent.zip`: binary desktop app bundle. It was size-checked and noted as a release artifact, but not unpacked or reviewed because the requested output is a source-level GitHub repo review and the zip is not needed to understand the Python execution path.
- `figs/tinyagent.png`: README/demo image only, not part of tool schemas, orchestration, validation, or execution.
- `src/tiny_agent/tool_rag/text-embedding-3-small/embeddings.pkl`: 10.3 MB binary pickled retrieval cache. Its loading path and trust implications were reviewed, but the pickle contents were excluded because it is binary training/retrieval data rather than source logic.
- `src/agents/*`, `src/chains/*`, and `src/executors/*`: copied/simplified LangChain-style compatibility and baseline code. They were read selectively for schema/error context, but TinyAgent's main path uses `src/llm_compiler/*`, so they were not treated as the core design.
- `.git/**`, `.gitignore`, and `LICENSE`: repository metadata and legal text, not execution behavior.
- Remote demo video, blog post, Hugging Face model/dataset pages, and arXiv PDF linked from README: useful project context, but not necessary for this source-code execution review.
