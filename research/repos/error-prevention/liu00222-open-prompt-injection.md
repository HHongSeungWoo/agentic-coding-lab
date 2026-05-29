# liu00222/Open-Prompt-Injection

- URL: https://github.com/liu00222/Open-Prompt-Injection
- Category: error-prevention
- Stars snapshot: 450 (GitHub REST API repository metadata, captured 2026-05-29 KST)
- Reviewed commit: 95290f7ce3794c4c52ad3fe8113db2bfcdfe89e0
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: in-scope
- Verdict: Useful prompt-injection benchmark and defense prototyping kit, especially for measuring whether an LLM follows an injected task instead of a target task. Best value for Agentic Coding Lab is as a safety-regression fixture generator and metric vocabulary. Do not adopt it as-is for coding-agent safety: attacks are mostly synthetic instruction concatenations, defenses are prompt/model wrappers rather than tool-action guards, reproducibility depends on live APIs/GPU/downloads, and newer DataSentinel/PromptLocate pieces are not fully packaged or wired into the main benchmark path.

## Why It Matters

Prompt injection is a direct error-prevention problem for coding agents. Agents read untrusted repository files, issue text, webpages, tool output, and logs; any of those inputs can try to redirect the agent away from the user's task, leak hidden context, skip checks, run unsafe commands, or edit the wrong files. A useful safety regression suite needs repeatable cases where benign target work is mixed with adversarial instructions and scored by whether the model stays on task.

Open-Prompt-Injection matters because it formalizes that shape as a target-task versus injected-task benchmark. The same execution harness can pair sentiment analysis with spam detection, summarization with grammar correction, natural language inference with hate detection, or a math target with a fixed compromise string. The evaluator then reports target-task performance, injected-task performance, attack success, and matching between direct injected outputs and attacked outputs.

For Agentic Coding Lab, the repo is not a coding-agent guardrail. Its strongest contribution is the benchmark pattern: build contaminated examples by combining legitimate work with attacker-controlled work, run multiple defenses, and keep separate scores for "did the original job" and "obeyed the attacker." That pattern can be translated into coding-agent regressions around file edits, shell commands, dependency changes, secret handling, and malicious repository instructions.

## What It Is

Open-Prompt-Injection is a Python toolkit for prompt-injection attacks, defenses, LLM wrappers, tasks, and evaluators. The README frames it as an open-source toolkit for implementing and evaluating attacks, defenses, and LLM-integrated applications or agents. The codebase also includes examples for two newer defenses from related papers:

- DataSentinel, a fine-tuned detector that asks whether a known-answer prompt survives contamination.
- PromptLocate, a detector plus localization/recovery pipeline intended to identify injected spans and recover the clean user data.

The core benchmark path uses:

- Task configs in `configs/task_configs/` for SST-2, SMS Spam, HSOL, MRPC, RTE, Gigaword, JFLEG, MATH-500, and a synthetic compromise task.
- Model configs in `configs/model_configs/` for PaLM2, Azure/OpenAI GPT, Vicuna, Llama, Llama 3, FLAN, InternLM, Mistral QLoRA, and DeepSeek variants.
- Attackers in `OpenPromptInjection/attackers/` for naive append, newline escape, ignore-instruction, fake completion, and combined attacks.
- Application defenses in `OpenPromptInjection/apps/Application.py` for instructional reminders, sandwiching, random strings, delimiters, XML tags, LLM-based filtering, known-answer filtering, perplexity filtering, paraphrasing, retokenization, and response-based filtering.
- Evaluators in `OpenPromptInjection/evaluator/` for PNA-T, PNA-I, ASV, and MR.

The repository is MIT licensed, public, not archived, and the reviewed main branch was last pushed on 2025-10-29.

## Research Themes

