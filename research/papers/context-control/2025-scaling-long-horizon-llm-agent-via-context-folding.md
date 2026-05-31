# Scaling Long-Horizon LLM Agent via Context-Folding

- URL: https://arxiv.org/abs/2510.11967
- Cite as: arXiv:2510.11967
- DOI: 10.48550/arXiv.2510.11967
- Authors: Weiwei Sun, Miao Lu, Zhan Ling, Kang Liu, Xuesong Yao, Yiming Yang, Jiecao Chen
- Venue / source: arXiv preprint; official project page and GitHub repository are linked from the paper. The GitHub repository labels the work as ICML'26, but the arXiv/project citation still lists it as an arXiv preprint.
- Published: arXiv submitted 2025-10-13; paper PDF dated 2025-10-15.
- Citations snapshot: OpenAlex: 0 citations. Semantic Scholar: public page/search preview showed 33 citations, but the live Semantic Scholar Graph API returned HTTP 429 during review, so OpenAlex is the canonical snapshot here.
- Citation source: OpenAlex work W4415257590, `cited_by_count=0`, captured 2026-05-31; Semantic Scholar CorpusID 282064490 / arXiv lookup attempted 2026-05-31 and rate-limited.
- Code: https://github.com/sunnweiwei/FoldAgent
- Topic: context-control
- Reviewed at: 2026-05-31
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong context-control candidate. The paper's useful idea is not generic summarization, but explicit branch/return boundaries that let a long-running agent move exploratory work out of active context and reinsert only a task-relevant return message. Agentic Coding Lab should steal the host-enforced folding contract and metrics, while avoiding the heavy RL machinery unless there is a dedicated trace-and-reward training program.

## Problem

Long-horizon agents grow context linearly as they accumulate reasoning, tool calls, observations, file edits, searches, and test output. The paper argues that this creates two failures: performance drops when important facts are buried in long context, and efficiency drops because attention and KV-cache management become expensive. Its critique of post-hoc summarization is especially relevant: summarizing only when the window fills can interrupt the agent's working state and erase the reasoning path at an arbitrary point.

For coding agents, this maps directly to repeated repo exploration, long test logs, failed hypotheses, search results, and multi-step edit/test cycles. The hard part is not just shortening tokens. It is preserving the facts that determine the next safe action: issue constraints, files inspected, exact commands, failing assertions, edits already made, sandbox state, and unresolved risks.

## Method

Context-Folding adds two agent-callable context-management actions:

1. `branch(description, prompt)` creates a temporary sub-trajectory for a localized subtask.
2. `return(message)` ends that branch, folds away the intermediate action/observation sequence, and appends only the returned outcome to the main thread.

The context manager `F` therefore keeps the main thread compact while retaining the branch result. The paper frames this as a plan-execution loop: the main thread handles high-level decomposition and synthesis, while branches handle token-intensive execution such as web search or codebase exploration. Nested branching is disabled in the described instantiation, which keeps the structure simpler and bounds runaway delegation.

FoldGRPO trains this behavior end to end. It applies GRPO over folded contexts and adds token-level process rewards:

- Unfolded token penalty: once the main thread exceeds 50% of the working context limit, non-branch/non-finish main-thread tokens get a -1 penalty.
- Out-of-scope penalty: a GPT-5-nano judge compares branch prompt and returned message; out-of-scope branches receive -0.2 over branch tokens.
- Failure penalty: failed tool-call turns receive -1.

The implementation evidence matches the paper's scaffold. The public `sunnweiwei/FoldAgent` repository exposes `branch` and `return` tools, `workflow=search_branch` and `workflow=code_branch` modes, a `process_item` loop that creates branch agents from main history and appends only the returned branch message to main, a scope judge in `agents/verifier.py`, and training config using `algorithm.adv_estimator=foldgrpo`, `max_session=10`, `branch_len=32768`, and `process_reward='[flat,scope]'`. The README explicitly says the public repo is an open-source reimplementation based on `agent_loop` in verl and may differ from the paper's original training code.

## Evidence

The paper evaluates on two long-horizon task families:

- BrowseComp-Plus: 680 training instances and 150 evaluation instances, split into easy/medium/hard groups of 50 each. Tools are `search(query, topk)` and `open_page(url)`.
- SWE-Bench Verified: 500 evaluation instances. Training data is collected from SWE-Gym and SWE-Rebench rollouts, filtered to 740 instances with nontrivial success rates. Tools are `execute_bash`, `str_replace_editor`, and `think`, with reward from instance-specific sandbox unit tests.

Main results use Seed-OSS-36B-Instruct with a 32K active context and up to 10 branches, giving a theoretical 327K effective horizon:

- BrowseComp-Plus: Folding Agent + RL (FoldGRPO) scores 0.620 pass@1, compared with 0.478 for 327K ReAct Seed-OSS-36B, 0.540 for 327K ReAct + GRPO, 0.527 for Summary Agent + GRPO, and 0.640 for GPT-4.1 ReAct at 327K.
- SWE-Bench Verified: Folding Agent + RL (FoldGRPO) scores 0.580 pass@1, compared with 0.552 for 327K ReAct Seed-OSS-36B, 0.574 for 327K ReAct + GRPO, 0.550 for Summary Agent + GRPO, and 0.486 for GPT-4.1 ReAct at 327K.
- The paper reports absolute improvements from RL of +20.0 points on BrowseComp-Plus and +8.8 points on SWE-Bench Verified for the folding agent.

The behavior ablation is more useful than the headline accuracy. On BrowseComp-Plus, FoldGRPO improves finish rate from 0.806 to 0.935, reduces main trajectory length from 12,195 to 7,752 tokens, raises scope accuracy from 0.774 to 0.895, and increases average branch count from 3.51 to 4.98. On SWE-Bench Verified, FoldGRPO improves finish rate from 0.781 to 0.962, reduces main length from 47,475 to 8,885 tokens, raises scope from 0.473 to 0.754, and increases branches from 3.05 to 5.90.

The case study is directly illustrative: four BrowseComp-Plus branches fold a 107K-token full trajectory into a 6,524-token active context while preserving the final answer path. A complexity experiment combines up to 50 easy questions; although trained with at most 10 branches, the agent uses an average of 32.6 branches in that harder setting, suggesting some length generalization. A parallel-branch variant reaches 0.6133 pass@1 on BrowseComp-Plus, roughly comparable to the single-branch agent rather than clearly better.

The official project page repeats the key table and links the code. The GitHub repository, reviewed at commit `58a2d6964ecebe99940529eace50a0558901b8a5`, had 161 stars, 11 forks, Apache-2.0 license, and no releases when reviewed.

## Limits

The strongest limitation is reproducibility. The public code is useful, but the README says it may differ from the training code used in the paper. The repo also does not ship an obvious ready-to-use trained model release, and reproducing the results requires large RL infrastructure, a search server, BrowseComp-Plus data, Modal/SWE sandboxes, and model/API access.

The evidence is also entangled with prompt engineering. The paper says its BrowseComp-Plus prompt gets 0.478 accuracy with Seed-OSS-36B while the default BrowseComp-Plus prompt is around 0.08. That means the reported gains combine context folding, RL, task prompt design, tool setup, and data choices.

The out-of-scope reward depends on GPT-5-nano as a judge. That is pragmatic but not deterministic, locally reproducible, or obviously aligned with software-engineering safety requirements. A coding-lab version should not make branch-scope enforcement depend only on an LLM classifier.

Folding can permanently hide evidence. Once a branch returns, the main thread sees only the return message, so omitted file paths, command outputs, patches, or test failures are lost unless the host stores branch transcripts externally. This is riskier in coding than in many web-search tasks because exact low-level facts often determine correctness.

The paper's best-performing setup is sequential and depth-first. Nested branches are disabled, and the parallel-branch experiment did not beat the single-branch result. Multi-layer folding is named as future work, not demonstrated.

## Research Themes

- Token efficiency: High relevance. The system keeps active context around 32K while allowing roughly 327K total branch budget, and Table 2 shows more than 90% main-context reduction in the strongest setting.
- Context control: Very high relevance. It makes context management an explicit action space with branch, return, folded history, active-context budget, and scope metrics.
- Sub-agent / multi-agent: High relevance, but sequential. Branches are created on demand and share the main prefix; this is closer to host-managed subtrajectories than parallel specialist agents.
- Domain-specific workflow: High relevance. The paper includes an agentic coding workflow derived from OpenHands and evaluates on SWE-Bench Verified.
- Error prevention: High relevance. The process rewards penalize invalid tool calls, overly long main-thread work, and out-of-scope branch behavior.
- Self-learning / memory: Medium relevance. FoldGRPO learns a context-management policy offline, but it is not a persistent user/repo memory system.
- Popular skills: High relevance. The branch/return protocol is directly translatable into skill-like task envelopes, delegation contracts, and compression/return schemas.

## Key Ideas

- Context should be folded at meaningful subtask boundaries, not only when the window overflows.
- Branches let the agent spend many tokens on exploration while the main thread keeps a compact decision ledger.
- The return message is a context contract. Its quality determines whether folded work remains useful.
- Context-control behavior needs incentives. Outcome reward alone led to weaker finish rate, longer main trajectories, and worse scope control than FoldGRPO.
- Scope is a first-class metric. The paper measures whether branches stay on assignment, not only whether the final answer is correct.
- Folding can be KV-cache friendly because returning rolls context back to the branch point and appends a compact result.
- The same pattern applies to research and coding: main plans and synthesizes; branches perform bounded evidence gathering, implementation, or verification.

## Ideas To Steal

