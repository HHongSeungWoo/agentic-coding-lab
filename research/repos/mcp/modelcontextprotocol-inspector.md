# modelcontextprotocol/inspector

- URL: https://github.com/modelcontextprotocol/inspector
- Category: mcp
- Stars snapshot: 9,720 (GitHub REST API, captured 2026-05-11)
- Reviewed commit: f18775a1a5f3bd4b319763b4c12b3230091dd122
- Reviewed at: 2026-05-11
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong reference for MCP debugging and verification UX. Best ideas are the split UI/proxy/CLI architecture, request/notification visibility, proxy auth separation, OAuth debugging flow, config export, and automated CLI checks. Do not copy the browser-facing process-spawning proxy without localhost binding, per-session auth, origin checks, and clear warnings.

## Why It Matters

MCP Inspector is the official visual and CLI test tool for MCP servers. It sits at the point where protocol correctness, transport behavior, auth, server configuration, and developer debugging all meet.

For Agentic Coding Lab, this repo is useful because it shows how an agent-facing MCP workflow can be verified from two angles:

- Interactive inspection: connect to stdio, SSE, or Streamable HTTP servers; browse resources, prompts, tools, roots, tasks, sampling, elicitation, metadata, auth state, request history, and notifications.
- Scriptable checks: run `--cli` commands that list/call tools and read resources/prompts with JSON output, config files, headers, env vars, and metadata. This is directly useful for coding-agent CI or local verification loops.

The repo also carries hard-learned security choices after MCP Inspector's proxy RCE history: local-only binding by default, proxy session auth by default, origin validation, separate proxy auth header, and strong warnings around disabling auth.

## What It Is

The project is a TypeScript monorepo published as `@modelcontextprotocol/inspector` with three workspaces:

- `client`: React/Vite UI. It is the browser client for debugging MCP servers. It manages connection settings, auth, config, tool/resource/prompt/task views, request history, notifications, sampling, elicitation, roots, metadata, and MCP Apps rendering.
- `server`: Express proxy. It is both a local HTTP server for the browser and an MCP client to the target server. It bridges browser transports to stdio, SSE, or Streamable HTTP MCP servers.
- `cli`: command-line launcher and direct MCP CLI. Without `--cli`, it starts the web UI plus proxy. With `--cli`, it connects directly to a target MCP server and emits JSON for supported methods.

The README explicitly says the proxy is not an intercepting network proxy. It is a protocol bridge: browser UI to Inspector proxy to target MCP server.

## Research Themes

- Token efficiency: Moderate. The Inspector does not optimize prompts directly, but it helps debug token-efficient MCP designs by exposing resources, resource templates, prompts, tool schemas, `_meta`, resource links, and structured results without forcing all server context into one text blob.
- Context control: Strong. The UI separates resources, prompts, tools, roots, metadata, sampling, elicitation, tasks, request history, and notifications. It makes the client's visible MCP context explicit instead of hiding it behind one chat transcript.
- Sub-agent / multi-agent: Conditional. It is not a multi-agent framework, but sampling, elicitation, roots, tasks, and client-side request handlers model bidirectional host/server flows that could support agent-supervisor patterns.
- Domain-specific workflow: Strong. The Inspector lets developers inspect concrete MCP capabilities, run tools with schema-derived forms, export `mcp.json` server entries, and replay equivalent checks through CLI mode.
- Error prevention: Strong. The code validates schemas, surfaces transport and auth failures, records request/response history, forwards upstream 401 details, separates proxy auth from server auth, tests config/header/metadata behavior, and uses e2e checks for startup and CLI URL prefill paths.
- Self-learning / memory: Limited. It persists local browser settings, OAuth/session values, last connection settings, and metadata, but it does not implement durable agent memory or learning.
- Popular skills: Not a skill or prompt-pack repo. Reusable "skills" are operational patterns: MCP server smoke tests, auth debugging, config export, request history, notification visibility, and safe local proxy design.

## Core Execution Path

Web launcher path:

1. Package bin `mcp-inspector` points to `cli/build/cli.js`, implemented by `cli/src/cli.ts`.
2. `cli.ts` parses `-e`, `--config`, `--server`, `--transport`, `--server-url`, `--header`, and `--cli`.
3. Without `--cli`, `runWebClient` spawns `client/bin/start.js` and passes env vars, transport, server URL, command, and args.
4. `client/bin/start.js` generates or receives `MCP_PROXY_AUTH_TOKEN`, parses server command/env flags, starts the proxy server (`server/build/index.js` in production or `server/src/index.ts` through `tsx watch` in dev), then starts the static client server (`client/bin/client.js`) or Vite dev server.
5. The browser opens `http://localhost:6274` with query params for `MCP_PROXY_PORT` and, when auth is enabled, `MCP_PROXY_AUTH_TOKEN`.

Proxy server path:

1. `server/src/index.ts` starts Express on `HOST` or `localhost`, `SERVER_PORT` or `6277`.
2. It installs CORS, exposes `mcp-session-id` and `WWW-Authenticate`, then applies per-route origin validation and proxy auth middleware.
3. `/health` and `/config` let the UI verify the proxy and load defaults.
4. `/stdio` creates a target `StdioClientTransport`, creates an `SSEServerTransport` back to the browser, forwards child-process stderr as MCP log notifications, and calls `mcpProxy`.
5. `/sse` creates an upstream `SSEClientTransport`, creates an `SSEServerTransport` back to the browser, preserves dynamic headers, and calls `mcpProxy`.
6. `/mcp` handles Streamable HTTP sessions. First POST without `mcp-session-id` creates a target transport, a `StreamableHTTPServerTransport` for the browser, stores session maps, and calls `mcpProxy`; later GET/POST/DELETE route by `mcp-session-id`.
7. `/message` handles browser POSTs for SSE-backed sessions.
8. `/fetch` lets the browser do OAuth discovery/token fetches through the proxy to avoid CORS, limited to `http:` and `https:` URLs.
9. `/sandbox` serves the MCP Apps sandbox proxy HTML with rate limiting.

Bridge path:

1. `server/src/mcpProxy.ts` wires `transportToClient.onmessage` to `transportToServer.send` and `transportToServer.onmessage` to `transportToClient.send`.
2. On upstream send failure for a JSON-RPC request, it returns an Inspector-specific JSON-RPC error code `-32099` with serialized transport details.
3. It attaches valid HTTP status values and captures upstream 401 snapshots so the browser can trigger OAuth recovery instead of treating all proxy errors as opaque failures.
4. Close/error handlers shut down the peer transport and log likely target-server problems such as connection refused or 404.

Browser connection path:

1. `App.tsx` initializes command, args, URL, transport type, connection type, custom headers, OAuth fields, metadata, roots, history, notifications, and Inspector config from query params and storage.
2. `Sidebar.tsx` lets the user choose stdio/SSE/Streamable HTTP, proxy vs direct for remote transports, command/args/env, custom headers, OAuth settings, request timeouts, proxy address, proxy token, task TTL, and exported server config.
3. `useConnection.ts` checks proxy health for proxy mode, constructs SDK `Client` capabilities, merges server auth headers and proxy auth headers, chooses direct or proxy URL, creates `SSEClientTransport` or `StreamableHTTPClientTransport`, connects, records capabilities/server info/instructions, and installs notification/request handlers.
4. UI tabs call `makeRequest` for `tools/list`, `tools/call`, `resources/list`, `resources/read`, `prompts/list`, `prompts/get`, `tasks/list`, `tasks/cancel`, ping, logging level, roots notifications, completion requests, sampling, and elicitation.
5. Request/response pairs are appended to history; server notifications are appended separately and surfaced in `HistoryAndNotifications`.

CLI mode path:

1. `cli.ts` sees `--cli` and spawns `cli/build/index.js`.
2. `cli/src/index.ts` requires a target and `--method`, auto-detects transport from target URL path (`/mcp` means HTTP, `/sse` means SSE, command means stdio), or honors `--transport`.
3. It creates SDK transport directly, without the Inspector proxy.
4. It connects a `Client`, optionally sets logging to debug if supported, runs one method, prints formatted JSON, and closes transport.
5. Supported methods at the reviewed commit are `tools/list`, `tools/call`, `resources/list`, `resources/read`, `resources/templates/list`, `prompts/list`, `prompts/get`, and `logging/setLevel`.

