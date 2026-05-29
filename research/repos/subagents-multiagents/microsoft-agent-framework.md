# microsoft/agent-framework

- URL: https://github.com/microsoft/agent-framework
- Category: subagents-multiagents
- Stars snapshot: 10,849 (GitHub REST API repository metadata, captured 2026-05-29)
- Reviewed commit: dd9a4b6321f8922cb4505f84ed5c3e206dfbddb7
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: Conditional
- Verdict: Strong reference for typed multi-agent orchestration, handoff, checkpointing, hosting, and eval surfaces; useful as architecture to borrow from, but not a drop-in coding-agent substrate.

## Why It Matters

Microsoft Agent Framework is one of the more complete open multi-agent SDK candidates because it treats agent coordination as a typed workflow problem instead of only a prompt-routing problem. The repository has parallel Python and .NET surfaces, graph-based workflows, specialized orchestration builders, HITL/request-response events, checkpointing, deployment adapters, eval adapters, and several explicit security experiments.

For the Agentic Coding Lab index, the repo matters less as a ready-made coding assistant and more as a production-scale reference for boundaries: how agents become tools, how sessions and service-side conversation IDs are separated, how workflow state is checkpointed, how handoffs preserve or filter history, how human approvals interrupt execution, and where host policy has to own safety.

## What It Is

Agent Framework is a Python and .NET SDK for building agents, wrapping chat clients, registering tools and MCP servers, composing agents into workflows, and hosting the resulting systems on local, Foundry, Azure Functions, Durable Task, DevUI, A2A, and AG-UI surfaces. The Python side splits into core agent/workflow primitives plus preview packages for orchestrations, tools, hosting, DevUI, Hyperlight CodeAct, and provider connectors. The .NET side has comparable workflow, specialized orchestration, declarative workflow, and durable-agent packages.

The core abstraction is a runnable agent or workflow. Agents own model clients, instructions, tools, context providers, middleware, sessions, and optional compaction. Workflows own executors, typed edges, graph signatures, runner state, pending external requests, and checkpoints. Higher-level builders create common multi-agent shapes such as sequential pipelines, concurrent fan-out/fan-in, decentralized handoff, group chat, and Magentic-style manager/worker loops.

## Research Themes

### Token efficiency

The Python core includes an explicit compaction strategy protocol and group-aware message annotation. Tool calls, tool results, and reasoning blocks are treated as atomic groups so truncation does not split model-visible tool state. This is a practical design to copy for coding agents because coding transcripts often contain fragile command/result pairs. The current repository is more about safe message shaping than aggressive token-budget optimization; it does not provide a full coding-task summarizer or repository-state compressor.

### Context control

Context is a first-class pipeline. `ContextProvider` can add messages, instructions, tools, and middleware before a run and process response/state afterward. `HistoryProvider` handles load/store of input, context, and output messages, and `SessionContext` tracks provider-attributed context so callers can filter by source. Agents distinguish local `session_id` from provider/service `service_session_id`, and hosted-session identity context is documented to prevent resuming a hosted session under the wrong user or chat scope.

The useful pattern is explicit attribution and session scoping. A coding-agent lab should steal that model for file context, memory, tool output, subagent summaries, and user-provided constraints, rather than appending everything into one undifferentiated conversation.

### Sub-agent / multi-agent

Multi-agent support is concrete. Python agents can be exposed as `FunctionTool`s with optional session propagation. Workflow builders compose agents as executors. The orchestration package provides sequential, concurrent, handoff, group chat, and Magentic builders. The .NET side has comparable specialized workflow builders and executor hosts.

Handoff is the strongest subagent pattern. It injects synthetic `handoff_to_<target>` tools, intercepts those tool calls in middleware, filters internal handoff artifacts out of conversation history, persists per-agent sessions, and validates history-persistence constraints. Group chat and Magentic provide manager-driven speaker selection, termination, planning, progress ledgers, plan review, resets, and re-planning. These are relevant patterns for reviewer/planner/implementer/tester coding-agent teams.

### Domain-specific workflow

The framework is workflow-centric rather than coding-domain-centric. It has typed graph edges, fan-out, fan-in, switch-case, nested workflows, external request ports, human input pauses, checkpoint restore, and declarative .NET workflows. Those primitives are highly reusable for coding workflows, but the repo does not ship a dedicated patch planner, worktree owner, test runner loop, issue triage loop, or repository policy layer.

