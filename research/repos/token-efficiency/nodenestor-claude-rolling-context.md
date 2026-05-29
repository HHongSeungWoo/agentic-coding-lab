# NodeNestor/claude-rolling-context

- URL: https://github.com/NodeNestor/claude-rolling-context
- Category: token-efficiency
- Stars snapshot: 15 (GitHub REST API, captured 2026-05-29)
- Reviewed commit: c8274de85d5331fd591ed09dd9247de41d86980b
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: in-scope
- Verdict: High-fit reference for Claude Code rolling context compression. The useful pattern is a transparent proxy that keeps recent turns verbatim while replacing old turns with a structured rolling summary on the next request. The implementation is compact and auditable, but it is not yet a production-grade memory layer because compression state is in-memory only, old tool results are truncated before summarization, matching can replace non-matching prefix messages if a stored hash chain appears away from the start, debug surfaces can expose summaries, and the repo has no real test harness.

## Why It Matters

Claude Code-style coding sessions often fail late in a task because old shell output, tool results, diffs, and repeated assistant turns consume the context window. Built-in full-conversation compaction preserves momentum but can lose recent details or repeatedly summarize a previous summary. This repo tests a more targeted control loop: use live API token counts to decide when context is too large, summarize only the older segment, keep a recent suffix verbatim, and inject the summary only after the background compression has completed.

The core idea matters for Agentic Coding Lab because it treats compaction as an always-on transport concern rather than a manual user workflow. The proxy sits between Claude Code and the Anthropic API, so the host agent does not need to change its transcript storage format. Claude Code still writes full JSONL transcripts, while the API request can receive a compacted message array.

The project is also useful as a cautionary example. Transparent compression needs stronger invariants than a README diagram suggests: exact handling of tool-use/tool-result pairs, summary fidelity for long tool results, privacy of compressed content, persistence across restarts, deterministic matching, and verification that current goals and user constraints survive repeated compression cycles.

## What It Is

`claude-rolling-context` is a Python stdlib transparent HTTP proxy plus Claude Code plugin metadata and startup hooks. It listens on localhost, forwards Anthropic API traffic upstream, and intercepts `POST /v1/messages` requests.

When a response reports input usage above `ROLLING_CONTEXT_TRIGGER` (default 100000 tokens), the proxy starts a background thread. That thread calls a summarizer model (default `claude-haiku-4-5-20251001`) with a prompt that asks for a dense chronological coding-assistant summary. The compressor chooses a recent suffix based on `ROLLING_CONTEXT_TARGET` (default 40000 tokens) and stores a two-message prefix: a user message containing `[ROLLING_CONTEXT_SUMMARY]...[/ROLLING_CONTEXT_SUMMARY]`, plus an assistant acknowledgement. On a later request, content hashes identify the old messages that can be replaced with that prefix.

Claude Code integration is done through `.claude-plugin/plugin.json`, `hooks/hooks.json`, and startup scripts for Unix and Windows. The hook updates `~/.claude/settings.json` so `ANTHROPIC_BASE_URL` points at the local proxy, preserves an existing base URL as `ROLLING_CONTEXT_UPSTREAM`, and starts `proxy/server.py` in the background.

## Research Themes

- Token efficiency: Strong direct fit. It compresses old conversation turns, uses real API input token counts when available, keeps a configurable recent suffix, and estimates saved tokens for `/health`.
- Context control: Strong concept, moderate implementation. The boundary policy is recent-suffix preservation plus summary-prefix replacement, but there is no semantic selector, priority tier, exact artifact preservation, or user-visible diff of what was compressed.
- Sub-agent / multi-agent: Conditional. The stateless content-hash design can work across branches and subagents when transcripts share exact content, but there is no explicit session, agent, branch, or workspace identity.
- Domain-specific workflow: Good coding-agent prompt shape. The summarizer prompt explicitly preserves file paths, function names, code changes, errors, user instructions, active goal, timeline, current state, and key details.
- Error prevention: Weak. The proxy contains guardrails for cache-control noise, volatile Claude Code tags, and orphaned tool results, but there are no unit tests, integration tests, fixtures, or CI in the checkout.
- Self-learning / memory: Not a learning system. It is transient session compression. Full transcripts remain in Claude Code JSONL, but compressed summaries are process memory plus logs/debug output, not durable indexed memory.
- Popular skills: No skill pack. Reusable artifacts are the rolling-summary prompt, transparent proxy insertion, content-hash replacement scheme, and health/debug endpoints.

## Core Execution Path

Claude Code sends a normal Anthropic `POST /v1/messages` request to the local proxy because `ANTHROPIC_BASE_URL` was changed to `http://127.0.0.1:5588`.

`ProxyHandler._handle_messages()` reads and parses the request, hashes every message with role plus normalized content, strips `cache_control` and selected volatile Claude Code XML tags for hash stability, and counts characters for fallback sizing.

