# NeoLabHQ/context-engineering-kit

- URL: https://github.com/NeoLabHQ/context-engineering-kit
- Category: context-control
- Stars snapshot: 1,052 (GitHub REST API, captured 2026-05-29)
- Reviewed commit: dedca19ced62758f68a8a34cd2329ec065ecce6a
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: in-scope
- Verdict: High-signal prompt and plugin marketplace for context-controlled coding workflows. Mine the staged `.specs` lifecycle, meta-judge to judge verification, path-scoped rules, review scoring, Reflexion hook, MCP setup patterns, and file-backed memory. Do not copy the kit whole: it is Claude Code centric, manifests under-specify installed assets, many "commands" are actually `SKILL.md` files, several prompts use brittle hostile wording, and the repo does not provide repo-wide validators or benchmark evidence for its strongest reliability claims.

## Why It Matters

This repo is useful because it packages context-control patterns as installable agent artifacts rather than only as essays. It covers a large part of the AI coding loop: task intake, research, planning, implementation, review, testing, git operations, MCP setup, memory updates, rules, and decision records.

For Agentic Coding Lab, the strongest value is the execution grammar. The kit externalizes agent work into `.specs` task files, `.specs/scratchpad` notes, `.specs/analysis` files, `.fpf` knowledge layers, `CLAUDE.md` memories, path-triggered rules, and structured judge reports. Those artifacts create resumable context boundaries and let the orchestrator keep noisy search, implementation, and review context inside specialized subagents.

The repo is also a cautionary source. Its best patterns are concrete, but the implementation is mostly Markdown prompts with one small hook package. Quality depends on the host agent obeying instructions, on Claude Code plugin conventions, and on the operator accepting high token cost for multi-agent verification.

## What It Is

`context-engineering-kit` is a Claude Code plugin marketplace containing 13 plugin directories: `reflexion`, `review`, `git`, `tdd`, `sadd`, `ddd`, `sdd`, `kaizen`, `customaize-agent`, `docs`, `tech-stack`, `mcp`, and `fpf`. The root `.claude-plugin/marketplace.json` points each marketplace entry at `./plugins/<name>`. Each plugin has a minimal `.claude-plugin/plugin.json` with name, version, description, and author, while actual assets are discovered from conventional folders such as `skills/`, `agents/`, `rules/`, `hooks/`, `scripts/`, and `tasks/`.

Most of the repo is Markdown instruction text. The major source artifacts are `SKILL.md` files, Claude Code subagent definitions, rule files with path globs, documentation, and one TypeScript/Bun hook package for the Reflexion plugin. The README describes Claude Code installation through `/plugin marketplace add NeoLabHQ/context-engineering-kit` and cross-agent installation through `npx skills add NeoLabHQ/context-engineering-kit`.

The repo markets many assets as slash commands. In the reviewed checkout, the operational units are mostly `SKILL.md` files with `argument-hint` frontmatter and command-like names such as `plan-task`, `implement-task`, `review-local-changes`, and `do-and-judge`. That can be portable to tools that map skills to commands, but it is not a standalone CLI or framework runtime.

## Research Themes

