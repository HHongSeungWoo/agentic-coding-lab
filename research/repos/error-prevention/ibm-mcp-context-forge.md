# IBM/mcp-context-forge

- URL: https://github.com/IBM/mcp-context-forge
- Category: error-prevention
- Stars snapshot: 3,683 (captured in research/index.md on 2026-05-11)
- Reviewed commit: 49c7ffc42f141bca23138f4ed6a31e5901d0ec5d
- Reviewed at: 2026-05-19
- Status: Deep reviewed
- Scope fit: Strong fit for error prevention in agent tool-use systems. It is also a tool-use candidate because it is an MCP/A2A/REST/gRPC gateway, but this note only evaluates the error-prevention angle.
- Verdict: High-value pattern source. The useful pieces are the layered authorization, scoped visibility model, policy-hook boundaries, fail-closed federation controls, cancellation/timeouts, and Rust fast-path delegation back to a Python policy authority. Do not copy the whole product shape.

## Why It Matters

ContextForge treats tool execution as a control-plane problem rather than a thin adapter problem. The gateway sits between agents and upstream tools, then centralizes discovery, authentication, RBAC, token scoping, team/private/public visibility, plugin policy hooks, schema validation, cancellation, retries, metrics, and federation routing.

For Agentic Coding Lab, the most transferable idea is a narrow "tool authority" layer that every agent tool call must pass through. That layer can prevent common agent failures before execution: wrong tool, wrong team, stale session, unsafe URI, missing permission, exceeded budget, untrusted upstream, malformed output, unbounded call, or policy violation.

## What It Is

The repository is an IBM gateway for Model Context Protocol servers and related agent endpoints. The Python FastAPI service is the primary control plane. It exposes REST management APIs, MCP JSON-RPC transports, A2A routes, admin routes, OAuth metadata, and internal endpoints for optional Rust runtimes. It can register local tools, federated MCP gateways, REST tools, A2A agents, and gRPC-derived tools.

The project also includes optional Rust runtimes for MCP and A2A acceleration. Those runtimes are intentionally not independent policy engines: public Rust ingress authenticates by calling Python internal endpoints, direct execution eligibility is resolved by Python, and unsupported policy conditions fall back to Python execution.

The repo is explicitly beta/as-is, with security documentation warning that Admin UI/API surfaces are development/local oriented and that REST APIs should sit inside trusted environments rather than directly face untrusted end users.

## Research Themes

- Token efficiency: Not the main theme. ContextForge can reduce redundant discovery by caching tools/resources/prompts and aggregating upstream capabilities, but it does not focus on prompt-token compression.
- Context control: Strong. Team/private/public visibility, token team semantics, session ownership, per-server MCP endpoints, and discovery filters keep agents from seeing or calling resources outside their scope.
- Sub-agent / multi-agent: Moderate. A2A support and UAID cross-gateway routing provide multi-agent federation with hop limits and domain allowlists, but the repository is a gateway rather than a planner or sub-agent orchestrator.
- Domain-specific workflow: Moderate. It is domain-specific to tool gateways, MCP, A2A, OAuth, and enterprise deployment controls.
- Error prevention: Very strong. The execution path combines validation, RBAC, policy plugins, rate limits, cancellation, bounded retries, schema checks, SSRF defenses, content security, sanitized errors, and fail-closed federation.
- Self-learning / memory: Low. There is metrics, audit, cache, and session state, but no self-learning memory loop.
- Popular skills: Good source for skills around secure tool invocation, gateway design, federation safety, session isolation, policy-hook contracts, and fast-path fallback design.

## Core Execution Path

The main runtime starts at `mcpgateway/cli.py`, which launches `mcpgateway.main:app`. FastAPI lifespan initialization waits for the database, runs migrations, validates security configuration, validates UAID settings, initializes Redis/SIEM/session affinity/cancellation/metrics/SSO, and initializes the plugin manager. Plugin YAML failures can stop startup when plugins are enabled.

Incoming HTTP traffic passes through stacked middleware: correlation IDs, forwarded-host/proxy handling, security headers, rate limiting, validation, MCP protocol version validation, token scoping, auth context, password-change and CSRF checks, HTTP auth plugin hooks, request logging, admin/docs auth, observability, and client-disconnect cancellation. Security configuration can fail startup for weak secrets when strong-secret enforcement is enabled. Insecure defaults such as JWT and encryption secrets are documented as production blockers.

