# LongLLMLingua: Accelerating and Enhancing LLMs in Long Context Scenarios via Prompt Compression

- URL: https://arxiv.org/abs/2310.06839
- Cite as: arXiv:2310.06839; ACL Anthology ID `2024.acl-long.91`
- DOI: 10.18653/v1/2024.acl-long.91; arXiv DOI 10.48550/arXiv.2310.06839
- Authors: Huiqiang Jiang, Qianhui Wu, Xufang Luo, Dongsheng Li, Chin-Yew Lin, Yuqing Yang, Lili Qiu
- Venue / source: Proceedings of the 62nd Annual Meeting of the Association for Computational Linguistics, Volume 1: Long Papers, ACL 2024.
- Published: arXiv submitted 2023-10-10, v2 revised 2024-08-12; ACL Anthology publication August 2024, pages 1658-1677.
- Citations snapshot: 63 citations
- Citation source: OpenAlex work W4402671835, `cited_by_count=63`, API `updated_date=2026-05-24`, captured 2026-05-31. Semantic Scholar Graph API lookup for `arXiv:2310.06839` returned HTTP 429 on 2026-05-31, so no current Semantic Scholar count was verified.
- Code: https://github.com/microsoft/LLMLingua
- Topic: context-control
- Reviewed at: 2026-05-31
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong context-control pattern source for query-aware prompt compression and evidence placement, but not a drop-in coding-agent memory system because it is lossy, per-question, compressor-heavy, and evaluated mostly on QA/summarization/code-completion benchmarks rather than live software-engineering repair loops.

## Problem

Long-context prompts create three coupled failures: they cost more to run, they slow inference, and they can reduce answer quality because useful information becomes sparse or lands in weak prompt positions. The paper explicitly targets the "lost in the middle" behavior: relevant evidence placed in the middle of a long prompt is less likely to be used than evidence near the front or back.

This is directly relevant to Agentic Coding Lab. Long coding sessions accumulate user constraints, file paths, diffs, command outputs, stack traces, search results, decisions, and obsolete hypotheses. A generic summary or FIFO truncation can remove the one fact needed for the next action, while leaving noisy logs that distract the model. LongLLMLingua asks a narrower question: can a smaller model compress and reorder context so the downstream LLM sees a denser, better-positioned subset of task-relevant information?

## Method

LongLLMLingua extends LLMLingua from generic prompt compression to question-aware long-context compression. It keeps the target LLM unchanged and uses a smaller language model as the compressor.

The method has four main pieces:

1. Question-aware coarse-grained compression ranks each document or context block by how well it supports the question. Instead of scoring the document alone, it estimates the question likelihood conditioned on the document plus a restrictive statement: "We can get the answer to this question in the given documents." This is meant to reduce hallucinated relevance from the compressor.
2. Question-aware fine-grained compression scores tokens by contrastive perplexity: the shift between token perplexity without the question and token perplexity with the question. Tokens whose probability changes most under the question are treated as more likely to be useful evidence.
3. Document reordering moves high-ranked context chunks into positions the downstream LLM uses better, reducing lost-in-the-middle failures after compression.
4. Dynamic compression ratios allocate more token budget to more relevant chunks and less to lower-ranked chunks. A post-compression subsequence recovery step maps generated response fragments back to spans in the original prompt to repair entity/token corruption caused by lossy token deletion.

The official implementation matches those concepts. `PromptCompressor.compress_prompt` exposes `condition_in_question`, `reorder_context`, `dynamic_context_compression_ratio`, `condition_compare`, `context_budget`, and `rank_method="longllmlingua"`. `control_context_budget` ranks and selects context chunks, `get_rank_results` implements the LongLLMLingua ranking score, `iterative_compress_prompt` handles token-level compression with optional condition comparison, and `recover` attempts subsequence-based response repair. The repo documentation and notebooks show RAG, online meeting, LlamaIndex, and code-completion examples using those parameters.

## Evidence

The paper evaluates NaturalQuestions multi-document QA, LongBench, ZeroSCROLLS, MuSiQue, and LooGLE with GPT-3.5-Turbo, plus LongBench with LongChat-13B. These cover multi-document QA, single-document QA, summarization, few-shot learning, synthetic tasks, multi-hop QA, long-dependency QA, and code completion.

Key reported results:

- NaturalQuestions, 4x constraint: LongLLMLingua used 748 tokens versus 2,946 for the original prompt and scored 75.5 in the reordered setting. At the 10th evidence position it scored 71.2 versus 54.1 for the original prompt.
- LongBench with GPT-3.5-Turbo, 2,000-token constraint: LongLLMLingua averaged 48.3 with 1,822 tokens and 2.6x latency speedup, versus original prompt average 44.0 with 10,295 tokens. On the code category, it scored 56.7 versus original 54.2.
- LongBench with LongChat-13B, 2,000-token constraint: LongLLMLingua averaged 35.5 with 1,822 tokens, versus original prompt average 30.5 with 10,295 tokens. On the code category, it scored 48.8 versus original 42.5.
- LooGLE long-dependency QA: LongLLMLingua averaged 32.1 with 3,121 tokens, versus original prompt average 22.6 with 30,546 tokens. The appendix reports 94.0% estimated GPT-3.5-Turbo inference cost reduction for LooGLE.
- Latency: the paper reports end-to-end speedups from compression plus API call time, with gains becoming stronger at higher compression ratios and reaching 2.6x in the reported tables.

Ablations support the design choices. On NaturalQuestions at 2x, removing question-aware coarse-grained compression collapses scores from roughly the low-to-high 70s to around 40. Replacing the LongLLMLingua relevance score with SBERT, reversing the conditional probability, removing the restrictive statement, removing fine-grained question awareness, removing dynamic ratios, or removing subsequence recovery all reduce performance. LongBench ablations show the largest impact from question-aware coarse compression on document QA and synthetic tasks; subsequence recovery helps reference-based tasks but has smaller effect on summarization, code, and synthetic categories.

The code-completion evidence is useful but limited. The project includes a `Code.ipynb` example for RepoBench-P and reports a 1.4-point improvement at 6x compression. In the paper's LongBench tables, code-completion results improve under several settings, especially for LongChat-13B, but the task is next-line completion rather than repository editing with tests, tools, and evolving state.

## Limits

The paper's own limitation section matters for agent design. LongLLMLingua is question-aware, so the same source context must be recompressed for different questions. That blocks straightforward context-cache reuse and can create substantial overhead. The authors also state that it can double computation compared with LLMLingua.

The method is lossy. It deletes tokens and relies on a smaller model's proxy relevance signal. That is acceptable for QA evidence but risky for coding-agent state, where a single removed character in a file path, symbol name, assertion, command flag, or stack trace can change the next action. Subsequence recovery repairs generated response text, not the agent's internal decision process before generation.

The benchmarks are not long-horizon software-engineering agents. RepoBench-P and LongBench code completion show that code can benefit from compression, but they do not test multi-turn debugging, test reruns, tool observations, user constraints, permission decisions, or edits across files. Transfer to Agentic Coding Lab should be treated as a design hypothesis requiring a coding-agent regression harness.

The relevance model is per-question and mostly optimized for finding answer-bearing evidence. Coding tasks often need relational state: chronology of edits, exact command output, hypotheses already falsified, or constraints that are not semantically similar to the immediate question. Reordering can also damage workflows where temporal order is part of the evidence.

## Research Themes

- Token efficiency: High relevance. The core objective is reducing prompt tokens while maintaining or improving task quality, and the paper reports 3x-10x compression settings with lower cost and latency.
- Context control: High relevance. It offers explicit context ranking, selection, ordering, and per-chunk budget allocation rather than passive truncation.
- Sub-agent / multi-agent: Low relevance. The compressor is a separate module, but the paper does not study coordination between agents or delegated coding roles.
- Domain-specific workflow: Medium relevance. It adapts compression to the current question and includes RAG, meeting, and code examples, but does not define coding-agent-specific state schemas.
- Error prevention: Medium relevance. It reduces lost-in-the-middle and noise-induced failures, but it does not provide deterministic safety checks or validation against corrupted compressed facts.
- Self-learning / memory: Low relevance. No persistent memory or online learning loop is proposed; compression behavior is hand-designed and model-scored.
- Popular skills: Medium relevance. The parameterized compression workflow maps well to a skill-like "compress this context for this current goal" routine, especially when paired with project-specific preservation rules.

## Key Ideas

- Use the current question or goal as the conditioning signal for compression. Context is not globally important; it is important relative to the next decision.
- Rank context chunks before token deletion. Coarse filtering protects the fine-grained compressor from spending budget on irrelevant regions.
- Use contrastive relevance, not raw perplexity alone. The difference between question-conditioned and unconditioned token scores is a better proxy for useful evidence.
- Treat prompt order as a control surface. Compression and retrieval are not enough if the retained evidence is placed where the model underuses it.
- Allocate budgets dynamically. More relevant chunks should receive lower compression pressure; less relevant chunks can be compressed harder or dropped.
- Preserve a map back to original text. Lossy compressed text can damage entities, identifiers, or names, so downstream systems need provenance and recovery hooks.

## Ideas To Steal

