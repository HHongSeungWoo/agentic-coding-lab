# anthropics/claude-plugins-official

- URL: https://github.com/anthropics/claude-plugins-official
- Category: skills-instructions
- Stars snapshot: 28,358 (GitHub REST API, captured 2026-05-29)
- Reviewed commit: 8435428dfc0fd6e4fea1c8e505ef5022b1f0d403
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: in-scope
- Verdict: High-value reference for Claude Code plugin packaging, marketplace metadata, component discovery, CI policy gates, hook permission review, MCP distribution, and workflow plugins. It is a catalog and packaging corpus rather than a host runtime, so the strongest reusable patterns are the directory contracts, marketplace checks, and selected plugin designs.

## Why It Matters

This repository is Anthropic's official curated directory for Claude Code plugins. It matters because it shows the packaging surface around skills, commands, agents, hooks, and MCP servers as they are distributed through a marketplace, not just as loose prompt files.

For Agentic Coding Lab, the repo is useful in two ways. First, it documents the plugin contract: a plugin directory with `.claude-plugin/plugin.json`, optional `.mcp.json`, and conventional `commands/`, `agents/`, `skills/`, and `hooks/` directories. Second, it contains operational guardrails around that contract: SHA-pinned external entries, marketplace validation, frontmatter checks, license checks, MCP endpoint probes, policy scans, and nightly upstream bump automation.

The repo also complements `anthropics/skills`. `anthropics/skills` is mostly a skill corpus; this repo is a marketplace and plugin corpus. It shows how skills become installable bundles alongside hooks, MCP servers, slash commands, and subagents.

## What It Is

`anthropics/claude-plugins-official` is a Claude Code plugin marketplace repository. The top-level `README.md` describes `/plugins` as Anthropic-maintained internal plugins and `/external_plugins` as third-party partner/community plugins. The top-level `.claude-plugin/marketplace.json` is the registry. At the reviewed commit, it contained 204 marketplace entries: 50 local source entries that point to paths in this repository and 154 external source entries pinned to upstream commits.

Local plugins are normal directories such as `plugins/plugin-dev`, `plugins/mcp-server-dev`, `plugins/security-guidance`, `plugins/feature-dev`, `plugins/code-modernization`, `plugins/pr-review-toolkit`, and vendored external integrations such as `external_plugins/github`, `external_plugins/discord`, and `external_plugins/serena`. Each plugin has its own `.claude-plugin/plugin.json`; many also include `.mcp.json`, `skills/`, `agents/`, `commands/`, `hooks/`, helper scripts, references, examples, and README files.

The marketplace supports multiple source shapes. Local entries use string paths such as `./plugins/plugin-dev`. External entries use source objects with upstream URL, optional subdirectory path, ref, and pinned `sha`. The README also documents "skill-bundle plugins" where an upstream repo can expose selected `SKILL.md` directories through a `strict: false` marketplace entry and a `skills` array; those skills are registered as `<plugin-name>:<skill-name>` in Claude Code.

## Research Themes

