# open-compass/opencompass

- URL: https://github.com/open-compass/opencompass
- Category: harness-eval
- Stars snapshot: 6,984 (GitHub REST API, captured 2026-05-12)
- Reviewed commit: 0524d4992ecda339148b8f59c4cc41991deafc37
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: in-scope
- Verdict: Large, active, config-first LLM benchmark harness with strong model/dataset/evaluator registries, distributed runners, API concurrency, reproducible prediction/result artifacts, leaderboard summaries, and coding-benchmark coverage. Best patterns to steal are Python config composition, explicit infer/eval artifact boundaries, model/template abstraction, prompt-hash versioning, result station persistence, cascade judging, and runner/partitioner separation. Main limits for an agentic coding lab are weak environment/data/model pinning, Python-code configs as a trust boundary, broad mutable dependencies, uneven end-to-end coverage, external code-eval services, and no native repo-editing agent loop.

## Why It Matters

OpenCompass is a production-scale open LLM evaluation platform rather than a small research demo. It supports many local, accelerated, and API model backends; many academic and domain datasets; multiple prompting modes; LLM-as-judge evaluation; result summarization; and distributed execution. That makes it a high-signal reference for how a public benchmark harness handles scale, configuration, reporting, and repeatable artifact layout.

It matters for agentic coding research because it already covers coding benchmarks such as HumanEval, MBPP, LiveCodeBench, CodeCompass, DS1000, and code pass@k workflows. It is not a coding-agent harness in the SWE-bench sense, but its registry, runner, model abstraction, evaluator, and reporting patterns are directly useful for building one.

## What It Is

OpenCompass is a Python package and CLI. The root `run.py` imports `opencompass.cli.main`, and the installed console script is `opencompass`. Users run either a full Python config file or compose a run from `--models` and `--datasets`. Configs live inside the package under `opencompass/configs`, with model configs under `configs/models` and dataset configs under `configs/datasets` or `configs/dataset_collections`.

At runtime, the CLI resolves configs, creates a timestamped work directory, dumps the exact resolved config, runs inference tasks to produce prediction JSON files, runs evaluation tasks to produce result JSON files, then summarizes results into text/CSV reports. The central execution substrate is OpenICL: dataset readers, prompt templates, retrievers, inferencers, postprocessors, and evaluators are all registered components.

## Research Themes

- Token efficiency: Moderate. The harness tracks model max sequence length, output length, prompt hashes, API rate limits, and token length helpers, but it is not mainly a prompt-compression or context-budget optimizer.
- Context control: Strong. Dataset reader ranges, few-shot retrieval, prompt templates, model meta templates, generation parameters, `n`/`k` repeated runs, postprocessors, and evaluator settings are explicit in Python configs.
- Sub-agent / multi-agent: Limited. There is concurrent API execution and LLM-judge/cascade evaluation, but no general multi-agent runtime, planner, tool router, or stateful agent society.
- Domain-specific workflow: Strong. The repository has many benchmark-specific loaders, postprocessors, and evaluators across academic, math, code, safety, science, multimodal-adjacent, and leaderboard workflows.
- Error prevention: Moderate. There are unit tests for prompts, model adapters, partitioners, concurrent inferencers, watch tasks, summarizers, and representative dataset evaluators. Full CLI/e2e and every-dataset-config coverage is much thinner.
- Self-learning / memory: Limited. Result station persistence, prediction reuse, cache paths, and resumable inference are useful replay mechanisms, but the harness does not implement adaptive memory or learning across runs.
- Popular skills: Not a skill repository. Reusable capabilities are config packs, registries, prompt templates, model adapters, retrievers, inferencers, postprocessors, evaluators, runners, partitioners, summarizers, and result-station artifacts.

## Core Execution Path

`opencompass.cli.main` parses the command line, builds or loads a `Config`, initializes distributed mode when needed, builds a timestamped `work_dir`, dumps the resolved config to `work_dir/configs/<timestamp>_<pid>.py`, then reloads it with `Config.fromfile`. Reloading avoids serialization issues with initialized Python objects in configs.

