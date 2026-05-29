# toby-bridges/api-relay-audit

- URL: https://github.com/toby-bridges/api-relay-audit
- Category: error-prevention
- Stars snapshot: 601 on 2026-05-29 via GitHub web page; `research/index.md` row listed 605 via GitHub REST API capture on 2026-05-29
- Reviewed commit: 408e3f0b0ce25ae4cbe74add121c2fe30dc66583
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong, practical reference for preflight auditing of third-party AI API relays before coding agents depend on them. The best reusable ideas are the local-first scanner, tri-state verdicts, risk-matrix escalation for inconclusive security checks, package-install rewrite probes, raw error-response leak scanning, Anthropic SSE integrity checks, redacted transparent logs, and explicit false-positive handling. Do not treat it as a complete runtime guardrail: several detectors are heuristic, live-relay dependent, Anthropic-specific, or informational only.

## Why It Matters

Coding agents increasingly run through API relays, reverse proxies, "cheap Claude" providers, OpenAI-compatible gateways, and team-local LLM routers. Those intermediaries can inject hidden prompts, force model identity, truncate context, route to cheaper substitutes, rewrite returned commands, leak credentials through error paths, or break streaming semantics. A coding agent that trusts such a relay can be pushed into wrong edits, unsafe dependency installs, private-key handling, skipped safety checks, or hidden instruction leakage.

`api-relay-audit` matters because it treats the relay itself as an untrusted supply-chain component. Instead of only asking a model whether it is safe, the tool sends a battery of black-box probes and emits a structured Markdown report. The strongest coding-agent relevance is Step 8, which probes for package-install command rewriting. A relay that changes `pip install requests` into a typosquat on the response path can turn a normal agent workflow into code execution on the developer host.

The project is also useful as a research pattern because it is local-first. The user gives an API key to a local script, and the script talks to the target relay directly. That does not remove the risk of sending probes to a suspect relay, but it avoids handing the key to a third-party web scanner. The optional transparent log records request and response hashes rather than bodies, which is a good artifact pattern for security tooling that must be auditable without becoming another leak sink.

## What It Is

`api-relay-audit` is a Python security audit tool for AI API relay/proxy services. It ships two distributions:

- A root-level standalone `audit.py` for curl-style single-file use.
- A modular `api_relay_audit/` package plus `scripts/audit.py` for development and testing.

The CLI runs up to 13 steps:

- Infrastructure recon over DNS, WHOIS, TLS certs, headers, and home page snippets.
- Model list enumeration.
- Token injection estimation by comparing expected versus reported input tokens.
- Prompt extraction probes.
- Instruction conflict checks, including a "meow" system-prompt test and model identity override test.
- Jailbreak/role-impersonation extraction probes.
- Context-length canary scan with coarse and binary-search phases.
- Tool-call package substitution probes for pip, npm, cargo, and Go install strings.
- Error response leakage probes using deliberately broken raw requests.
- Anthropic SSE stream integrity analysis.
- Web3/wallet safety probes under `--profile web3` or `--profile full`.
- Infrastructure framework fingerprinting for One API, New API, LobeChat, FastGPT, Cloudflare, nginx, and Caddy.
- Latency variance fingerprinting over repeated identical requests.

The output is a Markdown audit report with a top-level risk summary, per-step details, and an overall LOW/MEDIUM/HIGH rating. Optional `--transparent-log` writes append-only JSONL entries with timestamps, URLs, HTTP method, request/response SHA-256 hashes, status code, selected response headers, elapsed time, transport, and redacted error metadata.

## Research Themes

