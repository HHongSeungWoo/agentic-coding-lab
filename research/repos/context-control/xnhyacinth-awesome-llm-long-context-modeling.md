# Xnhyacinth/Awesome-LLM-Long-Context-Modeling

- URL: https://github.com/Xnhyacinth/Awesome-LLM-Long-Context-Modeling
- Category: context-control
- Stars snapshot: 2,092 (GitHub REST API `stargazers_count`, captured 2026-05-19)
- Reviewed commit: 73253d2e1faeb71f6844d57f9232ce24fefcefde
- Reviewed at: 2026-05-19
- Status: reviewed
- Scope fit: conditional
- Verdict: Useful as a high-coverage taxonomy and watchlist for long-context modeling, especially KV-cache policy, prompt/context compression, memory, RAG, long-horizon agents, and long-context evaluation. Not directly adoptable as an Agentic Coding Lab runtime because it is a curated Markdown bibliography with no executable context-control system, no local eval harness, and weak provenance beyond links, dates, contribution rules, and CI lint checks.

## Why It Matters

This repo matters because it gives a dense map of the long-context field that coding-agent context-control work keeps touching: what to retain, what to compress, how to retrieve, when long context is worse than RAG, how to budget reasoning tokens, and how to evaluate long-context failures.

For Agentic Coding Lab, the value is not implementation reuse. The value is a taxonomy that turns a broad research area into operational buckets. The strongest transfer is to use the list as a source map for future paper reviews and as vocabulary for context-control artifacts: cache retention, hierarchical memory, RAG/context compression, reasoning-budget control, agent memory, externalized long-context processing, and benchmark selection.

The repo is also useful because it is current. The reviewed commit was pushed on 2026-05-17, and the `News` section includes papers up to 2026-05-14. That makes it better as a candidate-discovery surface than older "awesome" lists, but the same freshness creates review risk: entries are link-level citations, not validated summaries.

## What It Is

`Awesome-LLM-Long-Context-Modeling` is an Awesome-style curated bibliography. The primary artifact is a 3,465-line `README.md` containing a news feed, taxonomy, paper entries, GitHub/homepage badges, blogs, citation, contributor image, and star-history chart.

The repo has no package, source library, MCP server, prompt pack, test suite, examples directory, or local scripts. Supporting files are maintenance-oriented: `CLAUDE.md` gives rules for adding papers, `CONTRIBUTING.md` documents entry format and classification guidelines, `CITATION.cff` ties the repo to the companion survey paper, `.markdownlint.json` relaxes Markdown lint rules for the big list, and two GitHub Actions workflows run lint/link/duplicate/date/YAML/JSON/trailing-whitespace checks on pull requests.

The list claims coverage across surveys, efficient attention, KV-cache optimization, recurrent transformers, state-space models, position encoding, long-context training, long-term memory, RAG, in-context learning, context compression, model compression, long reasoning, multimodal/video, long-horizon agents, long-form generation, inference acceleration, benchmarks, technical reports, and blogs.

## Research Themes

- Token efficiency: Strong as bibliography coverage. Sections on KV-cache eviction, quantization, offloading, cache sharing, context compression, reasoning-budget control, prefill/sparse attention acceleration, and prompt compression provide many candidate methods. The repo does not measure token savings itself.
- Context control: Strong as taxonomy, weak as implementation. It separates context retention, compression, retrieval, memory, training, reasoning, and evaluation, which maps well to coding-agent context-control decisions. It does not provide context assembly rules, runtime policies, hooks, or schemas.
- Sub-agent / multi-agent: Moderate. `15. Long-Horizon Agents`, agentic memory items, long-video agents, multi-agent collaboration, and agentic benchmarks include relevant papers. The repo does not define sub-agent handoff or isolation patterns.
- Domain-specific workflow: Moderate. Coding-agent relevance appears in entries such as `Can Coding Agents Externalize Long-Context Processing?`, `LongCodeZip`, `Pruning the Unsurprising`, `Is Grep All You Need?`, `SwingArena`, function-calling benchmarks, and agent memory benchmarks. These are discoverable links, not workflows.
- Error prevention: Moderate as pointers. Evaluation sections cover lost-in-the-middle, long-form factuality, grounding, hallucination, tool honesty, complex function calling, and evidence verification. There is no local benchmark harness or failure taxonomy.
- Self-learning / memory: Strong as research coverage. Long-term memory is split into dialogue/persona, parametric/augmented/hierarchical memory, and agentic/working memory; RAG has memory-augmented and chunk-cache subsections. No persistent memory design is implemented in the repo.
- Popular skills: No skill system or usage telemetry is present. Reusable "skills" are inferred patterns: classify by primary contribution, update news by arXiv v1 date, avoid duplicate entries, preserve taxonomy, attach code/homepage badges, and run Markdown/link checks.

