# Agentic Research Pipeline Design

## Purpose

The Agentic Coding Lab needs a repeatable way to research systems that improve AI coding agents without turning the repository into a bookmark dump or a structured data warehouse. The research should find reusable patterns for working on top of tools such as Codex and opencode, not compare or adopt those tools themselves.

The output should help identify agentic coding artifacts that reduce token use, control context growth, prevent mistakes, improve workflow repeatability, support sub-agent and multi-agent work, and clarify how skills, MCP servers, and instruction files should vary across frontend, backend, and common coding workflows.

## Goals

- Collect high-signal GitHub repositories by category, using stars as a discovery heuristic.
- Keep the canonical research record in Markdown so agents and humans can read all relevant context directly.
- Review real implementation behavior by reading docs, examples, tests, and the full core execution path.
- Separate repository-level research notes from later synthesis documents that extract reusable design patterns.
- Preserve enough metadata to make each note reproducible without storing cloned source in this repository.
- Keep scope focused on support systems that improve agentic coding above existing agent tools.

## Non-Goals

- Do not build a JSON, CSV, SQLite, or database-backed catalog for the initial version.
- Do not vendor external repositories or source snapshots into this repository.
- Do not rank Codex, opencode, Claude Code, Cursor, Cline, or other agent tools as products.
- Do not review every source file in large repositories when the file is generated, vendored, UI-only, or unrelated to the agentic coding mechanism under study.
- Do not make star count the final quality metric. Stars are only a discovery mechanism.

## Repository Scope

The research includes support systems that can improve the use of an AI coding agent on top of an existing tool. In-scope examples include:

- Skill and instruction systems.
- MCP servers, clients, registries, and tool adapters when they improve agent workflows.
- Harnesses, eval loops, verification systems, and test automation for agentic coding.
- Context, prompt, memory, and workflow systems that can be adapted into agent support artifacts.
- Sub-agent and multi-agent coordination patterns.
- Sandbox, permission, and error-prevention patterns.

The research excludes agent applications and model clients when the main value is the tool itself. Codex, opencode, Claude Code, Cursor, Cline, IDE clients, and similar tools are out of scope as direct subjects.

Independent agent frameworks are conditional. A framework is not reviewed for adoption as a whole, but a note may be written when it contains a subsystem pattern that can be reused above another agent tool, such as context management, tool orchestration, permission boundaries, eval loops, or memory design.

## Discovery Categories

Discovery starts with four broad categories:

- `skills-instructions`
- `mcp`
- `harness-eval`
- `agent-support-systems`

Each category collects the GitHub Top 20 candidates by stars. Repositories that appear in more than one category should be deduplicated during triage. If many candidates do not fit these categories cleanly, the taxonomy should be refined later in synthesis rather than expanded during initial discovery.

## Research Themes

Every reviewed repository should be indexed against these themes when relevant:

- Token efficiency.
- Context control.
- Sub-agent and multi-agent coordination.
- Domain-specific workflow design.
- Error prevention.
- Self-learning and memory.
- Popular skills and reusable instruction patterns.

These themes cut across discovery categories. For example, an MCP repository may still contribute to token efficiency, and a skill repository may contain useful memory boundaries.

## Research Flow

### 1. Discovery Pass

Use GitHub search or the GitHub API to create an initial candidate list for each category. The discovery pass records repository name, URL, stars snapshot, category, and captured date in `research/index.md`.

The discovery pass should be semi-automated. Automation is useful for finding candidates and current star order, but it should not generate final architectural judgments.

### 2. Triage Pass

Triage removes duplicates and marks scope fit before deep review.

Scope fit values:

- `in-scope`: directly useful for improving agentic coding workflows above an existing tool.
- `conditional`: not useful as a whole, but likely contains reusable subsystem design.
- `out-of-scope`: mainly an agent tool, IDE client, model client, or unrelated developer utility.

Out-of-scope repositories remain visible in `research/index.md` so future searches do not repeatedly rediscover them.

### 3. Deep Review Pass

Deep review uses a temporary clone outside this repository. The research note records the reviewed commit, reviewed paths, excluded paths, reviewed date, and stars snapshot.

