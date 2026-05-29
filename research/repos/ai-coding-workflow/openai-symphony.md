# openai/symphony

- URL: https://github.com/openai/symphony
- Category: ai-coding-workflow
- Stars snapshot: 24,802 stars, 2,464 forks from GitHub REST API on 2026-05-29
- Reviewed commit: f577cb5a1e971f04ebcfcdd06e72e722ab4b2ebe
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong candidate for autonomous coding-run orchestration patterns. Symphony is most useful as a reference for issue-driven dispatch, per-ticket workspaces, Codex app-server supervision, retry/reconciliation loops, blocked-run surfacing, and workflow-as-repo-policy. Do not copy its current high-trust defaults or raw Linear tool breadth without a tighter deployment-specific security envelope.

## Why It Matters

Symphony is a direct answer to a problem most coding-agent workflows eventually hit: the unit of work should be the ticket, not the chat session. It continuously polls a tracker, claims eligible issues, creates deterministic isolated workspaces, launches a coding agent inside each workspace, monitors progress, retries failures, and releases or cleans up work based on tracker state.

For Agentic Coding Lab, the reusable pattern is the separation between work management and agent execution. Symphony keeps the orchestrator responsible for scheduling, claims, workspace lifecycle, retries, and status, while the agent and repo-local `WORKFLOW.md` are responsible for task semantics, ticket updates, PR creation, validation, and handoff. That boundary is valuable because it lets teams improve agent prompts and skills without rewriting the scheduler.

The repo is also useful because it is both a language-agnostic spec and an Elixir/OTP reference implementation. The spec captures portable invariants, while the implementation demonstrates where the hard edges show up: app-server protocol handling, non-interactive approval behavior, workspace path containment, dynamic tracker tools, SSH workers, dashboard state, and live end-to-end testing.

## What It Is

Symphony is an engineering-preview service for isolated autonomous implementation runs. The root `SPEC.md` defines a language-neutral service that reads work from Linear, creates one workspace per issue, launches Codex in app-server mode, and supervises the run until the issue leaves active workflow states or needs a retry.

The `elixir/` directory contains the current reference implementation. It is an OTP application with a `WorkflowStore`, `Orchestrator`, task supervisor, workspace manager, Linear tracker adapter, Codex app-server client, optional SSH worker support, terminal status output, and optional Phoenix LiveView/JSON observability server.

The repository also includes `.codex/skills` used by the workflow prompt: `linear`, `pull`, `push`, `commit`, `land`, and `debug`. These skills encode reusable coding-agent runbooks for Linear workpad updates, branch synchronization, PR creation, review handling, landing, and log triage. Symphony itself schedules and supervises; these repo-local instructions tell the agent how to execute the ticket.

## Research Themes

- Token efficiency: Symphony does not implement context compression directly. Its token story is operational: it keeps the full issue prompt in `WORKFLOW.md`, then uses same-thread continuation turns with short continuation guidance instead of resending the full prompt. It also tracks input/output/total token counters and rate-limit snapshots for runtime observability.
- Context control: Context is assembled from a strict Liquid-compatible prompt template with only normalized `issue` and `attempt` variables. Unknown variables and filters fail. `WORKFLOW.md` is the repo-owned contract for prompt, tracker, hooks, agent limits, and Codex settings, and reloads without restart for future runs.
- Sub-agent / multi-agent: Symphony is not a subagent framework inside one model turn. It is a multi-run orchestrator: bounded concurrent issue workers, per-state limits, optional SSH worker pools, host capacity selection, per-issue claims, retry queues, and separate Codex app-server sessions.
- Domain-specific workflow: The domain is issue-to-PR coding work. The sample workflow covers Linear states, a persistent `## Codex Workpad` comment, branch and PR handling, feedback sweeps, validation gates, and a merge flow routed through the `land` skill.
- Error prevention: Core protections include single-authority orchestrator state, dispatch revalidation before launch, deterministic workspace path sanitization, cwd/root containment checks, terminal/non-active reconciliation, hook timeouts, strict prompt rendering, app-server read/turn/stall timeouts, unsupported dynamic tool failure responses, and retry backoff.
- Self-learning / memory: There is no long-term learning or persistent scheduler database. Recovery is tracker-driven and filesystem-driven: preserved workspaces can be reused after restart, but retry timers, running sessions, blocked state, and exact runtime state are in memory only.
- Popular skills: The repo-local skills are not popularity-ranked, but they are highly relevant workflow artifacts. `linear` centralizes raw Linear GraphQL usage, `pull` and `push` encode safe branch/PR mechanics, `land` codifies review/check monitoring, and `debug` teaches log correlation with issue and session identifiers.

