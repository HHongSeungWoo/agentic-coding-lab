# swarmclawai/swarmvault

- URL: https://github.com/swarmclawai/swarmvault
- Category: memory
- Stars snapshot: 471 (GitHub REST API, captured 2026-05-20)
- Reviewed commit: 4b8c260cc678dd4feb8dc5055551501a0dabb372
- Reviewed at: 2026-05-20T21:18:33+09:00
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong source of durable agent-memory patterns. SwarmVault is too broad to copy wholesale, but its local-first raw/wiki/state substrate, graph-first recall, token-bounded context packs, task ledger, review queues, redaction pass, and Codex/Claude hooks are directly relevant to Agentic Coding Lab.

## Why It Matters

SwarmVault is one of the more complete implementations in this batch for turning agent work into durable, inspectable memory. It is not just a memory API or vector-store wrapper. It stores raw inputs, extracted text, generated wiki pages, graph artifacts, retrieval indexes, query outputs, chat sessions, context packs, and task records as repo-local files.

For Agentic Coding Lab, the useful idea is the operational loop: capture sources, compile them into a graph/wiki, query the compiled memory, save useful outputs, and carry explicit task state across agent sessions. That is closer to real coding-agent memory than many "long-term memory" projects because it includes provenance, reviewable files, handoff packs, and integration hooks that nudge agents to read prior graph context before broad searches.

## What It Is

SwarmVault is a TypeScript monorepo for a local-first "LLM Wiki" and agent memory store. The core engine ingests files, directories, public URLs, docs hubs, media, and GitHub repos; normalizes them into `raw/` and `state/extracts/`; compiles Markdown wiki pages under `wiki/`; writes a knowledge graph to `state/graph.json`; builds a local SQLite FTS retrieval index under `state/retrieval/`; and exposes recall/update tools through CLI commands, MCP tools, agent rule installs, and optional graph viewer/Obsidian surfaces.

The default provider is local heuristic extraction, so a vault can run without API keys. Richer extraction, answer generation, embeddings, image extraction, and audio transcription are provider-driven through OpenAI-compatible, Anthropic, Gemini, Ollama, local-whisper, or custom adapters.

The memory-specific surfaces are:

- `swarmvault context build`: builds token-bounded handoff packs with citations and omitted-evidence accounting.
- `swarmvault task start/update/finish/resume`: creates durable task records with decisions, changed paths, graph/page/source references, context packs, outcomes, and follow-ups.
- `swarmvault chat`: persists multi-turn chat sessions to both structured state and Markdown.
- `swarmvault query` and `swarmvault explore`: query compiled memory and save outputs back into the wiki.
- `swarmvault mcp`: exposes search, graph, context-pack, task, ingest, compile, doctor, review, and candidate tools to local agents.
- `swarmvault install --agent codex --hook` and `--agent claude --hook`: installs graph-first rule files and hooks.

## Research Themes

- Token efficiency: Strong. Querying uses local FTS/hybrid search, bounded wiki excerpts, bounded raw excerpts, compile/query `maxTokens`, graph traversal budgets, context-pack budgets, omitted-item lists, large-repo defaults, cached embeddings, and default first-party-only extraction classes. It is mostly selection and budgeting rather than learned compression.
- Context control: Strong. The repo separates `raw/`, `wiki/`, and `state/`; uses `swarmvault.schema.md` and project schemas as the compiler contract; supports source-class filters, managed sources, graph filters, context-pack targets, `SWARMVAULT_OUT`, review queues, candidates, and retrieval doctor checks.
- Sub-agent / multi-agent: Moderate. It is not a multi-agent runtime, but it supports many agent targets, MCP, persisted task handoffs, graph-first hooks, chat sessions, review bundles, watch jobs, schedules, and optional orchestration/provider roles.
- Domain-specific workflow: Strong. Code repositories get parser-backed module/symbol/import/call analysis. Research and personal-knowledge workflows get schema profiles, guided source sessions, contradiction linting, dashboards, citation-heavy pages, and mixed-source extraction.
- Error prevention: Strong local controls, with gaps. It has redaction enabled by default, URL private-IP blocking, path-boundary checks, atomic JSON writes, review approvals, candidate staging, retrieval doctor/repair, graph validation, source-class filtering, and tests for core safety surfaces. Gaps include no auth around local MCP mutation tools, limited regex redaction, no robust write locking, and provider privacy depending on config.
- Self-learning / memory: Strong. Saved outputs, chat sessions, task ledger records, context packs, source reload/watch, compile-state hashes, decay/supersession metadata, and consolidation tiers give it a real cumulative memory loop.
- Popular skills: Strong. The repository ships a `skills/swarmvault/SKILL.md`, command/artifact references, workflow examples, CLI agent installers, and hooks for Codex/Claude/Gemini/OpenCode/Copilot-style agents.

