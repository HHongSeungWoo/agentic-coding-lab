# teng-lin/notebooklm-py

- URL: https://github.com/teng-lin/notebooklm-py
- Category: domain-specific-coding
- Stars snapshot: 15,452 (GitHub REST API repository search, captured 2026-05-29)
- Reviewed commit: 7e00442ad4c7786e601fd7952cae32d4af3bbd39
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: conditional
- Verdict: Strong domain-specific pattern source for agent-facing research tooling, especially for API/CLI/skill boundaries, artifact workflows, and session safety. The fit is conditional because the system depends on undocumented NotebookLM RPCs and Google cookie sessions rather than an official API contract.

## Why It Matters

NotebookLM is a research workspace with notebooks, uploaded sources, grounded chat, web/Drive research, and generated artifacts such as podcasts, videos, reports, quizzes, flashcards, slide decks, mind maps, infographics, and data tables. This repository turns that product surface into an async Python library, a structured CLI, and installable agent skill files for Claude Code, Codex-style agents, and OpenClaw.

For the Agentic Coding Lab index, the interesting part is not NotebookLM itself. The repo shows how a domain wrapper can expose a complex research product to coding agents without asking the agent to automate a browser. It also shows the cost of building on an unofficial product surface: much of the engineering budget goes into cookie auth, shape-drift detection, idempotency, host validation, cassette scrubbing, and live RPC health checks.

## What It Is

`notebooklm-py` is an unofficial NotebookLM automation package. It ships:

- `NotebookLMClient`, an async Python client composed from feature APIs for notebooks, sources, artifacts, chat, notes, research, settings, and sharing.
- `notebooklm`, a Click/Rich CLI with JSON modes, auth checks, profile support, generated artifact commands, research import commands, and agent-install commands.
- A root `SKILL.md` that is bundled into the package and can be installed into `~/.claude/skills/notebooklm` and `~/.agents/skills/notebooklm`.
- Documentation for the reversed batchexecute RPC layer, auth lifecycle, architecture, stability policy, and contributor workflows.
- Extensive unit/VCR tests plus scheduled workflows that probe the live NotebookLM RPC surface with protected credentials.

The repo is not a general coding-agent framework. It is a product-specific, research-domain wrapper whose design patterns are reusable when a coding agent must operate a high-side-effect research tool through a stable CLI and a documented skill contract.

## Research Themes

- Token efficiency: The CLI supports compact JSON output, prompt-file inputs, explicit notebook/source IDs, and background wait patterns in the skill. The root skill itself is large and mixes reference, policy, recipes, and output conventions, so its token profile is a weakness even though the operational interface is token efficient.
- Context control: The skill tells agents to avoid ambient notebook state in parallel workflows, prefer explicit `-n` or full notebook UUIDs, use per-agent `NOTEBOOKLM_PROFILE` or `NOTEBOOKLM_HOME`, and verify auth with `notebooklm auth check --test --json`. This is a good example of converting product context into explicit tool context.
- Sub-agent and multi-agent support: The repo does not implement sub-agents, but the skill gives concrete sub-agent patterns for long waits, source processing, research polling, and artifact generation. The `AGENTS.md` file also warns that `notebooklm use` is single-agent context and should be avoided for parallel work.
- Domain-specific workflow: The coverage is broad: notebook lifecycle, source ingestion from URLs/YouTube/files/Drive/text, source fulltext, chat, personas, web/Drive research, source import, sharing, artifact generation, artifact download, and export formats.
- Error prevention: The strongest engineering patterns are the idempotency registry, strict decode helpers, middleware retry/auth-refresh path, loop-affinity guard, concurrency semaphores, trusted-host download checks, atomic file writes, cookie redaction, cassette leak checks, and per-RPC coverage gates.
- Self-learning and memory: Limited. The client can read/write NotebookLM notes and cache local chat turns, but it does not implement a durable agent memory loop or learn from previous tool outcomes.
- Popular skill design: The bundled skill is a serious operational manual for a domain tool. It includes activation criteria, install checks, command recipes, autonomy rules, parallelism guidance, generated artifact schemas, citation caveats, and known limitations.

