# broalantaps/Awesome-Context-Compression-LLMs

- URL: https://github.com/broalantaps/Awesome-Context-Compression-LLMs
- Category: token-efficiency
- Stars snapshot: 72 (GitHub REST API, captured 2026-05-12)
- Reviewed commit: 69527600696dd520a5b39f40c4072968a6725343
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: conditional
- Verdict: Useful curated map for token-efficiency research, especially its split between explicit prompt/input compression, implicit latent compression, and inference-time KV cache compression. It is not an implementation reference: there are no scripts, tests, schemas, benchmarks, automation, or provenance checks. Best Agentic Coding Lab transfer is the taxonomy as a triage lens for context-control techniques, not the repository mechanics.

## Why It Matters

Coding agents spend context on three different surfaces: visible prompt tokens sent to the model, intermediate reasoning or memory representations, and provider/model-side inference state. This list is useful because it separates those surfaces instead of treating "compression" as one generic trick.

For Agentic Coding Lab, the most transferable idea is the compression-locus taxonomy. Explicit compression maps to what an agent harness can directly control: file excerpts, tool outputs, shell logs, chat history, retrieved docs, and task summaries. Implicit compression maps to learned memory vectors, gist tokens, latent reasoning, and one-token RAG schemes that usually need model training or special model interfaces. KV compression maps to runtime serving systems and is mostly unavailable when using hosted APIs, but it informs what self-hosted inference stacks can optimize.

The repo also matters as a candidate source list. It names major families and many representative papers from 2019 through 2025, including LLMLingua, Selective-Context, RECOMP, AutoCompressor, ICAE, xRAG, Coconut, StreamingLLM, H2O, SnapKV, KIVI, Quest, and surveys. That gives a practical reading queue for deeper paper notes.

## What It Is

This is an "awesome list" repository for context-compression papers. The tracked source is almost entirely `README.md`: a short introduction, a taxonomy diagram, three categorized paper tables, a survey table, minimal contribution instructions, and a star-history badge.

The reviewed README contains 49 listed resources:

- 9 explicit prompt/input-level compression entries.
- 16 implicit latent/reasoning-level compression entries.
- 19 inference-time KV cache compression entries.
- 5 survey entries.

Each paper row uses a simple table schema: paper title/link, venue or date, tags, code link, and a one-line summary. Some rows link to GitHub implementations; some have no code link. The repository has no package code, no metadata file for the list, no validation script, no CI, no generated dataset, and no evaluation harness.

## Research Themes

- Token efficiency: Primary theme. The README focuses on reducing token usage, compressing latent state, and reducing KV-cache memory. It is strongest as a navigation aid for token-saving techniques, not as direct evidence that a technique works in coding-agent settings.
- Context control: Moderate. The taxonomy gives a clean "where compression happens" model, which helps choose controls available to an agent runtime. It does not define prompt-section policies, truncation rules, safety invariants, or source-aware context routing.
- Sub-agent / multi-agent: Minimal. No multi-agent orchestration appears. The relevant transfer is indirect: subagents can be assigned different compression layers or paper families during research.
- Domain-specific workflow: Weak for implementation, moderate for research planning. The list is LLM-compression specific, but it does not specialize for coding-agent artifacts such as diffs, stack traces, tool calls, repository maps, or build logs.
- Error prevention: Weak. There are no correctness checks, no stale-link checks, no paper metadata validation, no provenance fields, and no warning that compression can corrupt code, identifiers, or tool schemas.
- Self-learning / memory: Moderate as a reading map. The implicit section includes memory slots, soft prompts, autoencoder compression, continuous reasoning, and memory augmentation papers. The repo itself has no durable memory mechanism.
- Popular skills: No skills or prompt packs. Reusable patterns are the taxonomy, paper-table schema, contribution rubric, and research backlog structure.

## Core Execution Path

There is no runtime execution path because the repo is a curated list, not software.

The practical reader path is:

1. Read the README introduction to frame context compression as input-token, latent-state, or KV-cache work.
2. Use the taxonomy tree to choose the layer relevant to the problem.
3. Scan the paper tables for title, venue/date, tags, code availability, and TL;DR.
4. Follow paper or code links for primary evidence.
5. Add new entries by forking the repo, inserting a row in the same table format, and submitting a pull request.

