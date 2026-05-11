# mlflow/mlflow

- URL: https://github.com/mlflow/mlflow
- Category: harness-eval
- Stars snapshot: 25,865 (GitHub REST API, captured 2026-05-11; existing index snapshot)
- Reviewed commit: 0aa92b3fa7a1d37b352524350fbfebbe4d3ab60f
- Reviewed at: 2026-05-12T00:08:42+09:00
- Status: reviewed
- Scope fit: conditional
- Verdict: High-value reference for eval-driven agent development, trace-linked assessments, dataset lineage, prompt/version registry, scorer registry, and online scoring. Too broad to copy as a coding-agent harness; steal the evaluation and observability patterns, not the whole platform.

## Why It Matters

MLflow has become a full AI engineering platform rather than only an experiment tracker. The reviewed snapshot combines run/model/dataset tracking, GenAI traces, evaluation harnesses, LLM judges, human feedback, prompt registry/versioning, prompt optimization, scheduled production scoring, and MCP tooling for trace access.

For coding-agent work, the most relevant idea is a trace-centered feedback loop: capture agent execution as spans, turn traces into evaluation datasets, attach expectations and judge/human assessments, compare runs over time, and link every result back to prompt versions, model IDs, datasets, and source runs.

## What It Is

MLflow is a Python-first platform with tracking server, artifact stores, registries, UI, REST APIs, and many framework integrations. Its core entities are experiments, runs, logged models, datasets, traces, spans, assessments, scorers, judges, and prompt versions.

It has two evaluation systems:

- Classic model evaluation: `mlflow.models.evaluate`, `EvaluationMetric`, `ModelEvaluator`, default evaluator, metric artifacts, and `validate_evaluation_results`.
- GenAI evaluation: `mlflow.genai.evaluate`, `Scorer`, `Feedback`, traces, expectations, sessions, judges, prompt registry, and production scoring.

The docs explicitly say the classic and GenAI evaluation APIs are not interoperable.

## Research Themes

- Token efficiency: Strong indirectly. Existing traces can be reused instead of regenerating LLM outputs, MCP trace tools support field extraction, scorers can sample production traces, and evaluation has worker/rate-limit controls.
- Context control: Strong. Inputs, outputs, expectations, trace spans, prompt versions, model IDs, dataset sources, run IDs, feedback, and assessment metadata are separate structured fields instead of loose logs.
- Sub-agent and multi-agent workflows: Conditional. MLflow does not orchestrate agents, but traces, sessions, tool-call spans, retrieval spans, and session-level scorers can observe multi-step and multi-agent behavior.
- Domain-specific workflows: Strong for eval-driven development. The docs frame datasets, scorers, production traces, human feedback, judge alignment, and prompt optimization as an iterative improvement loop.
- Error prevention: Strong. It supports offline evaluation, online scoring, threshold validation in classic eval, judge alignment to human feedback, prompt optimization, and MCP-driven trace issue discovery.
- Self-learning and memory: Conditional. It has prompt optimization and judge alignment from feedback/traces, but not a general agent memory system.
- Popular skills applicability: MLflow is not a skills framework. Reusable patterns include trace capture, scorer contracts, assessment logging, prompt lineage, evaluation datasets, and MCP trace inspection.

## Core Execution Path

GenAI evaluation starts at `mlflow.genai.evaluate(data, scorers, predict_fn=None, model_id=None)`. `_run_harness` validates scorers, starts or reuses an MLflow run, sets active model context, enables evaluation autologging, converts data into an evaluation set, logs dataset inputs, and calls `harness.run`.

The harness converts rows to `EvalItem`s, separates single-turn and session-level work, and runs prediction and scoring through bounded thread pools. `_run_predict` either calls `predict_fn` with an evaluation request context, reuses or clones an existing trace, or creates a minimal trace for static outputs. `_run_score` runs scorers, converts return values into `Feedback`, logs assessments to the trace, records errors as scorer-error feedback, links traces to the run, computes aggregate metrics, and returns an `EvaluationResult`.