`opencompass.utils.run.get_config_from_arg()` resolves config files. With a user config, it loads that file, applies custom dataset/chatml/accelerator options, and normalizes work-dir fields. Without a user config, it recursively resolves named model and dataset config files from `opencompass/configs/models`, `opencompass/configs/datasets`, dataset collections, and package defaults. It also applies `--dataset-num-runs` by setting dataset `n` and `k`, and can switch HuggingFace-style configs to vLLM or LMDeploy accelerator configs.

The default infer config is filled with `NumWorkerPartitioner` and `LocalRunner(task=OpenICLInferTask)`. The default eval config is filled with `NaivePartitioner` and `LocalRunner(task=OpenICLEvalTask)`. Slurm, DLC, local API, and other runners can replace the local runner through config or CLI options.

For inference, the partitioner receives all model/dataset combinations and outputs task configs pointing at `work_dir/predictions`. `OpenICLInferTask` builds each model, loads each dataset, builds the prompt template, retriever, and inferencer, then writes predictions under `predictions/<model_abbr>/<dataset_abbr>.json`. Generation, PPL, chat, ChatML, and parallel API inferencers share this artifact boundary.

For evaluation, the partitioner points at `work_dir/results`. `OpenICLEvalTask` loads the dataset and predictions, applies dataset and model postprocessors, builds the configured evaluator, calls `evaluate()`, and writes `results/<model_abbr>/<dataset_abbr>.json`. It can dump per-sample details and can evaluate split prediction fragments.

For visualization, the CLI builds a summarizer, usually `DefaultSummarizer`, over the result directory. Summaries include model columns, dataset names, version hashes, metrics, and modes, and can be written to summary files. The optional result station stores predictions, results, and config per model/dataset so future runs can read or reuse artifacts.

## Architecture

The architecture is registry-driven and config-first:

- `opencompass/cli/main.py`: CLI argument parsing, mode selection, config dumping/reloading, infer/eval/viz orchestration, result station integration.
- `opencompass/utils/run.py`: model/dataset config resolution, accelerator conversion, default infer/eval config filling, Slurm/local runner defaults.
- `opencompass/registry.py`: MMEngine registries for partitioners, runners, tasks, models, dataset loaders, postprocessors, evaluators, OpenICL inferencers, retrievers, readers, prompt templates, metrics, and tree-of-thought wrappers.
- `opencompass/partitioners/`: task splitting. `NaivePartitioner` groups model/dataset chunks, `NumWorkerPartitioner` splits by dataset size and worker count, and size/sub partitioners handle larger scheduling variants.
- `opencompass/runners/`: execution backends. `LocalRunner` schedules subprocesses over visible GPUs, `LocalAPIRunner` manages concurrent API users, and Slurm/DLC/RJob/Volc runners emit cluster job commands.
- `opencompass/tasks/`: task wrappers. `OpenICLInferTask`, `OpenICLInferConcurrentTask`, `OpenICLEvalTask`, and `OpenICLEvalWatchTask` bridge config tasks to model, dataset, inferencer, and evaluator components.
- `opencompass/openicl/`: prompt/data/inference/evaluation machinery: `DatasetReader`, `PromptTemplate`, retrievers, generation/PPL/chat inferencers, parallel API inferencers, and base/HF/custom evaluators.
- `opencompass/models/`: unified model interfaces for HuggingFace, vLLM, LMDeploy-style configs, OpenAI/API adapters, streaming APIs, and other provider/backend wrappers.
- `opencompass/datasets/`: registered dataset loaders, postprocessors, and custom evaluators for many benchmarks.
- `opencompass/evaluator/`: higher-level evaluators such as generic LLM judge, cascade evaluator, and math verifier wrappers.
- `opencompass/summarizers/`: summary table generation, grouping, weighting, and function/subjective summarizers.
- `opencompass/utils/datasets.py` and `opencompass/utils/result_station.py`: dataset source/cache resolution and portable result persistence.

## Design Choices

Python config files are the main benchmark definition format. A dataset config typically declares `reader_cfg`, `infer_cfg`, `eval_cfg`, and a `*_datasets` list. Model configs declare model class, path or API metadata, generation limits, batch size, rate limits, and `run_cfg`. This lets configs import shared variables, loop over subject lists, and compose variants, but it also means config loading executes Python code.

Dataset config filenames often include a short hash suffix and alias files such as `mmlu_gen.py` import a selected versioned config. The summarizer reports a version hash derived from prompt/eval settings, so leaderboard rows can distinguish prompt/evaluator variants even when dataset names are similar.

