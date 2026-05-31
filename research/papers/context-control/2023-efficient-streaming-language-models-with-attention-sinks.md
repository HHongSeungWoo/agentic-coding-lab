# Efficient Streaming Language Models with Attention Sinks

- URL: https://arxiv.org/abs/2309.17453
- Cite as: arXiv:2309.17453
- DOI: 10.48550/arXiv.2309.17453
- Authors: Guangxuan Xiao, Yuandong Tian, Beidi Chen, Song Han, Mike Lewis
- Venue / source: ICLR 2024 conference paper; arXiv v4.
- Published: arXiv submitted 2023-09-29, OpenReview record published 2024-01-16, arXiv v4 revised 2024-04-07.
- Citations snapshot: 32 citations
- Citation source: OpenAlex work W4387294617, `cited_by_count=32`, captured 2026-05-31. Caveat: the OpenAlex record matched the title/DOI/arXiv ID but had contaminated author/location metadata; Semantic Scholar Graph API for `arXiv:2309.17453` returned HTTP 429 during review, so no Semantic Scholar count was verified.
- Code: https://github.com/mit-han-lab/streaming-llm
- Topic: context-control
- Reviewed at: 2026-05-31
- Status: reviewed
- Scope fit: conditional
- Verdict: Important serving-side context-control paper for bounded KV-cache streaming, but only conditional fit for Agentic Coding Lab because it preserves fluency over recent context rather than adding long-term memory, retrieval, or whole-session task state.

## Problem

LLMs deployed in long-running dialogue or streaming generation face two practical failures. First, keeping every prior key/value state makes decoding memory and latency grow with the stream. Second, models trained with a finite attention window degrade when asked to generate far beyond that window.

The obvious fix, sliding-window KV caching, keeps memory constant by retaining only recent tokens. The paper shows that this collapses once the first tokens are evicted, even when those tokens are not semantically important. Sliding-window recomputation avoids the quality collapse by rebuilding recent KVs every step, but it is too slow for continuous serving.

For Agentic Coding Lab, this is relevant as a low-level analogy for context budgets. Agents need bounded active context, but naive FIFO removal can delete structurally important anchors. The paper is not about coding-agent memory, but it gives a concrete mechanism for separating "stability anchors" from "recent working context."

## Method

The core observation is the attention sink phenomenon: decoder-only Transformers often assign high attention to initial tokens across most layers and heads. The authors argue this is partly a SoftMax artifact. If a query has no strong useful match, attention still has to sum to one, so the model learns to dump excess attention into globally visible early tokens. Because early tokens are visible to nearly every later token during autoregressive training, they become natural sinks.

StreamingLLM keeps two KV-cache regions:

- A small fixed prefix of initial tokens, usually four tokens, as attention sinks.
- A rolling window of the most recent tokens for local language modeling.

This avoids fine-tuning existing models. Instead of caching all history or evicting the initial tokens, it evicts the middle. For relative position encodings, the paper also reassigns positions within the current cache rather than preserving absolute positions from the original stream. In the official implementation, `StartRecentKVCache` concatenates the first `start_size` KVs with the latest `recent_size` KVs, while model-specific position-shift patches handle Llama, Falcon, and GPT-NeoX attention. The chat example calls `evict_for_space` before each new prompt to make room for the prompt plus generated tokens.

The paper also studies training future models with a dedicated learnable sink token prepended to every training sample. In 160M-parameter Pythia-style pre-training experiments, a single sink token becomes the attention offload point and reduces reliance on multiple arbitrary initial content tokens.

## Evidence

The most decisive evidence is the window-attention failure analysis. On the first PG19 book with Llama-2-13B, a 0+1024 window had perplexity 5158.07, while keeping 4 initial tokens plus 1020 recent tokens restored perplexity to 5.40. Replacing the original initial tokens with four newline tokens still achieved 5.60, supporting the claim that absolute early position matters more than token semantics.

The sink-count ablation shows that four initial tokens are usually enough. For Llama-2-7B on 400K PG19 tokens, 0+4096 produced perplexity 3359.95; 1+4095 got 11.88; 2+4094 got 10.51; 4+4092 got 9.59; 8+4088 only slightly improved to 9.54. Falcon, MPT, and Pythia also recovered with small prefixes.

