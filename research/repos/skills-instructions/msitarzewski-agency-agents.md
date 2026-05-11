# msitarzewski/agency-agents

- URL: https://github.com/msitarzewski/agency-agents
- Category: skills-instructions
- Stars snapshot: 96,005 (GitHub REST API, captured 2026-05-11)
- Reviewed commit: 783f6a72bfd7f3135700ac273c619d92821b419a
- Reviewed at: 2026-05-11
- Status: reviewed
- Scope fit: in-scope
- Verdict: High-signal role-library and workflow-design reference for reusable agent personas, cross-tool conversion, multi-agent handoffs, QA loops, and evidence-first guardrails. Best lessons are structural; do not copy the verbose persona style or unchecked runtime assumptions wholesale.

## Why It Matters

`msitarzewski/agency-agents` is a large, popular public library of reusable agent roles. It matters because it treats agents as portable Markdown artifacts with frontmatter, role identity, behavioral rules, deliverable templates, workflow steps, and success metrics. The repository also includes conversion and install scripts that adapt the same source prompts for Claude Code, Copilot, Antigravity, Gemini CLI, OpenCode, Cursor, Aider, Windsurf, OpenClaw, Qwen Code, and Kimi Code.

For agentic coding research, the main value is not a new runtime. The value is the design language around specialized roles, repeatable handoffs, QA gates, and multi-agent pipeline prompts. The NEXUS strategy docs are especially relevant because they translate a prompt library into an operating model with phases, task assignment, retry limits, and evidence requirements.

## What It Is

The repo is a Markdown-first agent library plus shell tooling. At the reviewed commit, `scripts/convert.sh --tool opencode --out /tmp/...` converted 184 frontmatter-backed agent files into OpenCode subagent files. A broader `scripts/lint-agents.sh` scan reported 200 Markdown files because it also scans non-agent strategy docs.

Source agents live under domain directories such as `engineering/`, `testing/`, `specialized/`, `product/`, `project-management/`, `marketing/`, `design/`, `paid-media/`, `sales/`, `finance/`, `game-development/`, `spatial-computing/`, `support/`, and `academic/`. Most agent files use YAML frontmatter with `name`, `description`, `color`, and often `emoji`, `vibe`, or `tools`, then a body organized around identity, mission, critical rules, deliverables, workflow, communication style, learning/memory, and success metrics.

The repo also includes `strategy/` docs for NEXUS, `examples/` demonstrating multi-agent workflows, `integrations/` docs for target tools, `integrations/mcp-memory/` for a prompt-level memory pattern, `scripts/` for conversion/install/linting, and `.gitignore` rules that deliberately exclude generated integration output.

## Research Themes

- Token efficiency: Mixed. Cross-tool conversion and on-demand subagent modes help keep agents available without always loading all roles, but individual role files are long and persona-heavy. Aider and Windsurf formats concatenate all agents into one large context file, which is poor for token economy.
- Context control: Strong conceptually. Agent files define role boundaries, NEXUS handoff templates force context transfer, and MCP-memory docs propose project/agent tags for recall. Runtime context control is left to host tools and user discipline.
- Sub-agent / multi-agent: Very strong. The `specialized/agents-orchestrator.md`, NEXUS playbooks, runbooks, examples, activation prompts, and handoff templates define phase-based orchestration, parallel tracks, Dev-QA loops, and escalation after three failures.
- Domain-specific workflow: Very strong. Roles cover coding, QA, product, design, marketing, sales, support, finance, game development, spatial computing, compliance, MCP, LSP/indexing, incident response, and more. Coding-specific examples include Frontend Developer, Backend Architect, Code Reviewer, DevOps Automator, Security Engineer, Workflow Architect, MCP Builder, and LSP/Index Engineer.
- Error prevention: Strong in QA and workflow roles. Evidence Collector, Reality Checker, Code Reviewer, Workflow Architect, API Tester, Accessibility Auditor, and NEXUS phase gates all push explicit verification, visual evidence, acceptance criteria, and retry loops.
- Self-learning / memory: Conditional. Most agents include "Memory" prose, but durable memory is not implemented. The MCP memory integration is a prompt pattern requiring an external server with `remember`, `recall`, `rollback`, and `search`.
- Popular skills: The most reusable local patterns are `Agents Orchestrator`, `Evidence Collector`, `Reality Checker`, `Workflow Architect`, `MCP Builder`, `Code Reviewer`, `Codebase Onboarding Engineer`, `Minimal Change Engineer`, `LSP/Index Engineer`, and NEXUS handoff/activation templates.

## Core Execution Path

The core source path is Markdown agent files plus converter scripts:

