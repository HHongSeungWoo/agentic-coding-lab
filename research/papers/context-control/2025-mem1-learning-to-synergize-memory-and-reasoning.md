# MEM1: Learning to Synergize Memory and Reasoning for Efficient Long-Horizon Agents

- URL: https://arxiv.org/abs/2506.15841
- Cite as: arXiv:2506.15841
- DOI: 10.48550/arXiv.2506.15841
- Authors: Zijian Zhou, Ao Qu, Zhaoxuan Wu, Sunghwan Kim, Alok Prakash, Daniela Rus, Jinhua Zhao, Bryan Kian Hsiang Low, Paul Pu Liang
- Venue / source: arXiv preprint v2, with OpenReview record accepted as ICLR 2026 Poster. The project README also reports COLM 2025 Workshop RAM2 oral and NeurIPS 2025 MTI-LLM Workshop oral presentations.
- Published: arXiv v1 submitted 2025-06-18; arXiv v2 revised 2025-07-17. OpenReview ICLR 2026 record has online date 2025-10-08.
- Citations snapshot: 0 citations
- Citation source: OpenAlex work W4417095241, `cited_by_count=0`, captured 2026-05-31. Semantic Scholar anonymous API returned HTTP 429 on 2026-05-31, so it was not used as the verified snapshot.
- Code: https://github.com/MIT-MI/MEM1, reviewed at commit `2609aef4e7c46d8d0c0f06b9312bc4b4abe04b9d`; project page: https://mit-mi.github.io/mem1-site/; released model: https://huggingface.co/Mem-Lab/Qwen2.5-7B-RL-RAG-Q2-EM-Release
- Topic: context-control
- Reviewed at: 2026-05-31
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong context-control paper because it turns memory pruning into a trained agent behavior instead of an ad hoc summarizer. For Agentic Coding Lab, the transferable value is the explicit working-state contract, outcome-level context regression, and long-horizon synthetic task construction, not the full RL training stack or free-form state as the only source of truth.

## Problem

Long-horizon agents often append every previous action, observation, and reasoning step to the prompt. MEM1 targets the resulting growth in memory use, inference cost, and degraded reasoning when the model sees input lengths outside the distribution it learned to handle.

The paper's specific setting is interactive agents that repeatedly query an environment, receive external information, and eventually answer interdependent objectives. That maps well to coding agents even though the paper does not evaluate software engineering directly. A coding session has the same pressure: the agent must retain user constraints, current files, failed commands, exact error text, hypotheses already tested, and pending decisions without carrying the entire transcript and every tool output forever.

The key problem framing is useful: context control should not be a passive compression filter. The acting model should learn or be forced to maintain a compact state that supports both memory and next-step reasoning.

## Method

MEM1 trains a Qwen2.5-7B base model with PPO to operate under a bounded rolling context. At each turn, the agent writes an internal state, then either emits a query/action or a final answer. If it queries the environment, the environment returns an information block. At the next turn, the agent must consolidate the previous internal state, action, and information into a new internal state; older state, action, and information are pruned from the live context.

The paper describes this with `<IS>`, `<query>`, `<info>`, and `<answer>` tags. The released code uses the same idea with `<think>`, `<search>`, `<information>`, and `<answer>` in the QA prompts. The implementation in `Mem1/gen_data/data_process/qa_search_train_merge_multi.py` explicitly tells the model that `<think>` is persistent memory and that only one question should be searched at a time.

Training has two important mechanics:

- Outcome rewards force useful memory. QA training uses exact match over final answers, and WebShop uses the environment reward. The appendix says intermediate format rewards were intentionally avoided because they sped up formatting but hurt final task performance.
- Masked trajectory reconstruction makes PPO compatible with pruned context. The rollout drops old context during generation, then training reconstructs the full trajectory with a 2D attention mask so tokens only attend to the context that would have been visible when they were generated. A separate info mask prevents gradients from being assigned to external information tokens.

The code matches these claims. `Mem1/train/rollout/llm_agent/generation_think.py` tracks per-turn state, prunes older observations via kept lengths, stores reconstruction fields, and composes final masked outputs. `Mem1/train/rollout/llm_agent/attn_mask_utils.py` builds the 4D attention mask and masks external information from the loss. `Mem1/train/train_ppo.sh` enables `actor_rollout_ref.actor.state_masking=true` and uses 6 turns for QA; `Mem1/train/train_ppo_webshop.sh` uses the same pattern with WebShop-specific rewards and 10 turns.

