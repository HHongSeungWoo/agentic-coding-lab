# matt1398/claude-devtools

- URL: https://github.com/matt1398/claude-devtools
- Category: context-control
- Stars snapshot: 3,408 (GitHub REST API, captured 2026-05-19)
- Reviewed commit: 16cc3c87c1e4d0e08ee101fb52dad1b85dbbe48a
- Reviewed at: 2026-05-19
- Status: reviewed
- Scope fit: in-scope
- Verdict: High-fit context observability reference for Claude Code. It does not control prompts or compaction directly, but it reconstructs session logs, tool calls, subagents, memory, token usage, and context-window phases well enough to become a practical model for Agentic Coding Lab context audits.

## Why It Matters

Agentic Coding Lab needs context control that can be inspected after a run. Prompt rules and handoff files are not enough if no one can answer what the agent read, which tool output filled the window, when compaction happened, which subagent consumed budget, or whether memory and CLAUDE.md files were actually visible.

`claude-devtools` matters because it turns Claude Code's local JSONL logs into a structured debugging surface. The useful pattern is not the Electron UI itself; it is the forensic pipeline: read append-only local transcripts, normalize messages, link tool calls to results, resolve subagent files, split context into named categories, and show compaction phases as state changes instead of vague progress bars.

## What It Is

`claude-devtools` is a TypeScript Electron app plus a standalone Fastify HTTP server. It reads Claude Code data under `~/.claude/`, especially `projects/<encoded-project>/*.jsonl`, per-session `subagents/agent-*.jsonl`, `todos/<session>.json`, and `projects/<encoded-project>/memory/*.md`.

The app is read-oriented for session data. It parses existing local logs, renders them in a desktop or browser UI, watches for updates, supports SSH-backed remote filesystem access, and optionally runs a local HTTP sidecar. It also stores app configuration in `~/.claude/claude-devtools-config.json` and renderer context-switch snapshots in IndexedDB.

## Research Themes

- Token efficiency: Strong implementation value. The app uses streaming JSONL parsing, requestId deduplication for streaming assistant entries, LRU session caches, mtime-size fingerprints, unchanged sentinels over IPC, search-specific lightweight extraction, and raw-message stripping before renderer transfer.
- Context control: Strong as observability, not enforcement. It reconstructs visible context across CLAUDE.md files, @mentioned files, tool outputs, thinking/text, task coordination, and user prompts, then resets accumulated context at compaction boundaries.
- Sub-agent / multi-agent: Strong for reconstruction. It reads subagent JSONL files, filters warmup/compact artifacts, links Task calls to agent files through `toolUseResult.agentId`, supports team metadata, detects continuation files through parent UUID chains, and marks near-simultaneous starts as parallel.
- Domain-specific workflow: High. The code is tailored to Claude Code session layouts, encoded project paths, tool block shapes, Claude memory directories, team tools, SSH remote sessions, and local developer workflows.
- Error prevention: Moderate to strong. It validates IPC IDs, constrains file reads to project or Claude roots, blocks sensitive paths, checks symlink realpaths, caps mentioned-file token reads, validates regex patterns, and can notify on tool errors or custom triggers.
- Self-learning / memory: Moderate. It exposes Claude Code's memory directory as a readable layer index, but it does not write memories, learn preferences, or choose retrieval policy.
- Popular skills: Session log parsers, append-only file watchers, context ledgers, compaction phase tracking, subagent trace linking, read-only memory viewers, token category panels, and local-only debugging sidecars.

## Core Execution Path

Electron startup in `src/main/index.ts` initializes `ConfigManager`, creates a local `ServiceContext`, starts `FileWatcher`, wires IPC handlers, and optionally starts a Fastify sidecar. Standalone startup in `src/main/standalone.ts` uses the same service stack without Electron, serving API routes and static renderer output.

