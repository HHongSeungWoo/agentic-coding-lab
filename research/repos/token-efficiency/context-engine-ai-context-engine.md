# Context-Engine-AI/Context-Engine

- URL: https://github.com/Context-Engine-AI/Context-Engine
- Category: token-efficiency
- Stars snapshot: 392 (GitHub REST API, captured 2026-05-12)
- Reviewed commit: b1dc3ef3ff4a566fcf83163626a955bf39549ac8
- Reviewed at: 2026-05-12T12:10:06+09:00
- Status: reviewed
- Scope fit: in-scope
- Verdict: Useful as a token-efficient MCP retrieval skill and product-facing tool guide, but not as an auditable compression/server implementation. The reviewed commit contains a Svelte marketing site plus agent instruction files; it does not contain `src/mcp`, server code, compression code, tests, examples, or the MCP bridge source. Best reusable pieces are the two-phase retrieval defaults, `toon`/`compact` output guidance, batch tools, multi-repo boundary tracing, memory tool patterns, and structured fallback/error guidance. Treat algorithmic claims such as ReFRAG micro-chunking, neural reranking, adaptive spans, and 60-85% savings as documentation claims unless the separate service or npm bridge is audited.

## Why It Matters

Context Engine matters for Agentic Coding Lab because it is explicitly trying to reduce coding-agent context load through MCP retrieval rather than prompt-only context stuffing. Its skill files teach an agent to prefer semantic search, symbol graphs, memory, batched retrieval, compact output, and query scoping before opening files directly.

The repo is also a cautionary data point. The public reviewed tree no longer exposes the server, indexer, compression, or test implementation needed to verify the architecture. The value is therefore mostly in agent-side interaction design: what tools should exist, how agents should choose among them, and which token-budget knobs should be exposed.

## What It Is

The reviewed repository is a public Context Engine website and multi-client instruction package. `README.md` describes skills for Claude, Cursor, Codex, Windsurf, Augment, Gemini, and generic assistants. It points terminal users to an external npm package, `@context-engine-bridge/context-engine-mcp-bridge`, with commands such as `ctxce connect`, `ctxce mcp-serve`, and `ctxce mcp-http-serve`.

The canonical skill is `skills/context-engine/SKILL.md`, duplicated under `.codex/skills/context-engine/SKILL.md` with short Codex references. It documents more than 30 MCP tools across search, symbol graph, graph traversal, memory, batching, cross-repo search, git history, diagnostics, and session defaults.

The repo is not, at the reviewed commit, a source tree for the actual MCP server. There is no `docs/`, `src/mcp/`, `server/`, `compression/`, implementation-level `context/`, `tests/`, `examples/`, `ctx-mcp-bridge/`, or `vscode-extension/` directory in the checked-out tree. Current implementation claims are visible only through README, skill docs, third-party notices, workflow leftovers, website copy, and npm registry metadata for the bridge package.

## Research Themes

- Token efficiency: Strong as a documented usage pattern, unverified as an implementation. The skill repeatedly recommends `compact=true`, `output_format="toon"`, `limit=3`, `per_path=1`, `include_snippet=false`, and low `context_lines` for discovery. `batch_search`, `batch_symbol_graph`, and `batch_graph_query` are documented as saving roughly 40-85% token overhead compared with repeated individual calls. `toon` is documented as a 60-80% compact output format. ReFRAG 16-24 token micro-chunking, adaptive span sizing, and score-variance expansion are described but not implemented in the reviewed tree.
- Context control: Strong. The docs define a two-phase discovery/deep-dive flow, standard filters (`language`, `under`, `path_glob`, `not_glob`, `symbol`, `repo`), session defaults, query-length constraints, result limits, and output formats. The multi-repo guidance says to discover collections lazily, target collections explicitly, and trace exact boundary keys rather than repeat vague searches across repos.
- Sub-agent / multi-agent: Limited. The repo does not provide subagents. It promotes parallel MCP tool calls and batch tools for independent retrieval work, plus `cross_repo_search` for multi-repo breadth.
- Domain-specific workflow: Strong for coding-agent retrieval. It covers code search, Q&A with citations, test/config search, symbol callers/definitions/importers, pattern search, git history, cross-repo flow tracing, and persistent memory.
- Error prevention: Moderate to strong in instructions. Tools are expected to return `ok`/`error` envelopes; docs include error recovery tables for search, graph, context-answer, memory, batch, and cross-repo failures. Weakness: the strongest enforcement is prose. The "do not use grep/read for exploration" rule can conflict with real coding-agent workflows where exact file inspection and local verification are necessary.
- Self-learning / memory: Strong as an MCP API concept, unverified as local implementation. `memory_store`, `memory_find`, and `context_search(include_memories=true)` model durable org/workspace-scoped notes with kind/topic/tags/priority metadata. The site claims self-learning behavior, but the public repo does not include the storage or learning code.
- Popular skills: No usage telemetry was reviewed. The important shipped skill surfaces are `skills/context-engine/SKILL.md`, `.skills/mcp-tool-selection/SKILL.md`, `.cursorrules`, `GEMINI.md`, `.augment/rules/context-engine.md`, and the Codex quick references under `.codex/skills/context-engine/references/`.

