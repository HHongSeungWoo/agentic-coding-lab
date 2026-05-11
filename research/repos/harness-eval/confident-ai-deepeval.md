# confident-ai/deepeval

- URL: https://github.com/confident-ai/deepeval
- Category: harness-eval
- Stars snapshot: 15,312 (GitHub REST API, captured 2026-05-12 KST)
- Reviewed commit: 67450ddb8d41d8d684f80f6e80fcaa3e2572ccf3
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong harness/eval reference for pytest-native LLM and agent evals. Most reusable ideas are the test-case schema, metric result contract, trace/span-scoped metrics, dataset iterator, and agent-facing iteration skill. Do not copy the cloud-first assumptions, stateful global managers, broad framework monkeypatching, or LLM-judge default without calibration.

## Why It Matters

DeepEval is one of the most complete open-source LLM eval harnesses for agentic systems. It treats evals as unit tests: users create typed test cases or goldens, attach metrics, run them through `assert_test()`, `evaluate()`, or `deepeval test run`, and receive pass/fail results with score, threshold, reason, error, cost, and verbose logs. For coding-agent work, the important pattern is not only "metric library", but a repeatable loop: dataset -> test run -> trace capture -> metric failure -> targeted iteration.

The repository has first-class support for agent-specific evaluation surfaces: tool correctness, argument correctness, task completion, plan quality, plan adherence, step efficiency, MCP use, RAG metrics, safety metrics, multi-turn conversational metrics, local structured result files, pytest integration, and span-level component evals. It also ships a `skills/deepeval` agent skill that tells coding assistants how to add eval suites, generate datasets, run `deepeval test run`, and iterate on failures.

## What It Is

DeepEval is a Python package and CLI for evaluating LLM applications. The core objects are:

- `LLMTestCase` for single-turn input/output/reference/tool/RAG fields.
- `ConversationalTestCase` and `Turn` for multi-turn interactions.
- `Golden` and `ConversationalGolden` for reusable datasets.
- `BaseMetric` and `BaseConversationalMetric` subclasses that compute score, success, reason, and diagnostic logs.
- `Trace`, `BaseSpan`, `AgentSpan`, `LlmSpan`, `RetrieverSpan`, and `ToolSpan` for traced component-level evals.
- `assert_test()` and `evaluate()` for direct Python and pytest use.
- `deepeval test run` as a pytest wrapper that finalizes test runs and reporting.
- Confident AI cloud APIs for datasets, hosted reports, traces, and metric collections.

The project is Apache-2.0, Python 3.9+, distributed through Poetry, and exposes both a `deepeval` CLI script and a pytest plugin.

## Research Themes

- Token efficiency: Not a token-efficiency system. It does reduce wasted evaluation work through cache support, async concurrency, per-task timeouts, retry policy, local result reuse, and required-field validation. LLM-judge metrics can be expensive because many metrics generate intermediate statements/verdicts/reasons.
- Context control: Strong. Eval context is made explicit through `LLMTestCase`, `ConversationalTestCase`, `Golden`, span fields, `update_current_trace()`, `update_current_span()`, and schema-validated judge outputs. Trace-only metrics set `requires_trace=True` and receive a nested span dictionary rather than unbounded raw logs.
- Sub-agent / multi-agent: Supports multi-agent and tool-using workflows as trace trees. Agent spans include available tools and handoffs; integrations cover CrewAI, LangGraph, OpenAI Agents, Pydantic AI, Strands, Google ADK, LlamaIndex, AgentCore, OpenAI, and Anthropic. It does not orchestrate subagents itself.
- Domain-specific workflow: Very strong metric taxonomy: agentic, RAG, multi-turn, MCP, safety, non-LLM format checks, multimodal, custom `GEval`, and deterministic-ish `DAGMetric`. The bundled DeepEval skill maps app type to eval artifact templates.
- Error prevention: Pytest `assert_test()` fails builds on metric failure; missing test-case params can raise or skip; `NoMetricsError` prevents empty iterator runs; timeout and retry layers avoid hanging provider calls; local `results_folder` preserves structured run JSON for regression inspection.
- Self-learning / memory: Stores datasets, test runs, hyperparameters, prompts, traces, and hosted report links, but does not implement autonomous memory or self-learning. Confident AI can provide history and human annotation outside the local package.
- Popular skills: Includes `skills/deepeval`, with templates and references for coding assistants to create datasets, pytest evals, tracing, Confident AI reports, and iteration loops.

