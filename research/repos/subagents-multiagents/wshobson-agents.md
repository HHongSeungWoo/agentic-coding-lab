# wshobson/agents

- URL: https://github.com/wshobson/agents
- Category: subagents-multiagents
- Stars snapshot: 35,693 (GitHub REST API `stargazers_count`, captured 2026-05-20)
- Reviewed commit: 08ded5e7b0fe57e7f40194775885eba539c3d8e7
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: in-scope
- Verdict: High-signal Claude Code plugin marketplace for subagent, skill-pack, workflow-orchestration, and governance patterns. Best ideas are plugin-scoped capability loading, frontmatter routing contracts, Agent Teams file-ownership protocols, artifact-backed checkpoints, and plugin evaluation/governance hooks. Main risks are static prompt-only enforcement, documentation/count drift, accepted duplicate agent names, broad default tool permissions, and reliance on host-specific experimental tools.

## Why It Matters

`wshobson/agents` is one of the largest public Claude Code plugin/subagent marketplaces and is directly relevant to reusable subagent and multi-agent design. It is not just a collection of role prompts: it packages agents, slash-command protocols, progressive-disclosure skills, Agent Teams workflows, Conductor-style project context, a delivery pipeline, evaluation tooling, and tool-governance hooks into one installable marketplace.

For Agentic Coding Lab, the value is the system shape. The repo shows how to split coding-agent behavior across plugin boundaries, how to use frontmatter as a dispatch and model-routing contract, how to encode workflow protocols as slash commands, how to isolate large workflow state into files, and how to add post-hoc quality/governance layers around prompt packs.

The caution is equally important. Many artifacts are instructions for Claude Code to follow, not executable runtimes. The strongest ideas need validators, host-capability checks, test fixtures, and stricter tool permissions before becoming dependable infrastructure.

## What It Is

The repository is a Claude Code plugin marketplace. The reviewed checkout has 81 plugin directories, 191 agent Markdown files, 102 command Markdown files, 155 `SKILL.md` files, 77 skill reference files, 12 skill asset files, 2 hook bundles, and a `plugin-eval` Python package with tests. The public docs claim 80 focused plugins, 185 specialized agents, 153 skills, and 100 commands; those are close but not exact for this commit.

Each local plugin follows this shape:

- `.claude-plugin/plugin.json` with plugin metadata.
- `agents/*.md` with YAML frontmatter such as `name`, `description`, `model`, `tools`, and optional `color`.
- `commands/*.md` with command frontmatter and step-by-step protocol bodies.
- `skills/<skill-name>/SKILL.md` with trigger descriptions, core instructions, and optional `references/` or `assets/`.

The root `.claude-plugin/marketplace.json` lists installable plugin sources. Claude Code installs selected plugins, which keeps unrelated agents and commands out of active context. `GEMINI.md`, `gemini-extension.json`, `Makefile`, and `tools/generate_gemini_commands.py` add a Gemini CLI extension path where commands are generated locally on demand.

The most relevant subagent/multi-agent areas are `plugins/agent-teams`, `plugins/full-stack-orchestration`, `plugins/backend-development`, `plugins/conductor`, `plugins/ship-mate`, `plugins/plugin-eval`, `plugins/protect-mcp`, `plugins/review-agent-governance`, and `plugins/block-no-verify`.

## Research Themes

