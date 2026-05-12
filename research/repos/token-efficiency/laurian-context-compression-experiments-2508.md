# Laurian/context-compression-experiments-2508

- URL: https://github.com/Laurian/context-compression-experiments-2508
- Category: token-efficiency
- Stars snapshot: 69 (GitHub REST API, captured 2026-05-12)
- Reviewed commit: 1bb4cbec7c34485d5ec99e575ded90afd9fa899a
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: conditional
- Verdict: Useful small experiment notebook-replacement for prompt-level context compression tuning, especially the "failed cheap model, successful strong model" dataset design and the GEPA then TextGrad optimization loop. Weak as a reusable artifact because the public repo ships only example-only data, no committed experiment outputs, no tests, no notebooks, weak scoring proxies, and limited reproducibility controls.

## Why It Matters

This repo studies a common token-efficiency failure mode in agentic RAG: after retrieval, each document must be compressed against a query before entering the answer-writing context. The original prompt works well with `gpt-4o`, but `gpt-4o-mini` often returns `NO_OUTPUT`, forcing a production fallback to the larger model. Improving the smaller model's extraction behavior can cut cost and rate-limit pressure without changing the retriever.

The important idea for Agentic Coding Lab is not the exact private domain prompt. It is the experimental shape: collect traces where a cheaper model failed, re-run the same document-query pairs through a stronger model, use the stronger model output as a target or critic, optimize the prompt, then test whether the cheaper model stops failing.

The repo also shows a trap. The most visible success metric is "extracts something instead of `NO_OUTPUT`." That is useful as a first recovery metric, but it can reward over-extraction. For coding agents, a context compressor must measure fidelity, coverage, exactness, and absence of harmful extra text, not only non-empty output.

## What It Is

`context-compression-experiments-2508` is a Python experiment repo for optimizing a contextual compression prompt with DSPy GEPA, TextGrad, and a hybrid TextGrad-on-GEPA pass. It is a script-based experiment, not a library or production compressor.

The source path is:

1. Load LangFuse-style observation JSON files from `data/observations`.
2. Extract `<context>` and `<query>` blocks from chat messages with regex.
3. Pair failed `gpt-4o-mini` observations with successful `gpt-4o` outputs from `data/gpt-4o`.
4. Optimize the system prompt using either DSPy GEPA or TextGrad.
5. Save timestamped optimized prompts and metadata under `data/results`.
6. Test the latest optimized prompt against observations with `gpt-4o-mini-2024-07-18`.
7. Save per-observation test outputs under `data/tests`.
8. Optionally visualize semantic line overlap between original contexts, `gpt-4o` outputs, and optimized `gpt-4o-mini` outputs.

The public checkout does not include the real 1,700+ observations, the 296 target outputs, or generated `data/results` and `data/tests` outputs. It includes only example JSON schemas and README excerpts from earlier runs.

## Research Themes

- Token efficiency: Primary theme. The repo tries to make a cheaper model perform a document-compression task that otherwise needs a larger model fallback. README claims `gpt-4o-mini` moved from 0% extraction on the selected failure set to 62% with GEPA, 79% with TextGrad, and 100% with the hybrid prompt, but public data and results are not present to reproduce those numbers.
- Context control: Strong task focus but weak enforcement. Prompts require verbatim extraction, heading preservation, multiple relevant spans, and `NO_OUTPUT` only when no relevant content exists. The scripts do not enforce those properties beyond simple scoring and post-hoc semantic line matching.
- Sub-agent / multi-agent: None. Claude Code/OpenCode/Cursor are mentioned as tools used to generate scripts, but no multi-agent architecture is implemented.
- Domain-specific workflow: Moderate. The private dataset is domain-specific, and optimized prompts pick up redacted domain terms. That is useful evidence that optimization can overfit to recurring domain concepts.
- Error prevention: Limited. The scripts skip malformed observations and truncate long contexts, but there are no unit tests, no exact-verbatim validator, no leakage guard for overfitted domain terms, and no seeded deterministic sampling.
- Self-learning / memory: None as durable memory. The feedback loop is offline prompt optimization over saved traces.
- Popular skills: No skill pack. Reusable patterns are trace mining, strong-model distillation targets, prompt-optimizer comparison, hybrid optimizer chaining, and visual coverage maps.

