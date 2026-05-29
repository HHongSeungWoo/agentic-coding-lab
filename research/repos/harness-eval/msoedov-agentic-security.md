# msoedov/agentic_security

- URL: https://github.com/msoedov/agentic_security
- Category: harness-eval
- Stars snapshot: 1,887 (GitHub REST API repository search, captured 2026-05-29)
- Reviewed commit: d2bbad32b4c686747cd142d6b1169d846aa73fc3
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: in-scope
- Verdict: Useful but uneven adversarial scanner reference. The best patterns are the raw HTTP target specification, FastAPI plus CLI entrypoints, streaming scan progress, dataset registry, local CSV ingestion, simple mutation modules, multimodal request adapters, failure CSV export, and optional MCP wrapper. The main caveats are that the primary scoring path equates detected refusals with "failures", several safety controls and provider abstractions are not wired into the default scanner, reporting artifacts are shallow, dynamic attack modules call external services or subprocesses, and operational hardening is weak for a server that defaults to binding on all interfaces.

## Why It Matters

Agentic Security is directly relevant to `harness-eval` because it tries to turn adversarial prompts, prompt-injection corpora, multimodal probes, and dynamic attack generators into a repeatable scanner against arbitrary LLM or agent HTTP endpoints.

For Agentic Coding Lab, the important idea is not the specific jailbreak datasets. It is the harness shape: define a target through an HTTP request template, swap in attack prompts, stream per-prompt results, classify target responses, and emit artifacts that can be used in CI. That maps naturally to coding-agent regression suites for repo prompt injection, terminal-output injection, unsafe tool calls, secret leakage, and verifier bypass attempts.

## What It Is

Agentic Security is a Python 3.12 package with a Fire-based CLI and FastAPI server. The CLI exposes `server`, `ci`, `init`, and `ls`; the server exposes verification, scan, stop, mock probe, data-config, report, proxy, static UI, and telemetry routes.

The target integration model is a plain-text HTTP spec. Users provide a request line, headers, and body with substitution tokens such as `<<PROMPT>>`, `<<BASE64_IMAGE>>`, and `<<BASE64_AUDIO>>`. `LLMSpec` parses that spec, validates modality requirements, replaces substitution tokens, strips stale `Content-Length`, and sends the request with `httpx`. The same scanner can target OpenAI-style APIs, arbitrary REST endpoints, the built-in mock probe endpoint, or multimodal endpoints.

The adversarial input side combines static Hugging Face datasets, local CSV files, remote CSVs, steganography transformations, multi-step injection datasets, and dynamic modules for AgenticBackend, Garak, InspectAI, adaptive attacks, and reinforcement-learning prompt selection. Results are streamed as JSON lines and exported to `failures.csv` and `full_scan_log.csv` in the process working directory.

## Research Themes

- Token efficiency: Limited. There is a nominal `maxBudget`, token counting from response word splits, a large budget multiplier, max prompt truncation for display, and optional early stopping, but there is no precise tokenizer, provider-aware cost accounting, or context minimization strategy.
- Context control: Moderate. The HTTP spec, dataset selection, options dictionaries, generated config, and scan parameters make the target and attack context visible. Run isolation is weak because global app state tracks current run, stop event, inbox queue, and secrets.
- Sub-agent / multi-agent: Conditional. The proxy queue, AgenticBackend module, Pydantic-AI operator demo, RL prompt selector, Garak bridge, and InspectAI bridge are agent-adjacent, but most are prototypes or optional dynamic modules rather than a coherent multi-agent runner.
- Domain-specific workflow: Strong for LLM red-team scanning. The repo covers jailbreak datasets, prompt-injection datasets, steganographic prompt mutations, multimodal image/audio probing, refusal classification, PII leak detection helpers, and CI-style thresholds.
- Error prevention: Moderate. It can become a safety regression harness, but current pass/fail semantics, detector calibration, report artifacts, and operational safeguards need tightening before it should gate coding-agent releases.
- Self-learning / memory: Limited. Q-learning and cloud RL prompt selectors exist, but the default scanner does not persist learning across runs or feed results back into a durable memory.
- Popular skills: Not a skill repo. Reusable concepts are HTTP-spec target adapters, dataset registry rows, lazy dynamic prompt modules, scanner state export, refusal classifier plugins, MCP tools, and route-level streaming scans.

