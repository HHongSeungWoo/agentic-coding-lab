# vibrantlabsai/ragas

- URL: https://github.com/vibrantlabsai/ragas
- Category: harness-eval
- Stars snapshot: 13,868 (GitHub REST API, captured 2026-05-11 in `research/index.md`; GitHub UI showed 13.8k during review)
- Reviewed commit: 298b68274234c060deacab3cf5fb52aa3a20e885
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: conditional
- Verdict: Strong RAG and LLM-app evaluation reference with reusable patterns for metrics, synthetic datasets, experiment storage, traces, and tool-call checks. It is less directly a coding-agent harness than Promptfoo, but its dataset/experiment split, metric schemas, KG-based test generation, and tool/goal metrics are highly useful for coding-agent retrieval and verification workflows.

## Why It Matters

Ragas is a mature Python framework for evaluating RAG, LLM workflows, and agents. It matters for agentic coding research because many coding agents depend on retrieved repository context, tool traces, generated explanations, and outcome-based checks. Ragas shows how to turn those behaviors into repeatable datasets, metric calls, stored experiments, synthetic test data, and trace-backed result rows.

The most relevant ideas are not the specific RAG metrics alone. The stronger reusable pattern is the whole loop: define a dataset, run an application or agent over each row, score the result with deterministic or LLM-based metrics, store the experiment output, compare against a baseline, and use traces/log links for diagnosis.

## What It Is

Ragas is a Python package and CLI for LLM application evaluation. It exposes older `evaluate()` / `EvaluationDataset` APIs for running metric suites over `SingleTurnSample` and `MultiTurnSample` objects, and a newer `Dataset` / `@experiment` path where users run arbitrary app code over rows and store result tables through local or plugin backends.

The repo includes metric implementations for RAG quality, factuality, semantic similarity, general LLM rubrics, SQL, summarization, multimodal checks, and agent/tool behavior. It also includes synthetic RAG testset generation that converts source documents into a knowledge graph, extracts summaries/entities/themes, builds relationships, synthesizes single-hop and multi-hop scenarios, and generates query/reference samples.

## Research Themes

- Token efficiency: Moderate. Ragas tracks token usage through callbacks, supports disk caching for repeated LLM/embedding calls, batches async jobs, and uses token limits in testset transforms. It is not primarily a prompt compression or context pruning system.
- Context control: Strong. Samples, required metric columns, Pydantic prompts, query scenarios, reference contexts, personas, and graph transforms make evaluation context explicit instead of implicit.
- Sub-agent / multi-agent: Conditional. It does not orchestrate subagents, but multi-turn samples, tool-call metrics, topic adherence, and agent goal accuracy model agent workflows.
- Domain-specific workflow: Strong. RAG, text-to-SQL, workflow classification, prompt iteration, benchmark-LLM, and agent examples show how to adapt the same harness to specific applications.
- Error prevention: Strong for evaluation loops. Metrics, baseline experiments, pytest examples, comparison utilities, result storage, and traces can catch regressions, although LLM-as-judge calibration remains necessary.
- Self-learning / memory: Conditional. Metric training, dynamic few-shot prompts, prompt optimization, cache, and stored experiments support iterative improvement, but Ragas is not a long-term agent memory system.
- Popular skills: Not a skill repo. Reusable building blocks are `Dataset`, `@experiment`, `EvaluationDataset`, `Executor`, `RunConfig`, `PydanticPrompt`, `DiscreteMetric`, `NumericMetric`, `ToolCallAccuracy`, `ToolCallF1`, `AgentGoalAccuracy`, `TestsetGenerator`, and storage backends.

## Core Execution Path

Legacy evaluation starts in `src/ragas/evaluation.py`. `evaluate()` wraps `aevaluate()`, converts Hugging Face datasets into `EvaluationDataset`, validates required columns, attaches default metrics when none are provided, initializes LLMs and embeddings, creates row and metric callback groups, submits each metric/sample pair to `Executor`, then aggregates per-row metric outputs into `EvaluationResult`.

Metric execution flows through `src/ragas/metrics/base.py`. A metric declares required columns, optional LLM/embedding dependencies, and either single-turn or multi-turn scoring. `SingleTurnMetric` and `MultiTurnMetric` trim samples to the needed fields, create callback groups, apply timeouts, and call metric-specific `_single_turn_ascore()` or `_multi_turn_ascore()`.

Modern application evaluation flows through `src/ragas/dataset.py` and `src/ragas/experiment.py`. A `Dataset` is a list-like table backed by CSV, JSONL, Google Drive, or memory. An `@experiment` function is run over each row concurrently, appends returned result rows to an `Experiment`, and saves the experiment through the selected backend.

