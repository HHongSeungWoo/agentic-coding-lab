# zai-org/ComplexFuncBench

- URL: https://github.com/zai-org/ComplexFuncBench
- Category: tool-use
- Stars snapshot: 180 via GitHub REST API on 2026-05-29
- Reviewed commit: c37b284e2f2e03ee456115b7c4b7e537f534be37
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong benchmark reference for complex native function-calling evaluation: multi-step calls, same-turn parallel calls, constrained and implicit argument reasoning, long opaque parameter values, long API observations, and cross-domain travel workflows. Best reused as an eval design and dataset-schema reference, not as a production coding-agent harness, because scoring depends on live model/API services, unpinned dependencies, no tests, and limited reproducibility controls.

## Why It Matters

ComplexFuncBench matters because it targets tool-use failures that simple function-calling benchmarks often miss: a model must select several APIs, use returned identifiers in later calls, satisfy user constraints, make date/location/value inferences, survive large JSON observations, and then produce a final natural-language answer. The dataset is also practical for coding-agent research because many coding workflows have the same shape: search or inspect, carry exact values forward, call another tool, combine results, and stop only after enough evidence has been gathered.

The most useful idea is the gold trajectory format. Each sample exposes the user request, the available tool schemas, the expected assistant tool calls, and saved observations. The evaluator replays saved observations when predicted calls match, so the model experiences a realistic multi-step environment without calling the real API for every step. This is directly adaptable to coding-agent evals where tools might be file search, AST queries, test runs, package metadata lookup, or issue/PR APIs.

## What It Is

ComplexFuncBench is a Python evaluation harness plus an external Hugging Face dataset for complex function calling. The GitHub repo contains runners for GPT, Claude, GLM, Qwen, Llama, and Mistral; a scoring module called `CompareFC`; prompt templates for LLM-based call comparison and final-response judging; RapidAPI metadata for Booking.com-style endpoints; and a small result printer.

The dataset is not vendored in the GitHub repo. It is published on Hugging Face as `zai-org/ComplexFuncBench` with dataset commit `5dc7739343f8c87aee465931ba66db13a0fb5dd4`; the repo README still points at `THUDM/ComplexFuncBench`, which redirects in practice. I downloaded `ComplexFuncBench.jsonl` into the `/tmp` checkout for review. It contains 1,000 JSONL rows with keys `id`, `functions`, and `conversations`.

Dataset shape from the reviewed snapshot:

- Domains: `Hotels` 150, `Flights` 150, `Car-Rental` 150, `Attraction` 150, and `Cross` 400.
- Tool schemas: 40 unique function names observed in the dataset, with 3 to 10 available functions per sample and an average of 5.76.
- Trajectories: 2 to 5 tool-call turns per sample, average 3.26; 2 to 11 total function calls per sample, average 5.07.
- Long context: serialized conversations range from 3,476 to 229,227 characters, average 34,994.6; serialized observations average 33,516.6 characters.
- Long values: many flight `token` and `offerToken` arguments exceed 500 characters; the max observed argument value was 710 characters.

## Research Themes

- Token efficiency: Medium. The benchmark stresses long contexts and large observations, but the harness mostly forwards full observations and tool schemas. It does not implement retrieval, truncation, observation summarization, or adaptive context packing.
- Context control: Medium. Per-sample `functions` limits visible tools, and provider runners convert only those tools for each request. There is no broader registry-selection layer or explicit context-budget policy.
- Sub-agent / multi-agent: None. The repo evaluates a single model loop per sample.
- Domain-specific workflow: High. Tasks are grounded in travel workflows over hotels, flights, car rentals, attractions, taxis, and cross-domain combinations, with real API-shaped responses and domain identifiers.
- Error prevention: Medium. The evaluator checks function existence, required parameters, extra parameters, parameter types, exact-match-critical values, response equivalence, and LLM semantic equivalence. It lacks tests, deterministic replay for all scoring branches, and a safe execution boundary for arbitrary model outputs.
- Self-learning / memory: None. Results, generated conversations, per-sample logs, and aggregate metrics are written, but there is no durable learning or memory loop.
- Popular skills: Function-call benchmark schema, multi-step tool replay, provider-specific tool-call adapters, exact/semantic call scoring, API-response-based equivalence, LLM-as-judge response scoring, long-context tool-use evaluation.

