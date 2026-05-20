# FoundationAgents/MetaGPT

- URL: https://github.com/FoundationAgents/MetaGPT
- Category: subagents-multiagents
- Stars snapshot: 68,155 via GitHub REST API on 2026-05-20
- Reviewed commit: 11cdf466d042aece04fc6cfd13b28e1a70341b1f
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong reference for multi-agent software-company SOPs, role-private queues, causal message tags, artifact-backed task state, and code/test/debug loops. Do not copy its broad tool permissions, prompt-routed team leader, auto dependency installation, weak sandbox boundaries, or thin local verification as-is.

## Why It Matters

MetaGPT is one of the clearest open-source examples of turning software delivery into a multi-agent organization. The useful part for Agentic Coding Lab is not the marketing claim that agents behave like a company; it is the concrete machinery: roles watch action-caused messages, a shared environment routes envelopes, artifacts are stored as PRD/design/task/code/test files, and downstream agents react to changed file references rather than giant chat blobs.

It also shows the drift risk in real agent frameworks. The repo contains an older deterministic software-company SOP and a newer MGX/RoleZero path where a team leader LLM routes work to dynamic tool-using roles. That split is valuable: it exposes which parts should be deterministic in our lab runtime and which parts can stay model-driven.

## What It Is

MetaGPT is a Python multi-agent framework centered on `Team`, `Environment`, `Role`, `Action`, `Message`, `Plan`, and project repositories. Its original workflow maps a requirement through product manager, architect, project manager, engineer, and QA roles. The current CLI entrypoint still exposes software-company options, but by default hires an MGX-style team: `TeamLeader`, `ProductManager`, `Architect`, `Engineer2`, and `DataAnalyst`.

The base runtime is a message bus plus role loop. Roles maintain private receive buffers, short-term memory, watched action tags, current state, and current action. Actions produce `Message` objects whose `cause_by`, `sent_from`, `send_to`, and optional `instruct_content` drive routing and handoff. The DI/RoleZero layer adds dynamic planning, tool recommendation, command parsing, editor/browser/terminal tools, long-term memory, and experience reuse.

## Research Themes

- Token efficiency: Messages increasingly carry structured file references and `instruct_content` instead of full artifacts. `ProjectRepo` stores PRDs, designs, tasks, source files, summaries, tests, and dependency edges. `RoleZero` limits history with `memory_k`, summarizes on `end`, uses `Planner.get_useful_memories`, and can retrieve long-term memories only when recent memory exceeds capacity.
- Context control: Roles filter news by watched `cause_by` tags or explicit recipient names. `RoleContext` separates `memory`, `working_memory`, `msg_buffer`, `watch`, `news`, `todo`, and state. `Editor.read` refuses large files and points to `similarity_search`; code generation pulls only sibling files in task lists or dependency-linked files.
- Sub-agent / multi-agent: `Team` owns an environment of roles. `Environment.run` concurrently gathers non-idle role `run()` calls. `MGXEnv` routes normal traffic through `TeamLeader`, while fixed-SOP roles chain through action tags such as `WritePRD`, `WriteDesign`, `WriteTasks`, `WriteCode`, `SummarizeCode`, `WriteTest`, `RunCode`, and `DebugError`.
- Domain-specific workflow: Software-company artifacts are first-class repositories: requirement, PRD, competitive analysis, system design, sequence/data diagrams, task lists, code plan/change, code summaries, source, tests, and test outputs. The workflow is specialized for coding, incremental development, and bugfixes.
- Error prevention: `ActionNode` builds typed Pydantic output models, output repair handles malformed JSON/markers, `WriteCodeReview` can rewrite until LGTM, `QaEngineer` loops write-test/run-debug, `Editor` validates line/content pairs and can roll back syntax-breaking edits, and `RunCode` asks an LLM to route failures to engineer or QA.
- Self-learning / memory: Basic `Memory` indexes messages by `cause_by`. `RoleZeroLongTermMemory` can offload older messages to a RAG store and retrieve related memories. `exp_cache` can fetch/store experiences around LLM calls using BM25 or Chroma-backed storage.
- Popular skills: SOP-as-code, role-private message queues, action-causal routing, team-leader delegation, dynamic command tools, Pydantic structured outputs, artifact graph tracking, code review/rewrite, test/debug handoff, editor lint rollback, and optional experience retrieval.

