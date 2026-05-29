# metatool-ai/metamcp

- URL: https://github.com/metatool-ai/metamcp
- Category: mcp
- Stars snapshot: 2,358 (GitHub REST API repository search, captured 2026-05-29 in `research/index.md`; GitHub repo page showed 2.4k at review time)
- Reviewed commit: 250240be7da37e3f21d53eaa66afac5eee775aa5
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strongly in-scope as a real MCP aggregation gateway with namespace routing, public endpoints, tool prefixing, tool-status middleware, API-key/OAuth access, and server pools. Treat it as a pattern library rather than a safe drop-in for autonomous coding agents: the current implementation has serious policy and security gaps around public-resource ownership, process spawning, secret storage, fail-open middleware, unscoped name lookups, and limited verification coverage.

## Why It Matters

MetaMCP is one of the more concrete examples of an MCP gateway rather than a single MCP server. It turns configured upstream MCP servers into namespace-scoped aggregate MCP endpoints, exposes them through SSE, Streamable HTTP, and generated OpenAPI routes, and gives administrators a UI for enabling servers/tools, overriding tool metadata, and assigning endpoint authentication.

For Agentic Coding Lab, the value is in the control-plane shape: local registry tables for servers, namespaces, endpoints, tools, and API keys; runtime pools for expensive MCP connections; request-time routing from prefixed tools to original upstream servers; and a middleware seam for context reduction and policy. The caution is that gateway convenience directly expands blast radius. A coding-agent gateway needs stronger trust, sandbox, audit, and authorization boundaries than this repo currently enforces.

## What It Is

The repo is a Turborepo monorepo with a Next.js frontend, an Express backend, shared tRPC routers, and shared Zod schemas. The backend uses `@modelcontextprotocol/sdk` 1.16.0, PostgreSQL through Drizzle, Better Auth for the admin UI, custom API-key auth for public endpoints, and a first-party OAuth 2.1-style flow for MCP clients.

The product model has four main objects:

- MCP servers: local config for upstream `STDIO`, `SSE`, or `STREAMABLE_HTTP` servers, including command/args/env or URL/headers/bearer token.
- Namespaces: group one or more MCP servers, track active/inactive status, and track per-tool active/inactive plus overrides.
- Endpoints: globally named public routes that map to one namespace and expose `/mcp`, `/sse`, `/api`, and `/api/openapi.json`.
- Tools: discovered upstream tool schemas cached in Postgres and mapped to namespaces for filtering and overrides.

## Research Themes

- Token efficiency: Good practical pattern. The built-in active-tool filter removes inactive tools from `tools/list`, and namespaces let users publish smaller task-specific tool surfaces instead of all configured servers.
- Context control: Strong conceptually. Namespaces, server status, tool status, tool name/title/description overrides, and annotations give an operator a control plane over what the model sees.
- Sub-agent / multi-agent: Not a multi-agent framework. It can serve as shared MCP infrastructure for several agents or clients, and nested MetaMCP is partly considered through prefix parsing and self-reference checks.
- Domain-specific workflow: Strong for MCP operations. The UI and backend support saved server configs, endpoint publication, inspector workflows, OpenAPI exposure, OAuth sessions, and bootstrap from environment variables.
- Error prevention: Mixed. It has DB constraints, per-server error status, crash tracking, startup cooldowns, connection cleanup, and request timeouts, but several policy checks are fail-open and tests are thin.
- Self-learning / memory: None directly. The useful memory-like pieces are cached tool schemas, tool-sync hashing, saved endpoint/namespace config, and in-memory runtime logs.
- Popular skills: MCP gateway routing, namespace design, tool namespacing, tool metadata override, auth-gated endpoint publication, Streamable HTTP/SSE session lifecycle, stdio process management, and OpenAPI generation from MCP tools.

## Core Execution Path

Startup:

1. `apps/backend/src/index.ts` creates the Express app, skips JSON parsing for MCP streaming routes, mounts OAuth discovery/token routes, Better Auth routes, `/metamcp`, `/mcp-proxy`, and `/trpc`.
2. `initializeOnStartup()` optionally bootstraps users, API keys, namespaces, endpoints, and registration controls from environment variables.
3. The backend listens on port `12009`, then `initializeIdleServers()` fetches all namespaces and MCP servers from Postgres, converts server rows to `ServerParameters`, warms `mcpServerPool` for upstream servers, and warms `metaMcpServerPool` for namespaces.

