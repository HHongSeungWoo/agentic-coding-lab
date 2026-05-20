# StonyBrookNLP/appworld

- URL: https://github.com/StonyBrookNLP/appworld
- Category: tool-use
- Stars snapshot: 421 via GitHub REST API on 2026-05-20
- Reviewed commit: a072b7a86e7c1d5b1d7175659d750ebb9b79f10a
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong reference for stateful tool-use evaluation, schema projection, MCP bridging, and execution logging. Best patterns are the single source of truth for API docs, `AppWorld.execute` transcript/state capture, task completion/evaluation boundary, and local/remote/docker/MCP execution modes. Do not copy its in-process safety guard as a real sandbox, and isolate task data/outputs more strictly for coding agents.

## Why It Matters

AppWorld is a benchmark and runtime for agents that solve tasks by calling many application APIs through code, function calling, or MCP. It matters for Agentic Coding Lab because it is not just a tool-schema collection: it owns the whole harness around a task world, including task specs, app state, API docs, code execution, request tracking, logs, checkpoints, completion signal, and state-based evaluation.

The most reusable idea is a controlled world with no-consequence tools but real side effects in task-local databases. An agent can make many API calls, write code, recover from errors, and finally call `supervisor.complete_task()`. The evaluator then checks final database state and answer correctness, not whether the trajectory looked like the reference solution.

## What It Is

The repo contains the `appworld` Python package and a companion `appworld-agents` experiment package. The core package exposes:

- `AppWorld`, the task environment and execution harness.
- `Requester` and `ApiCollection`, which turn app APIs into `apis.spotify.like_song(...)` style Python functions and REST requests.
- `ApiDocCollection` and `prepare_api_docs`, which project the same FastAPI/OpenAPI source into `standard`, OpenAI function-calling, MCP, SmolAgents, and OpenAPI formats.
- CLI servers for `environment`, `apis`, and `mcp`, with optional Docker execution.
- `Task`, `GroundTruth`, and evaluator code for loading task specs, controlling leakage, and scoring final state.

The public repo also has experiment agents: simplified ReAct/code/function-calling agents, OpenAI Agents SDK + MCP integration, and SmolAgents integration. The actual app implementations, some package tests, and data/task generation code are released as encrypted Git LFS `.bundle` files and are not plain source in this checkout.

## Research Themes

- Token efficiency: Strong. AppWorld exposes compressed API docs, response-schema toggles, field removal, app descriptions, API retrieval before function calling, and agent-side history trimming. Baseline agents first predict a small API set from roughly 457 APIs, then expose only predicted tools.
- Context control: Strong. `Task` separates instruction, supervisor identity, datetime, app descriptions, API docs, and ground truth. API docs can be exposed in multiple formats or queried through the `api_docs` app. Ground truth has `minimal`, `partial`, and `full` modes to avoid leaking solutions.
- Sub-agent / multi-agent: Low for agent orchestration, strong for parallel harness operation. AppWorld focuses on one task world per process/server, but `AppWorldInitializer` and guides handle multiple server URLs and batch parallelization.
- Domain-specific workflow: High. The domain model is daily apps plus a supervisor app. Tasks require realistic multi-app workflows, authentication, database mutation, and explicit task completion.
- Error prevention: Strong at harness level. It has syntax and execution safety checks, API call limits, max interaction limits, timeouts, extra-parameter checks, path-parameter validation, request tracking, structured logs, checkpointing, state reload, and verification against released solutions.
- Self-learning / memory: Low. It stores task state, logs, API calls, usage, and checkpoints, but does not learn durable preferences or policies across tasks.
- Popular skills: Function calling, MCP server/client, code execution harness, API schema projection, tool retrieval, task-world checkpoints, Docker/remote execution, terminal-agent evaluation, and state-based scoring.

## Core Execution Path

`Task.load(task_id)` reads task specs from `data/tasks/{task_id}/specs.json`, loads the supervisor profile, datetime, DB version, app descriptions, API docs, and optional ground truth. `GroundTruth.load` controls how much solution metadata is exposed: `minimal` still provides evaluation files and answer data, while `partial`/`full` add required apps/APIs and solution/generator material when available.

`AppWorld.__init__` resolves defaults, loads the task, validates DB version, creates output paths under `experiments/outputs/{experiment_name}/tasks/{task_id}`, chooses local or remote mode, creates an IPython `InteractiveShellEmbed` for local execution, and calls `initialize`.