Before forwarding the request, the proxy promotes any completed background compression from `pending` to active `prefix` plus `original_hashes`. It then scans the incoming message hashes for a stored hash chain. If a match is found, it replaces everything up to the match end with the stored two-message summary prefix, appends the remaining original messages, validates leading orphaned tool results, strips `cache_control` from injected message blocks, and only uses the merged payload if it is smaller by character count.

The proxy forwards the modified or unmodified request upstream. For streaming responses, it buffers all Server-Sent Events while also forwarding chunks to the client. It parses Anthropic `message_start.message.usage` or converter-style `message_delta.usage` to recover input token count. If no token count is found, it estimates tokens as `message_chars // 4`.

If the token count exceeds the trigger and no compression thread is already alive, the proxy starts `_do_background_compression()` on the current message array. The response is not blocked by this thread. The compression result becomes eligible for injection on a later request.

`RollingCompressor.compress()` computes `keep_ratio = target_tokens / real_token_count`, finds a recent-message boundary using character counts, extracts any existing summary from the first message, serializes old messages to text, calls the summarizer model, and returns `[summary_message, ack_message] + recent_messages`.

On repeated cycles, if the current request already begins with a rolling summary, the compressor skips the summary/ack pair when choosing the new material to summarize, passes the old summary to the summarizer prompt as an existing timeline, and asks the model to merge it with newly old conversation turns.

## Architecture

The repo has one runtime subsystem and a small installation layer:

- `proxy/server.py`: local HTTP proxy, upstream forwarding, content hashing, compression store, injection, SSE usage parsing, health/debug endpoints, and threaded request handling.
- `proxy/compressor.py`: summary prompt, recent-boundary selection, message-to-text serialization, summarizer API call, summary marker handling, and token-savings accounting.
- `.claude-plugin/plugin.json`: Claude Code plugin metadata with version `1.7.2`.
- `hooks/hooks.json`: SessionStart hook that tries PowerShell first and falls back to Bash.
- `hooks/start-proxy.sh` and `hooks/start-proxy.ps1`: settings mutation, proxy process lifecycle, version-based restart, PID/version/log files.
- `install.sh` and `install.ps1`: manual install path that writes Claude settings and links or junctions the plugin into `~/.claude/plugins/rolling-context`.
- `uninstall.sh` and `uninstall.ps1`: process cleanup, plugin/cache cleanup, marketplace metadata cleanup, and `ANTHROPIC_BASE_URL` restoration.
- `docker-compose.e2e.yml`: intended end-to-end test service, but it references an ignored/missing `test/Dockerfile.e2e`.

There is no package manager metadata, dependency lockfile, Python test suite, fixture set, CI config, persistent database, or explicit schema file. The implementation deliberately uses Python 3.7+ stdlib only.

## Design Choices

The most important design choice is asynchronous compression. The request that crosses the trigger still goes through with full context; the next eligible request gets the compressed prefix. This avoids adding latency to the triggering response, but it means one additional large request is expected and compression failures are silent to the user unless logs are inspected.

The second important choice is content-based matching instead of session IDs. Each compression records hashes for the summarized message chain. Later requests are scanned for that chain, and the longest-covered match is preferred. This makes restarts and branches conceptually simple, but the active store is still process-local, and matching is only as safe as the chain-placement assumptions.

The compressor preserves recency by ratio, not exact tokens. Real API input tokens decide `keep_ratio`, but `_find_keep_index()` applies that ratio to character counts. It tries to start the retained suffix at a user message without tool results, and otherwise keeps at least the last four messages. This is a pragmatic approximation, not a precise token or tool-boundary budgeter.

Old messages are summarized through a coding-specific prompt rather than dropped or stored as exact artifacts. This makes the compacted prefix portable text, but fidelity depends on the summarizer model and on the repository's own serialization limits: long messages are truncated to the first 3000 and last 1000 characters, tool inputs above 500 characters are truncated, and tool results are capped to 1000 characters per block before the summarizer ever sees them.

The summary is injected as a user message plus assistant acknowledgement. That keeps the message array valid for the Anthropic API and tells the model to continue from summarized context, but it also makes the summary itself part of the conversational instruction stream.

Claude Code integration is intentionally invasive but simple. Installers and hooks mutate `~/.claude/settings.json`, set or chain `ANTHROPIC_BASE_URL`, write logs/PID/version files under `~/.claude`, and start a background localhost server. There is no separate UI or interactive approval step in the scripts.

## Strengths

The core pattern is highly relevant to coding-agent token efficiency. Recent context remains verbatim, so the most error-prone part of a task - current files, commands, failures, and user corrections - is less likely to be lost than with whole-session compaction.

The implementation is small enough to audit. The full runtime path lives in two Python files and uses stdlib `http.server`, `http.client`, JSON, hashes, and threads.

