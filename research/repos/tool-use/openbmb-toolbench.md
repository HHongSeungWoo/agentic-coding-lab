# OpenBMB/ToolBench

- URL: https://github.com/OpenBMB/ToolBench
- Category: tool-use
- Stars snapshot: 5,653 (GitHub REST API, captured 2026-05-31; index row had 5,652 captured 2026-05-29)
- Reviewed commit: d56fdd89faf8c91fa135090b212bb9057ee5cfc2
- Reviewed at: 2026-05-31
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong research reference for runtime skill routing because it trains and evaluates a dense retriever over a 16k-API pool, then exposes only a small retrieved API set to a multi-step ToolLLaMA/ChatGPT execution loop. It is not production-ready routing code: retrieval is first-turn only, unindexed dense search is memory-bound, local tool execution uses dynamic import/eval, and evaluation depends on heavy external data and OpenAI-backed judges.

## Why It Matters

ToolBench directly targets the "too many tools for context" problem. The paper and code assume thousands of available APIs, but the runtime cannot put all API specs into the model prompt. Instead, it trains an API retriever from instruction-to-relevant-API labels, retrieves a top-k API subset for the current instruction, converts only those APIs into function schemas, and lets the agent perform multi-step API calls.

This is a closer analogue to SKILL.md routing than marketplace repos. For Agentic Coding Lab, the useful pattern is not the RapidAPI domain itself. It is the two-stage runtime: first select a compact capability subset from a large corpus, then run an agent loop with only that subset and evaluate both retrieval quality and task success.

## What It Is

ToolBench is the code, data format, model training, inference, and evaluation package for ToolLLM/ToolLLaMA. The project collects RapidAPI tools, generates natural-language instructions and relevant API labels, annotates multi-step tool-use traces through a depth-first search decision tree, trains ToolLLaMA on those traces, trains a dense API retriever, and evaluates tool-use solutions through ToolEval.

The repository contains five main subsystems:

- Data and preprocessing scripts for ToolLLaMA and retriever training.
- A sentence-transformer API retriever trained from instruction/API relevance pairs.
- Open-domain and closed-domain inference pipelines.
- Tool execution wrappers for RapidAPI-backed tools, a hard-coded ToolBench service, or local customized API code.
- ToolEval scripts for pass-rate and preference-style evaluation over six test subsets.

## Research Themes

- Token efficiency: High for tool exposure. Open-domain inference retrieves `retrieved_api_nums` APIs, commonly 5, instead of putting all 16k API specs into context. It also truncates tool descriptions, API descriptions, parameter descriptions, observations, and generated output. The remaining prompt still includes full schemas for the retrieved APIs, so cost scales with top-k and schema verbosity.
- Context control: High as a first-stage filter. `ToolRetriever` narrows the corpus before `rapidapi_wrapper` builds the function list. During execution, observations are truncated to `max_observation_length`, and local execution can filter response fields using stored response schemas. There is no iterative retrieval when the agent discovers a missing capability mid-run.
- Sub-agent / multi-agent: Low. The architecture separates retriever, planner/model, search controller, and executor, but these are components in one process, not autonomous subagents.
- Domain-specific workflow: High for API/tool learning. The data model understands RapidAPI categories, tools, APIs, parameters, example responses, response schemas, and G1/G2/G3 task families: single-tool, intra-category multi-tool, and intra-collection multi-tool tasks.
- Error prevention: Medium. The runtime has typed-ish status codes for missing function names, invalid inputs, final answer, give-up, 404, unauthorized, unsubscribed, rate limit, message errors, and request errors. It checks hallucinated function names during evaluation. It does not sandbox local customized APIs, and `server.py` uses dynamic import plus `exec`/`eval`.
- Self-learning / memory: Low. ToolBench learns offline from generated traces and retriever labels. The runtime does not maintain usage memory, update retrieval from failures, or prune tools based on telemetry.
- Popular skills: Dense tool retrieval, top-k context gating, instruction/API relevance labeling, in-batch negative retriever training, NDCG@k retrieval evaluation, multi-step tool-call traces, DFS/DFSDT planning, observation truncation, schema-guided response filtering, pass-rate and preference evaluation.