Synthetic testset generation starts in `src/ragas/testset/synthesizers/generate.py`. `TestsetGenerator.generate_with_langchain_docs()` or `generate_with_chunks()` builds graph nodes, applies transforms, picks query synthesizers, generates scenarios, generates query/reference samples, and returns a `Testset`.

## Architecture

The architecture is layered:

- `src/ragas/evaluation.py`: legacy metric-suite runner over homogeneous `EvaluationDataset` samples.
- `src/ragas/dataset_schema.py`: single-turn and multi-turn sample schemas, result aggregation, JSONL/CSV/HF conversion, and metric annotation structures.
- `src/ragas/dataset.py`: flexible row-store abstraction used by modern datasets and experiments.
- `src/ragas/experiment.py`: `@experiment` decorator, concurrent experiment execution, result saving, and optional git versioning.
- `src/ragas/backends/`: storage interfaces and local CSV, local JSONL, in-memory, and Google Drive backends.
- `src/ragas/metrics/`: legacy metrics, simple custom metrics, decorators, validators, and metric results.
- `src/ragas/metrics/collections/`: newer direct-kwargs metric implementations with stricter modern LLM/embedding validation.
- `src/ragas/prompt/`: Pydantic prompt formatting, structured output parsing, retry/fix-output prompt, dynamic few-shot prompt storage, and language adaptation.
- `src/ragas/llms/` and `src/ragas/embeddings/`: provider wrappers/factories and adapter logic.
- `src/ragas/testset/`: knowledge graph, personas, transforms, extractors, relationship builders, and query synthesizers.
- `src/ragas/callbacks.py`, `src/ragas/executor.py`, `src/ragas/run_config.py`, `src/ragas/cache.py`: tracing, async execution, retry/timeouts/concurrency, and reproducibility support.

## Design Choices

Ragas separates test data from experiment results. This is a strong design for iterative evaluation because dataset rows stay stable while each experiment row can add model output, metric scores, trace URLs, logs, and metadata.

Metrics declare required columns and operate over typed samples. That makes missing-context failures explicit and supports different metric families for single-turn RAG samples and multi-turn tool workflows.

LLM-as-judge prompts use Pydantic schemas. `PydanticPrompt` renders instructions, JSON schema, examples, and input data, then validates output. If parsing fails on legacy `BaseRagasLLM` paths, a repair prompt tries to fix the output format.

There are two metric APIs in transition. Legacy metrics use `SingleTurnSample` / `MultiTurnSample` and `MetricWithLLM`; newer collection metrics expose direct `ascore(**kwargs)` and return `MetricResult`. This migration improves ergonomic use but adds surface area and compatibility risk.

Synthetic data generation is graph-first. Documents become nodes, extractors add summaries/entities/themes/embeddings, relationship builders connect similar nodes, and query synthesizers sample persona/style/length combinations from the graph. This is more structured than blind question generation.

Reproducibility is partly addressed through `RunConfig(seed=42)`, retry/timeout settings, cache keys, local dataset/experiment backends, `version_experiment()`, and tests. Some randomness still uses module-level `random.shuffle()` without consistently consuming `RunConfig.rng`, so synthetic scenario sampling is not fully controlled by the run config.

## Strengths

The metric catalog is broad and concrete. Faithfulness decomposes responses into statements and checks support against retrieved contexts. Context precision and recall judge retrieved contexts against references. Factual correctness decomposes claims and computes precision/recall/F1. Answer relevance uses generated questions plus embedding similarity. Agent metrics cover tool-call sequence/arguments, unordered tool-call F1, topic adherence, and outcome goal accuracy.

The dataset and experiment APIs are pragmatic. Local CSV is easy to inspect, JSONL preserves nested structures, and in-memory backends are useful for tests and train/test splits.

The framework supports verification loops beyond one-off scoring. Examples run baseline RAG, agent math, workflow classification, text-to-SQL, prompt iteration, and benchmark comparisons. Tests include metric migration utilities that compare old and new metric implementations with score deltas and timing.

Tracing is first-class enough for diagnosis. Evaluation rows, metrics, and prompts are callback groups; `RagasTracer` can parse per-row metric and prompt I/O; integrations connect to Opik, LangSmith, MLflow, Langfuse, and related tools.

Synthetic test generation is unusually relevant for retrieval agents. The graph-and-scenario pipeline can create single-hop and multi-hop questions with reference contexts and metadata for persona, style, and length.

Custom metric ergonomics are good. `DiscreteMetric`, `NumericMetric`, `RankingMetric`, and decorators let teams encode product-specific checks without implementing a full metric class.

## Weaknesses

The repo is mid-migration. Deprecated `evaluate()` docs and legacy metric classes coexist with newer `@experiment` and collections APIs. Some docs mention parameters like `in_ci` that are not present in the reviewed `evaluate()` signature.

