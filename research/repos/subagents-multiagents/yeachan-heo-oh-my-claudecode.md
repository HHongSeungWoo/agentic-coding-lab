# Yeachan-Heo/oh-my-claudecode

- URL: https://github.com/Yeachan-Heo/oh-my-claudecode
- Category: subagents-multiagents
- Stars snapshot: 34,376 via GitHub REST API repository metadata on 2026-05-20
- Reviewed commit: 1fe17f0e19ec9e24c5964d4363a9f53aab45c73f
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: in-scope
- Verdict: High-fit reference for Claude Code multi-agent orchestration. It is more than a prompt pack: it combines agent definitions, skill loaders, command stubs, lifecycle hooks, MCP tools, local state, tmux workers, worktree isolation, and verification loops. The useful ideas are the routing/enforcement architecture and worker protocol; the main caution is the large, evolving surface area with some stale docs and best-effort hook behavior.

## Why It Matters

This repo is directly relevant to agentic coding systems because it shows how a Claude Code extension can turn prompts into a coordinated runtime. It packages specialized agents and skills, but the important part is the control plane around them: keyword detection, model enforcement, persistent workflow state, context guards, project memory, team task state, and worker lifecycle transitions.

For our lab, it is useful as a concrete example of how to prevent agent systems from becoming only "ask the model to coordinate." The repo encodes coordination into files, hooks, CLI APIs, and worktree rules. It also exposes failure modes worth tracking: prompt-heavy workflows need schema discipline, hook ordering can become complex, and documentation can drift quickly when the runtime changes.

## What It Is

oh-my-claudecode is a TypeScript/npm package and Claude Code plugin for team-style coding workflows. It installs as a Claude Code plugin, npm package, or local plugin-dir setup. The repo contains 19 agent definition files, 39 skills, 27 slash-command markdown loaders, a hook suite, an MCP server named `t`, an `omc` CLI, and a runtime-v2 team engine.

The product has two team surfaces. Native `/team` is an in-session workflow that runs a staged pipeline: plan, PRD, execution, verification, and fix. `omc team` is a terminal/tmux workflow that starts real worker panes for Claude, Codex, or Gemini, creates team state under `.omc/state/team/<team>`, optionally creates per-worker git worktrees, and makes workers claim and complete tasks through `omc team api`.

Other workflows layer on top of the same primitives: Ralph for PRD/story-driven persistence, Ultrawork for parallel execution, Autopilot for full lifecycle orchestration, CCG for Claude/Codex/Gemini synthesis, verification skills, deep interview/planning skills, and memory/wiki/notepad tools.

## Research Themes

- Token efficiency: Thin command markdown files lazy-load skill bodies instead of embedding full instructions into every prompt. The keyword detector suppresses heavy modes for small tasks. Model tiers route cheap exploration to Haiku/Sonnet and reserve Opus for planning/review roles. Team workers can receive short startup prompts with the full instruction stored in inbox files, and larger handoffs use artifacts/state instead of raw prompt repetition.
- Context control: Context is managed through `.omc/state`, `.omc/notepad.md`, project memory, PreCompact checkpoints, rules injection, context usage guards, and explicit team state roots. Worktree-backed workers receive `OMC_TEAM_STATE_ROOT` so they coordinate through the leader state root instead of accidentally creating isolated local state.
- Sub-agent / multi-agent: The repo defines specialized coding agents, native team stages, `omc team` tmux workers, provider routing for Claude/Codex/Gemini, CCG synthesis, Ultrawork parallelism, and Ralph/Autopilot persistence. The strongest pattern is that workers have a strict protocol: claim a task, work in the assigned workspace, send status, then transition task status with evidence.
- Domain-specific workflow: Most abstractions are coding-domain specific: PRDs, acceptance criteria, task decomposition, code review, security review, test engineering, design review, debugging, release, setup, doctoring, skill creation, and repo memory. The system is tuned for software delivery rather than generic chat agents.
- Error prevention: PreToolUse hooks enforce model/routing safety, warn on risky workaround language, block high-context agent spawning, and remind Claude about tool-use contracts. Team tasks use locks, claim tokens, leases, dependency checks, and allowed status transitions. Worktree mode refuses dirty leader worktrees and preserves dirty worker worktrees rather than force-cleaning them.
- Self-learning / memory: Project memory learns hot paths, build/test commands, environment hints, dependency clues, notes, and directives from tool use. Session hooks load and persist this memory. Notepad tools preserve priority and working context across compaction.
- Popular skills: Team, Ralph, Ultrawork, Autopilot, CCG, verify, ralplan, deep-interview, ai-slop-cleaner, setup/doctor, skillify, remember, wiki, and project-session-manager are the most reusable patterns for agentic coding workflows.

## Core Execution Path

Install/discovery starts through the Claude Code plugin marketplace (`/plugin marketplace add ...`, `/plugin install ...`), npm (`oh-my-claude-sisyphus`), or local plugin-dir setup. Setup then installs Claude-facing instructions, hooks, MCP config, and plugin metadata. The plugin manifest advertises agents, skills, commands, hooks, and MCP servers, while the npm package exposes `omc`/`oh-my-claudecode` CLI entry points.

