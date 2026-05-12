# jia-gao/leanctx

- URL: https://github.com/jia-gao/leanctx
- Category: token-efficiency
- Stars snapshot: 143 (GitHub REST API, captured 2026-05-12)
- Reviewed commit: 6a27975c51df3de15481a39b5cf280c1a0cc034d
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong token-efficiency implementation reference for coding-agent prompt compression. Best ideas are the drop-in SDK wrapper, local extractive compression, conservative verbatim routing for tool/code/error content, versioned benchmark records, and structural-integrity tests. Do not copy the safety claims or cost telemetry uncritically: fidelity depends on heuristic classification, SelfLLM can destroy structure if routed onto tool-bearing messages, TypeScript is passthrough-only, and actual provider cost calculation is not implemented in the compressor.

## Why It Matters

leanctx targets the part of token cost that prompt caching does not solve: dynamic per-request context such as chat history, retrieved documents, tool outputs, logs, and coding-agent transcripts. That is directly relevant to Agentic Coding Lab because coding agents spend much of their context budget on file reads, grep results, command logs, traces, and repeated conversational scaffolding.

The repo matters because it is not just a prompt policy. It implements a compression layer at the SDK boundary, before the request reaches Anthropic, OpenAI, or Gemini. That gives it a clean place to measure input/output tokens, decide whether compression is worth the latency, preserve provider API shape, and attach telemetry back onto the provider response.

Its most useful coding-agent pattern is "compress only what can safely move." Code, tracebacks, tool invocations, and tool linkage are treated as structural content; prose and repetitive logs become compression targets. That is a better baseline than naive truncation or whole-transcript summarization.

## What It Is

leanctx is a Python SDK, versioned as `0.3.1` in the reviewed checkout, that wraps official Anthropic, OpenAI, and Gemini clients with a configurable prompt-compression middleware. Users import `leanctx.Anthropic`, `leanctx.OpenAI`, or `leanctx.Gemini` instead of the provider client and pass `leanctx_config` to enable compression.

The Python SDK ships three compressor concepts:

- `Verbatim`: no-op compressor used for code, errors, unknown shapes, or safe fallback.
- `Lingua`: local extractive compression through LLMLingua-2, loaded lazily from the optional `[lingua]` extra and HuggingFace cache.
- `SelfLLM`: abstractive compression by calling a configured cheap provider model such as `claude-haiku-4-5`, `gpt-4o-mini`, or `gemini-2.5-flash`.

The repo also includes a `leanctx bench` CLI with versioned JSON output, OpenTelemetry instrumentation, LangChain conversion helpers, integration scripts that now delegate to bench scenarios, a TypeScript package, and benchmark docs. The TypeScript package is explicitly a `v0.0.0` passthrough skeleton, not a real compression port.

## Research Themes

- Token efficiency: Primary theme. The SDK saves tokens by compressing dynamic input before provider calls, with thresholds to avoid small-prompt overhead. Docs report 57% token removal on a 15-item LongBench v2 short-subset Lingua run, 35.6% token reduction on a larger coding-agent transcript, and 50% token reduction on the smaller bundled agent bench fixture. Evidence is promising but still small-sample.
- Context control: Strong architectural emphasis. The middleware gates by `mode` and `threshold_tokens`, extracts text from provider message shapes, classifies content, routes by type, preserves structural blocks, and records `leanctx.method` values such as `below-threshold`, `verbatim`, `hybrid`, and `opaque-bailout`.
- Sub-agent / multi-agent: No subagent orchestration. Applicability is indirect: it can compress the transcripts produced by multi-agent or tool-using systems, and the agent fixture is close to a coding-agent workflow.
- Domain-specific workflow: Strong for LLM application SDKs and moderate for coding agents. There are provider wrappers, LangChain helpers, and agent transcript fixtures. It does not implement Codex/Claude Code-specific history adapters, OpenAI Responses API interception, or a sidecar/proxy yet.
- Error prevention: Stronger than most compression repos because it tests structural invariants: tool linkage, tool input preservation, code verbatim, error verbatim, and log compression. Still heuristic; no parser proves that every code or diff payload is safe.
- Self-learning / memory: Minimal. Dedup and old-error purging are stateless or local message-list filters, not durable memory.
- Popular skills: No skill registry. Reusable patterns are the middleware pipeline, block-aware compressor, bench invariant design, and observability taxonomy.

