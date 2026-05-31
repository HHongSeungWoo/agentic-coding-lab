# Context as a Tool: Context Management for Long-Horizon SWE-Agents

- URL: https://arxiv.org/abs/2512.22087
- Cite as: arXiv:2512.22087
- DOI: 10.48550/arXiv.2512.22087
- Authors: Shukai Liu, Jian Yang, Bo Jiang, Yizhi Li, Jinyang Guo, Xianglong Liu, Bryan Dai
- Venue / source: arXiv preprint, cs.CL; public OpenReview record for ACL ARR 2026 January Submission 4936, modified 2026-03-20.
- Published: arXiv v1 submitted 2025-12-26; OpenReview submission posted 2026-01-05 and modified 2026-03-20.
- Citations snapshot: 6 citations on Semantic Scholar; 0 citations on OpenAlex
- Citation source: Semantic Scholar Corpus ID 284275525 shows 6 citations, captured 2026-05-31. OpenAlex work W7117557793 API reports `cited_by_count=0`, captured 2026-05-31, with OpenAlex record updated 2025-12-30.
- Code: No dedicated official CAT/SWE-Compressor implementation found. CatalyzeX shows only "Request Code"; IQuestLab/IQuest-Coder-V1 links the paper and provides related IQuest model/evaluation artifacts, not the CAT-GENERATOR training pipeline described in the paper.
- Topic: context-control
- Reviewed at: 2026-05-31
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong conceptual fit for Agentic Coding Lab because it turns context maintenance into an explicit agent action with a structured workspace and trajectory-level supervision. The practical pattern is worth stealing now, but the paper is not directly reproducible from public artifacts and should be treated as a design reference rather than an adoptable implementation.

## Problem

Long-horizon SWE agents accumulate issue text, file reads, shell output, edit attempts, test failures, hypotheses, and environment feedback across many turns. Standard ReAct-style agents usually keep an append-only transcript until the context window fills, or rely on external threshold compression after the fact. The paper argues that this causes three linked failures: context explosion, redundant or stale history dominating the prompt, and semantic drift where the agent loses track of the task state despite having many tokens available.

This maps directly to Agentic Coding Lab. Long coding sessions fail when old command output hides the current failure, summaries drop exact paths or test errors, or post-compact state no longer distinguishes user instructions from agent guesses. The paper's useful framing is that context management should not be a silent runtime cleanup policy; it should be part of the agent's own decision process and produce auditable state.

## Method

CAT, short for Context as a Tool, gives the agent a structured context workspace and a callable context-management action.

The workspace is represented as `C(t) = (Q, M(t), I^(k)(t))`:

- `Q` is the fixed, non-compressible segment: system prompt and key user intent.
- `M(t)` is long-term memory: a condensed summary of historical trajectories.
- `I^(k)(t)` is working memory: the most recent `k` ReAct interaction steps retained at high fidelity.

The key move is that context management is modeled at the same decision level as shell commands, file edits, and submit actions. The agent can invoke a context tool when a subtask finishes, the trajectory grows large, repeated failures suggest a strategy reset, or a concise memory block would serve future reasoning better than raw logs. The tool condenses the compressible historical segment into long-term memory while preserving the fixed segment and recent raw steps.

The training pipeline, CAT-GENERATOR, retrofits complete trajectories into supervised examples:

1. Generate base ReAct trajectories in a controlled SWE environment with context management disabled.
2. Identify condenser insertion points using context-growth signals, structural boundaries such as subtask completion or strategy changes, and error-recovery signals after repeated failures.
3. Segment context into fixed task content, compressible history, and recent working memory.
4. Generate a long-term memory block for the compressible history with a high-capacity model aligned to the agent backbone.
5. Stitch the context-tool action and its memory-block observation back into the original trajectory without changing the environment-action sequence.
6. Apply rejection sampling to discard failed trajectories, bad context-management behavior, semantic drift, or inconsistent internal state.

The resulting CAT-Instruct dataset is used to fine-tune SWE-Compressor from Qwen2.5-Coder-32B. At inference, the paper uses OpenHands with `execute_bash`, `str_replace_editor`, `submit`, and `context` tools, a 65,536-token training context length, temperature 0.0, and up to 500 interaction rounds for the main SWE-Bench Verified evaluation.

