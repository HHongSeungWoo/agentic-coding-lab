# kodustech/kodus-ai

- URL: https://github.com/kodustech/kodus-ai
- Category: error-prevention
- Stars snapshot: 1,107 (GitHub REST API, captured 2026-05-19)
- Reviewed commit: dfcbdb33d6407ff011811daf47d3af4ec658c921
- Reviewed at: 2026-05-19
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong in-scope system for AI-assisted error prevention. Best patterns are its staged PR review pipeline, BYOK cost gates, provider-aware Git integration, diff/context filters, agent coverage and verification loops, and explicit suggestion post-processing. It is not a drop-in reference because the useful logic is embedded in a large product with mixed legacy and agent paths, service dependencies, and some fail-open or stale execution edges.

## Why It Matters

Kodus is a production-oriented AI code review system, not a small prompt wrapper. It has to decide when to review, how much code to send, which model/account to use, how to avoid noisy comments, and how to fail without blocking a development team. That makes it directly relevant to Agentic Coding Lab error prevention: the repository shows how an agentic reviewer can be integrated into real PR, CLI, sandbox, config, cost, and platform workflows.

The main practical lesson is that error prevention is mostly pipeline design. The LLM is only one stage. Kodus surrounds it with eligibility gates, config inheritance, file and severity filters, model budget controls, sandboxed tool access, line anchoring, deduplication, validation, summaries, reactions, and optional request-changes or approval behavior.

## What It Is

`kodustech/kodus-ai` is a TypeScript/NestJS monorepo for the Kodus AI code review product. It supports GitHub, GitLab, Bitbucket, Azure Repos, Forgejo, a server-side webhook review flow, a CLI review flow, BYOK model configuration, MCP/plugin context, custom review rules, Kody memories, business-logic validation, sandboxed repository tools, and optional committable suggestions.

The current product positioning in the README is "AI Code Review with Full Control Over Model Choice and Costs." The implementation backs that up with BYOK provider mapping, fallback models, reasoning/thinking controls, per-key concurrency gates, OpenRouter routing options, and model-agnostic agent execution through the Vercel AI SDK.

## Research Themes

- Token efficiency: The agent path resolves model context windows, budgets prompts to a fraction of the window, applies large-PR filtering and file tiering, caps tool output, chunks oversized prompts, compresses conversation context, limits CLI file payloads, and lets CLI users request compact fields or prompt-only output.
- Context control: Review context is assembled from config hierarchy, changed-file metadata, enriched file content, external references, MCP/plugin data, Kody memories, task-management context, sandbox tools, optional AST/call-graph data, and business-logic ticket links. Context is explicitly layered rather than passed as one raw blob.
- Sub-agent / multi-agent: `ReviewOrchestratorService` dispatches a generalist agent in normal mode or separate bug/security/performance agents in deep mode, plus a Kody Rules agent when active rules exist. It uses `Promise.allSettled` so partial failures can be classified instead of collapsing the whole review.
- Domain-specific workflow: The primary workflow is PR review. It models PR cadence, branch scopes, ignored files, ignored titles, draft behavior, provider comments, reactions, checks, summaries, approval, request-changes, implemented suggestion tracking, and manual commands such as `@kody start-review`.
- Error prevention: Kodus combines skip gates, rate-limit gates, BYOK concurrency, sandbox isolation, tool-first investigation prompts, coverage ledgers, verifier passes, Kody-rule UUID validation, severity reclassification, severity filters, deduplication, valid-diff line snapping, and committable suggestion validation.
- Self-learning / memory: Kody Rules and memories are injected into review/chat context. IDE rule files can be synced into rules. Implemented suggestions and feedback are tracked. CLI memory/session features are present, although the deepest review focus here was code review.
- Popular skills: Useful transferable skills are PR reviewer orchestration, agent review CLI, BYOK model gateway, MCP/context ingestion, rules-as-policy, business requirement validation, sandboxed repository tools, and deterministic agent-friendly output.

## Core Execution Path

