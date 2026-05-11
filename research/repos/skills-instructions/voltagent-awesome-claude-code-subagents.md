# VoltAgent/awesome-claude-code-subagents

- URL: https://github.com/VoltAgent/awesome-claude-code-subagents
- Category: skills-instructions
- Stars snapshot: 19,547 (GitHub REST API, captured 2026-05-11)
- Reviewed commit: 6f804f0cfab22fb62668855aa3d62ee3a1453077
- Reviewed at: 2026-05-11
- Status: reviewed
- Scope fit: in-scope
- Verdict: Large, useful corpus of Claude Code subagent definitions and role patterns, especially for dispatch descriptions, context handoff, model routing, and QA/error-prevention checklists. Best value is as a pattern library for subagent role design; weakest areas are corpus consistency, oversized boilerplate, minimal executable validation, and some over-broad tool permissions.

## Why It Matters

`awesome-claude-code-subagents` is directly relevant to Agentic Coding Lab because it externalizes coding-agent roles into installable Markdown files. The repository shows how a team can split agent behavior into specialized role prompts rather than packing every behavior into one main `AGENTS.md` or system prompt.

The interesting artifact is not a runtime agent framework. It is the role corpus: frontmatter trigger descriptions, tool allowlists, model routing, context-manager requests, phase-based workflows, inter-agent handoff notes, and specialized verification checklists. Those are reusable ingredients for subagents, skills, prompt packs, and coding-agent error prevention.

The repo also exposes practical failure modes that matter for any agent catalog: repeated prompt boilerplate, aspirational metrics with no tests, documentation/manifests drifting out of sync, and tool permissions that are broader than the role requires.

## What It Is

The repository is a curated Claude Code subagent catalog. In the reviewed checkout, it contains 144 checked-in agent Markdown files under `categories/`, 10 category README index files, 10 category plugin manifests under `categories/*/.claude-plugin/plugin.json`, one root marketplace manifest, an interactive installer script, and a small `subagent-catalog` Claude Code command set.

Each agent file uses YAML frontmatter:

- `name`: subagent identifier.
- `description`: trigger text used for selection.
- `tools`: Claude Code built-in tools and, in some files, named MCP or command-like tools.
- `model`: `haiku`, `sonnet`, or `opus`.

Most agent bodies follow a repeated contract: role definition, "When invoked" sequence, checklist, capability taxonomy, JSON communication protocol, phased development workflow, progress JSON, delivery notification, and integration notes with other agents.

The repository is installable through Claude Code plugin marketplace metadata or by manually copying `.md` files into `~/.claude/agents/` or `.claude/agents/`. The checked-in runtime logic is limited to browsing, fetching, and installing files; actual subagent invocation belongs to Claude Code.

## Research Themes

- Token efficiency: Moderate. Category plugins, `model` routing, isolated subagent contexts, and cached catalog commands reduce active context and cost. However, many agent definitions are 200-286 lines with repeated boilerplate, so raw prompt footprint is high unless loaded selectively.
- Context control: Strong pattern, weak enforcement. Agents commonly begin by querying `context-manager`, and README emphasizes isolated context windows. The repo does not implement the context manager or enforce context budgets.
- Sub-agent / multi-agent: Strong as a role-design corpus. Category 09 contains explicit orchestration agents for task decomposition, distribution, context management, error coordination, knowledge synthesis, performance monitoring, and approval-gated refactors.
- Domain-specific workflow: Strong. Language, infrastructure, QA/security, data/AI, DX, business/product, specialized-domain, and research agents encode domain checklists, quality gates, and handoff targets.
- Error prevention: Moderate to strong in instructions. Debugging, code review, security audit, QA, UI testing, error coordination, and safe-refactor agents include useful failure-prevention behaviors. Most are not backed by executable tests.
- Self-learning / memory: Conditional. `knowledge-synthesizer`, `context-manager`, `performance-monitor`, and postmortem patterns describe memory and learning, but the repository itself stores no run history or adaptive feedback loop.
- Popular skills: No install telemetry was reviewed. Locally valuable agents for Agentic Coding Lab are `codebase-orchestrator`, `context-manager`, `agent-organizer`, `multi-agent-coordinator`, `task-distributor`, `debugger`, `code-reviewer`, `test-automator`, `ui-ux-tester`, `security-auditor`, `frontend-developer`, `backend-developer`, `typescript-pro`, and `design-bridge`.

