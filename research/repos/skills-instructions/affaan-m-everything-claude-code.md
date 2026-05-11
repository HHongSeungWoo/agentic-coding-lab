# affaan-m/everything-claude-code

- URL: https://github.com/affaan-m/everything-claude-code
- Category: skills-instructions
- Stars snapshot: 178,943 (GitHub REST API, captured 2026-05-11); duplicate ai-coding-workflow row captured 179,094
- Reviewed commit: 6c699df1821c8da2e498ee6c6a8e288a17a1302e
- Reviewed at: 2026-05-11
- Status: reviewed
- Scope fit: in-scope
- Verdict: Very broad harness optimization collection with agents, skills, commands, rules, hooks, selective installation, context-budget guidance, continuous learning, and security material. Best as a pattern mine, not as a package to copy wholesale.

## Why It Matters

`everything-claude-code` is one of the largest public collections of AI coding-agent support artifacts. It covers prompt/rule design, specialized agents, skills, command shims, hook runtime, MCP configs, installation manifests, session memory, context budgets, and security scanning. It is directly relevant because it treats agent productivity as a system problem rather than a prompt-writing problem.

For Agentic Coding Lab, it is valuable mainly for breadth: it shows many possible surfaces where agent behavior can be improved, measured, or constrained. The risk is the same breadth can become context bloat and operational complexity if imported without pruning.

## What It Is

The repo is a cross-harness AI agent performance system. The reviewed checkout includes root governance files (`AGENTS.md`, `CLAUDE.md`, `RULES.md`, `SOUL.md`), 200+ skill files, 50+ agents, command shims, language rules, MCP configs, hook registrations, installation scripts, selective install manifests, test scripts, and a Codex plugin manifest.

The Claude marketplace metadata describes one `ecc` plugin. The Codex plugin manifest exposes `./skills/` and `.mcp.json`, with default prompts for TDD, security review, and verification. `agent.yaml` presents a portable catalog of skills and commands for gitagent-style consumers.

## Research Themes

- Token efficiency: Strong in concept. The repo includes `context-budget`, `strategic-compact`, and selective install manifests. Risk remains high because a full install exposes many agents, skills, commands, hooks, and rules.
- Context control: Strong. It includes project-scoped continuous learning, session inspection, compaction guidance, and install profiles for minimizing loaded components.
- Sub-agent / multi-agent: Strong. It has many specialized agents and multi-plan/multi-execute commands, but the exact runtime depends on the host.
- Domain-specific workflow: Very strong. It includes language packs, framework packs, business operations skills, content workflows, security skills, and AI engineering workflows.
- Error prevention: Very strong. It ships security review, verification loops, quality gates, hook guards, config protection, secret scanning concepts, and agentic security guidance.
- Self-learning / memory: Strong. `continuous-learning-v2` stores project-scoped instincts and evolves them into skills, commands, or agents.
- Popular skills: Locally important examples include `context-budget`, `continuous-learning-v2`, `tdd-workflow`, `security-review`, `verification-loop`, `eval-harness`, `iterative-retrieval`, `agent-harness-construction`, and `mcp-server-patterns`.

## Core Execution Path

There are several execution paths.

For plugin installs, a host such as Claude Code or Codex loads plugin metadata, skills, commands, hooks, and MCP configuration. The Claude plugin path uses `.claude-plugin/marketplace.json`; Codex uses `.codex-plugin/plugin.json`. For manual installs, users run `install.sh`, PowerShell install, or the `ecc` Node CLI.

The selective install path resolves profiles and modules from `manifests/install-modules.json` through `scripts/install-plan.js` and applies them through `scripts/install-apply.js`. Modules group rules, agents, commands, hooks, platform configs, framework skills, workflow-quality skills, database skills, and other packs. The CLI front door is `scripts/ecc.js`, which dispatches subcommands such as `install`, `plan`, `catalog`, `consult`, `doctor`, `repair`, `status`, and `sessions`.

Hooks are registered in `hooks/hooks.json`. They cover session start, pre-tool use, post-tool use, pre-compact, and stop-like behavior. Representative hooks include Bash preflight, config protection, MCP health check, fact-forcing before first file edits, quality gates after edits, post-edit accumulation, and continuous-learning observation.

## Architecture

The architecture is a large content-and-runtime monorepo:

- `agents/`: specialized role prompts with frontmatter.
- `skills/<name>/SKILL.md`: reusable skill instructions with ECC origin metadata.
- `commands/`: legacy slash-command files.
- `rules/`: common and language-specific always-on guidance.
- `hooks/hooks.json`: matcher-driven hook registrations.
- `scripts/`: install, catalog, doctor, repair, session, hook, orchestration, and validation scripts.
- `scripts/lib/`: shared install and hook utilities.
- `manifests/`: selective install modules and profiles.
- `.claude-plugin/` and `.codex-plugin/`: marketplace manifests.
- `mcp-configs/`: MCP configuration assets.
- `tests/` and `scripts/ci/`: validation for agents, skills, hooks, rules, manifests, workflow security, and path hygiene.
- `ecc2/`: alpha Rust control-plane prototype noted in the README, not central to the current reviewed runtime path.

## Design Choices

The repo favors a full ecosystem over a minimal framework. It supplies every layer: instructions, agents, rules, hooks, commands, install profiles, security docs, and dashboards.

Selective install is the most important design mitigation. Instead of telling users to install everything, `install-modules.json` breaks the corpus into modules with target lists, dependencies, cost, stability, and defaultInstall flags.

The hook design is assertive. PreToolUse hooks can warn, block, or capture governance events. PostToolUse hooks collect quality signals and continuous-learning observations. This turns agent behavior into a monitored runtime rather than a pure prompt session.

