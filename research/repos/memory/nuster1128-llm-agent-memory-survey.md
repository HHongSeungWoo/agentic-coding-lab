# nuster1128/LLM_Agent_Memory_Survey

- URL: https://github.com/nuster1128/LLM_Agent_Memory_Survey
- Category: memory
- Stars snapshot: 494 (GitHub REST API repository metadata, captured 2026-05-20)
- Reviewed commit: b2d97c3f992281c093f297b7b14263803e0b1520
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: conditional
- Verdict: Useful as a compact survey companion and taxonomy source for LLM-agent memory. The practical value is the source/form/operation/evaluation/application framing, not code. Treat it as a diagram-backed reading map: provenance is paper-level rather than entry-level, update discipline is light, the core taxonomy is locked in binary images, and there is no machine-readable bibliography, benchmark harness, schema, tests, license file, or runnable memory component.

## Why It Matters

This repo is attached to "A Survey on the Memory Mechanism of Large Language Model based Agents", first released on arXiv in April 2024 and later marked in the README as accepted by ACM Transactions on Information Systems in July 2025. It is smaller than the newer awesome lists, but it gives a clean framing for what agent memory is, why it matters, how memory is implemented, how it is evaluated, and where memory-enhanced agents appear.

For Agentic Coding Lab, its best use is conceptual. It separates memory design by source, form, operation, evaluation mode, and application domain. That helps prevent one common coding-agent mistake: treating "memory" as a single vector store rather than a lifecycle with write, manage, read, source, representation, and benchmark choices.

## What It Is

`nuster1128/LLM_Agent_Memory_Survey` is a survey companion repository. The reviewed checkout contains one short `README.md` and eight image assets. There is no package metadata, script, source code, dataset, test suite, benchmark runner, issue template, structured bibliography, or license file.

The README links the paper, records two update entries, embeds all taxonomy/application diagrams, provides a BibTeX citation, and gives contact email addresses. The meaningful content is mostly in the embedded diagrams: source taxonomy, form taxonomy, operation taxonomy, evaluation taxonomy, and application table.

## Research Themes

- Token efficiency: Moderate as survey framing, weak as artifact. The form taxonomy distinguishes full interactions, recent interactions, retrieved interactions, external knowledge, and parametric memory, which maps to token-budget decisions. The repo does not quantify context cost, compression ratio, retrieval overhead, or prompt budget.
- Context control: Good conceptual fit. The diagrams separate inside-trial memory, cross-trial memory, external knowledge, textual retrieval, buffers, tools, fine-tuning, and model editing. No runnable context assembly policy or prompt injection boundary is provided.
- Sub-agent / multi-agent: Low to moderate. Multi-agent and development-group examples appear through applications such as ChatDev and MetaGPT, but there is no shared-memory protocol, conflict handling, role scope, or concurrent-agent ownership model.
- Domain-specific workflow: Moderate. The application diagram covers role-play, social simulation, personal assistant, game/open-world, code generation, recommendation, medical, financial, and science domains. Coding-agent transfer is limited to code-generation examples and general memory lifecycle concepts.
- Error prevention: Moderate as evaluation vocabulary. The repo names direct evaluation dimensions such as coherence, rationality, result correctness, reference accuracy, and time/hardware cost, plus indirect evaluation through conversation, multi-source QA, and long-context applications. It does not include failure taxonomies, stale-memory tests, hallucination checks, or reproducible eval scripts.
- Self-learning / memory: Strong as a taxonomy source. The README frames memory as central to self-evolution through experience accumulation, environment exploration, and knowledge abstraction. The operation taxonomy names writing, reading, merging, reflection, and forgetting.
- Popular skills: No skill pack or usage telemetry exists. Reusable patterns are survey-to-rubric skills: classify memory source, choose representation, define write/manage/read operations, and require direct plus indirect evaluation evidence before adoption.

## Core Execution Path

There is no runtime execution path. The repository works as a static survey page:

1. Reader opens `README.md`.
2. README introduces LLM-agent memory and links arXiv paper `2404.13501`.
3. Reader follows embedded diagrams for what memory is, why agents need it, implementation choices, evaluation choices, and application areas.
4. Reader cites the paper or contacts authors.

The research execution path for Lab should be different: use this repo to define a memory-review rubric, then deep-review individual systems or papers before adopting any mechanism.

## Architecture

The architecture is a README plus binary diagrams:

- `README.md`: 98-line entrypoint with abstract, update log, table of contents, section prose, image embeds, citation, acknowledgement, and contact.
- `assets/abstract.png`: visual overview of memory-enhanced agents across role-play, open-world games, code generation, social simulation, personal assistants, recommendation, finance, and medicine.
- `assets/what.png`: example-driven diagram of inside-trial and cross-trial memory in agent self-evolution.
- `assets/how.png`: high-level implementation diagram with memory sources, forms, and operations.
- `assets/memory_source.png`: table classifying surveyed systems by inside-trial information, cross-trial information, and external knowledge.
- `assets/memory_form.png`: table classifying surveyed systems by textual forms such as concatenation, buffer, retrieval, and tool use, plus parametric forms such as fine-tuning and model editing.
- `assets/memory_operation.png`: table classifying surveyed systems by writing, merging, reflection, forgetting, and reading.
- `assets/evaluation.png`: direct and indirect memory evaluation dimensions.
- `assets/application.png`: application-domain table mapping domains to representative systems.