## Core Execution Path

`evaluation.py` defines the CLI and model registry. It expects `data/ComplexFuncBench.jsonl` by default, although the repository does not include that path. The CLI requires `--model_name`, supports `--vllm_url` for local OpenAI-compatible servers, chooses a runner from `MODEL_MAPPING`, creates `result/{model_name}/{exp_name}.jsonl`, and can use multiprocessing through `--proc_num`.

For each sample, `process_example` creates a per-sample logger, instantiates the provider runner, and instantiates `RespEvalRunner`. It counts the gold assistant turns that contain `function_call` and the total gold call count, then calls `model.run(data)`.

Every provider runner follows the same loop. It starts with only the user query, converts the sample's `functions` into provider-specific tool schemas, and calls `init_golden`. `init_golden` extracts the gold function-call chain and matching observation chain from `conversations`, then sets the current gold calls and observations. Some lookup functions are treated as optional "free functions" and can be skipped or removed when only free lookups remain.

On each model turn, the runner asks the model for tool calls or a final response. If tool calls are returned, the runner normalizes provider output into the repo's common shape:

```json
{"name": "Search_Flights", "arguments": {"fromId": "...", "toId": "..."}}
```

The runner passes predicted calls, gold calls, gold observations, function schemas, and history to `CompareFC.compare_turn_prediction`. Successful predicted calls are mapped to saved gold observations and appended back into the model conversation as tool results. Format errors receive structured error objects; unexpected calls receive a generic API problem message. The loop continues until the model emits content instead of tool calls or fails early.

`CompareFC` scores calls in layers. First it checks schema format: function name exists, required parameters are present, no unknown parameters are included, and values have JSON-schema-compatible primitive types. It maps predicted calls to gold calls using exact matches first, then BGE embeddings plus Hungarian matching for remaining calls. It then compares each mapped pair through exact/rule matching, exact-match-critical parameter validation from `utils/exact_match_values.json`, live RapidAPI response equality, and finally GPT-based semantic equivalence using `prompts/compare.py`.

If the model emits a final assistant response, `RespEvalRunner` calls `gpt-4o-2024-08-06` twice: once for completeness against the original query and once for correctness against the gold conversation history and saved API observations. These scores are reported separately from call accuracy.

`print_results.py` aggregates results into domain success rate, domain call accuracy, overall success rate, overall call accuracy, and average completeness/correctness scores. It uses fixed denominators of 150 per single domain, 400 for cross-domain, and 1,000 overall, so it is only correct for full official runs.

## Architecture

The architecture is a small research harness, not a reusable service. The main boundaries are:

- `evaluation.py`: orchestration, CLI, multiprocessing, result JSONL writing, and model dispatch.
- `runner/base_runner.py`: shared gold-chain state, optional free-function handling, success-turn calculation, and result finalization.
- `runner/*_runner.py`: provider adapters for OpenAI, Anthropic, Zhipu/GLM, DashScope/Qwen, vLLM-hosted Llama, and Mistral.
- `models/*.py`: API clients and prompt formatting for provider calls.
- `utils/compare_method.py`: core function-call scorer.
- `utils/rapidapi.py` and `utils/tool_info.json`: live Booking.com15 RapidAPI endpoint metadata.
- `prompts/compare.py` and `prompts/response.py`: LLM judges for semantic call equivalence and final-response evaluation.
- `print_results.py`: aggregate reporting.

The task schema is simple and useful. Each row is self-contained:

- `id`: domain-prefixed sample id such as `Flights-49` or `Cross-38`.
- `functions`: a list of OpenAI-style JSON Schema function definitions with `name`, `description`, `parameters.properties`, and `parameters.required`.
- `conversations`: an alternating trace: initial `user`, one or more `assistant` turns with `function_call`, matching `observation` turns with saved API responses, and a final blank `assistant` content turn marking that the model should answer.

