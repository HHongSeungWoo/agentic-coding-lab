# PCIRCLE-AI/toonify-mcp

- URL: https://github.com/PCIRCLE-AI/toonify-mcp
- Category: token-efficiency
- Stars snapshot: 62 (GitHub REST API repo metadata, captured 2026-05-12)
- Reviewed commit: 88dd7fb69baa74db24bc84173280bbd127414584
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong practical reference for local-first compression of Claude Code tool output. Best patterns are automatic PostToolUse interception, TOON conversion for structured data, conservative debug-output reduction, savings thresholds, local stats, and cache controls. Main adoption risks are lossy replacement of exact tool output, duplicated hook/core implementations, heuristic source-code compression, weak prompt-injection/secret controls, and no retrieval path back to the original uncompressed payload.

## Why It Matters

Toonify MCP targets a common coding-agent context leak: large tool outputs get copied into the transcript even when the agent only needs the shape, a few diagnostics, or a compact table. It is directly relevant to Agentic Coding Lab because it operates at the tool-output boundary rather than asking every agent prompt to remember "be concise."

The repo is useful because it handles several high-volume coding-agent payloads: JSON/API responses, CSV/YAML, test failures, stack traces, compiler diagnostics, lint output, and source files. It also provides two integration modes: an automatic Claude Code PostToolUse hook and an explicit MCP server with an `optimize_content` tool.

The caution is fidelity. The plugin path suppresses the original tool output and injects optimized additional context. That is efficient, but it means exact formatting, comments, full stack frames, source context, and raw secrets may be lost or transformed before the model sees them. This is acceptable for "overview" workflows, but risky when the next action depends on exact bytes, line excerpts, legal text, generated code, or incident logs.

## What It Is

Toonify MCP is a TypeScript package and Claude Code plugin/MCP server. The package entrypoint starts either setup/status/doctor commands or a stdio MCP server. The plugin mode installs a local Claude marketplace entry and registers `hooks/post-tool-use.mjs` for `Read|Grep|Glob|WebFetch` outputs.

Core capabilities:

- Structured data compression through `@toon-format/toon`.
- Detection for JSON, YAML, CSV, TypeScript/JavaScript, Python, Go, PHP, generic code, and debug-heavy output.
- Heuristic source compression that removes comments, merges blank lines, shortens deep imports, and optionally summarizes import/repetition blocks.
- Debug-output compression that removes source excerpt noise, pointer-only lines, duplicate diagnostics, repeated stack frames, and repeated TypeScript/lint diagnostics.
- Result cache with LRU eviction, TTL, SHA-256 cache keys, and optional disk persistence.
- Prompt-cache formatting helpers for Anthropic/OpenAI-style message structures.
- Local metrics in `~/.claude/token_stats.json`.
- CLI setup, status, and doctor commands.

## Research Themes

- Token efficiency: High. It compresses at the boundary where large tool responses enter context, uses measured token counts in the TypeScript core, enforces a default 30% savings threshold for core optimization, and skips short/small payloads in hook mode. Benchmark docs report a 48.1% average structured-data snapshot, but benchmark fixtures are synthetic and not a coding-agent task eval.
- Context control: Medium. It can prevent bulky output from entering context, but it does not keep a reversible artifact pointer to the original payload or expose range/selector retrieval tools. Compression is inline replacement, not externalized context management.
- Sub-agent / multi-agent: Low. No subagent architecture. Multiple Claude sessions can use the same local hook and stats path, but there is no session ownership, locking, or handoff protocol.
- Domain-specific workflow: Strong for Claude Code. The hook matcher, setup/doctor/status CLI, debug-output fixtures, and source-code handling are coding-agent specific rather than generic prompt compression.
- Error prevention: Mixed. The code has many regression tests for parser edge cases, PHP syntax, debug output, cache behavior, CLI behavior, and server response shape. Risk remains because compression can remove comments/source excerpts that are sometimes the evidence needed to fix a bug.
- Self-learning / memory: Low. Metrics and cache persist local counters/results, but there is no learning loop, retrieval ranking, summary memory, or cross-session knowledge model.
- Popular skills: No skill pack. Reusable artifacts are the hook boundary, conservative compressor layers, savings gates, local stats, and install health checks.

