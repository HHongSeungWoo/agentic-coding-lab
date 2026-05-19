# foryourhealth111-pixel/Vibe-Skills

- URL: https://github.com/foryourhealth111-pixel/Vibe-Skills
- Category: context-control
- Stars snapshot: 2,057 (GitHub REST API repository search, captured 2026-05-11)
- Reviewed commit: 029869f3f6ea44d1a76b7e72596f6bb4b78589f3
- Reviewed at: 2026-05-19
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong context-control reference, especially for canonical entry, bounded re-entry, memory-plane governance, root/child delegation, and proof-bearing runtime artifacts. Do not copy wholesale: the repo is very large, PowerShell-heavy, policy-file-heavy, and partly generated/imported. Steal the contracts and artifact shapes, not the whole runtime.

## Why It Matters

`Vibe-Skills` is not just a skill collection. It is a governed agent runtime that treats context as a controlled execution surface: user intent is frozen before planning, plans are frozen before execution, specialists are bounded helpers, memory is staged and attributed, and final claims must be backed by receipts. That makes it highly relevant to Agentic Coding Lab's context-control theme.

The useful lesson is the separation of authority layers. The runtime keeps `vibe` as the explicit controller while allowing skills, subagents, memories, and delivery checks to contribute only through narrow, inspectable contracts. This is a practical antidote to prompt drift, hidden delegation, context bloat, and unsupported completion claims.

## What It Is

The public surface is a `vibe` skill/runtime plus install/update/check scripts. The README describes a six-step harness: freeze intent, create a requirement document, stage an XL plan, orchestrate skills, verify evidence, and preserve memory. Root `SKILL.md` is the canonical host-facing operating procedure. It requires hosts to launch via `vgo_cli.main canonical-entry`, then validate `host-launch-receipt.json`, `runtime-input-packet.json`, `governance-capsule.json`, and `stage-lineage.json`.

The source tree contains runtime code (`apps/vgo-cli`, `packages/runtime-core`, `scripts/runtime`), installer code (`packages/installer-core`, `install.sh`, `check.sh`), protocols, templates, routing overlays, memory drivers, adapter registries, configs, and a large `tests/runtime_neutral` suite. It also bundles hundreds of skills under an internal corpus, but the real design value is in the governance shell around those skills.

## Research Themes

- Token efficiency: Moderate. It uses progressive memory capsules, per-stage retrieval budgets, short runtime input packets, and a closure-first probe contract. However, the repo itself is huge and the runtime/config surface is not lightweight.
- Context control: Very strong. It freezes runtime input before requirements, uses stage lineage, bounded re-entry tokens, authority flags, memory admission, child-lane write scopes, and completion-language gates.
- Sub-agent / multi-agent: Strong. Root/child governance, delegation envelopes, child validation receipts, bounded parallel XL lanes, and specialist execution locks are first-class.
- Domain-specific workflow: Strong. Core skills include TDD, debugging, code review, brainstorming, planning, and subagent development; routing packs add domain specialists.
- Error prevention: Strong. It has fallback hazard alerts, no-silent-degradation policy, delivery acceptance truth layers, TDD/artifact-review gates, and tests for stale skill decisions, legacy memory rejection, child envelope mismatch, and authority alignment.
- Self-learning / memory: Strong. Workspace memory is a single brokered plane with Serena/ruflo/Cognee logical owners, cross-host identity, noise suppression, and stage-aware disclosure.
- Popular skills: The repo advertises 340+ bundled skills. The adopted pattern should be the curated internal corpus plus governed routing, not the raw volume.

## Core Execution Path

The canonical path is:

1. Host sees explicit `vibe` invocation and launches `vgo_cli.main canonical-entry` with repo root, artifact root, host id, entry id, and a cleaned prompt.
2. Runtime writes and verifies `host-launch-receipt.json`, `runtime-input-packet.json`, `governance-capsule.json`, and `stage-lineage.json`.
3. `scripts/runtime/invoke-vibe-runtime.ps1` advances through `skeleton_check -> deep_interview -> requirement_doc -> xl_plan -> plan_execute -> phase_cleanup`.
4. Public progressive stops can end at `requirement_doc` or `xl_plan`; continuation requires `--continue-from-run-id` and `--bounded-reentry-token`.
5. Execution reads frozen requirements/plans, selected skill execution locks, memory context packs, and optional child-lane delegation envelopes.
6. Cleanup writes receipts, memory activation reports, delivery acceptance reports, user briefing, and runtime summary.

The important design choice is that a later stage does not rediscover its own truth. It inherits frozen artifacts and emits receipts explaining what changed or what failed.

## Architecture

The root `SKILL.md` is the canonical instruction surface. `protocols/runtime.md`, `protocols/team.md`, `protocols/think.md`, `protocols/do.md`, `protocols/review.md`, and `protocols/retro.md` define the stage, team, planning, execution, review, and retrospective contracts. `core/skills/*` mirrors a small canonical set of reusable skill contracts.

