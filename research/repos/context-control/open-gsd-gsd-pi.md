# open-gsd/gsd-pi

- URL: https://github.com/open-gsd/gsd-pi
- Category: context-control
- Stars snapshot: 351 (GitHub REST API repository search, captured in `research/index.md` on 2026-05-29)
- Reviewed commit: b477b3cfafc88dfa3cbda85c5848e061d2b40949
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: in-scope
- Verdict: Very high-value context-control system for agentic coding research. Steal the per-unit context manifest, DB-authoritative workflow state, markdown projections, Context Mode exec digests, compaction snapshots, write gates, worktree safety, and verification-evidence loop. Do not copy the whole product surface or assume its single-host SQLite/WAL coordination model transfers to distributed labs.

## Why It Matters

GSD Pi is a current, maintained continuation of the GSD-style autonomous coding workflow. It is useful because it treats context as a runtime control plane rather than a prompt blob: work is decomposed into milestones, slices, and one-context-window tasks; every unit runs in a fresh session; context is assembled from explicit artifacts; and durable state lives outside chat in SQLite plus `.gsd/` projections.

For Agentic Coding Lab, the most reusable ideas are the small control contracts: `UnitContextManifest`, tool-policy lanes, DB-backed completion tools, deterministic pre-dispatch reconciliation, Context Mode command evidence, and host-owned verification gates. The system is also a cautionary reference: many good ideas are packed into a large CLI/product, so the lab should extract contracts and harnesses rather than import the full runtime.

## What It Is

`open-gsd/gsd-pi` is a TypeScript monorepo for a local-first coding agent. The npm package exposes `gsd`, `gsd-cli`, and an installer binary from `@opengsd/gsd-pi`; it requires Node 22 or newer and uses pnpm for development.

The main user workflow is `/gsd auto`. A state machine reads the project-root `.gsd/gsd.db`, chooses the next unit, creates a fresh model session, injects unit-scoped context, lets the agent work through GSD workflow tools, persists results to the DB, refreshes markdown projections, runs post-unit verification, and advances until the milestone completes. Planning artifacts live under `.gsd/` as human-readable projections, but completion status, queue order, requirements, memories, summaries, and verification evidence are database-backed.

The repo also includes a desktop studio, web surfaces, daemon/RPC packages, native helpers, cloud MCP gateway support, subagent orchestration, skills support, and extensive docs. For this review, the core subject is the GSD extension under `src/resources/extensions/gsd` and the docs/templates that define the agent workflow.

## Research Themes

- Token efficiency: Fresh session per unit, token profiles, inline levels, context-window budget allocation, section-boundary truncation, prompt-cache-friendly ordering, `.gsd/CODEBASE.md` as a capped structural map, Context Mode `gsd_exec` digests, searchable exec history, and `.gsd/last-snapshot.md` for compaction resume.
- Context control: Strong. Each known unit has a `UnitContextManifest` declaring skills, knowledge, memory, preferences, context lane, tool policy, artifacts, and nominal budget. SQLite is runtime truth; markdown files are projections for prompts, review, and git history.
- Sub-agent / multi-agent: Strong but single-host. Planning units can dispatch read-only scout/planner/reviewer specialists through manifest-limited `planning-dispatch`; execution can use reactive task batches, slice parallelism, and milestone workers coordinated by SQLite tables, leases, heartbeats, and command queues.
- Domain-specific workflow: Very strong for spec-driven coding. The hierarchy is milestone -> slice -> task, with deep project setup, requirements capture, research decisions, milestone planning, slice planning, execution, UAT, gate evaluation, validation, reassessment, and closeout artifacts.
- Error prevention: Strong. It has resource-version guards, health gates, drift reconciliation, tool contracts, write gates, worktree safety, stale-worker cleanup, dispatch stuck detection, post-unit artifact checks, verification retries, and duplicate-failure pause logic.
- Self-learning / memory: Medium to strong. Memories have categories, confidence, scope, tags, hit counts, time decay, FTS/semantic hooks, relations, and decision/knowledge backfill. Memory injection is kept in a volatile context message to preserve stable system-prompt caching.
- Popular skills: GSD supports the open Agent Skills layout, bundled/user/project skill directories, onboarding recommendations, skill preferences, skill telemetry, and skill-health reporting. This is useful as a portability pattern because the docs intentionally target multiple coding agents rather than only GSD.

