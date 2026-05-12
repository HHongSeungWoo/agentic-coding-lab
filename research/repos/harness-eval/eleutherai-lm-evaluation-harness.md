# EleutherAI/lm-evaluation-harness

- URL: https://github.com/EleutherAI/lm-evaluation-harness
- Category: harness-eval
- Stars snapshot: 12,505 on 2026-05-12 via GitHub API
- Reviewed commit: 95d580638385578c1c07fa554cf16ad7f5b5f460
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong reference architecture for reusable evaluation harnesses. The most useful pieces for this repo are the declarative task registry, narrow model adapter contract, request/response intermediate representation, filter plus metric pipeline, and reproducible run artifacts. Do not copy the full benchmark corpus or provider matrix.

## Why It Matters

lm-evaluation-harness is one of the clearest production-grade examples of a benchmark harness that separates task definition, model/provider execution, scoring, aggregation, caching, and result logging. It is language-model oriented rather than coding-agent oriented, but the architectural boundaries map well to agent verification: tasks declare what to run, adapters execute against many backends, filters normalize messy outputs, metrics score them, and run manifests preserve enough context to reproduce or audit failures.

## What It Is

The project is a Python CLI and library for few-shot and zero-shot evaluation of language models. Users run `lm-eval run` with a model backend and one or more tasks, or call `simple_evaluate()` / `evaluate()` from Python. Tasks are mostly YAML configs under `lm_eval/tasks`, optionally extended with Python functions. Model backends implement a shared `LM` interface for `loglikelihood`, `loglikelihood_rolling`, and `generate_until`. The evaluator builds task requests, batches them by request type, executes the model, applies response filters, computes per-document metrics, aggregates results and stderr, and writes aggregated plus sample-level artifacts.

## Research Themes

- Token efficiency: Caching, request grouping, length sorting, automatic batch-size detection, context grouping for one-token continuations, and request-cache files reduce repeated model work. It is not a prompt-compression system.
- Context control: Task configs own prompt construction, few-shot examples, delimiters, chat templates, system instructions, generation prefixes, stop sequences, truncation behavior, and prompt/sample hashes.
- Sub-agent / multi-agent: No first-class agent orchestration. Distributed ranks, multiple tasks, and multiple providers are execution scaling mechanisms, not sub-agent workflows.
- Domain-specific workflow: Very strong. YAML task specs, include inheritance, `include_path`, groups, tags, custom functions, and per-task metadata make new benchmark domains pluggable.
- Error prevention: Warnings and guards cover unsafe task code, chat-template/few-shot compatibility, model/task modality mismatches, generation kwargs, `--limit`, task integrity checks, and response-cache behavior. The `validate` subcommand is shallow compared with the docs.
- Self-learning / memory: No long-term learning loop. It has pragmatic memory in SQLite response caches, task request caches, sample hashes, and persisted result artifacts.
- Popular skills: Evaluation harness design, task registry design, model-provider adapters, batched inference, reproducible experiment tracking, filters for extracted answers, metric aggregation, and golden-output tests.

## Core Execution Path

1. CLI entrypoints `lm-eval` / `lm_eval` call `lm_eval.__main__.cli_evaluate`, which constructs `HarnessCLI`.
2. `HarnessCLI` dispatches to subcommands `run`, `ls`, or `validate`; old no-subcommand invocations are rewritten to `run` for compatibility.
3. `run` builds `EvaluatorConfig` by merging defaults, optional YAML config, and CLI overrides.
4. `EvaluatorConfig.process_tasks()` normalizes task names, YAML paths, globs, directories, and include paths.
5. `TaskManager` indexes default and extra task paths, then loads names, tags, groups, inline task configs, or YAML files into a flat task/group map.
6. `simple_evaluate()` seeds Python, NumPy, Torch, and few-shot sampling; initializes an `LM` backend via the model registry; optionally wraps it in `CachingLM`; applies runtime overrides such as `num_fewshot` and `gen_kwargs`; then calls `evaluate()`.
7. `evaluate()` builds all `Instance` requests, groups them by request type, executes each model method in batches, records responses, applies filter pipelines, calls each task's `process_results()`, and collects samples.
8. `evaluator_utils` and `Group.aggregate()` aggregate metrics, stderr, sample counts, group metrics, and higher-is-better flags.
9. `EvaluationTracker` writes result JSON, sample logs, task hashes, model/source/chat-template hashes, environment info, and total evaluation time.

