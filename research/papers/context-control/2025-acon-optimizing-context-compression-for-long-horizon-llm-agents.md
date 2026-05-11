# ACON: Optimizing Context Compression for Long-horizon LLM Agents

- URL: https://arxiv.org/abs/2510.00615
- Authors: Minki Kang, Wei-Ning Chen, Dongge Han, Huseyin A. Inan, Lukas Wutschitz, Yanzhi Chen, Robert Sim, Saravan Rajmohan
- Venue / source: arXiv preprint, with an OpenReview record as LLA 2026 Poster; a separate OpenReview record shows submission to ICLR 2026.
- Published: arXiv submitted 2025-10-01, v2 revised 2025-10-17; OpenReview LLA poster published 2026-03-02 and last modified 2026-04-10.
- Citations snapshot: 0 citations
- Citation source: OpenAlex work W4414808569, `cited_by_count=0`, captured 2026-05-11.
- Code: https://github.com/microsoft/acon
- Topic: context-control
- Reviewed at: 2026-05-11
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong validation candidate for context-control because it treats context compression as an optimizable agent subsystem, but direct adoption should be limited to failure-driven prompt/guideline loops and measured compression policies rather than assuming compression always lowers total cost.

## Problem

Long-horizon agents accumulate actions, observations, API outputs, and state across many steps. ACON's core claim is that this unbounded context creates two coupled failures: higher memory/token cost and degraded decisions from irrelevant or stale information. The paper argues that generic truncation, FIFO history windows, naive summarization, and retrieval are brittle because the agent must preserve heterogeneous state: IDs, credentials/tokens, tool preconditions, action outcomes, evolving environment state, and decision cues.

This is directly relevant to Agentic Coding Lab. Coding agents likewise need to preserve facts such as failing command output, file paths, dependency versions, test scope, user constraints, plan decisions, and unresolved risks across long sessions. Losing one of those facts can cause repeated commands, wrong edits, or unsafe reversions.

## Method

ACON has three pieces:

1. It compresses either interaction history or the latest observation with an LLM compressor. History compression runs only when history exceeds a threshold; observation compression runs only when an observation exceeds a threshold. The compressed content replaces raw context for later agent steps.
2. It optimizes the natural-language compression guideline instead of updating the main agent model. The utility step runs tasks with no compression and with compression, selects cases where full context succeeds but compressed context fails, then asks an optimizer LLM to identify what the compressed context lost. The resulting feedback is aggregated into updated compression guidelines.
3. It adds a compression step after utility optimization. For successful compressed trajectories, the optimizer identifies redundant spans and refines the guideline toward shorter outputs. The paper calls the reward-first step UT and the cost-focused refinement CO.

The method includes distillation: a large teacher compressor with the optimized guideline generates compressed outputs, and smaller models such as Qwen3-14B, Qwen3-8B, and Phi-4 are LoRA-trained on those input/output pairs. The student compressor then replaces the large compressor at inference time.

Implementation evidence matches the paper's structure. The GitHub repository exposes `HistoryOptimizer` and `ObservationOptimizer` modules under `src/productive_agents/ctxopt`, uses Jinja prompt templates, token thresholds such as `history_summarization_threshold` and `obs_summarization_threshold`, optional LLMLingua fallback compression, and benchmark-specific pipelines for AppWorld, OfficeBench, and 8-objective QA. The AppWorld README describes the same four-stage pipeline: baseline runs, guideline optimization, compressor LoRA distillation, and agent LoRA distillation.

## Evidence

The paper evaluates on AppWorld, OfficeBench, and 8-objective QA, all framed as multi-step agent settings. Metrics include task accuracy or EM/F1, average steps, peak input tokens, and cumulative dependency on prior tokens.

Main results:

- AppWorld with gpt-4.1: no compression scored 56.0 average accuracy with 9.93k peak tokens. ACON UTCO history compression scored 56.5 with 7.33k peak tokens. ACON UTCO observation compression scored 53.6 with 7.43k peak tokens.
- OfficeBench with gpt-4.1: no compression scored 76.84 with 7.27k peak tokens. ACON history UT scored 74.74 with 4.93k peak tokens; ACON observation UT scored 73.68 with 6.55k peak tokens.
- 8-objective QA with gpt-4.1: no compression scored 0.366 EM / 0.488 F1 with 10.35k peak tokens. ACON history UT scored 0.373 EM / 0.494 F1 with 4.71k peak tokens.
- Distilled compressors retained over 95% of teacher performance across reported benchmarks, according to the paper's summary.
- Small-agent result: Qwen3-14B improved from 26.8% to 33.9% on AppWorld, and from 0.158 to 0.197 EM on 8-objective QA when given ACON-compressed trajectories and compressors.

Ablations matter more than headline numbers for design. Moderate thresholds worked best: 4096 tokens for history and 1024 tokens for observation in the AppWorld ablation. Smaller thresholds compressed more often but hurt accuracy; larger thresholds preserved more raw context but saved less. The prompt-optimizer ablation found o3 with contrastive feedback strongest on AppWorld history compression, while removing contrastive feedback or switching optimizer models reduced accuracy.

Qualitative examples support the mechanism. In one AppWorld case, compressed history preserved the need to authenticate, carry the returned `access_token`, and pass it into file-system calls, preventing repeated 401 errors. In an observation-compression example, optimized compression preserved JSON structure and a needed `play_music` API that naive prompting omitted.

## Limits

ACON is not a free win. The paper explicitly notes that compressor calls can add cost and latency. History compression can also break KV-cache reuse, forcing recomputation of compressed histories. The authors report that observation compression is more likely to reduce API cost, while history compression can fail to help total cost despite reducing peak tokens.

Generalization is still limited. Most experiments use GPT models because of budget constraints. The paper says the framework is model-agnostic, but large-scale open-source models and other frontier models were not fully tested. The benchmarks are productivity and QA tasks, not software-engineering repair loops, so the evidence transfers by analogy rather than direct SWE-agent validation.

The optimization loop is expensive. It needs baseline successful trajectories, compressed failed trajectories, optimizer-model analysis, candidate prompt generation, and held-out evaluation. That is suitable for offline policy/guideline development, not for every user request. It also assumes enough successful full-context traces exist to identify what compression broke.

The method optimizes natural-language guidelines, so failures can come from prompt overfitting, optimizer-model bias, or brittle benchmark-specific rules. The best optimizer in the ablation was o3, which may not be available or cost-effective in all deployments.

## Research Themes

- Token efficiency: High relevance. The paper targets peak-token reduction and reports 26-54% peak-token savings, but warns that API/KV-cache cost may not fall with history compression.
- Context control: High relevance. It treats context as a managed subsystem with compression thresholds, summaries, observation filters, and reward/cost feedback.
- Sub-agent / multi-agent: Medium relevance. The compressor is a separate module from the acting agent, but the paper is not about collaborative multi-agent systems.
- Domain-specific workflow: High relevance. The optimized guidelines are task/environment-specific, which maps to coding-agent workflows with repo state, tests, and tool outputs.
- Error prevention: High relevance. The contrastive loop explicitly studies failures caused by missing/distorted context and turns them into summary rules.
- Self-learning / memory: Medium relevance. It learns compression guidelines offline from trajectories, but does not propose persistent user memory or online lifelong memory.
- Popular skills: Medium relevance. ACON supports a skill-like pattern: reusable compression guidelines that can be refined from failure audits.

## Key Ideas

- Optimize compression prompts using failures, not intuition. Compare full-context success against compressed-context failure to identify lost facts, distorted summaries, or missing state variables.
- Separate utility from cost. First recover task success, then ask what can be removed from successful compressed trajectories.
- Compress only when needed. Thresholds prevent paying compressor cost for short histories or observations.
- Treat observations separately from history. Large tool outputs may need structure-preserving filtering; accumulated history may need state and decision continuity.
- Distill compressor behavior after prompt optimization. A strong model can discover the guideline, while a smaller model can run it cheaply.
- Evaluate compression with task outcomes, not summary prettiness. A good summary is the one that preserves future action success under lower context cost.

