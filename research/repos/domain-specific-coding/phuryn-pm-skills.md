# phuryn/pm-skills

- URL: https://github.com/phuryn/pm-skills
- Category: domain-specific-coding
- Stars snapshot: 11,447 (GitHub REST API, captured 2026-05-20)
- Reviewed commit: 020ee82501d9c09f9b989517c4cf9641bad057ff
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: conditional
- Verdict: Strong pattern mine for domain-specific product-management workflows: it packages PM artifacts, prioritization, discovery, planning, and launch review as reusable agent skills and slash commands. Fit is conditional because it improves coding-adjacent product decisions more than coding execution itself, and because file writes, web search, artifact consistency, and verification are mostly prompt conventions rather than enforced contracts.

## Why It Matters

`pm-skills` shows how a product-management domain can be decomposed into installable agent skills and end-to-end commands. Instead of asking an agent to "write a PRD" from scratch, the repo gives the agent a repeatable workflow: gather context, ask for missing inputs, apply a named PM framework, generate a structured artifact, save it, and suggest the next workflow.

For Agentic Coding Lab, the useful part is the domain-specific skill pattern. Product work often sits upstream of code: requirements, trade-offs, prioritization, assumptions, stories, test scenarios, sprint scope, launch risk, and metrics. This repo provides many concrete examples of turning that upstream work into reusable instructions that can feed coding agents with better bounded context.

## What It Is

The repository is a Claude Code and Claude Cowork plugin marketplace for product managers. The reviewed checkout contains a root marketplace manifest, 8 plugin directories, 65 skills, 36 commands, plugin READMEs, and one validator script. GitHub API metadata on 2026-05-20 reported the default branch as `main`, pushed at 2026-04-22, and licensed under MIT.

The 8 plugins cover product discovery, product strategy, execution, market research, data analytics, go-to-market, marketing/growth, and a general PM toolkit. Each plugin has `.claude-plugin/plugin.json`, a `README.md`, a `commands/` directory, and a `skills/` directory. Commands are user-invoked workflows such as `/discover`, `/write-prd`, `/triage-requests`, `/plan-okrs`, `/transform-roadmap`, `/sprint`, `/pre-mortem`, `/test-scenarios`, `/plan-launch`, and `/north-star`. Skills are reusable domain modules such as `create-prd`, `prioritization-frameworks`, `opportunity-solution-tree`, `prioritize-assumptions`, `prioritize-features`, `sprint-plan`, `pre-mortem`, and `test-scenarios`.

There is no application runtime beyond the host plugin system. The repo's local executable behavior is validation of package structure, frontmatter, command metadata, and cross-references through `validate_plugins.py`.

## Research Themes

- Token efficiency: Moderate. Skills are split by PM task and commands load only named skills in principle, which is better than one large PM prompt. The repo does not add progressive disclosure files, retrieval rules, or token budgets, and several commands duplicate artifact templates that already exist in skills.
- Context control: Strong as a folder and frontmatter pattern. Plugins create domain boundaries, commands ask for missing context instead of dumping every question, and contribution rules ban cross-plugin command references. Weaknesses are broad instructions to read files, use web search, and save to the workspace without a repository-level consent or path policy.
- Sub-agent / multi-agent: Weak. Some workflows use PM, Designer, and Engineer perspectives, but these are prompt roles inside one agent, not separately orchestrated subagents with independent context, tools, or review checkpoints.
- Domain-specific workflow: Strong. The repo covers the PM lifecycle from discovery and strategy through PRD writing, backlog decomposition, OKRs, roadmaps, sprint planning, launch planning, GTM, metrics, A/B testing, and feedback analysis.
- Error prevention: Moderate to strong in prompt design. It emphasizes assumptions, non-goals, acceptance criteria, pre-mortems, Definition of Done, test scenarios, and statistical checks. Enforcement is weak because generated artifacts are not schema-checked or round-tripped into tests.
- Self-learning / memory: Weak. Workflows create durable Markdown artifacts, meeting summaries, reports, and plans, but there is no explicit memory store, artifact registry, feedback loop, or mechanism to update skills from outcomes.
- Popular skills: No install or invocation telemetry was reviewed. Based on README prominence and workflow centrality, the highest-signal candidates are `discover`, `write-prd`, `strategy`, `plan-launch`, `north-star`, `prioritization-frameworks`, `create-prd`, `opportunity-solution-tree`, `prioritize-assumptions`, `prioritize-features`, `pre-mortem`, and `test-scenarios`.

## Core Execution Path

The actual path is prompt-driven:

1. A user installs the marketplace or copies skill folders into another agent's skill directory.
2. The host loads a plugin and exposes commands plus skills.
3. The user invokes a command, for example `/discover`, `/triage-requests`, `/write-prd`, `/sprint`, or `/plan-launch`.
4. The command gathers the smallest necessary context: product stage, user problem, known research, goals, constraints, current artifacts, or uploaded files.
5. The command applies one or more skills. `/discover` chains ideation, assumption identification, assumption prioritization, and experiment design. `/triage-requests` chains feature-request analysis and feature prioritization. `/sprint` switches between planning, retrospective, and release-notes modes.
6. The agent generates a structured artifact: discovery plan, feature triage report, PRD, OKRs, outcome roadmap, sprint plan, pre-mortem, test scenarios, metrics dashboard, launch plan, or battlecard.
7. The command usually tells the agent to save the artifact as Markdown and offer natural next steps.

The repo-level validation path is separate: `validate_plugins.py` scans plugin directories for manifests, skill frontmatter, command frontmatter, README presence, and same-plugin command-to-skill references. It passed locally at the reviewed commit with 8 plugins, 65 skills, 36 commands, and 0 warnings.

## Architecture

The architecture is a static plugin marketplace:

- `.claude-plugin/marketplace.json`: marketplace metadata and list of 8 plugin sources.
- `pm-*/.claude-plugin/plugin.json`: per-plugin metadata, author, keywords, homepage, and license.
- `pm-*/commands/*.md`: slash-command workflows with frontmatter, invocation examples, step order, artifact shape, and follow-up suggestions.
- `pm-*/skills/*/SKILL.md`: domain modules with `name` and `description` frontmatter, context notes, PM framework instructions, output templates, and further reading.
- `pm-*/README.md`: plugin-level indexes for skills and commands.
- `validate_plugins.py`: local validator for manifest fields, YAML-like frontmatter, naming consistency, README presence, and same-plugin cross references.
- `.docs/images/*`: README visual assets only.

The contribution contract is also architectural: skills are nouns, commands are verbs, every skill name must match its directory, every command needs `description` and `argument-hint`, and commands should not reference skills across plugin boundaries.

## Design Choices

The strongest design choice is the command/skill split. Commands encode a full user workflow, while skills encode reusable domain knowledge. That keeps `/discover` readable as an orchestration plan while leaving assumption prioritization, experiment design, and opportunity mapping as reusable pieces.

The repo uses artifact-first workflows. Each command has a named output with sections, tables, owners, success metrics, or decision criteria. This matters for coding agents because it turns ambiguous PM requests into structured inputs: PRDs with non-goals, stories with acceptance criteria, sprint plans with capacity and risks, and test scenarios with preconditions and expected outcomes.

Prioritization is a recurring domain primitive. The best reusable pattern is "prioritize problems before solutions." The repo uses Opportunity Score, ICE, RICE, Impact x Risk, strategic alignment, effort, and revenue or retention signals to keep agents from blindly ranking feature requests by volume.

Planning and verification are treated as a chain, not separate one-off tasks. Discovery surfaces assumptions, prioritization picks what to test, experiments define success thresholds, PRDs capture scope, pre-mortems stress-test launch risk, stories express acceptance criteria, and test scenarios convert requirements into QA-ready behavior checks.

Context boundaries are mostly conversational. Commands tell the agent to accept pasted text, files, transcripts, spreadsheets, or links, then ask for the most important missing details. This is ergonomic for users, but it is still softer than a strict artifact boundary: there is no common policy for output paths, source citation, secret handling, or when web search is allowed.

The repo favors framework literacy over tooling. Skills mention known PM frameworks and authors, but the implementation is Markdown instructions, not parsers, schemas, planners, or test harnesses.

## Strengths

The domain decomposition is coherent. The marketplace maps product work into bounded plugins and gives users a small command vocabulary for common PM jobs.

Commands are practical, not just reference text. They specify context gathering, intermediate checkpoints, artifact formats, and follow-up workflows. `/discover` is especially useful because it moves from divergent ideas to assumptions to experiments instead of stopping at brainstorming.

Artifact templates are directly reusable for coding-agent inputs. PRDs, user stories, WWA backlog items, Definition of Done, test scenarios, pre-mortems, OKRs, and outcome roadmaps all create clearer constraints for implementation work.

The prioritization guidance is better than generic PM prompting. The repo repeatedly warns against letting customer requests become solution commitments and pushes the agent toward opportunities, assumptions, impact, uncertainty, effort, and strategic fit.

The validation script is a useful minimum bar for skill marketplaces. It catches missing manifests, malformed frontmatter, name mismatches, missing command descriptions, missing argument hints, and same-plugin skill references.

The contribution rule "skills are nouns, commands are verbs" is a simple reusable heuristic. It keeps domain knowledge and workflow orchestration from collapsing into the same file.

## Weaknesses

