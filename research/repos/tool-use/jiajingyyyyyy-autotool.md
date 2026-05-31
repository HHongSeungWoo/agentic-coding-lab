# jiajingyyyyyy/AutoTool

- URL: https://github.com/jiajingyyyyyy/AutoTool
- Category: tool-use
- Stars snapshot: 37 (GitHub REST API repository endpoint, captured 2026-05-31); index row was 36 (GitHub REST API, captured 2026-05-29)
- Reviewed commit: c7010ff49750ed338fec61556f7797b104a6826e
- Reviewed at: 2026-05-31
- Status: reviewed
- Scope fit: conditional
- Verdict: High-signal for a specific runtime routing subproblem: when an agent is already inside a repeated multi-step workflow, AutoTool can predict the next tool from recent tool-call history and fill parameters from execution history, allowing the host to skip another LLM call. It is not a general 10,000-skill retrieval router because it does not search a global skill corpus, does not reduce the fallback prompt's full tool-description context, and relies on learned/observed tool-sequence inertia.

## Why It Matters

AutoTool is useful because it approaches "skill usage at runtime" from a different angle than vector retrieval systems such as SkillRouter, Tool-SEE, or langgraph-bigtool. Those systems try to retrieve the right few tools or skills before exposing them to the model. AutoTool instead asks whether the agent needs to ask the model at all on a given step. If the recent trajectory strongly implies the next action, the runtime predicts the next tool, fills its parameters, generates the action text, and bypasses the LLM call.

That makes it relevant to large skill systems as a second-stage optimization. A 10,000-skill router still needs retrieval to find candidate skills, but once a workflow is underway, many steps are repetitive: inspect, parse, transform, test, fix, re-run, summarize. AutoTool's graph and parameter-dependency machinery suggests how to turn common skill chains into host-side shortcuts, reducing repeated prompt tokens, latency, and model-selection noise.

The boundary is important. AutoTool does not solve the user's original problem by itself. It cannot take 10,000 unrelated skill descriptions and discover the right first skill without context blow-up. It shines after the runtime already has a constrained tool universe and enough trajectory history to detect sequential inertia.

## What It Is

AutoTool is the code release for "AutoTool: Efficient Tool Selection for Large Language Model Agents" (arXiv:2511.14650, AAAI 2026). The repo contains:

- `autool/`: graph-based tool prediction, n-gram baseline, parameter completion, embeddings, parsers, memory, and toolkit helpers.
- `agentboard/`: a modified AgentBoard evaluation harness with ReAct, AutoTool+ReAct, and AutoTool+Reflection agents.
- `autool/core/tool_predict/tool_doc/`: JSON tool descriptions for AlfWorld, ScienceWorld, and ToolQuery-Academic.
- `agentboard/examples/` and `agentboard/visualisation/`: trajectory logs, parameter-dependency examples, and Markov-analysis artifacts.
- `scripts/`: plotting and visualization helpers for successor distributions and parameter dependencies.
- `eval_configs/main_results_all_tasks.yaml`: AgentBoard-style config selecting `ReactInertiaAgent` by default.

The public repo is an experimental research implementation. It includes enough code to trace the runtime path, but it does not include a clean production package, CI, formal tests, aggregate result tables, or a durable service API.

## Research Themes

- Token efficiency: Strong for skipped LLM turns. AutoTool sets token counts to zero on successful inertial calls and records `total_llm_calls`, input/output tokens, and overhead. It does not reduce the fallback LLM prompt's full tool-description footprint.
- Context control: Conditional. Runtime context is saved only when an inertial prediction succeeds and no model call is made. The system does not expose a smaller tool shortlist to the model when it falls back to ReAct.
- Sub-agent / multi-agent: Low. There is no subagent or multi-agent routing layer. The ideas could be applied per subagent by learning workflow-specific tool chains.
- Domain-specific workflow: Strong but narrow. The adapters are hand-written for AlfWorld, ScienceWorld, and ToolQuery-Academic, with domain parsers and environment-state heuristics.
- Error prevention: Moderate. It tracks failed tool calls, adds negative weights to tool sequences, limits consecutive inertial calls, and falls back after invalid actions. It does not provide permission gates, sandboxing, or formal safety constraints.
- Self-learning / memory: Moderate. It updates tool graphs and parameter dependencies from observed trajectories and current execution history. Persistence and cross-session reuse are weak and inconsistent.
- Popular skills: Not a skill catalog. The relevant "popular skill" idea is workflow-path inertia: successful tool sequences and parameter flows become reusable runtime hints.