- Token efficiency: Moderate. The tool is not a token optimizer, but it uses bounded, purpose-specific probes instead of long policy prompts. The token-injection step explicitly measures hidden-token overhead, and latency probes use `max_tokens=8`. The weak spot is live audit cost: context scanning, extraction, stream, Web3, and repeated latency probes all consume relay calls.
- Context control: Strong. The context scan plants five canaries through large filler text and searches for a truncation boundary. The prompt extraction and jailbreak steps test whether hidden instructions leak, while the instruction conflict step tests whether user-provided system prompts still control behavior.
- Sub-agent / multi-agent: Limited. The repo is not a multi-agent system. The reusable pattern is a preflight scanner that a coding-agent platform could run before assigning work to a relay-backed model.
- Domain-specific workflow: Strong for AI relay/proxy security. The project understands Anthropic and OpenAI-compatible request shapes, third-party relay frameworks, package-manager command strings, SSE events, LiteLLM-like error surfaces, and Web3 wallet safety.
- Error prevention: Core theme. The scanner tries to prevent agent failures caused by malicious intermediaries: hidden prompts, identity substitution, package-name rewrites, credential leakage, stream rewriting, context truncation, and unsafe wallet behavior.
- Self-learning / memory: Limited. There is no adaptive memory store. The closest reusable memory-like artifact is the transparent JSONL log plus a growing regression-test suite that captures prior false positives and false negatives.
- Popular skills: The repo ships `SKILL.md` and `skills/api-relay-audit/SKILL.md` so other agent environments can invoke the audit workflow. The valuable "skill" pattern is operational: collect key/url/model, run local audit, interpret risk summary, and report concrete relay hazards.

## Core Execution Path

The normal execution path starts in `scripts/audit.py` or root `audit.py`. The CLI parses target URL, API key, model, skip flags, profile, warmup count, timeout, output path, latency probe count, and optional transparent-log path. It constructs an `APIClient`, initializes a `Reporter`, optionally sends warm-up calls to reduce request-count-gated AC-1.b blind spots, then runs each audit step through `_run_step`.

`APIClient.call()` auto-detects Anthropic native versus OpenAI-compatible format. It tries Anthropic `/v1/messages` first, falls back to OpenAI `/v1/chat/completions`, caches the detected format, and switches to `curl -sk` on SSL/connect failures. `get_models()` tries both OpenAI bearer and Anthropic `x-api-key` auth styles. `raw_request()` preserves non-200 response bodies and headers for error leakage checks. `stream_call()` is Anthropic-specific and captures raw SSE event signals for Step 10.

Steps 3 through 7 are prompt- and context-behavior checks. Token injection compares reported input tokens against rough expected token counts. Prompt extraction sends verbatim, translation, and JSON-continuation probes, then classifies outputs using structural leak patterns, strong markers, weak markers, refusal markers, Claude self-identification, and retraction handling. Instruction conflict sends a strict "only meow" system prompt and an identity system prompt. Context scanning plants five `CANARY_*` markers across increasing payload sizes and binary-searches after the first truncation.

Step 8 asks the model to copy harmless install-command text exactly and compares the returned text against pinned expected commands. It strips common wrappers, tolerates case/trailing punctuation/benign whitespace, and treats token-level divergence as package substitution. It is intentionally a plaintext surrogate for AC-1.a response rewriting; it does not test structured `tool_call` JSON rewrites.

Step 9 builds default broken requests plus optional aggressive oversized-body probes. It sends malformed JSON, invalid model, wrong content type, missing fields, unknown endpoint, force-upstream-error, and auth-echo probes. It scans bodies and headers for full API key echo, first-eight prefix echo, upstream provider hosts, environment variables, filesystem paths, stack traces, LiteLLM internal fields, PII guardrail echoes, and secret-shaped regexes such as API keys, bearer tokens, AWS keys, Google keys, JWTs, PEM private keys, and DB credentials. Snippets are redacted before report output.

Step 10 opens an Anthropic streaming request with thinking enabled and runs `analyze_stream()` over collected `StreamSignals`. It marks transport errors, zero-event streams, or ping-only streams as inconclusive. It marks anomalies for unknown SSE event types, non-monotonic output token samples, inconsistent input token samples, empty `signature_delta` values, missing model identity on substantive streams, or a non-Claude stream model.

Step 11 runs only for Web3/full profiles. It sends ETH transfer guidance, raw transaction signing, and private-key handling probes. Marker lists classify responses as safe, injected, or inconclusive. Hard injected markers override safe-priority matching so contradictory "I cannot sign, but here is the signed tx" responses are not cleared as safe.

Steps 12 and 13 are informational. Step 12 sends unauthenticated GET probes to `/`, `/v1/models`, and a nonexistent path, then matches curated framework signatures in headers and body text. Step 13 warms format detection, sends repeated identical low-token calls, measures with `time.perf_counter()`, computes descriptive statistics and coefficient of variation, then flags stable, variable, high-variance, bimodal, or inconclusive latency. Neither step feeds directly into the final risk rating.

