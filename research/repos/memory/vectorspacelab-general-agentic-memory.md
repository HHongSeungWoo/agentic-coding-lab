# VectorSpaceLab/general-agentic-memory

- URL: https://github.com/VectorSpaceLab/general-agentic-memory
- Category: memory
- Stars snapshot: 848 (GitHub REST API, captured 2026-05-19)
- Reviewed commit: 565db2cc2518d377e44389b82aecf3cc129d5fe5
- Reviewed at: 2026-05-19T23:25:28+09:00
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong design reference for agent-readable filesystem memory and just-in-time research over stored context, but not safe to adopt as-is. Best ideas are the directory/README memory substrate, incremental taxonomy maintenance, explicit memorize/recall pattern for long-horizon work, and the research loop that plans retrieval, integrates evidence, and reflects on missing information. Do not copy the shell-tool execution model, weak path isolation, API/docs drift, untested core flows, or lack of privacy and scope controls.

## Why It Matters

`VectorSpaceLab/general-agentic-memory` is one of the more directly relevant memory repos for Agentic Coding Lab because it treats memory as something an agent can browse, not just vector-search. The root package builds a General Agentic Memory as a local file tree: raw content is split into chunks, summarized into memory records, placed into taxonomy directories, and indexed by generated `README.md` files. Query-time agents then explore that tree with `ls`, `cat`, and `grep`.

The repo also contains the original research implementation under `research/`. That path is a separate dual-agent system: a `MemoryAgent` writes concise abstracts and raw pages, while a `ResearchAgent` performs iterative planning, retrieval, integration, and reflection. Together, these two code paths show a practical split between high-fidelity offline storage and query-specific online context building.

For coding agents, the useful pattern is not "put everything in a vector DB." It is "store durable work artifacts in a human/auditable structure, then let the agent pull only relevant parts back into context." That maps well to repo conventions, bug investigations, build failures, design decisions, and long-running implementation sessions.

## What It Is

The repository has two related Python packages.

The root package, `gam`, is a product-oriented framework for text and video memory. It exposes a `Workflow("text" | "video")` SDK, `gam-add` and `gam-request` CLI commands, a FastAPI REST API, and a Flask web UI. Its active text path is `TextWorkflow -> TextGAMAgent -> TextChatAgent`. It stores memory as Markdown files and directories under a user-selected `gam_dir`.

The `research/` package, `gam-research`, is closer to the paper code. It exposes `MemoryAgent`, `ResearchAgent`, OpenAI/VLLM generators, page and memory stores, BM25/index/dense retrievers, TTL stores, benchmark scripts, and quickstart examples. Its memory store is JSON-backed when `dir_path` is provided.

The repo is in scope for the memory category because it implements ingestion, memory update, storage, retrieval, query-time research, retention via TTL, long-horizon offloading, and multimodal memory. It is not an MCP server, not a production memory service, and not a security-hardened storage layer.

## Research Themes

- Token efficiency: Strong ideas. The root path compresses raw inputs into chunk memories and directory READMEs, then query agents browse selectively instead of loading everything. `TextChatAgent` deduplicates already-read files and summarizes conversation history after a 60,000-character threshold. The long-horizon demo replaces large search tool outputs with short `[GAM Memory Result]` summaries.
- Context control: Moderate. The filesystem tree gives inspectable structure and query-time navigation, but there is no tenant/project/agent scope, no privacy class, no metadata filter contract, and path isolation is weak.
- Sub-agent / multi-agent: Moderate. The design clearly separates memory-building agents from chat/research agents. The research package has `MemoryAgent` and `ResearchAgent`; the product path has `TextGAMAgent` and `TextChatAgent`. It does not coordinate multiple concurrent agents or define conflict resolution.
- Domain-specific workflow: Strong concept, generic implementation. The long-horizon example is directly relevant to coding-agent workflows: search, memorize, replace context, recall later. The repo does not ship coding-specific schemas for source files, tests, commands, incidents, or architectural decisions.
- Error prevention: Mixed. There are fallbacks for LLM failures, collision-safe filenames, some retrieval deduplication, and TTL unit tests. There are also important safety gaps around shell command execution, path traversal, command injection, missing auth, and untested core ingestion/query behavior.
- Self-learning / memory: Strong fit. The system supports incremental addition, generated taxonomy, periodic reorganization after repeated additions, and query-time deep research. The research path stores abstracts that influence future planning.
- Popular skills: Useful patterns include agent filesystem memory, README-as-index, JIT retrieval, memorizer/researcher split, long-horizon memorize/recall tools, TTL memory cleanup, and multimodal segment memory.