## Core Execution Path

1. An operator authenticates with `notebooklm login`, browser-cookie import, `NOTEBOOKLM_AUTH_JSON`, or profile storage, then verifies with `notebooklm auth check --test --json`.
2. An agent calls the CLI or Python client. CLI modules parse options and delegate workflow logic to service modules, which construct `NotebookLMClient` through centralized auth-source resolution.
3. Feature APIs call the shared `RpcExecutor`, which encodes NotebookLM batchexecute payloads, applies idempotency policy, sends through `SessionTransport`, decodes positional response arrays, and wraps only expected transport/decode failures.
4. Chat is a special streaming path: `ChatAPI.ask` uses chat-aware authenticated POST handling, parses streamed answer chunks and references, then fetches the durable conversation ID through a normal RPC.
5. Source ingestion routes through source services. File upload uses a dedicated resumable upload path with upload URL validation and redacted logging. URL and Drive source creation can use probe-style idempotent wrappers; text source creation is explicitly non-idempotent.
6. Research workflows start fast or deep research, poll task state, import selected report/source rows, and verify timeout cases by comparing source snapshots before and after import.
7. Generated artifact workflows build type-specific payloads, create artifacts through NotebookLM RPCs, poll generated status, and download through host-validated streaming or structured exporters.
8. Session maintenance runs through token extraction, homepage probing, optional refresh command execution, cookie snapshot/delta persistence, file locks, and `__Secure-1PSIDTS` RotateCookies keepalive support.

## Architecture

The architecture is layered around a narrow central RPC path:

- CLI layer: Click command modules parse arguments and render user output. `src/notebooklm/cli/services/` owns workflow logic such as auth source resolution, login, skill installation, row adaptation, and artifact download orchestration.
- Client layer: `NotebookLMClient` is the composition root. It wires auth, lifecycle, kernel, transport, executor, polling, and feature APIs.
- Runtime layer: `RpcExecutor`, `SessionTransport`, `ClientLifecycle`, `PollRegistry`, concurrency semaphores, and middleware own retry, auth refresh, metrics, tracing, drain, and error injection behavior.
- RPC layer: `src/notebooklm/rpc/types.py`, encoder modules, decoder modules, and `safe_index` centralize method IDs, positional payload shapes, artifact/source type codes, and strict shape-drift errors.
- Feature layer: Notebooks, sources, artifacts, chat, notes, research, settings, and sharing expose domain methods instead of asking callers to assemble raw NotebookLM arrays.
- Auth layer: `_auth/*` splits token models, path/storage policy, cookie filtering, extraction, session refresh, refresh-command orchestration, keepalive rotation, account metadata, and browser-cookie import support.
- Agent layer: root `SKILL.md`, `AGENTS.md`, `cli/agent_templates.py`, and `cli/skill_cmd.py` expose package-maintained instructions for coding agents.

The most reusable architectural choice is that every high-level API and most low-level escape hatches still flow through the same executor, auth, retry, decode, and observability pipeline. The risky exception is the public raw `rpc_call`, which preserves transport safety but can bypass feature-specific payload builders and semantic guards.

## Design Choices