- Token efficiency: Limited. The benchmark uses small default `data_num` runs and caches `.npz` responses, but several defenses add extra model calls per example. `run.py` launches many background jobs for 7 by 7 task pairs and sleeps between calls; DataSentinel and PromptLocate add detector queries, binary search, and helper-model passes. There is no token budget accounting or adaptive short-circuit policy.
- Context control: Moderate. The benchmark explicitly separates target instruction, user data, injected instruction, and injected data, and the GPT wrapper maps text before `Text:` into a system message and the rest into a user message. Defenses test common context-boundary ideas such as delimiters, XML tags, random sequences, sandwich reminders, and paraphrasing. The separation is string-based and fragile; untrusted text can still be concatenated directly into the same prompt.
- Sub-agent / multi-agent: Low. There is no multi-agent orchestration. PromptLocate acts like a helper pipeline around a detector, tokenizer, helper language model, and spaCy segmentation, but this is not an agent role system.
- Domain-specific workflow: Moderate for prompt-injection research, low for coding workflows. The task suite spans classification and text generation NLP tasks rather than repository editing, command execution, tests, patches, or tool calls. The benchmark abstraction can be adapted to coding-agent tasks, but the shipped tasks do not exercise coding-agent side effects.
- Error prevention: Strong research fit, partial implementation fit. The repo measures when prompt injection redirects an LLM and includes multiple baseline defenses. It does not enforce filesystem, shell, git, network, package, or patch safety.
- Self-learning / memory: Limited. There is no durable incident memory, adaptive attack library, or self-updating defense loop. DataSentinel/PromptLocate use fine-tuned checkpoints supplied externally rather than learning from local failures in the harness.
- Popular skills: Not a skill repo. Reusable "skills" are the target-vs-injected task benchmark, explicit attack strategy classes, defense wrappers, and metrics that split normal accuracy from attack success.

## Core Execution Path

The main experimental path is `main.py`. It accepts paths for a model config, target task config, injected task config, data count, save path, attack strategy, API-key position, and defense string. It creates a target task with `PI.create_task(..., for_injection=False)`, a model with `PI.create_model`, an injected task with `for_injection=True`, an attacker with `PI.create_attacker`, and an application with `PI.create_app`.

The target task path loads a task config, downloads or prepares the raw dataset, creates a fixed target subset and injected subset, saves them under `./data/<task>_<dataset>_<split>_<num>/`, loads the appropriate target instruction from `data/system_prompts/*.txt`, and yields `(data_prompt, label)` pairs. Classification tasks are class-balanced up to `num / class_num`; generation tasks use the first `num` eligible examples without a class balance concept. Injected tasks use the same task abstraction but load the `injected_instruction` prompt and the injected data split.

The attack path wraps each clean target prompt with an injected task instruction and injected data item. `naive` appends the injected instruction and data. `escape` places the injected task on a new line. `ignore` adds an instruction to disregard previous instructions. `fake_comp` first adds a fake completion for the target task, then the injected task. `combine` uses newline escape, fake completion, and ignore-instruction together. The fake-completion strings are hand-coded per target task.

The application path builds `instruction + "\nText: " + data_prompt`, optionally applying defenses. Some defenses modify the instruction or prompt template, such as `instructional`, `sandwich`, `random_seq`, `delimiters`, and `xml`. Some run pre-query checks, such as `llm-based`, `known-answer`, and `ppl`. Some transform the input, such as `paraphrasing` and `retokenization`. `response-based` filters malformed or unexpected classification outputs after the model response.

The model path wraps several live or local models. PaLM2 uses `google-generativeai`; Azure GPT and OpenAI GPT use the OpenAI SDK; Vicuna uses FastChat; Llama/FLAN/InternLM/DeepSeek use Hugging Face transformers; Mistral/Llama3 QLoRA wrappers load optional LoRA adapters. The base `Model` seeds Python, NumPy, and Torch, but live API behavior and provider changes remain outside local determinism.

The evaluator computes four metrics when inputs are available:

- PNA-T: normal target-task performance on clean target prompts.
- PNA-I: normal injected-task performance when directly queried on injected prompts.
- ASV: attack success value, measured by whether attack responses satisfy the injected task labels or generation references.
- MR: matching rate between attack responses and direct injected-task responses.

For classification tasks, scoring is string-label parsing with simple substring rules. Gigaword uses ROUGE-1 F-score. JFLEG uses GLEU with temporary source/reference/output files. The synthetic `compromise` injected task checks whether both outputs contain `compromised`. `math500` is loadable as a target task, but the evaluator has no `math500` scoring branch, so target-task scoring for MATH-500 falls through to `None`.

