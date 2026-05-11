# mksglu/context-mode

- URL: https://github.com/mksglu/context-mode
- Category: skills-instructions
- Stars snapshot: 14.3k (GitHub repository page, captured 2026-05-11)
- Reviewed commit: df605439a44bad024bee68d5e563f78a5784e3a6
- Reviewed at: 2026-05-11
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong pattern source for context control, token efficiency, durable session memory, and hook-level error prevention. Do not copy wholesale: it is a large multi-platform MCP/hook product, not just a lightweight instruction pack.

## Why It Matters

context-mode attacks the main failure mode of long AI coding sessions: agents dump raw tool output into context, then lose working state on compaction. Its useful research value is the combination of model-side instructions, runtime hooks, sandboxed data processing, persistent SQLite memory, and verification-heavy platform adapters. The repo shows how far a "skills and instructions" system can go when it is backed by enforcement and durable storage instead of relying only on prompts.

For Agentic Coding Lab, the most relevant patterns are not the exact MCP tool names. They are the routing hierarchy, "think in code" workflow, reference-based resume snapshots, timeline search over prior work, and test discipline around hook/platform drift.

## What It Is

context-mode is an npm-distributed MCP server plus plugin/hook adapters for AI coding clients. It registers tools such as `ctx_execute`, `ctx_execute_file`, `ctx_batch_execute`, `ctx_index`, `ctx_search`, `ctx_fetch_and_index`, `ctx_stats`, `ctx_doctor`, `ctx_upgrade`, `ctx_purge`, and `ctx_insight`.

