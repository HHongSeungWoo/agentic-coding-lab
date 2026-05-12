# 3DAgentWorld/Toolkit-for-Prompt-Compression

- URL: https://github.com/3DAgentWorld/Toolkit-for-Prompt-Compression
- Category: token-efficiency
- Stars snapshot: 291 (GitHub REST API, captured 2026-05-12)
- Reviewed commit: e38d6d80c1bdc1eb4feb8fe008e0aad48003a006
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: in-scope
- Verdict: Useful compression-method survey and experiment scaffold, but not a drop-in coding-agent context compressor. It collects several lossy prompt compression families behind one API, with broad benchmark wiring, but reproducibility and safety are weak because models, APIs, datasets, ratios, and evaluation prompts are loosely controlled.

## Why It Matters

Token pressure is a core coding-agent problem: agents need to keep instructions, tool output, code, errors, and plans inside a finite context window without losing decision-critical details. PCToolkit is relevant because it implements or wraps common prompt compression approaches in one place: Selective Context, LLMLingua, LongLLMLingua, LLMLingua2, SCRL, and Keep It Simple.

The repo is most valuable as a taxonomy and reference harness. It shows what generic NLP compression keeps or drops, how compression ratios are counted, and how evaluations can connect compression to downstream task quality rather than only token savings.

## What It Is

PCToolkit is a Python package plus benchmark data. The package has four main modules: `pctoolkit/compressors.py`, `pctoolkit/datasets.py`, `pctoolkit/metrics.py`, and `pctoolkit/runners.py`. `PromptCompressor` is the user-facing facade. It dispatches by string type to method wrappers under `pctoolkit/methods/`.

The compression outputs are dictionaries with `compressed_prompt`, token counts, and an observed ratio. Methods are lossy. Selective Context deletes low self-information units. LLMLingua-family methods rank and filter contexts, sentences, and tokens with language-model loss or retrieval scores. SCRL selects tokens using a trained reinforcement-learning sentence compressor. KiS generates shorter text with a causal LM.

The repo also includes raw benchmark datasets and wrappers for BBC, ShareGPT, arXiv, GSM8K, LongBench, BBH, SCRL sentence-compression datasets, IconQA, and OKVQA. Evaluation is done through hard-coded runner branches, metrics, and OpenAI calls.

## Research Themes

- Token efficiency: Strong. This is the direct purpose of the repo, and it exposes multiple deletion, ranking, and generation-based compression methods.
- Context control: Moderate. LongLLMLingua exposes context-level, sentence-level, token-level, forced-context, budget, reorder, and dynamic-ratio knobs, but there is no coding-agent-aware protection for instructions, file paths, line numbers, stack traces, diffs, or code blocks.
- Sub-agent / multi-agent: None. The toolkit is single-process compression and evaluation code.
- Domain-specific workflow: Weak. Benchmarks include code completion through LongBench, but the runner is task-prompt-specific NLP evaluation, not an agent workflow.
- Error prevention: Weak. There are no real tests, no version pinning, no schema validation, and several hard-coded secrets/config values.
- Self-learning / memory: Limited. SCRL is trainable and checkpoint-based, but the toolkit has no adaptive memory or session learning.
- Popular skills: Relevant ideas are prompt compression, context ranking, token pruning, forced retention, reconstruction evaluation, and downstream task evaluation.

## Core Execution Path

For direct use, the user installs `requirements.txt`, downloads external models as needed, creates `PromptCompressor(type=...)`, then calls `compressgo(original_prompt=..., ratio=...)`. The facade dispatches to one of the method wrappers and returns a compressed prompt plus token counts.

Selective Context loads spaCy and GPT-2-style models, computes token self-information, aggregates it into sentence, phrase, or token units, and drops units below a percentile threshold. It returns removed content as `reduced_content`, which is useful for auditing loss.

LLMLingua, LongLLMLingua, and LLMLingua2 are implemented through `LLMLinguaCompressor`. The main path can rank contexts against a question, select a context budget, optionally filter sentences, then iteratively remove low-importance tokens. It uses token loss/perplexity, optional question conditioning, and optional retrieval/reranking backends such as BM25, gzip distance, SentenceTransformers, BGE, OpenAI embeddings, VoyageAI, and Cohere. The separate `longlingua_compressor.py` appears stale and unused by the facade.