## Core Execution Path

The CLI entrypoint is `agentic_security.__main__.main()`. Running the server starts Uvicorn with `agentic_security.app:app`; running CI calls `SecurityScanner().entrypoint()`. `entrypoint()` requires a local config file, loads `general.llmSpec`, `general.maxBudget`, `general.max_th`, `general.optimize`, and `general.enableMultiStepAttack`, marks configured modules as selected, and delegates to `SecurityScanner.scan()`.

`SecurityScanner.scan()` deep-copies selected datasets, applies an optional `only` filter, and runs `async_scan()`. `async_scan()` constructs a `Scan` model and consumes `routes.scan.streaming_response_generator()`, collecting each completed module's `failureRate` into an enhanced console table.

The FastAPI `/scan` route follows the same generator path. It merges configured in-memory secrets into the `Scan`, parses the HTTP spec with `LLMSpec.from_string()`, stores the current spec in global app state for proxy modules, and calls `fuzzer.scan_router()`.

`scan_router()` chooses `perform_single_shot_scan()` unless `enableMultiStepAttack` is true. The single-shot path filters selected datasets, adapts the request factory for image or audio specs, calls `prepare_prompts()`, creates `FuzzerState`, then scans each `ProbeDataset` with `scan_module()`. `scan_module()` iterates prompts, checks the stop event, calls `process_prompt()`, updates module failure rate and token totals, emits `ScanResult` JSON, optionally early-stops on optimizer signals, and stops when the shared budget is exceeded.

`process_prompt()` calls the target via `request_factory.fn(prompt=prompt)`, treats 4xx/5xx and request/JSON errors as failures, parses the response JSON, runs `refusal_heuristic()`, records refusals and outputs in `FuzzerState`, and returns `(tokens, refused)`. At the end of a scan, the state exports `failures.csv` for errors/refusals and `full_scan_log.csv` for errors/refusals/successes.

The multi-step path loads main datasets and `msj_data` probe datasets, randomly injects multi-step prompts into an accumulating `full_prompt`, sends the evolving context to the target, and emits the same `ScanResult` shape. The `probe_frequency` parameter is currently unused in the loop, so injection behavior is driven by the fixed attempt loop rather than the declared probability.

## Architecture

- `agentic_security/__main__.py`: Fire CLI, Uvicorn server launch, CI entrypoint, default config generation, dataset listing.
- `agentic_security/app.py` and `core/app.py`: FastAPI app construction, routers, middleware, global queue, stop event, current run, and secrets store.
- `agentic_security/routes/scan.py`: `/verify`, `/scan`, `/stop`, and `/scan-csv`; bridges API requests into the fuzzer generator.
- `agentic_security/http_spec.py`: raw HTTP spec parser, token substitution, modality detection, `httpx` execution, simple JSON escaping, and verification request.
- `agentic_security/probe_actor/fuzzer.py`: core scan router, single-shot scanner, multi-step scanner, per-module loop, prompt processing, optimizer hook, budget check, and CSV export.
- `agentic_security/probe_actor/state.py`: in-memory errors/refusals/outputs plus CSV artifact writers.
- `agentic_security/probe_actor/refusal.py`: marker classifier, packaged one-class SVM classifier, plugin manager, and separate PII leak helper.
- `agentic_security/refusal_classifier/`: ML refusal classifier, optional LLM judge classifier, hybrid weighted classifier, and regex/Luhn PII detector.
- `agentic_security/probe_data/`: dataset registry, Hugging Face and CSV loaders, Google Sheets normalization, steganography mutations, unified loader, image/audio generators, and dynamic module adapters.
- `agentic_security/probe_data/modules/`: AgenticBackend cloud prompt fetcher, adaptive attack prompt templates, Garak bridge, InspectAI bridge, and RL prompt selectors.
- `agentic_security/attack_rules/`: YAML attack rule model, loader, filters, variable rendering, and dataset conversion. This is tested but not connected to the default scan registry.
- `agentic_security/executor/`: concurrent executor, token-bucket rate limiter, circuit breaker, and metrics. These are tested but not used by the default fuzzer path.
- `agentic_security/routes/report.py` and `report_chart.py`: failure CSV download and plot endpoint. The chart generator currently returns an empty buffer before its plotting logic.
- `agentic_security/mcp/`: FastMCP wrapper exposing verify, start scan, stop scan, data config, and spec templates against the local FastAPI server.
- `tests/`: unit, integration, and system tests for spec parsing, routes, fuzzer behavior, classifiers, dataset loaders, executor utilities, and library-level scans.

