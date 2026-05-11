# firecrawl/firecrawl-mcp-server

- URL: https://github.com/firecrawl/firecrawl-mcp-server
- Category: mcp
- Stars snapshot: 6,276 (GitHub REST API, captured 2026-05-11)
- Reviewed commit: 71aa555b6eaaed1b119caa14ec02f316e7d6a108
- Reviewed at: 2026-05-11
- Status: reviewed
- Scope fit: in-scope
- Verdict: Useful reference for an MCP adapter over a production web retrieval API. Best patterns are tool-level workflow guidance, schema-first extraction, safe-mode gating, stateless HTTP transport, and explicit map/search/scrape/crawl routing. Do not copy its verification posture or docs drift: active code lacks documented retry/env controls and batch tools, tests are effectively absent, and several version files disagree.

## Why It Matters

Firecrawl MCP is a direct example of giving coding agents web search, scraping, crawling, extraction, browser interaction, and local document parsing through MCP. This is high-impact for coding workflows because many tasks require current docs, changelogs, pricing pages, product sites, API references, or issue pages that are outside the model context.

For Agentic Coding Lab, the repo matters less as a crawler implementation and more as a boundary design: it turns a broad web-data API into a set of narrower tools with descriptions that try to guide an agent toward cheaper, lower-context workflows.

## What It Is

The repository is a TypeScript MCP server published as `firecrawl-mcp`. It uses `firecrawl-fastmcp` to register tools and `@mendable/firecrawl-js` to call the Firecrawl API. The current active runtime is concentrated in `src/index.ts`; the older SDK-based implementation is kept as `src/legacy/index.md` and is not compiled.

Default startup is stdio for local MCP clients. `CLOUD_SERVICE=true`, `SSE_LOCAL=true`, or `HTTP_STREAMABLE_SERVER=true` switch the server to FastMCP `httpStream` transport on `/mcp`, with `/health` enabled. A Docker service image adds NGINX routes for `/mcp`, `/messages`, `/sse`, `/health`, and legacy URL-shaped API key forwarding.

Active tools at the reviewed commit:

- `firecrawl_scrape`
- `firecrawl_map`
- `firecrawl_search`
- `firecrawl_crawl`
- `firecrawl_check_crawl_status`
- `firecrawl_extract`
- `firecrawl_agent`
- `firecrawl_agent_status`
- `firecrawl_browser_create`
- `firecrawl_browser_execute` only when not in cloud safe mode
- `firecrawl_browser_delete`
- `firecrawl_browser_list`
- `firecrawl_interact`
- `firecrawl_interact_stop`
- `firecrawl_parse` only when not in cloud mode

README mentions `firecrawl_batch_scrape` and `firecrawl_check_batch_status`, but those tools are not registered in active `src/index.ts`.

## Research Themes

- Token efficiency: Strong in tool guidance, mixed in enforcement. Descriptions push JSON/schema extraction, `query` format for long pages, `map` before `agent`, search without scraped content first, and crawl limits. Actual outputs are unbounded JSON strings with no truncation layer.
- Context control: Strong workflow guidance. The server separates discovery (`map`, `search`), single-page retrieval (`scrape`), async broad retrieval (`crawl`, `agent`), and polling tools.
- Sub-agent / multi-agent: Conditional. `firecrawl_agent` delegates research to Firecrawl's hosted agent, but the MCP server itself has no multi-agent orchestration.
- Domain-specific workflow: Strong. Tool descriptions are written for web retrieval, docs scraping, structured extraction, browser interaction, and document parsing.
- Error prevention: Mixed. Zod schemas validate URLs, domains, enums, prompt lengths, and some option bounds; descriptions warn against high-context crawl usage. Verification and docs drift weaken reliability.
- Self-learning / memory: Weak. There is cache use through Firecrawl options such as `maxAge`, `storeInCache`, and `lockdown`, but no local memory or learning loop.
- Popular skills: Useful as a candidate backing service for a "web retrieval for coding agents" skill: search first, map before agent, scrape exact pages, prefer schema extraction, poll async jobs patiently.

## Core Execution Path

The package entrypoint is `dist/index.js`, built from `src/index.ts`. On process start, `dotenv` loads environment variables, then a `FastMCP<SessionData>` server is created with roots disabled, a custom logger, an auth callback, and a `/health` endpoint.