The paper also creates long-horizon data by composing existing QA datasets into multi-objective tasks. A model trained on 2-objective QA is tested on 3, 4, 6, 8, and 16 objectives, which directly probes whether the learned memory state generalizes beyond the training horizon.

## Evidence

The strongest evidence is the scaling curve on multi-objective QA. MEM1-QA is trained on 2-objective QA but tested up to 16 objectives. On 16-objective QA, MEM1-QA reports 1.97 EM count, 2.39 F1 count, 10.4 x 10^2 peak tokens, and 8.70 seconds per trajectory. Qwen2.5-14B-Instruct reports 0.567 EM, 0.703 F1, 38.4 x 10^2 peak tokens, and 29.7 seconds. The paper summarizes this as MEM1 using 27.1% of the peak tokens and 29.3% of the inference time of Qwen2.5-14B-Instruct in that setting.

The 8-objective result is also important because it is less dominated by total baseline collapse: MEM1-QA reports 1.87 EM and 2.31 F1 with 8.01 x 10^2 peak tokens, while Qwen2.5-14B-Instruct reports 1.55 EM and 1.87 F1 with 44.7 x 10^2 peak tokens. A-MEM keeps peak tokens lower than full context but is much slower in the table, which makes the cost of external memory retrieval visible.

WebShop supports the claim outside QA. MEM1-WebShop reports 70.87 average final reward, 0.81 x 10^3 peak tokens, 0.15 x 10^6 dependency, and 2.61 seconds per trajectory. AgentLM-13B reports 70.80 reward, 2.36 x 10^3 peak tokens, 0.30 x 10^6 dependency, and 5.23 seconds. AgentLM-7B reports lower reward, 63.60, with 2.24 x 10^3 peak tokens and 3.91 seconds.

Single-objective transfer is more mixed but still useful. On Wiki RAG, MEM1-QA is not the top accuracy model: it reports 0.405 EM and 0.471 F1, while Search-R1 reports 0.445 EM and 0.516 F1. MEM1-QA is more efficient: 5.63 x 10^2 peak tokens and 0.76 x 10^5 dependency versus Search-R1's 11.0 x 10^2 peak tokens and 1.50 x 10^5 dependency. On online Web-QA zero-shot transfer, MEM1-QA reports 0.397 EM and 0.485 F1, close to DeepResearcher's 0.372 EM and 0.492 F1, with lower peak tokens, dependency, and time.

Two ablations are especially relevant for lab practice:

- RL generalizes better than SFT. The appendix reports SFT collapse beyond 6 objectives, while RL remains robust through 16 objectives.
- Format reward is a trap. A format-constrained agent converged faster but reached 0.466 EM on 2-objective QA, below the 0.709 EM from outcome-only reward. It also produced shorter states, suggesting that syntax compliance can suppress useful memory exploration.

The implementation release is credible but research-oriented. The GitHub repository had 315 stars, MIT license, and 20 forks via GitHub API on 2026-05-31. It includes data processing scripts, retrieval launch scripts, rollout code, PPO training scripts, evaluation scripts, a demo JSONL, and a released Hugging Face checkpoint.

## Limits

MEM1 assumes tasks have verifiable rewards. The paper explicitly calls out that QA, math, and web navigation fit this assumption, while open-ended tasks have ambiguous or noisy rewards. Coding agents can often verify tests and builds, but many useful states, such as design intent or partial refactor quality, are not reducible to exact-match rewards.

The method is expensive to train and operationally heavy. The appendix reports training on 4 H100 or H200 GPUs and evaluation on a single H200 served with vLLM. That is not a lightweight context-control feature for a local coding assistant.

The evaluated domains are QA retrieval and WebShop, not software engineering. The transfer to Agentic Coding Lab is therefore architectural: state contracts, pruning discipline, and outcome-based evaluation. It is not direct evidence that MEM1 would preserve diffs, test failures, stack traces, or user constraints in a coding workflow.

