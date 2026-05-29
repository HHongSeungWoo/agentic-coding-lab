# Donchitos/Claude-Code-Game-Studios

- URL: https://github.com/Donchitos/Claude-Code-Game-Studios
- Category: domain-specific-coding
- Stars snapshot: 20,345 (GitHub REST API, captured 2026-05-29)
- Reviewed commit: 984023ddac0d5e27624f2baacde6105e45de375f
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong game-development agent-studio template for Claude Code. Best reusable patterns are the 49-role studio hierarchy, 73 skill workflow catalog, review-mode switch, director-gate library, GDD-to-ADR-to-control-manifest-to-story traceability, asset-spec flow, engine-version reference packs, and skill/agent behavioral spec framework. Main caveats are high prompt and coordination overhead, mostly prose-level enforcement, partial hook coverage, no repo-level CI/eval harness, Claude-specific tool assumptions, and manual verification for subjective game quality.

## Why It Matters

This repo is directly relevant to domain-specific coding because it encodes a full game studio operating model as coding-agent artifacts. It does not just say "make games better"; it defines named directors, leads, specialists, engine experts, slash-command workflows, phase gates, path-scoped rules, hooks, templates, and examples that turn game development into an agent-navigable production system.

For Agentic Coding Lab, the highest-value lesson is the domain model. Game projects fail in ways that generic coding agents rarely prevent: unclear pillars, unreviewed GDDs, asset/code mismatch, missing UX specs, stale engine APIs, late fun validation, scope creep, and weak playtest evidence. CCGS turns those failure modes into explicit artifacts and handoffs: game concepts, art bibles, system maps, GDDs, ADRs, control manifests, epics, stories, test evidence, asset manifests, sprint plans, and release gates.

The repo is also a useful stress test for how far prompt-native skill systems can go before they need deterministic tooling. It has unusually complete workflow coverage, but most checks remain instructions to Claude and shell hooks rather than executable validators.

## What It Is

`Donchitos/Claude-Code-Game-Studios` is a Claude Code project template that turns a new or existing game repo into a structured agent studio. The runtime payload is under `.claude/`: 49 agent definitions, 73 skill directories, 12 hook scripts, 11 path-scoped rule files, shared docs, workflow catalogs, templates, and a status-line script.

The template covers the whole game lifecycle: concept, systems design, technical setup, pre-production, production, polish, and release. It supports Godot, Unity, and Unreal through engine-specialist agents plus version-pinned engine reference docs. It also ships an optional `CCGS Skill Testing Framework/` directory that catalogs all skills and agents, defines quality rubrics, and provides behavioral spec files for skill/agent testing.

The project is not a game engine, asset generator, or autonomous build system. It is an instruction and workflow layer for Claude Code, with light shell-hook enforcement and many Markdown artifacts acting as contracts between agents.

## Research Themes

