# LongBench: A Bilingual, Multitask Benchmark for Long Context Understanding

- URL: https://arxiv.org/abs/2308.14508
- Cite as: arXiv:2308.14508; ACL Anthology 2024.acl-long.172
- DOI: 10.18653/v1/2024.acl-long.172
- Authors: Yushi Bai, Xin Lv, Jiajie Zhang, Hongchang Lyu, Jiankai Tang, Zhidian Huang, Zhengxiao Du, Xiao Liu, Aohan Zeng, Lei Hou, Yuxiao Dong, Jie Tang, Juanzi Li
- Venue / source: Proceedings of the 62nd Annual Meeting of the Association for Computational Linguistics (Volume 1: Long Papers), ACL 2024, pages 3119-3137; arXiv preprint v1 submitted 2023-08-28 and v2 revised 2024-06-19.
- Published: ACL 2024, August 2024; arXiv first submitted 2023-08-28.
- Citations snapshot: 97 citations in OpenAlex; Crossref reports `is-referenced-by-count=98`; Semantic Scholar API could not be verified from this environment because the API returned HTTP 429.
- Citation source: OpenAlex work W4402671766, `cited_by_count=97`, captured 2026-05-31; Crossref DOI API for 10.18653/v1/2024.acl-long.172, captured 2026-05-31; Semantic Scholar Graph API request for `arXiv:2308.14508`, captured 2026-05-31, returned rate limit.
- Code: https://github.com/THUDM/LongBench
- Topic: context-control
- Reviewed at: 2026-05-31
- Status: reviewed
- Scope fit: conditional
- Verdict: Useful as an evaluation scaffold for context-control policies, especially length-stratified tests and no-context leakage checks, but it is a benchmark paper rather than an agentic coding method. Steal the harness patterns and the negative compression evidence, not the old model leaderboard or the automatic metrics as final proof.

## Problem

LongBench addresses a gap in long-context evaluation. Many LLMs were strong on short prompts but weak on documents, reports, books, and codebases that run thousands or tens of thousands of tokens. Existing long-context evaluations were narrower, often focused on perplexity, artificial retrieval, or a small range of task types, so they did not cleanly measure whether a model could use long context across realistic task families.

For Agentic Coding Lab, this maps to a recurring context-control problem: a coding agent needs to know whether its context policy preserves enough evidence from files, command output, tests, prior decisions, and cross-file dependencies. Without a benchmark-style harness, truncation, retrieval, and summarization policies can look cheaper while silently dropping the exact fact needed for the next edit.

## Method

LongBench builds a bilingual benchmark with 4,750 test instances across 21 datasets and 6 task categories: single-document QA, multi-document QA, summarization, few-shot learning, synthetic tasks, and code completion. It includes 14 English tasks, 5 Chinese tasks, and 2 code tasks. English and code lengths are measured by word count, while Chinese lengths are measured by character count. The paper reports an average length of 6,711 words for English instances and 13,386 characters for Chinese instances.

The benchmark standardizes each example into an `(input, context, answer)` framing. In the released Hugging Face dataset and code, this becomes a JSON-style record with fields such as `input`, `context`, `answers`, `length`, `dataset`, `language`, `all_classes`, and `_id`. This schema is one of the most transferable design choices because it separates the short command/question from the long evidence payload.

The data construction mixes reused, adapted, and newly annotated data. Some datasets are directly extracted from prior test sets; others are modified to create longer contexts with distractors or few-shot examples. The authors add MultiFieldQA in English and Chinese using long documents from sources such as academic papers, legal documents, government reports, encyclopedias, and web text. They also add synthetic tasks for passage retrieval and counting, and code tasks from LCC and RepoBench-P. RepoBench-P uses cross-file code snippets and selects the harder XF-F setting, where in-file context does not already show the module usage.

LongBench-E is a length-stratified subset. It uses 13 English datasets with more even sampling across 0-4k, 4-8k, and 8k+ length ranges, so performance can be compared as context grows without being dominated by task mix.

Evaluation is automated. QA tasks use F1, summarization uses ROUGE-L, classification and synthetic retrieval/counting use accuracy or exact-match-style scoring, and code completion uses edit similarity. The prompts are task-specific and often repeat instructions before and after the long context. If a prompt exceeds a model's maximum context length, the evaluation truncates from the middle and preserves the beginning and end, because those positions often contain instructions, questions, or answer format constraints.