Fit to coding is indirect. The repo is product-management specific and useful upstream of engineering, but it does not include coding rules, code generators, MCP adapters, CI hooks, or implementation verification loops.

Generated artifact contracts are not enforced. The repo can validate plugin packaging, but not whether a generated PRD, roadmap, test plan, or launch plan has complete fields, consistent terminology, or traceability back to input evidence.

Some artifact templates drift. For example, the `/write-prd` command and the `create-prd` skill both describe an 8-section PRD, but the section names and contents differ. That can create inconsistent outputs depending on whether an agent follows command text or skill text more strongly.

Workspace writes are under-specified. Many commands tell the agent to save Markdown or CSV output, but the repo does not define where files should go, whether to ask before writing, how to avoid overwriting existing artifacts, or how to handle a user who wants chat-only output.

Web search instructions are broad. Several skills tell the agent to use web search for market, competitor, benchmark, or product context. That is useful for current PM work, but the repo does not require source quality, citation format, recency checks, or restrictions around private company information.

Safety-sensitive utility skills are mixed into the same marketplace. NDA and privacy-policy drafting may be useful, but they need stronger legal-review warnings and should not be treated like ordinary PM artifact generation.

The "product trio" pattern is simulated rather than validated. Asking one model to think as PM, Designer, and Engineer can improve coverage, but it is not a substitute for real cross-functional review.

## Ideas To Steal

Use domain plugins as context boundaries. A small plugin for `requirements`, `prioritization`, `planning`, or `verification` is easier to load selectively than a giant product-development prompt.

Separate workflow commands from reusable skills. Let commands orchestrate steps and checkpoints; let skills hold domain methods and output contracts.

Build coding-facing PM artifacts as first-class inputs: PRD, non-goals, assumptions, acceptance criteria, test scenarios, Definition of Done, risk register, and metrics.

Adopt the discovery-to-verification chain: ideas -> assumptions -> prioritization -> experiments -> PRD -> stories -> tests -> pre-mortem.

Copy the contribution heuristic: skills are nouns, commands are verbs. Add linting for this shape in any local skill marketplace.

Add a validator like `validate_plugins.py`, then extend it beyond packaging: check duplicate artifact templates, required source/citation sections, output path policy, and generated artifact schemas.

Use checkpoints in long-running PM workflows. `/discover` pauses after idea generation and assumption ranking; that pattern prevents an agent from carrying bad assumptions too far.

## Do Not Copy

Do not copy broad "save to workspace" instructions without an explicit output-path and overwrite policy.

Do not copy web-search behavior without source standards, citation requirements, and privacy boundaries.

Do not let command templates and skill templates define the same artifact independently. Keep one canonical artifact schema and reference it.

Do not treat Markdown PM artifacts as verification by themselves. Pair them with tests, issue links, acceptance checks, or reviewer sign-off.

Do not use the legal and privacy-policy skills without legal-review framing and jurisdiction-specific review.

Do not equate simulated PM/Designer/Engineer perspectives with actual multi-agent or human cross-functional review.

Do not import all 65 skills into an engineering workflow. Curate only the pieces that improve coding context: requirements, prioritization, stories, tests, risks, metrics, and launch readiness.

## Fit For Agentic Coding Lab

Fit is conditional but valuable. The repository is not a coding-agent support system in the narrow sense, yet it is one of the clearer examples of packaging a non-code domain into reusable agent workflows that can improve coding outcomes.

Best adaptation for Agentic Coding Lab is a smaller set of product-to-code skills: `write-prd`, `triage-requests`, `prioritize-features`, `write-stories`, `test-scenarios`, `pre-mortem`, and `setup-metrics`. These should be rewritten with stricter context boundaries, source citation rules, output paths, and artifact schemas.

The repo also suggests a useful evaluation target: given a vague product idea, can an agent produce a PRD, stories, acceptance criteria, and test scenarios that are traceable, scoped, and implementable? `pm-skills` provides the workflow skeleton, but Agentic Coding Lab would need stronger verification around artifact completeness and downstream code quality.

## Reviewed Paths

