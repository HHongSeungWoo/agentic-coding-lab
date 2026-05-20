# cft0808/edict

- URL: https://github.com/cft0808/edict
- Category: subagents-multiagents
- Stars snapshot: 15,823 via GitHub REST API on 2026-05-20
- Reviewed commit: 14a207557719c046af0f993a7bff1cc5a5015b33
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: in-scope
- Verdict: High-signal OpenClaw orchestration reference for role-specialized agents, visible task state, flow/progress audit trails, scheduler recovery, and prompt/context layering. Do not copy as a production control plane without tightening the split JSON/Postgres modes, enforcing permissions outside prompts, adding real sandbox policy, wiring durable audit consistently, and fixing backend dispatch/retry edge cases.

## Why It Matters

Edict is directly relevant to subagent and multi-agent coding support because it is not just a role-prompt pack. It installs named OpenClaw agents, gives each agent a separate workspace and SOUL prompt, writes an `allowAgents` graph into OpenClaw config, forces task state through a visible board, and records `flow_log`, `progress_log`, todos, scheduler metadata, and OpenClaw session activity.

The useful idea is institutional orchestration: Taizi triages input, Zhongshu plans, Menxia reviews and can reject, Shangshu dispatches, and execution departments do domain work. That maps well to coding-agent workflows where planning, review, implementation, testing, infrastructure, and documentation should not all happen inside one unconstrained prompt.

## What It Is

Edict is an OpenClaw-based multi-agent system with two runtime tracks.

The current local/dashboard path is JSON-backed. `install.sh` creates OpenClaw workspaces, deploys SOUL prompts, registers agents, symlinks each workspace's `data` and `scripts` back to the project, and starts a stdlib Python dashboard API over `data/tasks_source.json`. Agents update tasks through `scripts/kanban_update.py`, and the dashboard dispatches to OpenClaw with `openclaw agent --agent <id>`.

The newer `edict/backend` path is a FastAPI/Postgres/Redis architecture. It models tasks in SQLAlchemy, writes transactional outbox events, relays them to Redis Streams, consumes state events in an orchestrator worker, and runs a dispatch worker that enriches OpenClaw calls with SOUL prompts, task context, memory, and skills.

The project also ships React frontend code, a demo Docker image with static data, screenshots, docs, and platform install wrappers. Those are useful around the runtime, but the orchestration contract lives in `agents/`, `agents.json`, `scripts/`, `dashboard/server.py`, and `edict/backend/app`.

## Research Themes

- Token efficiency: Moderate. Agents receive narrow role prompts and the backend dispatch worker injects only recent flow entries, recent progress entries, relevant memory, and matched skills. There is no token budgeter, compactor, or transcript pruning policy beyond fixed recent-log slices and skill selection by manifest tags/orgs.
- Context control: Stronger than most prompt packs. Context is layered as global rules, group rules, agent SOUL, task card, recent flow/progress, memory, relevant skills, and dynamic reminders. JSON mode also merges OpenClaw session JSONL into activity views. The weak point is provenance and trust: upstream agent output, memory, remote skills, and task text are mostly prompt-separated, not typed as trusted/untrusted data.
- Sub-agent / multi-agent: Strong pattern source. The repo defines specialist agents for triage, planning, review, dispatch, data, documentation, engineering, compliance/testing, infrastructure, HR/agent admin, and daily news. OpenClaw `allowAgents` encodes the call graph, and the task state machine encodes where work should go next.
- Domain-specific workflow: Strong. The "three departments and six ministries" workflow is a concrete governance model: plan -> mandatory review -> dispatch -> execution -> review/done. Agent prompts include explicit obligations, expected CLI commands, review rounds, rejection behavior, and progress reporting.
- Error prevention: Good local controls, incomplete enforcement. The JSON CLI validates titles, blocks invalid state transitions, adds high-risk `PendingConfirm`, rejects premature `done` when todos are incomplete, caps progress logs, locks JSON writes, records audit entries, and has scheduler retry/escalation/rollback. Backend workers add Redis ACK, pending recovery, dead-letter topics, and timeouts. But many controls are prompt-level or dashboard-local, and the backend has several edge cases.
- Self-learning / memory: Explicit but simple. `kanban_update.py` supports global shared memory, per-agent memory, and per-task decision-chain memory. The backend dispatch worker injects global rules, top relevant agent memories, and full task memory chains. Memory is JSON-file based, not embedded, deduplicated, privacy-scoped, or versioned.
- Popular skills: Role-specific SOUL prompts, OpenClaw workspace generation, per-agent subagent allowlists, task-state Kanban control, flow/progress/todo audit trails, scheduler retry/escalation/rollback, session JSONL activity fusion, remote skill install/update, model hot-switching, Redis Streams workers, transactional outbox, and prompt-injection pattern detection.

