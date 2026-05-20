# swarmclawai/swarmclaw

- URL: https://github.com/swarmclawai/swarmclaw
- Category: memory
- Stars snapshot: 507, captured from GitHub REST API on 2026-05-20
- Reviewed commit: 6fbda49b1568a02af3994f8a9a8ae8279e4f9ae0
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: conditional
- Verdict: Strong source of memory and agent-runtime patterns, but not a small memory library. The useful pieces are scoped tiered memory, canonical upsert and supersession, hybrid FTS/vector/MMR recall, linked memory traversal, bounded prompt injection, idle consolidation, dream cycles, lazy MCP tool exposure, durable delegation, and schedule wakeups. Avoid copying the full platform shape, broad host-tool surface, plaintext local memory defaults, single shared access-key auth, and plain MCP env/header config storage.

## Why It Matters

SwarmClaw is a real self-hosted TypeScript agent runtime with memory deeply wired into chat execution rather than a standalone note database. It shows how long-term memory, session archives, MCP tools, native tools, delegated workers, schedules, and agent prompts interact in one execution path. That makes it useful for Agentic Coding Lab as a pattern catalog for "memory in the loop": what gets stored, what gets injected, what is withheld, and how the runtime keeps context size and tool count from overwhelming the model.

The repo is especially relevant because it handles several practical edges that simple memory demos skip: connector privacy, pinned identity memories, current-thread recall detection, auto-capture filtering, deduplication, memory graph expansion caps, idle maintenance, prompt-budget enforcement, lazy MCP tool promotion, and durable delegation job state.

## What It Is

SwarmClaw is a Next.js/TypeScript application and npm package for running autonomous agents and multi-agent swarms. It combines a dashboard, API routes, SQLite persistence, LangGraph/ReAct chat execution, native tools, MCP clients, external CLI delegation, scheduled wakeups, connectors, runtime skills, and wallet/platform integrations.

For memory, it keeps a separate SQLite database at `DATA_DIR/memory.db` with JSON metadata, FTS5 indexes, optional embeddings, references, images, links, sharing state, reinforcement counters, access tracking, and maintenance metadata. Agents can access memory explicitly through tools and implicitly through context injected into the system prompt.

## Research Themes

- Token efficiency: Strong. The runtime caps memory context, limits proactive recall to a few items, deduplicates memories already injected into a session, applies prompt budgets, auto-compacts chat history, truncates tool outputs against provider context windows, and exposes MCP tools lazily through search/promotion rather than always injecting every tool schema.
- Context control: Strong. Memory is scoped by global, agent, session, project, and connector context; archive memory is opt-in; current-thread recall requests bypass durable memory search; identity memories are withheld in group connector contexts; direct connector sessions can force session-scoped recall.
- Sub-agent / multi-agent: Strong. The runtime has native `delegate` and `spawn_subagent` tools, CLI backend delegation, batch and swarm modes, join policies, lineage, job checkpoints, coordinator prompt sections, shared memory flags, and scheduled task wakeups.
- Domain-specific workflow: Strong for local/private coding agents and agent operations. It integrates shell, files, edit, execute sandbox, OpenClaw, Claude/Codex/Gemini-style CLI delegation, projects, tasks, schedules, skills, connectors, and MCP servers.
- Error prevention: Good but uneven. It has capability policy gates, file access policy, shell kill guards, untrusted content detection, credential redaction, auth middleware, MCP pool eviction, loop/timeout handling, and tests. Shell path policy and external tool safety remain best-effort.
- Self-learning / memory: Very strong. It implements explicit memory tools, direct memory intent handling, automatic turn capture, breadcrumbs after important tools, session archive snapshots, daily digests, deterministic maintenance, LLM dream cycles, canonical memory upsert, linked memories, and memory doctor reports.
- Popular skills: The repo treats skills as first-class runtime assets. It supports `SKILL.md` imports, built-in tool docs, `use_skill`, managed skills, ClawHub-style installation, skill suggestions, and reviewed conversation-to-skill drafting.

## Core Execution Path

The main chat path starts in `executeSessionChatTurn`, which prepares provider, agent, session, messages, settings, credentials, route policy, skills, and memory scope before streaming a LangGraph/ReAct agent turn. `streamAgentChat` assembles prompt sections for identity, runtime orientation, workspace, agent awareness, coordinator state, current task, project and credential context, tool policy, memory, proactive recall, and goal anchoring. It then builds native and MCP tools, applies tool wrappers, runs the model/tool loop, records events and usage, and finalizes the session turn.