Public MCP endpoint path:

1. A client calls `/metamcp/:endpoint_name/mcp`, `/sse`, or `/api`.
2. `lookupEndpoint` resolves the endpoint row and namespace UUID.
3. `authenticateApiKey` enforces endpoint auth mode: no auth, API key, OAuth token, or API key plus OAuth. `rateLimitMiddleware` may apply in-memory endpoint/client token buckets.
4. SSE and Streamable HTTP handlers create or reuse a client-facing SDK transport and get a namespace-specific MetaMCP server from `metaMcpServerPool`.
5. `createServer(namespaceUuid, sessionId)` creates an MCP `Server` with tools/resources/prompts capabilities and request handlers.

Tool list path:

1. `tools/list` calls `getMcpServers(namespaceUuid)`, which joins namespace mappings to MCP server rows, includes only active mappings unless told otherwise, and always excludes `ERROR` servers.
2. For each server, `mcpServerPool.getSession()` returns an active or prewarmed `ConnectedClient`.
3. The handler checks capabilities, skips exact self-reference, requests all pages of upstream `tools/list`, stores original tool schemas in Postgres when the tool-name hash changes, and returns tools as `{sanitizeName(serverName)}__{tool.name}`.
4. Middleware applies namespace-specific tool overrides and filters inactive tools.

Tool call path:

1. `tools/call` parses the first `__` separator into server prefix and original tool name.
2. Tool override middleware maps an override name back to the original name. Tool filter middleware blocks inactive tools by returning an MCP tool error result.
3. The handler uses a cached `toolToClient` map, or dynamically scans namespace servers and paginated tool lists to find the target session.
4. It calls upstream `tools/call` with configurable timeout, max-total-timeout, and reset-on-progress options, then returns the upstream result.

Direct admin proxy path:

`/mcp-proxy/server/*` is cookie-authenticated and used by the web app/inspector to proxy a single configured server. It builds a transport from request query parameters for stdio, SSE, or Streamable HTTP and forwards raw JSON-RPC messages in both directions through `mcpProxy`.

OpenAPI path:

`/metamcp/:endpoint_name/api/openapi.json` lists tools through the same middleware stack and generates one OpenAPI path per tool. `/api/:tool_name` executes tools through middleware using a deterministic `openapi_${namespaceUuid}` session.

## Architecture

- `apps/backend/src/index.ts`: Express app composition, route mounting, startup bootstrap, idle server initialization.
- `apps/backend/src/routers/public-metamcp/*`: public SSE, Streamable HTTP, and OpenAPI endpoint routers.
- `apps/backend/src/routers/mcp-proxy/*`: authenticated admin/inspector proxy routes for direct server and namespace testing.
- `apps/backend/src/lib/metamcp/metamcp-proxy.ts`: aggregate MCP server implementation and handlers for tools, prompts, resources, and resource templates.
- `apps/backend/src/lib/metamcp/mcp-server-pool.ts`: singleton upstream server pool with idle/active sessions, crash handling, connection cap, invalidation, and expiry cleanup.
- `apps/backend/src/lib/metamcp/metamcp-server-pool.ts`: singleton namespace MetaMCP server pool, including persistent OpenAPI sessions.
- `apps/backend/src/lib/metamcp/metamcp-middleware/*`: functional middleware composition, inactive-tool filtering, and tool override/annotation mapping.
- `apps/backend/src/middleware/*`: endpoint lookup, API-key/OAuth auth, Better Auth cookie guard, and endpoint rate limiting.
- `apps/backend/src/db/schema.ts` and repositories: Postgres tables and CRUD for MCP servers, namespaces, endpoints, tool mappings, OAuth sessions, OAuth clients/tokens, API keys, and config.
- `apps/backend/src/routers/oauth/*`: protected resource metadata, authorization, token, introspection, revocation, userinfo, and dynamic client registration.
- `packages/trpc` and `packages/zod-types`: protected admin API procedure definitions and shared schema contracts.

## Design Choices

