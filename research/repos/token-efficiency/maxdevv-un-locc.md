# MaxDevv/Un-LOCC

- URL: https://github.com/MaxDevv/Un-LOCC
- Category: token-efficiency
- Stars snapshot: 71 (GitHub REST API, captured 2026-05-12)
- Reviewed commit: 6433d4ad95a1daaf3ba27ecb60eecd8f1b2e6d3b
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: conditional
- Verdict: Useful research prototype for lossy optical context compression, especially as an evaluation pattern for "cold archive" context. It is not a drop-in coding-agent compression layer: the repo measures visual needle retrieval, not reasoning over code, diffs, tool state, or agent transcripts; the implementation has no real token budget enforcement, no deterministic benchmark harness, no tests, and no production retrieval policy.

## Why It Matters

Un-LOCC explores a different way to reduce context cost: render text into an image, then ask a vision-language model to read from the image instead of consuming the same text as normal tokens. The useful observation is that some VLMs charge/process a fixed image-token budget for a dense page of text, so a dense rendered page can sometimes carry more source text than the equivalent text-token window.

For Agentic Coding Lab, the direct value is not "turn coding context into screenshots." Active coding context needs exact text, stable line numbers, diffs, syntax, tool IDs, and structured logs. The transferable idea is a lower-fidelity archive tier: old conversation history, long read-only logs, broad documentation, or historical evidence could be compressed into a visual artifact and queried only for recall-like tasks.

The repo also matters because it frames compression as an empirical calibration problem. The best font size, resolution, image-token count, and model vary sharply. A coding-agent context system should not assume one compressor ratio; it should profile each model/provider and keep per-model compression policies.

## What It Is

Un-LOCC is a small research repo for "Universal Lossy Optical Context Compression." It contains:

- `readme.md`: project explanation, key results, limitations, and a 90+ experiment appendix.
- `Un_LOCC_Research_As_PDF.pdf`: paper-style writeup with related work, method, results, and references.
- `main.py`: a Python O-NIH evaluation harness using Pillow and OpenRouter-compatible OpenAI chat completions.
- `corpus.txt`: Project Gutenberg source text used as the haystack corpus.
- `fonts/*.ttf`: local fonts used for rendering experiments.
- `fig-1.png`: bar chart summarizing maximum compression ratios by model and accuracy threshold.

The repo is a research/eval artifact, not a full compression library. The README points to `MaxDevv/Un-LOCC-Wrapper` for a Python implementation, but that external repo was outside this assigned review scope.

## Research Themes

- Token efficiency: Primary theme. README/PDF report up to 2.8:1 text-token-to-image-token compression at 93.65% retrieval accuracy for `google/gemini-2.0-flash-lite-001` in Experiment 56, and 2.2:1 at 94.44% for `qwen/qwen2.5-vl-72b-instruct` in Experiment 81. The code itself does not compute provider token counts or compression ratios.
- Context control: Moderate but visual-only. Control knobs are image dimensions, font, font size, padding, word count, and model. There is no relevance selection, chunk ranking, retention policy, or retrieval slice API.
- Sub-agent / multi-agent: None. A multi-agent system could share rendered archive pages, but this repo has no coordination, ownership, provenance, or concurrent retrieval design.
- Domain-specific workflow: Strong for VLM OCR-style retrieval experiments. Weak for coding agents unless adapted to read-only archive context. Code, patches, stack traces, and tool outputs need exact text channels.
- Error prevention: The O-NIH task avoids free-form transcription and grades with Levenshtein similarity after OCR normalization. However, the normalization conflates valid needle characters such as `A`/`4`, `B`/`8`, and `S`/`5`, which can inflate accuracy.
- Self-learning / memory: No learning or durable memory subsystem. The concept could become a visual memory tier, but the repo does not implement indexing, refresh, eviction, or retrieval history.
- Popular skills: No skill pack. Reusable artifacts are the O-NIH benchmark shape, visual packing parameters, and the warning that compression must be profiled per model.

## Core Execution Path

The actual runtime path is `main.py`:

1. CLI parses OpenRouter API key, model ID, font path, font size, image size, optional word count, test count, corpus path, and padding.
2. The script loads the selected `.ttf` font and `corpus.txt`.
3. If `--word_count` is absent, `find_max_word_count()` uses binary search plus Pillow font metrics to estimate the maximum number of source words that fit in the target image.
4. Each test run calls `prepare_text()`, which selects a random contiguous corpus span, generates a 9-character code in `XXX-XXX-XXX` form, and inserts that code at a random position.
5. `generate_image()` wraps the haystack text by pixel width, draws black text on a white RGB image, and writes a PNG under `output_images/test_image_<timestamp>.png`.
6. `query_llm_for_code()` base64-encodes the PNG, sends it as a data URL to OpenRouter via `OpenAI(base_url="https://openrouter.ai/api/v1")`, and asks the model to output only the verification code.
7. `fuzzy_similarity()` normalizes OCR-like confusions, removes hyphens/spaces, computes Levenshtein distance, and records a per-run similarity score.
8. The script prints expected code, received code, latency, per-run fuzzy accuracy, and average fuzzy accuracy over all runs.

