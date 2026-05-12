# Austin1serb/agents-md

- URL: https://github.com/Austin1serb/agents-md
- Category: token-efficiency
- Stars snapshot: 83 (GitHub REST API, captured 2026-05-12)
- Reviewed commit: d8d55982710bc4032442329c61a7bfb42da8550f
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: in-scope
- Verdict: Useful lightweight AGENTS.md pattern pack for command-output control and context discipline. Strong as a compact instruction source; weak as a security or enforcement system because it relies entirely on model compliance and has little explicit prompt-injection handling despite the README claim.

## Why It Matters

This repo targets one of the highest-leverage token-efficiency problems in coding-agent work: agents often print too much command output, full files, broad search results, logs, diffs, and validation output into context. The central idea is simple and practical: line caps are not enough, because one long line can still flood context; unknown or large output should be scoped first and byte-capped.

For Agentic Coding Lab, the repo matters because it is a small, copyable AGENTS.md instruction set rather than a full product. It gives a clean baseline for project-level rules that push agents toward narrower searches, scoped validation, direct edits, and concise communication. It also exposes the limits of pure prompt controls: there is no hook, wrapper, MCP tool, or runtime gate enforcing caps.

## What It Is

agents-md is a five-file Markdown repository. `AGENTS.md` is the main artifact: a project-level coding-agent instruction file focused on operating principles, context discipline, command-output byte caps, narrow code changes, validation proportional to risk, subagent restraint, and low-verbosity communication.

`README.md` explains the intended audience and highlights byte-capped command output as the biggest current win, with a claimed roughly 50% average token-usage reduction in the author's own Codex workflows. `codex-optimized-prompt.md` is a broader Codex system-prompt example that removes the frontend-heavy base prompt and adds a byte-output rule. `change-codex-system-prompt.md` explains how to install that prompt through `model_instructions_file` and how it differs from AGENTS.md. `codex-GPT-5.5-system-prompt.md` is a baseline prompt included for comparison.

## Research Themes

- Token efficiency: Strongest theme. The repo makes byte-capped output the main rule, discourages full-file/log/diff dumps, prefers targeted `rg`, and asks for low-verbosity summaries. README claims about 50% token reduction from the AGENTS.md rule in comparable Codex tasks, but does not provide benchmark data.
- Context control: Strong instruction-level controls: inspect narrow scope first, read only relevant sections after finding them, avoid broad searches and generated output, and escalate cap size only after narrowing. No runtime context budget or automatic truncation exists.
- Sub-agent / multi-agent: Limited but useful. Subagents are recommended only when they save context/time or improve quality. Research/review subagent prompts should avoid leading conclusions and require evidence, tradeoffs, uncertainty, alternatives, inspected files, changed files, validation, and risks.
- Domain-specific workflow: Coding-agent focused. It favors small maintainable code changes, existing patterns, direct patch edits, cheap scoped validation, and command-output hygiene. It is not domain-specific beyond general software engineering.
- Error prevention: Moderate. It reduces errors caused by context flooding, broad refactors, over-validation, and single-use abstractions. It does not provide test harnesses, sandbox policy, permission checks, or automated rollback protection.
- Self-learning / memory: Minimal. There is no memory system or durable learning loop. The only continuity-related content is in the Codex prompt examples, which say to continue naturally after context compaction.
- Popular skills: No formal skills or skill registry. The reusable artifact is the AGENTS.md instruction block itself, plus the Codex system-prompt example.

## Core Execution Path

There is no executable code. The intended execution path is:

1. Copy `AGENTS.md` into a repository root or into a Codex-level instruction directory.
2. Let the coding agent ingest it as project guidance.
3. During work, the agent first narrows scope with targeted file listings and searches.
4. When output may be large, the agent uses byte caps such as `head -c` or `tail -c`, not line-only caps.
5. The agent reads full instruction, skill, tool-doc, or policy files when relevant, but avoids dumping generated, binary, minified, database, huge JSON/JSONL, full logs, broad diffs, and unbounded command output.
6. For edits, the agent makes the smallest maintainable change, avoids unrelated cleanup, and validates only as much as the change risk justifies.
7. For final communication, the agent summarizes changed files, validation, and residual risk briefly.