## Architecture

Task registry: `TaskManager`, `TaskIndex`, and `TaskFactory` are the backbone. `TaskIndex` deterministically scans sorted `*.yaml` files, classifies them as tasks, Python tasks, groups, or tags, and warns on duplicates. `TaskManager.load()` expands task names, tags, groups, external YAML paths, and inline configs into flat `tasks`, `groups`, and `group_map` structures. `TaskFactory` resolves YAML includes, local `!function` references, Python task classes, `ConfigurableTask`, and `GroupConfig`. Later include paths can override earlier built-ins, which is useful for local benchmark extensions but needs governance.

Task definition: `TaskConfig` describes dataset source, splits, prompt functions, few-shot settings, output type, generation kwargs, filters, metrics, decontamination fields, metadata, and versioning. `ConfigurableTask` turns that config into documents, few-shot contexts, chat messages, and `Instance` requests. Supported output types are `loglikelihood`, `loglikelihood_rolling`, `multiple_choice`, and `generate_until`.

Model/provider abstraction: `LM` is deliberately narrow. Backends implement `loglikelihood()`, `loglikelihood_rolling()`, and `generate_until()`, plus chat-template, tokenizer, rank/world-size, and construction helpers. `TemplateLM` centralizes tokenization and loglikelihood token handling. `CachingLM` wraps any model with SQLite-backed response caching. The registry lazily maps aliases such as `hf`, `vllm`, `sglang`, `openai-completions`, `local-completions`, `openai-chat-completions`, `anthropic-chat-completions`, and `litellm` to backend classes.

Provider examples: `HFLM` handles Hugging Face causal and seq2seq models, PEFT/delta/GPTQ/GGUF paths, Accelerate data parallelism, tensor-parallel plans, automatic batch sizing, context grouping, and `think_end_token` stripping. `VLLM` handles tensor parallelism, Ray-backed data parallelism, LoRA, max context probing, and seed control. `TemplateAPI` handles HTTP payload construction, retries, async concurrency, batching, tokenizer backends, optional image payloads, and response parsing. OpenAI-compatible chat backends support generation but not loglikelihood, which makes them incompatible with many multiple-choice tasks.

Evaluator and batching: The evaluator creates a request IR (`Instance`) with `request_type`, arguments, document id, repeats, responses, and filtered responses. It groups all requests across tasks by request type, clones repeated requests, pads distributed ranks to equal work, and calls each model method once per type. Backends then add their own batching strategy: length sorting, automatic batch size search, max batch caps, async API concurrency, or provider-native batch calls.

Metrics and filters: Raw model responses are first transformed by filter ensembles such as regex extraction, multiple-choice regex, whitespace/case normalization, mapping, custom filters, `take_first`, `take_first_k`, majority vote, and decontamination. `process_results()` maps filtered responses to metric values. `api/metrics.py` registers metrics and aggregations for accuracy, normalized accuracy, mutual-information accuracy, exact match, likelihood, perplexity, byte/word/bits metrics, BLEU, chrF, TER, F1, MCC, Brier score, and custom/HF metrics. Aggregation and stderr are separate from per-document scoring.

Reproducibility and logging: Runs record model args, model name/source/hash, model revision when available, batch sizes, device, cache settings, seeds, Git hash, environment variables, tokenizer info, task configs, versions, n-shot values, sample counts, doc/prompt/target hashes, task hashes, and sample-level outputs. Config files mirror CLI flags and CLI values override YAML, which encourages version-controlled evaluation recipes.

Tests: The test suite covers registry behavior, YAML include/function resolution, task indexing, CLI parsing and backward compatibility, evaluator integration, few-shot formatting, metrics, group aggregation, request caching, Hugging Face backends, API payloads/concurrency, LiteLLM, and vLLM context behavior. Some backend tests are dependency-gated or skipped in normal lightweight runs, so full confidence depends on optional environments.

