# mcp-use/mcp-use

- URL: https://github.com/mcp-use/mcp-use
- Category: mcp
- Stars snapshot: 9,928 (GitHub REST API `stargazers_count`, captured 2026-05-11)
- Reviewed commit: 6bf61fdcb8313ff858ff0ea23756e9868a0158b6
- Reviewed at: 2026-05-11
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong reference for agent-facing MCP client/session patterns, dynamic tool surfacing, and code-mode context control. Adopt patterns selectively; local code execution and agent-controlled server addition need stricter sandbox, permission, and audit boundaries before using in a coding-agent environment.

## Why It Matters

mcp-use is a popular full-stack MCP framework with both Python and TypeScript implementations. For Agentic Coding Lab, the valuable part is not the MCP app/UI surface but the concrete execution path that turns MCP servers into agent tools: config parsing, connector/session lifecycle, tool/resource/prompt adaptation, LangChain agent loops, dynamic server selection, and code-mode tool access.

The repo also ships coding-agent-facing skills for building MCP apps and servers. Those skills are mostly server-builder guidance, but they show a useful packaging pattern: a short mandatory navigation skill plus focused references for tools, resources, prompts, widgets, auth, deployment, and common pitfalls.

## What It Is

A monorepo containing:

- Python package `mcp-use` (`libraries/python`, version 1.7.0 at review) with MCP client, agent, server, connectors, sandbox connector, code mode, LangChain adapter, and tests.
- TypeScript package `mcp-use` (`libraries/typescript/packages/mcp-use`, version 1.27.0 at review) with client, agent, server framework, React/browser hooks, code mode, OAuth, sessions, widgets, and tests.
- Additional TypeScript packages for CLI/scaffolding/inspector, documentation, examples, and Codex/Claude-style skills.

For agents, the core product is: configure one or more MCP servers, create client sessions over stdio or HTTP/SSE/streamable HTTP, expose discovered MCP tools as LangChain tools, run an agent loop, and optionally reduce context with code mode or server-manager mode.

## Research Themes

- Token efficiency: Code mode is the strongest idea. Agents see only `execute_code` and `search_tools`, then process data inside a Python/JavaScript execution environment and return summaries. Server-manager mode also limits exposed tools by connecting one server at a time. Default mode still enumerates every converted tool/resource/prompt in the system prompt.
- Context control: Prompt builders generate tool descriptions from active tools; memory can be internal, disabled, or supplied externally. There is no summarizing memory or token budget manager. Roots support lets clients advertise accessible files/directories to servers, but roots are not a full permission layer.
- Sub-agent / multi-agent: No local subagent orchestration. `RemoteAgent` exists for hosted execution, and server manager is a dynamic tool manager, not a multi-agent system.
- Domain-specific workflow: Strong MCP server/app workflow docs and skills, including mandatory skill routing for MCP server work. Agent workflow is generic LangChain plus MCP tools, not coding-agent-specific.
- Error prevention: Python has `tool_error_handler` middleware that turns validation/runtime failures into LLM-readable tool messages for retry. TypeScript adapters catch tool errors and return strings. Both use max-step/model-call limits. Tests cover many primitives, but some claimed recovery behavior has shallow unit coverage.
- Self-learning / memory: Conversation memory only. It stores messages/tool exchanges in process or accepts caller-managed external history. No durable learning, reflection, vector memory, or cross-session memory.
- Popular skills: `skills/mcp-builder`, `skills/mcp-apps-builder`, and `skills/chatgpt-app-builder` package framework best practices with navigation references and eval JSON. They are useful as an artifact pattern, less useful as direct coding-agent runtime logic.

## Core Execution Path

Standard Python agent path:

1. `MCPClient` loads a dict or JSON config with `mcpServers`.
2. `create_connector_from_config()` chooses `StdioConnector`, `HttpConnector`, `WebSocketConnector`, or `SandboxConnector`.
3. `MCPClient.create_session()` wraps the connector in `MCPSession`, calls `initialize()`, and caches it in `sessions` and `active_sessions`.
4. `BaseConnector.initialize()` runs the MCP initialize handshake and lists tools/resources/prompts according to server capabilities.
5. `MCPAgent.initialize()` gets active sessions or creates all sessions, then `LangChainAdapter` converts MCP tools/resources/prompts into LangChain tools.
6. `create_system_message()` injects tool descriptions into a prompt template.
7. LangChain `create_agent()` runs with `ModelCallLimitMiddleware`; tool calls route to adapter `_arun()`, then `connector.call_tool()`, then the MCP SDK client session.
8. Results are converted into strings/content blocks, streamed or returned, and stored in conversation history if memory is enabled.