## Core Execution Path

The core path starts with `initWorkspace()` in `packages/engine/src/config.ts`. It creates the vault scaffold, default config, schema file, artifact directories, and optional agent/Obsidian files. `resolvePaths()` centralizes the file layout, including `raw/sources`, `raw/assets`, `state/manifests`, `state/extracts`, `state/analyses`, `state/graph.json`, `state/retrieval/fts-000.sqlite`, `state/context-packs`, and `state/memory/tasks`.

Ingestion runs through `ingestInputDetailed()`, `ingestInput()`, `ingestDirectory()`, managed-source helpers, and source sessions. The pipeline infers source kind, fetches or reads input, extracts text when needed, applies redaction, writes canonical raw copies and extraction sidecars, and records manifests. Directory ingest respects `.gitignore`, `.swarmvaultignore`, `.swarmvaultinclude`, hard ignores such as `.git`, source classification, and a default first-party extraction class. URL ingest calls `validateUrlSafety()` to require HTTP(S) and block private or reserved IPs unless `SWARMVAULT_ALLOW_PRIVATE_URLS=1`.

Compilation runs through `compileVault()` in `packages/engine/src/vault.ts`. It loads config and schemas, lists manifests, loads saved outputs and memory task pages, compares compile-state hashes, analyzes dirty sources, reuses cached analyses, runs parser-backed local code analysis, and then calls the artifact sync path. That sync path writes source/module/concept/entity pages, builds candidate pages, computes contradictions and similarity edges, builds the graph, writes graph reports/share artifacts, rebuilds retrieval, updates compile state, and optionally stages an approval bundle instead of writing live changes.

Recall runs through local search, graph tools, and provider-backed answers. `searchVault()` reads the local SQLite FTS index and can merge semantic search. `queryVault()` pulls top wiki excerpts and raw extracted excerpts, optionally gap-fills with web search if configured, calls the heuristic or configured provider, and saves outputs by default. `queryGraphVault()`, `explainGraphVault()`, shortest-path, god-node, blast-radius, community, and hyperedge tools provide deterministic graph recall without asking an LLM first.

Durable task memory lives in `packages/engine/src/memory.ts`. `startMemoryTask()` creates JSON and Markdown task records and usually builds an initial context pack. `updateMemoryTask()` appends notes, decisions, changed paths, graph/page/source/node IDs, git refs, and context-pack IDs. `finishMemoryTask()` records outcome and follow-ups. `resumeMemoryTask()` renders Markdown, JSON, or `llms` handoff text. Compile turns memory tasks and decisions into graph nodes and edges such as `records_decision`, `uses_context`, `touched`, `produced_output`, and `follows_up`.

Context packs live in `packages/engine/src/context-packs.ts`. They combine graph query results, local search hits, target explanations, hyperedges, and relevant memory tasks into a token-bounded evidence bundle. They persist both JSON and Markdown, track included and omitted items, and can update a memory task with the pack ID.

Integrations wrap the same engine. The CLI exposes the commands. `createMcpServer()` registers local MCP tools and resources for workspace info, page search, graph operations, retrieval doctor/rebuild, vault query, context packs, memory tasks, ingest, compile, lint, approvals, candidates, watch state, migration, and consolidation. Agent installers write managed rule blocks and optional graph-first hooks for Codex and Claude that remind agents to read `wiki/graph/report.md` before broad grep/glob/search commands.

## Architecture

The repository is organized around a core engine package plus user-facing shells:

- `packages/engine`: source ingest, extraction, provider registry, compile, graph construction, retrieval, context packs, task memory, chat sessions, MCP server, agent installs, hooks, lint, consolidation, migration, and tests.
- `packages/cli`: command surface for init, quickstart, scan, ingest, source management, compile, query, chat, context, task, retrieval, doctor, graph, watch, hooks, install, MCP, and export commands.
- `packages/viewer`: graph/workbench UI. Useful product surface, but not required for the durable memory engine.
- `packages/obsidian-plugin`: editor integration wrapper around CLI/processes and workspace helpers.
- `skills/swarmvault`: installable skill instructions, command reference, artifact reference, and workflow examples.
- `worked` and `smoke/fixtures`: examples and test fixtures for repo, research, personal knowledge base, large repo, and mixed-source workflows.

