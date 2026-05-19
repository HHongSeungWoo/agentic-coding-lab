# muratcankoylan/Agent-Skills-for-Context-Engineering

- URL: https://github.com/muratcankoylan/Agent-Skills-for-Context-Engineering
- Category: context-control
- Stars snapshot: 15,590 (GitHub REST API `stargazers_count`, captured 2026-05-12)
- Reviewed commit: 7a95d94c364e25c869a86896a45791dfda6db8bf
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: in-scope
- Verdict: High-value context-control pattern library for agent skills, progressive disclosure, compression, degradation detection, filesystem offload, tool design, memory, evaluation, and multi-agent isolation. Best used as a design corpus for Agentic Coding Lab skills and guardrails, not as a drop-in runtime, because most artifacts are static instructions and illustrative scripts rather than enforced hooks, MCP tools, metrics, or production tests.

## Why It Matters

This repository is a concentrated static skill architecture for context engineering. It treats context as an attention budget and turns that premise into 14 installable skills covering context fundamentals, degradation, compression, optimization, latent KV briefing, multi-agent patterns, filesystem context, memory systems, tool design, hosted agents, evaluation, project development, and BDI mental states.

For Agentic Coding Lab, the useful part is the artifact structure: skill metadata for routing, short `SKILL.md` bodies, deeper reference files, scripts as optional implementation aids, examples that map principles to systems, and self-audit docs that name gaps. It is a strong source for practical vocabulary and design patterns around context control.

The caution is operational maturity. The repo teaches agents how to reason about context engineering, but does not itself enforce context budgets, hook tool outputs, measure skill activations, preserve raw artifacts, or validate every skill through an automated harness.

## What It Is

`Agent-Skills-for-Context-Engineering` is a Claude Code plugin marketplace and Open Plugins-compatible skill pack. The root marketplace installs one `context-engineering` plugin with all 14 skill directories. Each skill follows the same rough shape:

- `SKILL.md` with YAML frontmatter, activation triggers, concepts, guidance, examples, gotchas, integration, and references.
- Optional `references/` markdown for deeper implementation patterns.
- Optional `scripts/` Python examples demonstrating concepts.

The repo also includes a root collection-level `SKILL.md`, a canonical skill template, source/reference docs, a research curation rubric, and five examples: `digital-brain-skill`, `x-to-book-system`, `llm-as-judge-skills`, `interleaved-thinking`, and `book-sft-pipeline`.

There is no top-level app or build system. Runnable code is concentrated in example projects and illustrative scripts.

## Research Themes

- Token efficiency: Strong. The repo gives concrete patterns for progressive disclosure, effective-capacity budgeting, observation masking, structured compression, KV-cache prompt ordering, filesystem offload, and sub-agent context partitioning.
- Context control: Very strong. This is the core subject. The most useful patterns are degradation taxonomy, 70-80% compaction triggers, artifact-preserving summaries, dynamic skill loading, explicit context budgets, and file-backed scratch/plan/state.
- Sub-agent / multi-agent: Strong as architecture guidance. `multi-agent-patterns`, `hosted-agents`, `latent-briefing`, and examples emphasize context isolation, supervisor bottlenecks, direct forwarding, filesystem coordination, and task-scoped workers.
- Domain-specific workflow: Medium to strong. The core skills are generic, but examples translate them into personal knowledge systems, social-to-book pipelines, LLM evaluation tools, trace optimizers, and SFT pipelines.
- Error prevention: Strong as guidance, moderate as implementation. Skills include gotchas, recovery procedures, degradation detection, evaluation rubrics, and tool error-message design. Enforcement hooks and continuous validation are mostly absent.
- Self-learning / memory: Medium. Memory design covers file memory, vector stores, temporal knowledge graphs, consolidation, stale memory, and retrieval failures. The repository itself is mostly stateless and does not use plugin data storage.
- Popular skills: No usage telemetry was present. The most reusable candidates for Agentic Coding Lab are `context-fundamentals`, `context-degradation`, `context-compression`, `context-optimization`, `filesystem-context`, `multi-agent-patterns`, `tool-design`, `evaluation`, and `latent-briefing`.