## Core Execution Path

Startup runs through the Elixir application supervisor. It configures file logging, starts PubSub, `Task.Supervisor`, `WorkflowStore`, `Orchestrator`, optional `HttpServer`, and `StatusDashboard`. The CLI requires an explicit guardrail acknowledgement before starting, accepts an optional `WORKFLOW.md` path, `--logs-root`, and optional `--port` for the dashboard/API.

`WorkflowStore` loads `WORKFLOW.md`, caches the last known good workflow, and polls file stamps every second. `Config.Schema` turns YAML front matter into typed settings with defaults, `$VAR` resolution for configured secret/path fields, safer Codex default policy values, hook timeout defaults, tracker settings, worker SSH settings, and server/observability settings. Invalid reloads are logged while the last good workflow remains active.

The `Orchestrator` owns scheduling state. On each tick it refreshes runtime config, reconciles running and blocked issues, validates dispatch config, fetches candidate tracker issues, sorts by priority then age then identifier, checks claims and concurrency, revalidates each issue by ID, and dispatches eligible issues to `AgentRunner` tasks. Running, claimed, blocked, retry attempts, token totals, and rate limits live in one GenServer state.

`AgentRunner` creates or reuses a workspace, runs `before_run`, starts a Codex app-server session in that workspace, builds the first prompt from `WORKFLOW.md`, streams app-server updates back to the orchestrator, and refreshes tracker state after each completed turn. If the issue remains active and `agent.max_turns` is not exhausted, it sends a short continuation prompt to the same live Codex thread. `after_run` runs in an `after` block and is best effort.

`Codex.AppServer` launches `bash -lc <codex.command>` locally or over SSH, initializes app-server, starts a thread with approval/sandbox/dynamic-tool settings, starts turns with cwd/title/prompt/sandbox policy, buffers newline-delimited protocol messages, emits structured runtime events, handles dynamic `linear_graphql` calls, and converts approval or input-required situations according to the configured policy.

On normal worker exit, the orchestrator schedules a short continuation retry so it can re-check whether the issue is still active. On abnormal exit, timeout, stall, or spawn failure, it schedules exponential backoff capped by `agent.max_retry_backoff_ms`. On tracker reconciliation, terminal states stop the worker and clean the workspace; non-active states stop the worker without cleanup; active states refresh in-memory issue snapshots.

## Architecture

The architecture is intentionally layered:

- Root `SPEC.md`: language-neutral service contract, reference algorithms, conformance matrix, failure model, and security posture.
- `elixir/lib/symphony_elixir/workflow*.ex`: workflow file discovery, YAML front matter parsing, last-good reload cache, and prompt body access.
- `elixir/lib/symphony_elixir/config*.ex`: typed runtime config, defaults, validation, env indirection, and runtime Codex sandbox policy resolution.
- `elixir/lib/symphony_elixir/orchestrator.ex`: poll loop, claims, retries, blocked state, reconciliation, SSH host selection, snapshots, token/rate-limit aggregation.
- `elixir/lib/symphony_elixir/agent_runner.ex`: one issue run attempt, workspace hook boundaries, app-server session lifecycle, max-turn continuation loop.
- `elixir/lib/symphony_elixir/workspace.ex` and `path_safety.ex`: deterministic workspace path creation, local/remote hook execution, cleanup, symlink/canonicalization guards.
- `elixir/lib/symphony_elixir/codex/app_server.ex`: Codex app-server JSON-RPC/stdin-stdout client, approval/user-input handling, dynamic tool dispatch, protocol logging.
- `elixir/lib/symphony_elixir/linear/*.ex` and `tracker/*.ex`: tracker abstraction, Linear GraphQL queries, issue normalization, blocker/label/assignee routing, write helpers.
- `elixir/lib/symphony_elixir_web/*` and `status_dashboard.ex`: optional human-readable and JSON observability surfaces.
- `.codex/skills/*`: repo-local implementation workflow policies consumed by the agent running inside Symphony.

## Design Choices