## Core Execution Path

The reviewed execution path starts with the installed `gsd` CLI and the GSD extension. The repo overview says GSD stores project planning and runtime state in `.gsd/`, then `/gsd auto` drives the loop. In code, `src/resources/extensions/gsd/auto/loop.ts` coordinates iterations, while `auto/phases.ts` performs pre-dispatch checks, dispatch resolution, guards, unit execution, verification, finalization, and closeout.

Pre-dispatch starts by checking resource freshness, running a health gate, syncing project-root artifacts into worktrees when needed, deriving state from the canonical project root, applying deep-planning gates, optionally compiling a plan-v2 graph, reconciling state drift, and checking slice-parallel eligibility. Dispatch then resolves a `DispatchAction` from `auto-dispatch.ts`, runs pre-dispatch hooks, blocks prior-slice violations, checks repeated dispatch loops, validates worktree safety for source-writing units, and records the selected unit.

Unit execution in `auto/run-unit.ts` creates a new session rooted at the active unit directory, restores the selected model, checks provider readiness, captures a turn generation for stale-write detection, sends the prompt, and waits for an `agent_end` result under hard timeout supervision. Unit prompts come from markdown templates under `src/resources/extensions/gsd/prompts`, plus inlined context assembled by `auto-prompts.ts` and the manifest/composer layer.

Agents are expected to finish through DB-backed tools such as `gsd_plan_slice`, `gsd_task_complete`, `gsd_slice_complete`, and `gsd_validate_milestone`; prompts explicitly forbid manual checkbox/file writes for canonical state. After a unit ends, GSD checks artifacts, writes runtime records, runs verification gates, stores evidence, retries bounded failures, records costs/metrics, and either advances, pauses, or stops with a blocker.

## Architecture

The repo is a broad TypeScript monorepo:

- `src/resources/extensions/gsd`: the main workflow engine, prompts, tools, manifests, memory, reconciliation, worktree safety, verification, dashboard, commands, and tests.
- `packages/pi-coding-agent`, `packages/gsd-agent-core`, `packages/pi-agent-core`, `packages/pi-ai`, and `packages/pi-tui`: the agent runtime, session/compaction modules, model/provider layer, harnesses, and terminal UI packages.
- `packages/daemon`, `packages/rpc-client`, `packages/contracts`, and MCP/cloud packages: daemon, RPC, remote control, and tool transport boundaries.
- `docs/`, `gitbook/`, and `mintlify-docs/`: user and developer documentation for auto mode, token optimization, skills, MCP, subagents, parallel orchestration, hooks, and architecture.
- `studio/`, `web/`, and `vscode-extension/`: UI and integration surfaces, reviewed only enough to classify them as outside the core context-control path.

The state architecture is hybrid. `.gsd/gsd.db` is authoritative. Markdown files such as `PROJECT.md`, `REQUIREMENTS.md`, `DECISIONS.md`, `KNOWLEDGE.md`, `STATE.md`, roadmap files, plans, summaries, UAT, assessments, and validation reports are projections or review surfaces. `.gsd/exec` stores capped stdout/stderr and metadata. `.gsd/runtime` stores runtime side state such as write-gate snapshots. `.gsd/journal` and metrics files support forensics and dashboards.

## Design Choices

The best design choice is making unit context declarative. `UnitContextManifest` maps every known unit type to a context lane, tool policy, memory/knowledge policy, artifacts to inline/excerpt/reference on demand, skill policy, and prompt budget class. The runtime uses this both for prompt composition and write/tool safety, so context shape and permissions are not just soft prompt text.