The PR path starts in provider-specific webhook handlers under `libs/platform/infrastructure/webhooks/*`. Each handler maps provider payloads, saves PR metadata, skips repositories without active automation, dispatches chat/comment commands separately, and enqueues a code review job for supported PR actions. GitHub handles `pull_request`, `issue_comment`, and `pull_request_review_comment`; GitLab handles merge request and note hooks; Bitbucket handles Cloud and Data Center PR/comment events; Azure Repos handles PR created/updated/merge/comment events and has duplicate webhook suppression.

`EnqueueCodeReviewJobUseCase` creates a `CODE_REVIEW` workflow job. `CodeReviewJobProcessorService` loads it, validates payload shape, pre-checks the GitHub rate-limit bucket, enters the BYOK concurrency gate, marks the job processing, and races the review use case against the worker abort signal. Rate-limit errors are classified so the queue can delay until bucket reset. BYOK slots are released in `finally`.

`RunCodeReviewAutomationUseCase` maps the webhook payload into a unified review strategy input. It filters unsupported actions, skips merged PRs, resolves missing PRs for GitHub comments, substitutes the GitLab MR author for license validation, and forwards organization/team, repository, PR, platform, command, and abort-signal data.

`CodeReviewPipelineStrategy` then builds the staged pipeline:

- Shared early stages: prerequisites, new-commit validation, config resolution, review-engine selection, config validation, changed-file fetch, external context load, and initial comment/status.
- EE/legacy branch: file context gate, cross-file context collection, Kody fine tuning, PR-level legacy review, and file analysis.
- Agent branch: business-logic validation, sandbox creation, and agent review.
- Shared post stages: PR-level comments, committable suggestion validation, file comments, aggregation, summary update, and optional request changes or approval.

The agent branch is the main modern path. `CreateSandboxStage` clones the repo into E2B or local sandbox when possible. `AgentReviewStage` runs the orchestrator with changed files, rules, memories, PR metadata, optional call graph, provider token, and sandbox tools. Findings are normalized, snapped to valid diff lines, deduplicated, severity-filtered, formatted, and split into file-level and PR-level suggestions. Downstream stages post comments, persist results, update summaries, and optionally request changes on critical findings or approve clean PRs.

The CLI path starts in `apps/cli/src/features/review/command.ts`. It gathers a local diff, enriches it with optional context files, supports authenticated and trial modes, falls back from invalid personal credentials to team-key or trial flows when allowed, and can output terminal, JSON, markdown, prompt-only, agent envelope, or selected fields. The server-side CLI pipeline reuses `CreateSandboxStage` and `AgentReviewStage`, then formats results through `CliInputConverter`.

## Architecture

The repository is a large monorepo with product apps (`apps/api`, `apps/web`, `apps/webhooks`, `apps/worker`, `apps/cli`) and shared libraries. The code review execution surface lives mostly in `libs/code-review`, `libs/ee/automation`, `libs/cli-review`, `libs/platform`, `libs/sandbox`, `libs/core/workflow`, and selected common/config utilities.

Provider integration is abstracted behind `ICodeManagementService` and `CodeManagementService`. The facade dispatches to platform services for PR files, commits, repository content, comments, reactions, summaries, approvals, request-changes, clone params, review comments, and issue comments. Platform-specific adapters implement the GitHub, GitLab, Bitbucket Cloud/Data Center, Azure Repos, and Forgejo details.

The pipeline framework uses stages with shared context. `PipelineExecutor` catches stage failures, records `PipelineError` objects with severity, and continues unless a stage explicitly skips/stops the pipeline. This lets auxiliary stages fail partially while the review still posts useful findings.

The agent layer has a review orchestrator, concrete agents, a base provider, and an agent loop. The base provider builds prompts and budgets. The agent loop handles tools, model calls, provider options, timeouts, context compression, coverage recovery, second-chance/synthesis passes, verifier passes, and structured result repair.

Sandboxing has E2B and local providers. E2B clones with token headers in environment variables, blocks push URLs, supports proxy setup, and exposes remote grep/read/list/exec tools. Local sandbox disables Git hooks, uses `execFile` for clone operations, validates paths, blocks symlink escapes for reads, and whitelists read-only tool programs for agent `exec`.