`ServiceContext` is the main runtime bundle. Each context owns a `ProjectScanner`, `MemoryReader`, `SessionParser`, `SubagentResolver`, `ChunkBuilder`, `DataCache`, and `FileWatcher` over a `FileSystemProvider`. Local and SSH modes use the same higher-level services with different filesystem providers.

Project discovery starts in `ProjectScanner`. It scans `~/.claude/projects`, accepts only encoded project directories, reads root-level `.jsonl` session files, resolves cwd from logs when local, splits mixed-cwd directories into subprojects, groups worktrees, loads todo JSON, and builds session rows. `analyzeSessionFileMetadata` streams session files to derive first user message, message counts, ongoing state, git branch, context consumption, compaction count, and per-phase breakdown.

Session detail calls parse the full session through `parseJsonlFile` and `parseChatHistoryEntry`. The parser extracts message metadata, tool calls, tool results, usage, request IDs, sidechain flags, compact-summary flags, `sourceToolUseID`, and `toolUseResult`. Metrics dedupe assistant streaming entries by `requestId` so token totals are not inflated.

`SubagentResolver` lists files from both the new structure, `<project>/<session>/subagents/agent-*.jsonl`, and the legacy project-root `agent-*.jsonl` structure. It parses each file, filters warmup agents and `acompact` artifacts, links agents to parent Task tool calls by result agent IDs, falls back to description matching for team members, propagates team metadata across continuation files, and detects parallel starts within 100 ms.

`ChunkBuilder` filters sidechain messages and classifies main-thread messages as user, system, compact, hard noise, or AI. It buffers consecutive AI messages into independent AI chunks, attaches tool executions, sidechain messages, linked subagents, semantic steps, and semantic step groups. Task tool calls remain in semantic steps for context accounting even when renderer display hides duplicate Task rows.

Renderer code then transforms chunks into chat groups and context views. `contextTracker.ts` builds a per-AI-turn context ledger: global and directory CLAUDE.md files, user @mentions, tool output tokens, team coordination tokens, user message tokens, and thinking/text tokens. `processSessionContextWithPhases` resets accumulated injections when compact chunks appear and records token deltas between pre- and post-compaction AI groups.

Search deliberately avoids the full chunk path. `SearchTextExtractor` mirrors the classifier loop but extracts only user text and the last assistant text output. `SessionSearcher` combines that with an mtime-keyed LRU cache, staged breadth limits for SSH, and bounded concurrency.

Live updates come from `FileWatcher`. Local mode uses `fs.watch` plus debounce and a 30-second catch-up scan for missed macOS events. SSH mode uses polling. JSONL changes invalidate session/subagent caches and can run incremental appended-line error detection. Memory `.md` changes and todo JSON changes emit separate events to the renderer and HTTP SSE clients.

## Architecture

The repo is a desktop app with a reusable backend core:

- Main/runtime: `src/main/index.ts`, `src/main/standalone.ts`, `src/main/ipc/**`, and `src/main/http/**` expose the same session services through Electron IPC and Fastify routes.
- Service layer: `src/main/services/**` contains discovery, parsing, analysis, infrastructure, error detection, SSH, config, cache, and memory readers.
- Shared models/utilities: `src/main/types/**`, `src/shared/types/**`, and `src/shared/utils/**` define parsed messages, chunks, sessions, memory indexes, token formatting, sanitization, and session response contracts.
- Renderer: `src/renderer/**` owns chat rendering, context panels, memory views, notification settings, Zustand state, IndexedDB context snapshots, keyboard navigation, and HTTP/Electron API adapters.
- Tests: `test/**` covers parser, chunks, file watcher behavior, path validation, memory parsing, search extraction/cache, model/token helpers, store slices, and renderer utilities.

The central abstraction is `ServiceContext`. That keeps local and SSH session data isolated while reusing the scanner/parser/chunk/context pipeline.

## Design Choices

The strongest design choice is treating the transcript as the source of truth. The app does not wrap Claude Code or require a custom launcher, so it can inspect past sessions and avoid changing agent behavior.