## Core Execution Path

The normal plugin path is static discovery:

1. User adds the repository as a Claude Code marketplace.
2. User installs `context-engineering@context-engineering-marketplace`.
3. Claude Code reads `.claude-plugin/marketplace.json`, which points one plugin at `source: "./"` and lists all 14 skill directories.
4. The host loads skill names and frontmatter descriptions for discovery.
5. When a task matches a trigger, the host loads that skill's `SKILL.md`.
6. The skill may direct the agent to load a specific reference file or run/adapt a script.

There is no central runtime that automatically optimizes context. Scripts such as `context_manager.py`, `compaction.py`, `compression_evaluator.py`, `filesystem_context.py`, `memory_store.py`, `coordination.py`, and `evaluator.py` are concept demonstrations or helper templates.

The richer examples have their own paths. `llm-as-judge-skills` is a TypeScript package with Zod schemas, AI SDK tools, an `EvaluatorAgent`, and Vitest tests. `interleaved-thinking` is a Python package for capture -> analyze -> optimize -> generate-skill loops. `digital-brain-skill` is a file-structured skill template using JSONL/YAML/Markdown/XML. `x-to-book-system` is a PRD-style multi-agent design. `book-sft-pipeline` is a standalone skill and conceptual training pipeline.

## Architecture

The repo has five layers.

The distribution layer is `.claude-plugin/marketplace.json` and `.plugin/plugin.json`. The Claude marketplace manifest installs all skills as one plugin; the Open Plugins manifest provides minimal name, description, version, and author metadata.

The skill layer is `skills/`. It contains 14 directories, each with frontmatter-triggered `SKILL.md` and optional deeper artifacts. Skills are grouped conceptually into foundational, architectural, operational, development methodology, hosted infrastructure, evaluation, and cognitive architecture topics.

The reference/script layer sits inside each skill. References expand implementation details such as context component design, degradation monitoring, compression evaluation, optimization techniques, filesystem implementation patterns, memory implementation, framework examples, tool design, and evaluation metrics. Scripts provide lightweight implementations for token estimation, context building, degradation detection, compression probes, observation storage, scratch pads, memory stores, multi-agent coordination, and pipeline templates.

The examples layer demonstrates composition. `digital-brain-skill` is the clearest applied context-control example because it uses a three-level loading strategy and module isolation. `x-to-book-system` shows supervisor plus file-system coordination. `llm-as-judge-skills` is the most concrete software package. `interleaved-thinking` is an optimization-loop prototype with generated artifacts. `book-sft-pipeline` shows staged pipeline design and validation.

The docs/researcher layer is a source corpus. It includes curated notes from Anthropic skills guidance, context compression articles, Vercel tool reduction, Netflix context-compression/spec workflow material, LLM-as-judge rubricing, and a self-analysis of repository gaps.

## Design Choices

Progressive disclosure is the dominant design choice. The repository intentionally keeps discovery metadata short, `SKILL.md` files bounded, and detailed material in references. This lets an agent load only the relevant skill and then only the deeper file needed for the task.

The skills are platform-agnostic in prose, but packaged for Claude Code. They avoid hard dependence on one runtime in most instructions while still providing marketplace metadata for Claude and Open Plugins metadata for Cursor/Codex-like tooling.

The collection favors conceptual primitives over automation. Each skill explains mechanisms, decision thresholds, gotchas, and trade-offs. The scripts demonstrate mechanics but are not wired into a plugin hook or MCP server.

Skill descriptions use explicit trigger phrases. This is useful because frontmatter descriptions become the routing contract; the repo's self-audit identifies this as a strength.

The authoring template bakes in gotchas, integration, references, and metadata. This is a good pattern because failure modes are first-class, not afterthoughts.

