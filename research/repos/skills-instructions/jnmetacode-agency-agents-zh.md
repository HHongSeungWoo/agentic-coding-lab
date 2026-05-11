# jnMetaCode/agency-agents-zh

- URL: https://github.com/jnMetaCode/agency-agents-zh
- Category: skills-instructions
- Stars snapshot: 10,558 (GitHub REST API, captured 2026-05-11)
- Reviewed commit: 28c09a74e47db04062e185622db850c1689c07ac
- Reviewed at: 2026-05-11
- Status: reviewed
- Scope fit: in-scope
- Verdict: High-signal Chinese-language extension of the `agency-agents` role-library pattern. Best reusable ideas are localized specialist roles, cross-tool conversion, subagent packaging, evidence-first QA, explicit handoff templates, and context-budget warnings. Treat it as a corpus and design reference, not as an enforcement layer or runtime dependency.

## Why It Matters

`jnMetaCode/agency-agents-zh` matters because it shows how a broad Markdown role library changes when localized for a different market, language, tool ecosystem, and workflow culture. It tracks `msitarzewski/agency-agents` as an upstream baseline, translates the upstream corpus, then adds China-specific roles for platforms, enterprise collaboration, industrial software, legal/compliance, supply chain, education, and vertical operations.

For Agentic Coding Lab, the main value is not the marketing scale of "215 agents." The value is the practical adaptation layer: Chinese role names and descriptions, filename-based slugs for tool compatibility, additional converters for Codex CLI, Qwen, Trae, Kiro, WorkBuddy, Hermes, DeerFlow, and Qoder, and explicit warnings that installing the entire corpus as always-on context is ineffective.

The repo is also useful because it keeps the same core NEXUS workflow doctrine as the upstream role library: stage gates, structured handoffs, dev-QA loops, retry limits, evidence requirements, and memory-assisted cross-agent continuity. That makes it a strong comparison point for separating prompt-library structure from runtime orchestration.

## What It Is

This is a Markdown-first Chinese agent-role library plus converter and installer scripts. At the reviewed commit, the repository contains 215 agent files across agent directories such as `engineering/`, `testing/`, `specialized/`, `marketing/`, `game-development/`, `hr/`, `legal/`, `supply-chain/`, `support/`, and others. `AGENT-LIST.md` describes the corpus as 165 translated roles plus 50 China-market original roles; `UPSTREAM.md` records the upstream baseline as `msitarzewski/agency-agents` commit `783f6a7` with 184 upstream agent files.

Most agent files use YAML frontmatter with `name`, `description`, `emoji`, and `color`, followed by a structured prompt body. The body usually covers identity/memory, core mission, key rules, deliverables, workflow, communication style, success metrics, and advanced capabilities.

The repo is not an agent runtime. It packages role instructions for host tools. `README.md` promotes a separate sibling project, `agency-orchestrator`, for actual DAG-style execution. In this repo, orchestration is prompt/document driven through `specialized/agents-orchestrator.md`, `strategy/` playbooks, examples, and conversion scripts.

## Research Themes