In normal use, `UserPromptSubmit` runs keyword detection and skill injection. Explicit slash commands are small dispatchers that ask Claude to load the matching skill from the active install. Before tool calls, `pre-tool-enforcer` checks model parameters, provider compatibility, team routing, active skill state, context pressure, and common risky patterns. After tool calls, post-tool hooks collect error signals, update project memory, and inject relevant rules.

For `omc team`, the CLI parses worker count/provider/role syntax, optionally decomposes the task, validates CLIs, and creates team config, manifest, tasks, worker directories, inboxes, and tmux panes. Runtime v2 uses evented state and lifecycle transitions rather than `done.json` polling. Workers must call `omc team api` to claim tasks, heartbeat, communicate, and transition status. Completion can require delegation evidence or an explicit skip reason for broad tasks.

Persistent workflows are enforced at `Stop`. Ralph, Autopilot, Ultrawork, Team, todo continuation, and related modes can block premature stopping unless the mode is terminal, cancelled, stale, at a context limit, or past retry limits. PreCompact saves checkpoints so long-running sessions can resume with less context loss.

## Architecture

The architecture has four main layers:

- Product surface: agent markdown, skill markdown, command markdown, plugin metadata, and setup scripts.
- Runtime hooks: UserPromptSubmit, SessionStart, PreToolUse, PermissionRequest, PostToolUse, PostToolUseFailure, SubagentStart/Stop, PreCompact, Stop, and SessionEnd.
- Local control plane: `.omc/state`, `.omc/notepad.md`, project memory JSON, team task files, team manifests, inbox/mailbox files, event logs, and workflow state.
- Tooling plane: `omc` CLI, MCP server `t`, LSP/AST/python/notepad/memory/wiki/shared-memory tools, and optional interop tools.

Agents are mostly role definitions with model/tool permissions. Skills are workflow controllers that tell Claude how to sequence agents, artifacts, verification, and persistence. Commands are intentionally thin entry points. Hooks are the guardrail layer that can enforce or remind independently of the current prompt.

The team runtime is the most system-like component. It snapshots routing at team creation, creates worker state, optionally creates worktrees, overlays worker instructions, starts tmux panes, and relies on API-mediated lifecycle changes. Worker bootstrap instructions explicitly ban direct lifecycle file edits, nested team spawning, and uncontrolled sub-agent recursion. Worktree mode separates leader state from worker checkouts and treats dirty worktrees as protected user data.

## Design Choices

The repo uses lazy command-to-skill loading to control context cost. This is preferable to putting every workflow prompt into global instructions.

Model routing is duplicated across declarative frontmatter and PreToolUse enforcement. The hook preserves explicit models when safe, maps tier aliases, handles Bedrock/Vertex/proxy concerns, and denies unsafe no-model subagent calls in some cases.

Team mode is explicit-only in keyword detection. The code disables automatic team keyword triggering to avoid recursive team spawning inside workers, while preserving slash-command and CLI entry points.

Worker coordination is API-first. A worker should not directly mutate task lifecycle fields; it claims a task, works, reports, and transitions through validated operations with claim tokens and leases.

Context and handoff data are file-backed. The system favors state roots, notepads, memory summaries, inboxes, and artifact descriptors over repeatedly injecting large bodies of text.

Many hooks are fail-soft by design. That improves day-to-day usability, but critical safety features need careful review because some warnings are advisory and some runtime errors are intentionally suppressed.

## Strengths

- It demonstrates an end-to-end agent runtime, not just a collection of prompts.
- The team worker protocol is concrete: identity, inbox, heartbeat, claim token, status transition, result evidence, and shutdown path.
- Model and provider safety are enforced at hook time, which catches mistakes outside the skill prompt itself.
- Worktree mode has practical safety checks: dirty leader refusal, dirty worker preservation, branch/path validation, and explicit orphan cleanup.
- Context control is layered across prompt loading, small-task suppression, pre-agent context checks, notepad, memory, and compaction checkpoints.
- Verification is integrated into workflows through Ralph story acceptance, Team verify/fix stages, reviewer agents, deliverable checks, and verify skills.
- Install/discovery is well-covered through plugin metadata, npm package files, local plugin-dir docs, setup flows, and compatibility scanning for external plugins/MCP servers.

## Weaknesses

- The surface area is large: hooks, MCP tools, skills, commands, CLI, tmux, worktrees, and plugin setup all interact. That creates operational and debugging complexity.
- Some documentation and metadata appear stale. The marketplace description mentions different agent/skill counts than the current files, some docs reference older team paths, and one documented agent model differs from frontmatter.
- Several safety systems are advisory or fail-open. Deliverable verification warns rather than blocks, and many hook failures are suppressed to avoid breaking the user session.
- The prompt/skill corpus is broad and partially overlapping. Without generated inventories or schema validation, drift between docs, manifests, commands, and runtime behavior is likely.
- Environment setup is non-trivial. Full use can require Claude Code plugin behavior, npm build artifacts, tmux, optional Codex/Gemini CLIs, experimental native team env vars, and project-local config.
- Magic keyword detection is useful but brittle. The repo mitigates this with code-block stripping, task-size gating, and explicit-only team mode, but keyword-driven activation still creates hidden control flow.