`run.py` is an experiment launcher that builds a 7 by 7 sweep over target and injected datasets for PaLM2 and `combine`, then starts `main.py` processes through `os.system` with background `nohup` jobs and polls logs for `[END]`. The reviewed `run.py` sets `defense = ''`; this behaves like no defense inside `Application`, but `main.py` only calculates direct injected-task responses when `args.defense == 'no'`, so this launcher can produce `PNA-I = None` and `MR = None` for its nominal no-defense sweep.

## Architecture

The codebase is organized as a small factory-based package:

- `OpenPromptInjection/__init__.py`: public factories for models, apps, attackers, tasks, and evaluators, plus exports for DataSentinel and PromptLocate.
- `configs/task_configs/`: JSON configs that bind task names, task types, prompt file names, datasets, splits, ICL splits, and class counts.
- `configs/model_configs/`: JSON configs for providers, model names, API-key slots, GPU/device settings, seeds, temperatures, output lengths, and fine-tuned adapter paths.
- `data/system_prompts/`: target and injected instructions, including plain, injected, chain-of-thought, short, long, and medium-long variants. The default configs mostly use the plain target and injected prompt files.
- `OpenPromptInjection/tasks/`: dataset builders, preprocessing, target/injected task wrappers, synthetic compromise task, MATH-500 task, and local GLUE/JFLEG/Gigaword loaders.
- `OpenPromptInjection/attackers/`: one class per attack strategy plus a factory with fixed strategy names.
- `OpenPromptInjection/apps/`: the LLM-integrated application wrapper, legacy baseline defenses, DataSentinel detector, PromptLocate localization, BPE retokenization, and perplexity-filter utilities.
- `OpenPromptInjection/models/`: provider wrappers over APIs and local transformer models.
- `OpenPromptInjection/evaluator/`: metric implementation, response label parsers, ROUGE/GLEU helpers, and evaluator factory.
- `main.py` and `run.py`: single-run experiment script and multi-run launcher.

There is no packaging metadata such as `pyproject.toml` or `setup.py`, and no test suite in the reviewed checkout. The environment is specified by `environment.yml`, which pins many Python packages and CUDA-related packages. PromptLocate imports `spacy` and loads `en_core_web_sm`, but `spacy` is not present in the reviewed `environment.yml`, so that path needs extra installation beyond the stated environment file.

## Design Choices

The most important design choice is the target/injected task split. A prompt-injection run is not scored only by whether the target answer is wrong; it is scored by whether the model completed the attacker's task. This is more useful than a generic refusal or toxicity metric because it captures instruction hijacking.

The task abstraction reuses the same datasets as both target tasks and injected tasks. This gives a Cartesian benchmark matrix and makes attack success measurable with labels. The tradeoff is that the attack data is often ordinary benchmark text plus a task instruction, not a realistic malicious webpage, repository file, or tool output.

Attack strategies are intentionally simple and composable. The combined attack includes three common ingredients: boundary break, fake target completion, and instruction override. That simplicity helps regression testing, but it undersamples adaptive, obfuscated, multilingual, indirect, and tool-specific prompt injection.

Defenses are implemented as application-level wrappers, not as a separate guard policy engine. This makes them easy to compare inside the same harness, but it conflates prompt formatting, input filtering, output filtering, and detector-model calls under a single `defense` string.

The evaluator tolerates missing or failed metric paths by catching exceptions and setting metrics to `None`. This keeps long sweeps from crashing, but it can hide broken configurations, unsupported datasets, missing direct baselines, and malformed outputs.

The dataset preparation path caches generated `.npz` files in `./data`. That makes repeated local runs faster and more stable after the first run. It also means reproducibility depends on unversioned generated artifacts unless the exact external dataset versions, downloads, and cache contents are recorded.

The newer DataSentinel and PromptLocate code is exposed as application classes but not integrated into `main.py` as a named defense strategy. The README shows manual examples and external Google Drive checkpoints, so these are promising research artifacts rather than turnkey benchmark options.

