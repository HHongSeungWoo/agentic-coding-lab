# volcengine/MineContext

- URL: https://github.com/volcengine/MineContext
- Category: context-control
- Stars snapshot: 5,316 (GitHub REST API, captured 2026-05-12)
- Reviewed commit: 171c7a9ea8091e326ddcf0f10718aa1b58c83c65
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong reference for proactive, typed context capture and retrieval, especially for personal work memory. Useful for Agentic Coding Lab patterns, but not a drop-in dependency because tests are absent, token budgeting is weak, several documented paths are incomplete, and safety defaults are permissive.

## Why It Matters

MineContext is a concrete context-control system rather than a prompt-only proposal. It captures screenshots, documents, vault notes, web links, and monitored files, converts them into typed memories, stores them locally, retrieves them through context-type tools, and runs scheduled generators for activities, tips, tasks, and daily reports.

For Agentic Coding Lab, the interesting part is the full loop: raw evidence becomes structured memory, retrieval is mediated by type-specific tools, and later agents ask for context through an iterative sufficiency check rather than blindly stuffing all history into a prompt.

## What It Is

MineContext is a Python FastAPI backend plus an Electron/React desktop UI. The backend initializes configuration, prompts, local storage, LLM clients, capture components, processors, retrieval tools, a context-agent workflow, and scheduled proactive jobs.

The main memory store is Chroma, with one collection per context type and another collection for generated tasks. SQLite stores app artifacts such as vault documents, conversations, messages, activities, tips, reports, monitoring logs, and task rows. It is local-first by default under an application data directory, with configurable OpenAI-compatible chat, embedding, and vision models.

## Research Themes

- Token efficiency: Mixed. MineContext has chunking, vector search, small `top_k` defaults, a two-iteration context gathering loop, hourly report compression, screenshot batch merging, and task deduplication. It does not have an explicit token budget, packing strategy, truncation policy, or hard cap on assembled context size.
- Context control: Strong. It defines activity, intent, semantic, procedural, state, knowledge, and entity contexts, stores them separately, gives the agent type-specific retrieval tools, and asks the LLM to judge context sufficiency before answering.
- Sub-agent / multi-agent: Limited. The context agent is a single workflow with intent, context, and executor nodes. Tool calls run in parallel, but there are no durable specialist subagents; reflection code is present but disabled in the main execution path.
- Domain-specific workflow: Strong for personal productivity and desktop activity memory. The same pattern can map to coding evidence such as diffs, shell output, failing tests, issue text, PR discussion, and design notes.
- Error prevention: Moderate. It uses pHash screenshot deduplication, vector deduplication for generated tasks, JSON extraction prompts, entity normalization, settings validation calls, and tool-result validation prompts. Weaknesses are the lack of tests/evals and several paths where docs and code disagree.
- Self-learning / memory: Strong conceptually. Entity profiles, typed memory, screenshot memory merging, scheduled summaries, daily reports, tips, and task generation all build reusable memory. Some advanced memory-compression features are disabled by default and brittle if enabled.
- Popular skills: Screenshot understanding, document chunking, semantic retrieval, entity profiling, context sufficiency checks, proactive summaries, activity extraction, and task extraction.

## Core Execution Path

`opencontext start` loads the merged YAML/user configuration, initializes prompts, storage, LLM/VLM clients, context operations, capture components, processors, the context consumption manager, the completion service, and monitoring. It then starts capture components and serves FastAPI.

Capture components produce `RawContextProperties`. Screenshot capture uses `mss` and saves monitor images. Folder monitoring polls configured folders and emits file-created/file-updated events. Vault monitoring polls SQLite vault documents. Web-link capture can convert pages or PDFs into local markdown/files. HTTP routes can also add screenshots, files, and URLs.

`ProcessorManager` routes raw inputs by source type. Screenshots go to `ScreenshotProcessor`; local files, vault documents, and web links go to `DocumentProcessor`. The document path converts or extracts text, optionally uses a VLM for visual pages, chunks text semantically, creates `knowledge_context` chunks, vectorizes them, and upserts them to Chroma. The screenshot path resizes and pHash-deduplicates images, batches VLM extraction, asks an LLM to merge new and cached context items by type, refreshes entity profiles, vectorizes the results, and upserts them.

Interactive chat enters `ContextAgent`. The workflow classifies intent, skips retrieval for simple chat, and otherwise runs a context node. That node asks the LLM whether current context is sufficient, asks it to select retrieval tools if not, executes those tools in parallel, validates tool results with another LLM call, and repeats up to two iterations. The executor then streams the final answer or document operation with the collected context.

Proactive jobs run from `ConsumptionManager`. Realtime activity monitoring summarizes recent activity and intent contexts into SQLite activity rows. Smart tips query recent typed contexts plus previous tips. Smart task extraction queries recent activities and task-relevant contexts, then vector-deduplicates new tasks. Daily reports chunk a day into hourly windows, summarize each window, and merge the summaries into a vault report.

