# Shichun-Liu/Agent-Memory-Paper-List

- URL: https://github.com/Shichun-Liu/Agent-Memory-Paper-List
- Category: memory
- Stars snapshot: 2,007 (GitHub REST API repository metadata, captured 2026-05-19)
- Reviewed commit: 4b451283144ef66150273b51e7702de79a9239f3
- Reviewed at: 2026-05-19
- Status: reviewed
- Scope fit: conditional
- Verdict: Strong taxonomy and bibliography source for agent memory design, especially the split between factual, experiential, and working memory across token-level, parametric, and latent forms. It is not an implementation reference: the artifact is a Markdown paper list with images, no schema, no code, no tests, no benchmark matrix, and weak machine-readability.

## Why It Matters

`Shichun-Liu/Agent-Memory-Paper-List` matters because it compresses a fast-moving memory literature into one visible map. The README frames agent memory as distinct from RAG, context engineering, and LLM memory, then organizes the space through three lenses: storage form, memory function, and lifecycle dynamics.

For Agentic Coding Lab, the most useful contribution is conceptual hygiene. It gives a vocabulary for separating durable project facts, learned workflow experience, and active context state instead of placing all persistent notes into one "memory" bucket. That separation is directly useful for designing safer coding-agent memory tools.

## What It Is

The repo is the companion paper list for the survey "Memory in the Age of AI Agents." The checkout contains a single primary `README.md`, two taxonomy images, an MIT license, and one stray desktop metadata file.

The README includes news, badges for arXiv, Hugging Face, stars, license, and Semantic Scholar citations, a short introduction, two diagrams, and a paper list. The list has 199 paper rows at the reviewed commit. It is organized as a 3 x 3 matrix:

- Functions: factual memory, experiential memory, working memory.
- Forms: token-level, parametric, latent.

The introduction adds a lifecycle lens: formation, evolution, and retrieval. That lifecycle is visible in the prose and diagrams, but the individual paper rows are not tagged with lifecycle metadata.

## Research Themes

- Token efficiency: Good literature coverage, weak artifact support. The list includes context condensation, context compression, KV reuse/compression, prompt compression, and long-context memory papers. The repo itself does not provide token-budget fields, context-cost estimates, or extraction summaries.
- Context control: Strong conceptual relevance. Working memory is treated as active context management, not just chat history. This maps well to coding-agent context curation, but no policy or runnable context assembler is included.
- Sub-agent / multi-agent: Moderate coverage. The list includes multi-agent memory systems, memory sharing, role-aware routing, GUI agents, and workflow memory papers, but it does not compare coordination protocols or memory visibility boundaries.
- Domain-specific workflow: Mixed. It includes tool use, GUI agents, web agents, workflow automation, program repair, and skill-learning papers. It does not tag coding-specific tasks, repository workflows, build/test memory, or patch-review loops.
- Error prevention: Low as a repo feature. Privacy risk and retrieval/tool-selection papers are present, but the list has no risk taxonomy, no link checking, no benchmark validation, and no reproducibility status per paper.
- Self-learning / memory: Main strength. Experiential memory and self-evolving agents get dedicated coverage, including reflection, procedural memory, experience synthesis, tool memory, and runtime learning.
- Popular skills: Not a skill pack. Reusable patterns are taxonomy cards: context condensation, context branching, extract insights, memory graph, vector database, model/knowledge editing, multimodal RAG, KV reuse/compression, and latent memory generation.

## Core Execution Path

There is no runtime execution path. The practical path is editorial:

1. A reader lands on `README.md`.
2. The introduction distinguishes agent memory from adjacent concepts.
3. `assets/concept.png` positions agent memory against RAG, context engineering, and LLM memory.
4. `assets/main.png` maps representative systems across memory forms and functions.
5. The reader browses the Markdown paper list by function and form.
6. Contributors add or fix paper rows through README edits and pull requests.

The latest reviewed HEAD is a GitHub merge commit from 2026-03-04 that merged a paper-list addition. Git history shows most activity clustered around initial release in December 2025 and January 2026, with community additions and fixes afterward.

## Architecture

The architecture is a curated Markdown registry, not a software system. Its components are:

- `README.md`: source of truth for prose, taxonomy, paper rows, citation, and star-history link.
- `assets/main.png`: dense taxonomy map of representative works across token-level, parametric, and latent memory, with examples such as vector databases, knowledge graphs, model editing, context condensation, KV memory, and latent repositories.
- `assets/concept.png`: Venn-style boundary map among agent memory, LLM memory, RAG, and context engineering.
- `LICENSE`: MIT license.

The paper list uses Markdown headings as structure and bullet rows as records. There is no JSON, YAML, BibTeX database, CSV, DOI table, generated site, or script that can validate or export the bibliography.

## Design Choices

The strongest design choice is the two-axis paper taxonomy. Function answers why the agent needs memory; form answers where memory lives. That prevents a common design error where vector stores, summaries, model editing, and KV-cache techniques are all discussed as one interchangeable mechanism.

The repo also makes "working memory" an explicit function. For coding agents, this is useful because active task state, scratchpad compression, file-window selection, and command output retention should be designed separately from durable long-term facts.

The lifecycle lens is present but not operationalized. Formation, evolution, and retrieval are mentioned as dynamics, but paper rows cannot be filtered by extraction method, consolidation policy, forgetting policy, or retrieval strategy.

The list allows repeated papers across categories. That is sensible for cross-cutting systems such as MemRL and Hindsight, but it also means naive row counting overstates unique paper count.

The repository uses community PRs and simple README edits rather than a stricter contribution schema. This keeps contribution friction low, but it makes provenance, deduplication, link quality, and metadata consistency fragile.

## Strengths

The taxonomy is immediately transferable to system design. Agentic Coding Lab can use factual, experiential, and working memory as top-level product categories, then choose storage forms under each category.

Coverage is broad for a small repo: 199 paper rows across agent memory, RAG-adjacent systems, long-context processing, model editing, self-evolving agents, tool memory, GUI agents, multimodal memory, and KV-cache methods.

The diagrams carry practical meaning. `concept.png` is useful for boundary-setting; `main.png` is useful as a pattern inventory for memory mechanisms.

The bibliography is current through early 2026 at the reviewed commit and has clear popularity signal: 2,007 stars and 91 forks in the GitHub API snapshot captured 2026-05-19.

The list includes several coding-agent-relevant areas, including program repair, tool learning, workflow memory, GUI/web agents, context compression, and self-improving agent systems.

## Weaknesses

Machine-readability is weak. Paper rows are plain Markdown with mixed link styles, no stable IDs, no normalized venue/source fields, no abstracts, no code links, no tags beyond heading location, and no per-entry citation or benchmark metadata.

There are formatting inconsistencies that would complicate parsing: one malformed `[[paper]](...)` link for MemRL in working memory, mixed `http` and `https`, mixed arXiv URL styles, uppercase `ARXIV` DOI variants, versioned arXiv URLs, and inline LaTeX-style title fragments.

Provenance is shallow at the per-entry level. The repo links papers but does not explain why each paper belongs in a category, whether it was included from the survey, a community PR, author suggestion, or manual search, or whether the linked work has code, data, or independent replication.

Update discipline is visible only through Git history and news. There is no `CONTRIBUTING.md`, schema, CI link checker, duplicate detector, or changelog that records how additions are reviewed.

Benchmark coverage is not structured. Benchmark papers are present, but there is no benchmark matrix for task, dataset, metric, agent setting, memory type, baseline, or result. The repo helps find papers, not compare evidence.

The taxonomy is broader than coding-agent memory. Parametric memory, latent memory, multimodal memory, and model editing are important research areas, but most are costly, hard to reverse, and not ready to copy into a practical coding-agent memory layer without separate evaluation.

## Ideas To Steal

Use a function-first memory taxonomy in Agentic Coding Lab:

- Factual memory: verified project facts, user preferences, repo conventions, API contracts, and environment constraints.
- Experiential memory: lessons from prior debugging, failed commands, review feedback, successful workflows, and reusable tactics.
- Working memory: active task state, selected files, current hypotheses, recent command outputs, and context summaries.

Add storage form as a second field, not as the main product category. For the lab today, most safe memories should be token-level explicit records. Parametric and latent memory can stay research-only until reversibility, privacy, and evaluation are mature.

