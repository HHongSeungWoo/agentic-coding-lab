# gsd-build/gsd-2

- URL: https://github.com/gsd-build/gsd-2
- Category: context-control
- Stars snapshot: 7,359 (GitHub REST API, captured 2026-05-12)
- Reviewed commit: 2841a1e440fda1902f86fc6e1bb48f8f0e683d18
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong pattern source for context-controlled autonomous coding runs. Adopt the state, manifest, compaction, drift-repair, and verification ideas selectively; do not copy the full product architecture.

## Why It Matters

GSD 2 is a mature example of "context as runtime state" rather than context as one large prompt. It treats a long coding effort as a sequence of bounded units, gives each unit a fresh session, injects only the artifacts and tools that unit needs, records state in SQLite, projects reviewable markdown, and uses repair gates before spending another model call.

For Agentic Coding Lab, the useful part is not the whole CLI. The useful part is the control plane: per-unit context manifests, searchable command digests, compaction snapshots, drift detection, worktree safety, dispatch claims, and host-owned verification evidence.

## What It Is

GSD 2 is a TypeScript CLI and Pi SDK extension for spec-driven autonomous coding. Its main workflow is `/gsd auto`: plan milestones, break them into slices and tasks, dispatch tasks into fresh agent sessions, enforce git/worktree isolation, track runtime state in `gsd.db`, and recover from crashes or stale workers.

The repo also ships a headless orchestration path. `gsd headless --output-format json --context spec.md new-milestone --auto` launches a monitored subprocess, and `gsd headless query` returns machine-readable state for external orchestrators. Bundled skills and templates show how a caller writes a spec, launches GSD, polls state, handles blockers, and resumes.

## Research Themes

- Token efficiency: Fresh sessions per unit, token profiles (`budget`, `balanced`, `quality`), context-window budget allocation, section-boundary truncation, command-output digests, searchable exec history, compaction snapshots, observation masking, and cache-stable system prompt design.
- Context control: DB-authoritative state, markdown projection, per-unit `UnitContextManifest`, typed artifact policies, Context Mode tools (`gsd_exec`, `gsd_exec_search`, `gsd_resume`), tool policy lanes, and runtime write gates.
- Sub-agent / multi-agent: Parallel slice/task dispatch, planning/review specialist policies, DB leases, dispatch claims, worker metadata, stale-worker repair, and journaled handoff. Coordination is explicitly single-host SQLite/WAL, not distributed orchestration.
- Domain-specific workflow: Milestone -> slice -> task hierarchy, where a task should fit one context window. Deep planning covers project preferences, requirements, research decisions, roadmap creation, implementation, UAT, milestone validation, and completion.
- Error prevention: Pre-dispatch resource-version, health, state reconciliation, tool-contract, worktree-safety, idempotency, verification, retry, and pause gates. Source-writing units fail closed when worktree invariants are wrong.
- Self-learning / memory: DB-backed memories with categories, confidence, hit count, time decay, optional FTS/semantic lookup, and memory-backed architecture decisions. Dynamic memory is injected into volatile context to preserve prompt cache stability.
- Popular skills: Bundled `gsd-orchestrator` and `gsd-headless` skills encode spec launch, polling, blocker handling, and resume workflows. The skill idea is useful, but some bundled skill docs lag the code.

## Core Execution Path

The main path starts in `src/loader.ts`, which performs fast version/help handling, checks Node/git prerequisites, sets package/resource environment variables, and imports the CLI. `src/cli.ts` wires Pi SDK managers, bundled resources, headless routing, onboarding, model validation, and extension loading. The GSD extension registers `/gsd`, tools, hooks, dynamic tools, memory tools, exec tools, query tools, and write gates under `src/resources/extensions/gsd`.

Auto mode then runs a dispatch loop. The documented and implemented sequence is: acquire or validate a lock, guard resource versions, run health checks, reconcile DB/projection drift, decide the next unit, compile the unit tool contract, validate or prepare the worktree, journal the transition, execute the unit prompt, synchronize results, run verification, and either advance, retry, block, or pause.

The model does not receive the entire repo state. It receives a unit prompt built from task/slice plans, prior summaries, dependency summaries, roadmap excerpts, decisions, knowledge, relevant memories, templates, runtime context, and Context Mode instructions. Noisy command output is routed through `gsd_exec`; stdout/stderr are written under `.gsd/exec`, and the model receives a digest plus search/resume tools.

## Architecture

The repo is a monorepo centered on a TypeScript CLI:

- `src/loader.ts` and `src/cli.ts`: bootstrap, environment setup, CLI routing, bundled extension registration.
- `src/headless.ts` and `src/headless-events.ts`: JSON/event-oriented subprocess runner, query/resume behavior, and exit codes.
- `src/resources/extensions/gsd`: core GSD extension, `/gsd` command, auto orchestrator, workflow state, memory, Context Mode, verification, worktree safety, write gate, and tools.
- `packages/pi-coding-agent`: shared Pi coding-agent runtime used by the extension.
- `packages/mcp-server`: MCP server exposing read/query, workflow, memory, journal, and Context Mode tools.
- `gsd-orchestrator`: external-facing skill and templates for launching and monitoring GSD from a spec.

State is intentionally split by role. `gsd.db` is authoritative runtime state. Markdown files are reviewable projections. `.gsd/journal/*.jsonl` records event history. `.gsd/runtime` stores write-gate and runtime metadata. `.gsd/exec` stores command evidence. `.gsd/last-snapshot.md` stores compact resume context.

## Design Choices

The strongest design choice is `UnitContextManifest`. Each known unit type declares skills, knowledge, memory, preferences, Context Mode lane, tool policy, artifact requirements, and budget posture. Tests require every known unit to have a manifest and require every manifest to declare a tool policy.

The second key choice is drift-first orchestration. Before dispatch, GSD derives state, detects known drift classes, repairs idempotently, re-derives, and caps repair passes. Drift classes include stale sketch flags, unmerged merge state, stale renders, stale workers, unregistered milestones, roadmap divergence, and missing completion timestamps.

The third key choice is fail-closed source writing. Worktree safety verifies safe milestone IDs, expected `.gsd/worktrees/<MID>` roots, git markers, registered git worktrees, expected branch names, and leases before source-writing units proceed.

Verification is host-owned. The gate discovers commands from preferences, task plan `verify` fields, or package scripts, sanitizes command strings, runs them with timeouts, caps output, writes evidence JSON, retries bounded failures, and pauses on duplicate failure context or missing runnable checks.

## Strengths

GSD makes context boundaries explicit. A task is expected to fit one context window, and the system has a manifest-level contract for what each unit can see and do.

Its recovery model is unusually concrete. Dispatch claims, leases, stale-worker repair, reconciliation passes, journal events, and machine-readable headless query output make a long run inspectable after interruption.

Its Context Mode design is practical. Keeping raw command output on disk while returning compact digests directly attacks one of the main context bloat sources in coding agents.

Its test suite covers control-plane behavior, not only happy-path commands. Notable tests cover manifest coverage, composer output, worktree safety, compaction snapshots, verification gate discovery, retry policy, drift repair, and prompt-cache stability.

## Weaknesses

The system is large and invasive. It bundles CLI, extension runtime, DB schema, worktrees, headless subprocess control, MCP, memory, verification, docs, and UI surfaces. Copying it wholesale would import product complexity into Agentic Coding Lab.

Some documentation lags the implementation. The bundled `gsd-headless` skill describes blocked exit code `2`, while `src/headless-events.ts` and `gsd-orchestrator` use blocked exit code `10`. Older project-structure docs still imply disk files are primary, while current docs say SQLite is authoritative.

`gsd_exec` is an output and context sandbox, not strong OS containment. It runs bash/node/python subprocesses in the project cwd with an allowlisted environment and capped output. Mutation safety depends on higher-level tool policy and write-gate enforcement.

The write gate intentionally lets unknown tools through for compatibility in some planning contexts. That is pragmatic for an extensible agent runtime, but it is a bypass risk when new write-capable tools appear.

Several mechanisms are best-effort by design, especially journaling and some registration paths. That improves UX but means absence of evidence must be treated carefully in diagnostics.

## Ideas To Steal

Use a per-unit context manifest for every autonomous workflow step. Make context artifacts, memory policy, tool policy, and budget class data-driven and test-covered.

Keep runtime state authoritative in a structured store, then project markdown for human review. Avoid mixed authority where agents can silently diverge between DB and files.

Add a small Context Mode layer: command runner with output persisted to disk, digest returned to model, search over previous runs, and a compact resume snapshot after compaction.

Run a pre-dispatch invariant pipeline before every model call: resource/version guard, health, drift reconciliation, dispatch decision, tool contract, worktree/write safety, and journal event.

Model drift as a typed catalog with idempotent detect/repair handlers and a low max-pass cap. Persistent drift should block dispatch, not become another prompt instruction.

Make verification evidence first-class. Store command, exit code, capped output, retries, failure hashes, and final verdict as artifacts that later units can read.

Inject dynamic memory outside the stable system prompt when possible. Keep the long-lived system prompt cacheable, and route memories by unit/query.

## Do Not Copy

Do not copy the whole GSD runtime into Agentic Coding Lab. The valuable ideas can be implemented as smaller contracts and harnesses without taking on the full CLI/product surface.

Do not rely on command-output sandboxing as a security boundary. If a lab worker can run shell, use OS/container/worktree controls in addition to digesting stdout.

Do not allow unknown future tools by default in strict planning or read-only units. Compatibility is useful in GSD's broad extension runtime, but a lab harness should prefer deny-by-default for write-capable unknowns.