Standard TypeScript path is similar:

1. `MCPClient` extends `BaseMCPClient`.
2. Node config supports stdio and HTTP; browser config supports HTTP.
3. `createSession()` builds an `MCPSession`, auto-initializes, and stores it.
4. `BaseConnector.initialize()` caches capabilities, server info, and tools.
5. `MCPAgent.initialize()` builds tools through `LangChainAdapter`, optionally exposing resources/prompts as tools.
6. `createAgent()` from LangChain runs with `modelCallLimitMiddleware`; tool calls use `DynamicStructuredTool` functions that call connector methods.

Direct client path:

1. Create `MCPClient`.
2. `create_all_sessions()` / `createAllSessions()`.
3. `get_session()` / `getSession()`.
4. `list_tools()` / `listTools()`, `call_tool()` / `callTool()`, resource reads, prompt calls.
5. `close_all_sessions()` / `closeAllSessions()` for cleanup.

Code mode path:

1. `MCPClient(code_mode=True)` in Python or `new MCPClient(config, { codeMode: true })` in TypeScript creates an internal `code_mode` `MCPSession`.
2. The normal adapter exposes only two meta-tools: `execute_code` and `search_tools`.
3. On first execution, code executor lazily connects missing configured servers.
4. Executor builds a namespace of server names and async tool wrappers, plus `search_tools()` and `__tool_namespaces`.
5. Agent-generated code runs and calls MCP tools from inside the execution environment.
6. Only captured logs, final result, error, and elapsed time return to the agent.

Server-manager path:

1. Agent starts with management tools such as list/connect/get-active/disconnect; TypeScript also includes `add_mcp_server_from_config`.
2. `connect_to_mcp_server` creates or reuses a session for the chosen server.
3. Adapter converts that server's tools/resources/prompts.
4. Agent detects tool list changes after a complete tool result, recreates the LangChain agent, and restarts execution with accumulated messages. Restart count is capped.

## Architecture

The agent/client architecture is cleanly split:

- Config: JSON/dict object with server entries and callbacks.
- Connectors: transport-specific implementations over MCP SDK clients.
- Task managers: long-lived stdio/SSE/streamable HTTP lifecycle helpers.
- Session: thin lifecycle and primitive wrapper around one connector.
- Client: owns config, sessions, active server names, code-mode executor, and cleanup.
- Adapter: converts MCP tools/resources/prompts to LangChain tools.
- Agent: owns LLM, prompt, memory, tool list, streaming/run loop, dynamic reload, observability, and close semantics.
- Server manager: exposes server-selection tools and active-server tool cache.
- Server framework: separate MCP server SDK surface with tools/resources/prompts/widgets/auth/middleware.

Python has a broader connector set for client use (`stdio`, `http`, `websocket`, `sandbox`) and duplicated compatibility import paths under older module names. TypeScript splits base/browser/node concerns and has richer server/app/UI infrastructure.

## Design Choices

- Build on the official MCP SDK rather than reimplementing protocol details.
- Treat code mode as an internal MCP server, so existing adapter/agent logic does not need a separate special case beyond selecting the `code_mode` session.
- Prefer streamable HTTP first, then fall back to SSE for compatibility.
- Always advertise roots capability and answer roots/list from cached roots or callbacks.
- Convert MCP resources and prompts into tools by default for agent compatibility.
- Keep tool allow/deny as name-based filters (`disallowed_tools` / `disallowedTools`).
- Use LangChain agent middleware to cap model calls; Python also wraps tool errors as retryable messages.
- Track telemetry and observability metadata, with CI setting `MCP_USE_ANONYMIZED_TELEMETRY=false`.
- Ship MCP builder skills as first-class repo artifacts, but keep them separate from runtime packages.

## Strengths

