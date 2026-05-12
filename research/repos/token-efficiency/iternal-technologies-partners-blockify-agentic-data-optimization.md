# iternal-technologies-partners/blockify-agentic-data-optimization

- URL: https://github.com/iternal-technologies-partners/blockify-agentic-data-optimization
- Category: token-efficiency
- Stars snapshot: 174 stars, GitHub REST API repository response, captured 2026-05-12T12:06:06+09:00
- Reviewed commit: 9e36c10e5ccda43ece8af276a46adab5913dd71f
- Reviewed at: 2026-05-12T12:06:06+09:00
- Status: reviewed
- Scope fit: conditional
- Verdict: Useful pattern library for corpus-side context compression, RAG/search preprocessing, and coding-agent knowledge-base design. Treat the reported 78X/40X/3.09X claims as vendor benchmark claims unless rerun on local corpora; the open code is more valuable as a set of data-shaping, dedupe, metadata, and benchmark-harness patterns than as a turnkey agent memory subsystem.

## Why It Matters

Blockify attacks token waste before retrieval rather than after prompt assembly. The core idea is to replace naive chunks with compact, self-contained `IdeaBlock` records containing a title, critical question, trusted answer, tags, entities, and keywords. For agentic coding systems, this maps well to project docs, ADRs, design decisions, runbooks, incident notes, and codebase explanations where repeated boilerplate or stale variants often crowd out useful context.

The interesting part is corpus-side compression: ingest raw documents into structured Q/A units, cluster similar units, merge duplicates with an LLM, and store only canonical blocks in a vector store. This is different from prompt-only compression because it can reduce embedding count, retrieval noise, and top-k redundancy before an agent ever asks for context.

## What It Is

The repo contains three main layers:

- `blockify-distillation-service/`: FastAPI service that accepts existing IdeaBlocks, embeds them with OpenAI embeddings, clusters similar blocks, and merges clusters through the Blockify `distill` API.
- `blockify-skill-for-claude-code/`: Claude Code skill plus scripts for ingesting `.md`/`.txt` files through Blockify `ingest`, storing raw and distilled blocks in local ChromaDB, semantic search, direct API distillation, full pipeline automation, and benchmark report generation.
- `documentation/`: Architecture, API, IdeaBlock schema, RAG/agentic search notes, and platform integration guides for LangChain, LlamaIndex, Elastic, Milvus, Supabase, Cloudflare, Obsidian, n8n, Kibana, Starburst, and Unstructured.io.

The repository is not a self-contained local compressor: ingest and LLM merging depend on Blockify API credentials, and embeddings depend on OpenAI credentials. The distillation service can run locally, but its default merge model is the external Blockify `distill` chat-completions endpoint.

## Research Themes

- Token efficiency: Strong fit. IdeaBlocks compress retrieved context by making each unit short, semantically complete, and deduplicated. Repo claims 3.09X token efficiency, 40X size reduction, and about 98 tokens per retrieved block versus about 303 per traditional chunk, but these are documented/vendor benchmark outputs, not independently reproduced in this review.
- Context control: Strong fit. The schema forces context into `name`, `critical_question`, `trusted_answer`, `tags`, `entity`, and `keywords`, which helps agents retrieve answers rather than raw passages. Metadata filters enable domain, entity, permission, and source controls.
- Sub-agent / multi-agent: Indirect fit. Docs recommend agent routers, retrieval agents, synthesis agents, reflection agents, and per-domain Blockified indexes. The code does not implement multi-agent orchestration; it provides compressed retrieval substrate.
- Domain-specific workflow: Strong fit for enterprise docs, manuals, policy corpora, and knowledge bases. `technical-ingest` is documented for ordered manuals/procedures, but reviewed code mostly handles unordered text and IdeaBlock XML.
- Error prevention: Moderate fit. Deduplication and source metadata reduce conflicting/stale context risk. Human review and governance are discussed, but open code has limited validation beyond schema-ish field presence and benchmark math.
- Self-learning / memory: Conditional fit. ChromaDB raw/distilled collections can act as project memory, but there is no automatic agent feedback loop, aging policy, or memory promotion logic.
- Popular skills: The packaged Claude Code skill is a direct example of a data-optimization skill: ingest project docs, distill them, search before coding, and optionally benchmark retrieval quality.

## Core Execution Path

The local skill path is:

1. `ingest_to_chromadb.py` reads `.md`/`.txt`, chunks text at roughly 2,000 characters with 200-character overlap, calls `https://api.blockify.ai/v1/chat/completions` with `model: ingest`, regex-parses returned XML IdeaBlocks, generates stable content-hash IDs, embeds `name + critical_question + trusted_answer` with `text-embedding-3-small`, and upserts into ChromaDB `raw_ideablocks`.
2. `distill_chromadb.py` exports active raw blocks, clusters them with `difflib.SequenceMatcher` over `trusted_answer`, first within each source document and then globally over representatives, sends clusters of up to 15 blocks to Blockify `model: distill`, stores outputs in ChromaDB `distilled_ideablocks`, and marks raw blocks as distilled.
3. `search_chromadb.py` embeds the user query with the same OpenAI embedding model and searches the distilled collection by default, falling back to raw. It supports entity, tag, and active-only filters.
4. `run_full_pipeline.py` orchestrates ingestion, optional service-backed distillation, direct API fallback, benchmark execution, and summary reporting.

The service path is:

1. FastAPI `POST /api/autoDistill` receives `AutoDistillRequest` containing `BlockifyResult` records and submits an async job.
2. `DedupeService` filters active blocks, embeds each block with `OpenAIEmbeddingGenerator.create_text_blob`, and calls `DedupeAlgorithm.run_dedupe`.
3. `DedupeAlgorithm` iterates from an initial similarity threshold, finds similar pairs, builds non-overlapping clusters by BFS or Louvain, merges each cluster through an injected LLM merge function, re-embeds merged blocks, and increases threshold after configured iterations.
4. `BlockifyLLM` serializes cluster blocks into XML-like IdeaBlocks and calls Blockify `model: distill`. It parses one or more returned `<ideablock>` records into merged blocks.
5. Final response hides all original blocks and returns visible `type: merged` blocks with `blockifyResultsUsed` provenance.

## Architecture

The main architecture is a preprocessing pipeline:

`Documents -> parser/chunker -> Blockify ingest -> IdeaBlocks -> embeddings -> clustering -> Blockify distill -> vector/search store -> agent/RAG context`

Core data structure:

- `name`: short title for human scanning and search.
- `critical_question`: explicit query shape for retrieval alignment.
- `trusted_answer`: compact answer body, usually expected to be two or three sentences.
- `tags`: classification/governance surface.
- `entity` / `entity_type`: graph and filtering surface.
- `keywords`: BM25 and exact-search surface.

Distillation service:

- API layer: FastAPI endpoints for job submission, polling, delete, readiness, health, metrics, and OpenAPI docs.
- Job layer: thread-pool job manager with filesystem or SQLite persistence, progress updates, intermediate results, and timeout status.
- Embedding layer: batched, parallel OpenAI embeddings.
- Similarity layer: dense cosine matrix for small datasets; random-hyperplane LSH candidate generation for larger datasets; separate FAISS flat k-NN helper exists but is not used by the core algorithm path.
- Clustering layer: BFS connected components below `LOUVAIN_NODE_THRESHOLD`; NetworkX Louvain for larger similarity graphs.
- Merge layer: Blockify `distill` LLM call, with retry, XML parsing, hierarchical subcluster recursion for clusters above `MAX_CLUSTER_SIZE_FOR_LLM`.

Retrieval/search architecture:

- Local skill uses ChromaDB collections (`raw_ideablocks`, `distilled_ideablocks`) with cosine space.
- Docs recommend hybrid retrieval: dense vector search, BM25/sparse search, optional knowledge graph lookup, reciprocal rank fusion, cross-encoder reranking, and context assembly with metadata/citations.
- Integration docs show how IdeaBlocks become LangChain `Document`s, LlamaIndex `TextNode`s, Elastic documents, Milvus/Zilliz rows, Supabase pgvector records, or Cloudflare Vectorize entries.

Benchmark architecture:

- `BenchmarkRunner` loads raw and distilled ChromaDB blocks, extracts benchmark queries from raw blocks' `critical_question`, optionally reconstructs baseline chunks from source files, generates query/chunk embeddings, computes closest-match cosine distances, and reports vector, word/char, aggregate, enterprise projection, token, and cost metrics.
- HTML reports are Jinja2 templates with generated charts. Metric math is centralized in `benchmark/metrics.py`.

## Design Choices