The central design is namespace aggregation. MetaMCP does not try to merge upstream servers into one global tool registry. It lets operators compose named subsets and then publish each subset through a stable endpoint.

Tool routing is name-prefix based. Upstream tools are exposed as `ServerName__toolName`, and nested prefixes are handled by splitting on the first separator for runtime calls or the last separator in some refresh paths. This is easy for clients to understand, but it makes server-name uniqueness and parser consistency critical.

Middleware is implemented as pure functional wrappers around `listTools` and `callTool` handlers. The current production middleware is limited to tool overrides and inactive-tool filtering; the richer logging, validation, scanning, and security middleware described in docs is still future-facing.

Lifecycle is optimized for cold-start reduction. Both upstream MCP servers and aggregate namespace servers have idle pools. Updates invalidate idle namespace/OpenAPI sessions, while active client sessions continue until normal cleanup.

The trust model uses user ownership as `user_id` nullability. `null` means public/global. Private API keys cannot access another user's private endpoint, and public endpoints can only be created from public namespaces. However, public-resource mutation semantics are under-specified and currently too permissive in several admin mutations.

The auth model is split: Better Auth cookies protect admin tRPC and `/mcp-proxy`; public endpoints use endpoint-level API key and/or first-party OAuth tokens. OAuth tokens are opaque database records with an `mcp_token_` prefix rather than signed bearer tokens.

## Strengths

- Real gateway behavior, not just a demo: it aggregates tools, prompts, resources, and resource templates from multiple upstream MCP servers.
- Supports all important MCP transport modes for this use case: stdio upstreams, SSE upstreams, Streamable HTTP upstreams, public SSE, public Streamable HTTP, and OpenAPI projection.
- Namespace-level tool control is practical for coding agents: enable/disable servers, enable/disable tools, override tool names/titles/descriptions, and merge custom annotations.
- Tool namespacing with a visible server prefix is simple and prevents most ordinary name collisions in client-facing tool lists.
- Pools address a real MCP operations problem. Prewarmed stdio and aggregate servers reduce cold-start cost, and cleanup hooks close transports and process groups.
- Failure handling covers common operational cases: stdio command cooldown, process crash callbacks, server-level `ERROR` status, connection caps, session lifetime cleanup, and configurable tool-call timeouts.
- Endpoint auth is more than a single bearer check: it supports API keys, query-param auth when explicitly enabled, OAuth challenge metadata, token introspection, PKCE authorization-code flow, and public/private endpoint checks.
- Environment bootstrap is useful for reproducible deployments: users, API keys, namespaces, endpoints, registration controls, ownership, and update behavior can be seeded from env.

## Weaknesses

- Public resource ownership is unsafe. Several admin mutations block other users only when `user_id` is non-null, so any authenticated user can update or delete public MCP servers, namespaces, endpoints, and API keys unless higher-level UI policy prevents it. Comments say public resources require admin behavior, but no admin role is enforced in those branches.
- Stdio execution is not sandboxed. Users who can create MCP servers can run arbitrary commands in the MetaMCP container with configured environment variables. The direct `/mcp-proxy/server` path also accepts command/args/env through query parameters and merges full `process.env` into the spawned environment.
- Secrets are stored directly. API keys, bearer tokens, OAuth access tokens/refresh tokens, OAuth client secrets, custom headers, and MCP env values are stored as plain database fields. Hash helper functions exist for OAuth client secrets, but the registration path stores the secret value.
- Policy middleware often fails open. If parsing, server lookup, DB lookup, or override lookup fails, filter/override code usually includes the tool or allows the call. That is reasonable for availability but wrong for a high-risk coding-agent gateway.
- Tool/server lookups by name are not consistently scoped by user or namespace. `getServerUuidByName`, override lookup, and refresh logic can resolve the wrong server when public and private servers share names, which the database otherwise permits by `(name, user_id)`.
- Active-session invalidation is incomplete. Server and namespace updates refresh idle and OpenAPI sessions, but existing active MCP clients can keep old server config, tool maps, and upstream sessions until their session closes or expires.
- Rate limiting is local and fragile. Limits are in-memory per backend instance, cluster docs acknowledge that each machine counts independently, and the implementation appears gated by background-idle-session state rather than applying uniformly to every endpoint request.
- Observability is basic. There are app/error files, an in-memory 1000-entry MetaMCP log store, session health endpoints, and many debug logs, but no structured request IDs, audit log, metrics endpoint, tracing, per-tool latency histogram, or durable security event stream.
- Test coverage is very thin for the risk level. The only discovered Vitest test file covers `ToolsSyncCache`; routing, auth, namespace policy, process lifecycle, middleware enforcement, OAuth, and OpenAPI behavior are not covered by automated tests in the repo.

