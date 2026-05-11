# modelcontextprotocol/typescript-sdk

- URL: https://github.com/modelcontextprotocol/typescript-sdk
- Category: mcp
- Stars snapshot: 12,396 (GitHub REST API, captured 2026-05-11)
- Reviewed commit: 2c0c481cb9dbfd15c8613f765c940a5f5bace94d
- Reviewed at: 2026-05-11
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong reference for MCP protocol boundaries, transport design, auth/resource-server helpers, and verification discipline. Adopt design patterns selectively. Do not treat the v2 main branch as production-stable yet because the repository itself marks it pre-alpha and recommends v1.x for production until v2 stabilizes.

## Why It Matters

This is the official TypeScript SDK for Model Context Protocol servers and clients. It is the best single repo to study when designing coding-agent integrations that need a typed tool boundary, resource and prompt discovery, bidirectional client/server requests, Streamable HTTP, stdio, OAuth-aware clients, and conformance-oriented testing.

For Agentic Coding Lab, the value is not only "how to expose tools over MCP." The repo shows a mature separation between protocol types, protocol runtime, high-level ergonomic APIs, runtime adapters, auth helpers, and tests. That separation is directly relevant for any agent system that needs to keep tool schemas, transport lifecycle, security policy, and context loading from collapsing into one large framework.

## What It Is

The reviewed branch is the v2 monorepo. It splits the old single package into `@modelcontextprotocol/client`, `@modelcontextprotocol/server`, private/internal `@modelcontextprotocol/core`, and thin middleware/runtime packages under `packages/middleware` plus `@modelcontextprotocol/node`.

Core responsibilities:

- `packages/core`: MCP spec-derived Zod schemas, public TypeScript types, error classes, JSON-RPC protocol runtime, task manager, Standard Schema helpers, JSON Schema validators, URI template and in-memory transports.
- `packages/server`: high-level `McpServer`, lower-level `Server`, server stdio, Web Standard Streamable HTTP transport, resource/tool/prompt registration, completions, logging, sampling, elicitation, roots, and experimental tasks.
- `packages/client`: high-level `Client`, client stdio, Streamable HTTP, legacy SSE client transport, OAuth client orchestration, client middleware, Cross-App Access, output validation, list-change tracking, and experimental tasks.
- `packages/middleware`: framework/runtime adapters for Node HTTP, Express, Hono, and Fastify, intentionally kept thin.
- `docs`, `examples`, `test`: quickstarts, guides, runnable client/server examples, integration tests, package tests, and conformance adapters.

## Research Themes

- Token efficiency: Strong. Resources, resource links, server instructions, roots, prompt templates, and tool structured output all help avoid dumping full state into prompts. Resource links are the clearest token-saving pattern: tools can return pointers to large data and let clients fetch only what they need.
- Context control: Strong. The SDK separates tools, resources, prompts, server instructions, client roots, sampling `includeContext`, annotations, and list-change notifications. It keeps context selection mostly client/host-controlled rather than letting servers push arbitrary context into every turn.
- Sub-agent / multi-agent: Conditional. The SDK is not a multi-agent framework, but bidirectional requests, roots, sampling, elicitation, and task streams can support supervisor/worker or host/server workflows.
- Domain-specific workflow: Strong. `McpServer.registerTool`, `registerResource`, `registerPrompt`, `ResourceTemplate`, `completable`, and annotations make domain workflows explicit and discoverable.
- Error prevention: Strong. It uses spec-derived runtime schemas, Standard Schema validation, capability gating, JSON Schema output validation, protocol vs SDK error separation, timeout/cancellation handling, conformance tests, and host-header protection.
- Self-learning / memory: Limited. No durable memory product is included. The relevant reusable pattern is resource/template exposure plus roots and task stores, not autonomous memory.
- Popular skills: Not a skill repo. Applicable "skills" are architectural patterns for tool registration, auth-protected MCP servers, resumable transports, typed outputs, and conformance fixtures.

## Core Execution Path

Client path:

1. User creates `new Client({ name, version }, options)`.
2. User creates a transport such as `StreamableHTTPClientTransport`, `StdioClientTransport`, or `SSEClientTransport`.
3. `client.connect(transport)` calls `Protocol.connect`, installs transport callbacks, starts the transport, sends `initialize`, validates `InitializeResult`, records server capabilities/version/instructions, sets negotiated protocol version on HTTP transports, and sends `notifications/initialized`.
4. Client methods such as `listTools`, `callTool`, `listResources`, `readResource`, `listPrompts`, and `getPrompt` call `_requestWithSchema`, which assigns JSON-RPC IDs, enforces capabilities, installs response/progress/timeout handlers, sends through the transport, and validates the response schema.
5. Inbound server requests such as `sampling/createMessage`, `elicitation/create`, and `roots/list` are handled via `setRequestHandler`; wrappers validate inbound request and returned result shapes.

Server path:

1. User creates `new McpServer({ name, version }, options)`.
2. User registers tools, resources, prompts, completions, logging, tasks, instructions, and annotations. Registration lazily installs the relevant underlying `Server` request handlers and capabilities.
3. User connects a transport with `server.connect(transport)`.
4. On `initialize`, `Server` records client capabilities/version, negotiates protocol version, returns server capabilities and optional instructions.
5. `McpServer` handlers serve `tools/list`, `tools/call`, `resources/list`, `resources/templates/list`, `resources/read`, `prompts/list`, `prompts/get`, and `completion/complete`.
6. Each inbound JSON-RPC request gets a per-request context with `mcpReq.id`, method, metadata, cancellation signal, related `send`/`notify`, optional HTTP request/auth info, and optional task context.

Transport path:

- `Transport` is deliberately minimal: `start`, `send`, `close`, `onmessage`, `onerror`, `onclose`, optional `sessionId`, and protocol-version hooks.
- stdio serializes JSON-RPC messages as newline-delimited JSON and, on the client, spawns a child process with a whitelist of inherited environment variables.
- Streamable HTTP uses POST for JSON-RPC sends and SSE for streaming responses or server-initiated messages. The server supports stateful sessions, stateless mode, JSON response mode, event-store replay, protocol-version header validation, and DELETE session termination.

## Architecture

The main architecture is layered:

- Spec/types layer: `packages/core/src/types/schemas.ts` defines Zod schemas for JSON-RPC envelopes and MCP methods. `types.ts` derives TypeScript types. `specTypeSchema.ts` exposes Standard Schema validators for public spec types.
- Runtime protocol layer: `packages/core/src/shared/protocol.ts` implements role-agnostic JSON-RPC routing, request IDs, response correlation, schema validation, progress, cancellation, timeouts, task integration, and notification handling. `Client` and `Server` subclass it.
- Role layer: `packages/client/src/client/client.ts` and `packages/server/src/server/server.ts` enforce role-specific capabilities and initialization behavior.
- Ergonomic server layer: `packages/server/src/server/mcp.ts` provides `McpServer` as the high-level API for tools, resources, prompts, completions, tool output validation, and list-changed notifications.
- Transport layer: stdio and Streamable HTTP are pluggable implementations of the same `Transport` interface. Client legacy SSE remains for compatibility, while server-side SSE is removed in v2.
- Adapter layer: Express, Hono, Fastify, and Node HTTP packages adapt request/response types and safe framework defaults. They avoid adding MCP business logic.
- Verification layer: package tests, integration tests, conformance clients/servers, example snippet sync, and barrel-clean tests keep behavior and public API boundaries checked.

The most important boundary is that `@modelcontextprotocol/core` is private/internal in v2, while `@modelcontextprotocol/client` and `@modelcontextprotocol/server` explicitly re-export a curated public API from `core/public`. This reduces accidental public API expansion and keeps Node-only pieces on named subpath exports.

## Design Choices

Protocol and types:

- JSON-RPC validation is runtime-enforced with Zod-derived schemas and guards.
- Public protocol values are exposed as TypeScript types plus Standard Schema validators, not raw internal Zod schemas.
- `ProtocolError` is reserved for JSON-RPC errors that cross the wire; `SdkError` is local-only for timeouts, closed connections, unsupported capabilities, invalid results, and HTTP transport errors.
- `Protocol._onrequest` captures the current transport at request arrival so delayed responses go back to the correct client/stream, a critical choice for concurrent HTTP and stateless deployments.

Tools/resources/prompts:

- Tool and prompt schemas use Standard Schema with JSON Schema conversion. Zod v4, ArkType, Valibot, and wrapped JSON Schema can be used.
- Tool handlers get parsed input and can return both LLM-facing `content` and programmatic `structuredContent`.
- If a tool declares `outputSchema`, server-side high-level handlers validate `structuredContent`; clients also validate after they have cached tool metadata from `listTools`.
- Tool-level failures are returned as `{ isError: true }` so the model can see and self-correct. Missing tools, bad protocol requests, and unsupported capabilities use protocol errors.
- Resource templates separate discovery/listing from read callbacks. Prompt and resource completions are optional and bounded to 100 suggestions.

Transports:

- Streamable HTTP is the preferred remote transport. Server-side SSE is removed, while client-side SSE remains for legacy fallback.
- Stateful HTTP sessions use `mcp-session-id`; stateless mode is explicit via `sessionIdGenerator: undefined`.
- Event-store resumability is opt-in. SSE priming events are gated by protocol version to avoid breaking older clients.
- The Node HTTP package wraps Web Standard transport instead of duplicating protocol logic.

Auth and security:

- Client auth is broad: simple bearer token provider, OAuth provider, dynamic registration, PKCE, client credentials, private key JWT, Cross-App Access, protected resource metadata discovery, scope selection, 401 retry, and 403 upscoping with loop prevention.
- Server auth is intentionally narrower in v2. Express exposes resource-server helpers (`requireBearerAuth`, `mcpAuthMetadataRouter`, `getOAuthProtectedResourceMetadataUrl`, `OAuthTokenVerifier`); full authorization-server helpers are removed and delegated to an IdP/OAuth library.
- Framework app helpers enable localhost DNS rebinding protection by default for localhost bindings and warn for all-interface binding without allowlists.
- Direct Web Standard transport still has deprecated opt-in host/origin validation, but docs recommend external middleware.
- Form elicitation warns against collecting secrets; URL elicitation is the path for sensitive input.
- Tool annotations are explicitly untrusted hints, not an authorization system.

## Strengths

- Clear typed boundary between MCP wire shapes, local SDK errors, JSON-RPC protocol errors, and user-level tool errors.
- Good split between core protocol runtime, role-specific APIs, and framework adapters.
- Excellent transport lessons for coding agents: stdio for local tools, Streamable HTTP for remote services, session IDs, resumability, JSON response mode, and protocol-version headers.
- Strong schema story. User-defined tool/prompt schemas are validated at execution time and converted to JSON Schema for discovery.
- Context primitives are first-class: resources, resource templates, resource links, prompts, instructions, roots, annotations, and sampling requests are not treated as one generic text blob.
- Security posture is explicit: bearer/OAuth client support, resource-server helpers, token expiry checks, scope checks, host-header validation, session validation, safe stdio env inheritance, and warnings around sensitive elicitation.
- Verification is broad: unit tests, integration tests, conformance runners, expected-failure tracking, runtime-specific tests for Bun/Deno/Cloudflare Workers, auth tests, transport tests, and public barrel tests.
- Review docs in `REVIEW.md` encode protocol/spec review discipline and recurring catches, useful as a meta-pattern for agentic coding systems.

## Weaknesses

- v2 main is pre-alpha at the reviewed commit, and the repo README says v1.x remains recommended for production until v2 stabilizes.
- Task support is powerful but complex. It adds task stores, message queues, task metadata, response routing, and experimental APIs that need careful operational design before production use.
- Auth is split across client and Express middleware. Non-Express servers can still pass `AuthInfo` through transports, but first-class resource-server helper coverage is not symmetric across Hono/Fastify/Node examples.
- Some local guidance is stale against v2 reality: `CLAUDE.md` still describes server auth as living under `packages/server/src/server/auth`, while the FAQ and code put resource-server helpers in Express and remove authorization-server helpers.
- `McpServer` completion support for `completable()` introspects Zod object shapes; this is less portable than the broader Standard Schema story.
- Client output-schema validation depends on tool metadata cached by `listTools`; server validation is the stronger guarantee when using high-level `McpServer`.
- Direct transport DNS rebinding protection is deprecated and opt-in; safe defaults come from framework helpers. Agent developers wiring raw transports must remember this boundary.
- Large surface area. For a small coding-agent MCP server, copying the full task/auth/transport design would be more complexity than needed.

## Ideas To Steal

