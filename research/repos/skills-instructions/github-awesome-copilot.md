# github/awesome-copilot

- URL: https://github.com/github/awesome-copilot
- Category: skills-instructions
- Stars snapshot: 32,655 (GitHub REST API, captured 2026-05-11)
- Reviewed commit: e07740bdd8e878cde35e3ee23eb2c1ab7afee864
- Reviewed at: 2026-05-11
- Status: reviewed
- Scope fit: in-scope
- Verdict: High-signal, very broad corpus of GitHub Copilot agents, instructions, skills, hooks, workflows, plugins, and SDK recipes. Best reusable patterns are file-native packaging, trigger-rich skill descriptions, path-scoped instructions, MCP-aware agents, plugin bundles, generated catalogs, and CI validation gates. Weakest areas are uneven quality across community submissions, limited runtime enforcement, and a large generated website surface that is not itself an agent-support pattern.

## Why It Matters

`github/awesome-copilot` is the largest reviewed corpus so far for GitHub Copilot customization primitives. It is not one agent app. It is a marketplace-style source tree for reusable agent guidance: custom agents, custom instructions, agent skills, hooks, agentic workflows, plugin bundles, and cookbook recipes.

For Agentic Coding Lab, this matters because it shows how GitHub's Copilot ecosystem is converging on small, file-based artifacts with frontmatter metadata and generated discovery surfaces. The repository also shows practical governance around community prompt assets: required frontmatter, naming rules, generated README checks, plugin manifests, skill validation, line-ending checks, and workflow compilation validation.

The strongest lesson is packaging architecture. Instructions are path-scoped standards, agents are role/tool configurations, skills are progressive-disclosure task packs with optional assets, hooks automate session events, workflows turn natural language into GitHub Actions automation, and plugins bundle agents plus skills into installable toolkits.

## What It Is

`github/awesome-copilot` is a community-maintained collection for GitHub Copilot customization. At the reviewed commit it contained 219 custom agents, 183 instruction files, 340 skills, 67 plugin READMEs, 6 hook folders, 8 agentic workflow markdown files, and Copilot SDK cookbook recipes across .NET, Node.js, Python, Go, and Java.

Core source directories:

- `agents/`: `*.agent.md` files with frontmatter such as `description`, `name`, `model`, `tools`, and sometimes `mcp-servers`.
- `instructions/`: `*.instructions.md` files with `description` and usually `applyTo` globs for path-scoped Copilot behavior.
- `skills/`: one folder per skill, usually `SKILL.md` plus optional `references/`, `assets/`, `scripts/`, templates, or prompt files.
- `plugins/`: installable bundles with `.github/plugin/plugin.json` and `README.md`; on `main`, plugin directories also contain materialized `agents/` and `skills/` copies.
- `hooks/`: hook packages with frontmatter README, `hooks.json`, and scripts for Copilot coding-agent session events.
- `workflows/`: agentic workflow markdown sources with frontmatter for triggers, permissions, tools, and `safe-outputs`.
- `cookbook/`: runnable Copilot SDK examples and recipe docs.
- `eng/`: Node.js scripts that parse frontmatter, generate README catalog pages, generate marketplace metadata, materialize plugin payloads, and validate manifests.
- `docs/README.*.md` and `README.md`: generated discovery catalogs.

Prompt packaging exists, but not primarily as a top-level `prompts/` directory in this reviewed checkout. Prompt-like artifacts are embedded as skill bodies, one `*.prompt.md` under `skills/polyglot-test-agent/`, agentic workflow markdown bodies, and plugin command descriptions.

## Research Themes