Using real upstream input usage is better than guessing from prompt size alone. For streaming Anthropic responses, the proxy reads usage from SSE events and includes cache creation/read tokens in the trigger calculation.

The summary prompt is coding-task aware. It explicitly asks for active goal, previous goals, chronological timeline, current state, key details, file paths, exact identifiers, errors, code changes, user requests, and user constraints.

The rolling merge model avoids pure summary-of-summary drift in the ideal case. Each new compression prompt receives the previous summary plus the newly old raw messages, then asks for an integrated timeline.

The proxy preserves Claude Code's local JSONL transcript because it only changes the outgoing API payload. That is an important safety valve for later forensic recovery, manual review, or re-running compression.

Proxy chaining is built in. If a user already has an `ANTHROPIC_BASE_URL`, the installer/hook stores it as `ROLLING_CONTEXT_UPSTREAM` and puts rolling context in front of it.

The `/health` and `/debug/compressions` endpoints make the invisible transport behavior inspectable during development.

## Weaknesses

The repo has no checked-in tests. `docker-compose.e2e.yml` points to `test/Dockerfile.e2e`, but `test/` is ignored and absent. I verified Python syntax with `py_compile`, but there is no source-level coverage for hash matching, repeated compression, tool-call boundaries, SSE parsing, Claude Code hook behavior, or proxy chaining.

The compression store is process memory only. A proxy restart discards all active summaries and hash chains. Claude Code still has the full transcript, so this is recoverable, but the user pays another large-context cycle and loses any debug-only compression state.

Old-turn fidelity is lossy before the summarizer runs. `_messages_to_text()` truncates long message text, long tool inputs, and tool results. That means the prompt can ask to preserve every file path and error, but the summarizer may never receive the exact content if it was in a long tool result or command output.

Content-chain matching searches for a stored chain anywhere in the incoming message list, then replaces everything up to the match end. If a valid chain is found after new unmatched prefix messages, those prefix messages can be dropped even though the stored summary does not cover them. In normal Claude Code transcripts the summarized chain probably starts at the beginning, but the invariant is not enforced.

The injection safety check uses character count, not API token count. It avoids using a compression that is larger by characters, but it can still underperform token-wise, especially with structured JSON, code, or multilingual text.

Tool-use safety is partial. `_validate_tool_pairs()` drops leading messages through the last orphaned `tool_result`, which can prevent invalid API payloads. If a boundary bug leaves an orphan right after the summary prefix, that function can also drop the summary prefix itself, losing the compressed history.

Non-streaming response usage parsing appears ineffective in the reviewed code. The response buffer is only appended when `is_streaming` is true, but the non-streaming usage parser checks `elif not is_streaming and buffer`. Non-streaming calls therefore fall through to character-estimated token counts.

The debug endpoint can expose sensitive summarized context. `/debug/compressions` returns full summary content on localhost without authentication. Logs can also include snippets of stored and incoming message content when hash matching misses.

Compression failures are logged but not surfaced to Claude Code. If the summarizer endpoint fails, returns non-200, times out, or cannot fit the compression prompt, the user sees only normal upstream behavior and may not know rolling context stopped helping.

The default summarizer model string is future-dated relative to many public Anthropic examples and is not validated by the repo. If the model name is unavailable in a user's account or proxy, compression fails at runtime.

## Ideas To Steal

Keep recent context verbatim and summarize only old turns. This is the strongest directly reusable pattern for coding agents because recent tool output and user corrections are usually where exactness matters most.

Trigger compression from actual provider-reported input tokens. Character estimates are useful fallback telemetry, but the trigger should use real usage when possible.

Run compression asynchronously and inject on a later turn. This keeps normal response latency predictable while still shrinking future requests.

Represent compressed history as a structured timeline with active goal, previous goals, current state, and key details. This is a better coding-agent memory shape than a generic prose recap.

Merge the previous summary with newly old raw messages on every cycle. A rolling summary should accumulate a coherent task history rather than repeatedly summarize only the already summarized artifact.

Use content normalization for Claude Code-specific volatile blocks and cache metadata. Hashes should ignore transport noise that does not affect user-visible task state.

Expose explicit observability endpoints for compression count, saved-token estimates, active threads, stored entries, and the current summary. In a safer implementation, the debug content should be gated or redacted.

Preserve the canonical full transcript outside the compressed API payload. Compression should be an optimization layer, not the only copy of the work history.

## Do Not Copy

Do not search for a compression key anywhere and then drop all earlier messages unless the summary is known to cover that earlier prefix. Either require prefix-aligned matches or store enough provenance to prove the replacement range is exact.

Do not truncate tool results before summarization without an artifact fallback. Long shell output, diffs, JSON, stack traces, and test logs often contain the one exact clue a coding agent needs later.