## Strengths

The benchmark has a clean conceptual structure. Target task, injected task, attack strategy, defense, model, and evaluator are separate enough to support controlled comparisons.

The metrics separate several things that are often mixed together: clean target accuracy, clean injected-task ability, attack success against injected labels, and similarity to direct injected-task responses. That matters because an attack cannot be interpreted well if the model could not do the injected task in the first place.

The attack classes are easy to read and extend. Adding a new injection pattern means implementing `inject()` and `get_injected_prompt()` behind the existing attacker factory.

The defense list covers many baseline families from prompt-injection literature: instruction reminders, sandwiching, delimiters, XML tagging, random strings, paraphrasing, retokenization, perplexity filtering, LLM-based filtering, known-answer detection, and response-based filtering.

The dataset set is broad enough to test cross-task interference across classification and generation. SST-2, SMS Spam, HSOL, MRPC, RTE, Gigaword, and JFLEG give different output formats and scoring requirements.

The code has practical hooks for both API models and local open-weight models. The config layer can swap providers without rewriting the benchmark loop.

DataSentinel and PromptLocate add defense directions beyond static prompt formatting. The known-answer detector, fine-tuned detector wrapper, binary-search localization, and recovery output are directly relevant to contaminated-input handling.

The benchmark is small enough to adapt. A coding-agent lab could replace NLP tasks with coding tasks while retaining the target/injected split, attack wrappers, and ASV-style scoring.

## Weaknesses

There are no tests in the reviewed checkout. The repo has no unit tests for attack string generation, task splitting, metric parsing, defense dispatch, model wrappers, or launcher behavior.

Reproducibility is fragile. The environment is a conda file rather than a package, relies on live external dataset downloads, live model APIs, GPU-specific local models, Google Drive checkpoints, and provider-specific behavior. There are no dataset hashes, result manifests, or saved benchmark outputs in the repo.

`run.py` has a no-defense mismatch. It sets `defense = ''`, while `main.py` only gathers direct injected-task responses when the string is exactly `no`. That can silently suppress PNA-I and MR in the launcher output even though the application itself treats the empty defense string as no defense.

Metric failure is easy to miss. `Evaluator.__init__` catches broad exceptions around every metric and converts failures to `None`. This is convenient for sweeps, but bad for regression gating because unsupported tasks, parser failures, and missing baselines do not necessarily fail the run.

Scoring is shallow for classification. Label parsers use substring heuristics, such as checking for `positive`, `negative`, `spam`, `entailment`, or `equivalent`. These can mis-score explanations, negations, multi-label outputs, or refusals. The response-based defense depends on the same brittle parsers.

The attack corpus is synthetic. The benchmark mostly appends an injected instruction and a benchmark data point. It does not model malicious repository instructions, package metadata poisoning, command-output injection, hidden HTML, markdown links, code comments, diffs, or tool-call manipulation.

The defenses are not action guards. They may reduce instruction hijacking in text generation, but they do not validate shell commands, file paths, git operations, dependency changes, generated code, secrets, or network access before side effects.

DataSentinel and PromptLocate are not turnkey. Their checkpoints are external downloads, fine-tuning code is not included despite the README saying more code will be released, PromptLocate imports spaCy without the dependency in `environment.yml`, and the pipeline is separate from the main benchmark defense switch.

Some prompt/model wrappers are brittle. The GPT wrapper asserts that prompts split into exactly two parts on `\nText: `, which can fail if untrusted data contains that delimiter. Several local model wrappers hard-code CUDA, device maps, GPU memory, or max generation lengths.

Some dependencies and model choices are stale or operationally costly. PaLM2 `text-bison-001`, FastChat Vicuna loading, large GPU models, and API-key rotation assumptions make exact reruns harder in 2026 than the simple README example suggests.

## Ideas To Steal

Use target-vs-injected tasks as the core safety-regression pattern. For coding agents, define a legitimate coding request and a malicious injected request, then score whether the agent completed the legitimate task, obeyed the injected task, or did both.