## Core Execution Path

The DSPy path starts in `scripts/dspy_gepa_optimizer.py`. `DataLoader.load_observations()` reads all non-underscore JSON files from `data/observations`, extracts `<context>` and `<query>` with regex, truncates contexts above 25,000 characters, and attaches a `target_output` when a matching `data/gpt-4o/{id}.json` exists. `prepare_dataset(max_examples=50)` prioritizes targeted examples, creates a single `user` string containing the context and query, and splits the first 40 examples for training and the next 10 for validation.

`ContextCompressor` wraps a single `dspy.Predict("user -> reply")` step whose instructions are the base context-compression prompt. `DSPyGEPAOptimizer.setup_dspy()` configures `openai/gpt-4o-mini` as the target model and `cache/dspy` as the DSPy cache. GEPA uses `gpt-4o` as the reflection model with `temperature=1.0`, `auto="medium"`, `num_threads=4`, and `track_stats=True`.

The GEPA metric is `evaluate_compression()`. It gives zero when the prediction is `NO_OUTPUT` but the target is not, gives one when both are `NO_OUTPUT`, and otherwise gives up to `0.8` based on length ratio between prediction and target. It does not check that text is copied verbatim from the context, that all target spans are covered, or that extra irrelevant spans are absent.

The TextGrad path in `scripts/textgrad_optimizer.py` uses the same data loader and base prompt. It creates a mutable `tg.Variable` for the system prompt, calls `gpt-4o-mini` as the target engine, and uses `gpt-4o` as the backward critic. Each training example builds a `TextLoss` prompt asking for feedback on relevance, completeness, exactness, `NO_OUTPUT`, and format preservation. The loop samples five training examples per iteration with `np.random.choice`, runs eight iterations, evaluates the first 10 validation examples after each step, and saves the best prompt.

The hybrid path in `scripts/textgrad_latest_gepa_optimizer.py` finds the newest `data/results/gepa_context_compression_*` directory by modification time, extracts `step.signature.instructions` from `optimized_model.json`, then runs the same TextGrad loop starting from that GEPA prompt.

The test scripts load the latest result directory for each method, call OpenAI chat completions with `model="gpt-4o-mini-2024-07-18"`, `temperature=0.0`, and `max_tokens=2000`, then mark success as `bool(output and output != "NO_OUTPUT")`. They persist per-observation JSON plus aggregate success rate and token usage.

The coverage-map path uses `scripts/MatchLines.py` and `scripts/generate_coverage_image_map_base.py`. It splits context and output text into lines and sentences, embeds sentences with `sentence-transformers/all-MiniLM-L6-v2`, greedily matches output sentences to context sentences with cosine thresholds of `0.70` for normal lines and `0.60` for likely headers, then paints blue for `gpt-4o` target lines, red for optimized output lines, and white for overlap.

## Architecture

The architecture is flat and script-oriented:

- `README.md`: experiment narrative, original prompt, sample optimizer logs, reported success rates, and run commands.
- `CLAUDE.md`: agent-facing project guide with dataset shape, commands, scripts, and workflow descriptions.
- `pyproject.toml` and `uv.lock`: Python package metadata, pinned dependency resolution, lint/test command declarations, and dependencies such as `dspy-ai`, `textgrad`, `openai`, `weave`, `wandb`, `sentence-transformers`, and `Pillow`.
- `Makefile`: setup, optimizer, tester, process-kill, cache-clear, and data-check commands.
- `scripts/dspy_gepa_optimizer.py`: GEPA optimizer and length-ratio metric.
- `scripts/textgrad_optimizer.py`: TextGrad optimizer from the base prompt.
- `scripts/textgrad_latest_gepa_optimizer.py`: TextGrad optimizer using latest GEPA result as starting prompt.
- `scripts/test_latest_gepa_prompt.py`, `test_latest_textgrad_prompt.py`, `test_latest_textgrad_gepa_prompt.py`: API-based replay tests for latest optimized prompts.
- `scripts/MatchLines.py`: semantic line matching utility.
- `scripts/generate_coverage_image.py`, `generate_coverage_image_map.py`, `generate_coverage_image_map_base.py`: visualization helpers.
- `data/observations/_example-observation.json` and `data/gpt-4o/_example-output.json`: public schema examples only.
- `src/context_compression_experiments/__init__.py`: empty package marker with version.

