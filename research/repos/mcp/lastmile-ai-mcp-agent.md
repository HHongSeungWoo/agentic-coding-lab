# lastmile-ai/mcp-agent

- URL: https://github.com/lastmile-ai/mcp-agent
- Category: mcp
- Stars snapshot: 8,314 (GitHub REST API, captured 2026-05-11)
- Reviewed commit: f62d849350816588b1c6294e7914bbe4d8b84072
- Reviewed at: 2026-05-11
- Status: reviewed
- Scope fit: conditional
- Verdict: Strong source of MCP-native agent framework patterns, especially server lifecycle, request-scoped context, tool/resource/prompt aggregation, workflow composition, and evaluation hooks. Adopt ideas selectively; the full framework is broader than Agentic Coding Lab needs and brings provider, cloud, OAuth, CLI, and Temporal surface area that would be costly to carry.

## Why It Matters

`mcp-agent` is one of the most complete MCP-centered agent frameworks reviewed so far. It treats MCP servers as the primary capability boundary instead of wrapping every external system in bespoke tool adapters. The useful design signal is not the marketing claim that MCP is enough for agents, but the execution path: an app-level context loads config, a server registry owns MCP transport details, agents aggregate MCP tools/resources/prompts, and provider-specific LLM adapters run tool-calling loops against that aggregated surface.

For Agentic Coding Lab, this repo is most relevant as a pattern library for:

- Managing local and remote MCP server clients without leaking transport code into agent logic.
- Keeping tools namespaced by server while still letting callers use compact local names.
- Composing simple agent workflows such as router, parallel, orchestrator-worker, evaluator-optimizer, swarm, and deep research.
- Exposing an app back out as an MCP server with workflows and functions as tools.
- Adding verification, telemetry, token accounting, and tool filtering around agent runs.

The conditional fit comes from scope. `mcp-agent` is a general app framework, not a coding-agent support package. It includes much more than we should copy: cloud deployment, OAuth flows, ChatGPT app examples, multiple model providers, CLI scaffolding, and Temporal execution.

## What It Is

Python framework for building MCP-based agents. The central types are:

- `MCPApp` in `src/mcp_agent/app.py`: initializes settings, logging, tracing, executor, server registry, token manager, subagent discovery, workflow decorators, and app-level lifecycle.
- `Context` in `src/mcp_agent/core/context.py`: shared runtime state for config, executor, registries, token counter, OAuth identity, request-bound MCP session, and app references.
- `ServerRegistry` and `MCPConnectionManager` in `src/mcp_agent/mcp/`: load MCP server config and connect via stdio, SSE, streamable HTTP, or websocket.
- `Agent` in `src/mcp_agent/agents/agent.py`: combines instructions, MCP server names, local Python functions, human input callback, and an `MCPAggregator`.
- `AugmentedLLM` and provider adapters in `src/mcp_agent/workflows/llm/`: model-facing loop that discovers tools from the agent, sends them to the provider, executes tool calls, records history, and tracks tokens.
- Workflow classes and factories in `src/mcp_agent/workflows/`: reusable effective-agent patterns.
- `create_mcp_server_for_app` in `src/mcp_agent/server/app_server.py`: exposes app workflows/functions as MCP tools.

The project is Apache-2.0, Python 3.10+, package version `0.2.6` at the reviewed commit, and depends directly on `mcp>=1.20.0`, `pydantic`, `httpx`, `fastapi`, OpenTelemetry, and optional provider SDKs.

## Research Themes

