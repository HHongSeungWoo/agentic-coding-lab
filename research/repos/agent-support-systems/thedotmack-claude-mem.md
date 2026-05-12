# thedotmack/claude-mem

- URL: https://github.com/thedotmack/claude-mem
- Category: agent-support-systems
- Stars snapshot: 74,907 (GitHub REST API, captured 2026-05-12)
- Reviewed commit: a81deb495aa4b33b4486d9fadb0e9028ac73060b
- Reviewed at: 2026-05-12T11:30:35+09:00
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong in-scope persistent-memory system for coding agents. Best ideas are hook-based capture, compact context reinjection, privacy tags, per-file memory timelines, and progressive disclosure search. Do not copy its heavy daemon/provider stack or broad plugin distribution surface without a smaller threat model and simpler operations.

## Why It Matters

Claude-Mem is a full persistent context layer around coding agents, not just a prompt pack. It captures user prompts, tool calls, file-read context, assistant stop summaries, and manual memories; compresses them into structured observations with an observer model; stores them locally; indexes them in SQLite/FTS and optionally Chroma; then injects compact context into future sessions.

This makes it useful for Agentic Coding Lab because the repo shows concrete answers to recurring agent-support problems: how to observe without modifying the agent client, how to avoid dumping all history into context, how to let an agent fetch more only when needed, and how to prevent private prompt spans from becoming durable memory.

## What It Is

Claude-Mem is a TypeScript/Bun/Node package and plugin distribution for Claude Code, Codex CLI, Gemini CLI, Cursor, OpenCode, Windsurf, OpenClaw, and MCP-only clients. The primary worker mode uses a localhost Express service, SQLite database under `~/.claude-mem`, an optional Chroma MCP vector index, and an observer provider selected from Claude Agent SDK, Gemini, or OpenRouter.

The main runtime is hook driven. Plugin hook JSON calls `worker-service.cjs hook <platform> <event>`. Source code for those event handlers lives under `src/cli/handlers`, and the built CJS files under `plugin/scripts` are generated runtime artifacts.

## Research Themes

- Token efficiency: Core pattern is progressive disclosure. Session start injects a compact timeline/index of recent observations and summaries, while full records are fetched later with `get_observations`. Defaults inject 50 observations, zero full narratives, 10 session summaries, and visible savings percent.
- Context control: `SessionStart` injects project-scoped memory. `UserPromptSubmit` can optionally do semantic injection per prompt when `CLAUDE_MEM_SEMANTIC_INJECT=true`, but it is disabled by default. `PreToolUse` injects per-file history only for sufficiently large/stale files.
- Sub-agent / multi-agent: Hook adapters preserve `agentId` and `agentType` for observations, but `summarize` skips subagent contexts. Stored observations carry subagent labels, so it records subagent work without letting subagents close primary sessions.
- Domain-specific workflow: Modes define observation types, concepts, prompt text, icons, and summaries. Code mode turns tool events into typed observations such as decision, bugfix, feature, refactor, discovery, and change.
- Error prevention: Hooks are intentionally non-blocking for worker transport errors, missing transcript paths, and transient 5xx/429 failures. Programming errors and 4xx failures remain blocking in the hook classifier. The worker disallows tools in the observer Claude SDK session to avoid recursive action loops.
- Self-learning / memory: Persistent rows are `sdk_sessions`, `user_prompts`, `pending_messages`, `observations`, `session_summaries`, and manual memory observations. Summaries are generated at stop time from the last assistant message and stored separately from tool observations.
- Popular skills: `mem-search` is the important skill: it teaches search -> timeline -> get_observations and explicitly forbids full-detail fetching before filtering.

## Core Execution Path

Install path:

1. `npx claude-mem install` registers Claude plugin metadata, syncs plugin manifests, ensures Bun/uv/plugin dependencies, writes the install marker, and can register IDE-specific hooks.
2. For Claude Code, `plugin/hooks/hooks.json` registers Setup, SessionStart, UserPromptSubmit, PreToolUse, PostToolUse, and Stop commands.
3. For Codex, `plugin/hooks/codex-hooks.json` registers native plugin hooks and the installer registers a local marketplace. Codex SessionStart runs version check, worker start, then `hook codex context`.

Runtime capture and reinjection:

1. `SessionStart` starts the worker and calls `contextHandler`, which requests `/api/context/inject?projects=...` and returns `hookSpecificOutput.additionalContext`.
2. `UserPromptSubmit` calls `sessionInitHandler`, which resolves project identity, strips memory/private tags, creates or updates an SDK session, saves the cleaned prompt, starts the observer generator, and optionally performs semantic prompt-based injection.
3. `PostToolUse` calls `observationHandler`, which posts tool name/input/output/cwd to `/api/sessions/observations` unless the project or tool is excluded.
4. The worker `ingestObservation` path checks project exclusion, `CLAUDE_MEM_SKIP_TOOLS`, session-memory recursion, and prompt privacy, then queues a persistent pending observation.
5. `ClaudeProvider` starts a separate Claude Agent SDK observer session with Bash/Read/Write/Edit/Grep/Glob/Web/Task tools disallowed. It feeds init, observation, continuation, and summary prompts as synthetic user messages.
6. `processAgentResponse` parses XML `<observation>` or `<summary>` blocks, stores deduped observations/summaries in SQLite, syncs them to Chroma if enabled, broadcasts SSE updates, and confirms queued messages.
7. `Stop` calls `summarizeHandler`, which strips tags from the last assistant message, skips subagent/recursive/private-only cases, and queues a summary.
8. Future sessions receive compact context generated by `ContextBuilder`: query observations/summaries, build a chronological timeline, show IDs/titles/types/times, optionally include some full observations, and include token-economics footer when configured.

File-specific reinjection:

1. Claude Code `PreToolUse` for `Read`, and Codex `PreToolUse` for `Bash` or MCP read/view/cat tools, route to `fileContextHandler`.
2. Codex Bash commands are parsed with `shell-quote`; only read-like commands such as `cat`, `head`, `tail`, `less`, `more`, `bat`, `view`, `nl`, and `tac` produce candidate file paths.
3. Files under 1,500 bytes, directories, missing files, and files modified after the newest observation are skipped.
4. For eligible files, `/api/observations/by-file` returns recent observations, deduped by session and scored for specificity, then the handler injects a compact timeline with IDs and hints to use `get_observations` or `smart_outline`.

## Architecture

The system has four relevant planes.

Hook plane: platform adapters normalize Claude Code, Codex, Gemini, Cursor, Windsurf, and raw inputs into one `NormalizedHookInput`. `hookCommand` reads JSON from stdin, normalizes, dispatches to an event handler, and maps output back to platform-specific hook output.

Worker plane: `WorkerService` owns Express routes, database manager, session manager, provider agents, Chroma manager, transcript watcher, SSE broadcaster, and server-beta routes. It listens on `CLAUDE_MEM_WORKER_HOST`/`CLAUDE_MEM_WORKER_PORT`, defaulting to `127.0.0.1` and a UID-derived port.

Storage/search plane: SQLite stores sessions, prompts, pending messages, observations, summaries, feedback, and schema versions. Observation dedupe is `UNIQUE(memory_session_id, content_hash)`, where the hash uses memory session ID, title, and narrative. Search is SQLite/FTS for metadata/filter-only paths and Chroma for query semantic search when enabled. Chroma failures surface as 503-style errors for query search rather than silently pretending semantic search worked.

Distribution plane: source TypeScript builds to `plugin/scripts/*.cjs`; `plugin/.codex-plugin/plugin.json` and `.claude-plugin` manifests expose hooks, MCP, and skills. The repo also contains UI, marketplace sync, IDE installers, OpenClaw packaging, server-beta storage, and eval harnesses.

## Design Choices