The second strong choice is separating parse fidelity from UI transfer cost. Main process parsing keeps full messages and process details long enough to build chunks and semantic steps, then IPC session detail strips raw `messages` and process message arrays before sending to the renderer. The mtime-size fingerprint lets refresh calls skip full payloads when files are unchanged.

The context ledger is practical because it is category-first. Instead of one context number, it shows user prompts, CLAUDE.md, mentioned files, tool I/O, thinking/text, and task coordination separately. That maps directly to agent design decisions: shrink always-loaded rules, cap tool outputs, summarize team chatter, and inspect @mentions.

Compaction is modeled as a phase boundary. Both session metadata and renderer context stats treat compact-summary markers as resets and compute pre/post token deltas from assistant usage. This is a good pattern for any long-horizon coding agent that needs to explain what got lost after compaction.

Subagents are linked by evidence before timing. Result `agentId` matching is primary, description matching handles teams, and timing only fills gaps. That avoids many false links in sessions with parallel Task calls.

Search is optimized as its own read model. It does not reuse expensive chunk construction just to answer text search. This is a useful pattern for agent lab tools: build multiple projections from the same transcript, each with the minimum structure needed.

The safety posture is mostly read-local and boundary-based. IPC guards validate encoded project IDs and session IDs, path validation restricts user-requested reads to project or Claude roots, sensitive files are blocked, and symlink realpaths are checked. Memory reads accept only simple `.md` filenames inside the memory directory.

## Strengths

- End-to-end reconstruction of Claude Code sessions from real local artifacts: JSONL, subagent logs, todos, memory layers, CLAUDE.md files, and tool blocks.
- Clear service boundary for local vs SSH contexts through `FileSystemProvider` and `ServiceContext`.
- Good performance instincts: streaming parsers, bounded concurrency, metadata-level options, LRU caches, cache fingerprints, search-specific extraction, and SSH fast-search staging.
- Strong subagent support, including new and legacy directory structures, team metadata, continuation files, warmup filtering, and parallel detection.
- Context panel translates raw logs into actionable categories instead of only total tokens.
- Compaction phases are visible and navigable.
- File watcher includes retry, debounce, polling fallback, catch-up scans, incremental append parsing, and stale cache invalidation.
- Memory viewer is read-only and constrained to Claude Code memory files.
- Tests cover many failure-prone utilities and service contracts, especially path validation, file watcher edge cases, parser/chunk behavior, search, and memory parsing.

## Weaknesses

- It observes context but does not control context. There is no policy engine for prompt assembly, retrieval, compression, handoff generation, or tool-output truncation.
- Context attribution is heuristic. It estimates category tokens from rendered/tool data and known paths; it cannot prove the exact API prompt contents, and some generated text/tool call/result accounting may not match provider-side context semantics.
- The implementation depends on private Claude Code log schema details. Message fields, compact markers, team tags, subagent paths, and tool result shapes can drift.
- `SubagentDetailBuilder` constructs detail paths as `<project>/subagents/agent-*.jsonl`, while the resolver and path decoder support the newer `<project>/<session>/subagents/agent-*.jsonl` layout. Summary linking can work while drill-down detail misses new-layout subagents.
- Browser/standalone mode has a larger exposure surface. Docker defaults to `HOST=0.0.0.0`, CORS can be `*`, and there is no authentication. Some HTTP helper routes trust client-supplied `projectRoot` or `dirPath` for CLAUDE.md and agent-config reads rather than deriving them from a validated project ID.
- Transcript content itself may contain secrets already read by Claude Code. Path validation protects new file reads, but it cannot redact sensitive data that is already in JSONL tool outputs.
- Cost display is not a reliable pattern source: core metrics set `costUsd` to undefined rather than computing model pricing.
- Tests are broad but not complete for context-control claims. There is no obvious end-to-end fixture asserting the full context ledger across real Claude JSONL with compaction, @mentions, CLAUDE.md validation, tool outputs, team messages, and subagent drill-down.

## Ideas To Steal