The paper also tests simple context compression baselines. Retrieval compression chunks QA contexts and keeps top chunks by OpenAI embeddings, Contriever, or BM25. Summarization compression asks a model to summarize chunks and concatenates the summaries for summarization tasks.

## Evidence

The main paper evaluates eight 2023-era models: GPT-3.5-Turbo-16k, Llama2-7B-chat-4k, LongChat-v1.5-7B-32k, XGen-7B-8k, InternLM-7B-8k, ChatGLM2-6B, ChatGLM2-6B-32k, and Vicuna-v1.5-7B-16k. GPT-3.5-Turbo-16k has the best overall score in the reported tables at 44.7 across all tasks. ChatGLM2-6B-32k is close at 41.4 and substantially improves over ChatGLM2-6B at 25.7, supporting the claim that longer-context training and position scaling helped.

The length analysis is more valuable than the leaderboard. On LongBench-E, ChatGLM2-6B-32k and LongChat-v1.5-7B-32k have smaller relative drops from 0-4k to 8k+ than GPT-3.5-Turbo-16k, even though GPT-3.5-Turbo-16k has stronger aggregate task scores. This shows why a context-control benchmark needs length bins rather than a single average.

The truncation experiment also supports the benchmark design. GPT-3.5-Turbo-16k and ChatGLM2-6B-32k score better when allowed their maximum context than when truncated to 4k or 8k, indicating that the long context is actually useful rather than filler.

The compression results are cautionary. Retrieval improves Llama2-7B-chat-4k on QA tasks from 19.9 to 24.0 average under the best retrieval setting, but it slightly hurts GPT-3.5-Turbo-16k and ChatGLM2-6B-32k. Summarization compression hurts the average on summarization tasks for all three tested models, though it helps the long Chinese VCSUM task. The practical lesson is that retrieval and summaries can compensate for weak long-context models, but are not a universal replacement for preserving the original context.

The memorization check is important. With the long context removed, models still perform non-trivially on Wikipedia-derived QA datasets such as HotpotQA, 2WikiMultihopQA, and MuSiQue. For example, GPT-3.5-Turbo-16k scores 31.7 on HotpotQA without context and 51.6 with context. This is a useful benchmark hygiene pattern: always include a no-context baseline to estimate contamination, memorization, or prior-knowledge shortcuts.

The official repository matches the paper's evaluation story. The v1 code now lives under `LongBench/` in `THUDM/LongBench`, while the repository root has moved on to LongBench v2. I reviewed commit `2e00731f8d0bff23dc4325161044d0ed8af94c1e`. The v1 code includes `pred.py`, `eval.py`, task prompts and max generation lengths in `config/`, metric implementations, retrieval compression scripts, and a summarization compression script. The GitHub API reported 1,182 stars and 133 forks on 2026-05-31. The Hugging Face dataset page redirects to `zai-org/LongBench`, reports 178 likes and 78,262 downloads last month, and notes that the current dataset viewer cannot load the old dataset script.

## Limits

LongBench is not an agentic coding benchmark. It includes code completion and cross-file code snippets, but it does not evaluate multi-step repository editing, shell/tool use, test repair, file-system navigation, or long-running agent memory. Its fit for Agentic Coding Lab is therefore conditional: it is more useful for harness structure than for direct task content.

The model leaderboard is historically useful but stale. The evaluated models were appropriate for the paper's 2023-2024 context, but modern long-context models and agent runtimes need a separate sweep.

The automatic metrics are a known weakness. The paper itself flags ROUGE-L and F1 as potentially unreliable, especially for models that generate longer answers. The metrics are cheap and reproducible, but they can undercount semantically valid outputs and can reward format gaming.

The benchmark still couples long-context ability with instruction following. A model can fail because it missed the answer in the context, because it ignored the answer-format instruction, or because it was weak at the underlying task.

Data contamination remains a risk. The no-context experiment shows that several public, Wikipedia-derived tasks can be partly answered without the supplied context. LongBench partially mitigates this with delta scores and newly annotated MultiFieldQA, but it does not eliminate leakage concerns.

The context lengths are modest by 2026 standards. Most tasks sit around 5k-15k words or characters, and the paper does not stress 100k, 1M, or multi-turn context histories. The later LongBench v2 is a separate benchmark that targets longer and harder realistic tasks.