## Design Choices

Kodus treats review eligibility as a sequence of cheap gates before expensive model calls. It checks license/permissions/BYOK readiness, ignored users, centralized-config source repos, new commits, merge-only commits, cadence, manual versus automatic modes, ignored PR titles, branch rules, draft state, ignored files, and file-count limits.

Configuration is hierarchical. `CodeBaseConfigService` merges defaults, global/team settings, repository settings, repository file config, directory settings, and directory file config. Kody rules are filtered by repository/directory. The docs describe web and file config inheritance; the implementation also has `kodusConfigFileOverridesWebPreferences`, whose default is false, so file precedence is configurable rather than unconditional.

Model/cost control is first-class. BYOK docs and code support main and fallback models, provider/model/baseURL mapping, provider-specific reasoning options, OpenRouter routing, custom JSON provider options, internal fallback models, token usage tracking, and per-key concurrency limits. The workflow-level BYOK concurrency gate defers jobs via outbox instead of letting all jobs compete inside the LLM call.

The agent prompt is intentionally skeptical and tool-oriented. It instructs agents to inspect actual definitions/usages, verify external APIs with docs/tools, avoid signature claims without grep/definition evidence, and anchor root causes in changed lines.

Noise reduction is layered after generation. Findings must map to changed files, Kody-rule findings must carry valid rule UUIDs, line ranges are snapped to diff anchors, severity is reclassified, severity filters are reapplied, Kody Rules can bypass normal filters unless explicitly configured, duplicates are removed, and formatting is normalized before posting.

Failure handling usually favors useful partial output. Business-logic validation has `errorSeverity = partial`. Sandbox creation failure falls back to self-contained review. The agent orchestrator returns per-agent failures. The pipeline records partial and critical errors separately. Some verifier parse failures keep findings rather than dropping them, favoring recall over precision.

## Strengths

- The staged pipeline is a strong blueprint for production agent review: cheap gates first, expensive context later, posting and persistence last.
- BYOK controls are unusually practical: fallback models, provider options, OpenRouter routing, explicit concurrency, queue deferral, and token/cost telemetry.
- The agent loop has real guardrails: timeout wrappers, parent abort signal composition, max-step budgets, prompt chunking, recursion guards, context compression, coverage recovery, evidence-based verification, and structured result repair.
- Suggestion posting is provider-aware and not just text output. The system handles inline comments, PR-level comments, reactions/status, summaries, approvals, request-changes, and implemented-suggestion tracking.
- Custom rules are treated as policy objects, not plain prose. Kody-rule findings must map to known rule UUIDs, can carry configured severity, can link back to the rule, and have deterministic deduplication.
- Committable suggestions are guarded by complexity thresholds, patch application, syntax validation, and LLM validation before enabling GitHub apply buttons.
- The CLI is agent-friendly. `--prompt-only`, `--fields`, JSON output, `--fail-on`, no-changes envelopes, and auth fallback make it useful inside coding-agent loops.
- Tests cover meaningful failure modes: abort-signal leaks, rate-limit gates, pipeline stage order, branch matching, changed-file filtering, agent recursion, Kody-rule severity, sandbox lease behavior, platform adapters, and CLI output/filtering.

## Weaknesses

