# gsd-build/get-shit-done

- URL: https://github.com/gsd-build/get-shit-done
- Category: context-control
- Stars snapshot: 61,461 (GitHub REST API repository search captured in research/index.md on 2026-05-11)
- Reviewed commit: 8cd874969cc1e8d52b6c6464c89b36f25528e2d1
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: in-scope
- Verdict: High-value context-control system. Steal its artifact contracts, staged gates, budgeted routing, and subagent handoff patterns; do not copy the whole installer or runtime surface.

## Why It Matters

GSD is not a small context compression trick. It is an end-to-end attempt to keep agent work from decaying by moving durable state out of chat and into explicit project artifacts, then forcing every phase to consume only the artifacts and paths it needs. The strongest ideas for Agentic Coding Lab are the phase-specific context ledgers, decision coverage checks, direct-to-disk subagent outputs, and explicit boundaries between discussion, research, planning, execution, and verification.

It is also useful as a stress case: the repo shows what happens when prompt workflows grow into a product. The design has many good guardrails, but the surface area is large, docs drift against generated inventory, and several security controls are advisory rather than hard enforcement.

## What It Is

GSD is an npm-distributed workflow system for AI coding runtimes. The installer deploys commands, skills, agents, hooks, SDK query tools, and planning templates into tools such as Claude Code, Codex, Gemini, Copilot, Cursor, Windsurf, OpenCode, and others.

The core loop is:

1. Map an existing codebase when needed.
2. Create `.planning/PROJECT.md`, `REQUIREMENTS.md`, `ROADMAP.md`, and `STATE.md`.
3. Run a phase discussion to produce `CONTEXT.md` and locked implementation decisions.
4. Research and produce executable `PLAN.md` files.
5. Execute plans with fresh subagent contexts, often in waves and worktrees.
6. Verify against roadmap success criteria, plan must-haves, summaries, and actual code.

The main implementation is prompt/workflow text plus a TypeScript/Node SDK used as a typed query and mutation layer over the `.planning` filesystem.

## Research Themes

- Token efficiency: Uses two-stage namespace routers, minimal installs, lazy-loaded workflow mode files, direct-to-disk agent outputs, workflow size budgets, path-only subagent prompts, context-window-adaptive reads, and a documented MCP token budget warning. The architecture doc claims namespace routing cuts eager command descriptions from about 2,150 tokens to about 120 tokens.
- Context control: Treats `.planning` files as the canonical memory layer. `STATE.md` is the short-term pointer, `PROJECT.md` and `REQUIREMENTS.md` are durable project truth, `ROADMAP.md` defines phase goals, `CONTEXT.md` carries phase decisions with `D-XX` ids, and `SUMMARY.md` records dependency metadata after execution.
- Sub-agent / multi-agent: Heavy work is delegated to agents with fresh contexts: researcher, pattern mapper, planner, plan checker, executor, verifier, codebase mapper, and many specialists. Execute-phase groups plans into dependency waves and can isolate work with git worktrees where the runtime supports it.
- Domain-specific workflow: The system is optimized for solo-dev spec-driven coding. It supports new-project setup, existing-code mapping, PRD and ADR ingest express paths, UI and AI-specific planning aids, TDD mode, MVP mode, UAT, and drift checks.
- Error prevention: Strong pre-execution plan checks, post-execution verification, package provenance gates, worktree safety checks, explicit commit protocols, read-before-edit guards, prompt-injection scanners, schema and codebase drift checks, and decision coverage gates. Several hook controls warn instead of blocking.
- Self-learning / memory: Keeps learnings in project artifacts rather than hidden chat memory. `SUMMARY.md` frontmatter records `requires`, `provides`, `affects`, task commits, files, decisions, patterns, deviations, and issues. `PROJECT.md`, `STATE.md`, `ROADMAP.md`, and learning workflows evolve after phases.
- Popular skills: Commands are installed as runtime-specific skills or command files. The most reusable skill pattern is the small namespace router (`gsd-workflow`, `gsd-project`, `gsd-quality`, `gsd-context`, `gsd-manage`, `gsd-ideate`) that points to concrete commands without listing the whole command library in every prompt.

## Core Execution Path

Installation starts in `bin/install.js`. It detects the target runtime, copies command and agent assets, rewrites tool declarations for that runtime, and optionally installs hooks. The installer has a `--minimal` path that installs only the main loop to reduce cold-start prompt overhead.

For an existing codebase, `/gsd-map-codebase` spawns mapper agents that write `.planning/codebase/STACK.md`, `ARCHITECTURE.md`, `STRUCTURE.md`, `CONVENTIONS.md`, `TESTING.md`, `CONCERNS.md`, and related files directly. The orchestrator receives confirmations rather than pasted analysis, which keeps the main context small.

