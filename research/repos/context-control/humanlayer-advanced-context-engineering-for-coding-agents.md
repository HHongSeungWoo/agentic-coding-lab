# humanlayer/advanced-context-engineering-for-coding-agents

- URL: https://github.com/humanlayer/advanced-context-engineering-for-coding-agents
- Category: context-control
- Stars snapshot: 1.7k (GitHub page, captured 2026-05-29)
- Reviewed commit: 18608dedb759256d86b1c0101de82ecef8a556ab
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: in-scope
- Verdict: High-signal workflow write-up for coding-agent context control. Mine the frequent intentional compaction loop, research-plan-implement artifact boundaries, and human review placement; do not treat the repo as an operational framework because the checkout is a single essay with no local prompts, tests, schemas, hooks, or tooling.

## Why It Matters

This repo is useful because it frames coding-agent work as an explicit context-management process rather than a better-prompt problem. Its central claim is practical: large brownfield codebases can work with current coding agents when the human and agent deliberately keep context fresh, compacted, and artifact-backed.

For Agentic Coding Lab, the value is not code reuse. The value is the workflow contract: run focused research, turn research into an implementation plan, implement from that plan in phases, and put human attention on the artifacts where mistakes have the largest downstream blast radius. The repo also gives a cautionary failure case: shallow research over a dependency tree led to a poor plan, which is exactly the kind of failure a context-control system should detect earlier.

## What It Is

The repository contains one Markdown document, `ace-fca.md`, adapted from a talk about "advanced context engineering for coding agents." It is a narrative guide with diagrams, links to external prompts, links to example research and plan documents, and several case studies from HumanLayer/BAML/parquet-java work.

The core workflow is "frequent intentional compaction": instead of using one long chat until quality degrades, the operator intentionally produces compact artifacts at multiple boundaries. The article presents a three-part loop:

1. Research the codebase and task with fresh context.
2. Create a precise implementation plan with file paths, phases, and verification.
3. Implement phase by phase, compacting current state back into the plan after verified steps.

The article's linked HumanLayer command prompts and BAML example artifacts are external to this repo, but they clarify the intended shape: research documents under `thoughts/shared/research`, implementation plans under `thoughts/shared/plans`, complete-file reads before decomposition, parallel specialized subagents for discovery, and separate automated/manual verification gates.

## Research Themes

- Token efficiency: Strong conceptually. The repo argues for keeping context utilization around a mid-window band, restarting before context gets noisy, and using subagents to absorb search/read/log noise before the main agent acts. It does not ship token counters, truncation policies, or automated budget enforcement.
- Context control: Very strong as workflow guidance. The main pattern is to externalize transient context into research, plans, progress updates, commit messages, and reviewed artifacts, then start fresh from those artifacts rather than raw chat history.
- Sub-agent / multi-agent: Strong for research and summarization. Subagents are presented as context-isolation tools, not role-play. The external research command uses locator/analyzer/pattern-finder agents and requires the parent to synthesize after all subagents complete.
- Domain-specific workflow: Strong for brownfield coding. The examples target complex systems work: Rust language tooling, daemon code, race-prone systems, and large codebases where code review alone is too expensive.
- Error prevention: Medium to strong. The strongest prevention mechanism is human review of research and plans before implementation. External prompt artifacts add concrete rules for full reads, no unresolved questions in final plans, explicit non-goals, and success criteria. The repo has no local enforcement.
- Self-learning / memory: Medium. The workflow uses durable Markdown artifacts and sometimes commit messages as working memory, but there is no memory service, retrieval index, telemetry, or lifecycle policy in this repository.
- Popular skills: No packaged skills or usage telemetry. The reusable units are prompt-command patterns: `research_codebase`, `create_plan`, and `implement_plan`, plus the broader artifact convention around `thoughts/shared/research` and `thoughts/shared/plans`.

## Core Execution Path

The repo itself has no executable path. The practical execution path described by the article is a human-operated coding workflow.

First, the operator avoids naive long-session chatting. When the agent has spent tokens searching files, reading code flow, editing, running tests, and ingesting large logs, the operator compacts the state into a structured artifact. Good compaction preserves the goal, files and decisions, work already done, current failure, and next step.

Second, for real brownfield work, the operator uses research before planning. The linked research command starts by fully reading directly mentioned tickets or documents in the main context, decomposes the question, dispatches parallel locator/analyzer/pattern-finder subagents, waits for every subagent, then writes a dated research artifact with commit, branch, repository, question, summary, detailed findings, code references, historical context, related research, and open questions.

Third, planning consumes the ticket, research, and relevant files. The linked planning command requires full reads of mentioned files, parallel discovery, verification against code reality, focused human questions only when code cannot answer them, explicit design options, human approval of phase structure, a final plan with current state, desired end state, non-goals, implementation approach, phased file-level changes, automated verification, manual verification, testing strategy, performance notes, migration notes, and references.