- Keep a tiny transport contract and put JSON-RPC correlation, timeouts, cancellation, progress, and schema validation in a role-agnostic protocol layer.
- Split "tool ran and returned an error to the model" from "protocol request failed." This is important for coding agents that need the model to recover from tool failures.
- Use resource links for large or optional context instead of embedding everything in tool output.
- Treat server instructions as workflow constraints and cross-tool relationships, not duplicate tool descriptions.
- Make roots a client-owned boundary. Servers can ask what workspace roots exist, but the client decides what to expose.
- Use Standard Schema or an equivalent interface at the registration boundary, then convert to JSON Schema for discovery and validate concrete calls at runtime.
- Put Node-only or process-spawning exports behind subpath exports and test that root barrels stay browser/worker-safe.
- Provide framework adapters as thin packages with safe defaults, not as places for new protocol behavior.
- Add conformance harnesses that exercise both sides of the protocol with "everything client" and "everything server" fixtures.
- Keep review checklists near the repo. `REVIEW.md` is a good pattern for encoding recurring protocol, HTTP, schema, async, documentation, and CI catches.

## Do Not Copy

- Do not copy the whole v2 API surface unless the project truly needs client SDK, server SDK, multiple transports, OAuth, tasks, examples, and conformance harnesses.
- Do not treat tool annotations as policy enforcement. They are advisory metadata from a potentially untrusted server.
- Do not put secrets into form elicitation; route sensitive flows through URL/out-of-band paths.
- Do not rely on stateless Streamable HTTP without considering cross-client state and response routing. The SDK has defensive request-time transport capture, but app-level shared mutable state can still leak.
- Do not expose raw localhost HTTP MCP servers without host-header validation or auth.
- Do not import private core internals as public API in downstream projects. v2 is designed around curated client/server exports.
- Do not assume the v2 main branch is production-ready. Pin a stable release/branch and verify the protocol version and migration guide.

## Fit For Agentic Coding Lab

High fit as a reference system for MCP-based coding-agent infrastructure.

Best immediate applications:

- Build internal MCP servers with `McpServer` style explicit registration, object schemas, structured output, resource links, and tool-level error results.
- Use the protocol layering as a model for internal tool buses: transport-agnostic JSON-RPC runtime, role-specific capability checks, and high-level ergonomic registration APIs.
- Borrow verification ideas: conformance-style fixtures, barrel-safety tests, transport lifecycle tests, auth tests, and issue-regression tests.
- Use resource/context patterns for coding agents: roots for workspace boundaries, resources for read-only artifacts, resource links for large files, prompts for explicit workflow templates, and server instructions for cross-tool constraints.
- Use auth/security patterns for remote agent tools: bearer token provider, resource metadata discovery, scope handling, host-header validation, token expiry checks, and sensitive-data URL elicitation.

Adoption caution:

- For production MCP dependencies, use stable v1.x or a pinned v2 release after it is declared stable.
- For internal design, copy the boundaries and tests rather than the full complexity.

## Reviewed Paths