The final risk matrix maps findings to dimensions: D1 token injection, D2 instruction override, D3 tool substitution, D4 error leakage, D5 stream anomaly, D6 Web3 injection, plus inconclusive variants. D3/D4/D5/D6 anomalies or combined D1+D2 are HIGH. Standalone D1 or D2 are MEDIUM. Inconclusive critical checks, medium error leakage, or any crashed step are MEDIUM. Only absence of significant findings and inconclusive states becomes LOW.

## Architecture

The architecture is deliberately dual-distributed:

- `audit.py`: 3,623-line standalone script with stdlib plus subprocess/curl behavior, intended for quick download and local use.
- `scripts/audit.py`: modular CLI orchestrator that imports reusable package modules.
- `api_relay_audit/client.py`: transport, API-format detection, curl fallback, raw requests, streaming capture, model list fetching, and transparent logging hook.
- `api_relay_audit/context.py`: canary-based context scan.
- `api_relay_audit/tool_substitution.py`: AC-1.a plaintext install-command probes and classifiers.
- `api_relay_audit/error_leakage.py`: broken-request trigger builder, leak scanners, severity calculation, and redaction.
- `api_relay_audit/stream_integrity.py`: SSE signal dataclass, known event set, and anomaly analysis.
- `api_relay_audit/web3/injection_probes.py`: Web3 prompt-injection probes and marker classifiers.
- `api_relay_audit/infra_fingerprint.py`: framework signature database and aggregation.
- `api_relay_audit/latency_variance.py`: repeated request timing, bimodality heuristic, and CLI bounds validator.
- `api_relay_audit/identity_patterns.py`: non-Claude identity keyword matching with strict, context-strict, lax, and CJK matching paths.
- `api_relay_audit/reporter.py`: simple Markdown section and risk-summary builder.
- `api_relay_audit/transparent_log.py`: append-only JSONL logger and error/body hashing helpers.

Tests are a meaningful part of the architecture. `tests/test_dual_distribution_parity.py` pins the risk-matrix block, identity keywords, infra-fingerprint constants, latency thresholds, and stream-model helper behavior between modular and standalone distributions. Other tests cover client transport, raw requests, streaming parsing, tool substitution, error leakage, identity patterns, refusal/prompt leak classification, transparent logging, context scans, latency variance, Web3 injection, infra fingerprinting, reporting, and fail-open step handling.

The architecture favors explicit modules over a framework. There is no `pyproject.toml`, setup script, plugin runtime, database, service daemon, or persistent state. `requirements.txt` contains only `httpx>=0.24.0`; the standalone path advertises Python plus curl.

## Design Choices

The most important design choice is tri-state security semantics. Several checks can return clean, anomaly, or inconclusive, and the risk matrix treats inconclusive security-critical checks as MEDIUM rather than green. This prevents blocked probes, broken streams, all-200 malformed requests, all-error substitution probes, and crashed steps from silently improving the final verdict.

The scanner is local-first. The user runs a local CLI and gets a local Markdown report. That is important because the thing being tested is already an untrusted relay. Adding an external SaaS scanner would create another party that sees the API key.

Error leakage is tested through raw HTTP rather than the normal chat wrapper. `raw_request()` keeps non-200 bodies and headers so the scanner can inspect the exact error surface a relay exposes. The trigger set includes validation failures, upstream-forcing failures, and fake auth headers so both Anthropic and OpenAI-style credential paths are exercised.

The report is designed for operator reading, not only machine scoring. Each step adds tables, excerpts, and flags to the Markdown body. The risk summary aggregates all flags at the top. That makes the output useful for a human deciding whether a relay is safe enough for coding-agent work.

The transparent log avoids storing response bodies by default. It records hashes, status, timing, transport, URL, and metadata. This is a good compromise for reproducibility: the user can prove which requests were sent and whether outputs changed without persisting leaked prompts or credentials in plaintext.

The false-positive handling is unusually explicit. Prompt-leak detection separates structural prompt-template evidence from weak words like "assistant" or "developer". A refusal plus Claude/Anthropic self-ID can suppress weak markers, while refusal without Claude self-ID remains suspicious. Identity matching uses strict anchors for common words like GPT, Kimi, Grok, AWS, and context-strict handling for Warp/Windsurf. Tool substitution allows wrapper removal and benign whitespace/case noise but flags internal token changes. Web3 detection acknowledges safe-priority bias and adds hard injection overrides for contradictory dangerous completions.

