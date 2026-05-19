# coleam00/context-engineering-intro

- URL: https://github.com/coleam00/context-engineering-intro
- Category: context-control
- Stars snapshot: 13,301 (GitHub REST API, captured 2026-05-12)
- Reviewed commit: a2d84b021cee1e2f4e77ba854bba0be8cb319035
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong pattern source for PRP-style context packets, path-scoped context, plan/execute workflows, handoffs, validation gates, and subagent isolation. Best reused as workflow artifacts and templates, not as source code quality examples.

## Why It Matters

This repo is a high-signal context-engineering starter for AI coding assistants. Its core claim is practical: agent failures often come from missing context, weak examples, and absent validation loops, so the repo packages feature requests, codebase research, external docs, examples, gotchas, implementation tasks, and executable checks into reusable "Product Requirements Prompt" files.

For Agentic Coding Lab, the useful value is not the branding around PRPs. It is the artifact stack: lean global rules, explicit initial requirements, generated implementation blueprints, execution commands, path-triggered rules, on-demand reference docs, handoff files, validation subagents, and parallel work isolation. The repo also contains enough rough edges to be useful as a cautionary source: tests and generated reports drift from implementation, some command examples are underspecified, and some security examples are heuristic.

## What It Is

`context-engineering-intro` is a collection of Markdown-first templates, Claude Code slash commands, sample rules, sample agents, and domain-specific use cases. The root workflow is:

1. Write `INITIAL.md` with the requested feature, examples, documentation links, and gotchas.
2. Run `/generate-prp INITIAL.md` to research the codebase and external docs, then write a context-rich PRP under `PRPs/`.
3. Run `/execute-prp PRPs/<feature>.md` to implement from the PRP with planning, todos, validation, and iteration.

The repo expands that base pattern into several use cases:

- `use-cases/ai-coding-wisc-framework`: a direct context-control framework based on Write, Isolate, Select, Compress.
- `use-cases/ai-coding-workflows-foundation`: plan/execute/validate workflow with codebase-analyst and validator agents.
- `use-cases/build-with-agent-team`: a Claude Code skill for contract-first multi-agent implementation.
- `use-cases/agent-factory-with-subagents`: a phase-based Pydantic AI agent factory using specialized subagents.
- `use-cases/pydantic-ai`: a reusable Pydantic AI template with specialized PRP commands and examples.
- `use-cases/mcp-server`: a TypeScript MCP server template with OAuth, tool registry, database tools, tests, and specialized PRP commands.
- `use-cases/template-generator`: a meta-template for generating new domain-specific context-engineering packages.
- `claude-code-full-guide`: a broader Claude Code guide covering CLAUDE files, permissions, slash commands, MCP, subagents, hooks, GitHub CLI, dev containers, and worktrees.

## Research Themes

- Token efficiency: WISC recommends lean always-loaded rules, path-scoped on-demand rules, scout subagents for large docs, focused `/prime-*` commands, handoff files, and compressed plans instead of carrying all exploration in the main conversation.
- Context control: The repo repeatedly externalizes context into `INITIAL.md`, PRPs, planning docs, `.claude/rules`, `.claude/docs`, `HANDOFF.md`, generated template guides, and validation reports. The strongest concrete design is the WISC 3-tier system: global rules, auto-loaded path rules, and reference docs loaded only by scouts.
- Sub-agent / multi-agent: The workflows use codebase analyst, validator, Pydantic AI planner, prompt engineer, tool integrator, dependency manager, and validator subagents. The agent-team skill adds contract-first role assignment, file ownership boundaries, cross-agent review, and lead-run end-to-end validation.
- Domain-specific workflow: Pydantic AI and MCP templates specialize the same PRP loop with framework docs, examples, security patterns, test models, tool registration, OAuth, deployment, and inspection checks.
- Error prevention: PRP templates require known gotchas, anti-patterns, executable validation gates, success criteria, error handling strategy, and final checklists. Hook examples show deterministic blocking/logging around dangerous commands and edit events.
- Self-learning / memory: The repo favors file-backed memory over chat memory: `HANDOFF.md`, enriched commit messages with `Context:` sections, PRP history, planning docs, agent validation reports, query history inside the sample RAG agent, and stored local message/session examples in the agent-team plan.
- Popular skills: `build-with-agent-team/SKILL.md` is the main reusable skill artifact. The repo also includes Claude Code subagent definitions and command files that can be copied as workflow prompts for tools without native slash commands.