- Token efficiency: Mixed. Some skills intentionally pass file paths into subagents instead of serializing full documents, and shared docs such as `director-gates.md` avoid repeating entire gate prompts inside every skill. However, the overall corpus is large, many agents repeat the same collaboration protocol, and team workflows can spawn many roles for work that a smaller project might handle with one or two focused skills.
- Context control: Good at the artifact level. `dev-story` tells agents to read the story, TR registry, governing ADR, control manifest, technical preferences, and test path rather than browsing freely. `create-control-manifest` flattens ADR guidance into layer rules so implementers do not reread every ADR. The weak side is that enforcement depends on agents following prose instructions; there is no deterministic context packer or scanner that proves the right files were loaded.
- Sub-agent / multi-agent: Strong conceptually. The repo defines vertical delegation, horizontal consultation, conflict escalation, director panels, and team skills such as `/team-combat`, `/team-ui`, `/team-qa`, and `/team-release`. It explicitly calls for parallel Task spawning when inputs are independent. True independent multi-session "agent teams" are documented as experimental rather than implemented as a repo-local scheduler.
- Domain-specific workflow: Very strong. The workflow catalog is deeply game-specific: MDA brainstorming, art bible, visual entity inventory, per-system GDDs, UX specs, engine setup, vertical slice, playtests, balance checks, asset audits, live ops, localization, launch readiness, and day-one patch work.
- Error prevention: Good structure, partial automation. Story readiness blocks Proposed ADRs, stale manifest versions, invalid TR IDs, missing evidence paths, weak acceptance criteria, and asset references that do not exist. `story-done` checks tests, GDD/ADR deviations, scope, and evidence requirements. Hooks catch invalid JSON and warn about hardcoded gameplay values, asset naming, unsafe git pushes, and session gaps. The gaps are that many hook checks are advisory, some run only at commit time or after writes, and the skills themselves are not exercised by CI.
- Self-learning / memory: Light. The repo includes session-state files, session logs, compaction hooks, and one checked-in agent memory file for `lead-programmer`. This supports recovery and audit trails, not adaptive learning from previous projects.
- Popular skills: Most relevant for reuse are `/start`, `/brainstorm`, `/setup-engine`, `/map-systems`, `/design-system`, `/art-bible`, `/asset-spec`, `/create-architecture`, `/architecture-decision`, `/architecture-review`, `/create-control-manifest`, `/create-epics`, `/create-stories`, `/story-readiness`, `/dev-story`, `/story-done`, `/gate-check`, `/skill-test`, `/skill-improve`, and the `team-*` orchestration skills.

## Core Execution Path

The intended path starts when a user clones the template, opens Claude Code, and runs `/start`. The start flow asks whether the project is new, vague, clear, or brownfield, then routes to brainstorming, engine setup, project-stage detection, or adoption.

A new game moves through a seven-phase pipeline:

1. Concept: `/brainstorm` creates a game concept with pillars, MDA framing, player fantasy, and visual identity anchor. `/setup-engine` populates technical preferences and engine-specialist routing. `/art-bible` anchors visual direction. `/map-systems` decomposes the concept into systems.
2. Systems design: `/design-system` authors GDDs one section at a time; `/design-review` validates each; `/review-all-gdds` checks cross-document consistency.
3. Technical setup: `/create-architecture` builds the architecture overview; `/architecture-decision` writes ADRs; `/architecture-review` creates traceability; `/create-control-manifest` extracts flat implementation rules from Accepted ADRs.
4. Pre-production: `/asset-spec` builds a visual entity and screen inventory, then per-asset specs and an asset manifest. `/ux-design` and `/ux-review` create screen and interaction specs. `/vertical-slice`, `/playtest-report`, `/create-epics`, `/create-stories`, and `/sprint-plan` prepare production.
5. Production: `/story-readiness` checks each story before coding. `/dev-story` loads the story, TR registry, governing ADR, manifest, engine preferences, and evidence requirements; routes to the primary programmer and engine specialist; implements code and tests; then summarizes acceptance coverage. `/code-review` and `/story-done` close the loop.
6. Polish: performance profiling, balance checks, asset audit, playtesting, localization, soak testing, and `team-polish`.
7. Release: release checklist, launch checklist, changelog, patch notes, hotfix, and live-ops workflows.

The key coding path is `/dev-story`. It refuses to start if the TR registry or governing ADR is missing, checks manifest staleness, validates dependencies, marks active work, selects a programmer by story layer/type, optionally spawns an engine specialist, requires tests for Logic and Integration stories, and reports coverage against every acceptance criterion.

The key coordination path is `/gate-check` and the shared director-gate system. Phase gates can spawn creative director, technical director, producer, and art director in parallel. Review intensity is controlled by `full`, `lean`, and `solo` modes so users can trade coverage for speed.

## Architecture

The architecture is file-system native:

- `README.md`, `docs/WORKFLOW-GUIDE.md`, and `docs/examples/`: user-facing overview, phase guide, and concrete example sessions.
- `CLAUDE.md`: top-level project instruction file that imports `.claude/docs/*` guidance and defines the collaboration protocol.
- `.claude/agents/*.md`: 49 agent prompts with YAML frontmatter for name, description, tools, model tier, turn limits, memory, and sometimes skill bindings.
- `.claude/skills/*/SKILL.md`: 73 slash-command skills with frontmatter for invocation, allowed tools, argument hints, model tier, and detailed phase instructions.
- `.claude/docs/`: shared workflow catalogs, director gates, coordination maps, templates, coding standards, context management, skill references, and review guidance.
- `.claude/hooks/*.sh`: session, compaction, commit, push, asset, skill-change, notification, and subagent audit hooks wired by `.claude/settings.json`.
- `.claude/rules/*.md`: path-scoped coding/design rules for gameplay, engine, AI, networking, UI, shaders, tests, data files, narrative, design docs, and prototypes.
- `docs/engine-reference/{godot,unity,unreal}/`: curated engine-version reference docs that agents consult before suggesting engine APIs.
- `design/`, `docs/architecture/`, `production/`, `src/`, and `tests/`: scaffolded project areas that skills expect to populate.
- `CCGS Skill Testing Framework/`: optional meta-framework with catalog, rubric, templates, skill specs, and agent specs.

The core contract is Markdown frontmatter plus host-native Claude Code discovery. There is no central runtime binary. The "execution engine" is Claude Code reading skill files, spawning subagents via Task, and calling hooks configured in `.claude/settings.json`.

## Design Choices

The main design choice is to mirror a real game studio. Directors own cross-cutting judgment, leads own department-level outputs, specialists implement within narrower domains, and engine-specific specialists validate Godot/Unity/Unreal idioms. This creates strong domain boundaries for a coding agent that would otherwise collapse design, architecture, implementation, QA, and production into one voice.

The second major choice is collaborative control rather than autonomy. Agents are repeatedly instructed to ask questions, present options, let the user decide, draft before finalizing, and request explicit write approval. This is heavy, but appropriate for creative work where taste and scope matter.

The third choice is traceability over chat memory. GDD requirements become TR IDs, ADRs become governing implementation guidance, accepted ADRs become a control manifest, stories embed manifest versions and test evidence requirements, and `story-done` checks current requirements rather than trusting stale quoted story text.

The fourth choice is review intensity as a product setting. `full` mode runs more director/lead gates, `lean` keeps phase gates but skips most inline gates, and `solo` skips director gates. This is a good pattern for making a large agent system usable for solo projects without deleting rigor from the framework.

The fifth choice is asset/code coupling. `/asset-spec` first inventories visual entities and screens from GDDs and the art bible, then has art direction and technical art produce specs in parallel, then writes per-asset specs and a manifest. This explicitly connects creative style, dimensions, formats, naming, performance budgets, and generation prompts before production.

The sixth choice is engine-version safety. Engine specialists and implementers are told to check `docs/engine-reference/[engine]/VERSION.md`, deprecated APIs, breaking changes, and subsystem docs before relying on model memory. That is a good domain pattern for any fast-moving platform.

The seventh choice is to test the prompts themselves through specs and rubrics. `/skill-test` can run static, behavioral, category, and audit modes against the checked-in skill catalog. The current implementation is model-evaluated rather than executable, but the existence of per-skill and per-agent behavioral specs is still a useful maintainability pattern.

## Strengths

