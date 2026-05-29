# letta-ai/skills

- URL: https://github.com/letta-ai/skills
- Category: skills-instructions
- Stars snapshot: 108 (GitHub REST API, captured 2026-05-29; matches `research/index.md` row captured 2026-05-29)
- Reviewed commit: cb8a79f91a048ce8b189f564ebe94d74a6edb83e
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: conditional
- Verdict: Useful as a live skill corpus and as a case study in Letta-style memory-backed skill discovery, but the repo is not itself a skill manager. The strongest reusable material is the meta skill's guidance on hierarchical discovery, dynamic `skills` memory block updates, metadata precision, and validation culture. The current implementation is still flat, registry-less, and weakly governed for scale.

## Why It Matters

This repo is directly relevant to `skill-management-routing` because it sits at the boundary between Anthropic-style `SKILL.md` packages and Letta's persistent-memory agent model. It claims agents can dynamically discover updated skills and then update a `skills` memory block, which is a concrete alternative to stuffing all skills into the system prompt. It also contains an explicit scale analysis for 100-1000+ skill libraries, including category-first discovery, dynamic memory updates, registries, analytics, and pruning.

The value is mostly architectural rather than executable. It shows what a community skill repository wants to become, and it exposes the friction points that appear once a corpus grows: description context cost, category drift, missing machine-readable routing fields, stale contribution docs, and quality gates that are documented but not enforced.

## What It Is

`letta-ai/skills` is a shared repository of agent skills intended for Letta Code, Claude Code, Codex CLI, and compatible skill hosts. Skills follow the common package shape: a required `SKILL.md` with YAML frontmatter and optional `references/`, `scripts/`, and `assets/` directories.

At the reviewed commit the repository contains 42 `SKILL.md` files: 10 under `letta/`, 31 under `tools/`, and 1 under `meta/`. The top-level taxonomy is deliberately simple: Letta product ecosystem skills, general tool integrations, and a meta skill for creating and contributing skills. The repo also includes a GitHub workflow that invokes `letta-ai/letta-code-action@v0` on issues and review comments, but it does not include a loader, router, registry generator, search service, or CI validation job for the skill corpus.

## Research Themes

- Token efficiency: Strong conceptual material. The meta progressive-disclosure report recommends metadata -> category -> full skill -> references rather than loading every skill description/body. Current repo still exposes 42 frontmatter descriptions totaling about 1,342 words and 9,569 characters if a host loads every skill description.
- Context control: The repo's most important pattern is a mutable Letta `skills` memory block that starts with categories, adds category skill lists when explored, adds active skill content when selected, and removes loaded skill content when done. This is a strong context-control idea, but it is documentation only in this repo.
- Sub-agent / multi-agent: Some Letta skills cover fleet management, shared memory blocks, canary agents, and multi-agent concurrency. The skill corpus itself does not include a multi-agent router for skill review or activation.
- Domain-specific workflow: Strong corpus coverage for Letta agents, memory, compaction prompts, API clients, channel plugins, PDFs, Playwright, GitHub, Slack, MCP builder, spreadsheets, slides, notebooks, transcription, and other tool workflows. The organization is practical but broad.
- Error prevention: Culture and validation docs require generalizability, evidence strength, peer review, tradeoff documentation, and avoidance of one-off project config. Runtime enforcement is weak: the bundled validator only checks basic frontmatter and is not wired into CI.
- Self-learning / memory: High relevance. The repo frames skills as agent-to-agent shared learning, recommends contributing patterns validated across repeated agent work, and uses Letta memory concepts such as core memory blocks, archival memory, MemFS/QMD search, and safe memory update operations.
- Popular skills: `letta-api-client`, `agent-development`, `compaction-prompts`, `fleet-management`, `memfs-search`, `mcp-builder`, `playwright`, `github`, `pdf`, `slides`, `screenshot`, and `ai-news` are the highest-signal examples for reusable agent workflows and routing collisions.

## Core Execution Path

The intended user path is simple:

1. Clone the repo into a working project's `.skills` directory.
2. Letta Code, Claude Code, or another compatible host discovers `SKILL.md` files.
3. The agent browses or selects relevant skills from the repository.
4. If skills are updated, the user asks the Letta agent to check for new skills and update its `skills` memory block.
5. The host loads the selected `SKILL.md`; the agent optionally reads bundled `references/`, executes deterministic `scripts/`, or uses `assets/`.

The repo itself stops at files and documentation. Dynamic discovery, activation, context injection, memory block mutation, permission checks, and unloading are host responsibilities. The README states that Letta Code and Claude Code should handle automatic discovery, but no discovery code lives here.

The meta skill describes a more scalable path:

1. Always keep only top-level categories in memory.
2. Select a likely category from the task.
3. Load that category's skill list or `CATEGORY.md`.
4. Select one skill from the narrowed set.
5. Load full `SKILL.md` and references only as needed.
6. Update the `skills` memory block as navigation happens.

That path is not implemented in the current repository: there are no `CATEGORY.md` files, no `skills.index.json`, and no search or router tool for the corpus.

## Architecture

The actual repo architecture is a flat corpus:

- `letta/`: 10 Letta-specific skills for agent development, API clients, compaction, conversations, fleet management, memory import/navigation, configuration, channel plugins, and filesystem-to-MemFS migration.
- `tools/`: 31 general integrations such as 1Password, AI news, Datadog, Discord, DOCX, Figma, frontend guidance, GitHub, Google Workspace, iMessage, Jupyter, Linear, MCP builder, MemFS search, Morph WarpGrep, Notion, Obsidian, PDF, Playwright, Remotion, screenshot, Sentry, Slack, slides, social CLI, speech, Spotify, spreadsheets, transcription, visual identity, and Yelp.
- `meta/skill-development/`: skill authoring guidance, validation criteria, PR workflow, examples, and scripts for initializing, packaging, and quick-validating a skill.
- `.github/workflows/letta.yml`: a Letta Code action for issue/PR interaction, not corpus validation.

Resource distribution shows meaningful progressive-disclosure discipline: 21 skills have `references/`, 24 have `scripts/`, and 27 have `assets/`. Several skills use `agents/openai.yaml` for UI-facing metadata such as display name, icon, and default prompt. Those sidecars are not routing metadata; they do not express triggers, categories, permissions, trust, versioning, dependencies, or negative activation cases.

## Design Choices

The repo adopts the Anthropic skill shape because it is portable across hosts: frontmatter for name/description and Markdown for instructions, with resources kept out of the initial skill body. This makes the corpus easy to clone and easy for an agent to inspect with ordinary filesystem tools.

The strongest design choice is the meta guidance that progressive disclosure at scale is a discovery problem, not a documentation problem. The proposed architecture uses category metadata first, then category-local skill metadata, then full skill content. It also recommends explicit differentiation in metadata: trigger conditions, scope, "does not cover" clauses, related skills, optional keywords, version fields, deprecation metadata, usage analytics, and registry generation.

The Letta-specific twist is dynamic memory. Rather than treating the skill list as static system prompt content, the docs propose a mutable `skills` memory block. Initially it contains only categories; when the agent explores a category it appends category skills; when a skill becomes active it tracks loaded skill content; when the task is done it unloads. This maps skill selection into the same memory-management model Letta uses elsewhere.

The quality model is social first. `CULTURE.md`, `CONTRIBUTING.md`, and `validation-criteria.md` emphasize peer review, generalizability, evidence strength, repeated observations, and tradeoffs. This is useful for preventing low-quality skill growth, but it is not yet backed by strong automated governance.

## Strengths

- Clear corpus shape: agents can discover skills by scanning directories and reading `SKILL.md` frontmatter without a proprietary manifest.
- Practical current scale: 42 skills is still within the repo's own "flat list works" band of roughly 10-50 skills.
- Strong scale playbook: `progressive-disclosure-research.md` directly addresses 100+ skill libraries, false positives, memory overhead, hierarchical categories, registry files, search tools, analytics, deprecation, and usage-based pruning.
- Memory-backed routing pattern: updating the Letta `skills` memory block during task execution is a useful model for keeping skill context small without losing discoverability.
- Good authoring culture: contribution docs ask for evidence, peer review, generalizability, edge cases, and validation rather than one-off prompt dumps.
- Real bundled resources: many skills include scripts and references, which moves deterministic work and long docs out of the prompt.
- Cross-host intent: the corpus is designed for Letta Code, Claude Code, Codex CLI, and other compatible agents rather than a single runtime.

## Weaknesses

- No implemented router: the repo has no loader, search API, embedding index, registry generator, category loader, or activation algorithm.
- No machine-readable registry: there is no `skills.index.json`, `CATEGORY.md`, category manifest, dependency graph, lockfile, usage telemetry, or current generated catalog.
- Routing metadata is too thin: frontmatter usually has only `name` and `description`; most skills lack `category`, `keywords`, `version`, `last_updated`, `deprecated`, `replacement`, `permissions`, `tools`, `host_compatibility`, `trust`, `source`, or `related_skills`.
- Category taxonomy is already strained: `tools/` has 31 skills, slightly over the repo's own recommended 10-30 skill category size, while subdomains such as web, productivity, media, observability, memory, and messaging are collapsed together.
- Quality tooling is not enforced: `quick_validate.py` is not wired into CI, and running it across the repo fails 11 of 42 skills because quoted names and a space-containing name violate its own hyphen-case rule.
- Docs drift: `CONTRIBUTING.md` points to `development/patterns/skill-creator/SKILL.md` and an `ai/development/design/operations` hierarchy, while the repo actually uses `meta/skill-development` and `letta/tools/meta`.
- Security/governance is underspecified: skills can recommend installs, network calls, API tokens, `curl | sh`, screenshots, local files, or external CLIs without a shared permission manifest or trust label.
- Dynamic discovery claim is host-dependent: the README says agents can dynamically discover updates and update a `skills` memory block, but this repo cannot verify or enforce that behavior.

## Ideas To Steal