- Token efficiency: Strong. The system layers context through marketplace metadata, plugin manifests, component frontmatter, skill bodies, references, examples, and scripts. `mcp-server-dev` explicitly recommends search-plus-execute for large API surfaces so Claude does not carry hundreds of tool schemas in context.
- Context control: Strong. Plugin components are discovered by convention and loaded by need: commands when invoked, agents by task, skills by description, hooks by event, MCP tools by server. `skill-development` and `skill-creator` both promote progressive disclosure and moving long reference material out of `SKILL.md`.
- Sub-agent / multi-agent: Strong. `feature-dev`, `code-modernization`, and `pr-review-toolkit` encode multi-agent workflows for exploration, architecture, testing, security, and review. The repo does not implement the Task runtime; it packages agent definitions and command workflows that rely on Claude Code.
- Domain-specific workflow: Very strong. The catalog spans plugin authoring, MCP development, code modernization, feature development, PR review, security review, LSP setup, frontend design, session reports, math proof work, and partner MCP integrations.
- Error prevention: Very strong. Repo CI validates marketplace/plugin invariants, frontmatter, licenses, MCP URL liveness, and external plugin policy. Runtime examples include `security-guidance` and `hookify`, which use hooks to warn, block, or review work.
- Self-learning / memory: Moderate. `hookify` turns observed mistakes or explicit preferences into `.claude/hookify.*.local.md` local rules; `claude-md-management` updates project instructions from session learnings; `security-guidance` keeps session state and finding dedupe files. There is no general long-term memory architecture.
- Popular skills: No per-plugin install or usage data was reviewed. Locally important plugin/skill patterns include `plugin-dev`, `mcp-server-dev`, `skill-creator`, `security-guidance`, `hookify`, `feature-dev`, `code-modernization`, `pr-review-toolkit`, `claude-md-management`, and the MCP integrations under `external_plugins/`.

## Core Execution Path

Installation starts from Claude Code, not from code in this repo. The user can run `/plugin install {plugin-name}@claude-plugins-official` or browse `/plugin > Discover`. Claude Code reads the marketplace entry, resolves either a local path in the checked-out marketplace or a pinned upstream source, then loads the plugin's `.claude-plugin/plugin.json`.

Once a plugin is enabled, Claude Code discovers components from default locations and any custom paths in the manifest. Slash commands are loaded from `commands/*.md` and user-invoked skill frontmatter. Skills are loaded from `skills/<skill>/SKILL.md` when their descriptions match the task. Agents are loaded from `agents/*.md` and made available for manual or automatic Task use. Hooks are registered from `hooks/hooks.json` or manifest configuration. MCP servers are started or connected from `.mcp.json` or `mcpServers` manifest configuration.

Representative paths:

- `plugin-dev`: `/plugin-dev:create-plugin` guides an eight-phase authoring workflow: discovery, component planning, detailed design, structure creation, component implementation, validation, testing, and documentation. Its skills cover plugin structure, command development, agent development, skill development, hook development, plugin settings, and MCP integration.
- `mcp-server-dev`: `build-mcp-server` first asks discovery questions, then chooses remote HTTP, MCP app, MCPB, or local stdio, picks one-tool-per-action versus search-plus-execute, and routes to specialized references or skills.
- `security-guidance`: hooks run on session start, prompt submission, edit/write tool use, git commit/push commands, and stop. They combine regex warnings, LLM diff review, and agentic commit review, with README disclosure of model calls and local logs.
- `hookify`: broad hooks run on prompt, tool, and stop events, but rule evaluation is configured by project-local `.claude/hookify.*.local.md` files. Matching rules can warn or block.
- `feature-dev`, `code-modernization`, and `pr-review-toolkit`: commands orchestrate parallel agents, gather file lists or findings, then force explicit human checkpoints before risky stages.

The repo does not contain Claude Code's plugin loader, permission prompt implementation, MCP transport runtime, or Task scheduler. Those are host boundaries. This repo supplies plugin metadata, instructions, examples, scripts, CI, and policy.

## Architecture

The architecture is registry-plus-components:

- `README.md`: marketplace purpose, install flow, plugin directory layout, skill-bundle plugin example, and trust warning.
- `.claude-plugin/marketplace.json`: the official plugin registry, with local path sources and external SHA-pinned source objects.
- `plugins/`: Anthropic-maintained local plugin directories.
- `external_plugins/`: vendored or partner plugin directories, many centered on MCP integrations.
- `<plugin>/.claude-plugin/plugin.json`: per-plugin manifest with name, description, author, optional version/homepage/repository fields, and optional component path overrides.
- `<plugin>/.mcp.json`: MCP server config for stdio, SSE, HTTP, or wrapped `mcpServers` shapes.
- `<plugin>/commands/*.md`: slash command workflows with frontmatter such as `description`, `argument-hint`, `allowed-tools`, and `disable-model-invocation`.
- `<plugin>/agents/*.md`: subagent definitions with `name`, `description`, `model`, `color`, and optional `tools`.
- `<plugin>/skills/<skill>/SKILL.md`: model-triggered or user-invoked skills, often with `references/`, `examples/`, `scripts/`, `assets/`, or `evals/`.
- `<plugin>/hooks/hooks.json` and hook scripts: event handlers for `SessionStart`, `UserPromptSubmit`, `PreToolUse`, `PostToolUse`, `Stop`, and related events.
- `.github/workflows/` and `.github/scripts/`: validation, policy scanning, license checks, MCP URL liveness checks, frontmatter parsing, external SHA bumps, and failed-bump reverts.
- `.github/policy/`: policy scan prompt and JSON schema for plugin security/privacy review.

## Design Choices

The most important design choice is to keep marketplace metadata separate from plugin payloads. `marketplace.json` is the install/discovery index; each plugin manifest is the local identity document; component files remain plain Markdown, JSON, Python, shell, or TypeScript.

External plugin entries are SHA-pinned. The validation workflow treats SHA pinning as a hard invariant for the official curated marketplace. Nightly automation bumps upstream SHAs, validates the new plugin, dispatches the policy scan, and can revert only the failing entries so one bad upstream does not block the rest.

Plugins are component-based and convention-driven. Default component paths keep simple plugins small; manifest path overrides support larger organizations. `${CLAUDE_PLUGIN_ROOT}` is the portability anchor for hook commands, MCP stdio servers, command snippets, and plugin-internal file references.

Skills are treated as the preferred modern format for both model-invoked capabilities and user-invoked slash-command-like flows, while `commands/*.md` remains as a legacy slash command layout. The example plugin documents this transition explicitly.

Tool permissions are encoded close to the component. Commands use `allowed-tools` to pre-allow only needed tools or specific Bash command patterns. Agents can restrict `tools`. MCP tools are prefixed by plugin and server name, and `plugin-dev` advises pre-allowing specific MCP tools rather than wildcards.

Hooks are powerful but treated as a policy-sensitive surface. The policy scan prompt requires every registered hook to be enumerated, checks whether prompt/tool hooks are broad or project-gated, examines network calls and data access, and fails broad-scope hooks or undisclosed telemetry. This turns hook behavior into a marketplace review axis, not just a convenience feature.

MCP guidance is opinionated. Remote HTTP is the default for cloud APIs; MCPB is reserved for local filesystem, desktop, localhost, or OS-level needs; local stdio is acceptable for prototypes but discouraged for distribution. The MCPB docs emphasize that there is no manifest-level sandbox and every tool handler must validate paths, process spawning, sizes, and secrets.

## Strengths

The repo is the best reviewed example of a real Claude Code plugin marketplace contract. It shows how plugin distribution, discovery, installation, packaging, and policy can be represented as ordinary files and CI checks.

The quality gate story is unusually strong. Validation includes marketplace invariants, frontmatter parsing, required licenses for internal plugins, MCP endpoint liveness, an explicit security/privacy policy prompt, structured scan output, verdict caching, sticky PR comments, and automatic failed-bump reverts.

The plugin authoring materials are practical. `plugin-dev` does not just explain structure; it includes skills, agents, examples, and utility scripts for hooks, settings, command frontmatter, agent validation, and MCP integration. It is a reusable authoring kit.

The repo contains real hook patterns at several maturity levels. `security-guidance` is a sophisticated review hook with privacy disclosure, environment toggles, diff baselines, async rewake, pattern matching, model review, and dedupe. `hookify` is a simpler user-configurable rule system that translates local markdown rules into hook behavior.

The workflow plugins encode useful agentic coding patterns. `feature-dev` uses exploration agents before design, asks clarifying questions before implementation, and runs review agents after implementation. `code-modernization` stages artifacts and human gates before transformation. `pr-review-toolkit` splits review into specialized agents instead of one generic reviewer.

