# RECOMP: Improving Retrieval-Augmented LMs with Compression and Selective Augmentation

- URL: https://arxiv.org/abs/2310.04408
- Cite as: arXiv:2310.04408
- DOI: 10.48550/arXiv.2310.04408
- Authors: Fangyuan Xu, Weijia Shi, Eunsol Choi
- Venue / source: arXiv preprint; accepted as an ICLR 2024 poster under the OpenReview title "RECOMP: Improving Retrieval-Augmented LMs with Context Compression and Selective Augmentation."
- Published: arXiv submitted 2023-10-06; OpenReview published 2024-01-16 and last modified 2024-03-15.
- Citations snapshot: 10 citations
- Citation source: OpenAlex work W4394645901, `cited_by_count=10`, captured 2026-05-31. Semantic Scholar Graph API for `arXiv:2310.04408` returned HTTP 429 during review, so no Semantic Scholar count is recorded here.
- Code: https://github.com/carriex/recomp; reviewed commit `51d4432151efb3275257a9407dc71d1e5ec6634d` from 2026-01-06. GitHub API showed 148 stars and 8 forks on 2026-05-31.
- Topic: context-control
- Reviewed at: 2026-05-31
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong context-control paper for retrieval augmentation because it makes retrieved context conditional, compressed, and task-scored before it enters the LM context. For Agentic Coding Lab, adopt the selective compression/evaluation pattern, not the exact QA-trained T5/Contriever implementation.

## Problem

Retrieval-augmented LMs often prepend retrieved documents directly to the model input. That works for black-box LMs because the base model does not need retraining, but it creates three context-control problems: inference becomes more expensive, long contexts make it harder for the LM to find the useful span, and irrelevant retrieved text can distract the model into wrong answers.

RECOMP targets the augmentation step rather than the retriever or the base LM. The paper asks whether retrieved documents should be compressed into short textual evidence before being prepended. The core objective is practical: keep the useful retrieval signal, drop distractors, and sometimes prepend nothing when retrieved context is irrelevant or harmful.

This maps cleanly to coding agents. Search results, docs snippets, tool logs, test output, and repository-wide references are often useful, but stuffing every retrieved chunk into context can push out higher-priority state or make the agent chase irrelevant APIs and files.

## Method

RECOMP stands for Retrieve, Compress, Prepend. Given input `x`, target `y`, and retrieved documents `D`, it trains a compressor `c_theta` to produce a textual summary `s` that is concise, effective for the downstream LM, and faithful to the retrieved documents. The base LM is treated as black-box; the compressor is trained separately and is intended to be smaller than the LM whose context it controls.

The paper studies two compressors:

1. Extractive compressor: a sentence selector initialized from Contriever. It embeds the query/input and candidate sentences independently, scores them with an inner product, and prepends the top sentence or sentences. Training uses end-task signal from the LM: positive sentences are those that make the target more likely or produce the right answer, while negatives are hard retrieved sentences that score worse under the downstream task. The released training script implements this with SentenceTransformers and `MultipleNegativesRankingLoss`.
2. Abstractive compressor: a T5-large encoder-decoder model distilled from GPT-3.5 query-focused summaries. The teacher generates candidate summaries; a critic step keeps the summary that best improves the downstream LM. If the best generated summary is worse than using no retrieved evidence, the training target becomes an empty string. That is the selective augmentation mechanism.

The training criterion matters more than the model choice. RECOMP does not train summaries to optimize ROUGE or human salience. It trains summaries to help a downstream LM perform the task while using fewer context tokens. For QA, the score is answer EM; for language modeling, it is likelihood/perplexity.

The official repository is small and research-oriented. It provides evaluation scripts for language modeling and QA, an extractive compressor runner, a SentenceTransformers training script, and a Hugging Face summarization fine-tuning script. The README links released compressor models and training data; the Hugging Face training dataset page is live but its dataset viewer currently reports a schema/cast error, so reproducibility likely requires pulling files directly rather than relying on the viewer.

## Evidence

Language modeling results on WikiText-103 use GPT-2 as the in-domain base LM and evaluate transfer to GPT2-XL and GPT-J. With GPT-2, no retrieval has 37.84 perplexity. Prepending the top retrieved document improves to 32.90 using 141 tokens, while top-5 raw documents worsens to 35.53 using 512 tokens. The trained extractive compressor reaches 33.67 perplexity with 31 tokens, and the trained abstractive compressor reaches 33.64 with 15 tokens. Oracle compression is much stronger, reaching about 30.36-30.67 perplexity with 32-68 tokens, showing large headroom in selecting or synthesizing only the useful retrieval evidence.

Transfer is mixed but encouraging for textual compression. Compressors trained with GPT-2 remain close to useful on GPT2-XL and GPT-J. The paper uses this as a key argument for textual summaries over soft prompts: the compressed evidence is still ordinary text and can be consumed by other LMs.

