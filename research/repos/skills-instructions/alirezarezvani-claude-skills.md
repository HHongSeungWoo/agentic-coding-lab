# alirezarezvani/claude-skills

- URL: https://github.com/alirezarezvani/claude-skills
- Category: skills-instructions
- Stars snapshot: 14,416 (GitHub REST API, captured 2026-05-11)
- Reviewed commit: 8d3c5784f25d4deaddef2e1ef6e6d4eb30341666
- Reviewed at: 2026-05-11
- Status: reviewed
- Scope fit: in-scope
- Verdict: High-signal reference for large-scale Claude skill packaging, plugin marketplace layout, cross-agent skill indexes, context/memory control, and skill verification. Best reused as a pattern catalog; weaker as a source of exact metadata because docs, counts, and some platform instructions drift across files.

## Why It Matters

`alirezarezvani/claude-skills` is a broad, actively maintained skill marketplace rather than one narrow prompt pack. It packages skills, agents, commands, scripts, references, plugin manifests, generated docs, Codex/Gemini indexes, and CI workflows in one repo. That makes it useful for studying the operational side of skills: how a large library is indexed, installed, validated, documented, and kept cross-platform.

For Agentic Coding Lab, the most relevant parts are not the domain content itself. They are the repeatable structures around it: strict `.claude-plugin/plugin.json` manifests, `.codex/skills` symlink generation, `.gemini/skills` wrapper generation, standard-library helper scripts, scoped memory promotion, static skill security scanning, plugin audit commands, and multi-agent workflow patterns.

## What It Is

The repo is a filesystem-native skills library for Claude Code and adjacent coding agents. The root README describes a collection of Claude Code skills, plugins, agent skills, personas, commands, and Python tools across engineering, product, marketing, compliance, executive advisory, project management, business growth, and finance.

The actual installable surfaces are split across several mechanisms:

- Claude Code marketplace: `.claude-plugin/marketplace.json` maps plugin names to source directories such as `./engineering`, `./marketing-skill`, `./engineering/llm-wiki`, and `./engineering-team/self-improving-agent`.
- Claude plugin packages: each domain or standalone plugin has `.claude-plugin/plugin.json`, usually pointing `skills` to `./skills`.
- Codex: `.codex-plugin/plugin.json` points to `./.codex/skills/`, while `scripts/sync-codex-skills.py` creates symlinks and `.codex/skills-index.json`.
- Gemini: `scripts/sync-gemini-skills.py` creates `.gemini/skills/<name>/SKILL.md` symlink wrappers and `.gemini/skills-index.json`.
- Other tools: `scripts/convert.sh` converts depth-3 `SKILL.md` files into Antigravity, Cursor, Aider, Kilo Code, Windsurf, OpenCode, and Augment formats; `scripts/install.sh` copies converted outputs into tool-specific locations.

There is no single canonical count. The reviewed README claims 246 skills, 359 Python tools, 485 references, 27 agents, and 33 commands. The Codex dry-run sync found 188 skills. The Gemini dry-run sync found 312 items because it also includes agents and commands. Docs pages mention older counts such as 192 skills, 177 skills, and 28 plugins. Treat the repo as a living corpus with generated indexes, not a perfectly synchronized catalog.

## Research Themes

- Token efficiency: Strong in layout, mixed in catalog hygiene. Skills generally isolate `SKILL.md`, `references/`, `scripts/`, `assets/`, and `templates/` so deeper context loads only when needed. `llm-wiki` uses `context: fork`; self-improving-agent uses scoped `.claude/rules/` for zero-overhead file-specific rules. Some generated indexes and long descriptions are large, so trigger metadata needs pruning before direct reuse.
- Context control: Strong. Patterns include domain context files, index-first wiki querying, immutable raw sources, scoped rules, first-200-line memory awareness, and reference separation. The repo repeatedly pushes durable facts out of chat and into `CLAUDE.md`, `AGENTS.md`, `.claude/rules/`, or markdown vaults.
- Sub-agent / multi-agent: Strong. AgentHub defines worktree-isolated parallel agents, an append-only board, metric/LLM judging, and winner merge. `llm-wiki` ships ingestor/librarian/linter agents. C-level board skills model isolated multi-role deliberation. The runtime still depends on host agent support.
- Domain-specific workflow: Very strong breadth. Many skills encode concrete workflows with scripts and outputs, from SLO design to RFP analysis to MDR compliance. Depth varies by skill, but the packaging corpus is useful.
- Error prevention: Strong. `focused-fix`, `tdd-guide`, `skill-security-auditor`, `skill-tester`, `/plugin-audit`, CI quality gates, and `SKILL_PIPELINE.md` all target common AI coding failures: premature fixes, missing tests, unsafe scripts, stale manifests, and unverified installs.
- Self-learning / memory: Strong reference patterns. `self-improving-agent` curates auto-memory into `CLAUDE.md` or `.claude/rules/`; `llm-wiki` turns sources into persistent Obsidian-style knowledge; `autoresearch-agent` and eval workspaces suggest iterative improvement loops.
- Popular skills: No install telemetry was reviewed. Locally relevant examples are `skill-security-auditor`, `skill-tester`, `focused-fix`, `tdd-guide`, `self-improving-agent`, `llm-wiki`, `agenthub`, `slo-architect`, and the Codex/Gemini sync scripts.

