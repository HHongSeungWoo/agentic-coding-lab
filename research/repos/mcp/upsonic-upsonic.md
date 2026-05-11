# Upsonic/Upsonic

- URL: https://github.com/Upsonic/Upsonic
- Category: mcp
- Stars snapshot: 7,844 via GitHub API on 2026-05-11
- Reviewed commit: a9e515e307492960dd13a6e202f5cca9527e568a
- Reviewed at: 2026-05-11
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong MCP-enabled Python agent framework with reusable patterns for tool normalization, agent/team as MCP, policy gates, context compaction, and orchestration. It is a pattern source rather than a drop-in coding-agent runtime because its autonomous shell sandbox and verification loops are weaker than its orchestration abstractions.

## Why It Matters

Upsonic is relevant because it combines three surfaces that usually live in separate projects: a general Agent/Task runtime, a first-class MCP adapter, and higher-order agent orchestration through Team, DeepAgent, AutonomousAgent, and RalphLoop. For an agentic coding lab, the important value is not the public API alone; it is how MCP tools, Python tools, sub-agents, safety policies, memory, context compression, and evaluation all enter the same execution loop.

The repo also contains unusually detailed source-adjacent docs under `documents/ai/explanation/`. Those docs mostly match the code paths reviewed, which makes the project useful as an implementation reference for documenting agent runtimes.

## What It Is

Upsonic is a Python package for building autonomous AI agents. The reviewed package version in `pyproject.toml` is `0.76.3`, with optional extras for MCP, vector stores, loaders, model providers, storage, OCR, browser/web tools, and other integrations. The public root lazily exposes `Agent`, `Task`, `Team`, `Direct`, `Simulation`, `RalphLoop`, `AutonomousAgent`, and `PrebuiltAutonomousAgentBase`.

The core user model is:

- `Agent` owns model configuration, tool managers, policies, memory, context management, reliability, reflection, instrumentation, and workspace instructions.
- `Task` is the shared run object carrying description, context, attachments, response format, tools, skills, cache, guardrails, policy scope flags, RAG controls, usage, and final response.
- `ToolManager` converts many tool input forms into common `ToolDefinition` and `ToolResult` shapes.
- `MCPHandler` and `MultiMCPHandler` discover remote MCP tools and wrap them as normal Upsonic tools.
- `Agent.as_mcp()` and `Team.as_mcp()` expose local agents and teams as FastMCP servers with a `do(task: str)` tool.
- `Team`, `DeepAgent`, `AutonomousAgent`, and `RalphLoop` layer multi-agent, planning, filesystem/shell, and autonomous coding loops on top of the same agent pipeline.

## Research Themes

- Token efficiency: Lazy imports reduce cold-start load, and `ContextManagementMiddleware` prunes older tool rounds then summarizes old conversation pairs while preserving tool-call IDs. DeepAgent uses subagents and a virtual filesystem to keep main context smaller. RalphLoop stores state on disk and spawns fresh agents per iteration. Downsides: system prompts are very large, routing/selection prompts are verbose, and token budgeting is mostly reactive after context growth.
- Context control: Task context becomes explicit XML-like blocks for other tasks, RAG chunks, prior graph outputs, metadata, raw strings, and workspace `AGENTS.md`. System prompts also collect role/goal/instructions, culture, memory user profile, tool instructions, skills, and agent persona context. The context middleware preserves message part structure during summarization, which is important for tool-call continuity.
- Sub-agent / multi-agent: `Team` supports sequential, coordinate, and route modes; `DeepAgent` adds `task` subagent delegation; `ToolNormalizer` can wrap an `Agent` itself as a tool; the `plan_and_execute` orchestrator can use an analysis agent after plan steps; RalphLoop spawns disposable subagents for read/write/test/search work.
- Domain-specific workflow: The project has specialized modes for plain tasks, teams, deep agents, autonomous workspace agents, prebuilt autonomous agents, and RalphLoop coding loops. This gives several real patterns for domain-specific agent shells over a shared runtime.
- Error prevention: The runtime includes guardrail retries, tool-call limits, pre-registration and pre-execution tool policies, user and output policies, HITL pauses, read-before-edit file edits, MCP include/exclude filters, timeout/retry/caching wrappers, and truncated-tool-argument retry handling.
- Self-learning / memory: Agent memory can inject message history, summaries, user profiles, metadata, and cultural knowledge. RalphLoop uses a stronger deterministic memory pattern by persisting `PROMPT.md`, specs, a plan file, and `AGENT.md` learnings on disk.
- Popular skills: Useful built-in skill-like patterns include summarization, data analysis, code review, tool orchestration, reusable `ToolKit` bundles, and prebuilt applied-scientist skills for research, benchmarking, implementation, evaluation, progress tracking, and experiment management.

