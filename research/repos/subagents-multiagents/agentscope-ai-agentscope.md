# agentscope-ai/agentscope

- URL: https://github.com/agentscope-ai/agentscope
- Category: subagents-multiagents
- Stars snapshot: 25,842 (GitHub REST API, captured 2026-05-29)
- Reviewed commit: b9e363416acfb6af896f2e42c50dcd4782f9d2b8
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: conditional
- Verdict: Useful as a reference for evented ReAct execution, visible tool lifecycle, MCP/tool/workspace boundaries, human approval, external execution, context compression/offload, tracing, and service-session persistence. It is a weaker direct reference for subagent orchestration because the reviewed 2.0 tree does not implement first-class handoffs, agent-as-tool delegation, worker graphs, or a message-hub runtime despite advertising multi-agent support.

## Why It Matters

AgentScope is a popular Python agent framework from the Alibaba Tongyi Lab ecosystem, positioned as a production-ready agent framework with tools, MCP, skills, human-in-the-loop steering, memory/context management, planning, realtime work, service deployment, and visible execution. For Agentic Coding Lab, the interesting part is not a high-level multi-agent society runtime. The current implementation is more useful as a concrete example of a single-agent execution kernel that can be embedded in an application service, attached to workspace backends, and made observable through typed events.

The repo matters for the `subagents-multiagents` index because it shows the lower-level substrate a subagent system would need: message identities, per-session state, explicit tool call states, approval events, external execution events, task-tracking tools, prompt formatters for multi-speaker history, MCP tool import, permission rules, background tool continuation, and workspace-level offload. The caveat is important: current multi-agent support is mainly formatting multiple named speakers into provider prompts and not a runtime that routes ownership between agents.

## What It Is

AgentScope 2.0 packages the `agentscope` Python library and an optional FastAPI app. The library centers on `Agent`, `AgentState`, `Msg`/content blocks, `Toolkit`, `ToolBase`, `MCPClient`, `PermissionEngine`, `WorkspaceBase`, provider models, formatters, and middleware. The app layer adds Redis-backed agent/session/message/schedule storage, per-session run serialization, background task management, workspace managers, SSE chat streaming, and a web UI example.

The main agent is a ReAct-style loop. It builds model input from system prompt, skill instructions, compressed summary, stored context, and available tool schemas. It streams model and tool events, validates and executes tool calls, can pause for user confirmation or external execution, saves results into the conversation state, and repeats until it has a final assistant response or reaches `max_iters`.

## Research Themes

- Token efficiency: Provides approximate token counting, trigger/reserve ratios for context compression, a structured compression summary, tool result token limits, file offload for compressed context and oversized tool results, skill/tool group activation to reduce visible schemas, and provider formatters that can collapse multi-agent history into a `<history>` block. Token accounting is byte/4 by default, not tokenizer-exact unless provider subclasses override it.
- Context control: Separates `AgentState.context`, compressed `summary`, tool read cache, task context, permission context, and workspace offload. Context compression preserves recent messages and tries not to split tool call/result pairs. Tool result overflow can be truncated with a reminder and optionally offloaded to workspace files.
- Sub-agent / multi-agent: Conditional fit. Multi-agent formatters preserve speaker names by wrapping named message history in `<history>` tags, and task tools can track owners/dependencies. The reviewed code does not provide first-class handoff, agent-as-tool, swarm, planner/worker graph, or message-hub orchestration primitives.
- Domain-specific workflow: Strong service substrate: agents, sessions, credentials, workspace managers, scheduled tasks, background tool tasks, and task-list tools. The built-in coding-like tools (`Read`, `Write`, `Edit`, `Grep`, `Glob`, `Bash`) encode several coding-agent workflow norms such as read-before-edit and explicit command descriptions.
- Error prevention: Uses JSON schema validation for tool inputs, permission modes/rules, dangerous path and command checks, read-before-write/edit file cache, max ReAct iterations, user confirmation events, `DONT_ASK` mode for unattended schedules, tool result states, and tests around permission priority and shell parsing.
- Self-learning / memory: Current code has session state, context compression, task context, file caches, skills loaded from workspace directories, and offloaded context/tool results. It does not implement autonomous long-term learning or a general memory retrieval module in the reviewed tree, even though README/changelog language refers to memory.
- Popular skills: Good patterns to borrow are evented execution, resumable approvals, tool-state transitions, workspace-scoped tools/MCPs/skills, permission-rule suggestions, background tool result reinjection, and provider-specific multi-speaker formatting.

## Core Execution Path