## Core Execution Path

Claude Code marketplace execution starts from `.claude-plugin/marketplace.json`. A user adds the marketplace, installs a domain or standalone plugin, then Claude Code reads that plugin's `.claude-plugin/plugin.json`. Most plugin manifests are intentionally strict: `name`, `description`, `version`, `author`, `homepage`, `repository`, `license`, and `skills`. The reviewed `scripts/check_plugin_json.py --all` accepted all discovered plugin manifests.

After installation, the host skill loader discovers skill directories under the manifest's `skills` path. A user request matches a skill's frontmatter `description`; the host loads `SKILL.md`; the skill then routes the agent to workflows, slash commands, scripts, references, templates, agents, or MCP configuration as needed.

Codex execution is generated rather than native to the source tree. `scripts/sync-codex-skills.py` scans known domain folders, prefers `<domain>/skills/<name>/SKILL.md`, falls back to direct children, extracts descriptions, creates symlinks in `.codex/skills/`, and writes `.codex/skills-index.json`. `scripts/codex-install.sh` can then copy dereferenced skill directories into `~/.codex/skills`, by all skills, category, or skill name.

Gemini execution is similar but broader. `scripts/sync-gemini-skills.py` scans all `SKILL.md` files outside `.gemini`, selected eval/assets paths, and non-domain top-level folders. It also turns `agents/*.md` and `commands/*.md` into activatable skill wrappers. This is why Gemini reports 312 items while Codex reports 188.

For other tools, `scripts/convert.sh` is the conversion path. It reads frontmatter using `awk`, strips the frontmatter body, and emits tool-native files. Cursor and Kilo Code get flat rule files, Aider gets one combined `CONVENTIONS.md`, and Windsurf/OpenCode/Augment/Antigravity get skill directories with copied `scripts/`, `references/`, and `templates/`. `scripts/install.sh` then copies those generated integration files into project or home paths.

Representative skill execution paths:

- `focused-fix`: scope feature files, trace inbound/outbound dependencies, diagnose root causes, fix in dependency/type/logic/test/integration order, then verify related and full tests.
- `skill-security-auditor`: statically scans skill code, markdown, dependencies, file boundaries, symlinks, and binaries; reports PASS/WARN/FAIL with findings.
- `self-improving-agent`: reads auto-memory, finds promotion/staleness/consolidation candidates, promotes durable patterns into `CLAUDE.md` or `.claude/rules/`, and uses a PostToolUse Bash hook to suggest saving unexpected command-error fixes.
- `llm-wiki`: initializes a markdown vault, keeps `raw/` immutable, writes LLM-owned `wiki/` pages, maintains an index/log, and uses stdlib tools for search, linting, graph analysis, and export.
- `agenthub`: initializes a session, dispatches parallel agents into isolated worktrees, uses an append-only board, evaluates outputs, merges a winner, and archives losers.

## Architecture

The repository architecture is mostly declarative markdown plus small deterministic scripts:

- `README.md`, `INSTALLATION.md`, `CLAUDE.md`, `GEMINI.md`: user-facing installation, repository map, platform guidance, and working rules.
- `.claude-plugin/marketplace.json`: root Claude Code marketplace registry.
- `<domain>/.claude-plugin/plugin.json`: domain bundle manifests.
- `<standalone>/.claude-plugin/plugin.json`: standalone plugin manifests such as `llm-wiki`, `agenthub`, `self-improving-agent`, and `playwright-pro`.
- `.codex-plugin/plugin.json`: Codex plugin metadata pointing to `.codex/skills/`; this file is stale relative to current counts.
- `.codex/skills/` and `.gemini/skills/`: tracked symlink-based generated compatibility layers.
- `scripts/`: install, conversion, sync, docs generation, plugin validation, and review helpers.
- `commands/` and `.claude/commands/`: slash command definitions.
- `agents/`: `cs-*` role agents and personas.
- `engineering/`, `engineering-team/`, `marketing-skill/`, `product-team/`, `project-management/`, `c-level-advisor/`, `ra-qm-team/`, `business-growth/`, `finance/`: domain skill packages.
- `docs/`: generated MkDocs pages and guides.
- `.github/workflows/`: quality, security, sync, docs, and Claude review automation.
- `.mcp.json`: Tessl MCP at root; `project-management/.mcp.json` wires Atlassian SSE; Playwright Pro also includes MCP configuration.