- Token efficiency: Strong packaging pattern. Plugin installation loads only selected domains; skills use progressive disclosure; model tiers route expensive models to architecture/security/review and cheaper models to operational tasks. Weakness: several command protocols and role prompts are large, and actual counts drift from README counts.
- Context control: Strong workflow pattern, mixed implementation depth. `feature-development` and `full-stack-feature` force step outputs into `.feature-dev/` or `.full-stack-feature/` and require re-reading files instead of relying on conversation memory. Conductor creates persistent `conductor/` artifacts. `context-save` and `context-restore` are mostly conceptual prompt protocols rather than a concrete storage runtime.
- Sub-agent / multi-agent: Strong. `agent-teams` defines team roles, team creation, task assignment, dependency graphs, file ownership, interface contracts, progress monitoring, result synthesis, graceful shutdown, multi-reviewer deduplication, and competing-hypothesis debugging.
- Domain-specific workflow: Very broad. The repo covers language specialists, backend/frontend, UI, infrastructure, security, testing, data, LLM apps, documentation, operations, business, SEO, reverse engineering, Web3, payments, and more. For coding-agent design, the useful part is the packaging and workflow grammar more than any one domain body.
- Error prevention: Moderate to strong as patterns. It includes explicit approval gates, "halt on failure" rules, code review/QA/playwright loops, security checklists, block-no-verify hooks, Cedar policy enforcement, signed receipts, review-surface human approval, plugin-eval, and CI validation. Many controls still depend on prompt compliance or external CLIs.
- Self-learning / memory: Limited. There is no durable adaptive memory loop for the marketplace itself. Memory/context ideas appear in `context-management`, `agent-orchestration/context-manager`, Conductor artifacts, and Ship Mate pipeline docs, but not as measured, persisted learning from past runs.
- Popular skills: No install telemetry was reviewed. High-value candidates for Agentic Coding Lab are `agent-teams`, `conductor`, `plugin-eval`, `protect-mcp`, `review-agent-governance`, `block-no-verify`, `backend-development`, `full-stack-orchestration`, `tdd-workflows`, `context-management`, `developer-essentials`, and `llm-application-dev`.

## Core Execution Path

The normal plugin path is:

1. User adds the marketplace with Claude Code and installs one or more plugins.
2. Claude Code discovers plugin metadata, agents, commands, and skills from directory structure.
3. Users invoke slash commands directly or ask in natural language for a named agent/task.
4. Agent selection uses each agent's frontmatter `description`, model assignment, and optional tool allowlist.
5. Skill selection uses `SKILL.md` frontmatter descriptions and loads the skill body only when triggered.
6. Command files act as executable protocols for the host agent. They parse `$ARGUMENTS`, run preflight checks, call tools or subagents, write state artifacts, ask for approvals, and verify outputs.

The `agent-teams` execution path is the clearest multi-agent protocol:

1. `/team-spawn` verifies `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, selects a preset or custom team, calls `TeamCreate`, spawns teammates with `Agent`, creates initial setup tasks with `TaskCreate`, and reports team members.
2. `/team-feature` analyzes a feature, decomposes work into exclusive file-ownership streams, defines interface contracts, optionally asks for plan approval, spawns a lead plus implementers, creates tasks with `blockedBy` relationships, monitors `TaskList`, runs build/tests, assigns fix tasks, then sends shutdown requests and deletes the team.
3. `/team-review` resolves a target file/diff/PR, spawns reviewers for dimensions such as security, performance, architecture, testing, and accessibility, collects structured findings, deduplicates same-location issues, chooses higher severity on disagreement, and reports by severity.
4. `/team-debug` generates competing hypotheses across logic, data, state, integration, resource, and environment failure modes, spawns investigators, requires evidence and confidence levels, arbitrates root cause, and reports recommended fixes.

The non-Agent-Teams orchestrators use the standard Claude Code `Task` tool pattern. `backend-development:feature-development` and `full-stack-orchestration:full-stack-feature` run phase-based protocols with output files, checkpoints, and parallel validation tasks. `ship-mate:ship` routes a story through scan, orchestrate, architect, implement, review, QA, and Playwright stages with state in `.claude/pipeline/state.json`. Conductor routes work through `Context -> Spec & Plan -> Implement` with persistent `conductor/` docs and track metadata.

## Architecture

The repo is organized as a static marketplace plus a few executable helper packages:

- Marketplace layer: root `.claude-plugin/marketplace.json` and per-plugin `.claude-plugin/plugin.json` files.
- Plugin content layer: `plugins/<name>/agents`, `plugins/<name>/commands`, and `plugins/<name>/skills`.
- Documentation layer: `README.md`, `CLAUDE.md`, `GEMINI.md`, and `docs/*.md`.
- Cross-platform generation layer: `tools/generate_gemini_commands.py`, `Makefile`, and `gemini-extension.json`.
- Evaluation layer: `plugins/plugin-eval`, a Python package for static, LLM-judge, and Monte Carlo plugin/skill evaluation.
- Governance layer: `plugins/protect-mcp`, `plugins/review-agent-governance`, `plugins/block-no-verify`, and `plugins/signed-audit-trails`.
- CI layer: `.github/workflows/validate.yml` validates JSON manifests, marketplace source paths, hook JSON, agent-name collision baseline, and `plugin-eval` tests. `.github/workflows/eval-report.yml` runs scheduled/manual plugin-eval sweeps.

Agent files are the role layer. All 191 agent files reviewed have name, description, and model frontmatter. Model distribution in this checkout is 54 `opus`, 66 `sonnet`, 51 `inherit`, and 20 `haiku`. Only 9 agent files have explicit non-empty tool restrictions or MCP-only tool lists; most agents inherit the host's default tool permissions.

Command files are the workflow layer. They are Markdown protocols with strict behavioral rules, phase checkpoints, state file formats, and expected outputs. Some commands are concrete and host-tool-specific; others are high-level conceptual workflows with illustrative pseudocode.

Skills are the reusable knowledge layer. They use trigger descriptions, concise core guidance, and optional references/assets. `agent-teams` skills are especially relevant because they externalize team composition, task coordination, parallel feature work, multi-reviewer patterns, parallel debugging, and team communication protocols.

## Design Choices

Plugin granularity is the main context-control design. Instead of one huge prompt pack, users install only the needed plugin. This creates natural ownership boundaries and keeps agent/skill discovery smaller.

Frontmatter is the routing contract. Agent `description` drives natural-language selection, `model` drives cost/quality routing, and `tools` can restrict capabilities when used. Skill descriptions act as activation triggers. Command descriptions and argument hints are slash-command discoverability metadata.

The strongest multi-agent pattern is explicit coordination state. Agent Teams use `TaskCreate`, `TaskUpdate`, `blockedBy`, direct messages, broadcasts only for critical shared changes, plan approval messages, and shutdown messages. File ownership and interface contracts are treated as first-class coordination primitives.

The strongest long-horizon workflow pattern is artifact-backed progress. Feature and full-stack workflows write numbered Markdown outputs and JSON state before moving to the next phase. This reduces context-window dependence and makes resume/audit possible.

Human approval gates are built into several workflows. Feature workflows halt at architecture and validation checkpoints. Agent Teams support `--plan-first`. Conductor pauses between phases. Ship Mate pauses after architect plans and escalates after review/QA loop caps.

Quality and governance are packaged as plugins, not external policy docs. `plugin-eval` evaluates skills/plugins; `protect-mcp` adds Cedar policy and signed receipts around tool calls; `review-agent-governance` gates public review-surface actions; `block-no-verify` blocks git bypass flags.

Gemini support is handled by command generation rather than committing generated commands. The generator reads plugin command Markdown and emits TOML prompts that instruct Gemini to read the full source protocol, execute sequentially, and stop at checkpoints.

## Strengths

The plugin layout is a practical pattern for capability discovery and context control. It is easy to inspect, install selectively, and reason about at the directory level.

`agent-teams` is a strong reusable design for real multi-agent coordination. It addresses common parallel-agent failure modes: vague assignments, overlapping file edits, stale interface contracts, duplicate review findings, debugging confirmation bias, idle/overloaded workers, noisy broadcasts, and unsafe shutdown.

The workflow command protocols show good context-boundary discipline. They force intermediate artifacts onto disk, require later phases to read those artifacts, and define explicit state JSON. This is more robust than long multi-step prompts that depend on hidden conversation memory.

The repo includes verification and governance concepts as first-class artifacts. `plugin-eval` has deterministic static analysis, LLM judge paths, Monte Carlo plans, tests, and CI. `protect-mcp` and review governance show how prompt packs can be paired with pre/post tool hooks and tamper-evident receipts.

The model-routing strategy is clear and reusable. Critical architecture/security/review roles use stronger models, operational roles use cheaper/faster models, and `inherit` leaves some choices to the user.

The CI validation catches important marketplace drift: malformed JSON, missing plugin directories, missing plugin metadata, hook JSON errors, and growth beyond the current duplicate-name baseline.

## Weaknesses

The repo is mostly a static instruction and packaging system. Except for `plugin-eval`, generator scripts, collision checks, and hook test fixtures, most agent and command behavior is not executable or unit-tested locally.

Documentation and inventory counts drift. README and `GEMINI.md` claim 80 plugins, 185 agents, 153 skills, and 100 commands. The reviewed checkout has 81 plugin directories, 191 agent files, 155 skill files, and 102 command files. `docs/architecture.md` also contains older counts such as 15 workflow orchestrators, 71 development tools, and 107 skills.

Agent-name collisions are accepted as a baseline. The repo has 30 duplicate agent names across 95 files, including `code-reviewer`, `backend-architect`, `test-automator`, `debugger`, `performance-engineer`, and `security-auditor`. This is manageable when plugins are namespaced, but risky for natural-language routing and cross-plugin orchestration.

Tool permissions are not consistently least-privilege. Only a small set of agents declare explicit tool restrictions. Many reviewers, specialists, and operational agents inherit default host permissions unless the runtime or user config constrains them.

Several command protocols assume host-specific tools that are not portable. Agent Teams requires an experimental Claude Code feature and tools such as `TeamCreate`, `TaskCreate`, `TaskUpdate`, and `SendMessage`. Hook plugins depend on external npm CLIs. Gemini CLI support explicitly loses parallel subagent orchestration.

Some workflows are more aspirational than implemented. `agent-orchestration:multi-agent-optimize`, `context-save`, and `context-restore` contain useful architecture ideas but read like conceptual designs with pseudocode, not ready command runtimes.

The default governance examples can fail open if not configured carefully. The hook commands use `--fail-on-missing-policy false`, so policy-file absence is a setup-dependent risk. The review-governance README also notes that approval log JSON is not itself signed, only tool-call receipts are authoritative.

CI does not validate command semantics, tool-name availability, skill trigger quality across the whole repo, or whether command-referenced agents exist in the installed plugin set. It validates structure more than behavior.

## Ideas To Steal

Use plugin directories as install and context boundaries. Keep each plugin single-purpose with agents, commands, and skills colocated.

Generate a compact machine-readable index from frontmatter. Use it for routing, docs, duplicate checks, skill triggers, and install discovery instead of relying only on README prose.

Adopt the Agent Teams file-ownership protocol: one owner per file, explicit owned paths, shared-file owner, immutable interface contracts, dependency graph, and lead-owned integration.

Use multi-reviewer dimensions for code review. Spawn separate reviewers for security, performance, architecture, testing, and accessibility; then dedupe by file/line and calibrate severity centrally.

Use competing-hypothesis debugging. Assign separate investigators to plausible root causes, require confirming and contradicting evidence, then arbitrate by confidence and causal chain.

Require workflow artifacts before phase transitions. Numbered Markdown outputs plus state JSON make long agent workflows resumable and auditable.

Package quality gates as plugins. A local lab could adapt `plugin-eval` style checks into frontmatter schema validation, trigger tests, reference-link checks, tool allowlist checks, and dispatch simulations.

Pair prompt contracts with hooks. `block-no-verify`, `protect-mcp`, and `review-agent-governance` show how to turn important safety rules into `PreToolUse` and `PostToolUse` controls rather than relying only on instructions.

Keep generated Gemini or alternate-host commands out of source by default. Generate them locally from source command protocols to avoid stale duplicated command definitions.

## Do Not Copy

Do not copy all 191 agents into an active coding-agent environment. Start with a small verified subset and add roles only when routing and tests justify them.

Do not rely on duplicate un-namespaced agent names. Use plugin-qualified identifiers or a generated alias map when multiple plugins include `code-reviewer`, `test-automator`, or similar common names.

Do not let reviewer or auditor agents inherit write permissions by default. Split review-only and fix-applying roles, and make mutation an explicit escalation.

Do not treat command Markdown as verified behavior. Add tests or dry-run harnesses for command protocols, especially ones that claim to spawn teams, write state, or enforce approvals.

Do not copy conceptual commands such as `context-save` and `multi-agent-optimize` as-is. Convert them into concrete CLIs, MCP tools, hooks, or measured workflows before relying on them.

Do not use governance hooks without explicit fail-closed policy decisions. Missing policy files and unsigned approval logs need documented operational controls.

Do not make experimental host features mandatory for core workflows unless there is a fallback path. Agent Teams is useful, but it is currently host-specific and not available in every coding-agent runtime.

## Fit For Agentic Coding Lab

Fit is high and in-scope. This repo is best treated as a pattern library plus a packaging reference for a future Agentic Coding Lab subagent/skill ecosystem.

The most reusable pieces are the plugin directory convention, frontmatter routing contract, Agent Teams coordination grammar, artifact-backed workflow state, approval checkpoints, PluginEval validation ideas, and policy-hook plugins. These map directly to lab needs: subagent routing, task delegation, context boundaries, install/discovery, prompt contracts, verification, and error prevention.

The best adaptation would be a smaller, stricter marketplace:

- Start with `agent-teams`, `conductor`, `plugin-eval`, `protect-mcp`, `review-agent-governance`, `block-no-verify`, and a few coding-domain plugins.
- Generate a normalized index of agents, commands, skills, models, tools, triggers, and references.
- Fail CI on new duplicate names unless namespaced aliases are present.
- Require tool allowlists for review, audit, and analysis agents.
- Add command protocol tests for preflight, state writes, approvals, referenced agents, and verification steps.
- Add dispatch fixtures showing when each agent/skill should and should not activate.

The repo should not be adopted wholesale. It should be mined for contracts and then rebuilt with stronger enforcement and less prompt bulk.

## Reviewed Paths

- `/tmp/myagents-research/wshobson-agents/README.md`: overview, install flow, marketplace use, plugin counts, Agent Teams, Conductor, skills, model tiers, and architecture highlights.
- `/tmp/myagents-research/wshobson-agents/CLAUDE.md`: project structure, authoring conventions, frontmatter formats, model tiers, plugin-eval summary, and plugin-adding process.
- `/tmp/myagents-research/wshobson-agents/GEMINI.md`, `/tmp/myagents-research/wshobson-agents/gemini-extension.json`, `/tmp/myagents-research/wshobson-agents/Makefile`, `/tmp/myagents-research/wshobson-agents/tools/generate_gemini_commands.py`: Gemini extension setup, local command generation, cross-host command conversion, and sync/prune behavior.
- `/tmp/myagents-research/wshobson-agents/.claude-plugin/marketplace.json`: root marketplace metadata and plugin source registration, including the `agent-teams` entry.
- `/tmp/myagents-research/wshobson-agents/docs/architecture.md`, `/tmp/myagents-research/wshobson-agents/docs/plugins.md`, `/tmp/myagents-research/wshobson-agents/docs/agents.md`, `/tmp/myagents-research/wshobson-agents/docs/agent-skills.md`, `/tmp/myagents-research/wshobson-agents/docs/usage.md`, `/tmp/myagents-research/wshobson-agents/docs/plugin-eval.md`: plugin architecture, catalog, model assignments, skill design, command workflows, and evaluation framework.
- `/tmp/myagents-research/wshobson-agents/plugins/agent-teams/README.md`: Agent Teams prerequisites, commands, agents, skills, presets, and best practices.
- `/tmp/myagents-research/wshobson-agents/plugins/agent-teams/.claude-plugin/plugin.json`: plugin metadata.
- `/tmp/myagents-research/wshobson-agents/plugins/agent-teams/commands/team-spawn.md`, `team-delegate.md`, `team-feature.md`, `team-review.md`, `team-debug.md`: team creation, task assignment, feature decomposition, parallel review, and competing-hypothesis debugging protocols.
- `/tmp/myagents-research/wshobson-agents/plugins/agent-teams/agents/team-lead.md`, `team-implementer.md`, `team-reviewer.md`, `team-debugger.md`: role frontmatter, tool allowlists, lifecycle, ownership, evidence, and output contracts.
- `/tmp/myagents-research/wshobson-agents/plugins/agent-teams/skills/team-composition-patterns/SKILL.md`, `task-coordination-strategies/SKILL.md`, `parallel-feature-development/SKILL.md`, `team-communication-protocols/SKILL.md`, `parallel-debugging/SKILL.md`, `multi-reviewer-patterns/SKILL.md`: team sizing, role selection, dependency graphs, file ownership, messaging, debugging, and review consolidation.
- `/tmp/myagents-research/wshobson-agents/plugins/backend-development/commands/feature-development.md` and `/tmp/myagents-research/wshobson-agents/plugins/full-stack-orchestration/commands/full-stack-feature.md`: artifact-backed phased workflow, task spawning, approval gates, validation, deployment, and documentation handoff.
- `/tmp/myagents-research/wshobson-agents/plugins/conductor/README.md`, `commands/setup.md`, `commands/implement.md`, `agents/conductor-validator.md`, `skills/context-driven-development/SKILL.md`: context-driven development artifacts, setup flow, implementation loop, validation, and track management.
- `/tmp/myagents-research/wshobson-agents/plugins/ship-mate/commands/ship.md`, `agents/orchestrate.md`, `agents/implement.md`, `agents/review.md`, `agents/qa.md`, `agents/playwright.md`, `skills/scan/SKILL.md`: story pipeline routing, state file, stage contracts, loop caps, AGENTS.md/project-doc generation, review/QA/playwright gates.
- `/tmp/myagents-research/wshobson-agents/plugins/context-management/commands/context-save.md` and `context-restore.md`: context capture/restoration concepts and limits.
- `/tmp/myagents-research/wshobson-agents/plugins/agent-orchestration/commands/multi-agent-optimize.md`, `improve-agent.md`, `agents/context-manager.md`: multi-agent optimization and context-manager concept prompts.
- `/tmp/myagents-research/wshobson-agents/plugins/plugin-eval/pyproject.toml`, `src/plugin_eval/parser.py`, `src/plugin_eval/layers/static.py`, `tests/test_static.py`, `tests/test_e2e.py`, `docs/plugin-eval.md`: static parser/analyzer, anti-pattern detection, tests, dimensions, and CI-ready evaluation.
- `/tmp/myagents-research/wshobson-agents/plugins/protect-mcp/README.md`, `hooks/hooks.json`, `test/README.md`, `test/run-tests.sh`, `test/verify-fixtures.sh`: Cedar policy hooks, signed receipts, test fixtures, and verification model.
- `/tmp/myagents-research/wshobson-agents/plugins/block-no-verify/skills/block-no-verify-hook/SKILL.md`: bypass-flag prevention hook design.
- `/tmp/myagents-research/wshobson-agents/plugins/review-agent-governance/README.md`, `hooks/hooks.json`: human approval window, review-surface policy gating, and signed receipt behavior.
- `/tmp/myagents-research/wshobson-agents/.github/workflows/validate.yml`, `.github/workflows/eval-report.yml`, `.github/CONTRIBUTING.md`, `tools/check_agent_name_collisions.py`: CI validation, scheduled eval sweeps, contribution rules, and duplicate agent-name baseline.
- Directory inventory across `/tmp/myagents-research/wshobson-agents/plugins/*/{agents,commands,skills}` to measure actual counts, model distribution, tool restrictions, duplicate names, and plugin coverage.

## Excluded Paths

- `/tmp/myagents-research/wshobson-agents/.git/`: VCS internals. Used only through Git commands to capture commit, commit date, and latest commit message.
- `/tmp/myagents-research/wshobson-agents/.github/ISSUE_TEMPLATE/**`, `.github/FUNDING.yml`, and `.github/CODE_OF_CONDUCT.md`: project community/admin files, not subagent execution or skill-pack design.
- `/tmp/myagents-research/wshobson-agents/tools/yt-design-extractor.py` and `tools/requirements.txt`: YouTube/design extraction utility unrelated to subagent/multi-agent orchestration.
- UI/creative/product-only plugins such as `plugins/meigen-ai-design`, `plugins/brand-landingpage`, SEO/content plugins, and long domain-specialist prompt bodies: sampled only through inventory where relevant; excluded from deep prompt review because they are not core subagent coordination patterns.
- Individual domain skill reference files under unrelated language, UI, business, SEO, game, legal, finance, and marketing plugins: mechanism reviewed through representative skills; domain content excluded.
- External runtimes and linked repositories, including Claude Code marketplace/runtime, Claude Code Agent Teams implementation, `protect-mcp` npm package, `@veritasacta/verify`, Smithery, external `qa-orchestra`, and linked documentation sites: checked-in integration contracts reviewed, external code not cloned.
- Generated Gemini `commands/` output: absent in the reviewed checkout and intentionally generated locally on demand.
- Full verbatim prompt bodies: role and command structures were summarized; long prompt bodies were not reproduced.
- Vendored dependencies, build outputs, binaries, and generated UI assets: none were present as substantive local source paths in the clone beyond ignored or absent build/vendor directories.