## Core Execution Path

The main Python execution path is:

1. Application constructs `leanctx.Anthropic`, `leanctx.OpenAI`, or `leanctx.Gemini` with `leanctx_config`.
2. Wrapper creates the real upstream provider client and a provider-agnostic `Middleware`.
3. A wrapped request enters `compression_span` when observability is enabled.
4. Middleware exits early when `mode` is off, input is empty, or token count is below `trigger.threshold_tokens`.
5. Active middleware applies deterministic strategies: `DedupStrategy` drops duplicate non-tool-linked messages within the current request, and `PurgeErrorsStrategy` replaces old error messages with a placeholder.
6. Middleware classifies each remaining message as `error`, `code`, `prose`, or `unknown` using text extraction plus heuristic markers.
7. `Router` maps the content type to a compressor from config, defaulting safely to `Verbatim`.
8. Compressor returns compressed messages plus `CompressionStats`; middleware aggregates tokens, ratio, method, and cost.
9. Wrapper sends compressed messages to the upstream provider, then attaches `usage.leanctx_tokens_saved`, `usage.leanctx_ratio`, `usage.leanctx_method`, and `usage.leanctx_cost_usd` where the provider response has usage metadata.

Gemini has an adapter path that converts text-only `contents` to the common message shape and back. Non-text Gemini parts such as function calls, function responses, images, or inline data return `opaque-bailout` and bypass compression.

## Architecture

The runtime architecture is compact:

- `leanctx/client.py`: drop-in wrappers for Anthropic, async Anthropic, OpenAI, async OpenAI, and Gemini. It handles stream span lifetime and provider-specific message paths.
- `leanctx/middleware.py`: compression orchestrator. It parses config, applies strategies, checks thresholds, classifies messages, routes to compressors, and aggregates stats.
- `leanctx/_content.py`: recursive text extractor for string content, text blocks, tool-use input JSON, tool-result output, and document blocks.
- `leanctx/classifier.py`: conservative but heuristic content classifier. Error markers win over code; code is detected by fences or repeated code-like line prefixes; everything else becomes prose.
- `leanctx/router.py`: static content-type to compressor map with `Verbatim` fallback.
- `leanctx/compressors/`: `Verbatim`, `Lingua`, and `SelfLLM` implementations.
- `leanctx/strategies/`: pre-compression filters for per-call dedup and old-error purging.
- `leanctx/bench/`: scenario registry, CLI, workload fixtures, versioned schema, and runners for Lingua, SelfLLM providers, Anthropic E2E, agent structural invariants, and LongBench v2.
- `leanctx/observability/`: API-only OpenTelemetry spans and metrics, with lazy imports and bounded default attributes.
- `leanctx/integrations/langchain.py`: LangChain message conversion and LCEL runnable helper.
- `ts/`: TypeScript public-surface skeleton with passthrough middleware and response telemetry attachment only.

The strongest architecture choice is that the provider wrappers and direct middleware/compressor calls share the same stats and telemetry shape. That keeps measurements available whether users call wrappers, middleware, or compressors directly.

## Design Choices

The safe default is no compression. `mode` defaults to off, the router defaults to `Verbatim`, and unknown content falls through unchanged. This is important because prompt compression has correctness risk.

