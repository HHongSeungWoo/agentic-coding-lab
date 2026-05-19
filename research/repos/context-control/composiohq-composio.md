# ComposioHQ/composio

- URL: https://github.com/ComposioHQ/composio
- Category: context-control
- Stars snapshot: 28,173 (GitHub REST API repository metadata, 2026-05-12)
- Reviewed commit: 02723698b06fb7cccec9755ae8408ead1f6d419a
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong reference for agent tool context control. Composio's useful pattern is not "many integrations"; it is the session/tool-router design that keeps only a few meta-tools in the model, searches and loads schemas on demand, scopes auth/account/workbench state by session, and offers a direct-tools preset when the agent should not browse the full catalog. The hosted backend and broad defaults make it a pattern source more than a drop-in foundation for Agentic Coding Lab.

## Why It Matters

Coding agents fail when tool catalogs, auth state, execution state, and large results all compete for the same context window. Composio attacks that problem with a tool-router session: the model receives a compact meta-tool interface, asks for relevant tools by intent, gets schemas and execution guidance only when needed, can route large work into a remote workbench, and can reuse session-scoped memory across calls.

For Agentic Coding Lab, this repo is valuable because it shows a mature version of "context as runtime state" rather than "context as static prompt stuffing." The most reusable ideas are explicit session objects, lazy tool discovery, account pinning, direct narrow mode, large-output offload, and file/auth guardrails around tool execution.

## What It Is

Composio is a TypeScript and Python SDK plus CLI/docs for connecting agents to external app toolkits. The SDK exposes two main surfaces:

- Direct tool execution: fetch concrete tools with `tools.get(...)`, pass schemas to a provider, and execute a known tool slug.
- Tool Router sessions: create or reuse a session with `composio.create(userId, config)` / `composio.use(sessionId)`, expose router meta-tools, search for concrete tools at run time, manage connections, execute tools, and optionally use a sandboxed workbench.

The implementation reviewed here is client-side SDK/CLI behavior plus documentation. The catalog search, managed auth, session memory, tool execution, and workbench runtime are largely hosted Composio API behavior, so the repo reveals the integration contract and safety decisions more than the full backend internals.

## Research Themes

- Token efficiency: Tool Router sessions avoid loading the full catalog by exposing meta-tools such as search, schema retrieval, multi-execute, connection management, and workbench access. Docs recommend preloading only small known sets and keeping preloads under roughly 20 tools. The direct-tools preset disables search/multi-execute and preloads the allowed tools when the agent should stay narrow.
- Context control: Sessions carry user id, enabled/disabled toolkits, tool filters, tags, auth configs, connected-account pins, workbench settings, multi-account settings, preloaded tools, warnings, and config version. A session can be reused with `composio.use(...)`, updated, and exposed through SDK provider wrappers or MCP.
- Sub-agent / multi-agent: This is not a multi-agent orchestration framework. It supports many LLM providers, MCP clients, local custom tools, CLI scripting, and an experimental CLI sub-agent helper, but it does not provide planner/worker scheduling. Its relevant contribution is shared session/tool state that multiple agent surfaces can reuse.
- Domain-specific workflow: Toolkits, auth configs, connected accounts, ACL-aware shared accounts, raw proxy execution, custom tools, custom toolkits, and toolkit version pinning let an app build domain-specific tool surfaces without dumping unrelated schemas into the prompt.
- Error prevention: The SDK validates tool-router config with schemas, validates execution arguments, enforces toolkit version pinning for manual execution, has typed connection/auth errors, supports read-only/destructive/idempotent/open-world tag filters, and blocks sensitive local file paths for SDK auto-upload. The CLI also validates cached schemas before execution.
- Self-learning / memory: Tool Router search responses include session instructions, memory, known pitfalls, plan steps, time info, execution guidance, and workbench snippets. Docs describe shared session memory for useful IDs and relationships. This is runtime/session memory, not a repository-local learning system.
- Popular skills: The repo includes a generated Composio CLI skill source that teaches agents when to use `search`, `execute`, `link`, `proxy`, `listen`, and `run`. The skill is useful as an example of packaging a tool-specific operating procedure for coding agents, but the core research value remains the router/session contract.

## Core Execution Path

