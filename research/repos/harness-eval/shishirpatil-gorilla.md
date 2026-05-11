# ShishirPatil/gorilla

- URL: https://github.com/ShishirPatil/gorilla
- Category: harness-eval
- Stars snapshot: 12,861 (GitHub REST API, captured 2026-05-12)
- Reviewed commit: 6ea57973c7a6097fd7c5915698c54c17c5b1b6c8
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: in-scope
- Verdict: High-signal reference for tool/function-call evaluation. The most reusable pieces are BFCL's model-handler abstraction, JSONL prompt/answer schemas, two-phase generate/evaluate pipeline, deterministic AST/value checking, executable stateful multi-turn checking, agentic web-search and memory tasks, cost/latency reporting, and explicit leaderboard category weighting.

## Why It Matters

Gorilla is a broad project around API-calling LLMs, but the relevant harness is the Berkeley Function Calling Leaderboard (BFCL). BFCL is a mature benchmark for comparing native function-calling models and prompt-only models across single-turn, multi-function, parallel, relevance/irrelevance, multi-turn, web-search, memory, and format-sensitivity cases.

For coding-agent work, the important idea is that tool use is not only judged by text similarity. BFCL normalizes model outputs into function-call structures, executes multi-turn calls against simulated API backends, checks resulting state and tool responses, and stores inference logs with tool calls, state snapshots, token counts, latency, and handler diagnostics.

## What It Is

The repository contains several related efforts: the original Gorilla/APIBench model evaluation, OpenFunctions models, GoEx execution engine, Agent Arena, RAFT, API Zoo, and BFCL. This review focused on BFCL as the active function/tool-call eval harness and sampled the legacy Gorilla/APIBench path to understand its predecessor.

BFCL is packaged as `bfcl_eval` with a `bfcl` Typer CLI. Users run `bfcl generate` to produce model responses into `result/<model>/...`, then `bfcl evaluate` to score those responses into `score/<model>/...` and aggregate CSVs. The package supports API models, local vLLM/SGLang-hosted models, OpenAI-compatible remote endpoints, native function-calling mode, and prompt mode.

## Research Themes

- Token efficiency: Moderate. BFCL records input/output token counts, estimates cost, tracks latency, and uses provider-specific cache controls in some handlers, but it is not a context compression system.
- Context control: Strong. Datasets separate user messages, function docs, initial backend state, expected answers, prompt-format variants, and category mappings. Prompt-mode models get generated system prompts while FC models receive converted tool schemas.
- Sub-agent / multi-agent: Conditional. BFCL does not orchestrate subagents, but its multi-turn tool loop resembles an agent harness with repeated model calls, tool execution, state feedback, and force-quit limits.
- Domain-specific workflow: Very strong for function/tool-call evaluation. It includes Python, Java, JavaScript, live enterprise-style tool docs, web search, persistent memory, filesystem-like state, travel, trading, vehicle control, tickets, messages, and social posting APIs.
- Error prevention: Strong. Deterministic checks catch wrong function names, missing/extra args, wrong types, wrong values, bad relevance decisions, state mismatches, missing execution responses, and format sensitivity regressions.
- Self-learning / memory: Strong as an eval target, not as harness memory. BFCL V4 tests key-value memory, vector memory, and recursive summarization memory using prerequisite conversations and persisted snapshots.
- Popular skills: Not a skill repo. Reusable patterns are `BaseHandler`, `MODEL_CONFIG_MAPPING`, `load_dataset_entry`, `ast_checker`, `multi_turn_checker`, `agentic_checker`, `execute_multi_turn_func_call`, and `generate_leaderboard_csv`.

## Core Execution Path

CLI entrypoint is `berkeley-function-call-leaderboard/bfcl_eval/__main__.py`. `bfcl generate` parses model/category options, loads `.env`, and calls `_llm_response_generation.main`. `bfcl evaluate` calls `eval_checker/eval_runner.main`.

Generation expands category groups through `constants/category_mapping.py`, loads JSONL prompt rows with `load_dataset_entry`, and builds a handler from `constants/model_config.py`. Existing result files are reused unless `--allow-overwrite` is set. `--run-ids` reads `test_case_ids_to_generate.json` for targeted regeneration.

Each model handler inherits `BaseHandler`. The base class dispatches between single-turn FC, single-turn prompting, multi-turn FC, and multi-turn prompting. FC handlers compile tool schemas through `convert_to_tool`; prompt handlers inject generated system prompts through `system_prompt_pre_processing_chat_model`.

