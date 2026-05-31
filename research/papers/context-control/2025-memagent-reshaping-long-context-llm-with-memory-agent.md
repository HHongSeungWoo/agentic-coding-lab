# MemAgent: Reshaping Long-Context LLM with Multi-Conv RL-based Memory Agent

- URL: https://arxiv.org/abs/2507.02259
- Cite as: arXiv:2507.02259
- DOI: 10.48550/arXiv.2507.02259
- Authors: Hongli Yu, Tinghong Chen, Jiangtao Feng, Jiangjie Chen, Weinan Dai, Qiying Yu, Ya-Qin Zhang, Wei-Ying Ma, Jingjing Liu, Mingxuan Wang, Hao Zhou
- Venue / source: arXiv preprint and ICLR 2026 Oral on OpenReview.
- Published: arXiv submitted 2025-07-03; OpenReview record published 2026-01-26 and last modified 2026-04-11.
- Citations snapshot: 0 citations by OpenAlex; Semantic Scholar citation count could not be verified because the public API returned HTTP 429 from this environment.
- Citation source: OpenAlex work W6947947872, `cited_by_count=0`, captured 2026-05-31; Semantic Scholar API attempted 2026-05-31.
- Code: https://github.com/BytedTsinghua-SIA/MemAgent
- Topic: context-control
- Reviewed at: 2026-05-31
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong context-control paper because it turns bounded working memory into an explicit, trainable agent workflow, but Agentic Coding Lab should steal the workflow contract and verification pattern rather than the heavy RL recipe or QA-specific overwrite prompts.

## Problem

Long-context LLMs still degrade when inputs grow, even when nominal context windows are large. The paper argues that three common families of fixes are incomplete: positional extrapolation and continued pretraining can still hit performance and compute cliffs; sparse or linear attention often changes model architecture or relies on hand-designed patterns; and compression or external memory modules can be brittle, opaque, or hard to integrate with the normal decoder workflow.

The concrete problem is ultra-long document QA under a fixed active context budget. MemAgent asks whether a model with an 8K context window can process documents far beyond that window by reading chunks sequentially, maintaining a fixed-size token memory, and answering only from the final memory state.

This maps directly to Agentic Coding Lab's context-control problem. A coding agent has long-running evidence streams: user constraints, file reads, diffs, command output, test failures, tool results, review comments, and plan state. The useful question is not "can the model see everything?" but "can the agent repeatedly update a compact state that preserves exactly what later steps need?"

## Method

MemAgent decomposes one long-context task into many context-independent conversations. Each memory-update turn receives the problem, the previous memory, and one document chunk. The model outputs a new memory that overwrites the old one. After all chunks are processed, a final answer turn receives only the problem and the final memory and must produce the answer.

The default configuration in the paper and released code uses an 8K active window budget: roughly 1024 tokens for the problem, 5000 tokens for the document chunk, 1024 tokens for memory, and 1024 tokens for output. Since the memory length stays fixed and each chunk is processed independently, inference cost scales linearly with the number of chunks rather than quadratically with the total document length.

Training uses RL from verifiable rewards. The authors extend GRPO/DAPO into Multi-Conv DAPO: for each sampled trajectory, the rule-based reward is computed only from the final answer conversation, then the resulting group-normalized advantage is assigned to every memory-update and final-answer conversation belonging to that trajectory. In other words, memory writes receive credit or blame according to whether the final answer was correct.

The released implementation matches this design. `recurrent/impls/memory.py` and `recurrent/impls/async_memory.py` implement chunked memory updates and final-answer turns. `recurrent/generation_manager.py` and `recurrent/async_generation_manager.py` gather per-turn conversations and track `final_mask` plus `sample_index`. `verl/trainer/ppo/ray_trainer.py` extracts only final conversations for reward computation, then maps scalar GRPO advantages back onto all turns from the same original sample. The quickstart script exposes the same OpenAI-style loop against local vLLM or online model endpoints.

## Evidence

The paper evaluates mainly on synthetic long-context QA derived from HotpotQA and RULER-style tasks. Training data is synthesized from HotpotQA with about 28K-token examples; the authors filter examples answerable without context and train on 32,768 samples. Test sets scale the number of distractor articles from about 7K tokens to 3.5M tokens for the main HotpotQA-style task.

Headline result: RL-MemAgent-14B, trained with an 8K context window on 32K-token data, reports less than 5.5% degradation on 3.5M-token QA. RL-MemAgent-7B reports about 11% degradation in the longest setting. The abstract claims over 95% performance on 512K RULER, and the OpenReview abstract states over 95% on the 512K NIAH test with less than 10% loss on 3.5M QA.

The comparison set includes DeepSeek-R1-Distill-Qwen 7B/14B/32B, Qwen2.5-Instruct-1M 7B/14B, QwenLong-L1-32B, Qwen2.5-Instruct baselines, truncation, and MemAgent-style workflows without RL. Reported heatmaps show baseline degradation beyond 128K tokens on many RULER categories, while RL-MemAgent remains much more stable through 512K on NIAH, QA, variable tracking, and frequent-word extraction tasks.