## Weaknesses

The repository does not include the host-side loader, permission UI, Task runtime, MCP runtime, or installation implementation. Any research conclusion about actual runtime enforcement must be verified against Claude Code itself.

Many marketplace entries are external pointers, not vendored source. The repo pins and scans them, but a local deep review of this repo can only inspect the registry metadata unless each upstream is cloned separately.

Some validation logic is external to this repo through pinned GitHub actions in `anthropics/claude-plugins-community`. That is a reasonable supply-chain design, but it means the full invariant set is not locally auditable from this checkout alone.

Policy scanning is model-assisted. It is valuable for privacy/security review, especially hooks and telemetry, but it should not replace deterministic static checks, manual review, or sandboxing for high-risk plugins.

Plugin-level permission controls are advisory or host-mediated. `allowed-tools`, agent `tools`, hook decisions, and MCP annotations can reduce risk, but local MCPB servers and stdio MCP servers still run with user privileges unless the server code implements its own containment.

The repo has many README-described workflows but limited conventional test coverage for every plugin. Some helper scripts are clearly educational or best-effort rather than a comprehensive plugin test harness.

## Ideas To Steal

Use a one-file marketplace index that can reference local plugins and external pinned upstreams. Store enough source provenance to reproduce exactly what was reviewed.

Make SHA pinning non-negotiable for external marketplace entries. Pair automated bumps with validation, policy scans, verdict caching, and targeted reverts so freshness does not bypass review.

Adopt the plugin directory contract: `.claude-plugin/plugin.json`, optional `.mcp.json`, and root-level `commands/`, `agents/`, `skills/`, and `hooks/`. Keep components plain files so humans can review them.

Treat hook review as a first-class marketplace gate. Require reviewers to enumerate lifecycle events, check whether hooks are broad or gated, inspect network calls, and compare behavior to the install description.

Use progressive disclosure for skill and plugin docs: manifest and frontmatter for discovery, lean `SKILL.md` or command body for core flow, references for detail, scripts for deterministic work, assets for output resources.

Copy the MCP decision matrix. Default cloud APIs to remote HTTP, reserve local MCPB for unavoidable local access, and explicitly document that MCPB has no sandbox.

Use command/agent workflows as orchestration recipes: exploration before implementation, multiple architecture alternatives, human checkpoints, specialized review agents, and generated artifacts that let work resume later.

Package user-configurable guardrails like `hookify`: local markdown rule files, simple frontmatter, immediate hook activation, warning versus blocking modes, and project-local storage.

## Do Not Copy

Do not treat marketplace inclusion or model-based policy scanning as a security boundary. High-risk hooks, MCP servers, and local code still need deterministic checks and manual review.

Do not ship broad `UserPromptSubmit`, `PreToolUse`, or `PostToolUse` hooks without clear disclosure, gating, and opt-out. Broad hooks observe sensitive prompt and tool data even if they never make network calls.

Do not assume MCPB manifests provide filesystem, process, or network permissions. They do not; build containment inside each tool handler.

Do not copy long skill, command, agent, or policy prompt bodies verbatim into local artifacts. The reusable value is structural: triggers, phases, gates, references, scripts, and metadata.

Do not blindly copy `allowed-tools: Bash(*)` examples. Prefer precise command patterns or explicit MCP tool names, and document why each tool is needed.

Do not make Agentic Coding Lab depend on external GitHub Actions as the only source of validation truth. Mirror critical invariants locally where possible.

## Fit For Agentic Coding Lab

Fit is in-scope and high. This repo is directly about skills, instructions, commands, agents, hooks, MCP integration, plugin packaging, marketplace discovery, and quality gates for agentic coding tools.

The most useful Agentic Coding Lab artifact would be a local plugin-packaging spec modeled on this repo: directory layout, manifest fields, component discovery, permission metadata, hook review policy, MCP source provenance, and validation scripts. A second useful artifact would be a marketplace review harness that combines deterministic checks with a structured policy review, but does not rely solely on model judgment.