The TypeScript SDK entrypoint is `ts/packages/core/src/composio.ts`. `new Composio(...)` resolves config, creates a `ComposioClient`, and wires models for `Tools`, `ToolRouter`, `MCP`, `Toolkits`, `Triggers`, `AuthConfigs`, `Files`, and `ConnectedAccounts`. It also binds `create` and `use` to the tool-router model, making sessions the first-class high-level path.

For direct tools, `Tools.get(userId, query, options)` calls `getRawComposioTools(...)`, validates that the caller supplied a concrete selector such as tools, toolkits, search, or auth config ids, fetches matching tools from `client.tools.list(...)`, merges custom tools, optionally rewrites file schemas for auto-upload/download, applies modifiers, and delegates wrapping to the selected provider. Execution goes through `Tools.execute(...)`, which resolves the tool slug, runs before/after execution modifiers, validates parameters, and calls `client.tools.execute(...)`. Manual execution requires a toolkit version unless the caller explicitly skips the check; agentic provider wrappers skip by default to favor "latest" tools.

For dynamic context control, `ToolRouter.create(userId, config)` parses `ToolRouterCreateSessionConfigSchema`, applies direct-tools preset defaults when requested, converts camelCase config to the API payload, creates the backend session, and returns a `ToolRouterSession`. Config can include allowed/disabled toolkits, concrete tool filters, tags, auth configs, connected-account pins, managed connection behavior, workbench settings, multi-account policy, preloaded tools, and experimental local custom tools/toolkits.

`ToolRouterSession.tools()` fetches paginated session meta-tools with `Tools.getRawToolRouterSessionTools(...)`, appends preloaded local custom tools when configured, and wraps them for the provider. The default exposed router tools include search, schema retrieval, multi-execute, connection management, remote workbench, and remote bash. `session.search(...)` asks the backend for relevant concrete tools and returns schemas, guidance, known pitfalls, memory, recommended plan steps, connection statuses, next-step guidance, and workbench snippets. `session.execute(toolSlug, args, options)` executes a concrete remote tool or intercepts a local custom tool. `session.authorize(...)` links a toolkit/account to the session. `session.update(...)` patches the session and mutates local config version, warnings, and preload state.

The CLI follows the same model. It creates a short-lived tool-router session for search/execute flows, resolves auth configs and connected accounts from local caches, calls `session.search(...)` for `composio search`, writes schema caches under `~/.composio/tool_definitions`, validates inputs before `composio execute`, and stores very large outputs as artifacts instead of printing them inline.

## Architecture

The repo is organized as SDKs, provider adapters, CLI, examples, tests, and docs:

- TypeScript core implements the primary SDK abstractions: `Composio`, `Tools`, `ToolRouter`, `ToolRouterSession`, `ConnectedAccounts`, `AuthConfigs`, `MCP`, `Files`, custom tools, file modifiers, and provider interfaces.
- Python core mirrors the TypeScript surface with `Composio`, `Tools`, `ToolRouter`, `ToolRouterSession`, connected accounts, file handling, and provider wrappers.
- Provider packages convert Composio tool definitions into provider-native callable tools for OpenAI, OpenAI Agents, Anthropic, LangChain, LangGraph, LlamaIndex, Vercel AI, and others.
- The CLI wraps the same router/session model into commands for search, execute, link, proxy, listen, run, schema validation, cached connections, and local artifacts.
- Docs explain sessions, direct execution, workbench, users/sessions, tool filtering, multiple accounts, in-chat auth, MCP, toolkit versioning, proxy execution, and file handling.

The main boundary is important: the client repo does not implement the hosted search index, OAuth broker, remote session memory, or sandbox workbench runtime. Those are invoked through generated API clients. Agentic Coding Lab should copy the local contract shape, not assume the backend is inspectable here.

## Design Choices

Composio deliberately separates "agentic" and "direct" execution. Agentic sessions favor dynamic discovery, context reduction, hosted guidance, workbench offload, and managed auth. Direct execution favors fixed tool schemas, lower latency, clearer approval interception, and user-managed state.

Tool Router sessions make context control explicit. The session payload is the place where the app decides what the agent may discover, what is preloaded, which accounts are available, whether connection management is allowed, whether a workbench exists, and whether multi-account selection must be explicit.

The direct-tools preset is a useful safety valve. When `SessionPreset.DIRECT_TOOLS` is selected, the SDK defaults to `manageConnections: false`, `workbench: false`, and `preload.tools: "all"` for the allowed set, while the API payload disables search and multi-execute. That gives a narrow "known tools only" mode without requiring a separate SDK.

