# LoCoBench-Agent: An Interactive Benchmark for LLM Agents in Long-Context Software Engineering

- URL: https://arxiv.org/abs/2511.13998
- Cite as: arXiv:2511.13998
- DOI: 10.48550/arXiv.2511.13998
- Authors: Jielin Qiu, Zuxin Liu, Zhiwei Liu, Rithesh Murthy, Jianguo Zhang, Haolin Chen, Shiyu Wang, Ming Zhu, Liangwei Yang, Juntao Tan, Roshan Ram, Akshara Prabhakar, Tulika Awalgaonkar, Zixiang Chen, Zhepeng Cen, Cheng Qian, Shelby Heinecke, Weiran Yao, Silvio Savarese, Caiming Xiong, Huan Wang
- Venue / source: arXiv preprint, Salesforce AI Research
- Published: arXiv submitted 2025-11-17
- Citations snapshot: 0 citations
- Citation source: OpenAlex work W4417209600, `cited_by_count=0`, captured 2026-05-31. Semantic Scholar lookup was attempted but returned API 429 rate limiting, so OpenAlex is the verified current source.
- Code: https://github.com/SalesforceAIResearch/LoCoBench-Agent
- Topic: context-control
- Reviewed at: 2026-05-31
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong benchmark and design reference for coding-agent context control because it evaluates multi-turn exploration, tool choice, memory pressure, and comprehension-efficiency trade-offs at 10K-1M token codebase scale. Use it as a harness pattern and metric vocabulary, not as a turnkey scoring oracle: the released code shows heuristic metrics, aggressive context compression defaults, synthetic scenario conversion, and some paper/code drift that need local validation before adopting its rankings.

## Problem

Most code benchmarks still evaluate single-turn code generation or repository repair under relatively short contexts. LoCoBench-Agent targets a different failure mode: agents that must explore unfamiliar codebases, choose tools, remember earlier decisions, and maintain architectural consistency over many turns while context grows.

The paper argues that static long-context benchmarks such as LoCoBench measure whether a model can consume a supplied code context, but they do not measure the agent behaviors that matter in production coding tools: incremental file discovery, semantic search, read-before-write discipline, turn efficiency, error recovery, and memory retention across extended development sessions.

For Agentic Coding Lab, the core problem is directly in scope. A useful coding-agent support system needs to know when to load context, when to search, when to summarize, which artifacts must remain exact, and when continued exploration is no longer worth the token and latency cost. LoCoBench-Agent is valuable because it makes those context-control choices observable instead of treating them as incidental prompt behavior.

## Method

LoCoBench-Agent converts the original LoCoBench static scenarios into interactive agent sessions. The benchmark keeps the same broad coverage claim: 8,000 scenarios, 10 programming languages, 36 domains, 8 task categories, and context lengths from 10K to 1M tokens. The task categories include architectural understanding, cross-file refactoring, feature implementation, bug investigation, multi-session development, code comprehension, integration testing, and security analysis.

The scenario conversion pipeline decomposes each static task into phases. Typical phases are exploration, planning or diagnosis, implementation, validation, and documentation. Each phase has prompts, expected tool actions, success conditions, and dynamic follow-up prompts. The released `scenario_converter.py` implements this as category-specific phase templates, not as fully human-written conversations. That matters: the benchmark is a strong stress harness, but its phase prompts and success checks are still generated scaffolding.

The agent environment exposes coding tools rather than dumping all files into the prompt. The paper describes 8 specialized tools across file operations, search, and analysis. The released repository includes file-system tools, IDE-simulator style tools, compiler/debugger tools, grep/fuzzy search, and semantic search. The README summarizes the intended public surface as file operations, semantic search, code analysis, and 9 bias-free metrics.

The context-control design has three initialization modes:

- `minimal`: load README, project file structure or priority files, and entry points; require the agent to discover the rest.
- `empty`: load no file content but provide an exact file-structure map, forcing tool-based discovery.
- `full`: load the complete codebase, mainly as a baseline and only realistic for smaller contexts.

The paper's context-management layer combines tiered compression, hierarchical memory, file-level compression, LLM summarization, and semantic search. It describes a 40% early-warning threshold, 60% critical summarization threshold, and 95% emergency truncation threshold. The released `context_management.py` is more aggressive in practice: the config defaults to 40% early warning and 60% critical, and the adaptive manager triggers aggressive truncation when `usage_after >= critical_threshold`. The code comment still says "95% threshold," so this is paper/code drift worth noting.

Evaluation uses 9 LCBA metrics split into comprehension and efficiency:

- LCBA-Comprehension: execution success rate, multi-session memory retention, cross-file consistency, dependency traversal, solution usability.
- LCBA-Efficiency: runtime efficiency, memory efficiency, information coverage, long-range dependency resolution.

