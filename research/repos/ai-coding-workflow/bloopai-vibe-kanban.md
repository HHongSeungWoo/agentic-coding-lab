# BloopAI/vibe-kanban

- URL: https://github.com/BloopAI/vibe-kanban
- Category: ai-coding-workflow
- Stars snapshot: 26,578 (GitHub REST API, captured 2026-05-29)
- Reviewed commit: 4deb7eca8f381f7cbc1f9d15515a9ab8f8009053
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong source of reusable patterns for coding-agent task state, workspace/session/process modeling, worktree isolation, approval mediation, review loops, MCP orchestration, and kanban-driven status automation. It is less useful as a dependency candidate because the upstream README says Vibe Kanban is sunsetting, and several production-critical states remain best-effort or in-memory.

## Why It Matters

Vibe Kanban is one of the clearest open-source examples of a coding-agent workflow product that treats agent work as a first-class task lifecycle instead of a single chat transcript. It connects a kanban board, issue planning, per-task workspaces, branch/worktree management, coding-agent sessions, process logs, approvals, diffs, PRs, and merge/archive flows into one runtime model.

For Agentic Coding Lab, the value is not the UI. The useful material is the state machine underneath it: a task can have a workspace, a workspace can have one or more repos and sessions, a session can have ordered execution processes, a coding-agent turn can carry agent session/message IDs, and remote issue status can be derived from workflow events. That gives concrete examples for multi-run coordination, context handoff, and restart/reset semantics.

The repo also matters as a cautionary reference. The application is broad, but some coordination state is intentionally local, transient, or best-effort. Queued follow-ups and pending approvals live in memory, remote sync tolerates failure, and verification is built from setup/cleanup/review/dev-server conventions rather than a universal pass/fail contract.

## What It Is

Vibe Kanban is a Rust/Tauri-style local and remote application for managing coding-agent workspaces from a kanban board. The reviewed repo contains a Rust workspace with backend services, SQLite models, git/worktree managers, executor integrations, remote issue/workspace sync, MCP tools, and web frontend packages.

The user-facing workflow is:

1. Create or import a task/issue.
2. Start a workspace from a base branch and one or more repos.
3. Choose an executor profile such as Claude Code, Codex, Gemini CLI, Copilot, Amp, Cursor, OpenCode, Droid, CCR, or Qwen.
4. Run setup scripts, the coding agent, cleanup scripts, dev servers, review prompts, and follow-up prompts while streaming logs and diffs.
5. Review changes, create or attach a PR, merge locally or through the host, and archive or keep the workspace.

The README also states that Vibe Kanban is sunsetting. That makes the repo a pattern source and review target, not a stable product bet.

## Research Themes

- Token efficiency: Moderate. The repo does not present a general token-budgeting layer, but it keeps large workflow state outside model context in SQLite rows, JSONL process logs, git refs, remote issue records, and workspace files. MCP issue/workspace tools let agents query scoped state instead of pasting a full board into chat. Workspace-level `AGENTS.md` and `CLAUDE.md` files import per-repo instructions by path, which avoids duplicating repo guidance in every prompt.
- Context control: Strong. Workspaces, sessions, execution processes, coding-agent turns, process logs, scratch state, attachments, and repo target branches are modeled separately. Follow-ups reuse stored agent session IDs where an executor supports continuity. Reset can restore repo heads to a process boundary and soft-drop later process history. Review mode builds a focused diff prompt from fork-point/base context instead of handing the agent the entire workspace.
- Sub-agent / multi-agent: Conditional. The system supports multiple agent executors, multiple sessions per workspace, queued follow-ups, review sessions, and an MCP orchestrator mode that can create sessions and run prompts. It is not a swarm framework. The most reusable multi-agent pattern is scoped orchestration: the MCP server detects the current workspace from the working directory, exposes only workspace/session tools in orchestrator mode, and refuses to run a prompt inside the orchestrator's own session.
- Domain-specific workflow: High. The domain is coding-agent work. It has task statuses, workspace creation, setup/cleanup/dev-server scripts, live logs, approvals, review comments, PR creation, merge/archive flows, branch rename/rebase conflict handling, remote issue links, and status sync from coding activity.
- Error prevention: Strong but uneven. The backend checks for running processes before new runs, guards direct merge cases, refuses remote direct merges, validates branch rename and target branches, rolls back multi-repo branch rename failures, stores before/after commits per execution, uses per-path worktree locks, and routes tool approvals through executor-specific bridges. Gaps remain around in-memory queues/approvals, dangerous executor modes, best-effort remote sync, and lack of mandatory verification gates.
- Self-learning / memory: Low as adaptive memory, strong as durable operational memory. The repo stores workspace/session/process/turn state, PR links, remote workspace stats, scratch drafts, issue relationships, and raw logs, but it does not curate long-term lessons or automatically update reusable agent memory.
- Popular skills: No skill telemetry was present. The closest reusable capability packages are executor profiles, setup/cleanup scripts, remote issue/MCP tools, workspace config-file generation, and review-prompt generation.

