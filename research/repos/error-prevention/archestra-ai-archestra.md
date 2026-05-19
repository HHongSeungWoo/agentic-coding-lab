# archestra-ai/archestra

- URL: https://github.com/archestra-ai/archestra
- Category: error-prevention
- Stars snapshot: 3,647 (GitHub REST API repository search, captured 2026-05-11)
- Reviewed commit: 60ca5c3f50bb117d04077645fa7c3a2443f914e3
- Reviewed at: 2026-05-19
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong candidate for Agentic Coding Lab error-prevention patterns. The useful part is not the full enterprise platform, but the execution-time pattern: classify tool results as trusted or untrusted, carry that trust state through later turns and subagents, then deterministically gate generated tool calls before they execute.

## Why It Matters

Archestra is built around the problem Agentic Coding Lab cares about: an AI agent reads untrusted data, then tries to use powerful tools. The project treats that as an execution hazard rather than a prompt-writing problem. Its LLM proxy and MCP gateway put deterministic checks around tool outputs, tool-call arguments, credentials, RBAC, tool visibility, and streaming tool-call events.

For coding agents, the direct lesson is a practical safety loop: mark context dirty after untrusted reads, block or require approval for write/external tools while dirty, sanitize only through constrained workflows, and preserve an auditable reason for every refusal. That maps cleanly to repo editing, shell use, network calls, issue tracker access, deployment tools, and generated code execution.

## What It Is

Archestra is a TypeScript MCP-native secure AI platform. It includes a Fastify backend, an LLM proxy, chat and A2A agent execution, an MCP gateway, a private MCP registry, Kubernetes-based MCP server orchestration, policy models, RBAC, credential resolution, observability, and docs for lethal-trifecta style prompt injection.

The platform centralizes MCP servers and credentials so agents connect through one governed endpoint instead of each client owning local tools. It supports regular gateway exposure and a `search_and_run_only` mode where models see meta tools instead of the full tool list. It also includes an automated policy-configuration agent that proposes tool policies from metadata, but the actual enforcement is stored deterministic policy data.

## Research Themes

- Token efficiency: Secondary theme. The proxy can apply TOON compression to tool results, strip browser-only result data before model input, and expose only search/run meta tools to reduce tool-list bloat.
- Context control: Primary theme. Tool results are evaluated before the next model request, unsafe boundaries are attached to results, inherited untrusted context propagates through delegation and proxy headers, and model-visible tools can be filtered by gateway exposure mode and UI visibility.
- Sub-agent / multi-agent: Strong theme. Agent delegation carries `parentContextIsTrusted`; A2A defaults to blocking approval-required tools in autonomous contexts; Dual LLM uses a quarantined agent to inspect raw tool output while the main agent only sees constrained answers and a safe summary.
- Domain-specific workflow: Enterprise MCP workflow. The registry, gateway, OAuth, ID-JAG, JWKS, scoped installs, team/org permissions, and Kubernetes runtime are platform features rather than generic coding-agent logic.
- Error prevention: Core theme. New tools default to untrusted results and blocked use in untrusted context. The LLM proxy checks tool-call policies after model generation and before execution, buffers risky streaming tool-call chunks, and records blocked spans/metrics.
- Self-learning / memory: Limited. The system stores interaction records, policy auto-config reasoning, MCP session metadata, resource caches, and OAuth refresh status, but it does not learn durable behavioral rules from past failures.
- Popular skills: The reusable "skills" are policy auto-configuration, Dual LLM quarantine, search-and-run tool discovery, credential-resolved MCP execution, and explicit refusal metadata.

## Core Execution Path

The main error-prevention path starts in the LLM proxy. A request enters a provider route, resolves authentication, checks limits, persists client-declared tools for LLM-proxy agents, resolves the model, and loads the organization global tool policy. Before forwarding the request, it converts provider-specific messages into common messages and evaluates trusted-data policies over prior tool results.

Trusted-data evaluation decides whether each prior tool result is trusted, untrusted, blocked, or sanitized with Dual LLM. Blocked results are replaced with a policy message. Sanitized results are replaced with a safe summary. If any prior result remains untrusted, the current context becomes untrusted and the proxy carries an unsafe boundary forward.

The model call then goes to the selected provider adapter. In non-streaming mode, the proxy extracts generated tool calls from the response and runs tool-invocation policies. In streaming mode, text deltas can pass through immediately, but tool-call chunks are buffered when the tool has blocking policies, approval policies, conditional policies, or no clear always-allow policy. At stream end, the proxy evaluates the completed tool call and either emits the held tool-call events or replaces them with a refusal.

