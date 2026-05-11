# obra/superpowers

- URL: https://github.com/obra/superpowers
- Category: skills-instructions
- Stars snapshot: 185,997 (GitHub REST API, captured 2026-05-11)
- Reviewed commit: f2cbfbefebbfef77321e4c9abc9e949826bea9d7
- Reviewed at: 2026-05-11
- Status: reviewed
- Scope fit: in-scope
- Verdict: High-signal reference for an opinionated coding-agent methodology shipped as portable skills, bootstrap hooks, and plugin metadata. Best reusable pieces are trigger discipline, mandatory verification workflows, subagent review gates, and cross-harness packaging; weakest area is that runtime enforcement depends on host hook/skill support.

## Why It Matters

`obra/superpowers` is a complete methodology layer for coding agents rather than a single prompt pack. It externalizes engineering process into composable skills for brainstorming, worktree setup, plan writing, subagent execution, TDD, code review, debugging, verification, and finishing branches. The repository is especially relevant because it targets several harnesses, including Claude Code, Codex, Gemini CLI, OpenCode, Cursor, and GitHub Copilot CLI.

For Agentic Coding Lab, the value is direct: this repo shows how a reusable instruction system can force better agent behavior above the base client. It does not try to replace the agent. It injects bootstrapping instructions and makes the agent consult skill files before acting.

## What It Is

