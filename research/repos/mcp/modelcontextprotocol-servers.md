# modelcontextprotocol/servers

- URL: https://github.com/modelcontextprotocol/servers
- Category: mcp
- Stars snapshot: 85,413 (GitHub REST API, captured 2026-05-11)
- Reviewed commit: 4503e2d12b799448cd05f789dd40f9643a8d1a6c
- Reviewed at: 2026-05-11
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong reference corpus for MCP server construction, especially stdio packaging, tool annotations, roots-based filesystem access, resource/prompt boundaries, and CI/release layout. It is explicitly educational and not production-ready; use patterns selectively, with stronger security wrappers for network, env, git, and write-capable tools.

## Why It Matters

This is the official MCP reference server collection maintained by the MCP steering group. It no longer serves as the broad third-party server catalog; that moved to the MCP Registry. The current repo matters because it shows concrete server patterns across TypeScript and Python, with examples for tools, resources, prompts, roots, subscriptions, task flows, structured content, and packaging.

For coding agents, it is most useful as a pattern library: how to expose a narrow capability over MCP, how to advertise read/write/destructive hints, how to bind tools to client-provided roots, and how to test protocol adapters without building a full product.

## What It Is

The repository is a monorepo of seven reference MCP servers:

- `everything`: TypeScript protocol exercise server covering tools, prompts, resources, subscriptions, logging, roots, sampling, elicitation, tasks, stdio, SSE, and Streamable HTTP.
- `filesystem`: TypeScript file operation server with command-line and MCP Roots allowlists.
- `memory`: TypeScript local JSONL knowledge graph server.
- `sequentialthinking`: TypeScript single-tool reasoning trace server.
- `fetch`: Python web fetch and HTML-to-markdown server.
- `git`: Python Git repository operation server.
- `time`: Python timezone and conversion server.

Root docs warn that these are reference implementations for SDK/protocol education, not production-ready services. Contribution policy now accepts bug fixes, usability improvements, and protocol-feature demonstrations, but directs new server implementations and third-party listings to the MCP Registry.

## Research Themes

- Token efficiency: Good examples. `fetch` truncates output with `start_index`, `filesystem` offers `head`/`tail`, search, directory tree, and multi-file reads, and `everything` demonstrates resource links instead of always inlining blobs.
- Context control: Strong. Roots constrain filesystem scope, `memory` separates whole-graph reads from node search/open calls, `fetch` separates autonomous tool fetch from user-initiated prompt fetch, and `everything` shows session-scoped resources/subscriptions.
- Sub-agent / multi-agent: Limited. `everything` supports multi-client sessions and task APIs, but no agent orchestration or delegation framework.
- Domain-specific workflow: Strong. Each server maps one domain to MCP primitives: filesystem, git, web fetch, time, memory, reasoning, and protocol feature testing.
- Error prevention: Strong in `filesystem` and `git` through path validation, symlink checks, tool annotations, and argument-injection tests. Weaker in `fetch` and `everything`, where network/env exposure remains intentionally demonstrative.
- Self-learning / memory: Present in `memory`, but basic. It persists entities, relations, and observations to JSONL without privacy, consent, merge, TTL, provenance, or conflict controls.
- Popular skills: Not a Codex/Claude skill repo. It includes `.mcp.json` for MCP docs and a root `CLAUDE.md` telling Claude Code to use the MCP docs server, but the reusable artifacts are MCP servers, not prompt skills.

## Core Execution Path

TypeScript servers use `@modelcontextprotocol/sdk` and `StdioServerTransport` by default. Each package builds `src/*/*.ts` to `dist`, exposes an npm binary, and can run through `npx`, Docker, or client config. `filesystem`, `memory`, and `sequentialthinking` create an `McpServer`, register tools with Zod schemas, connect over stdio, and emit startup logs on stderr.

`filesystem` starts from allowed directories passed as CLI args, normalizes/realpaths them, skips inaccessible entries, and sets them into shared validation state. Every operation calls `validatePath`, which expands `~`, resolves relative paths against allowed directories, rejects paths outside allowlists, resolves symlink targets, and validates parents for new files. If the client supports MCP Roots, `oninitialized` calls `roots/list` and replaces the allowed directory set; `roots/list_changed` refreshes it at runtime.