Memory enters that path in two ways. The `memory` tool and legacy aliases route actions through `executeMemoryAction`, which normalizes scopes and categories, guards against storing file-like content, searches for existing canonical memories, updates or supersedes duplicates, writes to `MemoryDB`, and handles links, deletion, listing, search, and doctor reports. Separately, the memory capability's `getAgentContext` injects pinned, identity, known-sender, relevant, recent, and policy guidance into the prompt under an overall character budget.

After tool execution and chat turns, memory hooks add breadcrumbs and auto-capture substantive user/assistant/tool outcomes when filters pass. Idle maintenance and dream paths later compact this material: daily consolidation can create digest memories, deterministic maintenance dedupes and prunes stale working memory, access compaction promotes heavily used working items, and dream cycles generate consolidated insights, reflections, or flags from recent memory.

MCP tools are discovered from configured stdio/SSE/HTTP servers during `buildSessionTools`. Eager or always-exposed tools become LangChain tools immediately; the rest are searchable lazy candidates, with `mcp_tool_search` promoting relevant tools for later turns. Delegation and schedules sit beside this path as native tools: delegation creates durable jobs with backend resume IDs and checkpoints, while schedules enqueue future wake/task runs through a ticking runtime scheduler.

## Architecture

The application has four main runtime layers: a Next.js UI/API layer, a server-side agent execution layer, SQLite persistence, and tool integration. General app state uses `DATA_DIR/swarmclaw.db` through JSON-like collections and relational session messages. Long-term memory uses `DATA_DIR/memory.db` with a richer schema and FTS5. Workspace files live under a configurable workspace directory.

The agent execution layer is built around LangChain/LangGraph chat models and a ReAct-style loop. Provider routing, credential injection, prompt assembly, tool construction, context compaction, and lifecycle hooks are all server-side. Native tools cover files, shell, edit, execute, memory, schedules, delegation, subagents, MCP discovery, connectors, platform management, skills, and other product features.

Memory architecture is local-first. Records have category, title, content, metadata, optional embedding, file paths, image path, linked IDs, references, pinned/shared flags, access counters, content hash, reinforcement count, abstract, and timestamps. Search merges FTS and vector scores with lexical scoring, time decay, pinned/reinforcement/follow-up boosts, and MMR diversity. Linked recall uses a bounded graph traversal.

Security is concentrated in access-key middleware, encrypted credential storage, credential redaction, tool capability policy, file access policy, untrusted content checks, and sandboxed execution. These controls reduce risk but do not make the system multi-tenant or zero-trust.

## Design Choices

SwarmClaw treats memory as a native runtime capability rather than a separate retrieval service. That lets memory react to chat lifecycle events, tool results, connector metadata, schedules, and delegation outcomes, but it also tightly couples memory to the platform.

The memory store favors pragmatic local retrieval: SQLite plus FTS5 always works, embeddings are optional, and first searches can still return FTS results when an embedding has not been cached. Deduplication happens at write time with content hashes, subject-based canonical update, and supersession metadata instead of relying only on retrieval-time reranking.

The prompt design uses multiple gates before context is injected: should memory be used for this turn, what scope is safe, which memories are pinned or identity-like, whether a direct connector context is private, whether this is really a current-thread recall request, and how much budget remains. This is a stronger pattern than blindly appending top-k recall.

The tool runtime chooses explicit capabilities plus lazy extension. Native tools are always built from policy and agent settings. MCP tools can be discovered and searched without flooding the prompt. Delegation is durable, with job IDs, resume IDs, checkpoints, wait/cancel/status actions, fallback backends, and depth guards.

The autonomy layer separates immediate chat execution from background memory work. Daily digest, archive sync, dream cycles, and scheduled wakeups allow the agent to learn or resume without putting all work into the user-facing turn.

## Strengths

The strongest part is the complete memory lifecycle. It covers write, read, search, list, update, delete, link, unlink, auto-capture, archive, consolidation, dedupe, promotion, pruning, and diagnostic reporting with focused tests around many edge cases.

Scope handling is unusually practical. The code distinguishes durable, working, and archive memory; handles global, agent, session, project, and shared records; and treats connector contexts differently to avoid leaking private identity memories into group contexts.