1. A source agent file is selected from a category directory.
2. `scripts/convert.sh` extracts frontmatter fields with `get_field`, strips frontmatter with `get_body`, slugifies the name, and writes target-specific formats under `integrations/<tool>/`.
3. Tool-specific converters preserve the body but adapt metadata. Examples: OpenCode gets `mode: subagent` and normalized hex color, Cursor gets `.mdc` rule frontmatter, Qwen gets minimal SubAgent frontmatter, Kimi gets `agent.yaml` plus `system.md`, and OpenClaw splits persona sections into `SOUL.md` and operational sections into `AGENTS.md`.
4. `scripts/install.sh` copies either source Markdown or generated integration output into user or project locations. Claude Code and Copilot receive source Markdown directly; OpenCode, Cursor, Aider, Windsurf, and Qwen are project-scoped by default; Antigravity, Gemini CLI, OpenClaw, and Kimi use user config directories.
5. Host tools invoke agents by name, `@slug`, rule reference, skill activation, or an agent-file flag depending on platform.

The multi-agent workflow path is prompt-driven rather than executable code:

1. User activates `Agents Orchestrator` or a NEXUS mode.
2. Orchestrator reads a spec/task list and assigns work to domain agents.
3. Developer agent implements one task.
4. Evidence Collector, API Tester, or another QA agent validates against acceptance criteria.
5. PASS advances the pipeline; FAIL sends specific feedback back to the developer; after three attempts the task escalates for reassign/decompose/defer/accept decisions.
6. Phase gates and handoff templates preserve context between phases and agents.

There is no independent scheduler, subagent runtime, sandbox, permission layer, or automatic memory system in the repo. Those responsibilities remain in the host client and the user's orchestration process.

## Architecture

The architecture is filesystem-native:

- `README.md`: roster, quick start, use cases, design philosophy, supported tools, and integration docs.
- `CONTRIBUTING.md`: canonical agent template, semantic split between persona and operations, external service guidance, PR rules, and generated-output policy.
- `scripts/convert.sh`: conversion engine for Antigravity, Gemini CLI, OpenCode, Cursor, Aider, Windsurf, OpenClaw, Qwen, and Kimi.
- `scripts/install.sh`: installer and tool detector for home-scoped and project-scoped integrations.
- `scripts/lint-agents.sh`: frontmatter and section checker; currently scans strategy docs as if they were agents.
- `integrations/*/README.md`: target-tool install and activation instructions.
- `integrations/mcp-memory/`: external-memory prompt pattern, setup helper, and a Backend Architect example with memory instructions.
- `strategy/nexus-strategy.md`, `strategy/playbooks/`, `strategy/runbooks/`, `strategy/coordination/`: NEXUS orchestration doctrine, phase playbooks, scenario runbooks, activation prompts, and handoff templates.
- `examples/`: manual and memory-backed multi-agent workflow examples, plus a full parallel discovery case study.
- `<category>/*.md`: role definitions and domain workflows.

Generated integration files are intentionally not committed. `.gitignore` excludes `integrations/antigravity/agency-*`, `integrations/gemini-cli/skills/`, `integrations/opencode/agents/`, `integrations/cursor/rules/`, `integrations/aider/CONVENTIONS.md`, `integrations/windsurf/.windsurfrules`, `integrations/openclaw/*`, `integrations/qwen/agents/`, and `integrations/kimi/*/`.

## Design Choices

The strongest design choice is source-of-truth Markdown. One rich role definition is adapted to many host formats rather than maintaining separate prompt packs for every agent tool.

The second design choice is persona plus operations. `CONTRIBUTING.md` explicitly separates identity, communication, and rules from mission, deliverables, workflow, metrics, and advanced capabilities. The OpenClaw converter operationalizes this by routing identity-like sections to `SOUL.md` and everything else to `AGENTS.md`.

The third choice is evidence-first QA as a role pattern. Evidence Collector and Reality Checker are intentionally skeptical: they require screenshots, test output, actual command results, and realistic ratings. This is a useful counterweight to agent overclaiming.

The fourth choice is orchestration by protocol documents rather than runtime code. NEXUS provides phase definitions, assignment matrices, status reports, handoffs, QA verdict formats, retry limits, and escalation reports. This keeps the repo portable, but enforcement depends on human or host-agent compliance.

The fifth choice is broad role coverage. This improves discoverability and cross-functional planning, but it also makes quality uneven and increases token load if users install or concatenate everything.

## Strengths

The repo shows how to scale a role library without building a custom app. The source format is simple, inspectable, and adaptable to multiple host clients.

NEXUS is the highest-value artifact for workflow design. It names common multi-agent failure modes, then addresses them with context continuity, phase gates, parallel workstreams, Dev-QA loops, and structured handoffs.

The QA roles are concrete and behavior-shaping. They explicitly reject unsupported "production ready" claims and require screenshots, acceptance criteria, command output, and issue lists.