## Core Execution Path

The main runtime path is `agentboard/agents/test_agent.py`, registered as `ReactInertiaAgent`.

1. Agent initialization loads a task-specific tool description file from `TOOL_DESC_FILE`, then creates a `ToolGraph`.
2. `ToolGraph.load_from_json(tool_description_path, self.log_file)` loads tool nodes and attempts to load tool-chain history from the trajectory log path. The agent usually creates a new empty log file, so the graph often starts cold unless a populated log is provided.
3. The agent initializes a task-specific parameter-completion adapter: `AlfworldParamCompletion`, `ScienceWorldParamCompletion`, or `ToolQueryParamCompletion`.
4. On each `run()`, before entering the standard ReAct loop, the agent checks whether inertial execution is allowed. It blocks inertia when the continuous inertial-call limit is reached, when inertial calls exceed about 30% of steps, or after recent invalid-tool observations.
5. If enough execution history exists, it reads the latest `inertia_k` tool records from `ParameterFillingFramework.history`.
6. The current "intuition" text is taken from recent model memory, truncated to roughly the last 50 characters.
7. `ToolGraph.predict_next_tool_with_chain_similarity()` finds stored paths containing the recent tool sequence, collects the next tool after each matching subsequence, scores candidates by frequency and optional SimCSE semantic similarity, and returns a high-confidence candidate if the combined score exceeds `inertia_threshold`.
8. If a next tool is predicted, `param_completion.fill_parameters()` tries to fill required parameters from the parameter dependency graph, recent structured execution history, and environment adapter state.
9. If all required parameters are filled, the adapter generates an action string. The agent appends a synthetic assistant memory message explaining the graph-inertia decision, sets input/output token counts to zero, records the inertial step, and returns the action without calling the LLM.
10. If prediction or filling fails, the agent falls back to the normal ReAct loop and calls `call_model()`.
11. `update()` parses the action and observation, appends the tool to an inertia window, updates the graph with positive or negative weights depending on success/failure and whether the action came from LLM or inertia, records structured execution history, and updates cumulative timing counters.
12. At trajectory finalization, the agent saves action logs, updates the `ToolGraph` from the completed trajectory, and builds/saves a `ParameterDependencyGraph`.

There is also an n-gram baseline in `autool/core/tool_predict/ngram_predictor.py`. It trains from logged tool sequences, stores `(n-1)`-gram successor counts, computes conditional confidence, and can save/load a pickle model. The main AutoTool path uses `ToolGraph`, not the n-gram baseline.

## Architecture

AutoTool has four main runtime structures.

`ToolGraph` stores tool nodes, directed call edges, unique tool paths, a `tool -> path IDs` inverted index, and parameter-source edges. The inverted index narrows potential matching paths, and `is_subsequence()` then checks whether recent tool history appears in each candidate path.

The successor predictor is graph/statistical rather than corpus-retrieval-first. It computes candidate next tools only from paths that already contain the recent tool sequence. Candidate frequency is normalized by total matching frequency and multiplied by a confidence factor `1 - 1.1^-x`. Optional semantic scoring compares the "intuition" text to candidate tool descriptions using SimCSE embeddings. Final score is `alpha * frequency_score + (1 - alpha) * semantic_score`.

`ParameterDependencyGraph` learns output-to-input parameter dependencies from execution history. It compares prior outputs/inputs with later tool inputs, stores counts for `(source_tool, source_param) -> (target_tool, target_param)`, and returns potential sources sorted by count. `CoreParameterFillingEngine` first tries graph-derived parameter sources, then environment-context heuristics.