- Build a read-only context audit sidecar for Agentic Coding Lab runs. It should parse run logs after the fact and show what entered context by category.
- Treat compaction as a first-class phase boundary with pre/post token evidence and a reset context ledger.
- Use a `ServiceContext` bundle per workspace or remote host so caches, watchers, scanners, and filesystem providers cannot bleed across contexts.
- Keep transcript parsing streaming and projection-based. Session list metadata, search, full detail, notifications, and exports should not all share the most expensive representation.
- Add mtime-size fingerprints and unchanged sentinels to any UI that refreshes live agent logs.
- Link subagents to parent calls by explicit result IDs before falling back to timestamps.
- Record task/team coordination as its own token category instead of hiding it inside generic tool output.
- Maintain a lightweight memory index viewer for file-backed agent memories, with orphan detection and strict read containment.
- Use notification triggers as safety probes: tool errors, sensitive path access, token thresholds, and custom regex rules over tool inputs/results.
- Before renderer/UI transfer, remove raw message payloads that are not needed for display.

## Do Not Copy

- Do not treat reconstructed context categories as authoritative prompt accounting unless the agent runtime emits a signed or structured context manifest.
- Do not depend on private Claude Code schemas without versioned fixtures and drift tests.
- Do not expose a session-log HTTP server on an untrusted network without auth, origin controls, and clear warnings about prompt/tool-output sensitivity.
- Do not trust client-supplied `projectRoot` or `dirPath` for file reads. Derive roots from validated project/session IDs.
- Do not copy the current subagent detail path assumption; use the same locator for summary and drill-down reads.
- Do not make the lab depend on a large Electron UI when a smaller CLI/HTML report or JSON context ledger would satisfy most research needs.
- Do not display raw tool outputs without a redaction mode, because logs can contain secrets even if new reads are blocked.

## Fit For Agentic Coding Lab

Fit is high for the `context-control` category as an observability and audit reference. It should influence lab instrumentation more than lab runtime behavior.

Best adaptation: create a smaller context-audit artifact that reads our agent run logs and emits a stable JSON/Markdown report with turns, tools, subagents, token categories, memory files, compaction phases, and safety events. Pair that with optional UI later.

The key design invariant to steal is: context control should produce evidence. If a skill says "keep context small" or a handoff says "memory loaded," the runtime should leave enough structured trace data for a tool like this to verify the claim.

## Reviewed Paths