Allowed chat tool calls execute through AI SDK tool wrappers and the MCP gateway/client path. The chat MCP client checks whether a `require_approval` policy applies for interactive chat, blocks approval-required tools for autonomous A2A execution, filters tools that are not model-visible, and attaches unsafe-context metadata to tool results after execution.

The MCP gateway authenticates the incoming token, builds a token auth context, exposes only assigned and visible tools, and forwards allowed calls to `mcpClient.executeToolCall`. The MCP client verifies tool assignment, resolves the right MCP server or catalog install, resolves caller-specific credentials, attaches only configured passthrough headers, handles OAuth refresh/retry, recovers stale HTTP sessions, limits concurrency, records tool-call logs, and returns structured actionable errors when credentials or installs are missing.

The registry and orchestrator create the tool universe this path operates on. Registry routes store server metadata, preserve secrets outside plaintext config, validate preset/user values, discover tools, create default policies for new tools, assign tools to agents/gateways, and launch local MCP servers as Kubernetes deployments.

## Architecture

The useful architecture is split into five enforcement layers:

1. `platform/backend/src/routes/proxy/*` implements provider-facing LLM proxy routes and adapters. This is where prior tool outputs are rewritten, generated tool calls are blocked, streaming tool-call events are buffered, and provider-specific request/response formats are normalized.
2. `platform/backend/src/guardrails/*` and `platform/backend/src/models/*policy*.ts` implement the policy engine. Tool-result policies classify data trust; tool-invocation policies gate later tool calls based on tool input, context trust, team context, and global policy mode.
3. `platform/backend/src/clients/chat-mcp-client.ts`, `platform/backend/src/routes/chat/routes.ts`, and `platform/backend/src/agents/*` connect chat/A2A execution to the proxy and gateway. This is where approval-required tools and delegated context trust are handled.
4. `platform/backend/src/routes/mcp-gateway*.ts`, `platform/backend/src/routes/mcp-proxy.ts`, and `platform/backend/src/clients/mcp-client.ts` implement MCP authentication, tool listing, call execution, credential resolution, retries, structured errors, and app/model visibility.
5. `platform/backend/src/routes/internal-mcp-catalog.ts`, `platform/backend/src/routes/mcp-server.ts`, and `platform/backend/src/k8s/mcp-server-runtime/*` implement registry and self-hosted MCP orchestration.

The docs align with the code. The guardrail docs describe deterministic policy enforcement at the proxy, the lethal-trifecta docs frame the threat model, the Dual LLM docs explain quarantine/sanitization, and the gateway/registry/orchestrator docs describe tool exposure, auth, installs, and runtime isolation.

## Design Choices

Archestra separates result trust from invocation permission. A read tool can be allowed while its output marks the conversation untrusted. Later write, network, or external communication tools can then be blocked because the context is untrusted. This is the most transferable design choice for coding agents.

The policy model is intentionally simple. Specific policies run before defaults. Conditions are ANDed path/operator checks against tool input or policy context. Result policies support `mark_as_trusted`, `mark_as_untrusted`, `block_always`, and `sanitize_with_dual_llm`. Invocation policies support always allow/block, block in untrusted context, allow in untrusted context, and require approval.

New tools receive conservative defaults in `ToolModel`: invocation defaults to blocked when context is untrusted, and result trust defaults to untrusted. A separate policy-configuration subagent can propose better defaults from tool metadata, but enforcement remains database policy, not LLM judgment.

Global policy mode is a strong switch. In `restrictive` mode, missing policies make external tool results untrusted and can block external tool calls in untrusted context. In `permissive` mode, policy checks mostly short-circuit. This makes rollout easier but creates a large safety footgun.

Streaming is treated as a safety surface. The proxy does not blindly stream tool-call deltas if policy might block them. It holds those events, evaluates the final call, then either releases the call or emits refusal content. This is important because otherwise a client could start executing a streamed tool call before the proxy decides it is unsafe.

Auth is split into gateway auth and upstream MCP auth. The caller proves access to Archestra's gateway first; then the MCP client resolves personal, team, org, OAuth, enterprise-managed, or IdP-exchanged credentials at call time. Missing credentials return install or re-auth links instead of ambiguous tool failures.

## Strengths

The guardrails live on the actual execution path. Tool-output trust is evaluated before the next provider call, and tool-invocation policy is evaluated after the model emits tool calls but before the platform lets those calls execute.

