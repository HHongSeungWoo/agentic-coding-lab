# IAAR-Shanghai/Awesome-AI-Memory

- URL: https://github.com/IAAR-Shanghai/Awesome-AI-Memory
- Category: memory
- Stars snapshot: 894 (GitHub repository page, captured 2026-05-19)
- Reviewed commit: d6b5238ce146e6329b79a1c224d4752d57872724
- Reviewed at: 2026-05-19
- Status: reviewed
- Scope fit: conditional
- Verdict: Useful as a current memory-landscape map and candidate source, especially for taxonomy, benchmark coverage, and recent memory-system papers. Do not treat it as an implementation, validated registry, or machine-readable bibliography; it is a manually maintained bilingual README with HTML tables, badge metadata, no CI/schema, and several provenance/count/license inconsistencies.

## Why It Matters

AI-agent memory is moving fast enough that a compact landscape map has real value. This repo tracks recent papers, benchmarks, open-source systems, and memory concepts across long-term memory, retrieval, updating, forgetting, compression, personalization, multi-agent memory, and memory-native systems.

For Agentic Coding Lab, the useful transfer is not code. It is the way the repo separates memory research into practical buckets: concepts, recent updates, papers, benchmarks, open systems, and community-submitted additions. That shape can feed a coding-agent memory watchlist and help decide which memory systems deserve deeper reviews.

## What It Is

`IAAR-Shanghai/Awesome-AI-Memory` is an awesome-list style AI memory knowledge base. The reviewed checkout contains English and Chinese READMEs, two PNG assets, an Apache-2.0 `LICENSE`, and one Python helper script for badge paper counts.

The English README is the main artifact. It has an introduction, project scope, recent update log, core concepts, a 399-active-paper list, benchmark/task resource table, open-source systems table, multimedia links, an Adam Framework spotlight, contribution issue template, community links, and star-history embed. `README_cn.md` mirrors the same structure for Chinese readers.

## Research Themes

- Token efficiency: Moderate as coverage, weak as implementation. The core concepts and paper list cover context compression, KV cache management, memory compression, long-context evaluation, and cost-performance tradeoffs, but the repo does not run token-budget experiments or provide compression code.
- Context control: Moderate. The repo frames memory as external state with writing, retrieval, updating, deletion, compression, prioritization, forgetting, conflict resolution, and security governance. It does not provide context assembly, retrieval policy, or injection machinery.
- Sub-agent / multi-agent: Moderate. Scope and tags include shared/collaborative memory, multi-agent systems, tool-augmented memory, and planning-aware memory, but there are no dispatch contracts, role-specific memory stores, or isolation patterns.
- Domain-specific workflow: Moderate. Benchmark buckets cover personalization, long dialogue, long-context understanding, web navigation, episodic memory, and hallucination; systems cover memory products and frameworks. Coding-agent-specific workflow is present only indirectly through linked projects such as Autohand Code CLI, SkillClaw, Hindsight, SwarmVault, ToolPipe, and Adam.
- Error prevention: Moderate as bibliography. The benchmark matrix includes stale-memory invalidation, budgeted memory writing, hallucination, long-term consistency, retrieval, and personalization. There is no local eval harness, link checker, duplicate detector, or claim verification.
- Self-learning / memory: Strong as a landscape. This is the repo's core: LLM memory, explicit/parametric memory, short/long-term memory, episodic/semantic/procedural memory, memory operations, retrieval, compression, forgetting, and memory-native systems.
- Popular skills: No usage telemetry exists. Transferable skill patterns are memory candidate triage, benchmark mapping, update-log review, paper-to-pattern extraction, and system-watchlist maintenance.

## Core Execution Path

There is no runtime memory system. The practical execution path is manual curation:

1. Maintainers add papers and systems directly to `README.md` and `README_cn.md`.
2. Paper entries live inside four HTML `<details>` sections: `Survey`, `Framework & Methods`, `Datasets & Benchmark`, and `Systems & Models`.
3. Each paper entry uses a two-row HTML table pattern with date, title, shield-image tags, links, and a short bullet summary.
4. Resource sections separately list benchmark/task families and open-source systems ordered by publication date.
5. Contributors are asked to open issues with title, head names, publication venue, innovation, tasks, and significant result.
6. `scripts/update_paper_count.py` counts non-commented `rowspan="2"` paper entries and updates the paper-count badges in both READMEs.

For Lab use, the path should be: use this repo as a source map, then deep-review individual papers/repos before adopting any memory pattern.

## Architecture

The architecture is intentionally small:

- `README.md`: main English knowledge base. It is 8,083 lines and contains all taxonomy, paper tables, benchmark resources, open-source systems, community links, and star-history embed.
- `README_cn.md`: Chinese mirror of the README. It has the same major sections and similar paper/resource content.
- `scripts/update_paper_count.py`: 71-line script that strips HTML comments, counts `rowspan="2"` markers, and rewrites `Papers-N-blue.svg` badges.
- `assets/Gemini_Generated_Image_hretabhretabhret.png`: 1584x672 banner image used at the top of the README.
- `assets/wechat-qr-code.png`: 396x396 community QR image.
- `LICENSE`: Apache License 2.0 text, despite the README badge linking to MIT.

The data architecture is weaker than the topic architecture. Papers, tags, summaries, links, benchmarks, systems, and star badges are embedded in Markdown/HTML rather than normalized into YAML, JSON, BibTeX, CSV, or a generated catalog.

## Design Choices

- Uses a single bilingual README knowledge base instead of a package, website generator, or structured registry.
- Defines explicit in-scope and out-of-scope rules around LLM memory, external explicit memory, memory management, agent memory, multi-agent memory, cognitive inspiration, evaluation, benchmarks, and open-source tools.
- Keeps a richer AI-memory taxonomy in an HTML comment, while the visible page uses a long `Core Concepts` section as the practical taxonomy.
- Organizes papers by four broad buckets and publication date, not by implementation maturity, benchmark type, source quality, or coding-agent transfer.
- Uses shield-image tags inside HTML tables for tags such as `Agent Memory`, `Memory Retrieval`, `Graph-Structured Memory`, `Benchmark`, and `System`.
- Separates benchmark coverage into task families such as personalized evaluation, comprehensive evaluation, memory mechanism evaluation, long-term memory, long-dialogue reasoning, long-context understanding, episodic memory, hallucination, and web navigation.
- Uses dynamic GitHub star badges for linked open-source systems, which is useful visually but not durable provenance.
- Keeps a manual recent-update log with counts by category. The reviewed log shows frequent 2026 updates through 2026-05-10, and Git history shows many April-May 2026 README commits.
- Includes a special Adam Framework spotlight with production-use claims. This is useful as a candidate pointer, but it is not integrated into the same table schema as other systems.

## Strengths

- Very current for a curated memory bibliography. The reviewed commit was dated 2026-05-14 and includes papers and systems from early May 2026.
- Broad coverage across memory theory, methods, benchmarks, systems, models, and open-source frameworks.
- The visible concept glossary is practical for agent-memory design: storage/processing/retrieval/control layers, write/retrieve/update/delete/compress operations, lifecycle, conflict resolution, budgets, security governance, memory classification, and forgetting.
- Benchmark section is especially useful as a starting matrix. It groups memory evals by task rather than dumping all papers into one list.
- The systems table is useful for discovery. It lists 47 memory-related systems with dates, GitHub links, websites, and dynamic star badges.
- Paper entries include short summaries, not only links. That speeds triage before deeper paper review.
- Bilingual English/Chinese READMEs broaden audience and contributor pool.
- The count script at least makes one consistency check explicit: active paper count is derived after stripping commented-out entries.

## Weaknesses

- Conditional fit because this is a curated knowledge base, not a memory engine, retrieval service, benchmark harness, or coding-agent integration.
- Machine-readability is poor. The core data is embedded in HTML tables, shield images, Markdown, comments, and free-text summaries.
- Provenance is incomplete for durable research use. Entries usually lack normalized authors, venue, DOI/arXiv ID fields, code URLs, benchmark links, citation source, review date, or confidence status.
- No CI, link checker, schema validation, duplicate detection, stale-link detection, or badge consistency test is present.
- Several metadata signals conflict. README shows an MIT badge, while `LICENSE` is Apache-2.0. README badge says 399 papers; raw `rowspan="2"` count is 400 because one entry is commented out. README badge says 104 open-source projects, while the visible systems table has 47 GitHub star badges and 55 GitHub links.
- The active taxonomy is less structured than the commented taxonomy. The commented taxonomy is closer to a reusable schema, but readers and parsers will skip it.
- Update discipline is active but manual. Recent commit messages include generic labels such as `pr commit`, `sync pr commit`, and `append new paper`, which limits auditability.
- Trust and maturity are not encoded. Surveys, methods, benchmarks, speculative systems, commercial projects, and personal projects sit near each other without review status.
- Dynamic star badges are not captured snapshots. They cannot support reproducible trend analysis in Lab notes.
- Community and media blocks add noise for automated ingestion.

