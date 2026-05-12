# evidentlyai/evidently

- URL: https://github.com/evidentlyai/evidently
- Category: harness-eval
- Stars snapshot: 7,479 (GitHub REST API, captured 2026-05-12)
- Reviewed commit: a4aa4c2b37fe7a4344cc5031f566deccf3d69e4f
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: conditional
- Verdict: Strong observability and evaluation architecture for data, ML, and LLM systems. Evidently is not a coding-agent task harness, but its Dataset -> descriptor -> Report/Snapshot -> tests -> monitoring dashboard loop is directly useful for coding-agent regression dashboards, LLM judge metrics, trace review, and prompt-quality verification.

## Why It Matters

Evidently is a mature Python framework for evaluating and monitoring AI systems. It covers tabular data quality, drift, classification, regression, ranking, text, LLM-as-judge checks, traces, prompt storage, and dashboards. That makes it relevant to Agentic Coding Lab as a reference implementation for how one-off evals become repeatable monitoring over time.

The important pattern is not only the metric catalog. The stronger idea is the operational loop: convert outputs and traces into a typed dataset, add row-level descriptors and tests, summarize them into metrics, serialize a snapshot, flatten metrics into time-series points, and inspect regressions in a dashboard.

## What It Is

Evidently is an open-source Python package and local service for AI observability. Users create `Dataset` objects from pandas data, define a `DataDefinition`, optionally add text or LLM descriptors, then run a `Report` containing metrics or presets. The result is a `Snapshot` / `Run` that can be exported as JSON, dict, or HTML, or sent to a workspace for dashboarding.

For LLM systems, Evidently models evaluation as generated descriptor columns. Descriptors include deterministic text checks, code and JSON validators, semantic similarity, context relevance, and LLM judge templates for correctness, faithfulness, toxicity, bias, decline detection, and custom binary or multiclass classification. `TextEvals` and `TestSummary` then turn those row-level outputs into report metrics and pass-rate summaries.

For monitoring, the service stores snapshot JSON blobs and indexes metric points for time-series queries. Local OSS storage uses file-backed snapshot blobs and in-memory point indexes rebuilt from snapshots; SQL storage persists project metadata, snapshot metadata, metric definitions, point chunks, traces, and human feedback.

## Research Themes

- Token efficiency: Conditional. The LLM wrapper has rate limits, async batching, retries, and token accounting hooks, and tracing aggregates OpenInference token counts. It is not primarily a token-minimization system.
- Context control: Strong. `DataDefinition`, task configs, service columns, descriptor inputs, prompt templates, and trace-to-dataset conversion make evaluated context explicit.
- Sub-agent / multi-agent: Conditional. Evidently does not orchestrate agents, but OTLP tracing and span aggregation can monitor multi-step workflows, tool calls, token/cost totals, and human feedback.
- Domain-specific workflow: Strong. Presets cover drift, data quality, regression, classification, ranking, and text/LLM evals. Prompt optimization includes a code-review example that is close to coding-agent evaluation.
- Error prevention: Strong for eval gates. Metric tests, descriptor tests, reference comparisons, pass-rate summaries, snapshots, and dashboards can catch output regressions and data drift.
- Self-learning / memory: Conditional. Prompt registry, prompt versions, datasets, snapshots, and prompt optimizer runs support iterative improvement, but Evidently is not a long-term autonomous memory system.
- Popular skills: Not a skill repo. Reusable primitives are `Dataset`, `DataDefinition`, `Descriptor`, `LLMEval`, `LLMJudge`, `TextEvals`, `TestSummary`, `Report`, `Snapshot`, metric tests, `ProjectManager`, tracing storage, and prompt optimization.

## Core Execution Path

The basic flow starts with pandas data. `Dataset.from_pandas()` applies a `DataDefinition`, infers column types when needed, maps service columns like trace links and human feedback fields, and adds descriptors. Descriptor generation can produce one or more columns per row; those columns are registered as numerical, categorical, descriptor, or special columns.