The strongest design choice is making `WORKFLOW.md` the versioned repo contract. It contains both runtime settings and the prompt body, so poll cadence, tracker scope, workspace hooks, agent limits, Codex command/policies, and ticket execution rules can evolve with the target codebase rather than living in a separate control plane.

The second strong choice is single-authority orchestration. The orchestrator owns `running`, `claimed`, `blocked`, and `retry_attempts`, and all worker lifecycle events flow back to it. This avoids duplicate dispatch without requiring a persistent database, and it gives the status surfaces one coherent runtime snapshot.

The third choice is preserving workspaces rather than resetting them. Existing per-issue directories are reused so continuation and retry runs can resume from local progress. Terminal cleanup and explicit workspace removal handle the stale-state case. This is a good fit for coding agents because in-progress local changes are often the most important handoff context.

The fourth choice is treating tracker writes as an agent/workflow concern. Symphony reads and reconciles the tracker, but ticket comments, state transitions, PR attachments, and review handling are mainly delegated to the prompt and `linear_graphql` tool. That keeps the orchestrator general, but also means correctness depends heavily on the workflow prompt and skills.

The riskiest design choice is high-trust configurability. The example workflow uses `approval_policy: never`, broad inherited shell environment, workspace hooks as arbitrary shell, and a raw Linear GraphQL tool. The implementation now has safer defaults and CLI acknowledgement, but the architecture still assumes a trusted deployment unless the operator tightens sandbox, credentials, network, issue filters, and tool scope.

## Strengths

Symphony directly targets unattended implementation runs. It has concrete machinery for claims, dispatch ordering, per-state and global concurrency, retries, stall recovery, terminal cleanup, and operator-visible blocked sessions.

Workspace safety is treated as a first-order invariant. Local workspaces are sanitized from issue identifiers, canonicalized, checked against the configured root, guarded against symlink escape, and used as Codex cwd for thread and turn startup. The same checks are present in both workspace creation and app-server launch paths.

The Codex app-server client handles the annoying parts that a scheduler has to get right: startup handshake, separate thread and turn IDs, session IDs, partial JSON line buffering, stderr/noise handling, dynamic tool replies, approval/input-required events, token/rate-limit extraction, turn timeouts, and process exit mapping.

The retry model is practical for autonomous work. Clean exits get short continuation checks, crashes get exponential backoff, stale retry candidates release claims, slot exhaustion requeues with an explicit reason, and stalled sessions are killed rather than left invisible.

Observability is better than a raw daemon log. The orchestrator exposes snapshots with running/retrying/blocked rows, workspace path, worker host, session ID, last Codex event/message, token counters, rate limits, and polling status. The terminal dashboard and optional Phoenix dashboard/API share the same projection.

The test suite encodes operational behavior, not just pure functions. Tests cover config parsing, workflow reload, workspace hooks and symlink guards, Linear normalization, dispatch sorting, blocker handling, app-server protocol behavior, approvals, dynamic tools, token accounting, status rendering, SSH workers, CLI guardrails, and optional live Linear/Codex end-to-end runs.

## Weaknesses

The current reference implementation is explicitly a prototype. It is useful as a pattern source, but the README and CLI warn that it is an engineering preview, and the Elixir README recommends implementing a hardened version rather than treating this as supported production software.

Scheduler state is in memory only. Restart recovery is useful but partial: active tracker issues can be redispatched and existing workspaces reused, but blocked entries, retry timers, live sessions, and exact runtime metadata are lost. A restart can therefore re-run still-active work unless the workflow and tracker state prevent it.

The `linear_graphql` tool is powerful. It reuses Symphony's configured Linear auth and allows raw GraphQL queries/mutations. The skill narrows usage behaviorally, but the implementation does not enforce project-scoped operations or single-operation GraphQL parsing despite the spec recommending stricter validation.

Branch orchestration is mostly delegated to prompt and skills. The workflow prompt instructs the agent to use pull/push/land skills and manage PRs, but the orchestrator itself does not own git branch creation, PR linkage, CI proof, or merge readiness. This is flexible, but it means the scheduler cannot independently prove that a claimed issue reached a safe handoff state.

Remote worker support improves scaling but widens the safety surface. Local path canonicalization is strong; remote workspaces necessarily rely more on shell quoting, SSH behavior, remote filesystem expectations, and host-local workspace semantics. The spec correctly calls out environment drift and locality risks.