Several skills use quantitative heuristics as operating defaults: effective context at 60-70% of nominal window, compaction at 70-80%, observation masking after several turns, 50-70% compaction targets, and sub-agent partitioning when task context exceeds about 60%. These should be treated as starting points, not universal laws.

The examples intentionally show "skills as design input." `HOW-SKILLS-BUILT-THIS.md` in `digital-brain-skill` is especially useful because it maps each architecture decision back to a skill principle.

`latent-briefing` is deliberately specialized. It distinguishes text summaries, retrieval, prefix caching, and task-conditioned KV-cache retention, and clearly states the infrastructure precondition: direct access to compatible worker-model KV state.

## Strengths

The context-control taxonomy is coherent. The skills cover what goes into context, how context degrades, how to compress it, how to optimize it, how to offload it to files, how to split it across agents, and how to evaluate whether any of that helped.

The best sections are operationally specific. Examples include artifact-preserving compression sections, context-poisoning recovery, observation masking rules, cache-stable prompt ordering, file-backed scratch pads, plan persistence, sub-agent workspaces, tool description contracts, error-message design, and multi-dimensional eval rubrics.

The repository's static skill shape is easy to adapt. Frontmatter trigger descriptions, short `SKILL.md` bodies, reference files, scripts, and gotchas create a reusable pattern for Agentic Coding Lab skills.

`digital-brain-skill` is a strong concrete example of context engineering as filesystem design: modules, append-only JSONL, YAML config, Markdown narrative files, XML prompt templates, and small scripts that return compact summaries.

`llm-as-judge-skills` is the most executable example. It has typed inputs/outputs, bias-aware pairwise comparison, direct scoring, rubric generation, an evaluator wrapper, package metadata, and tests that document expected behavior.

The repository has a useful self-critique in `docs/skills-improvement-analysis.md`. It explicitly recognizes that the skills are knowledge-first, lack on-demand hooks, lack setup/config patterns, lack measurement infrastructure, and do not use persistent plugin data.

The skill gotchas are practical. They capture common real failures such as cache invalidation from whitespace, stale summary confidence, masking debug errors, supervisor bottlenecks, stale memory poisoning, broad glob over-retrieval, and missing temporal validity.

## Weaknesses

The repo is not an operational context-control system. It has no top-level hook that masks tool outputs, no token budget monitor, no context ledger, no MCP server, no persistent skill telemetry, and no automatic raw-artifact recovery path.

Scripts are unevenly production-ready. Many are useful demonstrations, but dependencies, storage choices, and integration boundaries are not standardized. Some scripts require external packages such as NumPy or model APIs; others are pure pseudocode-style examples.

No top-level automated validation was found. There are tests under `skills/context-compression/tests`, `examples/interleaved-thinking/tests`, and `examples/llm-as-judge-skills/tests`, but there is no repo-wide test runner, manifest validator, frontmatter schema check, broken-reference check, or script import check.

The evidence base is mixed. Some claims come from copied reference docs, transcripts, blog notes, or benchmark summaries. They are valuable as design inputs, but not all are independently reproducible in this repo.

Some docs drift. For example, `CLAUDE.md` still describes the marketplace manifest as having 5 bundled plugins, while the reviewed `.claude-plugin/marketplace.json` has one bundled plugin with all 14 skills.

The examples include generated or result artifacts. `interleaved-thinking/optimization_artifacts/` and `generated_skills/` are useful for demonstration, but should not be treated as curated source instructions without review.

The plugin manifest sets `strict: false` and does not encode skill versioning per directory. Skill metadata versions exist inside files, but the install surface does not enforce compatibility or dependency constraints.

Some topics are high-risk or narrow. `bdi-mental-states` and `latent-briefing` are intellectually useful, but can add ontology/KV complexity far beyond normal coding-agent needs. They need stronger "when not to use" enforcement in an applied system.

## Ideas To Steal

Use a skill format with three levels: terse discovery metadata, actionable `SKILL.md`, and deeper references/scripts loaded only on demand.

Treat "gotchas" as required skill content. For coding-agent support systems, failure modes often carry more value than generic best practices.

