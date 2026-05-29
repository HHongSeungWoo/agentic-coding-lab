# pythondatascrape/engram

- URL: https://github.com/pythondatascrape/engram
- Category: token-efficiency
- Stars snapshot: 17 (GitHub REST API, captured 2026-05-29)
- Reviewed commit: fd96d854e4ef72170a43feeff268b8ab0932636a
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strongly relevant as a local-first coding-agent context-compression prototype, especially for proxy-level window compression, Claude Code hooks, OpenAI-compatible request rewriting, and per-session token accounting. The implementation is much less mature than the headline claims imply: older turns are summarized by truncation, original-token baselines are mostly character estimates, Claude system-prompt identity compression is disabled, SDK `compress` is not fully wired in default `serve`, and the source-available license sharply limits reuse.

## Why It Matters

Engram targets a real cost pattern in AI coding tools: every model call carries repeated system prompt text, identity files, tool results, prior messages, and assistant restatements. Instead of asking users to manually trim context, it inserts a local daemon and HTTP proxy between tools such as Claude Code and upstream model APIs.

The repo matters for Agentic Coding Lab because it is agent-tool specific. It includes Claude Code settings mutation, SessionStart and PostToolUse hooks, an MCP server, a statusline, Unix-socket JSON-RPC, SDKs, and an OpenAI-compatible proxy. That makes it closer to a real coding-agent integration surface than generic prompt-compression papers or standalone summarizers.

Its most useful research value is the split between three compression surfaces: request-history rewriting in the proxy, identity/codebook compression through MCP and SDK calls, and tool-output reduction in the PostToolUse hook. Even where the implementation is naive, the boundaries are worth studying.

## What It Is

Engram is a Go daemon plus CLI, HTTP proxy, MCP plugin, Claude Code hooks, OpenClaw adapter, and thin Go/Python/Node SDKs. The daemon listens on `~/.engram/engram.sock` for newline-delimited JSON-RPC. The proxy listens on HTTP ports, defaulting to Anthropic on `4242` and OpenAI-compatible traffic on `4243`.

The active Anthropic path keeps the `system` prompt verbatim and compresses only conversation `messages`. If there are more than `window_size` messages, it keeps the last window unchanged and collapses the older head into one synthetic user message containing a `[CONTEXT_SUMMARY]` block. A second budget pass targets a hardcoded 24,000-token estimate.

The OpenAI path supports `/v1/chat/completions` and `/v1/responses`. It compresses `system` or `developer` identity messages only when deterministic `CompressIfSafe` rules think the content can safely become key=value pairs. It then applies the same window and budget compression to message history or Responses API `input` items.

The Claude Code plugin adds MCP tools for deriving a codebook, compressing identity, checking redundancy, reading stats, and generating reports. Its SessionStart hook can register a Claude session ID with the proxy and emit a compressed identity block as a message for Claude to use. Its PostToolUse hook locally summarizes large tool outputs or asks the daemon whether an output is redundant.

The repository is source-available, not open source in the normal permissive sense. The root license forbids commercial use and requires consent for using the compression technology, including non-commercial deployment or reproduction. The Claude plugin package still declares Apache-2.0, which conflicts with the root license posture.

## Research Themes

- Token efficiency: Primary theme. Runtime savings come from collapsing older messages, truncating oversized tool outputs, optionally compressing OpenAI identity messages, and reporting saved tokens. README claims include about 40-60% context reduction and 96-98% identity reduction for OpenAI/SDK codebook use, while CLI help still claims 85-93% session savings. The audited implementation supports directional savings but not those claims as general evidence.
- Context control: Strong integration surface, simple algorithm. Anthropic uses `window_size` tail preservation, a synthetic `[CONTEXT_SUMMARY]`, and a 24,000-token budget pass. OpenAI Responses input conversion recognizes typed messages, function calls, reasoning summaries, images, files, and tool outputs. The summary content is extractive/truncated, not semantic task-state compression.
- Sub-agent / multi-agent: No orchestration. Engram could reduce shared transcript cost for multi-agent coding sessions, but it has no worker routing, shared memory protocol, or subagent-specific context policy.
- Domain-specific workflow: Strong for AI coding tools. The Claude Code install path mutates `~/.claude/settings.json`, installs plugin files and hooks, registers a statusline, and routes API traffic through the proxy. OpenClaw support is mostly plugin copy plus a socket adapter.
- Error prevention: Mixed. The proxy fails open on malformed JSON and preserves unknown top-level request fields. Tests cover field preservation, streaming passthrough, unresolved session-header values, stats files, OpenAI Responses input conversion, and tool-output truncation. There are no exactness tests for diffs, patches, shell failures, stack traces, file paths, or tool-call linkage through compressed summaries.
- Self-learning / memory: Minimal. Sessions are in-memory with idle and TTL eviction. Per-session token stats persist to JSON files, and redundancy history stays in memory. There is no durable semantic memory, retrieval index, learned cache, or long-term session compaction artifact.
- Popular skills: The repo ships Claude Code skills for codebook management, codebook generation, settings, and reporting. They are useful as UX patterns, but some tool names and schema examples drift from the actual MCP server and Go parser.