LLM-as-judge metrics are only as reproducible as their model, prompt, structured-output adapter, cache, and calibration dataset. Ragas provides scaffolding but not automatic judge validation for a new domain.

The synthetic generation path can be expensive and brittle because it depends on LLM extraction, embeddings, graph relationships, persona mapping, and random sampling. It needs small smoke tests plus human review before being trusted.

CSV is convenient but lossy for nested agent traces and tool calls. The repo documents this, and tests explicitly show nested/mixed types are skipped for CSV correctness. JSONL is safer for coding-agent traces.

The experiment runner prints warnings and continues on per-row task failures by default. That is useful for long evals, but CI gates need explicit failure policy and thresholds.

Agent coverage is useful but not complete for coding agents. There are tool-call and goal metrics, but no built-in sandbox policy checks, filesystem side-effect assertions, patch correctness checks, or SWE-style task harness.

## Ideas To Steal

Use a `Dataset` versus `Experiment` split for Agentic Coding Lab evals.

Store experiment rows as original row plus agent output, score, score reason, trace path, git commit, runtime, and failure metadata.

Make metric required inputs explicit, so missing `retrieved_contexts`, tool calls, references, or rubrics fail early.

Adopt JSONL as the default local backend for nested coding-agent traces; keep CSV only for simple dashboards.

Build direct metrics for coding agents using the same pattern as `ToolCallAccuracy` and `ToolCallF1`: command sequence, file edit set, test command use, permission escalation, and final patch validity.

Use graph-based synthetic data for repository context evals: files/classes/functions as nodes, relationships from imports/calls/symbol overlap, then generate single-hop and multi-hop questions over code.

Cache LLM judge calls and embeddings by exact prompt/input for reproducible local iteration.

Record prompt I/O under each metric trace so failed scores can be audited.

Add a `version_experiment`-like commit capture before running expensive benchmarks, but avoid auto-staging in agent harnesses unless explicitly requested.

## Do Not Copy

Do not copy the whole RAG-specific metric catalog into a coding-agent harness. Reuse the schema, tracing, and result patterns, then define coding-specific checks.

Do not rely on CSV for traces, tool calls, nested messages, or retrieved context objects.

Do not treat LLM judge scores as ground truth without calibration, spot checks, and deterministic companion assertions.

Do not generate synthetic repository tests without preserving provenance to source nodes and reviewable reference contexts.

Do not let silent per-row experiment failures look like success in CI. CI mode needs strict failure thresholds and explicit handling of `None`, `nan`, and exceptions.

Do not assume `RunConfig(seed=42)` controls every stochastic path; inspect random usage before claiming reproducibility.

## Fit For Agentic Coding Lab

Fit is conditional but valuable. Ragas should be mined for harness patterns rather than adopted as the primary coding-agent benchmark system.

Best fit areas are RAG/context evaluation for coding agents, experiment storage, custom metrics, synthetic repository-context datasets, trace capture, and baseline comparison. We should not depend on Ragas alone for code patch verification, sandbox safety, or task execution correctness.

The most direct artifact candidate is an Agentic Coding Lab mini-harness with `Dataset`/`Experiment` semantics, JSONL storage, deterministic code checks, optional LLM judges, trace links, and synthetic code-context samples generated from a repository graph.

## Reviewed Paths