## Core Execution Path

The direct single-turn path starts with `LLMTestCase` plus metrics. `assert_test()` validates that a test case and compatible metrics are present, builds default async/display/error/cache configs from environment flags, calls `a_execute_test_cases()` or `execute_test_cases()`, converts each metric into `MetricData`, and raises `AssertionError` if any metric fails.

The batch path is `evaluate(test_cases=[...], metrics=[...])`. It validates types, optionally resets the global test-run manager, displays metric descriptions, executes metrics concurrently or sequentially, renders the console report, records hyperparameters/prompts, saves a temp run, optionally writes structured local result JSON, and finalizes/upload reports when not running under the CLI.

The CLI path is `deepeval test run <test_file_or_directory>`. It resets temp run/cache files, sets global flags such as cache, verbose, ignore-errors, skip-on-missing-params, and identifier, then calls `pytest.main()` with `-p deepeval`. The pytest plugin creates a test run at session start and wraps each test call in an `Observer`, so `assert_test(golden=..., metrics=[...])` can evaluate the current trace rather than a manually built test case.

The trace/dataset path is `EvaluationDataset.evals_iterator()`. It yields each `Golden`; user code calls an `@observe`-instrumented app or a framework integration; DeepEval captures trace/spans; after the iteration it builds `LLMTestCase` data from trace output, tools, contexts, and expected fields, then runs trace-level and span-level metrics. This supports both end-to-end evals and component-level evals in one test run.

Metrics are stateful objects. Each `measure()` or `a_measure()` mutates `score`, `reason`, `success`, `error`, `evaluation_cost`, and `verbose_logs`. LLM-judge metrics call provider adapters through `DeepEvalBaseLLM`, request schema-shaped output where possible, and parse JSON fallbacks. Deterministic or semi-deterministic metrics such as exact match, pattern match, JSON correctness, and tool correctness use local logic plus optional judge reasons.

## Architecture

The main package boundaries are clear:

- `deepeval/evaluate/`: public `assert_test()` and `evaluate()`, execution loops, async/sync configs, metric-data creation, console report rendering, local result store, and trace-scope assertion handling.
- `deepeval/metrics/`: metric implementations. Categories include G-Eval, DAG, RAG, agentic, MCP, safety, multi-turn, multimodal, and non-LLM checks. `BaseMetric` and `BaseConversationalMetric` define the mutation contract.
- `deepeval/test_case/`: Pydantic models and validators for single-turn, conversational, arena, tool-call, multimodal image, and MCP fields.
- `deepeval/dataset/`: goldens, file import/export, Confident AI push/pull/queue/delete, synthetic-data hooks, and `evals_iterator()`.
- `deepeval/tracing/`: contextvars, `@observe`, trace/span models, trace manager, REST/OTLP export, masking, sampling, update helpers, and offline evals.
- `deepeval/integrations/`, `deepeval/openai/`, `deepeval/anthropic/`, `deepeval/openai_agents/`: framework callbacks, OTel processors, client wrappers, and monkeypatches for capturing traces.
- `deepeval/cli/` and `deepeval/plugins/`: Typer CLI and pytest plugin.
- `skills/deepeval/`: coding-agent workflow, templates, and reference docs for creating eval suites and iteration loops.

Tests are split into `tests/test_core`, `tests/test_metrics`, `tests/test_integrations`, `tests/test_confident`, and `tests/test_docs`, with JSON schema fixtures for trace shapes and integration traces.

## Design Choices

DeepEval leans into pytest rather than inventing a new test runner. The public failure primitive is `assert_test()`, and the CLI wraps pytest while adding DeepEval-specific test-run finalization and report upload.

The test-case schema is intentionally explicit. Metrics declare required fields, and missing fields raise `MissingTestCaseParamsError` unless the user opts into skipping. This is useful for agent workflows because tool calls, expected tools, retrieval context, expected output, metadata, and MCP artifacts are all first-class fields.