The repository's `bias_free_evaluator.py` confirms the 5+4 metric split and computes aggregate scores by averaging those metric groups. Some metrics are deterministic or static-analysis based; others are session-log heuristics such as read-before-write patterns, tool diversity, file access ratios, and modified-file behavior. The paper frames the metrics as bias-free after correlation checks against file-count bias, but the implementation should still be treated as a metric proposal rather than an objective correctness oracle.

## Evidence

The paper evaluates six agents: GPT-5, GPT-4.1, GPT-4o, Claude Sonnet 4.5, Claude Sonnet 4, and Gemini 2.5 Pro. It reports runs across all 8,000 LoCoBench-Agent scenarios with up to 50 turns per scenario, 60-minute timeouts, sandboxed file systems, context compression, complete tool logs, modified-file histories, and context-window metrics.

Headline results:

- Gemini 2.5 Pro has the highest reported LCBA-Comprehension score at 0.7443, followed by Claude Sonnet 4.5 at 0.7336, GPT-5 at 0.7264, Claude Sonnet 4 at 0.7231, GPT-4o at 0.7211, and GPT-4.1 at 0.7085.
- Claude Sonnet 4.5 has the highest reported LCBA-Efficiency score at 0.6332, followed by GPT-4o at 0.6313, GPT-4.1 at 0.6239, Claude Sonnet 4 at 0.6208, GPT-5 at 0.6039, and Gemini 2.5 Pro at 0.5997.
- The paper reports a negative comprehension-efficiency correlation around `r = -0.42` in the text and shows a plotted linear trend of `r = -0.475, p = 0.341`. The important takeaway is not the exact coefficient but the stable qualitative pattern: broader exploration tends to raise comprehension scores while hurting efficiency.
- High-comprehension agents average more turns and broader edits. The paper states that high-comprehension models use 19+ conversation turns and far more file modifications, while efficiency-oriented agents average about 12-13 turns and use targeted exploration.
- Context length alone is not the differentiator. Reported comprehension stays roughly flat across difficulty/context levels, and some expert 1M-token settings perform as well as or better than easy settings. The authors attribute this partly to more structured large projects and more systematic exploration on large tasks.
- Multi-session memory retention is the weak spot. The paper highlights best performers barely around 37% retention, despite context windows from 128K to 1M tokens, implying that current compression and memory strategies lose important references over long sessions.
- Cross-file consistency is near saturation. The paper reports 0.93-0.98 ranges, suggesting that naming, imports, and local style consistency are easier than durable memory and efficient exploration.

The public code supports the existence of an evaluation harness. It includes scenario conversion, multi-turn session orchestration, context managers, semantic search, agent adapters, robust checkpointing, JSONL incremental result saving, and the LCBA metric calculator. The repository was cloned at commit `1abacfdccb5202572a3e75249fb699c6296f708f` from 2025-11-19, and GitHub API reported 21 stars, 5 forks, Apache-2.0 license, and last push on 2025-11-19 when reviewed on 2026-05-31.

There are also reproducibility caveats. The README points to a Google Drive `data.zip` for evaluation scenarios. The paper says all evaluation data, transcripts, and analysis scripts are released; the repository provides the framework and data download path, but the dataset is not vendored in the repo. The codebase contains multiple parallel evaluation paths (`AgentEvaluator`, `RobustAgentEvaluator`, and CLI helper flows), and some comments still refer to older "25" or "28" metric systems even though the final LCBA evaluator uses 9 metrics.

## Limits

The benchmark is interactive, but many interactions are generated from static scenarios. The phase templates, dynamic prompts, and success conditions can shape agent behavior in artificial ways. This is still useful for controlled stress testing, but it is not equivalent to observing real users, real issue threads, or production coding sessions.

The scoring is not pure functional correctness. Several metrics are proxies over tool logs, static patterns, read/write ordering, file access ratios, or style heuristics. That makes them valuable for diagnosing context-control behavior, but risky as a leaderboard score. For example, "information coverage" and "long-range dependency resolution" reward exploration patterns; a short correct fix can score worse if it does not read enough files.

The paper's "bias-free" claim should be interpreted narrowly. The authors validate against file-count bias and rescale efficiency metrics, but that does not remove all benchmark bias. Generated scenarios, generated prompts, model-specific tool schemas, static analyzers, and API throttling all introduce their own biases.

The reported "files modified" scale is suspicious as written. The paper discusses totals such as 10K-35K files modified across runs, while the underlying projects have 10-100 files each. This likely means aggregate modified-file events across many scenarios, but the prose sometimes reads like per-agent behavior. Any local adoption should normalize these counts by scenario, task category, and actual unique files.

