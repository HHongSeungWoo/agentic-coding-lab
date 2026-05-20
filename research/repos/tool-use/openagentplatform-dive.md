# OpenAgentPlatform/Dive

- URL: https://github.com/OpenAgentPlatform/Dive
- Category: tool-use
- Stars snapshot: 1,795 (GitHub REST API, captured 2026-05-20)
- Reviewed commit: 4010d87686b98d07fedf6cf0e0d46342b7b8bace
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: conditional
- Verdict: Conditional pattern source. Dive is primarily a desktop MCP host app, not a reusable agent lab library, but its `mcp-host` sidecar has concrete tool-use patterns worth stealing: MCP server lifecycle, per-tool enablement, elicitation, OAuth, abort, streaming progress, model tool verification, and prompt-based function-call fallback.

## Why It Matters

Dive is a full end-to-end MCP host: desktop UI, local host service, model provider config, MCP server management, OAuth, tool approval prompts, streaming chat, and persistent history. That makes it more useful for tool-use research than a small function-calling demo because it shows where tool execution actually crosses trust boundaries: local subprocesses, remote MCP transports, user approvals, OAuth redirects, and UI events.

For Agentic Coding Lab, the main value is not the desktop shell. The value is the control-plane design around tools: discover tools from servers, expose only enabled tools to the model, stream tool events separately from text, let the user answer structured approval requests, and keep abort/reload/logging wired through the whole stack.

## What It Is

Dive is an Electron/Tauri desktop app that starts a Python FastAPI sidecar (`dive_httpd`) from the `mcp-host` submodule. The sidecar loads model config, MCP config, prompt config, command aliases, plugin config, chat history storage, and OAuth token storage. It then builds a `DiveMcpHost` with a LangChain chat model and a `ToolManager`.

The host supports MCP over `stdio`, SSE, streamable HTTP, websocket, and a "local HTTP server" mode where a command is spawned and then contacted over HTTP. It also injects OAP cloud connector config through a plugin and can expose local installer tools such as `bash`, `fetch`, `read_file`, `write_file`, `add_mcp_server`, `reload_mcp_server`, and `request_confirmation`.

The reviewed checkout uses submodule `mcp-host` at `e1c3f20bfda4938532b315ff1e9bfef0c6eb0ed4`.

## Research Themes

- Token efficiency: Has approximate token counting, message trimming with a window policy, truncation in fetch/file/bash outputs, and a prompt-based tool fallback for models without native function calling. It does not do aggressive schema compression or dynamic tool retrieval; enabled tool schemas are passed to the model as a whole.
- Context control: Strong practical controls. MCP servers can be enabled/disabled, individual tools are hidden through `exclude_tools`, custom/system prompts are separate, slash-command skills prepend skill content, and chat retry/edit removes later messages from LangGraph state.
- Sub-agent / multi-agent: No general multi-agent runtime. The closest pattern is an installer-tool bundle that behaves like a task-specific sub-agent capability inside the main chat.
- Domain-specific workflow: Good desktop workflow for MCP setup: OAP cloud connectors, deep-link install, command-alias mapping, server logs, reload-on-config-save, and model tool-support verification.
- Error prevention: Uses Pydantic config validation, command existence checks, startup/tool-call timeouts, server status states, user elicitation, OAuth status events, abort signals, process cleanup, cached failed tool state, and tests across transports. It lacks a real command/filesystem sandbox.
- Self-learning / memory: Has chat persistence, LangGraph checkpointers, full-text search, and loadable skills. There is no autonomous memory selection or learned tool policy.
- Popular skills: Not a skills pack. Skills are local Markdown instructions exposed through `dive_skill`, and slash commands can prepend skill content to the user message.

## Core Execution Path