## Design Choices

The harness treats tasks as data first and code second. Most benchmark behavior lives in YAML, while Python is reserved for custom document processing, metrics, or legacy task classes. This makes task discovery and listing cheap, but `!function` also means task definitions can import arbitrary code when fully resolved.

The model contract is request-type oriented rather than provider oriented. This lets one evaluator work across local transformers, vLLM, SGLang, hosted completion APIs, and chat APIs. The cost is that provider capability matters: chat-completion-only models cannot run loglikelihood or rolling-perplexity tasks.

The evaluator uses a stable request/response intermediate representation instead of calling model backends directly from tasks. That enables cross-task batching, repeated sampling, distributed padding, caching, and sample logging.

Filtering is a first-class phase before metrics. This is important for generative tasks where the raw output may contain chain-of-thought text, explanations, labels, or formatting noise. Multiple filter pipelines can score the same model outputs in different ways.

Reproducibility is treated as an output artifact, not just a CLI convention. Hashes, configs, seeds, model identity, environment info, and sample logs are emitted with the result set.

## Strengths

- Clean separation between task registry, task construction, model execution, filtering, metrics, aggregation, and logging.
- Declarative task configs are flexible enough for many benchmark styles without changing evaluator code.
- Provider abstraction supports local models, accelerated inference engines, OpenAI-compatible APIs, provider-specific chat APIs, and LiteLLM routing.
- Batching is handled at several layers: evaluator request grouping, backend length sorting, automatic batch-size detection, distributed padding, API concurrency, and provider-native batches.
- Metrics pipeline supports exact, extracted, custom, and aggregate metrics while preserving sample-level evidence.
- Reproducibility artifacts are unusually complete for a benchmark harness.
- Tests exercise the registry, config loading, evaluator path, metrics, filters, groups, and representative backends.

## Weaknesses

- The benchmark corpus is large and heterogeneous, so startup, dependency, dataset, and cache behavior can be difficult to reason about.
- `validate` currently checks task resolution much more than full renderability or metric correctness, despite documentation implying deeper validation.
- YAML `!function` and unsafe task code require strong trust boundaries if reused for agent verification.
- Capability mismatch is easy: chat-only APIs cannot score loglikelihood or multiple-choice tasks that need token logprobs.
- Optional backend coverage means many important paths are skipped unless the right extras and hardware are installed.
- `--limit` is useful for smoke tests but can still produce misleading metrics if results are treated as real.
- Very high bootstrap defaults can be expensive for quick iteration.

## Ideas To Steal

- A YAML-first task schema with includes, metadata versioning, tags, groups, and external include paths.
- A small request IR like `Instance` that carries task name, doc id, arguments, repeats, raw responses, and filtered responses.
- A narrow model/runner adapter contract organized around capabilities rather than provider brands.
- Filter pipelines before metrics, especially regex extraction, mapping, first-answer selection, and majority vote.
- Sample-level logs with prompt, target, response, hashes, metric values, and task config.
- A run manifest that records seeds, model identity, model revision, tokenizer info, environment, Git hash, cache settings, and task hashes.
- Separate aggregation logic for task metrics and group metrics, including sample counts and stderr.
- Backward-compatible CLI evolution through explicit subcommands plus legacy argument rewriting.

## Do Not Copy

- Do not import the full benchmark corpus into a coding-agent lab; keep a smaller, curated task suite.
- Do not expose arbitrary YAML `!function` imports without an explicit trust or sandbox policy.
- Do not promise validation deeper than the implementation performs.
- Do not start with dozens of model providers. Build the adapter contract first, then add providers based on actual verification needs.
- Do not assume chat-completion APIs can support all scoring modes.
- Do not make expensive bootstrap stderr the default for fast coding-agent smoke checks.
- Do not let task override paths silently change official benchmark semantics without provenance in the run artifact.

## Fit For Agentic Coding Lab