Hook observation instead of client fork: the system does not need to modify Claude Code or Codex. It depends on lifecycle hooks and local worker APIs.

Observer session separation: the memory agent runs as a separate Claude SDK/Gemini/OpenRouter conversation. For Claude SDK, tools are disallowed and `CLAUDE_MEM_INTERNAL=1` prevents the memory worker from tracking itself.

Persistent queue: tool events are queued in `pending_messages`, so hook calls can return quickly and worker/provider failures do not lose all state. Queue engines can be SQLite or BullMQ/Redis.

Compact default injection: context injection renders short IDs, times, type icons, and titles. Full narratives are only injected when `CLAUDE_MEM_CONTEXT_FULL_COUNT` is raised from its default `0`.

Prompt privacy gate: stripped prompts are saved to `user_prompts`; if a prompt becomes empty after tag removal, observations and summaries for that prompt are skipped.

Local-first data model: state lives under `~/.claude-mem` by default. The repo is explicit that model-provider calls and Chroma embedding backends can still send content off-machine.

Recursion avoidance: skip tool defaults include `ListMcpResourcesTool`, `SlashCommand`, `Skill`, `TodoWrite`, and `AskUserQuestion`; file operations touching `session-memory` are skipped; injected memory tags are stripped before persistence.

Multi-client support via adapters: Codex gets native hooks and file-context extraction from Bash/MCP read commands; Gemini uses settings hooks and `GEMINI.md`; MCP-only clients get search tools and placeholder context files but not transcript capture.

## Strengths

Actual durable context loop: capture, compression, local storage, indexing, and reinjection are wired end to end.

Good token discipline: the default context is an index, not a RAG dump. The `mem-search` skill and MCP tool descriptions repeatedly enforce search -> timeline -> batch fetch.

Privacy is implemented in source and tests: `<private>`, `<claude-mem-context>`, `system_instruction`, `persisted-output`, and `system-reminder` tags are stripped from prompt/tool JSON; fully private prompts skip storage paths.

Works across coding agents: Claude Code and Codex hooks are first-class; Gemini/Cursor/Windsurf/OpenCode/OpenClaw integrations broaden applicability.

Per-file memory is pragmatic: before a file read, the agent sees old decisions tied to that file without mutating the read input or forcing a full file-history dump.

Operational hardening is serious: non-blocking hook failure classification, PID/health/readiness management, queue reset, provider error classification, fresh OAuth token lookup, and CORS restricted to local origins are all present.

## Weaknesses

Large moving surface: hooks, worker daemon, SQLite migrations, Chroma MCP, provider adapters, server-beta, viewer UI, installer flows, multiple IDE integrations, and generated bundles make the system expensive to audit and operate.

Observer model can leak sensitive data to providers: local storage is not the whole privacy story. Tool inputs/outputs and prompts can be sent to Claude/Gemini/OpenRouter for compression unless private tags or configuration prevent it.

XML parsing is brittle: source itself flags a planned move to deterministic tool-use/JSON output. Current parser accepts regex-based XML blocks and discards non-XML outputs.

Defaults may surprise security-conscious users: Chroma is enabled by default, Telegram integration default is `true` but inert without token/chat settings, and the local worker exposes many unauthenticated localhost APIs.

Dedup key may be coarse: `memory_session_id + title + narrative` can collapse repeated observations inside a session even if facts/files differ.

Context quality depends on model summarization: wrong or low-signal observations become durable memory, and the system needs prompt/mode tuning to keep observations useful.

## Ideas To Steal

Use lifecycle hooks as a narrow capture interface. Normalize each platform into one event schema, then push events into a local queue.

Render memory as a compact, dated, ID-addressable index at session start. Let the agent fetch full records only after it has task context.

Add file-read-time memory injection with strict gates: minimum file size, stale-observation check, per-session dedupe, max paths, and no mutation of tool input.

Make private and injected-memory tags strip at every persistence edge: user prompts, tool inputs, tool responses, and summaries.