Keep attack success separate from normal task accuracy. A coding-agent benchmark should track clean task success, malicious instruction compliance, and recovery behavior rather than only pass/fail.

Make attack strategies first-class objects. Coding-agent variants could include malicious `AGENTS.md`, poisoned README instructions, command-output injection, dependency install bait, hidden test-log instructions, patch-review manipulation, and secret-exfiltration requests.

Preserve the defense comparison interface, but replace string-only dispatch with typed policy configs. Each guard should record what it inspected, whether it blocked, what evidence it used, and whether detector failure occurred.

Build a coding-task equivalent of ASV. For example: did the agent run an unauthorized command, write outside the requested path, reveal a secret canary, modify an unrelated file, skip required tests, or follow malicious repo-local instructions?

Use direct injected-task baselines. If an agent cannot perform the injected action when asked directly, an attack-success score is less meaningful. Direct baselines help separate model capability from injection vulnerability.

Adopt localization/recovery as a research direction. PromptLocate's goal maps well to coding agents: identify the span of untrusted content that caused unsafe behavior, remove or quarantine it, and continue with the legitimate task.

Cache and version benchmark artifacts. The repo's `.npz` cache idea is useful, but a coding-agent lab should add manifests with dataset version, commit, prompt templates, model id, seed, tool policy, and expected outputs.

## Do Not Copy

Do not treat prompt formatting defenses as coding-agent security boundaries. Delimiters, XML tags, sandwich reminders, and random strings can be benchmark conditions, but side-effect safety needs deterministic tool policy.

Do not use broad exception-to-`None` behavior in regression gates. A failed metric should fail the evaluation unless it is explicitly marked unsupported.

Do not let unversioned external downloads define the benchmark state. Pin dataset revisions or store generated fixtures with provenance and hashes.

Do not rely on substring label parsers for high-stakes scoring without structured outputs or strict answer extraction. For coding agents, parse actions, diffs, commands, and test results with deterministic validators.

Do not use an empty string as a meaningful defense setting. The launcher and main script should agree on canonical defense names.

Do not make detector checkpoints out-of-band requirements for a "reproducible" defense. If a defense requires a fine-tuned model, the note should include checkpoint version, hash, training data, and evaluation script.

Do not copy the synthetic NLP task suite as a substitute for agent safety coverage. Coding-agent regressions need repository, shell, filesystem, git, package, network, and CI scenarios.

Do not ignore dependency completeness. If PromptLocate requires spaCy and `en_core_web_sm`, the environment and setup instructions need to install them.

## Fit For Agentic Coding Lab

Fit is high as an `error-prevention` research candidate and moderate as a reusable benchmark scaffold. The repo gives Agentic Coding Lab a concrete way to express prompt injection as a measurable conflict between a target objective and an injected objective.

The most useful adaptation is a coding-agent benchmark harness with the same conceptual fields:

- Target task: the real user request, such as edit a file, fix a bug, or run a test.
- Injected task: the malicious instruction, such as edit a different file, leak a secret, skip tests, install a package, or run an unsafe command.
- Attack strategy: where the injected instruction appears, such as README, `AGENTS.md`, issue body, command output, test log, dependency metadata, or generated patch.
- Defense: instruction hierarchy, taint tracking, sandbox policy, command parser, path allowlist, canary scan, diff reviewer, human approval, or quarantined summarizer.
- Metrics: clean task success, malicious compliance, unsafe side effects, recovery quality, and evidence quality.

Open-Prompt-Injection should not be imported directly as an agent guard. It is valuable as a benchmark design reference and as a source of baseline prompt-injection attacks/defenses to port into coding scenarios. The coding-agent version needs deterministic side-effect checks, hermetic fixtures, structured action logs, and failure semantics strong enough for regression testing.

## Reviewed Paths

