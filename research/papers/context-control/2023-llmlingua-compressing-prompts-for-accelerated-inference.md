# LLMLingua: Compressing Prompts for Accelerated Inference of Large Language Models

- URL: https://arxiv.org/abs/2310.05736
- Cite as: Jiang et al., EMNLP 2023; arXiv:2310.05736
- DOI: 10.18653/v1/2023.emnlp-main.825; arXiv DOI 10.48550/arXiv.2310.05736
- Authors: Huiqiang Jiang, Qianhui Wu, Chin-Yew Lin, Yuqing Yang, Lili Qiu
- Venue / source: Proceedings of the 2023 Conference on Empirical Methods in Natural Language Processing, pages 13358-13376, Singapore, Association for Computational Linguistics
- Published: arXiv submitted 2023-10-09, v2 revised 2023-12-06; ACL Anthology record published December 2023
- Citations snapshot: 96 citations
- Citation source: OpenAlex work W4389519226, `cited_by_count=96`, captured 2026-05-31; Semantic Scholar Graph API returned HTTP 429 during review, so OpenAlex is the verified current source
- Code: https://github.com/microsoft/LLMLingua
- Topic: context-control
- Reviewed at: 2026-05-31
- Status: reviewed
- Scope fit: in-scope
- Verdict: Foundational prompt-compression work for context-control: worth stealing as a measured, structure-aware compression policy, but unsafe to apply blindly to coding-agent state because token-level deletion can corrupt exact commands, code, numbers, paths, and failure evidence.

## Problem

LLMLingua targets the cost and latency problem created by long prompts. Chain-of-thought examples, in-context demonstrations, retrieved documents, and historical conversations can push prompts into thousands or tens of thousands of tokens. For API-only target models, parameter quantization or model-side acceleration is unavailable, so the paper compresses the prompt before sending it to the black-box LLM.

The paper's core framing is useful for Agentic Coding Lab: natural-language context is redundant, but not all context regions have the same failure cost. Instructions and questions are high sensitivity; demonstrations and context documents are lower sensitivity and can often be filtered more aggressively. Coding-agent sessions have the same shape, except the sensitive regions are broader: user constraints, exact file paths, shell commands, failing assertions, stack traces, diffs, and unresolved decisions often need lossless or near-lossless treatment.

## Method

LLMLingua is a coarse-to-fine prompt compression pipeline run by a smaller language model before the target LLM call.

First, a budget controller allocates different compression rates across prompt components. Instructions and questions receive more budget, while demonstrations are treated as more redundant. Under high compression, it performs demonstration-level or sentence-level filtering before token-level deletion so the remaining prompt keeps some linguistic and reasoning integrity. Demonstrations are ranked by perplexity from the small model, with higher-perplexity examples treated as more information-rich.

Second, iterative token-level prompt compression divides the selected prompt into segments. The small model scores token perplexity, keeps higher-perplexity tokens, and feeds the already-compressed previous segment into the next segment's scoring step. This is meant to reduce the independence error of scoring every token against the uncompressed prefix.

Third, distribution alignment instruction-tunes the small model on LLM-generated instruction data so its token distribution better approximates the black-box target model. The paper evaluates Alpaca-7B and a GPT2-Alpaca variant as compressors for GPT-3.5-Turbo-0301 and Claude-v1.3 targets.

The official repository implements the approach as `llmlingua.PromptCompressor`. The current code exposes context-level, sentence-level, and token-level filters; structured prompt compression with `<llmlingua>` tags; JSON/key-value compression; force-preserve options for tokens and digits; context reordering and question-aware ranking from LongLLMLingua; and LLMLingua-2 token-classification backends. For this note, the relevant evidence is the original LLMLingua path, while the later repository features show how the project evolved toward more controllable compression surfaces.

## Evidence

The paper evaluates four settings: GSM8K and BBH for reasoning and in-context learning, ShareGPT for conversation continuation, and Arxiv-March23 for summarization. The target models are GPT-3.5-Turbo-0301 and, for a smaller generalization check, Claude-v1.3. Metrics are exact match for GSM8K/BBH and BLEU, ROUGE, and BERTScore for ShareGPT/Arxiv-March23.

Headline results are strongest on GSM8K. With a one-shot constraint, LLMLingua reports 79.08 EM using 446 tokens, roughly 5x compression, slightly above the full-shot 78.85 EM baseline with 2,366 tokens. At the quarter-shot constraint, it reports 77.33 EM with 117 tokens, roughly 20x compression. On BBH, LLMLingua is near full-shot under the one-shot constraint, 70.11 EM versus 70.07, but drops to 56.85 EM at 7x compression, showing that harder symbolic reasoning is more sensitive.

