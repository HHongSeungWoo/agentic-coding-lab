# SqueezeAILab/LLMCompiler

- URL: https://github.com/SqueezeAILab/LLMCompiler
- Category: tool-use
- Stars snapshot: 1.9k (GitHub repository page, reviewed 2026-05-20; index snapshot was 1,851 on 2026-05-11)
- Reviewed commit: a00c9d35507507da70e8c637eee64efc8c1857ae
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong pattern source for parallel tool-use planning. LLMCompiler's useful idea is a compiler-shaped loop: prompt a planner to emit numbered tool calls, infer a DAG from `$id` references, dispatch ready tasks concurrently, then use a joiner LLM to synthesize or request a replan. It is research/eval code, not a production tool gateway: error handling, safety policy, sandboxing, schema enforcement, and observability are thin.

## Why It Matters

Most agent tool-use loops serialize reasoning, acting, and observing. That is easy to understand, but it wastes latency when a question decomposes into independent searches, calculations, file reads, tests, or repository inspections.

LLMCompiler shows a compact alternative: make the LLM produce a small executable plan with explicit data dependencies, then let a runtime schedule the independent parts. For Agentic Coding Lab, the valuable artifact is not the benchmark wrapper; it is the shape of a "plan compiler" for tool calls that can overlap independent work while preserving dependency order and final synthesis.

## What It Is

LLMCompiler is an ICML 2024 research implementation for parallel function calling. The public README and arXiv abstract describe three conceptual pieces: a function-calling planner, a task-fetching unit, and an executor. The code adds a joiner LLM that reads tool observations and either finishes or asks for another plan.

The repository is a small Python benchmark framework. It has one main runner, three benchmark configurations (`hotpotqa`, `movie`, and `parallelqa`), a custom LLMCompiler chain, a ReAct baseline, copied/simplified LangChain-style agent/chain helpers, Wikipedia search tools, an LLM-backed math tool, datasets, and result evaluation scripts.

## Research Themes

- Token efficiency: Moderate. Parallel planning can reduce repeated ReAct thought/action turns, and streaming mode starts execution before the whole plan is generated. Prompts are still large few-shot prompts, and replanning contexts concatenate prior plan/observation text without compression.
- Context control: Moderate. Tool context is only the user-provided tool descriptions plus few-shot examples; there is no dynamic retrieval, tool filtering, memory pruning, or artifact offload. The strongest context-control pattern is keeping intermediate observations in an action/observation scratchpad for the joiner rather than exposing every scheduler detail.
- Sub-agent / multi-agent: Low. There is one planner LLM, one joiner LLM, and concurrent tool tasks. The system is multi-call, not multi-agent.
- Domain-specific workflow: Moderate. Each benchmark defines domain prompts and tool descriptions. The `parallelqa` math tool description encodes domain rules about units, context, and when to pass search outputs as context.
- Error prevention: Limited. Planner prompts require unique increasing IDs, only provided actions, and `join()` last. The parser rejects unknown tool names. Top-level eval can convert exceptions into `"ERROR"`. There is no robust task timeout, retry, cancellation, approval, side-effect policy, or sandbox boundary.
- Self-learning / memory: Low. No durable memory or learning loop. Replanning can pass previous plan/observation context, but bundled configs set `max_replans` to 1.
- Popular skills: Useful skill patterns include "emit numbered calls with `$id` dependencies", "infer dependencies from `$id` markers", "schedule executable tasks only when dependencies resolve", "stream plan lines into the executor", and "separate final answer synthesis from tool execution".

## Core Execution Path

`run_llm_compiler.py` is the entrypoint. It selects a benchmark dataset, chooses benchmark-specific tools and prompts, creates an LLM for joining and a second LLM for planning, then constructs `LLMCompiler`. In non-ReAct mode, each dataset example is run through `agent.arun`; results are flushed to JSON after each example and summarized with accuracy and latency.

`LLMCompiler._acall` drives the compiler loop. For each replan iteration it creates a fresh `TaskFetchingUnit`. In blocking mode, `Planner.plan` calls the planner LLM, parses the full output into tasks, installs those tasks into the scheduler, and waits for `schedule()`. In streaming mode, `Planner.aplan` runs in a background task with `LLMCompilerCallback`; parsed tasks are pushed into an `asyncio.Queue`, and `TaskFetchingUnit.aschedule` schedules tasks as soon as they arrive.