## Architecture

The code is layered around capture, processing, storage, retrieval tools, agent workflow, proactive generation, and UI. The backend owns the actual context path; the frontend mostly configures settings, capture UX, conversations, and display.

Core state flows through `RawContextProperties`, `ProcessedContext`, `ContextProperties`, and `Vectorize`. `ContextType` is the central taxonomy, and `get_llm_context_string()` is the common serialization used when contexts are passed back to LLM prompts.

Storage is split intentionally. Chroma stores vector-searchable contexts in type-specific collections. SQLite stores relational application data and conversation artifacts. Configuration and prompts are YAML-based with user overrides, making model providers, capture sources, schedules, prompts, and route authentication adjustable without code changes.

Documentation mentions MCP as part of the consumption layer, and frontend IPC constants include MCP names, but this reviewed commit does not contain a backend MCP server execution path.

## Design Choices

MineContext makes context type explicit instead of treating memory as one flat vector pile. That choice enables type-specific prompts, retrieval tools, retention ideas, and generated artifacts.

The system uses LLMs as planners and validators. The context node does not hard-code a retrieval recipe; it asks the model to choose tools, executes them, then asks the model to filter relevance and judge sufficiency. This is flexible, but it also makes quality dependent on prompt behavior and model compliance.

The screenshot processor treats visual desktop activity as first-class evidence. It extracts multiple context types from one screenshot batch, merges batches by context type, and attaches entities. This is a useful pattern for turning noisy raw telemetry into typed memory.

Document ingestion separates visual and text-heavy pages. PDFs, DOCX, markdown, images, spreadsheets, JSONL, and FAQ spreadsheets have different conversion paths, with semantic chunking for text and VLM calls for visual pages.

The proactive layer is a consumer of memory, not a separate capture system. Activities, tips, tasks, and reports are generated from the same typed contexts that answer chat queries.

## Strengths

- Real end-to-end implementation of capture, processing, retrieval, answer generation, and proactive synthesis.
- Clear context taxonomy that separates activity, intent, semantic knowledge, procedures, state, knowledge chunks, and entities.
- Strong prompt assets for screenshot extraction, screenshot batch merging, document chunking, context collection, sufficiency checks, and generated artifacts.
- Local-first storage and configurable OpenAI-compatible model endpoints.
- Practical deduplication in several places: screenshot pHash, entity matching, and vector similarity for generated tasks.
- Retrieval tools expose context type, time range, and entity-oriented parameters, giving the agent a better interface than raw vector search.
- Scheduled summaries show how short-term activity can become durable artifacts for later retrieval.

## Weaknesses

- No tests or eval suites were present in the reviewed repository files, so regressions in context extraction, retrieval, and agent assembly are hard to detect.
- There is no explicit context token budget or deterministic packing layer before final answer generation.
- Chroma search builds filters for time and metadata but explicitly ignores `entities`, so retrieval tools can ask for entity filters that the vector backend does not enforce.
- Route authentication is disabled by default, and the enabled mode has broad excluded path patterns.
- API keys are stored in user YAML settings, and debug helpers can persist full prompts/responses locally; both need stricter handling for sensitive coding workspaces.
- The web-link upload route calls `submit_url` with an extra argument, while `submit_url` accepts only the URL. The web-link capture path also references `crawl4ai`, which is not listed in `pyproject.toml`.
- Documentation and frontend constants mention MCP, but no backend MCP server path was found.
- Optional memory-merger and cross-type evolution paths are disabled by default and contain brittle references to attributes that are not initialized in the constructor.
- Runtime settings update code imports `opencontext.opencontext`, which does not match the backend module layout and is caught as a warning path.
- The context-collection prompt asks the model to choose three to five tools, but the workflow does not enforce that range and only caps iterations.

## Ideas To Steal

- Use a small, explicit memory taxonomy and give each type its own retrieval tool.
- Add a context-sufficiency step before expensive retrieval, then validate tool results before final assembly.
- Convert raw activity into typed memory through extraction prompts, not just embeddings.
- Keep proactive generation downstream of the same memory store used for chat.
- Store source pointers such as screenshot paths or document metadata with generated summaries so users can inspect evidence.
- Maintain prompts as editable config with import/export and debug histories, while adding privacy controls before adopting the pattern.
- Use vector similarity to deduplicate generated action items against both historical and in-batch candidates.
- Separate raw capture, processed memory, generated artifacts, and conversations into different stores/contracts.

## Do Not Copy

- Do not copy the whole desktop screenshot/VLM dependency for coding agents without a narrower evidence model.
- Do not rely on LLM-planned retrieval without deterministic token budgets, hard caps, and evals.
- Do not store secrets or full debug transcripts in plain local files without clear user controls.
- Do not claim integrations such as MCP unless the execution path exists.
- Do not expose route auth as opt-in only for a context server that can contain private workspace data.
- Do not ship retrieval filters that appear supported at the tool layer but are ignored by the backend.
- Do not make memory compression paths optional but untested if downstream behavior depends on them.

