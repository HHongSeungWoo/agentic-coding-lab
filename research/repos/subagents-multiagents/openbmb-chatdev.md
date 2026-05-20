# OpenBMB/ChatDev

- URL: https://github.com/OpenBMB/ChatDev
- Category: subagents-multiagents
- Stars snapshot: 33,151 stars via GitHub REST API repository metadata, captured 2026-05-20
- Reviewed commit: b23950d03575e31c958d7f57af521fb782db8750
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong source for configurable multi-agent coding workflows, especially graph-shaped role chains, loop guards, context routing, and tool-bound agent nodes. Best copied as patterns, not as a direct runtime: current main is now a broad DevAll orchestration platform, and several safety and verification details need tightening before using it as a coding-agent substrate.

## Why It Matters

ChatDev is one of the canonical "software company of agents" projects, but the reviewed main branch has moved beyond the original fixed CEO/CTO/programmer chain. It now packages those ideas as a YAML-driven graph runtime: agents, literal prompts, pass-through context nodes, human gates, Python runners, subgraphs, loop counters/timers, memory stores, function tools, MCP tools, and dynamic map/tree expansion.

For Agentic Coding Lab, the useful part is not the visual UI or product packaging. The useful part is the execution model: treat a multi-agent coding process as a typed graph whose edges control task state, context retention, trigger semantics, and verification loops. `yaml_instance/ChatDev_v1.yaml` shows the old ChatDev software-development lifecycle as data: code generation, completion loop, code review loop, test/error-summary loop, and documentation/manual phase. The engine around it generalizes that shape to other teams and topologies.

## What It Is

The repository currently describes two generations:

- ChatDev 1.0: legacy "virtual software company" with roles such as CEO, product officer, programmer, code reviewer, and test engineer.
- ChatDev 2.0 / DevAll: current main branch, a zero-code multi-agent orchestration platform where workflows are YAML graphs rendered and run through backend/frontend tooling.

This review focused on the current main branch at `b23950d03575e31c958d7f57af521fb782db8750`, plus the bundled `ChatDev_v1.yaml` workflow that preserves the software-development role chain. The legacy `chatdev1.0` branch was not reviewed as source of truth.

The core runtime path is:

1. `run.py` or server APIs load a YAML design.
2. `entity/config_loader.py` resolves `${VAR}` placeholders from YAML/env/.env.
3. `entity.graph_config.GraphConfig` and `workflow.graph_context.GraphContext` create run/session state under `WareHouse/<session>/`.
4. `workflow.graph_manager.GraphManager` instantiates nodes, edges, subgraphs, start nodes, cycle metadata, and execution layers.
5. `workflow.graph.GraphExecutor` builds memory, thinking, tool managers, node executors, and edge condition managers.
6. `DagExecutionStrategy`, `CycleExecutionStrategy`, or `MajorityVoteStrategy` runs the graph.
7. Node outputs move through edge managers, which apply conditions, payload processors, context clearing, `keep_message`, `carry_data`, and triggers.
8. Results, logs, token usage, attachments, and workspace artifacts are archived under the session directory.

## Research Themes

