# paperclipai/paperclip

- URL: https://github.com/paperclipai/paperclip
- Category: agent-support-systems
- Stars snapshot: 64,250 (GitHub REST API, captured 2026-05-11; from local research index)
- Reviewed commit: 563413ecd44de22c6756bbdd1cb3ed08b4f9aed6
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: conditional
- Verdict: Strong reference for agent control-plane design: wake queues, issue locks, run identity, adapter boundaries, scoped context, and recovery are directly useful. It is not a drop-in coding-agent support layer because the full product is a large autonomous-company platform with substantial UI, governance, plugin, and operations surface.

## Why It Matters

Paperclip is a working multi-agent orchestration system rather than a thin prompt wrapper. It coordinates agents through durable issues, heartbeats, checkout locks, wakeup requests, run logs, budgets, workspaces, skills, REST/MCP tools, approvals, and adapter-specific execution. For coding-agent research, the valuable part is the control-plane pattern: turn "agent should work" into an auditable queued run with scoped context, an execution lease, a task lock, a bounded tool contract, and recovery when the run stops in an invalid state.

## What It Is

Paperclip is a TypeScript monorepo with an Express server, React UI, PostgreSQL/Drizzle schema, local and remote execution adapters, an MCP server, reusable skills, plugin support, routines, evals, and tests. The product models "companies" with agents, goals, projects, issues, routines, approvals, budgets, environments, and execution workspaces. Agents are woken by timers, assignments, comments, dependency changes, approvals, routines, and recovery paths, then run through adapters such as Codex local, Claude local, OpenCode, Cursor, process, HTTP, OpenClaw, Hermes, and external plugins.

## Research Themes

- Token efficiency: Uses scoped wake payloads, inbox-lite behavior, continuation summaries, session resume/delta prompts, comment batching, and explicit "do not poll" rules so agents do not repeatedly read the whole world.
- Context control: Builds a run-specific `paperclipWake` payload, issue task markdown, continuation summary document, workspace/environment metadata, runtime service state, linked comment context, skills manifest, model profile, and secrets manifest before adapter execution.
- Sub-agent / multi-agent: Uses an org chart, reporting-chain permissions, one-assignee issues, child issues for delegation, first-class blockers, mention wakeups, dependency wakeups, review/approval stages, routines, and deferred wakes when another agent owns active execution.
- Domain-specific workflow: The workflow is organized around companies, goals, projects, issues, execution workspaces, routines, approvals, budgets, and board interactions. The `skills/paperclip` heartbeat skill is the agent-side operating procedure.
- Error prevention: Atomic checkout, lazy execution locks, mandatory run IDs for agent mutations, company scoping, budget hard stops, subtree pause holds, blocker gates, stale lock cleanup, liveness recovery, bounded continuations, and 409 conflict rules prevent common multi-agent races.
- Self-learning / memory: No general memory service is shipped as a central runtime primitive. The practical memory layer is task sessions, adapter session state, continuation summary documents, issue documents/comments, company skills, and plugin-specific knowledge surfaces such as LLM Wiki.
- Popular skills: The core reviewed skill is `skills/paperclip`. Adjacent repo skills include agent creation, plugin creation, stop-diagnosis, terminal-bench loop, and PARA-style file memory, but only `skills/paperclip` is central to heartbeat execution.

## Core Execution Path

1. A wake source calls the heartbeat service and creates or coalesces an `agent_wakeup_requests` row plus a queued `heartbeat_runs` row.
2. For issue-scoped wakes, `enqueueWakeup` checks agent status, timer/on-demand policy, budgets, active tree holds, dependency readiness, stale queued retries, and active issue execution. It coalesces same-run wakes, defers conflicting issue wakes, or queues a new run.
3. `startNextQueuedRunForAgent` uses an agent start lock and the agent heartbeat concurrency policy to pick ready queued runs. `claimQueuedRun` atomically moves a run from `queued` to `running` and only then stamps the issue with `executionRunId` and `executionAgentNameKey`.
4. `executeRun` loads the agent, runtime config, issue context, comments, continuation summary, model profile, skills, secrets, workspace config, execution workspace, environment lease, runtime services, and adapter config. Scoped issue wakes auto-checkout before work when allowed.
5. The selected adapter receives an `AdapterExecutionContext` plus `runId`, agent/runtime/config, execution target, log/meta/spawn callbacks, runtime command spec, and optional short-lived local agent JWT. Local coding adapters inject `PAPERCLIP_*` env vars and build prompt bundles for Codex or Claude.
6. The agent acts through REST or MCP. Agent-mutating issue routes require `X-Paperclip-Run-Id`; checkout and mutation paths enforce issue ownership, checkout owner, company boundary, and active-run rules.
7. The heartbeat service stores logs, usage, cost, session state, result JSON, comments, continuation summary, liveness decisions, retries, handoff state, and final run status. It releases issue execution locks, releases or retains environment leases by policy, and promotes deferred wakes if appropriate.