1. Desktop startup creates config files under `.dive` or `.config`, starts `dive_httpd` with `--port 0`, writes host status to a bus file, and rewrites frontend `fetch` calls to `http://localhost:<port>`.
2. FastAPI loads `mcp_config.json`, `model_config.json`, `customrules`, `command_alias.json`, `plugin_config.json`, DB/checkpointer config, and OAP plugin callbacks.
3. `DiveHostAPI.prepare()` builds `DiveMcpHost`, which loads the active LangChain model and creates a `ToolManager` from enabled MCP servers.
4. `ToolManager` launches each MCP server as an async task. `McpServer` initializes the client session, calls `initialize()` and `list_tools()`, wraps each MCP tool as `McpTool`, and records server state/logs.
5. `/api/chat` creates `ChatProcessor`, converts uploads/paths into LangChain messages, and opens `dive_host.chat(...)` with MCP tools, optional local tools, skill tools, and prompt settings.
6. `ChatAgentFactory` compiles a LangGraph graph: `before_agent -> agent -> tools -> before_agent`. Models with native function calling get `bind_tools`; models needing fallback get XML-like `<tool_call>` instructions and parser extraction.
7. `ToolNode` invokes `McpTool._arun()`. The tool opens a session for the chat, calls `session.call_tool(...)`, streams progress/auth/elicitation custom events, handles URL elicitation errors, and returns JSON-encoded MCP content.
8. `ChatProcessor._handle_response()` streams text, tool calls, tool results, progress, authentication requests, elicitation requests, and final token usage back to the UI as server-sent events, then persists user/assistant/tool messages.

## Architecture

The architecture is a local sidecar host behind a desktop UI.

- Desktop shell: Electron and Tauri variants own windows, deep links, updates, dependency downloads, bundled Node/Python/uv paths, and host process lifecycle.
- Host sidecar: `mcp-host` is a Python FastAPI app exposing `/api/chat`, `/api/tools`, `/api/config`, `/model_verify`, `/v1/openai`, `/api/skills`, and plugin routes.
- Agent runtime: LangChain models plus a custom LangGraph ReAct loop. Tool calls are native function calls when supported and XML-tagged prompt calls when not.
- Tool runtime: `ToolManager` owns `McpServer` instances. `McpServer` abstracts stdio/SSE/streamable/websocket/local-http setup, sessions, auth, logs, restart, and enabled tool listing.
- Built-in MCP server: `packages/dive-mcp` is a Rust stdio MCP server with fetch and filesystem tools. Filesystem operations request user permission and can persist allowed directories.
- Plugins: OAP plugin mutates current MCP config, injects hidden built-in connectors, stores tokens, and registers FastAPI routes.
- UI control plane: React pages edit configs, toggle servers/subtools, respond to elicitation, show auth prompts, and receive host progress through SSE or backend events.

## Design Choices

Dive keeps the UI and tool execution separated by a local HTTP boundary. This is a good isolation shape for product complexity: the renderer does not call tools directly; it calls a local API that owns config, model state, persistence, process cleanup, and audit-ish logs.

The MCP abstraction chooses transport from config: `command + stdio`, `url` for remote HTTP transports, or `command + url` for a local HTTP MCP server. This gives one server model for local subprocess tools and remote cloud tools.

Tool exposure is config-driven. Disabled servers are not loaded, and `exclude_tools` removes individual tools before the model sees them. The UI writes the whole MCP config on each change, and the host reloads only changed servers unless forced.

The agent has two function-calling paths. Native tool support uses `bind_tools`; fallback support injects tool definitions and examples into the prompt and parses `<tool_call>` blocks back into LangChain `ToolCall` objects. Model verification explicitly tests both paths.

Elicitation is a first-class event path. Tools can ask for structured form input, URL-open approval, command confirmation, or password input. Requests carry a `request_id`, message, and JSON schema; the UI responds through `/api/tools/elicitation/respond`.

Abort is propagated through chat and tools. The UI calls `/api/chat/{chat_id}/abort`; `AbortController` calls `Chat.abort()`, the graph receives an abort event, local subprocess tools kill process groups, and MCP calls can send `CancelledNotification`.

## Strengths

The implementation covers real tool-use failure modes: MCP init timeout, remote auth required, stdio process death, tool call timeout, user cancellation, server reload, disabled subtools, missing command UI warnings, and retry after abort.

It has a useful split between normal MCP tools and local installer tools. Installer/local tools emit separate `agent_tool_call` and `agent_tool_result` style events, request confirmation for risky operations, support dry runs, and can update MCP config through the same API the UI uses.

Transport support is broad and tested: stdio, SSE, streamable HTTP, local SSE, websocket config validation, proxy support, OAuth, elicitation, and abort are all represented in tests.

The model verification flow is a concrete pattern: test connection, test native tool calling with a tiny `weather_tool`, then test prompt-based tool calling if native tools fail. That is directly reusable for a coding-agent harness.