Retrieval is layered instead of single-method. FTS, vector similarity, lexical scoring, salience boosts, temporal decay, reinforcement, pinned priority, follow-up priority, MMR diversity, and linked graph expansion each address a different failure mode.

The runtime has credible production concerns: auth setup, generated access keys, encrypted credentials, redaction, policy-gated tools, sandboxed execute backend, prompt injection warnings, MCP connection pooling, lazy tool discovery, context compaction, and tests across memory, MCP, tool wiring, scheduler, and delegation.

It also demonstrates how memory and multi-agent execution reinforce each other. Delegated jobs, swarms, tasks, schedules, and tool breadcrumbs can all leave durable traces that future turns can recall.

## Weaknesses

The system is large and platform-shaped. Extracting only memory would require untangling app storage, session models, agent config, tool context, lifecycle hooks, prompt sections, and UI/API assumptions.

Memories are stored locally in plaintext SQLite. Credentials are encrypted, but memory content can contain sensitive user data, raw connector context, and auto-captured tool outcomes unless policy and agents avoid it. There is no obvious default memory encryption, secret scanner, per-field sensitivity label, or enforced retention policy for all categories.

Auth is simple. A single shared access key and cookie protect the app when configured, and development mode allows requests when `ACCESS_KEY` is absent. This is acceptable for a local-first tool but weak for multi-user or hosted deployments without additional controls.

MCP server env and header config appears to live in normal server config records rather than the encrypted credential store. That is convenient, but it is risky if users paste tokens into MCP configuration.

Vector retrieval is optional and local-scale. If embeddings are not configured, search falls back to text retrieval. Query embeddings are cached asynchronously, so the first search can be less semantic. Similarity scans appear in-process over stored embeddings, which is not a large-scale vector index.

Tool safety has hard limits. File policy for shell commands is regex/best-effort, host execution and external CLI delegation require trust, MCP tools are external code paths, and LLM dream/consolidation output can still encode wrong conclusions if promoted without review.

## Ideas To Steal

Use one consolidated memory tool with narrow compatibility aliases, and guard memory writes that look like file/code/document storage.

Make memory scope and tier explicit. Durable memory should be the default; working memory should expire or promote; archive memory should require explicit search intent.

Add canonical upsert and supersession metadata. Corrections should update the canonical memory and mark stale competing memories as superseded rather than creating a trail of conflicting facts.

Inject memory through named prompt sections with a hard character budget. Pinned, identity, known-sender, relevant, recent, and policy guidance should compete for budget and drop whole low-priority blocks when needed.

Combine FTS, vector search, lexical scoring, salience boosts, and diversity. A small hybrid search is more robust than a pure embedding top-k for coding-agent memory.

Keep linked memory graph traversal bounded by depth, per-node lookup, and total expansion limits. Return truncation metadata so the agent knows when recall was partial.

Use session archive memories for old transcript recall, but keep them out of normal durable search unless the user asks for archive/all context.

Run background memory maintenance in deterministic and LLM tiers. Deterministic dedupe, promotion, and pruning should not depend on model output; model-generated digests/reflections should be clearly categorized and linked to sources.

Expose MCP tools lazily. A searchable tool catalog with explicit promotion is a good way to keep agent prompts smaller while preserving discoverability.

Persist delegation jobs with backend, prompt, resume ID, checkpoints, status, and cancellation. This is more useful than fire-and-forget subagent calls.

## Do Not Copy

Do not copy the whole platform just to get memory. The valuable patterns can be implemented in a much smaller service or library.

Do not store raw memory plaintext by default for a coding lab. Add redaction, sensitivity labels, optional encryption, and retention controls at the write path.

Do not rely on prompt guidance alone for privacy. Enforce scope, connector visibility, and mutability in the storage layer and API.

Do not allow `scope: all` or global shared memory as the default recall path. Treat broad recall as privileged or explicit.

Do not use async cached embeddings as the only semantic recall path if first-turn semantic recall matters. Either compute synchronously for important queries or make fallback behavior visible.

Do not store MCP tokens, headers, or env secrets in plain config records. Use credential references and redact them from logs, UI, exports, and model-visible context.

Do not allow host shell, external delegation, or broad MCP tools by default in a shared environment. Keep sandboxing, approval, and per-tool policy as hard gates.

Do not promote LLM dream outputs into canonical facts without source links, confidence, and a review or correction path.

## Fit For Agentic Coding Lab