For multi-turn and agentic categories, the base handler loops over turns and steps. It queries the model, decodes tool calls, executes them with `execute_multi_turn_func_call`, appends tool outputs back into chat history, logs state and handler events, and stops when the model emits no valid tool call or after `MAXIMUM_STEP_LIMIT`.

Evaluation loads model results, prompt entries, and possible answers. It selects scoring logic by category: AST/value checks for single-turn categories, relevance/no-call checks for relevance categories, executable state checks for multi-turn categories, and final-answer containment for agentic web-search/memory categories. CSV aggregation then computes non-live, live, multi-turn, agentic, format-sensitivity, and overall leaderboard views.

## Architecture

Key BFCL modules:

- `bfcl_eval/__main__.py`: Typer CLI for models, categories, generation, result listing, evaluation, and score viewing.
- `bfcl_eval/_llm_response_generation.py`: dataset collection, dependency scheduling, concurrent inference, result writing, local server lifecycle, and memory/web-search initial settings.
- `bfcl_eval/model_handler/base_handler.py`: shared inference loop and abstract provider hooks.
- `bfcl_eval/model_handler/api_inference/`: adapters for OpenAI Responses/Completions, Claude, Gemini, Mistral, Cohere, Grok, Qwen, Nova, and other API providers.
- `bfcl_eval/model_handler/local_inference/base_oss_handler.py`: vLLM/SGLang server startup and OpenAI-compatible completion calls for local models.
- `bfcl_eval/model_handler/utils.py`: tool schema conversion, prompt generation, AST/XML/JSON parsing, execution-list formatting, retry helpers, and memory prompt injection.
- `bfcl_eval/eval_checker/ast_eval/`: function name, type, required/optional arg, value, parallel-order, and multiple-function checks.
- `bfcl_eval/eval_checker/multi_turn_eval/`: simulated API execution, backend classes, state comparison, and response checking.
- `bfcl_eval/eval_checker/agentic_eval/`: final answer matching for web-search and memory agentic cases.
- `bfcl_eval/data/`: JSONL prompts, possible answers, multi-turn function docs, and memory prerequisite conversations.

Legacy Gorilla/APIBench lives under `gorilla/eval` and `data/api` / `data/apibench`. It generates model responses for APIBench and scores by tree-sitter AST matching against API-call databases, reporting functionality accuracy and hallucination. BFCL is more relevant for current tool-call agents because it has richer schemas, model adapters, multi-turn execution, and leaderboard aggregation.

## Design Choices

BFCL separates response generation from evaluation. That makes expensive API/model inference reproducible and debuggable because result JSONL files can be inspected, re-evaluated, or partially regenerated.

The model adapter interface is explicit. Each handler owns provider-specific request formatting, tool compilation, response parsing, chat-history updates, and output decoding into common AST/executable forms. This avoids forcing all vendors into one weak abstraction while still making the evaluator provider-agnostic.

The dataset schema is simple JSONL. Prompt rows have `id`, `question`, and usually `function`; multi-turn rows add `initial_config`, `path`, `involved_classes`, and sometimes `missed_function`; agentic rows rely on `involved_classes`; memory rows add `scenario`. Ground truth rows live separately under `possible_answer` and are aligned by category/order.

Single-turn scoring is mostly deterministic. The evaluator checks decoded function names, required parameters, unexpected parameters, language-specific type conversion, optional values, and normalized string/list/dict values. Parallel calls are order-insensitive.

Multi-turn scoring is executable. Model calls and ground-truth calls are run against the same simulated backend classes. The checker compares backend instance state after each non-empty turn and verifies expected tool responses appear in the accumulated model execution results.

Agentic V4 uses real external-ish behavior in the harness. Web search uses SerpAPI plus optional page fetching; memory uses persisted snapshots and three backend APIs: key-value/BM25, vector/FAISS with sentence-transformers, and recursive summarization text memory.

Leaderboard weighting is a design signal. Current overall score weights non-live 10%, live 10%, irrelevance 10%, multi-turn 30%, and agentic 40%, intentionally favoring harder multi-step/agentic behavior over saturated single-turn calls.

## Strengths

BFCL models tool-call evaluation as an end-to-end system, not only a prompt-output pair. It captures provider request formatting, function schema conversion, decoding, execution, state, logs, scoring, cost, and latency.