There are no committed notebooks, no application entrypoint, no unit tests, no real public datasets, and no generated optimization outputs in the reviewed checkout.

## Design Choices

The dataset design is failure-focused. Instead of optimizing on generic compression examples, the author filters traces where `gpt-4o-mini` produced `NO_OUTPUT`, then keeps cases where `gpt-4o` succeeds. That creates a direct "teach the fallback model what the stronger model saw" loop.

The prompt target is extractive, not abstractive. The base prompt repeatedly requires exact text copied as-is, no paraphrase or summary, headings preserved, and `NO_OUTPUT` only when no relevant information exists. This matches high-fidelity context compression for RAG.

The optimizer scripts are intentionally small-sample. Even though README describes 296 target examples, the code hard-codes `max_examples=50`, an 80/20 split, and small TextGrad batches. That reduces experiment cost but makes reported accuracy sensitive to file ordering and sample composition.

The scoring choice favors failure recovery over fidelity. Length ratio and non-empty output are cheap and easy to optimize, but they do not prove exact extraction. The README acknowledges this later by adding a semantic coverage visualization, but that visualizer is not integrated into optimizer scoring.

The hybrid design is sequential rather than ensemble-based. GEPA first searches prompt variants, then TextGrad refines the latest GEPA prompt. This is a practical pattern because TextGrad can start from a stronger prompt than the original instead of rediscovering the same broad guidance.

Reproducibility is partial. `uv.lock` pins dependencies, `.env.template` documents required keys, `cache/dspy` is configurable, test temperature is zero, and outputs are timestamped. Missing controls include public data, saved result artifacts, random seeds, sorted file loading, CLI-configurable sample size, exact model/version pinning in optimization paths, and CI tests.

## Strengths

The problem framing is concrete. It starts from production traces where a cheaper model failed, not synthetic examples.

The strong-model target pattern is reusable. `gpt-4o` outputs provide a practical teacher signal for making `gpt-4o-mini` handle the same compression task.

The repo compares multiple prompt-optimization methods against the same task shape: DSPy GEPA, TextGrad, and TextGrad after GEPA. That is more useful than presenting a single hand-written prompt.

The TextGrad loss prompt encodes the right qualitative criteria: relevance, completeness, exactness, `NO_OUTPUT` handling, and format preservation. Even though the numeric scoring is weak, the critic instructions point at the right dimensions.

The coverage-map tooling is a good exploratory diagnostic. Matching output lines back to context lines can reveal whether the cheap model covers the same regions as the strong model or merely extracts any plausible text.

The scripts save experiment metadata, prompts, token usage, and per-observation outputs in timestamped directories. That is the right shape for later regression tracking if the missing dataset is supplied.

## Weaknesses

The public repo is not reproducible. The real observations, `gpt-4o` targets, optimization outputs, and test outputs are absent. Only example schema data files are committed.

There are no tests despite `pyproject.toml` and `Makefile` exposing `pytest` commands. The claimed behavior depends on API calls and private files.

The scoring function is too weak for extractive compression. A long irrelevant extraction can score better than `NO_OUTPUT`, and length similarity can reward outputs that are not verbatim, not complete, or not grounded in the context.