## Design Choices

The strongest design choice is target integration through a raw HTTP spec rather than provider-specific SDKs. That makes it easy to point the same scanner at a local agent endpoint, an OpenAI-compatible service, or a bespoke REST wrapper. For coding-agent labs, this is more portable than a fixed provider abstraction because agents often sit behind custom HTTP or CLI harnesses.

The dataset registry is deliberately plain. Each row contains `dataset_name`, size metadata, source, selected flag, dynamic flag, URL, options, and modality. `prepare_prompts()` then maps selected names into base loaders or dynamic loaders. This is easy to inspect and simple to extend, although some registry entries are stale or duplicated.

The scanner streams status and result rows instead of waiting for a final report. That is a good CI and UI pattern: callers can show "Loading datasets", per-module progress, latency, prompt preview, response text, and current failure rate while long scans run.

The project treats dynamic attack generation as just another prompt dataset. Steganography transforms existing prompts; adaptive attacks generate prompt variants from an external harmful-behavior CSV; Garak and InspectAI communicate through the proxy route and tools inbox; AgenticBackend and RL modules call a hosted service. This keeps the fuzzer loop simple but blurs trust boundaries because dynamic modules can perform network calls and subprocess execution.

The multimodal adapters are pragmatic. If the HTTP spec contains an image token, the fuzzer wraps the request factory with an image generator that renders prompt text into a JPEG and injects base64. If the spec contains an audio token, it generates speech and injects base64 audio. This is useful for smoke tests, but it is not a full multimodal adversarial asset pipeline.

The false-positive control model is underdeveloped. The default refusal path ORs together marker phrases and a packaged one-class SVM. A hybrid confidence classifier and LLM judge exist separately, and a PII detector exists as a separate leak signal, but the main scan result only gets a boolean refusal. There is no per-detector evidence, confidence, calibration, or distinction between "target refused", "target leaked", "HTTP error", and "attack succeeded".

The operational-safety utilities are mostly side modules. URL validation, filename sanitization, secret hashing, log redaction, rate limiting, circuit breaking, and concurrent execution all have code and tests, but the default `/scan`, `LLMSpec.probe()`, fuzzer loop, and report export do not consistently use them.

## Strengths

The end-to-end scanner path is easy to follow. CLI or HTTP request, parse target spec, load datasets, run prompts, classify outputs, stream JSON lines, export CSV artifacts.

The raw HTTP spec boundary is a good fit for evaluating heterogeneous agent targets. It avoids hard-coding only OpenAI or Anthropic and lets a lab wrap any target behind a local endpoint.

The project has meaningful adversarial input breadth: jailbreak corpora, prompt-injection datasets, local CSVs, remote CSVs, Google Sheets CSV normalization, stenographic mutations, multi-step prompt injection, image generation, audio generation, Garak, InspectAI, adaptive attack templates, and RL selectors.

The mock probe endpoints make harness testing cheap. `/v1/self-probe` returns OpenAI-shaped responses with a seeded approximate refusal rate in tests; file and image probe endpoints provide local integration targets.