The handler boundary is practical for coding-agent harnesses. A local agent, CLI agent, MCP client, or remote model could be wrapped as a handler if it can emit structured calls or parseable text.

The multi-turn harness is especially useful. It tests whether a model can use previous tool results, mutate state correctly, handle missing functions/parameters, and avoid overcalling when no tool is appropriate.

The data categories cover real failure modes: irrelevant tools, relevant-but-open-ended tools, parallel calls, long contexts, withheld tools, missing parameters, prompt format sensitivity, web search without snippets, and memory persistence.

The result files are useful debugging artifacts. Inference logs can include transformed model inputs, raw assistant outputs, decoded calls, tool outputs, state snapshots, and force-quit events.

## Weaknesses

Reproducibility depends heavily on external services and mutable model endpoints. API keys, SerpAPI, live web pages, hosted proprietary models, and local GPU backends can all change results even at a fixed commit.

There are few conventional tests for BFCL itself in the repo. The closest BFCL test artifact is `test_case_ids_to_generate.json.example`; `raft/tests` and frontend tests are unrelated. Correctness is mostly protected by benchmark data, changelog fixes, and runtime assertions.

Agentic web-search scoring is shallow compared with the tool execution path. It checks whether one expected answer string appears in the final non-tool message, not whether the search trajectory or cited sources were sound.

Some execution uses Python `eval` after lightweight function-name blocking. The callable set is constrained to simulated backend instances, but this pattern should not be copied into a coding-agent harness with untrusted arbitrary tool strings.

The dataset has accumulated many historical fixes. The changelog shows frequent ground-truth and prompt corrections, so downstream users should pin commit SHA and treat benchmark upgrades as score-changing events.

BFCL is a benchmark harness, not a general coding-agent evaluator. It does not model file diffs, tests, package installs, code review, patch quality, or repository-wide task completion unless those are wrapped as tools and backends.

## Ideas To Steal

Use a two-phase pipeline: generate durable result artifacts first, evaluate them later.

Define one model/agent adapter interface with separate hooks for prompt construction, native tool schema compilation, response parsing, call decoding, tool-result injection, and result writing.

Represent tool-call datasets as JSONL with stable IDs, function docs, expected answers, initial state, involved backend classes, and category-derived output paths.

Score simple calls deterministically with function-name, required/optional arg, type, and value checkers. Keep parallel calls order-insensitive.

For agent/coding tasks, compare post-tool state, not only emitted commands. BFCL's state checker is a strong pattern for filesystem, issue tracker, database, or browser-state evals.

Persist per-run logs that include transformed inputs, raw outputs, decoded tool calls, tool outputs, state snapshots, token counts, latency, and internal handler decisions.

Make partial regeneration and partial evaluation first-class for expensive benchmarks.

Keep an explicit category-weighting formula so benchmark priorities are visible and reviewable.

## Do Not Copy

Do not use `eval` on model-produced strings in a real coding-agent harness. Prefer structured tool-call objects and an allowlisted dispatcher.

Do not rely on final-answer substring matching for high-stakes agentic tasks. It is acceptable for a leaderboard slice, but coding-agent evals need artifact/state/test checks.

Do not mix mutable live web answers into regression tests without snapshots or source pinning. BFCL's web-search category is valuable, but it needs careful provenance if used for CI.

Do not treat provider adapters as one-size-fits-all. BFCL shows that each vendor needs careful message roles, tool schema quirks, token accounting, retries, and response decoding.

Do not copy historical APIBench AST matching as the main modern pattern. It is useful background, but BFCL's structured schemas and executable checks are stronger.

Do not assume benchmark data is static. Pin commit SHA and record category/data version for any published result.

## Fit For Agentic Coding Lab

Fit is in-scope and strong. Gorilla/BFCL is one of the best references for harness-eval research around tool/function calling.

Agentic Coding Lab should adapt BFCL's durable result artifacts, handler abstraction, deterministic call checkers, executable state checking, category weighting, and detailed logs. For coding agents, the natural extension is to replace BFCL's simulated APIs with repo/file/test/issue/CI backends and score final workspace state, tests, patch content, and safety invariants.

The repo should be used as a design reference rather than a direct dependency unless the target is specifically function-calling leaderboard work. BFCL's benchmark data and provider matrix are heavy, but the architectural patterns are portable.

## Reviewed Paths