- Build a goal-aware context compressor for coding traces. Condition compression on the current user goal, next planned action, failing test, or open question rather than summarizing the whole session generically.
- Score context units before summarizing them. Rank files, diffs, command outputs, search notes, docs snippets, and decisions as separate chunks, then assign each a budget.
- Use dynamic retention classes. Preserve user constraints, edited files, exact failing output, command invocations, paths, symbols, environment details, and unresolved risks with higher budgets than narrative progress updates.
- Reposition key evidence. Put the current objective, constraints, and highest-value evidence near the active prompt edges instead of burying them in the middle of long histories.
- Keep provenance from compressed facts to original sources. Every compressed command output, error message, and file reference should retain a source pointer so an agent can re-open the exact original before editing or making a risky claim.
- Add a compression-regression harness. Save full-context and compressed-context versions of long coding tasks; flag cases where full context succeeds but compressed context fails, then update preservation rules.
- Separate policies by context type. Tool output, source code, user instructions, web research, plan state, and conversation history need different compression rules and different "never drop" fields.
- Prefer task-aware caches over per-question recompression. The paper's limitation suggests coding agents should cache compression artifacts at the goal/phase level and invalidate them when the task, files, or failing evidence changes.

## Do Not Copy

- Do not use lossy token deletion as the only representation of coding state. Exact symbols, paths, flags, stack frames, line numbers, and assertions must remain recoverable.
- Do not assume query-aware compression is cheap. A 7B-class compressor plus per-question recompression can erase latency/cost wins in interactive agent loops.
- Do not reorder chronological logs blindly. Build/test history, tool actions, and user decisions often require temporal ordering.
- Do not trust subsequence recovery as a correctness guarantee. It repairs surface strings after generation and does not prove the model reasoned over the right original fact.
- Do not apply the NaturalQuestions or LongBench scores as direct SWE-agent evidence. They validate a context-control mechanism, not end-to-end repository editing.
- Do not compress away low-similarity constraints. Security, permission, "do not edit", "do not commit", and test-scope constraints may be semantically distant from the immediate code question but still binding.

## Fit For Agentic Coding Lab

LongLLMLingua is in-scope because it treats context as an actively managed resource: select, compress, reorder, and recover. The most useful transfer is the shape of the control policy, not the exact token-deletion algorithm.

For Agentic Coding Lab, the practical artifact should be a coding-context compression contract:

- Inputs: current goal, task phase, user constraints, touched files, pending risks, command/test history, and candidate evidence chunks.
- Required retained fields: file paths, symbols, exact commands, exact failing outputs, user prohibitions, approvals, hypotheses already tested, and next action.
- Controls: chunk ranking, per-chunk budgets, recency/chronology guards, "never drop" patterns, source provenance, and validation against task outcomes.
- Verification: run compressed-trace regressions before enabling compression by default.

Verdict for adoption: use LongLLMLingua as a design reference for goal-aware context selection and evidence placement. Do not adopt it wholesale as a runtime memory layer until coding-agent traces prove that compressed context preserves exact operational facts.

## Related Repositories

- https://github.com/microsoft/LLMLingua - Official MIT-licensed implementation for LLMLingua, LongLLMLingua, LLMLingua-2, and later related work. Reviewed `main` commit `e0e9d99beb94098bbd924aa53c2c112eac41c758`, current GitHub API snapshot captured 2026-05-31: 6,230 stars, pushed 2026-04-08, default branch `main`.
- https://llmlingua.com/longllmlingua.html - Official project page with paper, code, demo links, method summary, benchmark table excerpt, and project news.
- Official implementation files reviewed: `llmlingua/prompt_compressor.py`, `README.md`, `DOCUMENT.md`, `examples/RAG.ipynb`, `examples/RAGLlamaIndex.ipynb`, `examples/Code.ipynb`, and `examples/Retrieval.ipynb`.
- The project page and documentation link LangChain and LlamaIndex integrations. These are useful ecosystem signals, but the deep review focused on the official Microsoft repository rather than third-party integration code.

## Reviewed Sources

- arXiv abstract page: https://arxiv.org/abs/2310.06839
- ACL Anthology record: https://aclanthology.org/2024.acl-long.91/
- ACL Anthology PDF: https://aclanthology.org/2024.acl-long.91.pdf
- Official project page: https://llmlingua.com/longllmlingua.html
- Official code repository: https://github.com/microsoft/LLMLingua
- GitHub API repository snapshot: https://api.github.com/repos/microsoft/LLMLingua
- GitHub API main commit snapshot: https://api.github.com/repos/microsoft/LLMLingua/commits/main
- OpenAlex API work record: https://api.openalex.org/works/W4402671835
- Semantic Scholar Graph API attempted source: https://api.semanticscholar.org/graph/v1/paper/arXiv:2310.06839?fields=title,citationCount,externalIds,url,venue,year,publicationDate,authors,openAccessPdf