## Core Execution Path

The main product text path starts at `Workflow("text", gam_dir=...)`. `BaseWorkflow` lazily builds an OpenAI-compatible generator, a `LocalWorkspace`, and a `GAMTree` loaded from disk. `TextWorkflow.add()` delegates to a cached `TextGAMAgent`; `TextWorkflow.request()` reloads the latest tree and creates a fresh `TextChatAgent`.

`TextGAMAgent.add()` reloads the tree and branches on whether the GAM is empty. For first creation, `_create()` resolves file and direct-text inputs, optionally chunks each text, generates a memory record per chunk, builds a taxonomy from chunk TLDRs, assigns chunks to directories, writes directories/files, and generates READMEs bottom-up. The final tree stores chunk Markdown files with the original content and uses directory READMEs as the navigational summary layer. Optional `output_dir` chunk dumps preserve the richer `TLDR`, `Memory`, and `Original Content` structure.

Chunking is LLM-assisted. The agent first generates a document summary and format guidance, then slides through text using token windows. Each window asks the LLM for semantic split lines; if the model refuses while pending content grows too large, the code forces a split. Tiny chunks are merged after splitting. Memory generation runs in a `ThreadPoolExecutor` and asks for `title`, `tldr`, and `memory`.

Taxonomy creation is also LLM-assisted. `_generate_taxonomy_from_tldrs()` processes TLDR batches, `_assign_chunks_to_taxonomy()` classifies each chunk into a taxonomy path, and `_execute_batch_organization_parallel()` creates only directories that contain chunks or needed ancestors. It then generates READMEs bottom-up so parent summaries can reference child summaries.

Incremental add follows a different path. `_add_incremental()` summarizes new chunks, asks whether they belong to the existing tree, then either adds them into existing directories or creates a new top-level topic. It merges the root README after additions and triggers taxonomy reorganization after five incremental adds or when `force_reorganize=True`.

The product query path is a ReAct-style filesystem explorer. `TextChatAgent.request()` builds a system prompt from the exploration guide plus root README/tree overview, calls the LLM with OpenAI tool specs, executes `ls`, `cat`, and `grep` through the workspace, appends tool results, and stops when the model emits an `<answer>` JSON block. It tracks files read and directories explored, caps `cat` output at 30,000 characters, caps `grep` file output at 10,000 characters, and replaces repeated file content with a dedup note.

The research path is smaller and more benchmark-oriented. `MemoryAgent.memorize(message)` loads `MemoryState`, prompts an LLM to produce one abstract using prior abstracts as context, appends the abstract if unique, and writes a `Page` containing the raw message plus a `[ABSTRACT]` header. `InMemoryMemoryStore` persists to `memory_state.json`; `InMemoryPageStore` persists to `pages.json`.

`ResearchAgent.research(request)` updates retrievers when page count changes, then loops for `max_iters`. Each iteration loads current abstracts, asks the LLM for a `SearchPlan`, runs planned keyword/vector/page-index retrieval, deduplicates hits by page ID, integrates evidence into a running `Result`, and reflects on whether the information is enough. If not enough, it asks the LLM to generate follow-up retrieval requests and repeats.