- Token efficiency: Strong structural pattern. Skills use metadata-first discovery: `name` and `description` are the trigger surface; detailed `SKILL.md` and bundled resources are loaded only when needed. The `agent-skills.instructions.md` file explicitly frames progressive loading as three levels: discovery metadata, full instructions, then resources.
- Context control: Strong. Instructions use `applyTo` globs, agents declare tool surfaces, skills split heavy details into references and scripts, and `what-context-needed` / `context-map` encode explicit context-request workflows before answering or editing.
- Sub-agent / multi-agent: Strong but uneven. The corpus includes multi-agent examples such as `polyglot-test-agent`, `ai-team-orchestration`, `gem-team`, TDD phase agents, planners, implementers, testers, fixers, and reviewers. Most are instruction protocols rather than a host-side orchestrator.
- Domain-specific workflow: Very strong. The repository covers language/framework guidance, MCP server generation, Azure/Dataverse/Power Platform workflows, testing, security, documentation, diagramming, Copilot SDK recipes, and AI-agent governance.
- Error prevention: Strong. Patterns include TDD red/green/refactor agents, Doublecheck verification, audit-integrity self-critique, line-ending checks, README regeneration checks, plugin structure checks, workflow safe outputs, hooks for secrets/license/tool guarding, and SDK error-handling recipes.
- Self-learning / memory: Conditional. Some skills and agents include memory or learning patterns (`dotnet-self-learning-architect`, `audit-integrity` lessons/memories, `mini-context-graph`, `ai-team-orchestration`), but there is no repository-wide runtime memory system.
- Popular skills: No usage or install-count data was reviewed, so this note does not rank true popularity. High-signal reusable skills for this research are `agent-skills`, `acquire-codebase-knowledge`, `copilot-instructions-blueprint-generator`, `suggest-awesome-github-copilot-*`, `context-map`, `what-context-needed`, `doublecheck`, `audit-integrity`, `agentic-eval`, and `polyglot-test-agent`.

## Core Execution Path

There are two execution paths: contribution/build-time and user/runtime.

Build-time path:

1. Contributors add files under `agents/`, `instructions/`, `skills/`, `hooks/`, `workflows/`, or `plugins/`.
2. Frontmatter and manifest conventions are validated by scripts such as `eng/validate-skills.mjs` and `eng/validate-plugins.mjs`.
3. `npm run build` runs `eng/update-readme.mjs` and `eng/generate-marketplace.mjs`.
4. `eng/update-readme.mjs` parses frontmatter with `vfile-matter`, generates catalog tables, creates VS Code / VS Code Insiders install links, extracts MCP server config from agents, and writes `docs/README.*.md`.
5. `eng/generate-marketplace.mjs` reads plugin metadata, merges `plugins/external.json`, and writes `.github/plugin/marketplace.json`.
6. CI verifies README freshness, plugin structure, line endings, skill/agent validity, and agentic workflow compileability.

Runtime path:

1. User installs or copies a resource through VS Code, Copilot CLI, GitHub CLI skill install, or manual file placement.
2. Copilot discovers the relevant primitive:
   - instructions apply by path glob;
   - agents become selectable role/tool configurations;
   - skills are selected by `name` and `description`;
   - hooks run on session events;
   - workflows run in GitHub Actions from markdown-defined triggers.
3. The host Copilot environment interprets the markdown instructions and invokes available tools/MCP servers/scripts as permitted by the host.

There is no central agent runtime in this repository. The repo supplies packaged guidance, generated catalogs, validation scripts, and examples; enforcement and tool execution belong to GitHub Copilot clients, GitHub Actions, Copilot CLI, VS Code, or external MCP servers.

Representative execution paths:

- `suggest-awesome-github-copilot-skills`: fetch remote skill catalog, scan local `.github/skills/`, compare local and remote `SKILL.md`, present install/update table, then only download assets after user request.
- `context-map`: search codebase, list files to modify, dependencies, tests, reference patterns, and risk assessment before implementation.
- `polyglot-test-agent`: coordinate a research -> plan -> implement pipeline, store state under `.testagent/`, then run builder/tester/fixer/linter agents to produce tests that compile and pass.
- `doublecheck`: extract verifiable claims, search sources, run adversarial review, and output a source-linked verification report.
- `relevance-check` workflow: on slash command, read issue/PR context, inspect current repository state, and post one bounded comment via `safe-outputs`.

## Architecture

The architecture is filesystem-native and catalog-driven.

Source primitives are plain markdown plus YAML frontmatter. Instructions are single files. Agents are single files with optional MCP metadata. Skills are directories with `SKILL.md` and optional resources. Hooks are directories with a README and `hooks.json`. Workflows are markdown files with agentic workflow frontmatter. Plugins are directories with `.github/plugin/plugin.json` and a README.

The `eng/` scripts form the build layer:

- `yaml-parser.mjs`: parses generic frontmatter, agent metadata, MCP server configs, skills, hooks, workflows, and YAML files.
- `constants.mjs`: defines generated section text, install-badge templates, directories, and validation constants.
- `update-readme.mjs`: builds catalog pages, fetches MCP registry names, generates install links, and updates featured plugin sections.
- `generate-marketplace.mjs`: generates `.github/plugin/marketplace.json` from plugin manifests and external plugin entries.
- `materialize-plugins.mjs`: copies root source agents and skills into plugin directories for published `main`, then rewrites plugin manifest paths to directory references.
- `validate-skills.mjs` and `validate-plugins.mjs`: enforce naming, required metadata, existence checks, sorted path arrays, and size limits.

GitHub Actions add guardrails:

- `validate-readme.yml`: runs plugin validation and `npm start`, then fails if generated files are stale.
- `check-plugin-structure.yml`: prevents materialized plugin files and symlinks from entering PRs targeting `staged`.
- `skill-check.yml`: runs an external skill-validator against changed skill/agent files in warn/report mode.
- `validate-agentic-workflows-pr.yml`: blocks compiled workflow YAML under `workflows/`, then compiles markdown sources with `gh aw compile --validate`.
- `check-line-endings.yml`: blocks CRLF in markdown.

The website is a separate display surface. It uses generated data, images, learning-hub pages, and UI assets. It is useful for discovery, but the reusable agent-support patterns live mostly in markdown, plugin manifests, scripts, and CI checks.

## Design Choices

The primary design choice is primitive separation. Instructions, agents, skills, hooks, workflows, plugins, and cookbook examples each have distinct file formats, installation paths, and use cases. This avoids collapsing all guidance into one giant prompt.

The second choice is frontmatter as contract. Every major artifact has required metadata. Instructions require `description` and usually `applyTo`. Agents require descriptive metadata and often declare `tools`, `model`, and MCP server config. Skills require `name` and a trigger-rich `description`. Workflows require `name`, `description`, `on`, permissions, and safe outputs.

The third choice is generated catalogs. The repo does not ask humans to maintain huge tables by hand. Build scripts read source files and produce `docs/README.*.md`, install badges, MCP links, bundled asset lists, and marketplace JSON.

The fourth choice is plugin bundling without source duplication on contribution branches. The contributing docs say source files live in top-level directories and plugins reference them declaratively. On published `main`, `materialize-plugins.mjs` copies files into plugin directories so plugin installs are self-contained. CI blocks those materialized copies from PRs to `staged`.

The fifth choice is safety through workflow shape. Workflow sources use `safe-outputs`, least-privilege permissions, and markdown-only submissions. Hooks include guard-style examples for secrets, licenses, dangerous tools, and governance logs. Agent safety instructions recommend allowlists, policy-as-config, human approval for high-impact tools, rate limits, and append-only audit logs.

## Strengths

The corpus is broad enough to reveal repeatable prompt-engineering patterns across many domains. Good descriptions specify both capability and activation triggers, which improves skill discovery.

The packaging model is practical. A team can copy one instruction, install one skill, select one agent, or install a plugin bundle. This gives a gradient from small local customization to larger workflow kits.

Context control is unusually explicit. `agent-skills.instructions.md` teaches skill authors to keep heavy materials in `references/`, `scripts/`, `assets/`, and `templates`; `context-engineering.instructions.md` teaches file-path, open-tab, and codebase-pattern context; `what-context-needed` and `context-map` turn context discovery into first-class workflows.

Verification appears at several layers. The repo includes human-facing verification protocols (`doublecheck`), engineering validation loops (`polyglot-test-agent` builder/tester/fixer), workflow safe outputs, CI-generated catalog checks, and contribution checklists.

The MCP pattern is well integrated. Agents can declare `mcp-servers`; generated docs turn those configs into install links; `.vscode/mcp.json` configures the GitHub Agentic Workflows MCP server for repo development.

## Weaknesses

Quality is uneven because this is a community corpus. Some entries are concise and actionable; others are broad persona prompts, promotional, or highly domain-specific. A downstream lab should curate, not bulk import.

Runtime enforcement is outside the repo. Tool allowlists, safe outputs, hooks, and workflow permissions matter only where the host honors them. Markdown instructions are not a security boundary.

The generated docs and README are huge. They are useful for browsing but noisy for deep analysis; the raw source files and build scripts are the better review targets.

The plugin story has branch-specific complexity. Contribution branches should contain declarative plugin manifests only, while `main` contains materialized plugin payloads. This is reasonable operationally but easy for contributors to misunderstand.

