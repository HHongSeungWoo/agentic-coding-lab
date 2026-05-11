# modelcontextprotocol/modelcontextprotocol

- URL: https://github.com/modelcontextprotocol/modelcontextprotocol
- Category: mcp
- Stars snapshot: 8,077 (GitHub REST API, captured 2026-05-11)
- Reviewed commit: 91a643c80ee9ad0eabbe09aa0c22498908614a8e
- Reviewed at: 2026-05-11
- Status: reviewed
- Scope fit: in-scope
- Verdict: Official MCP specification and documentation source. The main reusable value is not executable code, but a precise protocol contract for agent tool/resource/prompt boundaries, capability negotiation, transport behavior, schema validation, security consent, OAuth, roots, sampling, elicitation, tasks, and spec evolution. Strong source for designing coding-agent MCP support; weak as a direct implementation template because server/client behavior lives in SDKs and downstream servers.

## Why It Matters

This repository is the canonical source for what MCP means at the wire and documentation level. The current published protocol version in the repo is `2025-11-25`, with `draft` carrying in-progress breaking changes. The README and AGENTS file state that `schema/<version>/schema.ts` is the TypeScript source of truth, with JSON Schema and spec reference pages generated from it.

For Agentic Coding Lab, this repo defines the vocabulary and safety boundaries that every MCP server, client, registry, gateway, and coding-agent integration should be judged against. It gives clear distinctions that matter for coding agents:

- Tools are model-controlled actions and need human consent and audit.
- Resources are application-driven context sources and need URI, MIME, size, and access controls.
- Prompts are user-controlled reusable workflows.
- Sampling, roots, and elicitation are client-side capabilities that servers may request only after negotiation.
- Current tasks provide durable deferred execution; draft MRTR moves server-to-client requests into explicit retry payloads.

## What It Is

The repo contains the versioned MCP specification, protocol schema, official documentation site content, schema examples, Specification Enhancement Proposals, a small SEP automation tool, and a Claude plugin for spec contribution workflows.

The specification defines a JSON-RPC 2.0 protocol between hosts, clients, and servers. A host is the user-facing AI application, a client is one isolated connection from that host to one MCP server, and a server exposes context and capabilities. The protocol has a data layer for JSON-RPC lifecycle and primitives, and a transport layer for stdio or Streamable HTTP.

The repo is documentation/spec infrastructure, not a production MCP server. Verification focuses on generated schema/docs consistency and example validation rather than runtime behavior.

## Research Themes

- Token efficiency: Strong. Resources include `size`; annotations include `audience`, `priority`, and `lastModified`; draft tools guidance recommends deterministic `tools/list` ordering for client caching and LLM prompt cache hit rates. The protocol also separates resources from tools so hosts can avoid dumping every available context source into the model.
- Context control: Very strong. The architecture explicitly isolates servers from the full conversation and from other servers. Roots communicate file scope, resources are application-selected, sampling `includeContext` is soft-deprecated beyond `"none"` unless negotiated, and clients/hosts remain responsible for aggregation.
- Sub-agent / multi-agent: Limited direct support. MCP is not a multi-agent framework. Sampling allows nested model calls through the client, and tasks can represent durable long-running work, but orchestration policy stays outside the spec.
- Domain-specific workflow: Strong. Servers can expose narrow tools, resource templates, completions, prompts, and optional agent skills. The docs recommend remote HTTP for cloud APIs, MCPB/local stdio for local machine access, and skills to guide MCP server design.
- Error prevention: Strong. Capability negotiation prevents unsupported calls; JSON Schema validates tool inputs/outputs; protocol versus tool-execution errors are separated so models can self-correct; examples are validated against schema; Inspector docs promote edge-case testing.
- Self-learning / memory: Not a memory system. The spec enables memory-like servers through resources/tools, but persistent memory policy, retention, ranking, and privacy are deliberately outside the protocol.
- Popular skills: The repo ships `plugins/mcp-spec` with `/search-mcp-github` for spec history research and `/draft-sep` for SEP drafting. The docs also point to an `mcp-server-dev` plugin with skills for server design, MCP apps, and MCPB packaging.

## Core Execution Path

