# PrefectHQ/fastmcp

- URL: https://github.com/PrefectHQ/fastmcp
- Category: mcp
- Stars snapshot: 25,113 (GitHub REST API, captured 2026-05-11)
- Reviewed commit: 8209093871af25bc3ceb50bfbcec317632218afd
- Reviewed at: 2026-05-11
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong MCP framework reference. Steal the provider/transform/component split, decorator-to-component registration model, in-memory client test harness, session-scoped visibility, and search-over-tool-catalog pattern. Do not copy the full OAuth/apps/tasks/proxy surface wholesale unless the lab needs that operational complexity.

## Why It Matters

FastMCP is a mature Python framework for building MCP servers and clients. It is directly relevant to an agentic coding lab because it treats tools, resources, prompts, auth, transports, testing, and server composition as first-class framework concerns instead of examples around the raw MCP SDK.

The most useful lesson is architectural: a server should not be a bag of callbacks. FastMCP turns callbacks into typed components, stores them behind providers, applies transforms over the component catalog, runs auth and middleware at list and execution time, and exposes an in-process client for tests. That combination maps well to coding-agent infrastructure where the useful challenge is not only "define a tool" but also "show the right tools to the right session, prove the tool was authorized, and keep large catalogs out of the model context."

## What It Is

FastMCP is a Python MCP server/client framework. On the server side, authors create a `FastMCP` instance and register tools, resources, resource templates, and prompts with decorators or provider objects. On the client side, `Client` infers the transport from an in-process server, config object, script, or HTTP URL and provides typed methods for listing and invoking MCP capabilities.

The framework includes local component registration, mounted/namespaced servers, proxy providers for upstream MCP servers, OpenAPI/FastAPI generation, auth providers, component-level authorization, middleware, session state, runtime visibility controls, tool search transforms, and utilities for exposing agent skills as MCP resources.

## Research Themes

- Token efficiency: The `RegexSearchTransform` and `BM25SearchTransform` replace large `list_tools()` outputs with a small pair of synthetic tools, usually `search_tools` and `call_tool`. Search can return compact markdown or JSON definitions, has result limits, and supports pinned always-visible tools. Resource skill providers also keep supporting files out of `list_resources()` by default, exposing a manifest plus a resource template instead of every file.
- Context control: `Context` is injected into tools/resources/prompts but removed from public schemas. It exposes request metadata, progress, logging, sampling, elicitation, session state, and per-session visibility methods such as `enable_components`, `disable_components`, and `reset_visibility`. Visibility is represented as transforms, which lets global, provider-level, and session-level rules compose.
- Sub-agent / multi-agent: FastMCP is not a multi-agent planner. It is useful as a substrate for agents and sub-agents because it can mount or proxy many servers, namespace capabilities, expose skills as resources, and support background task metadata. The sandboxed-agent guidance explicitly recommends remote HTTP servers with short-lived scoped tokens and server-side credentials.
- Domain-specific workflow: The decorator layer lowers friction for domain teams while the provider layer supports generated or dynamic capability sources such as OpenAPI, FastAPI, filesystem examples, proxy servers, and skills directories. This is a good pattern for domain packages that want to publish a curated MCP surface without every user writing protocol plumbing.
- Error prevention: Pydantic validation, schema extraction, docstring parsing, dependency injection filtering, duplicate registration policies, version mixing checks, error masking, timeouts, redirect validation, SSRF-safe URL fetching, and broad tests all reduce common MCP integration mistakes.
- Self-learning / memory: FastMCP does not implement long-term learning. It has session state with a default one-day TTL and pluggable state stores, which is useful for per-session activation or workflow state but should not be treated as durable memory.
- Popular skills: The Skills Provider exposes Claude, Cursor, VS Code/Copilot, Codex, Gemini, Goose, Copilot, and OpenCode skill directories as MCP resources. It turns local `SKILL.md` folders into `skill://` resources with manifests, content hashes, and optional supporting-file templates.