- Token efficiency: Strong design intent. The repo explicitly prefers command-oriented on-demand assets, subagents, scratchpads, and path-scoped rules to avoid loading every detail into the main context. In practice, many skill and agent files are very large, so portability requires a progressive-loader strategy rather than blindly loading full files.
- Context control: Very strong. The SDD plugin manages task state through `.specs/tasks/draft`, `todo`, `in-progress`, and `done`; planning phases create scratchpads and analysis files; Reflexion curates memory into `CLAUDE.md`; FPF stores hypotheses, evidence, and decisions in `.fpf`.
- Sub-agent / multi-agent: Very strong. SDD planning dispatches researcher, code explorer, business analyst, architect, tech lead, team lead, QA, and developer agents. SADD implements meta-judge, implementation, judge, parallel grouping, sequential steps, competitive generation, and debate patterns. Review dispatches six specialized review agents.
- Domain-specific workflow: Strong. The kit includes focused plugins for SDD, SADD, TDD, DDD rules, TypeScript rules, MCP setup, docs, git, code review, Kaizen analysis, and first-principles decision records.
- Error prevention: Strong as prompt design, medium as enforcement. The kit has explicit quality gates, rubrics, retry loops, confidence/impact filtering, TDD instructions, and practical verification requirements. It also includes bypasses such as `--skip-judges`, max-iteration proceed states, and LLM-only checks without schema validators.
- Self-learning / memory: Medium to strong. `reflexion:memorize` updates `CLAUDE.md` with curated insights; FPF creates evidence and decision records; review and SDD produce durable reports. There is no embedding index, retrieval service, automatic memory decay, or merge-conflict policy for shared memory files.
- Popular skills: No usage telemetry is included. The likely high-value artifacts are `sdd:plan-task`, `sdd:implement-task`, `sadd:do-and-judge`, `sadd:do-in-parallel`, `reflexion:reflect`, `reflexion:memorize`, `review-local-changes`, MCP setup skills, and path-scoped DDD/TypeScript rules.

## Core Execution Path

The marketplace path starts with `.claude-plugin/marketplace.json`, which lists plugins by name, description, version, source path, and category. Installing a plugin makes that plugin's conventional folders available to the agent. Individual plugin manifests are intentionally thin; they do not enumerate every command, skill, agent, hook, or rule.

The SDD path is the most complete context-control flow. `add-task` creates a draft task under `.specs/tasks/draft/` with the original user intent. `plan-task` preflights the task, creates `.specs` folders, then orchestrates staged refinement. The default active stages are research, codebase analysis, business analysis, architecture synthesis, decomposition, parallelization, and verification rubric creation. Research, codebase analysis, and business analysis can run in parallel; each phase is judged; failures retry until a threshold or max-iteration limit. When planning completes, the task is promoted to `.specs/tasks/todo/`.

`implement-task` consumes planned tasks. It moves a task from `todo` to `in-progress`, reads the task once, then is instructed to behave as an orchestrator only. Implementation and verification are delegated to subagents. Each implementation step has a verification level: none, single judge, panel of two judges, or per-item judges. Final Definition of Done verification must pass before the task moves to `.specs/tasks/done/`.

The SADD path is a lower-friction multi-agent executor. `do-and-judge` dispatches a meta-judge and implementation agent in parallel, waits for both, passes the exact meta-judge YAML to a judge agent, parses only verdict/score/issues, and retries implementation with judge feedback. `do-in-parallel` adds independence validation and grouping: repeatable work shares a reusable meta-judge spec, shared interdependent work gets one combined judge, and independent work gets separate specs and judges. `launch-sub-agent` builds a subagent prompt with a reasoning prefix, task body, and mandatory self-critique suffix.

The Review plugin targets local and PR changes. `review-local-changes` first gathers `git status`, diff stats, and changed-file names without loading full diffs into the main context. It then uses up to six parallel agents to summarize changed files and find instruction files, dispatches applicable review agents, and scores each candidate issue with separate confidence and impact agents. Output is filtered by minimum impact and progressive confidence thresholds, then emitted as Markdown or JSON.

The Reflexion plugin has the only executable runtime package. The hook records `UserPromptSubmit` and `Stop` events into `/tmp/claude-hooks-sessions/<session_id>.json`. On `Stop`, it checks the last user prompt for standalone `reflect`, rejects slash-command matches such as `/reflexion:reflect`, prevents consecutive-stop loops, and blocks completion with a reason telling Claude to run `/reflexion:reflect`. The hook command silently no-ops when `bun` is unavailable.

The FPF plugin creates `.fpf/{evidence,decisions,sessions,knowledge/{L0,L1,L2,invalid}}`, initializes context, generates hypotheses, allows user-added hypotheses, verifies logic in parallel, validates evidence in parallel, audits trust, and writes a decision record. It is less about coding edits and more about auditable reasoning and decision context.