The repo also suggests practical coding-agent workflows worth adapting: `feature-dev` for new feature work, `code-modernization` for inventory-to-brief-to-transform migrations, `pr-review-toolkit` for specialized review agents, `security-guidance` for stop/commit safety checks, and `hookify` for user-authored local guardrails.

## Reviewed Paths

- `/tmp/myagents-research/anthropics-claude-plugins-official/README.md`
- `/tmp/myagents-research/anthropics-claude-plugins-official/.claude-plugin/marketplace.json`
- `/tmp/myagents-research/anthropics-claude-plugins-official/.github/workflows/validate-plugins.yml`
- `/tmp/myagents-research/anthropics-claude-plugins-official/.github/workflows/validate-frontmatter.yml`
- `/tmp/myagents-research/anthropics-claude-plugins-official/.github/workflows/validate-licenses.yml`
- `/tmp/myagents-research/anthropics-claude-plugins-official/.github/workflows/check-mcp-urls.yml`
- `/tmp/myagents-research/anthropics-claude-plugins-official/.github/workflows/scan-plugins.yml`
- `/tmp/myagents-research/anthropics-claude-plugins-official/.github/workflows/bump-plugin-shas.yml`
- `/tmp/myagents-research/anthropics-claude-plugins-official/.github/workflows/revert-failed-bumps.yml`
- `/tmp/myagents-research/anthropics-claude-plugins-official/.github/workflows/close-external-prs.yml`
- `/tmp/myagents-research/anthropics-claude-plugins-official/.github/scripts/validate-frontmatter.ts`
- `/tmp/myagents-research/anthropics-claude-plugins-official/.github/scripts/discover_bumps.py`
- `/tmp/myagents-research/anthropics-claude-plugins-official/.github/policy/prompt.md`
- `/tmp/myagents-research/anthropics-claude-plugins-official/.github/policy/schema.json`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/example-plugin/README.md`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/example-plugin/.claude-plugin/plugin.json`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/example-plugin/.mcp.json`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/plugin-dev/README.md`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/plugin-dev/.claude-plugin/plugin.json`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/plugin-dev/commands/create-plugin.md`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/plugin-dev/agents/agent-creator.md`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/plugin-dev/agents/plugin-validator.md`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/plugin-dev/agents/skill-reviewer.md`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/plugin-dev/skills/plugin-structure/SKILL.md`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/plugin-dev/skills/plugin-structure/references/manifest-reference.md`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/plugin-dev/skills/plugin-structure/references/component-patterns.md`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/plugin-dev/skills/command-development/SKILL.md`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/plugin-dev/skills/command-development/references/plugin-features-reference.md`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/plugin-dev/skills/agent-development/SKILL.md`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/plugin-dev/skills/skill-development/SKILL.md`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/plugin-dev/skills/hook-development/SKILL.md`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/plugin-dev/skills/hook-development/scripts/validate-hook-schema.sh`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/plugin-dev/skills/hook-development/scripts/test-hook.sh`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/plugin-dev/skills/hook-development/scripts/hook-linter.sh`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/plugin-dev/skills/mcp-integration/SKILL.md`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/mcp-server-dev/README.md`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/mcp-server-dev/skills/build-mcp-server/SKILL.md`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/mcp-server-dev/skills/build-mcpb/SKILL.md`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/mcp-server-dev/skills/build-mcpb/references/local-security.md`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/security-guidance/README.md`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/security-guidance/.claude-plugin/plugin.json`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/security-guidance/hooks/hooks.json`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/security-guidance/hooks/security_reminder_hook.py`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/security-guidance/hooks/llm.py`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/security-guidance/hooks/sg-python.sh`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/hookify/README.md`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/hookify/.claude-plugin/plugin.json`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/hookify/hooks/hooks.json`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/hookify/core/config_loader.py`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/hookify/core/rule_engine.py`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/hookify/skills/writing-rules/SKILL.md`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/feature-dev/README.md`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/feature-dev/commands/feature-dev.md`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/feature-dev/agents/code-explorer.md`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/feature-dev/agents/code-architect.md`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/feature-dev/agents/code-reviewer.md`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/code-modernization/README.md`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/code-modernization/commands/modernize-assess.md`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/code-modernization/commands/modernize-brief.md`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/code-modernization/agents/legacy-analyst.md`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/code-modernization/agents/business-rules-extractor.md`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/code-modernization/agents/security-auditor.md`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/code-modernization/agents/test-engineer.md`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/pr-review-toolkit/README.md`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/pr-review-toolkit/commands/review-pr.md`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/pr-review-toolkit/agents/code-reviewer.md`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/pr-review-toolkit/agents/pr-test-analyzer.md`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/pr-review-toolkit/agents/silent-failure-hunter.md`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/skill-creator/README.md`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/skill-creator/skills/skill-creator/SKILL.md`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/skill-creator/skills/skill-creator/scripts/quick_validate.py`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/skill-creator/skills/skill-creator/scripts/run_eval.py`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/skill-creator/skills/skill-creator/eval-viewer/generate_review.py`
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/math-olympiad/skills/math-olympiad/evals/trigger_eval.json`
- `/tmp/myagents-research/anthropics-claude-plugins-official/external_plugins/github/.claude-plugin/plugin.json`
- `/tmp/myagents-research/anthropics-claude-plugins-official/external_plugins/github/.mcp.json`
- `/tmp/myagents-research/anthropics-claude-plugins-official/external_plugins/discord/.claude-plugin/plugin.json`
- `/tmp/myagents-research/anthropics-claude-plugins-official/external_plugins/discord/.mcp.json`
- `/tmp/myagents-research/anthropics-claude-plugins-official/external_plugins/discord/ACCESS.md`
- `/tmp/myagents-research/anthropics-claude-plugins-official/external_plugins/discord/server.ts`
- `/tmp/myagents-research/anthropics-claude-plugins-official/external_plugins/telegram/.mcp.json`
- `/tmp/myagents-research/anthropics-claude-plugins-official/external_plugins/imessage/.mcp.json`
- `/tmp/myagents-research/anthropics-claude-plugins-official/external_plugins/context7/.mcp.json`
- `/tmp/myagents-research/anthropics-claude-plugins-official/external_plugins/serena/.mcp.json`
- `/tmp/myagents-research/anthropics-claude-plugins-official/external_plugins/terraform/.mcp.json`