## Core Execution Path

The central runtime path starts when a task creates a workspace. `crates/server/src/routes/workspaces/create.rs` validates the request, generates a workspace branch from the container service, creates a workspace row, attaches repo rows with target branches, copies remote issue attachments into `.vibe-attachments`, rewrites `attachment://` markdown references, and calls `ContainerService::start_workspace`.

`crates/services/src/services/container.rs` is the main orchestrator. `start_workspace` creates the physical container/worktrees, creates a session, discovers setup scripts, and builds a chain of `ExecutorAction`s. If all repos mark setup scripts as parallel, setup can fan out; otherwise setup actions run sequentially before the coding-agent action. Cleanup is chained after the coding-agent action.

`start_execution` captures each repo's pre-run HEAD, creates an `execution_process` row, creates a coding-agent turn for prompt-carrying actions, starts raw and normalized log capture, unarchives the workspace for non-archive work, and asks the deployment implementation to spawn the process. `try_start_next_action` advances setup, coding, cleanup, and archive actions. Finalization stores after-HEAD repo states, marks completion/failure/killed status, commits uncommitted changes after successful coding or cleanup, consumes a queued follow-up if one exists, and emits live update events.

Follow-up and review routes reuse the same process model. `crates/server/src/routes/sessions/mod.rs` ensures the workspace exists, enforces executor continuity for a session, optionally resets to an earlier process boundary, reuses stored agent session info, and starts a follow-up action. `crates/server/src/routes/sessions/review.rs` computes review context from changed files and commits, creates a review prompt, and runs it as another coding-agent process.

The closeout path runs through git/PR routes. Branch status reports ahead/behind, rebase/conflict state, uncommitted changes, PR links, and merge records. PR creation pushes workspace branches and records host PR metadata. Direct merge uses squash semantics with safety checks, syncs linked remote issue status, and archives unpinned workspaces.

## Architecture

The repo is organized around a Rust backend plus web packages:

- `crates/db`: SQLite migrations and models for tasks, workspaces, workspace repos, sessions, execution processes, coding-agent turns, PRs, merges, scratch state, and remote/local links.
- `crates/services`: orchestration services for containers, queued messages, execution logs, approvals, events, remote sync, and executor process lifecycle.
- `crates/local-deployment`: local implementation that creates workspaces, writes agent config files, spawns executors, injects environment variables, monitors process exits, commits changes, runs cleanup/archive behavior, and performs periodic workspace cleanup.
- `crates/workspace-manager` and `crates/worktree-manager`: physical workspace and git worktree creation, migration, locking, cleanup, deletion, and orphan cleanup.
- `crates/git` and `git-host`: low-level branch, commit, rebase, merge, remote, PR, and provider operations.
- `crates/executors`: executor profiles and command builders for supported coding agents, including permission-policy mapping and approval hooks.
- `crates/server`: HTTP/WebSocket routes for workspaces, sessions, execution logs, diffs, approvals, PRs, merges, rebase handling, and branch management.
- `crates/remote`: remote issue/workspace API and database used for kanban status, project metadata, issue relationships, and local workspace links.
- `crates/mcp`: local MCP server exposing project, issue, workspace, and session operations to external agents.
- `packages/*`: frontend and shared UI/type packages. These were reviewed only where they exposed runtime API or workflow behavior.

The data model has a useful separation of concerns. A `Workspace` is the durable unit of task execution and branch/worktree isolation. A `Session` is an agent conversation lane inside a workspace. An `ExecutionProcess` is one spawned setup, cleanup, dev-server, archive, review, or coding-agent process. A `CodingAgentTurn` stores prompt, summary, agent session ID, and agent message ID for continuity.

## Design Choices

Vibe Kanban uses git worktrees as the isolation boundary. Each workspace has a generated branch and one or more repo worktrees. Multi-repo workspaces track target branch per repo through `workspace_repos`, and execution processes record before/after commits per repo through `execution_process_repo_states`.