The second major choice is structured state with markdown projection. Runtime truth is in SQLite tables for milestones, slices, tasks, artifacts, requirements, decisions, memories, verification evidence, worker coordination, runtime KV, gate runs, and dispatch ledgers. Markdown files remain important because agents and humans can read them, but drift repair regenerates projections from DB state rather than importing completion status from markdown.

The third choice is fail-closed source-writing isolation. Source-writing units are recognized from their manifest tool policy; in worktree isolation mode, `worktree-safety.ts` validates milestone id, canonical `.gsd/worktrees/<MID>` root, `.git` marker shape, registered git worktree membership, expected branch, non-empty project content, and lease ownership before dispatch.

Context Mode is another strong design. `gsd_exec` runs bash/node/python from the project root with timeout and capped output, writes full evidence under `.gsd/exec`, and returns only a short digest. `gsd_exec_search` finds prior runs so agents avoid repeating noisy commands. `gsd_resume` reads `.gsd/last-snapshot.md`, which is written before compaction and contains active unit context, top memories, and recent exec runs.

Verification is host-owned. Verification commands are discovered from task plans, preferences, package scripts, Python pytest markers, or simple Node test files. Commands are sanitized against redirects, command substitution, logical fallbacks, and prose-like strings; outputs are capped; evidence is written; retries use hashed failure contexts and pause on duplicate failures.

## Strengths

The repo has one of the clearest context-control implementations in this index: task size is defined by context-window fit, the model gets fresh sessions, and context is assembled from explicit artifacts with per-unit policy.

The prompt engineering is operational rather than decorative. Prompts specify working directory, stale-path handling, canonical DB tool calls, exact artifact templates, verification evidence, and closeout phrases. Planning prompts require files, inputs, expected outputs, executable verification, observability impact, and failure-mode coverage when applicable.

The runtime converts many prompt rules into gates. Planning units cannot edit source outside `.gsd/`; read-only and verification lanes restrict shell/subagent surfaces; worktree writes are blocked when isolation invariants are missing; direct `STATE.md` writes and some pending approval paths are guarded.

The long-run state model is unusually robust. It has stale-worker repair, dispatch claims, milestone leases, runtime KV, journal events, write-gate persistence, compaction checkpoints, crash recovery, and forensics reports. Those are the right primitives for unattended multi-hour or overnight runs.

The Context Mode command-output design is directly reusable. It reduces token pressure without throwing evidence away, and the search/resume tools make prior evidence retrievable by later turns.

The documentation and tests cover the control plane deeply. Reviewed docs explain auto mode, state authority, token optimization, skills, subagents, MCP, parallel orchestration, and cloud MCP. The source tree includes targeted tests for manifests, write gates, compaction snapshots, state reconciliation, worktree safety, verification, parallel orchestration, and DB invariants.

## Weaknesses

The system is very large. It includes a CLI, extension system, DB schema, prompts, TUI, web, desktop, daemon, MCP/cloud gateway, subagents, native helpers, and many compatibility paths. That scale is useful for research but too heavy to copy into a lab harness.

Some strictness is intentionally partial. `shouldBlockPlanningUnit` blocks known write/bash/subagent tools, but unknown tools pass through outside read-only mode for compatibility. A lab harness with a smaller tool surface should prefer deny-by-default for unknown write-capable tools.

Context budgets are partly advisory. Manifests declare `maxSystemPromptChars`, but comments state blown budgets log telemetry rather than necessarily truncating or failing. There is real truncation elsewhere, but the manifest budget itself is not a hard contract.

Some units still use unrestricted `tools: all` because closeout/validation may need source fixes. That is pragmatic, but it means the strongest safety story depends on when worktree isolation is enabled and whether source-writing units are correctly classified.

The parallel coordination model is explicitly single-host. It relies on local SQLite WAL, local process heartbeats, local worktrees, and same-machine command queues. This should not be treated as distributed orchestration.

The docs include ambitious developer guidance and synthesis documents that are not the same thing as runtime guarantees. The strongest evidence is the actual `src/resources/extensions/gsd` path; broad design docs should be treated as rationale and vocabulary, not proof that every idea is fully enforced.

## Ideas To Steal