## Core Execution Path

Plugin path:

1. `toonify-mcp setup` validates Claude CLI availability, adds `.claude-plugin/marketplace.json` as a local marketplace, and installs/updates/enables `toonify-mcp@pcircle-ai`.
2. Claude Code loads `hooks/hooks.json`, which registers `node ${CLAUDE_PLUGIN_ROOT}/hooks/post-tool-use.mjs` for `PostToolUse` events matching `Read|Grep|Glob|WebFetch`.
3. The hook reads JSON from stdin and extracts `tool_name` plus `tool_response`.
4. It passes through empty responses, non-string responses, responses shorter than 50 characters, disabled config, skipped tool patterns, and responses below `TOONIFY_MIN_TOKENS` or config threshold.
5. It tries structured detection in order: JSON, YAML, CSV. Structured content is converted to TOON and emitted with `[TOON-JSON]`, `[TOON-YAML]`, or `[TOON-CSV]` if character savings clear the configured threshold.
6. If structured detection fails, it detects debug-heavy output and applies conservative log/trace compression. Debug output uses a lower 10% savings threshold.
7. If not debug output, it detects code and applies source compression. Code also uses a 10% savings threshold.
8. On success, the hook writes `{ continue: true, suppressOutput: true, hookSpecificOutput: { hookEventName: "PostToolUse", additionalContext: output } }`.
9. On errors, it logs to stderr and writes `{ continue: true }`, so workflow continues without optimization.

MCP path:

1. Running `toonify-mcp` without CLI subcommands constructs `ToonifyMCPServer` and connects via stdio.
2. `ListTools` exposes `optimize_content`, `get_stats`, `clear_cache`, `get_cache_stats`, and `cleanup_expired_cache`.
3. `optimize_content` validates non-empty string input, then calls `TokenOptimizer.optimize(content, { toolName, size })`.
4. `TokenOptimizer` rejects non-strings, rejects content over 10 MB, checks the result cache, skips disabled or configured tool patterns, then runs `Pipeline`.
5. `Pipeline` detects content type, routes to `ToonCompressor`, `CodeCompressor`, or `DebugOutputCompressor`, then asks `Evaluator` whether token savings exceed the threshold.
6. Structured outputs can be wrapped with cache-friendly TOON instructions through `CacheOptimizer`; code/debug outputs are returned as compressed text.
7. The server records metrics and returns a JSON text response containing success, result data, and message.

## Architecture

The architecture has three layers.

The integration layer is CLI plus Claude/MCP boundary code:

- `src/index.ts` selects setup, doctor, status, or MCP server mode.
- `src/cli/setup.ts`, `doctor.ts`, `status.ts`, and `claude-cli.ts` configure and inspect Claude Code plugin/MCP registration.
- `.claude-plugin/marketplace.json` and `.claude-plugin/plugin.json` define local plugin metadata.
- `hooks/hooks.json` registers the automatic Claude Code hook.
- `src/server/mcp-server.ts` exposes explicit MCP tools.

The optimization layer is split between a TypeScript core and a standalone JavaScript hook:

- `TokenOptimizer` owns config defaults, 10 MB input limit, tiktoken-based counting, result cache, skip patterns, and prompt-cache wrapping.
- `Pipeline` is detect -> route -> compress -> evaluate.
- `Detector` parses/detects JSON, YAML, CSV, code languages, and debug-heavy output.
- `ToonCompressor`, `CodeCompressor`, and `DebugOutputCompressor` implement format-specific compression.
- `hooks/post-tool-use.mjs` reimplements detection/compression in standalone JavaScript rather than importing the compiled TypeScript core.

The support layer covers cache, metrics, and tokenization:

- `LRUCache` provides in-memory TTL/LRU result caching with SHA-256 keys and optional persistent storage.
- `PersistentCache` allows disk cache only under `~/.toonify-mcp`, `~/.claude`, or OS temp.
- `CacheOptimizer` formats large TOON payloads with static prompt-cache instructions, but MCP responses do not directly emit provider-native cache blocks.
- `MetricsCollector` writes aggregate counters to `~/.claude/token_stats.json`.
- `MultilingualTokenizer` wraps tiktoken and language detection, though the main evaluator uses raw `countBase()` token counts.

