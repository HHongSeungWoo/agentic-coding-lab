# context-space/context-space

- URL: https://github.com/context-space/context-space
- Category: context-control
- Stars snapshot: 810 (GitHub REST API `stargazers_count`, captured 2026-05-29)
- Reviewed commit: c8423afb91f0e13c4c05cfa505d499f404aa0398
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: conditional
- Verdict: High-signal reference for a hosted integration and tool-context plane, especially provider boundaries, credential handling, invocation logging, and MCP-facing agent ergonomics. It is not yet a strong retrieval, memory, or context-assembly system: query-aware discovery, semantic ranking, token budgeting, evidence provenance, and synthesis are mostly roadmap or schema-level hooks rather than active runtime behavior.

## Why It Matters

Context Space is useful for Agentic Coding Lab because it shows one concrete way to keep agent context outside the model prompt: a service owns provider catalogs, credentials, adapter execution, invocation records, and an MCP facade that agents can call from Cursor, Claude Code, or any MCP client. That boundary is more reusable than the individual integrations because it separates the agent-facing tool contract from provider-specific auth, token refresh, API clients, and stdio MCP server bootstrapping.

The repo is also a useful cautionary example. It markets "context engineering infrastructure", but the reviewed implementation is primarily a tool and integration gateway. It has good service seams for later retrieval and context synthesis, yet the current runtime does not use semantic search, context-budget assembly, memory, source-grounded evidence packs, or query-aware tool recommendation.

## What It Is

Context Space is a Go backend plus a Next.js web app. The backend exposes provider, credential, invocation, identity, and MCP APIs; loads provider manifests; registers concrete adapters and a generic MCP adapter; stores invocation metadata in Postgres; uses Redis for coordination; and uses HashiCorp Vault transit for provider credential encryption. The web app manages integration setup and exposes HTTP/SSE MCP endpoints that translate MCP tool calls into backend invocations.

The reviewed commit is `c8423afb91f0e13c4c05cfa505d499f404aa0398` on `main`, with commit subject `refactor: implement ACL pattern and decouple module dependencies (#59)`. The repository is licensed AGPL-3.0 at review time.

## Research Themes

- Token efficiency: The unified MCP facade can expose a small set of meta-tools (`list_tools`, `call_tool`, connection status, connect flow) instead of registering every provider operation directly in the model context. Per-provider MCP endpoints can further narrow the visible tool set. The limit is that `list_tools` can still return a large catalog, and its `query` and `context` request fields are logged but not used for semantic filtering or budget-aware ranking.
- Context control: Strong fit for external context service boundaries. Providers, operations, credentials, invocations, and MCP surfaces are owned by backend modules instead of being assembled ad hoc inside the agent. Weak fit for code-context retrieval, memory, or prompt-pack construction.
- Sub-agent / multi-agent: Low direct coverage. The system is agent-client agnostic and can serve multiple users or clients, but it does not model sub-agent delegation, shared scratchpads, task routing, or multi-agent state.
- Domain-specific workflow: Strong integration workflow coverage. It includes OAuth/API-key onboarding, provider manifests, operation metadata, Cursor and Claude Code connection helpers, and a catalog UI oriented around tool availability.
- Error prevention: Useful patterns include parameter-schema validation, auth middleware, Vault-backed credential encryption, Redis locks around OAuth refresh, invocation status records, and event emission. Gaps remain around plaintext API-key storage, generic MCP permission enforcement, actual process sandboxing, and narrow tests.
- Self-learning / memory: Minimal current implementation. The data model records invocations and provider metadata, and some schema/config paths anticipate embeddings and discovery, but there is no implemented agent memory loop or feedback-driven retrieval.
- Popular skills: MCP facade design, provider adapter registry, credential injection, OAuth refresh boundary, invocation ledger, tool catalog generation from MCP servers, and one-click agent client configuration.

## Core Execution Path

The backend starts in `backend/cmd/server/main.go`, initializes identity/access, translation, provider core, provider adapter, credential management, and integration modules, then mounts routes under `/v1`. Provider adapter startup loads registered templates and provider manifests, while the integration module wires invocation and MCP handlers to provider, adapter, credential, Redis, and event-bus dependencies through ACL interfaces.

For normal REST execution, `POST /v1/invocations/:provider_identifier/:operation_identifier` authenticates the user, parses a `parameters` object, and calls `InvocationService.InvokeOperation`. The service validates provider state, resolves the adapter, fetches or refreshes credentials when required, creates an invocation record, emits started/success/failure events, calls `ExecuteContract`, persists response or error data, and updates credential last-used metadata.