`Planner.generate_llm_compiler_prompt` builds the planning prompt from tool descriptions plus a synthetic `join()` operation. The prompt tells the model to maximize parallelizability, use only provided actions, make IDs unique and increasing, refer to prior outputs as `$id`, always make `join()` last, and emit `<END_OF_PLAN>` after `join()`.

`LLMCompilerPlanParser` is the compiler front end. It uses regexes to parse optional `Thought:` lines and numbered calls like `3. search("Mount Everest")`. It parses arguments with `ast.literal_eval` when possible, finds the named tool, and infers dependencies by scanning the raw argument string for `$1` or `${1}`. A `join` task depends on every previous task.

`TaskFetchingUnit` is the runtime scheduler. It tracks tasks, `asyncio.Event` objects for completion, and remaining task IDs. Every scheduling tick it finds tasks whose dependencies are done, replaces `$id` markers in arguments with prior observations, launches ready tasks with `asyncio.create_task`, and marks a task done after its tool returns. Independent tasks therefore run concurrently; dependent tasks wait on events.

After tool execution, `LLMCompiler._acall` serializes each non-join task as thought/action/observation text. `LLMCompiler.join` appends this scratchpad to the joiner prompt and asks the agent LLM for `Action: Finish(answer)` or `Action: Replan(...)`. If replanning is requested and the iteration is not final, it formats previous plans and observations into a replanner context for the next planner call.

## Architecture

The architecture is small and direct:

- `src/llm_compiler/planner.py` owns prompt construction, planner LLM calls, streaming token parsing, and queue emission.
- `src/llm_compiler/output_parser.py` turns planner text into `Task` objects and dependency lists.
- `src/llm_compiler/task_fetching_unit.py` performs DAG scheduling and `$id` argument substitution.
- `src/llm_compiler/llm_compiler.py` coordinates planning, scheduling, scratchpad generation, joining, and replanning.
- `src/tools/base.py` defines LangChain-style `Tool` and `StructuredTool` wrappers, including optional pydantic schema inference for structured tools.
- `configs/*` hold benchmark-specific prompts, tools, and `max_replans`.
- `src/react/*`, `src/agents/*`, `src/executors/*`, and `src/chains/*` provide the ReAct baseline and copied/simplified LangChain compatibility code.

There is no separate server, registry, MCP layer, policy engine, plugin system, or persistent scheduler. The compiler is an in-process async chain.

## Design Choices

The most important design choice is using the planner output itself as an executable intermediate representation. Numbered function calls become tasks; `$id` markers become edges; `join()` becomes the required terminal operation.

Dependency inference is deliberately simple. The parser does not ask the model to emit a separate graph. Instead, it scans arguments for prior task IDs. This keeps the plan human-readable and compact, but it means malformed references can break scheduling or create missing-dependency errors.

The runtime separates planning from synthesis. Tools do not decide the final answer. The joiner sees a clean thought/action/observation transcript and decides whether to finish or replan. That keeps final response formatting out of individual tools.

Streaming is treated as a latency feature. In streaming mode, the parser emits a task whenever a complete plan line arrives. The scheduler can start early independent tasks while the planner is still generating later lines.

Tool descriptions carry substantial policy. The `parallelqa` math tool description tells the planner what not to do with search results, when to pass context, and how to reduce math calls. This is a pragmatic way to make planner behavior domain-specific without changing runtime code.

The shipped configs mostly disable the replanning story. `hotpotqa`, `movie`, and `parallelqa` all set `max_replans` to 1, so the final iteration forces `is_replan = False`. Replanning code exists, but the default examples evaluate one-shot planning plus joining.

## Strengths

The compiler-shaped IR is easy to inspect. A developer can read a plan, see which calls should run in parallel, and understand why later calls wait.

The DAG scheduler is small but expressive enough for common tool-use patterns: parallel lookups, dependent calculations, fan-in into synthesis, and optional replanning.