Track memory provenance fields: content session ID, memory session ID, platform source, project, prompt number, agent ID/type, files read/modified, provider model, and discovery token estimate.

Provide a memory search skill that teaches the agent the retrieval protocol, not only an MCP tool list.

Use `CLAUDE_MEM_INTERNAL`-style recursion guards for any observer/critic agent that runs inside the same tool ecosystem it observes.

## Do Not Copy

Do not copy the whole daemon and marketplace distribution shape unless the project truly needs multi-IDE support. A smaller Agentic Coding Lab artifact should start with one hook format, one local database, and one search interface.

Do not rely on regex XML as the long-term structured-output format. Prefer schema-constrained tool calls or JSON with validation and repair logic.

Do not expose broad unauthenticated local APIs by default if the worker could bind beyond loopback. If using a local worker, keep loopback binding, add auth for write/admin routes, and threat-model browser-origin access.

Do not enable remote embeddings, provider compression, or notifications without explicit user-facing data-flow controls. "Local database" is insufficient if compression/search providers receive raw observations.

Do not let auto-generated memories compete with native agent memory without disabling or clearly scoping one of them. Claude-Mem explicitly sets `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1` for Claude Code installs.

## Fit For Agentic Coding Lab

Fit is high for agent-support-systems. Claude-Mem is a mature example of external memory around coding agents: it observes actual work, produces compact reusable records, and reinjects them with token-budget awareness.

Most applicable patterns for this repo are:

- A minimal hook/event capture schema for prompts, tool calls, file reads, and stop summaries.
- Local memory records that are typed, project-scoped, file-linked, and ID-addressable.
- A compact context pack with "what exists" first and "fetch details by ID" second.
- Privacy tags and recursion tags enforced before persistence.
- Tests that lock down hook failure behavior, private-tag stripping, file-context gating, and search strategy selection.

Less applicable pieces are viewer UI polish, broad IDE installers, OpenClaw packaging, server-beta multi-tenant storage, Telegram notifications, and full Chroma process management. Those solve product distribution problems more than Agentic Coding Lab research needs.

## Reviewed Paths