For backend MCP execution, `/v1/mcp/list_tools` enumerates providers and operations into a provider-keyed operation map, while `/v1/mcp/call_tool/:provider_identifier/:operation_identifier` forwards request JSON as operation parameters through the same invocation service. `ListToolsRequest.Query` and `ListToolsRequest.Context` exist but are not part of the retrieval path at the reviewed commit.

For agent clients, the Next.js app provides `/api/mcp/[id]` for a single integration and `/api/mcp` for a unified server. The single-integration endpoint dynamically registers provider operations as MCP tools. The unified endpoint exposes meta-tools that call backend list and invocation APIs. `web/src/hooks/use-mcp.ts` generates Cursor and Claude Code configuration using those endpoints and an Authorization header.

The generic MCP adapter can launch external stdio MCP servers from registered templates. It builds command, argument, and environment mappings from credentials and parameters, initializes an `mcp-go` client, lists tools, validates required arguments, calls the chosen MCP tool, and returns tool content as JSON.

## Architecture

The strongest architectural idea is the separation between provider core, provider adapter, credential management, invocation, and identity/access modules. That makes provider metadata, auth state, adapter execution, and user identity independently testable in principle, and it gives agents a stable call boundary that does not expose raw provider implementation details.

Provider definitions live mostly under `backend/configs/providers/*/manifest.json`, while executable behavior is in adapter templates and concrete adapter implementations under `backend/internal/provideradapter/infrastructure/adapters`. Concrete OAuth/API adapters cover native services; the MCP adapter covers stdio MCP servers using hardcoded default templates in `backend/internal/provideradapter/infrastructure/adapters/mcp/template.go`.

The data plane is operational rather than retrieval-centric. Provider and operation tables include metadata and embedding-oriented fields, and `backend/cmd/load_providers` can generate embeddings, but runtime invocation and list-tools paths do not use those embeddings to select, rank, compress, or assemble context.

The web architecture wraps the backend with MCP SDK servers instead of requiring agents to call backend REST directly. This is a practical agent workflow fit: setup happens in a UI, while agents receive a standard MCP endpoint with per-user auth.

## Design Choices

The project uses ACL interfaces to decouple module dependencies. The reviewed commit explicitly refactors around that pattern, and the resulting module constructors avoid direct cross-module persistence access for most core flows.

Credential treatment is split by credential type. Provider OAuth and API credentials are encrypted through Vault transit before storage and decrypted through credential factories only when needed for execution. User API keys for accessing Context Space itself are different: they are generated as `cs-` prefixed random values and stored as plaintext values in the application database so they can be validated and later returned to the owner.

The unified MCP design chooses late binding. Rather than registering every operation as a first-class MCP tool on the unified endpoint, it exposes a discovery tool plus a generic `call_tool`. That keeps initial tool exposure small, but moves operation selection and parameter construction into the agent loop.

The generic MCP adapter favors operational convenience over isolation. It launches configured commands such as `npx`, `uvx`, or `uv` with mapped env vars and args. There is no reviewed evidence of a process sandbox, network policy, or per-template runtime allowlist beyond the registered template definitions.

## Strengths

The service boundary is clear and relevant: agents call Context Space, Context Space owns provider auth and adapter execution, and provider-specific complexity stays outside prompts and client configs.

MCP integration is practical. The repo supports both per-provider MCP servers and a unified MCP server, includes generated client configuration paths for Cursor and Claude Code, and can wrap external stdio MCP servers behind the same hosted credential and invocation plane.

Credential handling for provider credentials is substantially better than many small MCP wrappers. Vault transit encryption, OAuth refresh flows, scope metadata, Redis refresh locks, and credential last-used tracking are all present.

Invocation logging gives useful operational provenance. Each call records user, provider, operation, status, timing, parameters, response data, error message, and timestamps, with event emission for started, success, and failure transitions.

The provider catalog is broad. The reviewed tree contains dozens of provider manifests and many MCP default templates, making it a useful corpus for studying integration metadata shape and operation taxonomy.

## Weaknesses

Retrieval and context assembly are underbuilt relative to the project positioning. Embedding fields, discovery config, and query/context request fields exist, but the runtime list-tools path does not semantically rank tools, enforce context budgets, assemble evidence packs, or synthesize task-specific context.