Do not let docs and skills be independent truth sources. GSD shows how stale skill docs can create operational confusion around exit codes and state authority.

Do not assume SQLite/WAL coordination applies to distributed workers. GSD explicitly targets single-host operation; cross-host labs need a different lease and storage layer.

## Fit For Agentic Coding Lab

This repo is in-scope for `context-control`. It gives concrete implementation patterns for context budgeting, unit-scoped prompts, compaction survival, command-output compression, state reconciliation, worktree safety, verification gates, and headless orchestration.

The best near-term fit is a smaller Agentic Coding Lab "control plane" pattern:

- Define lab unit manifests for research, plan, implement, review, verify, and handoff.
- Store run state and evidence in structured files or SQLite, with markdown projections for review.
- Add typed drift detectors for stale plans, missing evidence, stale worker claims, and unmerged handoffs.
- Add a digesting exec wrapper and searchable command history.
- Require host-owned verification evidence before marking a unit complete.

The repo should not be treated as a reusable dependency candidate unless Agentic Coding Lab decides to adopt GSD as a whole workflow product. Its design is more valuable than its package surface for this category.

## Reviewed Paths

- `README.md`: product overview, auto-mode loop, Context Engineering, preferences, git isolation, crash recovery, and architecture summary.
- `CONTEXT.md`: domain glossary, current decisions, drift catalog, worktree safety, and recovery model.
- `VISION.md`: project values and boundaries.
- `docs/user-docs/auto-mode.md`, `docs/user-docs/token-optimization.md`, `gitbook/core-concepts/auto-mode.md`, `gitbook/reference/commands.md`, `gitbook/configuration/mcp-servers.md`: user-facing workflow, command, token, and MCP docs.
- `gsd-orchestrator/SKILL.md`, `gsd-orchestrator/workflows/build-from-spec.md`, `gsd-orchestrator/workflows/monitor-and-poll.md`, `gsd-orchestrator/templates/spec.md`: headless spec orchestration and polling workflow.
- `src/loader.ts`, `src/cli.ts`, `src/headless.ts`, `src/headless-events.ts`: entry points and headless control.
- `src/resources/extensions/gsd/index.ts`, `bootstrap/register-extension.ts`, `commands/index.ts`: extension and command registration.
- `src/resources/extensions/gsd/unit-context-manifest.ts`, `unit-context-composer.ts`, `auto-prompts.ts`, `context-budget.ts`, `context-masker.ts`: context manifest, composition, budgeting, and masking.
- `src/resources/extensions/gsd/bootstrap/register-hooks.ts`, `bootstrap/exec-tools.ts`, `bootstrap/write-gate.ts`: compaction, provider request hooks, Context Mode tools, and write policy.
- `src/resources/extensions/gsd/compaction-snapshot.ts`, `exec-sandbox.ts`, `exec-history.ts`, `tools/exec-tool.ts`, `tools/exec-search-tool.ts`, `tools/resume-tool.ts`, `tools/context-mode-tool-result.ts`: Context Mode implementation.
- `src/resources/extensions/gsd/auto/orchestrator.ts`, `auto/phases.ts`, `state-reconciliation/*`, `worktree-safety.ts`, `auto/workflow-dispatch-claim.ts`, `auto/workflow-dispatch-ledger.ts`, `workflow-manifest.ts`, `journal.ts`: dispatch, reconciliation, safety, ledger, manifest, and journal mechanics.
- `src/resources/extensions/gsd/verification-gate.ts`, `auto-verification.ts`, `auto/verification-retry-policy.ts`: verification discovery, evidence, retry, and pause behavior.
- `src/resources/extensions/gsd/memory-store.ts`, `bootstrap/system-context.ts`, `context-store.ts`: memory and knowledge injection.
- `packages/mcp-server/README.md`, `packages/mcp-server/src/index.ts`: MCP server capabilities.
- Representative tests for unit manifests, context composer, drift repair, worktree safety, compaction snapshots, verification gate, verification retry, and prompt-cache stability.

## Excluded Paths

- `packages/pi-coding-agent/src/core/export-html/vendor/highlight.min.js` and related export-html vendor assets: generated/minified UI support, not core context-control behavior.
- `web/`, `studio/`, `vscode-extension/`, and most TUI component/theme/rendering paths: UI surfaces rather than the runtime context-control path.
- `native/` and `packages/native/**`: native wrapper/build concerns, not the agent workflow contract.
- `docker/`, `mintlify-docs/images`, `docs/dev/tui-*.html`, report rendering assets, image assets, and binary/golden UI fixtures: generated, binary, or presentation-only paths.
- Large fixture and snapshot trees were sampled through representative tests rather than exhaustively read because they mainly encode expected output, not new workflow mechanics.
- `node_modules` was not present in the review clone and would be vendor code if present.
