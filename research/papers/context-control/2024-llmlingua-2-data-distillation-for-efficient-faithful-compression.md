# LLMLingua-2: Data Distillation for Efficient and Faithful Task-Agnostic Prompt Compression

- URL: https://arxiv.org/abs/2403.12968
- Cite as: arXiv:2403.12968; ACL Anthology ID `2024.findings-acl.57`; DOI `10.18653/v1/2024.findings-acl.57`
- Authors: Zhuoshi Pan, Qianhui Wu, Huiqiang Jiang, Menglin Xia, Xufang Luo, Jue Zhang, Qingwei Lin, Victor Ruhle, Yuqing Yang, Chin-Yew Lin, H. Vicky Zhao, Lili Qiu, Dongmei Zhang
- Venue / source: Findings of the Association for Computational Linguistics: ACL 2024, pages 963-981
- Published: arXiv submitted 2024-03-19, v2 revised 2024-08-12; ACL Findings 2024 publication in August 2024
- Citations snapshot: 29 citations
- Citation source: OpenAlex work W4402670850, `cited_by_count=29`, updated 2026-05-28 and captured 2026-05-31. Semantic Scholar API was also checked on 2026-05-31, but the `arXiv:2403.12968` record returned `citationCount=285` with unrelated extra authors, so I treat that record as noisy and did not use it as the snapshot.
- Code: https://github.com/microsoft/LLMLingua, reviewed at commit `e0e9d99beb94098bbd924aa53c2c112eac41c758`; project page https://llmlingua.com/llmlingua2.html
- Topic: context-control
- Reviewed at: 2026-05-31
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong context-control primitive for compressing long natural-language context with a cheap extractive classifier, but it should be adopted in Agentic Coding Lab only as a guarded compression layer with schema-aware forced retention, coding-specific regression tests, and explicit no-compress zones for code, diffs, exact failures, and user constraints.

## Problem

Long prompts improve LLM behavior in RAG, chain-of-thought, in-context learning, summarization, and long-document QA, but they increase inference cost, latency, context-window pressure, and sometimes degrade information perception. Earlier task-agnostic prompt compression methods, including LLMLingua and Selective-Context, usually remove tokens by estimating entropy or perplexity with a causal small language model. The paper argues that this is a weak proxy because entropy is not directly optimized for downstream prompt usefulness and causal models only see left context when scoring token importance.

LLMLingua-2 attacks a specific context-control problem: how to remove redundant prompt tokens without using the downstream task or query, while keeping the compressed prompt faithful to the original and cheap enough to run before a black-box target LLM. That is relevant to Agentic Coding Lab because coding agents accumulate large amounts of semi-redundant conversation, command output, documentation snippets, issue text, and search results. However, coding sessions also contain high-value exact strings, so the adoption question is not "can we compress?" but "which context regions are safe to compress, under which retention contract, and how do we catch regressions?"

## Method

LLMLingua-2 has three main stages.

First, it distills an extractive compression dataset from GPT-4. The authors use MeetingBank transcripts, split long transcripts into chunks of no more than 512 tokens ending at sentence boundaries, and prompt GPT-4-32k to compress each chunk by removing unimportant words only. The instruction explicitly forbids reordering, changing words, abbreviations, emojis, new words, or added symbols. The paper removes a fixed compression-ratio requirement because information density varies across documents and even across speakers in a transcript.

Second, it converts GPT-4 compressed text into token labels. Given original text and compressed text, the data annotation algorithm assigns each original word a preserve/discard label. It handles ambiguity, word variation, and limited reordering with a local bidirectional search and fuzzy/lemmatized matching. Two quality-control metrics filter low-quality samples: variation rate flags words in the compressed output that do not appear in the original, and alignment gap compares hitting rate against matching rate to detect poor alignment. The paper text says it filters the highest variation-rate samples and the highest alignment-gap samples; the released `filter.py` implementation uses 90th-percentile thresholds for both metrics.

Third, it trains a token-classification compressor. The main model uses `xlm-roberta-large`; the small model uses multilingual BERT. At inference time, the model predicts `p_preserve` for each token/word, retains the highest-probability words to satisfy a target rate or token budget, and preserves original word order. The official implementation exposes this through `PromptCompressor(..., use_llmlingua2=True)` and `compress_prompt_llmlingua2`, with practical controls such as `force_tokens`, `force_reserve_digit`, `chunk_end_tokens`, optional context-level filtering, and structured `<llmlingua>` segments that can disable compression or apply different rates per segment.

## Evidence

The strongest evidence is that a MeetingBank-trained extractive classifier generalizes across several non-meeting benchmarks while running faster than entropy-based baselines.