Long-stream language-modeling tests show stable perplexity across Llama-2, MPT, Falcon, and Pythia model sizes over 4 million PG19 tokens. The paper reports that StreamingLLM matches sliding-window recomputation quality while avoiding its quadratic recomputation cost.

Instruction-tuned streaming QA is more agent-relevant. On concatenated ARC questions with Llama-2 chat models, dense attention ran out of memory, window attention collapsed near zero accuracy, and StreamingLLM stayed close to one-shot accuracy. For Llama-2-7B-Chat, one-shot scored 71.25 on ARC-Easy and 53.16 on ARC-Challenge; StreamingLLM scored 71.34 and 55.03.

Efficiency results compare against sliding-window recomputation on A6000 GPUs. StreamingLLM reports up to 22.2x per-token decoding speedup with similar memory footprint.

The paper's own appendices are important negative evidence. On LongBench, a 4+3496 StreamingLLM cache underperformed the default truncation baseline on QA and summarization because it lost important beginning information. A 1750+1750 cache restored truncation-like performance, confirming that the method only works when needed information remains in cache.

## Limits

StreamingLLM does not extend the true context window. The official README and paper both emphasize that the model only recognizes the retained sink tokens and recent tokens. Intermediate history is discarded. This makes the method unsuitable for long-document QA, full-session summarization, or coding tasks where an early design constraint must still be available hours later.

The "infinite context" phrasing is easy to overread. It means stable continuous generation with bounded KV cache, not arbitrary recall over an infinite history.

The method is mostly serving/inference infrastructure. Agentic Coding Lab cannot directly copy it into prompt assembly unless it has control over KV-cache eviction or model serving internals. For API-based agents, the transferable idea is policy design: preserve small structural anchors and recent operational context, while moving durable facts into explicit memory or retrieval.

Evidence is strongest for language-model perplexity and recent-answer streaming QA. It is not evaluated on software-engineering repair loops, tool-use trajectories, or long-horizon coding tasks. The paper also shows that increasing cache size does not monotonically improve perplexity, reinforcing the broader "long context is not automatically used well" finding.

## Research Themes

- Token efficiency: High relevance. It keeps KV cache bounded and reports large decoding speedups versus recomputation.
- Context control: High relevance at the serving layer. It defines a clear eviction policy: preserve sink prefix plus recent window, evict middle history.
- Sub-agent / multi-agent: Low relevance. There is no multi-agent orchestration or delegation model.
- Domain-specific workflow: Low to medium relevance. The method is general inference machinery, but the StreamEval setup models recent-information workflows.
- Error prevention: Medium relevance. It identifies a specific failure mode of FIFO/window eviction and validates an anchor-preserving alternative.
- Self-learning / memory: Low relevance. Sink-token pre-training changes model behavior, but there is no agent memory store or online learning loop.
- Popular skills: Low relevance. Useful as a context-control principle, not as a skill or prompt-pack pattern.

## Key Ideas

- FIFO context eviction can be structurally wrong even when the removed tokens look semantically unimportant.
- Some tokens serve as attention anchors rather than content carriers.
- A bounded active context can be split into stable anchors and recent working state.
- The right evaluation for streaming context control is not "can it ingest a long prompt" but "does quality remain stable after many evictions."
- Long-context serving and long-term memory are different problems.
- Context-extension methods can combine with StreamingLLM, but they only increase the size of the recent region available to the model.

## Ideas To Steal

- Add an "anchor plus recency" pattern to Agentic Coding Lab context policy. Keep a compact immutable header with goal, user constraints, repo identity, safety decisions, and current plan status; rotate recent logs aggressively below it.
- Make compaction tests check for FIFO-anchor loss. A regression fixture should fail if summaries drop early constraints simply because they are old.
- Separate stability anchors from memory. Anchors keep the current reasoning frame stable; durable memory/retrieval stores facts that must survive after active context eviction.
- For local models or owned serving stacks, experiment with sink-aware KV eviction for long-running coding assistants that stream tool output and chat turns continuously.
- Track "middle eviction" explicitly in context summaries. When old material is removed, record whether its durable facts were promoted to memory, indexed retrieval, or deliberately dropped.
- Use recent-context benchmarks for coding agents. Some tasks should ask about facts from the last N tool calls, not the whole transcript, to evaluate whether active working context survives compaction.
- Treat "larger context" claims skeptically. Measure whether the model uses the retained content and whether required facts are still in the active/cacheable region.