Metric execution is mutable and object-oriented. This keeps metric implementations simple, but makes copying and isolation important. The async trace-metric isolation tests confirm that metric instances are copied per trace to avoid cross-test contamination.

Trace evaluation uses contextvars and a global `TraceManager`. `Observer` creates spans around sync functions, async functions, sync generators, and async generators; `trace()` creates a top-level trace context; framework integrations either call observers or translate OTel/framework events into DeepEval spans. `EvalSession` centralizes per-run trace queues and resets them atomically.

Component-level evals are span-scoped. Metrics can live on the root trace, an `@observe` span, or framework-emitted spans. Trace-required metrics receive a nested span dictionary through a private `_trace_dict` on `LLMTestCase`.

The result contract is rich enough for automation: each metric row carries name, threshold, score, reason, success, strict mode, evaluation model, error, evaluation cost, and verbose logs. Local result storage writes timestamped `test_run_*.json` files without overwriting collisions.

Cloud support is integrated but not mandatory for local assertions. Confident AI APIs power hosted datasets, reports, traces, online evals, and metric collections. Docs and CLI strongly recommend login, but local pytest evaluation can still run with model credentials and optional local result files.

## Strengths

DeepEval has unusually broad metric coverage for agentic systems: final-task metrics, plan metrics, tool correctness, argument correctness, MCP metrics, RAG metrics, safety/compliance metrics, multi-turn conversational metrics, custom G-Eval criteria, and DAG-style rubric graphs.

The pytest-native workflow is directly applicable to coding agents. A coding agent can add `tests/evals/...`, run `deepeval test run`, inspect failed metric reasons, edit prompts/tools/retrieval, and rerun. The bundled DeepEval skill formalizes this loop.

Trace/span correlation is the strongest architectural idea. It lets failures point to a retriever, tool, LLM call, sub-agent, or full trace instead of only scoring the final answer. That is valuable for debugging agent regressions.

The dataset abstraction is practical. Goldens can be loaded from code, CSV, JSON, JSONL, Confident AI, or synthetic generators, then iterated through apps without forcing every app to precompute all outputs.

The verification layer has real engineering work behind it: no-metric guard, missing-param validation, async task binding, per-task timeout handling, retry policy, local-store collision avoidance, pytest integration tests, and framework integration tests.

## Weaknesses

LLM-as-judge is the default center of gravity. This makes evals flexible but potentially flaky, costly, slow, and provider-dependent. Calibration, human review, and deterministic checks are still needed for high-stakes gates.

Metric instances are mutable state containers. The code has isolation tests and `copy_metrics()`, but custom metric authors can easily leak state if they reuse objects incorrectly.

The trace path is complex. Contextvars, global managers, async task monkeypatching, framework callbacks, OTel processors, and client monkeypatches create many edge cases. The test suite reflects this complexity.

Confident AI is deeply embedded in naming, API types, docs, and workflows. Local-only users can run evals, but cloud concepts still shape the architecture, CLI, telemetry, and docs.

CI reliability depends on secrets for many tests and metrics. GitHub workflows skip or ignore OpenAI-dependent sections when secrets are absent; full maintainer tests need protected secrets.

Component-level evaluation is documented as single-turn only. Multi-turn conversations have strong E2E metrics, but not the same span-level component evaluation surface yet.

The red-teaming module is no longer in this repo. `deepeval/red_teaming/README.md` points users to `confident-ai/deepteam` for v3.0 onward, so this repo should not be treated as the current red-team engine.

## Ideas To Steal

Use pytest as the user-facing eval runner. A coding-agent lab should provide an `assert_eval()`-style API that fails CI with metric names, scores, thresholds, errors, and reasons.

Adopt the `Golden` / `TestCase` split. Goldens are stable dataset rows; test cases are realized app executions with actual output, trace, tool calls, contexts, and metadata.

Attach metrics at multiple scopes: full task, trace, span, tool call, retrieval step, and final answer. This is the best way to make eval failures actionable for coding agents.

Emit a structured result row for every metric with `score`, `success`, `threshold`, `reason`, `error`, `cost`, and `verbose_logs`. Keep a timestamped local JSON run history by default.