There is paper/code drift in context management. The paper describes 40%/60%/95% thresholds, while the released adaptive manager uses 40% and 60% defaults and can aggressively truncate at the critical threshold. That makes the code useful as a reference implementation but not an exact executable form of the paper description.

Semantic search is implemented with optional `sentence-transformers` or OpenAI embeddings and falls back when dependencies are missing. That means benchmark results can depend on environment setup, embedding provider, cache state, and API availability.

The model set is time-sensitive. GPT-5, Claude Sonnet 4.5, and Gemini 2.5 Pro are evaluated as named API models, but default API settings, model revisions, throttling, and context limits can change. The results are best treated as a November 2025 snapshot, not a stable ranking.

## Research Themes

- Token efficiency: High relevance. The benchmark directly measures turn count, runtime/memory efficiency, context pressure, compression events, and exploration cost under 10K-1M token codebases.
- Context control: Very high relevance. The main contribution is an evaluation environment for file loading, semantic search, summarization, compression thresholds, initial context modes, and read-before-write behavior.
- Sub-agent / multi-agent: Low to medium relevance. The released code has framework adapters and evaluates agents, but the paper is primarily about individual coding agents rather than multi-agent coordination.
- Domain-specific workflow: High relevance. The task categories, phase decomposition, coding tools, compiler/test hooks, and repository-specific prompts are software-engineering specific.
- Error prevention: Medium to high relevance. The benchmark records tool errors, compile/test failures, progress stalls, and read/write discipline, but it does not deeply study safety policy or destructive operation prevention.
- Self-learning / memory: Medium relevance. The paper evaluates multi-session memory retention and hierarchical summaries, but it does not propose a persistent learning memory system.
- Popular skills: Medium relevance. It supports skill-like operational patterns: exact file-path discipline, semantic-search-first exploration, phased execution, compression policies, and verification gates.

## Key Ideas

- Evaluate context-control as agent behavior, not just prompt length. The benchmark observes when the agent searches, reads, writes, summarizes, and stops.
- Use initial context modes to separate context stuffing from tool-mediated discovery. Minimal and empty modes make file retrieval strategy part of the score.
- Score comprehension and efficiency separately. A single success score hides the central trade-off between exhaustive exploration and lean execution.
- Treat semantic search as a context valve. Agents can query the codebase without immediately loading every file into the conversation.
- Preserve architectural memory separately from recent turns. The hierarchy of working memory, compressed memory, and architectural memory is a useful mental model even if the implementation needs tuning.
- Measure read-before-write discipline. For coding agents, "did it inspect dependencies before editing?" is often more actionable than a generic answer-quality score.
- Look for saturation signals. The paper's best practical insight is that agents need dynamic termination policies: continue exploring while information gain is high, then switch to implementation.
- Make benchmark traces first-class artifacts. Conversation history, tool calls, diffs, context usage, compression events, and failure logs are more valuable for improving agents than a final scalar score.

## Ideas To Steal

- Build an Agentic Coding Lab "context-control benchmark mode" with three initial-context profiles: full, minimal, and empty. Use the same tasks across profiles to measure whether a workflow actually benefits from search and memory tools.
- Track two top-level scores in every long coding run: comprehension evidence and efficiency evidence. Do not let a high-pass rate hide runaway turn counts, repeated reads, or context bloat.
- Add a phase-aware exploration budget. Start with semantic/file search, require targeted dependency reads, then explicitly transition to implementation once repeated searches stop producing new files or facts.
- Store a context-pressure trace for each run: token usage, files loaded, files summarized, summaries created, tool output sizes, and exact moments of compression/truncation.
- Create a read-before-write ledger. Before an agent edits a file, record whether it read that file, imported dependencies, relevant tests, and nearby configuration.
- Adopt exact-path discipline from the empty-mode prompt. File tree maps should show exact paths, and tools should reject guessed or normalized paths when that would hide an agent failure.
- Use semantic search as a retrieval preview, not as final evidence. Search results should point to files/functions; important code still needs explicit reads before edits.
- Add metric regression tests for the metrics themselves. Feed known-good and known-bad traces into LCBA-like scoring and verify that short correct fixes, careful exploratory fixes, and wasteful broad rewrites are ranked as intended.
- Keep compression policy versioned. Each summary should record which policy produced it, what was dropped, and what downstream action depended on it.
- Sample "memory retention failures" from real coding sessions. When an agent repeats work, forgets a user constraint, or edits against stale assumptions, turn the trace into a benchmark case.

## Do Not Copy