The README appendix then records manual experiment results with image token counts, estimated text tokens, compression ratio, model, font, and average accuracy. Those ratio fields are not produced by `main.py`.

## Architecture

The architecture is intentionally flat:

- Research surface: README, PDF, figure, and experiment appendix.
- Evaluation harness: `main.py` with functions for needle generation, haystack preparation, text wrapping, image rendering, OpenRouter model call, and fuzzy scoring.
- Data/assets: Gutenberg corpus and font files.
- Dependencies: only `openai` and `Pillow` in `requirements.txt`.

There is no package layout, no importable module boundary, no config schema, no result store, no test suite, no CI, no notebook, and no benchmark runner beyond the CLI script. Model behavior is accessed through a remote VLM API; no local model or compression model code is implemented.

## Design Choices

The central design choice is to compress by changing modality, not by summarizing or pruning text. The source text remains visually present in the image, but it becomes lossy because OCR/perception can miss, confuse, or truncate details.

O-NIH uses retrieval instead of full transcription. That keeps output cost low and avoids common transcription failure modes such as repetition, but it only proves that a model can locate a distinctive token. It does not prove that the model can reason across the compressed context.

The benchmark treats model-specific image tiling as a core budget constraint. README/PDF argue that images slightly below a model's single-tile limit often perform better than larger images that trigger chunking. The reported good default is 864x864 for several VLMs.

Font choice is treated as a compression parameter. The experiments report strong differences between legible sans-serif fonts and weaker fonts, with Atkinson Hyperlegible, Lato, and Lexica Ultralegible performing well. Font size around 12px to 16px is the claimed practical band.

The text-token estimates in the README appendix appear to use a rough word-to-token conversion rather than provider-native tokenization. Image-token counts are recorded in the appendix, but there is no code path that measures them during a run.

The auto capacity path has a subtle risk: `find_max_word_count()` estimates how many corpus words fit, then `prepare_text()` inserts an extra needle token. When using max capacity, the final rendered haystack can exceed the measured fit. `generate_image()` draws all lines and lets overflow clip rather than validating that the final text fits.

Randomness is unseeded and results are printed to stdout. That is fine for exploration, but weak for reproducible regression testing.

## Strengths

The repo is small and easy to audit. The end-to-end evaluation path fits in one Python file and the research claims are backed by raw experiment logs in the README.

The benchmark design is practical for comparing VLM perception under many rendering settings. It avoids asking the model to transcribe thousands of words and instead uses a focused retrieval target.

The work correctly surfaces model-specific sweet spots. The table shows that Gemini Flash Lite, Qwen VL, Phi-4 Multimodal, UI-TARS, and Llama-4-Scout have different useful ratios and different failure points.

The visual packing variables are concrete: resolution, font family, font size, contrast, padding, word count, and model. Those are easy to turn into a grid search or provider profile.

The README/PDF limitations are candid about the biggest gap: perceptual retrieval is not the same as contextual understanding. That warning is essential for coding-agent transfer.

## Weaknesses

The strongest reported results are not generated by a reproducible benchmark artifact. `main.py` prints stdout only; the README appendix is a hand-maintained experiment log with no JSON/CSV source, seeds, retry policy, or exact API response metadata.

The implementation does not enforce or measure token budgets. It accepts image size and word count, but it does not ask the provider for image token counts, count text tokens with a tokenizer, compute compression ratio, or stop when a budget is exceeded.

The fuzzy scorer can over-credit mistakes. `generate_needle()` allows `A`, `B`, `S`, `4`, `5`, and `8`, while `normalize_for_ocr()` maps `A -> 4`, `B -> 8`, and `S -> 5`. A model can output a different valid character and still receive full credit for that position after normalization.

The max-word calculation can undercount final visual load because the needle is inserted after capacity calculation. At high density, this can clip the rendered code or surrounding text.

There are no tests. No unit tests cover wrapping, overflow, needle injection, scorer behavior, API error handling, or result aggregation. No examples directory or CI exists.

The eval corpus is a single public-domain prose source. That does not represent coding-agent context, which includes code, diffs, JSON, tables, stack traces, shell logs, file paths, and mixed structured/unstructured text.

The API path has no retries, no rate-limit handling, no per-run persistence, and no cost accounting. API exceptions become empty strings and are folded into accuracy.

Image-based context also creates a prompt-injection blind spot. Harmful or instruction-like text embedded in the image may bypass text-only filters or policy checks if the host system treats the image as inert archival context.

## Ideas To Steal

Use "compression profiles" per model/provider. Store empirically validated settings such as image size, font, font size, and safe density instead of using one global compression ratio.