Add a no-empty-eval guard. If a test harness runs with no local metric sources, fail loudly instead of producing a misleading green or empty report.

Make metric required-fields explicit and machine-checkable. Agent eval suites should fail early when a metric needs `expected_tools`, `retrieval_context`, or trace data that the dataset does not provide.

Ship agent-facing templates and iteration instructions with the harness. DeepEval's skill is a useful example of turning an eval framework into a repeatable coding-agent workflow.

## Do Not Copy

Do not make cloud upload or hosted dashboards part of the core local abstraction. Keep cloud reporting as an adapter over a local-first result contract.

Do not rely on mutable metric objects as the only result channel. Prefer pure metric-return objects or cloned metric execution contexts to avoid state leakage.

Do not make broad monkeypatching the default integration strategy for a coding-agent harness. Prefer explicit wrappers, typed adapters, or narrow instrumentation hooks when possible.

Do not gate agent regressions only on LLM-judge scores. Pair subjective judge metrics with deterministic checks for tool names, argument structure, JSON schema, file diffs, command success, and security invariants.

Do not copy the red-teaming surface from this repo. Current red teaming has moved to `confident-ai/deepteam`; this repo only retains a redirect README.

Do not import UI/docs app shape into a harness. The reusable parts are source contracts, execution loops, result schemas, and tests, not the Next.js documentation site or binary assets.

## Fit For Agentic Coding Lab

Fit is high for `harness-eval`. DeepEval shows how to make agent quality checks look like ordinary tests while still preserving traces, metric reasons, and hosted/local reports.

Most applicable patterns:

- Pytest-compatible eval assertions for CI.
- Local structured run artifacts for agent-readable feedback.
- Dataset iterator that lets a coding agent call the real app under test.
- Span-scoped component evals for retrievers, tools, planners, and LLM calls.
- Tool correctness and argument correctness metrics for agent behavior.
- Agent skill plus templates that guide a coding assistant through dataset, eval suite, trace setup, and iteration.

Less applicable patterns:

- Cloud-first Confident AI coupling.
- Provider/API-key-heavy CI as the main verification story.
- Stateful metric mutation.
- Complex monkeypatch-heavy framework integrations.

For Agentic Coding Lab, this is best used as a design reference and possible optional dependency for Python LLM apps, not as the universal harness. A repo-native harness should copy the local-first contracts and verification loop, then add coding-specific deterministic checks around file edits, shell commands, tests, diffs, permissions, and security review.

## Reviewed Paths

