# TeleAI-UAGI/Awesome-Agent-Memory

- URL: https://github.com/TeleAI-UAGI/Awesome-Agent-Memory
- Category: memory
- Stars snapshot: 421 (GitHub REST API, captured 2026-05-20)
- Reviewed commit: 93e81b22f2f1129a09debb8334cb9ab8a5bf5f93
- Reviewed at: 2026-05-20T21:12:29+09:00
- Status: reviewed
- Scope fit: conditional
- Verdict: Useful as a very current memory landscape and watchlist, especially for agent-memory products, benchmark names, and coding-agent-adjacent memory papers. It should not be treated as an authoritative benchmark, neutral taxonomy, or machine-readable registry. Agentic Coding Lab should steal the fast-moving category map and benchmark buckets, but add structured provenance, review status, link checks, stale-entry detection, and coding-agent-specific memory lifecycle fields before using it for decisions.

## Why It Matters

`TeleAI-UAGI/Awesome-Agent-Memory` tracks memory systems, benchmarks, surveys, papers, articles, and workshops for LLM and multimodal agent memory. The repo matters because it is unusually current: the reviewed commit was pushed on 2026-05-20, the same day as review, and recent commits add or reorder memory papers, benchmarks, products, and workshops.

For Agentic Coding Lab, the value is candidate discovery and category pressure-testing. The README names coding-agent memory systems such as Claude-Mem, agentmemory, Memov, OMEGA, Akephalos, SWE-Pruner, LCM, and AppWorld-adjacent memory/context work. It also separates plain-text, multimodal, simulation, nonparametric, parametric, evolution, context engineering, and cognitive-science memory material, which is a useful reminder that "memory" is not one feature.

## What It Is

The repository is a static curated list. The checkout contains only `README.md`, `LICENSE`, and `.gitignore`. There is no package, schema, script, CI workflow, website source, benchmark runner, data file, or generated catalog in the repo.

The README is 1,003 lines and serves as the entire knowledge base. It contains:

- A top hotlist of 2026 articles and announcements.
- 32 open-source product entries, ordered by GitHub star badge.
- 9 closed-source product entries and 3 archival entries marked debunked or inactive.
- 2 tutorials.
- 14 surveys.
- 32 benchmark entries split into plain-text, multimodal, and simulation-environment sections.
- 66 nonparametric memory paper entries, 32 parametric memory paper entries, 49 memory-for-agent-evolution paper entries, and 9 cognitive-science memory entries.
- 7 articles, 2 workshops, and a star-history embed.

Bold text is used as a signal for resources with reproducible code publicly available on GitHub. Code, paper, blog, data, docs, schema, eval, and leaderboard links are embedded as ad hoc Markdown links.

## Research Themes

- Token efficiency: Moderate coverage, no implementation. The repo includes compression, context pruning, lossless context management, KV cache, sparse attention, context caching, long-context serving, and benchmark papers, but it does not define token budgets, compaction policies, or context-packing logic.
- Context control: Strong as a watchlist. The dedicated "Context Engineering & Harness Engineering" section names coding-agent-relevant work such as SWE-Pruner, LCM, CL-bench, ACON, AgentFold, and file-system context abstraction. It does not provide a context assembly architecture.
- Sub-agent / multi-agent: Moderate. The list includes MIRIX, multi-agent memory systems, context sharing, and coordination articles, but there are no contracts for agent-scoped stores, shared memory, permissions, conflict resolution, or synchronization.
- Domain-specific workflow: Good for coding-agent discovery. Several product notes explicitly mention Claude Code, Codex, OpenClaw, MCP, Git-backed memory, local markdown memory, coding-agent persistent memory, GUI agents, app-world benchmarks, and long-horizon engineering.
- Error prevention: Mixed. The list includes debunked and inactive archival entries, hallucination benchmarks, privacy papers, and context-pruning papers. But there is no local verification, stale-link detection, trust score, maturity score, or evidence standard.
- Self-learning / memory: Strong as taxonomy coverage. It covers nonparametric memory, graph memory, multimodal memory, parametric memory, reinforcement learning, continual learning, procedural memory, reflective memory, self-evolving agents, and cognitive-science inspiration.
- Popular skills: No skill implementation is present. Transferable "skills" are curation patterns: maintain a memory watchlist, separate product types from papers and benchmarks, surface code/data availability, and mark debunked or inactive entries.

## Core Execution Path

There is no runtime memory execution path. The actual workflow is manual curation:

1. Maintainers edit `README.md` directly.
2. New papers, products, benchmarks, and articles are placed under year and topic headings.
3. Open-source items are bolded and ranked higher when code is available.
4. Product entries use live GitHub star badges, plus optional `code`, `paper`, `blog`, `docs`, `evals`, or `schema` links.
5. Readers scan sections, follow links, and deep-review downstream repos or papers themselves.
6. Contributors are asked to open an issue or pull request to add papers, fix links, or improve categorization.