Project setup creates `.planning/PROJECT.md`, `REQUIREMENTS.md`, `ROADMAP.md`, and `STATE.md`. These are the long-lived state that later workflows read first.

`/gsd-discuss-phase` loads workflow init data, prior state, relevant codebase maps, canonical references, and user constraints. It asks for implementation decisions within the current roadmap phase, rejects scope creep into deferred ideas, writes `CONTEXT.md` with decision ids and canonical references, writes `DISCUSSION-LOG.md`, commits the discussion artifacts, and updates `STATE.md`.

`/gsd-plan-phase` calls `gsd-sdk query init.plan-phase`, optionally runs PRD or ADR ingest, then delegates research to `gsd-phase-researcher`. It may run `gsd-pattern-mapper`, then invokes `gsd-planner` to create `PLAN.md` files with exact files, tasks, verification commands, `read_first`, and `must_haves`. `gsd-plan-checker` runs an adversarial loop with revision limits. The phase ends with requirement coverage and decision coverage checks before plans are committed and state is updated.

`/gsd-execute-phase` calls `gsd-sdk query init.execute-phase`, builds a phase plan index, groups plans into dependency waves, and dispatches executor agents. Worktree-capable runtimes can run isolated agents; Codex currently fails closed when worktree execution is requested because it has no matching isolation primitive. Executors commit implementation changes, write and commit summaries, and return a completion marker. The orchestrator has a filesystem fallback: commits plus summary can prove completion even if the runtime loses the final message.

After each wave, GSD validates hooks if they were skipped in worktrees, merges worktrees from a manifest, runs build/test gates, performs drift checks, and invokes `gsd-verifier`. At completion it updates shared artifacts once, records learnings, closes todos, updates project memory, and can advance to the next phase.

## Architecture

- Command layer: `commands/gsd/*.md` are user-facing entrypoints. Namespace command files route broad requests to concrete skills.
- Workflow layer: `get-shit-done/workflows/*.md` contains the phase runbooks. The workflows are intentionally thin orchestrators that load state, dispatch agents, apply gates, and update artifacts.
- Agent layer: `agents/*.md` contains role prompts for planning, execution, verification, mapping, research, review, and specialists.
- Reference layer: `get-shit-done/references/*.md` defines shared contracts such as context budgets, gates, checkpoints, agent contracts, and mandatory initial reads.
- Template layer: `get-shit-done/templates/*.md` defines the artifact schemas for project, state, roadmap, context, spec, plan, summary, verification, and UAT files.
- SDK/query layer: `sdk/src/query/*.ts` provides typed filesystem reads, phase lookup, config access, plan indexing, decision coverage checks, commits, state mutation, and verification helpers.
- Hook layer: `hooks/*.js` and `hooks/*.sh` provide advisory context monitoring, prompt-injection scanning, read-before-edit checks, workflow guardrails, session state, phase boundaries, and commit validation.
- State layer: `.planning` is the database. There is no server-side state store; artifacts are inspectable and committable.

## Design Choices

- Artifact-first memory: Instead of relying on chat history, every workflow is forced through named Markdown and JSON artifacts with explicit consumers.
- Phase boundaries: Discussion captures decisions, planning turns decisions into executable prompts, execution changes code, and verification checks outcomes. This reduces context mixing.
- Decision ids as contracts: `CONTEXT.md` decisions use `D-XX` ids, and the SDK can block plans that fail to include trackable decisions.
- Fresh context for heavy work: Subagents read files themselves and write results to disk, avoiding large pasted summaries in the orchestrator context.
- Path passing over content passing: Workflows often pass file paths to agents instead of embedding file contents.
- Context budget as a first-class input: Workflows change read depth and prompt richness based on configured context window and current usage.
- Goal-backward checking: Plan checker and verifier start from roadmap success criteria and requirements, not from the agent's claimed completion.
- Git as control plane: Execution relies on atomic commits, summary commits, worktree manifests, and explicit path staging to detect partial or unsafe states.
- Advisory safety hooks: Many protections warn rather than block, preserving runtime compatibility while leaving some risk to the user.

## Strengths

- Excellent practical model for externalized context: the artifact set is concrete, ordered, and mapped to workflow consumers.
- Strong separation of roles: researcher, planner, checker, executor, verifier, and mapper each have distinct context needs and output contracts.
- Good examples of token-aware orchestration: namespace routers, lazy references, minimal install, direct-to-disk outputs, and context-window adaptation.
- Verification is built into the workflow rather than bolted on. Plan checks run before execution and verifier checks run after implementation.
- Parallel execution design is unusually detailed: dependency waves, file-overlap detection, worktree manifests, summary rescue, and post-wave shared artifact updates.
- The test suite covers many workflow invariants: size budgets, context coverage gates, prompt-injection scanning, read loop guards, worktree safety, package legitimacy, TDD mode, verification quality, and installer runtime transforms.