For contextual tasks, LLMLingua beats sentence selection and Selective-Context under the paper's token budgets. On Arxiv-March23, it reports stronger ROUGE/BERTScore at both 350-token and 175-token constraints, reaching 9x compression in the stricter condition. On ShareGPT, it improves BLEU/ROUGE/BERTScore while reaching about 3.3x compression in the stricter condition.

Ablations support the design. Removing iterative token-level compression drops GSM8K one-shot EM from 79.08 to 72.93. Removing the budget controller drops it to 73.62. Random selection in the budget controller drops it to 72.78. Removing distribution alignment has a smaller effect, 78.62 EM, but still shows a measurable benefit. A stop-word removal baseline keeps far more tokens and performs worse, which is a useful warning against naive syntactic compression.

The latency and cost analysis is directionally practical but hardware/model-specific. On GSM8K with a V100-32GB, the reported end-to-end speedup ranges from 1.7x at 2x compression to 5.7x at 10x compression, with LLMLingua overhead between 0.8s and 0.2s in the reported table. Estimated GPT-3.5-Turbo input/generation costs fall across all four datasets, but those numbers reflect 2023 pricing and model behavior.

Qualitative cases show both promise and risk. GPT-4 can often reconstruct the intended reasoning from heavily compressed prompts, but the paper also reports that recovery quality depends on compression ratio and small-model quality. Some compressed examples are hard for humans to read and contain malformed words or distorted numbers, which matters for coding-agent auditability.

## Limits

The method is lossy. It optimizes downstream task accuracy, not faithful reconstruction of every fact. That is acceptable for some summarization or few-shot prompting, but dangerous for coding-agent context where a single path, flag, version, line number, or test assertion may be decisive.

High compression breaks down. The authors explicitly report notable performance drops around 25x-30x on GSM8K, and they state that the upper compression limit depends on prompt length, task type, and sentence count. Agent workflows should treat compression ratio as a policy parameter validated by regression tests, not a target to maximize.

Small-model mismatch remains a risk. Distribution alignment helps, but GPT2-Alpaca performs below Alpaca-7B, and the compressor's tokenizer can underestimate or misalign the target model's token length. Modern target models and tokenizers have changed since GPT-3.5-Turbo-0301 and Claude-v1.3, so current deployments need fresh calibration.

The evaluation is not software-engineering-agent specific. It includes reasoning, conversation, and summarization, with a few project-page examples for code completion using later LongLLMLingua. It does not test multi-turn coding loops, tool outputs, diffs, build logs, or permission/sandbox state.

The compressed text can become operationally opaque. A human reviewer may not be able to audit whether a compressed prompt preserved all safety constraints or exact evidence. For Agentic Coding Lab, that argues for structured retained fields and compression provenance rather than replacing working memory with unreadable token fragments.

## Research Themes

- Token efficiency: High relevance. The paper directly reduces prompt tokens and reports speed/cost savings, with the strongest evidence in prompt-heavy reasoning and summarization.
- Context control: High relevance. It treats prompt regions as budgeted components and introduces context-level, sentence-level, and token-level controls.
- Sub-agent / multi-agent: Low relevance. The compressor is a separate model/module, but the work is not about multi-agent coordination or delegation.
- Domain-specific workflow: Medium relevance. Component-sensitive budgets transfer well, but coding requires domain-specific protected spans and schema-aware policies not present in the paper.
- Error prevention: Medium relevance. Ablations and qualitative cases expose when compression loses reasoning structure, but there is no agent safety harness or failure-recovery loop.
- Self-learning / memory: Low to medium relevance. Distribution alignment is an offline training step; the method does not provide persistent memory or autonomous update policies.
- Popular skills: Medium relevance. The practical artifact resembles a reusable "compress context" skill with progressive disclosure, force-preserve controls, and benchmarked thresholds.

## Key Ideas

- Allocate compression budgets by prompt role. Instructions and questions deserve more protection than demonstrations or retrieved context.
- Use coarse filtering before token pruning. Dropping whole demonstrations or sentences can preserve semantic integrity better than immediately deleting tokens everywhere.
- Rank retained content by model surprise. Higher-perplexity tokens or demonstrations are treated as more information-bearing.
- Make token compression iterative. Re-score later segments against the already-compressed prefix so token dependencies are less distorted.
- Align the compressor to the target model's distribution when possible. A small model's importance estimates are only a proxy.
- Evaluate compression on task success and generated output length, not just input token count.
- Preserve controllability in the API. The official implementation's later structured tags, context filters, force tokens, and digit preservation are more useful for agent systems than a single global compression ratio.

