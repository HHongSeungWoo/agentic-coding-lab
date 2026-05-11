# mastra-ai/mastra

- URL: https://github.com/mastra-ai/mastra
- Category: harness-eval
- Stars snapshot: 23,771 (GitHub REST API, captured 2026-05-11)
- Reviewed commit: d4e92831b7033a37552b6deb7438b494f29e3acc
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: conditional
- Verdict: Broad TypeScript agent framework with unusually integrated eval, workflow, memory, tool-validation, and observability primitives. It is not a standalone coding-agent harness, but its trace-backed trajectory scoring, scorer workflows, HITL tool approval, and memory processors are strong patterns to adapt.

## Why It Matters

Mastra matters for agentic coding research because it treats evals as part of the agent runtime rather than a separate report generator. Agents, workflows, tools, memory, observability, and scorers all share runtime context, traces, storage, and spans. That makes it a useful reference for evaluating actual tool-using behavior instead of only final text output.

The most relevant pieces are the eval runner, scorer abstraction, trajectory extraction, typed workflows, durable agent steps, runtime tool validation, memory processors, and observability span model. These are the same surfaces where coding agents usually fail: wrong tool call, hidden tool execution, bad retry loop, missing verification, lost state after suspension, leaked context, or unreviewable scoring.

Fit is conditional because the repository is a full application framework with docs, playground UI, providers, stores, deployers, and integrations. Agentic Coding Lab should mine the architecture, not adopt the whole stack as a harness.

## What It Is

Mastra is a TypeScript monorepo for building AI applications. The root README describes agents, workflows, memory, MCP support, observability, evals, model routing, and human-in-the-loop flows. The core runtime lives mostly under `packages/core`, scorer implementations under `packages/evals`, memory under `packages/memory`, observability under `observability/`, workflow adapters under `workflows/`, and runnable examples under `examples/`.

An agent can generate or stream with tools, subagents, workflows, memory, processors, scorers, channels, browser context, and workspace or skill tooling. Workflows model typed execution graphs with steps, branches, loops, parallelism, state, suspend/resume, and nested agent/tool/processor calls. Evals can run against agents or workflows, extract trajectories from traces or outputs, execute scorer pipelines, emit observability scores, and persist legacy score records when storage is configured.

## Research Themes

- Token efficiency: Strong runtime patterns. `prepareRun` can trim scorer input/output before LLM judging, memory processors load only selected history, semantic recall narrows retrieval, and observational memory compresses long histories into observations with buffering and reflection thresholds.
- Context control: Strong. Agents resolve thread/resource memory from reserved request-context keys, processors run in a fixed order, tools and workflow steps validate schemas, and `activeTools` enforcement is tested at execution time rather than only in model instructions.
- Sub-agent / multi-agent: Moderate. Agents can expose subagents as tools and workflows can orchestrate agents, tools, and processors, but the reviewed eval surface is more about single target behavior and trace scoring than collaborative multi-agent protocols.
- Domain-specific workflow: Strong. Typed workflow steps, suspend/resume snapshots, durable agent workflows, Inngest and Temporal adapters, state readers, and examples provide a reusable model for long-running agent workflows with human checkpoints.
- Error prevention: Strong. Tool input/output/request-context validation, approval and suspension schemas, FGA checks, guardrail processors, active-tool enforcement tests, trajectory blacklists, tool-failure analysis, and sensitive-data filtering all address concrete agent failure modes.
- Self-learning / memory: Strong. Working memory, message history, semantic recall, and observational memory provide layered memory. Observational memory adds observer and reflector runners that convert raw turns into durable observations.
- Popular skills: Conditional. This is not a skills repository. The reusable "skill-like" pieces are workspace skill tools, processors, workflow steps, scorer definitions, and tool wrappers rather than packaged coding skills.

## Core Execution Path

Agent execution starts in `packages/core/src/agent/agent.ts`. `generate()` and `stream()` validate request context, enforce FGA when configured, merge default options, resolve the model, normalize structured-output settings, and enter the private execution path.

The private execution path resolves memory thread and resource information, gives reserved request-context keys precedence, creates an `AGENT_RUN` span, injects browser context when present, prepares capabilities, and starts an internal prepare-stream workflow. The loop layer preserves processor state across iterations so input processors, output processors, and memory processors can coordinate.