On MeetingBank, LLMLingua-2 reaches 86.92 QA EM with 970 tokens at 3.1x compression, close to the original prompt's 87.75 EM with 3,003 tokens and well above LLMLingua's 67.52 EM at 2.5x. On summarization it improves Rouge1 over the original prompt but trails the original on Rouge2/RougeL, which suggests compression can increase salience while still losing some phrasing/detail useful for summary overlap metrics.

On LongBench and ZeroSCROLLS with a 2,000-token constraint, LLMLingua-2 beats task-agnostic baselines: LongBench average 39.1 versus 34.6 for LLMLingua, and ZeroSCROLLS 33.4 versus 27.2. It does not beat the question-aware LongLLMLingua on LongBench, which is expected because query-aware compression can keep evidence for a known question. On GSM8K, LLMLingua-2 preserves nearly full-shot performance at high compression: 77.79 EM in the half-shot setting with 178 tokens and 14x compression, compared with 78.85 full-shot EM at 2,366 tokens. On BBH, it essentially matches full-shot in the 1-shot setting, but drops in the half-shot setting, showing that aggressive compression still has failure modes.

The Mistral-7B transfer result is practically interesting. LLMLingua-2 improves over the original prompt on MeetingBank QA and LongBench single-document QA with Mistral-7B, which the authors attribute to shorter, denser prompts helping a target model with weaker long-context handling. This is a useful clue for coding agents that route work to smaller/local models: compression can sometimes be an accuracy intervention, not only a cost intervention.

Latency evidence is strong for the compressor itself. On MeetingBank with a V100-32G GPU, LLMLingua-2 compression takes 0.5 seconds at 2x and 0.4 seconds at 3x or 5x, versus LLMLingua at 2.9, 2.1, and 1.5 seconds. End-to-end latency drops from 14.9 seconds without compression to 9.4, 7.5, and 5.2 seconds at 2x, 3x, and 5x. Appendix I reports 2.1 GB peak GPU memory for LLMLingua-2 compared with 16.6 GB for LLMLingua and 26.5 GB for Selective-Context. Training cost is non-trivial but bounded: about 23 hours for XLM-RoBERTa-large and 16 hours for multilingual BERT on the MeetingBank compression data.

Ablations support the main design choices. The paper's instruction-plus-chunking variant reports 2.6x compression, 2.2 variation rate, and 36.7 QA F1 in the LongBench single-document QA ablation. Removing chunk-wise compression raises compression to 21x but drops QA F1 to 27.9, indicating that overly aggressive compression is not a win. Alternative instructions reach very high compression ratios but much lower QA F1, supporting the decision to optimize for extractive fidelity rather than shortest possible text.

Implementation evidence matches the paper. The official repository includes the LLMLingua-2 runtime in `llmlingua/prompt_compressor.py`, token-classification dataset utilities, data collection scripts for GPT-4 compression, word-labeling and filtering scripts, model training scripts, evaluation scripts for MeetingBank, LongBench, ZeroSCROLLS, GSM8K, and BBH, a runnable LLMLingua-2 notebook, Hugging Face model cards for the XLM-RoBERTa and mBERT compressors, and the released `microsoft/MeetingBank-LLMCompressed` dataset with 5,169 rows.

## Limits

The paper is not a software-engineering agent paper. It evaluates meeting QA/summarization, long-document QA, synthetic tasks, code benchmark slices inside LongBench, math reasoning, and BBH, but it does not test patch generation, debugging loops, build/test output compression, retrieval over repository state, tool-call traces, or long-running agent memory.

Task-agnostic compression is a tradeoff. It is efficient because the same document can be compressed once and reused across queries, but it cannot know which details a future coding task will need. Query-aware methods outperform it on some retrieval-style settings, and coding agents often know the active objective, failing test, or file path. For those cases, task-aware or schema-aware compression should dominate blind prompt compression.

The training data is narrow. The released compression dataset is built from MeetingBank, a meeting-transcript domain. The authors show transfer, and adding 50k TriviaQA-wiki examples yields only modest gains, but coding context has different redundancy patterns: code punctuation, stack traces, file paths, JSON, diffs, shell commands, logs, semantic version strings, and user constraints. Dropping a "small" token in code can change behavior.

Faithfulness is extractive but not automatically safe. The method preserves word order and removes words, so it avoids hallucinating new content, but deletion can still corrupt meaning. Negation, conditionals, exact numbers, flags, line numbers, path separators, indentation, and punctuation can be critical. The implementation offers `force_tokens` and digit preservation, which are necessary but not sufficient for code or terminal output.