The system favors durable database state for workflow history and ephemeral memory for live coordination. Workspace/session/process rows, turn metadata, branch state, PR links, raw logs, and remote issue links survive process restart. Queued follow-ups and approval waiters do not.

Executor integration is normalized through `ExecutorAction` chains. Setup scripts, cleanup scripts, archive scripts, dev servers, initial prompts, follow-ups, and reviews all become process records with a run reason, status, timestamps, normalized logs, raw logs, and optional next action. That makes the workflow inspectable even when the actual agent is an external CLI.

Permissions are executor-specific. Codex maps policy to sandbox and approval settings, Claude uses hooks and permission prompts, and Gemini/Qwen/OpenCode integrations use the same approval bridge shape. Unsupported or less interactive actions fall back to no-op approvals.

Kanban state follows runtime signals. Starting a workspace can move linked remote issues into progress, opening a PR can move them into review, and merge completion can move them to done if linked PRs are merged. The local task model still exists, but the richer board behavior lives in remote issue/workspace sync.

The MCP server is intentionally local and scoped. Global mode can operate across projects and workspaces. Orchestrator mode is derived from the current working directory, restricts tools to the current workspace, removes list/delete workspace operations, and prevents an orchestrator session from running a prompt against itself.

## Strengths

- Clear task/workspace/session/process/turn model that maps well to real coding-agent operations.
- Worktree-first isolation with multi-repo target branches, before/after commit tracking, reset-to-process, cleanup, orphan cleanup, and branch lifecycle handling.
- Strong process observability through raw JSONL logs, normalized log streams, live events, execution status, and workspace status derivation.
- Practical executor abstraction that keeps CLI-specific command construction, session continuity, model/variant settings, and permission policies behind profile types.
- Review and closeout flows are integrated with diffs, PR creation, PR attachment, merge safety checks, rebase conflict detection, branch rename, and archive semantics.
- MCP tools expose the workflow to agents without requiring agents to scrape the UI or manually infer workspace context.

## Weaknesses

- The repo is sunsetting, so long-term upstream maintenance is uncertain.
- Queued follow-ups are an in-memory `DashMap` with one queued message per session; they are useful for UX but not a durable scheduler.
- Approval waiters and pending approval notifications are in memory. Restart or process loss can break live approval state even though process history is durable.
- Verification is conventional rather than enforced. Setup, cleanup, dev-server, review, and PR flows exist, but there is no generic required test result object or merge gate.
- Some status automation depends on configured remote status names such as "In progress", "In review", and "Done"; remote sync failures are treated as best effort in several paths.
- Dangerous executor permission modes exist, and unsupported executors can run with no-op approval mediation.
- MCP `get_execution` exposes structured execution status but currently returns `final_message: None`, limiting direct agent handoff through that tool.

## Ideas To Steal

- Model coding-agent work as `workspace -> session -> execution_process -> coding_agent_turn` rather than as one chat log.
- Store before/after git commits per execution and use them for reset, review context, diff inspection, and process provenance.
- Generate workspace-level `AGENTS.md` and `CLAUDE.md` files that import per-repo instruction files for multi-repo context handoff.
- Treat setup, cleanup, review, archive, dev-server, and coding-agent prompts as the same observable process primitive with different run reasons.
- Use scoped MCP mode based on the current working directory so an agent can manage its own workspace without receiving global destructive tools.
- Sync kanban status from actual workflow signals: workspace start, PR open, PR merge, local merge, and archive.
- Keep branch rename and multi-repo operations transactional enough to roll back partial success.
- Separate raw logs from normalized log views so UI and agents can replay or reinterpret process output later.

## Do Not Copy

- Do not copy transient queued-message or approval storage if restart-safe automation is required.
- Do not make verification only a script convention if a lab harness needs enforceable pass/fail gates.
- Do not depend on string-matched board status names without a typed status contract or migration plan.
- Do not expose full-access executor modes without project-level policy, auditability, and explicit user approval.
- Do not treat the frontend board as the source of truth; the durable state model and git/process records are the important pieces.
- Do not rely on best-effort remote sync as the only record of issue or PR lifecycle.
- Do not adopt the whole product surface while the upstream project is sunsetting; extract patterns behind smaller local interfaces.

## Fit For Agentic Coding Lab

Fit is high as a workflow and state-model reference. The repo directly covers the lab's target concerns: coding-agent task state, kanban orchestration, multi-run coordination, workspaces/branches, executor permissions, review/verification hooks, context handoff, and MCP-mediated control.

