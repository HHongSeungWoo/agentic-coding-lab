# gastownhall/gastown

- URL: https://github.com/gastownhall/gastown
- Category: subagents-multiagents
- Stars snapshot: 15,414 (GitHub REST API, captured 2026-05-20)
- Reviewed commit: 625bcf8a92f9faef9804f73624a8bf770085ebd2
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong pattern source for multi-agent coding workspaces. Gas Town combines durable task state, isolated worktrees, persistent agent identities, dispatch queues, watchdog recovery, and a merge queue into one operational system. Borrow the lifecycle invariants and failure handling; do not copy the whole city metaphor or full runtime stack unless you also want its operational complexity.

## Why It Matters

Gas Town is one of the more complete public examples of coding-agent workspace orchestration. It treats agent work as stateful infrastructure rather than prompt choreography: every assignment, worker identity, hook, merge request, convoy, restart, and cleanup decision is recorded outside the model context in Beads/Dolt, git branches, tmux sessions, and event logs.

For an agentic coding lab, the repo is most valuable because it shows how many edge cases appear once agents run concurrently: double dispatch, stale claims, lost completion messages, dirty sandboxes, branch loss, zombie sessions, cross-rig misrouting, queue starvation, force-push risk, and context-window handoff. The implementation contains concrete guards for most of these, not just design prose.

## What It Is

Gas Town is a Go CLI and local runtime for managing a "town" of coding agents across one or more repositories. A mayor coordinates work, rigs wrap repos, crew workspaces are persistent human/agent clones, polecats are autonomous workers, witnesses monitor polecats, refinery agents merge submitted work, and a deacon/daemon layer keeps infrastructure moving.

The project supports multiple agent providers, including Claude Code, Codex, Gemini, Cursor, OpenCode, Copilot, AMP, Pi/OMP, and others. It starts agents in tmux with role-specific environment, hooks, instructions, and session prompts. The dominant state store is Beads backed by Dolt, with two levels of databases: town-level `hq-*` coordination beads and rig-level project beads.

## Research Themes

- Token efficiency: Instead of carrying full state in prompts, it rehydrates context through `gt prime --hook`, structured agent beads, attached molecules, formulas, hooks, and session/event logs. Root-only "wisps" avoid huge task explosions until poured.
- Context control: Sessions are deliberately ephemeral while identity, hook state, worktree, branch, molecule progress, and completion metadata persist. `gt handoff`, PreCompact hooks, session restart, and SessionStart priming are the main context-cycle controls.
- Sub-agent / multi-agent: This is the core contribution. It has coordinator agents, worker agents, watchdog agents, dog helpers, convoy swarms, per-rig witnesses, a refinery merge queue, and scheduler-controlled polecat dispatch.
- Domain-specific workflow: The domain is autonomous software engineering. The workflow is bead assignment -> isolated polecat branch/worktree -> formula-guided implementation -> `gt done` -> merge-request bead -> refinery gates/merge -> cleanup and convoy completion.
- Error prevention: It has per-bead and per-assignee locks, cross-rig prefix guards, spawn caps, reuse fail-closed checks, MR readback, verified remote pushes, merge slots, stale-claim handling, branch-loss escalation, hook guards, and proxy allowlists.
- Self-learning / memory: Persistent identities and agent beads accumulate traceable history. Session discovery (`seance`), mail, events, completion metadata, patrol receipts, convoy failures, and Dolt-backed issue state serve as memory more than model-side learning.
- Popular skills: The reusable ideas are durable assignment ledgers, worktree-per-worker isolation, persistent worker identity with ephemeral context, restart-first watchdogs, queue contexts separate from work items, and verified merge handoff.

## Core Execution Path

The central flow starts with `gt sling`. Direct and scheduled sling paths resolve the target rig, guard against cross-rig prefix mistakes, reject already hooked or terminal work unless forced, attach a formula/molecule, create or reuse a polecat, hook the work bead, store dispatch metadata, and start the agent session.

When `scheduler.max_polecats` is enabled, sling does not mutate the work bead. It creates an ephemeral sling-context bead in the target rig database with JSON fields such as work bead ID, formula, args, target rig, convoy, merge mode, failure count, and dispatch metadata. The daemon's capacity dispatch loop later scans ready contexts, checks `bd ready`, enforces active polecat capacity, dispatches through `executeSling`, closes the context, and records circuit-breaker failures if dispatch keeps failing.