The tool universe comes from Booking.com15-style endpoints. Common functions include `Search_Flight_Location`, `Search_Car_Rentals`, `Search_Hotel_Destination`, `Search_Flights`, `Search_Hotels`, `Search_Attraction_Location`, `Search_Taxi`, `Search_Attractions`, `Get_Flight_Details`, `Get_Seat_Map`, and cross-domain lookup/detail calls. Tool schemas include required parameter lists, basic types, descriptions, and occasional enum/default documentation.

## Design Choices

The dataset uses gold trajectories rather than only final answers. This enables stepwise evaluation: a model gets credit for correct calls and receives observations only for matched calls. It also exposes where a run stopped early, hallucinated a function, missed a parameter, or produced a wrong value.

The harness supports multiple calls in one assistant turn. That is important because many samples require parallel lookups, such as searching two locations or comparing two dates before proceeding to dependent detail calls.

The scorer separates strict and soft equivalence. Some parameters must match exactly because they are identifiers, dates, currencies, coordinates, or opaque tokens. Other differences can pass if the API response is equal or if an LLM judge determines semantic equivalence.

Saved observations are used for matched calls, while live RapidAPI calls are reserved for response-based equivalence. This reduces live API dependency during the model interaction itself, but scoring can still depend on RapidAPI availability when exact/value checks are insufficient.

Provider adapters normalize model-specific tool-call protocols into one internal call format. OpenAI/Mistral/GLM API paths use native tool calls, Claude maps Anthropic `tool_use` blocks, Qwen uses OpenAI-compatible DashScope responses, Llama uses prompt-formatted JSON-like calls through vLLM completions, and GLM vLLM uses a custom ChatGLM prompt.

The final natural-language answer is evaluated by a separate LLM judge instead of a gold reference answer. The final gold assistant turn in the dataset is blank, so correctness is judged against the saved API-observation history, not reference text.

## Strengths

- Strong benchmark coverage for realistic multi-step tool workflows with dependent identifiers, same-turn parallel calls, temporal reasoning, constraints, and cross-domain composition.
- Dataset rows are self-contained: user query, visible tool schemas, gold calls, and saved API observations live together.
- Uses real API-shaped observations, including very large nested JSON responses, which stresses long-context tool-result handling.
- Stepwise replay gives partial credit and useful error localization through success turns and correct-call counts.
- The scoring stack is richer than exact match alone: format checks, exact-match-critical values, live response equivalence, embedding-based call mapping, and LLM semantic comparison.
- Provider adapters show practical differences among OpenAI, Claude, GLM, Qwen, Llama, and Mistral tool-call surfaces.
- Result records preserve generated conversations, message/error details, count dictionaries, and response-judge outputs for postmortem review.
- The benchmark is compact enough to audit: the repo has about 30 source/config files, and the dataset has 1,000 rows.

## Weaknesses

- The GitHub repo does not include the dataset, and the documented default input path is absent. Users must fetch `ComplexFuncBench.jsonl` from Hugging Face and place it manually.
- Metadata is inconsistent: the README points to `THUDM/ComplexFuncBench`, the current Hugging Face API reports `zai-org/ComplexFuncBench`, and the dataset card's statistics table says `Total` 600 even though the JSONL has 1,000 rows.
- The five advertised complexity aspects are not exposed as explicit per-example labels in the JSONL. Domain and ID are present, but multi-step, constraints, implicit value reasoning, long values, and long-context cases are not directly stratified.
- Reproducibility depends on many external services: model APIs, vLLM servers, OpenAI for final-response judging, OpenAI for semantic call comparison, RapidAPI for response equivalence, and Hugging Face/FlagEmbedding for BGE embeddings.
- Dependencies are mostly unpinned. Only `torch==2.3.0` is fixed; SDK, NumPy, SciPy, Requests, FlagEmbedding, and provider libraries can drift.
- There are no tests or CI files. I found no test directory or pytest/unittest entrypoint in the checked-out repo.
- `CompareFCBase` loads `BAAI/bge-large-en-v1.5`, creates a RapidAPI client, and creates an OpenAI judge client in the scorer constructor. Because each `process_example` instantiates a runner, this can be expensive and fragile under multiprocessing.
- `print_results.py` hard-codes official dataset denominators, so debug runs, subset runs, or failed/skipped rows produce misleading success rates.
- Some adapter paths are research-grade. The Llama runner uses `eval` while decoding model output, GLM prompt construction shuffles tool order, `.env` names `ZHIPUAI_API_KEY` while code reads `ZHIPU_API_KEY`, and provider SDK behavior may have drifted since the January 2025 commits.
- The repo has no explicit license in GitHub metadata. The Hugging Face dataset card lists Apache-2.0, but code reuse licensing is unclear from the repo snapshot.