`memory` resolves `MEMORY_FILE_PATH` or defaults to `memory.jsonl` beside the package, migrating legacy `memory.json` when needed. Tool calls load the full JSONL graph, mutate entities/relations/observations in memory, and rewrite the file. Search and open operations return matching entities plus connected relations.

`sequentialthinking` registers one read-only/idempotent tool. It stores thought history and branches in process memory, optionally logs thoughts to stderr, and returns only counters/branch IDs in structured output.

`everything` is the main protocol showcase. `index.ts` dynamically selects `stdio`, deprecated `sse`, or `streamableHttp`. `createServer()` advertises tools/prompts/resources/logging/tasks, loads instruction docs, registers standard tools/resources/prompts immediately, then registers capability-gated tools after initialization. It demonstrates resource templates, file resources, session resources, subscriptions, simulated logging, roots, sampling, elicitation, progress notifications, and task lifecycle.

Python servers use the lower-level `mcp.server.Server` API with `stdio_server()`. `fetch` lists one `fetch` tool plus a `fetch` prompt; tool calls obey robots.txt by default and use the autonomous user-agent, while prompt calls skip robots gating and use the manual user-agent. `git` lists Git tools with annotations, optionally scopes all requested repo paths under `--repository`, discovers client roots, and calls GitPython. `time` lists two read-only tools for current time and timezone conversion.

## Architecture

The monorepo is intentionally flat:

- Root `package.json` defines npm workspaces for TypeScript packages and broad scripts for build/watch/publish.
- Each TypeScript server is independently versioned, tested with Vitest, and published as an npm package.
- Each Python server has its own `pyproject.toml`, `uv.lock`, tests, Dockerfile, and PyPI script entry point.
- `.github/workflows/typescript.yml` detects package.json files under `src`, runs `npm ci`, `npm test --if-present`, and `npm run build` per package, then publishes on releases.
- `.github/workflows/python.yml` detects pyproject packages, runs `uv sync`, pytest when present, pyright, `uv build`, and PyPI trusted publishing.
- `.github/workflows/release.yml` periodically generates release metadata from changed packages, updates versions, tags releases, and publishes changed npm/PyPI packages.

The most reusable server architecture is in `everything`: server factory, transport adapters, registration index files, feature-specific modules, and session cleanup. `filesystem` is the best security architecture: central path validation and shared allowed-directory state, with all tools forced through that layer.

## Design Choices

The repo chooses small single-purpose servers over one gateway. This keeps each MCP surface easy to inspect and install, but means shared concerns such as auth, policy, rate limits, and audit are not centralized.

Tool annotations are treated as protocol-facing UX. `filesystem`, `git`, `time`, and `sequentialthinking` mark read-only, idempotent, destructive, and open-world behavior so clients can guide approval and display risk.

`everything` cleanly separates tools, prompts, and resources. It shows when to return text, structured content, resource links, inline resources, annotations, progress, logs, and subscriptions. It also shows capability-gated registration, because sampling, elicitation, and roots are only useful when the client advertises support.

Install UX favors direct package runners: `npx` for TypeScript, `uvx` for Python, with pip and Docker alternatives. READMEs include Claude Desktop JSON, VS Code one-click install links, Windows `cmd /c` npx wrappers, and some Zed/Zencoder/Codex examples.

The maintenance model now treats this repository as a small official reference set. Third-party lists and many older servers were moved to `servers-archived`; README and PR workflows direct new discovery submissions to the MCP Registry.

## Strengths

The reference servers are small enough to audit. A coding-agent team can read a full server, its tests, install docs, and package metadata in one sitting.

`filesystem` has practical defense-in-depth: allowed roots, symlink resolution, parent validation for new files, prefix-vulnerability tests, Windows/WSL path handling, and dry-run diffs for edits.

`git` now has meaningful safety tests for repo scoping and flag/argument injection across diff, checkout, show, branch creation, log dates, and branch filters.

`everything` is a compact protocol conformance playground. It covers primitives that many real MCP servers skip: resources, prompts, completions, annotations, roots, subscriptions, progress, tasks, logging, and multi-client transports.

CI is broad for a reference repo. TypeScript packages are tested and built; Python packages run pytest, pyright, and builds; releases are package-diff driven.

Install docs are pragmatic across clients and platforms. The Windows npx wrapper and VS Code MCP JSON examples reduce common setup failures.