## Core Execution Path

The root execution path is Markdown-driven. `CLAUDE.md` supplies global project rules: read planning/task files, keep files under 500 lines, use Python conventions, add pytest coverage, update docs, ask when context is missing, and verify paths before referencing them. `INITIAL.md` captures a feature request, example files, documentation links, and special considerations. `.claude/commands/generate-prp.md` reads that file, analyzes codebase patterns, researches docs, records gotchas, and writes a PRP from `PRPs/templates/prp_base.md`. `.claude/commands/execute-prp.md` loads the PRP, creates a todo plan, implements tasks, runs validation commands, fixes failures, and re-reads the PRP before completion.

The PRP template is the actual context packet. It asks for goal, why, user-visible behavior, success criteria, "All Needed Context" with URLs/files/docfiles and why each matters, current and desired trees, known gotchas, ordered implementation tasks, pseudocode, integration points, validation levels, final checklist, and anti-patterns. `PRPs/EXAMPLE_multi_agent_prp.md` shows the packet filled for a Pydantic AI research agent with an email sub-agent, including external API docs, specific example files, auth gotchas, implementation tasks, tests, and integration checks.

WISC extends the path into context budgeting. `.claude/commands/plan-feature.md` spawns parallel codebase research subagents, analyzes interfaces/tests/prior work, then writes an execution plan to `.claude/archon/plans/`. `.claude/commands/execute.md` reads the full plan first, checks git state, executes tasks in dependency order, runs incremental type/lint/test validation, and reports results. `.claude/commands/handoff.md` writes a concise `HANDOFF.md` with goal, completed work, next steps, key decisions, dead ends, changed files, current test state, and first action for the next session.

The Pydantic AI and MCP use cases clone the same shape with domain-specific commands. Pydantic AI generation requires official docs, examples, TestModel/FunctionModel testing, environment-based providers, dependency injection, and string output by default. MCP generation requires reading MCP patterns, tool registry examples, OAuth flow, database security, Cloudflare Workers config, and then validating through TypeScript, Wrangler, unit tests, OAuth, MCP Inspector-style endpoint checks, and deployment.

## Architecture

The repo architecture is mostly an artifact library rather than a runtime system.

The top layer is instruction and command artifacts: `CLAUDE.md`, `.claude/commands/*.md`, `.claude/agents/*.md`, `SKILL.md`, and use-case-specific global rules. These are intended to be loaded by coding assistants and converted into behavior.

The second layer is context packet templates: `INITIAL.md`, `PRPs/templates/prp_base.md`, Pydantic AI PRP templates, MCP PRP templates, and generated example PRPs. These define what context must be assembled before implementation.

The third layer is progressive disclosure. WISC provides `.claude/rules-example/*.md` with `paths:` frontmatter for auto-loading focused rules and `.claude/docs-example/*.md` with header metadata (`Purpose`, `When to use`, `Size`) for scout subagents to inspect before loading full reference docs.

The fourth layer is validation and orchestration. The workflow foundation has `codebase-analyst` and `validator` subagents; the Claude guide has `validation-gates`; the agent factory has five Pydantic AI subagents; the agent-team skill defines lead/worker contracts and validation ownership.

The fifth layer is runnable examples. Pydantic AI examples show `agent.py`, `tools.py`, `providers.py`, `settings.py`, CLI, and tests. The MCP use case has TypeScript source, OAuth handling, tool registration, database utilities, and Vitest tests. The RAG agent contains a PGVector schema, ingestion pipeline, semantic/hybrid search tools, settings, dependencies, prompts, CLI, and tests.

## Design Choices

The strongest design choice is treating context as an executable artifact. A PRP is not a prose spec; it includes exact files to read, URLs to research, gotchas, task order, pseudocode, validation commands, and anti-patterns. That converts vague prompting into a checklist the agent can execute and verify.

