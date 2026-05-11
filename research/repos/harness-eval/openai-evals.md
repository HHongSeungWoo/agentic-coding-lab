# openai/evals

- URL: https://github.com/openai/evals
- Category: harness-eval
- Stars snapshot: 18,438 (GitHub REST API, captured 2026-05-12)
- Reviewed commit: 8eac7a7de5215c907fbddc30efdaf316913eccdd
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: in-scope
- Verdict: Foundational Python eval harness with a large declarative registry, reusable scoring templates, event logs, model/provider adapters, and early solver abstractions for stateful or tool-using agents. Best patterns to steal are registry-driven eval definitions, per-sample deterministic seeding, event-first logging, model-graded YAML prompts, and SolverEval separation between task environment and solver strategy. Main limits are stale model metadata, weak sandboxing, costly external-provider dependence, Git-LFS data friction, and a beta solver layer with uneven test coverage.

## Why It Matters

OpenAI Evals is one of the canonical public examples of an LLM evaluation harness. It matters for agentic coding because it shows how a benchmark runner can separate eval definitions, data, scoring logic, model/provider adapters, run metadata, and result logs.

The repo is especially useful for designing coding-agent verification because it contains both simple deterministic templates and more agent-like evals: tool-use conversations, bugged-tool detection, retrieval-based skill acquisition, error recovery from wrong reasoning, and self-prompting. These are not coding-agent benchmarks directly, but they model patterns a coding-agent lab needs: task state, solver state isolation, tool loops, final-answer extraction, log replay, and aggregate metrics.

## What It Is

OpenAI Evals is a Python package and CLI framework for evaluating LLMs and LLM systems. It exposes `oaieval` for one eval and `oaievalset` for eval sets. Users register evals in YAML under `evals/registry/evals`, datasets under `evals/registry/data`, completion functions under `evals/registry/completion_fns`, solver specs under `evals/registry/solvers`, model-graded rubrics under `evals/registry/modelgraded`, and eval sets under `evals/registry/eval_sets`.

At runtime, the CLI resolves an eval name from the registry, resolves one or more model/completion/solver targets, builds a `RunSpec`, creates a recorder, instantiates the eval class from a dotted Python path, runs all samples, logs events, then records a final report. The package ships reusable templates such as `Match`, `Includes`, `FuzzyMatch`, `JsonMatch`, `JsonValidator`, and `ModelBasedClassify`, plus custom `elsuite` evals for more complex multi-turn tasks.

## Research Themes

- Token efficiency: Moderate. It records token usage from sampling events and some eval docs include token estimates, but it does not optimize context or compress prompts.
- Context control: Strong for harness structure. Prompts, datasets, model-graded rubrics, solver specs, eval sets, seed, command, and run config are explicit artifacts.
- Sub-agent / multi-agent: Conditional. `SolverEval`, `NestedSolver`, CoT/extract solvers, self-prompting Prompter/Tasker flows, and multi-completion model-graded comparisons provide patterns, but there is no general multi-agent orchestration runtime.
- Domain-specific workflow: Strong. `elsuite` contains many domain evals plus tool-use, retrieval, reasoning-recovery, and prompt-generation workflows.
- Error prevention: Strong. Deterministic matchers, JSON validators, model-graded meta-evals, registry tests, dummy eval CI, and bugged-tool/error-recovery suites map well to regression testing.
- Self-learning / memory: Limited but relevant. `PersistentMemoryCache` supports private CoT interaction reuse inside nested solvers; skill-acquisition evaluates retrieval-aided learning, but the harness does not provide durable adaptive memory.
- Popular skills: Not a skill repo. Useful reusable capabilities are registry specs, eval templates, event recorder, `CompletionFn`, `Solver`, `TaskState`, `SolverEval`, model-graded YAML, and CI smoke runs with `dummy`.

## Core Execution Path