Local `initialize` closes old global clients/state, prepares output directories, writes code/data version files, executes the preamble, freezes task datetime, saves initial DB state, and writes logs. The preamble imports a curated set of standard libraries, installs safe `print` behavior, blocks `input`, and creates `apis` plus `requester` through `ApiCollection.load`.

`ApiCollection.load` creates a `Requester`, then wraps each app API as a callable. `Requester` uses FastAPI `TestClient` in unified local mode, `requests` in remote API mode, or `MCPClient.call_tool` in MCP mode. It tracks every non-admin request, validates extra parameters when enabled, handles path parameters, moves `access_token` into HTTP auth headers, converts responses to JSON, and can wrap/unwrap MCP responses under a `response` key.

`AppWorld.execute(code)` is the main boundary. In remote environment mode, it POSTs to `/execute`. In local mode, it checks syntax against `SafetyGuard`, resets per-interaction request count, enforces max interactions, enables runtime monkey patches when configured, parses syntax errors before running, executes code in IPython with optional timeout, captures stdout/stderr/display output, normalizes stack traces, increments interaction counters, appends to `environment_io`, saves DB state as changes, writes API-call and environment I/O logs, disables the safety guard, and resets request count again.

`batch_execute` runs several code snippets as one interaction with sub-interaction numbers. `task_completed` queries `supervisor.show_active_task` and checks whether the task status moved into the terminal status literal. `evaluate` loads start DBs and output DB changes, imports the ground-truth `evaluation.py`, passes `ModelCollectionPair` plus public/private data and answer into it, and produces a `TestTracker` report. Dataset evaluation aggregates task and scenario goal completion.

MCP mode has a parallel path. `appworld serve apis` hosts the app APIs. `appworld serve mcp` builds MCP tool schemas from `ApiDocCollection.build(...).mcp()`, starts stdio or streamable HTTP transport, lists one tool per app API, and executes tools through `ApiCollection.load(..., remote_apis_url=..., wrap_response=True)`. `MCPClient` hides stdio/http differences, handles several MCP output styles, supports allowed-tool filtering, and normalizes invalid-tool or schema errors into response dictionaries.

The experiment agents wrap this runtime. `Agent.solve_tasks` starts `AppWorld.initializer`, opens each task world, loops up to `max_steps`, asks a model for code/tool calls, executes with `world.batch_execute`, records usage, and stops on `world.task_completed()` or budget exhaustion. Function-calling, full-code, SmolAgents, and OpenAI Agents SDK variants all reuse the same AppWorld task world and final evaluation.

## Architecture

The core package is split into environment runtime, request/API wrappers, task and ground-truth loaders, evaluator, schema projection, servers, app libraries, and common utilities. The app list includes `api_docs`, `supervisor`, `amazon`, `phone`, `file_system`, `spotify`, `venmo`, `gmail`, `splitwise`, `simple_note`, and `todoist`; `admin` is mounted as a mandatory internal app.

API implementation is FastAPI-first. Each app exposes typed routes. `prepare_api_docs` reads OpenAPI specs, removes refs, parses YAML metadata from descriptions, adds auth/access-token parameters, validates response schemas, and emits multiple model-facing projections. `ApiDocCollection` then lets callers compress parameters, remove fields, filter apps/APIs, or export function-calling, MCP, SmolAgents, or raw OpenAPI docs.

Runtime has three deployment shapes:

- Unified mode: Python client and FastAPI app live in one process through `TestClient`.
- Decoupled mode: `environment`, `apis`, and/or `mcp` servers run as separate processes and are called over HTTP or stdio.
- Docker mode: CLI wraps servers in `ghcr.io/stonybrooknlp/appworld:{tag}` and mounts only `data` plus `experiments/outputs`.

State is DB-backed and task-local. `local_remote.py` points app model classes to input/output DB homes, freezes time locally or remotely, sets random seeds, saves DBs as full snapshots or changes, and clears DB caches. `AppWorld.save_state` and `load_state` provide checkpoints under task output directories.

The experiment package is registry-driven. `FromDict`/`Registrable` instantiate agent/model classes from JSONnet configs. Config generators produce matrices over agent type, model provider, dataset, reasoning mode, and remote/MCP setup. Agent implementations are separate from the world runtime.

## Design Choices