## Core Execution Path

The Claude/Anthropic runtime path is:

1. `engram install --claude-code` copies the Claude plugin, registers a statusline and Stop hook, creates `~/.engram/engram.yaml`, writes `ANTHROPIC_BASE_URL=http://localhost:<port>` into Claude settings, installs a launchd or systemd service, and verifies the socket and proxy port.
2. `engram serve` loads config, starts the Unix-socket daemon, starts the Anthropic HTTP proxy, optionally starts the OpenAI-compatible proxy, writes `~/.engram/proxy.port`, and begins an update check against GitHub.
3. The Claude SessionStart hook reads the real Claude session ID from hook input, posts it to `/internal/register-session`, scans upward for `CLAUDE.md`, and tries to derive and compress identity through daemon MCP-style calls.
4. Claude Code sends `POST /v1/messages` to the local proxy because settings changed `ANTHROPIC_BASE_URL`.
5. The proxy parses the request, extracts system text for estimates and fallback fingerprinting, but leaves the upstream `system` payload unchanged.
6. The proxy estimates original tokens with `len/4` on messages and system text, falling back to raw body size when larger.
7. `Compress` keeps the last `window_size` messages verbatim and summarizes older messages as `role: text`, truncating each old message around 120 characters.
8. If the compressed estimate still exceeds 24,000 tokens, `CompressBudget` walks backward from the tail and summarizes the remaining head with first-sentence and tool-line summaries.
9. The proxy patches only the `messages` field in the original JSON body, preserving fields such as `max_tokens`, `tools`, `temperature`, and `stream`, forwards upstream, and streams the response back to the client.
10. After the response, it extracts exact compressed input tokens from provider usage when available, otherwise estimates, then writes `~/.engram/sessions/<session>.ctx.json` atomically.

The OpenAI runtime path is similar but handles both chat completions and Responses API input. It can rewrite system/developer identity messages with key=value codebook strings when `CompressIfSafe` accepts the content. Responses API inputs are normalized into message envelopes, compressed, then re-marshaled as typed input items with a synthetic summary item plus compacted tail items.

The tool-output path is separate. The Claude PostToolUse hook triggers for tool outputs over 800 characters. It first tries local summarization: JSON objects become key/type sketches, JSON arrays become sample-shape summaries, Todo/Edit/Write outputs become a few lines, and long line-oriented outputs keep head and tail. If local summarization does not shrink the output, it calls `engram.checkRedundancy`. The daemon checker records every checked string and flags exact, normalized, or Jaccard-similar repeats.

## Architecture

- `cmd/engram/`: Cobra CLI for `serve`, `install`, `status`, `statusline`, `analyze`, `advisor`, `update`, and `mcp`.
- `internal/proxy/`: Anthropic and OpenAI HTTP proxy, message compression, budget compression, usage parsing, session ID attribution, and per-session context stats.
- `internal/daemon/`: Unix-socket JSON-RPC server/client, MCP-style method dispatch, global identity-compression stats, redundancy checker, and report generation.
- `internal/identity/codebook/` and `internal/identity/serializer/`: deterministic identity dimension derivation, codebook schema validation, safe key=value compression gates, and serialization.
- `internal/context/`: lightweight context codebooks, compressed turn history, and built-in response codebook definitions.
- `internal/server/`: SDK-facing request orchestration for identity serialization, prompt assembly, provider calls, and in-memory session history.
- `internal/session/`: session ownership, lifecycle state, turn counters, token counters, idle eviction, TTL eviction, and capacity limits.
- `internal/optimizer/`: static project scanner, savings estimator, advisor state, and statusline formatting.
- `plugins/claude-code/`: MCP server, daemon client, SessionStart/PostToolUse/Stop hooks, tests, and user-facing skills.
- `plugins/openclaw/`: OpenClaw gateway adapter and manifest.
- `sdk/go`, `sdk/python`, `sdk/node`: thin pooled Unix-socket clients for daemon methods.
- `demo/` and `bench/identity/`: OpenAI demos and a daemon-dependent identity compression benchmark.