For Agentic Coding Lab, that maps to a research intake path rather than an agent path: use the list to select paper candidates, then review primary papers/repos before adopting any algorithm.

## Architecture

The architecture is a single Markdown knowledge artifact:

- `README.md` carries the full taxonomy, categorized tables, contribution rules, acknowledgement text, and star-history badge.
- `project.html` exists but is only a 1-byte stub, so it contributes no UI or technical design.
- `LICENSE` is MIT legal text.
- GitHub issues and pull requests provide the only contribution workflow beyond the README instructions.

The README's taxonomy is its main design surface:

- Explicit context compression: token pruning, summarization, and information-theoretic selection before or during encoding.
- Implicit context compression: soft prompts, autoencoders, memory vectors, and latent reasoning.
- Inference-time KV compression: cache eviction, quantization, sparse attention, and streaming inference.

This structure is compact and easy to scan, but it is not machine-readable. There are no required fields for date added, last verified, benchmark task, compression ratio, quality delta, license, implementation maturity, or coding-agent applicability.

## Design Choices

The best design choice is organizing by compression location. That avoids mixing together prompt compressors that an agent harness can call today, latent compressors that need trained adapters or model changes, and KV methods that usually require control over serving infrastructure.

The row schema favors fast scanning. Title, venue/date, tags, code, and one-line summary are enough to decide whether a paper deserves deeper review. The code column is useful for finding implementation candidates.

The list includes both recent and field-defining older work. The implicit section reaches back to Compressive Transformers in 2020 and memory augmentation in 2022, while the explicit and KV sections emphasize 2023-2025 papers.

The contribution process is intentionally lightweight: fork, add paper in table format, categorize it, submit PR. That lowers friction but leaves quality control mostly manual.

The repo does not expose provenance. There are no citation sources, no link-check logs, no "last verified" fields, no criteria for inclusion, no maintainer notes explaining why a row is present, and no stated process for updating venue names or paper status.

Some category boundaries blur. For example, Keyformer is listed under explicit compression even though its title and summary center on KV cache reduction. That is a small but important warning: use the taxonomy as a starting hypothesis, not final classification.

## Strengths

The taxonomy is practical. "Input, latent, KV" maps well to engineering ownership boundaries: agent runtime, model/adaptation layer, and inference server.

The paper coverage is broad for a compact list. It captures prompt pruning, RAG compression, summarization, soft prompts, memory slots, latent reasoning, streaming attention, KV eviction, quantization, sparse attention, and surveys.

The code column is useful for follow-up implementation review. It quickly points to repositories like microsoft/LLMLingua, facebookresearch/coconut, Hannibal046/xRAG, mit-han-lab/streaming-llm, FasterDecoding/SnapKV, jy-yuan/KIVI, and SqueezeAILab/KVQuant.

The README gives short definitions and keywords for each section. That makes the list more useful than a flat bibliography.

History shows some maintenance after initial publication. The repo was created in December 2025, had many README adjustments in the first week, and merged an outside PR in January 2026 adding an implicit-compression paper.

## Weaknesses

There is no implementation. Agentic Coding Lab cannot copy runtime code, tests, configs, adapters, prompt compressors, or benchmark harnesses from this repo.

Evidence quality is thin. TL;DR cells summarize claimed paper contributions but do not record benchmark datasets, compression ratios with quality deltas, failure modes, cost/latency tradeoffs, or whether code was actually run.

Update discipline is lightweight. The Git history shows active initial curation, then a merged PR on 2026-01-17 and no pushed commits afterward in the reviewed clone. GitHub metadata showed `updated_at` on 2026-04-24, but no README content change after the January merge. There is one open issue unrelated to list maintenance.

Metadata is inconsistent. Some rows have missing venues, some code cells are empty, some links point directly to PDFs while others use abstract pages, and tags are not normalized across sections.

The taxonomy is not validated. There is no script to detect duplicate papers, dead links, malformed rows, missing code links, future venue/date inconsistencies, or category drift.

The list does not discuss coding-agent safety. It omits preservation needs for exact code, diffs, terminal output, JSON, stack traces, tool-call IDs, and task instructions.

## Ideas To Steal