The standard skill shape is `SKILL.md` plus optional `scripts/`, `references/`, `assets/`, `templates/`, `expected_outputs/`, `agents/`, `commands/`, and `evals/`. Many scripts are Python standard-library tools, which keeps skill packages portable.

## Design Choices

The repo treats skills as products. Every substantial skill is expected to have trigger-oriented frontmatter, a workflow, scripts where deterministic checks help, reference docs for depth, assets/templates for output, and validation artifacts.

Marketplace distribution is bundle-first. Large domains install as one plugin, while high-value tools such as `llm-wiki`, `agenthub`, `self-improving-agent`, and `playwright-pro` can install as standalone plugins. This supports both broad adoption and focused installs.

Cross-platform support is generated from the filesystem rather than maintained by hand. Codex and Gemini indexes are symlink layers. Other platforms get converted output under `integrations/`. This is pragmatic, but it creates drift when docs mention commands or counts that scripts no longer support.

The repo emphasizes static and procedural verification. `check_plugin_json.py` enforces a strict plugin schema. `tests/test_skill_integrity.py` validates frontmatter, headings, scripts, references, and duplicate names. GitHub Actions run compile checks, pytest, safety, skill security audits, and Tessl quality reviews.

Context control is a recurring design pattern. `SKILL-AUTHORING-STANDARD.md` asks skills to check domain context before questions, keep `SKILL.md` lean, move knowledge into references, and include proactive triggers. `llm-wiki` and `self-improving-agent` extend that into durable memory systems.

## Strengths

The repo is a rich packaging corpus. It demonstrates domain bundles, standalone plugins, command packs, agent definitions, MCP config, compatibility symlinks, generated docs, and CI gates in one place.

The verification story is stronger than most prompt-pack repos. Plugin schema validation passed locally. Codex dry-run sync reported 188 unchanged symlinks and no errors. Gemini dry-run sync reported 312 total items. `compileall` passed across major script directories, with one future SyntaxWarning in a PowerShell string.

The error-prevention patterns are practical. `focused-fix` prevents premature patches by forcing scope, trace, diagnose, fix, verify. `/plugin-audit` chains discovery, structure validation, quality scoring, script testing, security audit, marketplace compliance, ecosystem sync, and domain review. `skill-security-auditor` is directly reusable as a pre-install gate.

The best context/memory artifacts are genuinely useful. `self-improving-agent` distinguishes capture from curation and gives promotion criteria. `llm-wiki` shows a clear raw/source/wiki/schema separation with index-first querying and health linting.

AgentHub is a concrete multi-agent pattern. It uses worktree isolation, append-only board files, metric-based ranking, and archival semantics rather than just telling agents to collaborate in chat.

## Weaknesses

Metadata drift is the biggest weakness. The README, root `CLAUDE.md`, `.codex-plugin/plugin.json`, docs guides, marketplace metadata, Codex index, Gemini index, and plugin pages disagree on skill counts, tool counts, plugin counts, versions, and stars. The README still says "5,200+ GitHub stars" while the API snapshot is 14,416.

Some platform docs do not match scripts. The docs say `convert.sh --skill ... --tool codex` and `convert.sh --skill ... --tool gemini`, but reviewed `convert.sh` supports neither `--skill` nor `codex`/`gemini`; those platforms use separate sync scripts.

There is no host-side enforcement runtime. Security, context isolation, trigger behavior, command permissions, worktree isolation, and hook execution depend on Claude Code, Codex, Gemini, or other clients honoring the files. Markdown instructions are not a sandbox.

The corpus is broad enough that discoverability and quality are uneven. Some skills are full packages with scripts, references, and expected outputs; others are mostly instructions. Generated `.gemini` and `.codex` layers increase review surface.

The repo contains 37 tracked `.zip` skill packages. They are distributable artifacts duplicating skill content, but they add binary review overhead and should not be a default pattern for an internal research corpus.