## Core Execution Path

There is no runtime execution path. The practical maintenance path is:

1. A contributor finds a long-context paper or blog.
2. `CLAUDE.md` instructs the maintainer to read the arXiv abstract page for exact title, full authors, v1 submission date, and explicit conference status.
3. The maintainer searches for an official GitHub repository and project homepage.
4. The maintainer updates `README.md` in two places: `News` and the best-matching main taxonomy section.
5. The maintainer groups news by real arXiv v1 date in reverse chronological order, avoids duplicate date blocks, and preserves entry formatting.
6. Section placement should follow paper content, not a requested section label.
7. PR workflows run Markdown lint, link checks, awesome-lint, duplicate checks, date-format checks, YAML/JSON lint, and trailing-whitespace checks. Several checks are warning-only or fail-open.

The user-facing path is simpler: browse the table of contents, jump to a topic, and follow links to papers, GitHub repos, or homepages. For coding-agent research, the most useful path is to use the taxonomy as a queue of paper candidates rather than as a source of final claims.

## Architecture

The repo is intentionally flat.

`README.md` is the source of truth. It begins with badges, links to the companion survey and notes, a short field description, a Mermaid "taxonomy at a glance", the survey citation, a long table of contents, a `News` feed, the 20-section paper taxonomy, blogs/tutorials, acknowledgements, and star history.

The 20 main sections are:

1. Survey Papers
2. Efficient Attention
3. KV-Cache Optimization
4. Recurrent Transformers
5. State Space Models & Hybrids
6. Position Encoding & Length Extrapolation
7. Long-Context Training
8. Long-Term Memory
9. Retrieval-Augmented Generation
10. In-Context Learning
11. Context Compression
12. Model Compression for Long Context
13. Long Reasoning
14. Long Video & Image
15. Long-Horizon Agents
16. Long-form Text Generation
17. Inference Acceleration & Serving
18. Benchmarks & Evaluation
19. Technical Reports
20. Blogs & Tutorials

The taxonomy has useful depth where context-control trade-offs are active. KV-cache optimization splits into attention-score/heavy-hitter eviction, streaming/sliding-window retention, query-aware/learnable retention, layer-budget/merge/hybrid eviction, quantization/compression, offloading/hierarchical cache, and architectural KV reduction/cache sharing. Context compression splits into hard prompt/token pruning, soft/gist/latent compression, visual/multimodal token compression, and RAG/KV-aware compression. RAG splits long-document QA, long-context-vs-RAG, memory-augmented RAG, chunk caches/KV reuse, retriever/indexing optimization, and surveys/evaluation. Benchmarks split LLM, multimodal/video, agentic long-horizon, and long reasoning/generation.

`CLAUDE.md` is a maintainer instruction file. It is notable because it encodes update discipline: use arXiv v1 dates, do not invent badges, classify by paper content, keep numbering continuous, and run Markdown lint. Some routing examples in `CLAUDE.md` still reference older section numbers such as `9.1 Context` and `2.4 IO-Aware Attention`, so maintainer instructions have minor drift from the current 20-section README taxonomy.