## Weaknesses

The repo explicitly disclaims production readiness and says the repository itself is not eligible for security vulnerability reporting. That is a poor fit for directly adopting these servers in sensitive environments.

`fetch` warns it can access local/internal IPs. It obeys robots.txt by default but does not implement SSRF protections such as private IP denylisting, DNS rebinding defense, content-type allowlists, or auth-bound fetch policy.

`everything` includes deliberately unsafe demo surfaces: `get-env` returns all environment variables, HTTP/SSE examples use permissive CORS for Inspector testing, and `gzip-file-as-resource` allows all HTTP(S) domains unless an allowlist env var is set.

`memory` is too naive for durable agent memory. It rewrites a local JSONL file with no concurrency control, no encryption, no provenance, no user consent boundaries, no TTL, and no schema migrations beyond a filename migration.

Docker images demonstrate packaging but not hard isolation. They do not consistently set a non-root runtime user, read-only filesystem, seccomp, network policy, or mount policy.

`sequentialthinking` may encourage externalized chain-of-thought logs. It supports `DISABLE_THOUGHT_LOGGING`, but the default logs thoughts to stderr, which is risky in shared agent infrastructure.

## Ideas To Steal

Use MCP tool annotations everywhere, especially on write-capable coding tools. Clients need `readOnlyHint`, `idempotentHint`, and `destructiveHint` to make permission UX sane.

Adopt the `filesystem` roots pattern: start with explicit allowed directories, accept MCP Roots when available, refresh on `roots/list_changed`, and reject operation if no valid roots exist.

Put all path and permission checks in one shared validation layer. Every tool should call it before touching the filesystem.

Model rich outputs with resources and `structuredContent`, not only giant text blobs. Use resource links for generated artifacts and inline resources only when small enough.

Gate optional tools by client capabilities after initialization. Do not register sampling, elicitation, roots, or task tools blindly.

Mirror the install documentation pattern: `npx`/`uvx`, Docker, Claude Desktop JSON, VS Code config, Windows-specific command wrappers, and inspector/debug commands.

Copy the CI package-detection pattern for mixed monorepos. Dynamic matrices keep reference packages independent while still enforcing tests/builds.

## Do Not Copy

Do not expose environment dumping tools outside a demo server.

Do not ship web-fetch tools without SSRF controls, domain policy, size/time limits, and clear user-vs-model initiation semantics.

Do not treat local JSONL graph memory as production agent memory without consent, privacy, provenance, conflict resolution, and concurrency handling.

Do not rely on tool annotations as security boundaries. They are hints to clients, not enforcement.

Do not publish write-capable Git/filesystem tools without external sandboxing and human approval gates.

Do not copy permissive CORS HTTP examples into deployed remote MCP servers.

## Fit For Agentic Coding Lab

Fit is in-scope and strong as reference material. The best adoption target is not the whole server set, but selected patterns: roots-driven filesystem scope, narrow tool schemas, annotations, structured/resource outputs, capability-gated tools, and dynamic CI verification.

For Agentic Coding Lab, `filesystem` and `git` are the most directly relevant coding-agent adapters. They show both the power and risk of exposing local project state. `everything` is useful as a test harness for MCP client behavior and for designing richer output channels. `fetch`, `memory`, and `sequentialthinking` are useful cautionary examples: valuable capabilities, but dangerous if copied without policy and privacy controls.

## Reviewed Paths