The retriever layer has three channels. `IndexRetriever` snapshots pages and fetches by explicit page index. `BM25Retriever` builds a Pyserini/Lucene index over page content. `DenseRetriever` uses FlagEmbedding plus FAISS, or an external embedding API, and aggregates scores across multiple semantic queries. TTL stores add timestamped cleanup for abstracts and pages.

The long-horizon example wraps an external BM25 searcher with `search`, `memorize`, and `recall` tools. `memorize` stores selected search results in GAM, runs a GAM chat query to produce a refined memory result, and mutates the live tool-call history so raw search output is replaced by a short memory tag. That is the clearest Agentic Coding Lab pattern in the repo.

## Architecture

The root package architecture has five layers: generator, workspace, tree, memory builder, and query agent. The generator wraps OpenAI-compatible chat completions and optional JSON schema output. The workspace runs shell commands locally or inside Docker. The tree is a read-only in-memory view of files on disk. The memory builder mutates the filesystem through workspace commands. The query agent explores the filesystem through tool calls.

Storage for root `gam` is intentionally simple. A GAM directory contains `.gam_meta.json`, generated directories, chunk `.md` files, and generated `README.md` summaries. The README files are not decoration; they are the primary index that guides query-time exploration. For video, the tree contains segment directories with generated segment summaries, subtitles, and clips.

The research package architecture is more conventional. `MemoryState` is a list of abstracts. `Page` stores a header, raw content, and metadata. Stores are protocol-shaped but concrete implementations are in-memory plus optional JSON persistence. Retriever indices are separate filesystem artifacts under configured index directories.

The access surfaces are broader than the core memory architecture. CLI calls build the same agents directly. REST routes construct `LocalWorkspace`, `GAMTree`/`VideoGAMTree`, and agents per request. The Flask web app and static assets provide browsing/pipeline UI, but do not define the memory model.

There is no central policy layer. Model calls, filesystem writes, retrieval, retention, and API access are handled inside individual components. That keeps the prototype understandable, but it leaves scoping, access control, redaction, and audit as caller responsibilities.

## Design Choices

GAM chooses an agent-readable filesystem over opaque vector memory for the product path. This is a good fit for coding agents because Markdown files and READMEs can be inspected, diffed, repaired, and versioned.

The system keeps raw content available. Memory summaries guide navigation, but the chunk files preserve original content so the query agent can read source-like evidence before answering.

The repo embraces just-in-time context assembly. The expensive work at query time is not only vector search; it can be multi-round filesystem exploration or the research package's plan/search/integrate/reflect loop.

LLMs are used for both content semantics and storage layout. They decide chunk boundaries, memory records, taxonomy directories, chunk assignments, README descriptions, incremental placement, and reorganization. This maximizes adaptivity but creates a large validation burden.

The product code separates memory construction from memory use. `TextGAMAgent` writes and reorganizes the store; `TextChatAgent` only explores and answers. That boundary is useful for future permissions: writers and readers can be governed differently.

The research code separates memorization from research. Abstracts are cheap planning context, while pages remain detailed evidence retrieved by keyword/vector/page ID. This is a useful pattern for coding memories: compact durable summaries plus retrievable raw artifacts.

The repo supports multiple deployment surfaces before hardening the core. SDK, CLI, REST, and web are all present; safety, tests, and API consistency lag behind.

## Strengths

The filesystem memory model is practical and inspectable. It gives agents a small, familiar tool interface and gives humans a way to audit or repair memory manually.

The README-as-index pattern is strong. Bottom-up README generation creates a hierarchy of summaries that can guide selective recall without dumping every chunk into context.

The long-horizon demo shows the right operational idea: offload bulky tool results into memory, replace immediate context with a compact result, and recall details later when needed.

The research loop has a clear control structure. Planning, retrieval, integration, and reflection are explicit phases, which makes it easier to test and reason about than a single hidden RAG call.

Incremental add is more thoughtful than append-only memory. The code checks whether new material belongs in the current structure, can expand with a new topic, updates affected READMEs, and periodically asks for reorganization.