## Evidence

The paper evaluates on SWE-Bench Verified, the 500-instance human-validated subset of SWE-Bench. Training data comes from SWE-smith and SWE-ReBench, yielding 20k CAT-Instruct fine-tuning instances plus a separate 20k BASE-INSTRUCT set for baselines without context-management capabilities.

CAT-Instruct statistics are important because they describe the expected operating regime:

- Average trajectory length: 87.4 steps; median 77.5; max 500.
- Average tokens per step: 13,044; median 10,875; max 65,536.
- Context-management actions per trajectory: average 4.22; median 4; max 26.
- Average compression input/output: 15,585 tokens before compression to 4,676 after, about a 30% remaining-token ratio.

Main SWE-Bench Verified result:

- SWE-Compressor, 32B, OpenHands scaffold: 57.6 Pass@1.
- ReAct Agent baseline, same model scale/scaffold: 49.8 Pass@1.
- Threshold-Compression Agent baseline: 53.8 Pass@1.
- The paper positions SWE-Compressor as the strongest reported 32B post-trained SWE agent in its comparison table, though some much larger proprietary and open systems score higher.

The interaction-budget table gives the most actionable evidence:

- At 150 steps, CAT scores 54.8 with 1.89M tokens, ReAct scores 53.2 with 1.96M tokens, and Threshold-Compression scores 54.2 with 2.49M tokens.
- At 500 steps, CAT scores 57.8 with 2.75M tokens, ReAct drops to 48.8 with 2.54M tokens, and Threshold-Compression scores 53.8 with 5.18M tokens.
- CAT Base SFT without the full CAT-GENERATOR benefit reaches 55.0 at 500 steps but uses 5.07M tokens, suggesting that simply exposing a context action is not enough; trajectory-level supervision matters.

The paper also reports that CAT stabilizes active context after roughly 100 rounds, staying below about 32k tokens in one analysis and around 35k in the ReAct comparison figure. More than 40% of SWE-Bench Verified tasks remain interactive beyond 100 rounds, so the long-horizon case is not an edge case for this benchmark. Performance gains are larger on medium and hard tasks, which is the right shape of evidence for a context-control technique.

One caveat: the paper reports 57.6 as the headline solved rate in the abstract and Table 2, while Table 3 lists 57.8 for the 500-step CAT setting. I treat 57.6 as the canonical main result and note the 57.8 table value as a paper inconsistency rather than a separate claim.

## Limits

Reproducibility is the biggest limitation. I found no public CAT-GENERATOR code, no released CAT-Instruct data, and no clearly released SWE-Compressor checkpoint corresponding to the Qwen2.5-Coder-32B model in the paper. CatalyzeX has no linked code. The IQuestLab/IQuest-Coder-V1 repository stores the paper PDF and provides SWE-Bench Verified evaluation artifacts for IQuest models, but it does not expose the paper's offline condenser-point generation, stitched CAT trajectories, rejection sampling data, or SWE-Compressor training recipe.

The linked IQuest repo is adjacent rather than definitive. Its R2E-Gym-derived agent code includes LLM summarizing condensation triggered by context-length errors, and its OpenHands configuration exposes standard edit/bash/submit tools. That is useful corroborating ecosystem context, but it is not the same as the paper's first-class learned `context` tool policy.

The evaluation is narrow. SWE-Bench Verified is the right domain, but the method is not tested across multiple coding-agent scaffolds, multiple base models, or real user-interruption workflows. There is no released ablation for how large `k` should be, how often context calls are too frequent, what fields summaries drop, or whether summaries preserve exact commands and diffs under adversarial or flaky test output.

The training setup is expensive and offline. CAT-GENERATOR depends on complete trajectories, high-capacity summary generation, and rejection sampling. That is plausible for model post-training, but not a lightweight feature a local agent can copy without a trajectory corpus and evaluation harness.