This is a high-fit reference for the harness-eval category. The transferable design is not the specific NLP benchmark set, but the execution contract: declarative tasks, runner adapters, request instances, batched execution, filters, metrics, aggregates, and reproducible evidence. For coding agents, a similar system could define tasks as repositories, setup commands, prompts, allowed tools, expected files, and scoring rules. The runner adapter could execute a coding agent instead of an LM completion endpoint. Filters could parse test output, diffs, lint results, artifact manifests, and reviewer signals. Metrics could aggregate pass rate, patch quality, runtime, token cost, flakiness, and reproducibility.

The main adaptation needed is that coding agents produce workspace mutations and command logs, not only strings. The harness should preserve the same sample-level evidence idea but store patch diffs, file hashes, tool traces, command exit codes, and verifier outputs. The LM harness shows how to keep task authorship, model execution, scoring, and result logging independent.

## Reviewed Paths

- `README.md`, `pyproject.toml`
- `docs/README.md`, `docs/interface.md`, `docs/config_files.md`, `docs/python-api.md`, `docs/model_guide.md`, `docs/API_guide.md`, `docs/task_guide.md`, `docs/new_task_guide.md`, `docs/footguns.md`, `docs/decontamination.md`
- `lm_eval/__main__.py`
- `lm_eval/_cli/harness.py`, `lm_eval/_cli/run.py`, and related CLI subcommand files
- `lm_eval/config/evaluate_config.py`, `lm_eval/config/task.py`
- `lm_eval/evaluator.py`, `lm_eval/evaluator_utils.py`, `lm_eval/result_schema.py`
- `lm_eval/loggers/evaluation_tracker.py`
- `lm_eval/tasks/manager.py`, `lm_eval/tasks/_index.py`, `lm_eval/tasks/_factory.py`, `lm_eval/tasks/_yaml_loader.py`, `lm_eval/tasks/README.md`, and representative task YAML/config patterns
- `lm_eval/api/model.py`, `lm_eval/api/task.py`, `lm_eval/api/instance.py`, `lm_eval/api/registry.py`, `lm_eval/api/metrics.py`, `lm_eval/api/filter.py`, `lm_eval/api/group.py`
- `lm_eval/models/__init__.py`, `lm_eval/models/huggingface.py`, `lm_eval/models/vllm_causallms.py`, `lm_eval/models/api_models.py`, `lm_eval/models/openai_completions.py`, `lm_eval/models/litellm_llms.py`
- `lm_eval/filters/*`
- `tests/test_registry.py`, `tests/test_task_manager.py`, `tests/test_cli_subcommands.py`, `tests/test_evaluator.py`, `tests/test_requests_caching.py`, `tests/test_metrics.py`, `tests/test_fewshot_context.py`, `tests/test_aggregation_pipeline.py`, `tests/test_group.py`, `tests/test_evaluator_utils.py`
- `tests/models/test_huggingface.py`, `tests/models/test_api.py`, `tests/models/test_vllm_context_length.py`, `tests/models/test_litellm.py`

## Excluded Paths

- Exhaustive `lm_eval/tasks/**` benchmark corpus: reviewed registry mechanics, task docs, and representative YAML patterns, but not every benchmark config. The full corpus is repetitive domain content rather than core harness architecture.
- `tests/testdata/**`: used only to understand golden-output and cache-test shape. Large fixtures, pickles, and static expected outputs were not line-reviewed because they are test artifacts.
- `docs/img/**` and notebook/tutorial-only material: excluded as visual or walkthrough content, not runtime architecture.
- `.github/**`, issue templates, release automation, and community metadata: excluded as project operations rather than evaluation architecture.
- Backend files for providers not central to this review, such as Megatron, NeMo, TensorRT-LLM, GGUF, WatsonX, and WinML: covered through registry mapping and representative HF/vLLM/API/LiteLLM backends instead of exhaustively reading every provider implementation.
- Decontamination preprocessing scripts and dataset-statistic artifacts such as `pile_statistics.json`: reviewed decontamination docs and evaluator hooks, but excluded long data-prep assets from the architecture review.