- Corpus-side dedupe instead of prompt-side trimming. This reduces duplicate embeddings and top-k pollution rather than merely shortening the final prompt.
- Q/A record shape. `critical_question` makes every block query-addressable; `trusted_answer` keeps returned context compact and generation-ready.
- Source-provenance preservation. Merged blocks track `blockifyResultsUsed`, and raw blocks can be marked hidden/distilled instead of deleted.
- Iterative distillation. The service re-embeds merged results and increases threshold over iterations, allowing coarse duplicate removal first and tighter cleanup later.
- Hierarchical LLM merging. Large clusters are split deterministically by UUID ordering with roughly `sqrt(n) * 2` target subcluster size to stay within LLM context limits.
- ChromaDB first for local developer use. This makes the skill easy to run on a workstation, with production docs showing how to move the same IdeaBlock schema into other stores.
- Benchmark from user data. The harness is meant to calculate distance and token metrics on the user's local ChromaDB/source corpus rather than relying only on static claims.

## Strengths

- Clear, reusable abstraction: IdeaBlocks are compact enough for coding-agent context and structured enough for metadata filtering, citations, and governance.
- Good separation between ingestion, distillation, retrieval, and benchmarking scripts. Each stage can be replaced independently.
- Practical retrieval advice: docs correctly emphasize dense + BM25/sparse + metadata filters + reranking instead of vector-only search.
- Strong coding-agent applicability: the Claude Code skill demonstrates project-doc ingestion, local vector search, and search-before-coding workflow.
- Scale-aware dedupe design in service: LSH candidate reduction, cluster-level merging, intermediate saves, progress callbacks, and async job polling are useful implementation patterns.
- Benchmark harness has centralized math and tests for metric functions, which is better than burying ROI calculations in report templates.

## Weaknesses

- Major performance claims are not backed by reproducible checked-in benchmark outputs. The benchmark code can generate reports, but the README numbers are vendor claims unless rerun with API keys and a known corpus.
- Open implementation depends on external Blockify and OpenAI APIs for the core value path. Offline/air-gapped operation is mostly described as enterprise capability, not demonstrated by the reviewed community code.
- XML parsing is mostly regex-based. That is fragile for malformed XML, entity escaping, nested content, or output drift from LLMs.
- Documentation and code diverge in places. Some docs describe MinHash, FAISS IVF/PQ, PostgreSQL/Redis, and richer enterprise algorithms, while reviewed service code uses random-hyperplane LSH, dense cosine/NetworkX, and only SQLite/filesystem job stores are implemented.
- LSH random hyperplanes are not seeded, so candidate generation can be nondeterministic between runs.
- Direct API distillation script uses `SequenceMatcher` on `trusted_answer`, which is cheap but weaker than semantic embeddings for paraphrase-level duplicates.
- Tests are shallow. They cover health, simple similarity/LSH behavior, filesystem job store behavior, and benchmark math. They do not exercise the full ingest-distill-search pipeline, API failure modes, ChromaDB integration, or LLM response parsing deeply.
- A reviewed test imports `FileSystemJobStore`, while implementation defines `FilesystemJobStore`; this suggests at least one test path would fail once pytest is available.
- FastAPI CORS is `allow_origins=["*"]`; acceptable for demo/local use but not a hardened service default.
- The license is a custom Blockify Community License with revenue threshold, no-competing-product, and no-managed-service restrictions; this is not a permissive open-source license for reuse in competing data-optimization tooling.

## Ideas To Steal

- Use `critical_question + trusted_answer` as the atomic memory unit for coding-agent docs. It naturally supports search, citation, and answer assembly.
- Store both raw and distilled collections. Keep raw provenance but make distilled blocks the default retrieval target.
- Mark superseded blocks hidden/inactive instead of deleting them. This gives auditability and rollback for knowledge-base updates.
- Add corpus-side duplicate removal before vectorization in project memory pipelines. This can reduce embedding spend and retrieval noise more reliably than prompt compaction alone.
- Build a benchmark harness that compares baseline chunks against compressed memory units using the same queries, embeddings, and token-cost assumptions.
- Use metadata-first retrieval controls: entity type, tags, source document, document version, sensitivity, and review state.
- For large duplicate clusters, use deterministic hierarchical merging with source IDs preserved through each merge level.
- Package retrieval workflows as agent skills with explicit setup, ingest, distill, search, and benchmark commands.

## Do Not Copy