SCRL loads a pretrained token selector from a model directory, chunks input text by character length, predicts keep/drop labels, and joins selected-token summaries. KiS chunks text, runs `generate()`, and joins generated simplifications. In both wrappers, the `ratio` argument is effectively not a control knob for compression strength.

For evaluation, `pctoolkit_demo.py` loads a compressor, dataset, metrics, and calls `run()`. `runners.py` branches by dataset. Reconstruction and summarization flows call OpenAI chat completions to restore or answer from compressed text, then compute BLEU, ROUGE, and BERTScore. LongBench, BBH, GSM, IconQA, and OKVQA branches use task-specific prompts and simple accuracy or matching logic.

## Architecture

The architecture is a shallow toolkit facade around several heterogeneous implementations:

- Facade: `PromptCompressor` chooses a compressor by string type and forwards a large common argument list.
- Method wrappers: small wrappers normalize input/output around Selective Context, LLMLingua-family logic, SCRL, and KiS.
- Vendored/adapted method code: Selective Context and SCRL source are included directly; LLMLingua-family code is copied/adapted into one large module.
- Data layer: `datasets_helper.py` loads local benchmark files through Hugging Face `datasets`.
- Evaluation layer: `runners.py` manually orchestrates compression, LLM restoration/answering, and metrics per dataset.
- Metrics layer: `metrics.py` defines BLEU, ROUGE, BERTScore, LongBench-style QA/classification/retrieval/code metrics, but only enables three generic metrics by default.

The main design is plug-and-play at the API level, not at the reproducibility level. Each method still brings its own models, tokenizers, external downloads, hardware assumptions, and task-specific parameters.

## Design Choices

The best design choice is making compressor output explicit: compressed prompt, original tokens, compressed tokens, and observed ratio. That is the right primitive for comparing token-efficiency methods.

The second useful choice is evaluating compression through task performance. Reconstruction, summarization, math, QA, few-shot, code completion, and synthetic tasks reveal different loss modes.

The weakest design choice is unifying very different methods through a single loose `compressgo()` signature. Some parameters matter only for one method. Some methods ignore `ratio`. For Selective Context, `ratio` is a deletion percentile; for LLMLingua-family methods, it is transformed into a target remaining fraction; for SCRL and KiS it is not used to control the generated length.

Another risky choice is allowing user-provided `context_budget` to be applied through `eval("target_token" + context_budget)`. That is not acceptable in an agent system.

## Strengths

PCToolkit gives a compact map of prompt compression families with executable code rather than only citations.

The LLMLingua-family wrapper exposes useful practical knobs: forced context IDs, context count, sentence filtering, token filtering, context reorder, dynamic compression ratios, and question-conditioned scoring.

The runner connects compression to downstream outcomes. Even with rough implementation, this is better than optimizing only token count.

Selective Context returns removed content, which makes compression loss inspectable.

The repo includes benchmark loaders and dataset cards, making it easy to see which tasks the authors intended to test.

## Weaknesses

Reproducibility is weak. Dependencies are unpinned, spaCy model downloads are not declared, NLTK resources are downloaded at runtime, SCRL pretrained models must be fetched manually, and many Hugging Face models require network/GPU access.

Evaluation is brittle. `runners.py` has hard-coded API keys, a hard-coded non-default OpenAI base URL, broad exception swallowing, concurrent API calls, and prompts embedded directly in code. Results are printed, not written to structured artifacts.

The repo has no meaningful test suite. A search found examples and evaluation scripts, but no unit/integration tests for compressor contracts, ratios, metrics, or runner branches.

Compression semantics are inconsistent. `ratio` does not mean the same thing across methods, and KiS/SCRL wrappers do not use it as a compression target.

There is stale or broken-looking code. `pctoolkit/methods/longlingua_compressor.py` is not imported by the facade and uses a non-package relative import. The OpenAI embedding helper indexes `["LongBench"]` where the API normally returns `data`. The LongBench facade type defaults to LLMLingua-style ranking unless the caller overrides `rank_method`.