## Architecture

The main layers are:

- Server services: `heartbeat.ts`, `issues.ts`, `routines.ts`, workspace/environment services, budget services, recovery services, skills/secrets/services, and plugin orchestration.
- API routes: issue routes enforce checkout ownership and run-scoped mutation; routine, approval, environment, workspace, and plugin routes expose control surfaces.
- Database: Drizzle schemas for agents, issues, heartbeat runs, wakeup requests, routines, environments, execution workspaces, comments, approvals, budgets, skills, and plugins.
- Adapters: built-in server adapters plus external adapter/plugin loading. The adapter boundary is intentionally no-Drizzle and receives a prepared context.
- Agent tools: REST API, MCP server, and `skills/paperclip` define how agents identify themselves, select work, checkout, comment, update status, ask for approval, and delegate.
- Execution environments: local, SSH, sandbox, and plugin-backed environments are acquired as leases; workspaces are realized locally or remotely, with sync/restore metadata.
- UI: a broad React control surface for agents, issues, runs, workspaces, approvals, routines, budgets, plugins, and transcripts.

## Design Choices

- The issue is the serialized unit of work; the run is the serialized execution attempt; the wakeup request is the delivery intent.
- Issue execution locks are lazy-stamped at claim time, not queue time, so queued wakes do not block other valid routing until they actually run.
- Routines create ordinary issues and wake assignees instead of using a separate executor path. This reuses checkout, dependency, wake, and recovery logic.
- Adapters are replaceable execution shells. Paperclip centralizes context, budget, workspace, secret, and audit handling before handing control to Codex, Claude, HTTP, process, or other adapter types.
- Local agents get a short-lived run JWT and must send a run ID on mutating requests. This makes writes attributable to one active heartbeat run.
- Context is explicit and bounded: wake payload, task markdown, comment delta, continuation summary, execution stage, workspace metadata, environment metadata, runtime services, and installed skills.
- Workspaces and environments are first-class. A run may use project primary checkout, task session checkout, git worktree, local execution, SSH, sandbox, or plugin-managed runtime, with sync-back metadata.
- Recovery is product semantics, not just process restart. The execution model distinguishes live path, waiting path, recovery path, parent/child structure, blockers, monitors, and terminal statuses.

## Strengths

- Strong coordination semantics around checkout, execution locks, deferred wakes, dependency readiness, and liveness recovery.
- Good tool-boundary discipline: adapters do not own database writes; agent mutations go through REST/MCP; server routes enforce run and ownership constraints.
- Practical coding-agent integration through Codex and Claude local adapters, injected env vars, prompt bundles, managed home/skills, session resume rules, and remote/sandbox execution targets.
- Context management is concrete: continuation summaries, wake payloads, session reset policy, comment batching, and scoped issue prompts reduce unnecessary rereads.
- Routines, approvals, comments, mentions, blockers, and monitors share the same wake/issue execution path, which avoids many parallel scheduler semantics.
- Tests cover high-risk behavior: race handling, checkout conflicts, stale locks, run recovery, deferred comment wakes, routine dispatch serialization, dependency wakeups, session policy, and adapter registry behavior.

## Weaknesses

- The core heartbeat service is very large and mixes scheduling, context assembly, workspace setup, adapter invocation, result handling, retry, recovery, and lock promotion. It is valuable but hard to extract cleanly.
- Scope is much larger than a coding-agent harness. Companies, boards, governance, UI, plugins, finance/costs, and environments add operational weight.
- Some safety remains prompt/skill-enforced, especially final-disposition behavior and "do not poll" norms. The strongest parts are where the server also enforces the invariant.
- `getServerAdapter` falls back to the process adapter for unknown types, which is convenient but less fail-closed than a strict production control plane would want.
- Process and HTTP adapters are necessarily weaker boundaries than first-party CLI adapters because the server cannot fully shape their internal behavior.
- The "memory" story is mostly continuation/session/document based, not a general retrieval or self-learning memory architecture.

## Ideas To Steal

- Model wake intent, execution attempt, and task lock as separate durable records.
- Lazy-stamp an execution lock only when a queued run is claimed.
- Require a run-scoped ID or token on agent writes, and reject mutations when the run does not own the checkout.
- Build a small, explicit wake payload for each run instead of replaying the full issue/project/company state.
- Keep a continuation summary document per issue and feed it into later sessions.
- Treat blockers as first-class dependencies, not just parent/child hierarchy.
- Implement routines by creating normal work items and waking normal agents.
- Defer comment or mention wakes while another run owns the issue, then promote them after release.
- Use adapter contracts with `execute`, `test`, skill listing, session codec, model profiles, and capability flags.
- Add liveness recovery for "successful" runs that leave `in_progress` with no next action.