- Token efficiency: The repo has explicit `TokenTracker` export, `context_window` trimming per node, `keep_message` for durable task context, passthrough filtering after loops, and dynamic map/tree fan-out to split large inputs. It lacks a rigorous token budget planner; efficiency is mostly controlled by graph design and context routing.
- Context control: This is one of the strongest patterns. Edges decide whether to carry data, preserve messages, clear previous context, clear kept context, or only trigger execution. Nodes decide whether to keep no context, a bounded window, or unlimited context. Tool-call traces can be restored into node context through `context_trace`.
- Sub-agent / multi-agent: The runtime supports role agents, DAG teams, SCC-based cycles, subgraph nodes, majority voting, dynamic parallel agents, and centralized manager/evaluator patterns in example YAMLs. `ChatDev_v1.yaml`, `MACNet_v1.yaml`, `GameDev_with_manager.yaml`, `reflexion_loop.yaml`, and `react_agent.yaml` are the main reusable examples.
- Domain-specific workflow: Coding workflows are modeled with specialized roles and phase prompts: programmer, reviewer, test engineer, product officer, manual writer. The game-development workflow shows stronger domain decomposition into designer, planner, manager, core developer, polish developer, QA, and Python execution.
- Error prevention: Built-in retry policy for model calls, typed config parsing, YAML validation tools, loop counters/timers, tool loop limit, workspace-scoped file tools, and test/error-summary phases help. However, many failures become assistant messages instead of hard runtime failures, which can hide breakage unless edge conditions check for it.
- Self-learning / memory: Memory is first-class: simple vector memory, file memory, blackboard memory, and Mem0 memory. The reflexion example writes evaluator feedback into blackboard memory and feeds it back to the actor.
- Popular skills: Current main has an Agent Skills subsystem that discovers `.agents/skills`, exposes `activate_skill` and `read_skill_file`, filters incompatible skills by allowed tools, and blocks reading skill files before activation. This is relevant for skill-aware subagents, but the bundled workflows do not make it the dominant pattern.

## Core Execution Path

`GraphManager.build_graph()` is the structural compiler. It deep-copies node definitions, builds subgraphs, attaches edge metadata to source and target nodes, requires explicit start nodes, warns about nodes that cannot be triggered by any predecessor, and chooses a DAG or cycle-aware execution plan.

For DAGs, `workflow/executor/dag_executor.py` executes topological layers and uses `ParallelExecutor` to run independent nodes in the same layer concurrently.

For cyclic graphs, `workflow/cycle_manager.py` detects strongly connected components with Tarjan's algorithm and `workflow/executor/cycle_executor.py` schedules each SCC as a super node. On entry, the executor requires a unique externally triggered initial node unless a configured entry node can be used. It then breaks the entry edge for scoped topological sorting, supports nested cycles recursively, stops when an out-of-cycle edge is triggered, when the initial node is not retriggered, or when a max-iteration limit is reached.

For ChatDev's coding workflow, `yaml_instance/ChatDev_v1.yaml` encodes phases as nodes and edges:

- `USER` keeps the user task available to multiple role nodes through non-triggering context edges.
- `Programmer Coding` writes initial code using file/uv tools.
- `Programmer Code Complete` iterates up to a loop counter until it emits `<INFO> FINISHED`.
- `Code Reviewer` reviews code with read-only-ish tooling and emits `<INFO> Finished` when satisfied.
- `Programmer Code Review` modifies code based on review comments.
- `Software Test Engineer` runs code with timeout-aware instructions.
- `Programmer Test Error Summary` summarizes failures without editing.
- `Programmer Test Modification` fixes code based on failure summary.
- `Chief Product Officer` and `Chief Executive Officer` handle manual/documentation phase.

This is a role chat chain, but the chat is mediated by typed graph edges rather than a single transcript. Edges decide which comments, task messages, and tool traces enter each role's input queue.

## Architecture

Main components:

- Config model: `entity/configs/*` dataclasses parse YAML into typed graph/node/edge/memory/tooling/thinking configs and expose `FIELD_SPECS` for UI/schema generation.
- Runtime graph: `workflow/graph_context.py`, `workflow/graph_manager.py`, `workflow/graph.py`, and `workflow/runtime/*` keep mutable run state, dependency layers, run directory, token tracker, log manager, attachment store, and code workspace.
- Node execution: `runtime/node/executor/*` implements agent, human, Python, literal, passthrough, subgraph, loop counter, and loop timer nodes.
- Agent runtime: `runtime/node/executor/agent_executor.py` builds system prompts, applies thinking and memory, calls provider adapters, executes tool loops, persists attachments, and writes memory after completion.
- Tooling: `runtime/node/agent/tool/tool_manager.py` routes function tools and MCP tools. Function tools come from `functions/function_calling/`; MCP can be remote HTTP or local stdio.
- Edge logic: `runtime/edge/conditions/*` and `runtime/edge/processors/*` implement condition managers and payload transformers. Conditions can be simple functions or declarative keyword/regex checks.
- Memory: `runtime/node/agent/memory/*` implements simple FAISS memory, file-index memory, blackboard memory, and Mem0 memory.
- Observability: `utils/log_manager.py`, `utils/token_tracker.py`, `workflow/runtime/result_archiver.py`, and server WebSocket services write structured logs, token usage, node outputs, and artifact events.