The closest coding-agent-adjacent pieces are the file access provider, shell tools, Agent Skills progressive disclosure, local memory provider, and Hyperlight CodeAct sandbox. These are primitives, not an opinionated software-engineering agent.

### Error prevention

The project has several prevention layers. Function tools validate schema, reject unexpected arguments, enforce unique names, and can require user approval. Workflow validation catches duplicate edges, missing targets, type-incompatible routes when annotations exist, output-designation errors, and graph signature drift during checkpoint restore. File access rejects absolute paths, parent traversal, symlink escapes, and unsafe overwrite/delete defaults. Shell tools make approval the default boundary. Docker shell and Hyperlight CodeAct add stronger execution boundaries when configured.

The security work is serious but still host-policy-dependent. FIDES prompt-injection defense is experimental and opt-in. MCP approval and allowlists are configurable, not mandatory. Skill script approval can be disabled. Local shell policy is explicitly not a sandbox. Custom checkpoint decoding can be unsafe if unrestricted pickle support is enabled.

### Self-learning / memory

The Python harness includes an experimental durable memory provider backed by `MEMORY.md`, topic markdown files, transcripts, and state. It extracts durable facts from transcript deltas, consolidates topic files, rebuilds an index, selects relevant topics by recency and keyword matching, and can persist local history via file-backed sessions. This is a good baseline for agent memory mechanics, especially topic files and explicit consolidation, but it is not specialized for codebase facts, ownership history, bug patterns, or project-specific decision records.

### Popular skills

Agent Skills are implemented as a progressive-disclosure provider: the model sees skill names/descriptions first, then can load skill details, read skill resources, and run skill scripts through registered runners. File-backed skills guard against path traversal and symlink escape. The model is useful for coding-agent skills because it keeps large procedural context out of the prompt until needed. The main caution is that script execution is only as safe as the trusted source policy, runner policy, and approval configuration.

## Core Execution Path

For a Python agent run, `Agent.run()` normalizes the input into messages, prepares a `SessionContext`, loads history/context providers, injects provider tools and middleware, merges local tools and MCP tools, applies compaction/token annotation through the chat client, invokes the model, handles streaming/non-streaming outputs, persists history, and updates `service_session_id` when the provider returns one. `Agent.as_tool()` wraps that whole flow as a function tool and decides whether the subagent receives an isolated session or inherits the parent session.

For a Python workflow run, `Workflow.run()` validates or restores runner state, optionally loads a checkpoint, injects initial messages or pending request responses, executes supersteps through edge runners, emits status and data-plane events, classifies outputs versus intermediate outputs by designation, stores checkpoints, and returns a `WorkflowRunResult` with final state and event timelines. Pending human/tool approval requests are typed events, and resumed responses are validated against the pending request type.

For .NET workflows, `Workflow` and `InProcessRunner` provide the same high-level model: typed executors, routes, ports, shared state, checkpoints, superstep execution, and event emission. Durable Task adds orchestration scheduling, deterministic replay constraints, durable entities for agent sessions, live status, HITL state, and persistent conversation history.

## Architecture

The architecture is layered:

- Core agents and chat clients define the model/tool/session/middleware boundary.
- Workflow primitives define typed executors, graph edges, runner contexts, checkpoints, output designation, and external requests.
- Orchestration builders compile familiar multi-agent patterns into workflows.
- Tool packages expose file, shell, MCP, skills, memory, and CodeAct primitives.
- Hosting packages adapt agents/workflows to Azure Functions, Foundry Agent Server, DevUI, A2A, AG-UI, and Durable Task.
- Eval packages convert agent/workflow traces into provider-agnostic eval items and Foundry-compatible evaluations.

The strongest architectural choice is keeping graph execution and agent execution related but distinct. Agents can be workflow executors and workflows can be exposed as agents, but workflow topology, checkpoint signatures, pending requests, and output designation remain explicit.

## Design Choices