Local full pytest could not run because the active Python did not have `pytest` installed. The no-dependency compile check did pass, but test-suite health at this commit was not fully reproduced in this environment.

## Ideas To Steal

Use a root marketplace manifest plus strict per-plugin manifests. Add a local `check_plugin_json.py` equivalent and run it before publishing skills.

Generate per-harness indexes from source directories. Symlink-based `.codex/skills` and `.gemini/skills/<name>/SKILL.md` wrappers are easy to inspect and dry-run.

Keep skill packages progressive: short trigger frontmatter, compact `SKILL.md`, references for depth, scripts for deterministic work, assets/templates for repeatable outputs.

Create a first-class skill security auditor. Scan scripts, markdown, dependencies, filesystem boundaries, symlinks, and binaries before install.

Adopt the `focused-fix` and `/plugin-audit` phase structure for coding-agent error prevention. They are explicit enough to reduce common agent shortcuts.

Use scoped memory promotion. Capture volatile learnings in memory, review them, then promote durable rules to `CLAUDE.md` or path-scoped rules only when proven.

For multi-agent experiments, copy the AgentHub primitives: isolated worktrees, append-only board, status/result files, metric-first evaluation, and archived losing branches.

## Do Not Copy

Do not copy the count/version metadata manually. Generate every catalog count from the same source of truth and fail CI on drift.

Do not ship binary `.zip` skill artifacts in the main research repo unless distribution requires them. Source directories are easier to diff, review, scan, and cite.

Do not treat skill instructions as a security boundary. Pair any imported skill system with actual filesystem, network, process, and secret controls.

Do not expose hooks that parse broad command output without a clear false-positive story. The self-improving error hook is useful, but text-pattern hooks can trigger on code examples or logs.

Do not copy all domains wholesale. The useful part for Agentic Coding Lab is the packaging, context, validation, and orchestration infrastructure, not every marketing/compliance/executive skill.

Do not rely on docs pages as authoritative execution guidance when scripts and manifests exist. In this repo, docs lag behind implementation.

## Fit For Agentic Coding Lab

Fit is strongly in-scope. This is one of the richest examples of an instruction and skill support system for coding agents. It is not an agent client, but it directly improves agent behavior by packaging domain procedures, deterministic tools, memory patterns, security scans, and cross-agent install surfaces.

The best local adaptation would be a smaller, higher-consistency version: a curated skill set, one generated catalog, strict manifest validation, security scanning before install, no binary bundles, dry-run sync for every supported harness, and regression tests for trigger descriptions plus scripts.

## Reviewed Paths