The memory model in `continuous-learning-v2` is project-scoped by default. It captures prompts/tool calls through hooks, extracts atomic instincts with confidence and evidence, and can promote patterns from project to global scope.

## Strengths

The repo is unusually comprehensive. It provides examples for nearly every support-system category: context budget, memory, evaluation, security, agent orchestration, MCP, installer design, and domain-specific skills.

The selective install model is useful. It acknowledges that a full skill/rule/agent catalog can hurt context quality and offers profiles and modules rather than one all-or-nothing bundle.

The context-budget skill is a concrete artifact worth adapting. It classifies agents, skills, rules, MCP tools, and CLAUDE.md chain overhead, then recommends token savings.

The continuous-learning-v2 design has a useful anti-contamination idea: project-specific instincts by default, global promotion only after cross-project evidence.

The security guide correctly treats skills, hooks, MCP, repo settings, and environment variables as supply-chain and runtime attack surfaces.

## Weaknesses

The repo is very large and uneven. It mixes core coding support, language packs, business workflows, security essays, dashboards, installers, and alpha control-plane work. Review and adoption require strong pruning.

Full installation can be counterproductive. Hundreds of skills and dozens of agents can increase trigger noise, context overhead, and user confusion.

Some claims in README-style material are broad and marketing-heavy. Actual value should be judged per skill, hook, and script rather than by aggregate counts.

The hook system increases operational risk. Hooks that inspect commands, edits, configs, MCP health, and session data are useful but become another code surface that needs testing, permissions, and user trust.

## Ideas To Steal

Create a local context-budget audit for skills, agents, MCP servers, project instructions, and always-on rules.

Use install manifests with module cost/stability/defaultInstall fields so users can choose lean profiles.

Make memory project-scoped first and require explicit promotion to global memory.

Treat hooks as observability and guardrail layers, but keep them narrow and explainable.

Add doctor/repair/list-installed commands for any durable agent-support package.

Use validation scripts to check skill metadata, agent schemas, hook config, no personal paths, and workflow security.

## Do Not Copy

Do not copy the entire catalog into Agentic Coding Lab. It would likely create context bloat and unclear ownership.

Do not import broad hooks without an explicit permission model and tests. Hook failures can block or distort agent workflows.

Do not mix business-domain skills into a general coding lab unless they answer a concrete local need.

Do not let learned instincts become global without evidence and review. Memory pollution is a real risk.

Do not accept README counts as quality signals. Review individual artifacts.

## Fit For Agentic Coding Lab

Fit is in-scope, but adoption should be selective. The repo is best used as a source of patterns for install profiles, context-budget auditing, continuous learning, hook guardrails, and security threat models.

Recommended artifact candidates are a small context-budget skill, a project-scoped memory schema, an install manifest format for local skills, and a hook validation checklist. Avoid copying the whole ECC surface.

## Reviewed Paths

- `/tmp/myagents-research/affaan-m-everything-claude-code/README.md`
- `/tmp/myagents-research/affaan-m-everything-claude-code/RULES.md`
- `/tmp/myagents-research/affaan-m-everything-claude-code/SOUL.md`
- `/tmp/myagents-research/affaan-m-everything-claude-code/agent.yaml`
- `/tmp/myagents-research/affaan-m-everything-claude-code/.claude-plugin/marketplace.json`
- `/tmp/myagents-research/affaan-m-everything-claude-code/.codex-plugin/plugin.json`
- `/tmp/myagents-research/affaan-m-everything-claude-code/manifests/install-modules.json`
- `/tmp/myagents-research/affaan-m-everything-claude-code/scripts/ecc.js`
- `/tmp/myagents-research/affaan-m-everything-claude-code/scripts/install-plan.js`
- `/tmp/myagents-research/affaan-m-everything-claude-code/hooks/hooks.json`
- `/tmp/myagents-research/affaan-m-everything-claude-code/EVALUATION.md`
- `/tmp/myagents-research/affaan-m-everything-claude-code/the-security-guide.md`
- `/tmp/myagents-research/affaan-m-everything-claude-code/skills/context-budget/SKILL.md`
- `/tmp/myagents-research/affaan-m-everything-claude-code/skills/continuous-learning-v2/SKILL.md`
- `/tmp/myagents-research/affaan-m-everything-claude-code/skills/tdd-workflow/SKILL.md`
- `/tmp/myagents-research/affaan-m-everything-claude-code/skills/security-review/SKILL.md`
- `/tmp/myagents-research/affaan-m-everything-claude-code/skills/verification-loop/SKILL.md`
- `/tmp/myagents-research/affaan-m-everything-claude-code/agents/`
- `/tmp/myagents-research/affaan-m-everything-claude-code/commands/`
- `/tmp/myagents-research/affaan-m-everything-claude-code/scripts/ci/`

## Excluded Paths

- `/tmp/myagents-research/affaan-m-everything-claude-code/.git/`: VCS internals; commit captured separately.
- `/tmp/myagents-research/affaan-m-everything-claude-code/assets/`: visual and guide images; not core behavior.
- `/tmp/myagents-research/affaan-m-everything-claude-code/docs/*/README.md` translations: skipped duplicate translated content.
- Most individual `skills/*/SKILL.md` files: catalog sampled by representative skills; reviewing 199 skills line-by-line is a separate task.
- Most individual `agents/*.md` files: directory and format reviewed; agent-by-agent behavior not reviewed in this batch.
- `ecc2/`: alpha control plane noted but not deeply reviewed because current support-system value is in skills, hooks, and install manifests.
- Generated package locks and dependency files: noted for stack shape but not reviewed line-by-line.