## Design Choices

The strongest design choice is boundary compression. Instead of relying on the agent to summarize after the fact, Toonify acts before large outputs enter the context window.

Structured data uses TOON rather than free-form summaries. This keeps field names and rows machine-readable and is safer than asking an LLM to summarize JSON. It is still a representation change, so consumers must understand TOON and edge cases from the upstream package.

The pipeline evaluates compression by token savings, not only bytes. The hook path uses character savings for speed and standalone operation. That makes plugin and MCP behavior similar but not identical.

Default thresholds are conservative for structured data and looser for code/debug output. Core default `minSavingsThreshold` is 30%; hook mode uses configured 30% for structured data and 10% for debug/code because those formats often save less while still reducing noise.

The code compressor avoids deleting logic by targeting comments, blank lines, import paths, import blocks, and repetitive line structures. It preserves common task-marker comments, JSDoc first lines, Python docstring first lines, PHP attributes, PHP heredoc/nowdoc bodies, URLs, and PHP backtick command strings.

The debug compressor preserves headlines and actionable diagnostics while removing noisy excerpts. It keeps first/last stack frames for long traces and inserts `[toonify]` markers for omitted repeats. This is a useful transparency pattern: the model sees that content was compressed, not silently deleted.

Caching has two meanings. Result caching avoids recompressing identical content plus tool metadata. Prompt-cache structuring creates a static TOON instruction prefix, but it is mostly a helper surface and metrics model, not an end-to-end provider cache integration inside Claude Code.

Privacy posture is local-first. The tool does not run a hosted service, and metrics/cache live locally. That does not prevent optimized output from being sent by Claude Code or an MCP client to a model provider.

## Strengths

Automatic plugin integration hits the highest-leverage point: Claude Code tool output. Users do not need to remember a separate compression command.

The MCP server is narrow and understandable. `optimize_content` plus stats/cache tools make behavior testable without installing the plugin path.

TOON conversion for structured data is a good fit for repeated rows and API payloads. It keeps schema-like information visible while reducing punctuation and repeated keys.

Debug-output compression is practical for coding agents. Removing pointer lines, repeated diagnostics, repeated stack frames, and unhighlighted source excerpts cuts noise while retaining filenames, error messages, and terminal summaries.

The repo has better-than-average regression coverage for a small agent-support tool. Tests cover MCP handler behavior, optimizer thresholds, parser edge cases, pipeline routing, code compression, debug output fixtures, hook subprocess behavior, cache mechanics, metrics, and CLI setup/doctor/status.

Security controls are present, though incomplete. The core rejects content over 10 MB, validates result-cache config, limits persistent cache paths, skips `Bash`, `Write`, and `Edit` in hook defaults, and fails open rather than breaking user workflows.

Install ergonomics are unusually complete for a research candidate: setup repairs marketplace/plugin state, doctor checks core optimizer boot, Claude CLI, marketplace, plugin, config, assets, and stats path, and status reports last optimization/skipped reason.

## Weaknesses

The automatic hook suppresses original output without creating a stable reference to the exact raw payload. If compression removed a needed line, the agent has no built-in `read_original` or artifact ID to recover it.

Hook mode and core mode duplicate detection/compression logic. The changelog and tests show active effort to keep them aligned, but duplication raises maintenance risk. A future fix in TypeScript can miss `post-tool-use.mjs`, which is the default automatic path.

Source-code compression is inherently lossy. Comments, docstring bodies, source excerpts, and import details can contain requirements, generated-code warnings, licensing notices, task constraints, or debugging clues. The repo says exact formatting should be skipped, but detection is heuristic and the hook has no per-file opt-out metadata.

There is no secret redaction layer. Large API JSON, config YAML, logs, or source files can contain secrets. Toonify may reduce tokens but still passes sensitive optimized content into model context and may persist it in caches/stats if configured.

Prompt-injection risk is not addressed. WebFetch or Read output can contain malicious instructions; Toonify wraps structured output with TOON labels, but it does not classify untrusted text or isolate it from agent instructions.