The storage model is file-first. `raw/` is canonical input. `state/` holds manifests, extracts, analysis caches, graph/retrieval/index/task/session machine state, approval bundles, and watch status. `wiki/` holds generated Markdown pages, dashboards, outputs, memory task pages, context-pack companions, candidates, graph reports, and AI export artifacts. Stable page frontmatter records `page_id`, `kind`, `source_ids`, `node_ids`, project IDs, freshness/status/confidence, hashes, backlinks, related IDs, schema hash, tier/supersession metadata, and timestamps.

The provider model is pluggable. Code analysis is local and parser-backed. Text analysis can be heuristic or provider-backed. Image extraction uses a structured multimodal provider when configured. Audio transcription can use cloud OpenAI-compatible audio or local-whisper. Embeddings are cached in `state/embeddings.json` and used for semantic search and inferred similarity edges.

## Design Choices

SwarmVault treats memory as a local artifact tree instead of a remote service. That makes history review, diffs, backups, and agent handoff simpler, and it matches coding workflows where the repo is the natural unit of memory.

It keeps generated knowledge separate from source truth. The raw source and extracted sidecars are not the same as generated wiki pages. This is important because agents can edit schemas or add sources instead of silently hand-editing generated provenance.

It uses schemas as the human contract. `swarmvault.schema.md` and project schema composition influence extraction, naming, grounding, exclusions, and page structure. That is a practical pattern for keeping memory aligned with a project vocabulary instead of letting embeddings alone decide organization.

It gates some generated changes through candidates and approvals. `compile --approve` stages bundles, and candidate pages can be promoted or archived. This is a useful compromise between automatic memory growth and reviewability.

It treats graph recall as first-class. The graph is not only visualization data; it powers reports, graph query/path/explain tools, context packs, hooks, exports, and memory task edges.

It records memory work as tasks, not only facts. The task ledger captures goal, status, decisions, notes, changed paths, git refs, context packs, outcomes, and follow-ups. For coding agents, this is often more useful than a generic "user preference" memory.

It makes recall products persistent. Query outputs, chat transcripts, context packs, source briefs, source reviews, and AI exports are saved to disk and can feed later compiles.

## Strengths

The actual implementation is deep. The engine includes source capture, extraction, analysis cache invalidation, graph construction, retrieval, context packaging, task memory, review queues, safety checks, agent hooks, MCP, migration, and tests. It is not a thin demo.

The memory shape fits agentic coding. Context packs and task records map directly to handoffs, branch switches, reviewer sessions, and future continuation. Graph-first hooks are a low-friction way to reduce repeated broad searches.

The local-first default is credible. The default config uses a heuristic provider, parser-backed code analysis runs locally, and cloud/provider paths are explicit configuration choices.

The artifact model is inspectable. Markdown pages, JSON graph/state files, SQLite retrieval, and frontmatter hashes make it possible to audit what changed and why.

The graph has useful provenance. Nodes, edges, communities, hyperedges, evidence classes, page IDs, source IDs, related IDs, contradictions, similarity edges, and code relations are all available to recall tools.

The safety baseline is better than most memory repos. Redaction is on by default for text/extracted payloads; URL ingest blocks private/reserved IPs; path-boundary helpers are used around sensitive reads/deletes; writeJsonFile uses temp-file rename; review bundles and candidates exist; and tests cover redaction, path traversal for context packs, retrieval repair, agent installs, MCP surfaces, graph tools, consolidation, and memory tasks.

## Weaknesses

The product surface is very broad. Engine, CLI, viewer, Obsidian plugin, many provider types, media extraction, graph export formats, agent installers, hooks, schedules, and review workflows create a lot of behavior to maintain.

MCP is local and unauthenticated. The server exposes mutating tools such as ingest, compile, rebuild retrieval, start/update/finish tasks, approvals, candidates, migration, and consolidation to any client that can connect to the stdio server. That is acceptable for a trusted local agent session, but not enough for shared or remote memory.

Provider privacy depends on configuration. Ingest redaction happens before stored text/extracted text, but cloud text, image, embedding, and audio providers receive selected content when configured. Redaction is regex-based and cannot be treated as complete data-loss prevention.

Binary raw copies can still contain sensitive content. Text and transcribed sidecars are redacted, but preserving original binary/file bytes means secrets embedded in PDFs, office files, screenshots, or archives may remain in `raw/`.

There is no obvious cross-process locking for state writes. Atomic JSON writes help single-file integrity, but concurrent agents compiling, querying, updating tasks, rebuilding retrieval, or accepting approvals could race.

The default heuristic provider is intentionally shallow. High-quality synthesis, contradiction analysis, image extraction, embeddings, and answer quality require configuring stronger providers.