## Core Execution Path

`metagpt "Create a 2048 game"` calls `generate_repo` in `metagpt/software_company.py`. It updates config, builds a `Context`, constructs a `Team`, hires `TeamLeader`, `ProductManager`, `Architect`, `Engineer2`, and `DataAnalyst`, sets budget with `invest`, and starts `Team.run`.

`Team` creates an `MGXEnv` by default. `Team.run_project` publishes the user requirement as a `Message`, then `Team.run` loops until rounds run out, budget is exceeded, or all roles are idle. Each round calls `env.run`, which schedules every non-idle role concurrently with `asyncio.gather`.

Base `Environment.publish_message` routes a `Message` to roles whose registered addresses match `send_to`, then records it in environment history. `MGXEnv.publish_message` changes that flow: regular messages are sent to the team leader, public chat can make messages visible to all, direct chat can bypass the team leader, and only messages published by the team leader's profile are released to intended members.

Base `Role.run` is observe, think, act, publish. `_observe` drains the role's private `MessageQueue`, keeps only new messages whose `cause_by` is in `watch` or whose `send_to` includes the role name, and writes them to memory. `_think` either picks the sole action, advances by fixed order, or asks the LLM to choose a state. `_act` runs the current action and wraps its output as an `AIMessage`. `publish_message` then hands it back to the environment.

`RoleZero` changes the role loop into a dynamic command runner. It always uses a dummy `RunCommand` action as the todo, builds plan status and tool schemas, asks the LLM for command JSON, parses commands, and executes mapped tools such as `Plan.append_task`, `Editor.*`, `Browser.*`, `Terminal.run_command`, `RoleZero.ask_human`, and role-specific functions. It can quick-answer simple user messages, continue observing during long reactions, and ask the human whether to continue after hitting `max_react_loop`.

The older fixed SOP remains useful as a deterministic reference. `ProductManager` writes PRD files, `Architect` writes system design, `ProjectManager` writes task lists, `Engineer` writes code and optional reviews, `SummarizeCode` triggers QA, and `QaEngineer` writes tests, runs them, and routes failures to either engineer or QA based on `RunCode` summary. However, the current CLI has the old `Engineer` and `QaEngineer` hiring code commented out, so `--code-review` and `--run-tests` do not wire that legacy QA loop in the default MGX team.

## Architecture

The core layering is clean. `Context` owns config, cost manager, and LLM factory. `Team` owns budget, idea, and environment. `Environment` owns roles, address map, history memory, and project archive. `Role` owns identity, actions, private runtime context, planner, memory, and LLM prefix. `Action` owns prompt execution and optional private model selection. `Message` is the shared envelope.

`Message` is the main contract. It has stable `id`, natural-language `content`, optional Pydantic `instruct_content`, OpenAI-style `role`, causal `cause_by`, sender `sent_from`, recipient set `send_to`, and metadata. The causal tag is serialized as a string derived from the action class, so agents can subscribe to semantic events rather than only role names.

`RoleContext` is the runtime state cell. It holds the environment pointer, async receive queue, persistent memory, working memory, numeric state, current todo action, watched action tags, observed news, react mode, and max react loop. This makes each role independently resumable and testable.

`Plan` and `Task` model task state. Tasks have ids, dependencies, instruction, type, code/result, success/finished flags, and assignee. `Plan.add_tasks` topologically sorts dependencies, merges common prefixes, and sets the current unfinished task. `reset_task` resets downstream dependents. `Planner` wraps plan generation, review, confirmation, task-result processing, and useful-memory construction.

`ProjectRepo` wraps a `GitRepository` plus `FileRepository` namespaces for docs, resources, source, tests, and test outputs. `FileRepository.save` can update dependency metadata through `DependencyFile`. Engineers and QA use this graph to find affected source files, test files, design docs, task docs, code summaries, and bugfix context.