- Treat NotebookLM RPCs as typed-but-fragile contracts. The repo keeps RPC IDs, enum codes, and positional payload expectations in source-controlled Python types and documents how to recapture RPCs when Google changes them.
- Prefer feature APIs and CLI commands over raw browser automation. This gives agents a stable text interface even though the backend is reverse engineered.
- Use an idempotency taxonomy instead of blind retries. Methods are classified as `UNCLASSIFIED`, `PROBE_THEN_CREATE`, `IDEMPOTENT_SET_OP`, `AT_LEAST_ONCE_ACCEPTED`, or `NON_IDEMPOTENT_NO_RETRY`.
- Fail loudly on shape drift. `safe_index` defaults to strict typed failures, with `NOTEBOOKLM_STRICT_DECODE=0` only as a temporary soft mode.
- Keep auth source precedence explicit: command storage path, `NOTEBOOKLM_AUTH_JSON`, then profile storage. This matters for agents because wrong-account operations can be more damaging than command failure.
- Validate download hosts and upload URLs. Artifact downloads require HTTPS and trusted Google host suffixes; upload URLs are checked for host, path, credentials, and upload-id shape.
- Make generated outputs first-class. Quiz, flashcard, report, mind-map, table, deck, video, infographic, and audio flows have command/API support instead of being treated as opaque browser UI actions.
- Bundle the skill as package data. This keeps the agent instructions versioned with the CLI and client behavior, and lets users install the exact skill that matches the installed package.

## Strengths

- Broad domain surface: The repo covers most NotebookLM objects and workflows that a research agent would need, including operations beyond the public web UI such as structured quiz/flashcard/data-table exports and batch downloads.
- Strong agent affordances: JSON output, prompt-file inputs, explicit ID flags, profile isolation, auth preflight, and skill recipes make the tool much easier for agents to operate safely.
- Serious auth/session engineering: The code redacts secrets, filters cookies by domain policy, stores snapshots atomically, uses file locks and compare-and-swap guards, supports account metadata, coalesces refreshes, and implements PSIDTS keepalive rotation.
- Thoughtful side-effect control: Idempotency policies prevent unsafe replay of create/import/research operations while still permitting safe refresh/retry for known idempotent paths.
- Good generated-artifact handling: The download path includes trusted-host checks, streaming writes through temp files, zero-byte checks, atomic replacement, and structured exporters for non-file artifact types.
- Research provenance is visible to callers: Research tasks carry task IDs, import validation catches mixed-task imports, source snapshots verify timeout outcomes, and helpers can select cited source URLs from report markdown.
- Verification culture is unusually mature for a reverse-engineered wrapper: The repo has hundreds of tests, sanitized VCR cassettes, RPC method coverage checks, strict coverage thresholds, nightly E2E, RPC health checks, dependency audit, CodeQL, action pinning checks, and secret-gated workflows.

## Weaknesses

- The core dependency is unofficial. Google can change RPC IDs, positional array shapes, cookie requirements, rate limits, or DBSC behavior without notice. The repo mitigates this well, but it cannot remove the product risk.
- The bundled skill is monolithic. It is useful, but it asks an agent to load a large reference manual with install, auth, autonomy policy, recipes, schemas, caveats, and timing guidance in one file.
- Artifact create idempotency is conservative but incomplete. `CREATE_ARTIFACT` and `GENERATE_MIND_MAP` are classified to avoid internal retries, and comments note that list-based probe recovery can be layered later. This prevents duplicate side effects but leaves commit-lost failures for humans or agents to inspect.
- Evidence provenance is best effort, not formal proof. Report citation selection is URL/markdown based and can fall back to all importable sources. Chat `cited_text` and character offsets are documented as NotebookLM internal chunk hints rather than authoritative source spans.
- The raw `NotebookLMClient.rpc_call` escape hatch is useful for development but weakens the feature-boundary story if exposed to agents without additional policy.
- Live verification depends on private credentials and real NotebookLM state. External users can run unit and cassette tests, but the strongest health checks require protected accounts, notebooks, and rate-limit tolerance.
- The implementation must preserve many reversed positional schemas. That makes maintenance labor high and makes code review harder than wrappers around official JSON APIs.

## Ideas To Steal

- Ship the CLI, Python client, and agent skill from the same package so the instructions match the installed behavior.
- Require a real auth preflight such as `auth check --test --json`, and document false-positive auth checks explicitly.
- Use explicit resource IDs, profile/home isolation, and JSON output as the default agent contract for multi-agent workflows.
- Centralize idempotency by RPC method and operation variant, then make retry behavior consult that registry.
- Put strict decode helpers around fragile external response shapes and gate shape drift in tests.
- Use trusted-host validation, temp files, writer threads, zero-byte checks, and atomic replacement for downloaded generated artifacts.
- Verify long-running import side effects by comparing before/after resource snapshots rather than trusting a single timeout or exception.
- Add static CI gates for method coverage, cassette secret leakage, action pinning, workflow permissions, package/install parity, and public API compatibility.