The converter scripts are pragmatic. They encode tool-specific metadata differences and make it easy to reuse the same roles across many agent clients.

The MCP memory docs describe a useful durable-context pattern: consistent project tags, receiving-agent tags, decision memories with rationale, handoff memories, and rollback after QA failures.

The contribution guide treats agent prompts as structured artifacts with template, metrics, examples, service declarations, and generated-output hygiene.

## Weaknesses

There is no runtime enforcement. Retry limits, evidence rules, memory use, and handoff discipline are prompt instructions, not hard guarantees.

Token efficiency is not a primary design constraint. Many agents are long, personality-heavy, and include large examples. Single-file integrations such as Aider and Windsurf can create very large always-present prompt surfaces.

`scripts/lint-agents.sh` currently fails on the reviewed commit: it scans `strategy/` docs as agent files and reports 16 missing-frontmatter errors plus 81 warnings across 200 Markdown files. `convert.sh` skips non-frontmatter docs, so conversion works, but lint is not aligned with conversion behavior.

Some integration docs drift from scripts. `integrations/opencode/README.md` documents `install.sh --tool opencode --path ...`, but `scripts/install.sh` does not parse `--path` at this commit.

OpenClaw splitting depends on English header keyword heuristics. Files with nonmatching headings can produce empty or weak `SOUL.md`/`AGENTS.md` segments; the linter warns about several files with no SOUL-mapped headers.

README stats are stale relative to local conversion behavior. README says 144 specialized agents and acknowledgments mention 147, while `convert.sh` converted 184 frontmatter-backed files at the reviewed commit.

## Ideas To Steal

Use one Markdown source role and deterministic converters for each host client. Keep generated target formats out of version control.

Separate persona from operations in every role. This helps both humans and converters decide what should become identity, behavior, workflow, and deliverable guidance.

Adopt evidence-first QA roles for coding workflows. A local Evidence Collector could require screenshots, test results, exact command output, and PASS/FAIL verdicts before a task advances.

Copy the NEXUS handoff pattern: metadata, current state, relevant files, dependencies, constraints, measurable deliverable request, acceptance criteria, evidence required, and next recipient.

Use three-attempt retry limits with escalation options. This prevents agents from looping forever on a failing task.

Add memory instructions as a reusable section, but make tags mandatory: project name, agent name, deliverable type, receiving agent, and decision topic.

Design agent names and descriptions for invocation behavior, not marketing. The converter relies on metadata; host tools surface these fields to users and models.

Keep a linter that validates prompt artifacts, but align scan targets with conversion targets so docs and agents are not conflated.

## Do Not Copy

Do not copy the whole roster into an always-on prompt. The library is too broad and verbose for that; use retrieval, subagent selection, or narrow bundles.

Do not treat the "Memory" prose inside agents as real memory. Without an MCP server or host memory layer, it is only instruction text.

Do not rely on prompt-only QA as a security or correctness boundary. Pair these roles with actual test runners, screenshots, typechecks, linters, and sandbox controls.

Do not copy stale or inconsistent integration instructions without testing script behavior. The Opencode `--path` doc mismatch is a concrete example.

Do not use header heuristics alone for semantic conversion if target formats require reliable persona/operations separation. Prefer explicit section metadata or stricter schema.

Do not import all non-coding roles into Agentic Coding Lab by default. Many are valuable for examples, but local focus should be coding workflows, context control, QA, tool design, memory, and orchestration.

## Fit For Agentic Coding Lab

Fit is in-scope. This repo is directly relevant to reusable agent instructions, role libraries, cross-tool packaging, multi-agent workflow design, context handoffs, memory patterns, and error-prevention roles.

Agentic Coding Lab should use it as a pattern library, not as a dependency. The strongest reusable artifacts are the role template, converter approach, NEXUS Dev-QA loop, handoff templates, evidence-first QA roles, MCP memory tagging pattern, and Workflow Architect's branch/failure/contract mindset.

A local adaptation should be narrower and more rigorous: fewer roles, shorter prompts, explicit trigger conditions, structured schemas, deterministic validators, and tests proving each role activates and improves outcomes.

## Reviewed Paths