The MCP, DDD, and Tech Stack plugins are persistent context setup layers. MCP setup skills guide users through Context7, Serena, Codemap, arXiv/Paper Search, or custom MCP setup, then update a selected `CLAUDE.md` target. DDD and Tech Stack rules use frontmatter such as `paths: ["**/*.ts"]` or `paths: ["**/*"]` so host runtimes can auto-load guidance when matching files are read or written.

## Architecture

- Marketplace layer: `.claude-plugin/marketplace.json` is the root catalog. It is versioned as `3.0.0` and points to plugin directories.
- Plugin layer: each plugin directory has a minimal `.claude-plugin/plugin.json`, a `README.md`, and some mix of `skills/`, `agents/`, `rules/`, `hooks/`, `scripts/`, `tasks/`, and `prompts/`.
- Instruction layer: `SKILL.md` files are the main command surface. Many include Claude-specific `argument-hint`, `allowed-tools`, `Task`, `AskUserQuestion`, `subagent_type`, and `${CLAUDE_PLUGIN_ROOT}` assumptions.
- Agent layer: SDD, SADD, Review, and FPF define specialized agents with names, descriptions, model hints, and role-specific processes.
- Artifact layer: target projects get `.specs` task and scratchpad state, `.fpf` decision state, `CLAUDE.md` memory, `.claude/rules` style instructions, and review reports.
- Rule layer: DDD and Tech Stack rules use frontmatter path globs and impact/title metadata for automatic context injection.
- Hook layer: `plugins/reflexion/hooks` is a TypeScript package using Bun at runtime and Vitest for tests.
- Maintenance layer: `justfile` supports syncing plugin READMEs with docs, version updates, sandbox helpers, and Claude command wrappers.
- Documentation layer: `docs/` mirrors plugin documentation, provides guides, references, and research-paper summaries. Much of this duplicates plugin README content.

## Design Choices

The key design choice is to make agent work artifact-backed. SDD does not ask an agent to "remember" a plan; it creates a draft task, refines it into a planned task, moves it through status folders, writes scratchpads, and records verification status.

The second important choice is strict orchestrator/subagent separation. SDD and SADD repeatedly tell the main agent not to read implementation files or verify work directly after setup. This is meant to preserve the main context window and avoid anchoring on partial implementation details.

The third choice is meta-evaluation before evaluation. SADD uses a meta-judge to produce task-specific YAML rubrics before a judge reviews implementation output. This reduces vague "code quality" judging and makes the judge apply an explicit spec.

The fourth choice is layered verification. Implementation agents perform self-critique, judges apply rubrics, SDD can use panels or per-item judges, and Review adds impact/confidence scoring. This is expensive, but it gives a concrete pattern for choosing when more verification is warranted.

The fifth choice is persistent local memory. Reflexion writes curated lessons into `CLAUDE.md`, MCP setup writes tool-use instructions into a chosen `CLAUDE.md`, and FPF writes reusable decision records.

The sixth choice is path-scoped context. DDD and Tech Stack rules are intended to load only when relevant files are touched. This is a better fit for large codebases than a single giant global instruction file.

The seventh choice is cross-agent packaging through standards-adjacent folders. The README claims compatibility with Claude Code, OpenCode, Cursor, Antigravity, Codex, and others through plugin/skill installers. The actual files still need host-specific adapters for slash commands, tools, hooks, and subagent dispatch.

## Strengths

- Broad operational coverage: the repo covers intake, planning, implementation, review, TDD, git, docs, MCP setup, memory, rules, and architectural decisions.
- Concrete context lifecycle: `.specs` and `.fpf` give visible state transitions rather than hidden chat-only state.
- Strong multi-agent patterns: SDD and SADD provide detailed orchestration, dependency, grouping, retry, and judge flows.
- Useful quality-gate grammar: rubrics, checklist items, thresholds, panel voting, per-item judges, Definition of Done checks, and confidence/impact filters are all reusable.
- Good context-isolation discipline: scratchpads and subagents are used to keep raw exploration and verbose reports out of the main agent context.
- Reflexion hook is small and tested: after installing npm dependencies in the hook package, `npm run test` passed 41 Vitest tests covering trigger matching, slash-command exclusion, cycle prevention, and last-prompt behavior.
- Path rules are practical: TypeScript and DDD rules demonstrate how to turn broad coding preferences into files that can be auto-loaded by glob.
- MCP setup skills connect context control to tool availability: they update persistent instructions only after guiding setup for tools like Context7 and Serena.
- The docs make provenance visible: `docs/resources/papers.md` maps plugins to papers and gives a useful bibliography for future synthesis.