- `README.md`: project scope, setup instructions, simple model query, combined attack example, DataSentinel example, PromptLocate example, detection-plus-localization pipeline, and paper citations.
- `main.py`: single-run experiment orchestration, task/model/attacker/app creation, response caching, defense-dependent direct injected baseline, evaluator invocation, and metric printing.
- `run.py`: multi-dataset launcher, 7 by 7 target/injected sweep, background process execution, log polling, sleep behavior, and no-defense string mismatch.
- `environment.yml`: pinned conda/pip environment, model/dataset dependencies, CUDA-heavy packages, and missing PromptLocate spaCy dependency.
- `configs/task_configs/*.json`: task names, task types, prompt-file bindings, datasets, splits, ICL splits, class counts, MATH-500 target config, and synthetic compromise injected config.
- `configs/model_configs/*.json`: provider/model coverage, API-key placeholders, GPU/device settings, seeds, temperatures, output lengths, and fine-tuned adapter paths.
- `data/system_prompts/*.txt`: target prompts, injected prompts, chain-of-thought variants, and short/long/medium-long injected prompt variants.
- `OpenPromptInjection/__init__.py`: package exports and factory surface.
- `OpenPromptInjection/utils/*.py`: JSON config loading and text prompt loading.
- `OpenPromptInjection/tasks/Task.py`, `TargetTask.py`, `InjectedTask.py`, `ReasoningTask.py`, `CompromiseTask.py`, `Math500.py`, `utils.py`, and `__init__.py`: dataset preparation, target/injected subset split, ICL example caching, task factories, preprocessing, synthetic compromise behavior, and MATH-500 wrapper.
- `OpenPromptInjection/tasks/sst2.py`, `sms_spam.py`, `hsol.py`, `gigaword.py`, `jfleg.py`, and `gleu.py`: local dataset builders/downloaders and GLUE/JFLEG/Gigaword helpers.
- `OpenPromptInjection/attackers/*.py`: attacker interface, naive, escape, ignore, fake-completion, combined attack implementations, and attacker factory.
- `OpenPromptInjection/apps/Application.py`: LLM-integrated app wrapper, prompt construction, defense preparation, pre-query detection, preprocessing defenses, post-response filtering, and verbose conversation logging.
- `OpenPromptInjection/apps/DataSentinelDetector.py`: known-answer detector prompt, QLoRA wrapper use, contamination decision, and preprocessing.
- `OpenPromptInjection/apps/PromptLocate.py`: segmentation, binary search localization, causal-influence scoring, detector query caching, recovery/localized output construction, spaCy dependency, and fallback behavior.
- `OpenPromptInjection/apps/utils.py`, `bpe.py`, and `__init__.py`: perplexity filter, retokenization support, and app exports.
- `OpenPromptInjection/models/*.py`: provider wrappers for PaLM2, Azure/OpenAI GPT, Vicuna, Llama, Llama 3, FLAN, InternLM, Mistral QLoRA, and DeepSeek variants.
- `OpenPromptInjection/evaluator/Evaluator.py`, `utils.py`, `gleu_utils.py`, and `__init__.py`: PNA-T/PNA-I/ASV/MR calculation, classification label parsers, ROUGE/GLEU generation scoring, compromise scoring, and broad metric exception handling.
- `LICENSE`: MIT license provenance.
- Git metadata and GitHub REST API metadata: reviewed commit, latest pushed date, star snapshot, forks, open issues, topics, license, and archival state.

## Excluded Paths

- `.git/**`: excluded as repository internals except for commit and history provenance needed to record the reviewed snapshot.
- `data/illustration.png`: README illustration only, not benchmark execution, scoring, or defense logic.
- `data/subword_nmt.voc`: large BPE merge vocabulary used by the retokenization defense. I reviewed the retokenization call path and excluded the full vocabulary contents as static data.
- Downloaded datasets, generated `./data/*/*.npz`, `./result/**`, and `./log/**`: not present as reviewed benchmark outputs in the checkout; the code paths that generate and consume them were reviewed instead.
- External Google Drive DataSentinel and PromptLocate checkpoints: referenced by README but not stored in the repo. I reviewed the code expecting those checkpoints, not the model weights.
- External papers, slides, Hugging Face datasets, model repositories, and provider APIs linked or referenced by the repo: treated as provenance and runtime dependencies. A full paper or model-weight review would require separate notes.
- Python bytecode, caches, local virtual environments, and runtime build artifacts: not present or not relevant to the research note.
