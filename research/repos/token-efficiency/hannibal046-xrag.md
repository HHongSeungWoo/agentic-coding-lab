# Hannibal046/xRAG

- URL: https://github.com/Hannibal046/xRAG
- Category: token-efficiency
- Stars snapshot: 179 (GitHub REST API, captured 2026-05-12)
- Reviewed commit: 121fa4180a8c1fa0ec1af5901d879452e5c9ce89
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong research reference for extreme RAG context compression: replace each retrieved document text span in the LLM prompt with one `<xRAG>` placeholder whose embedding is overwritten by a projected dense-retriever document vector. High idea value for token efficiency, but low direct adoption value for coding agents unless we can fine-tune/open-weight the target LLM and accept lossy, non-citable context.

## Why It Matters

xRAG attacks the expensive half of RAG after retrieval: feeding long retrieved documents through the language model. The repo implements the "one soft token per retrieved document" version of context compression. Retrieved text is encoded by a dense retriever, projected into the LLM hidden space by a small trainable bridge, and inserted at `<xRAG>` token positions before `forward` or `generate`.

For Agentic Coding Lab, this is relevant because coding agents often burn context on retrieved files, logs, docs, prior traces, or memory snippets. xRAG shows a hard upper bound approach: if a chunk can be represented by one retriever vector and the LLM is trained to use that vector, the prompt pays one token per chunk instead of hundreds. The tradeoff is severe: the LLM sees a learned semantic feature, not exact source text, so quotations, line references, code edits, and provenance become weaker unless the raw source remains available through tools.

## What It Is

xRAG is a research codebase for the NeurIPS 2024 paper "xRAG: Extreme Context Compression for Retrieval-augmented Generation with One Token." It includes custom Mistral and Mixtral causal LM wrappers, an SFR dense embedding wrapper, language-modeling preprocessing/training code, evaluation code, a latency/FLOPs profiler, sample data, and partial dense-retrieval utilities.

The main implementation supports two pretrained checkpoints listed in the README: `Hannibal046/xrag-7b` on `mistralai/Mistral-7B-Instruct-v0.2`, and `Hannibal046/xrag-moe` on `mistralai/Mixtral-8x7B-Instruct-v0.1`. The repo is not a plug-and-play RAG app. It is closer to a reproducibility scaffold for training a projector and evaluating xRAG on knowledge-intensive QA tasks.

## Research Themes

- Token efficiency: Core theme. One retrieved passage becomes one `<xRAG>` token in the LLM prompt. The profiler compares normal RAG prompt length `instruction_length + 180 * num_docs` against xRAG prompt length `instruction_length + num_docs`.
- Context control: Simple but powerful: `<xRAG>` token count must exactly match provided retrieval embedding count. Evaluation can select retrieval ranks and multiple documents, but each document still maps to one token with SFR's `get_embed_length() == 1`.
- Sub-agent / multi-agent: Not present. No subagent orchestration, routing, or multi-agent memory model.
- Domain-specific workflow: Knowledge-intensive RAG and QA. Data prep mixes open QA, closed QA, summarization, and fact checking datasets; evaluation primarily ships TriviaQA samples.
- Error prevention: Limited. The model wrappers assert placeholder/embedding count and attention-mask shape. Training filters examples for label availability and KL token-count match. There is no test suite, CI, or robust runtime validation.
- Self-learning / memory: Not a memory system. It can compress retrieved memory chunks if trained for that use, but it does not decide what to store, update, consolidate, or forget.
- Popular skills: No skill pack. Useful reusable pattern is "retrieved context as projected soft tokens" plus projector-only tuning and raw-RAG self-distillation.

## Core Execution Path

1. Retrieval selects one or more background documents. In the shipped TriviaQA path, `data/eval/triviaqa/retrieval/colbertv2/test.jsonl` stores ColBERT-v2 retrieval results as text passages.
2. If xRAG is enabled, `src/eval/run_eval.py` loads `Salesforce/SFR-Embedding-Mistral`, tokenizes each retrieved passage to max length 180, and calls `SFR.get_doc_embedding`.
3. Prompt construction inserts `<xRAG>` in the `Background:` slot instead of raw document text. With top-k retrieval, it inserts one placeholder per retrieved passage.
4. `XMistralForCausalLM` or `XMixtralForCausalLM` receives `input_ids` plus `retrieval_embeds`.
5. `prepare_inputs_embeds` embeds normal input tokens, reshapes retrieval vectors, asserts `num_xrag_tokens == num_retrieval_embeds`, projects each retrieval vector through `Projector`, and overwrites the corresponding `<xRAG>` token embedding.
6. The base Hugging Face model runs with `inputs_embeds`; generation uses the same embedding-replacement path for the first decoding step.
7. Evaluation decodes generated answers and computes substring match for open QA, fact-checking accuracy for `factkg`, or F1/Rouge-L for `truthfulqa`.