Registries are broad and permissive. `opencompass.registry` uses MMEngine `Registry`, and its wrapper defaults module registration to `force=True`. This lowers extension friction for research configs but can hide accidental key collisions.

The harness separates inference and evaluation artifacts. Predictions and results are plain JSON files in stable per-model/per-dataset directories. This enables reuse, `--reuse`, `--mode eval`, eval-watch mode, station persistence, and offline result summarization.

The model abstraction separates raw model calls from prompt formatting. `BaseModel` exposes `generate`, `get_ppl`, tokenization helpers, and template-aware methods such as `generate_from_template`. `BaseAPIModel` adds token-bucket style rate limiting and semaphore support. Provider classes such as `OpenAI`, `HuggingFace`, and `VLLM` implement the shared surface.

OpenICL is the benchmark inner loop. `DatasetReader` normalizes train/test splits and ranges; `PromptTemplate` produces structured prompt lists; retrievers select in-context examples; inferencers call models; evaluators score predictions. This is a clean boundary for adding new task families.

Evaluation is intentionally plural. Simple metrics use `AccEvaluator`, `EMEvaluator`, Rouge/BLEU/SQuAD/HF metric wrappers, or benchmark-specific evaluators. Fuzzy and reasoning-heavy tasks can use `GenericLLMEvaluator`, `MATHVerifyEvaluator`, or `CascadeEvaluator`, where a deterministic verifier runs first and an LLM judge handles remaining samples.

## Strengths

The config library is extensive and practical. Model configs cover local HuggingFace, vLLM, LMDeploy, OpenAI-style APIs, and many named model families. Dataset configs cover both simple PPL multiple-choice and generated-answer tasks with benchmark-specific extraction.

The execution boundary is clear. A run produces config, log, prediction, result, and summary artifacts under one work directory. This makes failures inspectable and lets users rerun only eval or visualization once predictions exist.

The partitioner/runner/task split scales well. The same benchmark definition can run locally, across GPUs, through API concurrency, or on Slurm-like infrastructure by changing runner config rather than dataset/evaluator code.

The model abstraction is useful for heterogeneous providers. Template parsing keeps chat-role formatting near the model adapter, while inferencers can call a common `generate_from_template` or PPL interface.

The evaluator registry handles both deterministic and model-graded scoring. Cascade evaluation is especially worth copying for coding-agent settings: use deterministic tests or parsers first, then reserve LLM judges for ambiguous failures.

Reporting is stronger than many harnesses. Summarizers understand model/dataset tables, version hashes, grouped averages, weighted groups, subjective/function summaries, and station persistence.

Coding benchmark coverage is real. The code-eval docs, pass@k examples, LiveCodeBench evaluator, CodeCompass evaluator, HumanEval tests, DS1000 service support, and external code-evaluation service show how the harness handles executable-code tasks at batch-eval scale.

## Weaknesses

Reproducibility is artifact-strong but environment-weak. OpenCompass dumps the resolved config and stores predictions/results, but a run does not automatically record the OpenCompass git SHA, full dependency lock, dataset file hashes, provider model snapshot, API response version, hardware, or environment variables.

Dependencies and data are mutable. `setup.py` has broad dependency ranges and optional extras with backend-specific packages. Dataset resolution can use OpenCompass downloads, ModelScope, HuggingFace, local paths, or internal URLs. Without explicit data locks, a named config can drift underneath a reported score.

Python configs and range parsing are not safe boundaries. Config loading executes Python, and `DatasetReader`/`NumWorkerPartitioner` support string ranges through `eval(...)`-style logic. That is acceptable for trusted benchmark repos but a poor default for untrusted task definitions.

Runner failure behavior is easy to miss. Local runner tasks are subprocesses with logs in `work_dir/logs`, and documentation warns that background task failures may only show terminal warnings. For expensive automated evaluation, failures should be first-class status records.

The registry default of `force=True` reduces friction but weakens collision detection. A lab harness should probably make duplicate registration explicit unless hot-reload behavior is required.

LLM-as-judge reproducibility remains soft. Generic judge configs can come from `OC_JUDGE_*` environment variables and remote APIs. Temperature is usually low, but provider behavior, prompts, and model versions still need pinning and audit artifacts.