## Ideas To Steal

- Use a first-class `MCP server -> namespace -> endpoint` graph. It is a clean mental model for exposing curated tool surfaces to agents.
- Prefix aggregated tools with a stable server identifier and route calls back to the original upstream name. Keep the prefix visible so models and operators can reason about provenance.
- Store namespace-tool mappings separately from upstream tool schemas. That makes per-namespace activation, overrides, and future policy decisions much easier.
- Implement middleware as composable list/call wrappers. It gives a natural place for filtering, metadata transforms, audit, quota, and policy without changing upstream MCP servers.
- Prewarm expensive stdio and aggregate sessions, but pair that with explicit invalidation and observability of idle/active pool state.
- Generate OpenAPI from MCP tool schemas for clients that cannot speak MCP directly, while reusing the same policy middleware used by MCP transports.
- Mark repeatedly crashing servers as unavailable at the control-plane level and exclude them from namespace routing until a human or config update resets them.
- Support env-based bootstrap for repeatable gateway deployments. It is useful for labs, demos, and enterprise-controlled tool catalogs.

## Do Not Copy

- Do not allow arbitrary stdio command execution without container, filesystem, network, secret, and package-install policy.
- Do not treat public/global resources as editable by every authenticated user. Add an explicit admin/owner role and test it.
- Do not store API keys, OAuth secrets, bearer tokens, and refresh tokens in plaintext if the gateway will handle real credentials.
- Do not rely on tool/server names for policy lookup when names are only unique within a user scope. Use UUIDs or namespace-scoped identities end to end.
- Do not make safety middleware fail open for coding-agent tools that can read/write files, call networks, or mutate external systems.
- Do not expose query-parameter API keys or query-driven stdio proxy creation as default patterns.
- Do not copy the rate-limiter shape for production; use a distributed limiter with clear semantics and tests.
- Do not assume docs-described middleware such as validation, scanning, error traces, and observability exists in the runtime path; much of it is roadmap text.

## Fit For Agentic Coding Lab

Fit is high as a concrete gateway case study. MetaMCP shows how to make MCP composition operational: registry rows, namespaces, endpoint publication, transport sessions, tool prefixing, middleware, cold-start pools, endpoint auth, OpenAPI projection, and env bootstrap.

Fit is medium as implementation inspiration. The namespace and middleware model is worth adapting, but the policy layer needs to be made stricter: UUID-based routing, explicit admin roles, deny-by-default middleware, secret hashing/encryption, process sandboxing, active-session revocation, and durable audit.

Fit is low as a direct dependency for an autonomous coding-agent lab without hardening. A coding agent connected to a broad MetaMCP endpoint could inherit every upstream tool's file/network/write privileges, and the current code does not provide enough isolation, provenance, or enforcement to make that safe by default.

## Reviewed Paths