- Do not copy the metrics as universal truths. Reproduce vector distance, token count, and cost numbers on the target corpus.
- Do not use regex XML parsing as the long-term contract for production agent memory. Prefer a strict schema, tolerant XML parser, or JSON with validation and repair.
- Do not make a coding-agent memory layer depend on one proprietary ingestion/distillation API unless the project accepts that lock-in.
- Do not rely on raw `SequenceMatcher` for semantic dedupe across code/docs; embeddings or structured keys are needed for paraphrases and renamed concepts.
- Do not advertise unimplemented storage backends or algorithms. Keep docs aligned with the actual code path.
- Do not use wildcard CORS, broad API keys, or unbounded external calls in a shared agent service without hardening and quotas.
- Do not adopt the custom license terms blindly for Agentic Coding Lab artifacts; reuse ideas, not restricted implementation details.

## Fit For Agentic Coding Lab

Fit is conditional but high-value as a pattern source.

Best use:

- Project documentation memory where many docs repeat product descriptions, setup steps, or policy statements.
- Coding-agent search over ADRs, runbooks, onboarding docs, and design notes.
- Preprocessing layer for an MCP semantic-search server that returns compact Q/A facts instead of long passages.
- Evaluation pattern for token-efficiency experiments: compare chunk baseline vs structured memory units on distance, token count, and answer relevance.

Poor fit:

- Full adoption as-is, because core compression requires external Blockify API access and the license restricts competing data-optimization products.
- Runtime context compression inside an active coding session. This repo is a corpus-preprocessing system, not an in-prompt summarizer.
- Code understanding without additional code-aware parsing. The current chunkers target text/Markdown; code symbols, call graphs, and diffs would need a separate extractor.

Recommended Agentic Coding Lab artifact candidates:

- `memory-block` schema inspired by IdeaBlocks: `title`, `question`, `answer`, `source`, `tags`, `entities`, `confidence`, `reviewed_at`, `supersedes`.
- `research-distill` command: cluster existing notes, propose merges, preserve source paths, require human approval before replacing notes.
- `token-efficiency-eval` harness: baseline chunks vs distilled notes over a fixed query set, reporting retrieval diversity, token count, and citation/source coverage.
- MCP semantic-search server returning distilled blocks with source links and metadata filters, fused with exact `rg` results for coding tasks.

## Reviewed Paths