The normative source starts in `schema/2025-11-25/schema.ts`. The schema defines JSON-RPC request/notification/response envelopes, initialization types, client/server capabilities, server primitives, client primitives, content blocks, tasks, and utility messages. `scripts/generate-schemas.ts` generates JSON Schema for all schema versions and transforms modern versions (`2025-11-25`, `draft`) to JSON Schema 2020-12. `scripts/validate-examples.ts` loads each `schema/<version>/schema.json` and validates examples in `schema/<version>/examples/<TypeName>/`.

The docs site is Mintlify content under `docs/`. `docs/docs.json` controls navigation and marks `2025-11-25` as latest. Developer docs explain architecture, local and remote connection paths, server/client tutorials, Inspector verification, security best practices, and agent-skill-assisted server building. Formal spec pages under `docs/specification/<version>/` mirror schema versions and describe normative behavior.

Runtime protocol flow:

1. Client sends `initialize` with supported protocol version, client capabilities, and client info.
2. Server replies with negotiated protocol version, server capabilities, server info, and optional instructions.
3. Client sends `notifications/initialized`.
4. During operation, each side must respect negotiated capabilities and protocol version.
5. Client calls server features: `tools/list`, `tools/call`, `resources/list`, `resources/read`, `resources/templates/list`, `prompts/list`, `prompts/get`, completions, logging controls, tasks, etc.
6. Server may request client features only when the client declared them: roots, sampling, elicitation, and task-augmented variants.
7. Shutdown is transport-level: close stdio streams or HTTP connections.

Transport behavior is split:

- `stdio`: client launches a subprocess; JSON-RPC messages are newline-delimited on stdin/stdout; server may log to stderr; stdout must contain only valid MCP messages.
- Streamable HTTP: single MCP endpoint accepts POST and optional GET/SSE streams. HTTP clients send negotiated `MCP-Protocol-Version` after initialization. Current `2025-11-25` supports optional `MCP-Session-Id`; draft removes protocol-level sessions.

## Architecture

The conceptual architecture is intentionally small:

- Host: user-facing AI app that manages clients, consent, permissions, model access, and cross-server context.
- Client: one stateful session to one server; performs lifecycle, routes messages, and preserves server isolation.
- Server: focused capability provider exposing resources, tools, and prompts, and optionally requesting client-side roots, sampling, or elicitation.

Server-side primitives:

- Tools are actions. They have names, descriptions, JSON Schema `inputSchema`, optional `outputSchema`, annotations, icons, and optional task support. Tool annotations are hints and must not be trusted from untrusted servers.
- Resources are URI-addressed context. They support direct resources, resource templates, `resources/read`, `resources/subscribe`, text/blob contents, MIME types, size, and annotations.
- Prompts are user-invoked templates with arguments and returned messages. Prompt messages can embed text, images, audio, and resources.

Client-side primitives:

- Roots expose `file://` workspace boundaries to servers. The docs clarify roots are coordination, not an OS security boundary.
- Sampling lets servers ask the host model to generate content while the client controls model choice, prompt review, and response disclosure. `2025-11-25` adds sampling tool use with `tools` and `toolChoice`.
- Elicitation lets servers request user input. Form mode is restricted to flat primitive schemas; URL mode is required for sensitive interactions and keeps credentials outside the MCP client and LLM context.

Utilities include ping, progress, cancellation, pagination, logging, completion, and tasks. Tasks are experimental in `2025-11-25`: a request can include `task`, receive `CreateTaskResult`, poll `tasks/get`, retrieve final result through `tasks/result`, and cancel with `tasks/cancel`.

## Design Choices

MCP deliberately assigns control surfaces:

- Model-controlled: tools.
- Application-controlled: resources.
- User-controlled: prompts.
- Host/client-controlled: sampling, roots, elicitation approval, model selection, and context aggregation.

The spec treats every powerful surface as negotiated. Calling a method without matching capability is an error or unsupported behavior. This is valuable for coding agents because it turns tool availability, long-running execution, roots, sampling, and interaction flows into explicit contracts rather than hidden prompt conventions.