- `/tmp/myagents-research/ShishirPatil-gorilla/README.md`
- `/tmp/myagents-research/ShishirPatil-gorilla/berkeley-function-call-leaderboard/README.md`
- `/tmp/myagents-research/ShishirPatil-gorilla/berkeley-function-call-leaderboard/TEST_CATEGORIES.md`
- `/tmp/myagents-research/ShishirPatil-gorilla/berkeley-function-call-leaderboard/CONTRIBUTING.md`
- `/tmp/myagents-research/ShishirPatil-gorilla/berkeley-function-call-leaderboard/LOG_GUIDE.md`
- `/tmp/myagents-research/ShishirPatil-gorilla/berkeley-function-call-leaderboard/CHANGELOG.md`
- `/tmp/myagents-research/ShishirPatil-gorilla/berkeley-function-call-leaderboard/SUPPORTED_MODELS.md`
- `/tmp/myagents-research/ShishirPatil-gorilla/berkeley-function-call-leaderboard/pyproject.toml`
- `/tmp/myagents-research/ShishirPatil-gorilla/berkeley-function-call-leaderboard/openfunctions_evaluation.py`
- `/tmp/myagents-research/ShishirPatil-gorilla/berkeley-function-call-leaderboard/bfcl_eval/__main__.py`
- `/tmp/myagents-research/ShishirPatil-gorilla/berkeley-function-call-leaderboard/bfcl_eval/_llm_response_generation.py`
- `/tmp/myagents-research/ShishirPatil-gorilla/berkeley-function-call-leaderboard/bfcl_eval/utils.py`
- `/tmp/myagents-research/ShishirPatil-gorilla/berkeley-function-call-leaderboard/bfcl_eval/constants/`
- `/tmp/myagents-research/ShishirPatil-gorilla/berkeley-function-call-leaderboard/bfcl_eval/model_handler/base_handler.py`
- `/tmp/myagents-research/ShishirPatil-gorilla/berkeley-function-call-leaderboard/bfcl_eval/model_handler/utils.py`
- `/tmp/myagents-research/ShishirPatil-gorilla/berkeley-function-call-leaderboard/bfcl_eval/model_handler/api_inference/openai_response.py`
- `/tmp/myagents-research/ShishirPatil-gorilla/berkeley-function-call-leaderboard/bfcl_eval/model_handler/api_inference/claude.py`
- `/tmp/myagents-research/ShishirPatil-gorilla/berkeley-function-call-leaderboard/bfcl_eval/model_handler/api_inference/gorilla.py`
- `/tmp/myagents-research/ShishirPatil-gorilla/berkeley-function-call-leaderboard/bfcl_eval/model_handler/local_inference/base_oss_handler.py`
- `/tmp/myagents-research/ShishirPatil-gorilla/berkeley-function-call-leaderboard/bfcl_eval/model_handler/parser/`
- `/tmp/myagents-research/ShishirPatil-gorilla/berkeley-function-call-leaderboard/bfcl_eval/eval_checker/eval_runner.py`
- `/tmp/myagents-research/ShishirPatil-gorilla/berkeley-function-call-leaderboard/bfcl_eval/eval_checker/eval_runner_helper.py`
- `/tmp/myagents-research/ShishirPatil-gorilla/berkeley-function-call-leaderboard/bfcl_eval/eval_checker/ast_eval/`
- `/tmp/myagents-research/ShishirPatil-gorilla/berkeley-function-call-leaderboard/bfcl_eval/eval_checker/multi_turn_eval/`
- `/tmp/myagents-research/ShishirPatil-gorilla/berkeley-function-call-leaderboard/bfcl_eval/eval_checker/agentic_eval/`
- `/tmp/myagents-research/ShishirPatil-gorilla/berkeley-function-call-leaderboard/bfcl_eval/data/README.md`
- `/tmp/myagents-research/ShishirPatil-gorilla/berkeley-function-call-leaderboard/bfcl_eval/data/BFCL_v4_*.json` sampled across simple, multiple, parallel, irrelevance, live, multi-turn, web-search, memory, and format-sensitivity categories.
- `/tmp/myagents-research/ShishirPatil-gorilla/berkeley-function-call-leaderboard/bfcl_eval/data/possible_answer/BFCL_v4_*.json` sampled across matching categories.
- `/tmp/myagents-research/ShishirPatil-gorilla/berkeley-function-call-leaderboard/bfcl_eval/data/multi_turn_func_doc/`
- `/tmp/myagents-research/ShishirPatil-gorilla/berkeley-function-call-leaderboard/bfcl_eval/data/memory_prereq_conversation/`
- `/tmp/myagents-research/ShishirPatil-gorilla/berkeley-function-call-leaderboard/bfcl_eval/scripts/`
- `/tmp/myagents-research/ShishirPatil-gorilla/gorilla/eval/README.md`
- `/tmp/myagents-research/ShishirPatil-gorilla/gorilla/eval/get_llm_responses.py`
- `/tmp/myagents-research/ShishirPatil-gorilla/gorilla/eval/get_llm_responses_retriever.py`
- `/tmp/myagents-research/ShishirPatil-gorilla/gorilla/eval/eval-scripts/ast_eval_hf.py`
- `/tmp/myagents-research/ShishirPatil-gorilla/gorilla/eval/eval-scripts/ast_eval_th.py`
- `/tmp/myagents-research/ShishirPatil-gorilla/gorilla/eval/eval-scripts/ast_eval_tf.py`
- `/tmp/myagents-research/ShishirPatil-gorilla/gorilla/eval/eval-data/questions/` sampled.
- `/tmp/myagents-research/ShishirPatil-gorilla/data/README.md`
- `/tmp/myagents-research/ShishirPatil-gorilla/data/api/` sampled.
- `/tmp/myagents-research/ShishirPatil-gorilla/data/apibench/` sampled.
- `/tmp/myagents-research/ShishirPatil-gorilla/openfunctions/README.md`
- `/tmp/myagents-research/ShishirPatil-gorilla/openfunctions/openfunctions-v1/gorilla_openfunctions_v1_test.json` sampled.