The repo also separates context by load cost. WISC keeps `CLAUDE.md` lean, moves domain-specific facts into path-scoped rule files, and moves heavy references into docs that scouts inspect by header before reading. This is directly applicable to Agentic Coding Lab: always-loaded instructions should be small, while deep domain references should be discoverable and selectively loaded.

Subagent isolation is used for research noise control and specialization. The codebase analyst extracts conventions; validator checks finished work; the Pydantic factory separates requirements, prompt design, tool planning, dependency planning, implementation, and validation. The agent-team skill goes further by defining lead-authored contracts before parallel spawn, explicit ownership, "do not touch" boundaries, and cross-review.

The repo favors validation loops over trust. PRPs ask for syntax/style, unit, integration, manual, and final checklist validation. MCP templates include TypeScript, Wrangler, local OAuth, MCP endpoint, tests, and database/permission checks. Pydantic AI templates require TestModel and FunctionModel so agent behavior can be tested without paying for real model calls.

The root templates use examples as primary guidance. `INITIAL_EXAMPLE.md` tells the agent which example files to mimic and what not to copy directly. This is a practical context-control pattern: examples become bounded pattern references rather than giant global instructions.

## Strengths

The artifact grammar is clear and repeatable. `INITIAL.md`, PRP templates, command files, and validation checklists give agents a predictable sequence from requirements to implementation.

The WISC use case is a compact, useful context-control model. Write, Isolate, Select, Compress maps cleanly to concrete commands: `/plan-feature`, `/execute`, `/handoff`, `/commit`, focused `/prime-*`, path rules, and on-demand docs.

The repo has strong examples of turning implicit conventions into explicit context. The WISC rule examples capture testing, database, adapter, workflow, CLI, server API, and isolation rules with path triggers. The docs examples include purpose and load guidance so agents can decide whether full docs belong in context.

The multi-agent skill is unusually practical. It addresses exact failure modes: endpoint mismatch, response shape drift, file conflicts, vague boundaries, missing ownership for cross-cutting concerns, and agents reporting done before validation.

The domain templates show how to specialize the same workflow without inventing a new system each time. Pydantic AI and MCP reuse the PRP loop but change docs, gotchas, folder structure, validation gates, and security checks for the domain.

The repo includes real runnable material, not just prompts. The MCP use case has TypeScript source and Vitest tests. The RAG agent has PGVector schema, ingestion code, agent dependencies, tools, and test files. The copy scripts make the templates portable.

## Weaknesses

Several artifacts drift from implementation. The RAG agent tests import `auto_search`, `search`, `SearchResponse`, `interactive_search`, and `set_search_preference`, but the reviewed `agent.py` only registers `semantic_search` and `hybrid_search`, and `tools.py` does not define `auto_search`. The validation report claims broad passing coverage for features absent from the source. For research, this makes the workflow pattern more trustworthy than the generated example quality.

Some instructions are Claude-specific and assume tools such as TodoWrite, Task subagents, Archon MCP, hooks, and Claude Code slash commands. The repo says artifacts can be used as prompts elsewhere, but portability requires adapter work.

The root `CLAUDE.md` is a generic Python template with duplicated import guidance and hard-coded preferences such as `venv_linux`, `PLANNING.md`, and `TASK.md`. It is useful as a starter, but not a polished universal context file.

The MCP security examples are partial. `validateSqlQuery` is explicitly pattern-based and still executes user SQL through `db.unsafe(sql)`. That is acceptable as a teaching scaffold with warning language, but Agentic Coding Lab should not copy it as a real SQL safety boundary.

The parallel worktree commands are underspecified. `prep-parallel.md` overloads `$ARGUMENTS` for feature name and count, and `execute-parallel.md` tells agents not to run tests while the surrounding methodology emphasizes validation. That needs tightening before reuse.

The hook examples are useful but shallow. `log-tool-usage.sh` logs only that an edit happened, not the file/tool metadata, and `hooks/README.md` still refers to `format-after-edit.sh` even though the checkout contains `log-tool-usage.sh`.

## Ideas To Steal

Adopt PRP-like context packets for Agentic Coding Lab: requirements, exact examples, docs with "why", current/desired trees, gotchas, task sequence, pseudocode, validation commands, final checklist, and anti-patterns.