Tool filtering is policy-aware. The config supports toolkit allow/deny lists, concrete tool allow/deny lists, auth config ids, connected account pins, and tags for read-only, destructive, idempotent, and open-world behavior. Multi-account mode defaults to explicit account selection when enabled.

Local custom tools are integrated without pretending they are remote. The SDK maps original and final slugs, detects collisions, intercepts local custom tool execution in `ToolRouterSession`, and passes a `SessionContext` that can call sibling local tools or backend remote tools. Multi-execute splits local and remote calls, runs local work in-process, sends remote work to Composio, and merges results.

File handling is opt-in for automatic local upload/download. TypeScript auto-upload is gated by `dangerouslyAllowAutoUploadDownloadFiles`, upload directories are allowlisted by realpath boundary checks, sensitive path segments and filenames are denied by default, and a `beforeFileUpload` hook can approve or reject files. Manual `files.upload(...)` still applies sensitive path protection but intentionally skips the automatic upload directory allowlist.

Toolkit versioning is stricter for manual code than for agents. Docs and SDK code require versions for direct manual execution unless skipped, because app code may parse exact output shapes. Sessions resolve versions automatically because the agent receives live schema/guidance.

## Strengths

The meta-tool approach is the strongest context-control idea. It keeps the model interface small while still allowing discovery across a very large integration catalog.

Sessions put scattered runtime concerns behind one id: available tools, account state, auth management, workbench state, memory, warnings, and config version. That is easier for an agent system to reason about than passing large tool lists and ad hoc side-channel state through every prompt.

Composio provides both broad and narrow modes. The same API can support exploratory agents with search and workbench, or locked-down agents with direct tools and connection management disabled.

The auth/account model is practical. User ids scope connections, connected accounts can be private or shared with ACLs, sessions can pin auth configs or concrete accounts, and multi-account mode can require explicit account selection.

The workbench pattern is useful for coding agents. Large tool outputs and multi-step data processing can move into a persistent sandbox, with bash sharing the same session state, instead of bloating chat context.

The SDK has real safety hooks: schema validation, execution modifiers, version checks, file upload deny/allow controls, sensitive file path blocking, and tag-based filtering for risky tools.

The CLI makes agent operations concrete. Search stores schemas, execute validates against cached/latest schemas, dry-run exists, large outputs can become artifacts, and the generated CLI skill documents when an agent should search, execute, link, proxy, listen, or script.

## Weaknesses

The most important behavior lives behind the hosted backend. Search ranking, execution guidance, memory contents, connection management, and sandbox behavior are described and consumed by SDKs, but not fully auditable in this repo.

The default session stance is broad. Docs say a default session can discover all Composio toolkits through search. That is convenient for demos, but too permissive for coding-agent labs unless wrapped in explicit toolkit/tool/tag allowlists.

Agentic provider execution skips toolkit-version checks by default. That fits dynamic agents, but it weakens reproducibility and can hide output shape drift if an agent pipeline depends on stable tool results.

Managed in-chat connection flow is powerful but risky. Letting an agent discover a missing connection and surface connection actions is ergonomic, yet production systems need a separate user approval and policy layer for identity, account choice, and destructive scopes.

Workbench execution is a black box from this repo. It is persistent and useful, but also creates another stateful execution environment with files, packages, network access, and potentially sensitive outputs. Agentic Coding Lab would need inspectable sandbox lifecycle, quotas, and audit logs.

The SDK file upload path is fairly cautious, but the CLI upload helper reviewed reads a local file or URL and uploads via a presigned URL without obviously reusing the SDK sensitive-path denylist or upload-directory allowlist. That is a concrete safety gap to avoid copying.

Session memory can improve planning, but it can also become an implicit context source. Without visible memory summaries, retention rules, and reset controls, it is harder to debug why an agent chose a tool or reused an identifier.

## Ideas To Steal

Use a session object as the central context-control primitive. Give it an id, config version, allowed tool surface, account pins, workbench policy, preload list, warnings, and update/reuse methods.

Expose a small set of meta-tools instead of a large tool catalog: search, get schema, execute batch, manage connections, run sandbox code, and fetch guidance. Make every meta-tool operate against a session id.

Offer two modes from the same router: exploratory sessions with search/workbench and direct sessions with only preloaded tools. Make the narrow preset easy to select and visible in config.