Some scripts and docs mention prompts/commands/collections more broadly than the reviewed source tree currently exposes. At this commit, prompt packaging is mostly skill-embedded rather than a complete standalone prompts directory.

## Ideas To Steal

Use separate primitives for separate jobs: path-scoped instructions, role/tool agents, task-specific skills, session hooks, action workflows, and plugin bundles.

Make skill descriptions trigger contracts. Include what the skill does, when to use it, and phrases users might say.

Adopt progressive disclosure as a required skill style. Keep metadata tiny, `SKILL.md` concise, and deeper references/scripts loaded only when relevant.

Generate discovery catalogs from source metadata. Avoid hand-maintained tables for large instruction/skill/agent libraries.

Add validation scripts for metadata and manifests. The skill/plugin validators are simple but effective: names, descriptions, path references, sorted arrays, asset size limits, and duplicate checks.

Package related agents and skills into installable plugins while preserving root source ownership. This allows `context-engineering`, `doublecheck`, `testing-automation`, or `polyglot-test-agent` style bundles.

Use `safe-outputs` and least-privilege permissions for agentic workflows. Treat generated workflow YAML as downstream output, not a community-submitted source artifact.

Design verification as reusable prompt infrastructure. `doublecheck`, `audit-integrity`, TDD agents, and polyglot builder/tester/fixer roles all encode specific failure-prevention loops.

## Do Not Copy

Do not import the whole corpus. It contains many overlapping, domain-specific, or low-signal entries. Copy patterns and curated examples, not volume.

Do not rely on markdown instructions for hard safety. Use host-enforced permissions, sandboxing, policy gates, approval workflows, and audit logs for real boundaries.

Do not copy generated website assets, screenshots, fonts, or learning-hub media into Agentic Coding Lab. They are discovery/UI material, not core agent support logic.

Do not copy materialized plugin directories into contribution branches without understanding the staged/main split.

Do not treat star count as quality for individual artifacts. The repository is popular as a collection, but individual skill/agent quality still needs review and eval.

Do not preserve emoji-heavy display text if building a terse internal research corpus. Keep the operational structure and constraints; adapt presentation to local style.

## Fit For Agentic Coding Lab

Fit is in-scope and strong. This repository is directly about reusable Copilot guidance, custom agents, skills, instructions, plugins, workflow automation, hooks, and verification patterns.

The best local adaptation would be a smaller curated library: a few high-value instructions, a few context-control skills, one or two verification skills, and plugin bundles for common coding workflows. The repo's build/validation pattern is more reusable than most individual prompts.

For Agentic Coding Lab, the immediate artifact candidates are:

- a skill template that requires trigger-rich descriptions, resource split, gotchas, troubleshooting, and verification steps;
- a catalog generator for local skills/instructions/agents;
- a plugin manifest convention with path validation;
- a context-map skill and a "what files do you need" micro-skill;
- a Doublecheck-like verification skill for research outputs;
- a polyglot test pipeline pattern with explicit research, plan, build, test, fix, and lint stages.

## Reviewed Paths

