# modelcontextprotocol/python-sdk

- URL: https://github.com/modelcontextprotocol/python-sdk
- Category: mcp
- Stars snapshot: 22,949 (GitHub REST API, captured 2026-05-11)
- Reviewed commit: 161834d4aee2633c42d3976c8f8751b6c4d947d5
- Reviewed at: 2026-05-11
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong reference implementation for MCP client/server protocol boundaries in Python. The reusable parts are the typed Pydantic protocol model, transport-independent session loop, in-memory test harness, high-level server decorators, streamable HTTP transport, and OAuth/resource-server security split. The main branch is also mid-transition to v2, with README/docs drift, so treat it as an architecture source more than a stable user manual.

## Why It Matters

This is the official Python SDK for the Model Context Protocol. It defines how Python tools, resources, prompts, clients, and servers should speak MCP over stdio, streamable HTTP, SSE, WebSocket, and in-memory transports.

For Agentic Coding Lab, it matters because MCP is a common boundary between coding agents and external capabilities. The repo shows how to make that boundary typed, testable, transport-agnostic, and security-aware instead of exposing ad hoc function calls.

## What It Is

The package `mcp` implements both low-level MCP protocol machinery and a higher-level Python server framework. The low-level layer models JSON-RPC messages and MCP methods, runs request/response sessions, and dispatches handlers. The higher-level `MCPServer` layer turns typed Python functions into MCP tools, resources, prompts, completions, and custom HTTP routes.

The reviewed commit is the main branch with v2 documentation present. `README.md` still describes stable v1.x usage, while `README.v2.md` and `docs/migration.md` describe the v2 pre-alpha API on main.

## Research Themes

- Token efficiency: Conditional. The SDK does not implement context compression or token budgeting, but resources, prompts, roots, pagination, and structured tool outputs give hosts narrower context surfaces than dumping raw data.
- Context control: Strong. MCP resources, resource templates, prompts, roots, sampling `include_context`, elicitation, `_meta`, progress, logging, and explicit `Context` injection create clear control points for what an agent can see or request.
- Sub-agent / multi-agent: Limited. `ClientSessionGroup` aggregates multiple server sessions and can disambiguate component names, but the repo does not orchestrate autonomous agents.
- Domain-specific workflow: Strong. Function decorators and type-derived schemas make it straightforward to wrap domain workflows as tools, resources, prompts, and HTTP-adjacent routes.
- Error prevention: Strong. Pydantic protocol models, TypeAdapter unions, output schema validation, version negotiation, transport validation, DNS rebinding checks, OAuth middleware, and extensive tests reduce malformed calls.
- Self-learning / memory: Weak. The SDK can expose memory-like resources, but it does not implement durable memory, learning loops, or retrieval policy.
- Popular skills: Strong for MCP skill surfaces: tools, resources, prompts, completions, sampling, elicitation, roots, logging, progress, and transport setup. It is not a packaged coding-agent skill library.

## Core Execution Path

A client starts through either the high-level `Client` wrapper or a raw transport context. The high-level wrapper chooses in-memory transport for an in-process `Server`/`MCPServer`, streamable HTTP for a URL, or a caller-supplied custom transport.

The transport yields read/write object streams of `SessionMessage`. `ClientSession` and `ServerSession` extend `BaseSession`, which allocates request IDs, wraps MCP messages as JSON-RPC, tracks in-flight responders, dispatches notifications, handles progress callbacks, normalizes response IDs, and runs a background receive loop.

Initialization negotiates protocol version and capabilities. The client sends `InitializeRequest`; the server replies with capabilities derived from registered handlers and options. After initialization, client methods like `list_tools`, `call_tool`, `read_resource`, and `get_prompt` become typed JSON-RPC requests.

On the server side, the low-level `Server.run()` receives each request, builds a `ServerRequestContext`, extracts tracing metadata, checks lifecycle state, dispatches to the configured handler, and converts exceptions into MCP `ErrorData` unless configured to raise.

The high-level `MCPServer` registers handlers on its low-level server. Tool calls route through `ToolManager`; resource reads route through `ResourceManager`; prompt rendering routes through `PromptManager`. Python function signatures generate input schemas, return annotations drive output schemas, and explicit `Context` parameters receive request/session helpers.

Responses and notifications flow back over the same transport. Stateful transports can support server-to-client requests such as sampling, roots, and elicitation. Stateless streamable HTTP deliberately blocks those workflows because there is no persistent client channel.

## Architecture

The protocol boundary lives in `src/mcp/types/`. `MCPModel` is a Pydantic base model with snake_case Python fields and camelCase wire aliases. The module defines MCP request/result/notification/content/resource/tool/prompt/sampling/elicitation/task models and TypeAdapter unions for client-to-server and server-to-client JSON-RPC directions.