## Weaknesses

- It is not a conventional runtime framework. Most behavior is prompt text executed by a host agent, with no repo-wide schema validation, CLI, or harness for the Markdown assets.
- Plugin manifests under-specify installed assets. The per-plugin `plugin.json` files do not list commands, skills, agents, rules, or hooks, so consumers must rely on folder conventions or installer-specific discovery.
- The command surface is inconsistent. README and docs describe slash commands, while the checked-in operational files are mostly `SKILL.md` assets with command-like names.
- Claude Code assumptions are pervasive: `Task`, `Skill`, `TodoWrite`, `AskUserQuestion`, `allowed-tools`, `subagent_type`, `${CLAUDE_PLUGIN_ROOT}`, hook events, and `/plugin` commands all need translation for Codex or other runtimes.
- Some prompts use hostile or violent motivational wording. Besides being unnecessary, this can be brittle across safety policies, enterprise environments, and agent runtimes.
- Verification gates are not fully hard gates. `--skip-judges` can disable checks, and planning may proceed after max iterations even if a judge score remains below threshold.
- The strongest reliability claims are not reproducible from the repo. README probability tables and "scientifically proven" claims are not backed by a checked-in benchmark harness or experiment logs.
- The Reflexion hook silently no-ops if Bun is missing and stores prompt/session payloads in `/tmp` without a cleanup or redaction policy.
- Some rules are opinionated enough to conflict with project conventions, such as mandatory enums, blanket library-first guidance, and file-size limits applying to all paths.
- Prompt files include typos, duplicated ideas, and very long embedded examples. They are useful source material, but not polished enough to copy directly into a strict lab baseline.

## Ideas To Steal

- Use a `.specs` task lifecycle: draft for user intent, todo for planned specs, in-progress for active work, done for verified tasks.
- Split planning into research, codebase analysis, business analysis, architecture synthesis, decomposition, parallelization, and verification-rubric stages.
- Require phase outputs to go through judge checks before downstream phases consume them.
- Use scratchpad files for verbose subagent reasoning and final reports, then return compact paths and summaries to the orchestrator.
- Use meta-judge generated rubrics before judge evaluation so checks are task-specific and evidence based.
- Add verification levels to implementation steps: none, single judge, panel, and per-item judges.
- Borrow the review plugin's confidence/impact filtering to reduce noisy code-review findings.
- Make path-scoped rule files a first-class context mechanism instead of stuffing all guidance into `AGENTS.md` or `CLAUDE.md`.
- Use memory curation rules before updating persistent context: deduplicate, keep specific evidence-backed lessons, avoid vague global advice, and prefer incremental updates.
- Use a Reflexion-style hook pattern with word-boundary trigger matching and cycle prevention, but make runtime dependency failures visible.
- Use FPF-style knowledge layers for architectural decisions: candidate hypotheses, logic-verified hypotheses, evidence-backed hypotheses, invalidated hypotheses, evidence, and decision records.
- Treat MCP setup as context setup: after tool installation, write a small persistent instruction block that tells future agents when and how to use the tool.

## Do Not Copy