Tooling is registry-based. `@register_tool` inspects class/function source, converts signatures and comments to schemas, and stores tools by name/tag. `ToolRecommender` validates requested tool names/tags/paths and can use BM25 recall plus LLM ranking. `RoleZero` then maps allowed command names to actual Python callables.

Memory exists at three levels: role-local `Memory`, `RoleZeroLongTermMemory` backed by RAG storage, and `exp_pool` experience cache around LLM calls. These are optional accelerators, not required for the base message bus.

## Design Choices

MetaGPT makes SOPs observable by turning every phase into an `Action` and every handoff into a `Message` caused by that action. This is better than direct role-to-role calls because the bus can route, log, replay, and filter events.

The role subscription model combines `watch` with address routing. A role can care about "messages caused by `WriteDesign`" regardless of sender, while also receiving direct messages by name. That maps well to Agentic Coding Lab triggers such as "review requested", "tests failed", "plan changed", or "file patched".

Artifact transfer shifted from in-message content to file references and structured payloads. This is a strong context-control pattern. The message says which artifacts changed; the recipient loads only what it needs from `ProjectRepo` and the dependency graph.

The newer MGX path centralizes delegation through `TeamLeader`. That gives a single place for user-facing coordination and role assignment, but it also makes routing model-dependent. For lab use, this should become a deterministic router with an optional LLM suggestion layer.

`RoleZero` treats tools as commands chosen in a loop, not as hardcoded actions. This is flexible for broad coding work, but weaker than a typed operation runner because command parsing, tool choice, and policy are largely prompt-mediated.

`ActionNode` builds schema-driven prompts and Pydantic output classes from node trees. This is a useful pattern for PRD/design/task artifacts where fields are known in advance. The repair layer helps non-OpenAI models, but it is still output repair after generation, not a guarantee of semantic correctness.

The code/test path deliberately separates implementation, review, summarization, test generation, test execution, and debug. The handoff can route failures to the role most likely responsible. That separation is worth copying, even if the prompts and default activation need hardening.

## Strengths

- Clear small core: `Team`, `Environment`, `Role`, `Action`, `Message`, `Memory`, and `Plan` are understandable and reusable.
- Role-private receive queues avoid one global memory becoming the transport layer.
- Causal action tags make routing more semantic than raw chat transcript scanning.
- `instruct_content` preserves structured handoff data alongside human-readable content.
- `ProjectRepo` plus dependency metadata gives a practical way to avoid stuffing PRD/design/task/code into every prompt.
- Fixed SOP roles show a concrete software pipeline with PRD, design, tasks, code, review, summaries, tests, run logs, and debug feedback.
- `Editor` has several strong agent-edit safeguards: line/content mismatch checks, exact-window feedback, syntax-lint rollback, and "do not rerun same failed edit" guidance.
- `Plan` supports dependency ordering, task replacement, downstream reset, and current-task tracking.
- `RoleZero` demonstrates dynamic tool maps, role-specific tools, command exclusivity, quick response classification, and human escalation.
- Long-term memory and experience cache are optional modules, so the base agent loop can run without vector infrastructure.

## Weaknesses

- Tool permission boundaries are weak. `Terminal.run_command` only blocks small string patterns such as `run dev` and `serve`, while editor, terminal, deployer, git, browser, and arbitrary registered tools need host-side allowlists, workspace guards, timeouts, and audit policy before reuse.
- `Editor._try_fix_path` accepts absolute paths and only prepends the working directory for relative paths. It is an editing UX tool, not a sandbox boundary.
- `RunCode` auto-installs `requirements.txt` and `pytest` before running tests. That is non-hermetic and unsafe for untrusted projects unless dependency installation is isolated and approved.
- `TeamLeader` is an LLM-controlled router. Bad routing, missing constraints, or prompt injection can send incomplete or unsafe instructions to teammates.
- Current CLI flags are misleading. `code_review`, `run_tests`, and `implement` exist in `generate_repo`, but the legacy engineer/QA wiring is commented out in the default path.
- Local tests for core orchestration are thin. Some software-company tests invoke the CLI without assertions; broader behavior depends on live LLMs, providers, browser/terminal state, or skipped tests.
- Error prevention often relies on another LLM pass: code review, run-result classification, debug rewriting, plan review, and output repair. There is less deterministic validation than the artifact model suggests.
- `Plan.reset_task` has an open implementation risk noted in source comments: cyclic dependencies can recurse forever. Plan generation needs explicit cycle detection before adoption.
- Message routing uses stringified class names and role names. Refactors, duplicate names, or stale serialized action strings can break subscriptions.
- Serialization covers many Pydantic fields, but live tool state such as terminal process, browser state, and editor cursor is not a robust resumability contract.