- Token efficiency: Stronger than a naive role pack because OpenCode uses `mode: subagent`, Cursor/Trae rules default to `alwaysApply: false`, Hermes can install by category, and Trae docs explicitly warn that installing all 215 rules dilutes matching and consumes context. Still weak if users generate Aider/Windsurf single-file formats or copy the full corpus into an always-on prompt.
- Context control: Good at artifact level, host-dependent at runtime. Filename slugs, frontmatter descriptions, project-scoped rules, OpenClaw persona/operations splitting, NEXUS handoffs, and MCP-memory tagging help control context, but no retrieval router or deterministic role selector is bundled.
- Sub-agent / multi-agent: Strong as a prompt protocol. `AgentsOrchestrator`, NEXUS phase docs, handoff templates, dev-QA loops, examples, and retry/escalation formats define how specialists should collaborate. The actual scheduler is external or manual.
- Domain-specific workflow: Very strong. Coding roles include Code Reviewer, Codebase Onboarding Engineer, Minimal Change Engineer, Workflow Architect, MCP Builder, LSP Index Engineer, SRE, Incident Response Commander, Security Engineer, API Tester, Evidence Collector, and Reality Checker. Chinese originals add DingTalk, Feishu, WeChat Mini Program, Qt PC-host/industrial HMI, FPGA, embedded Linux drivers, mechanical design, Xiaohongshu, Douyin, Baidu SEO, Chinese legal/contracts, invoices, and supply-chain roles.
- Error prevention: Strong in instruction design. Evidence Collector requires screenshots/logs/repro steps, Reality Checker defaults to "needs work" without proof, Minimal Change Engineer fights scope creep, Codebase Onboarding Engineer forbids unsupported inference, and Workflow Architect requires failure branches, handoff contracts, observable states, and assumptions.
- Self-learning / memory: Conditional. Many agents include memory prose. OpenClaw conversion injects workspace memory rules, and `integrations/mcp-memory/` defines a prompt-level pattern using `remember`, `recall`, `rollback`, and `search`. No memory server or persistence implementation is bundled.
- Popular skills: Reusable roles worth adapting are `specialized/agents-orchestrator.md`, `specialized/specialized-workflow-architect.md`, `testing/testing-evidence-collector.md`, `testing/testing-reality-checker.md`, `engineering/engineering-code-reviewer.md`, `engineering/engineering-codebase-onboarding-engineer.md`, `engineering/engineering-minimal-change-engineer.md`, `specialized/specialized-mcp-builder.md`, `specialized/lsp-index-engineer.md`, and selected China-specific engineering roles such as `engineering/engineering-pc-host-engineer.md` and `engineering/engineering-dingtalk-integration-developer.md`.

## Core Execution Path

The source-of-truth execution path is Markdown plus shell conversion:

1. A role file is selected from an agent directory.
2. The file's frontmatter is parsed by `scripts/convert.sh` using `get_field`; body content is extracted by `get_body`.
3. The slug is derived from the filename, not from the Chinese `name` field. This avoids unsafe or inconsistent slugs in target tools.
4. `scripts/convert.sh` writes host-specific output under an `integrations/<tool>/` directory or a custom `--out` path.
5. `scripts/install.sh` copies generated output or source Markdown into host-specific user/project directories.

Validated conversion samples:

- `rtk bash scripts/convert.sh --tool opencode --out /tmp/agency-zh-opencode-convert-20260511` converted 215 agents. Generated files add `mode: subagent` and convert named colors to hex.
- `rtk bash scripts/convert.sh --tool codex --out /tmp/agency-zh-codex-convert-20260511` converted 215 agents into TOML files with `developer_instructions`.
- `rtk bash scripts/convert.sh --tool openclaw --out /tmp/agency-zh-openclaw-convert-20260511` converted 215 agents into OpenClaw workspaces with `SOUL.md`, `AGENTS.md`, and `IDENTITY.md`.

The multi-agent workflow path is prompt-driven:

1. User activates `AgentsOrchestrator` or a NEXUS mode.
2. Orchestrator chooses phase-specific specialists from `strategy/` playbooks.
3. Specialists produce deliverables using structured handoffs.
4. QA roles collect evidence and produce PASS/FAIL feedback.
5. Failed tasks return to the relevant developer with specific feedback, up to three attempts.
6. Three failures trigger escalation: reassign, split, change approach, accept with known limits, or defer.
7. Phase gates decide whether the next phase can start.

There is no independent sandbox, scheduler, permission system, planner state machine, or memory database in this repository.

## Architecture

The architecture is filesystem-native and intentionally simple:

- `README.md`: Chinese-language roster, quick start, `agency-orchestrator` pitch, tool integration guide, China-market originals, examples, and community links.
- `AGENT-LIST.md`: generated complete list of 215 agents with department, Chinese name, description, and source classification.
- `CATALOG.md`: compact searchable path catalog by department.
- `UPSTREAM.md`: upstream commit, coverage table, path mapping, and local extra directory notes.
- `CONTRIBUTING.md`: agent template and contribution rules for translations and China-market originals.
- `scripts/convert.sh`: main converter for Antigravity, Gemini CLI, OpenCode, Cursor, Trae, Aider, Windsurf, OpenClaw, Qwen, Codex, DeerFlow, WorkBuddy, Hermes, Kiro, and Qoder.
- `scripts/install.sh`: installer and tool detector for global and project-scoped targets, including Hermes category filtering.
- `scripts/lint-agents.sh`: frontmatter and section linter requiring `name`, `description`, `color`, and `emoji`.
- `scripts/convert.ps1` and `scripts/install.ps1`: Windows variants, but these lag the Bash scripts for Qoder support.
- `scripts/sync-tw.sh`: Simplified-to-Traditional README generation using OpenCC.
- `integrations/`: tracked integration docs plus `integrations/mcp-memory/`; generated integration output is gitignored.
- `examples/`: manual and memory-assisted workflows, a Xiaohongshu campaign, landing-page sprint, book chapter workflow, and a NEXUS spatial discovery example.
- `strategy/`: NEXUS strategy, quickstart, phase playbooks, runbooks, activation prompts, and handoff templates.
- Agent directories: Markdown role corpus across coding, QA, business, design, operations, game development, and China-market specialties.

## Design Choices

The most important design choice is localization by extension, not a clean fork rename. `UPSTREAM.md` keeps an explicit upstream baseline and coverage map, while local additions live in the same flat role-library structure as translated upstream agents.

The second design choice is filename-based portability. Chinese `name` values are preserved for human use, while machine-facing slugs come from filenames such as `engineering-code-reviewer` and `marketing-xiaohongshu-operator`.

The third design choice is host-specific context packaging. OpenCode becomes on-demand subagents, Cursor/Trae become agent-requested rules, OpenClaw splits identity and operations, Codex becomes TOML `developer_instructions`, Hermes keeps category folders, Qoder receives category-derived tool lists, and Aider/Windsurf get single aggregate files.

The fourth design choice is prompt-level governance rather than runtime enforcement. NEXUS, Evidence Collector, Reality Checker, Workflow Architect, and Minimal Change Engineer all encode disciplined behavior, but they rely on the active host agent to follow instructions.

The fifth design choice is explicit context-budget education. The Trae README says full installation of 215 rules makes automatic triggering almost useless, and recommends 10-20 curated rules or explicit `@` invocation. This is a useful corrective to role-library bloat.

## Strengths

The repo provides a concrete example of adapting an agent corpus to a local platform ecosystem. It adds China-specific roles that are not generic translations, especially around DingTalk, Feishu, WeChat, Xiaohongshu, Douyin, Baidu SEO, industrial Qt desktop apps, embedded/FPGA work, and Chinese business/legal operations.

The role design remains structured and reusable. Many files include explicit rules, workflows, templates, success metrics, and concrete domain examples, making them more useful than one-line "you are an expert" prompts.

The coding-support roles are highly relevant to agentic coding reliability. Minimal Change Engineer, Codebase Onboarding Engineer, Workflow Architect, MCP Builder, LSP Index Engineer, Evidence Collector, and Reality Checker encode practical failure-prevention behavior.

The converter script is pragmatic and broad. It validates that one Markdown source corpus can target many agent host formats without maintaining each format manually.

NEXUS is still the strongest workflow artifact: it gives roles, phases, handoffs, QA verdicts, retry limits, escalation reports, and stage gates.

The repo explicitly acknowledges context-selection failure. The Trae guidance is especially useful: too many role descriptions in a project rule system reduce matching quality rather than improving it.

## Weaknesses

Runtime guarantees are absent. Evidence requirements, retry limits, role selection, memory use, and handoff discipline are prompt instructions, not enforced by code.

Token efficiency is mixed. Subagent/rule packaging helps, but generated Aider and Windsurf formats concatenate all agents. Many individual roles are long and persona-heavy.

Validation has a coverage gap. `scripts/lint-agents.sh` passes with 0 errors and 52 warnings, but its no-argument scan checks 200 files because it scans only one level deep in each agent directory. `convert.sh` recursively converts 215 agents, including nested game-development agents.