The design is registry-heavy: node types, memory stores, thinking modes, edge conditions, processors, function catalog entries, and model providers all register into schema/runtime registries. This is useful for extensibility and for visual authoring, but it also spreads control flow across many files.

## Design Choices

The strongest design choice is making agent collaboration explicit data. Role behavior, tooling, loop limits, conditions, and context policy live in YAML, so a "team" can be versioned and inspected without changing Python runtime code.

Edge semantics are unusually rich. A single edge can:

- trigger or only carry context,
- pass or suppress payload,
- mark a payload as kept,
- clear non-kept or kept prior context,
- run a condition,
- run a payload processor,
- dynamically split target execution into map/tree units.

This creates a compact language for agent workflow state. The downside is that edge behavior becomes hard to reason about when many non-triggering context edges, loops, and conditions overlap.

The runtime separates model providers from graph orchestration. OpenAI and Gemini adapters serialize messages, attachments, tools, and token usage in provider-specific code, while node/edge scheduling stays provider-neutral.

The code-generation workspace model is practical. Every session gets a `code_workspace`, file tools resolve paths under it, Python runner nodes run there, attachments live under it, and run logs are archived alongside outputs. This gives each workflow run a tangible artifact boundary.

The repo also includes two different verification ideas:

- Agent-driven verification: prompts ask test engineers/reviewers to run tools, inspect errors, and loop until markers such as `<INFO>` appear.
- Runtime/tool verification: Python nodes, `uv_run`, and edge processors execute code with timeouts and return stdout/stderr.

The first is flexible but weakly enforceable. The second is better for coding-agent systems, but not uniformly used in every coding flow.

## Strengths

- Graph-as-workflow is clear and reusable. Software-development phases are visible in `ChatDev_v1.yaml` rather than buried in agent code.
- Roles are narrow enough to create useful tension: programmer, reviewer, tester, product/manual roles, manager/evaluator patterns.
- Context routing is first-class. `context_window`, `keep_message`, pass-through nodes, and edge clearing policies directly address context bloat.
- Loop controls are explicit. `loop_counter` and `loop_timer` make termination visible in graph structure instead of relying only on prompts.
- Tool boundaries are configurable per node. Agent nodes can have no tools, function tools, local MCP, remote MCP, or skills.
- Function file tools mostly resolve paths under the session workspace and block modifications to attachments.
- Dynamic map/tree execution is useful for scalable subagent fan-out and reduction.
- Subgraph nodes make complex agent teams reusable and nestable.
- Memory is pluggable and stage-aware; nodes can read/write different stores at different phases.
- The runtime records token usage, logs, node outputs, and workflow summaries, which is essential for debugging agent systems.

## Weaknesses

- Current main is a broad orchestration product, not a focused AI coding harness. Coding workflow quality depends heavily on YAML prompts and tool selection.
- Validation coverage is uneven. There are unit tests for memory and WebSocket behavior, but little direct coverage for cycle scheduling, dynamic edge semantics, ChatDev_v1 execution, or code-review/test loops.
- Agent failures are often converted into assistant messages rather than hard failures. Downstream nodes may continue unless edge conditions detect the error text.
- Cycle detection initially traverses all outgoing edges, including non-trigger context edges. Later scoped execution filters trigger edges. This mismatch can inflate SCCs or make cycle reasoning harder.
- `code_save_and_run` in `functions/edge_processor/transformers.py` bypasses the safer `FileToolContext.resolve_under_workspace()` write path for parsed filenames, clears the workspace, and executes `uv run main.py` through `shell=True`. It is useful as a demo processor, but risky as a general coding-agent tool boundary.
- Prompt-level success markers such as `<INFO> Finished` and `<INFO> FINISHED` are brittle. Case and exact text drive control flow.
- Several workflow examples use empty/default provider fields or null tooling fields, making them templates rather than immediately runnable robust systems.
- The UI/schema registry architecture adds moving parts. For a code-agent runtime, many frontend and form-generation paths are not necessary.
- Local MCP inherits host environment by default if configured that way; docs warn about sandboxing, but runtime enforcement is limited.
- File and memory persistence can include multimodal blocks with data. This is useful, but can create large local artifacts and potential data retention issues if not governed.