Generic NLP compression can drop facts that are critical for coding agents: exact identifiers, numeric values, ordering constraints, error messages, file paths, line numbers, and negative instructions.

## Ideas To Steal

Use a simple compressor interface that always reports original token count, compressed token count, observed ratio, and compressed text.

Keep an audit trail of removed units, at least for deletion-based compressors.

Support forced-retention regions for instructions, current task, tool-call outputs, file paths, code blocks, errors, and user constraints.

Evaluate compression by downstream task success, not just token savings. For coding agents, that means build/test/lint success, patch correctness, and answer faithfulness.

Separate context-level ranking from token-level pruning. Long contexts often need coarse selection before fine pruning.

Use multiple loss probes: reconstruction quality, QA accuracy, code similarity, and exact-match checks for critical literals.

## Do Not Copy

Do not use `eval()` for budget expressions.

Do not ship hard-coded API keys, base URLs, model tokens, or user-specific paths.

Do not use one ambiguous `ratio` parameter across methods with different semantics.

Do not rely on generic sentence/token compression for coding-agent context without protecting syntax, identifiers, and constraints.

Do not make evaluation depend on live external LLM calls without recording model, prompt, seed/temperature, request parameters, and raw outputs.

Do not vendor large datasets or third-party method trees into a product repo unless provenance, license, and update policy are explicit.

## Fit For Agentic Coding Lab

Fit is in-scope as a token-efficiency reference, but adoption should be selective. The repo is useful for method taxonomy, API shape, ratio accounting, and evaluation ideas. It is not suitable as a direct context compressor for coding agents.

Agentic Coding Lab should adapt the interface and evaluation pattern, then add coding-specific guards: preserve system/developer/user instructions, exact command outputs, error lines, code hunks, paths, symbols, numbers, and open decisions. Compression should run behind a harness that measures whether the agent still performs the task correctly after compression.

The strongest practical artifact to derive is a small compression-eval harness with forced-retention spans, removed-content audit logs, and task-success metrics. The weakest artifact to copy is the runtime compressor stack itself, because it is model-heavy, brittle, and not coding-aware.

## Reviewed Paths