The code supports local and Docker workspaces. Docker is not used by default, but the abstraction points in the right direction for sandboxed memory exploration.

The TTL stores solve a real production concern: unbounded growth. They support days/hours/minutes/seconds TTL, auto-cleanup, manual cleanup, stats, persistence, and backward compatibility.

The repo includes benchmark scripts for LoCoMo, HotpotQA, RULER, and NarrativeQA. They are not lightweight tests, but they show how the authors intended to measure memory-assisted long-context QA.

## Weaknesses

The shell execution model is unsafe for untrusted inputs. `LocalWorkspace.run()` uses `subprocess.run(..., shell=True)`, and model-selected tool arguments flow into commands. `BaseTool.resolve_path()` does not block `..`, absolute path tricks, or escaping the workspace. `GrepTool` interpolates the search pattern into a shell command without robust escaping. `TextGAMAgent` writes and moves files through shell strings. This needs a real path sandbox and structured filesystem APIs before production use.

Privacy and scope controls are mostly absent. There is no user/repo/project namespace, no auth on REST by default, no secret/PII redaction, no memory classification, no consent gate for external LLM calls, and no audit trail for memory writes or reorganization.

The root product path sends raw document chunks and directory summaries to the configured LLM backend. That may be acceptable for research, but coding-agent memory often includes proprietary code, logs, credentials, customer data, or unreleased design details.

Some README/API examples drift from code. `research/README.md` and `research/examples/quickstart/ttl_usage.py` import `TTLMemoryStore` and `TTLPageStore` from `gam_research`, but `research/gam_research/__init__.py` does not export them. The TTL usage example also contains a syntax error in `regular_store.add"Old abstract 1")`.

There is a schema mismatch in the product text chunk analysis path. `TextGAMAgent` imports `CHUNK_FORMAT_ANALYSIS_SCHEMA` and `MEMORY_FORMAT_ANALYSIS_SCHEMA` from `src/gam/schemas/chunk_schemas.py`, but the parsing code expects keys defined in `src/gam/prompts/chunker_prompts.py`. With structured output enabled, format guidance can be empty or degraded.

Several latent code paths appear broken or stale. `GAMTree.create(...)` is referenced in CLI, REST, docs comments, and web routes, but the tree class exposes `create_empty(...)`. `BM25Retriever.load()` and `DenseRetriever.load()` call `InMemoryPageStore.load(self._pages_dir()).load()`, even though `load` is an instance method. `research/tests/run_ttl_tests.py` hard-codes a stale absolute path from another developer machine.

The final product GAM chunk files do not store the generated `memory` and `tldr` alongside original content. Those summaries are used to create READMEs and optional output chunks, but the main organized files contain only title, timestamp, and raw original content. That makes later memory repair less transparent.

The research memory model is minimal. Abstracts are plain strings with no source IDs, timestamps, confidence, privacy class, tags, or update history. Page IDs are list indices, which can become unstable if pages expire or stores are compacted.

Tests cover TTL, not the main memory system. I found no focused tests for `TextGAMAgent` chunking/organization, `TextChatAgent` query behavior, workspace path safety, REST routes, CLI first-run behavior, retriever consistency, or long-horizon memorize/recall mutation.

The video path has signs of integration drift. `VideoGAMAgent` saves clips as `video_clip.mp4` under segment directories whose names include ID/title/timestamps, while `InspectVideoTool` expects `segments/{target_segment}/video.mp4`.

## Ideas To Steal

Use a repo-local memory filesystem. Store durable coding-agent memories as Markdown in a navigable directory tree with generated and human-editable READMEs.

Make root README and directory READMEs first-class context indexes. A coding agent should start recall from compact structure summaries, then drill into raw evidence only when needed.

Separate memory building from memory answering. A write-capable memorizer can ingest and reorganize; a read-focused query agent can explore with constrained tools.