The shared session layer lives in `src/mcp/shared/`. It abstracts over transports with memory object streams, wraps JSON-RPC envelopes, manages request/response routing, handles cancellation/progress metadata, and keeps HTTP request metadata attached to messages.

The client layer lives in `src/mcp/client/`. `ClientSession` exposes typed MCP client calls and handles server requests for sampling, elicitation, roots, and ping through callbacks. `Client` manages transport lifecycle. `ClientSessionGroup` composes multiple sessions and remembers which session owns each tool/resource/prompt.

The low-level server layer lives in `src/mcp/server/`. `Server` is configured with constructor handlers, derives capabilities, manages lifespan, dispatches requests, and can expose streamable HTTP or legacy SSE Starlette apps. `ServerSession` enforces initialization and sends server-to-client requests/notifications.

The ergonomic server layer lives in `src/mcp/server/mcpserver/`. `MCPServer` provides decorators for tools, resources, prompts, completions, and custom routes. Managers validate function names, parameters, URI templates, prompt arguments, and structured outputs.

Transports are separated into stdio, streamable HTTP, SSE, WebSocket, and in-memory implementations. The streamable HTTP implementation is the most complete network transport: it handles session IDs, protocol-version headers, JSON and SSE responses, resumability, event replay, standalone GET streams, DELETE termination, and stateful/stateless manager modes.

Auth is split between reusable models, client OAuth, server provider protocols, bearer-token middleware, protected resource metadata routes, and token/client validation helpers. The server side expects applications to provide a `TokenVerifier` or authorization provider.

## Design Choices

The SDK keeps MCP protocol models strongly typed while preserving wire compatibility through Pydantic aliases. This lets Python code use snake_case without hand-written camelCase serialization.

The v2 low-level server favors explicit constructor handlers instead of decorator registration. That makes capabilities and dispatch behavior visible at construction time. The high-level `MCPServer` keeps decorators for normal application authors.

Every transport is reduced to the same read/write stream shape. That makes stdio, HTTP, WebSocket, and in-memory execution share the same session code and test harness.

Context is explicit. v2 removes ambient `get_context()` usage and injects `Context` only when a function signature asks for it.

Tool schemas are generated from Python type hints and docstrings. Structured return schemas can come from Pydantic models, TypedDict, dataclasses, typed classes, dicts, primitives, and generics. The client caches tool output schemas and validates returned `structured_content`.

Auth is deliberately pluggable. The SDK supplies OAuth discovery, PKCE, dynamic client registration support, protected resource metadata, bearer middleware, scope checks, and token model types, but token verification and provider storage are application responsibilities.

## Strengths

The typed protocol boundary is broad and concrete. Requests, notifications, results, content blocks, resources, prompts, sampling, elicitation, task-related experimental types, and JSON-RPC wrappers are represented as explicit models.

The transport/session split is clean. The same `BaseSession` machinery works across stdio, streamable HTTP, SSE, WebSocket, and in-memory tests.

The in-memory client/server path is excellent for verification. Tests can instantiate a `Client` around an in-process `MCPServer` without ports or subprocesses, while still exercising protocol sessions.

Security work is practical. Localhost streamable HTTP apps auto-enable DNS rebinding protection; POST content type is validated; stdio child processes inherit only a small safe environment by default; bearer auth checks expiry and scopes; OAuth client code supports PKCE and resource indicators.

The high-level server API is useful for coding agents. It gives tool schemas, structured outputs, progress reporting, logging, resource reads, elicitation, sampling, and prompt rendering without making every server author write JSON-RPC plumbing.

The test suite covers important protocol edges: initialization, version negotiation, structured output validation, request cancellation, response ID normalization, streamable HTTP replay/resumption, security headers, OAuth flows, bearer auth, sampling validation, and MCPServer integrations.

## Weaknesses

Documentation is split and partly stale. The stable README still documents v1, `README.v2.md` says v2 is pre-alpha, and several docs pages are explicit stubs.

The main branch appears to remain in a v2 transition despite docs saying stable v2 was anticipated in Q1 2026. Production adopters need to check release branches/tags rather than copying main blindly.

Tool annotations are advisory. The SDK models read-only/destructive/open-world hints, but clients are told not to trust annotations from untrusted servers.

High-level tool exceptions are often converted into `CallToolResult(is_error=True)` text. That is convenient for agents, but it can flatten typed application failures unless authors raise `MCPError` intentionally.

Stateless streamable HTTP cannot support server-to-client sampling, roots, or elicitation. Teams need stateful sessions for richer agent workflows.

Auth correctness depends on the embedding application. The SDK gives protocols, metadata routes, and middleware, but production token verification, revocation, storage, and issuer policy remain out of tree.

The low-level API is more explicit but less extensible after construction. Some high-level features still reach into private low-level handler registration, which is not a great pattern to copy.

## Ideas To Steal

Use typed union adapters for every protocol direction, not one loose JSON object type.

Normalize all transports into a `SessionMessage` stream so the protocol session can ignore how bytes move.