Use compression locus as the first triage field in Agentic Coding Lab notes: `input`, `latent`, `kv`, or `hybrid`. This immediately tells us whether an idea can be implemented in an agent harness, needs model adaptation, or belongs to serving infrastructure.

Add an "agent controllability" dimension to future research notes. Explicit prompt compression is high controllability; KV cache compression is low controllability for hosted APIs but high for self-hosted inference; latent compression depends on model access.

Build a local taxonomy for coding-agent context artifacts: instructions, conversation, file excerpts, diffs, command output, test logs, stack traces, retrieval snippets, memory notes, and subagent reports. Then map each artifact to compression families from this list.

Use the list as a seed for paper-review backlog. Good deeper-review candidates include LLMLingua/LongLLMLingua for prompt compression, RECOMP/xRAG for RAG compression, AutoCompressor/ICAE/gist tokens for learned summaries, Coconut for latent reasoning, and StreamingLLM/H2O/SnapKV/KIVI for serving-side memory control.

Create a machine-readable companion schema if adopting this style: title, URL, year, venue, category, subcategory, code URL, implementation status, benchmark task, max compression ratio, quality metric, reviewed date, and notes for coding-agent transfer.

Track "where compression can fail" beside every technique. For coding agents, savings are secondary to preserving exact commands, paths, identifiers, error text, patches, and tool semantics.

## Do Not Copy

Do not treat a curated README as evidence that methods transfer to coding agents. Follow primary papers and implementation repos before adopting an algorithm.

Do not copy the category labels without re-checking each paper. Some entries can plausibly fit more than one layer, and at least one explicit-section entry appears KV-adjacent.

Do not use one-line TL;DR claims as benchmark facts. Record task, model, compression ratio, quality loss, latency, and cost from primary sources.

Do not build a research index as freeform Markdown only if it needs maintenance. This repo shows the scanability upside, but also the missing validation downside.

Do not assume hosted-model agents can use KV-cache techniques. Most KV methods require model-server or kernel-level control.

Do not apply latent or abstractive compression to code-agent state without exactness tests. Learned summaries can erase identifiers, paths, arguments, and failure text.

## Fit For Agentic Coding Lab

Fit is conditional. The repo is useful as a reading map and taxonomy seed for token-efficiency research, but not as an implementation source.

The strongest fit is at the planning layer. Agentic Coding Lab can use the README's three-way split to decide which candidates deserve repo review, paper review, or dismissal. It also helps explain why "context compression" work may target different engineering surfaces with different adoption costs.

The direct coding-agent pattern is to separate compression controls by ownership:

- Agent-controlled: prompt pruning, selective context, summarization, retrieval compression, deduplication, log compaction.
- Model/adaptation-controlled: gist tokens, soft prompts, autoencoder memory slots, latent reasoning, one-token RAG.
- Serving-controlled: attention sinks, KV eviction, KV quantization, sparse attention, cache merging.

For future lab artifacts, this repo argues for a token-efficiency matrix rather than a single compression strategy. Each candidate should be scored on controllability, fidelity risk, implementation availability, eval evidence, and exact-structure preservation.

## Reviewed Paths

- `README.md`: taxonomy, definitions, keywords, paper tables, survey table, contribution instructions, acknowledgements, and star-history badge.
- `project.html`: checked and found to be a 1-byte stub with no usable UI or technical content.
- `LICENSE`: checked for repository license context only.
- Git metadata: reviewed HEAD, commit history, branch state, contributors, and merge history to assess update discipline.
- GitHub REST API metadata: stars, repository dates, default branch, open issue count, and pull-request state captured during review.
- `research/index.md`: read-only check confirmed the candidate row exists; not edited because assignment explicitly forbids index edits.

## Excluded Paths

- `.git/`: clone metadata only. Used through Git commands to record exact commit and history, not reviewed as source content.
- `project.html`: excluded from design analysis after inspection because it is a 1-byte UI-only candidate with no content.
- `LICENSE`: legal text only. It does not affect taxonomy quality, provenance, or coding-agent transfer.
- Generated paths: none present in the tracked checkout.
- Vendored dependencies: none present in the tracked checkout.
- Binary assets: none present in the tracked checkout.
- Scripts/tests/assets: none present in the tracked checkout beyond the 1-byte `project.html` file.