## Core Execution Path

For a terminal-based MCP client, the documented path starts outside this repo's source code:

1. Install the external bridge package with `npm install -g @context-engine-bridge/context-engine-mcp-bridge`.
2. Authenticate and index/watch a workspace with `ctxce connect <api-key> --workspace /path/to/repo`, optionally `--daemon`.
3. Expose MCP to the coding agent with `ctxce mcp-serve --workspace /path/to/repo` for stdio or `ctxce mcp-http-serve --workspace /path/to/repo --port 30810` for HTTP.
4. The bridge shares auth through `~/.ctxce/auth.json`; daemon logs are documented at `~/.context-engine/daemon.log`.
5. The coding assistant loads the Context Engine skill and then chooses MCP tools according to the documented decision tree.

At agent runtime, `search` is the default entry point. It auto-detects whether the user needs raw code search, Q&A, tests, config, symbols, or imports, then dispatches to tools such as `repo_search`, `context_answer`, `search_tests_for`, `search_config_for`, or `symbol_graph`.

For known code-search work, agents can bypass routing with `repo_search` or `code_search`, add filters, and choose compact output. For independent searches, `batch_search` collapses multiple `repo_search` calls into one MCP invocation. For relationships, `symbol_graph` handles direct callers, callees, definitions, importers, subclasses, and base classes; `graph_query` is documented for deeper impact, dependency, cycle, and transitive traversal when available.

For multi-repo work, `cross_repo_search` is the documented high-level path. The recommended workflow is boundary-driven: find the exact route, event name, or shared type in one repo, then search the target repo by that hard key. For persistent context, agents use `memory_store` during discovery, `memory_find` in later sessions, and `context_search(include_memories=true)` when code and stored notes should be ranked together.

The underlying service architecture is only described, not present. `GEMINI.md` says there are two MCP servers: a Memory Server on ports 8000/8002 and an Indexer Server on ports 8001/8003. It describes hybrid dense plus lexical search, neural reranking, Qdrant collections, symbol metadata, ReFRAG micro-chunking, TOON output, and local/hosted deployment modes. None of those server internals are available for verification at the reviewed commit.

## Architecture

The reviewed tree has four main surfaces.

First, onboarding and packaging:

- `README.md`: installation and setup instructions for assistant skills and the external bridge.
- `.claude-plugin/marketplace.json`: plugin marketplace metadata pointing at `./skills/context-engine`.
- `.codex/config.toml`: enables the stable RMCP client.

Second, the shared agent guidance:

- `skills/context-engine/SKILL.md`: canonical long-form tool-selection and tool-reference document.
- `.codex/skills/context-engine/SKILL.md`: byte-identical copy of the canonical skill.
- `.codex/skills/context-engine/references/tool-reference.md`: shorter Codex quick reference.
- `.codex/skills/context-engine/references/patterns.md`: stable Codex usage patterns.
- `.skills/mcp-tool-selection/SKILL.md`: compact MCP-vs-grep decision skill.
- `.cursorrules`, `GEMINI.md`, and `.augment/rules/context-engine.md`: host-specific instruction wrappers.

Third, product website and static assets:

- `src/routes/+page.svelte`, `src/routes/+layout.svelte`, `src/app.scss`, and `src/routes/contact/+page.svelte`: SvelteKit landing/contact pages, product claims, demo links, and external documentation/package links.
- `static/**`: logos, favicon, NVIDIA badge, and demo video assets.
- `package.json`, `svelte.config.js`, `vite.config.ts`, `tsconfig.json`, and lint/prettier config: website build/development setup.