AppWorld makes HTTP APIs the canonical source, then derives functional Python calls, OpenAI tools, MCP tools, SmolAgents tools, and OpenAPI docs. This avoids maintaining separate tool descriptions for each agent framework.

The preferred agent-facing API is functional, not REST: `apis.{app}.{api}(**params)`. REST remains available through `requester.get/post/...`. This gives agents fewer decisions while preserving an escape hatch for HTTP-native or non-Python agents.

The environment treats execution transcript and world state as first-class artifacts. Every `execute` call saves environment I/O, API calls, output DB changes, and version metadata. This is better for debugging and eval than a final score alone.

Completion is explicit. The supervisor app owns `complete_task`, and agents are expected to call it when done. The harness can stop on this signal without guessing from natural language.

Evaluation is state-based. Reference solutions are used for verification and metadata, but scoring compares final database state and answer through task-specific tests. This is a strong pattern for coding-lab tasks where final repo state and tests matter more than exact trajectory.

Tool retrieval is a benchmarked necessity. Baseline function-calling and SmolAgents paths predict a small API subset before exposing tools because the full API universe is too large for many model/tool-call limits.

Safety is layered but intentionally practical. The default in-process guard rejects disallowed imports/functions via AST analysis and monkey patches destructive functions at runtime. Docs recommend Docker/remote execution for stronger containment, while still keeping guards on to block disruptive calls like `sleep`, `exit`, or filesystem writes.

Parallelism is process/server based. Docs explicitly avoid async/thread sharing for unified worlds because freezegun and DB caches are process-wide. The initializer supports dynamic ports and per-batch server URLs instead.

## Strengths

- Strong single-source schema pipeline: FastAPI/OpenAPI -> standard docs -> function calling/MCP/SmolAgents/OpenAPI.
- Practical local-first execution loop with remote and Docker escape hatches.
- Durable logs for model calls, API calls, environment I/O, DB state changes, usage, and evaluation reports.
- Good eval boundary: explicit done signal plus state-based scoring.
- API call and interaction limits catch infinite loops and runaway agents.
- Requester normalizes local TestClient, remote HTTP, and MCP tool calls behind one API surface.
- MCP support is not a demo only; tests cover stdio/http transports, output-type variants, invalid tools, missing args, unauthorized calls, and allowed-tool filtering.
- `AppWorldInitializer` and CLI make multi-server, dynamic-port, and parallel task execution usable.
- Baseline agents demonstrate several tool-use modes over the same world: ReAct code, full code, native function calling, OpenAI Agents MCP, and SmolAgents.
- Verification harness runs released solutions over train/dev tasks and can exercise local, remote API, remote environment, Docker, and MCP modes.

## Weaknesses

- `SafetyGuard` is not an adversarial sandbox. It depends on AST detection and global monkey patching inside the same Python process. It is useful for cooperative evals, not enough for untrusted coding agents.
- Docker mode mounts `data` and `experiments/outputs` read/write. That is pragmatic for state persistence but still a sensitive surface if agents can inspect task data, ground truth, or prior outputs.
- The public clone has encrypted Git LFS bundle pointers for app implementations, extra tests, and generation code. Without `git-lfs` and unpacking, many app internals are not directly auditable from plain source.
- Process-global time freezing and DB caches make one-world-per-process/server a real constraint. Accidentally sharing a server across simultaneous tasks can corrupt or conflict state.
- MCP error messages inherit some weak behavior from the MCP library, especially invalid or missing tool names/arguments.
- Tool retrieval is model-driven in baselines. If the predictor misses an API, downstream agents may never see it unless configured to expose all tools or use ground truth.
- Some invalid function-call outputs are skipped with warnings in baseline agents, which can hide model/tool schema failures from a stricter automation loop.
- CLI server orchestration mutates environment variables, starts subprocesses, and has several unfinished help paths. Useful, but not a minimal reusable library boundary.
- Full install and verification depend on downloaded data plus encrypted bundle unpacking. This raises setup friction for contributors and independent auditors.
- Ground truth modes reduce leakage, but any terminal agent with direct filesystem access to `data/tasks` or `experiments/outputs` can bypass the intended API boundary unless the host isolates those paths.

## Ideas To Steal