The repo also ships instruction files and skills. `skills/context-mode/SKILL.md` defines the default agent behavior: prefer sandboxed `ctx_*` tools for large outputs, write code to analyze data, use file-backed indexing for Playwright/MCP outputs, batch search queries, and avoid re-indexing data already in context. `configs/*` adapts the same rules into `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, Copilot instructions, Cursor `.mdc`, Kiro steering, and platform-specific hook configs.

The implementation is TypeScript with generated ESM bundles committed for distribution. Runtime state is mostly SQLite: FTS5 content stores for indexed outputs and per-project SessionDB files for event history, resume snapshots, tool counters, byte accounting, and stats.

## Research Themes

- Token efficiency: Sandboxed subprocess execution returns only stdout, large outputs are indexed instead of returned, batch execution collapses many calls into one, search results are capped/throttled, URL fetches have a 24h TTL cache, and benchmarks claim 315 KB to 5.5 KB for structured data processing and 96% overall savings across fixtures.
- Context control: Hook routing blocks or redirects `curl`/`wget`, `WebFetch`, inline HTTP, verbose build tools, large reads, and repeated search calls. SessionStart injects an XML routing block; platform configs provide fallback model-side rules where hooks cannot inject.
- Sub-agent / multi-agent: Routing logic appends context-mode rules into subagent prompts and changes Bash-type subagents to general-purpose for Claude-like platforms. OpenCode/Kilo plugin hooks handle prompt capture and compaction without a native SessionStart hook.
- Domain-specific workflow: The core workflow is "think in code": write JS/Python/shell analysis inside the sandbox, print concise findings, then use FTS5 search for exact snippets. It is tailored to coding agents handling tests, logs, Git, MCP docs, browser snapshots, API responses, and build output.
- Error prevention: Security policy parsing, deny/ask/allow matching, SSRF guards, Read deny checks, shell allowlists, output hard caps, hook crash wrappers, bundle assertions, native dependency self-heal, and platform-specific formatter tests are central design pieces.
- Self-learning / memory: PostToolUse/UserPromptSubmit hooks persist file, rule, task, plan, git, error, decision, role, skill, subagent, MCP, latency, blocker, constraint, and rejected-approach events. PreCompact builds resume snapshots; SessionStart and timeline search recover prior work. Auto-memory searches project/user instruction files and memory directories.
- Popular skills: `skills/context-mode` is the main routing skill; `skills/ctx-stats`, `skills/ctx-doctor`, `skills/ctx-upgrade`, `skills/ctx-purge`, and `skills/ctx-insight` expose operational commands. `.claude/skills/context-mode-ops` contains maintainer workflow skills for review, release, validation, and issue triage.

## Core Execution Path

The default package path starts at `context-mode` (`src/cli.ts` / `cli.bundle.mjs`). With no subcommand, it starts the MCP server from `src/server.ts`. With `hook <platform> <event>`, it dispatches to hook scripts under `hooks/`. With `doctor`, `upgrade`, `insight`, or `statusline`, it runs utility paths.

The MCP server registers tools and lazily opens a per-project `ContentStore`. `ctx_execute` writes the requested code to a temp file and runs it through `PolyglotExecutor` in JavaScript, TypeScript, Python, shell, Ruby, Go, Rust, PHP, Perl, R, or Elixir. JS/TS execution is instrumented to count network and filesystem bytes. If stdout is large or an `intent` is supplied, the result is indexed and the tool returns titles/previews plus search terms instead of raw output.

`ctx_execute_file` resolves a project-relative path, checks Read deny policy, loads content into `FILE_CONTENT` inside the subprocess, and returns only printed analysis. `ctx_index` reads content or a path into FTS5. `ctx_search` queries the current content store by BM25/RRF or, in `sort: "timeline"`, merges current store results with prior SessionDB events and auto-memory files. `ctx_batch_execute` runs multiple shell commands, indexes all labeled output, and immediately searches it. With `concurrency > 1`, it uses `runPool` for bounded parallelism and per-command timeouts.

`ctx_fetch_and_index` fetches URLs in a subprocess, converts HTML to markdown with Turndown, indexes JSON by key path or text by line chunks, and returns a small preview. Fetches can run in parallel, but FTS5 writes are drained serially. The URL path performs scheme/IP SSRF checks before cache lookup, patches DNS lookup inside the subprocess to defend against rebinding, strips proxy env vars, and composes cache keys from `(source, url)` to avoid label collisions.

Hook execution wraps around the MCP path. `PreToolUse` calls `routePreToolUse`, which normalizes platform tool names, checks user security policies, blocks/redirects flooding tools, writes marker files for rejected approaches and byte accounting, and emits one-time guidance. `PostToolUse` extracts structured events and writes them to SessionDB. `UserPromptSubmit` captures raw prompts plus decisions/roles/intents. `PreCompact` builds and stores a resume snapshot. `SessionStart` injects the routing block, writes events files for auto-indexing, and restores live events or claimed snapshots.

## Architecture

The architecture has four layers:

1. Instruction layer: `skills/context-mode/SKILL.md`, platform configs, and `hooks/routing-block.mjs` define tool-selection hierarchy and "think in code" behavior.
2. Enforcement layer: `hooks/core/routing.mjs`, platform hook wrappers, and adapter formatters convert generic route decisions into Claude Code, Gemini, VS Code Copilot, Cursor, Codex, OpenCode/Kilo, and other platform responses.
3. Data layer: `ContentStore` stores searchable output in SQLite FTS5 with porter and trigram indexes. `SessionDB` stores durable session events, metadata, resume snapshots, tool counters, and bytes saved/returned.
4. Tool layer: `src/server.ts` implements sandboxed execution, file processing, web fetch/index, batch execution, stats, doctor, upgrade, purge, and insight dashboard launch.

Adapters are deliberately platform-specific only at the edges. `BaseAdapter` owns config/session directory conventions. Path hashing and worktree suffix logic live in `src/session/db.ts` and are imported into hooks through bundled JS so TS server and hook scripts do not drift. The OpenCode/Kilo adapter is an in-process TypeScript plugin because those clients use plugin hooks instead of JSON stdin/stdout hook subprocesses.

## Design Choices

The strongest design choice is replacing "summarize in the model" with "program the analysis." The skill says the model should generate code that reads/processes raw data and prints findings, while the runtime ensures the raw data remains outside context.

Search is built for exact retrieval, not fuzzy narrative memory. Markdown chunks preserve code blocks, titles/headings are weighted 5x in BM25, porter and trigram FTS5 results are merged with Reciprocal Rank Fusion, multi-term results get proximity/phrase reranking, and a Levenshtein vocabulary pass handles typos.

Session memory is reference-based. `buildResumeSnapshot` does not dump all prior data back into context; it emits compact XML sections with suggested `ctx_search` calls over `session-events`. The separate session directive writes category-organized markdown so SessionStart can index detailed history and inject a guide.

The hook router uses a hybrid of hard blocks, safe pass-through, and advisory context. It hard-blocks WebFetch and unsafe HTTP, rewrites some Bash commands to echo a redirect message, allows bounded commands such as `git status`, and throttles guidance with per-session marker files to avoid instruction spam.

The repo favors "best effort but never break the agent" for continuity and stats. Many write paths are `setImmediate` or catch-all guarded. For security, that is softened by visible warnings and `CONTEXT_MODE_REQUIRE_SECURITY=1` for fail-closed behavior.

## Strengths

The repo turns instructions into enforceable behavior. The same routing ideas exist in skill text, platform files, SessionStart injection, PreToolUse routing, and subagent prompt mutation.

It treats token efficiency as an end-to-end system: fewer tool calls, smaller responses, persistent searchable indexes, cache hints, progressive throttling, and byte accounting all reinforce the same goal.

Durable memory is practical and coding-specific. Captured events cover files, git operations, tasks, plans, errors, constraints, decisions, roles, skills, subagents, MCP calls, and rejected approaches. This is better than generic chat memory because it maps to agent recovery tasks after compaction.

Verification surface is broad. Tests cover search layers, security pattern parsing, hook routing, platform formatters, Codex manifests, OpenCode plugin behavior, session DB schema, resume fallback, byte accounting, bundle invariants, runtime detection, and adapters.

The design acknowledges platform limitations. Codex cannot modify args, Cursor cannot surface all hook context, OpenCode lacks SessionStart, and MCP-only platforms rely on instruction files. The repo encodes these differences instead of pretending one hook model fits all.

## Weaknesses

The system is large and operationally invasive. It installs hooks, rewrites or heals plugin registries, maintains generated bundles, manages native SQLite dependencies, and carries platform-specific edge cases. This is too heavy for a small skill pack.

Some documentation appears to lag implementation. For example, platform counts and support tables vary across README, docs, package metadata, and code; OMP/Kiro support descriptions differ between older docs and current source/config files. A consumer must trust source/tests over marketing tables.

The fail-open default for security module load failures is pragmatic but risky. Users must opt into fail-closed behavior with `CONTEXT_MODE_REQUIRE_SECURITY=1`.

Search over prior SessionDB events uses LIKE matching, while current content uses FTS5. Timeline memory therefore has weaker retrieval quality than indexed content, and auto-memory matching is a simple term scan over instruction/memory files.

The "mandatory" language in prompts can fight project-specific workflow preferences. It works as a product stance, but Agentic Coding Lab should adapt it into scoped heuristics and explicit escalation rules.

Generated bundles and large text artifacts (`server.bundle.mjs`, `cli.bundle.mjs`, hook bundles, `llms-full.txt`, lockfiles) increase review noise. They matter for distribution, but they are poor sources for design understanding.

## Ideas To Steal

Use a routing hierarchy that appears in both instructions and enforcement: gather via batch/index, follow up via search, process via sandboxed code, fetch via fetch-and-index, edit via normal file tools.

Persist session events as typed, prioritized, searchable records. Include `source_hook`, project attribution, dedup hashes, byte accounting, and compact categories. This is a useful schema for durable coding memory.

Build compaction snapshots as tables of contents with precise retrieval calls, not as lossy summaries. The "search first, do not ask the user to re-explain" directive is worth adopting.

Add progressive throttles for context-expensive tools. After a few `ctx_search` calls, reduce result count; after too many, block and route to a batched workflow.

Separate platform-normalized routing decisions from platform-specific output formatters. The same internal `{ action: "deny" | "ask" | "modify" | "context" }` shape can target multiple clients.

Treat generated/distribution artifacts as verification targets. The `assert-bundle` script is a good example of catching ESM bundling regressions that ordinary unit tests might miss.

Count real bytes saved/returned. Even approximate accounting gives a concrete feedback loop for context-efficiency work and reveals whether features actually reduce context.

## Do Not Copy

Do not copy the entire global-install and self-heal machinery unless building a product with the same distribution problem. Registry repair, cache symlinks, and settings mutation are high-blast-radius operations.

Do not adopt mandatory blanket routing without local escape hatches. A lab harness should encode "large or risky output goes through sandbox" rather than "all commands default to context-mode."

Do not keep security fail-open for high-trust environments. If a hook is acting as a policy boundary, failure should be visible and preferably fail-closed.

Do not vendor generated bundles into research artifacts. Review source and tests; treat bundles as distribution output.

Do not depend on native SQLite unless FTS5, WAL behavior, and cross-platform packaging are truly needed. For smaller systems, a lighter store may preserve most memory benefits with less operational risk.

## Fit For Agentic Coding Lab

Fit is high for patterns, moderate for implementation reuse. The repo is in-scope because it provides skills/instructions plus enforcement, context-window controls, persistent memory, verification workflows, and adapter patterns for coding agents.

Best candidates for Agentic Coding Lab artifacts:

- A compact "think in code" skill that routes large data processing to sandboxed scripts.
- A session-event schema and compaction snapshot format with search references.
- A hook-routing decision object plus per-platform formatter boundary.
- A context budget harness that measures bytes returned versus bytes indexed/avoided.
- Verification checklists for plugin manifests, hook formatters, and generated bundles.

Whole-project adoption is not recommended. It solves a broad commercial plugin problem across many clients; Agentic Coding Lab should extract smaller, composable pieces.

## Reviewed Paths

- `README.md`: install paths, tool catalog, platform behavior, context-saving/session-continuity claims, cache/search model.
- `BENCHMARK.md`: real-output fixture benchmark, tool decision matrix, reported context savings, reproduction notes.
- `package.json`: npm entrypoints, exports, scripts, dependencies, plugin/package metadata.
- `src/server.ts`: MCP tool registration and execution paths for sandbox, file processing, index/search, fetch/cache, batch, stats, doctor, upgrade, purge, insight.
- `src/executor.ts`, `src/runtime.ts`, `src/db-base.ts`, `src/runPool.ts`, `src/security.ts`, `src/fetch-cache.ts`: sandbox process model, runtime selection, SQLite drivers, concurrency primitive, deny policy parser, cache key design.
- `src/store.ts`, `src/search/unified.ts`, `src/search/auto-memory.ts`: FTS5 schema, BM25/RRF/fuzzy/proximity search, timeline merge, auto-memory file search.
- `src/session/db.ts`, `src/session/extract.ts`, `src/session/snapshot.ts`, `src/session/event-emit.ts`, `src/session/project-attribution.ts`: persistent memory schema, event extraction, resume snapshot builder, byte-accounting events, project attribution.
- `hooks/core/routing.mjs`, `hooks/pretooluse.mjs`, `hooks/posttooluse.mjs`, `hooks/precompact.mjs`, `hooks/sessionstart.mjs`, `hooks/userpromptsubmit.mjs`, `hooks/session-helpers.mjs`, `hooks/session-directive.mjs`, `hooks/auto-injection.mjs`, `hooks/run-hook.mjs`, `hooks/session-loaders.mjs`: routing, hook crash handling, session capture, compaction, resume, directive generation, bundle fallback.
- `src/adapters/*`, especially `detect.ts`, `base.ts`, `codex/*`, `opencode/plugin.ts`: platform detection, storage conventions, Codex limits, OpenCode/Kilo plugin execution path.
- `configs/*`, `.codex-plugin/*`, `.claude-plugin/*`, `.cursor-plugin/*`, `.openclaw-plugin/*`, `.pi/extensions/context-mode/*`, `skills/*`: instruction packs, plugin manifests, MCP config examples, operational skills.
- `src/cli.ts`, `scripts/postinstall.mjs`, `scripts/assert-bundle.mjs`, `scripts/heal-installed-plugins.mjs`, `scripts/version-sync.mjs`: CLI dispatcher, install/upgrade/self-heal paths, bundle verification, version sync.
- `tests/core/*`, `tests/hooks/*`, `tests/session/*`, `tests/adapters/*`, `tests/plugins/*`, `tests/security.test.ts`, `tests/opencode-plugin.test.ts`, `tests/scripts/*`, `tests/util/*`: verification coverage for hot paths and platform drift.
- `docs/platform-support.md`, `docs/adapters/openclaw.md`, `docs/jetbrains-copilot.md`: platform matrix and adapter-specific notes, read as secondary documentation behind source/tests.

## Excluded Paths

- `server.bundle.mjs`, `cli.bundle.mjs`, `hooks/session-*.bundle.mjs`, `hooks/session-attribution.bundle.mjs`: generated distribution bundles. I used source files and tests instead; bundles were considered only as artifacts guarded by `scripts/assert-bundle.mjs`.
- `build/` output: not present in the checkout; package scripts generate it from TypeScript.
- `bun.lock`: dependency lockfile, not useful for execution-path design except to confirm package manager.
- `llms.txt`, `llms-full.txt`, `docs/llms.txt`, `docs/llms-full.txt`: generated/aggregated documentation for LLM consumption; redundant with README/source for this review.
- `stats.json`: generated install/use statistics, unrelated to architecture except as product telemetry.
- `insight/src/**`, `insight/index.html`, `insight/vite.config.ts`, `web/index.html`: dashboard/UI-only surface. I noted `ctx_insight` launch mechanics but did not review UI implementation.
- `.github/ISSUE_TEMPLATE/*`, `.github/FUNDING.yml`, most workflow YAML: project maintenance metadata. I reviewed scripts/tests instead of CI wiring details.
- `tests/fixtures/**`, `tests/benchmark-results-v04.json`: large fixture data and benchmark output. I used benchmark/test descriptions, not raw fixture contents.
- `.cursor-plugin/assets/logo.png` and other image/binary assets: branding/binary assets with no bearing on context-mode execution.
- `docs/UPSTREAM-CREDITS.md`, most marketplace README copy: provenance/marketing material, not core design.
