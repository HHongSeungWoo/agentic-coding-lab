# ruvnet/ruflo

- URL: https://github.com/ruvnet/ruflo
- Category: mcp
- Stars snapshot: 48,864 (GitHub REST API, captured 2026-05-11)
- Reviewed commit: a03f6f6ed939659784dc1f35916351f06b74aa92
- Reviewed at: 2026-05-11T23:45:55+09:00
- Status: reviewed
- Scope fit: conditional
- Verdict: Strongly in-scope as an MCP-first orchestration and agent support system, but only conditionally useful as an execution substrate. Ruflo is best mined for tool registry design, persistent coordination state, memory/context plumbing, plugin contracts, and verification gates. Do not treat it as proof that a swarm engine executes coding work by itself; the main path is a ledger and control plane that delegates real work to Claude Code tasks, headless Claude/Codex, or a narrow `agent_execute` API path.

## Why It Matters

Ruflo is a very large, popular MCP/orchestration codebase that tries to package the full agent support stack: CLI install, MCP tools, Claude plugin hooks, agent and swarm state, workflows, persistent memory, guidance/gates, browser/agentdb/wasm integrations, and CI verification. That makes it useful for studying how a coding-agent platform can expose many capabilities through MCP while keeping install and plugin surfaces separate.

The main lesson is structural honesty. The repository repeatedly frames `claude-flow`/Ruflo as the ledger or orchestrator, while Claude Code, Task tools, headless CLI, Codex, or provider APIs perform the actual code work. The strongest parts are the explicit state stores, tool descriptions, initialization paths, and tests that audit drift. The weakest parts are the huge marketing surface, duplicated server abstractions, uneven wiring between guidance/security modules and the default MCP path, and several smoke tests that are static or advisory rather than full live round trips.

## What It Is

Ruflo is the rebranded package around a `claude-flow` v3 monorepo. The root package still publishes the `claude-flow` binary, while `ruflo/package.json` publishes the `ruflo` binary and wraps the `@claude-flow/cli` implementation. The default user paths are:

1. Claude Code plugin install: slash commands, skills, agents, and hooks only. The README says this path intentionally does not register an MCP server or write project files.
2. CLI install/init: `npx ruflo init` creates project files such as `.claude/`, `.claude-flow/`, `CLAUDE.md`, settings, hooks, and MCP config. The canonical MCP registration is `claude mcp add ruflo -- npx ruflo@latest mcp start`.
3. MCP server mode: the CLI starts a stdio JSON-RPC MCP server and exposes a large tool registry from `v3/@claude-flow/cli/src/mcp-client.ts`.
4. Web/UI bridge mode: `ruflo/src/mcp-bridge` can aggregate multiple MCP backends behind an Express service for the bundled web UI and hosted/self-hosted chat flows.

The repository also contains a standalone `@claude-flow/mcp` package with a more generic MCP server, session manager, schema-validating tool registry, HTTP transport, auth hooks, and rate limiting. The main CLI stdio server does not appear to use that generic registry for its normal `ruflo mcp start` tool execution path.

## Research Themes

- Token efficiency: Moderate. Tool descriptions are audited for "Use when..." guidance, plugin skills try to route users to specialized commands, and guidance retrieval can recommend concise workflows. There is no central token-budget controller on the default CLI MCP call path. The `@claude-flow/guidance` gateway has budgets, gates, and evidence tracking, but I did not find it wired as the central enforcement layer for `mcp-client.ts`.
- Context control: Strong. Memory defaults to `.swarm/memory.db`, migrates older `.claude-flow/memory/store.json`, validates key/query sizes, supports semantic search fallback paths, and reserves a `claude-memories` namespace through the RAG memory plugin. The guidance package adds retrieval, ledgers, gates, and hook integration. Context is mostly controlled by tool conventions and hooks rather than a single mandatory runtime.
- Sub-agent / multi-agent: Strong as coordination state, conditional as execution. `agent_spawn`, `swarm_init`, `task_create`, and workflow tools create durable records and routing metadata. Actual agent work happens through Claude Code Task tools, headless `claude -p`, external MCP backends, or `agent_execute`. The `agent_execute` path makes a direct Anthropic Messages API call and requires `ANTHROPIC_API_KEY`.
- Domain-specific workflow: Strong. Workflows, plugins, slash commands, hooks, ADMs/ADRs, and marketplace metadata encode domain workflows. `workflow_execute` can run sequential `task`, `wait`, and simple `condition` steps, but `parallel` and `loop` are explicitly skipped with notes in the reviewed implementation.
- Error prevention: Strong but unevenly attached. There are validation helpers, safe JSON parsing, restricted file writes, hook-level bash safety, secret detection, optional encryption-at-rest, tool description audits, witness verification, and security/honesty tests. The strongest enforcement appears in hooks/guidance/shared packages, while the core CLI MCP registry relies on each tool handler for validation.
- Self-learning / memory: Strong. Memory schema includes entries, patterns, pattern history, trajectories, sessions, embeddings, and fallback search paths. `v3/@claude-flow/cli/src/memory/intelligence.ts` implements local signal buffers, trajectories, and ReasoningBank-style pattern persistence.
- Popular skills: Strong as a pattern library. The repo ships many `.claude` agents, commands, plugin skills, hooks, and marketplace entries. These are useful examples for packaging agent workflows, but many are prompt/control artifacts rather than executable runtime logic.