Reports run through `src/evidently/core/report.py`. `Report.run()` validates current and reference data, converts them into `Dataset` instances, creates a `Snapshot`, and executes metrics through a `Context`. The context caches metric results, resolves metric dependencies, stores reference results, runs bound tests, and bridges newer `Dataset` objects into legacy `InputData` and renderers when needed.

Metrics return typed `MetricResult` objects such as `SingleValue`, `ByLabelValue`, `CountValue`, `MeanStdValue`, `ByLabelCountValue`, and `DataframeValue`. Each result declares value locations so downstream storage can flatten structured outputs into dashboard points.

Tests bind threshold logic to metric values or descriptor columns. A metric can supply default tests when `include_tests` is enabled, and explicit tests can compare values to constants or reference results. `TestSummary` aggregates row-level descriptor test columns into success counts, rates, all/any pass flags, and scores.

Monitoring stores the computed snapshot. `ProjectManager.add_snapshot()` writes the snapshot JSON blob and asks data storage to index metric points. The project API then serves snapshot lists, graph data, metric labels, label values, and dashboard time series.

## Architecture

The architecture is layered:

- `src/evidently/core/datasets.py`: dataset schema, task configs, descriptor registration, pandas conversion, special columns, and dataset serialization.
- `src/evidently/core/report.py`: report execution, metric dependency context, snapshot serialization, widgets, and test collection.
- `src/evidently/core/metric_types.py`: metric result schemas, value-location metadata, metric tests, bound tests, and metric calculation objects.
- `src/evidently/descriptors/`: row-level feature generation for text, JSON, code validity, semantic similarity, context relevance, and LLM judges.
- `src/evidently/llm/`: provider wrappers, prompt templates, output parsing, rate limits, and prompt optimization.
- `src/evidently/metrics/`: atomic metrics for data stats, drift, regression, row-test summaries, ranking, classification, and text outputs.
- `src/evidently/presets/`: bundled metric containers such as `TextEvals`, `DataDriftPreset`, `RegressionPreset`, `DataSummaryPreset`, and `RecsysPreset`.
- `src/evidently/tests/`: threshold builders and descriptor-column tests.
- `src/evidently/ui/service/`: local service app, project APIs, dashboard APIs, dataset APIs, prompt/artifact APIs, storage components, and tracing routes.
- `src/evidently/ui/service/storage/`: local JSON/file storage, in-memory point indexing, and SQL-backed metadata, metric, dataset, and trace storage.
- `src/evidently/sdk/`: local and remote client APIs for datasets, prompts, artifacts, and workspaces.

The repo has no in-repo `docs/` directory at the reviewed commit. The root README, API-reference generator README, examples, tests, and source code were used to reconstruct the actual architecture.

## Design Choices

Evidently treats descriptors as data generation, not only metric calculation. This is useful because each LLM judge, regex check, JSON schema match, Python validity check, or semantic score becomes an inspectable dataset column before aggregation.

Reports separate row-level evaluation from summary metrics. `TextEvals` can summarize descriptor distributions, `RowTestSummary` can produce pass rates, and generic metric tests can turn values into CI-style pass/fail results.

Snapshots are the durable unit of reporting. A snapshot stores metadata, tags, metric results, top-level metrics, widgets, and test widgets. This gives dashboards enough context to show both historical trend lines and individual report downloads.

The dashboard storage model flattens metric results into labeled numeric points. That makes time-series dashboards generic across drift, regression, LLM eval, and data-quality metrics, as long as a metric result exposes `metric_value_location`.

The LLM layer has a provider-neutral wrapper interface. Native OpenAI support and LiteLLM provider names sit behind one `LLMWrapper`, with async batch execution, semaphores, rate limiting, retries, and output parsing.

Prompt optimization is framed as an eval loop over a labeled dataset. Executors generate predictions, scorers measure quality, strategies propose prompt changes, and logs track score changes plus input/output token usage.

The current codebase bridges a new core API and legacy metric/rendering internals. This preserves compatibility and broad metric coverage, but it makes extension harder because current descriptors and presets sometimes wrap legacy features and renderers.