`oaieval` is implemented in `evals/cli/oaieval.py`. The parser accepts a completion function or comma-separated list, an eval name, optional registry paths, sample limits, seed, cache flag, recording mode, HTTP recorder options, dry-run mode, and extra eval/completion args.

`run()` creates or receives a `Registry`, adds custom registry paths, resolves the eval spec, merges `--extra_eval_params`, creates completion function instances through `registry.make_completion_fn()`, builds a `RunSpec` containing completion IDs, eval spec, seed, max samples, command, and visibility settings, then selects a recorder. It instantiates the eval class through `registry.get_class(eval_spec)` and calls `eval.run(recorder)`. After completion, it sums token usage from `sampling` events when present and records the final report.

`Registry` loads YAML resources from the package registry and `~/.evals` by default. It supports `evals`, `eval_sets`, `completion_fns`, `solvers`, and `modelgraded`. Each YAML key becomes a spec with injected `key`, `group`, and `registry_path`; `class` is normalized to `cls`; aliases dereference through string values or `id` fields. Registry values instantiate classes dynamically through dotted paths.

`Eval.eval_all_samples()` shuffles sample indexes with fixed `SHUFFLE_SEED = 123`, optionally truncates via `--max_samples`, assigns stable sample IDs from `<base>.<split>.<idx>`, seeds each sample RNG with `<sample_id>:<seed>`, and runs samples through a thread pool unless `EVALS_SEQUENTIAL` is set. `SolverEval` does the same but copies the solver per sample, so stateful solvers do not leak state across samples.

`oaievalset` resolves an eval set into concrete `oaieval` commands, writes progress to `/tmp/oaievalset/{model}.{eval_set}.progress.txt`, and can resume completed commands. It is a simple subprocess loop, not a richer scheduler.

## Architecture

The architecture is centered on registry-driven dynamic loading:

- `evals/cli/oaieval.py`: single-eval CLI, run config, recorder selection, eval instantiation, final report.
- `evals/cli/oaievalset.py`: eval-set expansion, subprocess execution, progress file resume.
- `evals/registry.py`: YAML loading, alias dereference, model/completion/solver resolution, class lookup.
- `evals/base.py`: dataclass specs for completion functions, evals, eval sets, and runs.
- `evals/eval.py`: `Eval` and `SolverEval` base classes, sample shuffling, per-sample seeding, threaded execution.
- `evals/record.py`: event model, default recorder context, local JSONL recorder, HTTP recorder, Snowflake recorder, final reports.
- `evals/api.py`: `CompletionFn`, `CompletionResult`, dummy target, and `record_and_check_match()`.
- `evals/metrics.py`: shared metrics such as accuracy, bootstrap accuracy std, confusion matrix, precision, recall, F-score.
- `evals/completion_fns/`: old completion-function adapters for OpenAI, LangChain, retrieval, CoT, and solver wrapping.
- `evals/solvers/`: newer solver abstraction with `TaskState`, provider solvers, nested solvers, postprocessors, and memory.
- `evals/elsuite/`: eval implementations, from simple templates to custom multi-turn task environments.
- `evals/registry/`: declarative eval, eval-set, completion-fn, solver, model-graded, and data registry.
- `docs/` and `examples/`: user workflows for building evals, registering data, custom eval code, completion functions, and notebooks.

## Design Choices

Declarative registries are the central design choice. A basic eval can be added by creating JSONL data plus a YAML file with a base alias, metrics, class path, and args. Model-graded evals add another YAML layer under `modelgraded`, making the grading prompt, choice strings, input-output mapping, and choice scores reusable across evals.

The harness distinguishes base eval aliases from concrete versioned eval IDs. Names like `coqa-match` point to `coqa-match.dev.v0`; the concrete ID selects a class and data path. This supports stable human-facing names while preserving versioned reproducibility.

Scoring is event-first. Eval code records sample-level `match`, `metrics`, `sampling`, `error`, `function_call`, `raw_sample`, and extra events through the default recorder. Final reports are aggregations over recorded events, not hidden mutable counters. Local logs start with serialized run spec and end with `final_report`.