Fourth, stale or aspirational operations metadata:

- `.github/workflows/ci.yml`: Python/Qdrant/pytest workflow that references `uv`, `scripts`, and `uv.lock`, none of which exist in the reviewed tree.
- `.github/workflows/publish-cli.yml` and `publish-vscode-extension.yml`: publish workflows triggered by paths under `ctx-mcp-bridge/` and `vscode-extension/`, which are absent from the reviewed tree.
- `NOTICE`, `THIRD_PARTY_LICENSES`, `.qdrantignore`, and `.indexignore`: legal/dependency/indexing clues for a larger system, including Qdrant, FastMCP, python-toon, tree-sitter, fastembed, FastAPI, uvicorn, tokenizers, and onnxruntime.

## Design Choices

The most important design choice is a unified retrieval interface. Agents start with `search` when uncertain, but can bypass routing with specific tools when they need deterministic behavior, speed, or filter control.

The second choice is exposing token controls directly to the agent. Discovery uses small limits, compact fields, TOON output, one result per path, no snippets, and no context lines. Deep dives add snippets and more context only after targets are identified.

The third choice is first-class batching. The docs tell agents to use `batch_search`, `batch_symbol_graph`, or `batch_graph_query` whenever there are at least two independent same-family queries.

The fourth choice is separating direct symbol lookup from semantic search. `symbol_graph` is the default for callers, callees, definitions, importers, and inheritance, while semantic search handles concepts and fallback cases.

The fifth choice is boundary-driven multi-repo search. Instead of searching every collection with one vague phrase, agents are told to extract hard keys and follow those across repos.

The sixth choice is memory as a normal retrieval source. Stored notes are not just chat history; they have structured metadata and can be blended with code hits.

The seventh choice is host portability. The same core tool-selection rules are copied into Claude plugin metadata, Codex skills, Cursor rules, Augment rules, Gemini rules, and generic `SKILL.md` files.

## Strengths

The tool-selection guidance is concrete. It names which tool to use for code lookup, Q&A, tests, config, symbol relationships, graph traversal, git history, memory, multi-repo search, and diagnostics.

The token-efficiency recommendations are practical for coding agents. Small discovery queries, compact/TOON output, snippets only on deep dive, batched queries, and session defaults are all reusable patterns.

The multi-repo section is one of the strongest parts. Boundary-key tracing maps well to real coding workflows where API routes, event names, and shared types are better anchors than semantic guesses.

The memory workflow is understandable. It distinguishes decisions, gotchas, conventions, notes, and policies, then shows how to retrieve by topic/tags/priority or blend memory with code search.

The error tables are useful. They give recovery steps for empty results, bad filters, rerank timeouts, graph availability, context-answer timeouts, duplicate memories, and batch partial failures.

The skill packaging is portable. A team could adapt the same guidance to multiple assistants without building a custom client.

The ignore files show awareness of privacy and indexing scope. `.qdrantignore` and `.indexignore` exclude local caches, uploaded workspaces, build outputs, model binaries, virtualenvs, node modules, and editor artifacts.

## Weaknesses

The public reviewed tree lacks the implementation needed to verify the core claims. There is no server code, compression code, MCP bridge source, indexer, memory store, retrieval algorithm, reranker, chunker, schema, test suite, or examples.

Several repository surfaces are inconsistent with the current tree. CI expects Python sources and `uv.lock`; publish workflows expect `ctx-mcp-bridge/` and `vscode-extension/`; the README points to an external bridge and documentation. Those may work elsewhere, but they are not reviewable here.

The "MCP tools at all costs" instruction is too strong for a coding agent. MCP retrieval is excellent for discovery, but real edits still need exact file reads, diffs, tests, compiler output, and sometimes literal grep. The skill partially allows exact confirmation, but the opening warnings are overbroad.

Privacy and security claims are mostly unverified. The docs mention hosted service, SaaS mode, self-hosted mode, org/workspace-scoped memory, API-key auth, and local auth files, but the code paths enforcing isolation, redaction, retention, and upload boundaries are not available.

The source-available license is restrictive. It blocks redistribution, assigns modifications to the licensor, and restricts competing services. That is a poor fit for directly copying code into Agentic Coding Lab even if source were present.