## Core Execution Path

Retriever data construction:

1. `preprocess/preprocess_retriever_data.py` loads instruction JSON and a test-id split.
2. It splits query rows into train/test sets.
3. For each row, every API in `api_list` becomes a retriever document.
4. A document is labeled positive when `[tool_name, api_name]` appears in the row's `relevant APIs`.
5. The script writes `corpus.tsv`, `train.query.txt`, `test.query.txt`, `qrels.train.tsv`, and `qrels.test.tsv`.
6. The document text later includes category, tool name, API name, API description, required parameters, optional parameters, and return schema.

Retriever training and evaluation:

1. `toolbench/retrieval/train.py` builds a `SentenceTransformer` from a configured base model, commonly `bert-base-uncased`.
2. Positive query/API examples become `InputExample(texts=[query, document], label=1)`.
3. Training uses `MultipleNegativesRankingLoss`, so other batch examples act as negatives. The paper discusses negative sampling, but the checked-in preprocessing/training path does not show a separate hard-negative file.
4. `APIEvaluator` encodes all test queries and corpus chunks, computes cosine similarity, sorts results per query, and reports average NDCG@1, NDCG@3, and NDCG@5.
5. `toolbench/retrieval/inference_example.py` demonstrates direct top-5 retrieval and counts matches against ground-truth relevant docs.

Open-domain inference:

1. `toolbench/inference/qa_pipeline_open_domain.py` creates `pipeline_runner(args, add_retrieval=True)`.
2. `pipeline_runner.run()` loads the model and a `ToolRetriever` from `corpus_tsv_path` and `retrieval_model_path`.
3. For each query, `rapidapi_wrapper.__init__()` calls `retrieve_rapidapi_tools(query, retrieved_api_nums, tool_root_dir)` when a retriever is present.
4. `ToolRetriever.retrieving()` embeds the user query, runs semantic search over precomputed corpus embeddings, asks for `10 * top_k` hits, filters excluded tools, standardizes category/tool/API names, and returns candidate API triples.
5. `rapidapi_wrapper.retrieve_rapidapi_tools()` keeps existing local API docs until it reaches top-k.
6. `fetch_api_json()` loads the tool JSON, finds the requested API, and extracts category, API description, required parameters, optional parameters, and tool name.
7. `api_json_to_openai_json()` converts each retrieved API into an OpenAI-functions-style schema and appends a special `Finish` function.
8. `rapidapi_wrapper.task_description` lists only unique retrieved tools and truncates each tool description to 512 characters. Function descriptions and parameter descriptions are truncated to 256 characters.
9. The agent loop receives only this retrieved function list plus `Finish`, not the global API pool.

Planner/executor loop:

1. `pipeline_runner.method_converter()` chooses either `single_chain` for CoT-style execution or `DFS_tree_search` for DFS/DFSDT.
2. The model is either ChatGPT function calling, Text-Davinci, ToolLLaMA, or ToolLLaMA-LoRA.
3. `single_chain` runs one linear ReAct-style loop: model emits thought plus function call, environment executes, observation is appended, and the loop stops on `Finish`, prune, or max depth.
4. `DFS_tree_search` keeps a tree of thoughts, actions, action inputs, observations, terminal nodes, and give-up nodes.
5. If a node already has children, DFS adds a diversity prompt describing previous failed candidates so the model tries a different action.
6. With `woFilter`, DFSDT uses pre-order traversal without LLM pairwise ranking. With filtering enabled, it can rank candidate branches through LLM pairwise comparisons before expansion.
7. Retrieval is not repeated inside the tree. Child environment copies explicitly set `retriever = None`, so all planning happens inside the initial retrieved tool subset.
8. API execution goes through `rapidapi_wrapper.step()`, which maps function names back to API names and calls either the hosted ToolBench RapidAPI service or local customized API code.
9. Outputs are written as trace JSON containing the tree/process and `answer_generation`, including visible functions, query count, token count, final answer, train messages, and validity.

Observation handling:

1. `rapidapi_wrapper.step()` truncates any observation longer than `max_observation_length`, default 1024 in the scripts.
2. Local `server.py` can filter response dictionaries through stored response schemas when `strip` is `filter`, and caps local observations to 2048 characters.
3. The paper describes ChatGPT-derived response compression schemas for long API responses; the checked-in local path implements schema filtering only when response example schemas are available.

Evaluation:

1. ToolEval expects converted answers for six subsets: `G1_instruction`, `G1_tool`, `G1_category`, `G2_instruction`, `G2_category`, and `G3_instruction`.
2. `eval_pass_rate.py` checks whether the final step calls `Finish`, asks an evaluator whether the final answer solves the query, checks task solvability, checks hallucinated tool names, and aggregates repeated judgments.
3. `eval_preference.py` compares candidate and reference solution traces, optionally using pass-rate results first, then asks an evaluator to select the better answer.
4. The normalized evaluator strips detailed tool descriptions and parameters before judging, caps final answers and answer details, and uses function-call prompts for answer status, task solvability, and preference.
5. The paper reports retriever NDCG and task-level pass/win rate, making it possible to separate "did the router retrieve the right APIs" from "did the agent use them well."

## Architecture

ToolBench is a pipeline, not a standalone serving framework. The large tool universe lives as JSON API docs and generated datasets. The retriever is a dense sentence-transformer model over serialized API documents. The runtime environment is created per query and gets either a ground-truth API list from the input file or a top-k list from the retriever.

The architecture has three practical context boundaries:

- Corpus boundary: all APIs are stored outside the model prompt and represented as retriever documents.
- Prompt boundary: only retrieved APIs are converted into function schemas and passed to the LLM.
- Observation boundary: API results are truncated or schema-filtered before being appended to the conversation.

The model-facing contract depends on backend choice. ChatGPT receives provider-native function schemas. ToolLLaMA receives a text prompt where `process_system_message()` stringifies the available function list into the system message and asks for `Thought`, `Action`, and `Action Input` format.

The executor boundary is weaker. Hosted ToolBench calls are mediated through an HTTP service, but customized/local APIs are imported dynamically and invoked through strings. This is acceptable for a benchmark, but unsafe as a general agent skill execution layer.

## Design Choices

- Retrieve APIs, not tools. The router selects individual API endpoints, then deduplicates tool descriptions for the task prompt. This is useful for fine-grained function routing, but SKILL.md routing likely needs both skill-level and operation-level grouping.
- Dense-only retrieval in the checked-in runtime. The code uses sentence-transformer embeddings and cosine similarity. There is no BM25 hybrid, ANN index, metadata filter, confidence threshold, or fallback expansion in the runtime.
- One-shot retrieval before planning. This keeps prompts small and deterministic, but the agent cannot ask for more tools after partial observations reveal a new need.
- Top-k as the main budget knob. `retrieved_api_nums` defaults to 5 in examples and server requests. This maps well to a skill router's "shortlist size" policy.
- Function schemas are generated from docs. API descriptions and parameter metadata become model-facing function definitions. Names are standardized and sometimes truncated to meet function-name constraints.
- `Finish` is always injected. The agent must explicitly end with a final answer or give-up/restart, which makes traces easier to evaluate.
- DFS/DFSDT separates search strategy from tool execution. The same environment can be used with linear CoT/ReAct or tree search.
- Evaluation measures multiple layers. Retriever NDCG, pass rate, win rate, and hallucination checks are separate signals.
- Response compression is schema-aware in concept. The paper's response-compression idea is stronger than the local implementation and is directly relevant to coding-agent tool observations.

## Strengths

- Directly demonstrates large-pool runtime routing: top-5 APIs are selected from a 16k-API universe before prompting.
- The data model creates explicit instruction-to-relevant-API labels, which are exactly what a learned skill router needs.
- Retriever evaluation uses NDCG@1/3/5, which is a good first metric for skill shortlist quality.
- Task evaluation measures whether the selected tools were actually sufficient to solve the task, not just whether retrieval looked plausible.
- Open-domain inference path cleanly shows where retrieval plugs into agent execution.
- The prompt budget is controlled at several layers: retrieved tool count, tool-description truncation, API-description truncation, parameter-description truncation, max sequence length, and observation truncation.
- DFSDT is a useful model-agnostic search controller for tool tasks where one bad tool call can derail a linear ReAct loop.
- Tool traces include reasoning, function calls, observations, and final answer, making them useful as training/evaluation data.
- The G1/G2/G3 split explicitly tests single-tool and multi-tool routing difficulty.
- Tool customization shows how new API docs and code can be added without retraining ToolLLaMA, if they are passed in context or included in retriever docs.