Evidence provenance is shallow. Invocation records show which provider and operation produced a response, but tool results are passed through without source citations, retrieval traces, document chunk lineage, confidence metadata, or response-grounding contracts.

Access control is uneven. Concrete OAuth adapters commonly validate required scopes against credential scopes, but generic MCP manifests often have empty `required_permissions`, and the generic MCP adapter mainly checks that credentials and required parameters exist. API-key providers inherit whatever privileges the external key has.

User API keys are stored and retrieved as plaintext. The values are random and route-limited by middleware to MCP, invocation, and credential paths, but this is still weaker than storing a hash with one-time display and revocation metadata.

The generic MCP adapter caches discovered tool schemas indefinitely after first initialization. It does not react to MCP `listChanged` notifications or template/tool schema drift during a process lifetime.

Testing is thin for the agent-facing behavior. The backend has a few focused Go tests for credentials, invocation service, MCP config building, and cron refresh. The web tree has test dependencies but no reviewed web test files, and there is no end-to-end coverage for MCP facade behavior, stdio MCP process execution, query-aware list-tools behavior, or permission enforcement for generic MCP templates.

## Ideas To Steal

Use a hosted context-service boundary for external tools: agent clients should receive a stable MCP surface while a backend owns provider auth, refresh, operation metadata, invocation state, and adapter-specific execution.

Keep provider metadata, credentials, and invocations as separate bounded contexts. That separation makes it easier to reason about ownership, audit, and policy than a single generic "tool call" table.

Offer both narrow and unified MCP endpoints. A single-provider endpoint reduces visible tool surface when the agent already knows the integration; a unified endpoint is better for exploration and dynamic workflows.

Treat MCP servers as adapter targets, not only as first-class clients. The generic stdio adapter pattern lets a platform reuse community MCP servers while still centralizing credential injection and invocation records.

Record every invocation with status, duration, inputs, outputs, and error data. Even without full evidence provenance, this is a useful minimum audit trail for debugging agent-tool interactions.

## Do Not Copy

Do not describe a tool gateway as retrieval or memory infrastructure unless runtime behavior actually ranks, budgets, assembles, and grounds context.

Do not store reusable user API keys as plaintext if the platform can support hashed validation and one-time display.

Do not rely on generic MCP command templates without a sandbox or runtime policy if the platform will run untrusted or user-provided servers.

Do not leave discovery request fields unused. If an API accepts `query` and `context`, agents will assume those fields affect results.

Do not treat provider/operation provenance as enough for source-grounded answers. Agentic coding workflows need file, chunk, commit, command, or document lineage when the context affects edits or decisions.

## Fit For Agentic Coding Lab

This repo fits the index as `conditional` for `context-control`. It is valuable as an integration-plane and MCP-boundary reference, not as a full context retrieval or memory system. The best lessons are service ownership, auth boundaries, provider catalog shape, unified-versus-specific MCP endpoint tradeoffs, and invocation audit records.

For Agentic Coding Lab, the most reusable pattern is to put context-producing tools behind a service that can enforce identity, credentials, policy, and audit before data enters the agent loop. The least reusable part is the current context selection story: without semantic retrieval, provenance-rich assembly, or token-budget control, the agent still has to decide what matters from a broad tool catalog.

## Reviewed Paths

- `README.md`
- `LICENSE`
- `backend/go.mod`
- `backend/cmd/server/main.go`
- `backend/cmd/load_providers/main.go`
- `backend/cmd/mcp-tool/main.go`
- `backend/configs/providers/*/manifest.json`
- `backend/internal/identityaccess/**`
- `backend/internal/credentialmanagement/**`
- `backend/internal/provideradapter/**`
- `backend/internal/providercore/**`
- `backend/internal/integration/**`
- `backend/internal/shared/**`
- `web/package.json`
- `web/src/app/api/mcp/**`
- `web/src/lib/mcp/**`
- `web/src/hooks/use-mcp.ts`
- `web/src/services/**`
- `docs/**`
- `examples/**`
- `Makefile`
- `docker-compose.yml`

## Excluded Paths

- `.git/**`
- `node_modules/**` and other dependency caches, if present
- Generated or static image assets under `resources/**`, `web/public/**`, and provider logo files
- Lockfile internals beyond dependency and script identification
- Most UI-only pages and components outside MCP setup, provider setup, and service-call paths
- Full line-by-line review of every provider manifest and i18n file; the review sampled representative OAuth, API-key, and MCP providers and summarized the catalog shape
- Deployment templates and environment examples except where they affected auth, credential, or service-boundary interpretation