## Ideas To Steal

- Add a "context regression" harness for Agentic Coding Lab. For each long coding task, save full-context traces and compressed traces; mark cases where the full trace succeeds and compressed trace fails. Use these pairs to update compression rules.
- Make summaries schema-aware. Preserve tables for file paths, edited files, commands run, failing tests, exact errors, env vars, user constraints, and unresolved decisions. Drop narrative once those fields are filled.
- Split compression policies by source. Use one policy for command/test output, another for tool observations/search results, and another for conversation history. Do not summarize all context with one generic prompt.
- Use a two-pass guideline update. Pass 1: recover missing facts from failures. Pass 2: remove redundant narrative from successful compressed traces while keeping exact commands, errors, and state.
- Gate compression by thresholds and risk. For coding agents, compress low-risk logs aggressively but preserve recent edits, failing test output, user instructions, and security/destructive-operation decisions longer.
- Track compression as a first-class artifact. Store the compressor prompt version, token counts, compressed fields, dropped fields, and downstream task result so regressions can be audited.
- Distill only after stable rules. First use a strong model to find robust coding-context rules; only then consider a cheaper local compressor or deterministic transformer around those rules.

## Do Not Copy

- Do not assume lower peak tokens means lower total cost. History compression can break cache reuse and add extra steps or compressor calls.
- Do not compress every turn. The paper's own threshold ablation shows over-compression can degrade accuracy.
- Do not adopt productivity-agent guidelines verbatim for coding. Coding needs exact preservation of commands, diffs, paths, failing assertions, stack traces, and user constraints.
- Do not trust compressed summaries without task-level regression tests. Summary faithfulness is insufficient if the next agent action fails.
- Do not depend on an expensive optimizer model for online operation. Use the optimization loop offline or on sampled traces.
- Do not overclaim model generality. Evidence is strongest for GPT-family agents and the tested benchmarks.
- Do not merge history and observation compression blindly. The appendix cost discussion suggests observation compression may be safer for cost than history compression.

## Fit For Agentic Coding Lab

ACON is in-scope because Agentic Coding Lab needs reliable context-control patterns for long coding sessions. The most valuable transfer is not the exact benchmark setup but the failure-driven compression lifecycle:

1. Capture full-context success traces and compressed-context failures.
2. Audit the first divergence and missing state.
3. Turn recurring failures into explicit compression rules.
4. Re-evaluate on held-out tasks.
5. Track both success and cost.

For coding agents, this should become a "compression contract" around working memory. Required retained fields should include current goal, user constraints, files touched, commands run, exact failing outputs, hypotheses tested, pending risks, and next actions. ACON supports the design argument that context compression should be validated like a behavior-changing component, not treated as harmless summarization.

## Related Repositories

- https://github.com/microsoft/acon - Official implementation. The repository is MIT licensed, had about 71 GitHub stars when reviewed, and includes `assets`, `configs`, `experiments`, and `src/productive_agents`. It provides benchmark runners, context optimizer modules, prompt templates, and distillation/training scripts.
- No dedicated Papers with Code page was found by live search for the exact paper title on 2026-05-11.

## Reviewed Sources

- arXiv abstract page: https://arxiv.org/abs/2510.00615
- arXiv PDF v2: https://arxiv.org/pdf/2510.00615
- OpenReview LLA 2026 poster: https://openreview.net/forum?id=x0alNh5o8v
- OpenReview ICLR 2026 submission record: https://openreview.net/forum?id=7JbSwX6bNL
- Hugging Face paper page: https://huggingface.co/papers/2510.00615
- OpenAlex API work record: https://api.openalex.org/works/W4414808569
- Official code repository: https://github.com/microsoft/acon
- Implementation files reviewed from the official repository: `src/productive_agents/ctxopt/base.py`, `src/productive_agents/ctxopt/history_optimizer.py`, `src/productive_agents/ctxopt/obs_optimizer.py`, `experiments/appworld/README.md`, `experiments/smolagents/README.md`, and `experiments/appworld/prompts/context_opt/prompt_history_v2.jinja`.