`CONTRIBUTING.md` is the public contribution contract. It requires title link, authors, venue/year, optional GitHub/homepage badges, most specific subsection, synchronized table of contents, preserved 20-chapter taxonomy, duplicate avoidance, and repository checks before PR.

`.github/workflows/pr-check.yml` is broad but mostly advisory. It runs markdownlint with `|| true`, lychee link checking with `fail: false`, awesome-lint with `|| true`, duplicate detection that always exits 0, relaxed YAML/JSON checks, and a hard trailing-whitespace check. `.github/workflows/ readme-check.yml` is narrower and stricter for README Markdown lint on PRs touching `README.md`.

## Design Choices

The first design choice is a topic-first taxonomy instead of chronological listing. This makes the repo usable for research planning because a reader can jump directly to a mechanism: KV eviction, RAG-vs-long-context, prompt compression, long-CoT budget control, agent memory, or benchmarks.

The second choice is to keep a separate `News` feed. That helps track recent arrivals without disturbing the stable taxonomy. The feed is split into visible week papers and collapsed month papers, and contribution rules say dates should be arXiv v1 dates rather than update dates.

The third choice is fine-grained subdivision where the field has many mechanisms. KV-cache, RAG, context compression, long reasoning, long video/image, inference serving, and benchmarks get the most internal structure. This is the repo's strongest context-control contribution.

The fourth choice is link provenance rather than summaries. Each entry generally has title, paper URL, authors, venue/year, and sometimes GitHub/homepage badges. That keeps maintenance cheap and breadth high, but it means readers must inspect original papers for methods, limitations, and evidence.

The fifth choice is to tie the repository to the arXiv survey `A Comprehensive Survey on Long Context Language Modeling` through README citation and `CITATION.cff`. This improves scholarly provenance for the taxonomy, but the GitHub list itself still evolves beyond the paper snapshot.

The sixth choice is contributor-friendly validation rather than hard quality gates. The repo checks Markdown, links, duplicate links, date format, YAML/JSON syntax, and trailing whitespace, but several checks explicitly do not fail PRs. This favors fast curation over strict editorial control.

The seventh choice is badge-based code/homepage discovery. Badges make official artifacts visible, but they are not normalized metadata. A few reviewed lines have malformed badge Markdown that points a GitHub-stars badge at anonymous review URLs, showing the limits of manual formatting at this scale.

## Strengths

The taxonomy is broad and current. It includes 1,460 numbered paper/blog entries in the main list and 72 news entries in the reviewed README. The latest commit is `docs: add recent long-context resources` on 2026-05-17, and recent history shows regular updates in March-May 2026.

The sectioning is better than a generic "awesome papers" dump. It separates mechanisms that matter for coding-agent context control: retention, compression, retrieval, memory, reasoning budget, serving cost, and evaluation.

The KV-cache section is especially strong for implementation scouting. It distinguishes eviction/selection, quantization/compression, offloading/hierarchical cache, and architectural cache sharing, then further separates attention-score, streaming, query-aware, and layer-budget methods.

The context-compression section is directly useful. It distinguishes hard token pruning, soft/gist/latent compression, visual token compression, and RAG/KV-aware compression. It includes coding-relevant entries such as `LongCodeZip` and tool-use compression work.

The RAG and memory sections are useful for deciding when not to stuff everything into context. Long-context-vs-RAG, memory-augmented RAG, chunk caches, indexing, and evaluation subsections map cleanly to coding-agent retrieval design.

The benchmark section is a strong queue for future eval reviews. It includes classic long-context benchmarks, lost-in-the-middle, needle tasks, RULER, long-form factuality, tool honesty, complex function calling, agent memory, GitHub issue solving, and grounding benchmarks.

The contribution rules encode good curation habits: use exact metadata, classify by primary contribution, avoid duplicates, use v1 dates, and avoid invented badges.