- `/tmp/myagents-research/github-awesome-copilot/README.md`
- `/tmp/myagents-research/github-awesome-copilot/AGENTS.md`
- `/tmp/myagents-research/github-awesome-copilot/CONTRIBUTING.md`
- `/tmp/myagents-research/github-awesome-copilot/package.json`
- `/tmp/myagents-research/github-awesome-copilot/docs/README.agents.md`
- `/tmp/myagents-research/github-awesome-copilot/docs/README.instructions.md`
- `/tmp/myagents-research/github-awesome-copilot/docs/README.skills.md`
- `/tmp/myagents-research/github-awesome-copilot/docs/README.plugins.md`
- `/tmp/myagents-research/github-awesome-copilot/docs/README.hooks.md`
- `/tmp/myagents-research/github-awesome-copilot/docs/README.workflows.md`
- `/tmp/myagents-research/github-awesome-copilot/.github/copilot-instructions.md`
- `/tmp/myagents-research/github-awesome-copilot/.github/pull_request_template.md`
- `/tmp/myagents-research/github-awesome-copilot/.github/plugin/marketplace.json`
- `/tmp/myagents-research/github-awesome-copilot/.github/workflows/skill-check.yml`
- `/tmp/myagents-research/github-awesome-copilot/.github/workflows/check-plugin-structure.yml`
- `/tmp/myagents-research/github-awesome-copilot/.github/workflows/validate-readme.yml`
- `/tmp/myagents-research/github-awesome-copilot/.github/workflows/check-line-endings.yml`
- `/tmp/myagents-research/github-awesome-copilot/.github/workflows/validate-agentic-workflows-pr.yml`
- `/tmp/myagents-research/github-awesome-copilot/.schemas/collection.schema.json`
- `/tmp/myagents-research/github-awesome-copilot/.schemas/tools.schema.json`
- `/tmp/myagents-research/github-awesome-copilot/.schemas/cookbook.schema.json`
- `/tmp/myagents-research/github-awesome-copilot/.vscode/mcp.json`
- `/tmp/myagents-research/github-awesome-copilot/.vscode/tasks.json`
- `/tmp/myagents-research/github-awesome-copilot/eng/constants.mjs`
- `/tmp/myagents-research/github-awesome-copilot/eng/yaml-parser.mjs`
- `/tmp/myagents-research/github-awesome-copilot/eng/update-readme.mjs`
- `/tmp/myagents-research/github-awesome-copilot/eng/generate-marketplace.mjs`
- `/tmp/myagents-research/github-awesome-copilot/eng/materialize-plugins.mjs`
- `/tmp/myagents-research/github-awesome-copilot/eng/validate-skills.mjs`
- `/tmp/myagents-research/github-awesome-copilot/eng/validate-plugins.mjs`
- `/tmp/myagents-research/github-awesome-copilot/instructions/agent-skills.instructions.md`
- `/tmp/myagents-research/github-awesome-copilot/instructions/agent-safety.instructions.md`
- `/tmp/myagents-research/github-awesome-copilot/instructions/context-engineering.instructions.md`
- `/tmp/myagents-research/github-awesome-copilot/instructions/taming-copilot.instructions.md`
- `/tmp/myagents-research/github-awesome-copilot/instructions/task-implementation.instructions.md`
- `/tmp/myagents-research/github-awesome-copilot/agents/context-architect.agent.md`
- `/tmp/myagents-research/github-awesome-copilot/agents/doublecheck.agent.md`
- `/tmp/myagents-research/github-awesome-copilot/agents/task-planner.agent.md`
- `/tmp/myagents-research/github-awesome-copilot/agents/playwright-tester.agent.md`
- `/tmp/myagents-research/github-awesome-copilot/agents/tdd-red.agent.md`
- `/tmp/myagents-research/github-awesome-copilot/agents/polyglot-test-planner.agent.md`
- `/tmp/myagents-research/github-awesome-copilot/agents/polyglot-test-builder.agent.md`
- `/tmp/myagents-research/github-awesome-copilot/agents/polyglot-test-tester.agent.md`
- `/tmp/myagents-research/github-awesome-copilot/skills/suggest-awesome-github-copilot-instructions/SKILL.md`
- `/tmp/myagents-research/github-awesome-copilot/skills/suggest-awesome-github-copilot-skills/SKILL.md`
- `/tmp/myagents-research/github-awesome-copilot/skills/copilot-instructions-blueprint-generator/SKILL.md`
- `/tmp/myagents-research/github-awesome-copilot/skills/what-context-needed/SKILL.md`
- `/tmp/myagents-research/github-awesome-copilot/skills/acquire-codebase-knowledge/SKILL.md`
- `/tmp/myagents-research/github-awesome-copilot/skills/context-map/SKILL.md`
- `/tmp/myagents-research/github-awesome-copilot/skills/doublecheck/SKILL.md`
- `/tmp/myagents-research/github-awesome-copilot/skills/audit-integrity/SKILL.md`
- `/tmp/myagents-research/github-awesome-copilot/skills/audit-integrity/references/anti-rationalization-guard.md`
- `/tmp/myagents-research/github-awesome-copilot/skills/audit-integrity/references/self-reflection-quality-gate.md`
- `/tmp/myagents-research/github-awesome-copilot/skills/audit-integrity/references/retry-protocol.md`
- `/tmp/myagents-research/github-awesome-copilot/skills/audit-integrity/references/self-learning-system.md`
- `/tmp/myagents-research/github-awesome-copilot/skills/structured-autonomy-implement/SKILL.md`
- `/tmp/myagents-research/github-awesome-copilot/skills/agentic-eval/SKILL.md`
- `/tmp/myagents-research/github-awesome-copilot/skills/polyglot-test-agent/SKILL.md`
- `/tmp/myagents-research/github-awesome-copilot/skills/polyglot-test-agent/unit-test-generation.prompt.md`
- `/tmp/myagents-research/github-awesome-copilot/plugins/awesome-copilot/README.md`
- `/tmp/myagents-research/github-awesome-copilot/plugins/awesome-copilot/.github/plugin/plugin.json`
- `/tmp/myagents-research/github-awesome-copilot/plugins/context-engineering/.github/plugin/plugin.json`
- `/tmp/myagents-research/github-awesome-copilot/plugins/doublecheck/.github/plugin/plugin.json`
- `/tmp/myagents-research/github-awesome-copilot/plugins/testing-automation/.github/plugin/plugin.json`
- `/tmp/myagents-research/github-awesome-copilot/plugins/polyglot-test-agent/.github/plugin/plugin.json`
- `/tmp/myagents-research/github-awesome-copilot/plugins/gem-team/.github/plugin/plugin.json`
- `/tmp/myagents-research/github-awesome-copilot/plugins/external.json`
- `/tmp/myagents-research/github-awesome-copilot/hooks/session-auto-commit/README.md`
- `/tmp/myagents-research/github-awesome-copilot/hooks/session-auto-commit/hooks.json`
- `/tmp/myagents-research/github-awesome-copilot/workflows/relevance-check.md`
- `/tmp/myagents-research/github-awesome-copilot/workflows/relevance-summary.md`
- `/tmp/myagents-research/github-awesome-copilot/cookbook/README.md`
- `/tmp/myagents-research/github-awesome-copilot/cookbook/copilot-sdk/README.md`
- `/tmp/myagents-research/github-awesome-copilot/cookbook/copilot-sdk/nodejs/error-handling.md`