MCP JSON-RPC calls go through `_handle_rpc_authenticated` in `mcpgateway/main.py`. It parses JSON with structured errors, validates the request, enforces server scope, resolves session affinity, checks session owner/admin status, checks per-method permission, and dispatches to method handlers. `tools/call` then registers cancellation if enabled, invokes `ToolService.invoke_tool`, maps client cancellation to JSON-RPC `-32800`, and unregisters the cancellation task.

`ToolService.invoke_tool` is the central tool execution path. It resolves the tool from cache/DB, filters by visibility/access/priority, hides inaccessible tools as not found, checks `server_id` constraints, closes DB state before slow upstream I/O, computes timeout, applies pre-invoke hooks, executes REST/MCP/A2A/gRPC branches, runs post-invoke hooks, records metrics, and converts failures to typed tool errors. REST calls use mapped path/query/header controls, reject missing required path parameters and invalid header/query shapes, preserve signed URL query only when no mapping overrides it, and validate REST success output against output schema. MCP calls handle OAuth, allowed passthrough headers, custom CA/mTLS options, session affinity, and timeout via `anyio.fail_after`. A2A calls run pre/post hooks and timeouts but currently do not have gateway-side output-schema enforcement.

Federated MCP gateways are managed by `GatewayService`. Registration normalizes local URLs, checks OAuth metadata, detects duplicates by URL/credentials/visibility, connects via SSE or StreamableHTTP without redirects, lists upstream tools/resources/templates/prompts, validates each discovered tool, skips invalid ones where possible, and fails the gateway when all discovered tools are invalid. Health checks avoid holding DB sessions during network calls and use concurrency limits, timeouts, failure thresholds, and throttled refresh.

The optional Rust MCP runtime receives public MCP traffic in edge/full modes but calls Python internal endpoints for authentication, authorization, direct-call planning, execution fallback, and metrics. It strips client-supplied internal headers before inserting trusted context headers. Direct Rust execution only happens when Python returns an eligible plan; hooks, tracing, unsupported transports, custom CA, direct proxy, auth-code OAuth, JSONPath filters, ambiguity, or post-hook needs push the call back to Python.

The A2A path similarly enforces local-first lookup, access checks, UAID parsing, domain allowlists, hop counts, JWT-shaped bearer forwarding only under explicit settings, and sanitized remote errors. Rust A2A also calls Python for auth/authz and agent resolution, stamps hop counts, queues bounded work, applies body limits, and uses circuit breakers.

## Architecture

The architecture is a policy-rich gateway:

- Python FastAPI control plane: REST management, MCP JSON-RPC, A2A routes, auth, RBAC, discovery, plugin orchestration, metrics, and internal trusted endpoints.
- Persistence and cache layer: SQLAlchemy models for tools/gateways/servers/prompts/resources/permissions, Redis-backed federation/session/cancellation/rate-limit features where configured, and in-memory fallbacks where acceptable.
- Middleware layer: request validation, token scoping, HTTP auth plugin integration, protocol version checks, rate limiting, security headers, forwarded host handling, admin/docs auth, observability, and disconnect cancellation.
- Service layer: `ToolService`, `GatewayService`, `A2AService`, `PermissionService`, content security, OAuth managers, session affinity, cancellation, and metrics buffers.
- Plugin layer: CPEX hooks for tool/resource/prompt/agent/HTTP phases with explicit writable-field policies, modes such as enforce/permissive/disabled, priority, conditions, and violation-to-status mapping.
- Optional Rust runtimes: MCP and A2A edge/full/shadow paths that accelerate transport/execution while delegating authority and fallback decisions to Python.

## Design Choices

The strongest design choice is separating "can this request proceed?" from "how do we execute it?" Authentication, token scoping, team membership, RBAC, resource ownership, method permission, server scope, plugin policy, and output validation are all checked before or around upstream execution.

Token team semantics are explicit. `teams=null` with admin can mean admin-wide visibility, `teams=[]` means public-only, and a list means team-scoped access. Non-admin missing teams resolve to public-only rather than implicit global access. `PermissionService` denies on errors, public-only tokens suppress admin bypass, and cache keys encode token team semantics so a broad token and narrow token do not share authorization outcomes.