1. A caller invokes `Agent.reply_stream()` or `Agent.reply()` with a new `Msg`, a list of messages, a `UserConfirmResultEvent`, an `ExternalExecutionResultEvent`, or `None`.
2. `_reply_impl()` validates whether the agent is starting a new reply or resuming an awaiting tool call. New inputs are appended to `AgentState.context`; resumptions update tool-call state or append external results.
3. The agent emits `ReplyStartEvent`, enters the ReAct loop, and calls `compress_context()` before model reasoning if estimated tokens exceed `ContextConfig.trigger_ratio * model.context_size`.
4. `_prepare_model_input()` constructs messages from system prompt, skill instructions, summary, conversation context, and currently activated tool schemas from `Toolkit`.
5. `_call_model()` invokes the active `ChatModelBase` through model-call middleware, local retry configuration, and optional fallback model.
6. Model chunks are converted into typed events for text, thinking, data, and tool calls. Completed responses are saved into `AgentState.context`.
7. If tool calls exist, `_batch_tool_calls()` groups them as concurrent or sequential according to each tool's `is_concurrency_safe` flag.
8. `_execute_tool_call()` checks tool availability, repairs/parses JSON, validates against JSON Schema, asks `PermissionEngine`, and then either emits `RequireUserConfirmEvent`, returns a denied/error tool result, emits `RequireExternalExecutionEvent`, or executes the local tool through `_acting()`.
9. Tool execution streams `ToolChunk` values and a final `ToolResponse`. Oversized tool output is truncated and optionally offloaded via the active workspace before being saved as a `ToolResultBlock`.
10. The loop continues until no tool calls remain and a final assistant message is produced, or until `max_iters` emits `ExceedMaxItersEvent`.

In the app path, `ChatService.stream_chat()` assembles the agent from storage and workspace state, attaches `ToolOffloadMiddleware`, serializes concurrent runs with `SessionManager.run(session_id)`, publishes SSE events, reconstructs/persists the assistant message, and writes updated `AgentState` back to storage.

## Architecture

The core runtime lives in `src/agentscope/agent/_agent.py`. It owns the reply loop, model input assembly, context compression, tool batching, permission checks, approval/external-execution pause/resume, event conversion, and context writes. `src/agentscope/message` and `src/agentscope/event` define the typed blocks and event stream used by both the library and app service.

Tools are under `src/agentscope/tool`. `ToolBase` defines capability flags and permission hooks. `Toolkit` collects Python tools, MCP tools, skills, and tool groups. Built-ins cover bash, read/write/edit, glob/grep, skill viewing, reset-tools, and task-list management. `src/agentscope/mcp` wraps stdio/SSE/streamable HTTP MCP servers as `MCPTool` instances with stateful or stateless connection modes.

Context and state are split across `src/agentscope/state`, `src/agentscope/agent/_config.py`, workspaces, and storage. `AgentState` holds session id, summary, context, reply id, ReAct iteration, permission context, tool context, and task context. `LocalWorkspace`, `DockerWorkspace`, and `E2BWorkspace` provide tool lists, MCP lists, skill lists, offload files, and sandbox/gateway integration.

The application layer under `src/agentscope/app` turns the library into a multi-tenant service: FastAPI routers, Redis storage, agent/session/schedule schemas, per-session locks, background task management, scheduler tools, workspace managers, and protocol middleware. Observability is implemented as middleware under `src/agentscope/middleware/_tracing`.

## Design Choices

- The core abstraction is one ReAct agent, not an orchestrator. Multiple agents can be represented as named messages, but ownership transfer and worker routing are left to application code.
- Execution is event-first. Text, thinking, tool calls, tool results, approval waits, external-execution waits, and max-iteration exits are all typed events.
- Tool calls are durable enough to pause. `ToolCallBlock.state` moves through `pending`, `asking`, `allowed`, `submitted`, and `finished`.
- Permission policy is tool-specific plus rule-based. The engine evaluates deny, ask, tool safety checks, allow, bypass, and default behavior in that order.
- Tool execution and context mutation are deliberately separated. Middleware `on_acting` wraps only raw tool I/O, while permission checks and context writes remain outside that hook.
- Tool groups let agents self-manage the visible tool surface via `reset_tools`; skills are prompt resources read through a `Skill` viewer tool rather than callable functions.
- Workspace backends are the unit of execution environment. Local workspaces expose local tools directly; Docker/E2B workspaces proxy tools and MCPs through an in-workspace gateway.
- Scheduled tasks default toward unattended safety through `PermissionMode.DONT_ASK`, converting permission prompts into denials.

## Strengths