## Ideas To Steal

Use `Message`-like envelopes with `id`, `content`, structured payload, `cause_by`, `sent_from`, `send_to`, and metadata. Make action cause tags first-class event types.

Give every subagent a private receive queue and explicit watch list. The shared environment should route messages; role memory should not double as transport.

Represent coding workflow artifacts as repository files with dependency edges. Send changed artifact references through messages, then let recipients load only necessary docs/code/tests.

Keep a deterministic SOP path for high-stakes coding phases: plan, implement, review, test, run, debug. Let LLMs fill phase content, but keep phase transitions host-controlled where possible.

Adopt planner task primitives: topological order, current task pointer, task result, finish/reset/replace/append, and downstream invalidation. Add cycle checks and schema validation.

Use an editor tool that rejects ambiguous edits. Require line numbers plus expected line contents, show before/after windows, and roll back syntax-breaking edits.

Split tool exposure into registry, recommender, and execution map. Tool selection can be dynamic, but the executable map should be explicit per role.

Use a team-leader pattern only as an orchestration surface. For Agentic Coding Lab, pair it with deterministic routing rules, policy checks, and traceable delegation records.

Use long-term memory and experience caches as optional context providers, not hidden global state. Every retrieved memory or experience should be visible in the trace.

## Do Not Copy

Do not expose broad terminal/editor/deployer/git tools without a real sandbox, cwd policy, path policy, command allowlist, network/dependency policy, timeouts, and approval gates.

Do not make an LLM team leader the only router. Routing should be validated against role capabilities, current task state, and allowed transitions.

Do not keep stale CLI options that do not affect runtime behavior. It creates false assurance around review/test coverage.

Do not auto-install dependencies during verification by default. Separate dependency resolution from test execution and make it explicit.

Do not treat LLM code review or LLM run-log classification as sufficient verification. Pair them with concrete tests, linters, type checks, execution status, and captured outputs.

Do not rely on output repair as a substitute for strict parsing and typed execution contracts. Repair should be logged and bounded.

Do not use path-only artifact handoffs without provenance. A lab runtime should attach artifact id, version/commit, dependency edge, producer action, and validation state.

Do not leave plan-cycle handling to comments. Task graphs need deterministic validation before agents can mutate execution state.

## Fit For Agentic Coding Lab

High fit as a pattern source, not as a drop-in runtime. The strongest reusable pieces are the event envelope, role-private queues, watched action tags, artifact-backed project repo, dependency-aware incremental context, and separated code/review/test/debug phases.

Agentic Coding Lab should preserve the SOP discipline but invert some responsibility. The host runtime should own routing constraints, permissions, artifact versions, task graph validity, verification commands, and trace evidence. LLM roles should produce proposals, patches, reviews, summaries, and debugging hypotheses inside those boundaries.

A practical lab artifact could be a small "SOP bus" inspired by MetaGPT: typed events, role subscriptions, task graph, artifact store, deterministic phase transitions, and pluggable role prompts. A second artifact could be a hardened editor/terminal tool layer with MetaGPT-style edit diagnostics but stronger workspace and command policy.

## Reviewed Paths