Streaming execution is a useful optimization. Starting tool calls as soon as the planner emits them is directly relevant to coding agents that can start independent file reads, searches, or tests before a full plan finishes.

The planner prompt has good low-level constraints: only known actions, unique increasing IDs, explicit `$id` dataflow, `join()` last, and no comments. These constraints translate well into agent skills or harness prompts.

The benchmark configs show how much tool reliability depends on descriptions. The math tool encodes concrete failure-prevention rules around units, context, and variable misuse.

The implementation is compact enough to study end to end. The core compiler path is only a few files rather than a framework spread across services.

## Weaknesses

Task failures can hang the scheduler. `_run_task` does not catch exceptions or set the completion event in a `finally` block. Because tasks are launched with `asyncio.create_task`, a tool exception can leave dependencies waiting forever.

Planner streaming failures can also hang. The planner task created in streaming mode is not awaited, so an exception before queue sentinel emission can leave `aschedule` waiting for tasks.

There are no per-tool timeouts, task limits, cancellation paths, concurrency budgets, or retry policies in the compiler scheduler. A slow or stuck tool can stall the whole run.

Parsing is fragile. The action regex is line-oriented, arguments are parsed opportunistically, dependency IDs are found by string scan, and joiner output parsing extracts text between the first `(` and first `)`. Parentheses in answers or malformed calls can produce wrong results.

Safety controls are benchmark-level only. The planner is told to use only listed actions, and parser lookup rejects unknown tool names, but user-provided tools can do anything. There is no permission model, side-effect classification, approval flow, sandbox, output schema validation, or audit log.

The math chain contains an unsafe pattern for production systems. `replace_min_max_functions` compiles and `eval`s an LLM-generated expression before `numexpr.evaluate` runs, so the later restricted `numexpr` globals do not fully protect the path.

Documentation and CLI drift exist. README examples use `--benchmark`, while the runner requires `--benchmark_name`.

Test coverage is sparse in-repo. There are datasets and evaluation scripts, but no obvious unit tests for parsing, dependency extraction, scheduling failures, streaming, or tool error behavior.

## Ideas To Steal

Use a textual task IR for agent tool plans: numbered calls, stable tool names, literal arguments, `$id` references, and one required terminal join step.

Infer the DAG from data references rather than asking the model for a separate graph object. Keep the first version simple and inspectable, then validate it strictly before execution.

Separate planner, scheduler, executor, and joiner responsibilities. A coding agent should be able to plan file reads/tests/searches, execute independent work in parallel, then synthesize from observations.

Stream plan tasks into the scheduler. For repository work, this could start `rg`, file reads, dependency checks, or test discovery while planning continues.

Make join/synthesis an explicit operation. The joiner should see normalized observations and decide finish versus replan, instead of letting every tool invocation mutate final answer state.

Put tool-use rules next to tool descriptions. Good tool descriptions can encode side-effect limits, argument rules, required context, batching advice, and known misuse patterns.

Record action/observation traces in a deterministic format. The trace can feed replanning, debugging, evals, and human review.

Use benchmark prompts as examples for skills: show the model exactly how to parallelize independent calls and how to wire dependent calls through `$id`.

## Do Not Copy

Do not launch background tool tasks without exception handling. Every task should set a terminal state: success, failure, cancellation, or timeout.

Do not execute LLM-generated code or expressions with raw `eval`. If a math/code tool is needed, use an AST allowlist, a sandboxed interpreter, or a restricted evaluator with tests.

Do not rely on prompt instructions as the only safety layer. Production tool-use needs registry policy, input validation, output validation, permission checks, side-effect labels, and user approval for risky operations.

Do not let malformed dependency references reach the scheduler. Validate missing IDs, duplicate IDs, unknown tools, out-of-order references, cycles, and unreachable joins before execution.

Do not hide streaming planner errors. The scheduler needs an explicit planner-failed sentinel and a way to cancel already-started tasks.

Do not concatenate unlimited observations into replanning context. Use summaries, artifacts, or bounded trace windows for coding tasks with large logs and files.

Do not copy README/CLI drift. Keep documented commands under test.

## Fit For Agentic Coding Lab