The ablation signal is important. A MemAgent workflow without RL is often better than ordinary long-context baselines on some retrieval-like tasks, but it degrades on harder multi-key and multi-value tasks. The RL-trained 14B model is the most stable, suggesting the workflow prompt alone is not enough; the model must learn how to write useful bounded memory under downstream reward.

Implementation evidence is unusually practical for a paper note. The official GitHub repo provides Apache-2.0 code, model weights for RL-MemoryAgent-7B and RL-MemoryAgent-14B, a HotpotQA-derived dataset on Hugging Face, quickstart inference, training scripts, evaluation scripts, and a modified verl training stack for recurrent multi-conversation RL. The repo snapshot reviewed was commit `ef4219b23499a069cb00e5daff4c426d4c600851`.

## Limits

The evaluation is dominated by answerable QA and synthetic RULER variants. Those tasks reward retaining sparse answer evidence, which is simpler than preserving a coding session's executable state, partial edits, failed hypotheses, environment constraints, and exact command outputs.

The memory update is overwrite-only. This is elegant and cheap, but it can silently discard facts. In coding workflows, a bad overwrite can lose a user constraint, a file ownership boundary, or an exact failing assertion. The paper's final reward can catch this only when the final answer is verifiably wrong; many coding failures are delayed, ambiguous, or partially correct.

The RL recipe is expensive. The released 7B script expects at least 4 nodes with 8 GPUs per node and notes 3-4 days to converge at that scale; the 14B script expects 16 nodes with 8 GPUs per node. That makes the exact method unsuitable as a routine lab workflow unless reused offline for a narrow, high-value memory policy.

Reward design is narrow. Training uses rule-based verifiers over boxed or exact answers. Agentic coding tasks need richer verifiers: tests, typechecks, review findings, changed-file ownership, permission safety, and user-intent satisfaction. Without those, the same credit assignment pattern would train the wrong memory behavior.

The linear-complexity claim is about the active processing workflow, not free inference. Processing a 3.5M-token document still requires hundreds of chunk generations, each with a model call and memory write. The workflow reduces active-context blowup but can add latency and many opportunities for compounding memory errors.

## Research Themes

- Token efficiency: High relevance. The paper bounds active context with 5K chunks and 1K memory, shifting cost from one huge prompt to linear chunk processing.
- Context control: Very high relevance. MemAgent is explicitly a learned context controller that decides what survives in bounded working memory.
- Sub-agent / multi-agent: Medium relevance. The multi-conversation machinery is reusable for agent workflows, but the paper is not about collaborative multi-agent systems.
- Domain-specific workflow: High relevance. The method succeeds because the workflow and reward are tailored to long-document QA; coding adoption would need coding-specific memory schemas and verifiers.
- Error prevention: Medium relevance. It can prevent lost-in-the-middle and long-context degradation, but it does not directly address unsafe edits, stale repository state, or tool misuse.
- Self-learning / memory: High relevance. It trains the model to write and preserve working memory from downstream reward rather than relying on static summarization prompts.
- Popular skills: Medium relevance. The memory-update prompt is skill-like, but the core value is the trained recurrent policy and verifier-backed workflow.

## Key Ideas

- Treat memory writing as an action, not as a passive summarization side effect.
- Keep memory in ordinary token space so it remains inspectable, editable, and compatible with standard decoder models.
- Use fixed-size overwrite memory to make long-context processing an iterative state-update problem.
- Assign final task reward backward to every context-independent conversation that contributed to the final memory.
- Track final-answer turns separately from intermediate memory turns with explicit masks and sample indices.
- Provide both sync and async recurrent-agent interfaces so multi-step workflows can be trained without hand-writing a state machine for every task.
- Use verifiable outcomes, not summary-quality judgments, to train what memory should retain.

## Ideas To Steal

- Add a bounded "working memory panel" for coding agents. It should be a structured state object that survives compaction: current goal, user constraints, files touched, commands run, failing outputs, resolved decisions, unresolved risks, and next action.
- Treat each context update as a separate conversation with its own input and output. This makes memory updates auditable and lets a verifier distinguish intermediate state from final task output.
- Introduce `final_mask` and `sample_index` equivalents in research harnesses. Only final task outcomes should be scored, but credit assignment and debugging need the full chain of memory updates.
- Train or tune memory policies against coding verifiers. For example: does the memory retain enough exact state for the next agent to pass tests, avoid touching forbidden files, and continue without re-reading everything?
- Start with prompt-level or rule-level memory contracts before RL. MemAgent supports the design direction, but the lab can prototype with deterministic schemas and regression tests first.
- Keep memory human-readable. Reviewable memory enables debugging, handoff, post-compact recovery, and user-visible audits in a way hidden KV-cache or embedding summaries cannot.
- Separate "what to remember" from "how to answer." The memory writer should preserve evidence and state; the final solver should consume that memory under task-specific verification.

## Do Not Copy