Build context-control skills around concrete boundaries: system prompt, tool definitions, retrieved docs, message history, tool outputs, file memory, and sub-agent handoffs.

Adopt artifact-preserving compression sections: user goal, files read, files changed, exact commands, exact failures, decisions, rejected approaches, current state, next verification step, and raw artifact pointers.

Use filesystem context as a first-class pattern: large tool outputs to files, scratch pads, persistent plans, per-agent workspaces, terminal logs, and dynamic skill loading.

Use context degradation as a diagnosis taxonomy before optimization. Lost-in-middle, poisoning, distraction, confusion, and clash map well to different remediation actions.

Copy the "context budget by component" idea. Budget system prompts, tool definitions, retrieved docs, history, tool output, and reserve separately, then trigger policies when categories exceed limits.

Translate the self-audit into backlog items: hooks, config, persistent data, measurement, composable scripts, and validation harnesses.

Use examples like `digital-brain-skill` as reference implementations of file-format choice: JSONL for append logs, YAML for config, Markdown for narrative guidance, XML for complex prompt templates.

## Do Not Copy

Do not ship static instruction skills as the whole solution. Agentic Coding Lab needs runtime enforcement: hooks, tool-output policies, budget checks, raw artifact storage, and verification.

Do not treat all thresholds and benchmark numbers as portable. Re-benchmark per model, workload, context size, and tool-output mix.

Do not load all 14 skills into active context. Use the repo's own progressive-disclosure principle and retrieve only the skill needed for the task.

Do not copy generated optimization artifacts or generated skills into a curated corpus without review. They are useful examples, not stable design authority.

Do not adopt latent KV briefing unless the runtime controls worker inference internals and model compatibility. For API-only coding agents, structured text handoff and filesystem memory are more practical.

Do not rely on illustrative scripts without hardening. Add tests, dependency checks, CLI contracts, error handling, storage scopes, and security reviews before turning them into tools.

Do not use broad memory or ontology systems when file-backed state is enough. The memory skill itself argues for the simplest viable layer.

## Fit For Agentic Coding Lab

Fit is high. This repo should be treated as a pattern library and skill-authoring reference for context-control work.

Best adaptation: build a smaller Agentic Coding Lab context-control pack with enforced behavior. Start with `context-fundamentals`, `context-degradation`, `context-compression`, `context-optimization`, `filesystem-context`, `tool-design`, `multi-agent-patterns`, and `evaluation`. Turn their strongest ideas into concrete artifacts:

- A `PostToolUse` or equivalent hook that stores large outputs as raw artifacts and injects compact, searchable references.
- A context ledger tracking files read/changed, commands run, failures, decisions, and pending verification.
- A compression contract with probe-based tests.
- A skill validator for frontmatter, headings, references, line counts, and examples.
- A metric path for activation, skipped compression, raw tokens, compressed tokens, re-fetch events, and verification outcomes.

The repo is worth adopting for vocabulary and structure. It should not be forked wholesale into active agent context without pruning, tests, and runtime controls.

## Reviewed Paths