Task adapters encode domain knowledge. AlfWorld and ScienceWorld adapters maintain local state such as objects, locations, inventory, receptacle states, visible objects, known locations, and last observations. ToolQuery-Academic tracks loaded graphs, last checked node, searched entity, and location query. Each adapter also turns filled parameters back into a concrete action string.

The evaluation harness is AgentBoard-derived. `agentboard/eval_main.py` reports success rate, progress rate, easy/hard rates, and grounding accuracy. The AutoTool logs add `total_llm_calls`, input/output tokens, `total_inertial_calling`, and detailed overhead fields for graph search, SimCSE, parameter filling, action generation, parser time, graph construction, and LLM time.

Offline or preprocessing paths exist, but they are not packaged as a single clean pipeline. `agentboard/visualisation/markov.py` computes 0th/1st/2nd-order Markov statistics, entropy reduction, and likelihood-ratio tests from trajectories. `ngram_predictor.py` can train a saved n-gram model. `ToolGraph.load_tool_chain_from_json()` can bootstrap paths from trajectory JSON. `ParameterDependencyGraph.update_graph()` can build parameter edges from trajectory steps.

## Design Choices

The central design choice is "skip model selection when path inertia is strong." AutoTool does not try to make the LLM a better tool selector on every step. It uses the host runtime to take over predictable next actions.

The second important choice is combining sequence frequency with a lightweight semantic signal. Frequency handles repeated workflow structure; SimCSE similarity helps break ties or prefer candidates whose descriptions fit the current thought. However, semantic matching is only applied after graph candidates exist. It cannot retrieve a tool absent from matching paths.

The third choice is parameter completion as a first-class requirement. Predicting a tool name is insufficient in environments where actions require object, location, graph, or query arguments. AutoTool therefore pairs tool prediction with history/PDG/environment state filling and refuses inertial execution if required parameters remain missing.

The fourth choice is online graph adjustment. In `update()`, successful inertial calls add weight `1`, failed inertial calls add `-1`, successful LLM calls add `0.5`, and failed LLM calls add `-0.5` to recent tool sequences. This is a practical way to dampen bad shortcuts and reward observed good paths, although the persistence story is weak.

The final choice is domain adapters over a generic schema. This makes the demos possible in AlfWorld, ScienceWorld, and ToolQuery-Academic, but it means AutoTool's runtime intelligence is strongly tied to hand-written parsers and environment-state heuristics.

## Strengths

AutoTool attacks repeated LLM calls directly. For long tool-use episodes, the biggest savings may come from not asking the model again on obvious steps, rather than only shortening the tool list.

The runtime path is concrete. `ReactInertiaAgent.run()` clearly shows the decision boundary: try graph prediction, try parameter filling, execute inertially if complete, otherwise fall back to LLM ReAct.

The graph is interpretable. Tool paths, successor counts, parameter edges, and Markov visualizations can be inspected. This is easier to debug than a black-box learned router.

The parameter-completion layer is useful for skill routing. Many coding skills are not just "which skill?" but "which file, command, test, artifact, or previous output should be passed next?" AutoTool's PDG-style source tracking is a transferable idea.

The paper and code track the right cost dimensions: LLM calls, input/output tokens, graph-search overhead, embedding overhead, parameter-filling time, and full task metrics. Even when the repo lacks aggregate result tables, the log schema shows what a runtime router should measure.

The Markov-analysis scripts are conceptually useful. Entropy reduction and likelihood-ratio tests can tell us whether a workflow has enough sequential structure to justify an inertial shortcut instead of calling a general router each turn.

## Weaknesses

It is not a large-corpus skill router. AutoTool does not index thousands of skills, retrieve top-k from a global catalog, or progressively load skill bodies. It assumes a small task-specific action/tool set: the checked tool description files contain 14 AlfWorld tools, 23 ScienceWorld tools, and 7 academic ToolQuery tools.