- Do not copy the whole prompt library unchanged. Extract patterns, then rewrite for the target runtime, tool names, policy constraints, and local project conventions.
- Do not copy hostile judge and agent identity language. Keep strictness through rubrics, evidence requirements, and failure criteria instead.
- Do not treat the README's reliability percentages as validated benchmarks. Require a local evaluation harness before using them as claims.
- Do not rely on folder discovery alone for installed assets. Agentic Coding Lab should maintain explicit manifests or generated indexes for skills, rules, agents, hooks, and commands.
- Do not make hook failures silent. If a hook requires Bun or another runtime, missing dependencies should be visible and actionable.
- Do not persist raw prompts or session data without retention and privacy rules.
- Do not apply broad DDD or TypeScript rules across every repository without project opt-in and conflict handling.
- Do not allow a "skip judges" path to look equivalent to the verified workflow in reporting or status.
- Do not use LLM judge output as the only quality signal for code. Keep existing lint, typecheck, build, tests, and project validators as primary evidence.
- Do not assume Claude Code subagent names or slash-command formats will work in Codex, Cursor, OpenCode, or Gemini without adapters.

## Fit For Agentic Coding Lab

Fit is high as a pattern source and moderate as directly reusable assets. The repo is squarely in-scope for context-control research because it turns agent context engineering into installable workflow artifacts with staged state, subagent isolation, verification, memory, and rules.

The best Agentic Coding Lab adaptation would be a smaller, typed, testable subset:

1. A portable task artifact schema inspired by `.specs`.
2. A Codex-native orchestrator contract that maps SDD/SADD phases to available tools.
3. Explicit manifests for all skills, agents, rules, hooks, and setup instructions.
4. Validators for task status transitions, rubric YAML, missing verification evidence, and stale context.
5. A review gate combining project test commands with LLM judge reports.
6. Safe memory update rules for `AGENTS.md` or project-local memory files.
7. A hook/runtime adapter with dependency checks, redaction, and cleanup.

Whole-repo adoption is not recommended. The repo is too Claude-specific and too prompt-heavy for that. The right move is to extract the durable shapes: staged artifacts, context isolation, meta-judge rubrics, path-scoped rules, and evidence-backed memory.

## Reviewed Paths