## Do Not Copy

- Do not copy the whole autonomous-company abstraction if the goal is a coding-agent support harness.
- Do not keep all scheduler, workspace, context, adapter, result, and recovery logic in one giant service if starting fresh.
- Do not rely only on prompt instructions for final-state discipline; pair them with server-side validation and recovery.
- Do not silently fall back to a broad process executor for unknown adapter types in a stricter system.
- Do not expose a broad MCP or REST surface to untrusted agents without tight scopes, rate limits, audit, and run ownership checks.
- Do not treat parent/child links as dependencies; Paperclip correctly separates structure from blockers.

## Fit For Agentic Coding Lab

Use Paperclip as a pattern source for a coding-agent control plane: task checkout, wake queues, run-scoped credentials, bounded context payloads, adapter execution, worktree/environment realization, continuation summaries, and liveness recovery all transfer well. Keep the scope narrower than Paperclip: a local-first coding lab likely needs issues/tasks, locks, run records, tool boundaries, continuation summaries, and verification hooks before it needs companies, org charts, finance, plugin UI, or board governance.

## Reviewed Paths

- Overview/docs: `README.md`, `docs/start/architecture.md`, `docs/start/core-concepts.md`, `docs/adapters/overview.md`, `docs/adapters/{codex-local,claude-local,process,http,external-adapters}.md`, `docs/api/{agents,issues,routines,approvals}.md`, `docs/agents-runtime.md`, `doc/execution-semantics.md`.
- Agent workflow: `skills/paperclip/SKILL.md`, `skills/paperclip/references/{api-reference,workflows,issue-workspaces,routines}.md`.
- Heartbeat/orchestration: `server/src/services/heartbeat.ts`, `server/src/services/issue-assignment-wakeup.ts`, `server/src/services/routines.ts`, `server/src/services/issues.ts`, `server/src/routes/issues.ts`.
- Context/memory/recovery: `server/src/services/issue-continuation-summary.ts`, `server/src/services/heartbeat-run-summary.ts`, `server/src/services/run-continuations.ts`, `server/src/services/recovery/{run-liveness-continuations,successful-run-handoff,service,issue-graph-liveness}.ts`.
- Workspace/runtime: `server/src/services/workspace-runtime.ts`, `server/src/services/workspace-realization.ts`, `server/src/services/environment-run-orchestrator.ts`, `server/src/services/environment-execution-target.ts`, `packages/adapter-utils/src/{execution-target,server-utils,remote-managed-runtime,sandbox-managed-runtime,sandbox-callback-bridge,session-compaction}.ts`.
- Adapter boundaries: `server/src/adapters/{registry,plugin-loader,index,process/execute,http/execute}.ts`, `packages/adapter-utils/src/types.ts`, `packages/adapters/{codex-local,claude-local}/src/server/execute.ts`.
- Tools: `packages/mcp-server/{README.md,src/client.ts,src/tools.ts,src/tools.test.ts}`.
- Data model: `packages/db/src/schema/{agents,issues,heartbeat_runs,agent_wakeup_requests,routines,environments,execution_workspaces,issue_comments,issue_documents}.ts`.
- Verification: `evals/README.md`, `evals/promptfoo/{promptfooconfig.yaml,tests/core.yaml,tests/governance.yaml,prompts/heartbeat-system.txt}`, and representative tests under `server/src/__tests__`, `server/src/services/**/*.test.ts`, `packages/adapter-utils/**/*.test.ts`, `packages/adapters/{codex-local,claude-local}/src/server/*.test.ts`.

## Excluded Paths

- `ui/**` and `docs/pr-screenshots/**`: UI/control-panel rendering and screenshots. I sampled UI only indirectly through docs and tests because the review target is orchestration, execution, and tool boundaries.
- `packages/db/src/migrations/**` and `packages/db/src/migrations/meta/**`: migration history and generated snapshots. I read current schema files instead.
- `pnpm-lock.yaml`, package changelogs, release notes, and generated package metadata: mechanical dependency/release surface, not current coordination behavior.
- `releases/**`, `report/**`, `docs/plans/**`, and most historical planning docs: useful project history but not current runtime truth. I read `doc/execution-semantics.md` because skills identify it as the current execution model.
- Plugin UI internals and example plugin surfaces, including most of `packages/plugins/**/src/ui/**`: plugin/UI-specific behavior outside the core control plane. I considered LLM Wiki only as evidence of plugin-specific knowledge/session surfaces, not as core memory.
- Binary/image assets, favicon, screenshots, and static media: unrelated to agent execution paths.
- Deployment-only files such as most Docker and cloud deployment docs: operational packaging, not scheduler/tool/memory semantics.
- Adapter UI config builders and stdout presentation helpers: useful for product UX, but not needed to understand server-side adapter execution contracts.