Provider abstraction exists in two generations. `CompletionFn` is a minimal prompt-to-completions protocol, good for simple eval templates and arbitrary wrappers. `Solver` is a richer abstraction where evals pass a `TaskState` containing task description, conversation messages, and current state; solvers return a `SolverResult` with output and metadata. `maybe_wrap_with_compl_fn()` and `maybe_wrap_with_solver()` provide backward compatibility between the two.

`SolverEval` is the better pattern for agent-like evaluation. It gives each sample a copied solver, avoiding state bleed, and lets the eval environment own messages, turns, tools, and grading. `bugged_tools`, `skill_acquisition`, `error_recovery`, and `self_prompting` demonstrate this more than the basic templates do.

Reproducibility is partially encoded. The run spec records seed, command, eval spec, completion function names, max samples, and creation metadata. Samples are shuffled deterministically and per-sample RNGs are deterministic. However, model aliases, provider behavior, external APIs, dependencies, Git-LFS data availability, and environment variables are not fully pinned by a run log.

## Strengths

The registry model is simple and powerful. It lets non-code contributors add many evals with data and YAML, while still allowing custom Python eval classes where necessary.

Event logs are practical. They support local JSONL inspection, final aggregation, token usage summaries when providers log usage, and alternate sinks through HTTP or Snowflake.

The model-graded template captures a useful declarative grading pattern. `ModelBasedClassify` separates policy completion, grading prompt, choice parsing, score mapping, multi-completion comparisons, and optional meta-eval labels.

The `SolverEval` split is highly relevant for coding agents. The eval controls environment dynamics while the solver controls strategy. This maps cleanly to coding tasks where the harness owns repo state, test commands, tool outputs, and pass/fail grading.

The advanced eval suites provide useful verification patterns: bugged-tool detection tracks whether a solver detects faulty tools; error recovery compares no/correct/incorrect reasoning conditions; skill acquisition compares direct answers against retrieval-aided loops; self-prompting evaluates generated prompts by running downstream taskers.

The CI contains a cheap registry smoke pattern: for new eval YAML files, parse the first key and run `oaieval dummy <eval> --max_samples 10`. This is a good low-cost guard for registry/class/data wiring.

## Weaknesses

The project shows age in model metadata. `n_ctx_from_model_name()` and `is_chat_model()` hardcode older OpenAI model names, and registry solvers use model IDs such as `gpt-4`, `gpt-4-0613`, and `gpt-4-turbo-preview`. Reproducible modern runs need explicit model snapshots or updated adapters.

The solver layer is marked beta and has uneven coverage. There are tests for generic solvers, Anthropic/Gemini message formatting, postprocessors, and basic eval templates, but no broad test matrix for all provider solvers, nested solvers, multi-turn envs, or registry YAML combinations.

External APIs are central. Many real evals require OpenAI or other provider keys, and some tests are skipped in GitHub Actions because API tests are costly. Offline verification is mostly limited to dummy runs and unit tests.

Data reproducibility depends on Git LFS. In this research clone, `git lfs` was unavailable, and data files such as `coqa/match.jsonl` and `test_modelgraded/joke_fruits.jsonl` appeared as LFS pointer files. The harness documents this, but it adds friction for local replication.

There is no strong sandbox/permission model. Tool-like evals are Python code running in-process, and provider solvers call external APIs. For coding-agent verification, filesystem, network, process, and secret boundaries would need to be supplied outside this harness.

`oaievalset` is coarse. It resumes whole eval commands, not individual samples, and `run-evals.md` explicitly says single evals cannot resume from the middle.

Some docs and PR guidance are stale or inconsistent. The README points users toward Dashboard Evals, while repository internals still carry older model IDs and contribution notes.

## Ideas To Steal

Use a registry layout with separate directories for eval definitions, eval sets, solver/provider specs, grading rubrics, and datasets.

Represent every run as a serialized spec before sample events, then append final report. Make logs replayable without a database.