The repository is a zero-dependency skills library plus harness adapters. Root files include `README.md`, `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, Codex plugin metadata under `.codex-plugin/plugin.json`, Gemini extension metadata, OpenCode plugin files, session-start hooks, and the `skills/` directory.

The current Codex plugin manifest exposes the whole `skills/` directory and describes the package as planning, TDD, debugging, and delivery workflows for coding agents. The `hooks/session-start` script injects the full `using-superpowers` skill as session context for supported platforms, so the agent is pushed to invoke relevant skills before answering or editing.

## Research Themes

- Token efficiency: Moderate. The repo relies on skill progressive disclosure, but `using-superpowers` is intentionally injected whole at session start. That trades context cost for behavior reliability.
- Context control: Strong. Skills contain compact trigger metadata and deeper linked references such as reviewer prompts, testing anti-patterns, debugging references, and visual brainstorming guidance.
- Sub-agent / multi-agent: Very strong. `subagent-driven-development` defines a controller/implementer/reviewer loop with fresh subagents, spec review, and code quality review.
- Domain-specific workflow: Moderate. Core skills are general coding workflow skills rather than framework-specific packs.
- Error prevention: Very strong. TDD, systematic debugging, receiving review feedback, requesting review, and verification-before-completion all target common AI coding failures.
- Self-learning / memory: Conditional. The repo includes docs about skill improvements from feedback, but no durable memory engine.
- Popular skills: The central skills for coding-agent reliability are `using-superpowers`, `brainstorming`, `writing-plans`, `subagent-driven-development`, `test-driven-development`, `systematic-debugging`, and `verification-before-completion`.

## Core Execution Path

For supported harnesses, installation puts skill files and platform metadata where the host can discover them. At session start, `hooks/session-start` resolves the plugin root, reads `skills/using-superpowers/SKILL.md`, escapes it into JSON, and returns additional context in the shape expected by Cursor, Claude Code, Copilot CLI, or a generic SDK consumer.

The runtime path is then instruction-driven:

1. `using-superpowers` tells the agent to check skills before any response or action.
2. User asks for coding work.
3. The agent invokes `brainstorming` before creative feature work, then later `writing-plans`.
4. Implementation can use `subagent-driven-development` or `executing-plans`.
5. Code changes are gated by `test-driven-development`, review skills, and `verification-before-completion`.
6. `finishing-a-development-branch` handles merge/PR/cleanup decisions.

There is no independent orchestrator process. The host agent interprets skill instructions and, when available, invokes local subagents and tools.

## Architecture

The architecture is filesystem-native:

- `skills/<name>/SKILL.md`: each skill's trigger metadata and procedure.
- `skills/*/*.md`: supporting prompt templates and reference material for reviewers, testing, debugging, and skill authoring.
- `hooks/session-start`: bootstrap script for loading `using-superpowers`.
- `.codex-plugin/plugin.json`: Codex plugin manifest with display metadata, capabilities, default prompts, icon paths, and skill root.
- `.opencode/`: OpenCode installer and plugin file.
- `scripts/sync-to-codex-plugin.sh`: deterministic sync script for publishing the Codex plugin shape into an OpenAI-owned plugin marketplace repo.
- `docs/`: design notes for OpenCode support, testing, visual brainstorming, and improvements from feedback.

The repo intentionally keeps runtime dependencies low. Most behavior lives in text instructions and small shell scripts rather than a framework.

## Design Choices

The largest design choice is "process as skill." Each workflow step is a separately activatable skill with strong trigger language and red-flag sections. The skills do not merely advise; many use absolute language to counter common model shortcuts.

The second choice is session bootstrap. Instead of hoping the host discovers skills naturally, the startup hook injects `using-superpowers` and tells the agent how to use the skill system. This improves activation reliability but increases initial context.

The third choice is staged rigor. Brainstorming requires user-approved design before implementation. TDD requires an observed red state before production edits. Subagent development requires spec review before code-quality review. Verification requires evidence before completion claims.

Packaging is cross-harness but conservative. The Codex sync script excludes root ceremony, docs, hooks, scripts, and platform-specific metadata that do not belong in the canonical Codex plugin payload.

## Strengths

The repo directly addresses common AI coding failure modes: jumping to code too early, weak requirements, tests after implementation, unverified fixes, ignored review feedback, and context-poisoned long sessions.

The skills are concrete enough to be executable by an agent. For example, `subagent-driven-development` defines exact status handling for `DONE`, `DONE_WITH_CONCERNS`, `NEEDS_CONTEXT`, and `BLOCKED`, and requires two separate review passes.

The bootstrap hook is pragmatic. It encodes platform output differences and legacy migration warnings in one place, which is better than relying on each agent session to remember installation details.

The repository also models a useful contribution discipline. `AGENTS.md` treats skill text as behavior-shaping code and demands real evidence before skill changes.

## Weaknesses

The repo cannot enforce its process without host cooperation. If a harness ignores hooks, lacks skill invocation, or lacks subagents, the methodology degrades into plain instructions.

The startup injection is intentionally forceful and can be expensive in context. A lighter loader with stable tool-level skill discovery would be more token efficient.

Some rules are globally prescriptive. They are helpful for quality, but teams with different workflows may need adapters rather than direct adoption.

There is no built-in benchmark suite proving each skill improves outcomes across tasks. The repository references evaluation principles, but the core package does not ship a top-level reproducible eval harness for the whole methodology.

## Ideas To Steal

Use a bootstrap skill that explains how to use all other skills and when to invoke them.

Treat skill descriptions as trigger contracts. The trigger wording should include "when to use" and avoid vague marketing copy.

Represent engineering workflows as staged skills with hard gates: clarify, design, plan, red test, green code, review, verify, finish.

Use subagents with narrow roles and fresh context. Put spec compliance before code quality so reviewers do not bless polished but wrong implementations.

Make verification a separate skill that runs before any completion claim.

Preserve platform-specific packaging, but keep shared skills under one common directory.

## Do Not Copy

Do not copy the mandatory language blindly into all local workflows. It is effective behavior shaping, but it can conflict with user preferences or simpler maintenance tasks.

Do not assume subagent-driven development is always beneficial. Small fixes or tightly coupled debugging can be slower with reviewer loops.

Do not rely on skill text as a security boundary. It improves agent behavior but does not enforce filesystem, network, or credential limits.

Do not import the session-start bootstrap wholesale unless the target harness supports safe context injection and predictable hook semantics.

## Fit For Agentic Coding Lab

Fit is in-scope and strong. This is one of the clearest examples of an agent-support layer that improves coding behavior above an existing client.

Agentic Coding Lab should use it as a reference for skill lifecycle design, workflow decomposition, review gates, and bootstrap reliability. The best local adaptation would be smaller topic-specific skills with explicit evidence requirements and a lightweight eval loop that measures whether each skill triggers and improves outcomes.

## Reviewed Paths

- `/tmp/myagents-research/obra-superpowers/README.md`
- `/tmp/myagents-research/obra-superpowers/AGENTS.md`
- `/tmp/myagents-research/obra-superpowers/package.json`
- `/tmp/myagents-research/obra-superpowers/.codex-plugin/plugin.json`
- `/tmp/myagents-research/obra-superpowers/gemini-extension.json`
- `/tmp/myagents-research/obra-superpowers/hooks/session-start`
- `/tmp/myagents-research/obra-superpowers/scripts/sync-to-codex-plugin.sh`
- `/tmp/myagents-research/obra-superpowers/.opencode/`
- `/tmp/myagents-research/obra-superpowers/.github/PULL_REQUEST_TEMPLATE.md`
- `/tmp/myagents-research/obra-superpowers/skills/using-superpowers/SKILL.md`
- `/tmp/myagents-research/obra-superpowers/skills/brainstorming/SKILL.md`
- `/tmp/myagents-research/obra-superpowers/skills/subagent-driven-development/SKILL.md`
- `/tmp/myagents-research/obra-superpowers/skills/test-driven-development/SKILL.md`
- `/tmp/myagents-research/obra-superpowers/skills/systematic-debugging/`
- `/tmp/myagents-research/obra-superpowers/skills/verification-before-completion/SKILL.md`
- `/tmp/myagents-research/obra-superpowers/skills/writing-skills/`

## Excluded Paths

- `/tmp/myagents-research/obra-superpowers/.git/`: VCS internals; commit captured separately.
- `/tmp/myagents-research/obra-superpowers/assets/`: icons and images; relevant for packaging only.
- `/tmp/myagents-research/obra-superpowers/docs/plans/`: skimmed by directory listing; not central to current execution path except as design provenance.
- Repetitive shell helper scripts under `/tmp/myagents-research/obra-superpowers/scripts/`: reviewed representative Codex sync script, not every release helper.
- Remaining skill reference files not named above: directory reviewed, but not all examples line-by-line because the main research target is the method and runtime path.
