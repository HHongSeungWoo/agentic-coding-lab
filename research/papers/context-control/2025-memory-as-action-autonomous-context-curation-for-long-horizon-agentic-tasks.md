# Memory as Action: Autonomous Context Curation for Long-Horizon Agentic Tasks

- URL: https://arxiv.org/abs/2510.12635
- Cite as: arXiv:2510.12635
- DOI: 10.48550/arXiv.2510.12635
- Authors: Yuxiang Zhang, Jiangming Shu, Ye Ma, Xueyuan Lin, Shangxi Wu, Jitao Sang
- Venue / source: arXiv preprint; OpenReview record for ACL ARR 2026 January Submission 1731.
- Published: arXiv submitted 2025-10-14, v2 revised 2026-01-10, v3 revised 2026-05-07. OpenReview record posted 2025-12-31 and modified 2026-03-20.
- Citations snapshot: 0 citations in OpenAlex; 7 citations on Semantic Scholar public page.
- Citation source: OpenAlex work W4415270781, `cited_by_count=0`, captured 2026-05-31; Semantic Scholar Corpus ID 282064912 public page shows "7 Citations", captured 2026-05-31. Semantic Scholar API returned HTTP 429 during verification.
- Code: https://github.com/ADaM-BJTU/MemAct
- Topic: context-control
- Reviewed at: 2026-05-31
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong conceptual source for treating context curation as an explicit agent action, but Agentic Coding Lab should adopt the audited memory-action interface and evaluation patterns rather than the full RL training stack or lossy deletion policy.

## Problem

Long-horizon agents accumulate task reasoning, tool calls, retrieval output, intermediate hypotheses, and stale observations. The paper argues that simply increasing context length does not solve this because attention can be diluted by irrelevant history, while external memory controllers and fixed summarization schedules are decoupled from the agent's reasoning state.

The paper names this as "context curation": selecting, integrating, and pruning information so a focused reasoning trace remains available at the right time. This is directly in-scope for Agentic Coding Lab. A coding agent has the same failure surface: large command outputs, old hypotheses, superseded diffs, test logs, issue comments, and search results can crowd out the current goal, user constraints, exact failing output, and next verification step.

## Method

Memory-as-Action, abbreviated MemAct, augments the agent action space with memory actions. The state is a working-memory sequence of interaction records. Each record contains an action, its observation, and a unique ID. Normal task actions append new records. Memory actions use a Prune&Write operator with two parameters: a set of target IDs to remove and generated memory content that summarizes facts, status, reflections, or plans needed after pruning. The memory action itself is appended back into the context as an addressable record.

The technical problem is that deletion breaks the append-only prefix assumption used by causal language models and standard LLM RL pipelines. If a token was generated before deletion, its hidden state may already encode the deleted content. The paper calls this a trajectory fracture and rejects simple attention masking as insufficient.

Dynamic Context Policy Optimization, abbreviated DCPO, handles this by segmenting trajectories at memory-edit points. Each segment has a fixed context prefix and the token sequence generated under that prefix. Full trajectories receive sparse terminal rewards: positive reward for task success, negative reward for constraint violations such as exceeding context length or step limits, and zero otherwise. Sampled segments inherit the trajectory-level advantage, normalized across multiple trajectories for the same prompt, then are optimized with a GRPO-style clipped objective.

The training pipeline has two stages. First, DeepSeek-V3.1 generates cold-start SFT trajectories with staged prompts: no hint below a soft threshold, a reminder to consider memory update between soft and hard thresholds, and a stronger instruction above the hard threshold. Only successful trajectories are retained, and the injected hints are removed. Second, Qwen2.5-7B-Instruct and Qwen2.5-14B-Instruct are trained with DCPO on tasks limited to at most three objectives, then evaluated on harder tasks with up to eight objectives.