- `/tmp/myagents-research/metatool-ai-metamcp/README.md`, `docs/en/concepts/*.mdx`, `docs/en/quickstart.mdx`, `README-oauth.md`, `recent-updates.md`, and `invalidation.md`: product model, endpoint concepts, middleware status, auth docs, maintenance caveat, and invalidation sequence.
- `/tmp/myagents-research/metatool-ai-metamcp/package.json`, `apps/backend/package.json`, `pnpm-workspace.yaml`, `turbo.json`, `Dockerfile`, `docker-compose.yml`, `docker-compose.test.yml`, and `example.env`: monorepo shape, dependencies, deployment, bootstrap config, and process model.
- `/tmp/myagents-research/metatool-ai-metamcp/apps/backend/src/index.ts`, `auth.ts`, `trpc.ts`, and `routers/trpc.ts`: Express composition, Better Auth setup, tRPC context, and admin API mounting.
- `/tmp/myagents-research/metatool-ai-metamcp/apps/backend/src/routers/public-metamcp/*`: public SSE, Streamable HTTP, OpenAPI schema, and OpenAPI tool execution paths.
- `/tmp/myagents-research/metatool-ai-metamcp/apps/backend/src/routers/mcp-proxy/*` and `apps/backend/src/lib/mcp-proxy.ts`: direct proxy transports, stdio/SSE/Streamable HTTP bridge behavior, JSON-RPC forwarding, and cleanup behavior.
- `/tmp/myagents-research/metatool-ai-metamcp/apps/backend/src/lib/metamcp/*`: aggregate server, upstream client construction, server fetch, runtime pools, lifecycle cleanup, crash/error tracking, logs, tool-name parsing, sync cache, env resolution, and middleware.
- `/tmp/myagents-research/metatool-ai-metamcp/apps/backend/src/middleware/*`: endpoint lookup, API-key/OAuth auth, Better Auth route protection, and rate-limit adapter.
- `/tmp/myagents-research/metatool-ai-metamcp/apps/backend/src/routers/oauth/*`: OAuth protected-resource metadata, dynamic client registration, authorization, token, introspection, revocation, userinfo, and helper utilities.
- `/tmp/myagents-research/metatool-ai-metamcp/apps/backend/src/db/schema.ts`, `apps/backend/src/db/repositories/*.ts`, and `apps/backend/src/db/serializers/*.ts`: database schema, ownership model, namespace mappings, endpoint/API-key/OAuth repositories, and serialization boundaries.
- `/tmp/myagents-research/metatool-ai-metamcp/apps/backend/src/trpc/*.impl.ts` and `packages/trpc/src/routers/frontend/*.ts`: admin mutations/queries, access checks, invalidation behavior, and protected procedure wiring.
- `/tmp/myagents-research/metatool-ai-metamcp/packages/zod-types/src/*.ts`: request/response schemas, transport enums, endpoint options, namespace tool override schemas, OAuth schemas, and server parameter shape.
- `/tmp/myagents-research/metatool-ai-metamcp/apps/backend/src/lib/stdio-transport/*`: custom stdio transport, process spawning, default inherited environment, message framing, process group termination, and crash callback.
- `/tmp/myagents-research/metatool-ai-metamcp/apps/backend/src/lib/metamcp/tools-sync-cache.test.ts` and `apps/backend/vitest.config.ts`: discovered automated test coverage and test configuration.
- Git metadata and GitHub repository page: reviewed commit, recent commit history, branch, remote URL, star/page snapshot, and maintenance context.

## Excluded Paths

- `/tmp/myagents-research/metatool-ai-metamcp/.git/`: VCS internals; commit and recent history were reviewed through git commands.
- `/tmp/myagents-research/metatool-ai-metamcp/pnpm-lock.yaml`, generated Next build outputs if present, and dependency trees: lock/build artifacts; package manifests and source imports were enough for architecture.
- `/tmp/myagents-research/metatool-ai-metamcp/apps/frontend/**`: skimmed for product surface and tRPC usage, excluded from detailed review because the assigned focus was backend MCP gateway routing, lifecycle, auth, policy, observability, and failure modes.
- `/tmp/myagents-research/metatool-ai-metamcp/apps/frontend/components/ui/**`, public assets, fonts, screenshots, logos, and SVG/PNG files: UI and binary assets not central to MCP gateway behavior.
- `/tmp/myagents-research/metatool-ai-metamcp/docs/cn/**`, `README_cn.md`, and locale JSON files: translated/user-facing content; English source docs and backend source were reviewed directly.
- `/tmp/myagents-research/metatool-ai-metamcp/docs/essentials/**`, Mintlify configuration, and documentation images: docs-site scaffolding unrelated to runtime routing and policy.
- `/tmp/myagents-research/metatool-ai-metamcp/apps/backend/drizzle/meta/*.json` and most migration snapshots: generated schema snapshots; current Drizzle schema and selected deployment config captured the model.
- `/tmp/myagents-research/metatool-ai-metamcp/packages/eslint-config/**` and `packages/typescript-config/**`: shared tooling config, not relevant to the gateway design except as monorepo support.