## Core Execution Path

1. A server author creates `FastMCP("Name")`, optionally with auth, middleware, providers, transforms, state store, error masking, pagination size, and transport settings.
2. `@mcp.tool`, `@mcp.resource`, and `@mcp.prompt` delegate to the server's `LocalProvider`. Functions are parsed into `FunctionTool`, `FunctionResource` or `FunctionResourceTemplate`, and `FunctionPrompt` components with Pydantic schemas and metadata.
3. Additional providers can be added directly, mounted from another `FastMCP` server, proxied from a remote MCP server, generated from OpenAPI/FastAPI, or loaded from skills/filesystem sources.
4. Client list operations call `FastMCP.list_tools`, `list_resources`, `list_resource_templates`, and `list_prompts`. The aggregate provider gathers components, transforms mark or rewrite them, session visibility transforms are applied, disabled components are filtered, app-only backend tools are hidden from model listings, and auth checks remove unauthorized components.
5. MCP protocol handlers in `MCPOperationsMixin` translate low-level MCP list/call/read/get requests into framework calls. Version and task metadata are read from request `_meta`.
6. `call_tool`, `read_resource`, and `render_prompt` run middleware, resolve the component through transforms and auth-aware lookup, and execute the component. Context dependencies are injected internally and cannot be overridden through user arguments.
7. Function components validate user arguments, run async functions directly or sync functions in a worker thread by default, enforce configured timeouts, convert outputs into MCP content/structured content, and mask internal errors when configured.
8. Tests and local clients use `Client(mcp)` to run through the same MCP-facing interface without a network server.

## Architecture

FastMCP's central type is `FastMCP`, which inherits provider behavior and mixes in lifecycle, MCP operation handlers, and transport helpers. The constructor builds a local provider first, adds external providers, attaches transforms, creates an underlying MCP SDK `Server`, stores auth/middleware/state settings, and installs default middleware such as reference dereferencing.

Components are explicit objects. `Tool`, `Resource`, `ResourceTemplate`, and `Prompt` own their schema, metadata, enabled state, version, tags, annotations, and execution behavior. Function-backed subclasses parse Python callables, type hints, docstrings, and output schemas into MCP-facing definitions. The public decorator API returns the original function in normal use, while storing a component in the provider.

Providers are the catalog layer. `Provider` defines list/get operations and a transform chain. `LocalProvider` stores components in a keyed dictionary and enforces duplicate/version policies. `AggregateProvider` combines providers concurrently and returns components from the aggregate view. `FastMCPProvider` wraps mounted child servers so child middleware and lifespan still run. `ProxyProvider` forwards through a `Client` to remote MCP servers. Skills providers expose skill directories as resources.

Transforms are catalog rewrites. Namespace transforms rename tools/prompts and rewrite resource URIs. Visibility transforms mark components as enabled or disabled without filtering inline. Tool transforms can rename and mutate tool schemas. Search transforms replace the visible tool list with synthetic discovery/execution tools while leaving permitted direct calls functional.

Context is a request/session control plane. `Context` is backed by context variables and gives components access to the active server, client capabilities, request metadata, session ID, progress, logs, sampling, elicitation, resources, prompts, state, and visibility changes. Session state keys are prefixed by session ID and default to a 24-hour TTL with `MemoryStore`, while request-scoped state supports non-serializable objects.

Auth is HTTP-centered. `AuthProvider`, `TokenVerifier`, `RemoteAuthProvider`, `OAuthProvider`, `OAuthProxy`, and `MultiAuth` integrate with MCP SDK bearer auth and Starlette middleware. Component-level auth checks can hide components from list calls and return not-found behavior on direct lookup. `AuthMiddleware` can also enforce checks centrally. STDIO deliberately skips auth, assuming local process trust.