Treat tool discovery as a retrieval result, not just a list of schemas. Return execution guidance, known pitfalls, connection status, plan steps, examples, relevant memory, and next actions alongside the schema.

Keep preload as an explicit performance tradeoff. Preload small stable tool sets; otherwise require search. Warn or reject unbounded preloads in broad contexts.

Make auth/account choice part of context policy. Support pinned accounts, aliases, shared-account ACLs, and explicit multi-account selection so the agent cannot silently choose the wrong identity.

Route local custom tools through the same session interface. Let custom tools call sibling tools and remote tools through a `SessionContext`, but keep their execution local and collision-checked.

Send large outputs to artifacts or a workbench instead of the chat transcript. The CLI's "large output to file" pattern is especially relevant for coding agents that inspect logs, API responses, or generated reports.

Apply file upload protections at every entrypoint. The SDK sensitive-path denylist, upload-directory allowlist, and approval hook are good starting points; they should also apply to CLI and any manual upload path.

Cache schemas locally for CLI/agent operation, but validate freshness before execution. Unknown top-level argument suggestions are a useful small guardrail.

## Do Not Copy

Do not default to "all toolkits discoverable" for coding agents. Start from explicit allowlists and only widen when a user or policy does so.

Do not hide search, memory, and workbench behavior behind an unaudited service if the goal is reproducible agent research. Keep ranking inputs, memory updates, and sandbox logs inspectable.

Do not let the model manage OAuth/account linking as an ordinary tool call without user-visible approval boundaries. Identity changes are policy events, not just context events.

Do not rely on latest toolkit versions for deterministic workflows. Pin versions when code parses outputs or when tests assert exact behavior.

Do not expose destructive/open-world tools through the same route as read-only tools without separate confirmation, logging, and policy checks. Tags are useful metadata, not sufficient enforcement by themselves.

Do not implement one-off file upload paths that bypass sensitive-file and allowlist checks. Every path that can read local files needs the same controls.

Do not make session memory invisible. Agents and developers need a way to inspect, summarize, clear, and diff memory state.

## Fit For Agentic Coding Lab

Composio is a high-fit reference for the context-control category. The lab should study it as a design pattern for dynamic tool context, not as a dependency decision.

The best Agentic Coding Lab adaptation would be a local, auditable tool router with:

- Explicit session manifests checked into artifacts or logs.
- Small meta-tool interface for search, schema loading, execution, and artifact/workbench operations.
- Strict allowlists by repo, task, tool category, and risk tag.
- Direct mode for known safe tools.
- Search responses that include why a tool matched and what context was used.
- Account and secret selection outside the model's unilateral control.
- Inspectable memory and sandbox state.
- Uniform file-read protections across SDK, CLI, and agent wrappers.

Composio's CLI skill source is also worth copying in spirit: package operational knowledge next to the tool so agents know when to search, when to execute, when to link, and when to script. For this project, those skills should be generated from audited command metadata plus local policy, not hand-waved docs.

## Reviewed Paths