The design handles multi-turn and multi-agent contamination. Unsafe context is not treated as a local prompt detail; it can be represented as an unsafe boundary, inherited through delegation, and sent to the proxy via an untrusted-context header.

The failure handling is practical. The proxy lazily commits streaming headers so pre-stream provider failures can still return correct HTTP status. Failed interactions are persisted. OAuth tokens refresh proactively and retry once on auth errors. Refresh failures are recorded. Stale MCP sessions are retried under locks. Missing installs/credentials return structured metadata with user-action links.

The gateway has several least-privilege controls: per-agent assigned tools, search-and-run exposure mode, RBAC for built-in tools, model/app visibility metadata, token resource binding, no negative auth-cache entries, and passthrough-header allowlists.

The tests cover the important mechanisms. Unit tests cover blocked tool calls, disabled tool filtering, trusted-data blocking, Dual LLM sanitization, approval policy behavior, app visibility filtering, search-and-run implicit tools, auth/JWKS paths, and helper normalization. E2E mappings exercise provider variants that block third-party tool calls in untrusted context while allowing Archestra built-in tools.

## Weaknesses

The global `permissive` mode bypasses much of the policy system, and `getGlobalToolPolicy` can fall back to permissive-style behavior when organization resolution is weak. For a lab focused on error prevention, default-open policy should not be copied.

Built-in Archestra tools bypass tool-invocation policy evaluation. That is understandable for internal control-plane tools, but the `run_tool` meta tool appears to dispatch third-party target tools through `mcpClient.executeToolCall` without re-running target invocation policies. In `search_and_run_only` mode, this can create a guardrail gap: the model calls an allowed built-in meta tool, and the actual third-party tool call happens underneath. Assignment/auth still apply, but the target invocation policy is not obviously enforced on that path.

`require_approval` is split across layers. `ToolInvocationPolicyModel.evaluateBatch` treats it as allow in proxy context, while chat/A2A wrappers decide whether to ask the user or block autonomous execution. That can work, but it is easy to get wrong if another execution path calls tools directly.

Trusted-data conditions are useful but shallow. They are path/operator checks with simple wildcard extraction and all-values matching. They do not express richer dataflow, taint composition, schema-aware constraints, or all/some quantifiers beyond the implemented wildcard behavior.

Dual LLM is a sanitization strategy, not a deterministic guarantee. It reduces raw-output exposure by separating the main and quarantine agents, but it still depends on model compliance, constrained prompts, and fallback behavior when the quarantine response is invalid.

Custom Kubernetes deployment YAML validation is shallow. The validator checks YAML shape and protected template markers, and the generator overwrites some protected deployment fields, but risky pod spec fields such as privileged containers, host networking, or host paths are not clearly rejected in the reviewed path. The Helm NetworkPolicy is a useful egress layer, but it is optional and does not replace pod security controls.

Direct MCP app/proxy routes execute assigned app-visible tools without LLM proxy invocation guardrails. That may be intended for user-driven app tools, but Agentic Coding Lab should treat every model-originated path and every meta-tool path as needing the same target policy check.

## Ideas To Steal

Add a conversation-level `context_is_trusted` bit with an explicit unsafe boundary that points to the tool result that dirtied the context.

Keep two deterministic policy planes: one for classifying tool results, one for gating future tool invocations. Do not collapse these into one allow/deny list.

Make new tools conservative by default: result output is untrusted, and side-effecting or external communication tools are blocked while context is untrusted.

Evaluate policy after the model emits concrete tool names and arguments, not before. Pre-prompt guidance can help, but the enforcement point should see the actual arguments.

Buffer streamed tool-call chunks until policy evaluation has completed. Never let a client start executing a streamed call that might be replaced by a refusal.

Use an LLM to draft policy recommendations, but store auditable deterministic policy as the artifact that enforcement reads.

Separate "gateway credential to access the tool surface" from "upstream credential used against the third-party service." Resolve upstream credentials at call time from the authenticated caller and scope.

Return structured tool errors with install, re-auth, or access hints. Bad credentials and missing installs should be recoverable workflow states, not opaque failures.

For search-and-run tool exposure, always re-check the resolved target tool's policy. A meta tool should be a routing convenience, not a guardrail bypass.

## Do Not Copy

Do not use a permissive global fallback as the default for a safety-first coding-agent lab.

Do not exempt broad built-in/meta tools from target policy checks if they can cause third-party, shell, filesystem, deployment, or network effects.

Do not depend on Dual LLM as the only protection for untrusted data. Use deterministic taint/trust state first, and treat sanitization as one controlled transition.

