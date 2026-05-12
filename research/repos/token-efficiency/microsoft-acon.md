# microsoft/acon

- URL: https://github.com/microsoft/acon
- Category: token-efficiency
- Stars snapshot: 71 (GitHub REST API `stargazers_count`, captured 2026-05-12)
- Reviewed commit: d63f9ae18959dc7215ff62899c94c5e8c56847ae
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong research implementation for failure-driven agent context compression. Best adoption target is the offline regression loop and thresholded memory-manager pattern, not the repo as a drop-in runtime because budget accounting, sandboxing, wiring, and tests are still research-grade.

## Why It Matters

ACON is the official implementation for "ACON: Optimizing Context Compression for Long-horizon LLM Agents." It targets the same failure mode Agentic Coding Lab needs to handle: long agent runs accumulate tool outputs, failed attempts, partial state, and user constraints until prompts become expensive or brittle.

The practical value is the way it treats context compression as a behavior-changing subsystem. It compares full-context success against compressed-context failure, asks an auditor model what was lost or distorted, updates compression prompts, then re-runs benchmarks. That maps cleanly to coding-agent traces where losing an exact command, error, file path, or user constraint can cause repeated work or unsafe edits.

## What It Is

`acon` is a Python research framework named `productive-agents`. It includes benchmark agents and environments for AppWorld, OfficeBench, and 8-objective QA via smolagents; context optimizers for history and observation compression; prompt-optimization scripts; token/cost analysis utilities; and LoRA distillation scripts for local compressor or agent models.

The core runtime is not a separate service. It is a memory layer inside the agent loop. Config files choose `type: history`, `type: obs`, or `type: unified`; threshold fields decide when compression runs; and prompt directories provide Jinja templates used by the compressor LLM.

## Research Themes

- Token efficiency: High. It directly reduces history and observation size with thresholds, preserved recent turns, LLMLingua/retrieval/discard baselines, token counting, and cache-aware post-run analysis.
- Context control: High. `MemoryManager` rewrites the active conversation by starting new sessions with `<HISTORY_SUMMARY>` and preserved recent turns, or replaces long observations before the next agent step.
- Sub-agent / multi-agent: Medium. The compressor is a separate model role from the acting agent, but the repo does not implement collaborative multi-agent coding workflows.
- Domain-specific workflow: High. Compression prompts are benchmark-specific and optimized from benchmark failures, which supports coding-specific compression contracts rather than generic summaries.
- Error prevention: High. The prompt optimizer searches for missing facts, lost variables, summary inaccuracies, API/action mistakes, and first divergence points.
- Self-learning / memory: Medium. It learns compression guidelines offline from trajectories; it does not implement persistent user/project memory.
- Popular skills: Medium. The learned prompt guideline resembles a reusable skill for compressing agent traces.

## Core Execution Path

AppWorld path:

1. `experiments/appworld/run_all.py` loads a `co_config_path`, builds per-task config, optionally creates a local vLLM compressor, and calls `experiments/appworld/run.py`.
2. `run.py` creates `AppWorldEnv`, resets a task, creates `AppWorldAgent`, then calls `agent.run`.
3. `UnifiedAgent.run` builds a user prompt from the environment, appends it to `MemoryManager`, optionally calls `optimize_history`, sends the current session to the acting LLM, executes the extracted action in the environment, logs the assistant response, then optionally calls `optimize_observation` on the new observation.
4. History compression summarizes older conversation messages before the acting LLM call. Observation compression rewrites the latest environment output after tool execution and stores the refined text as `env.observation`.
5. Histories are dumped as `llm_history.json`, `history_optimizer_history.json`, `obs_optimizer_history.json`, `step_alignment.json`, and benchmark-specific trajectories. Runners summarize success and main-agent token usage.

Prompt optimization path:

1. Run baseline and compressed experiments.
2. `experiments/prompt_optimizer/unified_update_history_prompt.py` or `unified_update_observation_prompt.py` finds tasks where baseline succeeded but compression failed, renders baseline and optimized histories, and asks an auditor model for structured JSON root-cause analysis.
3. Aggregated failures are sampled into an optimizer prompt to generate improved `.jinja` compressor prompts.
4. `run_ctxopt_pipeline.py` turns prompt variants into YAML configs, runs benchmark evals, and copies the best config.
5. `unified_compress_update_*` scripts analyze successful compressed traces to shorten prompts further, giving the paper's cost-optimization pass.

Distillation path:

1. `experiments/training/save_trajectories_dataset.py` exports successful optimizer or agent histories into JSONL chat conversations.
2. `finetune_sft_unsloth.py` LoRA-trains Qwen/Phi models on assistant responses only.
3. `serve_llm.py` serves models through vLLM's OpenAI-compatible API.
4. Runtime configs can use `model_type: local` and `lora_name` to replace the frontier compressor with a local model.

## Architecture

The repo has four main layers:

- Agent layer: `UnifiedAgent` coordinates prompt building, acting LLM calls, action extraction, memory updates, environment stepping, and history dumping. AppWorld, OfficeBench, and smolagents specialize prompt and action parsing.
- Memory/context layer: `MemoryManager` owns session histories, preserved recent turns, previous summary, optimization thresholds, and context optimizer instances.
- Optimizer layer: `HistoryOptimizer`, `ObservationOptimizer`, and `HistoryRetriever` implement LLM compression, LLMLingua fallback via local HTTP service, and embedding retrieval baseline.
- Experiment layer: benchmark runners, prompt-optimizer scripts, token analysis, evaluation, and training scripts orchestrate offline improvement loops.

There is no MCP boundary and no direct coding-agent integration. The transferable artifact is the pattern: configure compression by source, capture traces, audit compression regressions, and evaluate prompt variants against task success and token metrics.

## Design Choices

History compression starts only when the older conversation text plus prior summary exceeds `history_summarization_threshold`, unless the threshold is `-1`. AppWorld configs use 4096 tokens; smolagents configs use 2048. Recent turns are preserved with `preserve_last_k_turns`, usually `1`, so the next action still sees immediate action/observation continuity.

When history is compressed, `MemoryManager` starts a new session, re-adds the system prompt, injects the original first user prompt plus `<HISTORY_SUMMARY>`, then appends preserved recent assistant/user turns. `history_summary_rule: reset` replaces the summary from the original task prompt; `accumulate` appends the new summary to the current first user prompt.

Observation compression is separate. It only sees the current observation, task, and current session history text, and runs after an environment step. If token count is below `obs_summarization_threshold`, it returns the raw observation. AppWorld's checked-in observation config uses 256 tokens, while pipeline generators use 1024 for AppWorld and 400 for smolagents.

The prompt optimizer is contrastive rather than subjective. It searches for baseline success and optimized failure, then asks for missing/distorted facts, lost state variables, summary inaccuracies, inefficiency patterns, and remediation. That is the repo's strongest design choice.

Baselines are explicit: discard older turns, retrieve similar turns with embeddings, or use LLMLingua through `http://localhost:9999/compress`. This makes ACON useful as a comparison harness, not just a single summarization prompt.

Budget controls are partial. Runtime thresholds, max iterations, output truncation in smolagents, token/cost logging, and cache-aware analysis exist. But main run summaries mostly count the acting LLM; optimizer call cost is analyzed later from dumped histories, so live budget enforcement is not first-class.

Safety controls are benchmark-dependent. AppWorld relies on upstream AppWorld execution. Smolagents uses `LocalPythonExecutor` with restricted imports and final-answer tooling. OfficeBench uses a local workdir and 30-second command timeout, but its shell app still executes shell commands through `/bin/bash -c`, so it is not a hardened sandbox.

## Strengths

- Clean separation between history compression and observation compression, which matches coding-agent needs for different policies over chat history, command output, search results, and file diffs.
- Failure-driven prompt improvement loop with concrete regression artifacts rather than hand-written "make a good summary" instructions.
- Recent-turn preservation and thresholding avoid compressing every step.
- Prompt variant generation plus benchmark reruns supports empirical selection.
- Logs align agent history, optimizer history, environment history, token usage, and evaluation summaries, which makes compression failures auditable.
- Distillation path turns expensive optimized compressor behavior into local LoRA datasets and served models.
- Cache-aware analysis utilities recognize that lower peak context does not automatically mean lower total cost.

## Weaknesses

- No real unit test suite was found. `pyproject.toml` defines pytest options, but repository validation is mostly benchmark/evaluation scripts.
- `history_version` and `obs_version` are read in `MemoryManager` but do not select `HistoryOptimizerV2` or `ObservationOptimizerV2`; the V2 cache-preserving classes appear effectively unwired through normal config.
- Runtime token/cost summaries focus on the acting LLM, while optimizer costs require separate analysis. That can make a run look cheaper than it is.
- Pricing tables are inconsistent between `src/productive_agents/llm.py` and `experiments/analysis_tools/utils.py`; `llm.py` also falls back to a missing `gpt-4o` pricing entry for unknown models.
- OfficeBench shell execution is not strongly sandboxed. It has a timeout, action parsing, and local workdir copying, but no permission gate or OS-level isolation.
- Some integrations are brittle research code: Gemini import is commented out while the class uses `genai`; comments and config paths contain stale project references; LLMLingua assumes a localhost service; several scripts use hard-coded benchmark output conventions.
- Compression prompts are generic for productivity agents. They do not preserve coding-specific facts such as exact diff hunks, failing test commands, stack traces, file ownership boundaries, or user safety constraints.

## Ideas To Steal