Create a small `UnitContextManifest` equivalent for lab units such as research, plan, implement, review, verify, and handoff. Require every unit to declare context artifacts, memory policy, tools policy, and verification expectations.

Use structured runtime state as truth and markdown as projection. Agents should write through typed tools, not manually toggle status files, while humans still get readable artifacts in the repo.

Implement Context Mode as a separate primitive: capped exec output on disk, digest returned to the model, searchable prior runs, and a compaction resume snapshot.

Build a pre-dispatch invariant pipeline before every expensive model call: resource freshness, health, state reconciliation, dispatch decision, tool contract, root/worktree safety, and journal entry.

Model drift as typed records with detect/repair handlers and a small pass cap. Persistent drift should block dispatch and tell the operator which recovery command or artifact is involved.

Make verification evidence first-class. Store command, cwd, exit code, duration, verdict, truncated output, retry count, and failure hash so later agents do not rely on self-reported success.

Keep dynamic memory outside the stable system prompt when possible. GSD's volatile memory context preserves provider prompt-cache stability while still surfacing relevant prior knowledge.

Use planning-dispatch specialists carefully. Allow scout/reviewer/planner agents for read-heavy analysis, but gate implementation agents to source-writing execution units.

## Do Not Copy

Do not copy the full product architecture. Agentic Coding Lab can get most of the value from a smaller manifest, state, evidence, and verification layer.

Do not treat `gsd_exec` as a sandbox boundary. It is primarily a context and evidence tool; it still runs local subprocesses, so security-sensitive labs need OS/container isolation and permission gates.

Do not copy compatibility-driven pass-through behavior for unknown tools. A research harness can be stricter than a broad extension runtime.

Do not use SQLite/WAL worker coordination across machines or network filesystems. If the lab needs remote workers, use a real distributed lease/control plane.

Do not let prompt templates become the only enforcement mechanism. The useful GSD pattern is pairing prompt obligations with runtime gates and tests.

Do not assume markdown projections are safe to import as truth. GSD's current direction is DB-authoritative; that should be preserved.

## Fit For Agentic Coding Lab

Fit is very high for `context-control`. This repo provides concrete patterns for meta-prompting, context assembly, artifact schemas, long-run state, memory, verification gates, worktree safety, compaction recovery, and coding-agent portability.

The best adaptation is a smaller Agentic Coding Lab control plane:

- Unit manifests for each lab workflow step.
- A structured state store with markdown projections.
- Typed completion and evidence tools.
- Digesting exec/search/resume tools.
- Drift handlers for stale state, missing artifacts, stale workers, and unverified claims.
- Worktree or container root validation before source writes.
- Verification evidence as a required closeout input.

The repo is less attractive as a dependency candidate unless the lab wants to adopt GSD Pi as a product. Its implementation is valuable mainly as a pattern source and test corpus for agent control-plane design.

## Reviewed Paths