- `README.md`: product overview, installation paths, hook lifecycle summary, MCP/search workflow, feature list.
- `SECURITY.md`: local storage claims, provider/Chroma data-flow caveats, localhost worker default, privacy tags, command-injection policy.
- `package.json`, `plugin/package.json`, `plugin/.codex-plugin/plugin.json`: package version, scripts, runtime dependencies, Codex plugin capabilities.
- `plugin/hooks/hooks.json`, `plugin/hooks/codex-hooks.json`: actual Claude Code and Codex hook commands and lifecycle mapping.
- `scripts/build-hooks.js`, `scripts/sync-plugin-manifests.js`: build/distribution path from TypeScript source to generated plugin scripts/manifests.
- `src/npx-cli/commands/install.ts`, `src/services/integrations/CodexCliInstaller.ts`, `src/services/integrations/GeminiCliHooksInstaller.ts`, `src/services/integrations/McpIntegrations.ts`: installer behavior, Codex marketplace registration, Gemini hook mapping, MCP-only setup.
- `src/cli/hook-command.ts`, `src/cli/handlers/*`, `src/cli/adapters/*`: hook dispatch, context/session-init/observation/file-context/summarize handlers, Claude Code and Codex normalization.
- `src/shared/SettingsDefaultsManager.ts`, `src/shared/paths.ts`, `src/shared/worker-utils.ts`, `src/shared/should-track-project.ts`, `src/shared/EnvManager.ts`: defaults, local data paths, worker host/port, project exclusion, provider credential isolation.
- `src/utils/tag-stripping.ts`, `src/utils/context-injection.ts`, `src/utils/project-name.ts`, `src/utils/project-filter.ts`: privacy tags, context tag replacement, project identity and exclusion helpers.
- `src/services/worker-service.ts`, `src/services/server/Server.ts`, `src/services/worker/http/*`: worker route registration, health/readiness, CORS, session/data/search/memory routes.
- `src/services/worker/SessionManager.ts`, `src/services/worker/ClaudeProvider.ts`, `src/services/worker/GeminiProvider.ts`, `src/services/worker/OpenRouterProvider.ts`, `src/services/worker/agents/ResponseProcessor.ts`: queueing, provider generation, XML parsing response storage, Chroma sync, SSE broadcast.
- `src/sdk/prompts.ts`, `src/sdk/parser.ts`: observer prompts, summary prompts, XML parse contract.
- `src/services/sqlite/schema.sql`, `src/services/sqlite/SessionStore.ts`, `src/services/sqlite/observations/*`, `src/services/sqlite/prompts/*`, `src/services/sqlite/summaries/*`: storage schema, prompt/session/observation/summary persistence.
- `src/services/context/*`: context config, observation/summaries query, token economics, timeline rendering, compact agent formatter.
- `src/services/worker/search/*`, `src/servers/mcp-server.ts`, `src/server/mcp/tools.ts`, `plugin/skills/mem-search/SKILL.md`, `plugin/skills/how-it-works/SKILL.md`: search orchestration, MCP tools, progressive disclosure skill guidance.
- `docs/public/architecture/overview.mdx`, `docs/public/hooks-architecture.mdx`, `docs/public/progressive-disclosure.mdx`, `docs/public/usage/private-tags.mdx`, `docs/public/usage/search-tools.mdx`, `docs/public/configuration.mdx`: architecture and user-facing memory/search/privacy explanations.
- Tests sampled across `tests/hook-command.test.ts`, `tests/context-injection.test.ts`, `tests/hooks/file-context.test.ts`, `tests/utils/tag-stripping.test.ts`, `tests/cli/handlers/summarize-tag-stripping.test.ts`, `tests/integration/hook-execution-e2e.test.ts`, `tests/install-disable-auto-memory.test.ts`, `tests/worker/search/search-orchestrator.test.ts`, `tests/worker/search/strategies/hybrid-search-strategy.test.ts`, `tests/worker/http/routes/memory-routes.test.ts`, and related SQLite/context/parser/provider tests found by path search.

## Excluded Paths

- `plugin/scripts/*.cjs`, `plugin/ui/viewer-bundle.js`, `plugin/ui/viewer.html`: generated build outputs. Reviewed source equivalents instead.
- `src/ui/**`, `plugin/ui/**`, `docs/public/*.webp`, `docs/public/*.gif`, `docs/public/*.svg`, `src/ui/*.png`, fonts under `src/ui/viewer/assets` and `plugin/ui/assets`: UI-only or binary assets. Not relevant to memory execution beyond viewer display.
- `docs/i18n/**` and translated `plugin/modes/code--*.json`: generated/localized docs and mode translations. Core behavior was reviewed in English source docs/modes path.
- `evals/swebench/**`: evaluation harness, useful for product benchmarking but unrelated to persistent context capture/reinjection execution path.
- `docker/**`, `Dockerfile.test-installer`, `docker-compose.yml`: packaging/test infrastructure, not core memory logic.
- `openclaw/**`: gateway integration package. Relevant as distribution surface, but not necessary for understanding local hook/worker memory execution.
- `cursor-hooks/**`: legacy/standalone Cursor docs and templates. Current runtime path was covered through `src/services/integrations/CursorHooksInstaller.ts` references and shared hook handlers.
- `plans/**`, `ragtime/**`, `WARP.md`, `CHANGELOG.md`, `NOTICE`, issue/bug-fix notes: planning, examples, release/legal metadata, or project instructions. Not needed for actual memory/context execution.
- `tests/fixtures/**` and broad UI/viewer tests: fixtures and UI behavior. Reviewed representative hook, context, privacy, storage, search, and worker tests instead.
- `node_modules` or vendored dependency trees: not present in the clone and not needed; package dependency metadata was sufficient.