Training has two stages:

1. Pretraining uses paraphrase-style prompts where `<xRAG>` should mean the original document. Default config updates only the projector with NLL loss.
2. Fine-tuning builds both an xRAG prompt and a vanilla raw-background prompt. It trains the xRAG path with NLL and optionally adds KL self-distillation from the raw-background path's logits.

## Architecture

The model architecture is minimal and surgical:

- `SFR` wraps `MistralModel` as a dense retriever. It pools the last non-padding hidden state and exposes the same embedding for documents and queries.
- `XMistralConfig` and `XMixtralConfig` add `projector_type` and `retriever_hidden_size`.
- `Projector` is an MLP such as `mlp2x_gelu` from retriever dimension to LLM hidden dimension.
- `XMistralForCausalLM` and `XMixtralForCausalLM` subclass Hugging Face causal LMs and intercept `forward`/`generate` to replace placeholder token embeddings.
- `XRAG_TOKEN = "<xRAG>"` is added to the tokenizer as a placeholder. Its learned token embedding is not the compressed context when `retrieval_embeds` are passed; it is replaced before the base model sees it.

The data path has three loosely coupled parts:

- Language-modeling pipeline: `src/language_modeling/preprocessing.py`, `train.py`, `utils.py`, and configs under `config/language_modeling/`.
- Evaluation pipeline: `src/eval/run_eval.py`, `utils.py`, `data/eval/triviaqa/test.jsonl`, and precomputed ColBERT-v2 retrieval outputs.
- Dense retrieval utilities: scripts for ColBERT-style embedding, FAISS index building, retrieval, scoring, a hardcoded Flask ColBERT server, and MS MARCO retriever training configs.

Important nuance: the conceptual xRAG story reuses dense document embeddings from retrieval, and the tutorial demonstrates SFR embeddings for both search and compression over a toy datastore. The shipped TriviaQA evaluation path uses ColBERT-v2 text retrieval first, then recomputes SFR embeddings for the selected passages. That is still context compression for the LLM, but it is not full embedding reuse in the provided eval code.

## Design Choices

The strongest choice is inserting compressed context at the embedding layer instead of inventing a new attention mechanism. This keeps the base LLM architecture mostly intact and lets `generate` work through Hugging Face's `inputs_embeds` path.

Projector-only tuning is the second key choice. Defaults freeze the retriever and LLM and train the bridge, making xRAG closer to modality alignment than full model adaptation. The README tutorial describes the bridge as an extra modality bridge from retrieval feature space to LLM representation space.

Pretraining teaches the bridge that a document vector can stand in for the document text by asking the model to paraphrase or reconstruct meaning from `<xRAG>`. Fine-tuning then teaches task behavior and, when `alpha_kl > 0`, aligns the compressed path to the raw-background path.

The system treats chunking as retrieval-token multiplicity. Long backgrounds can be split into 180-token retriever chunks; each chunk contributes one `<xRAG>` token and one retrieval embedding. This gives a linear but much smaller context cost for multi-chunk documents.

Evaluation is intentionally lightweight. It relies on local JSONL files, direct Hugging Face model loading, deterministic generation, and simple answer matching. The repo favors research scripts over a production RAG stack.

## Strengths

- Extremely clear compression mechanism: one retrieved document embedding replaces one placeholder token embedding.
- Small model integration surface. The custom Mistral/Mixtral code is short and easy to inspect.
- Good separation between frozen retriever, frozen base LLM, and trainable projector in default configs.
- Training path includes both semantic pretraining and task fine-tuning, not only inference-time prompting.
- Self-distillation from raw RAG to xRAG is a practical way to preserve behavior while removing raw text from the prompt.
- Profiler directly measures prompt-length, CUDA time, FLOPs per generated token, and peak memory for raw RAG versus xRAG.
- Tutorial makes the architecture concrete with no-retrieval, raw RAG, and xRAG versions of the same question.
- Multiple backbone support shows the pattern is not tied only to dense Mistral; Mixtral wrapper follows the same design.

## Weaknesses