- Build a context regression harness for coding traces. Save full-context successful runs and compressed failed runs, then audit first divergence and missing state before changing compression rules.
- Split compression by source: command/test output, repository search results, long file reads, conversation history, and web/doc observations should each have separate thresholds and schemas.
- Preserve a fixed coding state table across history compression: user goal, explicit constraints, files touched, commands run, exact failures, current hypothesis, rejected hypotheses, pending edits, and next verification step.
- Keep recent raw turns around summaries. ACON's `preserve_last_k_turns` is simple and valuable for preventing summaries from erasing immediate tool feedback.
- Optimize for utility before cost. First recover failures caused by missing context; only then shorten successful compressed traces.
- Store compressor prompt version, threshold, summary output, raw token counts, preserved turn count, and downstream result. Compression should be debuggable like any other behavior-changing component.
- Add cache-aware token accounting when evaluating compression. History rewriting can destroy prompt-prefix reuse even when peak prompt size falls.

## Do Not Copy

- Do not adopt one generic "Reasoning / Completed" summary for coding. Use exact fields and lossless snippets for commands, errors, paths, and diffs.
- Do not count only main-agent tokens when claiming savings. Compressor calls, retries, local serving cost, and cache loss must be included.
- Do not wire compression to every turn by default. The threshold and interval checks are essential.
- Do not rely on LLM summaries without regression tests. The repo's own optimization loop assumes compression can cause task failure.
- Do not copy OfficeBench shell execution into a coding agent without a stronger sandbox, permission model, and destructive-command controls.
- Do not depend on unavailable local services such as LLMLingua or vLLM without capability checks and fallback behavior.
- Do not keep dead config knobs. If a version field exists, it should select the intended compressor implementation.

## Fit For Agentic Coding Lab

ACON is a good pattern source for token-efficiency and context-control work in Agentic Coding Lab. The most valuable pieces are not benchmark-specific agents, but the lifecycle:

1. Add thresholded compression in the memory layer, separate from the acting agent.
2. Keep the last raw turns and a structured summary.
3. Evaluate on task outcomes, not summary beauty.
4. Use compressed-failure versus full-success diffs to update compression rules.
5. Track both utility and real cost, including cache effects.

For coding agents, this should become a compression contract over execution memory. A compressed history must preserve exact user instructions, current repo/worktree state, file paths, commands and outputs, failed test assertions, environment constraints, risky operations, and unresolved questions. ACON supports that design argument with working research code, but the repo would need tighter tests, accounting, sandboxing, and schema-specific prompts before production adoption.

## Reviewed Paths

- `README.md`, `pyproject.toml`, `configs/private_config_dummy.yaml`
- `experiments/appworld/README.md`, `experiments/officebench/README.md`, `experiments/smolagents/README.md`
- `experiments/appworld/run.py`, `experiments/appworld/run_all.py`, `experiments/appworld/run_ctxopt_pipeline.py`
- `experiments/officebench/run.py`, `experiments/officebench/run_ctxopt_pipeline.py`, `experiments/officebench/evaluation/*`
- `experiments/smolagents/run.py`, `experiments/smolagents/run_ctxopt_pipeline.py`, `experiments/smolagents/eval_utils.py`, `experiments/smolagents/dataset.py`
- `src/productive_agents/agents/base.py`, `unified_agent.py`, `memory.py`, `utils.py`
- `src/productive_agents/agents/appworld/agent.py`, `officebench/agent.py`, `smolagents/agent.py`
- `src/productive_agents/ctxopt/base.py`, `history_optimizer.py`, `obs_optimizer.py`
- `src/productive_agents/llm.py`, `subtrate_api.py`
- `src/productive_agents/env/appworld/env.py`, `officebench/env.py`, `officebench/shell_executor.py`, `smolagents/env.py`, `smolagents/tool.py`
- `experiments/appworld/configs/context_opt/*.yaml`, `experiments/officebench/configs/context_opt/*.yaml`, `experiments/smolagents/configs/context_opt/*.yaml`
- `experiments/*/prompts/context_opt/*.jinja` and main benchmark prompt JSON files
- `experiments/prompt_optimizer/unified_update_history_prompt.py`, `unified_update_observation_prompt.py`, `unified_compress_update_history_prompt.py`, `unified_compress_update_observation_prompt.py`, `common/*`, `prompts/*`
- `experiments/training/save_trajectories_dataset.py`, `data_utils.py`, `finetune_sft_unsloth.py`, `serve_llm.py`, `preprocess.py`
- `experiments/analysis_tools/utils.py`

## Excluded Paths

- `experiments/officebench/tasks/**`: benchmark task fixtures, testbed PDFs/images/docs/spreadsheets, calendar/email data, and references. I inspected size and representative metadata but excluded full file-by-file review because they are generated/benchmark data, not context-compression implementation.
- `experiments/smolagents/data/nq_multi_8/*.jsonl`: benchmark QA examples. I reviewed loader and runner behavior, not every data row.
- `assets/concept.png`: paper illustration, not execution logic.
- `experiments/officebench/evaluation/templates/index.html`: UI/report template only; evaluation Python was in scope, HTML presentation was not.
- Binary and document fixtures under OfficeBench task folders: not source logic and not useful for Agentic Coding Lab patterns beyond confirming benchmark realism.
- Generated output directories such as `outputs/`, `experiments/*/outputs/`, `dataset/`, and `finetuned_models/`: absent from the fresh clone or expected run artifacts, excluded as generated state.