- `/tmp/myagents-research/msitarzewski-agency-agents/README.md`
- `/tmp/myagents-research/msitarzewski-agency-agents/CONTRIBUTING.md`
- `/tmp/myagents-research/msitarzewski-agency-agents/.gitignore`
- `/tmp/myagents-research/msitarzewski-agency-agents/scripts/convert.sh`
- `/tmp/myagents-research/msitarzewski-agency-agents/scripts/install.sh`
- `/tmp/myagents-research/msitarzewski-agency-agents/scripts/lint-agents.sh`
- `/tmp/myagents-research/msitarzewski-agency-agents/integrations/README.md`
- `/tmp/myagents-research/msitarzewski-agency-agents/integrations/claude-code/README.md`
- `/tmp/myagents-research/msitarzewski-agency-agents/integrations/opencode/README.md`
- `/tmp/myagents-research/msitarzewski-agency-agents/integrations/cursor/README.md`
- `/tmp/myagents-research/msitarzewski-agency-agents/integrations/qwen/README.md`
- `/tmp/myagents-research/msitarzewski-agency-agents/integrations/kimi/README.md`
- `/tmp/myagents-research/msitarzewski-agency-agents/integrations/mcp-memory/README.md`
- `/tmp/myagents-research/msitarzewski-agency-agents/integrations/mcp-memory/setup.sh`
- `/tmp/myagents-research/msitarzewski-agency-agents/integrations/mcp-memory/backend-architect-with-memory.md`
- `/tmp/myagents-research/msitarzewski-agency-agents/examples/README.md`
- `/tmp/myagents-research/msitarzewski-agency-agents/examples/workflow-startup-mvp.md`
- `/tmp/myagents-research/msitarzewski-agency-agents/examples/workflow-with-memory.md`
- `/tmp/myagents-research/msitarzewski-agency-agents/examples/nexus-spatial-discovery.md`
- `/tmp/myagents-research/msitarzewski-agency-agents/strategy/nexus-strategy.md`
- `/tmp/myagents-research/msitarzewski-agency-agents/strategy/QUICKSTART.md`
- `/tmp/myagents-research/msitarzewski-agency-agents/strategy/playbooks/phase-3-build.md`
- `/tmp/myagents-research/msitarzewski-agency-agents/strategy/runbooks/scenario-startup-mvp.md`
- `/tmp/myagents-research/msitarzewski-agency-agents/strategy/coordination/agent-activation-prompts.md`
- `/tmp/myagents-research/msitarzewski-agency-agents/strategy/coordination/handoff-templates.md`
- `/tmp/myagents-research/msitarzewski-agency-agents/engineering/engineering-frontend-developer.md`
- `/tmp/myagents-research/msitarzewski-agency-agents/engineering/engineering-backend-architect.md`
- `/tmp/myagents-research/msitarzewski-agency-agents/engineering/engineering-code-reviewer.md`
- `/tmp/myagents-research/msitarzewski-agency-agents/engineering/engineering-codebase-onboarding-engineer.md`
- `/tmp/myagents-research/msitarzewski-agency-agents/specialized/agents-orchestrator.md`
- `/tmp/myagents-research/msitarzewski-agency-agents/specialized/specialized-workflow-architect.md`
- `/tmp/myagents-research/msitarzewski-agency-agents/specialized/specialized-mcp-builder.md`
- `/tmp/myagents-research/msitarzewski-agency-agents/specialized/lsp-index-engineer.md`
- `/tmp/myagents-research/msitarzewski-agency-agents/testing/testing-evidence-collector.md`
- `/tmp/myagents-research/msitarzewski-agency-agents/testing/testing-reality-checker.md`
- `/tmp/myagents-research/msitarzewski-agency-agents/testing/testing-api-tester.md`
- Generated sample for execution-path validation: `/tmp/agency-opencode-convert.vq7i6F/opencode/agents/code-reviewer.md`
- GitHub REST metadata: `https://api.github.com/repos/msitarzewski/agency-agents`

## Excluded Paths

- `/tmp/myagents-research/msitarzewski-agency-agents/.git/`: VCS metadata; reviewed commit captured separately.
- Generated integration output under `integrations/antigravity/agency-*`, `integrations/gemini-cli/skills/`, `integrations/gemini-cli/gemini-extension.json`, `integrations/opencode/agents/`, `integrations/cursor/rules/`, `integrations/aider/CONVENTIONS.md`, `integrations/windsurf/.windsurfrules`, `integrations/openclaw/*`, `integrations/qwen/agents/`, and `integrations/kimi/*/`: intentionally gitignored generated files; conversion logic and one generated OpenCode sample were reviewed instead.
- Most individual role files in non-coding domains such as marketing, sales, finance, game-development, hospitality, retail, and legal: sampled by listing/frontmatter/lint output but not read line-by-line because their structure repeats the same role pattern and the research focus is coding-agent support systems.
- `/tmp/myagents-research/msitarzewski-agency-agents/scripts/i18n/agent-names-zh.json`, `scripts/i18n/localize-agents-zh.ps1`, and `CONTRIBUTING_zh-CN.md`: skimmed as localization support; excluded from deep review because they do not change the core execution path for agent instructions.
- `/tmp/myagents-research/msitarzewski-agency-agents/LICENSE`, badges, sponsorship/community links, and discussion references: checked for repository context but not relevant to skills execution or workflow design.
- Binary, vendored, or UI-only assets: none found in the tracked file list beyond normal repository metadata and generated-output ignore patterns.