## Ideas To Steal

- Express multi-agent coding teams as graph YAML with typed node and edge semantics. This makes agent workflow review much easier than opaque prompt chains.
- Separate trigger edges from context-only edges. This is powerful for preserving the original task while letting phase outputs drive execution.
- Add edge-level context controls: `carry_data`, `keep_message`, `clear_context`, `clear_kept_context`, and bounded node `context_window`.
- Use guard nodes for loop limits instead of only telling the model to stop.
- Model code review/testing as separate phases with different tool permissions. Reviewer can read/search/run; programmer can write; tester can execute; summarizer cannot edit.
- Keep a session `code_workspace` and archive node outputs, logs, token usage, and generated files together.
- Support subgraphs as reusable team components. A coding workflow can call a review subgraph, a ReAct tool subgraph, or a reflexion subgraph.
- Use map/tree dynamic edges for scalable parallel review, chunk analysis, test matrix execution, or multi-file summarization.
- Make memory attachments stage-aware. Retrieval during generation and writing after completion are different operations and should be configured separately.
- Add skill activation tools that force agents to load instructions before claiming skill use, and restrict skill file reads to activated skill directories.

## Do Not Copy

- Do not rely on prompt markers alone for phase transitions in critical coding workflows. Prefer structured verdicts or typed outputs validated by the runtime.
- Do not copy `code_save_and_run` as-is into a trusted coding harness. Rework it to reject path traversal, avoid `shell=True`, preserve workspace files unless explicitly requested, and surface timeout/exit status as typed data.
- Do not let model/provider exceptions become ordinary assistant text for verifier-critical phases. Fail closed or mark node status as failed.
- Do not use broad local MCP or host-inherited environment without sandbox policy.
- Do not make UI-generated schemas the only source of workflow validation. Add runtime tests for representative workflow graphs.
- Do not overuse non-triggering edges in cycles without visualization/testing; they make SCC and context reasoning difficult.
- Do not store full multimodal memory snapshots by default in sensitive projects. Add retention and redaction rules.

## Fit For Agentic Coding Lab

Fit is high for workflow-pattern extraction and moderate as reusable code.

Best matches:

- Multi-agent coding lifecycle design.
- Role/phase graph templates.
- Context routing rules.
- Subgraph composition.
- Loop guard nodes.
- Tool-permission separation by role.
- Run artifact archiving.
- Dynamic fan-out/reduce for parallel agent work.

Less direct fit:

- The full DevAll app UI.
- General workflow marketplace/product shell.
- Frontend canvas implementation.
- Legacy marketing assets and demos.

For Agentic Coding Lab, the strongest artifact candidate is a smaller "agent workflow graph spec" that borrows ChatDev's edge controls and phase loops but tightens verification into structured outputs, typed failure states, and sandboxed file/command tools.

## Reviewed Paths