Visibility is applied consistently across servers, tools, resources, prompts, and gateways. Public resources are visible broadly, team resources require matching team, private resources require ownership, unknown visibility denies, and inaccessible tools are hidden as not found to avoid existence leaks.

Plugin hooks have power but also boundaries. The policy layer declares which fields each hook can mutate. HTTP auth hooks cannot override existing auth-sensitive headers unless an explicit override setting is enabled. Plugin violations are mapped to structured HTTP/JSON-RPC errors with validated response headers. This is a good pattern for adding policy extension without letting plugins silently rewrite every security boundary.

Federation controls are defensive. UAID cross-gateway routing validates domains, rejects malformed endpoint components, stamps and checks hop counts, and fails closed at runtime when the allowlist is empty in the Python A2A service. OAuth metadata endpoints are scoped to public OAuth-enabled servers and DB failures produce service errors rather than open metadata.

Failure handling is first-class. Tool timeouts become `ToolTimeoutError`, cancellation re-raises `asyncio.CancelledError` rather than wrapping it as a normal tool failure, disconnect middleware cancels in-flight handlers, JSON-RPC cancellation returns `-32800`, and post-invoke hooks can observe timeout/failure state for circuit breakers. Public errors are sanitized while internal logs keep operator context.

The Rust runtime design is useful: fast paths are eligible only after the Python authority returns a plan, and fallback reasons are explicit. That avoids duplicating all policy logic into Rust while still allowing acceleration for simple, safe cases.

## Strengths

Layered authorization is unusually complete for an agent tool gateway. Requests can be rejected at transport, token, team, resource ownership, method permission, plugin policy, and upstream validation layers.

The project documents and tests several real error-prevention invariants: public-only tokens cannot reuse broader sessions, same-team peers cannot hijack another user's MCP session, sessionless streaming GETs are rejected, oversized Rust runtime bodies return 413, plugin auth can block revoked API keys, and output-schema validation skips `isError=true` responses.

The code tends to fail closed on high-impact access checks. Permission service errors deny, unknown visibility denies, missing team context narrows access to public-only, UAID runtime allowlist failure denies in Python, and OAuth well-known DB errors produce 503.

The tool execution path is careful about operational failure modes: timeouts, bounded retries, circuit-breaker hook state, no redirects on outbound clients, custom TLS isolation, cancellation propagation, DB sessions closed before slow network calls, and sanitized public exceptions.

Security controls are not only docs. `ContentSecurityService` enforces size, MIME, dangerous-pattern, prompt-template, and log-sanitization rules. `SecurityValidator` and validation middleware cover path traversal, shell/SQL injection patterns, control characters, MIME validation, and output sanitization.

The repo has broad tests across unit, integration, fuzz, live gateway, MCP compliance, Rust runtime, and plugin behavior. Representative tests cover token scoping, visibility branches, HTTP auth plugins, security validation, REST output-schema handling, timeout/post-hook behavior, Rust session isolation, direct method authorization, and body limits.

## Weaknesses

The system is large and configuration-heavy. The number of flags around auth, admin surfaces, plugins, passthrough headers, UAID, Rust modes, proxy trust, validation strictness, and feature gates makes deployment audit harder than the core patterns suggest.

The security documentation says the project is beta/as-is with latest-main fixes only and no backports. It also warns that Admin UI/API surfaces are for local/development use and that the REST API should be protected by an external trusted boundary.

Some important controls are opt-in or mode-dependent. UAID allowlist startup failure is controlled by a setting even though Python runtime validation fails closed. Rust A2A's UAID allowlist helper treats an empty allowlist as allowed with upstream warning, which is weaker than the Python path.

There are known validation gaps. The tool validation docs and code note that A2A lacks gateway-side output-schema enforcement, and REST success responses with an output schema but no structured content are currently lenient. These are acceptable as documented gaps but should not be copied into a stricter lab harness.

The plugin system is powerful enough to become a policy bypass if operated poorly. Settings such as allowing plugins to override auth-sensitive headers or RBAC decisions need strong governance, review, and production defaults.

Proxy and forwarding safety depends on deployment discipline. Token-scoping client IP reads the rewritten ASGI client host, so proxy middleware must be correctly configured. Forwarded host rewriting trusts registered hosts and assumes a trusted reverse proxy path.

