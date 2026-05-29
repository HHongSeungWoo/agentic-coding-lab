# google/adk-python

- URL: https://github.com/google/adk-python
- Category: subagents-multiagents
- Stars snapshot: 19,907 (GitHub REST API repository search, captured 2026-05-29)
- Reviewed commit: aa515125879725b53a2c003c89783dfdb0dd2654
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: conditional
- Verdict: High-signal reference for code-first multi-agent composition, resumable workflow execution, task-scoped delegation, MCP/tool/session boundaries, eval harnesses, and deploy surfaces. It is a broad general agent framework with Google-cloud-oriented integrations and some explicitly unsafe execution modes, so borrow runtime patterns selectively rather than adopting its full surface.

## Why It Matters

ADK 2.0 is one of the richer code-first Python agent frameworks for studying multi-agent runtime design. It combines a tree of `LlmAgent` sub-agents with a newer graph-based `Workflow` runtime, so it exposes both model-directed delegation and deterministic orchestration primitives. That makes it useful for comparing handoffs, task agents, single-turn agents, explicit fan-out/fan-in, loops, retry, human input gates, and resumable session state in one codebase.

For Agentic Coding Lab, the best material is not the default chat experience. The useful substrate is the shared event/context/session model: agents and workflow nodes both run through `Context`, `Event`, services, tool boundaries, and a `Runner`. This gives concrete patterns for isolating delegated task histories, routing outputs through typed events, preserving enough state to resume paused work, and separating tool/MCP credentials from model-visible context.

## What It Is

`google-adk` is a Python package for building, evaluating, and deploying agents. Public code can define `Agent`, `Workflow`, `Runner`, tools, services, and apps directly in Python, then run them locally through `adk run`, inspect them with `adk web`, expose them through FastAPI endpoints, evaluate them with eval sets, or deploy them to Cloud Run and Agent Engine.

The framework has two multi-agent layers. The legacy agent tree supports chat-style transfers to sub-agents and parent/peer agents. The newer 2.0 layer treats agents, functions, tools, joins, and parallel workers as graph nodes in a `Workflow`, with dynamic child node execution through `ctx.run_node`. Task and single-turn sub-agents bridge the two layers by exposing specialized agents as tool-like delegated work while preserving ADK's session and event model.

## Research Themes

- Token efficiency: Static instructions, context-cache configuration, event compaction, `include_contents="none"`, session history limits, branch/isolation filtering, and generated function-call ID stripping all reduce prompt load. The system offers mechanisms rather than a coding-specific budget planner; callers still need policies for which files, tool outputs, artifacts, and prior turns enter context.
- Context control: The core controls are `branch`, `isolation_scope`, `EventActions`, state prefixes, and session event filtering. Parallel branches can keep separate histories, task agents can run under a function-call-derived isolation scope, and other-agent messages are rewritten as contextual user messages. Local services for artifacts, credentials, sessions, and memory stay behind `Context` instead of being automatically prompt-visible.
- Sub-agent / multi-agent: ADK supports chat transfers through a constrained `transfer_to_agent` tool, task and single-turn sub-agent wrappers, agent-as-tool execution, deprecated sequential/parallel/loop agents, explicit graph workflows, dynamic `ctx.run_node` calls, `JoinNode`, and `ParallelWorker`. The task/single-turn wrappers are the most relevant because they make delegation a scoped, resumable runtime action instead of only a prompt convention.
- Domain-specific workflow: `Workflow` edges, routes, conditions, default routes, joins, loops, retries, timeouts, function nodes, tool nodes, request-input gates, dynamic fan-out/fan-in, and nested workflows provide reusable workflow primitives. Samples cover multi-agent trees, task sub-agents, workflow loops, request input, fan-out/fan-in, long-running tools, and MCP transports.
- Error prevention: The runtime validates agent names, graph structure, node schemas, function arguments, state schemas, max LLM calls, retry/timeout configs, tool confirmations, credential requests, API origins, uploaded builder paths, and YAML loader restrictions. Limits remain: arbitrary Python tools, stdio MCP commands, local code execution, and remote A2A agents are trusted integration boundaries unless the application adds host policy.
- Self-learning / memory: Memory is service-based. Agents and tools can add/search memory, and optional services include in-memory and Google-backed memory/RAG implementations. This is retrieval and session persistence, not an autonomous self-improvement loop or durable skill learner.
- Popular skills: Code-first agent definitions, Python function tools, MCP stdio/SSE/streamable HTTP toolsets, multi-agent task delegation, graph workflows, eval cases with tool trajectory and rubric metrics, FastAPI serving, Cloud Run/Agent Engine deployment, and experimental A2A bridging are the patterns most likely to appear in downstream agent stacks.