## Core Execution Path

The normal path starts at `Agent.do()` or `Agent.do_async()` with a string or `Task`. The agent normalizes input into a `Task`, registers a run id, opens an OpenTelemetry span when configured, then enters `_do_async_pipeline()`.

The direct pipeline is built by `Agent._create_direct_pipeline_steps()` and run by `PipelineManager`. Its main sequence is initialization, storage connection, cache check, LLM/model selection, tool setup, memory preparation, system prompt build, context build, chat history, user policy, user input assembly, message assembly, call manager setup, model execution, response processing, reflection, task management, reliability, agent output policy, cache storage, finalization, memory save, and call management. The shared state is `AgentRunOutput`; steps mutate it instead of passing many ad hoc values.

Tool setup calls `agent._setup_task_tools(task)`, which combines agent-level and task-level tools. `ToolManager.register_tools()` asks `ToolNormalizer` to process raw Python functions, methods, `ToolKit`s, providers, agents, MCP handlers, and classes. `ToolRegistry` stores the wrapped tools and ownership maps. `ToolWrapper` adds hooks, HITL pause checks, cache checks, retry/timeout, metrics, and stop-after-tool behavior.

Model execution calls the selected model adapter with a `ModelRequest`. If the model returns tool calls, `Agent._handle_model_response()` calls `_execute_tool_calls()`, which partitions calls by `ToolDefinition.sequential`, enforces `tool_call_limit`, validates each call with `tool_policy_post`, executes calls through `ToolManager.execute_tool()`, appends tool return parts, applies context management before the next model request, and recurses until no tool calls remain. HITL exceptions become run requirements so a paused run can be resumed.

The MCP path enters through `MCPHandler` or `MultiMCPHandler` in a task or agent tool list. `ToolNormalizer` calls `handler.get_tools()`, which opens a temporary connection, initializes the MCP session, lists tools, filters by include/exclude, prefixes names if configured, wraps each remote tool as `MCPTool`, and closes discovery. During execution, `MCPTool.execute()` calls `handler.call_tool(original_name, args)`, reusing a persistent MCP session in the agent's event loop and converting text, image, and embedded-resource MCP content into Upsonic tool results.

The export path runs in the opposite direction: `Agent.as_mcp()` and `Team.as_mcp()` lazily import FastMCP and expose one `do(task: str)` tool. Smoke tests show another Upsonic agent consuming those servers through `MCPHandler(command=f"{sys.executable} tests/..._server.py")`.

The coding-agent path has several variants. `AutonomousAgent` subclasses `Agent`, creates or resolves a workspace, adds workspace-bounded filesystem and shell toolkits, reads workspace `AGENTS.md`, and then uses the normal agent pipeline. `DeepAgent` subclasses `Agent`, adds a virtual filesystem backend, planning tool, and subagent delegation tool, then also uses the normal pipeline. `RalphLoop` is a separate autonomous development loop that stores durable state in markdown files, creates fresh agents per iteration, uses subagents, and gates progress with build/test/lint backpressure commands.

The eval path is separate from the main pipeline. `AccuracyEvaluator` runs an Agent/Graph/Team and scores output with a judge agent returning a Pydantic `EvaluationScore`. `PerformanceEvaluator` deep-copies tasks and measures latency plus memory with `tracemalloc`. `ReliabilityEvaluator` checks actual tool-call names against expected names, with optional ordering and exact-match checks.

## Architecture

The architecture is layered:

- Public facade: `src/upsonic/__init__.py` uses lazy import tables to expose the major runtime classes without importing every optional dependency.
- Agent core: `src/upsonic/agent/agent.py` owns the main public API, sync wrappers, run registration, model/tool/policy helpers, MCP export, and direct/streaming pipeline construction.
- Pipeline: `src/upsonic/agent/pipeline/` defines `Step`, `StepResult`, `StepStatus`, concrete pipeline steps, and `PipelineManager` for sequential or streaming execution.
- Context and memory: `src/upsonic/agent/context_managers/` builds prompts, task context, memory injection, chat history, reliability preparation, and context-window management.
- Tools: `src/upsonic/tools/` defines `Tool`, `ToolKit`, schema generation, `ToolManager`, normalizer, registry, execution wrapper, HITL pauses, MCP adapter, function/agent wrappers, built-in tools, and the `plan_and_execute` orchestrator.
- MCP: `src/upsonic/tools/mcp.py` handles stdio, SSE, and streamable HTTP transports; command preparation; discovery; persistent sessions; prefixing; multimodal result conversion; and multi-server aggregation.
- Task: `src/upsonic/tasks/tasks.py` is the run scratchpad used by agent, team, graph, tools, cache, RAG, policy, guardrail, reliability, and usage systems.
- Safety: `src/upsonic/safety_engine/`, `agent/policy_manager.py`, and `agent/tool_policy_manager.py` apply rule/action policies to input, output, tool registration, and tool calls.
- Orchestration: `src/upsonic/team/`, `agent/deepagent/`, `agent/autonomous_agent/`, and `ralph/` provide multi-agent and coding-agent shells.
- Evaluation: `src/upsonic/eval/` provides accuracy, reliability, and performance evaluators.
- Provider integrations: `src/upsonic/models/`, `profiles/`, `storage/`, `knowledge_base/`, `vectordb/`, loaders, and common/custom tools integrate external services and model APIs.

## Design Choices

- Treat every callable surface as a tool. Raw functions, methods, agents, MCP tools, toolkits, providers, and class instances all converge into `ToolDefinition` and `ToolResult`.
- Keep execution state in `AgentRunOutput` and `Task` instead of scattering state across pipeline steps.
- Separate MCP discovery from MCP execution. Discovery is short-lived and can run in a helper thread when already inside an event loop; execution uses a persistent session.
- Preserve MCP original names when prefixing. The LLM sees `prefix_tool`, but `MCPTool` calls the remote server with the original tool name.
- Make safety a pipeline concern and a tool concern. User policies run before message assembly, output policies after reliability, and tool policies before registration or actual invocation.
- Use XML-like prompt blocks for context boundaries. This is not novel, but it makes data provenance explicit and easy to inspect in traces.
- Provide both deterministic and LLM-based verification. Guardrails and tool-call reliability are deterministic; accuracy, routing, result combining, and many policy feedback loops are LLM-driven.
- Support internal-to-external agent composition. Agent-as-tool and agent/team-as-MCP let the same runtime be nested inside other runtimes.
- Separate real workspace operations from virtual filesystem operations. `AutonomousAgent` touches disk under a workspace; `DeepAgent` defaults to an in-memory virtual backend.

## Strengths

- MCP support is practical: stdio/SSE/streamable HTTP, include/exclude filters, name prefixing, original-name preservation, multi-server aggregation, and text/image/resource result handling.
- Tool normalization and ownership tracking are reusable. The registry can remove individual tools, entire MCP handlers, toolkits, agents, and providers cleanly.
- The pipeline is inspectable. Named steps, step results, run output, event classes, OTel spans, and PromptLayer/Langfuse hooks create good seams for tracing and tests.
- Context management is structurally aware of tool calls. It prunes old tool rounds and asks a model to summarize old requests/responses while preserving tool-call ids and part kinds.
- Safety controls exist at several boundaries: input, output, tool registration, tool execution, filesystem path validation, and MCP command preparation.
- Multi-agent options cover common patterns: sequential specialist selection, leader delegation, router selection, DeepAgent subagents, agent tools, and MCP export.
- RalphLoop is a useful autonomous coding pattern because it uses durable markdown state, fresh agents per iteration, subagents for expensive work, and backpressure commands before progress is marked.
- Evaluation covers three different concerns: answer quality, performance, and expected tool-call behavior.

## Weaknesses