## Do Not Copy

- Do not use cookie replay and undocumented RPCs when an official scoped API exists. This repo is valuable because NotebookLM has no public automation API, not because this auth model is generally desirable.
- Do not hand a raw RPC escape hatch to an autonomous coding agent without policy, allowlists, logging, and side-effect review.
- Do not treat NotebookLM citation snippets or internal offsets as full evidence provenance. Keep the source retrieval and quoted-context step explicit.
- Do not blindly retry generated artifact creation, source import, or research operations. The repo's non-idempotent classifications are there because duplicate side effects are plausible.
- Do not make a single giant skill file the only interface for a complex domain unless the context budget is acceptable. Split recipes, schemas, and policies when the host agent supports referenced files.
- Do not assume live E2E checks are reproducible by open-source users. Secret-gated product tests should complement, not replace, deterministic local tests.

## Fit For Agentic Coding Lab

This is a strong conditional inclusion for `domain-specific-coding`. It is not primarily about coding-agent internals, but it is directly about making a research domain tool usable by coding agents through a stable CLI and skill wrapper.

The most relevant AICL lesson is a pattern: when an agent needs to operate a specialized research product, build a narrow typed client, a CLI with JSON and explicit IDs, an installable skill with operational policy, and verification gates that understand product-specific side effects. The repo also shows what must be added when the product surface is unofficial: auth provenance, cookie hygiene, shape-drift detection, idempotency classification, live health checks, and blunt caveats for users.

The caveat for synthesis is important. This should not be treated as a model for normal API integration. Its best ideas are the agent boundary, generated-artifact workflows, and defensive verification patterns, not the reverse-engineered Google session dependency.

## Reviewed Paths