Give each sample a stable ID, deterministic per-sample seed, and isolated solver copy. This prevents accidental state coupling in parallel agent evals.

Separate deterministic scoring from model-graded scoring. Use deterministic matchers for correctness, JSON validity, tool-call shape, and file diffs; reserve model graders for fuzzy qualitative judgment.

Add a model-graded meta-eval path where human labels calibrate the grader itself before trusting its score.

Adopt `TaskState` style interfaces for coding agents: task description, message history, and explicit current state. Keep environment/tool mechanics in the eval, not inside the model adapter.

Use dummy targets in CI to verify registry wiring and harness execution without spending tokens.

Track tool-loop metrics beyond final accuracy: invalid calls, correct retrieval calls, used-bugged-input rate, turns, timeouts, context-limit failures, precision, recall, and F1.

## Do Not Copy

Do not rely on hardcoded model-name heuristics for current providers. Use provider metadata or explicit model capability config.

Do not treat model-graded scores as authoritative for high-stakes coding-agent verification. Calibrate with labels and pair with deterministic tests.

Do not run coding-agent evals in-process without a sandbox. OpenAI Evals is a harness, not a permission boundary.

Do not make large benchmark data an implicit dependency. Pin data versions, verify LFS availability, and provide tiny smoke datasets.

Do not copy the full registry scale if the local need is a small verification loop. The valuable part is the artifact boundary, not thousands of benchmark YAML files.

Do not use whole-eval resume only for expensive agent runs. Coding-agent tasks need sample-level checkpointing, artifacts, and cleanup.

## Fit For Agentic Coding Lab

Fit is strongly in-scope for harness-eval research. OpenAI Evals is not a coding-agent product, but it is a high-value reference for how to make evals declarative, versioned, runnable by CLI, logged as events, and extensible across models.

Agentic Coding Lab should adapt the registry boundaries, `TaskState`/`SolverEval` split, deterministic sample seeding, event logs, dummy CI smoke tests, and multi-metric tool-loop evaluation. It should not copy the older provider registry wholesale or assume API-model evals are enough for coding agents. A coding-agent harness needs stronger sandboxing, repo snapshot control, test-command capture, patch/diff artifacts, and sample-level resume.

## Reviewed Paths