The core `minTokensThreshold` config is defined but not enforced in `TokenOptimizer.optimize()`. The hook enforces estimated minimum tokens, but the MCP/core path relies on detection plus savings evaluation.

Prompt-cache metrics are aspirational. `CacheOptimizer` exposes hit/miss methods, but the main optimizer does not appear to call `recordCacheHit()` or `recordCacheMiss()` for actual provider reuse. Reported `withCaching` savings are an estimate derived from token savings, not verified provider billing data.

Metrics writes are local and atomic per write, but concurrent processes can still race through read-modify-write on the same `~/.claude/token_stats.json` file. For a plugin used by multiple sessions, counters can lose updates.

Some compression markers use language-specific comment syntax even for other languages. For example import summaries use `// ...` in the generic compressor path for Python/Go-style content. That is fine for context, but output should not be treated as runnable source.

## Ideas To Steal

Put token control at the PostToolUse boundary. This is more reliable than only teaching agents to truncate output manually.

Use a two-threshold policy: strict savings thresholds for structured payload rewrites, lower thresholds for debug/log cleanup where even modest reductions improve attention.

Preserve visible omission markers such as `[toonify] repeated N more times`. Silent deletion makes downstream debugging much harder.

Keep compressor layers explicit and ordered from low-risk to higher-risk. Merge blank lines before dropping comments; drop pointer-only lines before collapsing stack frames; evaluate final token savings after all layers.

Pair every compression decision with metadata: tool name, detected format, original tokens, optimized tokens, savings percentage, reason skipped, and timestamp. Toonify's status/metrics path is a good starting shape.

Use a local doctor command for agent-support tools. It catches broken CLI/plugin/config/assets before the agent relies on the tool during a task.

Add parser-edge regression fixtures for real failure modes. The PHP attribute/heredoc/backtick tests and repeated TypeScript diagnostic tests are exactly the kind of small fixtures an Agentic Coding Lab compressor needs.

Limit parser DoS surface with hard input-size caps and fast pass-through behavior. The 10 MB core limit and hook fail-open behavior are good operational defaults.

## Do Not Copy

Do not replace exact tool output without a reversible raw artifact reference. A safer design would emit compressed context plus `raw_ref`, byte length, hash, and a range-limited retrieval tool.

Do not maintain two independent compressor implementations. Prefer one shared library used by hook, MCP, CLI tests, and benchmarks.

Do not compress source files by default when exact comments/docstrings may carry requirements. Require allowlists, per-tool policy, or a "summary view vs exact view" distinction.

Do not treat local-first as sufficient privacy protection. Add secret scanning/redaction policies before optimized output enters model context or persistent cache.

Do not claim provider cache savings without observing provider cache hits/billing metadata. Keep prompt-cache estimates separate from measured token reductions.

Do not use character savings as the only acceptance metric when tokenization is available. It can misestimate CJK, minified JSON, code, and punctuation-heavy logs.

Do not suppress `Bash` output forever. Skipping Bash by default is safe, but coding agents often need long test output compressed. A better policy is to skip shell commands that mutate state and allow selected read-only verification/test outputs with raw recovery.

## Fit For Agentic Coding Lab

Fit is high as a concrete token-efficiency implementation reference. It is more directly applicable than many general prompt compressors because it is built around Claude Code, MCP, tool boundaries, logs, traces, and source files.

Best local adaptation would be a "tool output compressor with reversible artifacts":

- Hook into command/tool output before transcript insertion.
- Detect structured data, logs/traces, and source files.
- Produce compact context only when token savings exceed policy thresholds.
- Store exact raw output under a scoped artifact ID with hash and retention controls.
- Expose range reads, regex search, JSONPath/key listing, and raw restore tools.
- Record skip/optimize metrics locally per session.
- Run regression fixtures for parsers and debug-output compressors.

Adopt the pipeline idea and conservative debug compression. Rebuild the automatic path around one shared implementation, stronger privacy controls, and explicit raw-output recovery.

## Reviewed Paths