LLMCompiler is a high-value pattern source for a tool-use scheduler inside Agentic Coding Lab. It should not be copied as a dependency or trusted runtime.

A useful lab adaptation would be a local "tool plan compiler" with:

- Strict plan schema: numbered calls, args, dependencies, risk labels, expected outputs, and join step.
- Validation before execution: known tools, acyclic dependencies, present IDs, no duplicate IDs, type-checked args, max tasks, max concurrency, and side-effect policy.
- Parallel async scheduler with per-task timeout, cancellation, retry policy, and failure propagation.
- Streaming planner support with explicit planner completion/failure sentinels.
- Tool registry metadata: read/write/network/shell risk, required approval, input schema, output schema, artifact policy, and default timeout.
- Joiner/replanner that reads a bounded trace and structured failure records.
- Deterministic trace logs for review, tests, and future synthesis notes.

The strongest reusable design is "plan once, run DAG, join, replan only when needed." The weakest part to avoid is treating a research prompt and a regex parser as a full safety boundary.

## Reviewed Paths

- `README.md` for installation, benchmark usage, streaming option, model endpoints, custom benchmark guidance, and integration claims.
- `run_llm_compiler.py` for CLI arguments, dataset selection, model selection, LLMCompiler construction, ReAct baseline selection, result flushing, and eval loop.
- `src/llm_compiler/llm_compiler.py` for async-only compiler orchestration, blocking versus streaming planning, scratchpad generation, joiner prompting, replanning context, and stats.
- `src/llm_compiler/planner.py` for planner prompt construction, `join()` description, planner LLM calls, streaming parser callback, and queue sentinel behavior.
- `src/llm_compiler/output_parser.py` for action regexes, argument parsing, tool lookup, dependency extraction, and `Task` instantiation.
- `src/llm_compiler/task_fetching_unit.py` for dependency events, `$id` replacement, concurrent scheduling, and streaming task intake.
- `src/tools/base.py` and `src/agents/tools.py` for tool wrappers, pydantic schema inference, async wrapping, invalid-tool handling, and tool errors.
- `configs/hotpotqa/*`, `configs/movie/*`, and `configs/parallelqa/*` for benchmark prompts, tool descriptions, `max_replans`, and action examples.
- `src/docstore/wikipedia.py` for Wikipedia search behavior, alternative-title retry, async HTTP calls, and output truncation.
- `src/chains/llm_math_chain.py` and `configs/parallelqa/tools.py` for math tool prompting, expression execution, unit/context guidance, and invalid-expression behavior.
- `src/react/*`, `src/agents/agent.py`, and `src/executors/agent_executor.py` for the ReAct baseline, parser error handling, invalid-tool fallback, iteration/time limits, and async parallel action handling outside LLMCompiler.
- `src/chains/llm_chain.py` for stop token handling and prompt-shortening retry behavior.
- `src/callbacks/callbacks.py` for latency and token stats collection.
- `src/utils/model_utils.py` for OpenAI, Azure, vLLM, and Friendli model boundaries and environment variable requirements.
- `src/utils/evaluation_utils.py` and `evaluate_results.py` for exception-to-`ERROR` behavior, answer normalization, latency stats, and token summaries.
- `requirements.txt` for core dependency footprint.
- arXiv abstract page for paper metadata, component framing, and reported speed/cost/accuracy claims.

## Excluded Paths

- `datasets/*.json`: benchmark corpora and labels. They were size-scanned and sampled by path, but not deeply read because they do not define execution behavior.
- `figs/thumbnail.png`: binary README image, unrelated to tool execution or safety.
- `configs/*_react/**`: ReAct baseline prompts and tools. These were only read selectively where they clarified baseline behavior, not treated as core LLMCompiler design.
- Most copied LangChain-style plumbing in `src/chains/chain.py`, `src/agents/*`, and `src/executors/*`: read selectively for error handling and baseline behavior, but excluded from deep design analysis because the novel compiler path is in `src/llm_compiler/*`.
- `.git/**`, `.gitignore`, and repository metadata: version-control artifacts, not runtime design.
- `LICENSE`: legal metadata, not execution behavior.