## Ideas To Steal

- Use a task row schema that bundles `id`, visible tool schemas, expected tool-call trajectory, and saved observations.
- Replay saved observations after matched calls so the evaluation environment is mostly deterministic and cheap.
- Score tool use step by step, not only by final answer, and record both turn progress and call accuracy.
- Support same-turn multi-call batches because real workflows often require parallel lookups before dependent calls.
- Keep an exact-match-critical parameter list per function so identifiers, dates, coordinates, and opaque tokens are treated more strictly than cosmetic arguments.
- Combine multiple equivalence strategies: exact match, schema validation, semantic comparison, and response equivalence.
- Separate call accuracy from final-response completeness/correctness so a model that calls tools well but explains poorly is distinguishable from one that never gets the data.
- Keep generated conversations and structured error types in each result row for debugging and leaderboard audits.
- Use cross-domain tasks as first-class samples, not an afterthought; they expose registry scoping and context-management failures quickly.

## Do Not Copy

- Do not depend on live third-party APIs during default scoring unless responses are cached, versioned, and provenance-stamped.
- Do not use LLM judges as the only correctness authority for final answers when deterministic state or assertion-based checks are possible.
- Do not load heavyweight embedding models and API clients per sample in a large multiprocessing run. Initialize shared or per-worker resources explicitly.
- Do not hard-code official dataset denominators in result printers if the harness supports debug/subset runs.
- Do not expose a model-output `eval` path in a coding-agent runtime. Parse JSON or AST into a validated call envelope and dispatch by tool id.
- Do not leave complexity categories implicit. Add labels for task type, required call count, required domains, long-context size, long-value fields, and constraint classes.
- Do not rely on unpinned SDKs and moving provider APIs for benchmark reproducibility.
- Do not track a real `.env` file pattern in a public repo, even if values are blank; use `.env.example` and document every required variable consistently.

## Fit For Agentic Coding Lab

Fit is high as a benchmark/task-schema reference and medium as executable harness code. Agentic Coding Lab should borrow the gold trajectory format, stepwise replay, multi-call turn support, exact-critical-parameter checks, cross-domain task construction, and split metrics for tool calls versus final response.

For coding-agent applicability, map the same design onto deterministic local tools: repo search, file read snippets, AST/symbol lookup, package metadata, test execution, static analysis, issue/PR APIs, and patch application. The saved observations become controlled file/test/tool outputs. Scoring should prefer final repo state, tests, and structured assertions over live APIs or LLM judges.

The benchmark also highlights a useful stress pattern for coding agents: long tool outputs are part of the task, not noise. A coding lab can create tasks where the agent must mine a large test log, dependency graph, search result, or generated trace, carry exact values into later tool calls, and produce a concise final fix explanation.

Before adopting code, the lab would need deterministic fixtures, pinned dependencies, explicit task labels, safer parsing, cached judges if any, per-worker resource initialization, and a stronger sandbox/permission model around side-effecting tools.

## Reviewed Paths