## Core Execution Path

1. A caller invokes `Runner.run_async`, `Runner.run_live`, an API endpoint, or an eval harness with app/user/session IDs, a new message, and optional `RunConfig`.
2. The runner creates or loads a session, appends the user event, builds an `InvocationContext`, installs services and plugin managers, and routes execution to the root `App`, `Agent`, or `Workflow`.
3. For `LlmAgent`, the LLM flow assembles instructions, current contents, tool declarations, auth/confirmation preprocessors, planning/code-execution processors, output schema config, and model settings, then calls the model until final response, tool work, transfer, task dispatch, or pause.
4. Function calls are executed through `BaseTool`/`FunctionTool`/`BaseToolset` adapters, often in parallel. Tool responses, auth requests, confirmation requests, long-running pauses, state deltas, artifacts, and errors are emitted as `Event` objects.
5. For `Workflow`, the compiled graph and `NodeRunner` schedule triggered nodes, validate input/output schemas, apply retries/timeouts, emit node events, propagate routes, and coordinate joins, loops, parallel workers, and dynamic child runs.
6. For task and single-turn sub-agents, the coordinator handles model-emitted function calls by running child agents through `ctx.run_node` under a deterministic run ID and isolation scope, then synthesizes function responses back into the parent conversation.
7. Non-partial events are appended to the session service, state/artifact deltas are applied, event compaction may run, and final output is returned or streamed to the caller.

## Architecture

The architecture is layered around a shared runtime.

`src/google/adk/agents/*` defines `BaseAgent`, `LlmAgent`, invocation context, run config, context helpers, legacy sequential/parallel/loop agents, A2A remote agents, and callback surfaces. `src/google/adk/workflow/*` defines the 2.0 graph workflow runtime, including nodes, edges, graph validation, node scheduling, dynamic node runs, joins, parallel workers, retries, and wrappers that let `LlmAgent` participate as workflow nodes.

`src/google/adk/runners.py`, `src/google/adk/apps/app.py`, `src/google/adk/events/*`, and `src/google/adk/sessions/*` form the execution and persistence spine. Events carry content plus `EventActions` such as state deltas, artifact deltas, transfers, route decisions, requested auth, requested confirmations, rewind metadata, task agent state, and UI widgets. Sessions are append-only histories with mutable state derived from those events.

Tools live under `src/google/adk/tools/*`. Local function tools, toolsets, agent tools, transfer tools, MCP tools, Google service tools, long-running tools, and tool contexts share a common interface. Tool contexts are full `Context` objects, which gives tools access to state, artifacts, auth, memory, and dynamic node execution.

Evaluation, serving, deployment, and interop are separate surfaces: `src/google/adk/evaluation/*` and `src/google/adk/cli/cli_eval.py` handle eval cases and metrics; `src/google/adk/cli/api_server.py` and `fast_api.py` expose HTTP/SSE/live endpoints; `cli_deploy.py` targets Cloud Run and Agent Engine; `src/google/adk/a2a/*` and `RemoteA2aAgent` provide experimental A2A server/client bridges.

## Design Choices

- ADK is code-first. Agents, workflows, nodes, tools, schemas, and services are Python objects; YAML/config loading exists but is no longer the center of the design.
- Agents and workflows share `BaseNode`, `Context`, `Event`, and service boundaries. This makes graph nodes, LLM agents, functions, tools, and dynamic child calls interoperable.
- `branch` and `isolation_scope` are separate concepts. Branches isolate parallel or sub-branch histories; isolation scopes isolate delegated task histories and help task agents resume under the right function-call ID.
- Delegation has multiple semantics. Chat transfer changes active agent ownership, single-turn sub-agents act like scoped one-shot tools, task sub-agents can pause/resume until `finish_task`, and `AgentTool` runs a nested agent as a normal tool with a fresh in-memory session.
- Workflow graph validation rejects unsafe or ambiguous static structures, including unconditional cycles and static `mode="task"` LLM agents whose resume semantics are not compatible with graph nodes.
- Tool execution is model-facing but runtime-mediated. Auth requests, confirmations, missing mandatory arguments, long-running pauses, and tool exceptions become structured events or function responses rather than raw side effects hidden inside the model loop.
- MCP sessions are pooled and managed explicitly, with separate handling for stdio, SSE, and streamable HTTP. A dedicated session context avoids AnyIO task-group/cancel-scope lifecycle problems.
- Deployment and API serving are first-class but not policy-complete. The built-in API server checks origins for browser calls and validates builder uploads, while authentication, authorization, network policy, and production tenancy are expected at deployment boundaries.