- Token efficiency: Basic LLM memory is `SimpleMemory`, with `RequestParams.use_history` controlling whether previous messages are included. Deep Orchestrator adds `WorkspaceMemory`, relevance filtering, context budgets, compression heuristics, and trimming. Token tracking is first-class through `TokenCounter`, app/agent token nodes, model cost aggregation, and watchers, but compression is mostly heuristic rather than semantic.
- Context control: Strong MCP boundary control. Agents declare `server_names`; servers can declare `allowed_tools`; requests can pass `tool_filter`; roots are configured per server; request-bound contexts prevent concurrent MCP server requests from sharing upstream sessions. Deep Orchestrator explicitly builds task context from prior task outputs, artifacts, knowledge, and declared dependencies.
- Sub-agent / multi-agent: High coverage. It implements router, parallel fan-out/fan-in, orchestrator-worker, evaluator-optimizer, swarm, and deep orchestrator. It also loads `AgentSpec` definitions from YAML, JSON, Markdown front matter, Claude-style agent files, inline config, and directories.
- Domain-specific workflow: General framework rather than coding-specific. Coding applicability appears through examples that combine filesystem, fetch, Git, browser, Slack, Supabase, financial analysis, marketing, and Temporal workflows. The reusable piece is the pattern factory layer, not the example domains.
- Error prevention: Plan verification in Deep Orchestrator validates server names, agent names, task uniqueness, dependency ordering, and task completeness before execution. LLM adapters classify provider auth/bad-request errors as non-retryable. Tool schema validation rejects app tools that cannot become JSON schema. The separate `mcp-eval` docs describe regression tests for expected tool paths and outputs.
- Self-learning / memory: No durable long-term learning store for normal agents. Deep Orchestrator has per-run `WorkspaceMemory`, extracted knowledge items, artifacts, and filesystem workspace. OAuth token stores persist credentials, but that is auth state rather than agent memory.
- Popular skills: Not a skills repo. The closest equivalent is `AgentSpec` loading and subagent discovery from `.claude/agents`, `~/.claude/agents`, `.mcp-agent/agents`, config definitions, and Markdown/YAML/JSON files.

## Core Execution Path

Local agent path:

1. User creates `MCPApp(name=...)`.
2. `async with app.run()` calls `MCPApp.initialize()`.
3. Initialization loads `.env`, `mcp_agent.config.yaml`, `mcp_agent.secrets.yaml`, and environment aliases through `get_settings()`.
4. `initialize_context()` creates a `Context`, `ServerRegistry`, `AsyncioExecutor` or `TemporalExecutor`, workflow registry, logger, OpenTelemetry config, and token counter.
5. `MCPApp` optionally initializes OAuth token store/manager and loads subagents into `context.loaded_subagents`.
6. User creates `Agent(name, instruction, server_names, functions, context)`.
7. `async with agent` calls `Agent.initialize()`, which runs `AgentTasks.initialize_aggregator_task` through the executor.
8. Aggregator setup loads tools/prompts/resources from each MCP server, applying server-level `allowed_tools`, namespacing as `<server>_<tool>`, and caching maps.
9. `agent.attach_llm(OpenAIAugmentedLLM)` creates a provider adapter bound to the agent.
10. `llm.generate_str()` loads tools via `agent.list_tools()`, sends provider request, receives tool calls, executes `agent.call_tool()`, appends tool results, repeats until stop/length/content-filter/max-iterations, updates memory, and records token usage.

MCP client path:

1. `create_mcp_server_for_app(app)` creates a FastMCP server.
2. Server lifespan initializes the app and builds `ServerContext`.
3. `create_workflow_tools()` registers generic workflow tools such as `workflows-list`, `workflows-run`, `workflows-get_status`, `workflows-resume`, and per-workflow `workflows-<name>-run`.
4. `create_declared_function_tools()` registers functions declared with `@app.tool` and `@app.async_tool`.
5. Incoming FastMCP requests enter `_enter_request_context()`, which clones/binds `Context` to the request/session/identity before invoking workflow or tool code.

Server client path:

1. `ServerRegistry` reads `MCPServerSettings`.
2. For stdio it creates `StdioServerParameters` and wraps upstream stdio in `filtered_stdio_client()` to drop non-JSON stdout noise.
3. For streamable HTTP and SSE it applies URLs, headers, timeouts, read timeouts, and optional `OAuthHttpxAuth`.
4. For websocket it opens a websocket MCP client.
5. `MCPAgentClientSession` initializes the MCP session and handles sampling, roots, elicitation, logging, tracing metadata, and session IDs.

## Architecture

Runtime layers:

- Configuration layer: `Settings`, `MCPServerSettings`, provider settings, OAuth settings, logger, OTEL, Temporal, subagents, and env materialization.
- App/context layer: `MCPApp` owns lifecycle; `Context` carries shared state plus request-scoped clones.
- MCP transport layer: `ServerRegistry`, `MCPConnectionManager`, `ServerConnection`, `MCPAgentClientSession`, and `filtered_stdio_client`.
- Agent layer: `Agent` owns instructions, server access, functions, tool/resource/prompt lists, human input, and shutdown.
- LLM layer: `AugmentedLLM` abstraction plus OpenAI, Anthropic, Azure, Google, Bedrock, Ollama, LM Studio adapters.
- Workflow layer: factories create router, parallel, orchestrator, deep orchestrator, evaluator-optimizer, swarm, and intent classifier variants.
- Server layer: FastMCP server wrapper exposes app tools/workflows and internal relay routes.
- Observability layer: structured logging, token counter, OpenTelemetry spans, trace propagation in MCP metadata, and docs for `mcp-eval`.

Server/client management is a major strength. Temporary connections use `gen_client()` and `ServerRegistry.initialize_server()`. Persistent connections use `MCPConnectionManager`, a shared TaskGroup owner, health checks, ref-counted aggregator cleanup, reconnect for unhealthy servers, and explicit disconnect methods.

The deep orchestrator architecture is an additional subsystem, not part of the minimal agent path. It adds `TodoQueue`, `WorkspaceMemory`, `PolicyEngine`, `KnowledgeExtractor`, `AgentCache`, `SimpleBudget`, `PlanVerifier`, `ContextBuilder`, and `TaskExecutor`.

## Design Choices

- MCP is the framework boundary. Agents reference server names rather than direct tool objects. Tool discovery happens at runtime from MCP server capabilities.
- Tool names are server namespaced with `_`, e.g. `fetch_fetch` or `filesystem_read_file`, preventing collisions across servers.
- Server-level and request-level filtering are both supported. `MCPServerSettings.allowed_tools` filters discovered tools, while `RequestParams.tool_filter` can override exposure per LLM call.
- Configuration is file-first but can be programmatic. Secrets are deep-merged from `mcp_agent.secrets.yaml`; environment aliases exist for provider credentials; `MCP_APP_SETTINGS_PRELOAD` can fully preload settings.
- `Context` is global by default but can be copied per request. Tests explicitly cover request-bound context isolation and session preference.
- Provider adapters keep common agent semantics while preserving provider-specific APIs. The OpenAI adapter owns JSON tool-call parsing, tool result conversion, reasoning model token parameters, strict structured outputs, and non-retryable provider error mapping.
- Workflows are made composable by making many patterns implement `AugmentedLLM`, so a router, orchestrator, or parallel workflow can be used like another model node.
- Temporal support is layered under the same decorator API. The code deliberately disables some Temporal sandboxing for workflow class decoration, which is pragmatic but risky for deterministic execution discipline.
- Exposing apps as MCP servers is treated as a first-class path. `@app.tool` and `@app.async_tool` synthesize workflow classes and register FastMCP tools with schema validation.
- OAuth is both inbound and outbound. Inbound protected-resource mode uses FastMCP auth settings and a token verifier; outbound HTTP MCP clients use `TokenManager`, metadata discovery, PKCE, token stores, and `OAuthHttpxAuth`.

## Strengths

- Clear capability boundary: MCP servers own tools/resources/prompts; agents only aggregate and expose them to LLMs.
- Good practical support for server lifecycle: temporary vs persistent connections, multiple transports, timeouts, headers, env/cwd, roots, OAuth, and reconnect behavior.
- Strong workflow vocabulary that maps directly to common agent patterns.
- Request-scoped context is a useful pattern for MCP servers that need to multiplex clients without mutating app-wide upstream session state.
- Tool filtering exists at two layers and is tested by examples.
- Deep Orchestrator has real control logic beyond prompt chaining: plan verification, dependency management, retry/backoff, budget checks, context building, and synthesis.
- Observability is integrated in code rather than only docs: token counters, spans, trace propagation, log forwarding, progress notifications, and model cost summaries.
- Verification story is broad: unit tests for config, context, connection manager, app server tools, agents, workflows, OAuth utilities, content/resource conversion, and documented `mcp-eval` flows for behavioral regression.

## Weaknesses