## Weaknesses

The repo is a bibliography, not a context-control system. It does not implement a context assembler, token-budget monitor, memory store, RAG pipeline, compression algorithm, evaluation harness, or coding-agent workflow.

Entry provenance is shallow. Most entries provide links and citation metadata but no abstracts, method summaries, benchmark notes, limitations, artifact status, or last-checked evidence. GitHub badges indicate repository existence, not code quality or reproducibility.

Coverage is broad enough to be noisy. The list includes architecture papers, training recipes, multimodal video, model technical reports, blogs, and serving systems. For Agentic Coding Lab, many entries are background only and need filtering before review.

Manual Markdown maintenance creates drift. The reviewed README has malformed badge/link syntax in several places, such as entries pointing GitHub-stars badges at anonymous review URLs. `CLAUDE.md` also contains some stale section-routing examples from an older taxonomy.

CI is not strict enough to guarantee bibliography quality. The PR workflow makes markdownlint, lychee, awesome-lint, duplicate warnings, and YAML lint fail-open or advisory in several cases. It can catch trailing whitespace and some syntax issues, but not wrong classification, stale links hidden behind redirects, unofficial repos, or paper-method relevance.

The taxonomy is strong but not normalized as data. There is no YAML/JSON index, no stable entry IDs, no tags per paper, no machine-readable artifact status, no citation snapshots, and no way to query "coding-agent + compression + code available" without parsing Markdown.

The repo does not capture negative guidance. It lists many methods but rarely explains when a method should not be used, what costs it introduces, or which failure modes it addresses.

## Ideas To Steal

Use this taxonomy as a research intake map for Agentic Coding Lab. Seed paper-review queues from these buckets: KV-cache retention, hard/soft context compression, RAG-vs-long-context, memory-augmented RAG, agentic working memory, long-CoT budget control, and agentic benchmarks.

Create a local context-control matrix with columns for "mechanism", "runtime layer", "budget controlled", "loss mode", "needs model internals", "works with API-only agents", "evidence", and "coding-agent transfer". This repo's sections supply the initial mechanism list.

Adopt the update discipline from `CLAUDE.md`: exact title, full authors, v1 date, official code/homepage links, primary-contribution classification, no invented badges, duplicate avoidance, and checks before merge.

Translate the README taxonomy into Agentic Coding Lab categories:

- KV-cache policy -> model/runtime-level retention, mostly not available to API-only agents.
- Context compression -> prompt/tool-output/file-summary compression, directly useful.
- RAG and memory -> external workspace state, repo search, memory stores, and retrieval contracts.
- Long reasoning -> reasoning-budget gates, early-exit policies, and concise verifier loops.
- Long-horizon agents -> handoff, planning, externalized work, and memory coordination.
- Benchmarks -> local eval suite candidates for long task continuity, tool honesty, function calling, and code issue solving.

Use `News` as a pattern for research freshness. Keep a short "recent additions" section in Lab synthesis docs, separate from stable reviewed notes, so new papers do not pollute final recommendations before review.

Steal the "one primary section" rule. Agent artifacts should avoid duplicate classification unless a note explicitly states cross-category relevance. This keeps indexes usable.

Use the list to avoid overfitting context-control to prompt tricks. The field includes retrieval, cache policy, training, serving, evaluation, multimodal, and memory; Lab designs should name which layer they operate in.

## Do Not Copy

Do not copy the repo as a dependency or fork it into active agent context. It is too broad and too large for always-loaded use.

Do not treat any listed method as validated by inclusion. Inclusion means relevance to long-context modeling, not correctness, maturity, reproducibility, or coding-agent fit.

Do not copy the manual Markdown bibliography format for Lab internal metadata. Agentic Coding Lab should keep machine-readable metadata or structured frontmatter if it wants querying, deduplication, freshness checks, or artifact-status filtering.

Do not adopt model-internal KV-cache methods as if they apply to normal hosted coding agents. Many KV-cache, latent compression, and training-time methods require inference-engine or model-training control.

