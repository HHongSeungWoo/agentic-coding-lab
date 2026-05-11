# upstash/context7

- URL: https://github.com/upstash/context7
- Category: mcp
- Stars snapshot: 54,999 (GitHub REST API, captured 2026-05-11); duplicate ai-coding-workflow row captured 55,000
- Reviewed commit: 78b98266954d35da8aa93ad40c67df33a3ff4443
- Reviewed at: 2026-05-11
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong reference for a documentation-context MCP server and CLI skill installer. Best reusable patterns are two-step library resolution, query-specific docs retrieval, read-only MCP annotations, client-specific setup writers, and explicit query privacy guidance. Core crawling/indexing backend is private, so this repo is not a full self-hostable docs platform.

## Why It Matters

Context7 addresses a high-frequency AI coding problem: agents answer library/API questions from stale training data. It supplies an MCP server and CLI that fetch current, version-aware documentation snippets and code examples into the agent's context.

For Agentic Coding Lab, the repo is relevant as an MCP tool-boundary pattern. It does not just expose web search. It narrows the task to library ID resolution and documentation query, with explicit instructions about when to use it and what not to send.

## What It Is

The repository is a monorepo with a Context7 MCP package, a CLI package, docs, setup templates, and public website documentation. The README states that the repository hosts the MCP server source, while the API backend, parsing engine, and crawling engine are private.

The MCP package exposes two tools:

- `resolve-library-id`: find a Context7-compatible library ID for a library name and user query.
- `query-docs`: retrieve documentation snippets for a specific library ID and query.

The CLI exposes commands for library search, docs fetch, setup, removal, auth, upgrade, and skill registry operations.

## Research Themes

- Token efficiency: Strong. The agent retrieves only relevant docs for a specific query instead of loading full documentation.
- Context control: Strong. Library ID resolution is separated from docs retrieval, and queries are sent as focused prompts.
- Sub-agent / multi-agent: Not central. The repo serves tools to agents rather than coordinating agents.
- Domain-specific workflow: Strong. It specifically supports library/API documentation for coding tasks.
- Error prevention: Strong. It reduces hallucinated APIs and stale syntax, and warns not to include sensitive information in queries.
- Self-learning / memory: Conditional. It provides versioned docs and skills registry, but no local memory engine.
- Popular skills: The docs describe `context7-mcp` and a CLI `find-docs` style skill, plus a broader skills registry.

## Core Execution Path

In MCP mode, the user configures a local or remote Context7 MCP server. The MCP server starts from `packages/mcp/src/index.ts`, parses `--transport`, `--port`, and `--api-key`, validates incompatible flag combinations, and creates an `McpServer` named `Context7`.

The server registers `resolve-library-id` and `query-docs` with Zod schemas and read-only/idempotent annotations. Tool calls use `searchLibraries()` and `fetchLibraryContext()` from `packages/mcp/src/lib/api.ts`, which call Context7 API endpoints and attach source/version/client/auth headers through `generateHeaders()`.

In HTTP mode, Express serves `/mcp` for anonymous access and `/mcp/oauth` for authenticated access. It extracts API keys from Authorization or Context7 headers, validates JWTs when present, sets OAuth discovery headers, and uses stateless `StreamableHTTPServerTransport`.

In stdio mode, it reads `CONTEXT7_API_KEY` or `--api-key`, captures MCP client info during initialization, and connects through `StdioServerTransport`.

In CLI mode, `packages/cli/src/index.ts` registers `ctx7 library`, `ctx7 docs`, `ctx7 setup`, `ctx7 skills`, auth, remove, and upgrade commands. `ctx7 setup` detects target agents and writes MCP config, rules, and skills for Claude, Cursor, OpenCode, Codex, and Gemini.

## Architecture

The architecture is split by package:

- `packages/mcp/`: MCP server, API client, auth/JWT helpers, IP encryption, HTTP/stdio transports, and MCPB packaging.
- `packages/cli/`: `ctx7` command tree, setup flows, skill registry commands, auth, docs commands, config writers, templates, and agent detection.
- `docs/`: product docs for API, setup, clients, skills, private sources, enterprise, security, and library submission.
- `docs/openapi.json`: public API shape for the documentation service.

Important source files include:

- `packages/mcp/src/index.ts`: MCP server and transport setup.
- `packages/mcp/src/lib/api.ts`: Context7 API calls and error handling.
- `packages/mcp/src/lib/encryption.ts`: client IP encryption and telemetry/auth headers.
- `packages/cli/src/commands/docs.ts`: CLI library/docs commands.
- `packages/cli/src/commands/setup.ts`: setup orchestration.
- `packages/cli/src/setup/agents.ts`: per-agent config paths and MCP/rule/skill writers.
- `packages/cli/src/setup/mcp-writer.ts`: JSON/TOML MCP config merge/update/remove logic.
- `packages/cli/src/setup/templates.ts`: fallback rules and Codex sandbox guidance.

## Design Choices

The biggest design choice is a two-step docs protocol. The agent must resolve the library ID first unless the user already supplied an exact `/org/project` or `/org/project/version` ID. This reduces ambiguous retrieval.