The client side has a comparable layer split. `Client` infers transports, manages a reentrant session task, supports roots/sampling/elicitation/logging handlers, and exposes mixins for tools/resources/prompts/tasks. HTTP clients accept bearer or OAuth auth and avoid forwarding incoming headers by default, which is important when building gateways.

## Design Choices

- The framework separates "where components come from" from "how components are exposed" by using providers plus transforms. This is the core reusable architecture.
- Visibility is a mark-and-filter system. Transforms set visibility metadata; server methods filter after provider and session transforms have run. Later transforms override earlier ones.
- Auth filtering happens both when listing and when resolving a component for execution. Unauthorized component lookups intentionally look like missing components.
- Direct function dependencies such as `Context` and `Depends` are removed from public schemas and resolved internally. User-supplied arguments are filtered so callers cannot override injected dependencies.
- Tool search is discovery control, not hard access control. Original tools remain callable by name if the caller knows them and normal visibility/auth allows the call.
- Function-backed sync tools run in a worker thread by default. Authors can opt out for thread-affine libraries with `run_in_thread=False`, but FastMCP rejects incompatible timeout settings for inline sync execution.
- Resource templates are selected automatically when a resource URI or function signature contains parameters. URI template matching validates parameter consistency and does limited string-to-type coercion.
- Version handling is explicit. Local registration rejects mixing versioned and unversioned variants of the same logical component, and lookup can fall back to the highest enabled/authorized version.
- The in-memory `Client(mcp)` is treated as a first-class test path, not a separate test-only API.

## Strengths

- Clean component/provider/transform model. It is easier to reason about and test than direct protocol decorators scattered across a codebase.
- Excellent registration ergonomics. Tool/resource/prompt authors can use simple decorators, while advanced users can add providers and transforms.
- Strong context-control story for agents. Session visibility, namespacing, mounted servers, and tool search directly address context bloat and tool activation.
- Security is not an afterthought. Auth providers, component-level checks, middleware enforcement, SSRF-safe URL fetching, redirect validation, header stripping, and masked errors are all present.
- Testing model is practical. The same `Client` can test in-process servers and remote transports, and examples show fixtures for tools, resources, templates, and prompts.
- Composition works at useful boundaries. Mounted servers preserve child middleware/lifespan, and proxy providers can adapt upstream MCP servers without reimplementing their tools.
- Skills-as-resources is a useful bridge across coding agents. Manifests and SHA256 hashes provide inspectable sync surfaces without listing every supporting file by default.

## Weaknesses

- The surface area is large. Apps, tasks, OAuth flows, proxying, OpenAPI generation, skills, transports, and multiple auth modes raise maintenance and onboarding cost.
- Dynamic provider and visibility behavior can make catalogs hard to audit unless the host logs transforms, session rules, and final component lists.
- Search transforms reduce listing tokens but do not remove the need for real authorization, because original tools remain directly callable when allowed.
- STDIO auth bypass is sensible for local launches but dangerous if users mentally transfer HTTP assumptions to local process execution.
- The default in-memory state store is not suitable for multi-process or distributed deployments without replacement.
- Provider aggregation and version selection are more complex than a simple priority list. A smaller lab framework should document conflict behavior clearly before adopting this pattern.
- The framework includes UI/app metadata in core paths. That may be valuable for FastMCP Apps, but a coding-agent lab can probably avoid that coupling.

## Ideas To Steal

- Use explicit component objects for tools, resources, prompts, and templates; do not leave behavior as raw functions after registration.
- Put registration behind a `LocalProvider`, then make every other source implement the same provider interface.
- Implement transforms as catalog-level rewrites that can rename, hide, search, or namespace components without mutating the underlying providers.
- Add per-session visibility controls for activation workflows. This is a good way to keep rarely used tool groups out of the model context until requested.
- Build a tool-search transform for large catalogs. Return a tiny always-visible surface plus searchable full definitions.
- Keep injected context/dependencies out of public JSON schemas, and filter caller arguments before dependency resolution.
- Make an in-process MCP client the default test harness. It encourages protocol-level tests without making every test start a server.
- Expose agent skills as resources with a main instruction file, manifest, hashes, and supporting-file templates.
- Treat auth hiding as part of component lookup, not only route middleware. Unauthorized tools should not appear in listings or direct lookups.
- Provide sandboxed-agent deployment guidance that keeps privileged credentials server-side and exposes scoped capabilities to agents.