## Weaknesses

This is a desktop product monorepo, so reusable tool-use logic is mixed with packaging, UI state, locale files, update flows, and OAP product integrations.

There is no hard sandbox for local tools. Stdio MCP servers are arbitrary configured commands. The local `bash` tool uses `asyncio.create_subprocess_shell`; safety is confirmation, pattern detection, timeout, and process kill, not filesystem/network isolation.

Some safety relies on runtime context being present. For example, local `write_file` asks for confirmation only when an `ElicitationManager` is available; tests demonstrate direct execution without that manager. In normal chat the manager is passed, but the tool itself is not self-contained policy.

Tool names are not namespaced for the model. `McpTool.from_tool()` uses the raw MCP tool name and stores the server only as `toolkit_name`, so two servers exposing `search` or `read_file` can collide inside LangGraph `ToolNode`.

The Rust default filesystem server checks allowed directories with string prefix matching after normalization. That is weaker than path-ancestor checks and can misclassify paths with shared prefixes.

Secrets are practical but not ideal. Headers and API keys are Pydantic `SecretStr` in memory, but config serialization writes plain values. OAP token markers are replaced in config callbacks.

The local IPC path for elicitation is partially dormant in the app layers: `packages/core-js` supports it, but Electron and Tauri handlers are commented/stubbed in the reviewed commit.

## Ideas To Steal

Use a sidecar host process as the authority for model calls, tool config, MCP subprocesses, OAuth, logs, persistence, and verification. Keep UI/API clients thin.

Represent tool availability as two levels: server enabled state plus per-tool `exclude_tools`. Feed only enabled tools into the model, but keep cached disabled-server tool info for UI continuity.

Make elicitation a generic typed event: `{request_id, message, requested_schema}` out, `{request_id, action, content}` back. Use it for command approval, URL-open approval, OAuth assist, passwords, and MCP server forms.

Propagate `tool_call_id`, `thread_id`, and abort signal through runtime config so tool progress and cancellation can be attributed to a specific chat/tool call.

Support both native function calling and prompt-based tool calls, and add a model-verification harness that chooses the best mode per provider.

Stream tool events separately from assistant text: `tool_calls`, `tool_result`, `tool_call_progress`, `authentication_required`, `elicitation_request`, `agent_tool_call`, `agent_tool_result`, and final token usage.

Treat MCP installation as a controlled local-tool workflow: inspect current config, ask for confirmation, run install commands with risk detection, write config, reload host, and surface server-load errors.

Test tool infrastructure by behavior, not just schemas: init/list/call across transports, reload changes, excluded tools, elicitation accept/decline/cancel, URL elicitation, OAuth-required flow, abort during model/tool execution, and retry after abort.

## Do Not Copy

Do not copy the whole desktop app architecture for Agentic Coding Lab unless a desktop product is the goal. Extract the host/control-plane patterns instead.

Do not rely on regex confirmation as a sandbox. For coding agents, shell/file tools need workspace scoping, approval policy, command segmentation, and filesystem enforcement outside the model-reachable tool code.

Do not expose local installer tools by default without a policy layer. Dive defaults `enable_local_tools` to true when not specified, which is convenient for a product but broad for a coding lab.

Do not use raw tool names when aggregating many MCP servers. Namespace or disambiguate tool names before binding to the model.

Do not persist "always allow this directory" with string-prefix authorization. Use resolved path ancestor checks and store explicit scope grants.

Do not make config serialization the secret boundary. Treat API keys, OAuth tokens, and MCP headers as secrets with explicit storage and redaction semantics.

Do not carry dead/stubbed IPC paths into a lab artifact. Either wire the local IPC path end to end or remove it.

## Fit For Agentic Coding Lab

Fit is high for tool-use control-plane patterns and medium for direct adoption. The best reusable artifacts are:

- A `ToolManager`-style registry with server lifecycle, enabled tools, reload diffing, logs, status, and tests.
- A typed approval/elicitation channel shared by all risky tools.
- A model tool-capability verifier for native and prompt-based function calling.
- A streaming event taxonomy for tool calls, results, progress, auth, and approval.
- An abort contract that reaches model streaming, tool execution, subprocesses, and MCP cancellation.
- A config schema that separates server config, per-tool visibility, auth headers, timeouts, proxy, and command aliases.