## Strengths

The LLM evaluation surface is broad and practical. Built-in descriptors cover sentiment, text length, contains/includes words, valid JSON, valid Python, valid SQL, JSON match, JSON schema match, semantic similarity, BERTScore, context relevance, and LLM judges for correctness, faithfulness, completeness, context quality, PII, toxicity, bias, negativity, and decline behavior.

`TestSummary` is a strong pattern for agent gates. A coding-agent run can produce several row-level checks, then summarize them as a single pass-rate metric and dashboard point without losing per-row evidence.

The monitoring pipeline is concrete. `ProjectManager` stores snapshot blobs, local and SQL data stores flatten metric points, and project APIs expose metric names, labels, label values, and time-series data. This is the dashboard backbone a coding-agent lab needs for daily or per-commit regression views.

Tracing is unusually useful for agent workflows. The OTLP endpoint accepts spans tagged with `evidently.export_id`, stores traces by dataset/export, converts spans into tabular rows, preserves `_evidently_trace_link`, aggregates token and cost attributes, and supports SQL-backed human feedback.

Regression and drift presets are directly reusable for non-LLM signals. Runtime, token count, cost, file count, changed lines, unit-test pass rate, and rubric scores can be monitored like regression targets or data distributions.

The examples include a code-review prompt optimization workflow. It uses `LLMClassification`, `LLMEval`, labeled examples, an accuracy scorer, and feedback-based prompt iteration to improve a judge/prompt over repetitions. This is close to evaluating coding-agent review quality.

The Grafana LLM dashboard example shows a simple external monitoring path: compute descriptors over LLM responses, insert values into PostgreSQL, and graph them in Grafana. That is useful when the built-in service is not the desired dashboard surface.

## Weaknesses

Evidently is not a coding-agent harness. It does not run benchmark tasks, check out repositories, apply patches, execute tests in sandboxes, inspect diffs, enforce permission policy, or verify filesystem side effects.

LLM-as-judge reproducibility remains a risk. The wrappers provide retries, rate limiting, and structured output parsing, but the reviewed paths did not show a built-in judge cache, deterministic replay layer, model-version pinning policy, or calibration workflow for a new coding domain.

The new API still depends on legacy internals. Descriptors, metric rendering, report widgets, and some presets bridge into legacy feature generators and renderers. This adds maintenance risk for anyone trying to adapt internals rather than use public APIs.

OSS dashboard capability has product boundaries. The project manager explicitly rejects multiple dashboard tabs in OSS, so richer regression views may need SQL/export integrations, Grafana, or custom dashboards.

Local storage is pragmatic but not enough for durable high-volume monitoring. File storage keeps snapshot blobs, while local metric points are rebuilt into memory. SQL storage is the stronger option for persistent dashboards, traces, filtering, and human feedback.

File-based tracing has operational limits. Non-local filesystems use read-modify-write for JSONL traces, and human feedback is not implemented for file tracing. The code itself points users toward SQL storage for object-storage-like deployments.

Prompt optimizer test coverage is thin in the reviewed test paths. Unit tests cover basic optimizer context behavior, but the full prompt-improvement loop needs domain-specific smoke tests before use in a regression pipeline.

## Ideas To Steal

Model every agent run as a row in a dataset with explicit input, expected output, actual output, trace link, git commit, runtime, token count, cost, tool count, files touched, and test outcome columns.

Use descriptors for row-level agent checks: valid JSON response, valid patch metadata, valid Python snippet, expected file mention, forbidden phrase absence, trace link presence, LLM judge rubric result, and semantic match to a reference.

Aggregate descriptor checks with a `TestSummary`-like metric so dashboards can show pass rate over time while still allowing drill-down into failed rows.

Adopt a `Report` / `Snapshot` boundary for every benchmark run. Store raw metric results, tags, metadata, and a timestamp before generating dashboard points.

Flatten metric results into labeled time-series points. This supports generic dashboards for task success, unit-test pass rate, average latency, cost, token usage, LLM judge pass rate, drift in failure modes, and regression quality.