The main architectural split is sound: HTTP proxy traffic handles real coding-tool requests, while the Unix-socket daemon exposes identity, redundancy, stats, and reporting tools. The weaker part is that the SDK-facing `engram.compress` path is not wired to the same production path as the proxy.

## Design Choices

Engram chooses local request rewriting instead of provider-side compression. That gives it control over Claude Code and OpenAI SDK traffic without changing upstream APIs. It also avoids sending context to a third-party compression model.

Anthropic system prompts are fail-open and verbatim. This is an explicit reliability choice after earlier system-prompt rewriting caused compatibility problems. It improves safety for Claude but caps savings when `CLAUDE.md` or system instructions dominate the request.

The context compressor is deterministic and cheap. It does not call an LLM, does not run embeddings, and does not persist compressed semantic summaries. The tradeoff is fidelity: a 120-character old-turn excerpt can lose the exact command, file, patch, or error detail that a coding agent may later need.

The OpenAI path is more aggressive than the Anthropic path. It applies key=value identity compression to `system`, `developer`, or Responses `instructions` text when derivation finds enough structured signal. The `CompressIfSafe` gate accepts two or more explicit dimensions, or dense prose with at least three derived dimensions and a coverage ratio threshold.

Stats are intentionally lightweight. Per-turn context stats use exact provider usage for the compressed request when available, but original tokens are local estimates. Identity-compression stats use caller-supplied `originalTokens` when available. Static analyzer estimates assume fixed rates: 96% identity compression, 80% history compression, and 20% response-metadata compression.

Persistence favors counters over raw content. The proxy writes `.ctx.json` files with totals, not message bodies. The Stop hook writes identity estimate files. The daemon writes global `stats.json`. Session history in the SDK handler is in memory only.

The install path tries to be zero-touch for Claude Code. It copies plugin files, mutates settings, installs a service, starts it, and verifies readiness. OpenClaw is explicitly behind: its install path copies the plugin but does not currently perform the same daemon/service bootstrap.

## Strengths

The proxy boundary is practical. It can reduce real API request size while preserving most provider request fields and streaming behavior.

The Claude Code integration is unusually concrete for a small repo. It includes settings mutation, hooks, statusline correlation, MCP tools, plugin packaging, and tests around alternate hook payload shapes.

The implementation is deterministic and local. There is no compression model latency, no extra provider call, and no additional prompt-content egress for compression itself.

The OpenAI Responses handling is broader than a basic chat wrapper. It understands string input, typed message items, function call outputs, custom tool calls, computer call outputs, reasoning summaries, images, files, and audio markers well enough to produce compact summaries.

Token accounting is visible. The repo splits identity and context counters in `.ctx.json`, exposes daemon stats, renders a statusline, and has report generation. Even with rough estimates, the instrumentation surface is useful.

The redundancy checker has efficient exact and normalized indexes before falling back to pairwise Jaccard checks. That is a sensible shape for catching repeated tool outputs without making every check expensive.

Tests cover many integration edges: malformed proxy input, preserving unknown fields, no Anthropic `count_tokens` preflight, streaming usage extraction, per-session stats, unresolved session headers, OpenAI identity compression, large tool-output truncation, codebook derivation, and Unix-socket daemon basics.

The docs are candid in some places. README notes that Claude/Anthropic identity compression is disabled, and the OpenClaw punch list admits the OpenClaw install path is not zero-touch yet.

## Weaknesses

The core context compressor is shallow. It creates a line-per-message summary and clips old message text. It does not track files changed, unresolved tasks, command outcomes, exact errors, diffs, tool IDs, or decision state.

The strongest token-savings claims are not supported as general runtime evidence. README says 40-60% context reduction and 96-98% identity reduction; root help says 85-93% session savings; demos compare hand-written serialized identity against verbose prose. The actual Claude proxy does not compress system identity, and original-token baselines are mostly `len/4` estimates.

SDK `compress` is not production-ready in the default daemon. `runServe` constructs the SDK handler with a nil identity codebook and a provider pool factory that always returns "no provider factory configured". The advertised Python/Go/Node `compress` example is therefore not the same reliable path as the HTTP proxy and MCP identity tools.

The identity codebook docs drift from the parser. README examples use dimension type `text`, but the identity codebook schema accepts only `enum`, `range`, `scale`, and `boolean`. The context codebook supports arbitrary type hints, but the identity parser does not.

Claude session correlation is improved but still fragile. The SessionStart hook registers a session ID through a local HTTP call. If that fails, the proxy falls back to a system-prompt fingerprint. The handler comment says "first-request-claims" and "clears" the pending session, but the implementation keeps the pending ID persistent, so concurrent or later unrelated requests can inherit stale attribution until overwritten.