## Architecture

The core architecture is a three-part tool:

- UI host: React components and hooks present MCP capabilities and collect developer inputs.
- Local proxy: Express process owns privileged operations such as spawning stdio MCP servers and bridging browser-incompatible transports.
- Direct CLI: Node command path for automation and coding-agent feedback loops.

Important boundaries:

- Browser never spawns local MCP processes directly. It talks to the proxy.
- Proxy session auth uses `X-MCP-Proxy-Auth`, while upstream server auth uses `Authorization` or custom headers. This prevents the proxy token from colliding with the target server's bearer token.
- Direct mode is only for remote SSE/Streamable HTTP and requires target-server CORS. Stdio always goes through the proxy because the browser cannot spawn a process.
- Config has two layers: MCP server launch settings in command/URL/env/custom headers, and Inspector runtime config in `DEFAULT_INSPECTOR_CONFIG`.
- The UI exposes both host-as-client features and server-to-client features. It declares sampling, elicitation, roots, and tasks capabilities, then handles incoming `sampling/createMessage`, `elicitation/create`, `roots/list`, and task polling requests.
- MCP Apps are rendered through `@mcp-ui/client` with a double-iframe sandbox served by the proxy.

## Design Choices

Security and auth:

- Proxy auth is enabled by default. The proxy generates a 32-byte random token unless `MCP_PROXY_AUTH_TOKEN` is set.
- `DANGEROUSLY_OMIT_AUTH` disables proxy auth but README and server logs warn that this is unsafe.
- Both client and proxy bind to `localhost` by default. `HOST=0.0.0.0` is allowed but documented as trusted-network-only.
- Origin validation defaults to `http://localhost:<CLIENT_PORT>` and can be expanded with `ALLOWED_ORIGINS`.
- Token comparison uses `timingSafeEqual` after length check.
- Proxy forwards only selected upstream headers: `mcp-*`, `authorization`, `last-event-id`, and explicitly declared custom auth headers. It excludes the proxy auth header and browser/proxy MCP session header from upstream forwarding.
- OAuth discovery and token exchange can run through `createProxyFetch` in proxy mode, while direct mode uses native browser fetch.
- OAuth debugger uses an explicit state machine: metadata discovery, client registration, authorization redirect, authorization code, token request, complete.
- Redirect URL validation blocks non-HTTP(S) schemes before browser navigation or server website links.

Transport and error behavior:

- Stdio command args are parsed with `shell-quote`, then resolved through `findActualExecutable`.
- Stdio child stderr is converted into MCP `notifications/message` with syslog-ish severity inference.
- Streamable HTTP sessions are mapped by browser/proxy session IDs and upstream server session IDs are logged when available.
- Dynamic headers are updated in place per session so later requests can carry new auth/session values while preserving SDK-required `Accept` headers.
- Upstream 401 handling is special: the proxy captures `WWW-Authenticate`, body, and content type, then returns enough data for browser-side OAuth recovery.
- The proxy uses the JSON-RPC server-error band code `-32099` for Inspector-specific upstream transport failures and tests that client/server constants do not drift.

UX and verification:

- The sidebar exports both a single server entry and a full `mcpServers` file. This makes a debugged setup portable to Claude Code, Cursor, Inspector CLI, or other MCP clients.
- Request history and server notifications are separate panes, ordered newest-first, expandable, and tested for stable expanded state after new entries arrive.
- Tool forms convert schema-driven values and follow repo guidelines: omit empty optional values, preserve explicit defaults, always include required fields, and let the MCP server perform deep validation.
- Task-aware tools show run-as-task controls based on tool `execution.taskSupport` and server task support.
- Metadata is filtered to avoid reserved namespaces and invalid `_meta` key shapes.
- Auth UI supports quick OAuth and guided OAuth, with resource metadata discovery and step-by-step debugging.

## Strengths