The optional Codex path is to set `model_instructions_file = "path/to/codex-optimized-prompt.md"` in `.codex/config.toml`. The repo positions this as a higher-level system-prompt layer, while AGENTS.md remains project/developer guidance.

## Architecture

The architecture is instruction-only:

- `README.md`: public explanation, resource map, usage instructions, and the token-efficiency thesis.
- `AGENTS.md`: main reusable rule set for project-level agent behavior.
- `codex-optimized-prompt.md`: example replacement Codex instruction file, adding a hard "limit command output by bytes" rule and removing unrelated frontend guidance from the baseline.
- `change-codex-system-prompt.md`: setup guide for `model_instructions_file`, including profile-scoped prompts and subagent prompt files.
- `codex-GPT-5.5-system-prompt.md`: baseline prompt used as comparison material.

There are no scripts, tests, schemas, packages, hooks, MCP servers, or CI workflows. Enforcement is entirely through agent instruction following.

## Design Choices

The strongest design choice is byte limits over line limits. `AGENTS.md` explicitly warns that `head -n`, `tail -n`, and `sed -n` are insufficient when a single line is huge. This is a precise operational rule that agents can apply immediately.

The second strong choice is "scope before printing content." The instruction set tells agents to list files, search specific paths, count matches when useful, and avoid expensive outputs before reading raw content. This turns context control into a sequence of small search and inspection moves.

Validation is deliberately proportional. The file tells agents to skip validation for low-risk edits and say so plainly, use the cheapest useful check for risky changes, and avoid full builds/tests/lint unless justified or requested. That is token-efficient and time-efficient, but it depends on good agent judgment.

The code-change guidance is conservative: direct patches, narrow failing path first, no unrelated cleanup, no speculative abstractions, and no single-use wrappers. This pairs well with context discipline because it reduces the amount of code the agent must inspect and explain.

The repo also separates high-level Codex behavior from AGENTS.md behavior. `change-codex-system-prompt.md` treats `model_instructions_file` as a stronger instruction layer than AGENTS.md, and recommends AGENTS.md for project-specific or agent-specific guidance.

## Strengths

The rule set is compact and easy to adopt. A team can paste `AGENTS.md` into a repo and immediately get better behavior from agents that respect project instructions.

Byte-capped command output is specific, teachable, and measurable. It improves on the common but unsafe "use `head -n 20`" habit.

The instructions target real coding-agent failure modes: broad repo scans, full logs, huge diffs, generated files, unbounded `cat`, broad `rg`, `find`, `ls -R`, full test suites, and unnecessary abstractions.

It preserves important exceptions. Instruction files, skill files, tool docs, and policy files should be read fully unless unexpectedly huge; this avoids token thrift breaking correctness.

The subagent section is small but mature. It tells the main agent to keep ownership of final judgment and require evidence, uncertainty, tradeoffs, and inspected files from subagents.

## Weaknesses

There is no enforcement. If an agent ignores the file, no wrapper, hook, shell proxy, MCP tool, or CI check prevents unbounded output or broad validation.

The README advertises prompt-injection resistance, but the reviewed `AGENTS.md` has no direct rules for untrusted instructions, web content, malicious repo files, secret handling, or tool-output injection. Security value is mostly indirect through context discipline.

The token-savings claim is anecdotal. The repo says the byte-cap rule reduced average token usage by roughly 50% in the author's workflows, but there are no fixtures, logs, comparison methodology, or reproducible benchmark scripts.

Some command examples preserve exit codes with a temp file and `tail -c`, but the main simple examples use pipes that can hide original command status unless wrapped carefully. This is acknowledged later, but agents may copy the simpler pattern first.

