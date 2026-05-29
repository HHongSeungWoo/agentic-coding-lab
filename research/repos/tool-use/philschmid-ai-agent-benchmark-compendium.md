# philschmid/ai-agent-benchmark-compendium

- URL: https://github.com/philschmid/ai-agent-benchmark-compendium
- Category: tool-use
- Stars snapshot: 151 (GitHub REST repository endpoint, captured 2026-05-29)
- Reviewed commit: 2401142c9923735261e5f6ff7c29f1fcfb7d2e81
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: conditional
- Verdict: Useful benchmark-discovery map for tool-use, function-calling, coding, and GUI/web agent evaluations. Conditional fit because the repo is a single Markdown compendium with no selection rubric, machine-readable metadata, link checker, reproducibility harness, or benchmark execution path.

## Why It Matters

Agentic Coding Lab needs a practical benchmark-selection map before it needs another ad hoc leaderboard. This repo is useful because it puts several important tool-use and coding-agent benchmarks in one small, readable place: BFCL, ToolBench, ComplexFuncBench, Tau-Bench, API-Bank, HammerBench, LiveMCPBench, MCP-Universe, SWE-bench variants, Aider benchmarks, WebArena, OSWorld, AndroidWorld, OfficeBench, and related assistant/web benchmarks.

Its value is breadth and vocabulary, not authority. The current README has exactly 50 benchmark entries across four categories: 13 under Function Calling & Tool Use, 11 under General Assistant & Reasoning, 7 under Coding & Software Engineering, and 19 under Computer Interaction (GUI & Web). For Lab benchmark selection, that makes it a good triage seed for deciding which benchmark families deserve deeper review.

## What It Is

`ai-agent-benchmark-compendium` is a Markdown-only compendium of AI-agent benchmarks. The reviewed checkout tracks only `README.md`; there is no package manifest, license file, schema, CI workflow, generated site, crawler, link checker, data export, test suite, or executable benchmark wrapper.

Each benchmark entry follows a loose human-readable pattern: a heading, a short prose description, and one `Links:` line with some mix of paper, GitHub, leaderboard, dataset, or blog links. The repository description on GitHub matches this purpose: a categorized compendium covering Function Calling & Tool Use, General Assistant & Reasoning, Coding & Software Engineering, and Computer Interaction.

GitHub metadata at review time reported 151 stars, 15 forks, 6 open issues or pull requests, default branch `main`, no detected primary language, no topics, and no license. The repository was created on 2025-10-15, last pushed on 2025-10-15, and had later GitHub activity through open submissions.

## Research Themes

- Token efficiency: Indirect. Some linked benchmarks involve long-context or contamination-aware evaluation, such as ComplexFuncBench and LiveBench, but the repo itself does not measure token cost, tool-spec compression, context packing, trace compaction, or benchmark prompt size.
- Context control: Moderate as a map. The categories separate function/tool use, reasoning, coding, and GUI/web interaction, which helps route benchmarks by context surface. There is no metadata for task horizon, tool count, context length, external state, multimodal inputs, or hidden/private test separation.
- Sub-agent / multi-agent: Weak. Some linked benchmarks touch multi-agent or agentic systems indirectly, and open issues request multi-agent additions, but the README has no explicit multi-agent taxonomy, collaboration metrics, delegation dimensions, or worker-isolation concerns.
- Domain-specific workflow: Strong as candidate discovery. It covers API use, mobile assistants, MCP servers, coding patches, web browsing, desktop/mobile GUI, office workflows, and embodied tasks. It does not normalize domains or map them to Lab-owned benchmark needs.
- Error prevention: Indirect. Safety and policy benchmarks such as FORTRESS, MASK, ST-WebAgentBench, and some web/GUI benchmarks are listed, but there is no local analysis of sandboxing, permissioning, destructive actions, prompt injection, rollback, or evaluator leakage.
- Self-learning / memory: Minimal. BFCL is described as touching memory in stateful multi-step environments, but the compendium has no durable memory taxonomy, longitudinal eval criteria, or learning-from-runs harness.
- Popular skills: Benchmark taxonomy, function-calling benchmark selection, MCP benchmark discovery, coding-agent evaluation selection, GUI/web benchmark selection, and manual curation of links to papers, leaderboards, repos, and datasets.

## Core Execution Path

There is no software execution path. The real workflow is manual curation and manual consumption:

1. A maintainer or contributor edits `README.md` directly.
2. Entries are grouped under one of four top-level benchmark categories.
3. Each entry gets a one-paragraph summary and a hand-written link list.
4. Readers browse or search the README, then leave the repo to inspect the linked benchmark paper, code, leaderboard, or dataset.
5. Proposed additions arrive through GitHub issues or pull requests.

For Agentic Coding Lab, the expected execution path should be: use this repo to discover candidate benchmark families, then separately deep-review each linked benchmark's source code, dataset license, evaluator, sandbox model, contamination controls, and maintenance state.

## Architecture

The architecture is one `README.md` file of 319 lines. It contains:

- Four category sections: Function Calling & Tool Use, General Assistant & Reasoning, Coding & Software Engineering, and Computer Interaction (GUI & Web).
- 50 benchmark subsections marked with `###`.
- 50 `Links:` lines.
- 43 entries with a `Paper` link, counting paper-like external sources.
- 43 entries with a `GitHub` label, though a few labels point to project websites or nested repository paths rather than a clean repo root.
- 26 entries with a `Leaderboard` link.
- 19 entries with a `Dataset` link.

Git history is also minimal. The reviewed branch has five commits by one author. The main content landed in two large README updates on 2025-10-15, followed by a title/repository-link cleanup and a clarity refactor. There are no tags or releases.

The open issue/PR queue is the only visible curation pipeline. At review time it included requests for MCPMark, OMATS, MEEET World, ClawBench, GameDevBench, and AWB. That is useful as a discovery signal but not a reviewed backlog because there are no labels, templates, status fields, or acceptance criteria.

## Design Choices

The main design choice is category-first navigation. Function Calling & Tool Use is separated from Coding & Software Engineering and GUI/Web, which is helpful because a Lab benchmark may need to test different surfaces: schema-valid function calls, stateful API workflows, patch generation, browser interaction, desktop automation, or mobile control.

The first category is the strongest for this `tool-use` review. It spans single-turn function calling, serial/parallel/multi-turn calling, REST API use, policy-governed conversational API tasks, mobile-assistant calls, Pythonic function calling, nested calls, tool-learning data generation, MCP-scale tool navigation, and real MCP server interaction.

The coding section is smaller but high-value for Lab selection because it includes SWE-bench, SWE-bench Verified, SWE-bench Pro, LiveCodeBench, SWE-PolyBench, and Aider benchmarks. Those entries shift evaluation from generic tool calls toward real repository edits, tests, refactoring, self-repair, and multi-language issue resolution.

The README favors short prose over structured data. This makes it easy to skim but hard to query. Benchmark size, task count, modality, task source, execution environment, evaluator type, license, dataset availability, private-test policy, contamination control, maintenance status, and cost profile are not captured consistently.

## Strengths

The benchmark coverage is broad for such a small repo. It includes core function-calling leaderboards, API/task-world benchmarks, MCP-specific benchmarks, coding-agent benchmarks, live web/browser benchmarks, desktop/mobile GUI benchmarks, and factuality/reasoning benchmarks that often appear in agent-evaluation discussions.

The Function Calling & Tool Use section is especially relevant. It does not stop at "valid JSON"; it includes parallel calls, multi-turn calls, nested calls, user constraints, long parameter values, REST APIs, policy-following API workflows, mobile assistant interactions, Pythonic calls, tool-learning data, and MCP toolsets.

The README gives every entry at least one outward link. Most entries have enough paper/code/leaderboard/dataset pointers to start a proper deep review without doing broad search first.

The category split is practical for Lab planning. It suggests that one evaluation suite should not collapse tool-use, coding patches, GUI operation, web browsing, safety, and factuality into a single score.

The open submission queue is useful signal. Multiple outside contributors proposed newer benchmarks after the initial README snapshot, which means the repo can surface emerging benchmark names even when those additions are not yet merged.

The repo is small and transparent. There are no generated artifacts, vendored dependencies, binary assets, or hidden runtime behavior to audit.

## Weaknesses

Fit is conditional because the repo is a curated list, not a benchmark, framework, registry, or evaluation harness. It cannot execute tasks, score agents, pin datasets, validate links, or reproduce any leaderboard result.

Selection criteria are implicit. The README does not state what qualifies as "modern," "agentic," "benchmark," or "in category"; it does not record why a benchmark was included, rejected, or placed in one category instead of another.

Metadata quality is inconsistent. Some entries include task counts, domains, datasets, leaderboards, or GitHub repos; others have only a paper or blog. Link labels are not always clean enough for automated ingestion, and there is no canonical record of benchmark version, release date, license, evaluator style, private-test availability, or last-verified date.

Reproducibility is weak. The repo has no CI, no link checker, no checksum or dataset pinning, no benchmark runner, no schema, no lockfile, and no captured leaderboard snapshots. Reproducing any claim requires leaving the repo and reviewing the linked source independently.

Maintenance is lightweight. The reviewed branch had only five commits, no releases, no tags, one tracked file, no license, and six open submissions with no labeling or visible triage process.

The category taxonomy is useful but shallow. It does not distinguish static function-call syntax from host-side execution, simulated tools from real APIs, deterministic tasks from live-web tasks, public tests from hidden tests, or benchmark-as-dataset from benchmark-as-runtime.

It includes benchmarks outside the narrow coding-agent tool-use scope. General factuality, honesty, national-security safety, embodied tasks, and broad reasoning benchmarks may be useful context, but they require filtering before becoming Lab priorities.

## Ideas To Steal

Build a Lab benchmark registry around the same top-level split, but make it structured: function/tool use, coding/software engineering, GUI/web/computer interaction, reasoning/factuality, safety/policy, and multi-agent collaboration.