- The product surface is large and hard to extract. Many useful pieces depend on NestJS services, repositories, organization/team config, PostHog, queues, platform integrations, E2B, and database-backed state.
- There is visible docs/code drift. Examples include documented file limits versus code limits, unconditional `kodus-config.yml` override language versus configurable override behavior, schema/default suggestion count mismatches, and comments about verification in fast mode that do not fully match the `skipHeavyPasses` condition.
- The runtime path reviewed for repository `kodus-config.yml` parsing strips unknown keys and merges config but did not obviously call the Ajv validator helper. Invalid-config skipping appears weaker in code than in docs unless validation happened earlier at save time.
- `RunCodeReviewAutomationUseCase` catches top-level errors and logs them without rethrowing. That can let the job processor mark a job completed even when early automation failed before the pipeline/check observer finalized a failure.
- Some legacy/agent boundaries look stale. `CollectCrossFileContextStage` expects a sandbox, but sandbox creation is in the agent branch after the EE branch. Legacy cross-file analysis also has early returns saying agents now handle it via tools.
- Agent failure policy is mixed. Per-agent failures can be recorded as critical or partial, but a thrown orchestrator error is caught by `AgentReviewStage` and converted to empty results. That improves availability but can hide a broken review unless observers/checks surface the error clearly.
- Several fallbacks are fail-open for recall. If verification parsing fails, findings may be kept. If validation or posting fails, comments can degrade to non-committable or empty outputs. This is reasonable for PR assistants but needs explicit policy in stricter gatekeeping.
- E2B tool commands are shell-string based in several places. Many paths are quoted or validated, and the sandbox is isolated, but the pattern should be treated as a security-sensitive surface. The local provider is more defensive with `execFile`, whitelists, and path checks.

## Ideas To Steal

- Use a typed, stage-based review context with explicit skip/stop/status fields and per-stage error severities.
- Add a cheap rate-limit preflight before expensive LLM work, then classify observed provider errors into smart retry delays.
- Gate BYOK concurrency by organization, provider, hashed key, baseURL, and model; defer jobs through a durable outbox instead of queueing inside the model client.
- Resolve review config before fetching full file content, using metadata first to choose repository/directory settings and filters.
- Separate business-logic validation outcome from pipeline skip status so optional validation cannot abort the rest of review.
- Make rules first-class records with UUIDs, severity, scope, links, and deterministic deduplication rather than plain prompt text.
- Require generated findings to map back to changed files and valid diff lines before posting inline comments.
- Keep an evidence/coverage ledger for agent review and use verifier passes to drop speculative, pre-existing, style-only, or ungrounded findings.
- Offer compact CLI modes for agents: structured JSON, field masks, prompt-only output, and `--fail-on` thresholds.
- Validate "apply this suggestion" separately from "comment this suggestion" so unsafe edits can still be surfaced as normal advice.

## Do Not Copy

- Do not copy the whole monorepo architecture for a lab system. The useful patterns can be much smaller than the product.
- Do not carry forward the stale dual-path review logic without a clear ownership boundary between legacy and agent review.
- Do not rely on fail-open verifier behavior for blocking gates without a policy knob that can switch to fail-closed.
- Do not build agent tools around unrestricted shell strings. If local execution is required, prefer `execFile`, path normalization, read-only command allowlists, output caps, and no hook execution.
- Do not let docs, schemas, defaults, and runtime behavior drift. Error-prevention tools need self-consistent policy because users treat review comments as authority.
- Do not swallow top-level automation errors unless the job/check state records a visible failure.

## Fit For Agentic Coding Lab

This repo is a high-value pattern source for the lab's error-prevention work. The best adaptation is not a clone, but a smaller reviewer architecture with the same control planes: eligibility gates, context budgets, rule/memory injection, sandboxed tools, provider-aware posting, severity filters, verification passes, and deterministic CLI output.

For a lab implementation, the most portable subset is:

- A local/CI review command that collects diffs, filters large/noisy files, and emits JSON plus `--fail-on` behavior.
- A pipeline context with stages for config, changed files, sandbox/tools, agent review, verifier, dedup/filter, and output.
- A rules layer that requires stable rule IDs and explicit severity.
- A verifier/evidence pass that drops ungrounded findings before they reach the developer.
- A cost gate around model/provider configuration, with max input tokens and concurrency controls.

The less portable pieces are multi-tenant organization/team data, full provider adapters, billing/licensing, web settings UI, and the historical EE/legacy review path.

## Reviewed Paths