The MCP tool descriptions are unusually prescriptive. They tell the agent to use Context7 for library/API documentation even for well-known frameworks, but not for refactoring, business logic debugging, code review, or general concepts.

The setup CLI writes client-native config. Claude and Cursor get JSON MCP entries; Codex gets TOML `mcp_servers`; OpenCode and Gemini get their own config shapes. The same setup also writes rules and installs skills.

The MCP HTTP server is stateless. It rejects GET for MCP requests, uses SSE-style responses for long tool calls, and creates a fresh server/transport per request.

The repo also adds explicit privacy guidance: do not include API keys, passwords, credentials, personal data, or proprietary code in documentation queries.

## Strengths

Context7 is a strong example of a narrow, high-value MCP server. The tools are read-only, idempotent, and directly tied to common coding tasks.

The setup package handles real client differences instead of assuming one universal config format.

The CLI fallback matters because not every environment has MCP. A skill can still instruct the agent to use `npx ctx7 library` and `npx ctx7 docs`.

The error handling is practical. The API client gives specific messages for rate limits, invalid API keys, missing libraries, redirects, and empty docs.

The public docs include library owner configuration (`context7.json`), version pinning, default exclusions, private source docs, and skill registry security/trust concepts.

## Weaknesses

The core indexing backend is private. The repo cannot be reviewed as a complete crawling, ranking, parsing, or benchmark-scoring system.

The MCP server depends on the hosted Context7 API. A local deployment only runs the protocol adapter, not the docs corpus.

The default `CLIENT_IP_ENCRYPTION_KEY` fallback is public and only suitable as a fallback. Real deployments need a configured key if encrypted client IP forwarding matters.

The docs quality and safety depend on indexed third-party sources. The README warns that community-contributed projects may be incomplete or unsafe.

## Ideas To Steal

Use a two-tool pattern for retrieval: first resolve canonical source ID, then query the exact source.

Add read-only, idempotent MCP annotations to documentation tools.

Make tool descriptions include both "use for" and "do not use for" boundaries.

Write per-agent setup adapters instead of hand-maintained installation docs only.

Support both MCP and CLI+skill modes for environments without MCP.

Add explicit privacy guidance to every tool input that sends user queries to a service.

## Do Not Copy

Do not treat hosted docs retrieval as a replacement for primary source review in high-risk changes.

Do not send proprietary code, credentials, or sensitive user data as docs queries.

Do not assume the public repo gives a self-hosted Context7 backend. It does not include crawling/indexing infrastructure.

Do not blindly install arbitrary skills from a registry without security review, even if trust scores exist.

## Fit For Agentic Coding Lab

Fit is in-scope and strong. It is a direct example of MCP improving agent coding quality through current documentation.

Agentic Coding Lab should adapt the protocol shape, not the hosted backend. A local version could expose project docs, internal API docs, or curated framework notes through the same resolve-then-query pattern.

## Reviewed Paths

- `/tmp/myagents-research/upstash-context7/README.md`
- `/tmp/myagents-research/upstash-context7/package.json`
- `/tmp/myagents-research/upstash-context7/docs/api-guide.mdx`
- `/tmp/myagents-research/upstash-context7/docs/skills.mdx`
- `/tmp/myagents-research/upstash-context7/docs/resources/developer.mdx`
- `/tmp/myagents-research/upstash-context7/docs/adding-libraries.mdx`
- `/tmp/myagents-research/upstash-context7/packages/mcp/package.json`
- `/tmp/myagents-research/upstash-context7/packages/mcp/src/index.ts`
- `/tmp/myagents-research/upstash-context7/packages/mcp/src/lib/api.ts`
- `/tmp/myagents-research/upstash-context7/packages/mcp/src/lib/encryption.ts`
- `/tmp/myagents-research/upstash-context7/packages/cli/src/index.ts`
- `/tmp/myagents-research/upstash-context7/packages/cli/src/commands/docs.ts`
- `/tmp/myagents-research/upstash-context7/packages/cli/src/commands/setup.ts`
- `/tmp/myagents-research/upstash-context7/packages/cli/src/commands/skill.ts`
- `/tmp/myagents-research/upstash-context7/packages/cli/src/setup/agents.ts`
- `/tmp/myagents-research/upstash-context7/packages/cli/src/setup/mcp-writer.ts`
- `/tmp/myagents-research/upstash-context7/packages/cli/src/setup/templates.ts`

## Excluded Paths

- `/tmp/myagents-research/upstash-context7/.git/`: VCS internals; commit captured separately.
- `/tmp/myagents-research/upstash-context7/docs/images/`: UI screenshots and diagrams; not execution path.
- `/tmp/myagents-research/upstash-context7/i18n/`: translated README variants, skipped as duplicate content.
- `/tmp/myagents-research/upstash-context7/public/`: static assets only.
- `pnpm-lock.yaml`: dependency lock not reviewed line-by-line.
- Private Context7 API backend, parsing engine, and crawling engine: not present in repository.