The scan route returns incremental JSON lines and supports a stop event. That is a better user experience than a blocking one-shot process for large datasets.

The state model exports both failures and the full event log as CSV. Even though the schema is simple, it gives a starting point for reproducible scan artifacts.

Tests cover many small contracts: HTTP spec parsing, CSV upload route, probe endpoints, fuzzer status messages, executor rate limiting and circuit breaking, security helpers, attack rule loading, provider adapters, PII detection, and default config generation.

The MCP wrapper is a useful integration idea for agent-facing tooling. It exposes scan operations as callable tools, even though the current implementation needs better streaming handling.

## Weaknesses

The scanner's main metric is ambiguous and likely unsafe as a gate. `refusal_heuristic()` returns true when the target appears to refuse, `scan_module()` counts that as a failure, and `SecurityScanner.show_enhanced_table()` marks a module as passing when `failureRate <= max_th * 100`. For harmful prompt datasets, refusal is usually the safe behavior, so this naming and threshold logic can invert the security conclusion unless users reinterpret "failure" as "attack failed".

Result semantics collapse different events. HTTP 422, HTTP 500, request errors, JSON parse errors, and detected refusals all contribute to the same failure count. Successful harmful compliance is recorded as "success" in the full log. That is not enough for reliable false-positive or false-negative analysis.

Important safety and reliability controls are not in the hot path. `ConcurrentExecutor`, token-bucket rate limiting, circuit breaker, `SecurityValidator.validate_url()`, `sanitize_log_output()`, `RateLimiter`, and the hybrid refusal classifier have tests, but the default scanner largely bypasses them.

Target URL validation is permissive. `parse_http_spec()` only checks scheme and netloc, while a stronger SSRF-oriented validator exists elsewhere. The default examples and test specs use `0.0.0.0`, and the server binds to `0.0.0.0` with wildcard CORS.

Telemetry is enabled by default unless `DISABLE_TELEMETRY` is set, initializes Sentry with `send_default_pii=True`, and samples traces at 100 percent. That is risky for a security scanner that handles prompts, responses, endpoint URLs, headers, and potential secrets.

Dynamic modules have sharp operational edges. AgenticBackend and RL modules default to a hosted `mcp.metaheuristic.co` service and include a default token-like value in source. Garak writes a config file and launches a subprocess. InspectAI uses `asyncio.create_subprocess_shell()` with a formatted command string. These should be opt-in and sandboxed for coding-agent evals.

Report artifacts are incomplete. `/failures` only serves `failures.csv` from the current working directory, `full_scan_log.csv` has no route, and `plot_security_report()` returns an empty buffer before its plotting code. There is no JSONL report with run config, target metadata, dataset snapshot, detector evidence, or per-sample verdicts.

The config documentation and code disagree. Docs and README describe `agesec.toml`, while `SettingsMixin.default_path` is `agentic_security.toml`. That makes CI setup brittle.

The MCP `start_scan` tool posts to a streaming endpoint and calls `response.json()`, which does not match the newline-delimited scan stream. The included MCP client test also expects prompts/resources/tools from a client flow that comments it does not work.

Several integrations are proof-of-concept level. The OpenAI/Anthropic provider abstraction is tested but not used by the scan path. YAML attack rules are converted into datasets but not exposed in the registry. `scan-csv` reads uploaded CSV content but does not pass that content to the fuzzer and hardcodes `maxBudget=1000`.

## Ideas To Steal

Use raw HTTP request templates for target adapters. A coding-agent lab can wrap CLI agents, local web servers, and model gateways behind one token-based request format.

Stream scan status and sample results as JSON lines. Long adversarial runs need progress, per-sample timing, and partial results before the final verdict.

Keep local mock targets. A deterministic self-probe endpoint lets the harness, UI, and CI verify wiring without model costs or external credentials.