The data-labeling pipeline depends on GPT-4 outputs and heuristic alignment. GPT-4 is instructed not to change words, yet the paper and code both include variation and alignment filters because this instruction is imperfect. The code's filtering thresholds also appear to differ from the paper text for variation rate, which matters if someone tries to reproduce the training data exactly.

Operationally, the released library loads Hugging Face models and sets `trust_remote_code=True` by default when model config does not override it. That is not an acceptable default for an agent lab that may load arbitrary third-party compressors. Any adoption should pin known model IDs, disable remote code where possible, and treat model loading as a supply-chain boundary.

## Research Themes

- Token efficiency: High relevance. The paper directly targets 2x-5x prompt compression, reports 1.6x-2.9x end-to-end latency speedups, and uses smaller token-classification models to lower compressor overhead.
- Context control: High relevance. It is a reusable compression policy for active context, with chunking, token budgets, preserve probabilities, force tokens, and structured no-compress regions in the shipped library.
- Sub-agent / multi-agent: Low relevance. The compressor is a separate module from the target LLM, but the paper does not study multi-agent delegation or collaboration.
- Domain-specific workflow: Medium relevance. The method is task-agnostic, but the data-distillation pipeline can train domain-specific compressors. Agentic Coding Lab would need coding-domain compression labels and policies.
- Error prevention: Medium relevance. Extractive compression reduces hallucinated summaries, but the paper does not provide a failure-driven regression harness. For coding, deletion-induced errors need explicit tests.
- Self-learning / memory: Medium relevance. The method distills an offline compression model from GPT-4-generated examples; it is not online memory, but it suggests a path for learning compression rules from accumulated traces.
- Popular skills: Medium relevance. The structured compression and force-token controls map well to skill-like context contracts: "compress this region, preserve these tokens, never compress these fields."

## Key Ideas

- Treat prompt compression as token classification rather than generative summarization. This preserves original order and content while making compression fast and model-agnostic with respect to the target LLM.
- Distill compression targets from a stronger model, then train a cheaper model to run the compression policy.
- Use extractive instructions with hard constraints, not generic "summarize" prompts, when faithfulness matters.
- Chunk long context before distillation and inference. Very long inputs push GPT-4 and classifiers toward over-aggressive compression.
- Filter training data with explicit faithfulness and alignment metrics. Compression examples should be rejected when the compressed text adds words or cannot be aligned to the original.
- Allow domain users to force tokens and disable compression by segment. The official implementation's `force_tokens`, `force_reserve_digit`, and structured `<llmlingua, compress=False>` controls are more important for coding than the headline compression ratio.
- Evaluate compression by downstream task performance and latency, not by token count alone.

## Ideas To Steal

- Build a coding-context compression contract around preservation classes. Always preserve file paths, exact commands, exit codes, failing assertions, stack frames, line numbers, version strings, env vars, user constraints, open questions, and destructive-operation approvals.
- Add no-compress spans to Agentic Coding Lab artifacts. For example, wrap diffs, code snippets, test failures, and user requirements in explicit regions that compressors must copy or bypass.
- Use a two-tier policy: cheap extractive compression for prose/log narration and structured selection for critical fields. Natural-language chat can be compressed aggressively; code, shell, JSON, and task state need schema-aware preservation.
- Expose `force_tokens` equivalents in any local harness. For coding, the forced set should include path separators, newlines, punctuation used in code, common shell operators, brackets, quotes, digits, and project-specific sentinels.
- Train or evaluate on coding traces before adoption. A MeetingBank compressor is useful as a baseline, not as the final policy. Build a dataset from successful/failed agent sessions and label what must survive compaction.
- Use returned word labels as an audit artifact. The library can return preserved/discarded word labels; Agentic Coding Lab could store those labels with compressed traces to debug why a later agent step failed.
- Use task-agnostic compression for reusable documents and task-aware compression for active work. Documentation pages and search snippets can be compressed once; failing test context should be compressed relative to the current bug.
- Treat compression ratio as a dial with risk classes. Low-risk background material can target 3x-5x; current edits, test failures, and user constraints should be 1x or lightly compressed until verified.

## Do Not Copy