## Do Not Copy

- Do not copy the complete OAuth/provider matrix before there is a concrete deployment need. A narrow bearer/JWT verifier plus component checks is a more reasonable starting point.
- Do not copy UI/app/Prefab coupling into a coding-agent runtime unless the product actually has MCP Apps as a core feature.
- Do not rely on search transforms as security controls. They are discovery controls and must be paired with visibility/auth enforcement.
- Do not use dynamic filesystem or skill providers without a clear trust boundary, path traversal checks, size limits, and audit logs.
- Do not use in-memory session state for production multi-worker deployments.
- Do not hide conflict-resolution rules inside provider aggregation. Make duplicate names, version precedence, and namespace behavior visible.

## Fit For Agentic Coding Lab

High fit. FastMCP is one of the better references for how to turn MCP into an extensible agent runtime surface. The lab should not try to become FastMCP, but it should borrow the smaller set of architectural primitives: provider-backed component registration, transforms for context control, in-process client verification, component-level auth, and skills/resources for sharing agent instructions.

For coding agents specifically, the most valuable pattern is "capability catalog as a controllable data structure." FastMCP makes it possible to dynamically expose fewer tools, mount domain servers, search capabilities on demand, and keep session-specific activation outside the global server definition. That is directly applicable to reducing tool confusion and context cost in large coding workspaces.

## Reviewed Paths