- Excellent debugging surface for MCP servers: capabilities, tools, resources, prompts, tasks, roots, sampling, elicitation, metadata, request history, and notifications are all visible.
- Good separation between privileged local process control and unprivileged browser UI.
- CLI mode is practical for agent verification: one command can list tools, call tools, read resources, get prompts, pass headers/env/metadata, and emit machine-readable JSON.
- Proxy auth is intentionally distinct from upstream server auth, avoiding one of the easiest local-proxy design mistakes.
- Auth failure handling is detailed. Upstream 401s are captured across SSE and Streamable HTTP and can trigger OAuth instead of becoming generic proxy failures.
- Config export bridges debugging and production client setup. The same server settings can move into `mcp.json`.
- Test suite covers the behavior that matters for agents: CLI subprocess behavior, config files, env parsing, JSON tool args, headers, metadata, proxy auth headers, config endpoint auth, OAuth scope discovery, URL validation, request history, tools UI, and e2e startup/URL parameter paths.
- README security guidance is concrete and tied to the known RCE class: do not expose the proxy to untrusted networks, do not disable auth, and understand browser-based attack paths.

## Weaknesses

- The web UI is useful for humans, but too stateful and browser-centric to be a direct agent runtime. Agents should use the CLI patterns or a smaller harness.
- CLI mode supports core list/read/call methods but not the full UI surface such as sampling approvals, elicitation resolution, roots changes, tasks payload flows, or OAuth debugging.
- Proxy `/fetch` is necessary for OAuth/CORS, but it is still a generic authenticated HTTP fetch primitive. Its safety depends on local binding, auth, and origin controls staying enabled.
- The session token is placed in the launch URL for convenience. That reduces onboarding friction but has normal URL-token tradeoffs around browser history, screenshots, logs, and shared URLs.
- Stdio command spawning is inherently high risk. The Inspector mitigates access to the proxy, but once an authenticated browser can reach it, it can ask the proxy to run local commands.
- Security relies on multiple distributed defaults: localhost bind, proxy auth, origin validation, allowed origins, custom header filtering, redirect validation, sandbox validation, and user not setting `DANGEROUSLY_OMIT_AUTH`.
- The UI contains some stub-like/less-central surfaces, such as `ConsoleTab`, and many reusable UI primitives that are not relevant to the underlying MCP debugging architecture.
- Streamable HTTP and SSE paths share concepts but have separate route/session mechanics, increasing maintenance and testing burden.

## Ideas To Steal

- Provide both human inspection and scriptable verification for every integration protocol. UI for diagnosis, CLI JSON for agents and CI.
- Make request history and notifications first-class. Coding agents need to see "what did I send" and "what did the server emit" separately.
- Keep proxy auth and upstream server auth on separate headers. Never overload `Authorization` for both.
- Export successful debug configurations to the same config shape used by production clients.
- Add one Inspector-specific transport error code with structured `data` so client logic can distinguish upstream auth failures, HTTP status, and proxy infrastructure failures.
- Use proxy fetch only as an authenticated helper for browser limitations, not as the whole API.
- Treat OAuth as debuggable state, not a black box: show metadata discovery, client registration, redirect, code exchange, tokens, scopes, and resource metadata.
- Convert child-process stderr into visible notifications so local stdio servers can be debugged without tailing separate terminal logs.
- Build CLI tests around real subprocesses and in-process HTTP/SSE MCP test servers. This catches packaging, argument parsing, and transport issues that pure unit tests miss.
- Use e2e tests for URL/query startup state because config prefill is part of the product contract.

## Do Not Copy

- Do not copy a browser-accessible local process-spawning proxy without default auth, localhost binding, origin checks, and explicit unsafe-mode warnings.
- Do not expose `/fetch` or equivalent SSRF-capable helpers broadly. If a similar endpoint is needed, keep it authenticated, scoped, logged, and local by default.
- Do not put proxy session tokens in URLs for non-local or shared environments. Prefer a setup flow that avoids URL token persistence if the workflow is not purely local.
- Do not make a coding agent depend on the full React UI state model. Copy the CLI/harness pieces for automation and keep UI as a diagnostic layer.
- Do not assume custom headers are safe to forward wholesale. The reviewed proxy forwards a constrained set and uses an explicit custom-header allow mechanism.
- Do not disable auth for convenience while testing browser-driven local proxies. The README's warning is central to the threat model, not decorative.
- Do not copy all OAuth debugger complexity unless OAuth is a first-class support target. For internal tools, a smaller bearer-token path plus clear 401 diagnostics may be enough.
- Do not treat schema-derived UI validation as a replacement for server-side validation. The README explicitly leaves deep validation to the MCP server.