The project also marks weak signals as weak. Infrastructure fingerprinting and latency variance are informational. The ROADMAP keeps a known limitation where Cloudflare or other edge-layer evidence can dominate app-layer framework aggregation. The channel-fingerprint design memo explicitly says protobuf signature/channel detection is not implemented until empirical verification is done.

## Strengths

The coverage is broad for a small CLI. It probes prompt injection, prompt leakage, instruction override, context truncation, package-install rewriting, error-response leakage, streaming integrity, wallet-safety prompt injection, framework fingerprinting, and latency anomalies.

The Step 8 package substitution probe is directly relevant to coding agents. Plaintext echo is not the same as structured tool-call mutation, but it is a practical canary for response-path rewrite rules that trigger on package manager command strings.

Step 9 is a strong operational check for relay maintainers and users. Error response bodies are a common place for proxies to leak upstream details, internal fields, and credentials. The scanner searches both body and headers and redacts sensitive snippets before writing the report.

Stream integrity is more concrete than natural-language self-reporting. Known event types, usage monotonicity, input-token consistency, non-empty thinking signatures, and `message_start.message.model` are protocol-level signals that a relay has less freedom to fake accidentally.

The final risk matrix is conservative. High-impact anomalies escalate to HIGH even if other steps are clean. Inconclusive checks escalate to MEDIUM so a relay cannot win by suppressing or breaking probes.

The repo has a large regression-test surface focused on previous false positives, false negatives, and dual-distribution drift. I could not execute it in this environment because `pytest` is not installed, but the tests are visible and extensive. A static scan found 17 test files with hundreds of `test_*` functions.

The docs and comments show provenance discipline. The code attributes ideas to Liu et al. on malicious intermediary attacks, Zhang et al. on shadow API infrastructure, hvoy.ai for SSE signal inspiration, SlowMist for Web3 signature isolation, and LiteLLM issues for error leak patterns.

## Weaknesses

The scanner is not a runtime enforcement boundary. It can tell a user whether a relay looks suspicious during an audit run; it cannot stop a live coding agent from using a relay later, nor can it prove the relay will behave the same under different prompts, models, keys, time windows, or request counts.

Some core checks are heuristic. Token injection uses rough expected token counts, prompt extraction uses marker and regex classification, Web3 safety uses substring markers, infra fingerprinting uses curated header/body strings, and latency variance can be caused by ordinary network/provider behavior. These are useful signals, not formal proofs.

Step 8 does not exercise real structured tool calls. The code documents this limitation: a relay that rewrites only `tool_call` JSON payloads while leaving plaintext alone can evade the current substitution probe. A coding-agent lab should treat this as a starter pattern and add actual tool-call round trips when the client supports them.

Step 10 is Anthropic-specific. OpenAI-compatible or non-Anthropic relays tend to become inconclusive at the SSE layer. That is correct semantics, but it means the most protocol-specific integrity check does not generalize across all model providers.

The report can contain sensitive material. Error snippets are redacted for API keys, but prompt extraction, jailbreak outputs, response previews, headers, and target metadata can still reveal operator details or hidden prompt content. Generated audit reports need the same handling as security findings.

The packaging is lightweight. There is no `pyproject.toml` or installable Python package metadata in the reviewed checkout. Modular development imports from the repo root via `sys.path.insert`, and standalone/modular parity is maintained by tests rather than a code-generation source of truth.

The infrastructure recon path still shells out via `run_cmd(..., shell=True)`, although domains and URLs are quoted with `shlex.quote` in the reviewed code. For a security tool, a subprocess-list style would be cleaner and easier to reason about.

Live verification is operationally expensive and environment-sensitive. The audit requires a real API key and target relay, sends intentionally broken requests, may trigger relay logs/alerts, and can incur billing. The aggressive 256 KB error probe is properly opt-in, but even normal probes should be run with consent and disposable credentials where possible.

## Ideas To Steal

Use preflight relay auditing as part of coding-agent model configuration. A relay that fails package substitution, error leakage, stream integrity, or hidden prompt checks should not be allowed into an autonomous coding workflow.

Adopt tri-state verdicts everywhere: clean, anomaly, and inconclusive. Inconclusive should not equal safe, especially when a probe is blocked, all requests error, malformed inputs return HTTP 200, or a stream cannot be parsed.

