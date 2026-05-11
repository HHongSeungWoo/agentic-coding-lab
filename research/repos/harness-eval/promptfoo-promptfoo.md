# promptfoo/promptfoo

- URL: https://github.com/promptfoo/promptfoo
- Category: harness-eval
- Stars snapshot: 21,130 (GitHub REST API, captured 2026-05-11)
- Reviewed commit: 6a496fa6014df09840fae85e39a5124bf967b3be
- Reviewed at: 2026-05-11
- Status: reviewed
- Scope fit: in-scope
- Verdict: High-signal evaluation and red-team framework for LLM apps and coding agents. Most useful reusable patterns are declarative eval configs, provider abstraction, assertion handlers, trace-aware grading, red-team plugin generation, coding-agent threat plugins, CI output, and local result storage.

## Why It Matters

Promptfoo is a mature open-source CLI/library for LLM evaluation and red teaming. It matters for agentic coding because coding-agent behavior needs regression tests, not only ad hoc human review. Promptfoo provides patterns for running prompt/model/provider matrices, applying assertions, grading outputs, tracing agent tool use, and generating adversarial tests.

The repo is especially relevant because it includes coding-agent red-team categories such as repository prompt injection, terminal output injection, secret reads, sandbox escape, network egress bypass, delayed CI exfiltration, generated vulnerabilities, automation poisoning, steganographic exfiltration, and verifier sabotage.

## What It Is

Promptfoo is a Node.js package with a CLI (`promptfoo` / `pf`), eval engine, web viewer, red-team generator, provider adapters, assertion system, MCP server, code scanning action, local database models, tracing, and many examples.

Users write `promptfooconfig.yaml` files defining prompts, providers, tests, assertions, redteam settings, and output paths. `promptfoo eval` resolves config, loads providers, renders prompts with variables, calls providers, runs assertions, stores results, writes outputs, and can share or view results.

## Research Themes

- Token efficiency: Conditional. The framework measures token usage and cost, but it is not primarily a context compression system.
- Context control: Strong for eval. It formalizes prompts, vars, providers, test cases, scenarios, and outputs rather than leaving context implicit.
- Sub-agent / multi-agent: Moderate. It supports agent providers, Claude Agent SDK, MCP targets, and trace-aware assertions, but is not itself a general multi-agent orchestrator.
- Domain-specific workflow: Strong. Red-team plugins and examples cover RAG, agents, MCP, code scanning, providers, and coding-agent threats.
- Error prevention: Very strong. Assertions, red-team plugins, CI integration, code scanning, and verifier-sabotage tests directly target regressions and unsafe behavior.
- Self-learning / memory: Conditional. It stores eval history and traces, but does not implement adaptive long-term memory.
- Popular skills: Not a skill repo. Relevant reusable modules are `evaluateWithSource`, `evaluator`, `assertions`, `providers`, `redteam`, `claude-agent-sdk` provider, and MCP target wrapper.

## Core Execution Path

CLI startup begins in `src/main.ts`. It configures environment files, logging, update checks, DB migrations, loads default config, creates a Commander program, and registers commands including `eval`, `init`, `view`, `mcp`, `redteam`, `generate`, `validate`, `code-scanning`, and `share`.

`promptfoo eval` runs through `src/commands/eval.ts`. It loads environment variables, resolves config paths or cloud config IDs, handles watch mode, runs migrations when writing, validates options, and calls the evaluator.

`src/evaluate.ts` loads API providers, reads tests, processes prompts, reads provider-prompt mappings, sanitizes the config for persistence, creates an Eval record, and calls `doEvaluate()` from `src/evaluator.ts`.

The evaluator renders prompts, handles conversation variables, applies provider rate limits and concurrency, calls providers, tracks token usage and latency, extracts binary data, records traces, runs assertions, handles model-graded assertions, updates metrics, and stores results.

Assertions are dispatched through `src/assertions/index.ts`. Supported checks include contains/equals/regex/json/sql/xml/html, latency/cost, moderation, LLM rubric, RAG metrics, tool-call checks, trajectory checks, trace checks, Python/JavaScript/Ruby custom checks, webhook, and red-team assertions.

Red-team generation lives under `src/redteam/`. It builds test cases from plugins and strategies, supports remote generation when allowed, and can wrap MCP providers for tool-aware prompt materialization.

## Architecture

The architecture is modular:

- `src/main.ts`: CLI command registration and top-level error handling.
- `src/commands/`: command implementations for eval, init, validate, generate, redteam, MCP, view, share, code scanning, and utilities.
- `src/evaluate.ts` and `src/evaluator.ts`: runtime eval construction and execution engine.
- `src/assertions/`: assertion handlers and grading logic.
- `src/providers/`: provider registry and adapters for many LLM APIs, local models, HTTP, browser, Docker, MCP, Claude Agent SDK, OpenCode SDK, and more.
- `src/redteam/`: vulnerability plugins, strategies, grading, materialization, report generation, and coding-agent threat definitions.
- `src/tracing/`: OpenTelemetry and trace-aware grading infrastructure.
- `src/app/`: web UI.
- `examples/`: large corpus of provider and scenario examples.
- `code-scan-action/`: GitHub Action for code scanning.
- `docs/agents/`: internal agent guidance for development of this repo.

## Design Choices

The main design choice is declarative eval configuration with pluggable providers and assertions. This makes tests reusable and CI-friendly.

Provider abstraction is broad. A provider can be a hosted model, local model, HTTP endpoint, package function, MCP target, browser target, or Claude Agent SDK session. This is important for coding agents because the target may be a tool-using agent rather than a chat completion API.