- `/tmp/myagents-research/phuryn-pm-skills/README.md`: marketplace positioning, install path, plugin catalog, command list, and PM framework claims.
- `/tmp/myagents-research/phuryn-pm-skills/.claude-plugin/marketplace.json`: root marketplace metadata and plugin source list.
- `/tmp/myagents-research/phuryn-pm-skills/CONTRIBUTING.md`: contribution rules, noun/verb convention, frontmatter requirements, no cross-plugin command references, validator instruction.
- `/tmp/myagents-research/phuryn-pm-skills/validate_plugins.py`: packaging validator and local verification path.
- `/tmp/myagents-research/phuryn-pm-skills/pm-product-discovery/.claude-plugin/plugin.json`
- `/tmp/myagents-research/phuryn-pm-skills/pm-product-strategy/.claude-plugin/plugin.json`
- `/tmp/myagents-research/phuryn-pm-skills/pm-execution/.claude-plugin/plugin.json`
- `/tmp/myagents-research/phuryn-pm-skills/pm-go-to-market/.claude-plugin/plugin.json`
- `/tmp/myagents-research/phuryn-pm-skills/pm-product-discovery/commands/discover.md`: full discovery workflow and chained skill orchestration.
- `/tmp/myagents-research/phuryn-pm-skills/pm-product-discovery/commands/triage-requests.md`: feature-request parsing, theme clustering, prioritization, and triage report.
- `/tmp/myagents-research/phuryn-pm-skills/pm-product-discovery/commands/brainstorm.md`, `interview.md`, and `setup-metrics.md`: context gathering, interview prep/synthesis, and metrics artifact patterns reviewed through targeted search and representative reads.
- `/tmp/myagents-research/phuryn-pm-skills/pm-execution/commands/write-prd.md`: PRD workflow, context-gathering questions, non-goals, user stories, and review iteration.
- `/tmp/myagents-research/phuryn-pm-skills/pm-execution/commands/plan-okrs.md`: OKR planning and quality checks.
- `/tmp/myagents-research/phuryn-pm-skills/pm-execution/commands/transform-roadmap.md`: feature-to-outcome roadmap transformation.
- `/tmp/myagents-research/phuryn-pm-skills/pm-execution/commands/sprint.md`: sprint planning, retro, and release-note modes.
- `/tmp/myagents-research/phuryn-pm-skills/pm-execution/commands/pre-mortem.md`: risk classification and launch readiness workflow.
- `/tmp/myagents-research/phuryn-pm-skills/pm-execution/commands/test-scenarios.md`: QA scenario generation from requirements.
- `/tmp/myagents-research/phuryn-pm-skills/pm-execution/commands/write-stories.md`: user story, job story, and WWA backlog item routing reviewed through targeted search.
- `/tmp/myagents-research/phuryn-pm-skills/pm-product-discovery/skills/opportunity-solution-tree/SKILL.md`
- `/tmp/myagents-research/phuryn-pm-skills/pm-product-discovery/skills/analyze-feature-requests/SKILL.md`
- `/tmp/myagents-research/phuryn-pm-skills/pm-product-discovery/skills/prioritize-assumptions/SKILL.md`
- `/tmp/myagents-research/phuryn-pm-skills/pm-product-discovery/skills/prioritize-features/SKILL.md`
- `/tmp/myagents-research/phuryn-pm-skills/pm-execution/skills/prioritization-frameworks/SKILL.md`
- `/tmp/myagents-research/phuryn-pm-skills/pm-execution/skills/create-prd/SKILL.md`
- `/tmp/myagents-research/phuryn-pm-skills/pm-execution/skills/user-stories/SKILL.md`
- `/tmp/myagents-research/phuryn-pm-skills/pm-execution/skills/wwas/SKILL.md`
- `/tmp/myagents-research/phuryn-pm-skills/pm-execution/skills/outcome-roadmap/SKILL.md`
- `/tmp/myagents-research/phuryn-pm-skills/pm-execution/skills/sprint-plan/SKILL.md`
- `/tmp/myagents-research/phuryn-pm-skills/pm-execution/skills/pre-mortem/SKILL.md`
- `/tmp/myagents-research/phuryn-pm-skills/pm-execution/skills/test-scenarios/SKILL.md`
- Directory-level and search-based review across `pm-product-strategy`, `pm-market-research`, `pm-data-analytics`, `pm-marketing-growth`, `pm-go-to-market`, and `pm-toolkit` for context gathering, artifact saving, web search, workflow chaining, and verification patterns.

## Excluded Paths

- `/tmp/myagents-research/phuryn-pm-skills/.git/`: VCS internals; commit SHA captured separately.
- `/tmp/myagents-research/phuryn-pm-skills/.docs/images/`: README screenshots, GIFs, and diagrams; useful for marketing context but not agent workflow semantics.
- `/tmp/myagents-research/phuryn-pm-skills/LICENSE`: license noted as MIT from repo metadata, not deeply analyzed.
- Full line-by-line review of every one of the 65 skills and 36 commands: out of scope for a focused deep review; representative files and targeted searches covered the product-management workflows requested.
- External Product Compass articles, book links, Google templates, GitHub badges, and hosted install documentation: treated as further reading or provenance, not part of the cloned execution path.
- Claude Code and Claude Cowork host implementation: the repo depends on those plugin hosts, but their internals are outside this candidate review.