- `/tmp/myagents-research/3DAgentWorld-Toolkit-for-Prompt-Compression/README.md`
- `/tmp/myagents-research/3DAgentWorld-Toolkit-for-Prompt-Compression/requirements.txt`
- `/tmp/myagents-research/3DAgentWorld-Toolkit-for-Prompt-Compression/pctoolkit/README.md`
- `/tmp/myagents-research/3DAgentWorld-Toolkit-for-Prompt-Compression/pctoolkit_demo.py`
- `/tmp/myagents-research/3DAgentWorld-Toolkit-for-Prompt-Compression/datasets_helper.py`
- `/tmp/myagents-research/3DAgentWorld-Toolkit-for-Prompt-Compression/datasets_card/README.md`
- `/tmp/myagents-research/3DAgentWorld-Toolkit-for-Prompt-Compression/datasets_card/LongBench.md`
- `/tmp/myagents-research/3DAgentWorld-Toolkit-for-Prompt-Compression/datasets_card/BBH.md`
- `/tmp/myagents-research/3DAgentWorld-Toolkit-for-Prompt-Compression/datasets_card/Arxiv_BBC_shareGPT.md`
- `/tmp/myagents-research/3DAgentWorld-Toolkit-for-Prompt-Compression/datasets_card/SCRL_datasets.md`
- `/tmp/myagents-research/3DAgentWorld-Toolkit-for-Prompt-Compression/pctoolkit/compressors.py`
- `/tmp/myagents-research/3DAgentWorld-Toolkit-for-Prompt-Compression/pctoolkit/datasets.py`
- `/tmp/myagents-research/3DAgentWorld-Toolkit-for-Prompt-Compression/pctoolkit/metrics.py`
- `/tmp/myagents-research/3DAgentWorld-Toolkit-for-Prompt-Compression/pctoolkit/runners.py`
- `/tmp/myagents-research/3DAgentWorld-Toolkit-for-Prompt-Compression/pctoolkit/pretrain_models/README.md`
- `/tmp/myagents-research/3DAgentWorld-Toolkit-for-Prompt-Compression/pctoolkit/methods/abs_compressor.py`
- `/tmp/myagents-research/3DAgentWorld-Toolkit-for-Prompt-Compression/pctoolkit/methods/selective_context_compressor.py`
- `/tmp/myagents-research/3DAgentWorld-Toolkit-for-Prompt-Compression/pctoolkit/methods/selective_context_source.py`
- `/tmp/myagents-research/3DAgentWorld-Toolkit-for-Prompt-Compression/pctoolkit/methods/llmlingua_compressor_pro.py`
- `/tmp/myagents-research/3DAgentWorld-Toolkit-for-Prompt-Compression/pctoolkit/methods/llmlingua_compressor_utils.py`
- `/tmp/myagents-research/3DAgentWorld-Toolkit-for-Prompt-Compression/pctoolkit/methods/longlingua_compressor.py`
- `/tmp/myagents-research/3DAgentWorld-Toolkit-for-Prompt-Compression/pctoolkit/methods/scrl_compressor.py`
- `/tmp/myagents-research/3DAgentWorld-Toolkit-for-Prompt-Compression/pctoolkit/methods/kis.py`
- `/tmp/myagents-research/3DAgentWorld-Toolkit-for-Prompt-Compression/pctoolkit/methods/SCRL_new/README.md`
- `/tmp/myagents-research/3DAgentWorld-Toolkit-for-Prompt-Compression/pctoolkit/methods/SCRL_new/Makefile`
- `/tmp/myagents-research/3DAgentWorld-Toolkit-for-Prompt-Compression/pctoolkit/methods/SCRL_new/config/example.json`
- `/tmp/myagents-research/3DAgentWorld-Toolkit-for-Prompt-Compression/pctoolkit/methods/SCRL_new/bin/train.py`
- `/tmp/myagents-research/3DAgentWorld-Toolkit-for-Prompt-Compression/pctoolkit/methods/SCRL_new/bin/evaluate.py`
- `/tmp/myagents-research/3DAgentWorld-Toolkit-for-Prompt-Compression/pctoolkit/methods/SCRL_new/scrl/model.py`
- `/tmp/myagents-research/3DAgentWorld-Toolkit-for-Prompt-Compression/pctoolkit/methods/SCRL_new/scrl/rewards.py`

## Excluded Paths

- `/tmp/myagents-research/3DAgentWorld-Toolkit-for-Prompt-Compression/.git/`: VCS internals; reviewed commit recorded separately.
- `/tmp/myagents-research/3DAgentWorld-Toolkit-for-Prompt-Compression/imgs/`: logos, architecture image, and PDF asset; visual documentation only, not execution path.
- `/tmp/myagents-research/3DAgentWorld-Toolkit-for-Prompt-Compression/dataset/`: 390 MB of vendored/raw benchmark data, including JSONL, JSON, prompt text, and Parquet files. Loaders and dataset cards were reviewed instead of every data row.
- `/tmp/myagents-research/3DAgentWorld-Toolkit-for-Prompt-Compression/dataset/GSM8K/grade_school_math/`: vendored benchmark scripts/data; not compression implementation.
- `/tmp/myagents-research/3DAgentWorld-Toolkit-for-Prompt-Compression/dataset/IconQA/download_iconqa.sh` and `/tmp/myagents-research/3DAgentWorld-Toolkit-for-Prompt-Compression/dataset/OKVQA/download_okvqa.sh`: dataset download helpers, unrelated to prompt compression logic.
- `/tmp/myagents-research/3DAgentWorld-Toolkit-for-Prompt-Compression/pctoolkit/methods/SCRL_new/data/`: copied SCRL test data; evaluation scripts and README were reviewed instead.
- `/tmp/myagents-research/3DAgentWorld-Toolkit-for-Prompt-Compression/pctoolkit/methods/SCRL_new/images/`: model diagram binary asset; not runtime behavior.
- `/tmp/myagents-research/3DAgentWorld-Toolkit-for-Prompt-Compression/pctoolkit/methods/SCRL_new/loaders/`: SCRL dataset-specific loaders; representative data-loading behavior was covered through top-level dataset loading and SCRL evaluation code.
- External demo links in README, including Hugging Face Spaces and YouTube: UI/demo surfaces outside the cloned repo; not needed for method or evaluation review.