- `README.md`: product scope, metric taxonomy, integrations, Confident AI, vibe-coder quickstart, human quickstart, pytest assertion examples, and dataset iterator examples.
- `pyproject.toml`: package metadata, Python/Poetry setup, CLI entrypoint, pytest plugin registration, main/dev/integration dependencies, pytest markers.
- `deepeval/__init__.py`: public API exposure, dotenv loading, `evaluate`, `assert_test`, `compare`, `instrument`, login, telemetry.
- `deepeval/evaluate/evaluate.py`: `assert_test()`, `evaluate()`, config defaults, console reporting, local/cloud test-run finalization.
- `deepeval/evaluate/execute/*.py`: sync/async execution, trace/dataset iterator paths, component-level DFS, timeout/error handling, metric-data creation, duplicate filtering, trace-scope assertion.
- `deepeval/evaluate/configs.py`, `utils.py`, `local_store.py`: async/display/cache/error configs, result schemas, API trace conversion, local run JSON storage.
- `deepeval/metrics/base_metric.py`, `utils.py`, `g_eval/`, `dag/`, `task_completion/`, `plan_adherence/`, `step_efficiency/`, `tool_correctness/`, `mcp/`, `pii_leakage/`, `misuse/`: metric contract, judge schema extraction, required-param validation, agent/RAG/MCP/safety examples.
- `deepeval/test_case/*.py`: single-turn, conversational, arena, tool-call, multimodal, and MCP test-case models and validators.
- `deepeval/dataset/*.py`: goldens, file import/export, push/pull/queue to Confident AI, synthetic hooks, `evals_iterator()`, OpenTelemetry test-run sandwich.
- `deepeval/tracing/*.py`: trace manager, `Observer`, `@observe`, `trace()`, trace/span types, context update helpers, masking, sampling, REST/OTLP trace export.
- `deepeval/integrations/**`, `deepeval/openai/**`, `deepeval/anthropic/**`, `deepeval/openai_agents/**`: framework adapters, OTel instrumentation, client wrappers, callback handlers, event listeners, and OpenAI/OpenAI Agents tracing.
- `deepeval/cli/**`, `deepeval/plugins/plugin.py`: Typer CLI, `deepeval test run`, pytest plugin hooks, test-run lifecycle.
- `.github/workflows/test_core.yml`, `test_metrics.yml`, `test_integrations.yml`, `full_test_core_for_pr.yml`, `black.yml`: CI coverage, secret-dependent test gates, integration jobs, formatting.
- `docs/content/docs/**`: selected docs for evaluation overview, single-turn E2E, component evals, CI/CD unit testing, agent quickstart, environment variables, data privacy, safety metrics, agentic metrics, datasets, and tracing.
- `tests/test_core/test_tracing/test_integration/test_dataset_iterator.py`, `tests/test_core/test_evaluation/test_trace_scope_assert_test.py`, `tests/test_core/test_evaluation/test_async_trace_metric_isolation.py`, `tests/test_core/test_evaluation/test_execute/test_execute_llm_test_case.py`, `tests/test_core/test_evaluation/test_local_store.py`, `tests/test_core/test_test_case/**`, `tests/test_metrics/**`, `tests/test_integrations/**`: sampled tests covering iterator semantics, trace-scoped assertions, metric isolation, timeout persistence, local storage, schemas, metrics, and integrations.
- `skills/README.md`, `skills/deepeval/SKILL.md`, `skills/deepeval/references/*.md`, `skills/deepeval/templates/*.py`: agent-facing eval workflow, artifact contracts, metric selection, tracing guidance, iteration loop, and pytest templates.
- `deepeval/red_teaming/README.md`: confirmed red-teaming module was moved to `confident-ai/deepteam`.

## Excluded Paths

- `docs/app/`, `docs/components/`, `docs/home/`, `docs/lib/`, `docs/src/`, `docs/public/`, `docs/package.json`, `docs/yarn.lock`, `docs/next.config.mjs`, `docs/vercel.json`: documentation website implementation and UI-only Next.js plumbing. I reviewed `docs/content/docs/**` for product behavior and excluded the UI shell.
- `assets/**`, including `demo.gif`, hero SVGs, and `confident-mcp-architecture.png`: binary/visual marketing assets. Not relevant to eval architecture beyond README illustrations.
- `examples/**`, `demo_trace_scope/**`, root `test_agentcore_agent.py`, root `test_pydantic_agent.py`, and notebooks: demo and exploratory usage examples. I used docs/tests/source for actual architecture because examples are not authoritative execution paths.
- `poetry.lock`, `docs/yarn.lock`, generated trace schema fixture JSON under `tests/**/schemas/*.json`: lockfiles and generated/fixture artifacts. I sampled schema filenames to understand coverage but did not inspect every fixture body.
- `.cursor-plugin/**`: plugin manifest only; relevant behavior lives in `skills/deepeval/**`, which I reviewed.
- `.scripts/changelog/**`, `scripts/check_openai_model_capabilities.py`, `manual_after_evals_iterator.py`, `MAINTAINERS.md`, `CITATION.cff`, `.vscode/**`, `.git/**`: release/dev helper or metadata paths, not eval harness architecture.
- `deepeval/benchmarks/**`, `deepeval/model_integrations/**`, `deepeval/models/answer_relevancy_model.py`, `deepeval/models/detoxify_model.py`, `deepeval/models/hallucination_model.py`, `deepeval/models/summac_model.py`, `deepeval/models/unbias_model.py`: benchmark/model implementation details were lower priority than harness execution. I reviewed the base model contract, retry policy, and model provider selection instead.
- `deepeval/red_teaming/**` beyond `README.md`: no current in-repo red-team implementation exists; README redirects to `deepteam`.