- `README.md`: product overview, metrics claims, repo structure, quick starts, API models, IdeaBlock format, FAQ, integrations list.
- `blockify-distillation-service/README.md`: service features, API usage, configuration, deployment, endpoints, algorithm overview.
- `blockify-distillation-service/app/api.py`: FastAPI routes, CORS, health/readiness/metrics, job submission and polling.
- `blockify-distillation-service/app/models.py`: request/response schema for IdeaBlocks, jobs, stats, health, webhooks.
- `blockify-distillation-service/app/config.py`: environment-driven settings for APIs, DB, job execution, algorithm thresholds, observability.
- `blockify-distillation-service/app/service.py`: high-level dedupe orchestration, hierarchical merge, merged-block construction, health status.
- `blockify-distillation-service/app/dedupe/algorithm.py`: iterative embedding, similarity search, clustering, LLM merge loop, stats, intermediate result generation.
- `blockify-distillation-service/app/dedupe/embeddings.py`: OpenAI embedding batching and text blob construction.
- `blockify-distillation-service/app/dedupe/lsh.py`: random-hyperplane LSH candidate generation and parallel similarity scoring.
- `blockify-distillation-service/app/dedupe/similarity.py`: dense cosine, FAISS flat k-NN helper, pair extraction.
- `blockify-distillation-service/app/llm/blockify.py`: Blockify `distill` API call, prompt construction, retry, XML/JSON parsing.
- `blockify-distillation-service/app/jobs.py`: async job manager, timeout wrapper, progress, persistence integration.
- `blockify-distillation-service/app/db/factory.py` and `app/db/filesystem.py`: implemented persistence backends and unimplemented advertised backends.
- `blockify-distillation-service/tests/test_api.py`, `test_lsh.py`, `test_similarity.py`, `test_db.py`, `conftest.py`: observed test coverage and test/import issue.
- `blockify-skill-for-claude-code/README.md`: local skill quick start, ChromaDB flow, distillation options.
- `blockify-skill-for-claude-code/skills/blockify-integration/SKILL.md`: agent-facing instructions and workflow.
- `blockify-skill-for-claude-code/skills/blockify-integration/scripts/ingest_to_chromadb.py`: local ingest/chunk/parse/embed/upsert path.
- `blockify-skill-for-claude-code/skills/blockify-integration/scripts/distill_chromadb.py`: direct API clustering, distillation, and source marking.
- `blockify-skill-for-claude-code/skills/blockify-integration/scripts/search_chromadb.py`: semantic search with filters and distilled fallback behavior.
- `blockify-skill-for-claude-code/skills/blockify-integration/scripts/run_full_pipeline.py`: orchestration across ingest, service/direct distillation, benchmark, summary.
- `blockify-skill-for-claude-code/skills/blockify-integration/scripts/run_benchmark.py`: benchmark CLI and environment validation.
- `blockify-skill-for-claude-code/skills/blockify-integration/scripts/benchmark/metrics.py`, `embeddings.py`, `report_generator.py`: benchmark metric math, embedding distance calculation, report generation.
- `blockify-skill-for-claude-code/skills/blockify-integration/tests/test_metrics.py`: benchmark math tests.
- `blockify-skill-for-claude-code/skills/blockify-integration/references/API.md`, `SCHEMA.md`, `DISTILLATION.md`: skill reference docs.
- `documentation/ARCHITECTURE-END-TO-END.md`: RAG pipeline, retrieval flow, Claude Code/MCP search pattern, vector DB architecture.
- `documentation/BLOCKIFY-DEEP-DIVE.md`: problem framing, IdeaBlock concept, metrics, processing pipeline.
- `documentation/DISTILLATION-SERVICE.md`: distillation algorithm documentation, scale expectations, API and config.
- `documentation/IDEABLOCK-STRUCTURE.md`: XML schema, fields, tags, entity types, technical manual format, validation guidance.
- `documentation/CLAUDE-CODE-BLOCKIFY-SKILL.md`: skill behavior, scripts, setup, simple JSON path.
- `documentation/RAG-AGENTIC-SEARCH-RESEARCH.md`: agentic RAG, hybrid search, context assembly patterns.
- `documentation/integrations/README.md`, `BLOCKIFY-LANGCHAIN.md`, `BLOCKIFY-LLAMAINDEX.md`, `BLOCKIFY-ELASTIC.md`: representative framework/search integration patterns.
- `demo-files-with-duplicates/County Government HR Case Study AirgapAI.md`: sampled duplicate-demo corpus style and benchmark-oriented content.
- `ENTERPRISE.md`, `SECURITY.md`, `LICENSE`: enterprise boundary, security reporting, and custom license constraints.
- `blockify-distillation-service/pyproject.toml`, `requirements.txt`, `blockify-skill-for-claude-code/skills/blockify-integration/requirements.txt`: dependencies and packaging.

Attempted tests:

- `rtk pytest -q` in both service and skill areas returned no collected tests through the `rtk` wrapper.
- `rtk python -m pytest -q ...` could not run because the active Python environment has no `pytest` installed.

## Excluded Paths

- `.git/`: cloned repository metadata; not relevant to architecture review.
- `assets/images/`: README/marketing images and prompts; binary/visual assets, no execution-path logic.
- `demo-files-with-duplicates/*.md` beyond one sampled file: synthetic/sample enterprise case-study corpus for demos and benchmark inputs; useful to know it exists, but not necessary to inspect every near-duplicate content file for architecture.
- `blockify-skill-for-claude-code/skills/blockify-integration/scripts/benchmark/templates/` and `styles.css`: HTML/CSS report presentation layer. Metric formulas and report orchestration were reviewed in Python; templates were excluded as UI/report-only.
- `blockify-distillation-service/helm/blockify-distillation/templates/` and chart YAML: deployment packaging. Reviewed README/config level for deployment capabilities; Kubernetes manifests do not change compression or retrieval architecture.
- `documentation/integrations/*.md` not listed under reviewed paths: repeated integration cookbooks for specific platforms. Representative RAG framework and search-engine integrations were reviewed; remaining guides follow the same upstream-Blockify-then-index pattern.
- `CONTRIBUTING.md`, `llms.txt`, `CLAUDE_DEPLOYMENT_NOTES.md`: contribution/deployment/meta guidance; not part of data optimization architecture.
- Python cache/test artifacts, if generated locally: execution byproducts, not source.