The reviewer reads:

- README and primary documentation.
- Examples and tests that show the expected contract.
- Entry points.
- Configuration and schema code.
- Loaders, registries, or extension points.
- Orchestration loops.
- Tool, MCP, or execution boundaries.
- Prompt, instruction, context, or memory assembly.
- Sandbox, permission, verification, and error handling code.

The reviewer excludes generated files, vendored dependencies, unrelated integrations, snapshots, and UI polish that does not affect the agentic coding mechanism being studied.

### 4. Note Pass

Each accepted or conditional candidate gets one Markdown note under `research/repos/<category>/<owner>-<repo>.md`.

The note captures what the repository does, how its core mechanism actually works, which design choices are worth copying, which choices should not be copied, and how it fits the Agentic Coding Lab.

### 5. Synthesis Pass

After enough repository notes exist, write synthesis documents under `research/synthesis/`. Synthesis documents compare patterns across notes and extract reusable guidance for future agentic coding artifacts.

Initial synthesis topics:

- `token-efficiency.md`
- `context-control.md`
- `subagents-multiagents.md`
- `domain-profiles.md`
- `ai-coding-workflow.md`
- `error-prevention.md`
- `memory.md`
- `popular-skills.md`

## File Layout

```text
research/
  index.md
  repos/
    skills-instructions/
      <owner>-<repo>.md
    mcp/
      <owner>-<repo>.md
    harness-eval/
      <owner>-<repo>.md
    agent-support-systems/
      <owner>-<repo>.md
  synthesis/
    <topic>.md
```

## Index Shape

`research/index.md` is the triage board for all discovered candidates. It should remain compact enough to scan quickly.

Suggested columns:

- Category.
- Repository.
- URL.
- Stars snapshot.
- Captured at.
- Scope fit.
- Status.
- Note path.
- Short reason.

Allowed status values:

- `candidate`
- `triaged`
- `reviewed`
- `rejected`
- `adopted`

## Repository Note Template

```md
# owner/repo

- URL:
- Category:
- Stars snapshot:
- Reviewed commit:
- Reviewed at:
- Status:
- Scope fit:
- Verdict:

## Why It Matters

## What It Is

## Research Themes

- Token efficiency:
- Context control:
- Sub-agent / multi-agent:
- Domain-specific workflow:
- Error prevention:
- Self-learning / memory:
- Popular skills:

## Core Execution Path

## Architecture

## Design Choices

## Strengths

## Weaknesses

## Ideas To Steal

## Do Not Copy

## Fit For Agentic Coding Lab

## Reviewed Paths

## Excluded Paths
```

## Review Checklist

For each repository, answer these questions in the note:

- Is it an agent tool itself, or a support system that improves agent use?
- Can the useful parts be layered above Codex, opencode, or another existing agent tool?
- If it is a framework, which subsystem pattern is worth studying independently?
- Where does execution begin?
- Where are configuration and schemas defined?
- How are skills, tools, prompts, context, or memory loaded?
- Where is the orchestration loop?
- Where are tool, MCP, sandbox, permission, and execution boundaries?
- How does it recover from failure?
- How does it prevent agent mistakes?
- How does it reduce token use or context growth?
- How does it support human override or review?
- How does it verify work?
- Which patterns should become Agentic Coding Artifacts, and which should remain research-only?

## Error Handling

Discovery should tolerate GitHub rate limits or search gaps by recording the partial state and retrying later. A candidate should not become `reviewed` unless a commit hash and reviewed paths are recorded.

If a repository is too large to review fully, the note must explain the selected core execution path and excluded areas. This is acceptable only when the excluded areas are not part of the agentic coding mechanism being studied.

If a repository has no clear docs or source path for the claimed behavior, mark it `rejected` or keep it `candidate` with a short reason instead of inferring architecture from marketing text.

## Validation

The first implementation of this research workflow should be validated by running one complete category through discovery and triage, then deep-reviewing at least one repository note. The resulting note should be readable without reopening the cloned repository and should clearly identify reusable ideas for the Agentic Coding Lab.