Fit is high as a design reference and conditional as a dependency. SwarmClaw is useful to study because it shows real interactions between durable memory, prompt budget, tool policy, MCP tools, subagents, schedules, and execution records. It is not a clean dependency for Agentic Coding Lab because its memory system is embedded in a full product runtime.

The best adaptation is a smaller local memory runtime: SQLite plus FTS, optional embeddings, explicit scopes, memory tiers, canonical upsert, linked records, prompt injection budgets, archive recall, deterministic maintenance, redaction, and tests. Add MCP lazy discovery and durable delegation only where the lab needs multi-agent execution, not as baseline complexity.

For agent-runtime patterns, copy the lifecycle shape: prepare context, decide whether memory applies, inject bounded recall, execute tools under policy, record structured outcomes, and run background consolidation outside the foreground turn.

## Reviewed Paths

- `README.md`: product scope, install path, runtime claims, memory/MCP/delegation/schedule feature map, and release notes.
- `package.json`: package identity, scripts, runtime/test dependencies, and test surface.
- `research.md`, `docs/**`, `skills/**`: background product positioning, runtime skill conventions, and agent-facing tool docs.
- `src/lib/server/chat-execution/**`: chat preparation, prompt assembly, LangGraph/ReAct execution, proactive memory recall, compaction, tool loop, and lifecycle hooks.
- `src/lib/server/memory/**`: memory database, tiers, policy, graph traversal, session archive memory, consolidation, dream service, and tests.
- `src/lib/server/session-tools/memory.ts` and `src/lib/server/session-tools/memory-tool.ts`: memory tool API, canonical upsert, scope filters, prompt context injection, auto-capture, and write guards.
- `src/lib/server/session-tools/index.ts`: native tool construction, MCP tool loading, lazy MCP discovery, policy wrappers, hooks, and output truncation.
- `src/lib/server/mcp-*.ts` and `src/app/api/mcp-servers/**`: MCP stdio/SSE/HTTP client, connection pool, lazy gateway runtime, and config/test/list routes.
- `src/lib/server/session-tools/delegate.ts`, `src/lib/server/session-tools/subagent.ts`, `src/lib/server/session-tools/schedule.ts`, `src/lib/server/runtime/scheduler.ts`: external delegation, native subagents/swarms, wake scheduling, and scheduled task execution.
- `src/proxy.ts`, `src/app/api/auth/route.ts`, `src/lib/server/storage-auth.ts`, `src/lib/server/storage.ts`, `src/lib/server/credentials/**`, `src/lib/server/session-tools/credential-env.ts`: auth, generated keys, encrypted credential storage, and redaction.
- `src/lib/server/tool-capability-policy.ts`, `src/lib/server/session-tools/file-access-policy.ts`, `src/lib/server/session-tools/shell.ts`, `src/lib/server/session-tools/execute.ts`, `src/lib/server/untrusted-content.ts`, `src/lib/server/ws-hub.ts`: tool policy, file policy, sandbox/host execution, prompt-injection detection, and websocket auth.
- `src/lib/server/**/*.test.ts`, especially memory, MCP, session-tool wiring, scheduler, direct memory intent, dream, and consolidation tests: behavior coverage and edge-case intent.
- `.github/workflows/ci.yml`: CI entry points and package validation context.

## Excluded Paths

- `.git/**`: version-control internals only.
- `node_modules/**`, `.next/**`, `out/**`, `coverage/**`, `electron-dist/**`: generated, dependency, or build output paths; these were not present in the review clone or not needed for source understanding.
- `public/**`, `doc/assets/**`, `resources/**`: screenshots, logos, icons, and binary/branding assets. README image references were enough for context.
- Most `src/components/**`, `src/views/**`, `src/hooks/**`, `src/stores/**`, and UI-heavy `src/app/**` pages: dashboard presentation and client state were not central to memory/runtime execution. Server API routes related to auth, MCP, memory, and execution were reviewed where relevant.
- Desktop packaging and deployment files such as `electron*`, `electron-builder.yml`, `Dockerfile`, `fly.toml`, `render.yaml`, and `railway.json`: useful for distribution posture but not central to memory design.
- Product and release documentation not tied to runtime behavior: skimmed for orientation, but code paths were treated as source of truth.
- Wallet, connector-specific, email, image generation, Google Workspace, and marketplace implementation details outside shared runtime hooks: broad product features, not primary memory or agent-runtime paths for this category.