Routing lives under `scripts/router` and `config/pack-manifest.json`. The router scores packs and skills, applies authority/fallback guards, and emits overlays for memory governance, retrieval, exploration, closure, quality debt, framework/domain hints, and confirm UI. `packages/runtime-core/src/vgo_runtime/router.py` still keeps canonical runtime selection on `vibe`, so specialist routing cannot become the root orchestrator.

Runtime execution is split between Python CLI/core and PowerShell orchestration. `packages/runtime-core/src/vgo_runtime/canonical_entry.py` handles canonical launch, truth artifact checks, bounded re-entry validation, and host decision inheritance. `scripts/runtime/Freeze-RuntimeInputPacket.ps1`, `Write-RequirementDoc.ps1`, `Write-XlPlan.ps1`, `Invoke-PlanExecute.ps1`, and `Invoke-PhaseCleanup.ps1` implement the staged bridge.

Memory is intentionally centralized. `scripts/runtime/workspace_memory_driver.py` owns `.vibeskills/memory/workspace-memory-plane.jsonl`; `memory_backend_driver.py` is a compatibility shell that refuses legacy modes and routes to the broker. Workspace identity is anchored at `.vibeskills/project.json` and is host-agnostic.

Installation is ledger and manifest based. `config/adapter-registry.json`, `config/vibe-entry-surfaces.json`, installer materializers, and discoverable wrapper generation produce host-visible wrappers while keeping most bundled skills internal.

## Design Choices

The best design choice is the single-authority rule: `vibe` remains runtime authority, and specialists are bounded execution units. Current routing vocabulary is explicit: `skill_candidates -> skill_routing.selected -> skill_execution_lock -> selected_skill_execution -> skill_usage.used / unused`. Routing and selection are not use claims.

Progressive bounded re-entry is another strong choice. Requirement and plan stops require an explicit user re-entry token, and structured host decisions must match the pending stage. Tests cover approval, revision with delta, wrong-stage rejection, and control-only prompts that reuse frozen task type.

The memory design uses owner roles rather than generic recall. State store owns active session continuity, Serena owns explicit project decisions, ruflo owns short-term semantic handoffs, and Cognee owns long-term relationships. Configs define per-stage reads/writes, token budgets, ingest admission, noise filters, and disclosure levels.

Delivery acceptance separates governance truth, engineering verification truth, workflow completion truth, and product acceptance truth. That prevents a runtime from reporting "done" merely because stages completed or tests passed.

## Strengths

- Strong artifact trail: host launch receipt, runtime input packet, governance capsule, stage lineage, requirement receipt, plan receipt, execution manifest, cleanup receipt, memory activation report, and delivery acceptance report.
- Good authority boundaries: root vs child flags decide whether requirement freeze, plan freeze, global dispatch, and completion claims are allowed.
- Practical child-lane model: delegation envelopes include root run, inherited requirement/plan paths, write scope, approved specialists, and validation receipt.
- Mature memory governance: one workspace plane, cross-host identity, lane/kind ownership, noise suppression, file locking, atomic writes, and capsule projection.
- Honest fallback design: fallback is forbidden by default, silent degradation is blocked, and degraded results are non-authoritative with hazard alerts.
- Strong tests around runtime contracts, memory activation, memory identity, bounded re-entry, delivery acceptance, root/child hierarchy, installed wrappers, and routing vocabulary.

## Weaknesses

- The implementation is heavy. A small lab would struggle to maintain the mix of PowerShell, Python, JSON policy files, templates, docs, wrappers, and generated bundles.
- Public README language markets "340+ skills" more than it explains the minimum viable runtime. The signal is in the contracts, not the skill count.
- Many policies run in `shadow` or `soft` modes. That is useful for rollout but can be mistaken for hard enforcement if copied without care.
- The routing/config system is broad and keyword-heavy. It provides many overlays but also creates a large audit surface for drift.
- Generated, bundled, archived, and vendor content makes the repo expensive to review. Future adopters need a stricter source-of-truth map.
- PowerShell is central to governed execution and tests, which raises portability and onboarding cost for Unix-first agent tooling.

## Ideas To Steal

- Use one canonical runtime authority and treat specialists/subagents/memory as bounded contributors.
- Require a minimal proof quartet for launched sessions: launch receipt, runtime input packet, governance capsule, and stage lineage.
- Add bounded re-entry tokens for human approval at requirement and plan boundaries.
- Freeze context into requirement and plan artifacts, then make execution inherit those paths instead of reinterpreting the chat.
- Model selected skills as obligations, not usage proof; require material `skill_usage.evidence` before claiming a skill shaped output.
- Build a workspace memory plane with owner attribution, per-stage budgets, capsule disclosure, and write-admission/noise filters.
- Give child agents explicit delegation envelopes with inherited context, write scope, done definition, and no final-claim authority.
- Separate governance success from product acceptance success in final reporting.
- Keep fallback truth levels visible and non-authoritative unless the primary path is restored.
- Generate host wrappers from machine-readable entry-surface config rather than hand-maintaining many public commands.

## Do Not Copy

