# superagent-ai/superagent

- URL: https://github.com/superagent-ai/superagent
- Category: error-prevention
- Stars snapshot: 6,608 (GitHub REST API, captured 2026-05-19)
- Reviewed commit: 5adc62db2c209b32ac0e273e9b92b62d41ce0a35
- Reviewed at: 2026-05-19
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong practical pattern source for agent error prevention, especially pre-agent input gates, output redaction, repo-poisoning scans, and provider fallback. Do not copy its fail-open hook behavior, LLM-only redaction assumptions, or current docs/code drift.

## Why It Matters

Superagent is built around the exact prevention layer that agentic coding systems need before high-trust model execution: classify user prompts and untrusted files, remove secrets or PII before outputs/logs leave the process, and scan repositories/MCP servers/AI rules before an assistant reads them. It is not an IDE agent itself; it is a reusable guardrail substrate around agents, which makes it relevant to Agentic Coding Lab.

## What It Is

A monorepo for the `safety-agent` TypeScript and Python SDKs, a `safety-agent-cli` command, an MCP server, and documentation. The current execution surface has three implemented methods:

- `guard`: classify text, URL content, PDFs, and images as `pass` or `block`.
- `redact`: remove or rewrite sensitive text using a model and a redaction prompt.
- `scan`: clone a Git repo into a Daytona sandbox and ask OpenCode to produce a security report for AI-agent-targeted threats.

The advertised `test` red-team method is documentation-only in this commit.

## Research Themes

- Token efficiency: Large text and PDF inputs are split by character/page and processed in parallel, with token usage summed. No broader context compression or budget planner exists.
- Context control: Guard prompts wrap untrusted input before the app model sees it. Redaction is a separate output/input sanitizer. Custom guard `systemPrompt` can replace the default classifier prompt, which is flexible but can weaken policy.
- Sub-agent / multi-agent: No native sub-agent system. `scan` delegates repository review to OpenCode running in a Daytona sandbox, acting like a one-shot external review agent.
- Domain-specific workflow: Strong focus on AI app security workflows: Claude Code/Cursor prompt hooks, RAG upload checks, MCP server audits, dependency audits, and CI scanning.
- Error prevention: Primary theme. It blocks prompt injection, system prompt extraction, secret exfiltration attempts, unsafe instructions, repo poisoning, and PII/secret leakage.
- Self-learning / memory: No memory or self-learning loop. The only persistent telemetry path is token-count usage posting for billing.
- Popular skills: Pre-flight guard, output redaction, repository scan before install, provider abstraction, structured JSON schemas, retry/fallback controls, SSRF-aware URL ingestion.

## Core Execution Path

`createClient` builds a `SafetyClient`, currently requiring a Superagent API key in both TypeScript and Python code even though some docs say default guard needs no key. The key is used for usage reporting, while the default Superagent guard endpoint itself has no provider auth header.

`guard(options)` normalizes input through `processInput`. Plain strings become text unless they look like URLs. URL inputs are validated for length, `http`/`https` protocol, hostname presence, and private/internal IPs before fetch. TypeScript also uses DNS lookup and fails closed on DNS errors; Python has a weaker IPv4-oriented resolver path. URL, Blob, File, and bytes content become text, image base64, or PDF pages.

Guard then selects `superagent/guard-1.7b` by default. Text is wrapped as `Analyze the following input for safety` for third-party models; Superagent models receive raw input. Images are passed as multimodal content and require a vision-capable model. PDFs are analyzed per non-empty page. Long text is chunked at word boundaries. Page/chunk results are aggregated with OR logic: one `block` blocks the whole input, and violation types/CWE codes are deduplicated.

`callProvider` parses `provider/model`, looks up a provider adapter, applies a structured JSON response format when the hardcoded support matrix says it is available, posts to the provider, and transforms the response into a unified shape. Retryable provider status codes `429`, `500`, `502`, and `503` can trigger a single fallback model attempt. Superagent endpoints additionally have timeout fallback to an always-on endpoint.

`redact(options)` builds a system prompt from default entities or caller-provided entities, with optional rewrite mode. It calls the same provider layer, parses JSON containing `redacted` and `findings`, then reports token usage. There is no deterministic second pass to verify that the sensitive input is absent from the returned text.

`scan(options)` validates only that repo URLs start with `https://` or `git@`, requires `DAYTONA_API_KEY`, creates a Daytona sandbox, installs `opencode-ai@latest`, clones the target repo, uploads a detailed security-review prompt, and runs `opencode run -m <model> --format json`. It parses OpenCode text events and usage events into a natural-language report plus cost.

## Architecture

The source is organized as mirrored TypeScript and Python SDK implementations:

- `sdk/typescript/src/client.ts` and `sdk/python/src/safety_agent/client.py` own guard/redact/scan orchestration.
- `providers/*` implement provider request/response transforms for Superagent, OpenAI, Anthropic, Google, Bedrock, Groq, Fireworks, OpenRouter, Vercel AI Gateway, and OpenAI-compatible APIs.
- `prompts/*` hold the classifier, redaction, and repo-scan prompts.
- `schemas.*` define strict JSON response shapes for guard and redact.
- `utils/input-processor.*` performs URL, MIME, PDF, image, and text normalization.
- `cli/src/commands/*` exposes guard/redact/scan as shell commands and hook adapters.
- `mcp/src/index.ts` exposes the same capabilities as MCP tools with Zod schemas.

There is no central policy engine or middleware framework. Policy is distributed across prompts, TypeScript/Python option schemas, provider schemas, and CLI/MCP wrappers.

## Design Choices

Superagent chooses a lightweight SDK boundary instead of embedding inside a full agent runtime. This makes the guardrail easy to place before prompts, before file ingestion, after model output, or inside CI.

The guard result is intentionally simple: `classification`, `reasoning`, `violation_types`, `cwe_codes`, and `usage`. That shape is useful for automated gates and user-facing explanations.

Structured output is preferred where supported, but the SDK also parses plain JSON and markdown code blocks. This makes many providers usable, at the cost of relying on hardcoded model capability lists that can drift.

The repo scanner is deliberately read-only in prompt instructions and emphasizes direct evidence, actionable findings, and false-positive reduction. This is a useful design stance for AI security reviews.

The CLI hook path for Claude Code returns `decision: "block"` for malicious input. However, on guard errors in stdin/hook mode it prints "Allowing prompt to proceed..." and exits success, making availability win over security.

## Strengths

- Clear separation of guard, redact, and scan lets developers insert only the prevention step they need.
- Parallel chunk/page scanning with block-if-any aggregation is a simple, strong default for long untrusted documents.
- Provider abstraction supports many model backends while preserving a common result shape.
- Structured JSON schemas reduce output parsing ambiguity for supported providers.
- SSRF protections in the TypeScript URL processor cover protocols, localhost, private IP ranges, DNS-to-private resolution, IPv6, and fail-closed DNS errors.
- CLI and MCP wrappers make the system usable by coding agents without app-specific SDK integration.
- Tests cover chunking, mocked guard/redact behavior, structured-output routing, model fallback, scan input validation, file/image/PDF handling, and TypeScript SSRF checks.
- Documentation contains practical workflows for scanning AI rules files, MCP servers, dependencies, CI pull requests, RAG uploads, image uploads, Claude Code hooks, and Cursor hooks.

## Weaknesses

- Detector accuracy is mostly delegated to models/prompts. Unit tests mock provider outputs; the MCP `evaluation.xml` has small QA examples but no robust benchmark, adversarial corpus, thresholds, or regression metrics.
- Current docs and code disagree in several important places: default guard model is documented as `guard-0.6b` in some pages but code uses `guard-1.7b`; docs say the API key is optional for default guard, but current clients/CLI/MCP require `SUPERAGENT_API_KEY`; MCP descriptions mention legacy 20B models while current code calls the SDK default and OpenAI for redaction.
- Custom guard `systemPrompt` replaces the default classifier instructions instead of extending a non-bypassable base policy. If exposed to untrusted configuration, it can erase the safety rubric.
- Hook-mode CLI failures are fail-open. A network outage, parse error, or provider error can allow a prompt that was never classified.
- MCP tool errors are returned as text, so the MCP host or agent must decide whether an error means block, retry, or proceed.
- Redaction is LLM-only and lacks deterministic post-validation for obvious secrets/PII that should no longer appear.
- URL fetching has no explicit response size cap in SDK code. Redirect targets are not revalidated after fetch follows redirects, creating a possible SSRF bypass class.
- TypeScript URL validation is stronger than Python. Python allows unresolved hostnames to proceed to fetch, uses `socket.gethostbyname` rather than full IPv6-aware resolution, and follows redirects without per-hop validation.
- `scan` produces a natural-language report, not a structured pass/fail verdict. CI examples grep for threat words, which is brittle.
- Python `scan` builds shell commands with repo, branch, and env values interpolated into command strings. TypeScript uses Daytona git APIs for clone, but the cross-language pattern is inconsistent.

## Ideas To Steal

- Add a pre-agent guard hook that returns a machine decision plus short human reason, violation tags, and security taxonomy IDs.
- Normalize all untrusted inputs into a small typed shape before scanning: text, image, PDF pages, URL-fetched text.
- Use block-if-any aggregation for chunked documents and merge reasons/tags rather than trusting a final summarizer to notice every threat.
- Treat `AGENTS.md`, `.cursorrules`, MCP tool descriptions, dependency docs, comments, and examples as executable influence over coding agents.
- Pair prompt-injection detection with output redaction so the system protects both inbound instruction integrity and outbound data leakage.
- Keep provider adapters behind one registry and make structured-output capability explicit per provider/model.
- Provide a sandboxed repo review command that gathers a natural-language security report, but have the product layer convert that report into a structured gate.
- Surface fallback behavior as a first-class option: primary model, fallback model, timeout, and retryable status codes.