Use trace-to-dataset conversion for agent trajectories. Spans can become columns such as command count, tool error rate, token totals, cost totals, user/session grouping, and links back to trace detail.

Keep prompt and judge rubrics versioned separately from code. Evidently's local/remote prompt APIs and prompt optimizer are useful patterns for evolving rubric prompts while preserving run metadata.

Use reference-aware tests for regression gates. A metric threshold can compare current run quality, latency, or cost to a baseline instead of hardcoding every threshold.

Mine the code-review prompt optimization example as a seed for coding-agent review evals: labeled feedback examples, judge prompt execution, accuracy scoring, repeated prompt improvement, and final prompt selection.

## Do Not Copy

Do not treat Evidently as a replacement for SWE-style harness execution. It should sit after task execution and evaluate outputs, traces, and metrics.

Do not copy the whole ML metric catalog into a coding-agent lab. Use the storage, descriptor, test, and snapshot patterns, then define agent-specific metrics.

Do not depend on LLM judges as the only gate. Pair them with deterministic checks such as tests passed, patch applies, file allowlists, JSON schema, Python syntax, command policy, and trace completeness.

Do not rely on local in-memory point storage for serious regression dashboards. Use SQL, exported JSON, or an external warehouse/Grafana path when historical durability matters.

Do not ignore prompt and model versions. LLM judge outputs should store provider, model, prompt version, template, parsing mode, and calibration set.

Do not assume trace ingestion alone gives a clean eval dataset. Span names, attributes, resource tags, and root input/output fields need conventions or rows become inconsistent.

Do not adopt legacy internals unless necessary. Prefer the public `Dataset`, descriptor, `Report`, preset, SDK, and service APIs.

## Fit For Agentic Coding Lab

Fit is conditional and strong as an observability layer. Evidently should be studied as a system for post-run evaluation, regression monitoring, prompt/judge iteration, and trace-backed diagnosis. It should not be adopted as the primary task runner or correctness oracle.

Best-fit uses for Agentic Coding Lab are:

- daily or per-commit dashboards for agent success rate, test pass rate, cost, latency, token usage, and LLM judge pass rates;
- row-level descriptors for deterministic format/code checks and rubric-based review checks;
- trace ingestion for multi-step agent runs and human feedback loops;
- prompt registry and optimizer patterns for coding-review or answer-quality judge prompts;
- reference/current comparisons for drift and regression gates.

The most useful prototype would wrap an existing coding-agent harness output table in Evidently-style datasets, descriptors, reports, snapshots, and dashboard points, while leaving task execution, sandboxing, and code correctness checks in a separate harness.

## Reviewed Paths