- The autonomous shell sandbox is weak by coding-agent standards. `AutonomousShellToolKit` defaults to `shell=True` and a small substring blocklist. It runs in the workspace, but many destructive workspace commands are still possible unless callers add an allowlist or external controls.
- MCP stdio command validation is less strict than the error message suggests. `prepare_command()` blocks shell metacharacters and has an allowlist, but it also accepts any executable found by `shutil.which(first_part)`, so installed commands outside the nominal allowlist can pass.
- MCP's security warning is accurate but not a full policy. Stdio MCP servers still run arbitrary local processes; there is no per-server approval workflow or capability sandbox in the reviewed path.
- Context management is reactive and partly heuristic. It estimates tokens from prior usage or character counts, then uses an LLM summarizer that can fail or distort old context.
- Several high-level orchestration choices are prompt-driven. Team selection, routing, result combining, accuracy judging, and policy feedback depend on LLM behavior without much deterministic fallback beyond retries and first-entity fallback.
- `ReliabilityEvaluator` checks tool-call names and order, not argument semantics, tool outputs, or side effects. `AccuracyEvaluator` is LLM-as-judge and can be nondeterministic.
- DeepAgent subagent delegation is useful, but usage rollup and concurrency semantics are less explicit than the prompts imply. Multiple subagent calls can run in the normal parallel tool path only if the model emits them that way.
- The runtime does not provide a mature coding-agent verification contract like mandatory diff review, test result parsing, git safety, network/secret sandboxing, or human approval before destructive commands.

## Ideas To Steal

- Normalize all tool sources into one registry with ownership maps, so add/remove and policy enforcement work the same for functions, agents, MCP handlers, and toolkits.
- Preserve `mcp_original_name` metadata when prefixing tools, so collision avoidance does not leak into remote call semantics.
- Use `AgentRunOutput` as a serializable run ledger containing status, step results, usage, messages, requirements, and trace ids.
- Make context compaction preserve tool-call/return structure and exact ids instead of summarizing the conversation as plain text.
- Put tool policies both before exposure to the model and immediately before execution.
- Model HITL as typed pause exceptions that become resumable run requirements, not as ad hoc callbacks inside tools.
- Expose agents and teams as MCP servers with the same `do(task)` surface used internally.
- For autonomous coding loops, prefer RalphLoop's disk-backed state and backpressure pattern over relying on long conversational memory.
- Use a reliability evaluator for tool-call expectations alongside broader LLM-as-judge accuracy evals.

## Do Not Copy

- Do not copy the default shell execution stance. A coding agent needs stronger command allowlists, approvals, dry-run/diff previews, and probably `shell=False` where possible.
- Do not copy the `prepare_command()` executable check as-is if the goal is a strict MCP command allowlist; accepting any executable on `PATH` weakens the allowlist.
- Do not rely on a security warning alone for MCP server trust. Treat stdio servers as local code execution.
- Do not make huge monolithic prompt strings the primary control plane without tests that lock down expected behavior.
- Do not use LLM judges, routers, and combiners as the only correctness mechanism for coding tasks.
- Do not treat workspace path bounds as sufficient protection for file deletion or shell execution.
- Do not hide verification behind framework abstraction. Coding-agent applicability needs explicit test/build/lint commands, captured outputs, and pass/fail semantics.

## Fit For Agentic Coding Lab

Upsonic is in-scope as a source of MCP and orchestration patterns. The highest-fit pieces are `MCPHandler`/`MultiMCPHandler`, `ToolManager` normalization, agent/team as MCP, policy gates, context compaction, and RalphLoop's disk-state plus backpressure loop.

It is a medium fit as a direct coding-agent base. `AutonomousAgent`, `DeepAgent`, and RalphLoop show useful directions, but the reviewed execution paths need stronger shell safety, deterministic verification, git-aware change control, and human approval semantics before they are appropriate for high-trust codebase modification.

Recommended use: mine patterns and tests, especially around MCP prefixing, tool registry ownership, structured run output, context pruning/summarization, and disk-backed autonomous loops. Avoid adopting the default workspace shell behavior without redesign.

## Reviewed Paths