Do not rely on fail-open CI for research quality. For Lab notes, validation should fail on blank sections, missing reviewed commits, duplicate note paths, invalid categories, and stale required fields.

Do not import every taxonomy branch into Lab as equal priority. Multimodal long video, low-level serving, and model compression are useful background, but current coding-agent context-control work should prioritize prompt/tool-output compression, retrieval, filesystem memory, handoffs, and evals.

## Fit For Agentic Coding Lab

Fit is conditional. The repo is in-scope for `context-control` as a field map and candidate source. It is not a direct support system for coding agents.

Best use is as a curated radar. Agentic Coding Lab should mine it for paper candidates, then deep-review selected papers and code repositories before adopting patterns. The immediate transfer is a smaller Lab taxonomy:

- Context selection: RAG, long-context-vs-RAG, focused retrieval, query-guided retention.
- Context compression: hard pruning, summaries, gist/latent ideas translated to text-safe handoffs, code-aware compression.
- Context memory: working memory, episodic memory, persistent file state, memory benchmarks.
- Reasoning budget: early exit, dynamic thinking, concise reasoning, verifier-gated expansion.
- Evaluation: lost-in-the-middle, grounding, long-form factuality, tool honesty, complex function calling, long-horizon issue solving.

The repo should be cited in synthesis as a discovery source, not as evidence. Any pattern copied into Lab needs an original paper/code review, local reproduction notes, and a coding-agent-specific failure analysis.

## Reviewed Paths

- `README.md`: primary artifact; reviewed overview, taxonomy-at-a-glance Mermaid diagram, table of contents, `News`, all top-level headings, and sampled high-signal sections for surveys, KV-cache optimization, long-context training, long-term memory, RAG, in-context learning, context compression, long reasoning, long-horizon agents, benchmarks, blogs, acknowledgements, and star history.
- `CLAUDE.md`: maintainer workflow, paper update rules, news date rules, classification guidance, entry formatting, lint commands, and Git workflow notes.
- `CONTRIBUTING.md`: public entry requirements, classification guidelines, checklist, and expected checks before PR.
- `CITATION.cff`: citation metadata for the companion arXiv survey and repository.
- `.markdownlint.json`: Markdown lint exceptions; reviewed to understand why long lines, inline HTML, and heading increments are allowed.
- `.github/workflows/ readme-check.yml`: strict README Markdown lint workflow for pull requests touching `README.md`.
- `.github/workflows/pr-check.yml`: broader PR checks for Markdown lint, link checking, awesome-lint, duplicates, date format, YAML/JSON syntax, trailing whitespace, and summary reporting.
- Git metadata: remote URL, current branch, latest commit, commit count, recent history, working-tree status, and reviewed commit.
- GitHub REST repository metadata: star/fork/open-issue snapshot, pushed timestamp, topics, license, default branch, and public repository status.

## Excluded Paths

- `.git/`: VCS internals. Used only through Git commands to record commit, branch, remote, history, and checkout state.
- `.DS_Store`: macOS filesystem metadata; binary/local artifact with no research or context-control value.
- `LICENSE` and `.gitignore`: legal and ignore metadata; checked for repository shape but not deeply reviewed because they do not affect taxonomy, provenance, or context-control transfer.
- Remote badge images, contributor image, star-history SVG, and shields in `README.md`: presentation/UI-only assets. Badge targets were sampled when they affected provenance, but image contents were not reviewed.
- External linked papers, project pages, blogs, GitHub repositories, and the companion LCLM-Horizon repository: out of scope for this repo note. Links were used to assess taxonomy/provenance style, but individual papers require separate reviews before claims are adopted.
- Exhaustive line-by-line validation of all 1,460 numbered entries: excluded because this review targets repository design, taxonomy quality, coverage, provenance, update discipline, and transfer to coding-agent context control rather than verifying every citation.