## Weaknesses

- The runtime is not a scalable 10k-skill service as written. `ToolRetriever` embeds the entire corpus at startup and uses sentence-transformers semantic search over in-memory embeddings, with no persistent vector index, sharding, metadata pruning, or incremental update path.
- Retrieval is API-level and first-turn only. There is no agent action like `search_tools` or `read_tool` during execution, so missing tools cannot be recovered mid-task.
- The checked-in retriever training path only materializes positive qrels and relies on in-batch negatives. The paper mentions sampled negatives, but the repo path does not expose a rich hard-negative mining loop.
- `APIEvaluator` does brute-force chunked scoring and defaults to a tiny corpus chunk size, so it is a correctness evaluator rather than a production retrieval implementation.
- Function-name generation truncates names to the last 64 characters, which can cause collisions and weak provenance for large registries.
- Retrieval returns top-k even when confidence is poor. There is no threshold, abstain, ask-clarification, or broaden-search policy.
- The model prompt still receives full schemas for the retrieved APIs. If SKILL.md files are long, this pattern must be paired with progressive disclosure rather than loading full skill contents.
- Hosted RapidAPI execution depends on a hard-coded ToolBench service URL, external keys, and live API behavior. Reproducibility is fragile.
- Local customized API execution uses dynamic import plus `exec` and `eval` in `toolbench/inference/server.py`.
- Many dependencies are old and heavy: FastChat-era OpenAI calls, old `transformers`, Deepspeed, LangChain, sentence-transformers, Flask, and large model/data downloads.
- There are no local unit tests or CI-style checks in the checked-out repo.
- ToolEval depends on OpenAI-backed evaluator calls and repeated stochastic judgments; useful for research, but too expensive and non-deterministic as the only production gate.

## Ideas To Steal

- Build a compact `skills.index.json` corpus where each skill has a short retrieval document: name, category, triggers, negative triggers, required inputs, outputs, side-effect class, examples, and provenance.
- Train or tune a dense retriever from real traces: user task -> selected SKILL.md files -> successful final outcome.
- Use NDCG@k and "skill recall@budget" as router metrics before measuring full task success.
- Keep top-k small and explicit. Treat `k=3`, `k=5`, and `k=10` as budget modes with measured pass-rate/cost tradeoffs.
- Separate router evaluation from agent execution evaluation. A bad answer may come from missing skill retrieval, poor skill use, or tool/runtime failure.
- Add a `Finish`/terminal action requirement to skill-use traces so evaluation can reliably identify completed attempts.
- Store full tool/skill traces with visible skills, observations, token counts, retrieval hits, and final status.
- Use schema-aware observation compression. For coding agents, this maps to truncating logs, test output, diffs, stack traces, and search results by known structure rather than raw character cuts.
- Use a tree-search retry controller only after initial skill selection. If a linear pass fails due to tool error or bad branch, generate alternative actions within the same retrieved skill subset before broadening.
- Add response/observation status codes that separate missing capability, bad arguments, permission failure, external service failure, rate limit, and final answer.

## Do Not Copy