- `README.md`, `SECURITY.md`, `Dockerfile`, `docker-compose.yml`: product claims, local-data model, install/deployment modes, no-telemetry claims, Docker read-only mount, and network isolation guidance.
- External docs pages linked from the README for token usage, JSONL format, tool calls, subagents, compaction, memory, SSH remote sessions, copy/paste, and verbose comparison: reviewed as product documentation because no local docs folder is present.
- `package.json`, `electron.vite.config.ts`, `vite.standalone.config.ts`: scripts, package boundaries, Electron/standalone bundling, native module stubs, and production dependencies.
- `src/main/index.ts`, `src/main/standalone.ts`, `src/main/http/index.ts`, `src/main/services/infrastructure/HttpServer.ts`: Electron startup, standalone startup, route registration, SSE forwarding, static serving, host/port/CORS behavior, and service wiring.
- `src/main/services/infrastructure/ServiceContext.ts`, `ServiceContextRegistry.ts`, `DataCache.ts`, `FileWatcher.ts`, `ConfigManager.ts`, `LocalFileSystemProvider.ts`, `SshFileSystemProvider.ts`, `SshConnectionManager.ts`: context isolation, caches, watchers, config storage, local/SSH filesystem behavior, and remote-session safety.
- `src/main/services/discovery/ProjectScanner.ts`, `ProjectPathResolver.ts`, `SubprojectRegistry.ts`, `WorktreeGrouper.ts`, `SubagentLocator.ts`, `SubagentResolver.ts`, `MemoryReader.ts`, `SessionSearcher.ts`, `SearchTextExtractor.ts`, `SearchTextCache.ts`, `SessionContentFilter.ts`: discovery, metadata, subagents, memory, search, and filtering paths.
- `src/main/services/parsing/SessionParser.ts`, `MessageClassifier.ts`, `ClaudeMdReader.ts`, `AgentConfigReader.ts`, `src/main/utils/jsonl.ts`, `toolExtraction.ts`, `metadataExtraction.ts`, `sessionStateDetection.ts`, `pathDecoder.ts`, `pathValidation.ts`, `regexValidation.ts`, `tokenizer.ts`: log parsing, message classification, context file reads, validation, token estimation, and path handling.
- `src/main/services/analysis/ChunkBuilder.ts`, `ChunkFactory.ts`, `ToolExecutionBuilder.ts`, `SubagentDetailBuilder.ts`, `ProcessLinker.ts`, `SemanticStepExtractor.ts`, `SemanticStepGrouper.ts`, `ToolResultExtractor.ts`, `ToolSummaryFormatter.ts`: chunks, tools, subagent detail, semantic steps, and waterfall support.
- `src/main/ipc/**` and `src/main/http/**`: IPC/HTTP route contracts, validation layers, session detail responses, search, subagents, memory, utility reads, SSH, context switching, notifications, and config.
- `src/renderer/utils/contextTracker.ts`, `claudeMdTracker.ts`, `aiGroupEnhancer.ts`, `displayItemBuilder.ts`, `groupTransformer.ts`, `toolLinkingEngine.ts`, `sessionExporter.ts`: renderer context ledger, CLAUDE.md detection, display item assembly, tool result linking, and export behavior.
- `src/renderer/types/contextInjection.ts`, `claudeMd.ts`, `groups.ts`, `data.ts`, `api.ts`; `src/renderer/components/chat/ContextBadge.tsx`, `SessionContextPanel/**`, `TokenUsageDisplay.tsx`, `AIChatGroup.tsx`, `CompactBoundary.tsx`, `items/linkedTool/**`, `items/SubagentItem.tsx`; `src/renderer/services/contextStorage.ts`; `src/renderer/store/slices/contextSlice.ts`, `sessionDetailSlice.ts`, `memorySlice.ts`, `subagentSlice.ts`: context UI, token popovers, context panel, IndexedDB snapshots, and state flow.
- `src/shared/utils/contentSanitizer.ts`, `memoryIndex.ts`, `sessionDetailResponse.ts`, `markdownTextSearch.ts`, `modelParser.ts`, `tokenFormatting.ts`, `sessionIdValidator.ts`: shared parsing, display, and IPC contract utilities.
- `test/main/**`, `test/renderer/**`, `test/shared/**`: parser, chunk, file watcher, project scanner, search, memory, path validation, IPC guard, store, renderer utility, and shared contract tests.

## Excluded Paths

- `public/*.mp4`, `resources/demo.mp4`, `public/memory.png`, `resources/icons/**`, and other image/video/icon assets: binary or product-demo media, not execution or context-control logic.
- `src/renderer/components/settings/**`, most `src/renderer/components/layout/**`, sidebar/dashboard/search UI styling, `src/renderer/index.css`, and Tailwind/CSS constants: sampled only where they touch context, memory, or notification behavior; most are UI shell and visual presentation.
- `resources/entitlements*.plist`, `resources/afterInstall.sh`, `scripts/notarize.cjs`, build signing metadata, and installer packaging details: release/platform mechanics, not session parsing or context control.
- `pnpm-lock.yaml`, `postcss.config.cjs`, `tailwind.config.js`, `eslint.config.js`, `knip.json`, `tsconfig*.json`, and workspace metadata: dependency/tooling configuration reviewed only enough to understand scripts and test/build gates.
- `CHANGELOG.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `LICENSE`, and repository housekeeping: maintenance/legal context, not runtime design.
- Generated build output, vendored dependency trees, and coverage artifacts: none were present in the reviewed checkout; if produced locally, they should stay excluded from research notes.