Tools are assembled from assigned tools, memory tools, toolsets, client tools, subagent tools, workflow tools, workspace tools, skill tools, channel tools, and browser tools. `formatTools` sanitizes names and detects collisions. The tool builder creates `TOOL_CALL` or `MCP_TOOL_CALL` spans, validates input before execution, validates resume/suspend data, validates output, records success or failure, and returns structured validation errors where possible.

On finish, the agent updates message lists, persists memory, creates thread titles when configured, runs live scorers asynchronously, and ends the agent span. Live scorers build scorer input from stored messages and output from response messages rather than only the visible text returned to the caller.

Eval execution starts in `packages/core/src/evals/run/index.ts`. `runEvals()` validates data and scorers, executes an agent or workflow target with target scorers disabled, collects raw output and scorer data, runs agent/workflow/trajectory scorers, and supports concurrency through `p-map`. For trajectory scorers it first tries to reconstruct behavior from observability traces in storage, then falls back to agent tool invocations or workflow step results. Scores are emitted through observability when available and can also be saved to the older storage path.

## Architecture

The architecture is split into runtime layers:

- `packages/core/src/agent/`: agent construction, generation/streaming, tool conversion, durable agent flows, loop integration, processors, subagents, scorers, and tests.
- `packages/core/src/workflows/`: workflow definition, typed steps, execution engine contracts, state, snapshots, suspend/resume, nested workflows, and step adapters for agents, tools, and processors.
- `packages/core/src/tools/`: `createTool`, runtime validation, tool builder, type guards, MCP metadata, approval and suspension support, and structured tool errors.
- `packages/core/src/evals/`: scorer base abstraction, eval runner, trace scoring workflow, trajectory extraction, and scorer run metadata.
- `packages/evals/src/scorers/`: built-in scorer implementations including deterministic trajectory accuracy and multidimensional trajectory analysis.
- `packages/core/src/memory/` and `packages/memory/src/`: abstract memory integration plus concrete memory, semantic recall, working memory, message-history processors, and observational memory.
- `packages/core/src/observability/` and `observability/mastra/`: tracing context propagation, span types, span processors, trace storage, score linking, exporter bridges, metrics, and sensitive-data filtering.
- `workflows/inngest/` and `workflows/temporal/`: workflow engine adapters with tests that expose adapter-specific persistence and resume behavior.
- `docs/src/content/en/docs/` and `docs/src/content/en/reference/`: user-facing descriptions for evals, workflows, memory, observability, agents, tools, and processors.
- `examples/agent/` and `examples/durable-agents/`: runnable examples for eval seeding, observability scores, processors, workflows, MCP, durable agents, and research-agent flows.

## Design Choices

Scorers are modeled as small workflows. `createScorer()` builds a scorer with `preprocess`, `analyze`, `generateScore`, and `generateReason` style stages. Stages can be normal functions or prompt-object LLM judges. Running a scorer creates `SCORER_RUN` and `SCORER_STEP` spans, so eval logic becomes observable in the same trace system as agents and tools.

Trajectory scoring is trace-first. `extractTrajectoryFromTrace()` builds a tree from observability spans and filters scorer/internal/noisy spans. It converts tool calls, MCP calls, model generations, agent runs, workflow runs, workflow steps, conditionals, parallel blocks, loops, sleeps, and processor runs into trajectory steps. Fallback extraction from message tool invocations and workflow step results keeps evals usable without full trace storage.

Workflows are the shared orchestration substrate. Agent steps stream nested agent chunks, tool steps validate schemas, processor steps model guardrail and memory phases, and durable agent steps can suspend for approval or runtime tool suspension. This gives Mastra one abstraction for app workflows, eval scorer pipelines, and internal agent loops.

Memory is attached through processors rather than only through prompt assembly. The abstract memory layer supplies input processors for working memory, message history, and semantic recall, plus output processors for saving and embedding messages. Observational memory adds its own lifecycle with observation turns, buffering, activation, reflection, and injected context messages.

Security controls are mostly runtime-adjacent rather than separate policy files. Tools validate schemas and request context, agents can enforce FGA, processors can block or redact, active tool filtering is enforced before execution, and observability can redact sensitive span data. The design gives several hooks for safer coding agents, but the final policy still depends on the application's tool and runtime permissions.