- `README.md`: public positioning, install workflow, plugin/MCP mode, limitations, and docs links.
- `package.json`, `package-lock.json`, `tsconfig.json`, `jest.config.js`: package entrypoint, scripts, dependencies, Node version, and test/build setup.
- `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`: plugin metadata and local marketplace structure.
- `hooks/hooks.json`, `hooks/post-tool-use.mjs`: actual automatic Claude Code PostToolUse path, tool matcher, config loading, structured/debug/code detection, compression, thresholds, passthrough/fail-open behavior, and output suppression.
- `src/index.ts`: CLI dispatch and default MCP server startup.
- `src/server/mcp-server.ts`: MCP tool list, input validation, optimizer invocation, stats recording, cache tools, response format, and shutdown cleanup.
- `src/optimizer/token-optimizer.ts`, `types.ts`: config defaults, 10 MB limit, cache keying, skip patterns, pipeline invocation, savings handling, cache wrapping, and public API.
- `src/optimizer/pipeline/*`: detect -> route -> compress -> evaluate pipeline, content-type definitions, savings evaluation, and parser/detector heuristics.
- `src/optimizer/compressors/*`: TOON conversion, source-code compression layers, debug-output compression layers, metadata output, and supported content types.
- `src/optimizer/caching/*`: LRU cache, persistent cache path restrictions, prompt-cache wrapper, provider strategy thresholds, and cache stats.
- `src/optimizer/multilingual/*`: language detection/tokenizer adapter and raw-token counting behavior relevant to savings evaluation.
- `src/metrics/metrics-collector.ts`: local stats path, aggregate metrics, status/dashboard formatting, and atomic write approach.
- `src/cli/setup.ts`, `doctor.ts`, `status.ts`, `claude-cli.ts`: install repair flow, health checks, status reporting, and Claude CLI command boundaries.
- `docs/CACHE.md`, `docs/benchmarks.html`, `docs/privacy.html`, `docs/llms.txt`, `docs/llms-full.txt`: cache docs, benchmark claims/reproduction pointers, privacy/local-first boundaries, and AI-readable summaries.
- `SECURITY.md`, `CHANGELOG.md`, `SUPPORT.md`, `CONTRIBUTING.md`, `CONTRIBUTORS.md`: security scope, release history, support expectations, contribution process, and recent feature context.
- `tests/**/*.test.ts`, `tests/**/*.ts`, `tests/fixtures/debug-output/*.txt`: MCP/server tests, optimizer tests, hook subprocess tests, parser edge cases, cache tests, CLI tests, metrics tests, debug/code compressor tests, benchmark sources, and representative debug-output fixtures.
- Git/GitHub metadata: reviewed commit, branch, remote URL, tracked file list, clean checkout state, latest commit metadata, and star/fork/open-issue snapshot from GitHub REST API.

## Excluded Paths

- `.git/`: clone metadata only. Used through Git commands for commit, branch, remote, tracked files, and checkout state; not reviewed as source.
- `node_modules/` and `dist/`: absent in the reviewed checkout. No vendored dependency source or generated build output was reviewed.
- Localized README files (`README.de.md`, `README.es.md`, `README.fr.md`, `README.id.md`, `README.ja.md`, `README.ko.md`, `README.pt.md`, `README.ru.md`, `README.vi.md`, `README.zh-TW.md`): excluded after English README, docs, code, and changelog review because they duplicate product/install messaging for localization rather than changing execution path.
- Static website UI assets (`docs/index.html`, `docs/index-zh.html`, `docs/terms.html`, `docs/terms-zh.html`, `docs/privacy-zh.html`, `docs/benchmarks-zh.html`, `docs/assets/tailwind.css`, `docs/tailwind.input.css`, `docs/favicon.svg`, `docs/social-preview/v3-before-after.svg`, `docs/CNAME`, `docs/robots.txt`, `docs/sitemap.xml`): reviewed only where docs claims mattered; excluded as UI/static hosting assets, not compressor logic.
- `.github/RELEASE_TEMPLATE.md`: release-process template only; not relevant to runtime behavior.
- `.github/workflows/ci.yml`: reviewed briefly for build/test expectations, then excluded from deeper analysis because it only runs `npm ci`, build, and tests across Node versions.
- `.gitignore`, `.npmignore`, `LICENSE`: packaging/legal metadata. Not part of execution path beyond noting MIT license and package contents.