A polecat works inside a branch/worktree, guided by `gt prime`, hooks, and a formula. On completion, `gt done` verifies role, saves intent/checkpoints, auto-saves recoverable git state, validates it is not on the default branch, verifies commits ahead, rebases or checks contamination where needed, pushes the exact branch/commit, creates an MR bead with structured fields, records completion metadata on the agent bead, clears the hook, and moves the polecat to idle. The sandbox is preserved for reuse.

Witness patrol handles the failure side. It classifies live/dead/hung/stuck polecats using tmux liveness, agent process checks, done-intent labels, heartbeat v2 state, agent bead fields, hook status, and pending MR evidence. Its dominant policy is restart-first, preserving branches and worktrees. Dirty state creates cleanup wisps, repeated abandoned bead respawns trip a spawn-storm circuit breaker, and mountain convoys can auto-skip a task after repeated polecat failures.

Refinery then processes `gt:merge-request` beads. It filters by rig, skips blocked or owned-direct work, detects stale claims, checks branch existence, runs gates, handles pre-verification fast paths, serializes default-branch pushes with a merge-slot bead, verifies pushed commits, closes MR/source beads, cleans branches, updates convoy state, and creates conflict-resolution tasks when merges fail.

## Architecture

The architecture is organized around a town root with per-rig directories. Town-level beads hold cross-rig coordination, identities, role definitions, mayor/deacon/boot/dog state, routes, and shared mail. Rig-level beads hold project work, merge requests, molecules, witness/refinery/polecat/crew agent beads, and local work state.

Workspace isolation is mostly git and process based. Crew use long-lived full clones. Polecats and refinery use git worktrees from a shared `.repo.git` or the mayor rig clone. Each polecat has a permanent identity, a persistent sandbox directory, and an ephemeral tmux session. A worktree gets a `.beads/redirect` pointing to the canonical rig beads database so all agents see the same state.

Agent startup is environment-driven. `AgentEnv` sets `GT_ROLE`, `GT_RIG`, `GT_POLECAT`/`GT_CREW`, `BD_ACTOR`, `GIT_AUTHOR_NAME`, `GT_ROOT`, `BEADS_AGENT_NAME`, session IDs, and safety env such as `BD_DOLT_AUTO_COMMIT=off` for polecats and `BD_BACKUP_ENABLED=false`. `BuildStartupCommand` inserts optional `exec_wrapper` commands between `exec env ...` and the agent binary, making local or remote sandbox wrappers pluggable.

Coordination uses several channels at once: Beads/Dolt records, tmux sessions and nudges, file-based channel events, git branches, mail, hooks, and structured JSON/key-value fields in bead descriptions. This is not minimal, but the redundancy is intentional: patrol cycles can recover from missed mail, stale tmux sessions, failed pushes, or half-written completion flows.

## Design Choices

Gas Town makes work state durable before handing it to an agent. A polecat is not "working" because a prompt says so; it has an agent bead, a hook bead, a worktree, a branch, and often an attached molecule. That makes recovery possible when the model, tmux pane, or host process dies.

It separates queue intent from work mutation. Scheduled dispatch creates sling-context beads and leaves the work bead untouched until capacity is available. This avoids marking work as in progress before an actual worker exists, and it gives the scheduler an idempotent retry object.

It prefers restart over deletion. Witness recovery usually restarts a session in the same sandbox, only nuking explicitly or when work is already verified as merged. This protects partially completed work and makes context loss less dangerous.

It uses multiple locks and caps rather than assuming agents will serialize themselves. Examples include flock locks around sling work and assignee hooks, a scheduler dispatch lock, per-agent bead locks, max active polecat capacity, respawn counters, merge slots, and branch/commit verification gates.

It treats merge as a separate agent-owned workflow. Polecats submit; refinery verifies and lands. That boundary gives the system a place to enforce quality gates, branch protection via PR strategy, conflict delegation, batch-then-bisect, and convoy completion.

It currently favors productivity over local least privilege. Built-in agent presets use permissive flags such as Claude `--dangerously-skip-permissions`, Codex `--dangerously-bypass-approvals-and-sandbox`, Gemini `--approval-mode yolo`, Copilot `--yolo`, AMP `--dangerously-allow-all`, and OpenCode `OPENCODE_PERMISSION={"*":"allow"}`. Host-level sandboxing exists as an `exec_wrapper` and proxy design, but the normal local tmux path is high trust.