- No tests or CI are present. Behavior relies on research scripts and runtime asserts.
- Direct coding-agent usefulness is limited because xRAG requires an open-weight LLM with custom class loading and projector training. Closed hosted models cannot accept these soft tokens.
- Compression is lossy. The LLM cannot quote exact retrieved text, cite line numbers, or inspect code spans from the compressed vector alone.
- Provided dense-retrieval utilities look incomplete or stale. Several scripts import `ColBERT`, `PolBERT`, `DPR`, `RetrieverTokenizer`, or `RAGTokenizerFast` symbols that are not exported by the reviewed `src/model`, while `colbert_server.py` hardcodes an external `/mnt/v-xincheng/ColBERT/` path.
- The main evaluation data included in the repo is TriviaQA; code branches for other datasets exist, but their data files are not included.
- Evaluation metrics are simple answer-string checks and do not evaluate faithfulness, citation quality, calibration, or retrieval failure modes.
- In shipped eval, xRAG compression embeddings are recomputed from retrieved passage text with SFR rather than reused from the ColBERT retrieval index.
- Several paths assume GPU-heavy infrastructure: 7B/MoE checkpoints, bf16, FlashAttention, Accelerate, DeepSpeed, and 8-GPU launch examples.
- `encode_with_chat_format_finetune` assumes a retriever is present when `use_rag_tuning` is true because `num_split` is only initialized in the `use_retriever_embed` branch.
- The repo has no license in GitHub metadata, which complicates direct reuse.

## Ideas To Steal

- Represent retrieved memory/doc chunks as placeholders in prompt text, then bind each placeholder to an external embedding at model-input time.
- Keep the compression bridge small and train it separately before considering full LLM tuning.
- Pair compressed-context training with a raw-context teacher path so compressed prompts learn to mimic uncompressed RAG behavior.
- Make placeholder count and embedding count a hard invariant. This is the right failure mode for compressed-context prompts.
- Use one token per retrieval chunk as a tunable context budget: top-k and chunking directly determine prompt-token cost.
- Add a profiler that reports token count, memory, latency, and FLOPs for raw context versus compressed context under identical generation settings.
- For agent memory research, separate "semantic memory available as vector" from "exact source available by tool." Use xRAG-like vectors for cheap recall, but fetch raw files/logs before edits or citations.

## Do Not Copy

- Do not treat one-vector compression as enough for code editing, exact diagnostics, legal/security review, or line-specific reasoning.
- Do not depend on xRAG for provenance. Keep retrieved source IDs and raw text accessible outside the compressed prompt.
- Do not reuse the dense retrieval scripts as-is without fixing missing imports, external ColBERT assumptions, and hardcoded paths.
- Do not cite benchmark quality from this repo alone. The checkout has scripts and sample data, not reproduced result tables.
- Do not assume the provided TriviaQA eval path proves embedding reuse. It retrieves with ColBERT outputs and embeds selected texts with SFR at evaluation time.
- Do not adopt GPU-heavy training defaults for lightweight agent tooling unless the goal is research, not day-to-day coding-agent support.

## Fit For Agentic Coding Lab

Fit is high as a token-efficiency research pattern and low as an immediate implementation dependency. The core idea is valuable: context can be moved from token space into learned embedding space when the model is trained to consume those embeddings. That is the most extreme version of compressing retrieved agent memory or documentation.

For near-term Agentic Coding Lab work, the practical adaptation is conceptual rather than direct. Use xRAG as a warning and target: semantic vectors can reduce prompt load, but coding agents still need raw source retrieval for exact operations. A robust coding-agent design would combine cheap vector summaries or memory embeddings with tool-mediated source access, citation checks, and fallback to raw snippets when exactness matters.

Direct adoption would require controlling the LLM weights, tokenizer, model class, retriever, and training loop. That makes it unsuitable as a drop-in improvement for standard Codex/Claude-style coding agents, but useful for future local-agent research where an open model can be fine-tuned for compressed repo memory.

## Reviewed Paths