- Define tools once as typed app APIs, then generate every model/provider schema projection from that source.
- Give agents a simple functional API surface while preserving REST/OpenAPI for interoperability.
- Treat the environment boundary as `execute(code) -> output + logs + saved state`, not just a Python `exec`.
- Persist API calls and environment I/O in parseable formats after every interaction.
- Add a first-class `complete_task` tool as the stop condition for long-running tool tasks.
- Use state-based evaluation against final artifacts, with per-task tests and aggregate scenario metrics.
- Support local, remote, Docker, and MCP execution with the same task API so sandboxing can be upgraded without rewriting agents.
- Add an initializer that can start server pools, allocate dynamic ports, and propagate generated URLs into task configs.
- Use API retrieval to cap model-visible tools, but keep a fallback path for all tools or deterministic allowlists.
- Separate ground-truth modes so evaluation can run while solution/code hints remain hidden from agents.
- Normalize MCP tool results with structured response envelopes and output-type compatibility knobs.
- Keep verification as a product feature: run reference solutions end to end across execution modes before trusting the harness.

## Do Not Copy

- Do not treat in-process monkey patching as sufficient sandboxing for coding agents. Use process, container, VM, seccomp/AppArmor, filesystem, network, and approval boundaries.
- Do not give terminal agents direct access to task data, ground truth, or output folders that contain evaluation artifacts.
- Do not rely on a single server process to host multiple concurrent task worlds when state is process-global.
- Do not expose hundreds of tools without a deterministic retrieval, scoping, or fallback strategy.
- Do not return only free-form tool errors if an agent should recover programmatically. Add typed error codes and retry hints.
- Do not make encrypted/vendor-like payloads the only place where critical runtime logic can be reviewed if the goal is an open research artifact.
- Do not let baseline warnings silently skip malformed tool calls in production-style evaluation; count them as structured failures.
- Do not assume Docker bind mounts are a complete safety story. Mounted paths need least privilege and task-specific isolation.

## Fit For Agentic Coding Lab

High fit as a tool-use and evaluation harness reference. AppWorld is less useful as a direct coding assistant architecture and more useful as a pattern library for controlled task worlds.

For Agentic Coding Lab, the strongest adaptation is: a task-local world, generated tool schemas, a compact execution boundary, transcript/state artifacts after every step, explicit completion, and final state/test evaluation. The lab should pair this with stronger host sandboxing, permission categories, and typed tool-result envelopes.

The MCP work is directly reusable conceptually. A coding lab can expose repo/search/test/file tools through an AppWorld-like MCP server, use allowed-tool filters per task, and still score final repository state rather than prompt-visible answers.

## Reviewed Paths