Tracing uses `@mlflow.trace` and manual span APIs on top of OpenTelemetry. Span processors register traces/spans, aggregate token/cost metadata, link active runs/models/prompts, and export trace data. During GenAI evaluation, async trace export is bypassed where needed so the scorer can synchronously retrieve the generated trace.

Prompt management wraps the model registry. `register_prompt` creates immutable prompt versions, aliases point to mutable production/staging labels, `load_prompt` returns cached prompt objects, and prompt usage is linked to active runs, models, traces, and spans. Prompt optimization loads prompt versions, patches candidate templates during evaluation, scores candidates, and registers improved prompt versions.

Classic evaluation follows `mlflow.models.evaluate`: convert data to a dataset, load a model or endpoint when needed, log dataset/model lineage, run selected evaluators, log metrics/tables/artifacts, and optionally compare candidate and baseline results through validation thresholds.

## Architecture

- `mlflow/genai/evaluation/`: GenAI evaluation API, data conversion, prediction/scoring harness, session handling, trace linking, result assembly.
- `mlflow/genai/scorers/`: scorer base class, built-in scorers, LLM judges, registry, online trace/session scoring processors.
- `mlflow/genai/judges/`: judge abstraction, built-in judge wrappers, alignment hooks.
- `mlflow/genai/datasets/` and `mlflow/entities/evaluation_dataset.py`: evaluation dataset creation, record conversion, trace-derived datasets, provenance, granularity checks.
- `mlflow/tracing/`: fluent tracing APIs, provider setup, trace manager, processors, exporters, client operations, prompt linkage.
- `mlflow/genai/prompts/`, `mlflow/prompt/`, and model-registry prompt entities: prompt version storage, aliasing, formatting, cache, tags, and lineage.
- `mlflow/genai/optimize/`: prompt optimization API and optimizer interface.
- `mlflow/models/evaluation/`: classic ML/model evaluation, custom metrics, default evaluator, result validation.
- `mlflow/mcp/`: FastMCP server that exposes curated MLflow CLI commands and trace/scorer/run tools to coding assistants.
- `tests/genai/`, `tests/tracing/`, `tests/entities/`, and `tests/models/evaluation/`: behavioral coverage for evaluation, traces, datasets, prompts, prompt cache, and validation.

## Design Choices

- Trace is the central GenAI artifact. Evaluations attach feedback and expectations to traces rather than producing only aggregate metrics.
- Prediction and scoring are separate stages with independent worker pools, backpressure, retries, and rate limits.
- Scorers introspect their call signature and receive only the fields they declare: `inputs`, `outputs`, `expectations`, `trace`, or `session`.
- Existing traces can be evaluated directly, linked to a run when the backend supports it, or cloned when cross-backend/cross-experiment linking is unavailable.
- Dataset rows normalize around `inputs`, `outputs`, `expectations`, optional `trace`, and optional tags, which keeps static examples and trace examples on the same path.
- Prompt registry is implemented on top of the model registry using model-version tags and aliases, trading implementation reuse for conceptual coupling.
- Prompt loading creates lineage as a side effect by linking prompts to active runs, models, traces, or spans.
- Online scoring uses stored scorer configuration, filters, sampling, checkpoints, and assessment cleanup to evaluate production traces/sessions continuously.
- MCP exposes trace operations and AI analysis commands with field extraction so agents can inspect failures without loading whole traces.

## Strengths