## Ideas To Steal

- Use the repo's memory vocabulary as a controlled Lab checklist: memory type, storage location, lifecycle, operation, retrieval method, update/forgetting policy, scope, and evaluation target.
- Add a `Recent Updates` section to Lab memory synthesis, but make each item structured with date, source, category, candidate path, and review status.
- Build a benchmark matrix by task family. Coding-agent memory should be evaluated separately for recall, stale-memory invalidation, conflict handling, preference retention, hallucination resistance, and long-horizon workflow support.
- Keep open-source memory systems in a chronological watchlist with captured stars, reviewed commit, license, storage model, retrieval model, privacy notes, and coding-agent fit.
- Reuse the contribution issue shape, but extend it with `Evidence`, `Reproducibility`, `Security/Privacy`, and `Transfer to coding agents`.
- Convert shield-image tags into plain controlled tags. Good starting tags include `Memory Writing`, `Memory Retrieval`, `Update Mechanisms`, `Long-Term Memory`, `Graph-Structured Memory`, `Benchmark`, `System`, `Personalization`, and `Memory Hallucination`.
- Treat special spotlight sections as "candidate profiles" only when they include validation details, session counts, deployment context, and links to inspectable artifacts.
- Use active-paper count automation, but back it with a structured source file and tests rather than parsing README rowspans.

## Do Not Copy

- Do not copy the monolithic README as Lab's durable storage format. It is hard to diff, query, validate, and split across parallel workers.
- Do not use HTML table rows and badge images as the canonical data model.
- Do not rely on dynamic GitHub star badges for research metadata; capture stars with date and source.
- Do not mix license, paper-count, and project-count badges without automated consistency checks.
- Do not treat paper summaries as verified findings. They are useful triage blurbs, not substitutes for reading papers or running benchmarks.
- Do not leave the best taxonomy inside comments. If a taxonomy matters, make it first-class and machine-readable.
- Do not mix community QR codes, multimedia links, and research data in files that agents need to parse.

## Fit For Agentic Coding Lab

Fit is conditional but useful. This repo belongs in `memory` as a landscape and candidate source. It should not be imported as code or cited as proof that a memory technique works.

The best Lab use is to mine it for vocabulary, benchmark candidates, and memory-system repos to deep-review. For coding-agent memory design, the strongest pattern is a layered review rubric: what gets written, how it is scoped, how it is retrieved, how stale or conflicting memory is handled, how budgets are enforced, and what benchmark proves the behavior.

## Reviewed Paths

- `/tmp/myagents-research/iaar-shanghai-awesome-ai-memory/README.md`: main English scope, concepts, update log, paper tables, benchmark matrix, systems table, contribution template, community links, and star-history embed.
- `/tmp/myagents-research/iaar-shanghai-awesome-ai-memory/README_cn.md`: Chinese mirror; reviewed headings and structure for parity with the English README.
- `/tmp/myagents-research/iaar-shanghai-awesome-ai-memory/scripts/update_paper_count.py`: paper-count automation and evidence that the README is manually maintained with a brittle marker-count convention.
- `/tmp/myagents-research/iaar-shanghai-awesome-ai-memory/LICENSE`: Apache-2.0 license text and source for the README license-badge mismatch.
- `/tmp/myagents-research/iaar-shanghai-awesome-ai-memory/assets/Gemini_Generated_Image_hretabhretabhret.png`: confirmed as README banner image, not a technical diagram used for analysis.
- `/tmp/myagents-research/iaar-shanghai-awesome-ai-memory/assets/wechat-qr-code.png`: confirmed as community QR image.
- Git metadata: reviewed commit, branch, status, latest commit date, recent log, and current GitHub repository page for star snapshot.

## Excluded Paths

- `/tmp/myagents-research/iaar-shanghai-awesome-ai-memory/.git/`: excluded as VCS internals except for provenance checks such as commit, branch, status, and log.
- `/tmp/myagents-research/iaar-shanghai-awesome-ai-memory/assets/Gemini_Generated_Image_hretabhretabhret.png`: excluded from technical analysis after file inspection because it is a 2.0 MB binary banner asset.
- `/tmp/myagents-research/iaar-shanghai-awesome-ai-memory/assets/wechat-qr-code.png`: excluded from technical analysis after file inspection because it is a small binary QR/community asset.
- Generated, vendored, package-lock, UI-only, test, benchmark-runner, schema, and application source paths: none were present in the reviewed checkout.