The website contains marketing metrics and claims that cannot be validated from the repo: less than 100ms search latency, 80% less compute, self-learning, 32 languages, and 16 IDE integrations.

No current tests or examples exercise MCP behavior. The `package.json` test command is Playwright-focused for the website, and no Playwright tests are present in the reviewed tree.

## Ideas To Steal

Use two-phase retrieval defaults in coding-agent MCP skills: compact discovery first, snippet-rich deep dive second.

Expose output shape as a first-class token control. A `toon`-like compact format plus `compact=true` and `include_snippet=false` are easy for agents to reason about.

Add batch tools for independent searches and symbol queries. The exact savings need measurement, but the interface pattern is valuable.

Use a unified `search` router, but document when to bypass it with direct tools such as `repo_search` for deterministic filters or tight loops.

Make multi-repo retrieval boundary-driven. Teach agents to extract exact routes, event names, and type names before crossing repos.

Blend durable memory with code retrieval through structured metadata. The `kind`, `topic`, `tags`, and priority pattern maps cleanly to coding-agent notes.

Standardize tool envelopes around `ok`, `error`, `results`, `citations`, and `used` fields so agents can recover without parsing ad hoc text.

Ship assistant-specific wrappers that defer to one canonical skill. This keeps Claude, Codex, Cursor, Gemini, and Augment instructions aligned.

## Do Not Copy

Do not copy the "never grep/read" policy literally. For coding agents, retrieval should guide exploration, but exact file reads, diffs, tests, and local command output remain mandatory verification tools.

Do not treat documented compression ratios, latency, reranking quality, or self-learning claims as evidence without implementation and benchmark access.

Do not adopt a private SaaS or npm bridge as a core dependency without auditing auth, upload, retention, isolation, telemetry, and failure behavior.

Do not copy the license model into open research artifacts. The repo's license is not friendly to derivative redistribution.

Do not leave workflows that point at absent source trees. CI and publish automation should fail early if expected packages are removed.

Do not store agent memories without explicit privacy boundaries, deletion semantics, workspace scoping, and prompt-injection handling for recalled notes.

Do not make one huge MCP skill the only control surface. Split stable quick references from detailed docs so agents can load less context.

## Fit For Agentic Coding Lab

Fit is in-scope for token efficiency and context control, with an implementation caveat. Context Engine is a good reference for the interface of a coding-agent retrieval layer: search router, compact output, batching, symbol graph, cross-repo tracing, memory, diagnostics, and fallback tables.

It is not currently a good source for compression architecture, MCP server internals, retrieval correctness, privacy enforcement, or verification harness design because the public reviewed commit does not contain those parts. Agentic Coding Lab should borrow the instruction and tool-shape patterns, then evaluate or implement the backend independently.

The strongest local adaptation would be a project-local MCP retrieval skill that uses compact defaults, batch calls, boundary tracing, and memory metadata, but pairs retrieval with deterministic file inspection, test execution, diffs, and permission gates.

## Reviewed Paths