## Weaknesses

- Large surface area. The repo includes many commands, workflows, agents, hooks, runtime adapters, generated inventories, and tests. A smaller lab system should extract patterns rather than adopt the package wholesale.
- Prompt logic is partly enforced by convention. Markers such as completion strings, headings, and Markdown sections are useful but brittle.
- Documentation drift exists. Some docs describe older agent or command counts, while `docs/INVENTORY.md` is treated as authoritative.
- Security hooks are mostly advisory. Prompt-injection and read guards warn, but a compromised or inattentive agent can continue.
- The README recommends running Claude Code with broad permission skipping. That may fit the author's workflow, but it is not a safe default for a lab harness.
- There is no strong evidence that the full workflow improves coding outcomes beyond its own contract tests. The tests validate the system mechanics more than end-task quality.
- File-based state is inspectable but can become noisy. Without pruning and clear ownership, `.planning` can grow into another context management burden.

## Ideas To Steal

- A small, typed context ledger set: `PROJECT.md`, `REQUIREMENTS.md`, `ROADMAP.md`, `STATE.md`, per-phase `CONTEXT.md`, `PLAN.md`, `SUMMARY.md`, and `VERIFICATION.md`.
- Decision ids in phase context plus automated plan coverage checks.
- `init.<workflow>` query commands that return compact JSON paths and config, keeping prompts stable and avoiding repeated filesystem discovery.
- Namespace routers that advertise broad workflow classes while keeping concrete commands directly invocable.
- Direct-to-disk subagent outputs with the orchestrator receiving only path, status, and line-count confirmation.
- Goal-backward plan checking before execution and goal-backward verification after execution.
- `SUMMARY.md` frontmatter with dependency metadata: `requires`, `provides`, `affects`, files, commits, decisions, deviations, and issues.
- Context-window-adaptive read policy: richer context for large windows, strict path and summary mode for smaller windows.
- Worktree manifest cleanup that refuses broad worktree discovery and only cleans what the orchestrator created.
- Package legitimacy gate that treats ambiguous package installs as a human checkpoint instead of guessing.
- Mandatory `read_first`, `must_haves`, exact file paths, and verification commands in every executable plan.

## Do Not Copy

- Do not copy the whole multi-runtime installer into Agentic Coding Lab. It solves distribution for a product, not a minimal research harness.
- Do not copy the broad permission-skipping posture as a default.
- Do not copy the entire command and agent catalog. The useful unit is the contract between artifacts and phases.
- Do not rely on advisory security hooks where the lab needs hard enforcement.
- Do not build a large Markdown protocol without schema tests and migration rules.
- Do not use runtime-specific prompt transforms as the primary abstraction unless the lab explicitly targets those runtimes.
- Do not make context management depend on users remembering many command flags.

## Fit For Agentic Coding Lab

Fit is high for design patterns and moderate for implementation reuse. The best extraction is a smaller artifact-driven workflow:

1. A project memory file and short state pointer.
2. A phase context file with decision ids and canonical references.
3. A planner that must cite those ids in plans.
4. A checker that blocks missing decisions or requirements.
5. Executors that write summaries with dependency metadata.
6. A verifier that checks actual files and tests, not agent claims.

The lab should keep the GSD idea of durable, inspectable context artifacts, but implement a narrower path with fewer commands, stricter schemas, and hard validation where safety matters.

## Reviewed Paths