- `README.md`: install, project scope, runtime state in `.gsd/`, common commands, workflow claims, verification commands, and package layout.
- `VISION.md` and `CONTEXT.md`: project principles, continuation context, domain glossary, state reconciliation, worktree safety, recovery taxonomy, and tool contract language.
- `package.json`: npm package metadata, Node/pnpm requirements, build/test/verify scripts, bundled dependencies, and portability surface.
- `mintlify-docs/introduction.mdx`, `gitbook/core-concepts/auto-mode.md`, `gitbook/core-concepts/project-structure.md`, and `docs/user-docs/token-optimization.md`: user-facing hierarchy, state authority, fresh sessions, Context Mode, tool policies, verification gates, token profiles, and adaptive routing.
- `docs/user-docs/skills.md`, `docs/user-docs/subagents.md`, `docs/user-docs/parallel-orchestration.md`, and `docs/user-docs/cloud-mcp-gateway.md`: skills portability, subagent run state, worker coordination, and MCP/runtime boundaries.
- `docs/prompt-map.md` and `docs/db-map.md`: documented prompt pipeline, context stack, tool policy modes, prompt inventory, DB schema, migrations, and table inventory.
- `docs/dev/building-coding-agents/03-state-machine-context-management.md`, `04-optimal-storage-for-project-context.md`, `11-god-tier-context-engineering.md`, and `13-long-running-memory-fidelity.md`: design rationale for layered context, structured state, context budgeting, and memory reconciliation.
- `src/resources/extensions/gsd/prompts/system.md`, `plan-slice.md`, `execute-task.md`, and `validate-milestone.md`: meta-prompt posture, stale-path rules, DB-backed tool contracts, planning schema, verification evidence, and parallel reviewer orchestration.
- `src/resources/extensions/gsd/templates/plan.md`, `task-plan.md`, `task-summary.md`, and related templates: spec-driven artifact schema and machine-parsed plan/summary fields.
- `src/resources/extensions/gsd/unit-context-manifest.ts`, `unit-context-composer.ts`, `tool-contract.ts`, `auto-prompts.ts`, `context-budget.ts`, and `bootstrap/system-context.ts`: manifest design, context lanes, artifact policies, prompt composition, memory injection, budget allocation, and cache-stable system context.
- `src/resources/extensions/gsd/bootstrap/write-gate.ts` and `bootstrap/register-hooks.ts`: runtime write-gate state, planning-unit tool policy enforcement, queue/gate guards, compaction hook, and worktree write blocking.
- `src/resources/extensions/gsd/auto/loop.ts`, `auto/phases.ts`, `auto/run-unit.ts`, `auto/workflow-kernel.ts`, `auto/orchestrator.ts`, and `auto-dispatch.ts`: auto-mode loop, pre-dispatch gates, dispatch resolution, stuck detection, session creation, tool-contract/worktree safety flow, and pure decision helpers.
- `src/resources/extensions/gsd/state-reconciliation/**`, `worktree-safety.ts`, `worktree-lifecycle.ts`, `worktree-state-projection.ts`, and `db/unit-dispatches.ts`: drift detection/repair, worktree validation, source-write root safety, and dispatch ledger mechanics.
- `src/resources/extensions/gsd/tools/exec-tool.ts`, `exec-search-tool.ts`, `resume-tool.ts`, `exec-sandbox.ts`, `exec-history.ts`, `compaction-snapshot.ts`, and `context-mode-snapshot.ts`: Context Mode implementation, persisted command evidence, search, and resume snapshots.
- `src/resources/extensions/gsd/memory-store.ts`, `memory-extractor.ts`, `tools/memory-tools.ts`, `knowledge-projection.ts`, and `memory-backfill.ts`: memory CRUD, ranking, extraction, knowledge/decision backfill, and prompt/query surfaces.
- `src/resources/extensions/gsd/verification-gate.ts`, `auto-verification.ts`, `custom-verification.ts`, `verification-evidence.ts`, and `auto/verification-retry-policy.ts`: command discovery, sanitization, evidence output, retry behavior, and custom workflow verification.
- Representative tests under `src/resources/extensions/gsd/tests/**`: reviewed by filename and targeted source references for manifest, write-gate, reconciliation, worktree, compaction, verification, parallel, DB, and prompt-regression coverage.

## Excluded Paths

- `studio/`, `web/`, `vscode-extension/`, and most TUI rendering assets: useful product surfaces but not the core context-control execution path.
- `mintlify-docs/images`, font files, icons, HTML export templates, and bitmap/SVG branding assets: presentation assets rather than agent orchestration mechanics.
- `packages/native/**`, `native/**`, and platform packaging scripts: relevant for distribution and performance but not central to context engineering or verification gates.
- Lockfiles and generated build artifacts such as `pnpm-lock.yaml`, `dist-test` outputs when present, and generated fixtures: useful for reproducibility but not independent design evidence.
- Most localization files under `docs/zh-CN/**`: redundant with reviewed English docs for this analysis.
- Large test fixture trees and golden outputs: sampled through representative tests and source files; exhaustive fixture reading would mostly duplicate expected-output data.
- UI-only dashboard/studio/web state management beyond docs and high-level package metadata: intentionally excluded to keep the review focused on coding-agent context control.