The compression baselines are intentionally simple and should not be treated as polished context-control implementations. Retrieval is evaluated mainly on QA tasks, summarization compression is narrow, and the released `summ/compress.py` has rough edges such as hard-coded model choices, empty API-key placeholders, and a code path where `new_text` is referenced before assignment and then falls back to the original text on exception.

The repository is an evaluation release, not a secure production runner. It uses `trust_remote_code=True` for some Hugging Face models and has hard-coded key placeholders in compression/retrieval scripts. Those are acceptable for a research harness but not directly for Agentic Coding Lab runtime policy.

## Research Themes

- Token efficiency: Medium relevance. The paper evaluates retrieval and summarization as context compression, but the main artifact is a benchmark, not a token-saving method. Its strongest token lesson is that compression must be judged by task outcome, not shorter prompt length.
- Context control: High relevance. LongBench gives concrete dimensions for evaluating whether long context is preserved and used: task families, length bins, truncation baselines, no-context baselines, and compression comparisons.
- Sub-agent / multi-agent: Low relevance. There is no multi-agent orchestration or subagent division of labor.
- Domain-specific workflow: Medium relevance. The benchmark includes code completion and cross-file code snippets, but does not model real coding-agent workflows with edits, tests, and tools.
- Error prevention: Medium relevance. The no-context baseline and length-stratified evaluation help detect false confidence, memorization, and context-loss failures.
- Self-learning / memory: Low relevance. The paper discusses memory mechanisms as background but does not propose persistent memory or self-improving context policies.
- Popular skills: Medium relevance. LongBench can inform a reusable "evaluate context policy" skill: build a task fixture, run no-context/truncated/full/compressed variants, then compare deltas by length and task type.

## Key Ideas

- Use a unified long-context example schema: short input, long context, accepted answers, length, dataset, language, class labels, and stable IDs.
- Evaluate context-control policies by task family, not only by aggregate score. Single-doc QA, multi-doc QA, summarization, few-shot examples, synthetic diagnostics, and code all stress context differently.
- Add a length-balanced split. Averages over natural data distributions hide whether a model or policy degrades as context grows.
- Keep a no-context baseline. It separates actual context use from memorization, prior knowledge, and benchmark leakage.
- Preserve the beginning and end when forced to truncate. The paper's implementation assumes instructions and questions are often at the edges.
- Test naive compression explicitly. Retrieval and summarization can help weak long-context models but can hurt stronger models or tasks that require global information.
- Include synthetic tasks that target specific failure modes, such as finding a paragraph from a generated summary or counting unique repeated passages.

## Ideas To Steal

- Build an Agentic Coding Lab "LongBench-Coding" fixture format with fields like `task_id`, `goal`, `context_blocks`, `files`, `command_history`, `tool_outputs`, `expected_answer_or_patch`, `length_bucket`, `source_repo`, and `allowed_metrics`.
- Add length buckets to every context-control evaluation. For modern coding agents, use buckets such as 0-8k, 8k-32k, 32k-128k, and 128k+ rather than only the paper's 0-4k, 4-8k, and 8k+ ranges.
- Run four baselines for every candidate context policy: no context, middle truncation, full context, and policy-compressed context. Report both raw scores and delta from full context.
- Include leakage checks for coding tasks. A no-repo or no-file-context baseline can reveal when an answer is coming from package/common knowledge rather than the provided codebase.
- Reuse the multi-task taxonomy but make it coding-native: single-file QA, multi-file QA, log summarization, few-shot convention following, synthetic path/symbol retrieval, cross-file completion, and patch repair.
- Preserve exact artifacts in the schema. Coding-agent context should retain file paths, line numbers, commands, exit codes, failing assertions, dependency versions, and user constraints as structured fields, not only prose summaries.
- Treat compression methods as competitors in the same harness. Compare retrieval, deterministic filters, LLM summaries, and hybrid memory policies under identical tasks and length buckets.
- Add task-level and context-source-level reporting. A policy that helps test-log summarization may harm cross-file repair, just as LongBench retrieval helped weak QA settings but hurt stronger long-context models.
- Keep automatic metrics for cheap regression checks, but route ambiguous patch quality, summarization, and multi-step repair tasks to stronger judge or human review.

## Do Not Copy