Lingua is block-aware. It compresses plain string content and text blocks, recurses into `tool_result` blocks, preserves `tool_use` blocks verbatim, and preserves images, thinking blocks, documents, and unknown blocks. It also protects `tool_result` strings containing fenced code or Python tracebacks. This design directly supports coding-agent transcripts where tool IDs and code spans must remain exact.

SelfLLM is intentionally different: it flattens message text, prompts a provider model to summarize, and returns one message with the role of the first input message. This is useful for dense prose but structurally dangerous for agent/tool traffic unless routing prevents it from seeing tool-bearing messages.

The system exposes latency and cost tradeoffs instead of hiding them. Lingua has zero marginal provider cost and keeps data local, but first use downloads about 1.2 GB of model weights and local runs in docs take seconds. SelfLLM adds a provider call with network latency, data egress, and provider cost, but can produce more natural summaries for prose-heavy inputs.

The bench design is good. `BenchRecord` has `schema_version: "1"`, required fields, `--runs`, clean missing-extra/env diagnostics, and scenario registration. The `agent-structural` scenario turns qualitative safety promises into binary invariants that can fail CI.

Observability is API-only by design. leanctx does not configure OTel providers or exporters; it emits spans and metrics only when the application opts in. It also avoids recording raw exception messages as span attributes because those may contain user content or IDs.

## Strengths

The wrapper boundary is practical. Swapping imports lets existing SDK code get compression and telemetry without rewriting call sites.

The block-aware Lingua path is the most valuable implementation idea. It avoids the common failure mode where compression saves tokens by silently corrupting code, traces, tool IDs, or tool inputs.

The repo treats prompt compression as a production subsystem, not a one-off summarizer. It includes thresholds, provider-specific wrappers, streaming span lifetime, usage telemetry, OpenTelemetry spans/metrics, and benchmark records.

The LongBench v2 runner is an unusually strong evaluation hook for a small SDK. It compares no compression, Lingua, and SelfLLM under the same prompt template, truncation cap, and evaluation model, then emits per-question JSONL when configured.

The agent workload benchmark is directly relevant to coding agents. It asserts that `tool_use_id` links survive, code blocks survive byte-identically, errors survive, tool inputs survive, and a verbose log span actually shrinks.

Provider-specific edge cases are handled thoughtfully. OpenAI reasoning models get `reasoning_effort="minimal"` in SelfLLM, and Gemini 2.5+ gets `thinking_budget=0` so hidden reasoning does not consume the visible summary budget.

The docs are candid in places: LongBench v2 results are marked directional, the SelfLLM provider comparison admits subjective quality judgment, and agent-workload docs warn that the result is one transcript.

## Weaknesses

Classification is heuristic and coarse. The classifier emits only `unknown`, `error`, `code`, or `prose`; the enum values `repeat` and `long_important` exist but are not emitted in the reviewed code. README config examples include `long_important`, but no classifier path routes content there.

Routing happens per message, not by structural block. Lingua has internal block protection, but if users route `prose` to `SelfLLM`, an assistant message containing prose plus `tool_use` can be collapsed into a summary and lose tool-call structure.

The missing-dependency behavior is less safe than the README wording implies. With no Lingua route configured, core install is passthrough. But if `routing` selects `lingua` and `llmlingua` is not installed, the first compression call raises `ImportError`; it does not automatically fall back to `Verbatim`.

Cost telemetry is only partially real. Middleware aggregates `cost_usd`, and observability tests use fake compressors to prove aggregation and no double-counting. Actual `SelfLLM` provider calls return `_Completion(cost_usd=0.0)` because no provider pricing table or cost calculation is implemented.

Token accounting is approximate outside OpenAI-style tokenizers. `count_tokens` prefers `tiktoken`, then falls back to `len(text)//4`; message framing overhead and provider-native Anthropic/Gemini counters are not used in middleware triggers.

The strongest public benchmark is small. LongBench v2 evidence is 15 short items, not the full 503-item set, with caveats about rate limits and statistical significance. The agent workload is also one synthetic transcript, though the invariants are well chosen.