Dynamic reload is pragmatic but not total. `WorkflowStore` reloads settings and the orchestrator refreshes key runtime fields, but in-flight sessions are not restarted, optional extension resources may require restart, and some policy changes only affect future dispatches, hooks, or app-server launches.

## Ideas To Steal

Use a repo-owned workflow file that combines scheduler config and agent prompt template. Keep it versioned with the target codebase so task routing, validation expectations, handoff rules, and runtime limits change together.

Make the orchestrator a single scheduling authority with explicit `claimed`, `running`, `retrying`, and `blocked` sets. Do not let workers independently decide whether they own the same ticket.

Create deterministic per-issue workspaces and preserve them across retries. Use sanitized identifiers, root containment checks, and terminal cleanup rather than sharing one working tree across concurrent agents.

Separate first-turn prompts from continuation turns. The first turn should render full issue context; later turns in the same thread should send compact continuation guidance and rely on existing thread/workspace state.

Treat tracker state as a control plane. Poll active states for dispatch, re-check issue state before launch, reconcile running tasks every tick, stop work when a ticket leaves active states, and clean workspaces only for terminal states.

Surface blocked sessions as a first-class runtime state. Approval requests, user-input-required turns, and MCP elicitations should not vanish into retries or stalls; operators need issue ID, workspace, session ID, last event, and error.

Build observability around the agent protocol, not only process status. Token totals, rate-limit snapshots, last app-server event, app-server PID, turn count, retry due time, and worker host are all useful when supervising many unattended runs.

Codify branch/PR/review/merge behavior as reusable skills. Symphony's `pull`, `push`, `land`, `linear`, and `debug` skills are strong examples of moving operational policy into agent-readable artifacts that can be invoked from the workflow prompt.

Add a real integration profile that creates disposable tracker work and runs a real agent turn. Unit tests prove protocol handling; live tests prove auth, tracker, workspace, app-server, and dynamic tool paths still compose.

## Do Not Copy

Do not copy the high-trust sample policy into a less trusted environment. `approval_policy: never`, inherited shell environment, broad Linear GraphQL auth, and arbitrary hooks require a dedicated sandbox and credential boundary.

Do not rely on workspace isolation as the whole security model. It prevents accidental cwd/root mistakes, but it does not defend against malicious issue text, repository content, network exfiltration, over-broad credentials, or dangerous hook scripts.

Do not expose a raw tracker mutation tool without authorization constraints. A lab adaptation should scope issue/project/team access, validate allowed operations, and log mutation intent separately from generic GraphQL transport success.

Do not make restart recovery ambiguous. If blocked state and retry queues matter, persist them or make restart semantics explicit in operator docs and dashboards.

Do not bury branch creation and CI proof entirely in prose if the orchestrator needs compliance guarantees. Prompt/skill delegation is flexible, but critical gates may deserve machine-readable state or tracker annotations.

Do not copy the UI surface before the runtime contracts. The dashboard is useful, but the reusable foundation is the snapshot schema, issue/session identifiers, event summaries, and retry/block state transitions.

## Fit For Agentic Coding Lab

Fit is high for the AI coding workflow track. Symphony is not a generic model client; it is a workflow layer above a coding agent that coordinates independent implementation runs. It directly covers the requested themes: isolated autonomous runs, workspace orchestration, task supervision, context handoff through preserved workspaces and continuation prompts, permissions policy, verification expectations, and reusable runbook skills.

The best adaptation path is to extract the scheduler contract and tighten the safety envelope:

1. Define a small orchestrator state model for `unclaimed`, `running`, `retrying`, `blocked`, and `released`.
2. Use a versioned workflow file with strict prompt rendering and typed config.
3. Require per-ticket workspace roots with symlink/root containment checks.
4. Add a durable status snapshot and blocked-run state.
5. Keep branch/PR/review skills as separate reusable artifacts, but make critical completion evidence machine-readable.
6. Scope tracker tools and credentials to the smallest project/team boundary needed.

Symphony should be referenced as a design source for orchestration and supervision, not as a complete production answer. The key lesson is that autonomous coding-agent work needs an external run manager with claims, isolation, retries, reconciliation, and observability; the agent prompt alone is not enough.

## Reviewed Paths