- `README.md`: current project positioning, v1/v2 split, quick start, legacy branch note, MacNet/IER/ECL context.
- `run.py`: CLI execution entrypoint and task attachment setup.
- `entity/config_loader.py`, `entity/graph_config.py`, `workflow/graph_context.py`: config loading, runtime session directory, graph state.
- `entity/configs/node/node.py`, `entity/configs/node/agent.py`, `entity/configs/edge/edge.py`, `entity/configs/edge/edge_condition.py`: node, agent, edge, retry, and condition schemas.
- `workflow/graph.py`, `workflow/graph_manager.py`, `workflow/topology_builder.py`, `workflow/cycle_manager.py`: graph build, edge preparation, memory/thinking build, topology, cycle detection.
- `workflow/executor/dag_executor.py`, `workflow/executor/cycle_executor.py`, `workflow/executor/parallel_executor.py`, `workflow/executor/dynamic_edge_executor.py`, `workflow/runtime/execution_strategy.py`: DAG, cycle, parallel, map/tree, majority vote execution.
- `runtime/node/executor/agent_executor.py`, `python_executor.py`, `human_executor.py`, `subgraph_executor.py`, `loop_counter_executor.py`, `loop_timer_executor.py`, `passthrough_executor.py`, `literal_executor.py`: concrete node behavior.
- `runtime/node/agent/tool/tool_manager.py`: function, MCP remote, MCP local, and attachment normalization boundaries.
- `runtime/node/agent/providers/openai_provider.py`: provider call mode, tool serialization, token usage extraction.
- `runtime/node/agent/memory/*`: simple, file, blackboard, Mem0 memory behavior.
- `runtime/node/agent/skills/manager.py`, `entity/configs/node/skills.py`: Agent Skills discovery, activation, compatibility, and file-read rules.
- `runtime/node/splitter.py`, `entity/configs/edge/dynamic_edge_config.py`: dynamic split and map/tree config behavior.
- `functions/function_calling/file.py`, `functions/function_calling/uv_related.py`, `functions/function_calling/code_executor.py`: workspace file, package, and execution tools.
- `functions/edge/conditions.py`, `functions/edge_processor/transformers.py`: function conditions and code-save/run edge processor.
- `yaml_instance/ChatDev_v1.yaml`: main software-development role chain.
- `yaml_instance/GameDev_with_manager.yaml`, `yaml_instance/MACNet_v1.yaml`, `yaml_instance/MACNet_optimize_sub.yaml`, `yaml_instance/subgraphs/reflexion_loop.yaml`, `yaml_instance/subgraphs/react_agent.yaml`: multi-agent team examples and loop patterns.
- `docs/user_guide/en/execution_logic.md`, `workflow_authoring.md`, `dynamic_execution.md`, `modules/memory.md`, `modules/thinking.md`, `modules/tooling/function.md`, `modules/tooling/mcp.md`, `nodes/agent.md`, `nodes/passthrough.md`, `nodes/loop_counter.md`, `nodes/loop_timer.md`: documentation cross-check for runtime behavior.
- `check/check_yaml.py`, `check/check_workflow.py`, `tools/validate_all_yamls.py`: validation utilities.
- `tests/test_mem0_memory.py`, `tests/test_memory_embedding_consistency.py`, `tests/test_websocket_send_message_sync.py`, `tests/test_server_main_reload.py`: available test coverage sample.

## Excluded Paths

- `frontend/`: Vue/Vite UI, canvas/workbench views, sprites, fonts, localization, and UI utilities. Excluded as UI-only; only docs and backend execution paths were relevant.
- `assets/` and `frontend/public/media/`: screenshots, gifs, logos, tutorial images, generated visuals. Excluded as binary/media/marketing assets.
- `package-lock.json`, `frontend/package-lock.json`, `uv.lock`: dependency lockfiles. Excluded except to confirm stack shape.
- `server/routes/*`, most `server/services/*`, and WebSocket UI services beyond selected tests/docs: useful for product operation, but not central to multi-agent coding workflow mechanics.
- `docs/user_guide/zh/*` and `README-zh.md`: Chinese mirrors of docs. English docs were reviewed to avoid duplicate content.
- `yaml_instance/blender_*`, `spring_*`, `deep_research_*`, `data_visualization_*`, and media-specific examples: domain demos outside the requested coding-workflow focus, except where dynamic/team patterns were already represented by reviewed examples.
- `assets/cases/*`, generated case media, and tutorial images: generated/company output paths, not reusable runtime logic.
- Legacy `chatdev1.0` branch: noted from README but not checked out; reviewed commit is current `main`.