Use WISC as a compact context-control doctrine. Keep always-loaded rules small, move path-specific conventions to triggered files, use scout subagents for heavy docs, write plans/handoffs to files, and compress by creating retrieval-oriented handoff artifacts.

Add headers to long reference docs: purpose, when to use, approximate size, and a short outline. Require a scout to read only headers first and load full docs only when relevant.

Make `HANDOFF.md` a standard context reset primitive. Include completed work, next steps, key decisions, dead ends, changed files, validation state, and one recommended first action.

Borrow the agent-team lead prompt structure: ownership, do-not-touch paths, produced contracts, consumed contracts, cross-cutting concerns, coordination triggers, and validation required before reporting done.

Use domain-specific PRP variants. A Pydantic AI PRP should include TestModel/FunctionModel checks and provider configuration; an MCP PRP should include tool schemas, auth, permissions, client inspection, and deployment checks.

Add enriched commit bodies for AI context changes. The WISC `/commit` command's `Context:` section is a lightweight way to make changes to rules, commands, and docs visible in git history.

Keep copy scripts gitignore-aware when packaging reusable templates. The MCP copy script's explicit integrity check is a useful pattern for template portability.

## Do Not Copy

Do not copy generated example claims without verification. The RAG validation report is inconsistent with the actual source, so Agentic Coding Lab should require source/test import checks before accepting generated reports.

Do not copy the MCP SQL validation as sufficient security. Prefer parameterized, tool-specific operations over arbitrary SQL strings, and treat pattern-based blockers only as defense-in-depth.

Do not copy hard-coded usernames, model names, environment paths, or provider assumptions. Convert them into configurable fields or project-local defaults.

Do not rely on mandatory "ultrathink" or product-specific prompt phrasing as a core mechanism. Convert the intent into explicit review steps, checklists, and verification commands.

Do not adopt parallel worktree execution without contracts and validation. If multiple agents produce variants, each must run tests or the lead must run an explicit validation matrix before selection.

Do not let global rules become a dumping ground. The repo's own WISC guidance is better than its root `CLAUDE.md`: keep global context lean and move details into scoped files.

## Fit For Agentic Coding Lab

Fit is high for context-control patterns and moderate for direct artifact reuse. The repo is in-scope because it provides concrete instruction packs, PRP templates, path-scoped context, subagent workflows, handoff/commit memory, validation gates, and domain-specific context assembly for coding agents.

Best Agentic Coding Lab artifact candidates:

- A `repo-prp.md` or `implementation-packet.md` template derived from `prp_base.md`.
- A WISC-style context hierarchy: `AGENTS.md` core, path-scoped rules, and scout-loaded references.
- A standard handoff template and a "dead ends" section for compaction/resume.
- A contract-first multi-agent prompt template with ownership and validation.
- A validation-gates subagent prompt with explicit test commands and failure iteration.
- Domain PRP variants for MCP servers, AI agents, frontend apps, and research notes.

Whole-repo adoption is not recommended. The source is a collection of examples with uneven freshness, not a cohesive tested framework. Extract the file-backed context workflows and validation grammar; verify all runnable examples independently before using them as canonical implementation references.

## Reviewed Paths