- Add a host-level `branch -> return` context contract for long coding sessions. Use it for bounded exploration, test reproduction, implementation, verification, and source-review passes.
- Treat the main context as a compact task ledger: current goal, constraints, files touched, branch returns, risks, final verification state. Keep raw branch transcripts outside active context but addressable.
- Require structured branch returns for coding: objective, files read, files changed, exact commands run, exact failing/passing outputs, hypotheses rejected, remaining risks, and recommended next action.
- Add scope gates for branches. A branch assigned "inspect failing test" should not silently edit production code; a branch assigned "implement fix" should report exactly what it changed.
- Track metrics from the paper in local harnesses: active main tokens, full transcript tokens, branch count, scope violations, invalid tool calls, finish status, verification pass/fail, and post-fold regressions.
- Use process-reward analogues as deterministic host rules before attempting learned policy: warn or block token-heavy main-thread exploration, invalid tool calls, missing return fields, and branch work outside its declared scope.
- Make branch summaries cite durable artifacts. A returned claim should include file paths, command IDs/log paths, commit/diff references, or source URLs so the main agent can reopen evidence without expanding the whole branch transcript.
- Evaluate folding against simple baselines: no folding, periodic summary, manual plan/checklist, and folding with typed returns. The paper's value is in the ablation discipline as much as the mechanism.

## Do Not Copy

- Do not depend on RL as the first implementation. Agentic Coding Lab can get most practical value from host-enforced branch boundaries, typed return schemas, and metrics before training a policy.
- Do not discard branch transcripts. Fold them out of active context, but keep them retrievable for audits, regressions, and final review.
- Do not trust free-form `return(message)` for coding. A vague branch return can lose exact tests, file paths, stack traces, or user constraints.
- Do not use a proprietary LLM judge as the only branch-scope control. Prefer deterministic ownership rules, file-claim checks, command logs, and optional LLM review as a secondary signal.
- Do not assume parallel branching is automatically better. The paper's parallel experiment read more pages but did not clearly improve pass@1.
- Do not let branch count become unbounded without budgets. The combined-question experiment shows adaptive use of 32.6 branches on average, which is promising but needs cost and wall-clock limits.
- Do not equate "folded away" with "irrelevant." Coding branches often produce evidence that must survive as exact artifacts rather than prose.

## Fit For Agentic Coding Lab

This paper is in-scope for `context-control` because it gives a concrete mechanism for bounded active context in long software-engineering sessions. The immediate adoption path should be a runtime/workflow pattern, not model training:

1. Main agent owns planning, user constraints, risk tracking, and final synthesis.
2. Branches receive narrow prompts with explicit return requirements and allowed file/tool scope.
3. Branch transcripts, diffs, logs, and evidence are persisted outside active context.
4. Main receives compact typed returns and can reopen evidence by ID/path when needed.
5. Verification checks compare final state against branch returns and user constraints.

The most valuable Agentic Coding Lab artifact would be a "folded branch contract" for Codex-like runs: a Markdown/JSON return schema, command-log references, file-claim policy, branch scope checker, and metrics report. FoldGRPO is a useful north star for future training/eval, but the host-side contract is the practical near-term win.

## Related Repositories

- https://github.com/sunnweiwei/FoldAgent - Official linked implementation. Reviewed commit `58a2d6964ecebe99940529eace50a0558901b8a5`; Apache-2.0; 161 stars and 11 forks via GitHub API captured 2026-05-31. It includes `agents/fold_agent.py`, `agents/tool_spec.py`, `agents/prompts.py`, `agents/verifier.py`, `scripts/train_fold.py`, BrowseComp/SWE evaluation scripts, and a vendored/modified `verl` tree. The README warns it is an open-source reimplementation and may differ from the paper's original training code.
- https://context-folding.github.io/ - Official project page with paper, code, case-study PDF link, result table, and citation snippet.
- https://huggingface.co/papers/2510.11967 - Hugging Face paper page linking arXiv, PDF, project page, and GitHub; useful for community metadata but not used as the citation-count authority.

## Reviewed Sources

- arXiv abstract page: https://arxiv.org/abs/2510.11967
- arXiv PDF v1: https://arxiv.org/pdf/2510.11967
- Official project page: https://context-folding.github.io/
- Official code repository: https://github.com/sunnweiwei/FoldAgent
- GitHub API repository record: https://api.github.com/repos/sunnweiwei/FoldAgent
- OpenAlex API work record: https://api.openalex.org/works/W4415257590
- Semantic Scholar public paper page / CorpusID 282064490: https://www.semanticscholar.org/paper/Scaling-Long-Horizon-LLM-Agent-via-Context-Folding-Sun-Lu/6ca29e9438224626cafa50f121c22244f35575c0
- Semantic Scholar Graph API attempts: `arXiv:2510.11967` and `CorpusId:282064490`, both returned HTTP 429 on 2026-05-31.
- Hugging Face paper page: https://huggingface.co/papers/2510.11967
- Implementation files reviewed from commit `58a2d6964ecebe99940529eace50a0558901b8a5`: `README.md`, `agents/fold_agent.py`, `agents/tool_spec.py`, `agents/prompts.py`, `agents/verifier.py`, `scripts/train_bc_qwen3_8b.sh`, `scripts/eval_bc.py`, and `scripts/eval_swe.py`.