Assertions are composable and can be model-graded, deterministic, trace-aware, or custom-code-based. The evaluator groups model-graded assertions by provider when possible to reduce local model reload overhead.

The red-team system separates plugins from strategies. Plugins define vulnerability goals; strategies mutate or deliver attacks. Coding-agent plugins get default exclusions for canary-breaking strategies, which shows attention to evaluation validity.

The Claude Agent SDK provider defaults to read-only tools when a working directory is provided, captures tool calls, emits tool spans, derives skill calls, supports MCP config transformation, and warns users about side effects when broader permissions are enabled.

## Strengths

Promptfoo has a strong execution core. It manages concurrency, rate limits, caching, token usage, progress reporting, provider resolution, serial conversation variables, and graceful shutdown.

The assertion catalog is broad enough for agent workflows. Tool trajectories, trace spans, skill usage, JSON validity, SQL checks, cost, latency, and LLM rubrics are all useful for coding-agent regression.

The coding-agent red-team taxonomy is directly reusable. It names practical threats that local coding-agent harnesses should test.

The framework handles both normal evals and adversarial red-team generation, so the same result pipeline can compare baseline behavior and security behavior.

The examples directory is huge and gives many concrete config patterns for providers and use cases.

## Weaknesses

The repository is large and complex. Adopting it as a dependency is easier than reimplementing it, but understanding all behavior requires careful module-level review.

Many advanced capabilities depend on external providers, cloud features, or remote generation. Local-only users need to disable or configure these paths deliberately.

Red-team generation can create false positives or false negatives if target labels, inject variables, provider wrappers, or graders are misconfigured.

Promptfoo evaluates through configured targets; it does not automatically understand a local coding workflow unless the harness is wrapped as a provider with clear inputs, outputs, permissions, and traces.

## Ideas To Steal

Define a coding-agent red-team plugin taxonomy for local harnesses.

Represent agent evals as config: prompts, providers, tests, vars, assertions, outputs.

Add trace-aware assertions for tool use, tool sequence, tool args, error spans, and duration.

Capture skill invocation as a first-class metric when evaluating skill-based agents.

Use provider wrappers to adapt MCP or agent SDK targets into the same eval pipeline.

Separate deterministic assertions from model-graded assertions and record their token/cost separately.

Store eval results locally and make them viewable, diffable, and exportable for CI.

## Do Not Copy

Do not import the whole framework if a small local harness only needs a few checks. The full system is powerful but heavy.

Do not run red-team prompts against real credentials, broad filesystem access, or unrestricted network access.

Do not trust model-graded assertions without calibration. Use deterministic checks for critical safety properties where possible.

Do not let generated adversarial tests become hidden policy. Keep test cases reviewable.

Do not rely on default provider behavior for coding-agent sandboxing; explicitly configure working dirs, tools, permissions, and cleanup.

## Fit For Agentic Coding Lab

Fit is in-scope and strong. Promptfoo is one of the best references for harness/eval and error-prevention research.

Agentic Coding Lab should adapt the red-team taxonomy, trace-aware assertions, provider-wrapper idea, and local eval result model. It should not duplicate Promptfoo wholesale unless the project intends to become an eval framework.

## Reviewed Paths

- `/tmp/myagents-research/promptfoo-promptfoo/README.md`
- `/tmp/myagents-research/promptfoo-promptfoo/package.json`
- `/tmp/myagents-research/promptfoo-promptfoo/src/main.ts`
- `/tmp/myagents-research/promptfoo-promptfoo/src/commands/eval.ts`
- `/tmp/myagents-research/promptfoo-promptfoo/src/commands/mcp/index.ts`
- `/tmp/myagents-research/promptfoo-promptfoo/src/evaluate.ts`
- `/tmp/myagents-research/promptfoo-promptfoo/src/evaluator.ts`
- `/tmp/myagents-research/promptfoo-promptfoo/src/assertions/index.ts`
- `/tmp/myagents-research/promptfoo-promptfoo/src/providers/index.ts`
- `/tmp/myagents-research/promptfoo-promptfoo/src/providers/claude-agent-sdk.ts`
- `/tmp/myagents-research/promptfoo-promptfoo/src/redteam/index.ts`
- `/tmp/myagents-research/promptfoo-promptfoo/src/redteam/constants/codingAgents.ts`
- `/tmp/myagents-research/promptfoo-promptfoo/src/redteam/plugins/index.ts`
- `/tmp/myagents-research/promptfoo-promptfoo/src/redteam/mcpTargetProvider.ts`
- `/tmp/myagents-research/promptfoo-promptfoo/examples/anthropic/claude-code-session/README.md`
- `/tmp/myagents-research/promptfoo-promptfoo/examples/`
- `/tmp/myagents-research/promptfoo-promptfoo/docs/agents/`
- `/tmp/myagents-research/promptfoo-promptfoo/code-scan-action/`

## Excluded Paths

- `/tmp/myagents-research/promptfoo-promptfoo/.git/`: VCS internals; commit captured separately.
- `/tmp/myagents-research/promptfoo-promptfoo/src/app/`: web UI implementation; reviewed only as a result viewer surface.
- `/tmp/myagents-research/promptfoo-promptfoo/site/`: documentation site build, not core eval runtime.
- `/tmp/myagents-research/promptfoo-promptfoo/examples/*`: directory sampled; all 1000+ example files not reviewed line-by-line.
- Individual provider adapters beyond `providers/index.ts` and `claude-agent-sdk.ts`: provider architecture reviewed, not every API implementation.
- Individual red-team plugins beyond registry and coding-agent constants: taxonomy reviewed; plugin-by-plugin prompts are separate work.
- Generated/build/dependency files such as `package-lock.json`: not reviewed line-by-line.