- Do not load full SKILL.md files for top-k by default. Use the ToolBench-style retriever to select skill IDs, then progressively load only summaries, task-specific sections, or referenced files as needed.
- Do not make retrieval a one-time irreversible choice. A skill system should support `search_skills`, `read_skill`, and "broaden search" actions during execution.
- Do not use dense-only retrieval as the whole router. Combine deterministic filters such as project scope, file globs, language, tool permissions, and trust labels with lexical and semantic retrieval.
- Do not rely on long descriptions as routing text. ToolBench uses long serialized API docs because APIs are structured; SKILL.md routing needs compact, curated router-facing metadata.
- Do not execute skill code or tools through generated strings, `exec`, or `eval`.
- Do not accept top-k without confidence or provenance. The agent should know whether a retrieved skill is high-confidence, stale, experimental, untrusted, or merely a fallback.
- Do not judge routing only by final answer quality. Keep retrieval labels and visible-skill logs so failures are attributable.
- Do not use OpenAI-judge pass/fail as the only regression gate. Pair judge-based evaluation with deterministic checks, fixture tasks, and exact expected skill IDs where possible.
- Do not assume API routing equals skill routing. SKILL.md files often contain procedures, constraints, scripts, and references; their retrieval granularity may be section-level, not endpoint-level.

## Fit For Agentic Coding Lab

ToolBench is in-scope as a runtime routing and evaluation reference. The most valuable transplant is a retrieval-gated execution loop:

1. Store all skills outside prompt in a machine-readable catalog.
2. Retrieve a short skill/API subset from the user task and project context.
3. Present only that subset to the agent.
4. Let the agent execute with explicit final/give-up actions.
5. Record trace-level evidence.
6. Evaluate both router quality and task outcome.

For Agentic Coding Lab, this should become a skill-router prototype rather than a direct dependency. A practical version would expose `search_skills(query, filters, k)`, `read_skill(skill_id, section)`, `record_skill_use(skill_id, outcome)`, and `broaden_skill_search(reason)` tools. It should use deterministic filters first, semantic/lexical retrieval second, and an LLM selector only over a short candidate list.

Required changes before adoption:

- Replace the in-memory brute-force retriever with a persistent index and incremental catalog updates.
- Add metadata filters for repo, language, domain, risk, side effects, permissions, dependencies, and maturity.
- Support grouped retrieval: skill pack -> skill -> section/resource.
- Add retrieval confidence, abstention, and fallback policies.
- Add runtime dynamic retrieval actions instead of initial top-k only.
- Replace dynamic execution with permissioned tool IDs and validated arguments.
- Add deterministic eval fixtures where expected skills are known.
- Track context cost per selected skill and prune unused skills through telemetry.

## Reviewed Paths