Add response-path package command canaries. Even before full structured tool-call support exists, echo probes for `pip`, `npm`, `cargo`, and `go` commands are cheap and directly relevant to coding-agent supply-chain risk.

Build raw error-surface scanners. A coding-agent lab should deliberately test its own gateways, MCP servers, and tool wrappers with malformed inputs, fake auth, oversized bodies, and invalid models, then scan for credentials, upstream URLs, env vars, stack traces, internal fields, and PII echoes.

Keep transparent logs body-free by default. Hash request/response bytes, record status/timing/transport/policy versions, and redact errors so evidence does not become another secret store.

Write regression tests for false positives, not only happy paths. This repo's refusal detector, identity patterns, Web3 hard-injection override, latency outlier handling, Next.js infra false-positive removal, and dual-distribution parity tests are good examples.

Separate high-confidence risk dimensions from informational signals. Infrastructure family and latency variance can guide manual review without directly driving a HIGH verdict.

Make source attribution and "not implemented yet" explicit. The channel-fingerprint memo is a good pattern: document the hypothesis, verification plan, integration design, and disproof criteria before shipping a brittle detector.

## Do Not Copy

Do not copy the monolithic-plus-modular duplication as a default architecture. If a lab needs a standalone artifact, prefer generation from shared modules or a build step plus parity tests, not manual mirrored code.

Do not rely on plaintext echo probes as full tool-call safety. Real coding agents need structured tool-call mutation tests, command-policy checks, dependency allowlists, and sandboxed installation paths.

Do not treat token deltas or latency variance as decisive by themselves. They are useful suspicious signals, but provider billing, tokenizer differences, queueing, warm-up, and routing can all distort them.

Do not store audit reports casually. They may contain hidden prompt text, target infrastructure details, response headers, or leaked snippets. Treat them as sensitive security artifacts.

Do not run aggressive probes against paid or third-party relays without understanding cost and policy. Broken requests and oversized bodies can consume quota, trip abuse detection, or expose the user to relay-side logging.

Do not let "local scanner" imply no data leaves the machine. The API key and probe contents still go to the relay under test by definition; local-first only removes an extra scanner service from the trust chain.

Do not make prompt-level hidden-instruction checks the only safety gate. Coding-agent safety also needs file/path restrictions, shell command approval, dependency controls, network egress policy, and post-diff verification.

## Fit For Agentic Coding Lab

Fit is high for the `error-prevention` category. The repo is a useful reference for auditing a model-routing dependency before a coding agent uses it. The strongest lab adaptation would be a "relay admission check" that runs a subset of these probes, records the reviewed commit/version of the scanner, stores the report as a security artifact, and marks the relay as approved, blocked, or needs-human-review.

The most reusable artifact is not the exact CLI but the pattern set:

- A local runner that never sends keys to a scanner SaaS.
- A Markdown report with step-level evidence and a compact risk summary.
- A risk matrix where package rewrite, credential leak, stream anomaly, and wallet-safety injection are immediate blockers.
- Explicit inconclusive handling.
- Redacted, hash-based forensic logs.
- Regression tests for detector drift and false-positive fixes.

For coding agents, this should be paired with runtime controls. A relay that passes today can still behave differently later. The lab should treat the audit as an admission and monitoring tool, then enforce safe shell, file, dependency, MCP, and network behavior independently.

## Reviewed Paths