The redundancy checker is unbounded and in-memory. Every checked content string is appended to raw and normalized slices. Exact and normalized checks are indexed, but similar checks still scan all normalized entries, and there is no eviction, per-session scope, or size cap.

Tool-output reduction happens in a hook, not inside the upstream request body. When the local summarizer fires, it emits guidance/content for Claude rather than guaranteeing that the original tool output is removed from all future context. This may reduce later restatement behavior, but it is not a complete transcript compactor.

Security and privacy controls are partly present but not consistently wired. The SDK handler can use an injection detector, but `serve` creates it without one. Rate limiting exists in `internal/security` but is not integrated with the proxy. Proxy error logging includes a body preview for non-2xx upstream responses, which can expose sensitive prompt or provider error content in logs.

The "local-first" story has an external network footnote. `engram serve` starts a background GitHub release check by default and writes update availability under `~/.engram`.

Versioning is inconsistent. Changelog documents `0.3.3`; Claude plugin package and install constant are `0.2.1`; the MCP server advertises `0.2.0`; the OpenClaw manifest says `0.2.0`.

The root includes a checked-in `engram-demo` Mach-O executable and generated package metadata. That is not harmful to the algorithm review, but it is noisy for a source repo.

## Ideas To Steal

Use an HTTP proxy boundary for coding-agent context compression. It is the cleanest place to preserve provider request shape, forward streaming responses, and attach token stats without changing every tool call site.

Keep a recent tail verbatim. For coding agents, recent turns, tool calls, and current errors need exact fidelity more than old conversational head content does.

Emit a synthetic, tagged context summary block. `[CONTEXT_SUMMARY]` is simple, inspectable, and easy to test. A better Agentic Coding Lab version should make the summary structured by goal, files, commands, failures, decisions, and open questions.

Split identity, context, and tool-output savings in telemetry. Even rough counters are better than one blended savings number because they show which mechanism is actually working.

Pair request rewriting with hook-level tool-output hygiene. A PostToolUse hook can reduce oversized outputs before they become repeated transcript baggage, while the proxy handles history already inside API calls.

Use fail-open request forwarding for malformed or unsupported provider shapes. A compression layer should not break the user's model call just because parsing failed.

Treat source-aware safety gates as first-class. Engram's `CompressIfSafe` is simple, but the idea is right: only compress identity when structure or dense recognized signal exists.

Persist per-session stats separately from raw content. `.ctx.json` counters with atomic writes are useful for UX and privacy.

## Do Not Copy

Do not copy the 120-character old-turn truncation as a coding-agent memory strategy. It will lose exact details that matter for patches, tests, stack traces, and shell output.

Do not cite the 85-93%, 96-98%, or 40-60% claims without tying them to a specific benchmark path. The repo mixes live proxy estimates, static analyzer assumptions, and demo projections.

Do not leave system-prompt compression claims in a Claude path where system prompts are intentionally forwarded verbatim. The README mostly clarifies this, but other docs and hooks still make the boundary easy to misunderstand.

Do not expose a generic SDK `compress` method until the default daemon has a loaded codebook, provider factory, context schema support, and safe error behavior.

Do not rely on unbounded in-memory redundancy history. Add eviction, per-session namespaces, byte caps, and observability for dropped records.

Do not log upstream response body previews by default in a privacy-sensitive local proxy. Provider errors can include prompt snippets, account details, request IDs, or tool content.

Do not ship conflicting license signals. A root source-available license plus Apache-2.0 plugin metadata makes reuse riskier than necessary.

Do not use identity parser docs that advertise unsupported field types. If `text` is wanted, it should be accepted and tested in the identity schema.

## Fit For Agentic Coding Lab

Fit is high as a research candidate and pattern source, not as a drop-in dependency. Engram is directly about token efficiency for coding tools, and it implements the integration surfaces Agentic Coding Lab cares about: proxy rewriting, hooks, MCP, statusline metrics, local daemon, session IDs, and SDKs.

The best adoption path is to borrow the architecture, not the exact algorithms. A lab implementation should keep Engram's proxy/hook/stats split but replace the old-turn truncation with a coding-aware compactor that preserves exact tool IDs, command failures, file paths, patches, open-task state, and evidence hashes.

The repo is also a useful cautionary example. Token-efficiency systems can become hard to evaluate when identity compression, context compression, tool-output guidance, static estimates, and demo projections all report under one "tokens saved" umbrella. Agentic Coding Lab should require named scenarios, exact baselines, and category-level counters.