- `README.md`: overview, installation paths, plugin catalog, reliability table, Reflexion examples, marketplace positioning, and cross-client claims.
- `CLAUDE.md`: project structure, design philosophy, commands-over-skills guidance, contribution rules, MCP usage notes, and internal development practices.
- `CONTRIBUTING.md`: plugin philosophy, minimal token footprint guidance, plugin structure, manifest expectations, and quality guidelines.
- `.claude-plugin/marketplace.json`: marketplace manifest, plugin list, versions, categories, and source paths.
- `plugins/*/.claude-plugin/plugin.json`: reviewed representative and aggregate manifest shape; all are minimal name/version/description/author manifests.
- `plugins/README.md` and plugin READMEs: plugin directory conventions, plugin summaries, target use cases, and documentation claims.
- `plugins/sdd/README.md`, `skills/add-task/SKILL.md`, `skills/plan-task/SKILL.md`, `skills/implement-task/SKILL.md`, `skills/create-ideas/SKILL.md`: SDD task lifecycle, planning stages, implementation orchestration, verification levels, retry behavior, and status folders.
- `plugins/sdd/agents/*`: sampled researcher, code-explorer, business analyst, software architect, tech lead, team lead, developer, QA, and writer agent roles for staged context assembly.
- `plugins/sdd/prompts/judge.md`, `plugins/sdd/scripts/create-folders.sh`, `plugins/sdd/scripts/create-scratchpad.sh`: judge methodology and artifact creation support.
- `plugins/sadd/README.md`, `skills/do-and-judge/SKILL.md`, `skills/do-in-parallel/SKILL.md`, `skills/do-in-steps/SKILL.md`, `skills/launch-sub-agent/SKILL.md`, `skills/judge/SKILL.md`, `skills/tree-of-thoughts/SKILL.md`, `skills/do-competitively/SKILL.md`, `skills/judge-with-debate/SKILL.md`: SADD orchestration, grouping, model selection, meta-judge, judge, debate, and competitive execution patterns.
- `plugins/sadd/agents/meta-judge.md`, `plugins/sadd/agents/judge.md`: rubric generation, mechanical evaluation, checklist application, scoring, scratchpad use, and rule generation.
- `plugins/reflexion/README.md`, `skills/reflect/SKILL.md`, `skills/memorize/SKILL.md`, `skills/critique/SKILL.md`: self-refinement, memory curation, multi-perspective critique, and confidence rules.
- `plugins/reflexion/hooks/**`: hook configuration, TypeScript source, session storage, trigger logic, package metadata, and Vitest tests.
- `plugins/review/README.md`, `skills/review-local-changes/SKILL.md`, `skills/review-pr/SKILL.md`, `agents/*`: review workflow, specialized agents, confidence/impact scoring, CI-oriented output formats, and local/PR scope handling.
- `plugins/tdd/README.md`, `skills/test-driven-development/SKILL.md`, `skills/write-tests/SKILL.md`, `skills/fix-tests/SKILL.md`: red-green-refactor flow, test-writing, and test-fixing guidance.
- `plugins/ddd/README.md`, `plugins/ddd/rules/*.md`: automatic DDD/code-quality rules, path/impact frontmatter, representative rules for library-first, size limits, data flow, error handling, and architecture.
- `plugins/tech-stack/README.md`, `rules/typescript-best-practices.md`: path-scoped TypeScript best practices and examples.
- `plugins/mcp/README.md`, `skills/setup-context7-mcp/SKILL.md`, `skills/setup-serena-mcp/SKILL.md`, `skills/setup-codemap-cli/SKILL.md`, `skills/setup-arxiv-mcp/SKILL.md`, `skills/build-mcp/SKILL.md`: MCP setup, persistent instruction updates, and server-building guidance.
- `plugins/fpf/README.md`, `skills/propose-hypotheses/SKILL.md`, `skills/status/SKILL.md`, `skills/query/SKILL.md`, `skills/decay/SKILL.md`, `skills/actualize/SKILL.md`, `skills/reset/SKILL.md`, `tasks/*.md`, `agents/fpf-agent.md`: ADI workflow, knowledge layers, evidence freshness, trust audit, and decision records.
- `plugins/customaize-agent/README.md`, representative skills for creating/testing agents, commands, hooks, skills, prompts, and applying Anthropic skill best practices.
- `plugins/docs/README.md`, `skills/update-docs/SKILL.md`, `skills/write-concisely/SKILL.md`: documentation maintenance and writing guidance.
- `docs/reference/skills.md`, `docs/reference/agents.md`, `docs/reference/commands.md`, `docs/resources/papers.md`, selected guides under `docs/guides/`: docs coverage, reference indexes, and research-paper provenance claims.
- `justfile`: docs sync, versioning, sandbox helpers, and Claude command wrappers.
- GitHub REST API metadata for stars, forks, issues, license, default branch, and pushed timestamp.
- Local verification command in the external checkout: `npm run test` under `plugins/reflexion/hooks`, after dependency installation.

## Excluded Paths

- `docs/assets/*.png` and `docs/assets/*.gif`: branding and tutorial media, not primary technical artifacts.
- `node_modules/` and generated `plugins/reflexion/hooks/package-lock.json` created by local dependency installation in the temporary checkout: verification byproducts, not reviewed source.
- `.git/**` in the temporary clone: used only for commit and status checks.
- Full line-by-line review of every DDD rule, long writing reference, Kaizen example, and Customaize-Agent hook tutorial: representative files were sampled because the relevant context-control patterns were already clear.
- External paper full texts linked from `docs/resources/papers.md`: paper titles and provenance were reviewed as repo documentation, but the note does not validate every claimed paper-to-plugin mapping.
- GitHub issues, pull requests, Actions runs, release notes beyond the current repository metadata and README news section: not needed to evaluate the checked-in context-control artifacts.
- Third-party directories and installers such as `agentskills.io`, `vercel-labs/skills`, OpenSkills, Context7 pages, and marketplace mirrors: noted for portability claims, but not deeply reviewed.
- Docs copies that duplicate plugin README content: source plugin files were preferred where duplicate content existed.