## Fit For Agentic Coding Lab

High fit as a reference for MCP debugging, verification, and safe local tooling.

Best applications:

- Add a scriptable MCP smoke-test harness modeled on Inspector CLI: list tools, call a tool, read resources, get prompts, pass metadata/headers/env, and return JSON for agent evaluation.
- Add a "debug transcript" artifact for agent tool calls: request JSON, response JSON, notifications, transport errors, and timing/timeout settings.
- Add config export/import for internal MCP servers so working debug setups become reusable agent configs.
- Use Inspector's auth split as a baseline for any local proxy: `X-...-Proxy-Auth` for proxy access, `Authorization` for target server access.
- Borrow proxy 401 propagation and structured transport errors for agent-friendly recovery from OAuth/bearer failures.
- Reuse the test pattern: real subprocess CLI tests, dynamic-port HTTP servers, request recording, header assertions, metadata assertions, and e2e checks for startup parameters.

Adoption caution:

- Use the repo as a debugging and verification pattern, not as a direct embedded runtime.
- Pin the Inspector version if using it operationally; the reviewed commit is a current main-branch snapshot.
- Keep security defaults stricter than the local developer case if the tool is exposed beyond a single developer machine.

## Reviewed Paths

- `README.md`: architecture, quickstart, stdio/SSE/Streamable HTTP usage, config file support, query params, server export, CLI mode, UI vs CLI comparison, auth/security warnings, local binding, DNS rebinding protection, timeouts, and tool input validation guidance.
- `package.json`, `client/package.json`, `server/package.json`, `cli/package.json`: workspace layout, package entrypoints, scripts, dependencies, test commands, and Node version expectations.
- `client/bin/start.js`, `client/bin/client.js`: production/dev launcher, token generation, proxy/client startup, browser open URL construction, port handling, static client serving, and cache headers.
- `server/src/index.ts`: Express proxy routes, auth middleware, origin validation, header forwarding, dynamic header updates, stdio/SSE/Streamable HTTP transport creation, 401 handling, config/health/fetch/sandbox endpoints, local binding, and startup logging.
- `server/src/mcpProxy.ts`: transport bridge, close/error propagation, Inspector transport error serialization, upstream 401 capture, and JSON-RPC error response behavior.
- `server/static/sandbox_proxy.html`: MCP Apps double-iframe sandbox relay, referrer/origin validation, sandbox permissions, iframe isolation self-test, and postMessage routing.
- `client/src/App.tsx`: global UI state, connection defaults, local/session storage, metadata filtering, tab routing, request/notification handlers, tool/resource/prompt/task orchestration, sampling, elicitation, roots, and auth debugger routing.
- `client/src/lib/hooks/useConnection.ts`: SDK client setup, proxy health checks, direct/proxy URL construction, header merging, proxy auth injection, OAuth token injection, request history, timeout/progress config, capabilities, notifications, incoming sampling/elicitation/roots/tasks handlers, and disconnect cleanup.
- `client/src/lib/proxyFetch.ts`, `client/src/lib/auth.ts`, `client/src/lib/oauth-state-machine.ts`, `client/src/lib/connectionAuthErrors.ts`, `client/src/lib/constants.ts`, `client/src/lib/configurationTypes.ts`, `client/src/utils/configUtils.ts`, `client/src/utils/urlValidation.ts`: proxy fetch shape validation, OAuth provider/session storage, guided OAuth state machine, auth error detection, default config, proxy address/token helpers, query overrides, and redirect URL safety.
- `client/src/components/Sidebar.tsx`, `AuthDebugger.tsx`, `OAuthFlowProgress.tsx`, `HistoryAndNotifications.tsx`, `ToolsTab.tsx`, `ResourcesTab.tsx`, `PromptsTab.tsx`, `TasksTab.tsx`, `SamplingTab.tsx`, `ElicitationTab.tsx`, `RootsTab.tsx`, `MetadataTab.tsx`, `AppsTab.tsx`, `AppRenderer.tsx`, `CustomHeaders.tsx`, `DynamicJsonForm.tsx`, `ToolResults.tsx`, `JsonView.tsx`, `ListPane.tsx`: UI execution paths for connection setup, auth, config export, request/notification visibility, schema forms, tool calls, resources/prompts, tasks, MCP Apps, and context views.
- `cli/src/cli.ts`, `cli/src/index.ts`, `cli/src/transport.ts`, `cli/src/client/connection.ts`, `cli/src/client/tools.ts`, `cli/src/client/resources.ts`, `cli/src/client/prompts.ts`, `cli/src/error-handler.ts`, `cli/src/utils/awaitable-log.ts`: web-vs-CLI dispatch, config loading, target/transport detection, direct SDK connection, method dispatch, JSON argument parsing, metadata merging, header parsing, errors, and output flushing.
- `sample-config.json`: documented `mcpServers` shape for stdio server entries.
- `SECURITY.md`: vulnerability reporting process and public-issue avoidance.
- `Dockerfile`: production build/runtime split, package installation, exposed ports, and default `npm start` entrypoint.
- `AGENTS.md`: local contribution guidance, V2 note, build/test commands, and workspace organization.
- `client/src/__tests__/*`, `client/src/lib/__tests__/*`, `client/src/lib/hooks/__tests__/useConnection.test.tsx`, `client/src/utils/__tests__/*`, `client/src/components/__tests__/*`: unit and component tests for proxy fetch, auth, config endpoint, routing, URL validation, proxy auth headers, custom headers, OAuth scope recovery, history/notifications, tool/task UI, resources, apps, metadata, sampling, and elicitation.
- `client/e2e/startup-state.spec.ts`, `client/e2e/cli-arguments.spec.ts`, `client/e2e/transport-type-dropdown.spec.ts`: Playwright checks for startup hash state, CLI/query prefill, and transport selection behavior.
- `cli/__tests__/cli.test.ts`, `tools.test.ts`, `headers.test.ts`, `metadata.test.ts`, `helpers/*`, `README.md`: subprocess CLI tests, built-in stdio and HTTP MCP fixtures, config file tests, env parsing, JSON tool args, header forwarding, metadata forwarding/merging, and test runner notes.

