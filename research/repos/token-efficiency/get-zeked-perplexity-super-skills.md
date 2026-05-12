# get-zeked/perplexity-super-skills

- URL: https://github.com/get-zeked/perplexity-super-skills
- Category: token-efficiency
- Stars snapshot: 156 (GitHub REST API, captured 2026-05-12)
- Reviewed commit: a64366047bb707541e1656f3215361120c7b5ead
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: conditional
- Verdict: Useful as a catalog and packaging reference for Perplexity-style `SKILL.md` prompt packs, with the strongest direct value in the linked `token-efficient`, `research-knowledge`, `ai-agent`, `dev-engineering`, and `agent-security` skills. The hub repo itself is README-only, so it is not a complete installable skill bundle or executable system.

## Why It Matters

This repo matters because it is a compact registry of agent skills that tries to merge Perplexity Computer workflows with Claude Code-style operating discipline. For Agentic Coding Lab, the useful parts are not runtime compression algorithms; they are reusable prompt-pack patterns for cutting response waste, controlling context intake, splitting research work across agents, packaging skills as portable `SKILL.md` files, and making coding agents verify work before claiming completion.

## What It Is

`perplexity-super-skills` is a hub README that links to 12 separate skill repos. The collection covers AI agents, development, marketing, sales, finance, legal, product, operations, research, content, agent security, and token efficiency. The primary repo contains only `README.md`; it does not vendor the linked `SKILL.md` files.

The linked skills follow a simple distribution model: one human README plus one canonical `SKILL.md`. The hub tells users to download or copy each child repo's `SKILL.md`, upload it into Perplexity Computer, or paste it into another agent as system context or project rules. This is closer to a curated skill catalog than a framework.

## Research Themes

- Token efficiency: The linked `token-efficient` skill is a small always-on behavior overlay. It targets output waste: sycophantic openers, narrated tool calls, redundant post-action summaries, unnecessary caveats, decorative formatting, tiny todo lists, and over-delegation to subagents. It does not compress input context or tool output.
- Context control: The sampled skills use routing tables, "when to use" sections, source quality tiers, RAG faithfulness checks, memory provenance tags, trust-aware retrieval, TTLs, and quarantine protocols. These are practical controls for deciding what enters context and what can influence action.
- Sub-agent / multi-agent: The research and AI-agent skills define orchestrator/subagent patterns, unique output files per worker, master-only synthesis, self-contained task prompts, conflict checks, and two-stage review with spec compliance before code quality.
- Domain-specific workflow: The collection packages broad functional workflows as monolithic domain manuals. Some are directly useful for coding agents, especially AI Agent Builder, Dev & Engineering, Research & Knowledge, Agent Security, and Token Efficient. Business-domain skills are less relevant to this category.
- Error prevention: The Dev & Engineering skill imports strict TDD, systematic debugging, code review thresholds, CI/CD gates, and security checks. The Agent Security skill adds pre-install audits, permission analysis, prompt-injection screening, and data-exfiltration checks.
- Self-learning / memory: Research continuity is handled by searching prior memory, reading workspace files, date-stamping facts, and maintaining a research index. Security guidance adds provenance, sanitization before retrieval, quarantine, audit cadence, and short TTLs for untrusted memory.
- Popular skills: Most applicable to Agentic Coding Lab are `token-efficient`, `research-knowledge-super-skill`, `ai-agent-super-skill`, `dev-engineering-super-skill`, and `agent-security-super-skill`.

## Core Execution Path

The hub execution path is manual:

1. User selects a row from the hub README table.
2. User opens the linked child repo.
3. User downloads or copies `SKILL.md`.
4. User uploads it to Perplexity Computer or pastes it into another agent's instruction system.
5. The target agent loads the skill based on YAML frontmatter and natural-language trigger description.

There is no loader, registry API, command runner, test harness, or local validation in the hub repo. Actual behavior comes from the child `SKILL.md` files. The sampled child repos mostly encode workflows as markdown sections, checklists, prompt templates, shell examples, Python snippets, and decision tables. Many referenced `scripts/...` commands are illustrative patterns; the scripts are not shipped in the sampled child repos.

For token efficiency, the direct path is simpler: install the linked `token-efficient/SKILL.md`; it tells the agent to answer first, avoid tool-use narration, skip redundant summaries, avoid small todo lists, and use coding/research/automation profiles.

## Architecture

The primary repo architecture is:

- `README.md`: collection table, install methods, usage guidance for Perplexity Computer and other agents, and a generic skill architecture diagram.
- `.git/`: VCS metadata, excluded from review content.

The README describes a common super-skill shape:

- gap analysis;
- domain sections;
- workflows;
- templates;
- decision trees;
- quality checks;
- integration points.

The sampled child repos implement that shape as `README.md` plus `SKILL.md`:

- `token-efficient`: 109-line `SKILL.md`; deliberately small, behavior-only overlay.
- `research-knowledge-super-skill`: 2,087-line `SKILL.md`; deep research, RAG, knowledge graph, source quality, templates, and memory continuity.
- `ai-agent-super-skill`: broad agent architecture manual; ReAct, Plan-Execute, Reflexion, MCP, RAG, subagents, prompt optimization, skill packaging, backend memory, deployment.
- `dev-engineering-super-skill`: broad coding-agent manual; architecture, frontend, backend, TDD, debugging, review, DevOps, security, data, docs.
- `agent-security-super-skill`: defensive agent-security manual; skill/plugin validation, prompt injection, memory poisoning, permissions, tool safety, incident response.

The architecture favors copy-paste portability over composable loading. It is easy to distribute, but expensive to load if an agent ingests entire broad skills for narrow tasks.

## Design Choices

The strongest design choice is the "single canonical `SKILL.md`" package. It makes installation simple and auditable, and the frontmatter description doubles as the trigger spec.

The collection uses progressive disclosure inside large files through tables of contents, quick-reference cards, section-level "when to use" notes, and decision trees. This helps humans skim, but it is not true agent-side progressive loading because the whole file may still enter context.

The `token-efficient` child skill chooses a small always-loaded profile instead of a huge manual. That is the best token-efficiency pattern in the collection: a short behavior overlay with universal, coding, research, and automation profiles.

The research and AI-agent skills make subagent prompts self-contained. They explicitly tell implementers not to read plan files because the controller should inject full task text. This is a strong context-control pattern: fewer redundant file reads and less accidental plan drift.

The research skill's parallelization rule is also good: each subagent writes to a unique file, includes source URLs for every fact, and the master synthesizes only after all research files exist. That maps well to multi-agent research without overwrite risk.

The security skill treats external content, memories, tool descriptions, and MCP configs as potential instruction sources. It uses provenance tags, trust-aware retrieval, and "data not instructions" rules. This is directly applicable to coding agents that read web pages, issues, logs, docs, or tool outputs.

## Strengths

- Very low install friction: README table plus one `SKILL.md` per child repo.
- Clear trigger descriptions in frontmatter, especially in the sampled child skills.
- Strong behavior-level token-efficiency defaults in `token-efficient`.
- Good reusable research workflow: tier the question, run parallel searches, fetch primary sources, build a claims registry, and rate confidence.
- Good multi-agent guardrails: unique output files, no same-file parallel writes, master-only synthesis, and conflict detection.
- Good coding-agent discipline in sampled skills: TDD, root-cause debugging, spec review before quality review, verification reporting, and code review thresholds.
- Strong context-safety patterns: memory provenance, memory sanitization, pre-install audits, least privilege, URL validation, and exfiltration checks.
- Useful skill-authoring guidance: frontmatter requirements, trigger design, optional `examples/`, `templates/`, and `scripts/` directories.

## Weaknesses

- The reviewed repo is only a hub README; it does not contain the actual skill files it advertises.
- No machine-readable manifest pins child repo names, commits, checksums, categories, or compatibility.
- The README table says 12 skills, but the clone instructions still say "all 10 skills locally"; packaging docs are slightly stale.
- Several child skills are huge monolithic prompt packs. Loading 2,000+ lines to answer a narrow task undermines the token-efficiency goal.
- Referenced helper scripts such as `prompt_optimizer.py`, `rag_evaluator.py`, `project_scaffolder.py`, and `code_quality_checker.py` are not present in the sampled child repos; they function as examples, not runnable assets.
- No automated validation, tests, CI, or `agentskills validate` output is stored in the hub.
- No measured token savings, latency savings, quality deltas, or eval results are provided.
- The broad domain skills mix durable agent patterns with platform-specific Perplexity Computer assumptions, so direct Codex reuse needs adaptation.

## Ideas To Steal

- Build a small always-loaded token-efficiency overlay, separate from large domain manuals.
- Use `description` frontmatter as a real trigger contract: explicit intent, positive cases, and when not to load.
- Store broad skills as a routing `SKILL.md` plus separate reference files, rather than forcing every section into the hot context.
- Require subagent task prompts to include full task text, explicit scope, explicit exclusions, protected files, and required verification output.
- Use unique filenames for parallel research agents and have the controller synthesize only after all worker artifacts exist.
- Add a claims registry to research notes: claim, source, authority tier, date, confidence, and caveat.
- Add memory provenance metadata: source, trust level, source URL, creation time, expiry, session, user, and verification status.
- Apply a memory sanitization wrapper before injecting retrieved memories into context.
- Gate prompt optimization on both quality and cost, not quality alone.
- Add skill supply-chain review before installing third-party skills: publisher identity, permissions, hidden instructions, obfuscation, dependency risk, sandbox test.