License fit is poor for direct reuse. The source-available license allows study but restricts using, deploying, integrating, or reproducing compression technology without written consent. Treat it as design research unless permission is obtained.

## Reviewed Paths

- `README.md`, `CHANGELOG.md`, `LICENSE`, `go.mod`, `Makefile`: positioning, claims, disabled Claude identity compression, config defaults, release history, license terms, Go version, dependencies, and test targets.
- `docs/getting-started.md`, `docs/cli-reference.md`, `docs/integration-guide.md`: user-facing setup, CLI behavior, SDK examples, and integration claims, including some stale repo and MCP wording.
- `context-compression-punch-list.md`, `high-impact-compression-punch-list.md`, `engram-proxy-review.md`, `statusline-context-correlation-review.md`, `zero-touch-install*.md`, `openclaw-zero-touch-punch-list.md`: maintainer-noted gaps, completed fixes, known install and correlation issues, and claimed verification history.
- `cmd/engram/*.go`: CLI root, serve/install/status/statusline/analyze/advisor/mcp/update behavior, service installation, readiness path, statusline rendering, and version drift.
- `internal/proxy/*.go` and proxy tests: Anthropic and OpenAI request rewriting, session registration, token estimation, usage parsing, field preservation, streaming passthrough, context stats, budget compression, OpenAI Responses conversion, and fallback behavior.
- `internal/daemon/*.go` and tests: Unix-socket JSON-RPC framing, health/stats/compress dispatch, identity compression stats, redundancy checks, report generation, global stats persistence, and daemon lifecycle.
- `internal/identity/codebook/*.go`, `internal/identity/serializer/*.go`, and tests: schema validation, deterministic derivation, prose rules, safe compression gates, and key=value serialization.
- `internal/context/*.go` and tests: context codebooks, compressed history, response codebook definitions, prompt codebook reinjection, and history growth across turns.
- `internal/server/*.go` and tests: SDK-facing prompt assembly, session creation and ownership, query/identity size caps, optional injection detector, response cap, and provider-pool dependency.
- `internal/session/*.go`, `internal/optimizer/*.go`, `internal/security/*.go`, `internal/provider/**/*.go`, and tests: in-memory sessions, scanner/estimator/advisor/statusline math, injection and rate-limit utilities, provider interface, pool hashing, and Anthropic provider implementation.
- `plugins/claude-code/server.mjs`, `lib/daemon-client.mjs`, `hooks/*.mjs`, `tests/*.mjs`, `skills/*/SKILL.md`, and `package.json`: MCP tools, hook behavior, daemon client, local tool-output summarization, session registration, Stop hook stats, skill UX, and plugin metadata.
- `plugins/openclaw/adapter.go`, `adapter_test.go`, and `manifest.json`: OpenClaw socket adapter, derive/compress request sequence, and install manifest.
- `sdk/go`, `sdk/python`, `sdk/node`: thin client APIs, connection pooling, JSON-RPC methods, and test coverage.
- `codebooks/*.yaml`, `bench/identity/*`, `demo/*.go`: example codebooks, daemon-dependent identity benchmark, OpenAI demo methodology, and demo-only token calculations.
- Git metadata and GitHub REST API metadata: exact reviewed commit, last commit date/message, default branch metadata, stars, topics, open issues, and detected nonstandard license.

## Excluded Paths

- `.git/`: clone metadata only. Used through Git commands to record the reviewed commit and clean status, not reviewed as source content.
- `plugins/claude-code/server.bundle.mjs`: generated bundle of the Claude plugin. I reviewed the source `server.mjs`, daemon client, hooks, and tests instead.
- `engram-demo`: checked-in Mach-O arm64 executable. Excluded as binary output; source demos were reviewed.
- `go.sum`, `sdk/python/uv.lock`, `plugins/claude-code/package-lock.json`: dependency lockfiles. Checked presence, but implementation review used source and package manifests.
- `sdk/python/src/engram.egg-info/*`: generated Python packaging metadata. Excluded from behavior analysis.
- `install/launchd/*.plist` and `install/systemd/*.service`: static service templates. The generated service logic in `cmd/engram/install.go` was reviewed instead.
- `docs/engram-native-simulation-platform-spec.md`: product/spec material for a broader simulation platform, not the current token-compression runtime.
- `internal/transport/quic/*`, `internal/auth/*`, `internal/events/*`, `internal/errors/*`, `internal/plugin/*`, and `internal/config` tests not directly cited above: skimmed through file map and targeted searches, but not deeply analyzed because they are support infrastructure rather than the core compression path.
- Vendored dependency source: none present in the tracked checkout.
- UI-only paths: none present in the tracked checkout.