- `/tmp/myagents-research/modelcontextprotocol-servers/README.md`
- `/tmp/myagents-research/modelcontextprotocol-servers/CONTRIBUTING.md`
- `/tmp/myagents-research/modelcontextprotocol-servers/SECURITY.md`
- `/tmp/myagents-research/modelcontextprotocol-servers/CLAUDE.md`
- `/tmp/myagents-research/modelcontextprotocol-servers/.mcp.json`
- `/tmp/myagents-research/modelcontextprotocol-servers/package.json`
- `/tmp/myagents-research/modelcontextprotocol-servers/.github/pull_request_template.md`
- `/tmp/myagents-research/modelcontextprotocol-servers/.github/workflows/typescript.yml`
- `/tmp/myagents-research/modelcontextprotocol-servers/.github/workflows/python.yml`
- `/tmp/myagents-research/modelcontextprotocol-servers/.github/workflows/release.yml`
- `/tmp/myagents-research/modelcontextprotocol-servers/.github/workflows/readme-pr-check.yml`
- `/tmp/myagents-research/modelcontextprotocol-servers/.github/workflows/claude.yml`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/everything/README.md`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/everything/docs/architecture.md`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/everything/docs/features.md`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/everything/docs/how-it-works.md`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/everything/docs/startup.md`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/everything/docs/extension.md`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/everything/docs/structure.md`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/everything/package.json`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/everything/index.ts`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/everything/server/index.ts`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/everything/server/roots.ts`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/everything/resources/session.ts`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/everything/resources/subscriptions.ts`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/everything/transports/stdio.ts`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/everything/transports/sse.ts`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/everything/transports/streamableHttp.ts`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/everything/tools/index.ts`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/everything/tools/get-env.ts`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/everything/tools/gzip-file-as-resource.ts`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/everything/__tests__/server.test.ts`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/everything/__tests__/registrations.test.ts`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/everything/__tests__/tools.test.ts`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/everything/__tests__/resources.test.ts`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/filesystem/README.md`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/filesystem/package.json`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/filesystem/index.ts`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/filesystem/lib.ts`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/filesystem/path-utils.ts`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/filesystem/path-validation.ts`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/filesystem/roots-utils.ts`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/filesystem/__tests__/path-validation.test.ts`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/filesystem/__tests__/roots-utils.test.ts`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/filesystem/__tests__/startup-validation.test.ts`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/filesystem/__tests__/structured-content.test.ts`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/filesystem/__tests__/directory-tree.test.ts`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/filesystem/__tests__/lib.test.ts`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/memory/README.md`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/memory/package.json`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/memory/index.ts`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/memory/__tests__/knowledge-graph.test.ts`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/memory/__tests__/file-path.test.ts`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/sequentialthinking/README.md`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/sequentialthinking/package.json`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/sequentialthinking/index.ts`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/sequentialthinking/lib.ts`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/sequentialthinking/__tests__/lib.test.ts`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/fetch/README.md`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/fetch/pyproject.toml`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/fetch/src/mcp_server_fetch/server.py`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/fetch/src/mcp_server_fetch/__init__.py`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/fetch/src/mcp_server_fetch/__main__.py`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/fetch/tests/test_server.py`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/git/README.md`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/git/pyproject.toml`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/git/src/mcp_server_git/server.py`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/git/src/mcp_server_git/__init__.py`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/git/src/mcp_server_git/__main__.py`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/git/tests/test_server.py`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/time/README.md`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/time/pyproject.toml`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/time/src/mcp_server_time/server.py`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/time/src/mcp_server_time/__init__.py`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/time/src/mcp_server_time/__main__.py`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/time/test/time_server_test.py`
- `/tmp/myagents-research/modelcontextprotocol-servers/src/*/Dockerfile`

## Excluded Paths

- `/tmp/myagents-research/modelcontextprotocol-servers/.git/`: VCS internals; exact commit recorded separately.
- `/tmp/myagents-research/modelcontextprotocol-servers/package-lock.json`: generated npm lockfile; reviewed package metadata and CI instead of lock entries.
- `/tmp/myagents-research/modelcontextprotocol-servers/src/*/uv.lock`: generated Python lockfiles; package dependencies and CI commands reviewed through `pyproject.toml` and workflows.
- `/tmp/myagents-research/modelcontextprotocol-servers/src/*/dist/`: generated build output; not present in checkout and not needed because source was reviewed.
- `/tmp/myagents-research/modelcontextprotocol-servers/src/*/.venv/`, `/tmp/myagents-research/modelcontextprotocol-servers/src/*/node_modules/`: vendored/dependency directories; not present and excluded by design.
- README framework/client/resource catalogs outside the official reference servers: skimmed for maintenance status, excluded from core analysis as registry-style listings rather than executable server patterns.
- VS Code badge redirect URLs and README badge images: UI/install affordances only; summarized install UX without reviewing rendered badge assets.
- Embedded tiny image payload in `src/everything/tools/get-tiny-image.ts`: binary demo payload; reviewed surrounding tool behavior, not image bytes.
- `LICENSE` and `CODE_OF_CONDUCT.md`: legal/community text, not MCP architecture or agent execution path.