## Core Execution Path

In the JSON/OpenClaw path, `install.sh` checks OpenClaw, backs up existing workspaces, creates `workspace-<agent>` directories, writes SOUL prompts, registers each agent in `openclaw.json`, sets `tools.sessions.visibility all`, symlinks every workspace's `data` and `scripts` to the project, syncs agent config, and starts the dashboard plus refresh loop.

Task creation can happen through the dashboard API or by an agent calling `scripts/kanban_update.py create`. The canonical task record is `data/tasks_source.json`. Agents are instructed to update it only through the CLI. `kanban_update.py` sanitizes titles/remarks, infers the current agent from environment or workspace path, checks command permissions, loads the backend task state machine as the canonical transition table, updates task state/todos/progress, appends audit records to `data/audit_log.json`, and triggers live-data refresh.

The visible workflow is `Pending/Taizi -> Zhongshu -> Menxia -> Assigned -> Doing/Next -> Review -> Done`, with `Blocked`, `Cancelled`, and `PendingConfirm` as control states. Dashboard `handle_create_task`, `handle_review_action`, and `handle_advance_state` mutate tasks and call `dispatch_for_state`. Dispatch maps state or org to an agent id, marks scheduler status as queued, checks the OpenClaw gateway, resolves the OpenClaw binary, builds a state-specific message, runs `openclaw agent --agent <agent> -m <msg> --timeout 300`, and records success, failure, timeout, missing binary, or gateway-offline in scheduler metadata and flow logs.

The dashboard scheduler scans stalled tasks. It retries current-state dispatch, escalates to Menxia then Shangshu, rolls back to a saved snapshot, and eventually blocks tasks after repeated failed rollback. Startup recovery re-dispatches tasks whose last dispatch was left queued.

For observability, `get_task_activity` merges `flow_log`, `progress_log`, todo snapshots, resource fields, phase durations, and OpenClaw session JSONL entries. It parses assistant messages, thinking snippets, tool calls, user messages, and tool results, then deduplicates and sorts them into one task timeline.

In the Postgres/Redis path, `TaskService.create_task` creates a task and outbox event in one transaction. `OutboxRelay` locks unpublished events, publishes them to Redis Streams, and marks them published. `OrchestratorWorker` consumes task-created/status/completed/stalled topics, recovers stale pending messages, dispatches next agents, and emits stalled/retry/escalation events. `DispatchWorker` consumes `task.dispatch`, adds SOUL/context/memory/skills/reminders, calls OpenClaw, emits heartbeats and agent output, ACKs success, leaves retryable failures unacked for redelivery, and publishes stalled/dead-letter events when retries are exhausted.

## Architecture

The root architecture is file-centric and OpenClaw-centric. `agents.json` and `install.sh` define the agent graph. `agents/GLOBAL.md`, `agents/groups/*.md`, and `agents/<id>/SOUL.md` define behavior. `scripts/kanban_update.py` is the primary agent-facing API. `dashboard/server.py` is the human control plane and local HTTP API. `scripts/sync_agent_config.py`, `sync_from_openclaw_runtime.py`, `refresh_live_data.py`, `apply_model_changes.py`, and `skill_manager.py` keep dashboard state synchronized with OpenClaw workspaces and configuration.

The newer backend architecture is service-centric. `edict/backend/app/models/task.py` defines `TaskState`, `STATE_TRANSITIONS`, state/org/agent maps, and a task table that preserves legacy dashboard fields. `models/outbox.py` implements the transactional outbox table. `models/audit.py` defines an audit-log table, but I did not find service or worker code writing `AuditLog` in this commit. `services/event_bus.py` wraps Redis Streams and Pub/Sub. `workers/orchestrator_worker.py`, `dispatch_worker.py`, and `outbox_relay.py` are the durable worker layer.

The two architectures are not one coherent runtime yet. `kanban_update.py` explicitly says JSON mode and backend mode are independent and not automatically synchronized. The root Dockerfile runs the dashboard/demo JSON path. `edict/docker-compose.yml` runs Postgres, Redis, backend, orchestrator, dispatcher, and frontend, but that stack is separate from the root JSON dashboard flow.

## Design Choices

Edict encodes multi-agent governance as both role prompts and task state. This is stronger than a free-form group chat: the system has a mandatory review stage, explicit rejection path, dispatch stage, and final review/done gate.