- `/tmp/myagents-research/zai-org-complexfuncbench/README.md`: project framing, claimed coverage, leaderboard, evaluation instructions, external dataset link, model-serving assumptions, and citation.
- `/tmp/myagents-research/zai-org-complexfuncbench/evaluation.py`: CLI, model mapping, input/output paths, multiprocessing, per-example loop, result schema, response-eval invocation, and resume behavior.
- `/tmp/myagents-research/zai-org-complexfuncbench/print_results.py`: aggregate metrics, hard-coded denominators, domain parsing, and completeness/correctness averaging.
- `/tmp/myagents-research/zai-org-complexfuncbench/runner/base_runner.py`: gold trajectory extraction, free-function handling, success-turn calculation, match postprocessing, and result finalization.
- `/tmp/myagents-research/zai-org-complexfuncbench/runner/gpt_runner.py`, `claude_runner.py`, `glm_runner.py`, `qwen_runner.py`, `llama_runner.py`, and `mistral_runner.py`: provider-specific schema conversion, tool-call decoding, observation replay, and stop/failure handling.
- `/tmp/myagents-research/zai-org-complexfuncbench/runner/response_runner.py`: GPT-based completeness and correctness evaluation for final generated responses.
- `/tmp/myagents-research/zai-org-complexfuncbench/models/gpt.py`, `claude.py`, `glm.py`, `qwen.py`, `llama.py`, and `mistral.py`: API clients, environment variables, retry behavior, custom prompt formatting, vLLM/OpenAI-compatible paths, and provider-specific assumptions.
- `/tmp/myagents-research/zai-org-complexfuncbench/utils/compare_method.py`: `CompareFC`, schema checks, exact/value/response/LLM-based equivalence, BGE embedding matching, free-function bookkeeping, and error messages.
- `/tmp/myagents-research/zai-org-complexfuncbench/utils/rapidapi.py`: RapidAPI request construction, endpoint dispatch, response normalization, retry behavior, and observation shortening helper.
- `/tmp/myagents-research/zai-org-complexfuncbench/utils/tool_info.json`: Booking.com15 endpoint map used for live response-based equivalence.
- `/tmp/myagents-research/zai-org-complexfuncbench/utils/exact_match_values.json`: per-function exact-critical parameters.
- `/tmp/myagents-research/zai-org-complexfuncbench/utils/utils.py` and `utils/logger.py`: JSONL loading/saving, brittle JSON cleanup, retry decorator, and logging setup.
- `/tmp/myagents-research/zai-org-complexfuncbench/prompts/compare.py`, `response.py`, and `prompts.py`: LLM judge prompts and simple template renderer.
- `/tmp/myagents-research/zai-org-complexfuncbench/requirements.txt` and `.env`: dependency surface, pinned/unpinned packages, required credentials, and environment-variable mismatch.
- Hugging Face dataset `zai-org/ComplexFuncBench` API metadata and downloaded `ComplexFuncBench.jsonl`: dataset commit `5dc7739343f8c87aee465931ba66db13a0fb5dd4`, row count, schema, domain distribution, function counts, trajectory lengths, long-observation examples, and representative task examples. The downloaded JSONL was used only inside `/tmp/myagents-research/zai-org-complexfuncbench` for review.
- Git metadata and GitHub REST repository endpoint: reviewed commit, default branch, recent commit history, stars/forks/open issues, repository license snapshot, and current owner/name metadata.

## Excluded Paths

- `/tmp/myagents-research/zai-org-complexfuncbench/resources/*.png`: README diagrams and visual assets only. They illustrate data collection/evaluation flow but do not define executable behavior or schemas.
- Exhaustive manual review of all 1,000 downloaded JSONL rows: I computed aggregate statistics and inspected representative examples, including long-context/cross-domain cases, but did not manually read every large API observation because the execution design lives in the harness and schema.
- Generated outputs under `logs/**` and `result/**`: not present in the checked-out repo before running evaluations, and no model evaluation was run because it would require paid/provider credentials and RapidAPI access.
- Live RapidAPI calls for arbitrary benchmark examples: reviewed the calling code and endpoint metadata, but did not exercise live Booking.com15 APIs because that requires a subscribed RapidAPI key and would not be deterministic.
- Full dependency installation or model-serving reproduction: not run because the review task is repository analysis, and a faithful run would require model API keys, optional vLLM-hosted models, GPU-capable embedding/model infrastructure, and external paid services.
- `.git/**` internals: used only for commit provenance and recent history, not reviewed as project logic.