- End-to-end lineage across runs, models, datasets, traces, prompts, scorers, feedback, and assessments.
- GenAI evaluation supports static examples, live `predict_fn`, pre-existing traces, managed datasets, and multi-turn sessions.
- Trace reuse turns production failures into regression datasets and reduces repeated LLM calls.
- Scorer model is flexible: deterministic code scorers, built-in LLM judges, guideline judges, registered scorers, online scorers, and session-level scorers share one assessment path.
- Tracing is broad and practical: OpenTelemetry-compatible spans, sync/async/generator support, tool/retrieval spans, token/cost aggregation, attachments, tags, and run/model linkage.
- Prompt registry has immutable versions, aliases, cache invalidation, Jinja sandboxing, response formats, model config, and trace/run/model linkage.
- Verification loops are explicit: classic metric thresholds, GenAI feedback, judge-human alignment, prompt optimization, online scoring, and AI issue discovery.
- Tests cover important behavior such as trace reuse/linking, scorer errors, managed datasets, prompt alias cache behavior, prompt formatting, trace prompt tags, and rate limiting.

## Weaknesses

- Very broad platform with large dependency and operational surface; too heavy as a direct lightweight coding-agent harness.
- Dual classic/GenAI evaluation APIs create conceptual friction and duplicated mental models.
- Several advanced features are Databricks-backed or provider-dependent, including scheduled scorers, managed datasets, default hosted judges, and some endpoint workflows.
- Prompt registry storage on model registry tags is clever but leaky; a purpose-built prompt store would be simpler for a new agent harness.
- LLM judges require calibration. MLflow provides alignment tools, but raw judge output is not a substitute for human feedback or deterministic checks.
- The system observes and evaluates agent behavior but does not itself provide sandboxing, patch application, CI execution, permissioning, or repo mutation controls.
- Background async linking/export improves throughput but makes lineage correctness harder to reason about unless critical eval paths force synchronous availability.

## Ideas To Steal

- Make trace plus assessment the main unit of agent evaluation, not a separate log file and metric row.
- Let production traces become evaluation datasets with preserved source provenance and expectations.
- Use a prediction request ID so an evaluation run can synchronously recover the trace generated by the candidate system.
- Run prediction and scoring in separate bounded pools with rate-limit and retry policy per stage.
- Standardize scorer outputs into feedback objects with values, rationales, metadata, and scorer-error records.
- Let scorers declare only the fields they need, so simple checks do not receive or load full traces.
- Link prompt versions to every run/trace/model that used them, and keep aliases mutable while versions stay immutable.
- Expose trace search, field extraction, feedback logging, and issue discovery as MCP tools for coding agents.
- Add online scoring checkpoints so sampled production traces and sessions are continuously assessed.
- Keep a validation-threshold mechanism for release gates and candidate-vs-baseline comparisons.

## Do Not Copy

- Do not copy the full platform shape if the target is a focused coding-agent harness.
- Do not split classic and GenAI evaluation semantics unless there is a strong compatibility reason.
- Do not use model registry tags as prompt storage when a smaller prompt/version table would be clearer.
- Do not treat LLM judges as ground truth without human alignment and deterministic tests.
- Do not depend on cloud-only scheduled scoring or managed dataset behavior for a local-first agent system.
- Do not make UI inspection the primary verification route; preserve machine-readable traces, assessments, and metrics first.
- Do not confuse observability with control. MLflow does not replace sandboxing, patch review, command permissioning, or CI enforcement.

## Fit For Agentic Coding Lab

Scope fit is conditional but strong as a reference implementation. MLflow is directly relevant to experiment/eval tracking, trace capture, datasets, scoring, prompt/version registry, and feedback loops. It is less relevant for the execution harness itself because it does not manage repo edits, shells, sandboxes, permissions, or code-review workflows.

Best use: adapt MLflow's trace/evaluation data model and lifecycle into Agentic Coding Lab. Each agent run could produce a trace, each tool call could be a span, each review/test result could be an assessment, each prompt or skill version could be linked to the trace, and production failures could be promoted into regression datasets.

## Reviewed Paths