The best adoption path is selective:

- Use the workspace/session/process/turn model as a durable state baseline.
- Use worktrees and per-execution commit snapshots for isolation and reset.
- Add a stricter verification result schema around setup, tests, cleanup, review, and merge readiness.
- Make queues, approvals, and orchestration requests durable before using them for unattended multi-agent work.
- Keep MCP scoped by workspace and role, with explicit denial for recursive self-invocation.
- Convert kanban transitions from name-based convenience into typed workflow events.

The repo should be cited as a rich operational design reference, not copied wholesale as a maintained platform.

## Reviewed Paths

- `/tmp/myagents-research/bloopai-vibe-kanban/README.md`: product scope, supported agents, usage, feature list, sunsetting notice, and environment controls.
- `/tmp/myagents-research/bloopai-vibe-kanban/docs/core-features/creating-tasks.mdx`: task creation, create-and-start workflow, agent/profile/base-branch choices, and kanban status movement.
- `/tmp/myagents-research/bloopai-vibe-kanban/docs/core-features/new-task-attempts.mdx`: task-attempt/session concept, fresh starts, context reset, and subtask linkage.
- `/tmp/myagents-research/bloopai-vibe-kanban/docs/core-features/monitoring-task-execution.mdx`: worktree creation, setup scripts, agent execution, streaming logs, approvals, cleanup script behavior, and commit-message source.
- `/tmp/myagents-research/bloopai-vibe-kanban/docs/core-features/testing-your-application.mdx`: dev-server script, embedded preview, dev logs, and DOM/component context handoff.
- `/tmp/myagents-research/bloopai-vibe-kanban/docs/core-features/reviewing-code-changes.mdx`: diff review comments, review submission, and task status transition back to in-progress.
- `/tmp/myagents-research/bloopai-vibe-kanban/docs/core-features/subtasks.mdx`: subtask relationship to task attempts and inherited branch behavior.
- `/tmp/myagents-research/bloopai-vibe-kanban/docs/core-features/resolving-rebase-conflicts.mdx`: rebase conflict banner, agent-generated conflict instructions, manual editor path, abort, and continue.
- `/tmp/myagents-research/bloopai-vibe-kanban/docs/integrations/vibe-kanban-mcp-server.mdx`: local MCP server, issue/workspace/session tools, and planning-agent workflow.
- `/tmp/myagents-research/bloopai-vibe-kanban/docs/supported-coding-agents.mdx`: supported executor surface.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/db/src/models/workspace.rs`: workspace state, status derivation, cleanup eligibility, context loading, and first-message extraction.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/db/src/models/workspace_repo.rs`: workspace/repo target branch state and child target-branch propagation.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/db/src/models/session.rs`: session state, executor binding, working-directory resolution, and orchestrator-session selection.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/db/src/models/execution_process.rs`: process status, run reasons, action chains, reset/drop semantics, and before/after repo state.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/db/src/models/coding_agent_turn.rs`: prompt, summary, unseen state, and agent session/message ID continuity.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/db/src/models/task.rs`: legacy/local task status and parent workspace field.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/db/migrations/20250617183714_init.sql`: original task/task-attempt/activity schema.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/db/migrations/20251209000000_add_project_repositories.sql`: multi-repo project/workspace schema and execution repo states.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/db/migrations/20251216142123_refactor_task_attempts_to_workspaces_sessions.sql`: task-attempt to workspace/session/process refactor.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/db/migrations/20251120000001_refactor_to_scratch.sql`: scratch-state refactor.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/server/src/routes/workspaces/create.rs`: workspace creation, remote issue attachment import, branch generation, and start flow.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/server/src/routes/workspaces/git.rs`: branch status, direct merge, target branch changes, branch rename rollback, and rebase conflict routes.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/server/src/routes/workspaces/pr.rs`: PR creation, attaching existing PRs, PR checkout workspaces, and PR sync.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/server/src/routes/workspaces/links.rs`: local/remote workspace link and sync behavior.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/server/src/routes/sessions/mod.rs`: follow-up execution, reset-to-process, executor continuity, setup rerun, and scratch clearing.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/server/src/routes/sessions/queue.rs`: queued follow-up API.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/server/src/routes/sessions/review.rs`: review prompt creation and review execution.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/server/src/routes/execution_processes.rs`: raw and normalized log streams and replay behavior.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/server/src/routes/approvals.rs`: approval response API and notification stream.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/services/src/services/container.rs`: main workspace/session/process orchestration, action chaining, reset, and finalization logic.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/services/src/services/queued_message.rs`: in-memory queued-message service.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/services/src/services/execution_process.rs`: raw log storage, fallback log loading, and session/message ID extraction.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/services/src/services/events.rs`: live update event service.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/services/src/services/events/streams.rs`: initial snapshots and JSON patch streams.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/services/src/services/approvals.rs`: pending approval storage, timeout/cancellation behavior, and response validation.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/services/src/services/approvals/executor_approvals.rs`: executor approval bridge.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/services/src/services/remote_sync.rs`: best-effort remote issue, PR, and workspace stat sync.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/services/src/services/remote_client.rs`: remote API client surface used by sync and routes.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/local-deployment/src/container.rs`: local worktree/container creation, config-file generation, executor spawn, approval bridge selection, exit monitor, auto-commit, cleanup, and archive behavior.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/workspace-manager/src/workspace_manager.rs`: physical workspace creation, migration, deletion cleanup, and orphan cleanup.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/worktree-manager/src/worktree_manager.rs`: per-path worktree locks, branch/worktree creation, robust cleanup, and prune behavior.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/git/src/lib.rs`: commit, merge, branch status, rebase, remote, and conflict handling.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/git/tests/git_workflow.rs`: git workflow safety and behavior tests.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/git/tests/git_ops_safety.rs`: git operation safety tests.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/executors/src/profile.rs`: executor config, variants, models, and permission policy.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/executors/src/actions/mod.rs`: executor action chain and working-directory handling.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/executors/src/executors/codex.rs`: Codex sandbox and approval-policy mapping.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/executors/src/executors/claude.rs`: Claude plan mode, approval hooks, and permission prompts.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/remote/src/routes/issues.rs`: remote issue CRUD, status transitions, tags, relationships, and PR links.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/remote/src/db/issues.rs`: remote issue persistence and query behavior.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/remote/src/routes/workspaces.rs`: remote workspace links and stats routes.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/remote/src/db/workspaces.rs`: remote workspace persistence.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/api-types/src/issue.rs`: issue and status API types.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/mcp/src/bin/vibe_kanban_mcp.rs`: MCP server modes, port/base URL discovery, and orchestrator CLI behavior.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/mcp/src/task_server/mod.rs`: workspace-context detection and MCP server construction.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/mcp/src/task_server/tools/mod.rs`: global versus orchestrator tool routing and scope guard.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/mcp/src/task_server/tools/task_attempts.rs`: MCP workspace creation/start flow.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/mcp/src/task_server/tools/sessions.rs`: MCP session creation, prompt execution, and execution lookup.
- `/tmp/myagents-research/bloopai-vibe-kanban/crates/mcp/src/task_server/tools/remote_issues.rs`: MCP remote issue operations, tag expansion, and context defaults.
- `https://api.github.com/repos/BloopAI/vibe-kanban`: repository metadata and star snapshot.