The repo has no structured data layer. All model classifications and citation numbers are embedded in flattened JPEG/PNG image files, so automated agents cannot reliably query, diff, validate, or extend the taxonomy.

## Design Choices

The repo uses a paper-first static companion design rather than an awesome list or code artifact. That keeps the surface small and readable, but the useful survey tables are not in Markdown, BibTeX, CSV, JSON, YAML, or LaTeX source.

The main taxonomy is multi-axis:

- Source: inside-trial information, cross-trial information, external knowledge.
- Form: textual memory, external storage/API retrieval, tool-mediated memory, fine-tuning, model editing.
- Operation: writing, reading, merging, reflection, forgetting.
- Evaluation: subjective direct, objective direct, and indirect task evaluation.
- Application: role-play, social simulation, personal assistant, game/open-world, code generation, recommendation, medicine, finance, and science.

The design centers memory as part of self-evolution rather than only personalization. That is useful for coding agents because failures, commands, patches, test outcomes, and review feedback are all experience traces that can improve future behavior.

The repo chooses diagrams over normalized records. This helps human scanning and paper presentation, but weakens provenance and reuse. For example, model rows in the diagrams cite numeric references, but the repository does not include the bibliography table behind those numbers.

Update discipline is light. Git history has 15 commits, mostly in April 2024, one image update on 2024-04-26, and one README update on 2025-07-28 adding acceptance information. Commit messages are generic. There is no CI, contribution guide, link checker, generated badge, schema validation, or release tagging.

## Strengths

The taxonomy is compact and easy to transfer into a review rubric. Source, form, operation, evaluation, and application are the right axes for comparing memory mechanisms.

The operation split is especially useful. Writing, reading, merging, reflection, and forgetting map directly to coding-agent memory concerns: what gets saved, how it is recalled, how duplicate lessons are merged, how failures become rules, and when stale facts expire.

The evaluation diagram avoids a purely benchmark-name view. It distinguishes coherence/rationality, result correctness/reference accuracy, cost, and downstream task performance. That is a good starting point for Lab memory eval design.

The application table includes code generation alongside role-play, games, assistants, recommendation, medical, financial, and science agents, so it makes coding-agent memory one concrete domain rather than an afterthought.

The repository is small enough to audit fully. There are no hidden dependencies, generated docs, vendored code, or large source trees.

## Weaknesses

Machine-readability is the main weakness. The most useful tables are binary image assets with text and citation numbers embedded in pixels. Agents cannot reliably parse model coverage, update rows, count categories, or generate diffs.

Provenance is shallow at the repository level. The README links the arXiv paper and DOI announcement, but it does not include the paper bibliography, per-system URLs, code links, venues, benchmark names, inclusion criteria, or review dates for the systems shown in the tables.

The repo is not an implementation. There is no memory store, retrieval policy, API, MCP tool, hook, benchmark runner, or sample agent to inspect.

Update discipline appears mostly static after paper release. The only post-2024 content update visible in HEAD is acceptance information added in July 2025; the repository metadata shows latest push on 2025-07-28. It is not a living survey with current 2026 memory systems.

No license file is present, and GitHub API metadata reports `license: null`. That limits direct reuse of images or README content without separate permission checking.

The evaluation taxonomy is high-level. It names quality and cost dimensions, but does not specify datasets, metrics, gold labels, ablations, memory freshness tests, privacy tests, or stale-memory invalidation scenarios.

Security, privacy, retention, and redaction are not first-class in the repo. Those are required for coding-agent memory because sessions can contain secrets, proprietary code, user preferences, and incorrect inferred facts.

## Ideas To Steal

Use the five-axis rubric as required metadata for any Lab memory feature: source, form, operation, evaluation mode, and application/workflow.

Separate memory sources in coding-agent design:

- Inside-trial memory: current task state, selected files, hypotheses, recent commands, test output, and patch intent.
- Cross-trial memory: verified lessons from prior tasks, repo conventions, recurring failures, preferred tools, and review feedback.
- External knowledge: docs, issue trackers, API references, package docs, and web research with capture date.

Map memory forms to risk levels. Textual explicit memory is easiest to inspect and delete. Retrieval buffers need scoping and ranking. Tool-mediated memory needs permission boundaries. Fine-tuning and model editing should stay research-only for Lab until reversibility and privacy are solved.

Make operation coverage explicit. A memory system is incomplete if it can write and read but cannot merge duplicates, reflect into durable lessons, forget stale facts, or expose why a memory was recalled.