## Core Execution Path

The normal command entry is thin. Root `bin/cli.js` delegates to `v3/@claude-flow/cli/bin/cli.js`. `ruflo/bin/ruflo.js` locates installed `@claude-flow/cli` or the local v3 package and then either imports the CLI directly for non-TTY/explicit `mcp start`, or constructs the CLI with the `ruflo` name and description for interactive use.

The MCP stdio path is:

1. `ruflo mcp start` or equivalent launches the v3 CLI MCP server.
2. `v3/@claude-flow/cli/src/mcp-server.ts` starts a newline-delimited JSON-RPC server on stdin/stdout, initializes memory first, returns protocol version `2024-11-05`, and exposes `tools/list` plus `tools/call`.
3. `tools/list` is populated from `v3/@claude-flow/cli/src/mcp-client.ts`, which concatenates tool arrays from agent, swarm, memory, task, workflow, hooks, session, hive-mind, analysis, progress, embeddings, claims, security, transfer, system, terminal, neural, performance, GitHub, DAA, browser, agentdb, wasm, guidance, and autopilot modules.
4. `tools/call` looks up the handler by name and calls it. There is no single central JSON Schema validation pass in this path; validation is implemented in individual handlers and shared helper modules.
5. Orchestration tools persist state under local files such as `.claude-flow/agents/store.json`, `.claude-flow/tasks/store.json`, `.claude-flow/workflows/store.json`, `.claude-flow/swarm/swarm-state.json`, and `.swarm/memory.db`.

Agent execution is narrower than the tool count suggests. `agent_spawn` validates the request, selects a model through explicit config, enhanced model routing, or agent-type defaults, and creates an agent record. Its response explicitly points users to one of three execution paths: `agent_execute`, the Claude Code Task tool, or headless `claude -p`. `agent_execute` calls `executeAgentTask`, which updates local agent state and sends a direct Anthropic Messages API request. A separate `callAnthropicMessages` helper contains Anthropic/Ollama fallback logic, but the reviewed `executeAgentTask` path does not use it.

Workflow execution is partly real. `workflow_run` creates workflow state from templates or files. `workflow_execute` walks steps, executes `task` steps through `executeAgentTask` when an `agentId` or default agent exists, implements `wait`, and supports simple equality conditions. `parallel` and `loop` steps are skipped with explicit result notes rather than silently faked.

The web bridge path is separate. `ruflo/src/mcp-bridge/index.js` launches or connects to stdio MCP backend processes such as `ruvector`, `ruflo`, `agentic-flow`, `claude mcp serve`, `gemini-mcp-server`, and `@openai/codex mcp serve`, namespaces external tools, filters by configured groups, and exposes built-in `search`, `web_research`, and `guidance` tools. `ruflo/src/mcp-bridge/mcp-stdio-kernel.js` tunnels stdio calls to the bridge and signs requests only when `RVF_KERNEL_SECRET` is configured.

## Architecture

The repository has several overlapping layers:

- Root package: `package.json`, `bin/cli.js`, README, plugin metadata, and compatibility branding.
- Ruflo wrapper package: `ruflo/package.json`, `ruflo/bin/ruflo.js`, web UI config, and MCP bridge code.
- V3 monorepo: `v3/package.json` with workspaces such as `@claude-flow/cli`, `@claude-flow/mcp`, `@claude-flow/guidance`, `@claude-flow/shared`, memory/neural/browser-related packages, and tests.
- CLI MCP layer: `v3/@claude-flow/cli/src/mcp-server.ts`, `mcp-client.ts`, and `mcp-tools/*`.
- Generic MCP package: `v3/@claude-flow/mcp/src/server.ts`, `tool-registry.ts`, transports, session manager, resources, prompts, tasks, sampling, OAuth, and auth/rate limiting helpers.
- Guidance layer: `v3/@claude-flow/guidance/src/*` for deterministic gateways, gates, retrievers, hooks, ledgers, workflows, and context bundles.
- Plugin layer: `.claude-plugin/marketplace.json`, `plugins/ruflo-*`, hook JSON, ADRs, skills, and smoke scripts.
- Verification layer: `v3/@claude-flow/cli/__tests__`, `v3/__tests__/honesty`, `.github/workflows/v3-ci.yml`, `plugins/ruflo-core/scripts/*`, `scripts/audit-tool-descriptions.mjs`, and signed witness manifests under `verification/`.

There are two MCP server concepts to keep separate. The default Ruflo CLI stdio server is a pragmatic JSON-RPC wrapper around the CLI tool registry. The standalone `@claude-flow/mcp` package is a cleaner reusable MCP framework with schemas, sessions, rate limits, resources, prompts, tasks, sampling, and HTTP/stdio transports. The default CLI path does not appear to inherit all those generic protections.

## Design Choices

Ruflo favors breadth and plugin packaging over a small core. The registry exposes a very large tool surface and leans on "Use when..." descriptions plus CI audits to keep tool choices navigable.

Coordination is file-backed and inspectable. Agents, swarms, tasks, workflows, sessions, and memory all persist into local project state, which is good for coding-agent transparency and resume behavior. The cost is a lot of migration and stale-state logic.

The codebase separates ledger and executor responsibilities in the better-documented paths. The AGENTS guidance says `claude-flow = LEDGER`, and CLI output points users to Claude Code Task, headless Claude, hive-mind, or provider calls for real execution.

Security is layered but not uniform. Shared validation, safe filesystem writes, hook safety, guidance gates, optional encryption, OAuth modules, bearer auth, and rate limiting exist. Some of those are only active in specific transports or hooks. The generic HTTP MCP transport permits unauthenticated access when auth config is not supplied; this is reasonable for local dev but important for deployment.

Verification mixes strong and weak gates. Witness manifests, security source tests, tool description audits, and protocol string checks catch drift. Some "roundtrip" and protocol tests are static scans or advisory probes, so they should not be read as full live MCP integration coverage.

## Strengths

The repo gives a concrete model for exposing a large agent platform through MCP while keeping every tool addressable and documented.

Memory and context persistence are among the better patterns to steal: one default memory root, legacy migration, semantic fallback chains, reserved namespaces, trajectory/pattern tables, and strict key/value size checks.

The workflow implementation is more honest than many orchestration repos. Unsupported step types are reported as skipped, not fabricated as successful.

The plugin contract work is useful. `ruflo-core`, `ruflo-workflows`, and `ruflo-rag-memory` include ADR-style contracts and smoke scripts, which gives a way to govern plugin behavior beyond prompt text.

The verification suite has good "drift guard" ideas: signed witness manifests, tool description baselines, no-random-metrics honesty checks, static source checks for security regressions, and install smoke paths without optional native dependencies.

The CLI init path distinguishes plugin-only install from MCP-enabled project init. That reduces accidental project mutation for users who only want slash commands and skills.

## Weaknesses

The product surface is much larger than the proven execution core. There are many agents, tools, plugins, claims, and integrations, but the core execution path often records state and delegates work elsewhere.

There is duplicated MCP architecture. The CLI stdio server and generic `@claude-flow/mcp` package have different protocol versions and different validation/enforcement behavior, which makes it easy to overstate what protections are active in the default path.

`agent_execute` is less flexible than nearby code suggests. The file contains an Anthropic/Ollama fallback helper, but the real `executeAgentTask` path directly requires `ANTHROPIC_API_KEY` and calls Anthropic.