- `README.md`: root context-engineering workflow, `INITIAL.md` structure, PRP generation/execution, examples strategy, and validation framing.
- `CLAUDE.md`, `INITIAL.md`, `INITIAL_EXAMPLE.md`: global instruction template, feature request schema, and example requirements packet.
- `.claude/commands/generate-prp.md`, `.claude/commands/execute-prp.md`, `.claude/settings.local.json`: root slash command workflow and permission examples.
- `PRPs/templates/prp_base.md`, `PRPs/EXAMPLE_multi_agent_prp.md`: context packet schema, filled PRP, gotchas, task order, validation gates, and anti-patterns.
- `use-cases/ai-coding-wisc-framework/README.md`: WISC strategy, 3-tier context system, prime/plan/execute/handoff/commit commands.
- `use-cases/ai-coding-wisc-framework/.claude/commands/plan-feature.md`, `execute.md`, `handoff.md`, `commit.md`, `prime*.md`: concrete context-control and session-continuity commands.
- `use-cases/ai-coding-wisc-framework/.claude/rules-example/testing.md`, `database.md`: path-triggered rule examples with detailed conventions and anti-patterns.
- `use-cases/ai-coding-wisc-framework/.claude/docs-example/architecture-deep-dive.md`, `workflow-yaml-reference.md`: on-demand reference docs with scout-friendly headers and deep implementation traces.
- `use-cases/ai-coding-workflows-foundation/README.md`, `commands/create-plan.md`, `commands/execute-plan.md`, `commands/primer.md`, `agents/codebase-analyst.md`, `agents/validator.md`: planning, Archon tracking, codebase analysis, and validation workflow.
- `use-cases/build-with-agent-team/README.md`, `SKILL.md`, `example-plan/session-manager-plan.md`: multi-agent team workflow, lead-authored contracts, ownership boundaries, cross-review, and validation.
- `use-cases/agent-factory-with-subagents/README.md`, `CLAUDE.md`, `.claude/agents/*.md`, `SAMPLE_PROMPT.md`: phase-based Pydantic AI agent factory, subagent roles, Archon/TodoWrite integration, and quality gates.
- `use-cases/agent-factory-with-subagents/agents/rag_agent/*`: RAG example README, planning docs, `agent.py`, `tools.py`, `dependencies.py`, `settings.py`, `providers.py`, `prompts.py`, ingestion pipeline, PGVector schema, tests, and validation report.
- `use-cases/pydantic-ai/README.md`, `CLAUDE.md`, `.claude/commands/*.md`, `PRPs/templates/prp_pydantic_ai_base.md`, `examples/**`, `copy_template.py`: Pydantic AI domain PRP workflow, provider patterns, testing strategy, and template copy mechanics.
- `use-cases/mcp-server/README.md`, `CLAUDE.md`, `.claude/commands/*.md`, `PRPs/templates/prp_mcp_base.md`, `PRPs/ai_docs/mcp_patterns.md`, `src/**`, `examples/database-tools.ts`, `tests/unit/**`, `copy_template.py`: MCP domain PRP workflow, OAuth, Cloudflare Workers, tool registry, SQL/database safety examples, and tests.
- `use-cases/template-generator/README.md`, `CLAUDE.md`, `.claude/commands/*.md`, `PRPs/templates/prp_template_base.md`, `PRPs/template-pydantic-ai.md`: meta-template generation workflow and research-driven specialization.
- `claude-code-full-guide/README.md`, `.claude/commands/prep-parallel.md`, `execute-parallel.md`, `fix-github-issue.md`, `.claude/agents/*.md`, `.claude/hooks/*`, `.devcontainer/*`: broader Claude Code context setup, hooks, subagents, worktrees, GitHub issue workflow, and safe-container guidance.

## Excluded Paths

- `.git/**`: local clone metadata, not part of the reviewed design.
- `LICENSE`, `.gitattributes`, `.gitignore`: repository metadata; checked only for license/ignore context, not reviewed as design artifacts.
- `package-lock.json`: generated dependency lockfile for the MCP use case; not useful for context-control design beyond confirming npm usage.
- `worker-configuration.d.ts`: generated Cloudflare Workers type output; source templates and `wrangler.jsonc` were more relevant.
- `use-cases/ai-coding-wisc-framework/*.png`, `use-cases/build-with-agent-team/*.png`: binary diagrams; the README and skill text contained the actionable workflow details.
- `use-cases/agent-factory-with-subagents/**/documents/doc*.md` and duplicated sample RAG corpus files: synthetic/sample knowledge-base content. I reviewed the RAG schema, ingestion, tools, planning docs, and README instead of every raw corpus document.
- `claude-code-full-guide/.devcontainer/Dockerfile`, `devcontainer.json`, `init-firewall.sh`: environment containment examples, relevant only tangentially to context control; reviewed at a high level through the guide.
- `install_claude_code_windows.md`: platform install instructions, not a context-control artifact.
- Most duplicate files under `claude-code-full-guide/PRPs/**` and root `PRPs/**`: reviewed root versions once and compared purpose, avoiding duplicate reading.
- UI-only or branding surfaces beyond noted diagrams: no application UI implementation is central to the context-control patterns in this repo.