Adopt O-NIH-style sentinel retrieval tests for any lossy context compressor. For coding agents, inject known sentinels into logs, docs, and prior conversation chunks, compress them, then verify retrieval accuracy before trusting the compressor.

Separate cold context from active context. Optical compression may fit read-only historical material; active code, patches, tool calls, and errors should stay textual and structured.

Optimize around provider billing and tiling boundaries. If a VLM has sharp image-token cliffs, compression should choose dimensions just below those cliffs.

Treat typography as infrastructure. For any visual context tier, choose high-legibility fonts, fixed line height, high contrast, deterministic layout, and post-render overflow checks.

Keep retrieval prompts narrow. Ask for exact IDs, file names, log markers, or short snippets from the visual archive rather than asking for open-ended reasoning.

Build a real benchmark harness around this idea: seed control, fixed corpora, structured output, provider token usage capture, retry metadata, cost/latency capture, and regression thresholds.

## Do Not Copy

Do not replace active coding-agent context with rendered images. Code editing requires exact text, line references, indentation, Unicode fidelity, and patchable source.

Do not treat needle retrieval accuracy as proof of reasoning quality. It measures visual search for a distinctive code, not synthesis across many facts.

Do not use OCR normalization that collapses characters present in the generated alphabet. Either remove ambiguous characters from the alphabet or score exact characters separately from OCR-tolerant variants.

Do not rely on manual appendix logs for production claims. Capture raw run records with commit, model version, prompt, seed, token usage, latency, errors, and artifact hashes.

Do not fill images to theoretical capacity without validating the final rendered text after sentinel insertion. Overflow should fail the run, lower density, or split pages.

Do not send visually compressed context to a VLM without prompt-injection policy. Treat image text as untrusted user/content input, not as safe storage.

Do not assume optical compression is always cheaper. Base64 payload size, image-token billing, VLM latency, and lower accuracy can erase savings.

## Fit For Agentic Coding Lab

Fit is conditional. Un-LOCC is valuable as a research pattern for evaluating lossy context compression, but weak as a direct coding-agent subsystem.

Best local adaptation: an "optical archive bench" that tests whether historical, read-only agent context can be compressed into visual pages and queried for exact sentinels. Candidate inputs should be old shell logs, long documentation pages, issue threads, and conversation history, not active source files or current diffs.

Useful artifact candidates:

- A model/provider visual packing profile with safe page sizes and density thresholds.
- A sentinel-injection benchmark for lossy context stores.
- A retrieval-only archive tool that returns exact snippets and provenance from visual pages.
- A policy that routes only low-risk historical context into optical storage.

The implementation should not be copied directly. Agentic Coding Lab would need structured run records, deterministic tests, token/cost telemetry, overflow checks, prompt-injection handling, provenance links back to original text, and a fallback path to text retrieval.

## Reviewed Paths

- `readme.md`: project thesis, key results table, per-model optimization summary, O-NIH method, limitations, future work, acknowledgements, and all 90+ experiment appendix entries.
- `Un_LOCC_Research_As_PDF.pdf`: extracted with `pdftotext`; reviewed related work, method, results table, limitations, code/data availability, and references.
- `main.py`: full O-NIH execution path, CLI arguments, OpenRouter client setup, random needle insertion, text wrapping, maximum word-count search, image generation, VLM call, fuzzy OCR scoring, and stdout result reporting.
- `requirements.txt`: dependency surface, limited to `openai` and `Pillow`.
- `corpus.txt`: source corpus identity and sample content; treated as benchmark fixture data rather than implementation logic.
- `fig-1.png`: reviewed chart of maximum compression ratios at `>=95%`, `>=85%`, and `>=70%` accuracy thresholds.
- `fonts/*.ttf`: reviewed as rendering inputs and file inventory; not reverse-engineered as font binaries.
- Git metadata and GitHub REST API metadata: exact commit, branch, latest commit date/message, clean checkout status, remote URL, default branch, stars, forks, topics, and repository update timestamps.
- File inventory checks: verified no tracked tests, examples, eval directories, package build outputs, or vendored dependencies beyond listed files.

## Excluded Paths

- `.git/`: clone metadata only. Used through Git commands for commit, branch, remote, and cleanliness; not reviewed as source content.
- `fonts/*.ttf` binary internals: font files are binary rendering assets. I reviewed their presence and role in experiments, but not glyph tables or licensing internals.
- `output_images/`: generated runtime image directory referenced by `main.py`; absent in the clean checkout and excluded as generated output.
- `MaxDevv/Un-LOCC-Wrapper`: linked external implementation repo. Excluded because this assignment scoped the review to `MaxDevv/Un-LOCC` and the write scope allowed only this note.
- Vendored dependencies: none present in the checkout. Dependency source for `openai` and `Pillow` was not reviewed.
- UI-only paths: none present. `fig-1.png` is a research chart, not UI implementation.