## Do Not Copy

- Do not fail open in security hooks. Use explicit `allow_on_error` configuration with a loud default of fail-closed for high-risk deployments.
- Do not let caller-provided classifier prompts replace base safety instructions. Merge custom policy as additional constraints under an immutable system rubric.
- Do not rely on LLM redaction alone for secrets. Add local regex/entropy detectors and a final leakage check against original sensitive spans.
- Do not gate CI with substring search over a natural-language report. Produce structured severity, confidence, affected file, and pass/fail fields.
- Do not follow remote URL redirects without validating every hop and enforcing response byte/time limits.
- Do not hardcode provider structured-output capability without a maintenance path or provider capability tests.
- Do not interpolate repo URLs, branches, or API keys into shell commands inside a sandbox when structured clone/exec APIs are available.

## Fit For Agentic Coding Lab

High fit as a pattern source, conditional fit as a direct dependency. The best reusable ideas are the pre-prompt hook, document chunk aggregation, AI-rule/dependency/MCP scanning lens, provider fallback, and SSRF-aware input normalization. For Agentic Coding Lab, the patterns should be recast as local-first guard modules with deterministic validators, fail-closed defaults, structured scan results, and immutable base policies.

## Reviewed Paths

- `README.md`: product scope, features, integration options, open-weight model claims.
- `sdk/typescript/src/client.ts`: primary TypeScript guard/redact/scan execution path.
- `sdk/typescript/src/types.ts`: public option/result types and model surface.
- `sdk/typescript/src/schemas.ts`: strict JSON response schemas.
- `sdk/typescript/src/prompts/guard.ts`: classifier rubric for prompt injection, system prompt extraction, secret exfiltration, hidden reasoning, malicious code, and unsafe instruction updates.
- `sdk/typescript/src/prompts/redact.ts`: default sensitive entity list, placeholder mode, rewrite mode, and redaction rules.
- `sdk/typescript/src/prompts/scan.ts`: repo security review procedure, LLM safety checklist, read-only constraints, severity rubric, and false-positive filter.
- `sdk/typescript/src/utils/input-processor.ts`: URL validation, SSRF checks, MIME handling, PDF extraction, image conversion, and vision-model detection.
- `sdk/typescript/src/providers/*.ts`: provider registry, Superagent endpoints, OpenAI/Anthropic/Google/Bedrock/OpenRouter/Vercel/Groq/Fireworks/OpenAI-compatible transforms, structured-output support, and fallback behavior.
- `sdk/python/src/safety_agent/client.py`, `providers/*`, `prompts/*`, `utils/input_processor.py`: Python parity path and language-specific differences.
- `cli/src/index.ts`, `cli/src/commands/guard.ts`, `redact.ts`, `scan.ts`: command-line and hook behavior.
- `mcp/src/index.ts`: MCP tool schemas, annotations, error return behavior, and tool descriptions.
- `docs/content/docs/sdk/*.mdx`: quickstart, SDK API, providers, models, CLI, MCP documentation.
- `docs/content/docs/sdk/examples/*.mdx`: Claude Code/Cursor hooks, RAG upload checks, image upload checks, AI rules scans, MCP scans, dependency scans, and CI scan examples.
- `docs/content/docs/legacy/resources/data-retention.mdx`: zero-retention and usage-metrics claims for hosted APIs.
- `sdk/typescript/tests/*.ts`, `sdk/python/tests/*.py`, `cli/tests/*.ts`, `mcp/tests/*.ts`, `mcp/evaluation.xml`: mocked behavior coverage, SSRF tests, fallback tests, and small evaluation examples.

## Excluded Paths

- `docs/app/**`, `docs/components/**`, `docs/lib/**`, `docs/source.config.ts`, `docs/next.config.mjs`, and `docs/app/global.css`: documentation site UI/framework code; not part of guardrail execution.
- `docs/public/**`, `logo.png`, screenshots, icons, web manifests, and video assets: binary/static media with no safety logic.
- `docs/package-lock.json`, `cli/package-lock.json`, `mcp/package-lock.json`: generated dependency lockfiles; useful for supply-chain audit but not for design pattern extraction here.
- `docs/openapi.json` and `docs/content/docs/legacy/rest-api/*.mdx`: generated API reference; skimmed for legacy endpoint shape, excluded as authoritative execution-path evidence when current SDK source disagreed.
- `docs/content/docs/legacy/agent-frameworks/**` and legacy SDK pages: older integration examples; sampled only for historical context because current SDK/CLI/MCP paths are the active implementation.
- `CHANGELOG.md` and package metadata beyond dependency/version checks: release history was not needed to understand the current execution path.