- Scope is large. Core agent logic, cloud deployment, OAuth, CLI, app-server relay routes, Temporal, ChatGPT app examples, and many providers live together, increasing comprehension and maintenance cost.
- The simple `AugmentedLLM` memory is only in-process conversation history. Durable memory exists only in Deep Orchestrator and is still heuristic.
- Deep Orchestrator appears ambitious but partially rough: context compression is string truncation/summarization heuristics, relevance is keyword overlap, and some examples/tests refer to fields that differ from the current model names.
- Security depends heavily on correct config. Filesystem and subprocess MCP servers can expose broad host access; tool filtering helps but is opt-in.
- Internal HTTP relay routes fall back to unauthenticated mode when `MCP_GATEWAY_TOKEN` is unset. That is convenient locally, but dangerous if deployed without hardening.
- OAuth/token support is complex and likely easy to misconfigure. It includes introspection, audience validation, token caches, preconfigured tokens, internal callback routes, user identity mapping, and downstream token refresh.
- Temporal integration hides complexity but includes a comment about disabling sandboxing to avoid `RestrictedWorkflowAccessError`, which deserves caution for production deterministic workflows.
- Provider adapters contain duplicated behavior across model families. The shared `AugmentedLLM` abstraction helps, but provider-specific tool conversion remains large.

## Ideas To Steal

- Use MCP server names as explicit capability grants for agents, not a flat global tool registry.
- Add both static tool allowlists on server config and dynamic per-request tool filters.
- Keep a `ServerRegistry` abstraction that owns transport details and returns initialized MCP sessions.
- Use request-bound context copies for server mode so concurrent MCP clients do not race on shared upstream session state.
- Treat workflows as MCP tools with schema generation from Python signatures.
- Store loaded subagent specs separately from instantiated agents. Let precedence be project config, project agent files, user files, then inline definitions.
- In a coding-agent harness, add a plan verifier like Deep Orchestrator's before executing LLM-created task graphs: validate tool/server names, unique task IDs, and dependency direction.
- Add token tree accounting at app, agent, workflow, step, and LLM nodes to make expensive runs inspectable.
- Support stdio stdout filtering for MCP servers that print setup logs before JSON-RPC.
- Pair unit tests with behavioral MCP evals that assert tool call sequences and output contracts.

## Do Not Copy

- Do not copy the whole framework surface. Agentic Coding Lab should not inherit Cloud, ChatGPT apps, OAuth UI flows, provider zoo, and CLI scaffolding unless directly needed.
- Do not copy implicit global context as the default for multithreaded coding agents. Prefer explicit per-run contexts and only use global fallback for tiny examples.
- Do not copy unauthenticated internal relay defaults into any deployed service. Require a token or bind to loopback-only by default.
- Do not copy deep orchestrator memory as-is for long-term coding memory. Keyword overlap and in-memory artifacts are useful prototypes, not enough for stable project memory.
- Do not rely only on LLM self-verification. The plan verifier is useful because it checks structural facts; coding workflows need repository, diff, test, and permission checks too.
- Do not let filesystem MCP access default to broad paths. Coding-agent use should bind roots to the workspace and explicit writable roots.
- Do not expose all discovered MCP tools by default in high-risk workflows. Default to read-only or reviewed tool sets for coding tasks.

## Fit For Agentic Coding Lab

Best fit is as a design reference for an MCP-backed coding support layer. The immediate reusable patterns are:

- App-run context that resolves config, server registry, token/logging, and per-run IDs.
- Server registry plus connection manager for stdio/http/websocket MCP servers.
- Agent specs that declaratively map role/instruction to allowed MCP servers.
- Tool filtering and allowlists for safe coding-agent tool exposure.
- Workflow factories for router, parallel review, orchestrator-worker, and evaluator-optimizer patterns.
- Plan verification before execution for dynamically generated multi-step plans.
- Token/cost tree for every agent/workflow call.
- MCP server exposure for workflows so external clients can run and inspect tasks.

For our repo, the likely artifact candidates are:

- A small MCP server registry note or config pattern for coding agents.
- A tool exposure policy that combines server allowlists and per-request filters.
- A plan-verifier checklist for generated coding task DAGs.
- An eval harness pattern that checks expected tool sequences for common coding workflows.
- A context/memory design that borrows the idea of per-run workspace memory but swaps in repo-aware retrieval and artifact provenance.

## Reviewed Paths