## Strengths

Trace-backed evals are the biggest strength. The eval runner can score not just final output but the path the agent or workflow took, including nested spans and fallback extraction when traces are unavailable.

The scorer abstraction is composable. A deterministic check, an LLM judge, and a final score normalization step can all live in one observable scorer pipeline with `prepareRun` trimming.

Tool execution has serious guardrails. Input, output, resume data, suspend data, and request context are validated around execution. Approval and suspension are first-class, and tests cover active-tool enforcement so hidden model-selected tools are not executed.

Workflows provide a practical long-running-agent model. Typed steps, state, suspend/resume, snapshots, nested workflows, and adapter tests map well onto coding-agent workflows that require review, verification, or resumable background work.

Memory is deeper than a chat-history buffer. Working memory, semantic recall, and observational memory show how to combine short-term history, retrieved context, and compressed long-term observations.

Observability is integrated with runtime behavior. Spans carry entity identifiers, inputs, outputs, errors, request context, and tags; score traces can link scorer results back to spans; sensitive-data span processors provide a concrete redaction pattern.

## Weaknesses

Mastra is a broad agent application framework, not a narrow harness. Pulling it into a coding-agent lab would bring many unrelated concerns such as playground UI, provider integrations, deployers, store adapters, docs infrastructure, and product ergonomics.

The built-in evals are strong for agent behavior but not a complete coding-agent benchmark harness. They do not by themselves create repos, isolate sandboxes, run tests, collect patches, or compare against SWE-bench style ground truth.

Trace-backed trajectory scoring is only as good as the configured storage and span coverage. Without storage or observability, evals fall back to less complete message or workflow result extraction.

Some score persistence still has a legacy path alongside observability score emission. That is a migration smell to avoid in a smaller harness.

Observational memory includes powerful compression but has deployment caveats. The code uses in-process locks for resource/thread observation work, and comments note that distributed deployments need external locking or eventual-consistency handling.

Workflow adapters have real edge cases. Inngest tests and comments document differences around restart, nested resume, snapshot persistence, and request context across suspend/resume. A coding harness should treat adapter parity as a test target.

Many guardrails are processor or model based. They are useful defense-in-depth, but they should not replace deterministic sandbox permissions, filesystem policy, network policy, or secret handling in a coding-agent environment.

## Ideas To Steal

Represent eval scorers as observable mini-workflows rather than one opaque grading function.

Use `prepareRun`-style hooks so evals can trim inputs, remove sensitive context, or normalize outputs before any LLM judge sees them.

Make trajectories first-class objects with nested children, step types, inputs, outputs, duration, status, tool names, and failure metadata.

Prefer trace-backed trajectory extraction, but keep fallback extraction from messages and workflow step results so local tests still work without a full observability stack.

Add multidimensional trajectory scoring for expected steps, allowed ordering, redundant actions, token and duration budgets, forbidden tool paths, and repeated tool failures.

Enforce active tools at execution time. Prompting the model not to use a tool is weaker than filtering the actual tool registry before dispatch.

Treat approval and suspension as runtime states with schemas and snapshots. Coding agents need explicit human-review checkpoints for high-impact file, network, credential, or deployment actions.

Use span output processors for sensitive-data filtering and make score results link back to the exact target span being judged.

## Do Not Copy

Do not copy the full framework when the goal is a coding-agent harness. The useful parts are eval, trace, tool, workflow, and memory patterns.

Do not rely on LLM guardrails as the only safety layer. Coding agents still need deterministic runtime isolation, explicit allowed tools, and secret redaction.

Do not adopt in-process memory coordination for distributed runs without an external lock or an explicit eventual-consistency model.

Do not keep both legacy score storage and new observability score emission in a small system. Pick one score record model and migrate early.

Do not assume workflow engine adapters behave identically. Snapshot, resume, and request-context behavior must be covered by adapter conformance tests.

Do not let dynamic tool sources grow without a permission model. Mastra can merge many tool origins; a coding harness should keep tool provenance and authorization visible.

## Fit For Agentic Coding Lab

Fit is conditional and high-value. Mastra should not become the base runtime for Agentic Coding Lab unless the project explicitly wants a full TypeScript agent framework. It is more useful as a design reference for eval architecture.