- `/tmp/myagents-research/mlflow-mlflow/README.md`
- `/tmp/myagents-research/mlflow-mlflow/docs/docs/genai/index.mdx`
- `/tmp/myagents-research/mlflow-mlflow/docs/docs/genai/eval-monitor/index.mdx`
- `/tmp/myagents-research/mlflow-mlflow/docs/docs/genai/eval-monitor/running-evaluation/traces.mdx`
- `/tmp/myagents-research/mlflow-mlflow/docs/docs/genai/eval-monitor/scorers/index.mdx`
- `/tmp/myagents-research/mlflow-mlflow/docs/docs/genai/eval-monitor/scorers/llm-judge/alignment.mdx`
- `/tmp/myagents-research/mlflow-mlflow/docs/docs/genai/eval-monitor/ai-insights/ai-issue-discovery.mdx`
- `/tmp/myagents-research/mlflow-mlflow/docs/docs/genai/tracing/index.mdx`
- `/tmp/myagents-research/mlflow-mlflow/docs/docs/genai/prompt-registry/index.mdx`
- `/tmp/myagents-research/mlflow-mlflow/docs/docs/genai/prompt-registry/optimize-prompts.mdx`
- `/tmp/myagents-research/mlflow-mlflow/docs/docs/genai/datasets/index.mdx`
- `/tmp/myagents-research/mlflow-mlflow/docs/docs/genai/mcp/index.mdx`
- `/tmp/myagents-research/mlflow-mlflow/docs/docs/classic-ml/evaluation/index.mdx`
- `/tmp/myagents-research/mlflow-mlflow/docs/docs/classic-ml/tracking/index.mdx`
- `/tmp/myagents-research/mlflow-mlflow/mlflow/genai/__init__.py`
- `/tmp/myagents-research/mlflow-mlflow/mlflow/genai/evaluation/base.py`
- `/tmp/myagents-research/mlflow-mlflow/mlflow/genai/evaluation/harness.py`
- `/tmp/myagents-research/mlflow-mlflow/mlflow/genai/evaluation/utils.py`
- `/tmp/myagents-research/mlflow-mlflow/mlflow/genai/scorers/base.py`
- `/tmp/myagents-research/mlflow-mlflow/mlflow/genai/scorers/builtin_scorers.py`
- `/tmp/myagents-research/mlflow-mlflow/mlflow/genai/scorers/registry.py`
- `/tmp/myagents-research/mlflow-mlflow/mlflow/genai/scorers/online/trace_processor.py`
- `/tmp/myagents-research/mlflow-mlflow/mlflow/genai/scorers/online/session_processor.py`
- `/tmp/myagents-research/mlflow-mlflow/mlflow/genai/scheduled_scorers.py`
- `/tmp/myagents-research/mlflow-mlflow/mlflow/genai/judges/base.py`
- `/tmp/myagents-research/mlflow-mlflow/mlflow/genai/judges/builtin.py`
- `/tmp/myagents-research/mlflow-mlflow/mlflow/genai/datasets/__init__.py`
- `/tmp/myagents-research/mlflow-mlflow/mlflow/genai/datasets/evaluation_dataset.py`
- `/tmp/myagents-research/mlflow-mlflow/mlflow/entities/evaluation_dataset.py`
- `/tmp/myagents-research/mlflow-mlflow/mlflow/genai/prompts/__init__.py`
- `/tmp/myagents-research/mlflow-mlflow/mlflow/entities/model_registry/prompt_version.py`
- `/tmp/myagents-research/mlflow-mlflow/mlflow/prompt/registry_utils.py`
- `/tmp/myagents-research/mlflow-mlflow/mlflow/tracking/_model_registry/fluent.py`
- `/tmp/myagents-research/mlflow-mlflow/mlflow/tracking/client.py`
- `/tmp/myagents-research/mlflow-mlflow/mlflow/tracing/fluent.py`
- `/tmp/myagents-research/mlflow-mlflow/mlflow/tracing/provider.py`
- `/tmp/myagents-research/mlflow-mlflow/mlflow/tracing/trace_manager.py`
- `/tmp/myagents-research/mlflow-mlflow/mlflow/tracing/processor/base_mlflow.py`
- `/tmp/myagents-research/mlflow-mlflow/mlflow/tracing/processor/mlflow_v3.py`
- `/tmp/myagents-research/mlflow-mlflow/mlflow/tracing/export/mlflow_v3.py`
- `/tmp/myagents-research/mlflow-mlflow/mlflow/tracing/client.py`
- `/tmp/myagents-research/mlflow-mlflow/mlflow/tracing/utils/prompt.py`
- `/tmp/myagents-research/mlflow-mlflow/mlflow/entities/trace_info.py`
- `/tmp/myagents-research/mlflow-mlflow/mlflow/models/evaluation/base.py`
- `/tmp/myagents-research/mlflow-mlflow/mlflow/models/evaluation/default_evaluator.py`
- `/tmp/myagents-research/mlflow-mlflow/mlflow/models/evaluation/validation.py`
- `/tmp/myagents-research/mlflow-mlflow/mlflow/genai/optimize/optimize.py`
- `/tmp/myagents-research/mlflow-mlflow/mlflow/genai/optimize/optimizers/base.py`
- `/tmp/myagents-research/mlflow-mlflow/mlflow/genai/optimize/optimizers/metaprompt_optimizer.py`
- `/tmp/myagents-research/mlflow-mlflow/mlflow/mcp/server.py`
- `/tmp/myagents-research/mlflow-mlflow/mlflow/mcp/cli.py`
- `/tmp/myagents-research/mlflow-mlflow/tests/genai/evaluate/test_evaluation.py`
- `/tmp/myagents-research/mlflow-mlflow/tests/genai/evaluate/test_rate_limiter.py`
- `/tmp/myagents-research/mlflow-mlflow/tests/genai/datasets/test_evaluation_dataset.py`
- `/tmp/myagents-research/mlflow-mlflow/tests/tracing/test_fluent.py`
- `/tmp/myagents-research/mlflow-mlflow/tests/genai/prompts/test_prompts.py`
- `/tmp/myagents-research/mlflow-mlflow/tests/entities/test_prompt.py`
- `/tmp/myagents-research/mlflow-mlflow/tests/tracing/utils/test_prompt.py`
- `/tmp/myagents-research/mlflow-mlflow/tests/genai/utils/test_prompt_cache.py`