- `README.md`: public positioning, AutonomousAgent example, Agent/Task examples, MCP next step.
- `pyproject.toml`: package version, extras, MCP optional dependencies, provider/storage/tooling scope.
- `src/upsonic/__init__.py`: lazy public facade and root exports.
- `src/upsonic/agent/agent.py`: Agent constructor, direct/streaming pipeline setup, `do_async`, model loop, tool-call execution, policies, context management integration, `as_mcp`.
- `src/upsonic/agent/pipeline/manager.py` and `src/upsonic/agent/pipeline/steps.py`: pipeline execution, step sequence, tool setup, model execution, finalization, MCP cleanup.
- `src/upsonic/agent/context_managers/context_manager.py`, `system_prompt_manager.py`, `memory_manager.py`, and `context_management_middleware.py`: task context, system prompt assembly, memory injection, context pruning/summarization.
- `src/upsonic/tasks/tasks.py`: Task fields, context file extraction, tool management, guardrail/cache/policy state.
- `src/upsonic/tools/__init__.py`, `base.py`, `config.py`, `execution.py`, `hitl.py`, `normalizer.py`, `registry.py`, `wrappers.py`, and `orchestration.py`: tool abstractions, wrapping, HITL, registration, ownership, agent tools, and `plan_and_execute`.
- `src/upsonic/tools/mcp.py`: MCP command preparation, warning, transport setup, discovery, `MCPTool`, `MCPHandler`, `MultiMCPHandler`, prefixing, call/result processing.
- `src/upsonic/team/team.py`, `coordinator_setup.py`, `delegation_manager.py`, `context_sharing.py`, `task_assignment.py`, and `result_combiner.py`: sequential, coordinate, route, delegation tools, routing, result synthesis, `as_mcp`.
- `src/upsonic/agent/autonomous_agent/autonomous_agent.py`, `tools/filesystem.py`, and `tools/shell.py`: workspace setup, read/write/edit/list/search/grep/move/copy/delete, shell execution, path validation.
- `src/upsonic/agent/deepagent/`: DeepAgent construction, virtual filesystem, planning toolkit, subagent toolkit, prompts, backends.
- `src/upsonic/ralph/`: loop/config/result, state manager, phases, backpressure gate, filesystem/subagent/learnings/plan tools.
- `src/upsonic/eval/accuracy.py`, `performance.py`, `reliability.py`, and `models.py`: judge scoring, performance profiling, tool-call reliability assertions.
- `src/upsonic/agent/policy_manager.py`, `tool_policy_manager.py`, `src/upsonic/safety_engine/base/`, `anonymization.py`, and selected policy modules: policy execution, reversible anonymization, tool safety path.
- `tests/smoke_tests/tools/test_agent_as_mcp.py`, `_math_agent_server.py`, `test_team_as_mcp.py`, `_team_server.py`, `test_smoke_mcp.py`, and `test_mcp_tool_name_prefix.py`: MCP smoke path, exported agent/team consumption, prefix behavior.
- `tests/smoke_tests/agent/test_context_management_middleware.py`, `tests/smoke_tests/task/test_task_guardrail.py`, `tests/smoke_tests/policy/test_tool_policy.py`, `tests/smoke_tests/evals/`, `tests/unit_tests/agent/test_deep_agent.py`, and `tests/unit_tests/ralph/test_ralph_comprehensive.py`: focused verification of context, guardrails, tool policies, evals, DeepAgent, and RalphLoop.
- `documents/ai/explanation/agent/agent.md`, `tools/tools.md`, `tasks/tasks.md`, `eval/eval.md`, `safety_engine/safety_engine.md`, `team/team.md`, `context/context.md`, and `ralph/ralph.md`: source-adjacent docs used to cross-check actual execution paths.

## Excluded Paths

- `uv.lock`, generated caches, and `__pycache__/`: generated dependency/runtime artifacts; not useful for architecture review.
- `notebooks/`: notebook demos and report artifacts; useful for product examples but not needed to understand agent/MCP execution paths.
- `src/upsonic/models/`, `profiles/`, and provider-specific model adapters beyond MCP references in search results: important for production behavior, but this review focused on agent orchestration and tool/MCP paths rather than every provider's request mapping.
- `src/upsonic/storage/`, `knowledge_base/`, `vectordb/`, `embeddings/`, `text_splitter/`, and loaders beyond context/RAG call sites: these are storage/RAG implementation details; reviewed only where Agent context and memory call into them.
- `src/upsonic/interfaces/`, `cli/`, `server/`, and channel integrations: user-facing transport/UI surfaces; not central to MCP/agent execution, except that interfaces can wrap an `AutonomousAgent`.
- `src/upsonic/canvas/`, `simulation/`, `graph/graphv2/`, and unrelated utility modules: adjacent features outside the assigned focus.
- `src/upsonic/tools/custom_tools/` and most `common_tools/`: provider/tool integrations are numerous; the review focused on the shared tool wrapper/registry/MCP execution path they plug into.
- `src/upsonic/prebuilt/` templates and generated autonomous-agent templates: sampled at the framework boundary only; detailed domain templates were excluded as application content.
- Binary/media assets and UI-only artifacts: no relevant runtime path depended on them for MCP, orchestration, context control, verification, security, or coding-agent applicability.
- Tests requiring live LLM providers, external MCP servers, credentials, or third-party services were read statically rather than executed; they validate integration shape but are not reliable offline verification for this review.