Auth path depends on mode. In cloud mode, `authenticate` extracts an API key from `x-firecrawl-api-key`, `x-api-key`, or `Authorization: Bearer ...` and stores it in session data. Outside cloud mode, it requires either `FIRECRAWL_API_KEY` or `FIRECRAWL_API_URL`, then returns the env API key if present. Tool calls use `getClient(session)`, which creates a Firecrawl SDK client with optional `apiUrl` and API key.

Tool calls follow a simple adapter pattern:

- Zod validates MCP arguments.
- Helpers remove empty top-level options and transform user-friendly `formats`, `jsonOptions`, `queryOptions`, `screenshotOptions`, `parsers`, `pdfOptions`, and webhooks into Firecrawl SDK option objects.
- Each tool logs a small event, calls one Firecrawl SDK method, and returns `JSON.stringify(result, null, 2)`.
- Async jobs return IDs; status tools poll Firecrawl with those IDs.

Transport selection happens at the end of `src/index.ts`. Default local mode starts stdio. Cloud, SSE local, and HTTP streamable modes start FastMCP `httpStream` with `stateless: true`; host is `0.0.0.0` only in cloud mode, otherwise `HOST` or `localhost`.

## Architecture

The active architecture is intentionally thin:

- `src/index.ts`: all active server setup, auth, schemas, tool descriptions, tool handlers, safe-mode checks, and transport startup.
- `src/types/fastmcp.d.ts`: local type declarations for the `firecrawl-fastmcp` dependency.
- `package.json`: npm package metadata, `firecrawl-mcp` bin, build/start scripts, and dependency pins.
- `server.json`: MCP registry metadata, but stale relative to `package.json`.
- `smithery.yaml`: stdio startup config for Smithery with Firecrawl API key and API URL.
- `Dockerfile`: Smithery-generated build/runtime image for stdio-style execution.
- `Dockerfile.service`, `docker/nginx.conf`, `docker/entrypoint.sh`: service image with Node app behind NGINX.
- `.github/workflows/*.yml`: CI build, npm/MCP registry publishing, and GHCR image publishing.
- `jest.config.js`, `jest.setup.ts`: test scaffolding and mocks, but no `.test.ts` files exist.
- `src/legacy/index.md`: older implementation and docs fragments; reviewed for historical retry/auth behavior but excluded from active execution.

## Design Choices

The most valuable design choice is embedding agent workflow policy in tool descriptions. `firecrawl_scrape` tells agents when to use markdown, JSON, or query formats. `firecrawl_map` says to find the right page before escalating to the agent. `firecrawl_search` recommends search results first and low limits when scraping results. `firecrawl_crawl` warns that crawl output can exceed context limits.

Safe mode is tied to `CLOUD_SERVICE=true`. In safe mode, scrape omits interactive actions, crawl omits webhook fields, browser execute is not registered, and local file parse is not registered. This is a pragmatic way to publish one package with a stricter hosted profile and a more permissive local/self-hosted profile.

The server prefers stateless HTTP for cloud/service mode. This lowers session-management burden for hosted MCP deployment, but it also means per-call auth and backend SDK behavior carry most state and safety responsibility.

The API adapter keeps Firecrawl-specific options visible rather than hiding them behind a tiny generic "fetch URL" tool. This is good for agents that need control over JSON extraction, PDFs, screenshots, proxy behavior, cache age, crawl depth, web search domains, and asynchronous jobs.

The repo also keeps legacy URL-based API key support in NGINX routes. That helps old clients but leaks credentials into request paths, logs, browser history, and observability systems more easily than header-based auth.

## Strengths

The tool taxonomy maps well to agent decision-making. Search, map, scrape, crawl, extract, agent, interact, browser, and parse represent distinct retrieval strategies instead of one overloaded endpoint.

Schema-first extraction is first-class. The server exposes JSON and query formats, supports schemas for scrape/extract/agent, and repeatedly tells agents to avoid full markdown when only structured fields are needed.

The domain filter design for search is safer than raw query string concatenation alone. Include/exclude domains are validated as hostnames and are mutually exclusive before being converted to `site:` operators.