Implementation evidence in the official repository matches the paper's design. The repo is a `verl` 0.5.0 based training framework. `verl/experimental/agent_loop/mem_agent_loop.py` registers `mem_agent`, exposes `prune_context`, reconstructs prompt IDs after deletion, and emits response masks for trajectory segments. `verl/trainer/ppo/core_algos.py` registers the `dcpo` advantage estimator and deduplicates rollout IDs when computing group statistics. `DCPO/config/mem_search_tool_config_single.yaml` defines the `prune_context` schema with required `memory` and `delete_ids` fields.

## Evidence

The evaluation covers a synthetic multi-objective QA benchmark derived from HotpotQA and single-objective benchmarks: 2WikiMultihopQA, Bamboogle, HotpotQA, Frames, and BrowseComp-Plus. The main metrics are task accuracy, solved sub-objective count, token cost, and tool-call frequency. Task accuracy is judged by an LLM evaluator with a three-pass consensus protocol.

Main 14B results are strong for context control:

- MemAct SFT+RL reaches 0.537 average accuracy on single-objective tasks and 0.591 average accuracy on multi-objective tasks, with average token cost of 8.2 x 10^4.
- Qwen3-235B reaches 0.500 single-objective average and 0.531 multi-objective average, with cost of 16.7 x 10^4.
- Search-R1, which shares the RL search-agent setup but lacks memory actions, reaches 0.535 single-objective average and 0.514 multi-objective average, with cost of 19.3 x 10^4.
- A-MEM is cheaper at 3.9 x 10^4 tokens but much less accurate: 0.383 single-objective average and 0.399 multi-objective average.
- On 8-objective tasks, MemAct SFT+RL scores 0.543 versus 0.393 for Search-R1 and 0.489 for Qwen3-235B.

The ablations are more important than the headline. The fixed-update baseline, which prunes every five turns, reduces context but trails MemAct on harder tasks, supporting the claim that timing matters. Search-R1 shows that RL without memory actions still suffers token growth and context noise. The appendix also reports a PPO-based DCPO variant that stays above Search-R1, suggesting the value is mostly in trajectory segmentation rather than one specific optimizer.

The efficiency evidence is credible but bounded. The paper reports that MemAct-RL-7B reduces total duration by 40% versus Search-R1 over 2,000 SGLang trajectories. The explanation is that sparse memory updates keep local prefixes stable enough for cache reuse while shrinking prefill burden. This is relevant to coding agents, but the measured workloads are QA/search tasks rather than repo-edit/test loops.

The qualitative case studies are useful. Successful memory actions preserve objective, verified facts, status, and assumptions while deleting raw search output. Failure cases show the main risk: unresolved ambiguity or unsupported guesses can be written into memory and later treated as facts.

## Limits

The strongest limitation is domain transfer. The experiments evaluate information-seeking and multi-hop QA, not software engineering tasks with file edits, build systems, test failures, dependency constraints, or destructive-operation safety. The paper mentions software engineering agents as motivation, but does not validate on SWE-bench or a coding-agent benchmark.

The method uses sparse terminal rewards, so credit assignment for individual memory actions remains weak. The authors explicitly note that the model can delete information that becomes relevant later. Because Prune&Write is lossy, the original detail cannot be recovered from the curated context unless a separate raw transcript is retained.

The cold-start setup also matters. The authors report that frontier models such as OpenAI o3 and DeepSeek-V3.1 did not reliably learn memory editing through prompting alone, so they used staged teacher prompting and filtering. This weakens the claim that the policy naturally discovers memory behavior without carefully constructed training data.

The public repository is research code, not a drop-in production component. It vendors a large `verl` tree, includes only two public commits, uses placeholder model paths and service URLs, references a `Mem/config/...` path in the 14B script while the public tree exposes `DCPO/config/...`, and assumes an 8x H100 class environment for the main setup. There is no obvious lightweight test suite or production-grade delete/restore ledger.