- Typed workflows: Python infers handler input/output types from annotations and .NET route builders carry typed protocols and ports. Missing annotations reduce validation strength but do not block execution.
- Superstep runner: Workflow execution proceeds through queued messages and edge runners, which makes concurrent fan-out, fan-in, checkpoint points, and pending request recovery easier to reason about.
- Output designation: A node can produce terminal output, intermediate output, or hidden internal output. This matters for multi-agent systems where manager messages and worker chatter should not all become final answers.
- Session separation: Local session state, service-managed conversation IDs, and hosted identity context are separate concerns.
- Handoff as tool signal: Agents request transfer through synthetic tools, while middleware turns those calls into routing decisions instead of provider-visible side effects.
- HITL as typed request/response: User approval, function approval, plan review, and custom request-info flows are modeled as resumable workflow events rather than one-off callbacks.
- Security as composable policy: Approvals, allowlists, sandbox tools, FIDES, file-store guards, and hosted identity checks are separate mechanisms that hosts combine.

## Strengths

- Mature typed orchestration model across Python and .NET, including graph validation, output classification, checkpoint restore checks, nested workflows, and human request/resume semantics.
- Real multi-agent patterns, not just examples: sequential, concurrent, group chat, handoff, Magentic, agent-as-tool, workflow-as-agent, and declarative workflow surfaces.
- Good boundary vocabulary for sessions, context providers, history providers, middleware, MCP tools, function tools, skill resources, and service-side conversations.
- Strong deploy and eval reach: Foundry evals, local eval protocol, workflow eval breakdowns, Azure Functions hosting, Durable Task, Foundry hosting, DevUI, A2A, and AG-UI.
- Security-sensitive implementation details are visible in code and tests: path traversal guards, symlink handling, approval defaults for dangerous actions, Docker isolation defaults, Hyperlight sandboxing, checkpoint decode tests, and FIDES tests.
- Test coverage is broad around workflows, checkpoints, orchestration builders, security, MCP, shell tools, memory, file access, DevUI, Azure Functions, and Hyperlight CodeAct.

## Weaknesses

- The framework is large and preview-heavy. Several packages, ADRs, and security features are marked experimental, proposed, preview, or subject to API churn.
- Coding-agent support is indirect. The repo provides orchestration, file, shell, memory, and CodeAct primitives, but not a complete coding loop with patch ownership, repo-scoped context selection, test repair, review feedback handling, or worktree safety.
- Safety defaults vary by mechanism. Local shell approval is conservative, but MCP and skills rely on host configuration, and some sandbox or CodeAct configurations can be weakened by deployment choices.
- Type safety depends on annotations and wrapper discipline. Missing Python annotations skip some validation, and nested workflow concurrency requires care because stateful workflow instances and executors may be shared.
- Provider integration breadth adds complexity. Foundry, Azure, OpenAI-compatible, A2A, AG-UI, Durable Task, DevUI, and MCP surfaces are valuable, but they increase the amount of compatibility and security behavior a host must understand.
- Some persistence surfaces need careful trust boundaries. File checkpoints are guarded by default, but custom checkpoint decoding with unrestricted pickle remains a footgun for untrusted data.

## Ideas To Steal

- Model agent teams as typed workflow graphs with explicit output/intermediate/hidden output designation.
- Use provider-attributed context and session state instead of mixing memory, history, tool results, and system context into one flat prompt.
- Treat handoff as a controlled routing signal with synthetic tools, conversation filtering, and per-agent session persistence.
- Represent approvals, human input, and plan review as resumable typed events with validated responses.
- Hash workflow graph signatures into checkpoints and reject restores after topology drift.
- Keep tool-call groups atomic during compaction and history trimming.
- Expose workflows as agents and agents as tools, but make session propagation an explicit option.
- Build eval conversion from traces so workflows can be assessed overall and per participating agent.

## Do Not Copy

- Do not copy the framework's broad provider matrix unless the lab needs that deployment surface; it adds a large maintenance and security burden.
- Do not rely on regex command policies or path filters as the primary sandbox for coding-agent execution. Treat them as UX guardrails and put real isolation underneath.
- Do not expose MCP tools, skill scripts, shell commands, or checkpoint files from untrusted sources without a stricter host policy than the generic SDK requires.
- Do not make coding-agent safety depend on model compliance with instructions such as "do not overwrite"; enforce repository ownership and write scopes outside the model.
- Do not assume preview APIs or experimental defenses are stable enough to become hard dependencies.

## Fit For Agentic Coding Lab