- Treat skill management as a routing system with a budget, not as a larger prompt appendix.
- Keep only a compact category summary in always-on context; lazy-load category skill lists and full skill bodies.
- Model `skills` as dynamic memory: categories, current category, category skills, loaded skills, and unload lifecycle.
- Add explicit negative routing metadata: "does NOT cover", "see also", and related-skill differentiation.
- Use a generated registry file for all skill metadata while keeping human-friendly directories as source.
- Track discovery funnel metrics: query -> category -> skill loaded -> skill actually used -> task outcome.
- Require evidence strength for new skills: repeated observations, tested alternatives, tradeoffs, and "would this help another agent?" checks.
- Standardize references at scale with predictable `references/README.md`, `quick-start.md`, `common-patterns.md`, `api-reference.md`, and `troubleshooting.md`.
- Separate host-facing UI sidecars from agent-routing metadata; both are useful but they serve different selectors.
- Include a skill authoring skill in the corpus so agents can improve the system using the same progressive-disclosure conventions.

## Do Not Copy

- Do not rely on README browsing as the main discovery mechanism once the library grows past the current small corpus.
- Do not use long natural-language descriptions as the only routing key; they are expensive and become ambiguous as nearby skills accumulate.
- Do not claim dynamic discovery without a host-visible contract for when the skill index is refreshed, how memory blocks are updated, and how stale skills are removed.
- Do not keep a single broad `tools/` category as the corpus grows; it will recreate the flat-list problem inside one directory.
- Do not document validators without running them in CI and fixing existing violations.
- Do not package executable skill scripts without provenance, dependency, network, permission, and sandbox metadata.
- Do not let contribution docs drift from actual paths and taxonomy; agents follow these docs literally.

## Fit For Agentic Coding Lab

This is a strong reference for the design of a skill-management layer, but not a drop-in implementation. Agentic Coding Lab should borrow the memory-backed progressive-disclosure model and combine it with stricter machine-readable infrastructure:

- `skills.index.json` generated from each `SKILL.md`, including category, trigger summary, negative triggers, keywords, tools, permissions, source, license, last reviewed commit, maturity, and related skills.
- `CATEGORY.md` or generated category summaries with 10-30 skills per category.
- A deterministic prefilter over project scope, task type, file globs, host compatibility, and permission requirements before LLM selection.
- A small top-k shortlist exposed to the model, not every skill description.
- A validator that fails CI on frontmatter schema drift, broken links, missing licenses, unsafe scripts without permission metadata, stale sidecars, and registry mismatch.
- Usage telemetry or review logs to prune low-utility skills and catch false-positive activations.
- A memory policy for skill activation: update a bounded `skills` state block, record active skills, evict full skill text after task completion, and preserve only compact learnings.

The repo's social validation model is also worth adopting, but only as a complement to automated checks. Peer review catches bad abstractions; schema and CI catch drift.

## Reviewed Paths

- `README.md`: usage flow, repository structure, current skills list, dynamic discovery and `skills` memory block claim.
- `CONTRIBUTING.md`: contribution flow, placement guidance, PR expectations, quality standards, and docs drift against actual repo structure.
- `CULTURE.md`: community validation model, generalizability test, evidence strength vocabulary, and peer-review norms.
- `.github/workflows/letta.yml`: Letta Code action integration and absence of corpus validation workflow.
- `meta/skill-development/SKILL.md`: authoring rules, progressive-disclosure recommendation, scripts list, and skill quality checklist.
- `meta/skill-development/references/progressive-disclosure-research.md`: main routing and scale architecture source.
- `meta/skill-development/references/validation-criteria.md`: evidence requirements, memory update tradeoffs, generalizability tests, and anti-patterns.
- `meta/skill-development/references/pr-workflow.md`: PR-based review process and merge expectations.
- `meta/skill-development/scripts/init_skill.py`: generated skill template and resource directory defaults.
- `meta/skill-development/scripts/quick_validate.py`: implemented validation scope and mismatch with current corpus.
- `meta/skill-development/scripts/package_skill.py`: packaging behavior and lack of manifest/provenance handling.
- All 42 `SKILL.md` files: frontmatter inventory, description-context cost, category distribution, and validator results.
- Representative skills: `letta/agent-development`, `letta/fleet-management`, `letta/letta-filesystem-to-memfs`, `letta/compaction-prompts`, `tools/memfs-search`, `tools/github`, `tools/playwright`, `tools/pdf`, `tools/screenshot`, `tools/speech`, `tools/mcp-builder`.
- Representative `agents/openai.yaml` files under `tools/pdf` and `tools/playwright`: UI metadata sidecar shape.

## Excluded Paths

- Binary/image assets such as `.png`, `.jpg`, `.svg`, notebook templates, and office/media examples were not deeply inspected because they do not affect skill routing or governance beyond proving that assets are bundled.
- Full examples under `letta/letta-api-client/examples/` were sampled only through surrounding docs; they are SDK usage examples, not skill discovery infrastructure.
- Tool-specific implementation scripts for Discord, Datadog, slides, screenshots, Yelp, transcription, and similar integrations were not line-by-line audited because the focus was skill management/routing, not each integration's runtime correctness.
- External Letta Code runtime internals were not reviewed in this note. This review records where `letta-ai/skills` delegates behavior to the host instead of implementing it locally.