It does not solve prompt context blow-up on fallback calls. The agent's standard ReAct prompt can still include the task's tool descriptions. AutoTool saves context only when it skips the model call entirely.

Cold start is a real limitation. The current agent creates a new trajectory log file and loads chains from that file, which is initially empty. Some graph learning happens online during the run, but durable cross-run graph reuse is not cleanly implemented as a persisted model or index.

Semantic retrieval is secondary and candidate-limited. If the recent tool sequence does not match any graph paths, SimCSE cannot find a tool from the full catalog. This is the opposite of SkillRouter-style retrieval, where semantic search is the first candidate generator.

The code is research-grade. There are many debug prints, duplicate parsing blocks, hard-coded `/data/...` paths, task-specific assumptions, and fragile flow around logs and parameter-dependency paths.

Packaging is currently broken or at least suspicious. `setup.py` uses `find_packages(include=["autotool", "autotool.*"])`, but the actual package directory is `autool`, so editable install may not install the intended package.

The repo has no formal tests or CI. `rtk python -m compileall autool agentboard/agents agentboard/visualisation scripts` passes, but there are no unit tests for the routing logic, parameter filling, graph persistence, or end-to-end inertial decisions.

The included example trajectories are partial and uneven. Some files are empty, many are old logs, and the repo does not ship clean aggregate result tables matching the paper. Reproducing final metrics requires AgentBoard data, Docker, API credentials, SimCSE model assets, and task environments.

There are safety gaps. Retrieval relevance or graph confidence is treated as permission to generate an action. There is no authorization layer, side-effect classification, approval gate, sandbox, or scoped execution policy.

## Ideas To Steal

Use "skip the LLM call" as a separate optimization from "retrieve fewer skills." A production skill router can first select relevant skills, then use AutoTool-like path inertia inside the selected workflow to avoid repeated selection calls.

Maintain a `skill_path_graph` per workflow or project. Nodes are skills/tools, edges are observed transitions, and paths store frequency, success/failure weights, and outcome metadata.

Record parameter and artifact flows. For coding agents, source parameters could be files, test names, command outputs, issue IDs, stack traces, generated patch IDs, or previous analysis summaries. Later skills can fill arguments from those sources without asking the LLM to restate them.

Use entropy or Markov tests to decide where shortcuts are safe. If a workflow has low conditional entropy after the last one or two skill calls, inertial execution may be worth trying. If entropy is high, use semantic retrieval or the LLM.

Gate inertial execution by both next-skill confidence and parameter-fill completeness. Predicting the next skill without valid arguments should produce a hint or shortlist, not an automatic action.

Add negative feedback to workflow paths. Failed tool calls should reduce edge/path weight, and repeated invalid calls should force fallback to the LLM or a diagnostic skill.

Track cost counters at the router layer. For every activation, log whether the model was skipped, how many tokens were saved, graph-search latency, embedding latency, parameter-fill latency, and whether the downstream action succeeded.

Keep domain adapters small and explicit. A general skill system can have adapters for coding domains such as git, tests, web search, docs lookup, package managers, and file editing rather than trying to infer every parameter generically.

## Do Not Copy

Do not use AutoTool as the only answer to "10,000 skills." It lacks first-hop retrieval, corpus indexing, and progressive loading.

Do not rely on sequence inertia before enough high-quality trajectories exist. Cold-start or one-off tasks need semantic/hybrid retrieval.

Do not expose all skill descriptions on fallback calls and call the system context efficient. AutoTool's savings come from no-call steps, not from smaller fallback prompts.

Do not treat graph-predicted execution as authorization. A production system needs policy checks between prediction and execution.

Do not bind the implementation to ad hoc environment paths, mutable private logs, or unschematized trajectory JSON. Persist graph/index state explicitly.

Do not copy the packaging and test posture. Fix package discovery, add unit tests for path matching/scoring/filling, and add regression tests for failed-action negative weighting before using this pattern.