Use the Function Calling & Tool Use entries as a first review queue: BFCL for function-call format breadth, ComplexFuncBench for hard call arguments and long context, Tau-Bench for policy-following API workflows, API-Bank and ToolBench for API retrieval/execution, HammerBench for mobile assistant interactions, and MCP-Universe or LiveMCPBench for MCP-scale tool environments.

For every benchmark candidate, record normalized fields: task count, domains, modality, tool surface, execution environment, evaluator type, public/private split, dataset license, code license, leaderboard URL, dataset URL, last verified date, setup burden, model API requirements, sandbox assumptions, contamination controls, and relevance to coding agents.

Keep the human-readable compendium, but generate it from a machine-readable source. Markdown should be the view, not the canonical database.

Use open submissions as an "incoming benchmark radar" but gate them with acceptance criteria: working code, accessible data, clear scoring, license, reproducible setup, recent maintenance, and relevance to Lab objectives.

Separate benchmark families by what they actually test: tool-call syntax, tool selection, argument reasoning, tool retrieval, stateful tool execution, policy compliance, final artifact correctness, GUI control, web browsing, multi-agent coordination, safety, and cost discipline.

Add a selection rubric for Agentic Coding Lab benchmark adoption: high signal for coding-agent behavior, reproducible locally or in controlled infrastructure, inspectable evaluator, stable dataset, low leakage risk, manageable cost, and clear failure taxonomy.

## Do Not Copy

Do not use a free-form Markdown list as the canonical benchmark index for Lab operations.

Do not treat inclusion in the compendium as evidence of benchmark quality, reproducibility, current maintenance, or safety.

Do not collapse all listed benchmarks into one comparison table without normalizing modality, task horizon, tool availability, hidden tests, evaluator type, and cost.

Do not rely on link labels alone. Some links are project pages, nested repo paths, blog posts, spreadsheets, or shortlinks rather than durable source roots.

Do not adopt the "PRs or issues welcome" process without templates, criteria, status labels, and verification requirements.

Do not recommend a benchmark for implementation from this repo alone. Each benchmark needs a separate source review before it can be added to Lab's evaluation stack.

Do not copy entries blindly into a machine registry. Current descriptions mix benchmark claims, dataset counts, model-family notes, and one-line summaries with no provenance per field.

## Fit For Agentic Coding Lab

Conditional fit as a discovery index. It is worth keeping in the research index because it compresses a large benchmark landscape into a short map and highlights several tool-use/function-calling benchmarks that should be individually reviewed.

It is not fit as an implementation dependency or authority. Agentic Coding Lab should use it to seed a benchmark selection backlog, then build a structured internal registry with evidence fields and per-benchmark notes.

Highest-priority follow-up candidates from this repo for Lab benchmark selection are BFCL, ComplexFuncBench, Tau-Bench, API-Bank, HammerBench, LiveMCPBench, MCP-Universe, SWE-bench Verified, SWE-PolyBench, Aider Polyglot, WebArena, OSWorld, AndroidWorld, and ST-WebAgentBench. The selection depends on whether the Lab wants to prioritize schema-valid tool calls, stateful API workflows, real repository patches, GUI/web operation, or policy/safety failures.

The strongest lesson is not a specific benchmark. It is that benchmark selection needs an explicit taxonomy and metadata model before results become comparable.

## Reviewed Paths

- `/tmp/myagents-research/philschmid-ai-agent-benchmark-compendium/README.md`: Primary artifact; reviewed all benchmark categories, entries, descriptions, links, taxonomy, and curation language.
- `/tmp/myagents-research/philschmid-ai-agent-benchmark-compendium/.git`: Used through Git commands only for reviewed commit, branch status, commit history, author count, tags, tracked files, and repository provenance.
- GitHub REST repository endpoint for `philschmid/ai-agent-benchmark-compendium`: reviewed stars, forks, open issues, license status, default branch, timestamps, topics, and repository description on 2026-05-29.
- GitHub REST issues endpoint for `philschmid/ai-agent-benchmark-compendium`: reviewed open submissions as curation/backlog evidence, not as accepted benchmark entries.
- `research/index.md`: confirmed the candidate row exists at line 289 with status `candidate`; left it unchanged per user instruction.
- `research/templates/repo-note.md` and nearby `research/repos/tool-use/*` notes: reviewed for required local note structure and style only.

## Excluded Paths

- Linked benchmark repositories, papers, datasets, spreadsheets, leaderboards, and project websites: excluded from deep review. They were treated as outbound candidates and metadata signals because this assignment was to review the compendium repository itself.
- Open pull request patches and issue bodies beyond title/body metadata: excluded from benchmark-quality conclusions because they are not merged into the reviewed commit.
- `.git/objects`, refs, and remote storage internals: excluded except through Git metadata commands.
- Build artifacts, generated files, vendored dependencies, examples, tests, schemas, package manifests, CI workflows, and licenses: none are tracked in the reviewed checkout; their absence is part of the review.
- Binary and UI-only assets: none are tracked in the reviewed checkout.