The update path is active but not automated. Git history has 347 commits from the 2025-10-30 initial commit through the reviewed 2026-05-20 commit. There were 46 commits since 2026-05-01 and 18 commits since 2026-05-15. Recent messages are mostly direct README curation such as adding papers, moving benchmark entries, promoting systems, or generic `Update README.md`.

## Architecture

The architecture is a single Markdown registry:

- `README.md`: canonical data store, navigation, taxonomy, links, badges, and visual embeds.
- `LICENSE`: Apache-2.0 license.
- `.gitignore`: ignores `.claude/`; no effect on public data.

There is no structured source of truth. Categories, years, product rank, code availability, benchmark grouping, and trust markers are encoded in Markdown headings, ordered lists, bold markers, inline prose, and link labels. GitHub star badges are dynamic remote images rather than captured metadata.

The repo uses external links as provenance. Most entries link to arXiv, GitHub, Hugging Face datasets, ACL Anthology, OpenReview, ACM, Nature, Cell, blog posts, or project pages. That is useful for discovery, but the repository does not normalize authors, venues, dates, citation counts, license, reviewed commit, benchmark task type, metric, dataset status, or reproducibility state.

## Design Choices

The strongest design choice is broad memory segmentation. The README separates products, tutorials, surveys, benchmarks, nonparametric memory, parametric memory, memory for agent evolution, cognitive-science memory, articles, and workshops. Within benchmarks, it splits plain text, multimodal, and simulation environments. Within nonparametric memory, it splits text, graph, multimodal understanding, and multimodal generation.

The second useful choice is pushing reproducible-code items upward and bolding them. That gives readers a quick signal that an entry may be inspectable. The signal is still weak because it does not distinguish runnable code, stub repositories, partial code, benchmark data, archived projects, or production-ready systems.

The third useful choice is keeping archival/debunked entries visible instead of deleting them. `MemPalace` and `Memvid` are marked debunked with critique links, and `Memary` is marked inactive. This is a practical anti-hype pattern for memory research because many memory claims are hard to verify.

The weakest design choice is mixing curated data, live badges, contributor instructions, marketing language, and external UI embeds in one file. A human can scan it, but an agent cannot reliably query it without brittle Markdown parsing.

## Strengths

The repo is very current. The reviewed commit adds a 2026 cognitive-science paper on 2026-05-20, and recent commits show multiple updates during the week of review.

Coverage is broad enough to expose blind spots. It includes memory products, closed-source systems, debunked projects, surveys, benchmarks, parametric memory, nonparametric memory, context engineering, reinforcement learning, continual learning, and cognitive-science references.

Benchmark coverage is better than many awesome lists. The README names plain-text memory benchmarks such as LoCoMo Refined, BEAM, PersonaMem, MemoryAgentBench, LifelongAgentBench, HaluMem, LongMemEval, LoCoMo, LongBench, and Minerva; multimodal benchmarks such as DeepImageSearch, Persona-MME, TeleEgo, Video-MME, MovieChat, CinePile, LongVideoBench, and EgoSchema; and simulation environments such as AMemGym, MemoryBench, ARE, and AppWorld.

The product section is practical for coding-agent memory discovery. It surfaces systems that explicitly mention Claude Code, Codex, OpenClaw, MCP, Git-backed traceability, local markdown memory, persistent coding-agent memory, ACLs, audit logs, and local-first operation.

The top hotlist gives a fast signal of current debates and claims, including benchmark skepticism, managed agent memory, Chronicle-style Codex memories, continual learning, and Claude Code memory commentary.

The archival section is unusually useful. Keeping debunked and inactive entries with critique links helps prevent agents from rediscovering and re-ranking weak candidates as if they were fresh.

## Weaknesses

Machine-readability is poor. The README can be parsed only with heuristic Markdown and HTML handling. There are no stable IDs, JSON/YAML/BibTeX/CSV source files, schemas, generated tables, link validation, or normalized fields.

Provenance is incomplete. Entries often include links, but they do not capture reviewed date, reviewed commit, author list, venue, DOI/arXiv ID as a field, license, code maturity, benchmark metrics, dataset license, citation source, or confidence level.

Update discipline is active but manual. High commit velocity is useful, but generic messages like `Update README.md` reduce auditability. No CI checks that star ordering is correct, links still resolve, bolded entries actually have usable code, or papers are in the right year and category.

Dynamic star badges are not reproducible metadata. The product rank says it is ordered by GitHub stars, but star counts are live badge images and can drift without a commit.

Taxonomy is broad but shallow. It separates major memory families, but does not encode capture policy, retrieval policy, update/delete behavior, memory scope, privacy posture, retention, conflict resolution, stale-memory handling, cost, latency, or safety constraints.

The repo has owner/product bias risk. It includes TeleAI items such as TeleMem and TeleEgo prominently, and the README footer brands the list as TeleAI/Ubiquitous AGI work. This does not invalidate the list, but Lab should treat it as a curated source, not a neutral benchmark authority.