Keep raw evidence near summaries. For coding work, store the test output, command, file path, commit, error, or user decision alongside the abstract so future agents can verify before acting.

Adopt the long-horizon `memorize`/`recall` pattern. After large search, log, or test outputs, save selected evidence into memory and replace immediate context with a compact, source-linked summary.

Use just-in-time research as a memory retrieval mode. A useful memory system can plan subqueries, search multiple channels, integrate evidence, check completeness, and iterate instead of returning top-k chunks once.

Add retention controls early. TTL stores, stats, and cleanup hooks are simple but important for long-running agent memory.

Use generated taxonomy with explicit reorganization thresholds. Agentic Coding Lab could periodically ask whether memory categories need merge/split/rename, but only apply validated file operations.

Expose separate LLM configs for memory construction and chat/research. Cheap models may summarize routine chunks; stronger models can answer complex questions over the memory.

## Do Not Copy

Do not execute model-controlled filesystem tools through raw shell commands. Use structured path APIs, normalize paths, enforce workspace containment, and reject unsafe patterns before any command runs.

Do not let memory paths, filenames, and move operations be direct LLM output without validation. Require a constrained operation schema and verify every target stays inside the memory root.

Do not send raw coding memory to external LLMs by default. Add local-model options, redaction, allowlists, and explicit privacy classes.

Do not rely on README claims without exercising the code path. This repo has useful docs, but several quickstart and helper paths are stale.

Do not use list indices as durable page IDs if retention or deletion can happen. Use stable IDs and store source/provenance metadata.

Do not store only abstracts in planning memory. For coding agents, memory needs task ID, repo, branch, source file, command, outcome, timestamp, confidence, and supersession relationships.

Do not treat generated READMEs as trusted truth. They should be helpful indexes with provenance and regeneration checks, not authoritative facts that override raw evidence.

Do not expose a REST or web memory surface without auth and filesystem root policy. Memory services are sensitive by default.

Do not ship memory features with tests only for TTL. Ingestion, retrieval, updates, reorganization, and safety controls need deterministic tests with mocked LLM outputs.

## Fit For Agentic Coding Lab

Fit is high as a design source and low as a direct dependency. The repo contains several patterns Agentic Coding Lab should reuse: Markdown/filesystem memory, directory summaries as navigational context, explicit memorizer/query-agent split, long-horizon offload and recall, and iterative research over stored evidence.

The best adapted version would be narrower and safer: a repo-scoped memory directory, stable JSON front matter for each memory file, generated README indexes, validated write operations, no raw shell tools, local-first summarization, source-linked raw evidence, and deterministic tests for every memory transition.

For coding-agent memories, the schema should be stricter than GAM's generic chunks. Useful fields include `repo_id`, `worktree`, `task_id`, `source_kind`, `source_path`, `command`, `observed_error`, `resolution`, `confidence`, `privacy_class`, `created_at`, `last_verified_at`, and `supersedes`.

The JIT research loop is worth adapting for "what do we already know about this repo/problem?" A research agent can plan memory subqueries, inspect linked evidence, integrate a compact working summary, and continue only if important facts are missing.

The major blocker is safety. Before borrowing the agent filesystem idea, Agentic Coding Lab needs a hardened memory workspace abstraction with path containment, no shell interpolation, redaction, scoped storage, auditable writes, and bounded retrieval.

## Reviewed Paths