- Real end-to-end implementation for MCP tools inside agents in two languages.
- Code mode is directly applicable to coding agents: discover tools lazily, execute loops/data processing outside model context, return compact summaries.
- Session lifecycle is explicit and easy to reuse: create session, initialize, list/call, close.
- HTTP connector handles modern streamable HTTP while preserving SSE compatibility.
- Server-manager dynamic tool reload is a practical way to avoid loading every server's tool schema into one prompt.
- Strong MCP primitive coverage: tools, resources, prompts, sampling, elicitation, notifications, roots, auth, completion, conformance.
- Tests and CI are broad: Python unit/integration matrices, TypeScript unit/integration, agent suites, and `mcp-conformance-action`.
- Skills package is a useful pattern for coding-agent guidance: mandatory top-level skill, reference folders, and eval fixtures.

## Weaknesses

- Local code mode is not a strong sandbox. Python executes generated code in-process with restricted builtins; TypeScript VM mode uses Node `vm` and docs warn it is for trusted environments. E2B is available in TypeScript code mode, but optional. Python's E2B support is for running MCP servers, not the code-mode executor.
- Agent-controlled server addition in TypeScript (`add_mcp_server_from_config`) can become command-spawn capability if exposed to untrusted prompts. That needs approval gates in a coding agent.
- Tool governance is mostly name filtering. There is no built-in policy engine for read/write/destructive categories, workspace path constraints, or per-call user confirmation.
- Default agent mode can still flood context with all tools/resources/prompts. Users must opt into code mode or server manager to get context benefits.
- Conversation memory is in-process transcript storage, not a bounded/summarized memory system.
- Some tests document behavior more than prove it. For example, TypeScript 404 reinitialization tests mostly assert wrapper shape rather than a failing request and successful retry.
- TypeScript `CodeModeConnector` appears to validate `detail_level` with array `in` semantics, so the meta-tool path may ignore valid `"names"` / `"descriptions"` requests and fall back to `"full"`; direct `client.searchTools()` still handles detail levels correctly.
- The monorepo mixes agent/client patterns with server apps, widgets, inspector, cloud deployment, and UI assets. Useful ideas require filtering to avoid adopting product-specific complexity.

## Ideas To Steal

- Code-mode meta-server: expose `search_tools` and `execute_code` as normal MCP tools so existing agent adapters work unchanged.
- Tool namespace wrappers: generate `server.tool(args)` functions inside an execution environment from active MCP sessions.
- Dynamic server manager: let the agent list/connect/release servers and recreate the tool list only at safe tool-result boundaries.
- Connector/session split: keep transport lifecycle separate from primitive-level session methods.
- Roots callbacks: advertise roots capability, then answer roots/list from caller-controlled state.
- Error-to-LLM formatting: return validation/runtime errors as structured, retryable tool messages instead of crashing the agent loop.
- Conformance workflow: run both server and client conformance across Python/TypeScript implementations and publish badge data.
- Skill artifact structure: one short router skill plus targeted reference docs and evals, rather than one huge prompt.

## Do Not Copy

- Do not treat restricted builtins or Node `vm` as safe execution for untrusted coding-agent code. Use an OS/container/cloud sandbox plus file/network policy.
- Do not expose arbitrary server configuration or command spawning to the agent without an approval workflow.
- Do not rely on tool names alone for access control. Add server identity, operation class, workspace path, and user intent checks.
- Do not preload all MCP tools in coding-agent prompts by default. Make discovery explicit and budgeted.
- Do not copy UI/widget/inspector complexity into a coding-agent MCP client layer unless the product needs MCP Apps.
- Do not assume generated API docs are source of truth; read runtime source and tests first.
- Do not let telemetry or observability metadata include secrets; keep the "has env/header" pattern rather than values.

## Fit For Agentic Coding Lab

High fit as a reference for MCP-backed coding-agent tool use. The most reusable subsystem is the client/session/adapter/code-mode path:

- Use MCP config to attach external capability servers.
- Convert live MCP tools to agent-callable tools.
- Add `search_tools` and code execution as context-control primitives.
- Keep tool results out of model context unless needed.
- Add dynamic server selection to avoid huge tool schemas.

For Agentic Coding Lab, this should be adapted with stronger coding-agent constraints: workspace-root enforcement, command allowlists, per-tool risk labels, approval prompts for mutation/destructive tools, durable audit logs, test/verification hooks, and a real sandbox for code-mode execution.

## Reviewed Paths