Some powerful surfaces are risky by default for a lab setting. Custom provider modules execute local code, local-whisper and media paths spawn binaries, docs/URL ingest fetches network content, and experimental orchestration or web-search paths need explicit policy boundaries.

URL safety is useful but not a full SSRF defense. The reviewed code checks the original URL's resolved host before `fetch()`, but the fetch path itself follows platform behavior and does not show a second private-IP validation after redirects.

Review gates are not universal. Compile approvals and candidates help, but query outputs save by default, task updates mutate directly, and auto-promotion logic can grow concept/entity pages based on heuristics.

## Ideas To Steal

Use a repo-local memory root with `raw/`, `wiki/`, and `state/` as separate trust zones.

Make generated memory diffable Markdown with stable frontmatter: `page_id`, `kind`, `source_ids`, `node_ids`, hashes, freshness, status, confidence, schema hash, and `managed_by`.

Add a task ledger for coding agents. Track goal, status, decisions, changed paths, context packs, git refs, outcomes, and follow-ups, then compile those records back into the graph.

Build token-bounded context packs with citations, included items, omitted items, and a durable JSON plus Markdown representation.

Install graph-first agent hints as nonblocking reminders. A hook that nudges agents to read a graph report before broad search is safer and easier to adopt than blocking search.

Save high-value query/chat outputs into the memory tree so useful reasoning becomes future evidence instead of disappearing into a chat transcript.

Use candidate and approval queues for generated memory changes that affect canonical pages.

Run redaction before storing text and before hashing semantic content, and emit a redaction log entry for audit.

Keep a retrieval manifest tied to graph/wiki hashes and provide a doctor/repair command.

Treat decay, supersession, and consolidation as metadata first. Do not delete old memory; mark it stale/superseded and create higher-tier summaries.

Expose MCP in layers. Start with read-only search/graph/context resources, then add mutating tools behind explicit local trust or approval gates.

## Do Not Copy

Do not copy the whole product surface into Agentic Coding Lab. The viewer, Obsidian plugin, many export formats, media extraction matrix, and large CLI surface would distract from durable coding memory.

Do not expose unauthenticated mutating MCP tools by default. A lab memory server should separate read-only recall from writes, ingest, compile, migration, and approval mutation.

Do not rely on regex redaction as the only privacy control. It is a useful baseline, not a security boundary.

Do not send repo or personal sources to cloud providers without a vault-level policy that states what content classes may leave the machine.

Do not allow custom provider modules or command executors without sandboxing, provenance, and user approval.

Do not adopt auto-promotion as a black box. If concept/entity promotion affects durable memory, keep it reviewable and explainable.

Do not store task memory without namespaces, locking, and conflict behavior if several agents can write concurrently.

Do not make UI dashboards required for the core memory loop. The useful pattern is the artifact contract and recall/update path, not the visual workbench.

## Fit For Agentic Coding Lab

SwarmVault is an in-scope, high-value reference for durable memory. The best fit is as a pattern library rather than a dependency.

The strongest transplant is a smaller coding-agent memory loop:

1. Store canonical sources and task records locally.
2. Compile them into reviewable Markdown pages plus a graph artifact.
3. Build a local retrieval index and graph query tools.
4. Generate context packs with citations and token budgets.
5. Record decisions, changed paths, outcomes, and follow-ups as durable task memory.
6. Recompile saved outputs and task records so future agents inherit the work.
7. Add nonblocking graph-first hooks for Codex-like agents.

For Agentic Coding Lab, this suggests memory should be shaped around coding work units, evidence packs, and project vocabulary. The lab does not need SwarmVault's full media/Obsidian/viewer/export product. It does need the idea that memory is a durable, reviewable artifact graph with explicit update paths and citations.

## Reviewed Paths