## Excluded Paths

- `/tmp/myagents-research/ShishirPatil-gorilla/.git/`: VCS internals; exact reviewed commit recorded separately.
- `/tmp/myagents-research/ShishirPatil-gorilla/.github/`, `.agents/`, `.codex/`, `.devcontainer/`: repository automation and local agent/devcontainer metadata, not core eval architecture.
- `/tmp/myagents-research/ShishirPatil-gorilla/agent-arena/client/`: React UI for Agent Arena; UI-only and outside BFCL function-call harness.
- `/tmp/myagents-research/ShishirPatil-gorilla/agent-arena/evalutation/`: sampled only via top-level README context; ELO notebooks/ratings are a separate agent-arena benchmark, not BFCL tool-call scoring.
- `/tmp/myagents-research/ShishirPatil-gorilla/raft/`: RAFT fine-tuning workflow and sample PDFs/images; unrelated to tool/function-call eval harness.
- `/tmp/myagents-research/ShishirPatil-gorilla/goex/`: execution-engine project with Docker/database/API side-effect abstractions; related conceptually, but not on the BFCL scoring path reviewed here.
- `/tmp/myagents-research/ShishirPatil-gorilla/gorilla/inference/`: model serving/demo path and image/gif assets; not eval architecture.
- `/tmp/myagents-research/ShishirPatil-gorilla/openfunctions/inference_*.py` and model-serving utilities: sampled docs only; model inference product path, not benchmark harness internals.
- `/tmp/myagents-research/ShishirPatil-gorilla/data/apizoo/`: large community API catalog; schema sampled through `data/README.md`, but individual API submissions are dataset content rather than harness logic.
- `/tmp/myagents-research/ShishirPatil-gorilla/berkeley-function-call-leaderboard/bfcl_eval/data/unused_datasets/`: retired executable/REST/SQL/chatable/composite datasets; noted as excluded by current evaluator.
- `/tmp/myagents-research/ShishirPatil-gorilla/gorilla/eval/eval-scripts/codebleu/parser/tree-sitter-python/` and `my-languages.so`: vendored/generated parser source and binary; reviewed only enough to identify legacy AST dependency.
- Binary/UI/generated assets such as `architecture_diagram.png`, `gorilla/inference/*.png`, `gorilla/inference/*.gif`, `raft/**/*.png`, `raft/sample_data/*.pdf`, `agent-arena/client/package-lock.json`, `agent-arena/client/public/*`, `goex/docker/sqllite_docker/example_sqlite.db`, and `agent-arena/evalutation/Agent_Arena_Elo_Rating.ipynb`: not relevant to BFCL runtime/scoring logic.