The project uses OpenClaw as the actual agent runtime and keeps its own orchestration state outside OpenClaw. That makes the dashboard auditable and recoverable even when OpenClaw sessions are noisy or incomplete.

Agent-facing writes go through a CLI instead of direct JSON edits. This creates one place for title cleanup, state transition validation, permission checks, audit entries, memory writes, todo gates, and file locking.

The backend tries to move from daemon threads to durable streams. Redis Streams consumer groups, `XAUTOCLAIM`, transactional outbox, and dead-letter topics are the right primitives for recovering dispatch after process death.

Memory is deliberately layered. Shared memory affects all agents, agent memory carries role experience, task memory carries upstream decisions, and relevant skills are loaded lazily. This is a useful context-control pattern even though storage and trust boundaries are still primitive.

The dashboard treats intervention as a normal workflow action. Stop, cancel, resume, manual advance, scheduler retry, escalation, rollback, model change, agent wake, and skill install are all exposed as control-plane actions rather than hidden prompt behavior.

## Strengths

- Clear specialized-agent taxonomy with separate workspaces, SOUL prompts, models, skills, and allowed subagent edges.
- Mandatory Menxia review and rejection loop gives a concrete quality gate before execution.
- `kanban_update.py` is a strong local control surface: state machine validation, high-risk confirmation, todo completion gate, title/remark sanitization, command permission checks, audit append, and atomic JSON writes.
- `flow_log`, `progress_log`, todos, scheduler fields, audit log, session JSONL parsing, and phase durations create a better audit trail than raw chat transcripts alone.
- Scheduler recovery is practical: queued dispatch recovery, retry, escalation, rollback, and blocked state all map to observable task changes.
- Backend outbox plus Redis Streams is the right direction for reliable multi-worker dispatch.
- DispatchWorker's context assembly is reusable: role prompt, task card, recent logs, memory, skills, and reminders are assembled in a deterministic order.
- Prompt-injection detection on agent output is basic but shows the right instinct: treat upstream agent text as something to inspect, not blindly trust.
- Tests cover several high-value regressions: state-machine consistency, file locking, dispatch missing-binary status, review completion gates, task mutation races, skill URL path traversal, and skill-manager defaults.
- Remote skill and model configuration are integrated with per-agent workspaces, which is useful for experimenting with agent specialization.

## Weaknesses

- JSON mode and Postgres/Redis mode are split. They share concepts but not a single source of runtime truth, so adoption can drift into two different systems.
- The backend audit table is only a model in reviewed code. JSON mode writes `data/audit_log.json`, while backend service methods append `flow_log` and outbox events but do not write `AuditLog`.
- OpenClaw `allowAgents` is configured, but the repo's own enforcement is uneven. CLI command permissions exist, while docs describe `can_dispatch_to` checks that I did not find implemented in runtime code.
- Many dashboard mutation paths still use `load_tasks()` plus `save_tasks()` rather than `modify_task(s)`. Tests explicitly keep backward compatibility for those paths, but this leaves race risk outside the scheduler-critical paths.
- Backend dispatch deduplicates in-flight work by `task_id` only. That can suppress legitimate parallel dispatches to multiple execution agents for the same task; a safer key would include agent or subtask.
- Backend orchestrator handles `Assigned` specially but does not dispatch `Doing` or `Next` through `ORG_AGENT_MAP`; the JSON dashboard does. That mismatch can strand execution in the newer stack.
- `OutboxRelay` sends a dead-letter event after max attempts but does not mark the original outbox row as terminal in reviewed code, so a permanently failing outbox event can be retried and dead-lettered repeatedly.
- `TaskService.add_progress`, `update_todos`, and `update_scheduler` do not use row locks like `transition_state`, so JSONB append/update races are still possible in the backend.
- Dashboard auth is optional and disabled until `data/auth.json` exists. The root Docker demo binds `0.0.0.0:7891`; without auth setup, powerful local APIs can be exposed.
- FastAPI backend has permissive CORS and no visible auth middleware in reviewed `main.py`/task routes. It should be treated as a local/dev service until protected.
- `GET /api/task-output/<id>` validates only the task id, then reads whatever path is stored in `task.output`. If an attacker can create or mutate a task, this is an arbitrary local file read through the dashboard API.
- Remote skills are capability injection. The code blocks unsafe `file://` roots and only fetches HTTPS URLs, but it allows arbitrary HTTPS hosts and installs prompt/tool text into agent workspaces.
- Sandbox/permissions are mostly inherited from OpenClaw and the OS. Dispatch workers run `openclaw agent` subprocesses with broad environment and project cwd; there is no repo-scoped filesystem policy, command allowlist, network policy, or approval gate in this repo.
- Some tests appear stale against current semantics. For example, the older e2e kanban test still expects `cmd_done` to set `Done` directly, while current `cmd_done` routes execution output to `Review` and rejects non-Doing/Next states.