- `README.md`: v2 status, package split, installation, quickstart, docs links, v1 production recommendation.
- `docs/server.md`, `docs/client.md`, `docs/server-quickstart.md`, `docs/client-quickstart.md`, `docs/faq.md`, `docs/documents.md`, `docs/migration.md`, `docs/migration-SKILL.md`: guides for server/client execution, transports, auth, tools, resources, prompts, completions, logging, progress, sampling, elicitation, roots, tasks, deployment, migration, and FAQ.
- `packages/core/src/types/schemas.ts`, `packages/core/src/types/types.ts`, `packages/core/src/types/specTypeSchema.ts`, `packages/core/src/types/guards.ts`, `packages/core/src/types/constants.ts`: typed MCP protocol boundary, JSON-RPC envelopes, capabilities, content blocks, tools, resources, prompts, sampling, elicitation, roots, tasks, public validators, and protocol versions.
- `packages/core/src/shared/protocol.ts`, `packages/core/src/shared/transport.ts`, `packages/core/src/shared/stdio.ts`, `packages/core/src/shared/taskManager.ts`, `packages/core/src/shared/toolNameValidation.ts`, `packages/core/src/errors/sdkErrors.ts`, `packages/core/src/util/standardSchema.ts`, `packages/core/src/util/inMemory.ts`, `packages/core/src/validators/*`: runtime protocol, transport contract, message framing, tasks, tool-name warnings, local SDK errors, Standard Schema conversion/validation, in-memory transports, and validators.
- `packages/server/src/index.ts`, `packages/server/src/server/server.ts`, `packages/server/src/server/mcp.ts`, `packages/server/src/server/stdio.ts`, `packages/server/src/server/streamableHttp.ts`, `packages/server/src/server/completable.ts`, `packages/server/src/server/middleware/hostHeaderValidation.ts`, `packages/server/src/experimental/tasks/*`: public server API, initialization, capabilities, high-level registration, stdio, Web Standard Streamable HTTP, completions, host validation helper, and experimental tasks.
- `packages/client/src/index.ts`, `packages/client/src/client/client.ts`, `packages/client/src/client/stdio.ts`, `packages/client/src/client/streamableHttp.ts`, `packages/client/src/client/sse.ts`, `packages/client/src/client/auth.ts`, `packages/client/src/client/authExtensions.ts`, `packages/client/src/client/crossAppAccess.ts`, `packages/client/src/client/middleware.ts`, `packages/client/src/experimental/tasks/*`: public client API, initialization, typed calls, output validation, stdio, Streamable HTTP, legacy SSE, OAuth, client credentials, private key JWT, Cross-App Access, middleware, and experimental task streaming.
- `packages/middleware/README.md`, `packages/middleware/node/src/streamableHttp.ts`, `packages/middleware/express/src/*`, `packages/middleware/hono/src/*`, `packages/middleware/fastify/src/*`: thin runtime/framework adapters, DNS rebinding defaults, Express auth helpers, Node HTTP wrapping, and parsed-body handling.
- `examples/server/README.md`, `examples/client/README.md`, `examples/server/src/simpleStreamableHttp.ts`, `examples/server/src/simpleStatelessStreamableHttp.ts`, `examples/server/src/resourceServerOnly.ts`, `examples/server/src/honoWebStandardStreamableHttp.ts`, `examples/server/src/mcpServerOutputSchema.ts`, `examples/server/src/elicitationFormExample.ts`, `examples/server/src/elicitationUrlExample.ts`, `examples/server/src/simpleTaskInteractive.ts`, `examples/client/src/simpleStreamableHttp.ts`, `examples/client/src/simpleOAuthClient.ts`, `examples/client/src/simpleClientCredentials.ts`, `examples/client/src/streamableHttpWithSseFallbackClient.ts`, `examples/client/src/parallelToolCallsClient.ts`, `examples/client/src/multipleClientsParallel.ts`, `examples/client/src/simpleTaskInteractiveClient.ts`: runnable usage patterns for server/client, auth, output schemas, elicitation, tasks, resumability, fallback, and concurrency.
- `test/conformance/*`, `test/integration/test/*`, `packages/*/test/**/*`: conformance clients/servers, auth conformance, integration tests, transport/session/resumability tests, Standard Schema tests, runtime tests, issue regressions, barrel-clean tests, and package tests.
- `REVIEW.md`, `SECURITY.md`, `CLAUDE.md`: review discipline, security reporting, and repository architecture guidance.

## Excluded Paths

- `.git/`, Git metadata, and local clone bookkeeping: generated repository state, not relevant to SDK architecture.
- `.github/`, `.changeset/`, `lefthook.yml`, `lefthook-local.example.yml`, `.prettier*`, `.npmrc`, `common/*`, `vitest.workspace.js`, `typedoc.config.mjs`: CI, release, lint, test, and config support. I read package/test scripts where they affected verification, but did not review workflow internals because the assigned focus was SDK design and agent applicability.
- `pnpm-lock.yaml`, `package-manager` lock/config details, `node_modules` if present: dependency resolution artifacts, not design source.
- Generated docs outputs such as `tmp/docs` or `dist` if produced locally: build artifacts. Public API was reviewed from source, package exports, and barrel-clean tests.
- Binary/sample payload contents such as base64 image/audio fixtures in conformance and examples: only their use as content-block fixtures matters.
- Full line-by-line review of every example and every test case: sampled broadly across server, client, auth, transport, tasks, conformance, and integration paths. Exhaustive test archaeology would not change the architectural findings.
- UI-only artifacts: none found as a primary concern. This SDK is library/framework code, not an app UI.