- `README.md`, `docs/README.md`, and English docs under `docs/how_to_use/en/code_review`, `docs/how_to_use/en/cli`, `docs/how_to_use/en/byok.mdx`, and `docs/how_to_use/en/security/data_usage.mdx`.
- Config/default paths: `default-kodus-config.yml`, `kodus-config.yml`, `libs/common/schemas/codereview.json`, `libs/common/utils/validateCodeReviewConfigFile.ts`, and `libs/ee/codeBase/codeBaseConfig.service.ts`.
- Workflow and pipeline paths: `libs/core/workflow/application/use-cases/enqueue-code-review-job.use-case.ts`, `libs/code-review/workflow/code-review-job-processor.service.ts`, `libs/ee/automation/runCodeReview.use-case.ts`, `libs/code-review/pipeline/strategy/code-review-pipeline.strategy.ts`, `libs/core/infrastructure/pipeline/services/pipeline-executor.service.ts`, and major stages under `libs/code-review/pipeline/stages`.
- Agent paths: `libs/code-review/infrastructure/agents/review-orchestrator.service.ts`, `libs/code-review/infrastructure/agents/base-code-review-agent.provider.ts`, `libs/code-review/infrastructure/agents/llm/agent-loop.ts`, `libs/code-review/infrastructure/agents/llm/agent-tools.factory.ts`, `libs/code-review/infrastructure/agents/llm/byok-to-vercel.ts`, and formatting/dedup/severity helpers used from `AgentReviewStage`.
- Git provider paths: `libs/platform/infrastructure/webhooks/*`, `libs/platform/infrastructure/adapters/services/codeManagement.service.ts`, provider services for GitHub, GitLab, Bitbucket, Azure Repos, and Forgejo, and the shared `ICodeManagementService` contract.
- CLI paths: `apps/cli/src/features/review/command.ts`, `apps/cli/src/services/review.service.ts`, `apps/cli/src/services/review-file-filter.ts`, `apps/cli/src/services/review-config-builder.ts`, `apps/cli/src/services/review-auth-fallback.ts`, `libs/cli-review/application/use-cases/execute-cli-review.use-case.ts`, `libs/cli-review/workflow/cli-review-job-processor.service.ts`, `libs/cli-review/pipeline/strategy/cli-review-pipeline.strategy.ts`, and `libs/cli-review/infrastructure/converters/cli-input.converter.ts`.
- Sandbox/failure paths: `libs/sandbox/infrastructure/providers/e2b-sandbox.service.ts`, `libs/sandbox/infrastructure/providers/local-sandbox.service.ts`, `libs/sandbox/infrastructure/services/sandbox-lease-manager.service.ts`, `libs/code-review/workflow/byok-concurrency-gate.service.ts`, `libs/core/workflow/domain/errors/classify-github-error.ts`, `libs/core/workflow/domain/errors/rate-limit.error.ts`, and `libs/core/workflow/infrastructure/abort-signal-race.ts`.
- Representative tests: code review job signal/rate-limit specs, pipeline strategy specs, agent review specs, base agent recursion specs, fetch/validate suggestion specs, branch review specs, platform service/webhook specs, sandbox lease specs, BYOK specs, and CLI review/filter/output specs.

## Excluded Paths

- `apps/web/**` and most `test/unit/web/**`: UI/settings behavior only. I used docs and config/service code for review semantics rather than web form rendering.
- Non-English duplicated documentation under `docs/how_to_use/pt-br/**`, `docs/how_to_use/es/**`, `docs/how_to_use/ja/**`, and `docs/how_to_use/zh/**`: English docs were reviewed as canonical content to avoid double-counting translations.
- Generated docs/snippets and snapshots such as `docs/_snippets/env-vars-generated.mdx`, generated ignore-path data, and release snapshot files: useful as inputs/defaults but not core execution logic.
- Binary/static assets such as logos, favicons, images, and docs media: no relevance to code review execution or error-prevention design.
- Dependency and build artifacts such as `yarn.lock`, package lockfiles, Docker deployment files, and generic release packaging: excluded unless they directly affected review execution.
- `docs-internal/**`, OpenAPI/Postman artifacts, and internal planning material: not required to understand the shipped review path.
- General product features outside code review, such as billing pages, onboarding UI, SSO, dashboards, analytics ingestion, and cockpit views: reviewed only where they intersected workflow state, permissions, telemetry, or CLI review.
