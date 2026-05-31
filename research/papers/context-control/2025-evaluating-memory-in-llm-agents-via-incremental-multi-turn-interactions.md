# Evaluating Memory in LLM Agents via Incremental Multi-Turn Interactions

- URL: https://arxiv.org/abs/2507.05257
- Cite as: arXiv:2507.05257
- DOI: 10.48550/arXiv.2507.05257
- Authors: Yuanzhe Hu, Yu Wang, Julian McAuley
- Venue / source: ICLR 2026 conference paper / poster; arXiv preprint v1 submitted 2025-07-07, v3 revised 2026-03-17.
- Published: arXiv submitted 2025-07-07; OpenReview published 2026-01-26 and last modified 2026-05-14.
- Citations snapshot: 1 citation
- Citation source: OpenAlex work W4415971869, `cited_by_count=1`, captured 2026-05-31. Semantic Scholar Graph API lookup for `ARXIV:2507.05257` returned HTTP 429 during review, so no Semantic Scholar count was verified.
- Code: https://github.com/HUST-AI-HYZ/MemoryAgentBench
- Dataset: https://huggingface.co/datasets/ai-hyz/MemoryAgentBench
- Topic: context-control
- Reviewed at: 2026-05-31
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong in-scope benchmark for context-control because it converts memory from a vague agent feature into measurable context behavior: retrieval, test-time learning, long-range understanding, and selective forgetting. Adopt the evaluation patterns and failure taxonomy, not the benchmark wholesale, because the tasks are mostly synthetic or adapted from non-coding corpora.

## Problem

Memory agents are commonly evaluated with anecdotes, short conversations, static long-context QA, or generic RAG metrics. Those settings miss the main challenge for long-running agents: information arrives incrementally, old context must be retained or overwritten, and queries may require a whole-session view rather than one retrieved snippet.

The paper frames memory as a context-control subsystem rather than a storage primitive. A memory agent must decide what to preserve, how to retrieve it, how to learn rules from prior turns, how to integrate distributed evidence, and when newer information should replace older information. This maps directly to coding agents, where stale assumptions, truncated command output, missing file paths, or outdated user constraints can cause repeated failures or unsafe edits.

## Method

MemoryAgentBench defines four memory competencies:

1. Accurate Retrieval (AR): retrieve specific evidence from long dialogue-like histories.
2. Test-Time Learning (TTL): learn labels, rules, preferences, or task patterns from examples observed during the interaction.
3. Long-Range Understanding (LRU): answer or summarize using a global view of a long sequence, not just local passages.
4. Selective Forgetting (SF): resolve conflicts by discarding or overwriting outdated facts with newer facts.

The benchmark reconstructs existing datasets and adds two new datasets, EventQA and FactConsolidation. Inputs are split into chunks and wrapped as simulated user-assistant turns with explicit memorization instructions. After all chunks are ingested, the agent answers multiple questions over the same context. This "inject once, query many" structure avoids rebuilding memory for every question and makes the benchmark closer to a long agent session than a one-shot long-context prompt.

The final OpenReview paper reports 2071 questions with context depths from 103K to 1.44M tokens. It evaluates long-context agents, simple lexical RAG, embedding RAG, structure-augmented RAG, and agentic memory systems. Metrics include accuracy, substring exact match, Recall@5, F1 or model-based F1 for summarization, and LLM-as-judge scoring for LongMemEval-style open answers.

Implementation review matches the paper's protocol. The official repository at commit `455306dcabc3842526eb83cd4e225e5d486c5c5d` has a `main.py` loop that loads agent/data configs, builds chunked contexts, initializes an `AgentWrapper`, memorizes each context, then runs every query for that context. `conversation_creator.py` standardizes Hugging Face rows into contexts and QA pairs. `agent.py` implements long-context buffers, BM25/dense/graph RAG handlers, Mem0, Cognee, Zep, Letta/MemGPT-style archival memory, Self-RAG, HippoRAG, RAPTOR, GraphRAG, MemoRAG, and retrieval-context logging. `utils/templates.py` contains the task-specific memory construction and query prompts. The public dataset page exposes 146 rows across `Accurate_Retrieval`, `Test_Time_Learning`, `Long_Range_Understanding`, and `Conflict_Resolution`; the code still uses `Conflict_Resolution` naming while the final paper calls the same FactConsolidation family `Selective Forgetting`.

## Evidence

Main result from the final OpenReview PDF: no evaluated architecture masters all four competencies. The headline table is more valuable as a failure map than as a leaderboard.

GPT-5-mini is the strongest reported long-context agent, with overall score 60.6, AR average 74.4, LRU average 66.2, and SF average 53.0. GPT-4.1-mini has strong AR average 71.8 but weaker overall score 46.9 because TTL, LRU, and SF do not scale automatically with a larger context window. Claude-3.7-Sonnet leads or remains competitive on several LRU/TTL cells but still scores only 22.5 average on SF.