- Do not treat LongBench scores as proof that a model or agent is good at software engineering. The benchmark has only code completion, not repository repair.
- Do not rely on ROUGE-L, F1, or edit similarity as final quality signals for coding-agent behavior. They are useful smoke metrics, not correctness guarantees.
- Do not assume retrieval or summarization compression is always beneficial. The paper's own results show compression can degrade stronger models and global summarization tasks.
- Do not use public benchmark performance without no-context and contamination controls. Public QA and Wikipedia-derived datasets can be partly solved from memory.
- Do not copy the released runner as production infrastructure. Hard-coded credentials, `trust_remote_code=True`, and research-script error handling need replacement before any runtime use.
- Do not evaluate only short or moderate long contexts. Agentic Coding Lab needs longer session histories, multi-file repos, and tool traces than LongBench v1 covers.
- Do not conflate instruction-following failures with context failures. A good harness needs error categories or traces that identify whether the model lost evidence, ignored format, or lacked task skill.

## Fit For Agentic Coding Lab

LongBench is conditionally in-scope. It is not a source of directly adoptable agent behavior, but it is a strong reference for designing context-control evaluations. The most important transfer is the evaluation discipline:

1. Standardize long-context task records.
2. Stratify by length and task type.
3. Include no-context, truncated-context, full-context, and compressed-context baselines.
4. Report deltas rather than only headline averages.
5. Audit cases where compression or truncation beats/fails full context.

For Agentic Coding Lab, this should become a context-policy regression suite. Every proposed memory, retrieval, summarization, or truncation rule should be measured against coding-native fixtures with exact retained evidence. A policy should not be accepted because it reduces tokens; it should be accepted only when it preserves or improves task success for the relevant context source and length bucket.

The paper also supports a practical warning: context-control should not be framed as "summarize more." LongBench shows that even simple retrieval can help one weak model while hurting stronger ones, and summarization can lose global task quality. Agentic Coding Lab should therefore make compression opt-in by source/risk and evaluate each policy against tasks where exact details matter.

## Related Repositories

- https://github.com/THUDM/LongBench - Official code repository. Reviewed commit `2e00731f8d0bff23dc4325161044d0ed8af94c1e`; MIT licensed; GitHub API reported 1,182 stars and 133 forks on 2026-05-31. The repository root now foregrounds LongBench v2, while original LongBench v1 files live under `LongBench/`.
- https://huggingface.co/datasets/zai-org/LongBench - Official dataset page after Hugging Face redirect from `THUDM/LongBench`. It provides loading snippets, schema, task statistics, and dataset card metadata; the dataset viewer currently reports that old dataset scripts are unsupported.
- https://longbench2.github.io - Related project page for LongBench v2. It is not the reviewed paper, but it confirms the authors later moved toward longer, harder, multiple-choice long-context tasks.

## Reviewed Sources

- arXiv abstract page: https://arxiv.org/abs/2308.14508
- arXiv PDF v2: https://arxiv.org/pdf/2308.14508
- ACL Anthology record: https://aclanthology.org/2024.acl-long.172/
- ACL Anthology PDF: https://aclanthology.org/2024.acl-long.172.pdf
- OpenAlex API work record: https://api.openalex.org/works/W4402671766
- Crossref DOI API record: https://api.crossref.org/works/10.18653/v1/2024.acl-long.172
- Semantic Scholar Graph API attempt: https://api.semanticscholar.org/graph/v1/paper/arXiv:2308.14508?fields=title,citationCount,externalIds,year,venue,publicationDate,authors,url
- Official code repository: https://github.com/THUDM/LongBench
- Official dataset page: https://huggingface.co/datasets/zai-org/LongBench
- Related LongBench v2 project page: https://longbench2.github.io
- Implementation files reviewed from official repository commit `2e00731f8d0bff23dc4325161044d0ed8af94c1e`: `LongBench/README.md`, `LongBench/task.md`, `LongBench/pred.py`, `LongBench/eval.py`, `LongBench/metrics.py`, `LongBench/config/dataset2prompt.json`, `LongBench/config/dataset2maxlen.json`, `LongBench/retrieval/README.md`, `LongBench/retrieval/LongBench.py`, `LongBench/retrieval/pred.py`, `LongBench/retrieval/eval.py`, `LongBench/summ/README.md`, and `LongBench/summ/compress.py`.