## Excluded Paths

- `.git/`, branch metadata, and clone bookkeeping: generated repository state, not part of Inspector design.
- `.github/`, `.npmrc`, lint/prettier/husky workflow files, and release/version scripts under `scripts/`: operational support. I read package scripts and AGENTS guidance where they affected build/test behavior, but did not review CI internals because the assigned focus was execution paths and coding-agent applicability.
- `package-lock.json`: dependency lock artifact. Dependency names and scripts were reviewed from package manifests instead.
- Build outputs such as `client/dist`, `server/build`, `cli/build`, and temporary local artifacts if present: generated from reviewed source.
- `node_modules` if present: vendored dependencies outside this repo's design ownership.
- Binary/image assets such as `mcp-inspector.png`, `client/public/mcp.svg`, screenshots, icons, and favicon-like assets: useful for branding but not relevant to MCP execution, security, or agent verification.
- Pure styling and design-system primitives such as `client/src/App.css`, `client/src/index.css`, `client/tailwind.config.js`, `postcss.config.js`, `components.json`, and most `client/src/components/ui/*`: UI-only surface. I reviewed higher-level UI components that drive MCP behavior, not low-level button/select/dialog implementations.
- TypeScript/Vite/Jest/Playwright config files (`tsconfig*`, `vite.config.ts`, `jest.config.cjs`, `playwright.config.ts`, eslint config): read only by implication through scripts/tests; not central to Inspector execution path.
- License, code of conduct, and generic contributing text except `SECURITY.md` and `AGENTS.md`: governance material with little bearing on debugging UX or agent workflow design.
- Exhaustive line-by-line review of every component test and every UI tab: sampled broadly across auth, proxy, config, history, tools, resources, apps, sampling, elicitation, and e2e tests. The reviewed sample was enough to identify verification patterns without turning this note into a complete test inventory.