- Do not copy the entire 340+ bundled skill corpus. Curate a much smaller set and route explicitly.
- Do not import the whole PowerShell-first runtime unless the target environment already accepts that operational dependency.
- Do not start with dozens of JSON policy files. First implement the minimal contracts and only split policies when they need independent review.
- Do not treat `shadow` or `soft` governance as real guarantees.
- Do not copy marketing claims about orchestration without the receipts, tests, and truth gates that make them meaningful.
- Do not expose every compatibility command as a public surface; keep one canonical entry and a small number of intentional progressive stops.

## Fit For Agentic Coding Lab

This repo is highly relevant as a pattern library for context-control architecture. The most transferable pieces are the stage model, bounded re-entry, memory plane, proof artifacts, selected-skill execution lock, root/child delegation envelope, and delivery truth layers.

Agentic Coding Lab should not attempt a wholesale port. A practical adaptation would be a smaller harness:

1. `intent_freeze` writes a requirement artifact.
2. `plan_freeze` writes an execution plan with selected helpers.
3. `execute` consumes only frozen artifacts and bounded memory capsules.
4. `verify_cleanup` writes evidence, acceptance state, and memory updates.

The Vibe-Skills repo proves that these contracts can be made testable. The lab version should keep the same invariants with fewer files, fewer wrappers, and fewer policy modes.

## Reviewed Paths

- `README.md`, `SKILL.md`, `docs/README.md`, `docs/install/README.md`, `docs/install/one-click-install-release-copy.en.md`
- `protocols/runtime.md`, `protocols/team.md`, `protocols/think.md`, `protocols/do.md`, `protocols/review.md`, `protocols/retro.md`
- `docs/design/workspace-memory-plane.md`, `docs/design/memory-runtime-v2-integration.md`
- `docs/governance/current-routing-contract.md`, `docs/governance/current-runtime-field-contract.md`, `docs/governance/subagent-handoff-governance.md`, `docs/governance/vibe-governed-project-delivery-acceptance-governance.md`, `docs/governance/specialist-dispatch-governance.md`
- `core/README.md`, `core/skills/*/instruction.md`, `core/skills/vibe/skill.json`, `core/skill-contracts/index.json`, `core/skill-contracts/v1/vibe.json`
- `commands/vibe.md`, `commands/vibe-what-do-i-want.md`, `commands/vibe-how-do-we-do.md`, `commands/vibe-do-it.md`, `commands/vibe-implement.md`, `commands/vibe-review.md`
- `templates/requirements/governed-requirement-template.md`, `templates/plans/governed-execution-plan-template.md`, context evidence report templates
- `scripts/router/README.md`, `scripts/router/resolve-pack-route.ps1`, selected `scripts/router/modules/*.ps1`
- `scripts/runtime/invoke-vibe-runtime.ps1`, `Invoke-VibeCanonicalEntry.ps1`, `Freeze-RuntimeInputPacket.ps1`, `Invoke-PlanExecute.ps1`, `workspace_memory_driver.py`, `memory_backend_driver.py`, and related runtime common modules
- `apps/vgo-cli/src/vgo_cli/main.py`
- `packages/runtime-core/src/vgo_runtime/canonical_entry.py`, `router.py`, `workspace_memory.py`, `workspace_memory_schema.py`, `memory.py`, and runtime-core contract tests
- `packages/installer-core/src/vgo_installer/install_plan.py`, `materializer.py`, `install_runtime.py`, `discoverable_wrappers.py`
- `install.sh`, `check.sh`, `config/adapter-registry.json`, `config/vibe-entry-surfaces.json`, `config/runtime-input-packet-policy.json`, `config/execution-topology-policy.json`, `config/native-specialist-execution-policy.json`, `config/project-delivery-acceptance-contract.json`, `config/fallback-governance.json`, memory policy configs
- Selected `tests/runtime_neutral/*` covering memory, bounded re-entry, root/child hierarchy, delivery acceptance, runtime lineage, install/wrapper contracts, router authority, and routing vocabulary

## Excluded Paths

- `bundled/skills/**`: sampled through packaging/runtime references only. It is a huge imported/internal skill corpus; reviewing each skill is outside this repo-level context-control assessment.
- `dist/**`: generated install/runtime distribution output. Source truth was reviewed in installer, config, adapter, and runtime files instead.
- `vendor/**`, `third_party/**`, `THIRD_PARTY_LICENSES.md`: third-party mirrors/license material, not primary Vibe-Skills design.
- `docs/archive/**`, historical wave/status reports, and dated consolidation notes not directly tied to current contracts: excluded as historical logs after current runtime docs/configs/tests were identified.
- `README.zh.md`: excluded as a language duplicate of the English README for this review.
- Binary/UI-only assets such as `logo.png`, docs media, and Office/PDF fixture binaries under document safety tests: excluded because they do not define the agent runtime or context-control contracts.
- `.git/**` and most `.github/**`: repository metadata and CI wrappers were not needed beyond test/verification entry points already covered in scripts and tests.