Do not expose full compressed summaries through an unauthenticated debug endpoint in a general-purpose agent runtime. Summaries can contain secrets, proprietary paths, user instructions, and security-sensitive command output.

Do not rely on in-memory compression state for durable work. Persist compression metadata, source hash chains, summary hashes, creation time, model, and budget if the runtime should survive restarts.

Do not use character-count reduction as the final injection criterion. Token-aware estimation or an actual count endpoint is needed when compression quality and context budget are the product claim.

Do not hide compression failure from the host agent completely. A robust agent should know whether compaction is active, stale, failed, or skipped because it was not beneficial.

Do not ship without fixtures for Anthropic message shapes, streaming and non-streaming usage, tool-use/tool-result pairs, multiple compression cycles, branch/subagent transcripts, and proxy-chaining paths.

Do not mutate user-level Claude settings or start background proxy processes without clear uninstall, audit, and conflict behavior. This repo has uninstall scripts, but production adoption needs more visible safety controls.

## Fit For Agentic Coding Lab

Fit is high as a pattern source and medium as an implementation base. The project directly targets Agentic Coding Lab's token-efficiency theme and handles the right behavioral surface: old-turn summarization, recent-context preservation, Claude Code integration, proxy transparency, and preserved canonical transcripts.

The best local adaptation would be a safer rolling compactor with explicit invariants: prefix-aligned source ranges, persisted compression records, exact artifact references for large tool outputs, token-aware budget checks, summary quality tests, redaction controls, and a visible status channel. The summary prompt structure is worth reusing, but it should sit beside exact retrieval for files, diffs, command outputs, and tool results.

Direct adoption would need verification work first. The current repo is small and plausible, but the lack of tests means correctness rests on manual reasoning. The biggest risk for a coding lab is not that compression fails to save tokens; it is that it silently drops or distorts an old user constraint, command result, or tool boundary while the agent continues with high confidence.

## Reviewed Paths

- `README.md`: project thesis, `/compact` comparison, compression lifecycle, defaults, proxy chaining, health/debug endpoints, install/uninstall claims, and transcript-preservation claim.
- `.claude-plugin/plugin.json`: plugin name, version `1.7.2`, description, author, and homepage metadata.
- `proxy/server.py`: proxy setup, environment variables, upstream connection, volatile-tag normalization, message hashing, in-memory compression store, match selection, injection, tool-result validation, raw proxying, SSE token parsing, fallback token estimation, background compression trigger, health/debug endpoints, and threaded server.
- `proxy/compressor.py`: summarizer endpoint config, summary markers, coding-agent summarization prompt, character counting, keep-index selection, existing-summary extraction, message serialization and truncation, summarizer API request, summary/ack message construction, and savings accounting.
- `hooks/hooks.json`: Claude Code SessionStart command wiring, PowerShell/Bash fallback, and hook timeout.
- `hooks/start-proxy.sh`: Unix hook behavior, settings rewrite, upstream chaining, default env insertion, PID/version handling, version restart, proxy process start, and log locations.
- `hooks/start-proxy.ps1`: Windows hook behavior, settings rewrite, upstream chaining, default env insertion, PID/version handling, process restart, and log locations.
- `install.sh` and `install.ps1`: manual installer behavior, Python checks, `~/.claude/settings.json` mutation, plugin link/junction registration, and displayed default mismatch.
- `uninstall.sh` and `uninstall.ps1`: proxy shutdown, log cleanup, plugin/cache/marketplace cleanup, installed plugin metadata cleanup, known marketplace cleanup, and `ANTHROPIC_BASE_URL` restoration.
- `docker-compose.e2e.yml`: intended e2e environment, credential mount, and missing/ignored `test/Dockerfile.e2e` reference.
- `.gitignore`: ignored virtualenv, cache, Python bytecode, `.env`, and `test/` paths.
- `LICENSE`: MIT license.
- Git metadata and GitHub REST API metadata: clean clone status, default branch `master`, latest commit, remote URL, stars, forks, open issues, language, license, pushed/updated times, and exact reviewed commit.

## Excluded Paths

- `.git/`: clone metadata only. Used through Git commands to record commit, branch, remote, log, and clean checkout status; not reviewed as source content.
- `__pycache__/`: generated locally by Python syntax verification and ignored by the repo; not source content.
- `test/`: absent in the reviewed checkout and ignored by `.gitignore`; the compose reference was noted as a verification gap.
- Vendored dependencies and package lockfiles: none present. The repo is Python stdlib-only at runtime.
- Build output, binary assets, screenshots, UI-only files, generated docs, and notebooks: none present in tracked files.
- External marketplace repo `NodeNestor/nestor-plugins`, Anthropic API behavior, CodeGate behavior, and Claude Code internals: relevant to deployment, but outside the assigned repository checkout and not audited as source.