RAG helps where the query points to local evidence. BM25 reaches 60.5 AR average and is especially attractive in cost-performance analysis, but its LRU average is only 35.6. HippoRAG-v2 reaches 65.1 AR average, near the best long-context systems for retrieval, but LRU and SF remain weak. Embedding RAG and structure-augmented RAG underperform when the task requires global integration, rule learning, or update propagation.

Agentic memory systems are not automatically better. Mem0, Cognee, Zep, MemGPT, Self-RAG, and MIRIX often lag their backbone long-context models. The stronger MIRIX variant with GPT-4.1-mini improves over MIRIX with GPT-4o-mini, but still scores 37.7 overall. This supports the paper's claim that memory architecture and backbone reasoning both matter.

Selective forgetting is the most useful stress test for Agentic Coding Lab. In the final table, most systems score single digits on multi-hop FactConsolidation. GPT-5-mini improves FC-MH to 28.0, but that is still low. A prompt overwrite-policy ablation barely helps: GPT-4.1-mini baseline averages 20.5 across FactConsolidation, aggressive "prefer later" reaches 22.0, and a conservative overwrite rule drops to 16.0. This is evidence that "just add a prompt rule" is not enough for reliable memory updates.

Ablations provide practical knobs. Smaller chunks help precise retrieval, while larger chunks preserve coherence for LRU. Increasing top-k generally improves retrieval but 10 chunks at 4096 tokens already consumes about 40K tokens and can add noise. Context-length scaling shows long-context model performance declining as histories grow, while Mem0 and Cognee can remain below the backbone even at smaller lengths. Latency tables show that heavy memory construction can dominate runtime: Mem0, Cognee, HippoRAG-v2, MemGPT, and MIRIX are orders of magnitude slower than BM25 in some settings.

## Limits

The benchmark is not a direct SWE-agent benchmark. Its strongest evidence comes from documents, novels, dialogue histories, classification/recommendation examples, and synthetic factual updates. Coding sessions have additional state types: diffs, exact shell output, dependency versions, test failures, permissions, file ownership, partial plans, and user constraints.

The protocol is two-stage: memory acquisition first, query execution later. That isolates memory capacity but does not fully capture interactive coding loops where new tool results, partial fixes, tests, and user feedback interleave with retrieval and state updates.

Selective forgetting uses controlled synthetic facts with serial numbers. That is defensible for isolating update behavior, but real agent memory updates are messier: newer information can be partial, conditional, wrong, or scoped to one repo/branch/user.

Some evaluation depends on LLM-as-judge scoring. The paper cites prior validation for LongMemEval and summarization judging, but any adoption should keep raw outputs and judge prompts auditable.

Reproducibility is useful but operationally heavy. The repository requires many external systems, API keys, GPU-backed embedding models for some methods, and dependency workarounds. The README explicitly notes missing HippoRAG dependency pinning and package conflicts. The code path also vendors or copies large memory-system packages, which is fine for benchmark reproduction but not a clean library boundary.

The final paper and project naming drift. OpenReview/arXiv final text uses `Selective Forgetting`; README and dataset/code still use `Conflict Resolution`. Treat them as the same benchmark family but preserve the final paper terminology in synthesis.

## Research Themes

- Token efficiency: High relevance. The cost and latency analyses show when long context, BM25, and agentic memory trade off cost against capability, especially under repeated queries over shared context.
- Context control: Very high relevance. The paper evaluates memory as incremental chunk ingestion, retrieval policy, active context assembly, and overwrite behavior.
- Sub-agent / multi-agent: Medium relevance. MIRIX uses a multi-agent memory architecture, but the paper is primarily a benchmark, not a multi-agent coordination method.
- Domain-specific workflow: High relevance. The benchmark argues that memory evaluation must be competency-specific; Agentic Coding Lab should create coding-specific AR, TTL, LRU, and SF tasks.
- Error prevention: High relevance. The SF and LRU failures are exactly the failure modes behind stale assumptions, repeated mistakes, and lost global task state.
- Self-learning / memory: Very high relevance. TTL and SF operationalize learning from interaction history and updating long-term memory.
- Popular skills: Medium relevance. The paper can inform skill validation: a useful skill should not only retrieve instructions, but also preserve global state, learn local project rules, and retire outdated guidance.

## Key Ideas

- Memory and long context are not the same. Full-context retention, RAG, and memory databases each fail differently under incremental interaction.
- Evaluate memory by competency, not by architecture. Retrieval, learning, global understanding, and forgetting need separate tasks and metrics.
- Use chunked multi-turn ingestion to activate real memory mechanisms. Static long-context prompts can hide failures in memory construction and update policy.
- Ask many questions against one built memory. This makes benchmark cost more realistic and exposes whether memory is reusable.
- Include overwrite/update tests. Agents that preserve everything can still fail when old facts should stop influencing answers.
- Separate local-evidence tasks from whole-history tasks. RAG looks strong on AR, but partial retrieval is often wrong for LRU and TTL.
- Measure latency and construction cost. A memory system that takes hours to build a memory for one long context is not a practical coding-agent subsystem.