Open-domain QA results use Flan-UL2 on NQ, TriviaQA, and HotpotQA. Raw top-5 documents get the best non-oracle accuracy but require about 660-684 evidence tokens. On NQ, raw top-5 gets 39.39 EM / 48.28 F1 with 660 tokens; RECOMP's trained abstractive compressor gets 37.04 EM / 45.47 F1 with 36 tokens. On TriviaQA, raw top-5 gets 62.37 EM / 70.09 F1 with 677 tokens; the trained abstractive compressor gets 58.68 EM / 66.34 F1 with 32 tokens, while the trained extractive compressor gets 58.99 EM / 65.26 F1 with 38 tokens. On HotpotQA, raw top-5 gets 32.80 EM / 43.90 F1 with 684 tokens; the trained extractive compressor is stronger than the abstractive one, reaching 30.40 EM / 40.14 F1 with 75 tokens.

The QA oracle results are important because they show that less context can beat full context when the selection is right. The extractive oracle gets 60.22 EM on NQ, 79.29 on TriviaQA, and 41.80 on HotpotQA with a small fraction of the original token budget. This is not deployable as-is because the oracle needs answer labels, but it validates the core premise that much of the retrieved context is not merely redundant; it can be harmful.

The analysis section gives the most practical signal. On NQ, top-5 raw documents contain the gold answer more often than top-1, but the LM also copies from irrelevant evidence more often. When the gold answer is not in evidence, top-5 raw context produces predictions copied from evidence 81% of the time, and GPT-3.5 summaries do so 85% of the time. The trained abstractive compressor reduces that number to 39%, and the trained extractive compressor to 33%. This is directly relevant to coding agents that may copy irrelevant API names, file paths, or config options from retrieval.

Faithfulness is the main caution. The authors manually inspect 30 non-empty abstractive summaries per QA dataset. Their trained abstractive compressor is useful on 80% of NQ samples, 77% of TriviaQA samples, and only 40% of HotpotQA samples. It is less faithful than GPT-3.5 summaries, though often more comprehensive. Multi-hop synthesis is the weak point.

## Limits

The paper is not a coding-agent evaluation. Evidence comes from language modeling and open-domain QA, so transfer to software engineering work is analogical. Coding tasks have stricter requirements for exact symbols, paths, stack traces, diffs, command output, versions, and user constraints.

The training loop assumes downstream labels or a measurable task score. That is feasible for QA and perplexity, and for offline coding harnesses with tests, but not for arbitrary online user tasks. The oracle numbers should be read as upper bounds, not deployable performance.

Abstractive compression can hallucinate or over-synthesize. The paper explicitly reports weaker faithfulness for its smaller abstractive compressor and poor HotpotQA usefulness. That is a serious concern for code, where a plausible but nonexistent API or file can waste many tool turns.

Selective augmentation is learned from comparisons against no-retrieval performance. In real agent workflows, "no retrieval" is not always a stable baseline, and some evidence is required for safety or reproducibility even if it does not immediately improve a benchmark score.

The official code is useful for reproducing the paper but not a production context-control subsystem. It relies on external data/model downloads, GPU-heavy models, research scripts, and dataset schemas that are not currently cleanly viewable through Hugging Face's dataset preview.

The paper optimizes the compressor, not the retriever. It assumes retrieved documents are available and mostly uses fixed top-k settings. Retrieval errors, stale sources, adversarial retrieved text, and source provenance are not deeply addressed.

## Research Themes

- Token efficiency: High relevance. RECOMP gets QA evidence down to roughly 5-11% of raw top-5 token counts with moderate loss, and language-modeling compression can use 15-31 tokens instead of 141-512.
- Context control: High relevance. The paper treats retrieval augmentation as a gated, compressed, task-scored context assembly step.
- Sub-agent / multi-agent: Medium-low relevance. The compressor is a separate model/module from the acting LM, but the work is not about coordination among agents.
- Domain-specific workflow: Medium relevance. Compressors are trained per task/dataset and judged by downstream outcomes, which maps well to repo-specific or workflow-specific context policies.
- Error prevention: High relevance. The selective compressor reduces copying from irrelevant evidence, a close cousin of agent errors caused by stale or noisy context.
- Self-learning / memory: Low relevance. The method learns offline compressors from datasets, not persistent user/project memory.
- Popular skills: Medium relevance. The reusable pattern is skill-like: a task-specific context filter with explicit rules, model weights, and evaluation.

## Key Ideas

- Retrieval augmentation should be conditional. If retrieved text is irrelevant or harmful, the compressor can output an empty string.
- Summaries should be optimized for the downstream LM outcome, not generic summarization quality.
- Use extractive compression when exact faithfulness matters and abstractive compression when synthesis across documents is valuable.
- Sentence-level reranking can be framed as context compression, not only retrieval reranking.
- Textual compressed evidence is portable across LMs in a way soft prompts and model-specific hidden states are not.
- Oracle compression is a useful diagnostic. If a tiny oracle context beats raw retrieved context, the system has a context-selection problem, not a retrieval-volume problem.
- Analyze not just task score but whether the model copies from irrelevant evidence.

## Ideas To Steal