Cloud mode has meaningful safety reductions. It requires per-request API key headers, disables local file parse, disables browser code execution, and removes high-risk scrape actions such as `executeJavascript`, `write`, and `generatePDF`.

Self-hosted support is real. `FIRECRAWL_API_URL` can route all SDK calls to a custom Firecrawl API, and `firecrawl_parse` supports local document parsing only in that mode.

The README/tool text teaches a practical context-budget workflow: search/map to discover, scrape exact pages, use JSON/schema for facts, crawl only with limits, and poll async jobs.

## Weaknesses

The active server does not implement the README's retry and credit-monitoring environment variables. `FIRECRAWL_RETRY_*` and `FIRECRAWL_CREDIT_*` appear in README/changelog/legacy content, but current `src/index.ts` does not read them. Rate-limit handling is delegated to the Firecrawl SDK/backend.

Documentation and runtime disagree. README documents `firecrawl_batch_scrape` and `firecrawl_check_batch_status`, but active code registers neither. `server.json` reports version `3.7.4`, `package.json` reports `3.15.0`, and the FastMCP server is constructed with version `3.0.0`.

Verification is thin. CI installs dependencies and runs `pnpm run build`, but does not run tests. `jest.config.js` searches for `**/*.test.ts`, no such files are present, and `package.json` lacks direct Jest or ts-jest dev dependencies even though `npm test` invokes `node_modules/jest/bin/jest.js`.

Context limits are mostly advisory. `agent.prompt` and `queryOptions.prompt` are capped at 10,000 characters, but URL array lengths, crawl limits, search result limits, and response sizes are not capped by the MCP adapter.

Tool results are raw formatted JSON strings. There is no response summarizer, pagination layer, byte budget, citation compaction, or metadata/content splitting in the server.

`firecrawl_parse` reads arbitrary local file paths and uploads content to the configured Firecrawl API. It is disabled in cloud mode, but in local HTTP/self-hosted deployments it has no allowlist or workspace sandbox at the MCP layer.

Safe mode still leaves some execution-like surfaces. `firecrawl_interact` remains registered in cloud mode and accepts `prompt` or `code`; `firecrawl_browser_create`, list, and delete also remain registered. Safety depends on Firecrawl backend policy, not only MCP schema gating.

## Ideas To Steal

Use separate MCP tools for web discovery, exact-page retrieval, site crawl, structured extraction, async research, and status polling. Agents make better choices when tool boundaries match retrieval strategy.

Put context-budget guidance directly in tool descriptions: "search first without scraped content", "map before agent", "JSON/schema for specific facts", and "crawl only with explicit limits".

Expose a cache/lockdown option for compliance-sensitive retrieval. The `lockdown` flag is a useful pattern for "do not make a fresh outbound request; fail on cache miss".

Use safe-mode registration to remove risky parameters and tools in hosted deployments while preserving richer local/self-hosted capability.

Treat async web work as a first-class MCP pattern: start job, return ID, poll status with patient intervals, and let the calling agent do other work.

Validate domain filters separately from free-form search query text, then compile them into search operators.

Annotate open-world and read-only/destructive behavior carefully so clients can reason about web access and browser/session effects.

## Do Not Copy

Do not let README, registry metadata, package version, and active tool registry drift. For MCP servers, docs drift causes agents to call non-existent tools.

Do not rely on prose-only context budget advice for high-volume retrieval. Add adapter-level limits, pagination, truncation, or result-shaping.

Do not expose local file parsing over network-accessible MCP without path allowlists, workspace roots, size limits, and explicit user consent.

Do not put API keys in URL paths for new deployments. Prefer headers or OAuth-style auth; keep legacy path support behind strict logging controls if needed.

Do not advertise retry/credit controls unless the active execution path reads and enforces those settings.

Do not treat build-only CI as enough for MCP behavior. Tool schema snapshots, auth-mode tests, safe-mode tests, and docs/tool-registry consistency tests are needed.

## Fit For Agentic Coding Lab

Fit is in-scope and strong. Firecrawl MCP is directly applicable as a web retrieval backend for coding agents, especially when an agent needs live docs, issue trackers, product pages, and structured extraction from current pages.

The best adaptation is not the Firecrawl backend itself, but the workflow contract. Agentic Coding Lab should copy the retrieval ladder: search or map first, scrape exact pages second, crawl only with limits, escalate to autonomous research only when cheaper paths fail, and poll async jobs instead of blocking blindly.