Security and guidance controls are not consistently central. Guidance gates and deterministic budgets are well-designed, but the default `mcp-client.ts` dispatcher does not appear to route every tool call through that gateway.

Several tests are not true live integration tests. The MCP protocol smoke checks built files for protocol strings, and some roundtrip behavior is advisory. Integration tests in other areas use simulations or generated metrics, so only the source-level guards should be treated as strong evidence.

Branding and compatibility layers add confusion. Root files still use `claude-flow`, the Ruflo wrapper points into v3, `.claude-plugin/plugin.json` still references old `claude-flow@alpha`, and multiple plugin/hook trees coexist.

## Ideas To Steal

Use a single MCP registry module that aggregates tool families and makes tool discovery auditable.

Audit tool descriptions in CI for actionable "Use when..." phrasing, minimum detail, and duplicate descriptions.

Persist orchestration as inspectable local state instead of hiding it inside process memory. Agents, tasks, swarms, workflows, and memory should have stable stores and status tools.

Treat orchestration as a ledger unless the code really executes. Explicitly tell callers which path performs work: native task tool, headless CLI, provider API, or external MCP backend.

Build memory with migrations and fallbacks: default local DB, legacy import, semantic search fallback, strict size limits, and named namespaces for imported memories.

Add witness-style verification for generated or plugin-installed artifacts. Signed manifests and marker checks are useful when install flows create many files.

Keep unsupported workflow semantics explicit. Returning "skipped: parallel not implemented" is much better than pretending a complex branch executed.

## Do Not Copy

Do not copy the giant all-in-one tool surface without an equally strong routing and validation story. A smaller MCP registry with clearer execution guarantees would be easier to trust.

Do not split MCP enforcement across multiple server abstractions unless the default user path clearly inherits the strictest one.

Do not market state creation as execution. `agent_spawn`, `swarm_init`, and `workflow_run` should be named and documented as planning/state operations unless they actually run work.

Do not rely on static protocol scans as proof of live MCP compatibility. They are useful drift guards but not enough.

Do not ship unauthenticated HTTP MCP outside localhost/dev assumptions. If the bridge or generic HTTP transport is exposed, auth and origin rules need to be mandatory.

Do not copy stale compatibility branding. The mixed `claude-flow` and `ruflo` naming makes entrypoint and support boundaries harder to audit.

## Fit For Agentic Coding Lab

Fit is conditional but high-value for research. Ruflo is a strong candidate for studying MCP orchestration, local memory, plugin contracts, hook safety, and verification around agent support systems. It is not a clean minimal runtime to adopt wholesale.

For a coding-agent lab, the most applicable pieces are:

- MCP tool registry shape and CI audits for descriptions.
- Durable coordination state for agents, tasks, workflows, sessions, and swarms.
- Memory schema, migration, and semantic fallback design.
- Plugin marketplace contracts, hook smoke tests, and ADR-per-plugin documentation.
- Guidance gates and bash/file safety as patterns to centralize in our own dispatcher.
- Honest workflow semantics and "ledger not executor" framing.

Adoption should avoid the broad marketing layer, UI-heavy assets, duplicated MCP implementations, and any assumption that a swarm record means real code execution happened.

## Reviewed Paths