Provide an in-memory transport that exercises the real session code for tests.

Generate tool input and output schemas from language-native types, then validate structured outputs on both server and client paths.

Inject request context by function annotation rather than relying on ambient globals.

Auto-enable DNS rebinding protection for localhost HTTP servers.

Separate OAuth/resource-server metadata, bearer-token verification, and application token-provider responsibilities.

Use progress tokens in `_meta` so long-running requests can report progress without adding method-specific protocol fields.

Offer a session-group abstraction for composing multiple MCP servers while retaining source-session routing.

## Do Not Copy

Do not ship generated docs or stubs as the main source of truth for a transitioning API.

Do not treat tool annotations as an authorization system. They are hints, not enforceable policy.

Do not assume stateless HTTP is enough for agent workflows that need server-to-client callbacks.

Do not hide all application errors as untyped tool text if callers need programmatic recovery.

Do not make private handler internals necessary for normal extension points.

Do not expose OAuth hooks without clear production examples for token verification, storage, revocation, and issuer constraints.

## Fit For Agentic Coding Lab

Fit is in-scope and strong. This repo is one of the best SDK references for agent capability boundaries: typed calls, strict schemas, transport isolation, explicit context, in-memory verification, and practical auth/transport hardening.

It is not a complete agent framework, memory system, evaluator, or multi-agent orchestrator. The best use is as a design baseline for how coding agents should safely call external tools and expose local project capabilities through MCP.

## Reviewed Paths

- `/tmp/myagents-research/modelcontextprotocol-python-sdk/README.md`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/README.v2.md`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/pyproject.toml`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/docs/index.md`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/docs/migration.md`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/docs/testing.md`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/docs/concepts.md`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/docs/authorization.md`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/docs/low-level-server.md`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/src/mcp/types/`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/src/mcp/shared/session.py`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/src/mcp/shared/message.py`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/src/mcp/shared/_stream_protocols.py`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/src/mcp/shared/memory.py`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/src/mcp/shared/exceptions.py`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/src/mcp/shared/auth.py`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/src/mcp/shared/auth_utils.py`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/src/mcp/client/client.py`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/src/mcp/client/session.py`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/src/mcp/client/session_group.py`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/src/mcp/client/_transport.py`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/src/mcp/client/_memory.py`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/src/mcp/client/stdio.py`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/src/mcp/client/sse.py`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/src/mcp/client/streamable_http.py`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/src/mcp/client/websocket.py`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/src/mcp/client/auth/oauth2.py`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/src/mcp/client/auth/utils.py`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/src/mcp/client/auth/extensions.py`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/src/mcp/server/lowlevel/server.py`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/src/mcp/server/session.py`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/src/mcp/server/context.py`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/src/mcp/server/models.py`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/src/mcp/server/validation.py`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/src/mcp/server/stdio.py`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/src/mcp/server/sse.py`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/src/mcp/server/streamable_http.py`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/src/mcp/server/streamable_http_manager.py`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/src/mcp/server/transport_security.py`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/src/mcp/server/websocket.py`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/src/mcp/server/mcpserver/`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/src/mcp/server/auth/`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/examples/snippets/`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/examples/servers/simple-auth/`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/examples/clients/simple-auth-client/`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/examples/servers/`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/examples/clients/`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/tests/client/test_session.py`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/tests/client/test_client.py`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/tests/client/test_output_schema_validation.py`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/tests/client/test_auth.py`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/tests/server/mcpserver/test_integration.py`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/tests/server/mcpserver/test_tool_manager.py`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/tests/server/test_streamable_http_security.py`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/tests/server/test_validation.py`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/tests/server/auth/test_routes.py`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/tests/server/auth/middleware/test_bearer_auth.py`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/tests/shared/test_session.py`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/tests/shared/test_streamable_http.py`
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/tests/test_types.py`

## Excluded Paths

- `/tmp/myagents-research/modelcontextprotocol-python-sdk/.git/`: VCS internals and packed objects; reviewed commit captured separately.
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/uv.lock`: generated dependency lockfile; dependency architecture reviewed through `pyproject.toml`.
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/examples/mcpserver/mcp.png`: static image asset for examples; no SDK architecture.
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/examples/clients/simple-chatbot/mcp_simple_chatbot/test.db`: binary sample database; app data, not protocol design.
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/docs/hooks/gen_ref_pages.py`: documentation-generation helper; not runtime protocol or SDK architecture.
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/src/mcp/cli/`: skimmed only for package shape; Claude/app installer plumbing is secondary to MCP SDK design.
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/src/mcp/os/`: platform utility support; not central to protocol, transport, auth, or coding-agent applicability.
- `/tmp/myagents-research/modelcontextprotocol-python-sdk/src/mcp/server/mcpserver/experimental/`: skimmed task capability surface only; experimental task orchestration is not central to current MCP SDK architecture.