The weak fit is UI and product integration. The Electron/Tauri/OAP layers are useful examples of a productized host, but Agentic Coding Lab should implement a smaller CLI/API-oriented version with stronger sandboxing and clearer trust boundaries.

## Reviewed Paths

- `README.md`, `MCP_SETUP.md`, `BUILD.md`, `SECURITY.md`, `package.json`: product scope, setup modes, build/runtime requirements, security policy, dependency shape.
- `mcp-host/README.md`, `mcp-host/doc/dive_httpd.md`, `mcp-host/doc/oap_mcp_transform.md`, `mcp-host/pyproject.toml`: host service docs, config priorities, OAP transform examples, Python dependencies and scripts.
- `mcp-host/dive_mcp_host/httpd/app.py`, `server.py`, `_main.py`, `routers/chat.py`, `routers/tools.py`, `routers/config.py`, `routers/model_verify.py`, `routers/utils.py`: FastAPI lifecycle, chat streaming, config reload, tool listing, OAuth/elicitation endpoints, verification.
- `mcp-host/dive_mcp_host/host/host.py`, `chat.py`, `agents/chat_agent.py`, `agents/agent_factory.py`, `agents/tools_in_prompt.py`, `prompt.py`: agent creation, LangGraph loop, native/prompt tool paths, abort, prompt design.
- `mcp-host/dive_mcp_host/host/tools/__init__.py`, `mcp_server.py`, `plugin.py`, `oauth.py`, `elicitation_manager.py`, `local_http_server.py`, `hack/stdio_server.py`, `hack/httpx_wrapper.py`: MCP lifecycle, transport sessions, OAuth, elicitation, logs, subprocess and HTTP client handling.
- `mcp-host/dive_mcp_host/internal_tools/tools/*.py`, `internal_tools/prompt.py`, `internal_tools/runtime.py`: local installer tools, confirmation, bash/file/fetch behavior, MCP config mutation and reload.
- `mcp-host/dive_mcp_host/oap_plugin/*.py`: OAP plugin config injection, hidden built-in connectors, token replacement, auth routes.
- `packages/dive-mcp/src/**`, `packages/dive-core/src/lib.rs`, `packages/core-js/src/lib.rs`: built-in Rust MCP server, filesystem/fetch tools, local IPC support.
- `electron/main/service.ts`, `electron/main/index.ts`, `electron/main/constant.ts`, `src-tauri/src/host.rs`, `src-tauri/src/lib.rs`, `src-tauri/capabilities/*.json`, `src-tauri/tauri.conf.json`: desktop host process startup, dependency management, config defaults, deep links, permissions.
- `src/ipc/init.ts`, `src/App.tsx`, `src/views/Overlay/Tools/index.tsx`, `src/components/ToolDropDown.tsx`, `src/components/PopupElicitationList.tsx`: frontend host fetch proxy, config toggles, subtool exclusions, elicitation response UI.
- `mcp-host/tests/test_tools.py`, `test_host.py`, `test_chat_agent.py`, `test_tool_in_prompt.py`, `test_installer.py`, `tests/httpd/**`, `tests/oap_plugin/**`: behavioral coverage for transports, reload, tool exclusion, elicitation, OAuth, abort, config routes, installer tools, and prompt tool parsing.

## Excluded Paths

- `package-lock.json`, `Cargo.lock`, `mcp-host/uv.lock`: dependency lockfiles; reviewed only as evidence of dependency management, not line-by-line.
- `build/`, `prebuilt/`, `resources/`, `public/`, `src-tauri/icons/`, `docs/*.gif`, `docs/*.jpg`, `docs/*.png`: binary/image/packaging assets that do not alter tool execution semantics.
- `src/locales/**`, `src/styles/**`, most UI components under `src/components/**`, and visual pages under `src/views/**`: UI-only or translation/styling paths; only tool-management and elicitation UI paths were reviewed.
- `docker/**`, `scripts/docker/**`, release/notarization/download scripts not involved in host runtime: build infrastructure outside actual tool-use path.
- `mcp-host/dive_mcp_host/httpd/database/migrations/**`: database migration history; relevant storage models were considered through server and tests, but migration files are not tool-execution logic.
- `patches/**`, `public/image/**`, `src/assets/**`: dependency patches and static assets, not part of MCP host behavior.