- `README.md`: repository positioning, skills overview, install flow, trigger table, examples, and structure.
- `SKILL.md`: collection-level skill map, core concepts, integration, and metadata.
- `CLAUDE.md`: repository guidance, build/test expectations, skill authoring rules, plugin architecture, and design principles.
- `CONTRIBUTING.md`, `LICENSE`, `.gitignore`, `.cursorindexingignore`: contribution process, license, ignored/generated paths, and local indexing rules.
- `.plugin/plugin.json`: Open Plugins manifest metadata.
- `.claude-plugin/marketplace.json`: Claude Code marketplace plugin definition and 14-skill bundle.
- `template/SKILL.md`: canonical skill structure, required frontmatter, gotchas, references, and metadata sections.
- `skills/context-fundamentals/SKILL.md`, `skills/context-degradation/SKILL.md`, `skills/context-compression/SKILL.md`, `skills/context-optimization/SKILL.md`, `skills/latent-briefing/SKILL.md`: core context-control skills.
- `skills/filesystem-context/SKILL.md`, `skills/memory-systems/SKILL.md`, `skills/multi-agent-patterns/SKILL.md`, `skills/tool-design/SKILL.md`: architecture, memory, tool, and multi-agent context patterns.
- `skills/evaluation/SKILL.md`, `skills/advanced-evaluation/SKILL.md`, `skills/project-development/SKILL.md`, `skills/hosted-agents/SKILL.md`, `skills/bdi-mental-states/SKILL.md`: evaluation, methodology, hosted-agent, and cognitive architecture skills.
- `skills/*/references/*.md`: reference headings and representative content for context components, degradation patterns, compression evaluation, optimization techniques, filesystem implementation, memory implementation, multi-agent frameworks, tool design, project case studies, evaluation metrics, hosted infrastructure, BDI, and latent briefing.
- `skills/*/scripts/*.py`: script entry points and major classes/functions for context management, degradation detection, compression evaluation, compaction, filesystem context, memory store, coordination, evaluation, tool description generation, hosted sandbox management, and pipeline scaffolding.
- `skills/context-compression/tests/test_compression_evaluator.py`: unit tests for heuristic scoring of structured and text ground truth.
- `docs/skills-improvement-analysis.md`, `docs/compression.md`, `docs/vercel_tool.md`, `docs/agentskills.md`, `docs/netflix_context.md`, `docs/claude_research.md`, `docs/gemini_research.md`, `docs/hncapsule.md`, `docs/blogs.md`: docs corpus reviewed for source ideas, self-audit, compression, tool reduction, and skill-writing guidance.
- `researcher/llm-as-a-judge.md`, `researcher/example_output.md`: curation rubric and example extraction output.
- `examples/digital-brain-skill/**`: README, skill definition, module docs, data formats, scripts, and skill mapping.
- `examples/x-to-book-system/**`: README, PRD, skills mapping, multi-agent architecture, context budget, memory, and tool design.
- `examples/llm-as-judge-skills/**`: README, package metadata, prompts/tools/agents docs, TypeScript source, examples, and tests.
- `examples/interleaved-thinking/**`: README, skill definition, pyproject, optimizer source, tests, generated-artifact structure, and docs headings.
- `examples/book-sft-pipeline/**`: README, standalone skill, pipeline script, reference docs, Gertrude Stein case-study metadata, and dataset/config samples.
- Git/GitHub metadata: reviewed commit, latest merge commit, branch, remote, tracked file structure, and GitHub REST star/fork/open-issue snapshot.

## Excluded Paths

- `.git/`: VCS internals. Used only through Git commands to capture commit, branch, remote, and history metadata.
- `node_modules/`, `dist/`, `build/`, `.venv/`, `__pycache__/`: absent in the reviewed checkout or ignored by project metadata; excluded as generated/vendor/build artifacts.
- `examples/book-sft-pipeline/examples/gertrude-stein/pangram/*.png`: binary AI-detector screenshots. File presence was noted, but image contents are UI/binary evidence rather than context-engineering logic.
- `examples/interleaved-thinking/optimization_artifacts/**`: generated optimization traces, analyses, and prompt outputs. Directory shape, summary/final prompt presence, and role in the example were reviewed; individual iteration artifacts were excluded as generated run output.
- `examples/interleaved-thinking/generated_skills/**/references/*.json` and `optimized_prompt.txt`: generated artifacts from an optimizer run. Structure was reviewed, but deep content was excluded because generated outputs require separate curation before reuse.
- External linked resources such as DeepWiki, arXiv PDFs, Vercel/Anthropic/MiniMax/OpenAI docs, Hugging Face datasets, and standalone example repositories: links and claims in checked-in docs were reviewed, but external sites were not cloned as part of this repo note.
- Full line-by-line review of long copied transcript/reference docs under `docs/`: headings and key source docs were reviewed for design provenance; exhaustive transcript review was excluded because those files are source/reference corpus, not executable repo behavior.