The TypeScript SDK is not a compression SDK yet. It mirrors wrapper shape and attaches passthrough telemetry, but real compression is explicitly future work.

OpenAI Responses API, Gemini multimodal/function-call compression, LlamaIndex helpers, TypeScript compression, and full LongBench sweep are roadmap items, not shipped behavior.

## Ideas To Steal

Use a provider-wrapper boundary for prompt compression. It is a natural place to preserve user API shape, enforce thresholds, attach telemetry, and route by provider.

Adopt a `Verbatim` default with explicit routes for risky content. Unknown content should cost tokens rather than risk corruption.

Build a block-aware compressor contract for coding agents: preserve tool IDs, tool inputs, code blocks, tracebacks, and structural metadata, then compress only prose/log payloads.

Create an `agent-structural` style benchmark for our own agent histories. The useful pattern is not the exact fixture; it is the invariant list and fail-fast JSON output.

Keep extractive and abstractive compression separate. Lingua-style extractive compression is better for needle-in-haystack fidelity; SelfLLM-style summarization is better for prose compactness but needs stronger guardrails.

Expose `opaque-bailout` as a first-class method. If compression cannot safely reason about a content shape, observability should show that traffic is bypassing compression.

Use versioned benchmark JSON records. This makes downstream dashboards and regression tracking less brittle than parsing prose benchmark output.

Compose compression with prompt caching. Stable prefix caching and dynamic suffix compression solve different token-cost windows.

## Do Not Copy

Do not copy the marketing claim that SelfLLM cost is surfaced unless actual provider pricing and cost calculation are implemented.

Do not route coding-agent tool traffic through an abstractive summarizer without structural tests. `SelfLLM` returns a single text message and can erase block structure by design.

Do not rely on simple code/error heuristics as a proof of safety. Add parsers, content tags, provider-native tool schemas, or explicit provenance from tool wrappers when possible.

Do not cite the LongBench v2 result as settled evidence. Treat it as a promising directional result until the full 503-item run or a stronger confidence interval exists.

Do not ship a TypeScript-facing claim based on this repo's `ts/` package. It is passthrough-only in the reviewed commit.

Do not silently fall back from missing compression extras in production without telemetry. A failed or absent compressor should produce an explicit method/status so users know whether requests are compressed.

Do not attach unbounded request data, raw exceptions, tenant IDs, paths, or prompts to metrics labels. leanctx avoids some of this, but `extra_attributes` still puts cardinality responsibility on users.

## Fit For Agentic Coding Lab

Fit is high as an implementation reference for a token-efficiency layer around agent transcripts. The most useful local artifact would be a compression harness that tags tool outputs by structural risk, preserves exact tool/code/error spans, and compresses repetitive logs or prose with invariant tests.

The repo is especially relevant for research on "fidelity before savings." It shows that naive truncation can lose answer-bearing middle context, while extractive compression can preserve distributed evidence with fewer tokens. That is directly applicable to long coding sessions where earlier tool outputs may matter later.

For Agentic Coding Lab, the best adoption path is not to depend on leanctx directly. Instead, borrow its contracts: safe default, content-type routing, block-aware compression, explicit bailouts, `leanctx.method`-like taxonomy, and bench records. Our own implementation should add stronger source-aware classification for file contents, diffs, shell logs, JSON, stack traces, and tool schemas.

The repo is less ready as a universal agent layer. It does not intercept all modern provider APIs, TypeScript is not functional for compression, and SelfLLM needs stricter routing before it is safe for coding-agent state. It is strongest for Python LLM apps and as a pattern library for agent-context compaction.

## Reviewed Paths