Do not copy the whole platform control plane unless the lab needs enterprise MCP registry, OAuth federation, Kubernetes orchestration, and team/org administration.

Do not rely on tool descriptions to keep the model safe. The important controls are post-generation policy checks, credential scoping, tool assignment, and explicit refusal.

Do not accept custom runtime YAML without a separate pod security policy if the runtime can launch arbitrary MCP servers.

Do not let approval logic live only in one UI path. Autonomous, chat, proxy, gateway, and meta-tool paths need one shared answer for whether a call may execute.

## Fit For Agentic Coding Lab

This repo is in-scope and high value for error prevention. The most useful adoption target is a compact version of Archestra's guardrail loop:

1. Tool result enters transcript.
2. Result policy classifies it as trusted, untrusted, blocked, or sanitized.
3. The conversation carries a trust flag and unsafe boundary.
4. The model proposes concrete tool calls.
5. Invocation policy evaluates tool name, arguments, and context trust.
6. Allowed calls execute; blocked calls become explicit refusals with logged reasons.

For coding agents, the first practical mapping is:

- Read-only local repo inspection can often stay trusted.
- Web pages, issue comments, dependency docs, PR comments, test output containing generated instructions, and remote tool output should mark context untrusted unless classified.
- File writes, shell commands, git pushes, package installs, deployment commands, credential access, and external communication should be blocked or require approval while context is untrusted.
- Subagents should inherit untrusted context from parents and return result trust metadata with their outputs.

The repo is best treated as a pattern source, not an implementation dependency. Agentic Coding Lab can implement a smaller policy engine with fewer enterprise concepts while preserving the core dataflow.

## Reviewed Paths