Test coverage is broad in units but uneven at the system level. There are useful tests for models, prompt templates, partitioners, concurrent API inferencers, eval-watch behavior, local datasets, and summarizers, but far fewer full CLI, full runner, all-config, code-eval-service, and leaderboard-regression tests.

Some documentation and code appear slightly out of sync. For example, current default infer filling uses `NumWorkerPartitioner`, while user-guide prose still emphasizes size-based default partitioning. This is minor but signals the maintenance burden of a large config surface.

## Ideas To Steal

Use explicit artifact directories for `configs/`, `logs/`, `predictions/`, `results/`, and `summary/` in every run.

Use a registry boundary for models, datasets, postprocessors, evaluators, inferencers, runners, and partitioners. Keep task configs declarative enough that new benchmarks do not require editing the runner.

Copy the prompt-hash/version idea. Leaderboard rows should identify the exact prompt, scorer, and generation settings, not just the dataset name.

Separate partitioning from execution. A coding-agent lab can map tasks to local sandboxes, cluster jobs, or API queues using the same benchmark definition.

Keep prediction JSON and result JSON separate. This enables offline rescoring, judge replacement, regression comparison, and cheap summary reruns.

Adapt result station persistence. A portable model/dataset bundle containing predictions, results, and config is useful for cross-run comparison and sharing.

Use cascade evaluation. First run deterministic checks such as unit tests, patch application, JSON/schema checks, or exact-match extractors; then use LLM judges only for cases deterministic scoring cannot resolve.

Support repeated runs as first-class config. `n`/`k`, pass@k, and repeated dataset expansion are directly relevant for stochastic coding agents and multiple candidate patches.

## Do Not Copy

Do not use `eval(...)` over user-controlled range strings. Parse range expressions with a small grammar or typed schema.

Do not rely on Python executable configs as the only benchmark input format if untrusted contributors can submit tasks. Add validation, signing, or a restricted manifest layer.

Do not make dependency and dataset versions implicit. A coding-agent lab should pin package locks, data hashes, Docker images, model snapshots, and judge versions.

Do not hide runner failures in subprocess logs only. Record task status, exit code, stderr pointer, timeout reason, retry count, and artifact completeness as structured data.

Do not default registry registration to overwrite existing keys unless the overwrite is explicit and audited.

Do not treat remote LLM judge scores as enough for coding-agent verification. Use them as secondary signals behind deterministic tests, replayable traces, and human-labeled calibration sets.

Do not copy the full benchmark-config sprawl for a smaller lab. The valuable piece is the boundary between config, execution, artifacts, scoring, and reporting.

## Fit For Agentic Coding Lab

Fit is in-scope for harness-eval research. OpenCompass is an excellent reference for batch model benchmarking, especially for model config management, dataset/scorer registries, distributed execution, result artifacts, and leaderboard summaries.

For an agentic coding lab, it should be treated as an architectural reference, not a direct foundation. The missing pieces are per-sample repository checkout, patch application, tool-call protocol capture, shell/test sandboxing, file-diff artifacts, trajectory metrics, sample-level resume, and deterministic pass/fail grading over real codebases.

The best adaptation path is to keep OpenCompass-like config and reporting ideas while replacing the inner task loop with an agent environment: prepare repo snapshot, expose controlled tools, capture actions, apply patch, run tests, score deterministically, then summarize alongside cost, time, turns, context use, and failure taxonomy.

## Reviewed Paths