- `/tmp/myagents-research/teng-lin-notebooklm-py/README.md`
- `/tmp/myagents-research/teng-lin-notebooklm-py/SKILL.md`
- `/tmp/myagents-research/teng-lin-notebooklm-py/AGENTS.md`
- `/tmp/myagents-research/teng-lin-notebooklm-py/pyproject.toml`
- `/tmp/myagents-research/teng-lin-notebooklm-py/docs/architecture.md`
- `/tmp/myagents-research/teng-lin-notebooklm-py/docs/auth-cookie-lifecycle.md`
- `/tmp/myagents-research/teng-lin-notebooklm-py/docs/rpc-reference.md`
- `/tmp/myagents-research/teng-lin-notebooklm-py/docs/rpc-development.md`
- `/tmp/myagents-research/teng-lin-notebooklm-py/docs/stability.md`
- `/tmp/myagents-research/teng-lin-notebooklm-py/src/notebooklm/client.py`
- `/tmp/myagents-research/teng-lin-notebooklm-py/src/notebooklm/_rpc_executor.py`
- `/tmp/myagents-research/teng-lin-notebooklm-py/src/notebooklm/_idempotency.py`
- `/tmp/myagents-research/teng-lin-notebooklm-py/src/notebooklm/rpc/types.py`
- `/tmp/myagents-research/teng-lin-notebooklm-py/src/notebooklm/_artifacts.py`
- `/tmp/myagents-research/teng-lin-notebooklm-py/src/notebooklm/_artifact_generation.py`
- `/tmp/myagents-research/teng-lin-notebooklm-py/src/notebooklm/_artifact_payloads.py`
- `/tmp/myagents-research/teng-lin-notebooklm-py/src/notebooklm/_artifact_downloads.py`
- `/tmp/myagents-research/teng-lin-notebooklm-py/src/notebooklm/_artifact_formatters.py`
- `/tmp/myagents-research/teng-lin-notebooklm-py/src/notebooklm/_research.py`
- `/tmp/myagents-research/teng-lin-notebooklm-py/src/notebooklm/research.py`
- `/tmp/myagents-research/teng-lin-notebooklm-py/src/notebooklm/_source_add.py`
- `/tmp/myagents-research/teng-lin-notebooklm-py/src/notebooklm/_source_upload.py`
- `/tmp/myagents-research/teng-lin-notebooklm-py/src/notebooklm/_source_content.py`
- `/tmp/myagents-research/teng-lin-notebooklm-py/src/notebooklm/_chat.py`
- `/tmp/myagents-research/teng-lin-notebooklm-py/src/notebooklm/_auth/tokens.py`
- `/tmp/myagents-research/teng-lin-notebooklm-py/src/notebooklm/_auth/storage.py`
- `/tmp/myagents-research/teng-lin-notebooklm-py/src/notebooklm/_auth/extraction.py`
- `/tmp/myagents-research/teng-lin-notebooklm-py/src/notebooklm/_auth/session.py`
- `/tmp/myagents-research/teng-lin-notebooklm-py/src/notebooklm/_auth/refresh.py`
- `/tmp/myagents-research/teng-lin-notebooklm-py/src/notebooklm/_auth/keepalive.py`
- `/tmp/myagents-research/teng-lin-notebooklm-py/src/notebooklm/_auth/cookie_policy.py`
- `/tmp/myagents-research/teng-lin-notebooklm-py/src/notebooklm/cli/services/playwright_login.py`
- `/tmp/myagents-research/teng-lin-notebooklm-py/src/notebooklm/cli/services/auth_source.py`
- `/tmp/myagents-research/teng-lin-notebooklm-py/src/notebooklm/cli/auth_runtime.py`
- `/tmp/myagents-research/teng-lin-notebooklm-py/src/notebooklm/cli/agent_templates.py`
- `/tmp/myagents-research/teng-lin-notebooklm-py/src/notebooklm/cli/skill_cmd.py`
- `/tmp/myagents-research/teng-lin-notebooklm-py/tests/scripts/check_method_coverage.py`
- `/tmp/myagents-research/teng-lin-notebooklm-py/tests/scripts/check_cassettes_clean.py`
- `/tmp/myagents-research/teng-lin-notebooklm-py/.github/workflows/test.yml`
- `/tmp/myagents-research/teng-lin-notebooklm-py/.github/workflows/nightly.yml`
- `/tmp/myagents-research/teng-lin-notebooklm-py/.github/workflows/rpc-health.yml`
- `/tmp/myagents-research/teng-lin-notebooklm-py/.github/workflows/verify-artifacts.yml`
- `/tmp/myagents-research/teng-lin-notebooklm-py/.github/workflows/dependency-audit.yml`

## Excluded Paths

- `/tmp/myagents-research/teng-lin-notebooklm-py/.git/` was not reviewed.
- `/tmp/myagents-research/teng-lin-notebooklm-py/uv.lock` was not audited beyond dependency context from `pyproject.toml`.
- `/tmp/myagents-research/teng-lin-notebooklm-py/image/` and static media were not reviewed because they do not affect the agent/tool boundary.
- `/tmp/myagents-research/teng-lin-notebooklm-py/tests/cassettes/` was counted and considered as VCR evidence, but individual cassette bodies were not line-reviewed.
- `/tmp/myagents-research/teng-lin-notebooklm-py/CHANGELOG.md`, `/tmp/myagents-research/teng-lin-notebooklm-py/CLAUDE.md`, `/tmp/myagents-research/teng-lin-notebooklm-py/CONTRIBUTING.md`, and `/tmp/myagents-research/teng-lin-notebooklm-py/SECURITY.md` were not deeply reviewed because the core API, skill, auth, artifact, and verification paths were sufficient for this index note.
- No live NotebookLM calls, generated-artifact jobs, or candidate-repo test suite runs were executed because the review did not have real Google/NotebookLM credentials and the required project verification is the local research-index checker.