Fourth, implementation consumes an approved plan. The linked implementation command reads the plan and all mentioned files fully, uses todos and plan checkboxes as task state, implements one phase at a time, runs success criteria, fixes failures before continuing, records progress in the plan, and pauses for human manual verification unless explicitly told to run multiple phases.

Finally, the human reviews the highest-leverage artifacts. The article explicitly values review of research and plans over line-by-line review of large AI-generated PRs, because wrong research can create many wrong implementation decisions and wrong plans can create large volumes of wrong code.

## Architecture

- Primary source layer: `ace-fca.md` is the only file in the reviewed checkout. It contains the workflow explanation, diagrams, links, claims, case studies, and external artifact pointers.
- Workflow concept layer: The article decomposes coding-agent work into research, plan, and implement phases, with optional repeated research passes and plan compaction after implementation phases.
- Artifact layer: The workflow relies on Markdown research docs, Markdown implementation plans, progress checkboxes, commit messages, and PRs as durable context. These artifacts are not templated inside this repo.
- External prompt layer: The linked HumanLayer command files define the operational prompts for research, planning, and implementation. They live in `humanlayer/humanlayer`, not in this candidate repo.
- Example evidence layer: The linked BAML artifacts show a research document and two competing plans, one produced without research and one using research. They demonstrate how research changes fix location and test strategy.
- Human review layer: The human operator is part of the architecture. Review is intentionally placed at research validity, plan correctness, phase boundaries, and manual verification rather than only at final PR code review.

## Design Choices

The most important design choice is workflow-level compaction rather than end-of-session summarization. The article recommends making compaction frequent and intentional, so each phase starts from a compact artifact instead of a long noisy transcript.

Subagents are treated as disposable context windows. Their job is to search, locate, summarize, and explain without polluting the parent context with every `Glob`, `Grep`, `Read`, build log, or JSON blob.

Research and planning are split. Research documents what the codebase actually does, while plans decide what should change. This separation makes it easier for humans to reject a bad research result before it becomes a plan.

Plans are expected to be exact and reviewable. The external plan prompt asks for concrete files, phases, non-goals, success criteria, and automated/manual verification. This turns a plan into an executable spec, not just a suggestion.

Implementation state is kept in the plan. The external implementation prompt uses checkboxes and todos as resumable task state, updates the plan after completed work, and treats existing checked work as trusted unless something looks wrong.

Worktrees are scoped to implementation. The article says research and planning can happen on main, while only implementation needs isolation in a worktree. That is a useful boundary for a lab workflow because it keeps read-only context work cheaper and implementation changes isolated.

The repo intentionally emphasizes human leverage. It argues that bad research and bad plans have larger blast radius than a bad line of code, so human review should move earlier in the pipeline.

## Strengths

- Clear mental model: context quality is the main controllable input to coding-agent quality, so workflow should optimize correctness, completeness, size, and trajectory.
- Strong phase boundaries: research, planning, implementation, and review have different context needs and artifact outputs.
- Good subagent framing: subagents are used for context isolation and focused evidence gathering, not as theatrical personas.
- Practical artifact examples: the linked BAML research and plans show how a research-backed plan can choose a better fix point and testing strategy than a plan produced without research.
- High-leverage review model: reviewing research and plans can keep teams aligned when AI-generated code volume makes full code review unrealistic.
- Explicit failure honesty: the parquet-java example shows the workflow can fail when research is too shallow or no codebase expert is present.
- Compact enough to teach: the repo is small, easy to review, and communicates a memorable workflow without requiring an installer or framework.

## Weaknesses

- The repository is only one Markdown essay. It has no local command prompts, schemas, templates, CLI, tests, hooks, MCP server, or examples checked in.
- Most operational detail is external. The research, planning, and implementation prompts are linked from another repository, and the BAML artifacts are linked from a third repository.
- There is no automation for context utilization, artifact validation, stale research detection, task-state consistency, or verification evidence.
- The evidence is anecdotal and case-study based. It is compelling process evidence, but not a reproducible benchmark or controlled evaluation.
- The workflow depends heavily on engaged expert humans. The repo is explicit about this, but it means the approach cannot be copied as a fully autonomous agent loop.
- The artifact system is not specified as a stable format. Research and plans have useful sections, but there is no local schema, linter, migration story, or ownership model.
- Some guidance is tied to Claude Code concepts and HumanLayer's `thoughts` tooling, so adaptation to Codex or another agent runtime needs translation.

## Ideas To Steal