For project-local use, this repo also highlights guardrails that Agentic Coding Lab should add around any web/file retrieval MCP: hard context budgets, source allow/deny lists, response shaping, path sandboxing for local files, and regression tests that compare docs against the actual tool registry.

## Reviewed Paths

- `/tmp/myagents-research/firecrawl-firecrawl-mcp-server/README.md`
- `/tmp/myagents-research/firecrawl-firecrawl-mcp-server/package.json`
- `/tmp/myagents-research/firecrawl-firecrawl-mcp-server/pnpm-lock.yaml` dependency/version references only
- `/tmp/myagents-research/firecrawl-firecrawl-mcp-server/server.json`
- `/tmp/myagents-research/firecrawl-firecrawl-mcp-server/smithery.yaml`
- `/tmp/myagents-research/firecrawl-firecrawl-mcp-server/src/index.ts`
- `/tmp/myagents-research/firecrawl-firecrawl-mcp-server/src/types/fastmcp.d.ts`
- `/tmp/myagents-research/firecrawl-firecrawl-mcp-server/src/legacy/index.md` selected historical retry/auth/startup sections only
- `/tmp/myagents-research/firecrawl-firecrawl-mcp-server/VERSIONING.md`
- `/tmp/myagents-research/firecrawl-firecrawl-mcp-server/CHANGELOG.md`
- `/tmp/myagents-research/firecrawl-firecrawl-mcp-server/Dockerfile`
- `/tmp/myagents-research/firecrawl-firecrawl-mcp-server/Dockerfile.service`
- `/tmp/myagents-research/firecrawl-firecrawl-mcp-server/docker/nginx.conf`
- `/tmp/myagents-research/firecrawl-firecrawl-mcp-server/docker/entrypoint.sh`
- `/tmp/myagents-research/firecrawl-firecrawl-mcp-server/jest.config.js`
- `/tmp/myagents-research/firecrawl-firecrawl-mcp-server/jest.setup.ts`
- `/tmp/myagents-research/firecrawl-firecrawl-mcp-server/tsconfig.json`
- `/tmp/myagents-research/firecrawl-firecrawl-mcp-server/.eslintrc.json`
- `/tmp/myagents-research/firecrawl-firecrawl-mcp-server/.prettierrc`
- `/tmp/myagents-research/firecrawl-firecrawl-mcp-server/.github/workflows/ci.yml`
- `/tmp/myagents-research/firecrawl-firecrawl-mcp-server/.github/workflows/publish.yml`
- `/tmp/myagents-research/firecrawl-firecrawl-mcp-server/.github/workflows/image.yml`
- `/tmp/myagents-research/firecrawl-firecrawl-mcp-server/.github/workflows/image-staging.yml`
- GitHub REST repository metadata for stars, default branch, pushed date, license, and issue/fork counts

## Excluded Paths

- `/tmp/myagents-research/firecrawl-firecrawl-mcp-server/.git/`: VCS internals; exact reviewed commit recorded separately.
- `/tmp/myagents-research/firecrawl-firecrawl-mcp-server/img/`: logo/wordmark PNG assets only, not MCP execution behavior.
- `/tmp/myagents-research/firecrawl-firecrawl-mcp-server/LICENSE`: legal text, not relevant to execution path beyond MIT license summary.
- `/tmp/myagents-research/firecrawl-firecrawl-mcp-server/.gitignore`: repository hygiene only.
- `/tmp/myagents-research/firecrawl-firecrawl-mcp-server/pnpm-lock.yaml`: not reviewed line-by-line; checked only for dependency versions because execution path is in source.
- `/tmp/myagents-research/firecrawl-firecrawl-mcp-server/src/legacy/index.md`: excluded from active architecture because `tsconfig.json` compiles `src/**/*.ts`, package entry is `dist/index.js`, and no active import references the markdown file; selected sections were read to understand docs drift and historical retry behavior.
- Missing tests under `/tmp/myagents-research/firecrawl-firecrawl-mcp-server/**/*.test.ts`: no test files exist to review, despite Jest config and setup mocks.
- Vendored dependencies such as `node_modules/`: not present in checkout and excluded as third-party generated dependency content.