- The event model is high-signal for building auditable agents. It separates reply, model call, text/thinking blocks, tool calls, tool result chunks, approvals, external execution, and max-iteration failure.
- HITL and external execution are not ad hoc strings; they are resumable event types tied to tool-call state.
- Tool boundaries are explicit. Tools declare read-only/concurrency/external/state-injected/MCP flags, schemas, permission checks, rule matching, and suggestions.
- Permission handling is practical for coding agents: read-only explore mode, accept-edits mode, deny/ask/allow priority, dangerous files/directories, command injection checks, and read-before-write/edit cache.
- Workspace abstraction is strong. Local, Docker, and E2B backends share a contract for tools, MCPs, skills, offloaded context, and lifecycle.
- App service design cleanly separates storage, session run serialization, workspace assembly, event streaming, and state persistence.
- Tests cover many important runtime surfaces: agent loop, HITL, external execution, tool batching, permissions, MCP clients, formatter behavior, tracing, local workspace offload, background task offload, and built-in tools.

## Weaknesses

- Multi-agent orchestration is thin in the reviewed commit. The repo advertises message hub, A2A, and multi-agent workflows, but the code path reviewed mostly supports named-message formatting, not handoff, delegation, agent-as-tool, or worker graph execution.
- Current memory is session/context management rather than durable semantic memory. Changelog language mentions long-term memory, but no `src/agentscope/memory` implementation exists in this checkout.
- Default token counting is approximate and can mis-estimate multimodal/tool-heavy contexts.
- Background offload intentionally lets long-running tool tasks keep running and later injects a `HintBlock`. That is useful, but it turns completion into a model-visible notification rather than a deterministic workflow state transition.
- Permission safety is good but not a full sandbox policy. Local `Bash` uses `asyncio.create_subprocess_shell`; host-level filesystem, network, and process isolation depend on workspace choice and deployment configuration.
- Tool-group and skill activation are model-mediated. They reduce context and capability sprawl, but a coding harness would still need deterministic capability grants for high-risk operations.
- Tracing is useful but not comprehensive. For example, tool descriptions are attempted through a `Toolkit` attribute shape that does not appear to exist in the reviewed `Toolkit`, so some tool metadata may be absent from spans.

## Ideas To Steal

- Model agent execution as a typed event stream that can reconstruct messages, power UI, feed tracing, and support persistence.
- Give tool calls explicit states and resume events instead of encoding approval waits in natural language.
- Keep permission policy layered: hard deny, explicit ask, tool-level safety, explicit allow, mode-level bypass, default ask/deny.
- Separate raw tool I/O middleware from context mutation so background/offload middleware cannot accidentally mutate agent state.
- Use workspace backends as a capability boundary: local tools for trusted environments, Docker/E2B/gateway-backed tools for sandboxed execution.
- Add a `DONT_ASK` mode for scheduled/background agents so unattended runs fail closed instead of waiting forever for approvals.
- Let tool results be chunked, stateful, multimodal, and offloadable; put only a bounded reminder into context when output is too large.
- Treat tool groups and skills as context-budget controls, but couple them with deterministic host policy for sensitive actions.

## Do Not Copy

- Do not treat named-message multi-agent formatting as sufficient subagent orchestration. A coding lab needs explicit worker ownership, handoff state, task assignment, and result contracts.
- Do not rely on model-mediated `reset_tools` alone for security-sensitive capability management.
- Do not use approximate token counting as the only guard for long coding sessions with large tool outputs or multimodal data.
- Do not run host shell tools outside a sandbox unless the surrounding system provides filesystem, process, network, and destructive-command policy.
- Do not let background task result injection substitute for a deterministic workflow event log when task completion must trigger exact follow-up behavior.
- Do not assume README/changelog feature claims match the current source tree; memory/evaluation/message-hub claims need code-path confirmation.

## Fit For Agentic Coding Lab

This is a conditional candidate for Agentic Coding Lab. It should not be copied as a direct subagent/multi-worker architecture, because the reviewed runtime does not implement first-class handoffs or worker graphs. It is valuable as a substrate pattern for a safer coding-agent runtime: evented execution, tool-state machines, approval pauses, external execution continuation, permissions, workspace boundaries, offload, session persistence, and OpenTelemetry spans.

The best adaptation would be to combine AgentScope-style event/tool/session mechanics with a separate coding-specific orchestrator. That orchestrator should define task ownership, subagent scopes, handoff payload schemas, owned paths, allowed commands, test gates, and result verification. AgentScope's current pieces are strong lower-level primitives, not the whole multi-agent policy layer.