## Strengths

- Strong composition vocabulary: chat transfer, task agent, single-turn agent, agent-as-tool, workflow node, dynamic node, join, parallel worker, branch, and isolation scope are distinct primitives rather than one generic "subagent" concept.
- The event/session model is a useful source of truth. State, artifacts, routes, rewinds, confirmations, auth requests, tool calls, agent state, and final output all move through typed event actions.
- Workflow 2.0 is substantial: graph validation, fan-out/fan-in, conditional routing, loops, retries, timeouts, HITL request input, nested workflows, dynamic node scheduling, and resumable child node state are all represented in runtime code.
- Tool and MCP boundaries are mature. Function tools infer schemas, toolsets can filter/prefix/cache tools, MCP supports multiple transports plus resources/sampling/progress, and credential/auth flows are modeled in `Context`.
- Context isolation is more concrete than prompt-only coordination. Branch and isolation filtering determine which events become model contents, and task agents do not automatically inherit the full coordinator transcript.
- Eval and deploy surfaces are broad enough for operational research: tool trajectory, response match, rubric, safety, final-response, user-simulator, and multi-turn metrics sit beside FastAPI, SSE/live streaming, Cloud Run, Agent Engine, and A2A bridges.
- Security affordances exist where the framework owns the boundary: origin checks, upload path checks, YAML argument blocking, max LLM calls, confirmation requests, GKE gVisor code execution, non-root Cloud Run image setup, and structured error events.

## Weaknesses

- The framework is large and product-shaped. Copying the full API would add agents, workflows, services, eval, deploy, A2A, MCP, live streaming, plugins, and Google integrations when an agentic coding lab likely needs a narrower harness.
- Some important safety boundaries are deliberately outside the framework. Python tools execute application code, stdio MCP launches configured commands, remote A2A trusts agent cards/endpoints, and API auth is not built into the local FastAPI server.
- Code execution has mixed security posture. `UnsafeLocalCodeExecutor` is explicitly unsafe, `ContainerCodeExecutor` relies on caller-provided Docker isolation, and only the GKE executor has strong visible sandbox controls.
- Task-agent semantics are powerful but subtle. The coordinator must synthesize function responses, track run IDs, manage isolation scopes, and loop until `finish_task`; static task agents are disallowed in workflow graphs because resume context is still hard.
- Tool execution is parallel by default for multiple function calls, which is efficient but dangerous for side-effecting coding tools unless the application imposes ordering, approval, and idempotency rules.
- Context control is event-filter based, not a full confidentiality model. If a tool, callback, plugin, remote agent, or service receives `Context`, it can access far more than what the LLM sees.
- A2A support is explicitly experimental, with legacy/new paths, extension negotiation, and live mode not implemented for `RemoteA2aAgent`.

## Ideas To Steal

- Model subagent delegation with multiple explicit semantics: transfer ownership, one-shot scoped call, resumable task, and nested agent-as-tool. Do not collapse them into a single "spawn agent" operation.
- Use event actions as the durable audit boundary for state deltas, artifacts, routes, approvals, auth requests, agent state, and rewinds.
- Preserve both branch and task isolation metadata in every event so context reconstruction can be deterministic after parallel work or human input pauses.
- Let a workflow scheduler own dynamic child runs and rehydrate them from session history, instead of treating dynamic subagent calls as untracked async tasks.
- Reject graph shapes that the runtime cannot resume safely. The static task-agent rejection is a good example of failing early when semantics are unclear.
- Make tool confirmation, auth requests, and long-running waits first-class pauses that can resume through normal user/session events.
- Add eval records that capture intermediate tool uses, tool responses, sub-agent responses, final session state, and per-turn metrics instead of scoring only the final text.
- Provide serving/deploy wrappers, but keep the core runner independent from the web framework so local CLI, tests, API, and deployment all exercise the same execution path.

## Do Not Copy

- Do not import the whole broad SDK shape into a coding-specific research harness. A smaller runner with explicit coding policies would be easier to verify.
- Do not allow side-effecting tools to run concurrently just because the model emitted multiple function calls. Coding tools need host-enforced ordering, approvals, and rollback/verification policy.
- Do not treat `Context` access as safe merely because prompt context is filtered. Tool, plugin, callback, MCP, and A2A boundaries need their own authority model.
- Do not expose local stdio MCP commands, unsafe local code execution, or Docker execution without explicit allowlists, filesystem scopes, network policy, and user-visible approval.
- Do not rely on origin checks as authentication. Browser CSRF defenses help, but multi-user or remote deployments need service-level authz and tenant-aware session services.
- Do not copy experimental A2A behavior as a stable contract until the legacy/new implementation split, cancellation, auth, and live-mode limitations are resolved.