- Do not copy the 40%/60% aggressive compression defaults blindly. They may be useful for benchmark stress, but production coding agents need risk-aware thresholds that protect active diffs, failing tests, user constraints, and recent decisions.
- Do not treat "bias-free metrics" as settled science. The file-count bias checks are useful, but local workflows need human-audited calibration and task-level correctness checks.
- Do not over-reward file access. Reading dependencies before editing is good; reading many irrelevant files to satisfy a coverage proxy is not.
- Do not expose every tool by default. The benchmark uses a rich tool suite to compare agents, but production harnesses should expose smaller tool sets based on the task and permission model.
- Do not rely on generated phase prompts as a substitute for real issue/task data. They are good for scalable coverage, weak for ecological validity.
- Do not conflate aggregate modified-file events with per-task edit quality. Normalize by scenario and inspect diffs.
- Do not assume raw 1M context windows solve memory. The paper's own memory-retention result suggests compression and retrieval design matter more than capacity alone.
- Do not use LLM summaries without preservation contracts. Summaries must explicitly retain file paths, function names, commands, errors, tests, decisions, and pending risks.
- Do not compare model rankings without pinning API versions, tool schemas, embedding setup, context limits, and retry/throttling policy.

## Fit For Agentic Coding Lab

LoCoBench-Agent is a high-fit context-control source. Its strongest contribution for Agentic Coding Lab is the evaluation shape: put agents in a constrained interactive repository environment, give them realistic file/search/edit tools, record every context-management decision, and score comprehension separately from efficiency.

The most practical adoption path is to build a smaller local harness inspired by LCBA:

1. Pick 20-50 real repository tasks from this project and adjacent coding-agent workflows.
2. Run each task in full, minimal, and empty context modes.
3. Record tool traces, file reads, edits, tests, summaries, context tokens, and turn counts.
4. Score with local rubrics: task solved, read-before-write coverage, wasted reads, repeated commands, summary loss, user-constraint retention, and verification evidence.
5. Use failed traces to improve skills, MCP tools, memory rules, and compaction prompts.

For context-control specifically, the paper supports three design bets:

- Agent workflows need explicit exploration policies, not just larger context windows.
- Context compression should be evaluated by downstream coding behavior, not by summary readability.
- Efficient agents need phase transitions and information-gain stopping rules.

The benchmark should not be adopted wholesale as a leaderboard. Instead, use it to design Agentic Coding Lab artifacts: a context-pressure logger, an exact-path file map, a search-read-edit ledger, a summary preservation contract, and a regression suite for compaction failures.

## Related Repositories

- https://github.com/SalesforceAIResearch/LoCoBench-Agent - Official implementation. Reviewed at commit `1abacfdccb5202572a3e75249fb699c6296f708f` from 2025-11-19. GitHub API snapshot on 2026-05-31 reported 21 stars, 5 forks, Apache-2.0 license, and Python as the primary language. Key files reviewed: `README.md`, `locobench/core/context_management.py`, `locobench/core/agent_session.py`, `locobench/core/semantic_search.py`, `locobench/generation/scenario_converter.py`, `locobench/generation/interactive_scenario_generator.py`, `locobench/evaluation/bias_free_evaluator.py`, `locobench/evaluation/robust_agent_evaluator.py`, and `locobench/cli.py`.
- https://github.com/SalesforceAIResearch/LoCoBench - Base static long-context code benchmark used as the source of the 8,000 scenarios. The LoCoBench-Agent README links it as the related project; it was not deep-reviewed here beyond confirming the relationship.
- https://huggingface.co/papers/2511.13998 - Hugging Face paper page, which confirms the GitHub code link and publication metadata.

## Reviewed Sources

- arXiv abstract page: https://arxiv.org/abs/2511.13998
- arXiv PDF v1: https://arxiv.org/pdf/2511.13998
- Official code repository: https://github.com/SalesforceAIResearch/LoCoBench-Agent
- Hugging Face paper page: https://huggingface.co/papers/2511.13998
- OpenAlex API work record: https://api.openalex.org/works/W4417209600
- GitHub API repository record: https://api.github.com/repos/SalesforceAIResearch/LoCoBench-Agent
- Implementation files reviewed from the official repository clone: `README.md`, `locobench/core/context_management.py`, `locobench/core/enhanced_summarization.py`, `locobench/core/agent_session.py`, `locobench/core/tool_registry.py`, `locobench/core/semantic_search.py`, `locobench/tools/file_system_tool.py`, `locobench/tools/semantic_search_tool.py`, `locobench/generation/scenario_converter.py`, `locobench/generation/interactive_scenario_generator.py`, `locobench/core/multi_turn_pipeline.py`, `locobench/evaluation/bias_free_evaluator.py`, `locobench/evaluation/revised_metrics.py`, `locobench/evaluation/agent_evaluator.py`, `locobench/evaluation/session_evaluator.py`, `locobench/evaluation/robust_agent_evaluator.py`, and `locobench/cli.py`.