Do not make semantic scoring a late tie-breaker if the goal is broad skill discovery. For large skill libraries, semantic or hybrid retrieval must be the initial candidate generator.

## Fit For Agentic Coding Lab

Fit is conditional but important. AutoTool should not replace a runtime skill retriever, but it should be part of the runtime skill-usage stack.

The right architecture for Agentic Coding Lab is layered:

1. Use deterministic filters and hybrid retrieval to shortlist skills from the full installed/enabled corpus.
2. Load only a few skill bodies or tool schemas into model context.
3. While executing, record selected skill IDs, arguments, outputs, artifacts, success/failure, and timing.
4. Build per-workflow skill path graphs and parameter dependency graphs from that telemetry.
5. When the current workflow state has high path confidence and complete parameters, let the host execute a safe next step or propose a deterministic next action without another model call.
6. Fall back to the LLM or skill search when confidence is low, parameters are missing, the action is side-effectful, or recent actions failed.

AutoTool is especially useful for repeated coding loops:

- run tests -> parse failure -> inspect file -> edit -> re-run tests;
- fetch docs -> read API example -> patch code -> typecheck;
- reproduce issue -> collect logs -> apply known remediation -> verify;
- search skill -> read skill -> run helper script -> summarize result.

For a 10,000-skill system, AutoTool's lesson is not "give the agent all skills." It is "once the router has found a workflow neighborhood, use statistical workflow memory so the agent does not need to re-select obvious next skills every turn."

## Reviewed Paths