- Do not compress code, diffs, JSON, stack traces, or shell output as ordinary prose. Deleting punctuation or tiny tokens can change semantics.
- Do not use "faithful" to mean "safe." Extractive deletion can still remove negation, conditions, flags, or exception details.
- Do not adopt the MeetingBank-trained model as a global coding memory compressor without a coding benchmark.
- Do not optimize for the highest compression ratio. The ablations show that aggressive compression can look efficient while harming QA.
- Do not rely on Semantic Scholar metadata blindly for citation snapshots here; the queried record looked merged/noisy.
- Do not inherit `trust_remote_code=True` as a default in agent infrastructure.
- Do not replace retrieval, indexing, or structured memory with compression. LLMLingua-2 shortens selected context; it does not decide what should enter context in the first place.
- Do not evaluate with summary overlap or token counts only. Coding adoption needs task-level regressions: can the agent still fix the bug, rerun the right command, and avoid repeating failed hypotheses?

## Fit For Agentic Coding Lab

LLMLingua-2 is in-scope because it gives a concrete, shipped, low-latency approach to compressing prompt context while preserving source faithfulness. The most valuable transfer is not "use this model everywhere"; it is the design pattern of extractive, auditable, budgeted compression with forced retention controls.

For Agentic Coding Lab, the practical artifact should be a context-compression layer with three modes:

1. `copy`: exact preservation for user instructions, active plan state, diffs, code, command lines, error snippets, and approvals.
2. `extract`: LLMLingua-2-style token selection for prose-heavy logs, issue discussions, docs, and search results.
3. `summarize`: higher-level synthesis only after exact evidence has been stored elsewhere and linked by provenance.

This paper supports adding compression as a measured subsystem with metadata: compressor model, commit/version, input token count, output token count, preserved fields, forced tokens, no-compress regions, and downstream success/failure. The lab should then maintain regression traces where compressed context caused a different or worse coding outcome. Those traces are the right source for future coding-specific distillation.

## Related Repositories

- https://github.com/microsoft/LLMLingua - Official MIT-licensed implementation for LLMLingua, LongLLMLingua, LLMLingua-2, and later related work. The reviewed `main` commit was `e0e9d99beb94098bbd924aa53c2c112eac41c758`. The GitHub page showed about 6.2k stars when reviewed on 2026-05-31. Relevant files include `llmlingua/prompt_compressor.py`, `llmlingua/utils.py`, `experiments/llmlingua2`, and `examples/LLMLingua2.ipynb`.
- https://huggingface.co/datasets/microsoft/MeetingBank-LLMCompressed - Released GPT-4 compressed MeetingBank dataset with 5,169 rows, used to construct training data for LLMLingua-2.
- https://huggingface.co/microsoft/llmlingua-2-xlm-roberta-large-meetingbank - Released XLM-RoBERTa-large token-classification compressor.
- https://huggingface.co/microsoft/llmlingua-2-bert-base-multilingual-cased-meetingbank - Released smaller multilingual BERT compressor.
- https://huggingface.co/spaces/microsoft/LLMLingua-2 - Public demo linked from the project page and repository.

## Reviewed Sources

- arXiv abstract page: https://arxiv.org/abs/2403.12968
- arXiv/ACL PDF full text: https://aclanthology.org/2024.findings-acl.57.pdf
- ACL Anthology record and BibTeX: https://aclanthology.org/2024.findings-acl.57/
- LLMLingua-2 project page: https://llmlingua.com/llmlingua2.html
- Official code repository: https://github.com/microsoft/LLMLingua
- Official repository files reviewed at commit `e0e9d99beb94098bbd924aa53c2c112eac41c758`: `README.md`, `llmlingua/prompt_compressor.py`, `llmlingua/utils.py`, `experiments/llmlingua2/README.md`, `experiments/llmlingua2/data_collection/README.md`, `experiments/llmlingua2/data_collection/compression_instructions.json`, `experiments/llmlingua2/data_collection/label_word.py`, `experiments/llmlingua2/data_collection/filter.py`, `experiments/llmlingua2/model_training/train_roberta.py`, `experiments/llmlingua2/evaluation/compress.py`, `experiments/llmlingua2/evaluation/scripts/compress.sh`, and `examples/LLMLingua2.ipynb`.
- Hugging Face dataset: https://huggingface.co/datasets/microsoft/MeetingBank-LLMCompressed
- Hugging Face XLM-RoBERTa compressor: https://huggingface.co/microsoft/llmlingua-2-xlm-roberta-large-meetingbank
- Hugging Face mBERT compressor: https://huggingface.co/microsoft/llmlingua-2-bert-base-multilingual-cased-meetingbank
- Hugging Face demo: https://huggingface.co/spaces/microsoft/LLMLingua-2
- OpenAlex citation/API record: https://api.openalex.org/works/W4402670850
- Semantic Scholar API check: https://api.semanticscholar.org/graph/v1/paper/arXiv:2403.12968?fields=title,authors,year,publicationDate,venue,citationCount,externalIds,url,openAccessPdf