## Excluded Paths

- `/tmp/myagents-research/bloopai-vibe-kanban/.git/`: VCS internals; only HEAD commit and branch metadata were needed.
- `/tmp/myagents-research/bloopai-vibe-kanban/node_modules/`, `/tmp/myagents-research/bloopai-vibe-kanban/target/`, and build caches: generated dependency/build output was not reviewed.
- `/tmp/myagents-research/bloopai-vibe-kanban/packages/*/dist`, `packages/*/.next`, and generated frontend output paths: generated artifacts, not workflow source.
- `/tmp/myagents-research/bloopai-vibe-kanban/shared/types.ts` and generated schema/type outputs: useful for API consumers, but generated from backend contracts and not reviewed as design source.
- `/tmp/myagents-research/bloopai-vibe-kanban/docs/**/*.png`, `docs/**/*.jpg`, `docs/**/*.gif`, and other static media: illustrative docs assets, not runtime behavior.
- `/tmp/myagents-research/bloopai-vibe-kanban/packages/ui/**`, `packages/local-web/src/**`, `packages/remote-web/src/**`, and `packages/web-core/src/**` UI-only components: excluded unless they revealed backend API or workflow behavior; the research target was orchestration/runtime design.
- `/tmp/myagents-research/bloopai-vibe-kanban/package-lock.json`, `pnpm-lock.yaml`, `Cargo.lock`, and other lockfiles: dependency reproducibility metadata, not agent workflow design.
- `/tmp/myagents-research/bloopai-vibe-kanban/LICENSE`, branding assets, icons, and favicon files: legal/static metadata, not workflow behavior.