- `README.md`: project goal, engineering-preview warning, harness-engineering positioning, run options.
- `SPEC.md`: language-neutral architecture, workflow schema, state machine, scheduling, workspace safety, app-server protocol contract, observability, failure model, security guidance, SSH extension, validation matrix.
- `docs/symphony-smoke-test-one.md`: repository smoke-test artifact created by a Symphony run.
- `elixir/README.md`: reference implementation overview, setup, workflow config, safer defaults, dashboard/API, tests, live E2E profile.
- `elixir/WORKFLOW.md`: sample production-style workflow prompt, Linear states, workspace hooks, high-trust Codex settings, workpad process, PR feedback sweep, blocked-access escape hatch, validation and merge rules.
- `elixir/AGENTS.md`: implementation-specific contributor rules, workspace safety reminders, spec alignment, validation commands, PR requirements.
- `elixir/mix.exs`, `elixir/Makefile`, `elixir/mise.toml`: dependencies, build/test/lint/dialyzer gates, escript entry point.
- `elixir/lib/symphony_elixir.ex`: OTP application supervision tree.
- `elixir/lib/symphony_elixir/cli.ex`: CLI workflow path handling, logs/port flags, guardrail acknowledgement, process lifecycle.
- `elixir/lib/symphony_elixir/workflow.ex`, `workflow_store.ex`: workflow discovery, parsing, prompt extraction, last-known-good reload loop.
- `elixir/lib/symphony_elixir/config.ex`, `config/schema.ex`: config schema, defaults, validation, env indirection, sandbox policy resolution.
- `elixir/lib/symphony_elixir/orchestrator.ex`: scheduler state, polling, dispatch, retry, reconciliation, blocked state, snapshots, worker host selection, token/rate-limit aggregation.
- `elixir/lib/symphony_elixir/agent_runner.ex`: workspace + hook + Codex session execution, continuation turn loop, state refresh.
- `elixir/lib/symphony_elixir/workspace.ex`, `path_safety.ex`: local/remote workspace lifecycle, hook execution, cleanup, symlink and root containment.
- `elixir/lib/symphony_elixir/codex/app_server.ex`, `codex/dynamic_tool.ex`: app-server JSON stream client, approval handling, input-required handling, dynamic `linear_graphql` tool.
- `elixir/lib/symphony_elixir/linear/client.ex`, `linear/adapter.ex`, `linear/issue.ex`, `tracker.ex`, `tracker/memory.ex`: tracker boundary, Linear GraphQL queries/mutations, issue normalization, memory test adapter.
- `elixir/lib/symphony_elixir/ssh.ex`: SSH-backed worker command and port launching.
- `elixir/lib/symphony_elixir/status_dashboard.ex`, `http_server.ex`, `symphony_elixir_web/**`: terminal dashboard, Phoenix dashboard, JSON API, presenter state projections.
- `elixir/lib/mix/tasks/*.ex`, `symphony_elixir/specs_check.ex`: local quality gates for public specs, PR body checks, workspace cleanup task.
- `elixir/test/symphony_elixir/*.exs`, `elixir/test/mix/tasks/*.exs`, `elixir/test/support/**`: unit, integration-style, snapshot, SSH, dynamic tool, CLI, observability, and optional live E2E coverage.
- `.codex/worktree_init.sh`: worktree setup helper for the Elixir implementation.
- `.codex/skills/commit/SKILL.md`, `pull/SKILL.md`, `push/SKILL.md`, `land/SKILL.md`, `linear/SKILL.md`, `debug/SKILL.md`: reusable agent workflow runbooks for commits, branch sync, PR publishing, merge supervision, Linear GraphQL, and log debugging.
- GitHub REST API response for repository metadata on 2026-05-29.

## Excluded Paths

- `.git/**`: local clone metadata; not relevant to the source review.
- `.github/media/**`: screenshots and demo poster assets; useful for presentation only, not workflow architecture.
- `.github/workflows/**`: sampled only through repository/test context; not deeply reviewed because the requested focus was runtime orchestration rather than GitHub Actions implementation.
- `LICENSE`, `NOTICE`, `mix.lock`: checked for context but excluded from design conclusions.
- `elixir/test/fixtures/status_dashboard_snapshots/**`: generated or golden display outputs; useful for tests but not primary architecture.
- Phoenix static assets and layout boilerplate under `elixir/lib/symphony_elixir_web/components/**` and `static_assets.ex`: UI support code, not core orchestration.
- Dependency source code was not vendored in the checkout and was not reviewed.
- Live external services were not exercised during this source review; the live E2E test code was reviewed as evidence of intended validation behavior.
