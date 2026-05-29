# aden-hive/hive

- URL: https://github.com/aden-hive/hive
- Category: subagents-multiagents
- Stars snapshot: 10,449 (GitHub REST API repository search, captured 2026-05-29)
- Reviewed commit: b993d886939f7ed440a0619a2ac720146c79aafc
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong multi-agent runtime and governance candidate, especially for queen-mediated delegation, evented worker lifecycle, task tracking, and operational guardrails. Treat it as a pattern source rather than a drop-in coding-agent substrate because several high-level claims are doc-level or stale in the reviewed code, including shared-state aggregation, output-key completion, and autonomous self-improvement.

## Why It Matters

Hive is a production-oriented agent harness that puts multi-agent work behind a visible control plane: a queen agent can incubate persistent colonies, fork session context into workers, fan out parallel tasks, receive structured worker reports, and keep a human in the loop through queen-mediated questions. That makes it useful for the Agentic Coding Lab index even though the product target is broader than coding agents. The valuable material is the governance architecture around subagents: phase gates, delegated task surfaces, credential-aware tool filtering, event logs, resumable state, and worker health inspection.

## What It Is

The repository implements an "OpenHive" desktop/runtime product. The older graph runtime uses `AgentHost`, `ExecutionManager`, `Orchestrator`, `NodeWorker`, and `AgentLoop` to run event-loop nodes connected by edges. The newer colony path uses `ColonyRuntime` and `Worker` clones: an overseer/queen stays persistent while ephemeral workers run delegated tasks and publish `SUBAGENT_REPORT` events. The system also includes MCP/tool registry loading, credential validation, file-backed task lists, skill catalogs, queen lifecycle tools, session stores, JSONL event logs, and documented evolution/memory concepts.

## Research Themes

- Token efficiency: Conversation stores, dynamic skills catalogs, context compaction, prompt-cache-aware phase suffixes, and tool-result spillover/pointers reduce prompt bulk. The design is practical: large tool outputs can be stored on disk while the model receives a pointer and later calls `load_data`.
- Context control: Worker context is forked from the queen by copying conversation parts and appending a delegated task. Agent contexts carry `agent_id`, `stream_id`, `task_list_id`, `colony_id`, `picked_up_from`, skills, credentials prompt, and scoped tool lists. The boundary is meaningful but not absolute because undeclared graph buffer permissions default open and some file tools are treated as always available when registered.
- Sub-agent / multi-agent: First-class support exists in two forms: graph nodes as autonomous `NodeWorker`s with fan-out/fan-in, and colony workers as independent AgentLoop clones that report to a queen. `run_parallel_workers` enforces batch and global concurrency caps, strips queen-only tools, preflights credentials, records template assignments, and schedules soft/hard timeout handling.
- Domain-specific workflow: The queen lifecycle is domain-rich: independent, incubating, working, and reviewing phases; an incubating evaluator gates persistent colony creation; `create_colony` writes colony-scoped skills and task/triggers metadata; workers can use session task tools while the queen owns colony template tools.
- Error prevention: Guardrails include credential preflight, MCP admission filtering, duplicate tool first-wins behavior, worker timeouts, stall/doom-loop detection, ghost empty-stream handling, resurrection retries, task reminders, event histories, and health summaries. Some guardrails are soft and rely on prompts or LLM judges.
- Self-learning / memory: Docs describe evolution, memory reflection, and regeneration of prompts/graphs/tools. The reviewed code has persistent conversations, skills, colony-local skill authoring, recalls in queen phase state, and task/progress stores, but I did not find a complete autonomous evolve-evaluate-regenerate loop wired as a production path.
- Popular skills: Hive's skills system is more than prompt snippets: colony-scoped skills, queen-created skill provenance, dynamic catalogs, visibility by queen phase, and default operational protocols are all part of runtime tool/context governance.

## Core Execution Path