- Repository metadata and install surface: `README.md`, `AGENTS.md`, `SECURITY.md`, `package.json`, `ruflo/package.json`, `v3/package.json`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`.
- CLI entrypoints: `bin/cli.js`, `bin/npx-safe-launch.js`, `ruflo/bin/ruflo.js`, `v3/@claude-flow/cli/bin/cli.js`.
- MCP server and registry path: `v3/@claude-flow/cli/src/mcp-server.ts`, `v3/@claude-flow/cli/src/mcp-client.ts`, representative `v3/@claude-flow/cli/src/mcp-tools/*.ts`, especially agent, swarm, task, workflow, memory, guidance, security, hooks, embeddings, progress, session, browser, agentdb, and autopilot tools.
- Agent execution path: `v3/@claude-flow/cli/src/mcp-tools/agent-tools.ts`, `v3/@claude-flow/cli/src/mcp-tools/agent-execute-core.ts`.
- Swarm/task/workflow path: `v3/@claude-flow/cli/src/mcp-tools/swarm-tools.ts`, `task-tools.ts`, `workflow-tools.ts`, `v3/@claude-flow/cli/src/commands/swarm.ts`.
- Memory/context path: `v3/@claude-flow/cli/src/mcp-tools/memory-tools.ts`, `v3/@claude-flow/cli/src/memory/memory-initializer.ts`, `v3/@claude-flow/cli/src/memory/intelligence.ts`, `v3/@claude-flow/cli/src/fs-secure.ts`, `plugins/ruflo-rag-memory/docs/adrs/0001-rag-memory-contract.md`.
- Guidance/security path: `v3/@claude-flow/guidance/src/gateway.ts`, `gates.ts`, `hooks.ts`, `workflows.ts`, `v3/@claude-flow/cli/src/commands/guidance.ts`, `v3/@claude-flow/cli/src/mcp-tools/guidance-tools.ts`, `v3/@claude-flow/shared/src/security/input-validation.ts`, `v3/@claude-flow/shared/src/hooks/safety/bash-safety.ts`, `v3/@claude-flow/cli/src/autopilot-state.ts`.
- Generic MCP package: `v3/@claude-flow/mcp/src/server.ts`, `tool-registry.ts`, `session-manager.ts`, `transport/stdio.ts`, `transport/http.ts`, `auth.ts`, `oauth.ts`, resources/prompts/tasks/sampling modules.
- Init/config/plugin path: `v3/@claude-flow/cli/src/commands/init/*`, `v3/@claude-flow/cli/src/config/*`, `plugins/ruflo-core/hooks/hooks.json`, `plugins/ruflo-workflows/docs/adrs/0001-workflows-contract.md`.
- Web bridge path: `ruflo/src/mcp-bridge/index.js`, `ruflo/src/mcp-bridge/mcp-stdio-kernel.js`, `ruflo/src/config/config.example.json`.
- Verification path: `.github/workflows/v3-ci.yml`, `v3/@claude-flow/cli/__tests__/mcp-tools-deep.test.ts`, `v3/@claude-flow/cli/__tests__/mcp-client.test.ts`, `v3/@claude-flow/cli/__tests__/security-verification.test.ts`, `v3/__tests__/honesty/tool-honesty.test.ts`, `scripts/audit-tool-descriptions.mjs`, `plugins/ruflo-core/scripts/test-mcp-protocol.mjs`, `plugins/ruflo-core/scripts/test-mcp-roundtrips.mjs`, `plugins/ruflo-core/scripts/witness/verify.mjs`, `verification/CAPABILITIES.md`.

## Excluded Paths

- Generated/build outputs: package `dist/` directories, generated JavaScript declaration/map files, and WASM package outputs such as `v3/@claude-flow/guidance/wasm-pkg/*`. Rationale: source TypeScript and test scripts were reviewed instead.
- Binary and visual assets: `*.gif`, `*.png`, `*.jpg`, `*.jpeg`, static web assets, screenshots, and UI-only media. Rationale: not relevant to MCP/orchestration except where the MCP bridge code itself was reviewed.
- Lockfiles: `package-lock.json`, `pnpm-lock.yaml`, and `v3/pnpm-lock.yaml`. Rationale: useful for dependency pinning, but not needed to understand execution paths beyond package metadata and imports.
- Exhaustive prompt packs: most `.claude/commands`, `.claude/agents`, `.agents/skills`, and generated plugin prompt files. Rationale: sampled as packaging artifacts; deep review focused on runtime MCP, hooks, memory, workflows, and tests.
- Domain/demo plugin bodies: market-data, neural-trader, IoT/Cognitum, and similar domain packs. Rationale: marketplace and ADR conventions were sampled, but these are not central to MCP orchestration or coding-agent applicability.
- UI application internals outside the MCP bridge and config. Rationale: the task focus is MCP/orchestration, not front-end implementation.
- External dependency source: `@claude-flow/cli-core`, optional packages, and npm dependencies not vendored in this repo. Rationale: reviewed local shims and call sites; external package internals are out of repo scope.
- Historical or stale reports: old implementation security summaries and compatibility notes were treated as context only when they conflicted with current code paths. Rationale: the reviewed commit and live source are authoritative for this note.