- `/tmp/myagents-research/openai-evals/README.md`
- `/tmp/myagents-research/openai-evals/LICENSE.md`
- `/tmp/myagents-research/openai-evals/SECURITY.md`
- `/tmp/myagents-research/openai-evals/pyproject.toml`
- `/tmp/myagents-research/openai-evals/Makefile`
- `/tmp/myagents-research/openai-evals/docs/run-evals.md`
- `/tmp/myagents-research/openai-evals/docs/build-eval.md`
- `/tmp/myagents-research/openai-evals/docs/custom-eval.md`
- `/tmp/myagents-research/openai-evals/docs/eval-templates.md`
- `/tmp/myagents-research/openai-evals/docs/completion-fns.md`
- `/tmp/myagents-research/openai-evals/docs/completion-fn-protocol.md`
- `/tmp/myagents-research/openai-evals/evals/cli/oaieval.py`
- `/tmp/myagents-research/openai-evals/evals/cli/oaievalset.py`
- `/tmp/myagents-research/openai-evals/evals/registry.py`
- `/tmp/myagents-research/openai-evals/evals/base.py`
- `/tmp/myagents-research/openai-evals/evals/eval.py`
- `/tmp/myagents-research/openai-evals/evals/api.py`
- `/tmp/myagents-research/openai-evals/evals/record.py`
- `/tmp/myagents-research/openai-evals/evals/metrics.py`
- `/tmp/myagents-research/openai-evals/evals/data.py`
- `/tmp/myagents-research/openai-evals/evals/completion_fns/openai.py`
- `/tmp/myagents-research/openai-evals/evals/solvers/README.md`
- `/tmp/myagents-research/openai-evals/evals/solvers/solver.py`
- `/tmp/myagents-research/openai-evals/evals/solvers/utils.py`
- `/tmp/myagents-research/openai-evals/evals/solvers/memory.py`
- `/tmp/myagents-research/openai-evals/evals/task_state.py`
- `/tmp/myagents-research/openai-evals/evals/solvers/providers/openai/openai_solver.py`
- `/tmp/myagents-research/openai-evals/evals/solvers/providers/anthropic/anthropic_solver.py`
- `/tmp/myagents-research/openai-evals/evals/solvers/providers/google/gemini_solver.py`
- `/tmp/myagents-research/openai-evals/evals/solvers/nested/cot_solver.py`
- `/tmp/myagents-research/openai-evals/evals/elsuite/basic/match.py`
- `/tmp/myagents-research/openai-evals/evals/elsuite/basic/includes.py`
- `/tmp/myagents-research/openai-evals/evals/elsuite/basic/fuzzy_match.py`
- `/tmp/myagents-research/openai-evals/evals/elsuite/modelgraded/classify.py`
- `/tmp/myagents-research/openai-evals/evals/elsuite/modelgraded/classify_utils.py`
- `/tmp/myagents-research/openai-evals/evals/elsuite/modelgraded/base.py`
- `/tmp/myagents-research/openai-evals/evals/elsuite/solver_tools_convo.py`
- `/tmp/myagents-research/openai-evals/evals/elsuite/bugged_tools/README.md`
- `/tmp/myagents-research/openai-evals/evals/elsuite/bugged_tools/eval.py`
- `/tmp/myagents-research/openai-evals/evals/elsuite/bugged_tools/tools.py`
- `/tmp/myagents-research/openai-evals/evals/elsuite/error_recovery/README.md`
- `/tmp/myagents-research/openai-evals/evals/elsuite/error_recovery/eval.py`
- `/tmp/myagents-research/openai-evals/evals/elsuite/skill_acquisition/readme.md`
- `/tmp/myagents-research/openai-evals/evals/elsuite/skill_acquisition/eval.py`
- `/tmp/myagents-research/openai-evals/evals/elsuite/self_prompting/readme.md`
- `/tmp/myagents-research/openai-evals/evals/elsuite/self_prompting/eval.py`
- `/tmp/myagents-research/openai-evals/evals/registry/evals/test-basic.yaml`
- `/tmp/myagents-research/openai-evals/evals/registry/evals/test-modelgraded.yaml`
- `/tmp/myagents-research/openai-evals/evals/registry/evals/coqa-ex.yaml`
- `/tmp/myagents-research/openai-evals/evals/registry/evals/bugged_tools.yaml`
- `/tmp/myagents-research/openai-evals/evals/registry/evals/error_recovery.yaml`
- `/tmp/myagents-research/openai-evals/evals/registry/evals/skill_acquisition.yaml`
- `/tmp/myagents-research/openai-evals/evals/registry/eval_sets/test-basic.yaml`
- `/tmp/myagents-research/openai-evals/evals/registry/eval_sets/coqa-ex.yaml`
- `/tmp/myagents-research/openai-evals/evals/registry/completion_fns/langchain_llms.yaml`
- `/tmp/myagents-research/openai-evals/evals/registry/solvers/defaults.yaml`
- `/tmp/myagents-research/openai-evals/evals/registry/solvers/anthropic.yaml`
- `/tmp/myagents-research/openai-evals/evals/registry/solvers/gemini.yaml`
- `/tmp/myagents-research/openai-evals/evals/registry/solvers/together.yaml`
- `/tmp/myagents-research/openai-evals/evals/registry/solvers/error_recovery.yaml`
- `/tmp/myagents-research/openai-evals/evals/registry/modelgraded/humor.yaml`
- `/tmp/myagents-research/openai-evals/evals/registry/modelgraded/fact.yaml`
- `/tmp/myagents-research/openai-evals/evals/registry/data/README.md`
- `/tmp/myagents-research/openai-evals/examples/*.ipynb` scanned for registry, eval-building, and log-processing patterns.
- `/tmp/myagents-research/openai-evals/evals/registry_test.py`
- `/tmp/myagents-research/openai-evals/evals/record_test.py`
- `/tmp/myagents-research/openai-evals/tests/unit/evals/test_metrics.py`
- `/tmp/myagents-research/openai-evals/evals/solvers/solver_test.py`
- `/tmp/myagents-research/openai-evals/evals/solvers/providers/anthropic/anthropic_solver_test.py`
- `/tmp/myagents-research/openai-evals/evals/solvers/providers/google/gemini_solver_test.py`
- `/tmp/myagents-research/openai-evals/evals/elsuite/basic/match_test.py`
- `/tmp/myagents-research/openai-evals/evals/elsuite/basic/json_match_test.py`
- `/tmp/myagents-research/openai-evals/evals/elsuite/basic/json_validator_test.py`
- `/tmp/myagents-research/openai-evals/.github/workflows/run_tests.yaml`
- `/tmp/myagents-research/openai-evals/.github/workflows/test_eval.yaml`
- `/tmp/myagents-research/openai-evals/.github/workflows/parse_yaml.py`
- `/tmp/myagents-research/openai-evals/.github/PULL_REQUEST_TEMPLATE.md`