- Coherent domain model. The role hierarchy, workflow phases, artifacts, and gates all reinforce the same game-studio operating system.
- Strong lifecycle coverage from first concept through launch, including areas many coding-agent packs ignore: art bible, entity inventory, UX specs, playtesting, localization, live ops, community, and release.
- Clear agent boundaries. Agent files state what each role owns, what it must not do, who it escalates to, and which sibling roles it coordinates with.
- Strong implementation traceability. `/dev-story`, `/story-readiness`, `/story-done`, TR registry, ADRs, manifest versions, and test evidence form a practical path from requirements to code closure.
- Good multi-agent orchestration vocabulary. Team skills name required roles, identify parallel phases, define blocked-agent behavior, and require partial reports instead of dropping work.
- Useful user-control mechanics. The collaboration protocol and review modes reduce the risk of an agent silently rewriting a creative project or overbuilding process for a solo developer.
- Domain-specific verification vocabulary. The system distinguishes Logic, Integration, Visual/Feel, UI, and Config/Data story evidence instead of pretending every game requirement is unit-testable.
- Asset workflow is unusually concrete for a coding-agent repo. It handles inventory, art bible anchoring, technical constraints, unique asset IDs, shared assets, specs, and manifest updates.
- Engine references make platform drift visible. Godot, Unity, and Unreal each have version files, deprecated APIs, breaking changes, modules, plugins, and best-practice docs.
- The optional testing framework creates a maintainable spec surface for skills and agents, including category rubrics for gate, review, authoring, readiness, pipeline, analysis, team, sprint, utility, and agent classes.

## Weaknesses

- Most guarantees are prompt-level. The repo has many excellent instructions, but few deterministic validators beyond shell hooks and JSON checks.
- Hook enforcement is narrow. `validate-commit.sh` warns about design sections, hardcoded gameplay values, and ownerless notes only for staged commits; `validate-assets.sh` reacts after writes; many path-scoped rules remain prose.
- No repo-level CI or executable eval suite was present in the reviewed tree. The skill testing framework describes `/skill-test`, but catalog `last_*` result fields are empty and the checks are Claude-evaluated rather than run as automated tests.
- Coordination cost is high. Forty-nine agents and seventy-three skills give strong coverage, but a solo developer can easily spend more turns coordinating reviews than building unless they use `lean` or `solo` modes.
- Prompt duplication increases maintenance cost. Many agents repeat the same collaboration protocol and decision workflow, which makes future changes harder unless generated or factored into shared references.
- Internal spec drift exists. For example, the pipeline rubric says pipeline skills should ask before each artifact, while `create-stories` asks to write all stories as a batch. That is small, but it shows why prompt specs need machine-checkable conformance tests.
- Multi-agent execution depends on Claude Code behavior. Parallel Task spawning, subagent audit hooks, `AskUserQuestion`, and tool frontmatter are host-specific; other coding agents would need adapters.
- Subjective game validation remains manual. The framework correctly asks for playtests, "fun" evidence, and user confirmation, but it cannot independently verify that a core loop feels good.
- Engine and tool facts are temporally fragile. Pinned engine docs and model-tier examples are useful, but there is no refresh command or freshness gate to detect when official docs or Claude model names change.
- The template starts with unconfigured project preferences. `/setup-engine` is expected to populate them, but before that point many downstream skills rely on users completing the setup path.

## Ideas To Steal

- Use a domain organization chart as the agent map when the domain has real professional roles. Game development benefits from creative, technical, production, QA, art, audio, narrative, UX, live-ops, and release roles.
- Add a review-mode switch to every heavy workflow. `full`, `lean`, and `solo` are a simple, reusable way to make rigor adjustable without maintaining separate skill sets.
- Build traceability as a chain of artifacts: domain requirement ID, architecture decision, flat control manifest, story, evidence path, and completion report.
- Make story types drive evidence requirements. Logic and Integration stories need automated or integration tests; Visual/Feel and UI stories need manual evidence; Config/Data stories can depend on smoke checks.
- Put director/lead gate prompts in a shared gate library instead of duplicating them across skills.
- Create domain-specific asset specs before implementation. The inventory-to-spec-to-manifest path is a good pattern for any domain where generated or external assets must align with code.
- Pair engine/platform specialists with version reference docs. Fast-moving platforms need a local "what changed after model training" source.
- Treat prompt packages as testable artifacts. A catalog, category rubric, and per-skill spec files make large skill packs reviewable even before fully automated evals exist.
- Add session lifecycle hooks for context recovery: session start, gap detection, pre/post compaction, stop logging, and subagent audit trails.
- Ask subagents to read named files directly instead of pasting large documents into Task prompts.