- Repository metadata and install surface: `README.md`, `package.json`, `bin/install.js`, `docs/ARCHITECTURE.md`, `docs/COMMANDS.md`, `docs/CONFIGURATION.md`, `docs/CLI-TOOLS.md`, `docs/USER-GUIDE.md`, `docs/INVENTORY.md`.
- Main commands: `commands/gsd/plan-phase.md`, `commands/gsd/execute-phase.md`, `commands/gsd/ns-workflow.md`.
- Core workflows: `get-shit-done/workflows/discuss-phase.md`, `get-shit-done/workflows/plan-phase.md`, `get-shit-done/workflows/execute-phase.md`, `get-shit-done/workflows/execute-plan.md`, `get-shit-done/workflows/map-codebase.md`.
- Main agents: `agents/gsd-planner.md`, `agents/gsd-plan-checker.md`, `agents/gsd-executor.md`, `agents/gsd-verifier.md`, `agents/gsd-phase-researcher.md`, `agents/gsd-codebase-mapper.md`.
- Shared references: `get-shit-done/references/context-budget.md`, `get-shit-done/references/agent-contracts.md`, `get-shit-done/references/gates.md`, `get-shit-done/references/checkpoints.md`, `get-shit-done/references/mandatory-initial-read.md`.
- Artifact templates: `get-shit-done/templates/context.md`, `get-shit-done/templates/project.md`, `get-shit-done/templates/roadmap.md`, `get-shit-done/templates/spec.md`, `get-shit-done/templates/summary.md`, `get-shit-done/templates/state.md`.
- SDK query paths: `sdk/src/query/init.ts`, `sdk/src/query/phase.ts`, `sdk/src/query/check-decision-coverage.ts`, `sdk/src/query/commit.ts`, `sdk/src/query/state-mutation.ts`, `sdk/src/query/verify.ts`.
- Hooks and guards: `hooks/gsd-context-monitor.js`, `hooks/gsd-prompt-guard.js`, `hooks/gsd-read-injection-scanner.js`, `hooks/gsd-read-guard.js`, `hooks/gsd-workflow-guard.js`, `hooks/gsd-validate-commit.sh`, `hooks/gsd-session-state.sh`, `hooks/gsd-phase-boundary.sh`, `hooks/lib/git-cmd.js`.
- Validation paths: `tests/workflow-size-budget.test.cjs`, `tests/agent-size-budget.test.cjs`, `tests/enh-2789-description-budget.test.cjs`, `tests/context-utilization.test.cjs`, `tests/bug-1974-context-exhaustion-record.test.cjs`, `tests/prompt-injection-scan.test.cjs`, `tests/read-injection-scanner.test.cjs`, `tests/bug-2346-agent-read-loop-guards.test.cjs`, `tests/bug-2492-context-coverage-gate.test.cjs`, `tests/subagent-timeout.test.cjs`, `tests/bug-2943-config-get-context-window-default.test.cjs`, `tests/pattern-mapper.test.cjs`, `tests/worktree-safety.test.cjs`, `tests/worktree-safety-policy.test.cjs`, `tests/bug-2075-worktree-deletion-safeguards.test.cjs`, `tests/bug-2924-worktree-head-attachment.test.cjs`, `tests/bug-3097-3099-executor-worktree-path-safety.test.cjs`, `tests/bug-3384-worktree-cleanup-manifest.test.cjs`, `tests/bug-2838-summary-rescue-gitignored-planning.test.cjs`, `tests/package-legitimacy-gate.test.cjs`, `tests/execute-mvp-tdd-gate.test.cjs`, `tests/tdd-mode.test.cjs`, `tests/verify-test-quality.test.cjs`, `tests/verification-overrides.test.cjs`, `tests/feat-3309-human-verify-mode.test.cjs`, `tests/enh-3209-plan-phase-ingest-adr.test.cjs`, `tests/adr-parser.test.cjs`, `tests/security.test.cjs`, `tests/security-scan.test.cjs`, `tests/installer-migration-install-integration.test.cjs`, `tests/codex-config.test.cjs`, `tests/bug-2979-hook-absolute-node.test.cjs`, `tests/bug-3017-codex-hook-absolute-node.test.cjs`, `tests/bug-3245-codex-toml-floats.test.cjs`, `sdk/src/query/config-mutation.test.ts`.

## Excluded Paths

- `assets/*.png`, `assets/*.svg`, and terminal artwork: binary or UI-only branding assets, not relevant to execution or context-control design.
- Localized README and docs translations such as `README.zh-CN.md`, `README.ja-JP.md`, `README.ko-KR.md`, `README.pt-BR.md`, and translated docs directories: redundant with the reviewed English source for this workflow analysis.
- `package-lock.json` and `sdk/package-lock.json`: dependency lockfiles, useful for install reproducibility but not informative for context-control mechanics.
- Generated inventories and alias files such as `docs/INVENTORY-MANIFEST.json`, `get-shit-done/bin/lib/command-aliases.generated.cjs`, and `sdk/src/query/command-aliases.generated.ts`: generated from source command metadata and not the design source of truth.
- Release, changelog, handover, and migration-history documents: useful project history but outside the current execution path reviewed here.
- Test fixtures and golden fixture data under `tests/fixtures` and `sdk/src/golden/fixtures`: supporting data for validation tests, not independent workflow design.
- Runtime compatibility adapters not listed above in full detail: sampled through installer, docs, and tests, but the context-control review focused on the shared workflow contracts rather than every runtime transform.