## Excluded Paths

- `/tmp/myagents-research/mlflow-mlflow/.git/`: VCS internals; commit SHA recorded instead.
- `/tmp/myagents-research/mlflow-mlflow/docs/static/`, docs images/media, and generated documentation assets: binary or presentation assets, not architecture-bearing for eval/tracking.
- `/tmp/myagents-research/mlflow-mlflow/docs/src/` and docs build tooling: documentation site UI and build code, not core harness/eval logic.
- `/tmp/myagents-research/mlflow-mlflow/mlflow/server/js/`: product UI implementation; relevant only as a presentation layer over trace/eval data, not needed for architecture review.
- Lock files such as `/tmp/myagents-research/mlflow-mlflow/uv.lock` and JavaScript package locks: generated dependency state, not design logic.
- Notebook-heavy examples and tutorial datasets under `/tmp/myagents-research/mlflow-mlflow/examples/`: useful for users, but redundant after reading docs, APIs, and tests for the eval/tracing/prompt architecture.
- Flavor-specific integrations such as sklearn, xgboost, pytorch, transformers, langchain, llama_index, openai, anthropic, and related tests: sampled through central eval/tracing integration points; not reviewed line-by-line because they are adapters, not the harness core.
- Deployment, gateway, serving, Docker, Helm, CI, release, and packaging paths: operationally important but outside the requested eval/tracking architecture.
- Generated or schema/binding-heavy files under protocol/API binding paths: excluded where they only mirror service contracts already visible through client and entity code.
- `/tmp/myagents-research/mlflow-mlflow/mlflow/recipes/` and `/tmp/myagents-research/mlflow-mlflow/tests/recipes/`: absent in reviewed commit, so there was no recipes package to review in this snapshot.