## Do Not Copy

- Do not copy the hub-only packaging model without a pinned manifest. A useful collection should pin child commits and hashes.
- Do not load 2,000-line domain skills by default. Convert them into progressive references or smaller skills with a router.
- Do not cite helper commands unless the scripts actually ship or the note labels them as pseudocode.
- Do not rely on README marketing for scope; inspect canonical `SKILL.md` content.
- Do not import platform-specific tool names directly into Codex instructions without mapping them to local tools.
- Do not ask for hidden chain-of-thought style output in modern coding agents; prefer concise reasoning summaries, plans, verification records, and structured artifacts.
- Do not treat third-party skills as safe because they are markdown. The Agent Security skill's own audit checklist is worth applying before installation.

## Fit For Agentic Coding Lab

Fit is conditional but useful. The candidate is not a token compression library and not a runnable workflow system. It is a prompt-pack catalog with several strong patterns for agent operating discipline.

Best adoption path for Agentic Coding Lab:

- Use `token-efficient` as inspiration for a small response-style skill that avoids narrated tool use and redundant summaries.
- Use `research-knowledge` patterns for repo and paper review notes: tiered research, primary-source preference, claims registry, confidence rating, and source dates.
- Use `ai-agent` subagent prompts for self-contained task dispatch and staged review.
- Use `agent-security` memory and tool-safety patterns for context-control research and future skill-installation workflows.
- Repackage large child skills into smaller modules with progressive loading, local validation, and pinned provenance.

The hub itself should remain a reference, not a dependency.

## Reviewed Paths

- `/tmp/myagents-research/get-zeked-perplexity-super-skills/README.md` at `a64366047bb707541e1656f3215361120c7b5ead`: primary hub README, collection table, import methods, generic architecture.
- `/tmp/myagents-research/get-zeked-token-efficient/README.md` and `SKILL.md` at `fefc30604ca7eae5a09fb253ade608b1e24a5dbd`: token-efficiency behavior overlay, profiles, anti-pattern table.
- `/tmp/myagents-research/get-zeked-research-knowledge-super-skill/README.md` and `SKILL.md` at `e834639fdfb8af57bb4aa19bc072f147aa9f5024`: research workflow, subagent research, RAG, source quality, memory continuity, templates.
- `/tmp/myagents-research/get-zeked-ai-agent-super-skill/README.md` and `SKILL.md` at `5757ead2e25398c4d7d10bc0dc020db5cee673c6`: agent architecture, MCP, RAG, subagent prompts, verification, prompt optimization, skill packaging.
- `/tmp/myagents-research/get-zeked-dev-engineering-super-skill/README.md` and `SKILL.md` at `d690cbb5742baae0a36805134b7483da6e8824d0`: TDD, systematic debugging, code review, engineering workflow combinations.
- `/tmp/myagents-research/get-zeked-agent-security-super-skill/README.md` and `SKILL.md` at `99f905627bda383fbfc87c137697750e0362dd65`: skill validation, MCP checks, memory poisoning prevention, permission and tool safety.
- `research/templates/repo-note.md`: local note template used for this review.
- `research/index.md`: read-only check confirmed the candidate row exists; not edited because the user explicitly prohibited index edits.

## Excluded Paths

- `.git/` directories in the primary and sampled clones: VCS metadata, not research content.
- Generated paths: none found in the primary repo or sampled child repo file lists.
- Vendored paths: none found in the primary repo or sampled child repo file lists.
- Binary paths: none found in the primary repo or sampled child repo file lists.
- UI-only paths: none found in the primary repo or sampled child repo file lists.
- `skills/`, `commands/`, `templates/`, and `examples/` directories in the primary repo: not present. Template and example material exists only inside the README and sampled `SKILL.md` files.
- Linked business-domain child repos not sampled deeply: `marketing-super-skill`, `sales-super-skill`, `finance-super-skill`, `legal-super-skill`, `pm-super-skill`, `operations-cx-super-skill`, and `content-creative-super-skill`. Rationale: they are domain workflow packs, less relevant to the assigned token-efficiency, research-agent, context-control, and coding-agent focus.
- Remaining child repo content outside the sampled files: not reviewed because the package pattern was confirmed from file lists and the canonical behavior is in `SKILL.md`.