## Ideas To Steal

- Use thin slash commands as stable entry points that lazy-load larger skills.
- Put model/routing checks in a PreToolUse hook so enforcement is not only prompt-based.
- Track active workflow skills in a session ledger and have Stop hooks continue or release them based on explicit terminal state.
- Give team workers a small, strict protocol: claim, work, acknowledge, transition, and include completion evidence.
- Separate worker checkout paths from a canonical team state root to make worktree mode predictable.
- Require delegation evidence for broad tasks, while allowing an explicit skip reason when delegation is not useful.
- Add a context preflight before spawning agent-heavy work.
- Persist project memory from real tool use: hot files, test commands, dependency hints, environment facts, and user directives.

## Do Not Copy

- Do not copy long prompt bodies or the whole workflow corpus verbatim. The reusable asset is the control-plane pattern, not the prose.
- Do not rely on documentation counts by hand. Generate inventories for agents, skills, commands, hooks, and MCP tools.
- Do not make critical safety purely advisory if correctness depends on it. Decide which checks must block and test those paths.
- Do not expose a large MCP tool surface by default without category gating, permission design, and a doctor command.
- Do not depend on keyword magic as the only activation path. Keep explicit commands and inspectable state.
- Do not require tmux, multiple CLIs, worktrees, and build artifacts without a very clear install/diagnostic path.

## Fit For Agentic Coding Lab

Fit is very high as a reference architecture for subagent orchestration in coding agents. It provides concrete patterns for agent packs, command discovery, lifecycle hooks, stateful workflows, context recovery, verification, model routing, worker isolation, and API-mediated team coordination.

It should not be treated as a drop-in blueprint. The lab should extract smaller primitives: command-to-skill lazy loading, hook-level routing enforcement, team task schemas, claim-token lifecycle, context preflight, compaction checkpoints, and project memory learning. Those primitives are easier to test and reason about than importing a broad all-in-one assistant runtime.

## Reviewed Paths

- `README.md`
- `package.json`
- `.claude-plugin/plugin.json`
- `.claude-plugin/marketplace.json`
- `.mcp.json`
- `docs/ARCHITECTURE.md`
- `docs/TEAM-WORKTREE-MODE.md`
- `docs/DELEGATION-ENFORCER.md`
- `docs/LOCAL_PLUGIN_INSTALL.md`
- `docs/COMPATIBILITY.md`
- `hooks/hooks.json`
- `commands/*.md`
- `agents/*.md`
- `skills/team/SKILL.md`
- `skills/omc-teams/SKILL.md`
- `skills/ralph/SKILL.md`
- `skills/ultrawork/SKILL.md`
- `skills/autopilot/SKILL.md`
- `skills/verify/SKILL.md`
- `skills/omc-setup/SKILL.md`
- `src/hooks/keyword-detector/index.ts`
- `src/hooks/task-size-detector/index.ts`
- `src/hooks/pre-compact/index.ts`
- `src/hooks/project-memory/index.ts`
- `src/hooks/project-memory/learner.ts`
- `src/hooks/rules-injector/index.ts`
- `src/hooks/persistent-mode/index.ts`
- `src/hooks/ralph/verifier.ts`
- `scripts/pre-tool-enforcer.mjs`
- `scripts/lib/pre-tool-enforcer-preflight.mjs`
- `scripts/post-tool-verifier.mjs`
- `scripts/verify-deliverables.mjs`
- `scripts/context-guard-stop.mjs`
- `scripts/context-safety.mjs`
- `src/team/runtime-v2.ts`
- `src/team/worker-bootstrap.ts`
- `src/team/git-worktree.ts`
- `src/team/mcp-comm.ts`
- `src/team/api-interop.ts`
- `src/team/ops/state/tasks.ts`
- `src/team/delegation-evidence.ts`
- `src/cli/commands/team.ts`
- `src/mcp/omc-tools-server.ts`
- `benchmark/README.md`
- `benchmarks/README.md`
- `vitest.config.ts`

## Excluded Paths

- README translations such as `README.ko.md`, `README.ja.md`, `README.zh.md`, and other localized variants.
- Image/media assets under `assets/` and seminar slide/media material under `seminar/`.
- Generated or runtime-like shell/session material under `shellmark/`.
- Benchmark run outputs, prediction artifacts, checkpoint files, and generated evaluation results.
- Example/demo missions and repo-internal research notes that do not affect install, routing, hooks, context control, verification, or team execution.
- Lockfile-level dependency review beyond package identity and runtime dependency categories.