The schema makes JSON Schema central. Tool `inputSchema` and `outputSchema` default to JSON Schema 2020-12 in modern versions. The `2025-11-25` changelog explicitly establishes 2020-12 as the default and decouples request payloads from RPC method definitions into standalone parameter schemas.

The error design is agent-friendly. Unknown tools, malformed requests, and unsupported methods are protocol errors. Tool validation or business failures should be returned as `CallToolResult` with `isError: true`, so a model can see actionable feedback and retry.

Authorization is HTTP-only and based on OAuth 2.1 patterns. MCP servers are OAuth resource servers; MCP clients are OAuth clients. The spec requires Protected Resource Metadata discovery, Resource Indicators, bearer tokens in Authorization headers, PKCE, audience validation, no query-string tokens, and no token passthrough.

Spec evolution is active:

- `2025-03-26`: added OAuth authorization, Streamable HTTP, JSON-RPC batching, and tool annotations.
- `2025-06-18`: removed batching, added structured tool output, elicitation, resource links, protected resource metadata/resource indicators, HTTP protocol version header, and security best practices.
- `2025-11-25`: added icons, URL mode elicitation, tool use in sampling, Client ID Metadata Documents, incremental scopes, experimental tasks, JSON Schema 2020-12 default, tool-name guidance, and richer elicitation enums/defaults.
- `draft`: removes protocol-level sessions and `Mcp-Session-Id`, adds `extensions` capabilities, OpenTelemetry `_meta` conventions, deterministic tool ordering, standard HTTP request headers (`Mcp-Method`, `Mcp-Name`), custom tool-parameter headers via `x-mcp-header`, and MRTR as a replacement for direct server-to-client requests.

## Strengths

The primitive taxonomy is unusually useful for coding agents. It separates actions, context, workflow templates, workspace boundaries, nested model calls, and user input instead of flattening all external capability into "tools."

The trust model is explicit. The spec states MCP cannot enforce all security at protocol level, but it gives implementors concrete obligations around user consent, root boundaries, tool approval, sampling approval, sensitive elicitation, OAuth audience binding, Origin validation, local server execution consent, and session/task isolation.

Schema discipline is strong. TypeScript is source of truth; JSON Schema and MDX references are generated; examples are validated; docs state exact generation and check commands. That makes protocol drift more visible than in many prompt/tool ecosystems.

The task model addresses a real coding-agent need: expensive verification, batch jobs, long-running builds, or workflows needing user input can return immediately and be polled without blocking the model indefinitely.

The draft MRTR direction is promising for horizontally scaled remote servers because it avoids server-initiated requests needing sticky sessions or shared queues. It also makes user input and sampling dependencies explicit in retry payloads.

The security best practices page is concrete, not generic. It covers confused deputy attacks, token passthrough, SSRF in OAuth discovery, session hijacking, local MCP server compromise, and scope minimization.

## Weaknesses

This repo is not an implementation. It does not show how real clients merge tool lists, route approvals, sandbox local servers, enforce roots, redact sampling prompts, or persist task state. Those patterns must be reviewed in SDKs, Inspector, and reference servers.

Roots are not an enforceable security boundary. The client can tell a server where it should operate, but malicious or overprivileged local servers can ignore roots unless OS permissions, sandboxing, or server-side path validation enforce them.

The current `2025-11-25` HTTP session model and draft sessionless model create migration complexity. Implementors must track which version they support and avoid assuming session IDs exist going forward.

Tasks are experimental and add state-management obligations: cryptographically strong IDs, auth-context binding, TTL cleanup, polling limits, and careful handling of `input_required`. Weak implementations can leak task results or create denial-of-service pressure.

Sampling with tools enables powerful nested agent loops but increases risk. Servers can request tools during sampling, execute tool-use responses themselves, and continue loops; implementations need iteration limits, review UI, and strict tool-result balancing.

Docs include tutorial code and user-facing client examples that are useful conceptually but not sufficient for production security. Local server setup examples still rely on executing commands from config, which the security guide separately warns must be treated as arbitrary code execution.

## Ideas To Steal

Adopt the primitive-control taxonomy in Agentic Coding Lab docs and evaluations: model-controlled tools, app-controlled resources, user-controlled prompts, client-controlled roots/sampling/elicitation.