- `README.md`: project positioning, minimal server example, server/client/app pillars, documentation pointers.
- `pyproject.toml`: package scope, Python version, dependencies, optional extras, test/lint/typecheck configuration.
- `docs/servers/server.mdx`: `FastMCP` constructor, server behavior, auth/middleware/provider/transform options, transports.
- `docs/servers/tools.mdx`: tool registration, schemas, docstrings, sync/async execution, threadpool behavior, timeouts.
- `docs/servers/resources.mdx`: read-only resources, templates, lazy loading, context access, result conversion.
- `docs/servers/prompts.mdx`: prompt decorators, arguments, string conversion, message rendering.
- `docs/servers/context.mdx`: context API, session state, request metadata, sampling, elicitation, component visibility.
- `docs/servers/visibility.mdx`: server/provider/session visibility semantics, allowlist/blocklist behavior, ordering.
- `docs/servers/auth/authentication.mdx` and `docs/servers/authorization.mdx`: HTTP auth model, provider types, component auth checks, scope/tag restrictions, STDIO exception.
- `docs/servers/testing.mdx`: in-memory client tests for tools/resources/templates/prompts.
- `docs/servers/providers/overview.mdx` and `docs/servers/providers/skills.mdx`: provider abstraction, composition, proxying, skills-as-resources.
- `docs/servers/transforms/tool-search.mdx`: search transform behavior, regex/BM25 tradeoffs, direct-call caveat, auth/visibility interaction.
- `docs/deployment/sandboxed-agents.mdx`: recommended boundary for sandboxed coding agents and short-lived scoped tokens.
- `src/fastmcp/server/server.py`: core `FastMCP` class, decorator delegation, list/get/call/read/render behavior, auth and visibility filtering, mounting, proxy/openapi/fastapi helpers.
- `src/fastmcp/server/mixins/mcp_operations.py` and `src/fastmcp/server/mixins/transport.py`: low-level MCP handler registration, version/task metadata flow, stdio/http/sse transport setup.
- `src/fastmcp/server/http.py`: Starlette app creation, request context middleware, auth route integration, streamable HTTP session manager behavior.
- `src/fastmcp/server/providers/base.py`, `aggregate.py`, `fastmcp_provider.py`, `proxy.py`: provider contract, aggregation, mounted server delegation, remote proxy forwarding.
- `src/fastmcp/server/providers/local_provider/local_provider.py` and `decorators/*.py`: local component registry, duplicate policies, version mixing checks, tool/resource/prompt decorator implementations.
- `src/fastmcp/server/providers/skills/*.py`: skill directory scanning, `skill://` resources, manifests, hashes, supporting-file resource templates, path traversal checks, vendor defaults.
- `src/fastmcp/tools/*.py`, `src/fastmcp/resources/*.py`, and `src/fastmcp/prompts/*.py`: component base classes, function parsing, Pydantic validation, result conversion, URI template matching, prompt argument conversion.
- `src/fastmcp/server/context.py`, `dependencies.py`, and `transforms/visibility.py`: context variables, session/request state, dependency injection, header/token helpers, session visibility transforms.
- `src/fastmcp/server/transforms/search/base.py`, `regex.py`, `bm25.py`, `namespace.py`, and `tool_transform.py`: catalog search, namespacing, and tool mutation patterns.
- `src/fastmcp/server/middleware/middleware.py` and `middleware/authorization.py`: middleware dispatch model and explicit authorization enforcement.
- `src/fastmcp/server/auth/*.py` and `auth/providers/*.py`: auth provider base, token verification, OAuth/proxy flows, JWT/introspection verification, redirect validation, SSRF-safe fetching.
- `src/fastmcp/client/client.py`, `client/transports/*.py`, and `client/mixins/*.py`: transport inference, HTTP auth/header behavior, reentrant session management, tool/resource/prompt client methods.
- `examples/simple_echo.py`, `examples/filesystem-provider/server.py`, `examples/auth/github_oauth/server.py`, `examples/testing_demo/tests/test_server.py`, and `examples/namespace_activation/server.py`: minimal server, dynamic provider, OAuth example, test style, and session activation pattern.
- `tests/server/test_server.py`, `tests/server/test_context.py`, `tests/server/test_server_safety.py`, `tests/server/auth/test_authorization.py`, `tests/server/providers/test_skills_provider.py`, `tests/server/providers/test_skills_vendor_providers.py`, and `tests/utilities/test_skills.py`: behavioral coverage for registration, mounted resources, context state, auth checks, self-mount safety, skills resources, and manifests.

## Excluded Paths

- `docs/assets/**`, image/video/logo files, and other binary brand assets: generated or visual assets, not relevant to MCP framework architecture.
- `docs/apps/**`, `src/fastmcp/apps/**`, `examples/apps/**`, and UI-only app/Prefab docs: important for FastMCP Apps, but outside this review's focus on tool/resource/prompt registration and coding-agent MCP runtime design. Core app metadata encountered in server/tool code was still noted.
- `docs/v2/**`, `docs/changelog.mdx`, and `docs/updates.mdx`: historical and migration material, excluded to keep the review on current architecture at the recorded commit.
- `uv.lock` and example lockfiles: generated dependency resolution artifacts.
- Generated API reference pages under `docs/python-sdk/**`: mostly generated from source; used only indirectly when source docs were insufficient.
- JSON schema/config reference files such as `docs/assets/schemas/**` and `src/fastmcp/utilities/mcp_server_config/v1/schema.json`: generated/config support, not core framework flow.
- `.github/**`, release automation, and repository maintenance scripts such as `scripts/auto_close_*`: project operations, not runtime architecture.
- Provider-specific OAuth examples beyond the reviewed GitHub example: repetitive recipes after reviewing auth base classes, provider implementations, and one concrete HTTP OAuth server.
- Domain demos such as ATProto, smart-home, SQLite/search/task examples not listed above: useful examples but not necessary after reading the framework paths that implement the underlying patterns.
- UI-specific consent tests and app frontend tests: relevant to FastMCP Apps, not to the MCP server/client framework review requested here.