- `README.md`, `docs/tutorial/usage.md`, `docs/ACADEMIC_WORK.md`, `docs/FAQ-EN.md`: project positioning, current CLI usage, software-company claim, Data Interpreter references, and known limitations.
- `metagpt/software_company.py`: CLI entrypoint, default hired roles, current MGX team composition, and commented legacy engineer/QA path.
- `metagpt/team.py`: team construction, environment selection, hiring, budget check, project start, run loop, serialization, and archive behavior.
- `metagpt/environment/base_env.py` and `metagpt/environment/mgx/mgx_env.py`: message routing, role registration, public/direct chat, team-leader mediation, history, and external environment API decorators.
- `metagpt/roles/role.py`: base role runtime, `RoleContext`, memory/watch filtering, react modes, publish/put message behavior, think/act loop, and exported think/act APIs.
- `metagpt/schema.py`: `Message`, `MessageQueue`, `Plan`, `Task`, `TaskResult`, documents, serialization helpers, and structured payload serialization.
- `metagpt/memory/memory.py`, `metagpt/memory/role_zero_memory.py`, `metagpt/memory/longterm_memory.py`: short-term memory, action index, long-term RAG memory, and recovery behavior.
- `metagpt/roles/di/role_zero.py`, `team_leader.py`, `engineer2.py`, and `data_analyst.py`: dynamic command loop, quick thinking, team delegation, tool maps, planner integration, terminal/editor/browser tools, code generation, and data-code execution.
- `metagpt/roles/product_manager.py`, `architect.py`, `project_manager.py`, `engineer.py`, and `qa_engineer.py`: fixed SOP role definitions, watches, actions, code/review/summarize/test/run/debug handoffs, and legacy QA loop.
- `metagpt/actions/action.py`, `action_node.py`, `write_prd.py`, `design_api.py`, `project_management_an.py`, `write_code.py`, `write_code_review.py`, `write_test.py`, `run_code.py`, `debug_error.py`, and `actions/di/write_plan.py`: action base class, structured output nodes, artifact writers, code generation, review/rewrite, test generation, execution, debugging, and dynamic planning.
- `metagpt/utils/project_repo.py`, `file_repository.py`, `git_repository.py`, and dependency utilities by reference: artifact namespaces, changed-file detection, save/delete, dependency updates, archive, and git-backed project state.
- `metagpt/tools/tool_registry.py`, `tool_recommend.py`, `tools/libs/editor.py`, `tools/libs/terminal.py`, and `tools/libs/linter.py`: tool schema generation, tool validation/recommendation, editor operations, terminal execution, and lint rollback.
- `metagpt/strategy/planner.py`, `strategy/task_type.py`, and `exp_pool/*`: plan state, review flow, task-type guidance, experience cache, and retrieval manager.
- `tests/metagpt/test_team.py`, `test_environment.py`, `test_role.py`, `test_software_company.py`, `tests/metagpt/tools/libs/test_editor.py`, and adjacent action/memory tests by path scan: available local coverage and gaps.

## Excluded Paths

- `examples/**` except for path inventory: demo scripts, benchmark demos, notebooks, UI demos, generated sample data, and showcase workflows. They were excluded unless runtime behavior was already represented in core modules.
- `examples/ui_with_chainlit/**`, website-like assets, images, screenshots, static public files, and frontend-only demo UI: useful for demos, not core multi-agent orchestration.
- `docs/resources/**`, generated workspace PDFs/SVGs/JPEGs, media, and binary sample files: documentation artifacts or generated outputs, not runtime behavior.
- `metagpt/ext/aflow/**`, `metagpt/ext/sela/**`, `metagpt/ext/spo/**`, and related examples: separate research/workflow optimization modules outside the requested software-company subagent review.
- `metagpt/ext/stanford_town/**`, `ext/werewolf/**`, `ext/android_assistant/**`, `environment/minecraft/**`, and domain game/mobile simulations: domain-specific agent environments, not reusable coding-lab core except as examples of external env adapters.
- `metagpt/environment/minecraft/mineflayer/mineflayer-collectblock/**`: vendored third-party JavaScript/TypeScript dependency.
- Provider implementations under `metagpt/provider/**` beyond the `Context` boundary: model API adapters, not multi-agent orchestration logic.
- RAG/document-store internals beyond memory and experience manager integration points: retrieval backends were treated as external storage boundaries.
- `tests/data/**`, generated fixtures, binary fixtures, and serialized demo projects: test assets rather than source runtime.
- Packaging/build/config files such as lockfiles, Dockerfile, setup metadata, `ruff.toml`, and generated tool schemas: operational metadata, not agent behavior.