Require capability negotiation in any local tool framework. Agents should not assume support for roots, tasks, sampling, structured outputs, or list-change notifications unless declared.

Represent tool failures as model-visible execution errors when the model can self-correct, and reserve protocol errors for malformed or unsupported calls.

Use `outputSchema` plus `structuredContent` for coding-agent tools that return parseable facts, diagnostics, test summaries, or patch plans, while preserving text fallback for compatibility.

Treat roots as advisory context plus a prompt to enforce real filesystem gates elsewhere. Pair roots with sandbox permissions and path validation.

Use task-style deferred execution for long builds, test suites, browser checks, or large repository analyses. Include TTL, auth-context binding, progress tokens, poll intervals, cancellation, and final-result retrieval.

Borrow URL mode elicitation for secrets and external OAuth. Sensitive third-party credentials should go directly between user and trusted server domain, never through the coding agent transcript.

Mirror the repo's validation pipeline for protocol artifacts: generated JSON Schema check, generated docs check, example validation, docs formatting, and broken-link checks.

## Do Not Copy

Do not treat MCP itself as a sandbox. Local MCP servers run code with user privileges unless the client/platform adds a sandbox.

Do not trust tool annotations such as `readOnlyHint`, `destructiveHint`, or `openWorldHint` from untrusted servers for approval decisions.

Do not pass through OAuth tokens from client to upstream APIs. The spec explicitly forbids accepting tokens not issued for the MCP server and forwarding them downstream.

Do not request passwords, API keys, access tokens, payment credentials, or other secrets through form-mode elicitation. Use URL mode or an out-of-band secure flow.

Do not design current integrations around `MCP-Session-Id` as a permanent primitive. The draft removes protocol-level sessions.

Do not expose large dynamic tool lists in arbitrary order. Draft guidance points toward deterministic ordering and cache-friendly lists.

Do not assume generated schema/MDX files are the editing source. The TypeScript schema is authoritative.

## Fit For Agentic Coding Lab

Fit is very strong. This repo should be treated as the baseline spec reference for MCP-related candidates and coding-agent integrations. It gives stable terminology, protocol methods, capability rules, and security expectations that can be turned into review checklists.

Concrete applications:

- MCP server review rubric: verify capabilities, schema quality, error separation, roots/path handling, auth, token audience binding, SSRF defenses, consent surfaces, and logging redaction.
- Coding-agent tool design: split tools/resources/prompts instead of making every context source a tool; use structured outputs and execution errors for self-correction.
- Long-running verification: model after tasks or draft MRTR rather than blocking a single call indefinitely.
- Security policy: local servers require explicit command review and sandboxing; remote servers require OAuth audience binding, Origin validation, least scopes, and no token passthrough.
- Context policy: use resource annotations, resource sizes, deterministic tool lists, and explicit resource selection to reduce context bloat.

The repo should not be copied as implementation code, but it should drive spec compliance checks and vocabulary across the research corpus.

## Reviewed Paths

- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/README.md`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/AGENTS.md`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/package.json`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/docs/docs.json`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/docs/docs/learn/architecture.mdx`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/docs/docs/learn/server-concepts.mdx`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/docs/docs/learn/client-concepts.mdx`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/docs/docs/learn/versioning.mdx`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/docs/docs/develop/build-server.mdx`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/docs/docs/develop/build-client.mdx`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/docs/docs/develop/connect-local-servers.mdx`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/docs/docs/develop/connect-remote-servers.mdx`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/docs/docs/develop/build-with-agent-skills.mdx`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/docs/docs/tools/inspector.mdx`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/docs/docs/tutorials/security/security_best_practices.mdx`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/docs/specification/2025-11-25/index.mdx`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/docs/specification/2025-11-25/changelog.mdx`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/docs/specification/2025-11-25/architecture/index.mdx`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/docs/specification/2025-11-25/basic/index.mdx`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/docs/specification/2025-11-25/basic/lifecycle.mdx`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/docs/specification/2025-11-25/basic/transports.mdx`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/docs/specification/2025-11-25/basic/authorization.mdx`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/docs/specification/2025-11-25/basic/utilities/cancellation.mdx`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/docs/specification/2025-11-25/basic/utilities/progress.mdx`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/docs/specification/2025-11-25/basic/utilities/tasks.mdx`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/docs/specification/2025-11-25/client/roots.mdx`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/docs/specification/2025-11-25/client/sampling.mdx`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/docs/specification/2025-11-25/client/elicitation.mdx`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/docs/specification/2025-11-25/server/resources.mdx`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/docs/specification/2025-11-25/server/tools.mdx`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/docs/specification/2025-11-25/server/prompts.mdx`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/docs/specification/2025-11-25/server/utilities/completion.mdx`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/docs/specification/2025-11-25/server/utilities/logging.mdx`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/docs/specification/2025-06-18/changelog.mdx`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/docs/specification/2025-03-26/changelog.mdx`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/docs/specification/draft/index.mdx`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/docs/specification/draft/changelog.mdx`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/docs/specification/draft/basic/transports.mdx`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/docs/specification/draft/basic/utilities/mrtr.mdx`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/docs/specification/draft/server/tools.mdx`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/schema/2025-11-25/schema.ts`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/schema/2025-11-25/schema.json`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/schema/2025-11-25/schema.mdx`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/schema/draft/schema.ts`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/schema/draft/schema.json`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/schema/draft/schema.mdx`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/schema/draft/examples/Tool/with-output-schema-for-structured-content.json`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/schema/draft/examples/CallToolResult/result-with-structured-content.json`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/schema/draft/examples/InputRequiredResult/input-required-result-with-elicitation-and-sampling-and-request-state.json`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/schema/draft/examples/CreateMessageRequestParams/request-with-tools.json`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/schema/draft/examples/ElicitRequestURLParams/elicit-sensitive-data.json`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/scripts/generate-schemas.ts`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/scripts/validate-examples.ts`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/seps/README.md`
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/plugins/mcp-spec/README.md`

## Excluded Paths

- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/.git/`: VCS internals; reviewed commit captured separately.
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/.github/`: repository automation and issue templates; not protocol behavior.
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/.claude-plugin/`: plugin packaging metadata; agent-facing plugin behavior sampled from `plugins/mcp-spec/README.md`.
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/blog/`: announcements and marketing/news content; useful history but not normative protocol source.
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/docs/images/`, `docs/logo/`, `docs/favicon.svg`, `docs/mcp.png`, `docs/style.css`: UI/static assets and screenshots; excluded as binary or presentation-only.
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/docs/footer.js`, `docs/spec-version-warning.js`: site UI helpers, not protocol semantics.
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/docs/community/`: governance/community pages; sampled via changelogs/SEP references, not needed for protocol execution path.
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/docs/seps/` and most `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/seps/*.md`: rendered/proposal history; current and draft protocol deltas reviewed through changelogs and draft spec pages.
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/docs/extensions/`: optional extension docs outside core MCP protocol primitives; noted only through draft `extensions` capability.
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/schema/2024-11-05/`, `schema/2025-03-26/`, `schema/2025-06-18/`: older generated schemas; evolution reviewed through changelog pages, current schema reviewed in depth.
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/schema/draft/examples/**` not listed above: many generated/validated examples; sampled representative tool, structured output, MRTR, sampling-tools, and URL elicitation examples.
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/package-lock.json`: generated dependency lock; verification scripts and dependency categories reviewed through `package.json`.
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/tools/sep-automation/`: SEP workflow automation, tests, and mocks; unrelated to core protocol runtime aside from governance automation.
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/typedoc.config.mjs`, `typedoc.plugin.mjs`, `tsconfig.json`, `eslint.config.mjs`, `.prettierrc.json`, `.prettierignore`, `.npmrc`, `.nvmrc`, `.gitattributes`, `.gitignore`, `.prototools`: build/lint/docs-generation configuration; sampled through `package.json` scripts.
- `/tmp/myagents-research/modelcontextprotocol-modelcontextprotocol/CODE_OF_CONDUCT.md`, `CONTRIBUTING.md`, `GOVERNANCE.md`, `LICENSE`, `MAINTAINERS.md`, `SECURITY.md`, `ANTITRUST.md`: project/legal/security reporting process; not protocol design or coding-agent execution behavior.