Borrow the lifecycle lens as required metadata for every memory record: formation source, confidence, evidence path, evolution policy, decay/forget rule, retrieval trigger, and allowed scopes.

Allow multi-label memories. A single item can be both experiential and working-memory-derived, or factual and retrieval-backed. Force-fit single categories only for UI grouping, not for storage semantics.

Turn the diagrams into a design checklist. Before adding a memory feature, classify whether it is context condensation, insight extraction, graph memory, vector retrieval, procedural/tool memory, model editing, KV compression, or latent state management.

Use the repo as a discovery backlog. For each promising paper, create structured local notes with code availability, benchmark claims, failure modes, and transfer patterns for coding agents.

## Do Not Copy

Do not use a Markdown-only registry as an operational memory source. Coding-agent memory needs a typed schema, validation, source attribution, scoped retrieval, retention controls, and migration rules.

Do not treat all memory research as equally adoptable. Model editing, parametric memory, and latent memory have reversibility and privacy risks that are much harder than saving explicit text records.

Do not rely on stars, citations, or a survey list as evidence that a method works for coding agents. Require task-level evals, reproducible code, and failure analysis before adopting a technique.

Do not copy the loose contribution path for a lab knowledge base. Use link checking, duplicate detection, normalized IDs, and required fields for paper/source provenance.

Do not let category boundaries blur RAG, context engineering, and agent memory. The repo's boundary diagram is useful precisely because those terms overlap; production tools should make the boundary explicit in tool names and schemas.

Do not store desktop metadata or binary cruft in research artifacts. The reviewed repo contains `assets/.DS_Store`, which is irrelevant to memory design.

## Fit For Agentic Coding Lab

Fit is strong as a taxonomy and candidate-discovery source, conditional as a repo candidate. It should not be adopted as a component because it has no runtime, no API, and no machine-readable registry. It should influence the memory spec.

The best transfer is a memory design matrix for the lab. Rows should be memory function: factual, experiential, working. Columns should be implementation form: explicit token-level store first, retrieval/index layer second, research-only parametric/latent options later. Every memory tool should declare which cell it writes to or reads from.

For near-term implementation, Agentic Coding Lab should use this repo to justify three separate tool surfaces:

- `remember_fact`: saves verified, durable project/user facts with evidence.
- `remember_lesson`: saves experiential workflow lessons only after successful verification.
- `summarize_working_state`: compresses active task state without making it permanent unless promoted.

The repo also supports a research backlog for benchmark-driven memory work: context compression for long tasks, retrieval policies for project facts, procedural memory for tool use, and privacy/error prevention for persistent agent memory.

## Reviewed Paths

- `/tmp/myagents-research/shichun-liu-agent-memory-paper-list/README.md`: primary taxonomy, introduction, news, badges, 199 paper rows, citation, and star-history link.
- `/tmp/myagents-research/shichun-liu-agent-memory-paper-list/assets/main.png`: reviewed visually; taxonomy map of memory forms, functions, and representative mechanism families.
- `/tmp/myagents-research/shichun-liu-agent-memory-paper-list/assets/concept.png`: reviewed visually; boundary map among agent memory, LLM memory, RAG, and context engineering.
- `/tmp/myagents-research/shichun-liu-agent-memory-paper-list/LICENSE`: MIT license.
- `/tmp/myagents-research/shichun-liu-agent-memory-paper-list/.git` metadata via `git rev-parse`, `git show`, `git log`, `git shortlog`, and `git ls-tree`: exact reviewed commit, update timing, contributors, and hidden file inventory.
- `https://api.github.com/repos/Shichun-Liu/Agent-Memory-Paper-List`: GitHub REST API metadata for stars, forks, repository dates, pushed timestamp, license, and default branch.

## Excluded Paths

- `/tmp/myagents-research/shichun-liu-agent-memory-paper-list/.git/`: VCS internals; used only through Git commands to record commit and update provenance.
- `/tmp/myagents-research/shichun-liu-agent-memory-paper-list/assets/.DS_Store`: Apple Desktop Services Store metadata; binary desktop artifact with no research, taxonomy, or implementation content.
- Generated source paths: none present.
- Vendored dependency paths: none present.
- UI-only application paths: none present.
- Binary taxonomy images were not excluded because they are part of the repo's core taxonomy artifact and were reviewed visually.