## Core Execution Path

The normal use path is file and plugin based:

1. A user installs a category plugin through Claude Code, runs the interactive installer, copies an individual agent file, or uses `agent-installer`.
2. Claude Code discovers subagent files in global or project agent directories.
3. Claude Code uses each frontmatter `description` as selection guidance, or the user explicitly asks for a named agent.
4. The selected subagent runs in its own context window with its configured tool set and model.
5. The subagent body requests context, executes a phased workflow, emits progress or handoff JSON, and returns a completion summary.

Repo-local supporting paths:

- `README.md` is the human-facing catalog and main index. It lists categories, agents, installation options, subagent structure, model routing, tool assignment philosophy, and the `subagent-catalog` tool.
- `categories/*/README.md` files provide per-category selection guides and common combinations. These are the practical dispatch index for humans and installer/search tools.
- `categories/*/*.md` files are the subagent definitions.
- `.claude-plugin/marketplace.json` groups categories into installable Claude Code plugins such as `voltagent-core-dev`, `voltagent-lang`, `voltagent-qa-sec`, and `voltagent-meta`.
- `categories/*/.claude-plugin/plugin.json` lists agents included in each plugin bundle.
- `install-agents.sh` is an interactive local/remote installer. It browses categories, toggles selected agents, and copies or downloads files into global or local Claude agent directories.
- `tools/subagent-catalog/` provides Claude Code commands for `list`, `search`, `fetch`, and `invalidate`, backed by a 12-hour cached copy of the root README.

There is no `docs/`, `examples/`, or `subagents/` directory in the reviewed checkout. Examples are inline in README files, command files, agent bodies, and `agent-installer.md`.

## Architecture

The architecture is a static catalog plus thin installation/search helpers:

- Root metadata: `README.md`, `CLAUDE.md`, `CONTRIBUTING.md`, `LICENSE`, `.gitignore`.
- Plugin metadata: `.claude-plugin/marketplace.json` and one `.claude-plugin/plugin.json` per category.
- Agent corpus: 10 numbered category directories under `categories/`.
- Tooling: `install-agents.sh` and `tools/subagent-catalog/`.
- Contribution check: `.github/workflows/enforce-plugin-version-bump.yml` checks category plugin version bumps and marketplace version sync when category Markdown changes.

The category layout is useful because it creates both ownership boundaries and install bundles:

- `01-core-development`: API, backend, frontend, fullstack, mobile, UI, GraphQL, microservices, desktop, realtime.
- `02-language-specialists`: TypeScript, Python, Go, Rust, Java, React, Vue, Angular, PHP, .NET, PowerShell, and other framework experts.
- `03-infrastructure`: cloud, DevOps, SRE, Kubernetes, Terraform, Docker, database, network, Windows infra.
- `04-quality-security`: code review, debugging, QA, test automation, security, compliance, performance, a11y, UI/UX testing.
- `05-data-ai`: data, ML, LLM, MLOps, NLP, prompt, Postgres, database optimization.
- `06-developer-experience`: CLI, build, docs, dependency, Git, MCP, readme, refactor, tooling, Slack, PowerShell module/UI.
- `07-specialized-domains`: blockchain, fintech, healthcare, IoT, M365, mobile apps, payments, quant, risk, SEO, embedded, game.
- `08-business-product`: business analysis, content, customer success, legal, license, product, project, sales, scrum, tech writing, UX research, WordPress.
- `09-meta-orchestration`: agent organization, context, task distribution, workflow orchestration, knowledge synthesis, error coordination, performance, safe refactors, IT ops routing.
- `10-research-analysis`: research, search, market, competitive, trend, idea validation, data research, scientific literature.

## Design Choices

The most important design choice is using subagent frontmatter as the dispatch contract. Descriptions are often specific enough to act as trigger rules, for example "Use this agent when..." or "Use when..." with task boundaries. Category README tables repeat these triggers in human-readable selection guides.