## Fit For Agentic Coding Lab

This repo is a strong conditional fit for `subagents-multiagents`. It is not a coding-agent lab by itself, but it contains unusually concrete runtime machinery for the hardest parts of coding-agent orchestration: scoped subagents, deterministic workflow graphs, resumable child runs, event-sourced context reconstruction, tool/MCP boundaries, eval traces, and deploy APIs.

The most useful adaptation would be a smaller ADK-inspired runtime: typed events, branch and isolation metadata, explicit delegation modes, graph validation, dynamic child scheduling, confirmation/auth pauses, state/artifact services, and eval records that include intermediate tool/subagent activity. The missing layer is coding-specific policy: owned paths, command allowlists, destructive-action approvals, patch discipline, test evidence, code review, and final verification gates.

## Reviewed Paths

- `README.md`
- `pyproject.toml`
- `src/google/adk/__init__.py`
- `src/google/adk/agents/base_agent.py`
- `src/google/adk/agents/llm_agent.py`
- `src/google/adk/agents/sequential_agent.py`
- `src/google/adk/agents/parallel_agent.py`
- `src/google/adk/agents/loop_agent.py`
- `src/google/adk/agents/invocation_context.py`
- `src/google/adk/agents/context.py`
- `src/google/adk/agents/run_config.py`
- `src/google/adk/agents/remote_a2a_agent.py`
- `src/google/adk/workflow/_workflow.py`
- `src/google/adk/workflow/_graph.py`
- `src/google/adk/workflow/_node_runner.py`
- `src/google/adk/workflow/_base_node.py`
- `src/google/adk/workflow/_function_node.py`
- `src/google/adk/workflow/_tool_node.py`
- `src/google/adk/workflow/_dynamic_node_scheduler.py`
- `src/google/adk/workflow/_join_node.py`
- `src/google/adk/workflow/_parallel_worker.py`
- `src/google/adk/workflow/_llm_agent_wrapper.py`
- `src/google/adk/runners.py`
- `src/google/adk/apps/app.py`
- `src/google/adk/events/event.py`
- `src/google/adk/events/event_actions.py`
- `src/google/adk/flows/llm_flows/base_llm_flow.py`
- `src/google/adk/flows/llm_flows/single_flow.py`
- `src/google/adk/flows/llm_flows/auto_flow.py`
- `src/google/adk/flows/llm_flows/agent_transfer.py`
- `src/google/adk/flows/llm_flows/functions.py`
- `src/google/adk/flows/llm_flows/contents.py`
- `src/google/adk/flows/llm_flows/instructions.py`
- `src/google/adk/tools/base_tool.py`
- `src/google/adk/tools/base_toolset.py`
- `src/google/adk/tools/function_tool.py`
- `src/google/adk/tools/tool_context.py`
- `src/google/adk/tools/transfer_to_agent_tool.py`
- `src/google/adk/tools/agent_tool.py`
- `src/google/adk/tools/mcp_tool/*`
- `src/google/adk/code_executors/*`
- `src/google/adk/evaluation/agent_evaluator.py`
- `src/google/adk/evaluation/eval_case.py`
- `src/google/adk/evaluation/eval_metrics.py`
- `src/google/adk/cli/cli_eval.py`
- `src/google/adk/cli/utils/evals.py`
- `src/google/adk/cli/api_server.py`
- `src/google/adk/cli/fast_api.py`
- `src/google/adk/cli/cli_deploy.py`
- `src/google/adk/a2a/*`
- `contributing/samples/multi_agent/*`
- `contributing/samples/workflows/*`
- `contributing/samples/tools/*`
- `contributing/samples/mcp/*`
- `tests/unittests/**` sampled for runtime, workflow, tool, MCP, evaluation, and API behavior

## Excluded Paths

- Generated or static assets under `assets/**` and documentation/media files not needed for runtime analysis.
- Release, packaging, lint, formatting, and CI plumbing except `pyproject.toml` dependency and extra definitions.
- External website documentation beyond the in-repo README and available design/API-server docs.
- Exhaustive provider-specific integrations under Google service tools, database/session backends, telemetry exporters, auth schemes, and examples that did not change the core agent, workflow, tool, MCP, eval, deploy, or security-boundary conclusions.
- Full test-suite enumeration; representative unit tests and sample directories were used to validate runtime behavior and advertised patterns.