## Strengths

- Durable external state: agent beads, hook beads, MR beads, sling contexts, convoy beads, routes, mail, event logs, and git branches keep work recoverable across context and process loss.
- Strong workspace model: crew, polecat, witness, refinery, and mayor workspaces have distinct roles; polecats get isolated branches/worktrees with persistent identities and reusable sandboxes.
- Practical concurrency controls: direct dispatch locks, scheduler locks, assignee locks, agent bead locks, merge slots, capacity limits, stale-claim handling, and circuit breakers address real double-dispatch and spawn-storm risks.
- Serious handoff and completion handling: `gt done` writes intent/checkpoints, validates branch state, verifies remote commit after push, creates/readbacks MR beads, stores completion metadata, and only then clears hooks.
- Watchdog recovery is detailed: witness distinguishes dead session, dead agent in live tmux, stuck done-intent, never-heartbeated startup, dirty idle sandbox, closed bead still running, submitted-still-running, and pending MR cases.
- Tool boundaries are layered: Claude/Gemini/Codex/etc. hooks run `gt prime`, inject mail, block PR workflow and dangerous commands, and Stop hooks can auto-run `gt done` when a polecat has unsubmitted commits.

## Weaknesses

- The system is large and terminology-heavy. Extracting one mechanism means understanding town, rig, bead, hook, molecule, convoy, polecat, witness, refinery, deacon, and daemon interactions.
- Some safety is provider-hook or prompt dependent. Local polecat-to-polecat isolation is mostly worktree discipline plus hooks, not a hard OS boundary.
- Default local agent presets intentionally bypass approval/sandbox modes. The sandboxed execution plan with `exitbox`, Daytona, mTLS proxy, and branch-scoped git is promising, but it is separate from the ordinary high-trust local tmux path.
- There is doc drift. Older molecule/lifecycle prose still describes nuking sandboxes after `gt done`, while current code and newer docs preserve polecat sandboxes for reuse. Identity docs also imply fuller git author attribution than the polecat `AgentEnv` code sets.
- Some critical paths are duplicated or transitional. `runSling` still notes future unification with `executeSling`, so single dispatch and scheduled/batch dispatch do not share every implementation step.
- Operational dependencies are heavy: Dolt SQL, Beads behavior, tmux, git worktrees, provider-specific hooks, shell commands, and agent CLI startup quirks all become part of correctness.

## Ideas To Steal

- Make assignment state durable before an agent starts: worker ID, hook/work item, formula/checklist, branch, workspace path, dispatcher, and merge mode should all be externalized.
- Use "identity persists, context expires" as the worker model. Keep worker history and sandbox state, but allow session restarts and handoffs freely.
- Use queue-context records for capacity scheduling instead of marking source work in progress before a worker is allocated.
- Treat completion as a recoverable transaction with checkpoints: intent written early, push verified, MR record read back, agent metadata updated, hook cleared last.
- Give watchdogs typed classifications and restart-first actions. Avoid a generic "agent failed" bucket; it hides important differences between lost work, completed work, pending merge, dirty sandbox, and auth/startup failure.
- Put merge through a separate queue with gates, stale-claim detection, conflict tasks, branch verification, and post-merge cleanup.
- Add explicit route/prefix checks for multi-repo work so a worker cannot accidentally operate on another repo's task ID.
- Keep hook guards small and structural: block dangerous commands, PR workflow drift, wrong `bd init`, patrol formula misuse, and missing `gt done` on Stop.

## Do Not Copy

- Do not copy the full metaphor or role taxonomy unless it matches your users. The mental overhead is real.
- Do not rely on permissive provider flags as your only autonomy story. Pair agent approval bypass with real workspace, network, credential, and command boundaries.
- Do not use tmux liveness alone as truth. Gas Town had to add agent process checks, heartbeat state, startup grace, done-intent labels, and bead snapshots because tmux can be alive while the agent is dead or blocked.
- Do not mutate source task state just to express queued intent. The sling-context design is safer.
- Do not let cleanup delete branches/worktrees before merge evidence is verified. Gas Town has many guards because premature nuke risks losing work.
- Do not duplicate dispatch paths long term. The repo itself shows the maintenance risk of direct sling and `executeSling` not being fully unified.