The second major choice is model routing. The README says `opus` is for deep reasoning, `sonnet` for everyday coding, and `haiku` for quick tasks. The reviewed corpus has 17 `haiku`, 102 `sonnet`, and 25 `opus` agents. This is a practical cost/quality pattern to copy, especially when paired with explicit trigger descriptions.

Tool permissions are role dependent in concept, but uneven in practice. The README describes read-only reviewers, research agents, code writers, and documentation agents. The actual corpus has 102 agents with full `Read, Write, Edit, Bash, Glob, Grep`; only a few roles such as `security-auditor` and `compliance-auditor` are truly read-only. Some review agents still have Write/Edit/Bash, which can blur analysis and modification responsibilities.

Most agent bodies encode a standard workflow grammar:

- Start with context retrieval.
- Analyze current state.
- Implement or review systematically.
- Track progress with JSON.
- Deliver with metrics and handoff notes.
- Name integration partners.

That grammar is reusable because it gives every specialist the same lifecycle while keeping domain logic local to the role.

The meta-orchestration category is the strongest reusable design section. `agent-organizer` handles task decomposition and capability matching. `task-distributor` handles queues, load balancing, priorities, and capacity. `multi-agent-coordinator` handles dependency graphs, parallel execution, deadlocks, and result aggregation. `context-manager` defines shared state, indexing, synchronization, cache, lifecycle, and access-control ideas. `codebase-orchestrator` adds a safe refactor protocol: map, propose, preview, wait for approval, execute only after approval.

The repository uses README as data source for search. `subagent-catalog` fetches the root README, caches it for 12 hours under `~/.claude/cache/subagent-catalog.md`, then uses substring search over names, descriptions, and category names. This is simple and token-efficient, but it couples command correctness to README/index accuracy.

## Strengths

The corpus gives many concrete examples of agent role specialization. It is useful when designing a local subagent because it shows what fields, trigger language, workflow phases, checklists, and handoff sections look like across domains.

The repeated "Communication Protocol" pattern is valuable. Agents emit structured JSON with `requesting_agent`, `request_type`, and domain-specific query payloads. This is a reusable convention for cross-agent calls even if the repo does not implement the message bus.

The best agents include specific error-prevention gates. `debugger` requires reproduction, root-cause identification, side-effect checks, validation, documentation, and prevention. `code-reviewer` prioritizes security, correctness, tests, performance, and maintainability. `ui-ux-tester` requires documented-flow coverage, interaction driving, screenshots, console/network checks, and defect reports. `codebase-orchestrator` enforces approval loops, diff previews, fallback reporting, and risk ranking.

The category plugin layout lets users install only relevant capability bundles. This is better than one all-or-nothing mega prompt because teams can choose language, QA/security, infrastructure, or meta-orchestration agents separately.

The catalog and installer are pragmatic. They support local and remote discovery, global or project installation, cache invalidation, and fetching a specific agent definition without cloning the repository.

The repo contains useful domain-specific prompt patterns beyond ordinary coding. `healthcare-admin` shows how to wrap an external specialized agent corpus into one high-level specialist with compliance/data-source boundaries. `design-bridge` shows how to bridge a design-memory repository into implementation-focused agents. `it-ops-orchestrator` shows "task smell" routing across PowerShell, Windows infra, Azure, M365, and security agents.

## Weaknesses

There is no executable validation for the subagent corpus itself. I did not find a schema check that verifies frontmatter, required sections, tool names, model names, broken agent links, or plugin manifest/file consistency.

The corpus has visible drift. The README badge says `131+` subagents, the marketplace manifest says `141 specialized Claude Code subagents`, and the checkout contains 144 agent files. Category plugin manifests include two missing QA files: `cost-accounting-performance-reviewer.md` and `performance-roi-translator.md`. They also omit two existing files: `healthcare-admin.md` and `agent-installer.md`. `categories/01-core-development/README.md` references `wordpress-master.md` as if it were local, but the file lives under `08-business-product`.

Many agents are large and formulaic. Several files are exactly or near 286 lines with repeated blocks for checklist, progress tracking, delivery notification, excellence checklist, and integration. This consistency helps generation, but it is expensive context if agents are loaded whole.