- `README.md`: overview, minimal path, quickstart, config examples, workflows, durable execution, app-as-server, auth, observability.
- `pyproject.toml`: package metadata, dependencies, optional provider/runtime groups, CLI entry points.
- `src/mcp_agent/app.py`: app lifecycle, config loading, OAuth initialization, subagent discovery, workflow/tool decorators.
- `src/mcp_agent/config.py`: settings models, MCP server config, OAuth config, env aliases, secrets merge, preload behavior.
- `src/mcp_agent/core/context.py`: shared and request-bound context, logger/session/resource fallbacks, executor and registry initialization.
- `src/mcp_agent/agents/agent.py` and `src/mcp_agent/agents/agent_spec.py`: agent model, initialization, tool/resource/prompt APIs, human input, function tools, AgentSpec.
- `src/mcp_agent/mcp/`: server registry, connection manager, client session, sampling, stdio filtering, aggregator, generated client helpers.
- `src/mcp_agent/workflows/llm/`: base LLM abstraction and OpenAI adapter execution loop, structured output, tool execution, token tracking.
- `src/mcp_agent/workflows/factory.py`: creation helpers, AgentSpec loaders, provider selection, pattern factories.
- `src/mcp_agent/workflows/orchestrator/`, `parallel/`, `router/`, `evaluator_optimizer/`, `swarm/`, `intent_classifier/`: reusable workflow implementations.
- `src/mcp_agent/workflows/deep_orchestrator/`: adaptive planning, queue, memory, policy, budget, plan verification, context building, task execution.
- `src/mcp_agent/server/`: app-as-MCP server, workflow tools, function tool adapters, token verifier.
- `src/mcp_agent/oauth/`: token manager, stores, OAuth flow, metadata, PKCE, HTTP auth.
- `docs/configuration.mdx`, `docs/concepts/*.mdx`, `docs/advanced/*.mdx`, `docs/test-evaluate/*.mdx`, `docs/oauth_support_design.md`: config, conceptual model, Temporal/monitoring, eval, and OAuth design.
- `examples/basic/mcp_basic_agent`, `examples/basic/mcp_server_aggregator`, `examples/basic/mcp_tool_filter`, `examples/mcp/mcp_roots`, `examples/oauth/protected_by_oauth`, `examples/temporal/orchestrator.py`: representative execution examples.
- `tests/core`, `tests/app`, `tests/config`, `tests/mcp`, `tests/server`, `tests/agents`, `tests/workflows`, `tests/oauth`, `tests/utils`, `tests/human_input`: unit and integration-style coverage for the main execution paths.
- `SECURITY.md`: supported versions and vulnerability disclosure note.
- `schema/mcp-agent.config.schema.json`: generated config schema, checked for config surface shape but not line-by-line.

## Excluded Paths

- `examples/cloud/chatgpt_apps/*/web`, `src/mcp_agent/data/examples/cloud/chatgpt_app/web`, and `docs/css`, `docs/logo`, `docs/images`: UI-only or image assets; not relevant to MCP agent runtime design.
- `examples/cloud/*` and `src/mcp_agent/cli/cloud/**`: mostly managed cloud deployment packaging and commands; reviewed only where they intersected app-as-server/auth concepts.
- `src/mcp_agent/data/templates/**` and `src/mcp_agent/data/examples/**`: packaged scaffold/example copies; redundant with source examples and generated-like distribution data.
- `examples/usecases/**` after sampling representative use cases: domain demos are numerous and repetitive; not necessary to understand core execution paths.
- `examples/model_providers/**`, `examples/langchain`, `examples/crewai`, `examples/lm_studio`: provider/integration demos; core provider mechanics were read in `src/mcp_agent/workflows/llm`.
- `examples/mcp/mcp_roots/test_data/**` and generated property/sample reports: binary/generated/demo data, not framework design.
- `examples/cloud/chatgpt_apps/*/web/yarn.lock`, package lockfiles, and frontend build files: dependency locks/UI implementation, not relevant to MCP framework patterns.
- `logs/**`: runtime log output, generated.
- `scripts/**`, `Makefile`, and packaging helper paths: not needed beyond confirming project shape.
- Remaining provider adapters after OpenAI sampling: reviewed common `AugmentedLLM` base and one full provider loop; others mainly repeat provider-specific conversion and API calls.