- `README.md`: platform framing, central MCP toolbox, guardrails, orchestrator, private registry, and Dual LLM positioning.
- `docs/pages/platform-ai-tool-guardrails.md`: deterministic tool call/result policy model, policy actions, inherited unsafe context, and policy auto-config agent.
- `docs/pages/platform-lethal-trifecta.md`: threat model for private data plus untrusted content plus external communication.
- `docs/pages/platform-dual-llm.md`: main/quarantine model split for sanitizing untrusted tool outputs.
- `docs/pages/platform-security-concepts.md`: enforcement location at LLM proxy and gateway rather than prompt-only controls.
- `docs/pages/platform-mcp-gateway.md`: gateway exposure, search-and-run mode, auth methods, access control, and passthrough header allowlist.
- `docs/pages/platform-private-registry.md`: registry item/install split, scoped installs, credential resolution, and labels.
- `docs/pages/platform-orchestrator.md`: Kubernetes runtime model for self-hosted MCP servers.
- `docs/pages/platform-access-control.md`: RBAC resource/action model and scope rules.
- `docs/pages/mcp-authentication.md`: gateway auth versus upstream auth, personal/team credential lookup, OAuth refresh, and missing-credential errors.
- `docs/pages/platform-built-in-agents-policy-config.md`: automated policy recommendation flow and boundaries.
- `docs/pages/platform-llm-proxy.md`: LLM proxy role and request metadata.
- `platform/backend/src/guardrails/tool-invocation.ts`: enabled-tool filtering and post-generation invocation blocking.
- `platform/backend/src/guardrails/trusted-data.ts`: trusted-data evaluation, unsafe boundaries, block replacement, and Dual LLM sanitization.
- `platform/backend/src/models/tool-invocation-policy.ts`: invocation policy evaluation, approval handling, permissive/restrictive modes, and streaming policy hints.
- `platform/backend/src/models/trusted-data-policy.ts`: result trust policy evaluation, default behavior, path conditions, and Archestra built-in trust bypass.
- `platform/backend/src/database/schemas/tool-invocation-policy.ts` and `platform/backend/src/database/schemas/trusted-data-policy.ts`: policy storage shape.
- `platform/backend/src/models/tool.ts`: default policy creation for discovered tools and policy auto-config trigger.
- `platform/backend/src/agents/subagents/policy-configuration.ts`: LLM-assisted policy recommendation and timeout behavior.
- `platform/backend/src/agents/subagents/dual-llm.ts`: quarantine/main agent sanitization implementation.
- `platform/backend/src/agents/context-trust.ts`: context-trust evaluation for delegated tool execution.
- `platform/backend/src/routes/proxy/llm-proxy-handler.ts`: provider-independent proxy enforcement, streaming buffering, refusal conversion, error persistence, and metrics.
- `platform/backend/src/routes/proxy/llm-proxy-helpers.ts`: tool-call argument normalization, blocked metrics, interaction records, and error handling.
- `platform/backend/src/routes/proxy/adapters/openai.ts`: representative provider adapter for message conversion, tool-result updates, compression, and response extraction.
- `platform/backend/src/clients/llm-client.ts`: internal calls through the proxy and inherited untrusted-context header.
- `platform/backend/src/routes/mcp-gateway.ts`: stateless MCP gateway endpoint, auth challenge behavior, and JSON-RPC error handling.
- `platform/backend/src/routes/mcp-gateway.utils.ts`: tools/list and tools/call handlers, token validation, JWKS/ID-JAG/team/OAuth auth, search-and-run filtering, and passthrough headers.
- `platform/backend/src/routes/mcp-proxy.ts`: MCP Apps route, app visibility filtering, and session-auth context.
- `platform/backend/src/clients/mcp-client.ts`: assigned-tool validation, server/credential resolution, OAuth refresh/retry, stale-session recovery, concurrency limits, and structured error results.
- `platform/backend/src/clients/chat-mcp-client.ts`: chat tool filtering, approval checks, autonomous approval blocking, model output shaping, and unsafe-boundary metadata.
- `platform/backend/src/routes/chat/routes.ts`: chat streaming path through proxied models and MCP tools.
- `platform/backend/src/agents/a2a-executor.ts`: A2A/subagent execution and parent context trust propagation.
- `platform/backend/src/archestra-mcp-server/index.ts`: built-in Archestra tool registration, validation, and RBAC checks.
- `platform/backend/src/archestra-mcp-server/rbac.ts`: built-in tool permission map and meta-tool permission choice.
- `platform/backend/src/archestra-mcp-server/delegation.ts`: delegation access checks and trust propagation.
- `platform/backend/src/archestra-mcp-server/search-tools.ts`: search meta tool behavior.
- `platform/backend/src/archestra-mcp-server/run-tool.ts`: run meta tool dispatch path and policy-bypass concern.
- `platform/backend/src/routes/internal-mcp-catalog.ts`: registry create/update, secret handling, preset validation, and inheritance behavior.
- `platform/backend/src/routes/mcp-server.ts`: MCP install/re-auth lifecycle, validation, tool discovery, cleanup, and status transitions.
- `platform/backend/src/k8s/mcp-server-runtime/k8s-yaml-generator.ts`: default/custom deployment YAML generation and validation limits.
- `platform/backend/src/k8s/mcp-server-runtime/k8s-deployment.ts`: runtime deployment/secrets/env/session mechanics.
- `platform/helm/archestra/templates/mcp-network-policy.yaml`: optional egress policy for MCP server pods.
- `platform/backend/src/guardrails/*.test.ts`, `platform/backend/src/models/*policy*.test.ts`, `platform/backend/src/routes/proxy/*test.ts`, `platform/backend/src/routes/mcp-gateway*.test.ts`, `platform/backend/src/routes/mcp-proxy.test.ts`, `platform/backend/src/clients/*mcp-client*.test.ts`: representative tests for blocking, trust evaluation, approval behavior, auth, search-and-run mode, visibility, normalization, and failure paths.
- `platform/helm/e2e-tests/mappings/*blocks-tool-untrusted-data.json` and `*allows-archestra-untrusted-context.json`: provider matrix mappings for untrusted-context guardrail behavior.

## Excluded Paths

- `platform/frontend/**`: mostly UI surfaces for configuring and viewing the platform. I used backend/API behavior as the source of truth for enforcement and did not review UI-only rendering paths deeply.
- `docs/assets/**`, screenshots, image files, and marketing media: binary or visual documentation assets that do not change execution behavior.
- `platform/pnpm-lock.yaml`, package manager locks, bundled Helm chart archives such as `postgresql-18.0.8.tgz`, and certificate bundles: generated/vendor/binary dependency artifacts.
- `platform/shared/hey-api/**` and generated OpenAPI/client outputs: generated API client/schema material. I reviewed source routes and schemas instead.
- `platform/backend/src/database/migrations/meta/**`: generated migration snapshots. I reviewed current schema definitions for the policy tables instead.
- Provider adapters beyond representative OpenAI plus grep/test sampling: many provider files repeat the same adapter pattern. The important enforcement point is centralized in `llm-proxy-handler.ts`; provider-specific tests were sampled for coverage.
- Knowledge-base UI/content-management paths outside trust/RBAC implications: relevant to product scope, but not central to MCP tool-call error prevention.
- Local developer scripts, Docker compose, CI plumbing, and non-security route tests: useful operationally, but not part of the agent execution guardrail path reviewed here.