- `/tmp/myagents-research/StonyBrookNLP-appworld/README.md`: installation, data layout, AppWorld basics, API forms, execution safety, serving modes, MCP usage, agent experiments, evaluation, and license/bundle notes.
- `/tmp/myagents-research/StonyBrookNLP-appworld/pyproject.toml`: package dependencies, optional MCP/CI extras, build includes/excludes, encrypted bundle packaging, and lint/test boundaries.
- `/tmp/myagents-research/StonyBrookNLP-appworld/src/appworld/environment.py`: `AppWorld`, `AppWorldInitializer`, `AppWorldServers`, local/remote execution, safety, logging, state save/load, evaluation, and parsing logs.
- `/tmp/myagents-research/StonyBrookNLP-appworld/src/appworld/requester.py`: local TestClient/remote HTTP/MCP request path, request tracking, response normalization, extra-parameter checks, access-token handling, and request limits.
- `/tmp/myagents-research/StonyBrookNLP-appworld/src/appworld/api_docs.py` and `src/appworld/collections/api_docs.py`: API-doc extraction, schema conversion, examples, compression/filtering, and provider-specific schema projections.
- `/tmp/myagents-research/StonyBrookNLP-appworld/src/appworld/collections/apis.py`: functional API wrapper, login shortcut, datetime override control, and requester construction.
- `/tmp/myagents-research/StonyBrookNLP-appworld/src/appworld/task.py` and `src/appworld/ground_truth.py`: task specs, app descriptions, ground-truth modes, required API inference, task IDs, dataset loading, and leakage controls.
- `/tmp/myagents-research/StonyBrookNLP-appworld/src/appworld/evaluator.py` and `src/appworld/verify.py`: `TestTracker`, per-task evaluation, aggregate metrics, reports, and solution-based verification harness.
- `/tmp/myagents-research/StonyBrookNLP-appworld/src/appworld/common/safety_guard.py`, `common/errors.py`, `common/registrable.py`, and `common/types.py`: execution guard, trace formatting, registries, and config construction.
- `/tmp/myagents-research/StonyBrookNLP-appworld/src/appworld/apps/__init__.py` and `src/appworld/apps/lib/apis/local_remote.py`: app mounting, state-management routes, DB path switching, time freezing, remote DB/date APIs, and cache clearing.
- `/tmp/myagents-research/StonyBrookNLP-appworld/src/appworld/serve/apis.py`, `serve/_apis.py`, `serve/environment.py`, and `serve/_mcp.py`: API server, environment HTTP server, MCP server/client, transports, output modes, and tool-list/call behavior.
- `/tmp/myagents-research/StonyBrookNLP-appworld/src/appworld/cli.py`: install/download/verify/run/evaluate/serve commands, Docker wrapping, multiple-server orchestration, dynamic ports, and experiment runner entry points.
- `/tmp/myagents-research/StonyBrookNLP-appworld/experiments/pyproject.toml`: `appworld-agents` package, optional dependencies, and package-data boundaries.
- `/tmp/myagents-research/StonyBrookNLP-appworld/experiments/code/simplified/*`: base agent loop, ReAct code agent, function-calling agent, full-code agent, API predictor, language-model retry/cache/logging, and runner.
- `/tmp/myagents-research/StonyBrookNLP-appworld/experiments/code/openai_agents/*`: OpenAI Agents SDK runner, MCP adapter, tool filtering, streaming logs, and MCP stop-at-tool behavior.
- `/tmp/myagents-research/StonyBrookNLP-appworld/experiments/code/smolagents/*`: SmolAgents tool generation, MCP client adapter, API retrieval, task completion, and runner integration.
- `/tmp/myagents-research/StonyBrookNLP-appworld/experiments/configs/_generator/templates/*.jsonnet.j2` and representative generated configs: model/agent/dataset config generation, MCP server kwargs, reasoning settings, and tool retrieval caps.
- `/tmp/myagents-research/StonyBrookNLP-appworld/guides/evaluating_terminal_agents.md`, `guides/parallelizing_worlds.md`, and `guides/developing_new_apps.md`: terminal-agent MCP workflow, process/server parallelism, API-doc generation, and app-extension patterns.
- `/tmp/myagents-research/StonyBrookNLP-appworld/tests/package/test_appworld.py`, `tests/package/test_safety_guard.py`, and `tests/package/test_prepare_api_docs.py`: behavior tests for execution, errors, state, MCP, safety guard, and schema generation.
- Git metadata and GitHub REST repository endpoint: reviewed commit, latest commit message/date, default branch, stars/forks/open issues, topics, and license snapshot.

## Excluded Paths

- `/tmp/myagents-research/StonyBrookNLP-appworld/src/appworld/.source/*.bundle` and `/tmp/myagents-research/StonyBrookNLP-appworld/generate/.source/*.bundle`: encrypted Git LFS bundle payloads for app implementations, tests, and generation code. In this checkout they are Git LFS pointer files because `git lfs` is not installed; I did not unpack or quote protected bundle contents.
- `/tmp/myagents-research/StonyBrookNLP-appworld/src/appworld/apps/{amazon,gmail,spotify,...}` and `generate/tasks` implementation files that would be produced by unpacking bundles: excluded as protected/plaintext-unavailable app/task internals. The review focused on public runtime boundaries, schemas, servers, and harness code.
- `/tmp/myagents-research/StonyBrookNLP-appworld/generate/**`: task/data/image generation support. Reviewed only bundle/install references and excluded deep generator logic because the assignment focuses on reusable tool-use execution paths.
- `/tmp/myagents-research/StonyBrookNLP-appworld/images/**`, `src/appworld/serve/static/icon.png`, and README media assets: visual/UI assets only.
- `/tmp/myagents-research/StonyBrookNLP-appworld/notebooks/**` and `src/appworld/serve/playground.html`: interactive demos and UI playground; useful for users but not core execution/sandbox/schema behavior.
- Most generated `experiments/configs/**` model matrices: sampled representative configs and generator templates instead of reviewing every provider/model pair.
- `experiments/code/legacy/**`: older baseline agents. Reviewed the current simplified, OpenAI Agents, and SmolAgents paths because they cover the relevant reusable tool-use patterns.
- `.git/**`, `.github/**`, lock/build metadata not listed above, screenshots, binary files, and release helper scripts: provenance or project operations, not agent execution semantics.