- `/tmp/myagents-research/open-compass-opencompass/README.md`
- `/tmp/myagents-research/open-compass-opencompass/setup.py`
- `/tmp/myagents-research/open-compass-opencompass/run.py`
- `/tmp/myagents-research/open-compass-opencompass/dataset-index.yml`
- `/tmp/myagents-research/open-compass-opencompass/docs/en/get_started/quick_start.md`
- `/tmp/myagents-research/open-compass-opencompass/docs/en/user_guides/config.md`
- `/tmp/myagents-research/open-compass-opencompass/docs/en/user_guides/datasets.md`
- `/tmp/myagents-research/open-compass-opencompass/docs/en/user_guides/models.md`
- `/tmp/myagents-research/open-compass-opencompass/docs/en/user_guides/evaluation.md`
- `/tmp/myagents-research/open-compass-opencompass/docs/en/user_guides/summarizer.md`
- `/tmp/myagents-research/open-compass-opencompass/docs/en/advanced_guides/persistence.md`
- `/tmp/myagents-research/open-compass-opencompass/docs/en/advanced_guides/code_eval.md`
- `/tmp/myagents-research/open-compass-opencompass/docs/en/advanced_guides/code_eval_service.md`
- `/tmp/myagents-research/open-compass-opencompass/docs/en/notes/academic.md`
- `/tmp/myagents-research/open-compass-opencompass/examples/eval_academic_leaderboard_REALTIME.py`
- `/tmp/myagents-research/open-compass-opencompass/examples/eval_api_demo.py`
- `/tmp/myagents-research/open-compass-opencompass/examples/eval_chat_demo.py`
- `/tmp/myagents-research/open-compass-opencompass/examples/eval_code_passk.py`
- `/tmp/myagents-research/open-compass-opencompass/examples/eval_lmdeploy_demo.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/cli/main.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/utils/run.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/registry.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/utils/datasets.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/utils/result_station.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/partitioners/base.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/partitioners/naive.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/partitioners/num_worker.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/partitioners/size.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/runners/base.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/runners/local.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/runners/local_api.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/runners/slurm.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/tasks/base.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/tasks/openicl_infer.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/tasks/openicl_infer_concurrent.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/tasks/openicl_eval.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/tasks/openicl_eval_watch.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/openicl/icl_dataset.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/openicl/icl_dataset_reader.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/openicl/icl_prompt_template.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/openicl/icl_retriever/icl_base_retriever.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/openicl/icl_retriever/icl_zero_retriever.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/openicl/icl_inferencer/icl_base_inferencer.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/openicl/icl_inferencer/icl_gen_inferencer.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/openicl/icl_inferencer/icl_ppl_inferencer.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/openicl/icl_inferencer/icl_chat_inferencer.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/openicl/icl_inferencer/icl_gen_inferencer_parallel.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/openicl/icl_inferencer/icl_chat_inferencer_parallel.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/openicl/icl_evaluator/icl_base_evaluator.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/openicl/icl_evaluator/icl_hf_evaluator.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/openicl/icl_evaluator/icl_misc_evaluator.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/openicl/icl_evaluator/code_evaluator.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/evaluator/generic_llm_evaluator.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/evaluator/cascade_evaluator.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/evaluator/math_evaluator.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/models/base.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/models/base_api.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/models/huggingface.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/models/huggingface_above_v4_33.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/models/openai_api.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/models/vllm.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/configs/models/openai/gpt_4o_2024_05_13.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/configs/models/hf_internlm/hf_internlm2_5_1_8b_chat.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/configs/models/qwen/vllm_qwen1_5_1_8b_chat.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/configs/datasets/mmlu/mmlu_openai_simple_evals_gen_b618ea.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/configs/datasets/mmlu/mmlu_ppl_ac766d.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/configs/datasets/mmlu/mmlu_all_sets.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/configs/datasets/gsm8k/gsm8k_gen_1d7fe4.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/configs/datasets/math/math_500_cascade_eval_gen_6ff468.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/datasets/gsm8k.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/datasets/humaneval.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/datasets/livecodebench/livecodebench.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/datasets/livecodebench/evaluator.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/datasets/codecompass/evaluator.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/summarizers/default.py`
- `/tmp/myagents-research/open-compass-opencompass/opencompass/summarizers/subjective.py`
- `/tmp/myagents-research/open-compass-opencompass/tests/TESTING_GUIDE.md`
- `/tmp/myagents-research/open-compass-opencompass/tests/models/test_base_model.py`
- `/tmp/myagents-research/open-compass-opencompass/tests/models/test_huggingface.py`
- `/tmp/myagents-research/open-compass-opencompass/tests/models/test_openai_api.py`
- `/tmp/myagents-research/open-compass-opencompass/tests/models/test_vllm.py`
- `/tmp/myagents-research/open-compass-opencompass/tests/openicl/test_icl_gen_inferencer_parallel.py`
- `/tmp/myagents-research/open-compass-opencompass/tests/openicl/test_icl_chat_inferencer_parallel.py`
- `/tmp/myagents-research/open-compass-opencompass/tests/openicl/test_icl_chatml_inferencer_parallel.py`
- `/tmp/myagents-research/open-compass-opencompass/tests/partitioners/test_base_partitioner.py`
- `/tmp/myagents-research/open-compass-opencompass/tests/partitioners/test_naive.py`
- `/tmp/myagents-research/open-compass-opencompass/tests/tasks/test_base_task.py`
- `/tmp/myagents-research/open-compass-opencompass/tests/tasks/test_openicl_infer_concurrent.py`
- `/tmp/myagents-research/open-compass-opencompass/tests/tasks/test_openicl_eval_watch.py`
- `/tmp/myagents-research/open-compass-opencompass/tests/datasets/test_humaneval.py`
- `/tmp/myagents-research/open-compass-opencompass/tests/datasets/test_local_datasets.py`
- `/tmp/myagents-research/open-compass-opencompass/tests/summarizers/test_default.py`