The fit is conditional but important. Agent Framework should be indexed as a high-value orchestration and hosting reference for coding-agent systems, especially for typed workflow execution, subagent handoff, HITL resume, checkpointing, eval conversion, and context/session boundaries.

It should not be treated as a complete coding-agent product. A lab system would still need a repository-aware planner, file ownership model, patch application discipline, test loop, sandbox policy, context budgeter for code, and review-feedback workflow. The best use is to borrow patterns: workflow graph contracts, evented approvals, attributed context, checkpoint signatures, and subagent session isolation.

## Reviewed Paths

- `README.md`
- `python/README.md`
- `SECURITY.md`
- `docs/FAQS.md`
- `docs/decisions/0002-agent-tools.md`
- `docs/decisions/0006-userapproval.md`
- `docs/decisions/0015-agent-run-context.md`
- `docs/decisions/0019-python-context-compaction-strategy.md`
- `docs/decisions/0023-foundry-evals-integration.md`
- `docs/decisions/0024-prompt-injection-defense.md`
- `docs/decisions/0024-codeact-integration.md`
- `docs/decisions/0026-hosted-session-identity-context.md`
- `docs/features/FIDES_IMPLEMENTATION_SUMMARY.md`
- `docs/features/code_act/python-implementation.md`
- `docs/features/code_act/dotnet-implementation.md`
- `python/packages/core/agent_framework/_agents.py`
- `python/packages/core/agent_framework/_clients.py`
- `python/packages/core/agent_framework/_sessions.py`
- `python/packages/core/agent_framework/_tools.py`
- `python/packages/core/agent_framework/_types.py`
- `python/packages/core/agent_framework/_mcp.py`
- `python/packages/core/agent_framework/_compaction.py`
- `python/packages/core/agent_framework/_evaluation.py`
- `python/packages/core/agent_framework/security.py`
- `python/packages/core/agent_framework/_harness/_file_access.py`
- `python/packages/core/agent_framework/_harness/_memory.py`
- `python/packages/core/agent_framework/_skills.py`
- `python/packages/core/agent_framework/_workflows/_workflow.py`
- `python/packages/core/agent_framework/_workflows/_workflow_builder.py`
- `python/packages/core/agent_framework/_workflows/_executor.py`
- `python/packages/core/agent_framework/_workflows/_workflow_context.py`
- `python/packages/core/agent_framework/_workflows/_runner.py`
- `python/packages/core/agent_framework/_workflows/_runner_context.py`
- `python/packages/core/agent_framework/_workflows/_validation.py`
- `python/packages/core/agent_framework/_workflows/_checkpoint.py`
- `python/packages/core/agent_framework/_workflows/_checkpoint_encoding.py`
- `python/packages/core/agent_framework/_workflows/_edge.py`
- `python/packages/core/agent_framework/_workflows/_edge_runner.py`
- `python/packages/core/agent_framework/_workflows/_workflow_executor.py`
- `python/packages/core/agent_framework/_workflows/_functional.py`
- `python/packages/core/agent_framework/_workflows/_agent_executor.py`
- `python/packages/orchestrations/README.md`
- `python/packages/orchestrations/agent_framework_orchestrations/_sequential.py`
- `python/packages/orchestrations/agent_framework_orchestrations/_concurrent.py`
- `python/packages/orchestrations/agent_framework_orchestrations/_handoff.py`
- `python/packages/orchestrations/agent_framework_orchestrations/_group_chat.py`
- `python/packages/orchestrations/agent_framework_orchestrations/_base_group_chat_orchestrator.py`
- `python/packages/orchestrations/agent_framework_orchestrations/_orchestration_request_info.py`
- `python/packages/orchestrations/agent_framework_orchestrations/_magentic.py`
- `python/packages/tools/agent_framework_tools/shell/_tool.py`
- `python/packages/tools/agent_framework_tools/shell/_policy.py`
- `python/packages/hyperlight/README.md`
- `python/packages/hyperlight/agent_framework_hyperlight/_provider.py`
- `python/packages/hyperlight/agent_framework_hyperlight/_execute_code_tool.py`
- `python/packages/azurefunctions/README.md`
- `python/packages/azurefunctions/agent_framework_azurefunctions/_app.py`
- `python/packages/foundry_hosting/README.md`
- `python/packages/foundry_hosting/agent_framework_foundry_hosting/_responses.py`
- `python/packages/foundry_hosting/agent_framework_foundry_hosting/_invocations.py`
- `python/packages/devui/README.md`
- `python/packages/a2a/README.md`
- `python/packages/ag-ui/README.md`
- `dotnet/src/Microsoft.Agents.AI.Workflows/Workflow.cs`
- `dotnet/src/Microsoft.Agents.AI.Workflows/Executor.cs`
- `dotnet/src/Microsoft.Agents.AI.Workflows/IWorkflowContext.cs`
- `dotnet/src/Microsoft.Agents.AI.Workflows/RouteBuilder.cs`
- `dotnet/src/Microsoft.Agents.AI.Workflows/InProc/InProcessRunner.cs`
- `dotnet/src/Microsoft.Agents.AI.Workflows/Checkpointing/FileSystemJsonCheckpointStore.cs`
- `dotnet/src/Microsoft.Agents.AI.Workflows/Specialized/SequentialWorkflowBuilder.cs`
- `dotnet/src/Microsoft.Agents.AI.Workflows/Specialized/ConcurrentWorkflowBuilder.cs`
- `dotnet/src/Microsoft.Agents.AI.Workflows/Specialized/GroupChat/GroupChatWorkflowBuilder.cs`
- `dotnet/src/Microsoft.Agents.AI.Workflows/Specialized/GroupChat/GroupChatHost.cs`
- `dotnet/src/Microsoft.Agents.AI.Workflows/Specialized/Handoff/HandoffWorkflowBuilder.cs`
- `dotnet/src/Microsoft.Agents.AI.Workflows/Specialized/Handoff/HandoffAgentExecutor.cs`
- `dotnet/src/Microsoft.Agents.AI.Workflows/Specialized/Magentic/MagenticWorkflowBuilder.cs`
- `dotnet/src/Microsoft.Agents.AI.Workflows/Specialized/Magentic/MagenticOrchestrator.cs`
- `dotnet/src/Microsoft.Agents.AI.Workflows/Executors/AIAgentHostExecutor.cs`
- `dotnet/src/Microsoft.Agents.AI.Workflows.Declarative/README.md`
- `dotnet/src/Microsoft.Agents.AI.Workflows.Declarative/WorkflowModelBuilder.cs`
- `dotnet/src/Microsoft.Agents.AI.Workflows.Declarative/DeclarativeWorkflowExecutor.cs`
- `dotnet/src/Microsoft.Agents.AI.Workflows.Declarative/InvokeMcpToolExecutor.cs`
- `dotnet/src/Microsoft.Agents.AI.DurableTask/CHANGELOG.md`
- `dotnet/src/Microsoft.Agents.AI.DurableTask/Workflows/DurableWorkflowRunner.cs`
- `dotnet/src/Microsoft.Agents.AI.DurableTask/Workflows/DurableWorkflowClient.cs`
- `dotnet/src/Microsoft.Agents.AI.DurableTask/Agents/AgentEntity.cs`
- `python/packages/orchestrations/tests/test_group_chat.py`
- `python/packages/orchestrations/tests/test_handoff.py`
- `python/packages/orchestrations/tests/test_magentic.py`
- `python/packages/orchestrations/tests/test_concurrent.py`
- `python/packages/orchestrations/tests/test_orchestration_request_info.py`
- `python/packages/core/tests/workflow/`
- `python/packages/core/tests/core/`
- `python/packages/core/tests/test_security.py`
- `python/packages/tools/tests/`
- `python/packages/hyperlight/tests/hyperlight/test_hyperlight_codeact.py`
- `python/packages/azurefunctions/tests/`
- `python/packages/devui/tests/devui/`

## Excluded Paths

- Binary image/media fixtures and generated UI assets.
- Package lockfiles, build metadata, release automation, and formatting configuration.
- Provider-specific samples not needed to assess orchestration, handoff, context, memory, eval, deploy, or coding-agent applicability.
- Exhaustive .NET and Python API surface files after representative core, orchestration, hosting, security, eval, and test paths were reviewed.
- Full Azure/Foundry/A2A/AG-UI end-to-end sample execution, because this review focused on repository architecture and source behavior rather than live cloud integration.