Some entries use future-dated or not-yet-standard paper metadata relative to the reviewed date. The list is valuable as a watchlist, but paper claims need direct paper review before Lab adoption.

## Ideas To Steal

Keep a fast memory watchlist, but make it structured. Agentic Coding Lab should track product, paper, benchmark, and article candidates with fields for category, scope, reviewed date, evidence URL, code URL, data URL, license, reviewed commit, maturity, and coding-agent transfer.

Use separate memory lanes instead of one "memory" bucket: product/tool, benchmark, survey, nonparametric memory, parametric memory, agent evolution, context engineering, cognitive-science inspiration, article/opinion, and workshop/community.

Add an explicit anti-hype lane. Preserve debunked, inactive, unreproducible, or partial-code candidates with evidence and reason so agents do not keep re-triaging them.

Borrow benchmark grouping for Lab eval planning. Coding-agent memory evals should be split into long-term conversational recall, dynamic user profiling, stale-memory invalidation, memory hallucination, long-horizon workflow, app-world simulation, multimodal/screen history, and context-pruning tasks.

Use code/data availability as first-pass triage, but make it explicit. Replace bold Markdown with fields such as `code_available`, `data_available`, `runnable`, `partial_code`, `archived`, `license`, and `last_verified`.

Track coding-agent memory patterns visible in the product section: local-first markdown memory, Git-backed traceability, MCP servers, ACLs, audit logs, tool notes, project context, preference passports, and drop-in compatibility with existing memory APIs.

Add freshness monitoring. The repo's high update cadence is useful; Lab should preserve that energy with stale-review warnings, link checks, badge snapshots, and "needs deep review" queues.

## Do Not Copy

Do not copy a monolithic README as the durable data model. It is hostile to parallel workers, schema validation, exact provenance, and automated synthesis.

Do not use live star badges as research metadata. Capture star counts with date, source, and repository API response.

Do not let bold text mean "reproducible." Code availability, data availability, runnable examples, benchmark scripts, dependency health, and license need separate checks.

Do not treat this list as a benchmark result. The repo names benchmarks; it does not run them, compare systems, validate metrics, or reproduce scores.

Do not adopt the taxonomy without adding lifecycle fields. Coding-agent memory needs write triggers, retention, scoping, retrieval assembly, deletion, conflict handling, privacy, auditability, and stale-memory invalidation.

Do not deep-link downstream products or papers into Lab decisions without reviewing the downstream artifact. This repo is a candidate map, not direct evidence.

Do not mix brand/footer UI assets, star-history images, and research records in files intended for agent parsing.

## Fit For Agentic Coding Lab

Fit is conditional and useful. This repo belongs in the `memory` research set as a current candidate source and taxonomy stress test. It is not an implementation to adopt and not a validated research database.

The strongest transfer is a Lab memory registry design. Agentic Coding Lab should keep the repo's broad category split and benchmark awareness, then convert it into structured records. Each candidate should state what memory is stored, who can read it, how it is retrieved, how it is updated or deleted, how stale memories are detected, what benchmark demonstrates value, what code/data exists, and what coding-agent workflow it improves.

For practical memory design, the list reinforces that coding-agent memory is not only vector retrieval. Viable patterns include local markdown passports, Git-traceable memory, MCP-backed memory servers, file-system abstraction, context pruning, procedural memory, simulation benchmarks, privacy-preserving edge/cloud memory, and anti-hallucination evals.

## Reviewed Paths

- `/tmp/myagents-research/teleai-uagi-awesome-agent-memory/README.md`: primary curated list; reviewed all sections, counts, taxonomy, product ordering, benchmark buckets, paper categories, article/workshop sections, contribution note, star-history embed, and footer branding.
- `/tmp/myagents-research/teleai-uagi-awesome-agent-memory/LICENSE`: Apache-2.0 license text.
- `/tmp/myagents-research/teleai-uagi-awesome-agent-memory/.gitignore`: only ignores `.claude/`; reviewed to confirm no hidden source/data workflow is implied.
- Git metadata through `93e81b22f2f1129a09debb8334cb9ab8a5bf5f93`: reviewed for exact commit, branch, clean checkout, commit count, initial commit date, and recent update cadence.
- GitHub REST API response for `TeleAI-UAGI/Awesome-Agent-Memory`: used for stars, license metadata, repository timestamps, topics, forks, and open-issue count.

## Excluded Paths

- `/tmp/myagents-research/teleai-uagi-awesome-agent-memory/.git/`: excluded as VCS internals except for commit, branch, status, and history provenance checks.
- Downstream linked repositories, papers, datasets, blogs, leaderboards, docs, and product pages: excluded from deep review because this assignment is for the curated repo itself. Links were used only to assess taxonomy, provenance style, and candidate coverage.
- Remote star-history SVG and TeleAI logo image embedded in `README.md`: excluded as external UI/binary assets. They do not define the repo's memory taxonomy or benchmark evidence.
- Generated, vendored, binary, local script, CI workflow, benchmark-runner, schema, package-lock, and application source paths: none were present in the reviewed checkout.