The strongest direct adaptations are a scorer workflow DSL, trace-backed trajectory schema, run-eval helper for agents and workflows, tool validation wrapper, approval/suspend runtime state, sensitive span redaction, and memory processor ordering. For coding-agent benchmarking, these should be combined with separate sandbox, repository reset, patch extraction, deterministic verifier, and dataset-runner components.

## Reviewed Paths

- `/tmp/myagents-research/mastra-ai-mastra/README.md`
- `/tmp/myagents-research/mastra-ai-mastra/package.json`
- `/tmp/myagents-research/mastra-ai-mastra/docs/src/content/en/docs/evals/`
- `/tmp/myagents-research/mastra-ai-mastra/docs/src/content/en/reference/evals/`
- `/tmp/myagents-research/mastra-ai-mastra/docs/src/content/en/docs/agents/`
- `/tmp/myagents-research/mastra-ai-mastra/docs/src/content/en/reference/processors/`
- `/tmp/myagents-research/mastra-ai-mastra/docs/src/content/en/docs/workflows/`
- `/tmp/myagents-research/mastra-ai-mastra/docs/src/content/en/docs/memory/`
- `/tmp/myagents-research/mastra-ai-mastra/docs/src/content/en/docs/observability/`
- `/tmp/myagents-research/mastra-ai-mastra/packages/core/src/evals/`
- `/tmp/myagents-research/mastra-ai-mastra/packages/evals/src/scorers/`
- `/tmp/myagents-research/mastra-ai-mastra/packages/core/src/agent/`
- `/tmp/myagents-research/mastra-ai-mastra/packages/core/src/agent/durable/`
- `/tmp/myagents-research/mastra-ai-mastra/packages/core/src/agent/__tests__/`
- `/tmp/myagents-research/mastra-ai-mastra/packages/core/src/workflows/`
- `/tmp/myagents-research/mastra-ai-mastra/workflows/inngest/`
- `/tmp/myagents-research/mastra-ai-mastra/workflows/temporal/`
- `/tmp/myagents-research/mastra-ai-mastra/packages/core/src/memory/`
- `/tmp/myagents-research/mastra-ai-mastra/packages/memory/src/`
- `/tmp/myagents-research/mastra-ai-mastra/packages/core/src/tools/`
- `/tmp/myagents-research/mastra-ai-mastra/packages/core/src/observability/`
- `/tmp/myagents-research/mastra-ai-mastra/observability/mastra/`
- `/tmp/myagents-research/mastra-ai-mastra/examples/agent/`
- `/tmp/myagents-research/mastra-ai-mastra/examples/durable-agents/`

## Excluded Paths

- `/tmp/myagents-research/mastra-ai-mastra/.git/`: VCS internals; exact reviewed commit is recorded above.
- `/tmp/myagents-research/mastra-ai-mastra/packages/playground-ui/` and `/tmp/myagents-research/mastra-ai-mastra/packages/playground/`: product UI and Studio/playground implementation; not core harness, eval, memory, or tool-verification architecture.
- `/tmp/myagents-research/mastra-ai-mastra/docs/static/`, image assets, screenshots, icons, and other binary media: documentation or UI assets rather than runtime behavior.
- `/tmp/myagents-research/mastra-ai-mastra/packages/_vendored/`: vendored dependencies; useful for builds but not Mastra's design.
- Lockfiles, generated build outputs, caches, and dependency directories such as `pnpm-lock.yaml`, `node_modules/`, `dist/`, `.turbo/`, and `.mastra/`: generated or environment-specific artifacts.
- `/tmp/myagents-research/mastra-ai-mastra/ee/`: enterprise-licensed code; only open runtime references such as FGA call sites were noted.
- Provider, deployer, store, voice, channel, browser, auth, server-adapter, and client-SDK packages outside the reviewed call paths: sampled only where they connect to agent tools, memory, observability, or workflow execution.
- Documentation outside evals, agents, workflows, memory, observability, tools, and processors: product reference material unrelated to harness-eval research.
- `/tmp/myagents-research/mastra-ai-mastra/.changeset/`, `.github/`, `.husky/`, editor config, lint config, and release automation: repository maintenance rather than agent/eval architecture.
- Files touched by the reviewed commit under `packages/playground-ui/`: identified to understand the snapshot commit but excluded as UI-only.