## Do Not Copy

- Do not copy the full 49-agent hierarchy for smaller domains. Start with the few roles that create real handoff value, then add roles only where ownership boundaries matter.
- Do not rely on prose-level rules for checks that can be scanned mechanically. Hardcoded tuning values, missing GDD sections, invalid JSON, stale manifest versions, missing evidence files, and deprecated APIs are scanner candidates.
- Do not ship a large skill corpus without CI that runs metadata checks, static skill checks, hook shell tests, and behavioral fixtures.
- Do not duplicate long collaboration protocols in every agent file without generation or shared includes.
- Do not make subjective quality gates look more objective than they are. "Fun", visual feel, and usability need playtest/evidence artifacts and should be reported as human-confirmed.
- Do not assume Claude-specific tools and hooks will transfer to Codex, Cursor, Gemini, or other hosts unchanged.
- Do not hard-code fast-moving model, engine, or API names without a docs refresh process.
- Do not let optional meta-testing live entirely outside normal verification. If a skill-test framework exists, wire at least static checks and catalog coverage into CI.

## Fit For Agentic Coding Lab

Fit is high for `domain-specific-coding`. This repo should be mined as a pattern library for domain-agent studios rather than adopted wholesale.

Best direct fits:

- A game-development skill pack with a smaller role set and the same artifact traceability: GDD -> ADR -> manifest -> story -> test evidence.
- A reusable review-mode primitive for all heavy workflows.
- A cross-domain "control manifest" pattern that turns architecture decisions into implementation rules.
- A story readiness/completion workflow with evidence requirements by work type.
- An asset-spec and manifest workflow for domains that combine generated assets, technical constraints, and code.
- A skill-quality catalog with behavioral specs, rubrics, and coverage status.

Needed upgrades for Agentic Coding Lab:

- Add rule IDs, machine-readable metadata, and deterministic scanners for the most common checks.
- Add CI for skill frontmatter, catalog consistency, hook scripts, example fixtures, and cross-host packaging.
- Replace repeated agent protocol text with shared includes or generated files.
- Add engine-doc freshness checks and source provenance for API claims.
- Define a portable adapter layer for hosts that do not support Claude Code Task, hooks, or `AskUserQuestion`.

## Reviewed Paths