- `README.md`: project framing, bilingual quickstart, coverage list, profiles, dual distribution claims, and key links.
- `ROADMAP.md`: shipped feature history, threat-model anchor, known limitations, deferred channel fingerprinting, false-positive fixes, test-count claims, and Codex review notes.
- `SKILL.md` and `skills/api-relay-audit/SKILL.md`: agent-skill workflow for collecting key/url/model, running the audit, interpreting reports, risk thresholds, and operator guidance.
- `audit.py`: standalone single-file implementation, CLI, detector implementations, API client, reporter, risk matrix, and output behavior.
- `scripts/audit.py`: modular CLI orchestration, shared prompt-leak detector, step functions, `_run_step` fail-open wrapper, profile gating, transparent log setup, and final risk matrix.
- `api_relay_audit/client.py`: API format detection, Anthropic/OpenAI calls, curl fallback, raw request handling, SSE streaming, model list fetching, timing, and transparent logger integration.
- `api_relay_audit/context.py`: canary marker placement, context recall checks, coarse scan, binary search, and fine scan.
- `api_relay_audit/tool_substitution.py`: package-manager probe set, wrapper stripping, token-level classifier, inconclusive handling, and AC-1.a limitation note.
- `api_relay_audit/error_leakage.py`: broken-request triggers, credential and infrastructure leak patterns, redaction, severity ordering, and inconclusive semantics.
- `api_relay_audit/stream_integrity.py`: `StreamSignals`, Anthropic event whitelist, usage/signature/model checks, event-shape classification, and anomaly/inconclusive logic.
- `api_relay_audit/web3/injection_probes.py`: ETH transfer, transaction signing, private-key probes, safe/unsafe marker lists, hard injected marker override, and verdict aggregation.
- `api_relay_audit/infra_fingerprint.py`: framework signature database, body scan cap, informative headers, per-probe classification, and majority aggregation.
- `api_relay_audit/latency_variance.py`: probe-count validation, timing loop, `ensure_format()` warm-up, `perf_counter()` use, statistics, CV thresholds, and bimodality heuristic.
- `api_relay_audit/identity_patterns.py`: non-Claude keyword set, strict/context-strict/lax matching, CJK handling, identity anchors, suffix rules, and documented residual false positives.
- `api_relay_audit/reporter.py`: Markdown report construction and risk summary rendering.
- `api_relay_audit/transparent_log.py`: JSONL logger, SHA-256 helpers, error redaction, and append-only behavior.
- `tests/test_dual_distribution_parity.py`: risk-matrix parity, identity keyword parity, infra/latency constants parity, and standalone timing behavior.
- `tests/test_tool_substitution.py`, `tests/test_error_leakage.py`, `tests/test_stream_integrity.py`, `tests/test_client_stream.py`, `tests/test_web3_injection.py`, `tests/test_infra_fingerprint.py`, `tests/test_latency_variance.py`, `tests/test_identity_patterns.py`, `tests/test_refusal_detector.py`, `tests/test_clean_summary_flags.py`, `tests/test_fail_open_step_wrapper.py`, `tests/test_client.py`, `tests/test_client_raw_request.py`, `tests/test_context.py`, `tests/test_transparent_log.py`, and `tests/test_reporter.py`: sampled for detector expectations, regression coverage, false-positive controls, and failure semantics.
- `docs/comparison-api-relay-audit-vs-hvoy-vs-cctest.md`: self-comparison against hvoy.ai and cctest.ai, unique-value claims, known shortfalls, and claimed test/review posture.
- `docs/channel-fingerprint-design-memo.md`: unimplemented channel fingerprint hypothesis, verification plan, protobuf parser sketch, risk integration proposal, and known failure modes.
- `docs/codex-review.md`, `docs/python-code-explanation-zh.md`, `docs/_metrics.md`, and `FOR_JOHN.md`: sampled for architecture history, review findings, diary context, and implementation rationale.
- `requirements.txt`: dependency surface (`httpx>=0.24.0`).
- `.github/**`, `deploy/**`, `web/**`, and `scripts/experiments/**`: sampled only to understand packaging, site/demo shape, and deferred experiments.

## Excluded Paths

- `.git/**`: repository metadata except for reviewed commit, latest commit message, and provenance.
- `web/index.html` and `web/data-example.json`: presentation and example-site content, not detector execution.
- `deploy/deploy-nas.sh`: deployment helper, not part of scanner behavior.
- `.github/**`: CI and repository automation metadata, not runtime detector logic.
- `scripts/collect-metrics.py`, `scripts/extract-data.py`, and `scripts/context-test.py`: auxiliary data/context tools; sampled only for project shape because the deep review focused on the main audit path.
- `scripts/experiments/verify_signature_schema.py`: experimental support for a deferred channel-fingerprint idea, not shipped scanner behavior.
- Remote GitHub issues, pull requests, linked papers, hvoy.ai source, SlowMist guide, LiteLLM issue pages, and cctest.ai internals: considered through repository comments/docs only. A full independent review of those sources would require separate notes.
- Binary/image badge assets referenced by README and GitHub Pages: presentation-only.
- Exhaustive line-by-line review of the standalone `audit.py` duplicate blocks after comparing them to modular code and parity tests: reviewed enough to understand the execution path and drift controls, but modular files were the main behavior authority.