- `README.md` for the public SDK and integration overview.
- `ts/packages/core/src/composio.ts` for SDK construction and high-level model wiring.
- `ts/packages/core/src/models/Tools.ts` for direct tool retrieval, provider wrapping, paginated session-tool retrieval, direct execution, session execution, proxy execution, and modifiers.
- `ts/packages/core/src/models/ToolRouter.ts` for session creation, direct-tools preset handling, custom tool mapping, MCP config construction, and session reuse.
- `ts/packages/core/src/models/ToolRouterSession.ts` for session tools, search, execute, authorize, toolkit status, update, local custom tools, and multi-execute routing.
- `ts/packages/core/src/types/toolRouter.types.ts` and `ts/packages/core/src/lib/toolRouterParams.ts` for session config schema, defaults, tags, workbench, multi-account, preload, direct preset, and API payload transformation.
- `ts/packages/core/src/models/ConnectedAccounts.ts`, `ts/packages/core/src/types/connectedAccounts.types.ts`, and `ts/packages/core/src/models/AuthConfigs.ts` for user/account scoping, shared-account ACLs, auth config lifecycle, tool access config, and connection linking behavior.
- `ts/packages/core/src/models/MCP.ts` for MCP server config creation, generation, update, delete, and user-scoped instance URLs.
- `ts/packages/core/src/models/SessionContext.ts`, `ts/packages/core/src/models/CustomTool.ts`, `ts/packages/core/src/models/customToolExecution.ts`, and `ts/packages/core/src/types/customTool.types.ts` for local custom tool registration, slug mapping, schema validation, and session-aware execution.
- `ts/packages/core/src/utils/modifiers/FileToolModifier.node.ts`, `ts/packages/core/src/utils/sensitiveFileUploadPaths.node.ts`, `ts/packages/core/src/utils/uploadDirAllowlist.node.ts`, `ts/packages/core/src/utils/fileUtils.node.ts`, and `ts/packages/core/src/models/Files.node.ts` for automatic upload/download behavior and file safety controls.
- `python/composio/sdk.py`, `python/composio/core/models/tools.py`, `python/composio/core/models/tool_router.py`, and `python/composio/core/models/tool_router_session.py` for parity with the TypeScript session/direct execution model.
- `ts/packages/cli/src/services/tools-executor.ts`, `ts/packages/cli/src/effects/create-tool-router-session.ts`, `ts/packages/cli/src/commands/tools/commands/tools.search.cmd.ts`, `ts/packages/cli/src/commands/tools/commands/tools.execute.cmd.ts`, `ts/packages/cli/src/services/tool-input-validation.ts`, `ts/packages/cli/src/services/tool-file-uploads.ts`, and `ts/packages/cli/skills-src/composio-cli/index.ts` for CLI session creation, meta-tool execution, schema caching, input validation, large output handling, file upload behavior, and generated agent skill content.
- `docs/content/docs/tools-and-toolkits.mdx`, `docs/content/docs/configuring-sessions.mdx`, `docs/content/docs/sessions-vs-direct-execution.mdx`, `docs/content/docs/users-and-sessions.mdx`, `docs/content/docs/workbench.mdx`, `docs/content/docs/managing-multiple-connected-accounts.mdx`, `docs/content/docs/authenticating-users/in-chat-authentication.mdx`, `docs/content/docs/toolkits/enable-and-disable-toolkits.mdx`, `docs/content/docs/tools-direct/fetching-tools.mdx`, `docs/content/docs/tools-direct/executing-tools.mdx`, `docs/content/docs/tools-direct/toolkit-versioning.mdx`, `docs/content/reference/meta-tools/index.mdx`, and `docs/content/docs/single-toolkit-mcp.mdx` for documented behavior and tradeoffs.
- `ts/packages/core/test/models/toolRouter.test.ts`, `ts/packages/core/test/models/customToolRouting.test.ts`, `ts/packages/core/test/utils/sensitiveFileUploadPaths.test.ts`, `ts/packages/core/test/utils/uploadDirAllowlist.test.ts`, `python/tests/test_connected_accounts.py`, and `python/tests/test_tool_execution.py` for behavioral coverage around sessions, custom tools, file safety, shared-account ACLs, and paginated meta-tool retrieval.
- `ts/examples/tool-router/**`, `python/examples/tool_router/**`, and `ts/examples/session-management/README.md` for expected session, preload, direct preset, update, and file workflows.

## Excluded Paths

- `docs/public/images/**`, `docs/public/images/templates/**`, `docs/public/*.png`, videos, GIFs, and other binary media: documentation assets, not execution or context-control logic.
- `docs/app/**`, `docs/components/**`, and most docs styling/navigation code: UI shell for documentation, not SDK/tool-router behavior.
- `docs/public/openapi-v3.json`, `docs/public/data/toolkits*.json`, and generated catalog JSON: large generated API/catalog data useful for docs rendering but not needed to understand the router design. Meta-tool reference pages were treated as generated wrappers and only the index-level summary was reviewed.
- Lockfiles and package manager metadata such as `pnpm-lock.yaml`, `uv.lock`, and workspace release/config files: dependency resolution and release mechanics, not agent context-control behavior.
- `.github/**`, `.changeset/**`, CI, release automation, and repository maintenance scripts: operational project plumbing outside the agent execution path.
- Provider packages beyond the OpenAI/OpenAI Agents wrapping pattern: most adapters repeat schema-to-provider conversion and do not change the context-control design.
- UI-only examples, generated test snapshots, recordings, fixtures, and visual assets: not relevant to tool discovery, auth/session management, sandbox/workbench behavior, or safety guardrails.