## Excluded Paths

- `/tmp/myagents-research/openai-evals/.git/`: VCS internals; exact reviewed commit recorded separately.
- `/tmp/myagents-research/openai-evals/evals/registry/data/**`: benchmark payloads are mostly Git-LFS-managed data; local clone lacked `git lfs`, so full data bodies were not pulled. Reviewed data README, registry references, and pointer files for harness architecture.
- `/tmp/myagents-research/openai-evals/evals/registry/evals/*.yaml` beyond representative files: hundreds of benchmark registrations use the same schema; sampled representative basic, model-graded, CoQA, bugged-tools, error-recovery, and skill-acquisition entries.
- `/tmp/myagents-research/openai-evals/evals/registry/eval_sets/*.yaml` beyond representative files: eval-set schema is simple list expansion; sampled test and CoQA sets.
- `/tmp/myagents-research/openai-evals/evals/registry/modelgraded/*.yaml` beyond representative files: model-graded rubric schema reviewed through `humor` and `fact`; remaining files are additional rubric content.
- `/tmp/myagents-research/openai-evals/evals/registry/solvers/*.yaml` beyond provider/default/error-recovery files: solver registry pattern reviewed; remaining files are task-specific solver presets.
- `/tmp/myagents-research/openai-evals/evals/elsuite/**/scripts/**`: dataset generation, plotting, and experiment shell scripts; useful for reproducing papers, not core harness architecture.
- `/tmp/myagents-research/openai-evals/scripts/**`: helper generators for eval content; not part of runtime path for `oaieval`.
- `/tmp/myagents-research/openai-evals/examples/*.ipynb` full outputs: notebooks were scanned for workflow patterns but not read cell-by-cell as UI/tutorial artifacts.
- `/tmp/myagents-research/openai-evals/evals/elsuite/**/README.md` and custom evals beyond selected agent-like suites: sampled high-relevance suites; full benchmark-by-benchmark review would be separate research.
- `/tmp/myagents-research/openai-evals/evals/solvers/providers/together/**`, most LangChain/retrieval completion functions, and individual postprocessors: provider abstraction reviewed through OpenAI, Anthropic, Gemini, registry YAML, and solver utilities; every adapter is not needed to understand architecture.
- `/tmp/myagents-research/openai-evals/MANIFEST.in`, `mypy.ini`, formatter/pre-commit details, and package metadata beyond `pyproject.toml`: ancillary build/config files, not harness behavior.
- Vendored/binary/UI-only paths: no vendored dependency tree or product UI implementation found in this repo snapshot; binary-like data is handled through Git-LFS and excluded above.