## Excluded Paths

- `/tmp/myagents-research/anthropics-claude-plugins-official/.git/`: VCS internals, excluded except for commit capture.
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/*/LICENSE` and top-level `LICENSE`: license presence and Apache 2.0 requirement were reviewed through workflow and sampled files; repeated license bodies were not analyzed line-by-line.
- `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/claude-md-management/*.png` and `/tmp/myagents-research/anthropics-claude-plugins-official/plugins/claude-code-setup/*.png`: screenshot/example assets, not relevant to packaging or runtime logic beyond noting asset support.
- `/tmp/myagents-research/anthropics-claude-plugins-official/external_plugins/*/bun.lock` and package lock/dependency payloads: dependency snapshots were noted but not reviewed line-by-line.
- Most external marketplace upstream repositories referenced by object sources in `.claude-plugin/marketplace.json`: their URLs, SHAs, and registry metadata were reviewed, but the upstream repos were not individually cloned for this note.
- Most long agent, command, skill, and policy bodies outside the representative files listed above: reviewed structurally and through frontmatter/search where relevant, but not reproduced verbatim or audited sentence-by-sentence.
- Language LSP plugin READMEs under `plugins/*-lsp/`: sampled as plugin catalog entries; not central to the requested focus on packaging, discovery, context loading, permissions, verification, and reusable coding-agent workflow patterns.