For graph-style agents, `AgentHost.start()` initializes entry-point streams, timers, webhooks, event subscriptions, and shared managers. `AgentHost.trigger()` runs pipeline stages, resolves a stream, creates a run id, and calls `ExecutionManager.execute()`. The execution manager cancels prior active runs for the stream, sets up state/checkpoints, creates an `Orchestrator`, and wraps execution in resurrection retry handling. `Orchestrator` validates the `GraphSpec`, creates one `NodeWorker` per node, activates the entry node, routes worker completion/failure events, and handles fan-out/fan-in and terminal aggregation. Each event-loop node is backed by `AgentLoop`, which streams LLM output, executes tools, applies judge decisions, persists conversation/cursor state, detects stalls, and blocks or escalates for user/queen input.

For colony-style agents, the queen/overseer calls lifecycle tools. `start_incubating_colony` runs a readiness evaluator over recent queen conversation and switches the queen into incubating phase only when the proposed persistent colony is concrete enough. `create_colony` writes colony-local skill files, forks the queen session, seeds task/progress metadata, writes trigger configuration, emits `COLONY_CREATED`, and locks the original session. `run_parallel_workers` validates a task batch, enforces a hard cap and `max_concurrent_workers`, filters tools by credentials and queen-only status, publishes colony template entries, then calls `ColonyRuntime.spawn_batch()`. Each `Worker` runs an AgentLoop in its own storage directory and reports through `report_to_parent` or a synthesized terminal report.

## Architecture

- `core/framework/agent_loop/agent_loop.py` is the central LLM loop. It injects `ask_user` only for direct queen/user I/O, `escalate` for worker/subagent paths, and `report_to_parent` for parallel workers. It persists conversation state, supports tool batching, compaction, user-input waits, judge calls, and runtime reliability guards.
- `core/framework/host/colony_runtime.py` is the newer clone-worker runtime. It starts/stops colony services, forks parent conversation into worker stores, spawns background workers, starts a persistent overseer, registers triggers, applies MCP allowlists, and tracks worker results.
- `core/framework/host/worker.py` wraps one AgentLoop clone. It scopes execution context with worker identity, applies account overrides, handles persistent overseer input, preserves explicit reports on cancellation, and emits `SUBAGENT_REPORT`.
- `core/framework/tools/queen_lifecycle_tools.py` exposes queen governance: phase state, incubating gate, colony creation, worker fan-out, stop/review transitions, status inspection, credential tools, trigger management, and message injection.
- `core/framework/orchestrator/*` implements the graph runtime: `GraphSpec`, `EdgeSpec`, `NodeSpec`, `DataBuffer`, `NodeWorker`, and `Orchestrator`.
- `core/framework/loader/tool_registry.py` owns local tools and MCP tools, context injection, concurrency-safety metadata, duplicate handling, admission gates, and credential-driven resync.
- `core/framework/tasks/*` implements file-backed session and colony task lists with atomic create/update/delete, blockers, owners, events, task reminders, and separate queen-only colony template tools.
- `core/framework/host/event_bus.py` is a broad in-process event surface covering execution, stream, worker, queen phase, trigger, judge, tool, context, task, and colony lifecycle events.

## Design Choices

- Queen-mediated human-in-the-loop is preferred over letting arbitrary workers talk directly to the user. Direct `ask_user` is available for queen/direct streams, while worker nodes escalate to the queen and wait for guidance.
- Parallel workers are deliberately isolated. They get their own storage directory, conversation store, task list id, browser/tool profile, event stream id, and account override context.
- Worker reports are structured and terminal. `report_to_parent` records status, summary, and data; timeout/cancellation paths still emit a report so the queen has a complete fan-in picture.
- Persistent colonies require a queen-authored skill. `create_colony` scopes that skill under the colony directory rather than the user-global skill directory, reducing accidental cross-colony leakage.
- Tool execution favors conservative parallelism. Only allowlisted concurrency-safe tools run in parallel; unknown or unsafe tools serialize.
- Tool and MCP visibility are credential-aware. Missing credentials can drop tools at preflight or spawn time rather than failing every worker repeatedly.
- The graph runtime strips missing tools from reachable nodes instead of hard failing. This improves availability but weakens deterministic configuration governance.
- Verification is layered but model-heavy: deterministic checks, implicit/custom judges, success criteria, health logs, and human escalation exist, but final acceptance can still fall back to accept after transient judge failures.