The headline 100% hybrid result measures "extracting something" rather than quality. The README is explicit that "extracting something is better than nothing," but for Agentic Coding Lab this is only a recovery metric, not an acceptance metric.

Data loading is not deterministic enough. `Path.glob("*.json")` is not explicitly sorted, TextGrad batch sampling has no seed, and GEPA reflection uses `temperature=1.0`. Re-running may train and validate on different examples or produce different prompts.

Optimizer and tester settings are hard-coded. The scripts do not expose sample size, split, seed, model names, token limits, thresholds, or output locations as CLI arguments.

Context truncation is crude. Long contexts are cut at 25,000 characters and suffixed with `"... [truncated]"`, which can remove answer-bearing sections while still treating the `gpt-4o` target as ground truth.

The optimized prompts shown in README contain redacted domain-specific guidance. That is expected from the private dataset, but it signals overfitting risk and limits transfer to other domains.

The semantic line matcher can produce false positives. It uses a small sentence-transformer model and greedy matching, with lower thresholds for likely headers. Repeated sentences or generic headings can inflate overlap.

## Ideas To Steal

Mine failure traces for compression training sets. For coding agents, collect cases where a cheap summarizer, context pruner, or retrieval compressor lost required file/test/log facts, then replay them through a stronger model or human target.

Use a stronger model as a teacher for a cheaper context-control model. The pattern is practical when the target task is narrow, such as "extract exact relevant lines from tool output" or "compress a failing test log without losing assertion text."

Optimize recovery first, then fidelity. A first metric can be "not empty when target exists," but the next gate must check exact grounding, required span coverage, no hallucinated lines, and no forbidden omissions.

Chain search-style and gradient-style prompt optimizers. GEPA can explore broad prompt variants; TextGrad can then refine the best candidate with critic feedback.

Make coverage maps for agent context compaction. Visualizing which original lines survive in compressed context would help compare summarizers, extractors, and handcrafted heuristics over source files, diffs, and shell logs.

Persist every run as a timestamped experiment directory with prompt, config, examples, per-item outputs, aggregate metrics, model IDs, token usage, and source commit. The repo has the directory pattern; Agentic Coding Lab should make it complete and CI-checkable.

Include the negative class. This repo focuses on failures where the strong model found content. A production compressor also needs examples where `NO_OUTPUT` is correct, otherwise optimization can drift toward always extracting something.

## Do Not Copy

Do not use non-empty output as the main success metric for coding-agent context compression. It is too easy to over-extract irrelevant text.

Do not score extractive compression with only output length ratio. Use source-grounded span matching, required-line recall, extra-line precision, exact string preservation, and task-level downstream checks.

Do not train on unsorted filesystem order or unseeded random batches when comparing optimizers. Experiment comparisons need stable splits.

Do not ship optimized prompts that quietly encode private domain terms unless the deployment domain, privacy boundary, and overfit risk are explicit.

Do not truncate long contexts by raw character prefix without recording whether the target span survived truncation.

Do not claim reproducible benchmark results from README logs alone. Keep the data manifest, config, exact prompt, run outputs, and scorer code together.

Do not treat semantic similarity as proof of verbatim extraction. It is useful for visualization, but exact extraction needs exact span validation or tolerant diff logic with explicit rules.

## Fit For Agentic Coding Lab

Fit is conditional but useful. The repo is not a ready subsystem for agent context management, but it is a good pattern source for building an experiment harness around context-compression prompts.

The best adaptation is a "compression failure replay" harness for coding agents. Inputs would be file excerpts, command output, test logs, stack traces, and prior tool results. Targets would identify the exact lines or spans that must survive. Cheap models or deterministic compressors would be optimized and tested against those targets.

For Agentic Coding Lab, the repo's strongest idea is the teacher-student loop: use a stronger model or human-reviewed output to label what a cheaper compressor should have extracted. The local implementation should add deterministic splits, richer metrics, exact grounding, negative examples, and downstream task checks before any prompt is considered safe.