- `/tmp/myagents-research/jiajingyyyyyy-autotool/README.md`: Project positioning, installation, AgentBoard dependency, workflow image reference, quickstart, repo layout, and citation.
- `/tmp/myagents-research/jiajingyyyyyy-autotool/setup.py`: Package metadata, dependency list, and package-discovery issue.
- `/tmp/myagents-research/jiajingyyyyyy-autotool/autool/core/tool_predict/datastruct.py`: `ToolGraph`, `ToolNode`, `ToolPath`, call edges, path index, parameter edges, graph update, path loading, prediction, candidate scoring, and fallback candidate scoring.
- `/tmp/myagents-research/jiajingyyyyyy-autotool/autool/core/tool_predict/ngram_predictor.py`: N-gram baseline, log training, confidence thresholding, pickle save/load, and limitations.
- `/tmp/myagents-research/jiajingyyyyyy-autotool/autool/core/tool_predict/tool_doc/alfworld_tool_description.json`: 14-tool AlfWorld action schema.
- `/tmp/myagents-research/jiajingyyyyyy-autotool/autool/core/tool_predict/tool_doc/scienceworld_tool_description.json`: 23-tool ScienceWorld action schema.
- `/tmp/myagents-research/jiajingyyyyyy-autotool/autool/core/tool_predict/tool_doc/academic_tool_description.json`: 7-tool ToolQuery-Academic action schema.
- `/tmp/myagents-research/jiajingyyyyyy-autotool/autool/core/param_completion/param_completion.py`: Environment adapter contract, core parameter filling, history-backed filling, alias matching, and `ParameterFillingFramework`.
- `/tmp/myagents-research/jiajingyyyyyy-autotool/autool/core/param_completion/param_dependency.py`: Parameter dependency graph construction, matching, save/load, stats, and execution history.
- `/tmp/myagents-research/jiajingyyyyyy-autotool/autool/core/param_completion/domain/alfworld.py`: AlfWorld parser adapter, state tracking, contextual parameter inference, and action generation.
- `/tmp/myagents-research/jiajingyyyyyy-autotool/autool/core/param_completion/domain/scienceworld.py`: ScienceWorld parser adapter, visible object/location state, contextual parameter inference, and action generation.
- `/tmp/myagents-research/jiajingyyyyyy-autotool/autool/core/param_completion/domain/tool_query.py`: Generic dataset adapter for academic/movie/weather-style graph and entity tools.
- `/tmp/myagents-research/jiajingyyyyyy-autotool/autool/core/update/history.py`: Simple execution-history structure used by graph update helpers.
- `/tmp/myagents-research/jiajingyyyyyy-autotool/autool/utils/embedding.py`: SimCSE embedding service, caching behavior, vector normalization, and similarity computation.
- `/tmp/myagents-research/jiajingyyyyyy-autotool/autool/utils/call_model.py`: OpenAI-compatible model call wrapper and token usage collection.
- `/tmp/myagents-research/jiajingyyyyyy-autotool/autool/memory/memory.py`: Temporary and essential memory containers used by the agents.
- `/tmp/myagents-research/jiajingyyyyyy-autotool/agentboard/agents/test_agent.py`: Main `ReactInertiaAgent` implementation, inertial decision path, fallback ReAct loop, online graph update, logging, and finalization.
- `/tmp/myagents-research/jiajingyyyyyy-autotool/agentboard/agents/test_agent2.py`: Reflection plus inertial agent variant.
- `/tmp/myagents-research/jiajingyyyyyy-autotool/agentboard/agents/react_agent.py`: Baseline ReAct agent for comparison and log shape.
- `/tmp/myagents-research/jiajingyyyyyy-autotool/agentboard/eval_main.py`: Evaluation launcher and aggregate metrics reported by the harness.
- `/tmp/myagents-research/jiajingyyyyyy-autotool/eval_configs/main_results_all_tasks.yaml`: Default run, agent, LLM, and task configuration.
- `/tmp/myagents-research/jiajingyyyyyy-autotool/agentboard/visualisation/markov.py`: Markov transition, entropy, and likelihood-ratio analysis helpers.
- `/tmp/myagents-research/jiajingyyyyyy-autotool/scripts/pie_chart.py` and `/tmp/myagents-research/jiajingyyyyyy-autotool/scripts/visulization.py`: Successor distribution and graph/parameter visualization utilities.
- `/tmp/myagents-research/jiajingyyyyyy-autotool/agentboard/visualisation/trajectories/*.json`: Baseline ScienceWorld trajectories used to inspect log schema and token/LLM-call fields.
- `/tmp/myagents-research/jiajingyyyyyy-autotool/agentboard/examples/**/trajectories/*.json`: Inertial trajectory examples, including empty and partial logs.
- `/tmp/myagents-research/jiajingyyyyyy-autotool/agentboard/examples/**/param_dependency_path/**/*.json`: Saved parameter-dependency examples.
- GitHub REST API metadata for `jiajingyyyyyy/AutoTool`: star count, default branch, timestamps, topics, fork/open issue counts, and repository state.
- `https://arxiv.org/abs/2511.14650`: Paper metadata, abstract, and cited positioning.
- `https://ojs.aaai.org/index.php/AAAI/article/view/40389/44350`: AAAI proceedings PDF, used to compare the implementation against the paper's claimed method, evaluation setup, and limitations.

## Excluded Paths

- `/tmp/myagents-research/jiajingyyyyyy-autotool/.git/`: VCS storage. Used only through `git rev-parse` and `git log` for provenance.
- `/tmp/myagents-research/jiajingyyyyyy-autotool/assets/workflow.png`: Visual workflow diagram. The executable behavior was reviewed from source code and paper text.
- `/tmp/myagents-research/jiajingyyyyyy-autotool/ppt&poster/AutoTool.pptx` and `/tmp/myagents-research/jiajingyyyyyy-autotool/ppt&poster/poster.pptx`: Binary presentation files. They may contain summary visuals, but source and paper were sufficient for architecture review.
- Generated `__pycache__` files under the cloned repo: Created by compile verification and excluded as build artifacts.
- Full AgentBoard upstream environment and datasets: Not vendored here. Reproduction would require the Docker image, downloaded AgentBoard data, API credentials, and task environments.
- SimCSE model weights from Hugging Face: Not downloaded. The review only needed the embedding call path and model dependency boundary.
- End-to-end evaluation runs: Not run because they require external AgentBoard data, model/API configuration, environment setup, and potentially large Docker/model assets. Static compile verification and project research validation were run instead.