## Strengths

- Strong queen-worker governance. Phase transitions, incubation approval, queen-only lifecycle tools, tool-surface changes by phase, and structured worker reports are directly relevant to coding-agent orchestration.
- Practical fan-out implementation. `run_parallel_workers` returns immediately, keeps the queen unblocked, enforces worker caps, records template-to-worker assignment, injects soft-timeout warnings, and hard-stops silent workers.
- Clear task ownership boundaries. Session tools write only to the caller's task list, while queen-only colony template tools manage the spawn plan. This is a useful pattern for separating worker progress from coordinator planning.
- Operational observability is broad. The event bus, session logs, state files, worker health summary, judge verdicts, task events, and colony phase events provide many hooks for UI, debugging, and evaluation.
- Tool/context boundaries are taken seriously. MCP schema context params are hidden from the model and injected from runtime context; per-worker profile/account overrides prevent spawned workers from accidentally sharing the queen's browser or OAuth profile.
- The system encodes recovery patterns that coding agents need: persisted pending user input, cursor restoration, resurrection retries, tool doom-loop detection, stall nudges, empty-stream protection, and cancellation-aware reports.

## Weaknesses

- Several docs overstate current implementation. The reviewed code marks `shared_state.py` and `outcome_aggregator.py` as stubs after a colony refactor, while docs still describe stronger shared buffer, outcome, and progress aggregation semantics.
- Output-key completion appears internally inconsistent. Synthetic `set_output` still exists in prompts/judge feedback and missing-key logic, but `AgentLoop` rejects `set_output` tool calls with "set_output is no longer available" and asks the model to report via conversation. This makes graph-node output-key contracts suspect.
- Self-improvement is not proven as an implemented loop. The evolution docs describe execute/evaluate/diagnose/regenerate, but the code paths reviewed show storage, skills, and observability rather than an autonomous, closed-loop coding agent that rewrites and verifies itself.
- Verification can degrade to soft acceptance. The judge pipeline can accept after transient judge outages, and much of the quality gate depends on LLM verdicts rather than deterministic tests, sandboxed execution, or typed postconditions.
- Some isolation policies are opt-in or uneven. Graph data buffer permissions are permissive when input/output keys are omitted, `tool_access_policy="all"` does not appear to grant all tools in the context builder, and always-available file tool names imply a broad default when those tools are present.
- Per-stream graph execution is less concurrent than some specs imply. `ExecutionManager.execute()` cancels active executions in the same stream before starting a new one; effective concurrency is across streams/workers/branches, not multiple active executions on a single stream.
- Event-driven graph entry points may have a sharp edge: `AgentHost.start()` passes `filter_graph` to `EventBus.subscribe()`, but the reviewed `EventBus.subscribe` signature does not accept that keyword.

## Ideas To Steal

- Use queen-mediated `ask_user` and worker `escalate` as separate primitives. It keeps human interaction centralized while still letting subagents request help.
- Require subagents to report via a structured terminal channel. A minimal schema of status, summary, data, error, duration, and tokens is enough for fan-in and audit.
- Put delegation through phase gates. Hive's independent/incubating/working/reviewing model is a useful way to shrink tool surfaces when the coordinator is drafting persistent automation.
- Fork conversation context into workers by copying durable message parts and appending a clear hand-off task. This preserves useful history while giving each worker an independent cursor and storage root.
- Combine soft and hard worker timeouts. A soft timeout asks for partial results through the normal agent channel; a hard timeout cancels while preserving any explicit report.
- Separate coordinator task templates from worker session task lists. This avoids every worker mutating the central plan while still letting the queen map spawned workers to planned work.
- Hide runtime context from tool schemas and inject it with contextvars. This is a clean way to give tools `agent_id`, `data_dir`, `profile`, and task list identity without letting the model spoof them.