## Do Not Copy

- Do not market bounded recent-context fluency as long-term memory.
- Do not use a tiny sink prefix for tasks that require early prompt facts, long documents, or repository-wide state. The LongBench appendix shows this can underperform ordinary truncation.
- Do not assume more retained tokens always improves behavior; the cache-size ablation is mixed.
- Do not apply the paper's exact four-token policy to prompt-level agent context without validation. The number is a model-serving KV-cache finding, not a universal prompt-layout rule.
- Do not let sink/anchor tokens carry semantic facts unless those facts are separately represented. Attention sinks are stability points, not reliable memory.
- Do not depend on this method when using black-box APIs that do not expose KV-cache eviction.

## Fit For Agentic Coding Lab

Conditional fit. The paper belongs in context-control because it is a crisp example of bounded active-context management, and because it explains why naive sliding windows can fail catastrophically. Its direct implementation value depends on whether Agentic Coding Lab controls model inference. If the lab is mostly API-agent workflows, the best transfer is conceptual rather than mechanical.

The practical takeaway is to design agent context as layers:

- Stable anchor layer: task objective, user constraints, current safety boundaries, ownership rules, and active plan.
- Recent working layer: last edits, command outputs, test failures, and unresolved hypotheses.
- Durable memory/retrieval layer: facts that must survive after active context eviction.

StreamingLLM supports the argument that active context should not be managed by age alone. But it also warns against pretending that bounded active context can replace memory, retrieval, or explicit state artifacts.

## Related Repositories

- https://github.com/mit-han-lab/streaming-llm - Official MIT-licensed implementation. Reviewed commit `2e5042606d69933d88fbf909bd77907456b9b4dd` from 2024-07-11. GitHub REST API showed 7,232 stars and 399 forks when captured on 2026-05-31. The repo includes core `StartRecentKVCache`, model-specific position-shift patches, long-perplexity evaluation, a streaming Llama chatbot example, and MT-Bench prompt data. Its README says the StreamEval dataset/evaluation code was still unreleased.
- https://github.com/tomaarsen/attention_sinks - Third-party implementation linked from the official README for enabling attention sinks on more Hugging Face LLMs; not deeply reviewed here.
- https://github.com/NVIDIA/TensorRT-LLM - The project page and README say StreamingLLM was integrated into NVIDIA TensorRT-LLM; not deeply reviewed here.
- https://github.com/huggingface/transformers/pull/26681 - Hugging Face Transformers integration PR linked by the official README; not deeply reviewed here.

## Reviewed Sources

- arXiv abstract page: https://arxiv.org/abs/2309.17453
- arXiv PDF v4: https://arxiv.org/pdf/2309.17453
- ar5iv HTML full text: https://ar5iv.labs.arxiv.org/html/2309.17453v4
- ICLR 2024 proceedings page: https://proceedings.iclr.cc/paper_files/paper/2024/hash/5e5fd18f863cbe6d8ae392a93fd271c9-Abstract-Conference.html
- OpenReview ICLR 2024 record: https://openreview.net/forum?id=NG7sS51zVF
- Project page: https://hanlab.mit.edu/projects/streamingllm
- Hugging Face paper page: https://huggingface.co/papers/2309.17453
- OpenAlex API work record: https://api.openalex.org/works/W4387294617
- Semantic Scholar Graph API attempted: https://api.semanticscholar.org/graph/v1/paper/arXiv:2309.17453?fields=title,authors,year,venue,publicationDate,citationCount,externalIds,url,openAccessPdf
- Official code repository: https://github.com/mit-han-lab/streaming-llm
- GitHub REST API repository record: https://api.github.com/repos/mit-han-lab/streaming-llm
- Implementation files reviewed from the official repository: `README.md`, `streaming_llm/kv_cache.py`, `streaming_llm/enable_streaming_llm.py`, `streaming_llm/pos_shift/modify_llama.py`, `examples/eval_long_ppl.py`, `examples/run_streaming_llama.py`, and `streaming_llm/utils.py`.