- `README.md`: positioning, quickstart, architecture diagram, provider support, benchmark claims, caching comparison, roadmap, and caveats.
- `pyproject.toml`: package version, optional extras, supported provider dependencies, bench and longbench extras, script entrypoint, ruff/mypy/pytest settings, and alpha classifier.
- `leanctx/__init__.py`: public API exports and reviewed version.
- `leanctx/client.py`: Anthropic/OpenAI/Gemini wrappers, async/stream paths, Gemini opaque bailout, and response usage telemetry attachment.
- `leanctx/middleware.py`: config parsing, mode/threshold gates, strategy pipeline, classifier/router/compressor execution, and stats aggregation.
- `leanctx/_content.py`, `classifier.py`, `router.py`, `tokens.py`, `stats.py`: text extraction, content taxonomy, routing fallback, token counting, and stats shape.
- `leanctx/compressors/base.py`, `verbatim.py`, `lingua.py`, `selfllm.py`: compressor protocol, no-op path, LLMLingua-2 extractive path, SelfLLM provider dispatch, reasoning/thinking model handling, and structural block behavior.
- `leanctx/strategies/base.py`, `dedup.py`, `purge_errors.py`: deterministic pre-compression filters and their state boundaries.
- `leanctx/_gemini_adapter.py`: Gemini text-only normalization and opaque bailout behavior.
- `leanctx/observability/*.py` and `docs/observability.md`: OTel API-only design, method taxonomy, span/metric attributes, stream lifetime, cost aggregation contract, and privacy/cardinality rules.
- `leanctx/bench/*.py`, `leanctx/bench/runners/*.py`, and `leanctx/bench/workloads.py`: bench CLI, versioned schema, scenario registry, agent/RAG/chat fixtures, Lingua/SelfLLM/E2E/LongBench runners, and invariant checks.
- `leanctx/integrations/langchain.py` and `tests/test_langchain.py`: LangChain message conversion, LCEL runnable helper, and tool metadata round-tripping.
- `tests/test_*.py`, `tests/bench/*.py`, and `tests/observability/*.py`: unit and integration coverage for wrappers, classifiers, compressors, strategies, provider adapters, streaming, benchmark CLI, LongBench runner, and observability.
- `scripts/integration_test_*.py`: legacy integration entrypoints now delegating to bench scenarios.
- `docs/benchmarks/agent-workload.md`, `docs/benchmarks/selfllm-providers.md`, `docs/blog/v0.3-launch.md`, and `docs/blog/data/lbv2-2026-05-03/README.md`: methodology, benchmark results, cost/latency discussion, caveats, and reproduction commands.
- `sample-data/agent-histories/checkout-502.json`: labeled coding-agent transcript fixture with must-preserve and should-compress fields.
- `ts/README.md`, `ts/package.json`, `ts/src/*.ts`: TypeScript skeleton, wrapper surface, passthrough middleware, and telemetry attachment.
- Git metadata and GitHub REST API metadata: exact reviewed commit, last commit message/date, default branch, topics, license, stars, and update time.

## Excluded Paths

- `.git/`: clone metadata only. Used through Git commands to record commit and status, not reviewed as source content.
- `docs/blog/data/lbv2-2026-05-03/{baseline,lingua,selfllm}.jsonl`: generated per-question benchmark output. I reviewed the directory README for schema, setup, aggregate numbers, and caveats; raw JSONL rows were not needed for architecture review.
- `docs/blog/launch-posts.md`: launch/social copy. Excluded as marketing-only after README, benchmark docs, and launch blog already covered the technical claims.
- `docs/plans/draft-otel.md` and most of `docs/plans/plan-otel.md`: historical planning material. I used source, tests, and observability docs as primary evidence; plan text is not runtime behavior.
- `Dockerfile`: packaging/deployment artifact. Excluded because it does not change compression architecture, fidelity, evaluation, or coding-agent applicability.
- `LICENSE`: legal text only. License status was checked through README/GitHub metadata; no implementation evidence lives there.
- Vendored dependencies: none present in the tracked checkout.
- Binary assets: none present in the tracked checkout.
- UI-only paths: none present in the tracked checkout.