Model adversarial inputs as datasets plus dynamic dataset modules. Static corpora, local CSVs, generated mutations, and external tools can share the same prompt iterator interface.

Export both a failure-focused artifact and a full event log. For Agentic Coding Lab, upgrade this to JSONL with run metadata, target metadata, dataset provenance, exact prompt, response, detector evidence, tool trace references, and verdict.

Add mutation modules for obfuscation and modality changes. The stenography and image/audio adapters are simple but useful seeds for prompt-injection variants in README files, terminal output, screenshots, and audio transcripts.

Expose harness operations through MCP tools after fixing stream handling. Agent-facing security checks should be callable as tools with explicit budgets and target scopes.

Keep a rule-loader path for local YAML attack cases. The attack rule schema can become a lightweight way to define coding-agent regression cases with pass/fail conditions and severity.

## Do Not Copy

Do not use refusal-only detection as the release gate. Coding-agent evals need explicit categories for refusal, unsafe compliance, secret leak, tool misuse, verifier bypass, target error, and harness error.

Do not let a pass threshold reward low refusal rates on harmful datasets. Define attack-success and defense-success metrics separately, then name thresholds after the thing they gate.

Do not run scanner servers open to the LAN with wildcard CORS, unauthenticated scan routes, and arbitrary target URLs unless the process is isolated and intentionally exposed.

Do not enable PII-sending telemetry by default in a security harness. Default to local-only logging and make external telemetry an explicit opt-in.

Do not call hosted prompt-generation services or external red-team tools from default CI. Dynamic attack modules should require explicit configuration, pinned versions, credentials, and network policy.

Do not execute bridge tools with shell strings when an argument-list subprocess API works. InspectAI-style bridges need stricter command construction and sandbox boundaries.

Do not rely on current-working-directory CSVs as the primary report store. Artifacts should go under a run-specific output directory with stable filenames and a manifest.

Do not keep safety helpers as unused side code. If URL validation, rate limiting, circuit breaking, and log redaction exist, wire them into the path that actually sends target requests and writes reports.

## Fit For Agentic Coding Lab

Fit is in-scope for `harness-eval`, with a "borrow patterns, not policy" recommendation. The repo is a useful reference for scanner ergonomics and target integration, but not a strong enough evaluator design to copy wholesale.

The best Agentic Coding Lab artifact would combine this repo's HTTP-spec target adapter and streaming runner with a stricter garak-like attempt record, deterministic coding-agent detectors, sandboxed target execution, tool-call capture, secret canaries, run-scoped reports, and clear attack-success metrics.

The repo is especially useful for early prototypes where the lab needs to test many target endpoints quickly. It is less suitable as a production gate until scoring semantics, artifact design, telemetry defaults, URL validation, dynamic module isolation, and detector evidence are redesigned.

## Reviewed Paths