- Add a "retrieve, compress, prepend" gateway before large external context enters Agentic Coding Lab prompts. Retrieved docs, search snippets, logs, and repo-wide matches should pass through relevance and compression gates.
- Use selective augmentation for coding context. A context filter should be allowed to return "no useful external evidence" instead of always filling the budget.
- Evaluate compression by coding outcomes: tests pass, lint/typecheck errors are resolved, correct files are edited, and user constraints are preserved. Do not score summaries only by readability.
- Split compression modes by evidence type. Use extractive retention for stack traces, failing assertions, file paths, command lines, schema fields, and API signatures. Use abstractive summaries for broader documentation, design rationale, and duplicate search hits.
- Build hard-negative datasets from agent failures. Sentences or snippets that look relevant but lead to wrong edits should become negatives for future context filters.
- Track a "copied irrelevant evidence" metric for coding. Examples: patch uses a path only present in an unrelated search hit, imports a library from stale docs, or repeats a command option from the wrong tool version.
- Store compressed context with provenance. Every retained fact should keep source path/URL, retrieval query, timestamp, and whether it was extracted verbatim or synthesized.
- Use oracle-style audits offline. For failed long-context tasks, ask what minimal exact evidence would have made the agent succeed, then turn that into compression policy tests.

## Do Not Copy

- Do not use abstractive summaries for exact coding evidence without guardrails. Preserve raw spans for identifiers, paths, stack frames, config keys, versions, and commands.
- Do not assume QA compression ratios transfer to coding. A 5% summary may be too lossy for debugging or migration tasks.
- Do not deploy oracle logic as a runtime strategy. It depends on labels or future outcomes that the agent does not have at decision time.
- Do not train a heavy T5/GPT-3.5 distillation pipeline as the first implementation. Start with deterministic/extractive policies and a regression harness.
- Do not collapse all retrieved context into one synthesized paragraph. Coding agents need provenance and separable evidence chunks.
- Do not ignore the failure mode where compressed text is more persuasive than raw evidence. The paper's GPT-3.5 summaries increased copying from irrelevant evidence in one analysis.
- Do not treat the official repo as turnkey infrastructure. It is a compact research release with external assets and limited operational packaging.

## Fit For Agentic Coding Lab

RECOMP is a strong conceptual fit for `context-control`. The most valuable contribution is the lifecycle: retrieve candidate context, compress it with a task-conditioned policy, selectively prepend only when it helps, and evaluate by downstream behavior.

For Agentic Coding Lab, the right adaptation is a context admission layer, not a generic summarizer. That layer should decide whether retrieved material enters the active prompt, whether it enters as exact evidence or a synthesis, and which provenance fields must survive. The default policy should favor exact extracted snippets for code/debugging facts, with abstractive summaries reserved for high-level documentation or repeated evidence.

The paper also supports a practical benchmark direction: build context-control regressions where raw retrieval distracts the agent, then measure whether compression prevents wrong-file edits, stale-doc usage, repeated failed commands, or loss of user constraints. RECOMP's downstream-score framing gives a defensible way to treat context compression as behavior-changing infrastructure that needs tests.

## Related Repositories

- https://github.com/carriex/recomp - Official MIT-licensed implementation. Reviewed commit `51d4432151efb3275257a9407dc71d1e5ec6634d`; the repo contains seven Python scripts, a README, one sample completion CSV, and links to external data/models. Current GitHub API snapshot showed 148 stars and 8 forks on 2026-05-31.
- https://huggingface.co/datasets/fangyuan/recomp_training - Training data release linked from the README. The page is live, but the dataset viewer reports a cast/schema error for at least one JSON file, so consumers should verify direct file access.
- https://huggingface.co/fangyuan/nq_extractive_compressor and https://huggingface.co/fangyuan/nq_abstractive_compressor - Example released compressor model pages linked from the README. They exist but have no model cards, so operational details mostly come from the paper and repository.

## Reviewed Sources

- arXiv abstract page: https://arxiv.org/abs/2310.04408
- arXiv PDF v1: https://arxiv.org/pdf/2310.04408
- arXiv TeX source: https://arxiv.org/e-print/2310.04408
- OpenReview ICLR 2024 poster record: https://openreview.net/forum?id=mlJLVigNHp
- OpenAlex API work record: https://api.openalex.org/works/W4394645901
- Semantic Scholar Graph API request attempted: https://api.semanticscholar.org/graph/v1/paper/arXiv:2310.04408
- Official code repository: https://github.com/carriex/recomp
- GitHub API repository metadata: https://api.github.com/repos/carriex/recomp
- Hugging Face training data page: https://huggingface.co/datasets/fangyuan/recomp_training
- Hugging Face model pages checked: https://huggingface.co/fangyuan/nq_extractive_compressor and https://huggingface.co/fangyuan/nq_abstractive_compressor
- Implementation files reviewed from the official repository: `README.md`, `eval_lm.py`, `prompt_flan.py`, `eval_qa.py`, `eval_utils.py`, `run_extractive_compressor.py`, `train_extractive_compressor.py`, and `train_hf_summarization_model.py`.