## Ideas To Steal

Use a mandatory review agent as architecture, not a nice-to-have prompt. The Menxia rejection loop is a good pattern for coding workflows where a plan should be reviewed before tools modify files.

Make task state first-class and visible. A coding lab could use `Planning`, `PlanReview`, `Implementation`, `Verification`, `Review`, `Done`, `Blocked`, and `NeedsHuman` states with legal transitions and a visible audit log.

Give agents a CLI/API for state updates instead of letting them hand-edit shared files. Put sanitization, state validation, audit, memory, and todo gates behind that interface.

Layer prompts and context deterministically: global rules, group rules, agent role, task card, recent flow, recent progress, task memory, relevant skills, and reminders. This is a better context contract than one large conversation transcript.

Record progress separately from state transitions. `flow_log` says where the task moved; `progress_log` says what the agent believed and did while there. Both are needed for debugging agent failures.

Keep scheduler recovery explicit. Retry, escalate, rollback, and block are more useful than only rerunning the same agent forever.

Use transactional outbox plus stream ACKs when moving beyond local files. This is a good way to avoid daemon-thread dispatch loss and DB/event dual-write bugs.

Treat remote skills as per-agent capabilities with source metadata and checksums. Add stronger review/approval before installation, but keep the per-agent specialization mechanism.

Parse runtime session logs into the task timeline. Tool calls, tool outputs, and assistant thoughts are valuable audit evidence when connected back to a task id.

## Do Not Copy

Do not copy the split runtime as-is. Pick JSON/local or Postgres/Redis/service mode as the source of truth, then make the other a compatibility adapter.

Do not rely on OpenClaw `allowAgents` and prompts as the full permission model. Add host-side checks for who can dispatch to whom, who can mutate which state, and which tools/commands/files are allowed.

Do not expose dashboard or backend APIs without authentication and local-network assumptions made explicit. Model switching, remote skill install, task output reads, agent wake, and task mutation are powerful operations.

Do not let task output paths become arbitrary file reads. Output artifacts should be under allowed roots or referenced by artifact ids.

Do not use task-id-only in-flight suppression when parallel execution is a design goal. Key concurrency by task plus target agent or subtask.

Do not treat a dead-letter publish as terminal unless the source row is marked terminal. Otherwise the relay can keep producing duplicate dead letters.

Do not install remote skills from arbitrary HTTPS URLs without provenance policy, review, pinning, and rollback. A skill is executable behavioral supply chain, even when it is "just Markdown."

Do not treat JSON file locks as a complete concurrency story if other HTTP paths still use load/save snapshots.

Do not present prompt-injection regex warnings as a security boundary. Use untrusted-context wrappers, tool permission checks, and typed data boundaries.

## Fit For Agentic Coding Lab

Fit is high as a pattern source and conditional as a component source. Edict is one of the better reviewed candidates for showing how a coding support system can combine specialized agents, explicit task state, review gates, visible progress, and intervention controls.

The best reusable artifacts are the state-machine-backed task board, agent-facing update CLI, role/group/global prompt hierarchy, review/rejection loop, flow/progress/todo audit model, scheduler recovery pattern, and context assembly in the dispatch worker.

The missing production pieces are enforceable permissions, a single durable runtime, artifact-scoped file access, authenticated APIs, stronger remote-skill provenance, robust worker idempotency, and verification gates that run tests or check artifacts instead of trusting agent summaries.

For Agentic Coding Lab, Edict should inspire a "governed coding workflow": planner, plan reviewer, implementer, test/verifier, security reviewer, and final summarizer, all tied to typed state transitions and audit events. It should not be adopted wholesale until the backend and dashboard converge and the safety model moves from prompt/CLI convention to host-enforced policy.

## Reviewed Paths