The memory is free-form model text. That is flexible, but it has no hard guarantee that exact facts survive. For coding, losing a single path, command flag, failing assertion, security constraint, or user instruction can be more damaging than losing a general QA clue.

The policy optimization mask is a careful approximation, not a perfect reconstruction. Appendix A.7 says the attention matrix modification does not fully recover original trajectories because position IDs are not duplicated for each internal state; the authors choose the faster approximation.

The released inference helper has rough edges. In `Mem1/inference/data_pipelines.py`, `model_estimated_match` currently returns `1` after commented-out GPT judging code, so users should not treat every helper script as a production-quality evaluator. The core `eval.py` exact-match and F1 code is more relevant for reproduced metrics.

## Research Themes

- Token efficiency: High relevance. MEM1 targets near-constant peak context and reports large peak-token and dependency reductions on long-horizon tasks.
- Context control: Very high relevance. The paper makes pruning and state consolidation part of the agent loop and training objective.
- Sub-agent / multi-agent: Low relevance. MEM1 uses an environment and retrieval service, but it is a single-agent memory/reasoning method, not a multi-agent coordination system.
- Domain-specific workflow: High relevance. It depends on task prompts, reward functions, and environment-specific rollout rules; direct reuse requires coding-specific state schemas and verifiers.
- Error prevention: Medium relevance. Better memory reduces repeated or stale reasoning, but the paper does not provide a safety mechanism for verifying preserved facts.
- Self-learning / memory: High relevance. It trains the model to update a compact internal state and discard irrelevant information through outcome rewards.
- Popular skills: Medium relevance. The method suggests skill-like context contracts and evaluation loops, but it is a learned model policy rather than a static skill corpus.

## Key Ideas

- Treat working memory as an action. The agent must explicitly write the state it will rely on before choosing the next search/action.
- Prune by construction. Older context is removed after each turn, so the model cannot depend on accidental access to the whole transcript.
- Train memory with final outcomes. The state is good if later actions and final answers succeed, not if the summary looks faithful in isolation.
- Use composed tasks to stretch horizon length. Training on shorter composite tasks and testing on longer compositions reveals whether memory scales.
- Separate generated tokens from environment tokens during training. External observations should inform later actions but should not receive policy-gradient credit.
- Budget reminders matter. The hint about remaining turns is a small but practical control that helps a pruned-context agent decide when to stop searching.
- Masked replay bridges pruning and PPO. Training can reconstruct the trajectory for optimization while preserving the visibility constraints used at inference.

## Ideas To Steal

- Add a first-class "working state" contract to Agentic Coding Lab. It should preserve current objective, user constraints, files touched, commands run, exact failing outputs, hypotheses tested, risks, and next actions.
- Make state updates mandatory before risky or long-running actions. The MEM1 pattern says "write what matters, then act"; for coding this should happen before edits, destructive commands, dependency changes, and verification runs.
- Evaluate context control by task success, not summary aesthetics. Build regression tasks where a long coding session is compressed, resumed, and judged by whether the agent finishes with correct tests and no repeated mistakes.
- Compose small coding tasks into longer horizons. Chain independent bug fixes, refactors, test failures, and review comments into synthetic multi-objective sessions to test whether memory policies degrade gracefully.
- Include explicit remaining-budget and remaining-step fields in handoffs. MEM1's turn hint maps to coding-agent budgets such as token budget, tool budget, time budget, and verification scope.
- Keep generated state separate from external evidence. Store exact command outputs, diffs, and user instructions as evidence artifacts, then let the working state summarize references to those artifacts.
- Use outcome-only or verifier-weighted rewards carefully. The format-reward ablation argues against over-optimizing Markdown shape, XML tags, or checklist compliance when the real goal is completed work.
- Consider "masked replay" as an offline evaluation idea. Even without PPO, a lab harness can replay what context was visible at each step and identify whether a compression policy required unavailable facts.

## Do Not Copy