- Root metadata and guidance: `README.md`, `SECURITY.md`, `CONTRIBUTING.md`, `CLAUDE.md`, `.mcp.json`.
- Package metadata: `libraries/python/pyproject.toml`, `libraries/python/DEPENDENCY_POLICY.md`, `libraries/typescript/packages/mcp-use/package.json`.
- Python docs: `docs/python/client/code-mode.mdx`, `docs/python/client/sandbox.mdx`, `docs/python/client/direct-tool-calls.mdx`, `docs/python/client/client-configuration.mdx`, `docs/python/client/multi-server-setup.mdx`, `docs/python/agent/memory-management.mdx`, `docs/python/agent/server-manager.mdx`, `docs/python/development/security.mdx`.
- TypeScript docs: `docs/typescript/client/code-mode.mdx`, `docs/typescript/client/client-configuration.mdx`, `docs/typescript/client/server-manager.mdx`.
- Python client/session/connectors: `libraries/python/mcp_use/client/client.py`, `session.py`, `config.py`, `code_executor.py`, `connectors/base.py`, `connectors/stdio.py`, `connectors/http.py`, `connectors/sandbox.py`, `connectors/code_mode.py`, task manager files.
- Python agent/adapters/managers: `libraries/python/mcp_use/agents/mcpagent.py`, `agents/adapters/langchain_adapter.py`, `agents/prompts/*.py`, `agents/managers/server_manager.py`, manager tools, `agents/middleware/tool_error_middleware.py`.
- Python server/security samples: `libraries/python/mcp_use/server/server.py`, `server/auth/*`, server auth tests.
- TypeScript client/session/connectors: `libraries/typescript/packages/mcp-use/src/client.ts`, `src/client/base.ts`, `src/session.ts`, `src/config.ts`, `src/connectors/base.ts`, `src/connectors/stdio.ts`, `src/connectors/http.ts`, `src/client/connectors/codeMode.ts`, `src/client/executors/*`.
- TypeScript agent/adapters/managers: `src/agents/mcp_agent.ts`, `src/adapters/base.ts`, `src/adapters/langchain_adapter.ts`, `src/agents/prompts/*.ts`, `src/managers/server_manager.ts`, manager tools.
- TypeScript security/server representative paths: `src/server/middleware/host-validation.ts`, `src/server/mcp-server.ts`.
- Examples: Python `code_mode_example.py`, `direct_tool_call.py`, `simple_server_manager_use.py`; TypeScript `examples/agent/code-mode/code_mode_example.ts`, `examples/agent/server-management/multi_server_example.ts`, representative client/server examples.
- Tests: Python code executor, client, HTTP connector, server manager, primitive/transport test lists; TypeScript code executor, code mode, server manager, 404 reinit, DNS rebinding, agent tests.
- Verification workflows: `.github/workflows/ci.yml`, `.github/workflows/conformance.yml`.
- Skills: `skills/mcp-builder/SKILL.md`, `skills/mcp-apps-builder/SKILL.md`, `.claude-plugin/marketplace.json`.

## Excluded Paths

- `docs/python/api-reference/**`: generated API reference from source; source files were reviewed instead.
- `docs/images/**`, `static/**`, `*.png`, `*.jpg`, `*.gif`, `*.mp4`, `*.svg`, fonts: binary/static visual assets, not execution logic.
- `libraries/typescript/packages/inspector/**`: web inspector UI and debugging product; relevant only as a consumer of client/server APIs, not core agent MCP execution.
- `libraries/typescript/packages/cli/**` and `packages/create-mcp-use-app/**`: scaffolding/build tooling, outside agent/tool execution path.
- Most `examples/server/ui/**` widget implementations: UI-only MCP Apps examples; representative widget/server framework paths were sampled, but frontend details were not central to coding-agent applicability.
- Provider-specific OAuth example apps under TypeScript server OAuth folders: useful deployment examples, but auth/provider mechanics are orthogonal to client/agent execution.
- Lockfiles and package-manager metadata such as `pnpm-lock.yaml`, `.changeset/**`, `.husky/**`: dependency/build state, not design logic.
- Release/deploy/stale/sync workflows in `.github/workflows/**`: operational automation; CI and conformance workflows were the relevant verification paths.
- Skill eval JSON files: useful for quality process, but not runtime behavior; top-level skill instructions and marketplace metadata were reviewed.