- Do not copy the QA prompt directly for coding. Coding memory needs exact paths, command outputs, diffs, test names, dependency versions, and user constraints, not prose summaries of article chunks.
- Do not rely on overwrite-only memory without guardrails. Critical coding facts should be protected by typed fields, append-only logs, or verifier-required slots.
- Do not assume final-answer rewards are enough. Coding agents need intermediate safety checks because harmful state loss may occur before final tests run.
- Do not adopt the full RL stack as the first implementation. The infrastructure and GPU cost are too high for exploratory lab work.
- Do not treat "linear context processing" as low latency. Many chunk calls can be slower than a single long-context call for moderate inputs.
- Do not overgeneralize from RULER/HotpotQA. Sparse retrieval and answer extraction are not the same as multi-file software repair.
- Do not hide memory updates. If the memory state cannot be inspected, corrected, or regression-tested, the main practical benefit disappears.

## Fit For Agentic Coding Lab

MemAgent is in-scope because it provides a concrete architecture for long-running context control: bounded state, explicit update steps, final-outcome verification, and credit assignment over multiple independent conversations. The lab should view it as evidence for "memory as a trained workflow," not as a plug-in replacement for context windows.

The most useful artifact candidate is a coding-memory state machine with a fixed budget and verifier-backed tests. A lightweight version could run after large observations, compaction events, or subagent handoffs. It would overwrite or revise a structured memory panel, but exact safety-critical fields would be pinned unless a verifier confirms they are obsolete.

For agentic coding, a practical adaptation would combine MemAgent with ACON-like failure audits: compare full-trace successes against memory-compressed failures, identify which coding facts were lost, update the memory schema or prompt, then re-run held-out tasks. This avoids jumping straight to RL while preserving the paper's key insight: memory quality must be judged by downstream task success.

The strongest takeaway is credit routing. In long sessions, only the final test or review outcome may reveal whether earlier context choices were good. Agentic Coding Lab should record the sequence of context updates so failures can be traced back to a missing field, bad summary, or stale assumption rather than treated as generic model error.

## Related Repositories

- https://github.com/BytedTsinghua-SIA/MemAgent - Official implementation. Apache-2.0, Python, 1,052 GitHub stars and 69 forks via GitHub API on 2026-05-31. Reviewed commit `ef4219b23499a069cb00e5daff4c426d4c600851`. Includes recurrent agents, modified verl training, quickstart inference, evaluation scripts, model-serving helpers, training scripts, and a vendored/modified verl tree.
- https://huggingface.co/BytedTsinghua-SIA/RL-MemoryAgent-14B - Released 14B model weights, Apache-2.0, Qwen2.5-14B-Instruct base, last modified 2025-07-07; Hugging Face API showed 395 downloads and 30 likes on 2026-05-31.
- https://huggingface.co/BytedTsinghua-SIA/RL-MemoryAgent-7B - Released 7B model weights, Apache-2.0, Qwen2.5-7B-Instruct base, last modified 2025-07-07; Hugging Face API showed 1,283 downloads and 7 likes on 2026-05-31.
- https://huggingface.co/datasets/BytedTsinghua-SIA/hotpotqa - Released HotpotQA-derived training and evaluation data, CC-BY-SA-4.0, last modified 2025-07-30; Hugging Face API showed 1,372 downloads and 13 likes on 2026-05-31.

## Reviewed Sources

- arXiv abstract page: https://arxiv.org/abs/2507.02259
- arXiv HTML full text: https://ar5iv.labs.arxiv.org/html/2507.02259v1
- arXiv PDF / official repository PDF reviewed from `paper/paper.pdf`
- OpenReview ICLR 2026 Oral record: https://openreview.net/forum?id=k5nIOvYGCL
- Project page: https://memagent-sialab.github.io/
- Official code repository: https://github.com/BytedTsinghua-SIA/MemAgent
- OpenAlex API work record: https://api.openalex.org/works/W6947947872
- Semantic Scholar API attempted: https://api.semanticscholar.org/graph/v1/paper/arXiv:2507.02259
- Hugging Face model APIs: https://huggingface.co/api/models/BytedTsinghua-SIA/RL-MemoryAgent-14B and https://huggingface.co/api/models/BytedTsinghua-SIA/RL-MemoryAgent-7B
- Hugging Face dataset API: https://huggingface.co/api/datasets/BytedTsinghua-SIA/hotpotqa
- Implementation files reviewed from the official repository: `README.md`, `quickstart.py`, `recurrent/impls/memory.py`, `recurrent/impls/async_memory.py`, `recurrent/interface.py`, `recurrent/generation_manager.py`, `recurrent/async_generation_manager.py`, `verl/trainer/ppo/ray_trainer.py`, `verl/trainer/config/ppo_trainer.yaml`, `verl/utils/reward_score/hotpotqa.py`, `taskutils/memory_eval/run.py`, `taskutils/memory_eval/utils/recurrent.py`, and `taskutils/memory_eval/utils/recurrent_boxed.py`.