- `/tmp/myagents-research/vectorspacelab-general-agentic-memory/README.md`: product positioning, SDK/CLI/REST/web access surfaces, text/video/long-horizon tasks, configuration, and relation to research package.
- `/tmp/myagents-research/vectorspacelab-general-agentic-memory/pyproject.toml` and `/tmp/myagents-research/vectorspacelab-general-agentic-memory/requirements.txt`: root package metadata, optional dependencies, CLI entrypoints, and runtime dependency shape.
- `/tmp/myagents-research/vectorspacelab-general-agentic-memory/examples/README.md`: example map for long text, long video, long horizon, REST, and web.
- `/tmp/myagents-research/vectorspacelab-general-agentic-memory/examples/docs/sdk_usage.md`: `Workflow` API, low-level text/video agent usage, parameters, and API reference.
- `/tmp/myagents-research/vectorspacelab-general-agentic-memory/examples/docs/cli_usage.md`: `gam-add`, `gam-request`, model/env options, text/video arguments, and JSON output behavior.
- `/tmp/myagents-research/vectorspacelab-general-agentic-memory/examples/docs/rest_api_usage.md`: FastAPI endpoints, request/response shapes, and server invocation.
- `/tmp/myagents-research/vectorspacelab-general-agentic-memory/examples/long_horizon/run.py`: search/memorize/recall tool design, context replacement with `[GAM Memory Result]`, and long-horizon workflow demonstration.
- `/tmp/myagents-research/vectorspacelab-general-agentic-memory/src/gam/workflows/base.py`, `text_workflow.py`, `video_workflow.py`, and `workflows/__init__.py`: SDK entrypoint, generator/workspace/tree setup, text/video add and request paths.
- `/tmp/myagents-research/vectorspacelab-general-agentic-memory/src/gam/agents/text_gam_agent.py`: text ingestion, chunking, memory generation, taxonomy, README generation, incremental add, and reorganization behavior.
- `/tmp/myagents-research/vectorspacelab-general-agentic-memory/src/gam/agents/text_chat_agent.py`: query-time ReAct loop, tool execution, history summarization, deduplication, and answer extraction.
- `/tmp/myagents-research/vectorspacelab-general-agentic-memory/src/gam/agents/video_gam_agent.py` and `video_chat_agent.py`: video segmentation/memory creation and multimodal query path.
- `/tmp/myagents-research/vectorspacelab-general-agentic-memory/src/gam/core/tree.py` and `core/node.py`: read-only tree model, disk loading, README summaries, and node representation.
- `/tmp/myagents-research/vectorspacelab-general-agentic-memory/src/gam/workspaces/local_workspace.py`, `docker_workspace.py`, and `workspaces/base.py`: command execution boundary, local/Docker behavior, and workspace metadata.
- `/tmp/myagents-research/vectorspacelab-general-agentic-memory/src/gam/tools/base.py`, `ls_tool.py`, `cat_tool.py`, `grep_tool.py`, `bm25_search_tool.py`, and `inspect_video_tool.py`: agent tool specs, path resolution, content limits, optional BM25 search, and video inspection.
- `/tmp/myagents-research/vectorspacelab-general-agentic-memory/src/gam/generators/openai_generator.py`, `sglang_generator.py`, and `generators/config.py`: LLM boundary, structured output handling, retries, model config, and batch generation.
- `/tmp/myagents-research/vectorspacelab-general-agentic-memory/src/gam/prompts/chunker_prompts.py`, `gam_prompts.py`, `chat_prompts.py`, `skill_prompts.py`, and `video_gam_prompts.py`: chunking, memory, taxonomy, README, query, skill, and video prompts.
- `/tmp/myagents-research/vectorspacelab-general-agentic-memory/src/gam/schemas/chunk_schemas.py`, `chat_schemas.py`, and `video_schemas.py`: memory chunk, taxonomy, incremental add, chat result, and video process schemas.
- `/tmp/myagents-research/vectorspacelab-general-agentic-memory/src/gam/cli.py`: CLI construction, argument mapping, and first-run tree behavior.
- `/tmp/myagents-research/vectorspacelab-general-agentic-memory/src/gam/rest_api/routes.py` and `rest_api/models.py`: REST add/query route logic, request models, and response models.
- `/tmp/myagents-research/vectorspacelab-general-agentic-memory/research/README.md`: paper-code architecture, quickstart, TTL docs, dataset setup, and benchmark reproduction commands.
- `/tmp/myagents-research/vectorspacelab-general-agentic-memory/research/pyproject.toml`, `requirements.txt`, and `setup.py`: research package metadata and dependencies.
- `/tmp/myagents-research/vectorspacelab-general-agentic-memory/research/gam_research/agents/memory_agent.py` and `research_agent.py`: dual-agent memory/research execution path.
- `/tmp/myagents-research/vectorspacelab-general-agentic-memory/research/gam_research/schemas/memory.py`, `page.py`, `ttl_memory.py`, `ttl_page.py`, `search.py`, `result.py`, and `tools.py`: research memory/page stores, TTL stores, search plans, hits, and result schemas.
- `/tmp/myagents-research/vectorspacelab-general-agentic-memory/research/gam_research/retriever/index_retriever.py`, `bm25.py`, `dense_retriever.py`, and `base.py`: page-index, BM25, dense/FAISS, API embedding, update, and load behavior.
- `/tmp/myagents-research/vectorspacelab-general-agentic-memory/research/gam_research/generator/openai_generator.py`, `vllm_generator.py`, and config modules: research LLM backend behavior.
- `/tmp/myagents-research/vectorspacelab-general-agentic-memory/research/gam_research/prompts/memory_prompts.py` and `research_prompts.py`: abstract generation, planning, integration, completeness check, and follow-up request prompts.
- `/tmp/myagents-research/vectorspacelab-general-agentic-memory/research/examples/quickstart/basic_usage.py`, `model_usage.py`, `ttl_usage.py`, and `README.md`: research quickstarts, retriever setup, and TTL examples.
- `/tmp/myagents-research/vectorspacelab-general-agentic-memory/research/eval/hotpotqa_test.py`, `locomo_test.py`, `narrativeqa_test.py`, and `ruler_test.py`: benchmark harness structure, chunk/session preparation, memory/research generation, and metrics.
- `/tmp/myagents-research/vectorspacelab-general-agentic-memory/research/tests/README.md`, `TEST_RESULTS.md`, `test_ttl_memory.py`, `test_ttl_page.py`, `test_ttl_before_after.py`, `test_ttl_standalone.py`, and `run_ttl_tests.py`: TTL test coverage, recorded results, and stale direct-loader script.