Some instructions are aspirational metrics rather than verifiable constraints. Examples include coordination overhead under 5 percent, 100 percent consistency, or 99.9 percent delivery guarantees without test harnesses or measurement hooks.

Tool permissions are broader than necessary for many roles. `code-reviewer` and `architect-reviewer` can write, edit, and run Bash even when their primary job is review. The repo does include read-only security/compliance agents, so a stricter permission split is possible.

Several agents assume unavailable or external tools. `codebase-orchestrator` lists tools such as `airis-mcp-gateway`, `context-manager`, `error-coordinator`, `pied-piper`, and `subagent-catalog:search`, but only the catalog commands are local to this repo. The external README entries for Airis, Pied Piper, and Taskade are useful pointers, not checked-in capabilities.

The `install-agents.sh` script parses GitHub API JSON with grep/sed and shell loops. It is sufficient for an interactive installer, but not as robust as a structured parser. It also writes into user agent directories, so it is not part of a deterministic test path.

## Ideas To Steal

Use frontmatter `description` as a precise trigger contract. Keep it specific to task type, not just a title.

Add `model` routing to subagents. Use cheaper models for search/listing/simple project management, stronger models for security, architecture, finance, healthcare, and large refactors.

Adopt a standard agent body contract: role, invocation steps, checklist, communication JSON, phased workflow, progress JSON, delivery summary, integration partners, and final priority rule.

Use per-category bundles for install and context control. A coding lab could expose `qa-security`, `frontend`, `infra`, `research`, and `meta` bundles rather than one huge prompt pack.

Copy the safe-refactor pattern from `codebase-orchestrator`: repository boundary scan, generated/vendor exclusions, risk weighting, before/after diff preview, explicit approval gate, deterministic fallback notes, and post-change verification.

Use `context-manager` as a design pattern, but make it concrete. Define exactly where context lives, how agents request it, what can be summarized, what must be exact, and how stale context is invalidated.

Use `subagent-catalog` style cached search as a lightweight discovery layer. Better version: generate a compact index from agent frontmatter instead of scraping README.

Create small specialist-orchestrators for ambiguous task domains. `it-ops-orchestrator` is a good example: route by "task smell", split sub-problems, assign specialists, merge outputs, and enforce safety workflows.

Use QA/security agents as post-processing gates. For example, route generated code through `code-reviewer`, UI changes through `ui-ux-tester` and `accessibility-tester`, and risky changes through `security-auditor`.

## Do Not Copy

Do not copy the corpus without adding a manifest/link validator. Broken plugin entries and README drift are easy to introduce in a large prompt catalog.

Do not give reviewers write/edit/bash permissions by default. Split "review only" and "apply fixes" agents, or require explicit escalation before mutation.

Do not treat aspirational metrics as evidence. If an agent claims latency, coverage, security posture, or coordination efficiency, pair that with commands, logs, tests, or dashboards.

Do not load full 200-286 line agent files for small subtasks if a shorter trigger plus targeted reference section would work. Use progressive disclosure or generated summaries for repeated boilerplate.

Do not assume external MCP/tool names in frontmatter are available. Validate tool names against the actual host environment before publishing a plugin.

Do not rely on README as the only machine-readable index. A normalized generated index from frontmatter and plugin manifests would be more reliable.

Do not use the healthcare, legal, finance, or security roles without domain review. Some files contain high-stakes domain guidance that should be treated as workflow scaffolding, not authoritative advice.

## Fit For Agentic Coding Lab

Fit is in-scope. The repository is not an agent app, but it is a high-signal skills/instructions corpus for subagent role design and coding-agent support systems.

For Agentic Coding Lab, the best adaptation is a smaller, verified subagent set with stricter permissions and generated indexes. Keep the useful role grammar, model routing, category bundles, context-manager protocol, safe-refactor approval gates, and QA/security post-processing agents. Add validation that this repository lacks: frontmatter schema checks, broken link checks, plugin/file consistency checks, tool-name validation, duplicate/missing category checks, and example dispatch tests.