Adapt the evaluation split. Direct coding-agent memory evals should test recall correctness, source attribution, stale-memory rejection, and cost. Indirect evals should measure task success on debugging, multi-session feature work, code review preference retention, and long-horizon repo navigation.

Use the application table as a reminder that coding-agent memory is domain-specific. A code-generation memory should understand files, symbols, commands, dependencies, test failures, reviews, and branches, not only user preference snippets.

## Do Not Copy

Do not use binary diagrams as canonical research data. Convert taxonomy and system rows into Markdown tables or structured records before using them in Lab workflows.

Do not adopt the paper's model classifications without reading the underlying papers. The diagrams provide citation numbers but not enough evidence, links, or context to validate each categorization.

Do not treat source, form, and operation axes as independent checkboxes. A coding-agent design must connect them into a policy: which event source is eligible, which form stores it, which operation mutates it, and which eval proves it helps.

Do not copy parametric memory or model editing into a coding-agent memory layer. They are hard to inspect, scope, roll back, and delete compared with explicit local memory records.

Do not omit governance. Lab memory needs scope, evidence paths, confidence, retention, redaction, deletion, and contradiction handling; this repo does not cover those enough.

Do not rely on this repo as a current candidate list. It reflects the survey snapshot and a small later README update, not the fast-moving 2026 memory-tool landscape.

## Fit For Agentic Coding Lab

Fit is conditional. The repo belongs in `memory` because it gives a clean survey taxonomy, but it should not be adopted as a dependency or operational source.

The best transfer is a memory design checklist for Agentic Coding Lab:

- `source`: inside-trial, cross-trial, external.
- `form`: explicit text, retrieval index, tool/API backed, parametric, model edited.
- `operation`: write, read, merge, reflect, forget.
- `evaluation`: direct recall/quality/cost tests and indirect coding-task tests.
- `domain`: coding-agent workflow type.

For near-term Lab design, the repo supports a conservative memory architecture: keep explicit, scoped, inspectable records; write only selected evidence-backed facts or lessons; retrieve with repo/task/user scope; merge duplicates; expire stale environment facts; and evaluate through concrete coding tasks rather than generic conversation quality.

## Reviewed Paths

- `/tmp/myagents-research/nuster1128-llm-agent-memory-survey/README.md`: primary entrypoint, abstract, update log, taxonomy embeds, paper link, TOIS acceptance note, citation, and contact.
- `/tmp/myagents-research/nuster1128-llm-agent-memory-survey/assets/abstract.png`: reviewed visually for application overview and high-level memory-plus-LLM framing.
- `/tmp/myagents-research/nuster1128-llm-agent-memory-survey/assets/what.png`: reviewed visually for inside-trial/cross-trial memory example and self-evolution framing.
- `/tmp/myagents-research/nuster1128-llm-agent-memory-survey/assets/how.png`: reviewed visually for memory source, form, and operation taxonomy.
- `/tmp/myagents-research/nuster1128-llm-agent-memory-survey/assets/memory_source.png`: reviewed visually for source taxonomy table.
- `/tmp/myagents-research/nuster1128-llm-agent-memory-survey/assets/memory_form.png`: reviewed visually for textual and parametric memory form taxonomy table.
- `/tmp/myagents-research/nuster1128-llm-agent-memory-survey/assets/memory_operation.png`: reviewed visually for write/manage/read taxonomy table.
- `/tmp/myagents-research/nuster1128-llm-agent-memory-survey/assets/evaluation.png`: reviewed visually for direct and indirect evaluation taxonomy.
- `/tmp/myagents-research/nuster1128-llm-agent-memory-survey/assets/application.png`: reviewed visually for memory-enhanced application-domain table, including code generation.
- Git metadata via `git rev-parse`, `git show`, `git log`, `git shortlog`, `git ls-files`, and `git ls-tree`: reviewed exact commit, authorship, update cadence, file inventory, and tracked asset sizes.
- `https://api.github.com/repos/nuster1128/LLM_Agent_Memory_Survey`: GitHub REST API metadata for stars, forks, license absence, default branch, pushed timestamp, and repository dates.
- `https://export.arxiv.org/api/query?id_list=2404.13501`: arXiv metadata for paper title, authors, publication date, summary, and arXiv identifier.

## Excluded Paths

- `/tmp/myagents-research/nuster1128-llm-agent-memory-survey/.git/`: excluded as VCS internals; used only through Git commands for provenance.
- `/tmp/myagents-research/nuster1128-llm-agent-memory-survey/assets/*.png`: binary images were reviewed visually because they are the core survey artifacts, but excluded from code/runtime/machine-readable analysis because they contain no executable logic or structured source data.
- Generated source paths: none present in the reviewed checkout.
- Vendored dependency paths: none present in the reviewed checkout.
- UI-only application paths: none present in the reviewed checkout.
- Scripts: none present in the reviewed checkout.