## Do Not Copy

- Do not keep stale synthetic tools in judge/prompt paths. If a completion protocol is removed, all prompts, judge feedback, tests, and output-key checks need to migrate together.
- Do not rely on LLM judges as the final verification layer for coding tasks. Coding-agent lab evaluations should add deterministic tests, execution traces, diff checks, and artifact validation.
- Do not make state isolation permissive by omission. Require explicit data permissions for subagents or fail closed when a graph node omits input/output declarations.
- Do not silently strip missing tools for high-stakes workflows. Missing tool configuration should often fail early with a visible deployment error rather than degrading a node's capabilities.
- Do not treat roadmap architecture docs as evidence. Hive's docs are valuable, but repo notes should cite implemented code paths separately from proposals.

## Fit For Agentic Coding Lab

Hive is in scope for the subagents/multiagents category as a rich governance case study. It is especially relevant to research on coordinator/subagent boundaries, task fan-out, structured subagent reports, phase-gated autonomy, human-in-the-loop escalation, tool-context injection, MCP credential filtering, and runtime observability. It is less directly useful as a coding-agent benchmark or reference implementation for code-edit correctness because the reviewed runtime is product/automation oriented, verification is mostly judge/event based, and some core graph-output abstractions are stale after refactors. Best fit: mine it for orchestration patterns and failure-mode checklists, then pair those patterns with stricter coding-agent verification.

## Reviewed Paths

- `README.md`
- `docs/agent_runtime.md`
- `docs/key_concepts/graph.md`
- `docs/key_concepts/worker_agent.md`
- `docs/key_concepts/evolution.md`
- `docs/key_concepts/goals_outcome.md`
- `docs/architecture/README.md`
- `core/framework/agent_loop/agent_loop.py`
- `core/framework/agent_loop/internals/judge_pipeline.py`
- `core/framework/agent_loop/internals/synthetic_tools.py`
- `core/framework/host/agent_host.py`
- `core/framework/host/execution_manager.py`
- `core/framework/host/event_bus.py`
- `core/framework/host/shared_state.py`
- `core/framework/host/outcome_aggregator.py`
- `core/framework/host/colony_runtime.py`
- `core/framework/host/worker.py`
- `core/framework/orchestrator/orchestrator.py`
- `core/framework/orchestrator/node_worker.py`
- `core/framework/orchestrator/node.py`
- `core/framework/orchestrator/context.py`
- `core/framework/orchestrator/edge.py`
- `core/framework/loader/tool_registry.py`
- `core/framework/loader/mcp_client.py`
- `core/framework/credentials/validation.py`
- `core/framework/tools/queen_lifecycle_tools.py`
- `core/framework/tools/worker_monitoring_tools.py`
- `core/framework/tasks/models.py`
- `core/framework/tasks/store.py`
- `core/framework/tasks/scoping.py`
- `core/framework/tasks/reminders.py`
- `core/framework/tasks/tools/session_tools.py`
- `core/framework/tasks/tools/colony_tools.py`

## Excluded Paths

- Frontend UI components, desktop packaging, visual assets, and styling not needed to assess agent governance.
- Most provider-specific MCP/tool implementations under tool packages; the review focused on registry/admission/execution boundaries rather than each integration.
- Example agents/templates, generated lockfiles, screenshots, marketing assets, bounty docs, and contribution metadata.
- Most unit tests beyond targeted inspection of task, colony, and runtime behavior signals; the repo note is a code/design review, not a full test audit of Hive itself.