## Excluded Paths

- `/tmp/myagents-research/github-awesome-copilot/.git/`: VCS internals; reviewed commit captured separately.
- `/tmp/myagents-research/github-awesome-copilot/website/`: UI application and generated/static website display layer. Reviewed by directory listing only because the task focuses on reusable Copilot instructions, agents, skills, prompts, and packaging.
- `/tmp/myagents-research/github-awesome-copilot/website/public/images/` and `/tmp/myagents-research/github-awesome-copilot/website/public/fonts/`: binary and UI-only media assets; not relevant to prompt execution patterns.
- `/tmp/myagents-research/github-awesome-copilot/README.md` contributor table after the introductory/catalog sections: generated contributor HTML, not agent behavior.
- `/tmp/myagents-research/github-awesome-copilot/.all-contributorsrc`: contributor metadata, not relevant to agent-support architecture.
- `/tmp/myagents-research/github-awesome-copilot/package-lock.json` and language recipe lockfiles: dependency snapshots; noted that Node build exists, not reviewed line-by-line.
- `/tmp/myagents-research/github-awesome-copilot/CODE_OF_CONDUCT.md`, `SECURITY.md`, `SUPPORT.md`, `LICENSE`, and `CODEOWNERS`: governance/support/license files were skimmed or listed, but not central to instruction-system behavior.
- Most individual `agents/*.agent.md`, `instructions/*.instructions.md`, and `skills/*/SKILL.md` not named above: reviewed by counts, filenames, catalog rows, and representative samples rather than line-by-line because the corpus is broad and repetitive.
- Materialized plugin payload copies under `plugins/*/agents/` and `plugins/*/skills/`: reviewed representative plugin manifests and one materialized listing; copies are generated/duplicated from root source artifacts on `main`.
- Remaining hook folders under `hooks/`: reviewed generated hook catalog and `session-auto-commit` as a representative package; other hooks are similar session-event packages and were not line-by-line targets.
- Remaining workflow files under `workflows/`: reviewed two representative workflows and CI compile rules; the rest are similar markdown agentic workflow sources.
- Copilot SDK recipe source files across all languages under `cookbook/copilot-sdk/*/recipe/`: reviewed cookbook organization and Node.js error-handling recipe; full SDK examples are useful but peripheral to the skills-instructions category.
- `.github/workflows/*.lock.yml` and compiled/generated workflow outputs: relevant as downstream build artifacts, but not source patterns to copy.