## Fit For Agentic Coding Lab

Fit is high for studying multi-agent coding workspace management. The repo directly addresses coordination, task state, persistent identities, context isolation, handoff, workspaces, verification, sandbox boundaries, and failure recovery.

The best adoption path is selective. For a lab, copy the invariants and interfaces: durable task ledger, worker-state schema, isolated git workspaces, assignment locks, queue contexts, restart-first watchdogs, completion checkpoints, and verified merge queue. Avoid importing Dolt/Beads/tmux/provider-hook coupling unless the lab wants a local-first runtime with similar constraints.

The sandbox story should be treated as an area to improve, not as finished prior art. The proxy server has strong ideas: mTLS identities, command/subcommand allowlists, minimal subprocess environment, rate/concurrency limits, cert denylist, and git receive-pack branch authorization to `refs/heads/polecat/<name>-*`. But the common local runtime still gives agents broad host access through permissive provider modes.

## Reviewed Paths

- `README.md`, `docs/overview.md`, `docs/design/architecture.md`, `docs/design/scheduler.md`, `docs/design/sandboxed-polecat-execution.md`, `docs/proxy-server.md`
- `docs/concepts/polecat-lifecycle.md`, `docs/design/polecat-lifecycle-patrol.md`, `docs/concepts/convoy.md`, `docs/concepts/molecules.md`, `docs/concepts/identity.md`, `docs/concepts/integration-branches.md`
- `internal/cmd/sling.go`, `internal/cmd/sling_dispatch.go`, `internal/cmd/sling_schedule.go`, `internal/cmd/capacity_dispatch.go`, `internal/scheduler/capacity/*.go`
- `internal/cmd/polecat_spawn.go`, `internal/polecat/manager.go`, `internal/polecat/session_manager.go`, `internal/polecat/reuse.go`, `internal/polecat/heartbeat.go`
- `internal/cmd/done.go`, `internal/cmd/done_rebase.go`, `internal/cmd/mq_submit.go`
- `internal/witness/handlers.go`, `internal/witness/manager.go`, `internal/witness/mountain.go`, `internal/witness/spawn_count.go`, `internal/cmd/patrol_scan.go`, `internal/cmd/witness.go`
- `internal/refinery/manager.go`, `internal/refinery/engineer.go`, `internal/refinery/batch.go`, `internal/refinery/types.go`, `internal/refinery/pr_provider*.go`
- `internal/beads/beads_sling_context.go`, `internal/beads/beads_agent.go`, `internal/beads/fields.go`, `internal/beads/beads_merge_slot.go`, `internal/beads/routes.go`, `internal/beads/beads_redirect.go`, `internal/beads/handoff.go`, `internal/beads/beads_mr.go`
- `internal/config/agents.go`, `internal/config/env.go`, `internal/config/types.go`, `internal/config/loader.go`, `internal/hooks/config.go`, `internal/hooks/installer.go`, `internal/hooks/templates/*`
- `internal/cmd/tap_guard.go`, `internal/cmd/tap_guard_dangerous.go`, `internal/cmd/tap_polecat_stop.go`
- `internal/proxy/server.go`, `internal/proxy/exec.go`, `internal/proxy/git.go`, `internal/proxy/ca.go`, `internal/proxy/denylist.go`, `cmd/gt-proxy-client/main.go`, `cmd/gt-proxy-server/main.go`

## Excluded Paths

- UI-only and presentation paths: `internal/web/static/`, `internal/web/templates/`, `internal/tui/`, browser E2E/static CSS/JS assets, and dashboard/view-only code.
- Generated or local-state paths: `.beads/backup/*.jsonl`, temporary runtime state, local event/log artifacts, and generated analysis output such as `docs/design/convoy/stage-launch/bv-insights.json`.
- Packaging and release-only paths: `npm-package/`, release scripts, installer packaging, GitHub workflow metadata, Renovate/config-only files, and Docker/Nix packaging except where docs referenced runtime sandboxing.
- Evaluation and fixture paths: `gt-model-eval/`, promptfoo/eval fixtures, and test harnesses not involved in core workspace coordination.
- Vendored dependency trees: none were intentionally reviewed; the sparse/blobless clone focused on first-party docs and Go source.
- Provider UI/instruction templates were sampled only for lifecycle hooks and guard behavior; visual or branding-only template content was excluded.