The paper treats context-tool invocation as an internal model capability. For production coding agents, a host-owned context action may be safer: the runtime can enforce schemas, version summaries, keep raw evidence retrievable, and audit what was dropped. A learned policy alone is hard to trust when user constraints, destructive-operation decisions, or security-sensitive outputs are involved.

## Research Themes

- Token efficiency: High relevance. CAT reduces active context growth and, under 150-step budget, uses fewer total tokens than ReAct and Threshold-Compression; under 500 steps it spends slightly more than ReAct but gets much higher success.
- Context control: Very high relevance. The paper's core contribution is a structured context workspace plus explicit context-management action.
- Sub-agent / multi-agent: Low direct relevance. It uses separate generation/summarization roles offline, but the deployed agent is not a collaborative multi-agent system.
- Domain-specific workflow: Very high relevance. The method is built for SWE agents, OpenHands-style bash/edit/submit workflows, and SWE-Bench Verified tasks.
- Error prevention: High relevance. Compression points include error-recovery moments, and the memory block is meant to preserve failed strategies, environment state, and persistent constraints.
- Self-learning / memory: Medium relevance. CAT learns context-management behavior from offline trajectories; it is not an online lifelong memory system.
- Popular skills: Medium relevance. The structured workspace and context-action trigger rules translate well into skill instructions, compacting protocols, and agent harness rules.

## Key Ideas

- Make context management a first-class action, not a hidden threshold callback.
- Split context into immutable task semantics, durable long-term memory, and recent high-fidelity working memory.
- Insert memory updates at semantic boundaries such as completed subtasks, strategy shifts, and recovery after repeated failures.
- Train context behavior from full trajectories so the model sees how a summary affects later decisions.
- Treat the context-tool output as an observation in the trajectory, preserving the action/observation discipline of ReAct.
- Validate context control with task success and token curves, not with summary fluency alone.
- Keep recent raw steps uncompressed because exact local detail is still needed for edits and tests.

## Ideas To Steal

- Add an explicit `context` operation to Agentic Coding Lab workflows. It should produce a versioned memory block rather than silently rewriting the transcript.
- Use a three-zone context contract: fixed user/task instructions, durable summary state, and recent raw tool interactions.
- Make summary fields coding-specific: current goal, user constraints, files inspected, files edited, commands run, failing tests, exact error excerpts, hypotheses tried, rejected approaches, unresolved risks, and next actions.
- Trigger compaction on milestones, not only token pressure. Good triggers include "subtask done," "new failure mode discovered," "test failure understood," "plan changed," and "before resuming after interruption."
- Store context-action evidence. Each context update should record input token count, output token count, retained raw window, dropped range, summary schema version, and downstream verification result.
- Use rejection sampling as a harness pattern even without model training. Discard summaries that lose exact file paths, user constraints, command outputs, or pending verification.
- Build a context regression suite from real coding traces. Compare full-context success to compacted-context failure, then update summary rules from the first missing fact that caused divergence.
- Keep raw evidence recoverable. CAT's long-term memory can be compact, but Agentic Coding Lab should pair summaries with links to raw logs or transcripts so an agent can re-expand evidence when needed.

## Do Not Copy

- Do not depend on a learned context policy without host-side safeguards. The runtime should still own what can be dropped, retained, and reloaded.
- Do not assume a generic natural-language summary is enough for coding. Exact commands, paths, stack traces, assertion messages, dependency versions, and user constraints need structured preservation.
- Do not treat threshold compression as equivalent to CAT. The paper's own baseline shows threshold compression helps less and can use far more tokens at long horizons.
- Do not copy the offline training loop unless we have trajectories, a verifier, and budget. CAT-GENERATOR is a post-training pipeline, not a small prompt tweak.
- Do not claim reproducibility from current public artifacts. The public IQuest materials are useful but do not release the core CAT data/model pipeline.
- Do not compress recent edit/test context too aggressively. The method keeps the last `k` ReAct steps because local exactness matters.
- Do not optimize only for token count. The 500-step results show success can justify more total tokens than a failing append-only run.

## Fit For Agentic Coding Lab

This paper is in-scope and high-signal for Agentic Coding Lab because it offers a concrete design language for long-session coding context:

1. Context should be an explicit operation with an auditable output.
2. Working memory should have stable zones with different retention rules.
3. Compression timing should be tied to task semantics and recovery points, not just token limits.
4. Summary quality should be judged by later coding success.

The immediate practical implementation should be host-side rather than model-trained: define a `context_update` workflow artifact, require structured fields, keep a recent raw window, and attach provenance for every compaction. Over time, collected traces can support a CAT-GENERATOR-like harness: start from successful full-context sessions, inject proposed context updates, replay or manually audit downstream behavior, and reject memory blocks that cause wrong edits or repeated work.

For Agentic Coding Lab, the strongest adoption target is a "context ledger" for long coding tasks. Each entry would say what changed, why compaction happened, what exact facts were retained, what raw span was summarized, and what the next verification step is. That transfers CAT's core benefit without requiring a custom 32B model or unreleased training data.

## Related Repositories

- https://github.com/IQuestLab/IQuest-Coder-V1 - Adjacent IQuest project page linked from the IQuest Coder site and tagged on Hugging Face with `arxiv:2512.22087`. It includes the paper PDF, IQuest model links, an R2E-Gym-derived SWE-Bench Verified evaluation framework, and trajectory data for IQuest model evaluation. It does not appear to release CAT-GENERATOR or SWE-Compressor training artifacts.
- https://huggingface.co/models?other=arxiv%3A2512.22087 - Hugging Face model search lists IQuest-Coder-V1 models tagged with this arXiv ID. These are IQuest Coder family models with custom architecture/modeling code, not clearly the Qwen2.5-Coder-32B SWE-Compressor described in the paper.
- https://www.catalyzex.com/paper/context-as-a-tool-context-management-for-long - CatalyzeX page for the paper shows "Request Code," so no code link was available there at review time.
- https://github.com/All-Hands-AI/OpenHands - The paper evaluates through OpenHands and compares against an OpenHands threshold-compression baseline, but the paper-specific CAT training pipeline is separate from the general OpenHands scaffold.

## Reviewed Sources

- arXiv abstract page: https://arxiv.org/abs/2512.22087
- arXiv HTML full text: https://arxiv.org/html/2512.22087
- arXiv PDF v1: https://arxiv.org/pdf/2512.22087
- OpenReview record: https://openreview.net/forum?id=sN3CHd0MSW
- OpenReview PDF: https://openreview.net/pdf/123c1ad24196b1d41acd5e8c3212ea0250a71f70.pdf
- Semantic Scholar paper page: https://www.semanticscholar.org/paper/Context-as-a-Tool%3A-Context-Management-for-Liu-Yang/57faa6ba3ed69fdd957aec24d0fda3a943bc9bdc
- OpenAlex API work record: https://api.openalex.org/works/W7117557793
- IQuest Coder project page: https://iquestcoder.ai/
- IQuestLab/IQuest-Coder-V1 repository: https://github.com/IQuestLab/IQuest-Coder-V1
- IQuest repository files checked: `README.md`, `IQuest-Coder-Eval/SWE-Verified/R2E-Gym/README.md`, `IQuest-Coder-Eval/SWE-Verified/R2E-Gym/benchmark/bench/loopcoder/loopcoder.sh`, `IQuest-Coder-Eval/SWE-Verified/R2E-Gym/src/r2egym/agenthub/agent/agent.py`, `IQuest-Coder-Eval/SWE-Verified/R2E-Gym/src/r2egym/agenthub/tools/__init__.py`, and `IQuest-Coder-Eval/SWE-Verified/R2E-Gym/src/r2egym/agenthub/config/openhands/edit_fn_calling.yaml`.
- Hugging Face model search for `arxiv:2512.22087`: https://huggingface.co/models?other=arxiv%3A2512.22087
- Hugging Face API record for `IQuestLab/IQuest-Coder-V1-40B-Instruct`: https://huggingface.co/api/models/IQuestLab/IQuest-Coder-V1-40B-Instruct
- CatalyzeX paper/code page: https://www.catalyzex.com/paper/context-as-a-tool-context-management-for-long