The memory action implementation also has safety concerns for direct adoption. It matches requested delete IDs against tool-response content, removes matched assistant/tool records, and keeps the generated memory note as the surviving state. That is fine for research traces, but a coding agent needs stricter guarantees around never pruning user/developer instructions, exact failing outputs, recent diffs, security decisions, or unverified assumptions.

## Research Themes

- Token efficiency: High relevance. The paper directly optimizes active context length, total token cost, and latency, with MemAct-RL-14B using roughly half the token cost of Qwen3-235B and less than half of Search-R1-14B in the main table.
- Context control: Very high relevance. The central contribution is turning context pruning and summarization into explicit policy actions with ID-targeted deletion and training-time trajectory segmentation.
- Sub-agent / multi-agent: Low relevance. There is a separate environment/tool layer, but the paper is about a single policy learning memory actions, not coordinating multiple agents.
- Domain-specific workflow: Medium relevance. The method learns behavior in QA/search workflows; the core idea transfers to coding, but the action schema and retained fields must be redesigned for software work.
- Error prevention: Medium-high relevance. The paper exposes failure modes where ambiguity and hallucination get written into memory, which is directly useful for designing memory validation gates.
- Self-learning / memory: High relevance. MemAct is explicitly about learned working-memory management through SFT and RL, though it does not provide long-term user or project memory.
- Popular skills: Medium relevance. The `prune_context` action resembles a reusable skill: it defines when to prune, how to summarize, and what fields to preserve.

## Key Ideas

- Treat memory edits as first-class agent actions, not as invisible middleware.
- Make context records addressable by stable IDs so the agent can delete specific observations instead of relying on token positions or recency windows.
- Require a write-before-delete operation: summarize the essential facts and status before removing raw context.
- Preserve the memory action itself in the transcript so future reasoning can inspect the curated state.
- Split training trajectories at memory edits because deleting context invalidates naive append-only policy-gradient assumptions.
- Use trajectory-level rewards for memory segments when the value of a memory action is only visible through later task success.
- Let models discover different memory strategies by capacity. In the paper, 7B models prune more aggressively, while 14B models learn a mix of fine-grained and coarse-grained pruning.
- Evaluate context control with task outcomes, token cost, latency, and complexity scaling, not just summary quality.

## Ideas To Steal

- Build an audited `prune_context` or `curate_context` action for coding agents. Inputs should include target record IDs, a structured memory note, reason for deletion, and a risk level.
- Use a coding-specific memory schema: objective, user constraints, files touched, commands run, exact failing outputs, confirmed facts, open hypotheses, assumptions, risks, and next verification command.
- Store both raw and curated transcripts. The active context can be pruned, but the raw log must remain available for debugging, recovery, review, and hallucination audits.
- Make every large tool result addressable. Search results, command outputs, test logs, screenshots, diffs, and subagent reports should have stable IDs so pruning can be precise.
- Add write-before-delete validation. Reject memory actions that delete records without preserving exact error strings, file paths, command names, commit SHAs, line numbers, or unresolved assumptions when those are present.
- Separate facts from assumptions in memory notes. The paper's failure cases show why guesses written as status or facts can poison later reasoning.
- Track context curation as telemetry: deleted IDs, retained summary fields, token delta, reason, whether a later step needed the raw record again, and final task outcome.
- Evaluate policies against fixed schedules and no-prune baselines on coding tasks. Useful metrics are test pass rate, repeated-command rate, edit reversions, token cost, time to verified fix, and post-compaction recovery quality.
- Use model-driven pruning sparingly at meaningful boundaries: after a subtask finishes, after a tool result is superseded, after negative search paths are exhausted, or when context approaches a budget threshold.

## Do Not Copy