- `README.md`: repo purpose, checkpoints, data requirements, training commands, evaluation examples, and profiler command.
- `Dockerfile`: dependency and runtime assumptions, including CUDA, PyTorch, Transformers, Accelerate, DeepSpeed, and FlashAttention.
- `tutorial.ipynb`: source cells for no-retrieval, raw RAG, SFR retrieval, and xRAG one-token generation walkthrough.
- `prepare_data.ipynb`: source cells for building instruction-tuning examples from QA, summarization, fact-checking, and context-aware datasets.
- `assets/framework.jpg`: architecture figure, viewed only to confirm high-level flow and frozen/trainable components.
- `src/model/SFR/modeling_sfr.py`: SFR embedding wrapper, last-token pooling, document/query embedding API, and embedding length.
- `src/model/xMistral/modeling_xmistral.py`: Mistral config, projector, `<xRAG>` embedding replacement, `forward`, and `generate`.
- `src/model/xMixtral/modeling_xmixtral.py`: Mixtral equivalent of the xRAG model wrapper.
- `src/model/__init__.py`: exported model classes used by training and evaluation.
- `src/language_modeling/utils.py`: loss functions, save logic, `XRAG_TOKEN`, paraphrase/RAG instruction templates, and retriever embedding helper.
- `src/language_modeling/preprocessing.py`: pretraining/fine-tuning encoders, background splitting, xRAG/raw RAG prompt construction, and task templates.
- `src/language_modeling/train.py`: config parsing, retriever loading, tokenizer/model setup, projector freezing, collator, NLL/KL training path, and checkpoint saving.
- `src/language_modeling/profiler.py`: synthetic raw-RAG versus xRAG prompt-length, latency, FLOPs, and peak-memory benchmark.
- `config/language_modeling/pretrain.yaml`: pretraining defaults for Wikipedia paraphrase training with SFR and projector-only updates.
- `config/language_modeling/finetune.yaml`: context-aware instruction tuning defaults, raw RAG self-distillation settings, and projector-only updates.
- `scripts/language_modeling/pretrain.sh` and `instruction_tuning.sh`: Accelerate launch examples for Mistral and Mixtral.
- `src/eval/run_eval.py`: prompt construction, retrieval-file loading, SFR embedding preparation, generation path, metrics, and result reporting.
- `src/eval/utils.py`: stop criteria, answer normalization, substring match, fact-checking, TruthfulQA, and recall helpers.
- `data/sample_paraphrase_pretrain.jsonl` and `data/sample_instruction_tuning.jsonl`: sample training schemas.
- `data/eval/triviaqa/test.jsonl`: included TriviaQA evaluation questions and answers.
- `data/eval/triviaqa/retrieval/colbertv2/test.jsonl`: included ColBERT-v2 retrieval result schema and top-k text passages; sampled and counted, not read exhaustively.
- `src/dense_retrieval/doc2embedding.py`, `build_index.py`, `retrieve.py`, and `score.py`: ColBERT-style document embedding, FAISS index, retrieval, reranking, and scoring utilities.
- `src/dense_retrieval/train_retriever.py`, `tsv2mmap.py`, and `colbert_server.py`: retriever training/preprocessing/server code, reviewed mainly for completeness and operational assumptions.
- `config/dense_retrieval/*.yaml`: retriever training configs for ColBERT, DPR, and PolBERT variants.
- `src/utils/utils.py`: JSONL helpers, wiki collection loader, seed helper, YAML loader, and retrieval metric utilities.
- Git metadata and GitHub REST API: reviewed commit, remote URL, star count, pushed date, license metadata, and tracked file list.

## Excluded Paths

- `.git/`: clone metadata only. Used through Git commands for commit, status, remote, and tracked file inventory, not reviewed as content.
- `.agents/` and `.codex/`: empty directories in the cloned checkout; no research content.
- `data/eval/triviaqa/retrieval/colbertv2/test.jsonl`: generated/precomputed retrieval output with 11,313 JSONL rows. I sampled schema and first rows and used line count, but excluded exhaustive reading because it is generated evaluation data.
- `data/eval/triviaqa/test.jsonl`: evaluation dataset with 11,313 rows. I sampled schema and first rows, but excluded exhaustive reading because individual trivia questions do not change the architecture review.
- `assets/framework.jpg`: binary figure. I viewed it to confirm architecture but excluded it from code-level analysis.
- Notebook outputs and binary notebook metadata in `prepare_data.ipynb` and `tutorial.ipynb`: reviewed source cells only; outputs are not needed for architecture and include bulky rendered state.
- `config/ds_configs/*.conf` and `config/fsdp_configs/*.config`: DeepSpeed/FSDP runtime packaging. Reviewed at inventory level only because they do not affect the xRAG compression mechanism.
- `.gitignore` and generated dependency/cache artifacts: not relevant to model architecture or evaluation behavior.
- UI-only paths: none present in the tracked checkout.
- Vendored dependencies: none present in the tracked checkout.