## Ideas To Steal

- Build a context-compression contract for coding agents with protected regions. Never token-prune user constraints, active plan, file paths, exact commands, failing test names, stack traces, line numbers, version numbers, secrets/security decisions, or destructive-operation approvals.
- Split context into sensitivity classes before compression: immutable user instructions, current task state, recent edits, command/test evidence, retrieved docs, historical discussion, and low-value chatter. Assign each class a default budget and allowed compression method.
- Use a two-stage policy. First select or summarize whole context blocks; only apply token-level compression to low-risk prose or redundant documentation blocks.
- Add force-preserve patterns inspired by the repo's API: newlines, punctuation used in code, digits, path separators, quoted strings, flags beginning with `-`, environment variable names, issue IDs, and error codes.
- Store compression metadata with every compacted artifact: source block IDs, original token count, compressed token count, compressor version, protected spans, dropped sections, and downstream verification result.
- Calibrate compression thresholds with agentic coding regressions. Use traces where full context succeeds and compressed context fails, then add protected-field rules rather than raising compression globally.
- Prefer readable summaries for high-risk state. LLMLingua-style token fragments may be model-readable, but Agentic Coding Lab needs human-auditable state at compaction boundaries.

## Do Not Copy

- Do not apply 10x-20x token pruning to code, diffs, stack traces, shell output, JSON, YAML, or tables without a parser and protected-field rules.
- Do not assume human-unreadable compressed prompts are acceptable in a collaborative coding agent. They make review, debugging, and safety audits harder.
- Do not optimize only input token count. Compressor runtime, extra model calls, cache effects, and shorter or worse generations all matter.
- Do not trust perplexity as a universal importance signal. Rare tokens can be important, but common-looking tokens such as `not`, `rm`, `--force`, `0`, or a closing brace can be critical.
- Do not use paper-era pricing, GPT-3.5-Turbo behavior, or Claude-v1.3 results as current production evidence.
- Do not rely on distribution alignment unless the target model family and tokenizer are known and periodically revalidated.
- Do not merge this with memory compaction without provenance. Long-lived agent memory needs exact source links and recoverability, not only compressed text.

## Fit For Agentic Coding Lab

LLMLingua is in-scope because it is one of the field-defining prompt-compression papers and directly informs context-window control. The best transfer is not the exact token-pruning algorithm; it is the design discipline of treating prompt regions differently, measuring compression against downstream task quality, and exposing explicit compression budgets.

For Agentic Coding Lab, the practical pattern should be "bounded lossy compression behind a protected-state schema." Use LLMLingua-style compression for low-risk prose, old discussion, duplicate docs, and retrieved background. Use lossless or parser-aware compaction for code, commands, test output, file ownership, user instructions, and safety decisions. The agent should know which fields are compressed, which are verbatim, and which were dropped.

The paper also supports a research harness: replay coding sessions with full context and compressed context, compare task success and error types, then refine the compression contract. A compression policy should graduate only after it preserves edit correctness, test recovery, and user constraint compliance across those traces.

## Related Repositories

- https://github.com/microsoft/LLMLingua - Official MIT-licensed implementation, reviewed locally at commit `e0e9d99beb94098bbd924aa53c2c112eac41c758`. It includes `llmlingua/prompt_compressor.py`, docs, examples for RAG/CoT/code/meetings, and tests for LLMLingua, LongLLMLingua, and LLMLingua-2 behavior.
- https://llmlingua.com - Official project page for the LLMLingua series, including LLMLingua, LongLLMLingua, LLMLingua-2, demos, integrations, and applied examples.
- LangChain and LlamaIndex integrations are linked from the official README and documentation, showing adoption as retrieval/context compression components rather than standalone agents.

## Reviewed Sources

- arXiv abstract page: https://arxiv.org/abs/2310.05736
- arXiv HTML/PDF v2: https://ar5iv.labs.arxiv.org/html/2310.05736v2 and https://arxiv.org/pdf/2310.05736
- ACL Anthology record and PDF: https://aclanthology.org/2023.emnlp-main.825/ and https://aclanthology.org/2023.emnlp-main.825.pdf
- OpenAlex API work record: https://api.openalex.org/works/W4389519226
- Semantic Scholar Graph API lookup attempted for `arXiv:2310.05736` on 2026-05-31; API returned HTTP 429 and was not used for the citation count.
- Official project page: https://llmlingua.com
- Official code repository: https://github.com/microsoft/LLMLingua
- Implementation/docs reviewed from the official repository clone: `README.md`, `DOCUMENT.md`, `llmlingua/prompt_compressor.py`, `tests/test_llmlingua.py`, and the examples index in `examples/`.