- Make "frequent intentional compaction" a first-class workflow policy: compact before context quality degrades, not only after failure.
- Treat research documents as disposable but reviewable context artifacts. If research is wrong, throw it out and rerun with better steering before planning.
- Split research from planning from implementation. Do not let an agent jump from vague task to edits without a research-backed plan for nontrivial brownfield work.
- Use subagents as context filters that return file paths, line references, architecture links, and concise summaries.
- Require plans to include current state, desired end state, explicit non-goals, phased changes, exact files, automated verification, manual verification, testing strategy, and references.
- Place human review at research and plan boundaries, where one correction can prevent hundreds or thousands of wrong generated lines.
- Keep implementation progress in the plan artifact with checked phases, verification evidence, and manual-test status.
- Scope worktrees to implementation while allowing research and planning to run on the main checkout in read-only mode.
- Compare plan quality with and without research as an internal evaluation pattern for context-control systems.
- Use failures as input to research-depth policy: dependency-tree problems need deeper traversal and codebase expertise before implementation.

## Do Not Copy

- Do not copy the repo as if it were a framework. There is no runtime system to install or validate.
- Do not rely on long narrative guidance where Agentic Coding Lab needs enforced artifacts, schema checks, and verification gates.
- Do not assume the 40-60% context-utilization heuristic is universally optimal. Treat it as a practical starting point that needs measurement per model and workload.
- Do not overfit to HumanLayer's `thoughts` directory conventions without defining equivalent Codex-local artifact ownership and sync behavior.
- Do not let research artifacts become trusted forever. The workflow's own example shows research can be wrong and must be reviewed or refreshed.
- Do not skip final code and test review. The repo argues for earlier artifact review, not abandoning verification of actual changes.
- Do not reproduce the linked prompt bodies wholesale. Extract their structure: full reads, subagent decomposition, synthesis, plan sections, verification split, and phase pauses.

## Fit For Agentic Coding Lab

Fit is high as a workflow-pattern source and low as implementation source. This candidate should inform how Agentic Coding Lab defines context-control artifacts and review gates.

A good adaptation would be a small lab workflow with:

1. A research artifact contract for brownfield discovery.
2. A plan artifact contract that cannot contain unresolved questions.
3. A context ledger recording files read, files changed, commands run, failures, decisions, and verification evidence.
4. A rule that subagents return compact evidence and raw artifact pointers rather than large pasted transcripts.
5. A phase executor that updates plan state only after automated verification passes.
6. A manual-verification gate that distinguishes human-only checks from agent-runnable checks.

The repo should also be used as a warning: the craft is not just prompt text. Agentic Coding Lab would need validators, stale-context checks, budget policies, artifact ownership rules, and verification tooling to make the workflow repeatable across users and repositories.

## Reviewed Paths

- `ace-fca.md`: full reviewed source in the cloned candidate repository, including workflow description, context-control framing, compaction discussion, subagent section, research/plan/implement flow, BAML examples, failure cases, human-review argument, and external links.
- Git metadata for the candidate checkout: remote URL, current branch, commit history sample, tracked file list, and reviewed commit `18608dedb759256d86b1c0101de82ecef8a556ab`.
- GitHub repository page: public metadata snapshot, stars/forks/issues, file list, and commit count as of 2026-05-29.
- External linked prompt artifact `humanlayer/humanlayer/.claude/commands/research_codebase.md`: sampled for command structure, subagent decomposition, complete-file-read rule, synthesis requirements, metadata, and research document shape.
- External linked prompt artifact `humanlayer/humanlayer/.claude/commands/create_plan.md`: sampled for planning process, full context reads, interactive design options, plan template, no-open-questions rule, success criteria split, and subtask guidance.
- External linked prompt artifact `humanlayer/humanlayer/.claude/commands/implement_plan.md`: sampled for plan consumption, phase implementation, mismatch handling, plan checkbox state, automated verification, and manual verification pauses.
- External linked BAML research artifact `ai-that-works/.../2025-08-05_05-15-59_baml_test_assertions.md`: sampled for frontmatter, research question, detailed code findings, code references, architecture insights, historical context, and open questions.
- External linked BAML plan artifacts `fix-assert-syntax-validation-no-research.md` and `baml-test-assertion-validation-with-research.md`: sampled to compare plan structure and the effect of research on fix location, validation strategy, and tests.

## Excluded Paths

- Embedded images and videos in `ace-fca.md`: reviewed for role in the narrative, but not analyzed as primary technical artifacts because they are illustrative media hosted outside the repo.
- External talks, podcast episodes, LinkedIn/X posts, PR discussions, and blog posts linked by the article: not deeply reviewed because the repo note focuses on the checked-in candidate and directly linked workflow artifacts.
- The full `humanlayer/humanlayer`, `ai-that-works/ai-that-works`, `BoundaryML/baml`, and `dexhorthy/parquet-java` repositories: not cloned for this note. Only the specific linked prompt and example artifacts were sampled to understand the workflow.
- CodeLayer/private beta product claims and sales sections: noted as context, but excluded from pattern extraction because they do not expose reusable implementation details in this repository.
- Full prompt bodies from linked command files: intentionally summarized rather than reproduced to preserve focus on structure and design choices.