- `/tmp/myagents-research/evidentlyai-evidently/README.md`
- `/tmp/myagents-research/evidentlyai-evidently/api-reference/README.md`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/__init__.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/core/datasets.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/core/report.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/core/metric_types.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/core/tests.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/core/serialization.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/descriptors/__init__.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/descriptors/generated_descriptors.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/descriptors/llm_judges.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/descriptors/text_match.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/descriptors/_context_relevance.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/llm/options.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/llm/templates.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/llm/utils/wrapper.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/llm/utils/blocks.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/llm/utils/templates.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/llm/utils/parsing.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/llm/optimization/optimizer.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/llm/optimization/prompts.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/llm/optimization/scorers.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/metrics/column_statistics.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/metrics/row_test_summary.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/presets/dataset_stats.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/presets/drift.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/presets/regression.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/presets/recsys.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/presets/special.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/tests/__init__.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/tests/numerical_tests.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/tests/categorical_tests.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/tests/descriptors.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/ui/service/app.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/ui/service/local_service.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/ui/service/base.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/ui/service/api/projects.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/ui/service/api/datasets.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/ui/service/managers/projects.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/ui/service/storage/local/base.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/ui/service/storage/local/__init__.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/ui/service/storage/sql/data.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/ui/service/storage/sql/metadata.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/ui/service/storage/sql/models.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/ui/service/components/storage.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/ui/service/components/tracing.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/ui/service/tracing/api.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/ui/service/tracing/storage/base.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/ui/service/tracing/storage/file.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/ui/service/tracing/storage/sql.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/ui/service/datasets/metadata.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/sdk/datasets.py`
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/sdk/local.py`
- `/tmp/myagents-research/evidentlyai-evidently/examples/grafana/grafana_llm_evaluation_dashboard/README.md`
- `/tmp/myagents-research/evidentlyai-evidently/examples/grafana/grafana_llm_evaluation_dashboard/evidently_metrics_calculation.py`
- `/tmp/myagents-research/evidentlyai-evidently/examples/datasets/code_review.csv`
- `/tmp/myagents-research/evidentlyai-evidently/examples/llm_input_output_validation.ipynb` (searched source cells with `rg`)
- `/tmp/myagents-research/evidentlyai-evidently/examples/agentic_systems_tracing.ipynb` (searched source cells with `rg`)
- `/tmp/myagents-research/evidentlyai-evidently/examples/cookbook/prompt_optimization_code_review_example.ipynb` (searched source cells with `rg`)
- `/tmp/myagents-research/evidentlyai-evidently/examples/cookbook/regression_preset.ipynb` (searched source cells with `rg`)
- `/tmp/myagents-research/evidentlyai-evidently/tests/features/test_llm_judge.py`
- `/tmp/myagents-research/evidentlyai-evidently/tests/future/report/test_report.py`
- `/tmp/myagents-research/evidentlyai-evidently/tests/future/test_ui/test_llm_judges.py`
- `/tmp/myagents-research/evidentlyai-evidently/tests/future/llm/test_optimizer.py`
- `/tmp/myagents-research/evidentlyai-evidently/tests/ui/test_tracing_storage.py`

## Excluded Paths

- `/tmp/myagents-research/evidentlyai-evidently/.git/`, `.github/`, `.devcontainer/`, `.dvc/`: repository metadata, CI, devcontainer, and data-version metadata rather than runtime eval architecture.
- `/tmp/myagents-research/evidentlyai-evidently/ui/`, `src/evidently/ui/service/assets/`, `src/evidently/nbextension/static/`: frontend bundles, static assets, and notebook UI assets. Backend service APIs and storage were reviewed instead.
- `/tmp/myagents-research/evidentlyai-evidently/images/` and screenshot assets: generated or illustrative media, not evaluation logic.
- `/tmp/myagents-research/evidentlyai-evidently/api-reference/dist/` and `api-reference/evidently-theme/`: generated API docs output and docs theme implementation. Only the generator README was reviewed to understand docs layout.
- `/tmp/myagents-research/evidentlyai-evidently/examples/datasets/` except `code_review.csv`: sample data files and binaries. The code-review dataset was sampled because it is directly relevant to coding-agent prompt/judge evaluation.
- `/tmp/myagents-research/evidentlyai-evidently/examples/**/*.ipynb` output blobs: notebook source cells were searched for relevant architecture and examples; large outputs and binary notebook artifacts were not reviewed.
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/legacy/`: legacy implementation and renderer internals. The review followed current wrappers and bridge points but did not exhaustively audit legacy code.
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/guardrails/`: inline guardrails are adjacent but less central than reports, descriptors, monitoring, and tracing for this assigned harness-eval review.
- `/tmp/myagents-research/evidentlyai-evidently/src/evidently/llm/datagen/` and deeper RAG indexing helpers: useful adjacent tooling, but the review focused on evaluation, monitoring, reports, traces, and prompt optimization.
- `/tmp/myagents-research/evidentlyai-evidently/tests/legacy/`, broad Spark/calculation-engine/data-quality tests, and unrelated metric tests: extensive coverage exists, but targeted LLM judge, report, tracing, UI, and optimizer tests were sampled for architecture confidence.
- `/tmp/myagents-research/evidentlyai-evidently/docker/`, deployment scripts, packaging metadata, and release tooling: operational packaging rather than core eval or monitoring design.