Rust A2A trust headers include a SHA256 shared-secret tag rather than a real HMAC; the source comments call HMAC an upgrade path. For Agentic Coding Lab, use standard HMAC or mTLS for peer trust.

Rate limiting has a deliberate fail-open path on backend check failure. That may be acceptable for availability, but high-risk agent tool paths may need per-endpoint fail-closed or degraded-mode behavior.

## Ideas To Steal

Build one mandatory tool gateway path for all agent tool calls. Even if individual tools are local functions, route calls through a policy layer that checks tool identity, caller identity, team scope, resource ownership, budget, and output contract before returning to the agent.

Represent token scope explicitly: admin-wide, public-only, and team-scoped should be different values with different cache keys. Do not let a missing team claim become global access.

Use two-stage permissions for tool protocols: a coarse transport permission such as `servers.use`, then method-specific permission such as `tools.execute`, `resources.read`, or `prompts.fetch`.

Hide inaccessible tools as not found. Agents should not learn the names of tools they cannot use.

Keep policy hook mutation contracts narrow. For each hook, define exactly which fields can be changed, and validate plugin-provided headers/statuses before returning them.

Return explicit fast-path fallback reasons. When a direct executor cannot safely run a tool because of hooks, tracing, OAuth state, custom TLS, ambiguity, or unsupported transforms, return a reason and fall back to the policy-rich path.

Make cancellation observable and semantically separate from failure. Register cancellable tasks, map protocol cancellation to a stable code, re-raise runtime cancellation, and avoid wrapping user aborts as generic tool errors.

Validate successful structured outputs, but skip output-schema enforcement on explicit tool error envelopes. This mirrors MCP semantics and prevents validators from hiding useful upstream error messages.

Close DB sessions before slow upstream network execution. Reopen short-lived sessions for health checks, OAuth refresh, or metrics rather than holding locks across tool calls.

Use fail-closed federation allowlists and hop counters. Cross-gateway agent calls need endpoint parsing, domain/port allowlists, hop limits, and sanitized remote errors.

## Do Not Copy

Do not copy the whole gateway surface into Agentic Coding Lab. The admin UI, enterprise deployment matrix, multiple protocol families, Rust runtimes, OAuth variants, and plugin ecosystem are too much for a focused lab unless the project specifically needs them.

Do not copy weak or optional production controls. Treat empty federation allowlists as deny, make startup fail when federation is enabled without allowlists, and use HMAC/mTLS rather than ad hoc shared-secret tags.

Do not expose admin or REST management APIs to untrusted users just because the gateway has authentication. Keep management APIs behind an operator boundary.

Do not allow policy plugins to override auth headers or RBAC decisions by default. If an extension point can change identity or authorization, require explicit enablement, audit logs, and tests proving the intended precedence.

Do not accept lenient output-schema gaps for lab-critical workflows. A coding agent harness should prefer stricter success-path contracts and make missing structured output a visible error when the tool declared a schema.

Do not rely on deployment-only proxy trust for access decisions without tests. If forwarded IP/host affects policy, test the exact reverse-proxy configuration.

## Fit For Agentic Coding Lab

The repo is a strong source for the lab's tool-use safety layer. A practical adaptation would be much smaller:

- A registry of tools with owner, team, visibility, input schema, output schema, timeout, retry policy, and allowed side effects.
- A single invocation function that resolves the caller context, applies visibility/RBAC/resource checks, validates input, executes with timeout/cancellation, validates success output, and records an audit event.
- A plugin-like policy interface with fixed pre-call and post-call hooks, but narrow writable fields and no identity override by default.
- A session model that binds interactive tool sessions to caller identity and scope, with explicit denial on narrower tokens or cross-user reuse.
- A federation policy for remote helpers that requires allowlisted hosts, hop counts, no redirects, body limits, sanitized errors, and no implicit credential forwarding.
- A fast-path design where any optimized executor asks the policy authority for a plan and falls back on uncertainty.

Use ContextForge as a catalog of guardrails and failure contracts, not as a direct dependency. The lab likely needs fewer protocols and stronger defaults.

## Reviewed Paths