The repo is less useful as an implementation dependency. It has no library API, no public dataset, no tests, and no safety envelope for coding-agent artifacts. Borrow the workflow, not the code as-is.

## Reviewed Paths

- `README.md`: original context-compression prompt, production motivation, DSPy GEPA logs, TextGrad prompt, hybrid result, reported success rates, coverage-map explanation, run commands, result directory shapes, and troubleshooting notes.
- `CLAUDE.md`: project overview, intended dataset structure, script descriptions, command workflow, environment variables, and expected result directories.
- `pyproject.toml`: dependencies, optional dev tools, package metadata, Python version, pytest/mypy/black/isort config, and declared MIT license text.
- `uv.lock`: pinned dependency resolution for key packages including `dspy-ai`, `openai`, `textgrad`, and `sentence-transformers`.
- `Makefile`: setup/install/test/lint/check commands, optimizer commands, prompt-test commands, process-kill commands, `data-check`, and cache clearing.
- `.env.template`: required `OPENAI_API_KEY`, optional W&B settings, and `DSPY_CACHEDIR`.
- `scripts/dspy_gepa_optimizer.py`: data loader, base prompt, DSPy module, GEPA setup, reflection model, scoring logic, train/validation split, and result saving.
- `scripts/textgrad_optimizer.py`: TextGrad model wrapper, critic loss prompt, optimizer loop, unseeded batch sampling, simple evaluation, and result saving.
- `scripts/textgrad_latest_gepa_optimizer.py`: latest GEPA prompt discovery, prompt loading from `optimized_model.json`, TextGrad refinement, and hybrid result metadata.
- `scripts/test_latest_gepa_prompt.py`, `scripts/test_latest_textgrad_prompt.py`, `scripts/test_latest_textgrad_gepa_prompt.py`: latest prompt loading, observation loading, OpenAI replay call, success definition, per-observation JSON writing, summary metrics, and token accounting.
- `scripts/MatchLines.py`: markdown line parsing, sentence splitting, embedding model, cosine-threshold matching, duplicate/order handling, and line-level match details.
- `scripts/generate_coverage_image.py`, `scripts/generate_coverage_image_map.py`, `scripts/generate_coverage_image_map_base.py`: basic and aggregate coverage image generation, gold-output comparison, and color semantics.
- `data/observations/_example-observation.json`: LangFuse-style failed `gpt-4o-mini` observation schema, prompt layout, metadata, and token usage shape.
- `data/gpt-4o/_example-output.json`: strong-model target output schema and improvement flags.
- `src/context_compression_experiments/__init__.py`: package marker and version.
- `.editorconfig`, `.gitignore`, `.vscode/settings.json`: formatting rules, ignored artifacts, and editor spell-check vocabulary.
- Git metadata and GitHub REST API metadata: exact reviewed commit, default branch, last commit date/message, current stars/forks, topics, license metadata, and repository update timestamps.

## Excluded Paths

- `.git/`: clone metadata only. Used through Git commands for reviewed commit, remote state, tracked files, and status; not reviewed as source.
- `coverage_map.png`: generated binary visualization. I reviewed the README explanation and the scripts that generate it instead of treating pixels as source logic.
- `cache/dspy/.gitkeep`, `logs/.gitkeep`, `data/.gitkeep`, `data/results/.gitkeep`, `data/observations/.gitkeep`, `data/gpt-4o/.gitkeep`: empty directory marker files. They define expected storage locations but contain no runtime logic.
- `data/results/` generated experiment outputs: absent in the public checkout except `.gitkeep`.
- `data/tests/` generated test outputs: directory absent in the public checkout.
- Real private `data/observations/*.json` and `data/gpt-4o/*.json`: absent from the public checkout; only example schema files are available.
- Notebooks: none present in the tracked checkout.
- `tests/`: no test directory exists in the tracked checkout.
- `.agents/`: empty directory in the clone, no source content.
- Vendored dependencies and build output: none present in the tracked checkout.
- UI-only paths: none present in the tracked checkout.