- `/tmp/myagents-research/Context-Engine-AI-Context-Engine/README.md`
- `/tmp/myagents-research/Context-Engine-AI-Context-Engine/skills/context-engine/SKILL.md`
- `/tmp/myagents-research/Context-Engine-AI-Context-Engine/.codex/skills/context-engine/SKILL.md`
- `/tmp/myagents-research/Context-Engine-AI-Context-Engine/.codex/skills/context-engine/references/tool-reference.md`
- `/tmp/myagents-research/Context-Engine-AI-Context-Engine/.codex/skills/context-engine/references/patterns.md`
- `/tmp/myagents-research/Context-Engine-AI-Context-Engine/.skills/mcp-tool-selection/SKILL.md`
- `/tmp/myagents-research/Context-Engine-AI-Context-Engine/.cursorrules`
- `/tmp/myagents-research/Context-Engine-AI-Context-Engine/GEMINI.md`
- `/tmp/myagents-research/Context-Engine-AI-Context-Engine/.augment/rules/context-engine.md`
- `/tmp/myagents-research/Context-Engine-AI-Context-Engine/.claude-plugin/marketplace.json`
- `/tmp/myagents-research/Context-Engine-AI-Context-Engine/.codex/config.toml`
- `/tmp/myagents-research/Context-Engine-AI-Context-Engine/.qdrantignore`
- `/tmp/myagents-research/Context-Engine-AI-Context-Engine/.indexignore`
- `/tmp/myagents-research/Context-Engine-AI-Context-Engine/NOTICE`
- `/tmp/myagents-research/Context-Engine-AI-Context-Engine/THIRD_PARTY_LICENSES`
- `/tmp/myagents-research/Context-Engine-AI-Context-Engine/LICENSE`
- `/tmp/myagents-research/Context-Engine-AI-Context-Engine/package.json`
- `/tmp/myagents-research/Context-Engine-AI-Context-Engine/.github/workflows/ci.yml`
- `/tmp/myagents-research/Context-Engine-AI-Context-Engine/.github/workflows/publish-cli.yml`
- `/tmp/myagents-research/Context-Engine-AI-Context-Engine/.github/workflows/publish-vscode-extension.yml`
- `/tmp/myagents-research/Context-Engine-AI-Context-Engine/src/routes/+page.svelte`
- `/tmp/myagents-research/Context-Engine-AI-Context-Engine/src/routes/+layout.svelte`
- `/tmp/myagents-research/Context-Engine-AI-Context-Engine/src/routes/contact/+page.svelte`
- `/tmp/myagents-research/Context-Engine-AI-Context-Engine/src/app.html`
- `/tmp/myagents-research/Context-Engine-AI-Context-Engine/src/app.scss`
- `/tmp/myagents-research/Context-Engine-AI-Context-Engine/package-lock.json`
- `/tmp/myagents-research/Context-Engine-AI-Context-Engine` current git branch, remote branches, commit log, current tree, and absence checks for docs/source/test/example paths
- `https://api.github.com/repos/Context-Engine-AI/Context-Engine`
- `https://api.github.com/repos/Context-Engine-AI/Context-Engine/commits/test`
- `https://registry.npmjs.org/@context-engine-bridge%2Fcontext-engine-mcp-bridge/latest`

## Excluded Paths

- `/tmp/myagents-research/Context-Engine-AI-Context-Engine/.git/`: VCS internals. Used only to record the reviewed commit, branch, current tree, remote branches, and path/history absence signals.
- `/tmp/myagents-research/Context-Engine-AI-Context-Engine/static/*.png`, `static/*.svg`, `static/*.mp4`, and `static/*.webm`: logos, favicon, badges, and demo media. Binary/visual assets, not retrieval or compression logic.
- Full Svelte UI styling and animation details under `src/app.scss` and `src/routes/**`: sampled for product claims and external links, excluded as UI-only implementation.
- `/tmp/myagents-research/Context-Engine-AI-Context-Engine/package-lock.json`: dependency lockfile. Reviewed only enough to identify website dependency surface; lock resolution is not context-compression architecture.
- `/tmp/myagents-research/Context-Engine-AI-Context-Engine/eslint.config.js`, `.prettierrc`, `.prettierignore`, `tsconfig.json`, `vite.config.ts`, `svelte.config.js`, `.npmrc`, `.vscode/settings.json`: website/dev tooling, not MCP behavior.
- `/tmp/myagents-research/Context-Engine-AI-Context-Engine/src/routes/$types.ts` and Svelte starter remnants: generated or framework-support files.
- `/tmp/myagents-research/Context-Engine-AI-Context-Engine/.DS_Store`: local binary metadata artifact.
- `/tmp/myagents-research/Context-Engine-AI-Context-Engine/docs/`: absent in the reviewed commit.
- `/tmp/myagents-research/Context-Engine-AI-Context-Engine/src/mcp/`, `src/server/`, `server/`, `compression/`, and implementation-level `context/`: absent in the reviewed commit. No MCP server or compression source was available to review.
- `/tmp/myagents-research/Context-Engine-AI-Context-Engine/tests/` and `/tmp/myagents-research/Context-Engine-AI-Context-Engine/examples/`: absent in the reviewed commit. No test/example evidence for MCP behavior was available.
- `/tmp/myagents-research/Context-Engine-AI-Context-Engine/ctx-mcp-bridge/` and `/tmp/myagents-research/Context-Engine-AI-Context-Engine/vscode-extension/`: absent in the reviewed commit even though workflows and README reference bridge/extension packaging.