- `README.md`, `README_EN.md` by spot reference, and `docs/task-dispatch-architecture.md`: project purpose, OpenClaw dependency, role model, state flow, dashboard behavior, scheduler design, permissions claims, and documented architecture.
- `edict_agent_architecture.md`: planned event-driven architecture, event schemas, thought/todo schemas, replay, and intervention concepts.
- `agents.json`: sanitized OpenClaw agent/workspace graph and `subagents.allowAgents` matrix.
- `agents/GLOBAL.md`, `agents/groups/sansheng.md`, `agents/groups/liubu.md`, `agents/taizi/SOUL.md` by inventory, `agents/zhongshu/SOUL.md`, `agents/menxia/SOUL.md`, `agents/shangshu/SOUL.md`, and representative execution-agent SOUL files by pattern: role responsibilities, CLI contracts, review loop, progress requirements, delegation expectations, and safety rules.
- `install.sh`, `start.sh`, `Dockerfile`, `docker-compose.yml`, and `edict/docker-compose.yml`: workspace creation, OpenClaw config mutation, symlink strategy, startup path, demo deployment, and backend worker stack.
- `scripts/kanban_update.py`: agent-facing task update CLI, state transition loading, permission checks, high-risk confirmation, audit log, progress/todo handling, memory, delegation, sanitization, and file-lock use.
- `scripts/file_lock.py`: JSON read/update/write locking and atomic rename behavior.
- `scripts/sync_agent_config.py`, `scripts/sync_from_openclaw_runtime.py`, `scripts/apply_model_changes.py`, and `scripts/skill_manager.py` by source/behavior: OpenClaw config sync, runtime session mapping, model hot-switching, script/SOUL deployment, skills inventory, and remote skill management.
- `dashboard/server.py`: dashboard API, auth checks, task creation/actions/review/advance, dispatch, scheduler retry/escalation/rollback, session JSONL activity fusion, remote skill endpoints, model endpoints, notification validation, task output reading, and static serving.
- `dashboard/auth.py`: optional stdlib token auth, password setup, cookie/header token extraction, and public path rules.
- `dashboard/court_discuss.py` by scope check: separate multi-role discussion feature, not core task dispatch.
- `edict/backend/app/models/task.py`, `audit.py`, `outbox.py`, `thought.py`, and `todo.py`: backend task state, legacy field compatibility, audit schema, outbox schema, thought/todo data model.
- `edict/backend/app/services/event_bus.py` and `task_service.py`: Redis Streams wrapper, Pub/Sub mirror, consumer groups, stale claim, task CRUD, state transition row locks, outbox writes, progress/todo/scheduler updates.
- `edict/backend/app/workers/orchestrator_worker.py`, `dispatch_worker.py`, and `outbox_relay.py`: event routing, stalled-task handling, dispatch prompt/context/memory/skill assembly, OpenClaw subprocess call, ACK/retry/dead-letter behavior, and relay loop.
- `edict/backend/app/api/tasks.py`, `main.py`, `config.py`, and channel validators under `edict/backend/app/channels/`: API shape, CORS/auth posture, settings, notification webhook boundaries.
- Tests: `tests/test_state_machine_consistency.py`, `test_task_mutation_race.py`, `test_file_lock.py`, `test_kanban.py`, `test_e2e_kanban.py`, `test_dashboard_dispatch.py`, `test_dashboard_review_action.py`, `test_cwe22_file_url.py`, `test_skill_manager.py`, `test_sync_agent_config.py`, and `test_server.py`.

## Excluded Paths

- Generated/demo/runtime data: `data/**`, `docker/demo_data/**` except config-shape spot checks, `docs/screenshots/**`, `docs/demo.gif`, `docs/*.mp4`, generated live/status JSON, local OpenClaw session files, and benchmark/demo outputs. These are artifacts, not core orchestration contracts.
- UI-only code: `edict/frontend/**`, `dashboard/dashboard.html`, CSS/layout details, screenshots, and React component presentation were excluded except where API expectations affected runtime behavior.
- Marketing, article, and localized docs: `docs/wechat*.md`, `docs/design-*.md`, `README_JA.md`, `WINDOWS_INSTALL_CN.md`, and social/media docs were excluded except for install/config facts already represented in source.
- Platform wrapper duplication: `install.ps1`, `scripts/run_loop.ps1`, Windows-specific docs, and systemd wrapper details were not deep-reviewed after the Unix install/start paths established the runtime contract.
- Binary/media assets: images, GIFs, videos, QR codes, screenshots, and icons were excluded.
- External/vendor systems: OpenClaw internals, Redis, Postgres, FastAPI, SQLAlchemy, React, Vite, Docker base images, notification providers, remote skill sources, and provider/model APIs were treated as boundaries; I reviewed Edict call sites and configuration, not upstream source.
- Unrelated feature panels: morning news fetching, visual ceremony, template UI, and court discussion presentation were only skimmed where they touched agent routing, notification channels, or task state. The note focuses on OpenClaw orchestration, task state, audit, permissions, memory/context, verification, sandbox, and error handling.