- `/tmp/myagents-research/alirezarezvani-claude-skills/README.md`
- `/tmp/myagents-research/alirezarezvani-claude-skills/INSTALLATION.md`
- `/tmp/myagents-research/alirezarezvani-claude-skills/STORE.md`
- `/tmp/myagents-research/alirezarezvani-claude-skills/CLAUDE.md`
- `/tmp/myagents-research/alirezarezvani-claude-skills/GEMINI.md`
- `/tmp/myagents-research/alirezarezvani-claude-skills/SKILL-AUTHORING-STANDARD.md`
- `/tmp/myagents-research/alirezarezvani-claude-skills/SKILL_PIPELINE.md`
- `/tmp/myagents-research/alirezarezvani-claude-skills/.claude-plugin/marketplace.json`
- `/tmp/myagents-research/alirezarezvani-claude-skills/.codex-plugin/plugin.json`
- `/tmp/myagents-research/alirezarezvani-claude-skills/.codex/skills-index.json`
- `/tmp/myagents-research/alirezarezvani-claude-skills/.gemini/skills-index.json`
- `/tmp/myagents-research/alirezarezvani-claude-skills/.mcp.json`
- `/tmp/myagents-research/alirezarezvani-claude-skills/project-management/.mcp.json`
- `/tmp/myagents-research/alirezarezvani-claude-skills/scripts/install.sh`
- `/tmp/myagents-research/alirezarezvani-claude-skills/scripts/convert.sh`
- `/tmp/myagents-research/alirezarezvani-claude-skills/scripts/codex-install.sh`
- `/tmp/myagents-research/alirezarezvani-claude-skills/scripts/gemini-install.sh`
- `/tmp/myagents-research/alirezarezvani-claude-skills/scripts/sync-codex-skills.py`
- `/tmp/myagents-research/alirezarezvani-claude-skills/scripts/sync-gemini-skills.py`
- `/tmp/myagents-research/alirezarezvani-claude-skills/scripts/check_plugin_json.py`
- `/tmp/myagents-research/alirezarezvani-claude-skills/scripts/generate-docs.py`
- `/tmp/myagents-research/alirezarezvani-claude-skills/tests/test_skill_integrity.py`
- `/tmp/myagents-research/alirezarezvani-claude-skills/.github/workflows/ci-quality-gate.yml`
- `/tmp/myagents-research/alirezarezvani-claude-skills/.github/workflows/skill-security-audit.yml`
- `/tmp/myagents-research/alirezarezvani-claude-skills/.github/workflows/skill-quality-review.yml`
- `/tmp/myagents-research/alirezarezvani-claude-skills/docs/guides/agent-skills-for-codex.md`
- `/tmp/myagents-research/alirezarezvani-claude-skills/docs/guides/gemini-cli-skills-guide.md`
- `/tmp/myagents-research/alirezarezvani-claude-skills/docs/plugins/index.md`
- `/tmp/myagents-research/alirezarezvani-claude-skills/docs/orchestration.md`
- `/tmp/myagents-research/alirezarezvani-claude-skills/engineering/.claude-plugin/plugin.json`
- `/tmp/myagents-research/alirezarezvani-claude-skills/marketing-skill/.claude-plugin/plugin.json`
- `/tmp/myagents-research/alirezarezvani-claude-skills/engineering-team/playwright-pro/.claude-plugin/plugin.json`
- `/tmp/myagents-research/alirezarezvani-claude-skills/engineering/llm-wiki/.claude-plugin/plugin.json`
- `/tmp/myagents-research/alirezarezvani-claude-skills/engineering/skills/skill-security-auditor/SKILL.md`
- `/tmp/myagents-research/alirezarezvani-claude-skills/engineering/skills/skill-security-auditor/scripts/skill_security_auditor.py`
- `/tmp/myagents-research/alirezarezvani-claude-skills/engineering/skills/skill-security-auditor/references/threat-model.md`
- `/tmp/myagents-research/alirezarezvani-claude-skills/engineering/skills/skill-tester/SKILL.md`
- `/tmp/myagents-research/alirezarezvani-claude-skills/engineering/skills/skill-tester/scripts/`
- `/tmp/myagents-research/alirezarezvani-claude-skills/engineering/skills/focused-fix/SKILL.md`
- `/tmp/myagents-research/alirezarezvani-claude-skills/engineering-team/skills/tdd-guide/SKILL.md`
- `/tmp/myagents-research/alirezarezvani-claude-skills/commands/focused-fix.md`
- `/tmp/myagents-research/alirezarezvani-claude-skills/.claude/commands/plugin-audit.md`
- `/tmp/myagents-research/alirezarezvani-claude-skills/engineering-team/self-improving-agent/`
- `/tmp/myagents-research/alirezarezvani-claude-skills/engineering/llm-wiki/`
- `/tmp/myagents-research/alirezarezvani-claude-skills/engineering/agenthub/`

## Excluded Paths

- `/tmp/myagents-research/alirezarezvani-claude-skills/.git/`: VCS internals; commit captured separately.
- `/tmp/myagents-research/alirezarezvani-claude-skills/docs/` pages not named above: generated MkDocs output and SEO pages; sampled to understand docs drift, not reviewed page-by-page.
- `/tmp/myagents-research/alirezarezvani-claude-skills/.gemini/skills/` and `/tmp/myagents-research/alirezarezvani-claude-skills/.codex/skills/` contents beyond indexes and symlink shape: generated compatibility wrappers duplicating source skills.
- `/tmp/myagents-research/alirezarezvani-claude-skills/*.zip` and domain `*.zip` packages: binary distribution artifacts. One representative archive was listed to confirm it bundles `SKILL.md`, scripts, and references; archives were not extracted or reviewed exhaustively.
- `/tmp/myagents-research/alirezarezvani-claude-skills/docs/stylesheets/`, `docs/overrides/`, badges, and static site files: UI-only docs presentation, not skill execution behavior.
- `/tmp/myagents-research/alirezarezvani-claude-skills/custom-gpt/`, `STORE.md` commercial bundle details beyond package strategy: adjacent distribution/marketing material, not core Claude skill runtime.
- Domain skills not named in Reviewed Paths: skimmed by index, manifest, and representative examples. Full line-by-line review of all 188 Codex skills / 312 Gemini items was out of scope for one deep repo note.
- `eval-workspace/`: historical evaluation outputs; relevant as evidence of evaluation practice, but not part of current package execution path.
- `.github/ISSUE_TEMPLATE/`, funding, branch-protection config, and miscellaneous automation docs: project operations rather than skill packaging, context control, or execution.