## Excluded Paths

- `/tmp/myagents-research/open-compass-opencompass/.git/`: VCS internals; exact reviewed commit is recorded above.
- `/tmp/myagents-research/open-compass-opencompass/.github/`: CI workflows, issue templates, and repository automation; useful maintenance context, but not benchmark architecture.
- `/tmp/myagents-research/open-compass-opencompass/.agents/` and `/tmp/myagents-research/open-compass-opencompass/.codex/`: repo-local agent/instruction files; unrelated to OpenCompass runtime behavior.
- `/tmp/myagents-research/open-compass-opencompass/docs/zh_cn/` and `/tmp/myagents-research/open-compass-opencompass/README_zh-CN.md`: Chinese localization of docs already reviewed through English docs and root README.
- `/tmp/myagents-research/open-compass-opencompass/docs/en/_static/` and `/tmp/myagents-research/open-compass-opencompass/docs/zh_cn/_static/`: logos and documentation static assets; UI/static only.
- `/tmp/myagents-research/open-compass-opencompass/autotest/`: internal/full-benchmark smoke automation, model lists, and run scripts; useful for operations but not required to understand core harness architecture.
- `/tmp/myagents-research/open-compass-opencompass/tools/`: helper scripts for conversion, collection, analysis, and maintenance; skimmed at directory level, excluded from deep review because core runtime paths are under `opencompass/`.
- `/tmp/myagents-research/open-compass-opencompass/examples/` beyond selected eval demos: examples repeat configuration patterns; representative API, chat, LMDeploy, code pass@k, and realtime leaderboard examples were reviewed.
- `/tmp/myagents-research/open-compass-opencompass/opencompass/configs/datasets/**` beyond representative MMLU, GSM8K, math/cascade, code, and demo configs: thousands of benchmark configs share the same schema; sampled configs cover generation, PPL, postprocessing, LLM judge, cascade eval, and few-shot retrieval patterns.
- `/tmp/myagents-research/open-compass-opencompass/opencompass/configs/models/**` beyond representative OpenAI, HuggingFace, vLLM, and LMDeploy-style configs: remaining files are mostly model-family parameter variants.
- `/tmp/myagents-research/open-compass-opencompass/opencompass/datasets/**` beyond representative dataset loaders/evaluators: many files are benchmark-specific adapters, scorer quirks, and answer extractors. Representative math, GSM8K, HumanEval, LiveCodeBench, CodeCompass, generic loader, and code-eval paths were reviewed for architecture.
- `/tmp/myagents-research/open-compass-opencompass/opencompass/datasets/SciReasoner/unconditional_protein_generation/omegafold/`: bundled domain-heavy model/evaluation code for one specialized scientific dataset; not representative of the harness core.
- `/tmp/myagents-research/open-compass-opencompass/requirements/`: dependency grouping was checked through `setup.py`; individual requirement fragments were not deeply reviewed because they do not change harness architecture.
- `/tmp/myagents-research/open-compass-opencompass/dataset-index.yml`: scanned as dataset metadata, not treated as execution logic.
- Vendored/binary/generated/UI-only paths: no large vendored dependency tree, generated build output, product UI, or large binary payload was found in this clone. Documentation static assets and specialized dataset-domain code are excluded above.