- `/tmp/myagents-research/vibrantlabsai-ragas/README.md`
- `/tmp/myagents-research/vibrantlabsai-ragas/pyproject.toml`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/__init__.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/evaluation.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/dataset_schema.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/dataset.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/experiment.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/backends/base.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/backends/registry.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/backends/local_csv.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/backends/local_jsonl.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/backends/inmemory.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/metrics/base.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/metrics/discrete.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/metrics/numeric.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/metrics/ranking.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/metrics/decorator.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/metrics/_faithfulness.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/metrics/_context_precision.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/metrics/_context_recall.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/metrics/_answer_relevance.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/metrics/_answer_correctness.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/metrics/_factual_correctness.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/metrics/_tool_call_accuracy.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/metrics/_tool_call_f1.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/metrics/_goal_accuracy.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/metrics/_topic_adherence.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/metrics/collections/base.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/metrics/collections/faithfulness/metric.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/metrics/collections/tool_call_accuracy/metric.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/metrics/collections/agent_goal_accuracy/metric.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/prompt/pydantic_prompt.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/prompt/dynamic_few_shot.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/llms/base.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/cache.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/callbacks.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/executor.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/run_config.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/testset/graph.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/testset/synthesizers/generate.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/testset/synthesizers/base.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/testset/synthesizers/__init__.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/testset/synthesizers/single_hop/base.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/testset/synthesizers/single_hop/specific.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/testset/synthesizers/multi_hop/base.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/testset/synthesizers/multi_hop/specific.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/testset/transforms/base.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/testset/transforms/default.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/testset/transforms/engine.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/testset/transforms/extractors/llm_based.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/testset/transforms/relationship_builders/traditional.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/optimizers/base.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/optimizers/dspy_optimizer.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/docs/concepts/datasets.md`
- `/tmp/myagents-research/vibrantlabsai-ragas/docs/concepts/experimentation.md`
- `/tmp/myagents-research/vibrantlabsai-ragas/docs/concepts/components/eval_dataset.md`
- `/tmp/myagents-research/vibrantlabsai-ragas/docs/concepts/metrics/available_metrics/index.md`
- `/tmp/myagents-research/vibrantlabsai-ragas/docs/concepts/metrics/available_metrics/agents.md`
- `/tmp/myagents-research/vibrantlabsai-ragas/docs/concepts/test_data_generation/rag.md`
- `/tmp/myagents-research/vibrantlabsai-ragas/docs/getstarted/quickstart.md`
- `/tmp/myagents-research/vibrantlabsai-ragas/docs/getstarted/evals.md`
- `/tmp/myagents-research/vibrantlabsai-ragas/docs/howtos/applications/add_to_ci.md`
- `/tmp/myagents-research/vibrantlabsai-ragas/examples/ragas_examples/rag_eval/evals.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/examples/ragas_examples/improve_rag/evals.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/examples/ragas_examples/agent_evals/evals.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/examples/ragas_examples/workflow_eval/evals.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/tests/unit/test_experiment.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/tests/unit/test_dataset_schema.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/tests/unit/test_metric.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/tests/unit/test_validation.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/tests/unit/test_tool_call_accuracy.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/tests/unit/test_tool_call_f1.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/tests/unit/test_tool_call_accuracy_collections.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/tests/unit/test_quoted_spans_collections.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/tests/unit/test_single_hop_query_synthesizer.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/tests/unit/test_multi_hop_query_synthesizer.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/tests/unit/test_prechunked_generation.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/tests/e2e/test_testset_generation.py`
- `/tmp/myagents-research/vibrantlabsai-ragas/tests/utils/metric_comparison.py`

## Excluded Paths

- `/tmp/myagents-research/vibrantlabsai-ragas/.git/`: VCS internals; commit captured separately.
- `/tmp/myagents-research/vibrantlabsai-ragas/.github/`: CI workflow implementation; sampled indirectly through repo metadata, not central to RAG eval architecture.
- `/tmp/myagents-research/vibrantlabsai-ragas/.agents/`, `.claude/`, `.codex/`, `.cursor/`: local AI-assistant instructions and commands; not the eval framework being reviewed.
- `/tmp/myagents-research/vibrantlabsai-ragas/docs/_static/` and `docs/extra/`: images, CSS, fonts, JavaScript, and docs theming assets; UI/static only.
- `/tmp/myagents-research/vibrantlabsai-ragas/docs/**/*.ipynb`: notebook variants of docs; Markdown and source files provided enough architecture signal.
- `/tmp/myagents-research/vibrantlabsai-ragas/docs/howtos/integrations/`: integration tutorials sampled by source integrations; full notebook/docs sweep would be integration-specific rather than core harness review.
- `/tmp/myagents-research/vibrantlabsai-ragas/examples/ragas_examples/*/datasets/` and test data CSV/JSON files: sample data artifacts; reviewed examples using them, not every row.
- `/tmp/myagents-research/vibrantlabsai-ragas/examples/ragas_examples/ag_ui_agent_experiments/`: AG-UI example path; UI/protocol-specific, not core eval harness.
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/integrations/`: sampled tracing/observability integration files; did not review every third-party adapter because core adapter pattern was clear.
- `/tmp/myagents-research/vibrantlabsai-ragas/src/ragas/metrics/collections/*/util.py`: utilities sampled through metric implementations and tests where relevant; not every prompt constant reviewed line-by-line.
- `/tmp/myagents-research/vibrantlabsai-ragas/tests/e2e/metrics_migration/*.ipynb`: migration analysis notebooks; `tests/utils/metric_comparison.py` and migration plan provided sufficient verification-loop signal.
- `/tmp/myagents-research/vibrantlabsai-ragas/tests/benchmarks/`: performance benchmark scripts; useful but secondary to architecture and metric semantics.
- `/tmp/myagents-research/vibrantlabsai-ragas/scripts/`, `Makefile`, `.pre-commit-config.yaml`: repo maintenance tooling, not evaluation runtime.
- Binary/static assets such as `.png`, `.jpg`, `.gif`, `.ico`, `.ttf`, `.svg`: generated or visual documentation assets, not source architecture.