## Reviewed Paths

- `README.md`
- `pyproject.toml`
- `docs/NEWS.md`
- `docs/changelog.md`
- `docs/roadmap.md`
- `scripts/model_examples/README.md`
- `scripts/model_examples/openai_chat_multiagent.py`
- `scripts/model_examples/ollama_multiagent.py`
- `src/agentscope/agent/_agent.py`
- `src/agentscope/agent/_config.py`
- `src/agentscope/agent/_utils.py`
- `src/agentscope/message/_base.py`
- `src/agentscope/message/_block.py`
- `src/agentscope/event/_event.py`
- `src/agentscope/model/_base.py`
- `src/agentscope/formatter/_formatter_base.py`
- `src/agentscope/formatter/_openai_formatter.py`
- `src/agentscope/formatter/_openai_response_formatter.py`
- `src/agentscope/formatter/_anthropic_formatter.py`
- `src/agentscope/tool/_base.py`
- `src/agentscope/tool/_toolkit.py`
- `src/agentscope/tool/_tool_group.py`
- `src/agentscope/tool/_types.py`
- `src/agentscope/tool/_adapters.py`
- `src/agentscope/tool/_response.py`
- `src/agentscope/tool/_builtin/_bash.py`
- `src/agentscope/tool/_builtin/_read.py`
- `src/agentscope/tool/_builtin/_write.py`
- `src/agentscope/tool/_builtin/_edit.py`
- `src/agentscope/tool/_builtin/_skill.py`
- `src/agentscope/tool/_builtin/_meta.py`
- `src/agentscope/tool/_task/*`
- `src/agentscope/mcp/_config.py`
- `src/agentscope/mcp/_mcp_client.py`
- `src/agentscope/permission/*`
- `src/agentscope/state/_state.py`
- `src/agentscope/state/_task.py`
- `src/agentscope/skill/*`
- `src/agentscope/workspace/_base.py`
- `src/agentscope/workspace/_local_workspace.py`
- `src/agentscope/workspace/_docker/_docker_workspace.py`
- `src/agentscope/workspace/_e2b/_e2b_workspace.py`
- `src/agentscope/app/_service/_agent.py`
- `src/agentscope/app/_service/_chat.py`
- `src/agentscope/app/_manager/_session_manager.py`
- `src/agentscope/app/_manager/_background_task_manager.py`
- `src/agentscope/app/_manager/_workspace_manager.py`
- `src/agentscope/app/_manager/_scheduler/_scheduler_manager.py`
- `src/agentscope/app/_middleware/_tool_offload_middleware.py`
- `src/agentscope/app/_middleware/_protocol/*`
- `src/agentscope/app/_router/_chat.py`
- `src/agentscope/app/_schema/_agent.py`
- `src/agentscope/app/_schema/_chat.py`
- `src/agentscope/app/_schema/_session.py`
- `src/agentscope/app/storage/_base.py`
- `src/agentscope/app/storage/_redis_storage.py`
- `src/agentscope/middleware/_base.py`
- `src/agentscope/middleware/_tracing/*`
- `examples/agent_service/main.py`
- `tests/agent_basic_test.py`
- `tests/hitl_user_confirmation_test.py`
- `tests/hitl_external_execution_test.py`
- `tests/permission_engine_test.py`
- `tests/permission_bash_parser_test.py`
- `tests/toolkit_test.py`
- `tests/toolkit_task_test.py`
- `tests/toolkit_skill_test.py`
- `tests/task_tool_test.py`
- `tests/mcp_sse_client_test.py`
- `tests/mcp_streamable_http_client_test.py`
- `tests/tracing_test.py`
- `tests/tool_offload_middleware_test.py`
- `tests/workspace_local_test.py`
- `tests/workspace_docker_test.py`
- `tests/workspace_e2b_test.py`
- `tests/formatter_*_test.py`

## Excluded Paths

- Frontend UI implementation under `examples/web_ui/frontend/**`, except for confirming that the app exposes chat/tool/permission views; runtime behavior was reviewed in Python service and library code.
- Static image assets, logos, screenshots, QR codes, and media files.
- Provider model implementation details beyond `ChatModelBase` and formatter boundaries; the review focused on orchestration, tools, state, permissions, and observability.
- Dockerfile template internals and E2B bootstrap minutiae beyond confirming workspace lifecycle, sandbox/gateway model, and offload behavior.
- Individual provider example scripts beyond representative multi-agent examples and the model example README.
- Packaging, contribution docs, generated metadata, and lockfiles that do not affect agent execution behavior.