## Ideas To Steal

- Build an Agentic Coding Lab memory benchmark with four slices: exact recall of prior tool outputs, project-specific rule learning, whole-session/codebase state synthesis, and stale-fact overwrite.
- Convert long coding traces into chunked memory-construction turns. Chunks should include user instructions, file reads, diffs, command outputs, test results, search findings, and review feedback.
- Use "one trace, many questions" evaluation. After a long coding session, ask multiple probes: current failing test, files touched, rejected approaches, user constraints, next safe command, and superseded assumptions.
- Add a selective-forgetting suite for coding. Examples: a branch changes after `git fetch`, a test failure is fixed by a later command, a user revises a constraint, or a dependency version discovered later invalidates an earlier plan.
- Keep task-specific prompts and schemas. Coding memory probes need exact path, command, output, and line-reference expectations, not generic "remember this" instructions.
- Log retrieved context as first-class evidence. The official code saves retrieved context for RAG handlers; Agentic Coding Lab should do the same so memory failures can be classified as retrieval failure, synthesis failure, or overwrite failure.
- Evaluate context-control systems under cost budgets. Compare raw long context, BM25 over trace chunks, structured state ledgers, and agentic memory with equivalent query sets and cached-context assumptions.

## Do Not Copy

- Do not copy the task corpus directly as a coding-agent benchmark. Novels, classification labels, recommendations, and synthetic facts are useful abstractions but miss code-specific state.
- Do not assume RAG is enough because it wins local retrieval. The paper repeatedly shows retrieval systems failing when global integration or learned rules are needed.
- Do not assume larger context windows solve memory. Long-context models still degrade with longer inputs and can fail update/forgetting tasks.
- Do not rely on prompt-only overwrite rules. The overwrite ablation shows limited gains and no reliable multi-hop update propagation.
- Do not make memory construction too expensive for normal coding runs. Heavy graph or agentic systems can be impractical despite appealing abstractions.
- Do not hide memory failures behind aggregate scores. Keep per-competency and per-question diagnostics, especially for stale-state and update failures.

## Fit For Agentic Coding Lab

This paper is in-scope for `context-control` because it gives Agentic Coding Lab a concrete evaluation shape for memory and context systems. The key adoption is a benchmark pattern:

1. Stream a realistic trace into the agent's memory/state system chunk by chunk.
2. Freeze the memory state.
3. Ask multiple targeted probes that require different memory competencies.
4. Record raw answer, retrieved context, active context, cost, latency, and whether old facts were correctly retired.

The practical artifact to build is a coding-session `MemoryAgentBench-lite`: small enough to run in CI, but explicit about competencies. Start with deterministic probes over saved traces before adding LLM-as-judge questions. Required coding probes should include exact recall, state update, plan continuity, test result interpretation, and stale instruction handling.

The verdict for adoption is strong but bounded. Use MemoryAgentBench to structure evaluation and vocabulary; build a domain-specific benchmark around real coding traces and repository state rather than treating this paper's results as proof that any memory architecture will transfer to SWE agents.

## Related Repositories

- https://github.com/HUST-AI-HYZ/MemoryAgentBench - Official MIT-licensed benchmark implementation. GitHub API snapshot on 2026-05-31 showed 347 stars, 54 forks, 24 commits in the web UI, and latest cloned commit `455306dcabc3842526eb83cd4e225e5d486c5c5d`.
- https://huggingface.co/datasets/ai-hyz/MemoryAgentBench - Official dataset release, MIT-licensed, with 146 rows across four splits and an arXiv link to 2507.05257.
- https://memoryarena.github.io/ - Related follow-on project linked from the official README; noted as related context only, not reviewed deeply for this paper note.

## Reviewed Sources

- arXiv abstract page and metadata: https://arxiv.org/abs/2507.05257
- arXiv HTML v3 full text: https://ar5iv.labs.arxiv.org/html/2507.05257v3
- OpenReview forum record: https://openreview.net/forum?id=DT7JyQC3MR
- OpenReview final PDF: https://openreview.net/pdf?id=DT7JyQC3MR
- Official code repository: https://github.com/HUST-AI-HYZ/MemoryAgentBench
- Official dataset page: https://huggingface.co/datasets/ai-hyz/MemoryAgentBench
- OpenAlex API work record: https://api.openalex.org/works/W4415971869
- Semantic Scholar API attempt: https://api.semanticscholar.org/graph/v1/paper/ARXIV:2507.05257?fields=title,citationCount,externalIds,publicationDate,venue,year,url returned HTTP 429 during review.
- Implementation files reviewed from the cloned official repository: `README.md`, `main.py`, `agent.py`, `conversation_creator.py`, `initialization.py`, `utils/templates.py`, `utils/eval_data_utils.py`, `utils/eval_other_utils.py`, representative `configs/data_conf/*` files, and `bash_files/sh/*`.