- `/tmp/myagents-research/msoedov-agentic_security/Readme.md`
- `/tmp/myagents-research/msoedov-agentic_security/pyproject.toml`
- `/tmp/myagents-research/msoedov-agentic_security/Dockerfile`
- `/tmp/myagents-research/msoedov-agentic_security/SECURITY.md`
- `/tmp/myagents-research/msoedov-agentic_security/docs/design.md`
- `/tmp/myagents-research/msoedov-agentic_security/docs/getting_started.md`
- `/tmp/myagents-research/msoedov-agentic_security/docs/quickstart.md`
- `/tmp/myagents-research/msoedov-agentic_security/docs/configuration.md`
- `/tmp/myagents-research/msoedov-agentic_security/docs/api_reference.md`
- `/tmp/myagents-research/msoedov-agentic_security/docs/http_spec.md`
- `/tmp/myagents-research/msoedov-agentic_security/docs/probe_data.md`
- `/tmp/myagents-research/msoedov-agentic_security/docs/operator.md`
- `/tmp/myagents-research/msoedov-agentic_security/docs/external_module.md`
- `/tmp/myagents-research/msoedov-agentic_security/docs/refusal_classifier_plugins.md`
- `/tmp/myagents-research/msoedov-agentic_security/docs/ci_cd.md`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/__main__.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/app.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/core/app.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/core/security.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/config.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/lib.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/http_spec.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/primitives/models.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/dependencies.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/routes/scan.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/routes/probe.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/routes/proxy.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/routes/report.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/routes/telemetry.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/routes/_specs.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/middleware/cors.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/middleware/logging.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/probe_actor/fuzzer.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/probe_actor/state.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/probe_actor/refusal.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/probe_actor/operator.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/probe_actor/cost_module.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/probe_data/__init__.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/probe_data/data.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/probe_data/models.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/probe_data/unified_loader.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/probe_data/msj_data.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/probe_data/stenography_fn.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/probe_data/image_generator.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/probe_data/audio_generator.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/probe_data/modules/fine_tuned.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/probe_data/modules/adaptive_attacks.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/probe_data/modules/garak_tool.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/probe_data/modules/inspect_ai_tool.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/probe_data/modules/rl_model.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/refusal_classifier/model.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/refusal_classifier/pii_detector.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/refusal_classifier/hybrid_classifier.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/refusal_classifier/llm_classifier.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/executor/concurrent.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/executor/rate_limiter.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/executor/circuit_breaker.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/attack_rules/models.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/attack_rules/loader.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/attack_rules/dataset.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/llm_providers/base.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/llm_providers/openai_provider.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/llm_providers/anthropic_provider.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/llm_providers/factory.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/mcp/main.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/mcp/client.py`
- `/tmp/myagents-research/msoedov-agentic_security/agentic_security/report_chart.py`
- `/tmp/myagents-research/msoedov-agentic_security/tests/unit/probe_actor/test_fuzzer.py`
- `/tmp/myagents-research/msoedov-agentic_security/tests/integration/routes/test_probe.py`
- `/tmp/myagents-research/msoedov-agentic_security/tests/integration/routes/test_report.py`
- `/tmp/myagents-research/msoedov-agentic_security/tests/integration/routes/test_csv.py`
- `/tmp/myagents-research/msoedov-agentic_security/tests/unit/test_spec.py`
- `/tmp/myagents-research/msoedov-agentic_security/tests/unit/test_security.py`
- `/tmp/myagents-research/msoedov-agentic_security/tests/unit/probe_data/test_unified_loader.py`
- `/tmp/myagents-research/msoedov-agentic_security/tests/unit/executor/test_concurrent.py`
- `/tmp/myagents-research/msoedov-agentic_security/tests/unit/executor/test_rate_limiter.py`
- `/tmp/myagents-research/msoedov-agentic_security/tests/unit/executor/test_circuit_breaker.py`
- `/tmp/myagents-research/msoedov-agentic_security/tests/unit/attack_rules/test_loader.py`
- `/tmp/myagents-research/msoedov-agentic_security/tests/unit/attack_rules/test_dataset.py`
- `/tmp/myagents-research/msoedov-agentic_security/tests/unit/refusal_classifier/test_pii_detector.py`
- `/tmp/myagents-research/msoedov-agentic_security/tests/unit/test_mcp.py`
- `/tmp/myagents-research/msoedov-agentic_security/tests/system/test_lib.py`

## Excluded Paths

- `agentic_security/static/`: skimmed only by file listing; UI assets are not central to harness design.
- `agentic_security/static/icons/`, `agentic_security/static/favicon.ico`, and `docs/images/demo.gif`: binary or visual assets excluded from code review.
- `agentic_security/refusal_classifier/*.joblib`: packaged binary ML artifacts noted as part of the classifier path but not reverse engineered.
- `poetry.lock`: dependency lock not deeply audited because the review focused on scanner architecture and runtime boundaries.
- `LICENSE`, `CODE_OF_CONDUCT.md`, `mkdocs.yml`, `docs/stylesheets/extra.css`, and shell helper scripts: low relevance to adversarial harness design.