Documentation and script support drift in places. `README.md` and Bash scripts support newer tools such as Qoder, Codex, Hermes, DeerFlow, WorkBuddy, Kiro, and Trae, while `integrations/README.md` still lists only older tools and `integrations/cursor/README.md` still says 180 agents. PowerShell scripts do not include Qoder support at this commit.

Some counts disagree across docs. `README.md` says 215 agents, 17 tools, and 18 departments; `AGENT-LIST.md` says 215 agents and 17 departments; `UPSTREAM.md` says 184 upstream agents plus 49+ originals, while `AGENT-LIST.md` summarizes 165 translated plus 50 originals.

OpenClaw memory conversion injects startup rules for `USER.md`, `MEMORY.md`, and daily memory files, but the generated workspace only contains `SOUL.md`, `AGENTS.md`, and `IDENTITY.md`. That is a useful convention, not a complete memory implementation.

## Ideas To Steal

Use filename slugs as stable machine identifiers while allowing localized or human-friendly names in frontmatter.

Add `alwaysApply: false` or equivalent on project rule formats by default, and document that users should install curated bundles rather than an entire corpus.

Create role-specific "anti-failure" agents: Minimal Change Engineer for scope control, Codebase Onboarding Engineer for fact-only repo reading, Workflow Architect for branch/failure mapping, Evidence Collector for proof, and Reality Checker for deployment skepticism.

Adopt the NEXUS handoff template shape: metadata, context, related files, dependencies, constraints, measurable deliverables, acceptance criteria, evidence requirements, and next recipient.

Use converter tests as corpus verification. A practical check is: source count, lint count, and each generated target count should match or intentionally differ with an explanation.

Use category-filtered installation for large skill libraries. Hermes `--category` and Trae curated-install guidance are good patterns for token and platform limits.

For local market or domain adaptation, add genuinely local roles instead of only translating names. The DingTalk, Feishu, WeChat Mini Program, PC-host engineer, legal-contract, and invoice roles show what "localized specialization" can mean.

## Do Not Copy

Do not copy all 215 agents into always-on context. It harms matching, burns tokens, and lets roles fight each other.

Do not treat NEXUS or `AgentsOrchestrator` as a real runtime. It is a prompt protocol unless paired with an actual orchestrator, test harness, state store, and tool permissions.

Do not rely on prompt-level memory as durable memory. The MCP memory integration requires an external server with compatible tools, and OpenClaw memory files are not fully generated.

Do not copy documentation claims without running the scripts. Counts and supported-tool lists drift across README files and scripts.

Do not use heading heuristics alone if persona/operations splitting must be reliable. OpenClaw conversion classifies sections by matching header text; linter warnings show some files do not map cleanly to SOUL or AGENTS sections.

Do not make broad role libraries the default Agentic Coding Lab surface. Use a small, tested set of coding-support roles with clear triggers and measurable verification behavior.

## Fit For Agentic Coding Lab

Fit is in-scope. This repo is directly relevant to reusable specialized agents, prompt libraries, subagent packaging, context control, cross-tool conversion, memory handoffs, QA gates, and role-based error prevention.

The best fit is as a design-reference corpus. Agentic Coding Lab should reuse narrow patterns: stable role metadata, curated subagent bundles, evidence-first QA, explicit handoff schemas, retry/escalation limits, scope-control roles, and localized/domain-specific coding roles where they add real behavior.

The local adaptation should be more rigorous than this repo: fewer default roles, shorter prompts, explicit trigger rules, deterministic validators, source/generation count checks, and a real verification harness around any claimed QA or memory behavior.

## Reviewed Paths

- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/README.md`
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/AGENT-LIST.md`
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/CATALOG.md`
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/UPSTREAM.md`
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/CONTRIBUTING.md`
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/package.json`
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/.gitignore`
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/.github/workflows/lint-agents.yml`
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/scripts/convert.sh`
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/scripts/install.sh`
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/scripts/lint-agents.sh`
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/scripts/convert.ps1`
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/scripts/install.ps1`
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/scripts/sync-tw.sh`
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/integrations/README.md`
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/integrations/claude-code/README.md`
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/integrations/opencode/README.md`
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/integrations/openclaw/README.md`
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/integrations/cursor/README.md`
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/integrations/trae/README.md`
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/integrations/mcp-memory/README.md`
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/integrations/mcp-memory/backend-architect-with-memory.md`
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/integrations/mcp-memory/setup.sh`
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/examples/README.md`
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/examples/workflow-startup-mvp.md`
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/examples/workflow-with-memory.md`
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/examples/workflow-xiaohongshu-launch.md`
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/examples/workflow-landing-page.md`
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/examples/workflow-book-chapter.md`
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/strategy/nexus-strategy.md`
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/strategy/QUICKSTART.md`
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/strategy/coordination/agent-activation-prompts.md`
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/strategy/coordination/handoff-templates.md`
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/strategy/playbooks/phase-3-build.md`
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/strategy/runbooks/scenario-startup-mvp.md`
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/specialized/agents-orchestrator.md`
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/specialized/specialized-workflow-architect.md`
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/specialized/specialized-mcp-builder.md`
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/specialized/lsp-index-engineer.md`
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/testing/testing-evidence-collector.md`
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/testing/testing-reality-checker.md`
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/engineering/engineering-code-reviewer.md`
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/engineering/engineering-codebase-onboarding-engineer.md`
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/engineering/engineering-minimal-change-engineer.md`
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/engineering/engineering-pc-host-engineer.md`
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/engineering/engineering-dingtalk-integration-developer.md`
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/marketing/marketing-xiaohongshu-operator.md`
- Generated sample for OpenCode validation: `/tmp/agency-zh-opencode-convert-20260511/opencode/agents/engineering-code-reviewer.md`
- Generated sample for Codex validation: `/tmp/agency-zh-codex-convert-20260511/codex/agents/engineering-code-reviewer.toml`
- Generated sample for OpenClaw validation: `/tmp/agency-zh-openclaw-convert-20260511/openclaw/engineering-code-reviewer/SOUL.md`
- Generated sample for OpenClaw validation: `/tmp/agency-zh-openclaw-convert-20260511/openclaw/engineering-code-reviewer/AGENTS.md`
- Generated sample for OpenClaw validation: `/tmp/agency-zh-openclaw-convert-20260511/openclaw/engineering-code-reviewer/IDENTITY.md`
- GitHub REST metadata: `https://api.github.com/repos/jnMetaCode/agency-agents-zh`
- Local comparison note: `<repo>/research/repos/skills-instructions/msitarzewski-agency-agents.md`

## Excluded Paths

- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/.git/`: VCS metadata; reviewed commit captured separately.
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/integrations/*` generated outputs: excluded because generated files are gitignored; converter logic and representative generated OpenCode, Codex, and OpenClaw outputs were reviewed instead. Tracked integration README files and MCP memory docs were reviewed.
- `/tmp/myagents-research/jnMetaCode-agency-agents-zh/README.zh-TW.md`: generated Traditional Chinese README from `scripts/sync-tw.sh`; excluded from deep review because it mirrors `README.md`.
- Most individual non-coding business roles under `sales/`, `finance/`, `paid-media/`, `product/`, `support/`, `academic/`, and broad marketing categories: cataloged through `AGENT-LIST.md`, `CATALOG.md`, file counts, and sampled agent structure, but not read line-by-line because their pattern repeats the role-library template and the research focus is coding support systems.
- Most game-development subroles under `game-development/blender/`, `game-development/godot/`, `game-development/roblox-studio/`, `game-development/unity/`, and `game-development/unreal-engine/`: counted and included in conversion validation, but excluded from deep content review because they are domain prompts rather than agent-support-system infrastructure.
- `.github/ISSUE_TEMPLATE/*`, `.github/FUNDING.yml`, `.github/PULL_REQUEST_TEMPLATE.md`, and `.github/workflows/sync-to-gitee.yml`: unrelated to role execution or context-control design, aside from general project maintenance.
- `LICENSE`, badges, community links, star-history SVG, and sibling project marketing links: checked for context but excluded from design analysis.
- Linked sibling repository `jnMetaCode/agency-orchestrator`: noted as the claimed runtime/orchestration companion, but not reviewed because this assignment targets `agency-agents-zh`.
- Binary, vendored, or UI-only assets: none found in the tracked file list.