## Excluded Paths

- `/tmp/myagents-research/vectorspacelab-general-agentic-memory/.git/`: VCS internals; exact reviewed commit is recorded separately.
- `/tmp/myagents-research/vectorspacelab-general-agentic-memory/README_zh.md` and `/tmp/myagents-research/vectorspacelab-general-agentic-memory/research/README_CN.md`: Chinese-language duplicates of reviewed English documentation; excluded to avoid duplicate evidence.
- `/tmp/myagents-research/vectorspacelab-general-agentic-memory/research/assets/GAM-memory.png`: binary architecture image. I relied on README text and executable code paths for architecture because the bitmap does not define runtime behavior.
- `/tmp/myagents-research/vectorspacelab-general-agentic-memory/src/gam/web/templates/` and `/tmp/myagents-research/vectorspacelab-general-agentic-memory/src/gam/web/static/`: UI templates, CSS, and JavaScript; excluded as UI-only assets. The REST/API execution path was reviewed separately.
- `/tmp/myagents-research/vectorspacelab-general-agentic-memory/src/gam/web/routes/` except API-adjacent route behavior surfaced through docs and REST routes: Flask page/pipeline browsing endpoints are UI orchestration, not core memory ingestion/retrieval design.
- `/tmp/myagents-research/vectorspacelab-general-agentic-memory/research/download_data/` and `research/scripts/download_data.sh`: dataset download plumbing; benchmark invocation and data layout were reviewed from README and eval scripts.
- Generated benchmark outputs, dataset directories, retriever index directories, temporary chunk output directories, Python bytecode caches, local virtual environments, and test caches if produced locally: generated/runtime artifacts, not source architecture.
- Vendored dependencies and lockfiles: none were present in the reviewed checkout.