- `README.md`: project purpose, data statistics, API collection, retriever training commands, ToolLLaMA training, open-domain/closed-domain inference commands, API customization, web server, ToolEval, and experiment tables.
- `assets/paper.pdf`: paper text for dataset construction, API filtering, response compression, instruction generation, DFSDT, ToolEval, API retriever, NDCG results, and ToolLLaMA retriever integration.
- `scripts/preprocess_retriever_data.sh` and `scripts/train_retriever.sh`: default retriever preprocessing/training parameters.
- `preprocess/preprocess_retriever_data.py`: train/test split, API document creation, positive relevance labels, and qrels/corpus outputs.
- `toolbench/retrieval/train.py`: sentence-transformer retriever construction, `MultipleNegativesRankingLoss`, evaluator wiring, and training output path.
- `toolbench/retrieval/api_evaluator.py`: chunked query/corpus embedding, cosine scoring, sort, multiprocessing NDCG@1/3/5 computation, and CSV logging.
- `toolbench/retrieval/inference_example.py`: top-5 retriever usage and successful-match counting.
- `toolbench/utils.py`: function prompt injection, name normalization, LLaMA context extension helper, and retrieval document serialization.
- `toolbench/inference/qa_pipeline.py`: close-domain inference entrypoint.
- `toolbench/inference/qa_pipeline_open_domain.py`: open-domain inference entrypoint with retrieval enabled.
- `toolbench/inference/Downstream_tasks/rapidapi.py`: runtime environment, whitelist creation, retrieval-to-query conversion, API JSON loading, function-schema conversion, task prompt assembly, execution status codes, observation truncation, `Finish`, and pipeline runner.
- `toolbench/inference/LLM/retriever.py`: runtime `ToolRetriever`, corpus loading, embedding construction, semantic search, top-k expansion, excluded-tool filtering, and standardized API triples.
- `toolbench/inference/LLM/tool_llama_model.py`: ToolLLaMA prompt construction, function-list injection into text prompt, generation, and ReAct parsing.
- `toolbench/inference/LLM/chatgpt_function_model.py`: ChatGPT function-call wrapper, retries, total-token accounting, and function-name cleanup.
- `toolbench/inference/Algorithms/single_chain.py`: linear CoT/ReAct-style tool-call loop, trace serialization, and terminal handling.
- `toolbench/inference/Algorithms/DFS.py`: DFSDT/DFS tree search, diversity prompt, optional pairwise branch ranking, backtracking, query/token accounting, and trace serialization.
- `toolbench/inference/LLM_rank/rank_candidate.py` and `toolbench/inference/Prompts/rank_prompts.py`: pairwise LLM ranking of alternative branches.
- `toolbench/inference/Tree/Tree.py`: trace tree node structure, observation storage, train-message extraction, and JSON export.
- `toolbench/inference/server.py`: local customized API execution path, dynamic import/eval, error classification, schema filtering, and observation cap.
- `toolbench/inference/toolbench_server.py` and `toolbench/inference/callbacks/ServerEventCallback.py`: web/demo server, top-k request parameter, model/retriever loading, and streaming callbacks for retrieval and tool events.
- `preprocess/preprocess_toolllama_data.py`: trace-to-SFT conversion and `Thought`/`Action`/`Action Input` target formatting.
- `toolbench/tooleval/README.md`: ToolEval usage, pass-rate/win-rate descriptions, answer format, and evaluator extension points.
- `toolbench/tooleval/eval_pass_rate.py`: pass-rate evaluation, hallucination check, repeated evaluator calls, and CSV/JSON outputs.
- `toolbench/tooleval/eval_preference.py`: model-vs-model preference evaluation, pass-rate shortcut, repeated judgments, and win/tie/loss aggregation.
- `toolbench/tooleval/evaluators/registered_cls/base.py`: evaluator preprocessing, answer/tool truncation, and preference wrapper.
- `toolbench/tooleval/evaluators/registered_cls/rtl.py`: ToolEval task/answer/pass status checks and better-answer selection.
- `toolbench/tooleval/evaluators/registered_cls/tooleval.py`: OpenAI-backed normalized evaluator and function-call judge helpers.
- `data_example/instruction/*.json`: representative G1/G2/G3 query structure, `api_list`, `relevant APIs`, query IDs, and API metadata fields.
- `requirements.txt`: dependency and reproducibility surface.
- `LICENSE`: Apache-2.0 license.

## Excluded Paths

- `.git/`: repository metadata only; used only to identify the reviewed commit.
- `README_ZH.md` and `toolbench/tooleval/README_ZH.md`: Chinese translations of already-reviewed English docs.
- `docs/index.html`: static leaderboard/project page; reviewed only indirectly through README and ToolEval docs.
- `assets/*.png` and `assets/toolbench-demo.mp4`: diagrams, logo, and demo media. The paper PDF was reviewed; the remaining binary/media assets do not affect runtime routing.
- `ds_configs/*.json`: DeepSpeed training configs. Not relevant to skill routing beyond confirming heavy training setup.
- `toolbench/train/*`, `toolbench/model/*`, and LLaMA monkey patches: reviewed at a high level for ToolLLaMA context length and training surface, but not line-by-line because the routing question centers on retriever, prompt assembly, execution loop, and evaluation.
- `data_example/answer/*`: static/generated trace examples. I inspected the schema shape through code and representative references, not every generated answer file.
- `data_example/toolenv/response_examples/*`: static response examples for schema filtering. Reviewed as a concept through `server.py`; not every API response was read.
- `data_example/toolenv/tools/*/api.py`: generated API stubs/wrappers. Excluded from exhaustive review because local execution safety is already represented by `server.py`, and individual API wrappers are domain data.
- Large external datasets from Google Drive/Tsinghua Cloud and Hugging Face models: not downloaded. The review uses checked-in code, examples, README, paper, and GitHub API metadata.
- Runtime reproduction of ToolLLaMA or ToolEval: not run because it requires large model/data downloads and API keys.