- `README.md`: counts, installation, studio hierarchy, skill list, hooks, rules, design philosophy, and customization notes.
- `CLAUDE.md`: master project configuration, collaboration protocol, imported coordination/coding/context docs.
- `docs/WORKFLOW-GUIDE.md`: seven-phase pipeline, onboarding, phase steps, gate expectations, and common workflows.
- `docs/examples/session-implement-combat-damage.md`: concrete gameplay implementation example with design questions, architecture proposal, tests, and rule feedback.
- `docs/examples/session-story-lifecycle.md`: story readiness, implementation, and story completion flow.
- `docs/examples/session-gate-check-phase-transition.md`: gate-check example and stage advancement protocol.
- `docs/examples/skill-flow-diagrams.md`: pipeline diagrams for full lifecycle, GDD authoring, UX, story flow, QA, and brownfield adoption.
- `.claude/settings.json`: permissions, status line, and hook wiring.
- `.claude/docs/coordination-rules.md`: delegation, model tiers, subagent vs agent-team distinction, and parallel task protocol.
- `.claude/docs/agent-coordination-map.md`: hierarchy, delegation table, escalation paths, and common workflow patterns.
- `.claude/docs/director-gates.md`: shared gate definitions, review modes, invocation pattern, verdict handling, and gate recording.
- `.claude/docs/workflow-catalog.yaml`: phase definitions, required artifacts, and next-step logic.
- `.claude/docs/skills-reference.md`: slash-command catalog and team-orchestration list.
- `.claude/docs/technical-preferences.md`: engine, naming, performance, testing, library, and engine-specialist routing fields populated by `/setup-engine`.
- `.claude/agents/creative-director.md`, `technical-director.md`, `producer.md`, `gameplay-programmer.md`, and `technical-artist.md`: representative director, production, implementation, and asset/code bridge roles.
- `.claude/skills/dev-story/SKILL.md`: core implementation routing, context loading, dependency checks, engine-specialist routing, test requirements, and summary format.
- `.claude/skills/story-readiness/SKILL.md`: readiness checklist, ADR/TR/manifest checks, asset references, story type, and evidence requirements.
- `.claude/skills/story-done/SKILL.md`: acceptance verification, test traceability, evidence gates, deviation checks, QA/code review gates, and completion handoff.
- `.claude/skills/create-stories/SKILL.md`: story decomposition, type classification, ADR handling, TR IDs, QA test cases, and output schema.
- `.claude/skills/create-control-manifest/SKILL.md`: ADR-to-rule extraction and manifest schema.
- `.claude/skills/gate-check/SKILL.md`: phase gate checklists, director panel assessment, chain-of-verification, and stage update approval.
- `.claude/skills/asset-spec/SKILL.md`: entity inventory, asset identification, art/technical parallel review, specs, manifest updates, and shared asset protocol.
- `.claude/skills/team-combat/SKILL.md`: representative team workflow, parallel implementation agents, blocked-agent recovery, and file-write delegation.
- `.claude/skills/skill-test/SKILL.md`: prompt-level static/spec/category/audit testing for skills.
- `.claude/hooks/validate-commit.sh`, `validate-assets.sh`, `detect-gaps.sh`, `log-agent.sh`, and `pre-compact.sh`: representative automation and session-recovery hooks.
- `.claude/rules/gameplay-code.md`, `design-docs.md`, `data-files.md`, and `test-standards.md`: representative path-scoped rules.
- `docs/engine-reference/README.md` and `docs/engine-reference/{godot,unity,unreal}/VERSION.md`: engine-version safety pattern and pinned reference metadata.
- `CCGS Skill Testing Framework/README.md`, `catalog.yaml`, `quality-rubric.md`, `templates/skill-test-spec.md`, `skills/team/team-combat.md`, and `agents/specialists/gameplay-programmer.md`: optional skill/agent quality framework and sampled behavioral specs.
- `design/CLAUDE.md`, `src/CLAUDE.md`, `docs/CLAUDE.md`, `design/registry/entities.yaml`, and `docs/architecture/tr-registry.yaml`: scaffolded project-local guidance and registry examples.

## Excluded Paths

- `.git/**`: VCS internals; only commit, branch, and log metadata were needed.
- `.github/FUNDING.yml`, issue templates, pull request template, and `CODEOWNERS`: governance and contribution metadata, not part of the runtime agent workflow.
- `LICENSE`, `SECURITY.md`, `CONTRIBUTING.md`, and `UPGRADING.md`: inventoried as project support files but not deeply reviewed for coding-agent design.
- Full bodies of all 49 agent files and all 73 skill files: representative directors, specialists, pipeline, team, gate, asset, story, and meta-test files were read; the remaining files were inventoried through `rg --files --hidden` and sampled through catalogs.
- Full engine module docs under `docs/engine-reference/*/modules/` and plugin-specific engine references: reviewed at structure and version-reference level, not exhaustively line-by-line.
- Full template bodies under `.claude/docs/templates/`: reviewed as available artifact templates through file inventory and workflow references, not individually audited.
- Full optional behavioral specs under `CCGS Skill Testing Framework/skills/**` and `agents/**`: sampled representative specs and rubric; exhaustive spec-by-spec validation was outside the repo-note scope.
- `production/session-state/.gitkeep`, `src/.gitkeep`, and empty scaffold files: presence noted but not relevant to workflow assessment.