- `README.md`
- `SECURITY.md`
- `pyproject.toml`
- `mcpgateway/cli.py`
- `mcpgateway/main.py`
- `mcpgateway/auth.py`
- `mcpgateway/auth_context.py`
- `mcpgateway/middleware/rbac.py`
- `mcpgateway/middleware/token_scoping.py`
- `mcpgateway/middleware/http_auth_middleware.py`
- `mcpgateway/middleware/validation_middleware.py`
- `mcpgateway/middleware/security_headers.py`
- `mcpgateway/middleware/protocol_version.py`
- `mcpgateway/middleware/rate_limit_middleware.py`
- `mcpgateway/middleware/forwarded_host.py`
- `mcpgateway/middleware/client_disconnect.py`
- `mcpgateway/services/tool_service.py`
- `mcpgateway/services/gateway_service.py`
- `mcpgateway/services/a2a_service.py`
- `mcpgateway/services/permission_service.py`
- `mcpgateway/services/content_security_service.py`
- `mcpgateway/services/http_client_service.py`
- `mcpgateway/services/retry_manager.py`
- `mcpgateway/plugins/policy.py`
- `mcpgateway/plugins/framework/gateway_plugin_manager.py`
- `mcpgateway/plugins/framework/violation_codes.py`
- `plugins/config.yaml`
- `plugins/examples/circuit_breaker/`
- `plugins/examples/schema_guard/`
- `plugins/examples/resource_filter/`
- `plugins/examples/content_moderation/`
- `docs/docs/security/configuration.md`
- `docs/docs/security/uaid-cross-gateway-auth.md`
- `docs/docs/architecture/security-features.md`
- `docs/docs/architecture/tool-invocation-and-validation.md`
- `docs/docs/architecture/rust-mcp-runtime.md`
- `docs/docs/architecture/plugins.md`
- `docs/docs/architecture/multitenancy.md`
- `docs/docs/api/rfc9728-compliance.md`
- `docs/docs/api/cancellation.md`
- `crates/mcp_runtime/README.md`
- `crates/mcp_runtime/TESTING-DESIGN.md`
- `crates/mcp_runtime/src/config.rs`
- `crates/mcp_runtime/src/backend_url_validator.rs`
- `crates/mcp_runtime/src/lib.rs`
- `crates/a2a_runtime/src/config.rs`
- `crates/a2a_runtime/src/server.rs`
- `crates/a2a_runtime/src/trust.rs`
- `crates/a2a_runtime/src/uaid.rs`
- `crates/a2a_runtime/src/invoke.rs`
- `crates/a2a_runtime/src/circuit.rs`
- `crates/a2a_runtime/src/http.rs`
- `tests/unit/mcpgateway/middleware/test_token_scoping_extra.py`
- `tests/unit/mcpgateway/middleware/test_http_auth_integration.py`
- `tests/security/test_validation.py`
- `tests/unit/mcpgateway/services/test_tool_service_coverage.py`
- `tests/live_gateway/e2e_rust/test_mcp_session_isolation.py`
- Representative `tests/fuzz/`, `tests/compliance/mcp_2025_11_25/`, plugin integration, rate-limit, content-pattern, and OAuth well-known tests by targeted search.

## Excluded Paths

- `mcpgateway/admin_ui/**`, UI templates, static assets, and browser-only harnesses were excluded except where middleware/auth behavior referenced the admin surface. The assignment is about error prevention in execution paths, not UI rendering.
- `mcp-servers/**` and `a2a-agents/**` were excluded as sample/demo servers. The repository documentation warns that sample servers are not production hardening examples and should be sandboxed if used.
- Generated dependency and lock artifacts such as `uv.lock`, `package-lock.json`, `Cargo.lock`, `.secrets.baseline`, and generated snapshots were excluded because they do not define gateway behavior.
- Binary/media/theme assets, screenshots, icons, and documentation visual assets were excluded because they do not affect tool-use safety.
- Bulk deployment manifests, Helm/charts, Docker Compose variants, CI files, and supply-chain metadata were only scanned for security context and not deeply reviewed. They are operational packaging rather than the core invocation path.
- Full exhaustive tests were not read line by line. Representative unit, integration, fuzz, live gateway, MCP compliance, Rust runtime, and plugin tests were sampled around the relevant error-prevention invariants.