- Do not copy the full RL stack before proving a smaller rule-based or prompted memory-action harness fails. The repository assumes heavyweight distributed training infrastructure.
- Do not let the active-context deletion be the only copy. Coding agents need raw transcript recovery for safety, reproducibility, and review.
- Do not treat assumptions as durable facts. Memory writes should preserve uncertainty labels and require verification before final decisions.
- Do not use QA/search benchmarks as evidence that the method is safe for code editing. Software tasks need exact build output, diffs, and environment state.
- Do not prune system, developer, AGENTS, user constraints, permission decisions, destructive-operation rationale, or the most recent edit/test evidence.
- Do not rely on hidden IDs embedded in prose output. Use explicit metadata records so deletion is deterministic and inspectable.
- Do not assume lower active context always means lower total cost. Reconstructing context, breaking cache prefixes, or causing extra verification steps can erase savings.
- Do not import a vendored training framework into Agentic Coding Lab just to get the interface pattern. The valuable piece is the action contract and evaluation loop.

## Fit For Agentic Coding Lab

This paper is in-scope because Agentic Coding Lab is about improving agentic coding workflows above the base model/client. MemAct provides a clear design argument: context curation should be a visible, auditable action with its own inputs, outputs, and success criteria.

The most practical transfer is not end-to-end RL. It is a workflow artifact:

1. Assign stable IDs to context records.
2. Let the agent propose memory edits as explicit tool calls.
3. Validate the memory note against record type specific retention rules.
4. Keep a raw transcript and a deletion ledger.
5. Measure whether curated context improves long-run coding outcomes.

For a coding lab, the memory action should be conservative. It should aggressively compress low-risk, superseded logs and search results, while preserving exact commands, exact failures, user constraints, current diffs, and pending risks. The paper's best lesson is that memory is part of the action space; its warning is that a bad memory write can become a self-authored bug report that the agent later believes.

## Related Repositories

- https://github.com/ADaM-BJTU/MemAct - Official implementation, MIT licensed. Reviewed commit `eba053e0d02e779b658a2db110d8697f157022c1`; GitHub API showed 27 stars, 2 forks, 2 open issues, default branch `main`, and no releases on 2026-05-31. The repo includes DCPO configs/scripts, cold-start data, parquet datasets, a vendored `verl` tree, `mem_agent_loop.py`, `core_algos.py`, and the `prune_context` tool schema.
- https://anonymous.4open.science/r/MemAct-Anonymized-CBC3 - Anonymized code link listed on the OpenReview record. It returned `{"error":"not_connected"}` when fetched on 2026-05-31, so the public GitHub repository above was used as the code source.
- No dedicated Papers with Code page was found by live search for the exact paper title on 2026-05-31.

## Reviewed Sources

- arXiv abstract page: https://arxiv.org/abs/2510.12635
- arXiv PDF v3: https://arxiv.org/pdf/2510.12635
- OpenReview ACL ARR 2026 January submission: https://openreview.net/forum?id=ddGsiaISXg
- OpenReview PDF: https://openreview.net/pdf?id=ddGsiaISXg
- OpenAlex API work record: https://api.openalex.org/works/W4415270781
- Semantic Scholar public page: https://www.semanticscholar.org/paper/Memory-as-Action%3A-Autonomous-Context-Curation-for-Zhang-Shu/5f0f0c762c094bb6e1deba3222331ee51b98d1fc
- Semantic Scholar API attempted: https://api.semanticscholar.org/graph/v1/paper/arXiv:2510.12635
- Official code repository: https://github.com/ADaM-BJTU/MemAct
- GitHub API repository metadata: https://api.github.com/repos/ADaM-BJTU/MemAct
- Implementation files reviewed from official repository commit `eba053e0d02e779b658a2db110d8697f157022c1`: `README.md`, `DCPO/config/mem_search_tool_config_single.yaml`, `DCPO/config/mem_agent_loop_config.yaml`, `DCPO/scripts/run_dcpo_14B_single.sh`, `verl/experimental/agent_loop/mem_agent_loop.py`, `verl/trainer/ppo/core_algos.py`, and `verl/workers/reward_manager/mem_reward.py`.