- `/tmp/myagents-research/swarmclawai-swarmvault/README.md`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/README.md`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/cli/README.md`
- `/tmp/myagents-research/swarmclawai-swarmvault/STABILITY.md`
- `/tmp/myagents-research/swarmclawai-swarmvault/SCALE.md`
- `/tmp/myagents-research/swarmclawai-swarmvault/docs/live-testing.md`
- `/tmp/myagents-research/swarmclawai-swarmvault/docs/pdf-extraction.md`
- `/tmp/myagents-research/swarmclawai-swarmvault/CHANGELOG.md`
- `/tmp/myagents-research/swarmclawai-swarmvault/package.json`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/package.json`
- `/tmp/myagents-research/swarmclawai-swarmvault/skills/swarmvault/SKILL.md`
- `/tmp/myagents-research/swarmclawai-swarmvault/skills/swarmvault/references/commands.md`
- `/tmp/myagents-research/swarmclawai-swarmvault/skills/swarmvault/references/artifacts.md`
- `/tmp/myagents-research/swarmclawai-swarmvault/skills/swarmvault/examples/quickstart.md`
- `/tmp/myagents-research/swarmclawai-swarmvault/skills/swarmvault/examples/repo-workflow.md`
- `/tmp/myagents-research/swarmclawai-swarmvault/skills/swarmvault/examples/research-workflow.md`
- `/tmp/myagents-research/swarmclawai-swarmvault/worked/README.md`
- `/tmp/myagents-research/swarmclawai-swarmvault/worked/code-repo/README.md`
- `/tmp/myagents-research/swarmclawai-swarmvault/worked/personal-knowledge-base/README.md`
- `/tmp/myagents-research/swarmclawai-swarmvault/worked/research-deep-dive/README.md`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/src/config.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/src/schema.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/src/types.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/src/utils.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/src/ingest.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/src/extraction.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/src/redaction.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/src/source-classification.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/src/source-registry.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/src/source-sessions.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/src/sources.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/src/analysis.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/src/code-analysis.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/src/vault.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/src/markdown.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/src/freshness.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/src/consolidate.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/src/graph-tools.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/src/large-repo-defaults.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/src/search.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/src/retrieval.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/src/embeddings.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/src/context-packs.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/src/memory.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/src/chat.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/src/ai-export.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/src/mcp.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/src/agents.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/src/hooks.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/src/hooks/codex.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/src/hooks/claude.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/src/hooks/marker-state.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/src/providers/registry.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/src/providers/heuristic.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/src/providers/openai-compatible.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/src/providers/local-whisper.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/test/memory.test.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/test/context-packs.test.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/test/retrieval.test.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/test/ingest-redaction.test.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/test/audio-redaction.test.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/test/redaction.test.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/test/ingest-ignore.test.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/test/managed-sources.test.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/test/consolidation.test.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/test/provider-registry.test.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/test/graph-tools.test.ts`
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/engine/test/vault.test.ts`

## Excluded Paths

- `/tmp/myagents-research/swarmclawai-swarmvault/.git/`: clone metadata, not product behavior.
- `/tmp/myagents-research/swarmclawai-swarmvault/pnpm-lock.yaml`: generated dependency lock. Package manifests and source imports were enough for architecture and runtime review.
- `/tmp/myagents-research/swarmclawai-swarmvault/README.zh-CN.md` and `/tmp/myagents-research/swarmclawai-swarmvault/README.ja.md`: translated documentation; English README was treated as canonical.
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/viewer/`: UI-only graph/workbench implementation. I used docs/tests only to understand it as a surface, not as the memory execution path.
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/obsidian-plugin/`: editor integration UI/process wrapper. Relevant concept noted, but not central to engine storage, recall, or update semantics.
- `/tmp/myagents-research/swarmclawai-swarmvault/smoke/fixtures/**`: fixture corpus for smoke tests, including many tiny language examples. I read fixture references only where tests used them; the fixture bodies are not design logic.
- `/tmp/myagents-research/swarmclawai-swarmvault/smoke/fixtures/tiny-matrix/docs/paper.pdf`, `/tmp/myagents-research/swarmclawai-swarmvault/smoke/fixtures/tiny-matrix/docs/diagram.svg`, `/tmp/myagents-research/swarmclawai-swarmvault/smoke/fixtures/inbox-bundle/assets/graph.svg`, and `/tmp/myagents-research/swarmclawai-swarmvault/worked/large-repo/sources/assets/logo.svg`: binary/vector fixture assets, not source logic.
- `/tmp/myagents-research/swarmclawai-swarmvault/scripts/release-*.mjs`, `/tmp/myagents-research/swarmclawai-swarmvault/scripts/publish-clawhub-skill.mjs`, `/tmp/myagents-research/swarmclawai-swarmvault/scripts/check-published-manifests.mjs`, and related publishing/parity scripts: release automation, not runtime memory behavior.
- `/tmp/myagents-research/swarmclawai-swarmvault/validation/oss-corpus.json` and `/tmp/myagents-research/swarmclawai-swarmvault/scripts/live-oss-corpus.mjs`: validation corpus plumbing, useful for release checks but not the memory design.
- `/tmp/myagents-research/swarmclawai-swarmvault/packages/viewer/test/**` and `/tmp/myagents-research/swarmclawai-swarmvault/packages/obsidian-plugin/test/**`: UI/editor adapter tests. Engine tests were prioritized for memory, graph, retrieval, safety, and integration semantics.