The catalog is especially useful as a source of candidate roles. It should not be copied wholesale into active context. A local system should index these roles, retrieve only relevant sections, and prefer evidence-producing agents over broad role prompts.

## Reviewed Paths

- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/README.md`
- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/CLAUDE.md`
- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/CONTRIBUTING.md`
- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/LICENSE`
- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/.gitignore`
- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/.claude-plugin/marketplace.json`
- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/.github/workflows/enforce-plugin-version-bump.yml`
- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/install-agents.sh`
- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/tools/subagent-catalog/README.md`
- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/tools/subagent-catalog/config.sh`
- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/tools/subagent-catalog/list.md`
- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/tools/subagent-catalog/search.md`
- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/tools/subagent-catalog/fetch.md`
- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/tools/subagent-catalog/invalidate.md`
- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/categories/01-core-development/README.md`
- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/categories/01-core-development/.claude-plugin/plugin.json`
- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/categories/01-core-development/backend-developer.md`
- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/categories/01-core-development/frontend-developer.md`
- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/categories/01-core-development/design-bridge.md`
- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/categories/02-language-specialists/README.md`
- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/categories/02-language-specialists/typescript-pro.md`
- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/categories/04-quality-security/README.md`
- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/categories/04-quality-security/.claude-plugin/plugin.json`
- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/categories/04-quality-security/code-reviewer.md`
- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/categories/04-quality-security/debugger.md`
- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/categories/04-quality-security/test-automator.md`
- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/categories/04-quality-security/security-auditor.md`
- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/categories/04-quality-security/architect-reviewer.md`
- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/categories/04-quality-security/error-detective.md`
- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/categories/04-quality-security/ai-writing-auditor.md`
- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/categories/04-quality-security/ui-ux-tester.md`
- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/categories/07-specialized-domains/README.md`
- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/categories/07-specialized-domains/healthcare-admin.md`
- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/categories/09-meta-orchestration/README.md`
- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/categories/09-meta-orchestration/.claude-plugin/plugin.json`
- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/categories/09-meta-orchestration/agent-organizer.md`
- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/categories/09-meta-orchestration/multi-agent-coordinator.md`
- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/categories/09-meta-orchestration/task-distributor.md`
- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/categories/09-meta-orchestration/context-manager.md`
- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/categories/09-meta-orchestration/workflow-orchestrator.md`
- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/categories/09-meta-orchestration/codebase-orchestrator.md`
- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/categories/09-meta-orchestration/error-coordinator.md`
- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/categories/09-meta-orchestration/performance-monitor.md`
- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/categories/09-meta-orchestration/agent-installer.md`
- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/categories/09-meta-orchestration/it-ops-orchestrator.md`
- Directory and structure review of all `categories/*/*.md` agent files, all `categories/*/README.md` files, all `categories/*/.claude-plugin/plugin.json` files, and root tracked files, including counts for agents, model routing, tool-permission patterns, manifest/file mismatches, and README/index drift.

## Excluded Paths

- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/.git/`: VCS internals; reviewed commit captured separately.
- `/tmp/myagents-research/VoltAgent-awesome-claude-code-subagents/.claude/settings.local.json`: local Claude permission state; noted but excluded from catalog design analysis.
- Remote README badge images and VoltAgent logo assets: UI-only remote assets, not local agent behavior.
- External repositories linked from README or agent files, including Airis MCP Gateway, Pied Piper, Taskade MCP, healthcare-agents, avoid-ai-writing, awesome-design-md, and awesome-codex-subagents: useful references but outside this repo's checked-in execution path.
- Hosted Claude Code marketplace behavior: inferred from checked-in manifests and README only; the marketplace runtime itself is outside the clone.
- User target directories such as `~/.claude/agents/` and `.claude/agents/`: install destinations described by the repo, not part of the reviewed checkout.
- Byte-level review of shell UI formatting in `install-agents.sh`: installer flow, remote/local modes, API/raw URLs, and copy/download behavior were reviewed; ANSI colors and interactive menu presentation were not analyzed as agent-design substance.
- Generated, vendored, binary, and UI-only checked-in paths: none were present as substantive local corpus paths beyond remote README images and VCS internals.