The `codex-optimized-prompt.md` contains broad personality and communication text unrelated to token efficiency. As an optimization artifact, it is less focused than `AGENTS.md`.

The repo is very young and small: no releases, no license field in GitHub metadata, no tests, no examples beyond the Markdown files, and no compatibility matrix for different agent clients' AGENTS.md handling.

## Ideas To Steal

Adopt byte caps as a default AGENTS.md rule for unknown or potentially large output. Phrase it as "byte cap first, increase only after narrowing."

Keep the exception for instruction/policy files. Token efficiency should not cause agents to skim the files that define their rules.

Add a "scope before printing" checklist to local research and coding workflows: file list, targeted search, match counts, focused sections, nearby call sites, then capped logs or tests.

Pair token controls with small-change rules. Direct patches, no unrelated cleanup, and no single-use abstractions reduce both review surface and context load.

Use risk-matched validation language. Require the agent to state when validation is skipped and why, rather than running full suites reflexively.

For subagents, require evidence packets: findings, inspected files, changed files, validation run, risks, uncertainty, and better alternatives.

Use a stronger shell wrapper or harness for enforcement in our own system. This repo gives the prompt language; Agentic Coding Lab should add measurement and policy gates around it.

## Do Not Copy

Do not copy the README's prompt-injection-resistance claim without adding actual untrusted-input rules and enforcement.

Do not rely on prompt-only byte caps for critical workflows. Add shell wrappers, command helpers, or review checks where token budgets matter.

Do not use plain piped byte caps when command exit status is important unless the command is wrapped to preserve status.

Do not adopt the full `codex-optimized-prompt.md` as-is. It includes broad personality and platform behavior beyond the token-efficiency goal; extract the command-output and context-discipline rules instead.

Do not treat anecdotal 50% savings as evidence for our benchmark claims. Reproduce with captured before/after task traces if we cite numbers.

## Fit For Agentic Coding Lab

Fit is high as an instruction pattern source and low as an implementation reference. The repo is exactly in scope for token-efficiency research because it distills command-output and context-window rules into a portable AGENTS.md file.

Best use is to extract a compact "command output budget" section for our own AGENTS.md or skills, then back it with an `rtk`-style wrapper, test harness, or review checklist. The most valuable local adaptation would combine this repo's prompt rules with measured bytes returned per command and explicit exceptions for instruction/policy files.

It should not become a dependency. There is no code to reuse, and the repo's value is the written policy language plus its clear emphasis on byte caps.

## Reviewed Paths

- `README.md`: repo purpose, resource map, byte-capped command-output thesis, usage instructions, Codex config example, and token-savings claim.
- `AGENTS.md`: main coding-agent instruction set, including operating principles, context discipline, command-output controls, code-change rules, validation, subagents, and communication.
- `codex-optimized-prompt.md`: supporting Codex prompt example, reviewed for token-control additions and relationship to baseline system prompt.
- `change-codex-system-prompt.md`: Codex installation and instruction-layer explanation for `model_instructions_file`, AGENTS.md, and subagent prompts.
- `codex-GPT-5.5-system-prompt.md`: baseline prompt included by the repo, reviewed only to understand what the optimized prompt changes and omits.
- Git metadata: current commit, history, tracked file list, and GitHub REST API metadata for stars, forks, update time, and license status.

## Excluded Paths

- `.git/`: clone metadata only. Used through Git commands for commit/history, not reviewed as content.
- Generated paths: none present in the tracked checkout.
- Vendored dependencies: none present in the tracked checkout.
- Binary assets: none present in the tracked checkout.
- UI-only paths: none present in the tracked checkout.
- Unrelated paths: none present beyond Git metadata. All five tracked files are small Markdown artifacts directly relevant to AGENTS.md rules, Codex prompt configuration, or baseline comparison.