- Do not use a free-form internal state as the only durable memory for coding. Exact commands, diffs, logs, and user constraints need lossless storage or stable references.
- Do not assume learned pruning is safe without coding-specific regression tests. MEM1's evidence is strong for QA and WebShop, not for repository edits.
- Do not adopt the full RL stack unless there is a verifiable benchmark and real training budget. The paper's infrastructure is GPU-heavy and environment-specific.
- Do not reward format compliance as a proxy for quality. The paper's own ablation shows format reward can improve syntax while reducing final performance.
- Do not let the agent silently discard previous context. Agentic Coding Lab needs auditable state updates, state diffs, and recovery paths when compression drops critical evidence.
- Do not copy the QA prompt literally. Coding state should be structured around files, tests, commands, decisions, constraints, and risks rather than generic "summary and reasoning".
- Do not use `model_estimated_match` from the released inference helper as-is. The checked-in helper returns success unconditionally after commented-out judge code.
- Do not ignore ambiguous rewards. For design tasks, security reviews, and architecture choices, exact-match reward design will be weak or misleading.

## Fit For Agentic Coding Lab

MEM1 is in-scope for context-control because it gives a concrete pattern for bounded working memory in long interactive agents. Its practical value is not "train a MEM1 coding model now"; it is a design argument that context pruning should be a controlled behavior with a state contract and outcome-level evaluation.

The closest Agentic Coding Lab artifact is a "working-state memory protocol" for long coding sessions:

1. Before each major action, update a compact state with exact references to evidence.
2. Keep raw evidence outside the prompt but retrievable by stable IDs.
3. Prune narrative history aggressively only after required state fields are populated.
4. Resume from the state plus selected evidence, then verify task completion.
5. Run regression suites over compressed/resumed sessions to find lost-fact failures.

For coding agents, the state should be more typed than MEM1's free-form `<think>` block. Required fields should include user constraints, current plan, touched files, command history, exact failing output references, decisions made, open risks, and next verifier. MEM1 supports the principle that agents can operate under bounded context, but Agentic Coding Lab should implement that principle with auditable artifacts and deterministic retrieval before considering learned compression.

## Related Repositories

- https://github.com/MIT-MI/MEM1 - Official MIT-licensed implementation. Reviewed at commit `2609aef4e7c46d8d0c0f06b9312bc4b4abe04b9d`; GitHub API reported 315 stars, 20 forks, 8 open issues, Python as primary language, and last push on 2026-01-03 when captured on 2026-05-31.
- https://mit-mi.github.io/mem1-site/ - Official project page with architecture diagrams, result tables, demo/video section, and links to paper, code, and model.
- https://huggingface.co/Mem-Lab/Qwen2.5-7B-RL-RAG-Q2-EM-Release - Released Qwen2.5-7B checkpoint. Hugging Face API reported 92 downloads and 0 likes when captured on 2026-05-31.
- https://paperswithcode.com/author/ao-qu - Papers With Code author page listed the paper but reported no code implementation despite the official GitHub repository, so it was not used as primary code provenance.

## Reviewed Sources

- arXiv abstract page: https://arxiv.org/abs/2506.15841
- arXiv PDF v2: https://arxiv.org/pdf/2506.15841
- OpenReview ICLR 2026 record: https://openreview.net/forum?id=XY8AaxDSLb
- OpenReview API note record: https://api2.openreview.net/notes?id=XY8AaxDSLb
- Official project page: https://mit-mi.github.io/mem1-site/
- Official code repository: https://github.com/MIT-MI/MEM1
- GitHub API repository snapshot: https://api.github.com/repos/MIT-MI/MEM1
- OpenAlex API work record: https://api.openalex.org/works/W4417095241
- Hugging Face paper page: https://huggingface.co/papers/2506.15841
- Hugging Face released model API: https://huggingface.co/api/models/Mem-Lab/Qwen2.5-7B-RL-RAG-Q2-EM-Release
- Implementation files reviewed from the official repository: `README.md`, `Mem1/gen_data/data_process/qa_search_train_merge_multi.py`, `Mem1/inference/generate_rollout.py`, `Mem1/inference/data_pipelines.py`, `Mem1/inference/eval.py`, `Mem1/train/rollout/llm_agent/generation_think.py`, `Mem1/train/rollout/llm_agent/attn_mask_utils.py`, `Mem1/train/verl/utils/reward_score/qa_multiple.py`, `Mem1/train/train_ppo.sh`, and `Mem1/train/train_ppo_webshop.sh`.