## Fit For Agentic Coding Lab

MineContext is a high-value reference for context-control design, especially typed memory, retrieval tool interfaces, proactive summaries, and context sufficiency loops. It should influence Agentic Coding Lab architecture more than its implementation should be reused.

The best adaptation is a coding-focused version: capture git diffs, shell commands, test output, editor diagnostics, issue/PR text, design docs, and agent decisions; convert them into activity, intent, procedural, state, knowledge, and entity memories; retrieve them with type-aware tools; and assemble final context under a deterministic token budget with citations and eval coverage.

## Reviewed Paths

- `README.md`, `README_zh.md`, `src/architecture-overview.md`, `SECURITY.md`, `pyproject.toml`.
- `config/config.yaml`, `config/prompts_en.yaml`, `config/prompts_zh.yaml`.
- `opencontext/cli.py`, `opencontext/server/opencontext.py`, `opencontext/server/component_initializer.py`, `opencontext/server/context_operations.py`.
- `opencontext/server/routes/agent_chat.py`, `opencontext/server/routes/context.py`, `opencontext/server/routes/documents.py`, `opencontext/server/routes/screenshots.py`, `opencontext/server/routes/settings.py`, `opencontext/server/middleware/auth.py`.
- `opencontext/context_capture/base.py`, `opencontext/context_capture/screenshot.py`, `opencontext/context_capture/folder_monitor.py`, `opencontext/context_capture/vault_document_monitor.py`, `opencontext/context_capture/web_link_capture.py`.
- `opencontext/managers/capture_manager.py`, `opencontext/managers/processor_manager.py`, `opencontext/managers/consumption_manager.py`.
- `opencontext/context_processing/processors/document_processor.py`, `opencontext/context_processing/processors/screenshot_processor.py`, `opencontext/context_processing/processors/entity_processor.py`.
- `opencontext/context_processing/chunker/document_text_chunker.py`, `opencontext/context_processing/chunker/chunkers.py`.
- `opencontext/context_processing/merger/context_merger.py`, `opencontext/context_processing/merger/merge_strategies.py`, `opencontext/context_processing/merger/cross_type_relationships.py`.
- `opencontext/models/context.py`, `opencontext/models/enums.py`.
- `opencontext/storage/global_storage.py`, `opencontext/storage/unified_storage.py`, `opencontext/storage/backends/chromadb_backend.py`, `opencontext/storage/backends/sqlite_backend.py`.
- `opencontext/tools/tool_definitions.py`, `opencontext/tools/tools_executor.py`, `opencontext/tools/retrieval_tools/base_context_retrieval_tool.py`, `opencontext/tools/retrieval_tools/profile_entity_tool.py`, `opencontext/tools/retrieval_tools/get_activities_tool.py`, `opencontext/tools/retrieval_tools/get_reports_tool.py`, `opencontext/tools/retrieval_tools/get_tips_tool.py`, `opencontext/tools/retrieval_tools/get_todos_tool.py`.
- `opencontext/context_consumption/context_agent/agent.py`, `opencontext/context_consumption/context_agent/core/workflow.py`, `opencontext/context_consumption/context_agent/core/llm_context_strategy.py`, `opencontext/context_consumption/context_agent/nodes/intent.py`, `opencontext/context_consumption/context_agent/nodes/context.py`, `opencontext/context_consumption/context_agent/nodes/executor.py`, `opencontext/context_consumption/context_agent/models/schemas.py`.
- `opencontext/context_consumption/generation/report_generator.py`, `opencontext/context_consumption/generation/realtime_activity_monitor.py`, `opencontext/context_consumption/generation/smart_tip_generator.py`, `opencontext/context_consumption/generation/smart_todo_manager.py`.
- `examples/example_screenshot_processor.py`, `examples/example_document_processor.py`, `examples/example_todo_deduplication.py`, `examples/example_weblink_processor.py`.
- `frontend/packages/shared/IpcChannel.ts` for MCP-related frontend constants only.

## Excluded Paths

- `frontend/src/renderer/**`, `frontend/src/main/**`, UI styles, React components, and renderer assets: reviewed only at a high level because they are UI and desktop shell code, not the backend context-control execution path.
- `frontend/resources/**`, `src/*.gif`, `src/*.png`, icons, screenshots, and other media assets: documentation or packaging assets, not executable context logic.
- `frontend/build/**`, Electron packaging files, `opencontext.spec`, `build.sh`, `build.bat`, lockfiles, and package manager metadata: release/build machinery, not context assembly behavior.
- `frontend/externals/python/**`: operating-system helper scripts for window capture/inspection UX; relevant to capture ergonomics but not to memory extraction, retrieval, or agent context assembly.
- `.github/**`, `.pre-commit-config.yaml`, `.gitignore`, `CONTRIBUTING.md`, and `LICENSE`: project maintenance metadata, not runtime context-control design.
- Tests and evals: no dedicated test or eval directories/files were present in the reviewed file list.
