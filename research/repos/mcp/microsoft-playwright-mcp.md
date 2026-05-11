# microsoft/playwright-mcp

- URL: https://github.com/microsoft/playwright-mcp
- Category: mcp
- Stars snapshot: 32,347 (GitHub REST API, captured 2026-05-11 in `research/index.md`; GitHub UI also showed 32.3k during review)
- Reviewed commit: 8116437ffcfee1309cebc07dd30cee37720d2d19
- Reviewed at: 2026-05-11
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong browser-automation MCP reference, especially for accessibility-snapshot-driven interaction and web app verification. For coding agents, its own README now favors Playwright CLI + skills for token efficiency; MCP fit is best when persistent browser state, iterative page introspection, or long-running autonomous browser workflows outweigh schema and snapshot context cost.

## Why It Matters

Playwright MCP gives agents a real browser with structured page state, actions, network/console inspection, screenshots, storage, and optional testing assertions. That makes it directly relevant to coding-agent loops that need to inspect a local web app, verify UI behavior, debug console/network failures, or produce Playwright locator/code snippets.

The key design is not "browser screenshots for vision." It uses Playwright's accessibility snapshot as the primary action surface, with stable element refs and generated Playwright code. This is more deterministic and model-agnostic than pixel-only browser control.

## What It Is

This repository is the npm packaging/wrapper for `@playwright/mcp`. The published entrypoints are small:

- `cli.js` loads `playwright-core/lib/coreBundle`, decorates a Commander command with MCP options, and has a special `install-browser` path.
- `index.js` exports `createConnection` from the same `playwright-core` tool bundle for programmatic use.
- `config.d.ts`, README tool/options sections, Dockerfile, and tests live here.

The actual MCP implementation has moved into the Playwright monorepo and is bundled into the pinned runtime dependency `playwright-core@1.61.0-alpha-1778188671000`. I reviewed that bundled runtime through `node_modules/playwright-core/lib/coreBundle.js`, whose source markers identify the original `packages/playwright-core/src/tools/...` files.

## Research Themes

- Token efficiency: Mixed. Accessibility snapshots are cheaper and more actionable than screenshots, but README explicitly says coding agents may prefer CLI + skills because MCP schemas and verbose accessibility trees consume context.
- Context control: Strong. Tools can write snapshots/logs/results to files, `--snapshot-mode=none` can suppress automatic snapshots, and capabilities gate non-core tools.
- Sub-agent / multi-agent: Conditional. It supports multiple MCP clients and shared browser contexts, but persistent profiles can conflict and are not a multi-agent coordination layer.
- Domain-specific workflow: Strong. Browser automation, UI verification, locator generation, console/network triage, storage state, traces, video, and PDFs are all browser-workflow specific.
- Error prevention: Strong for UI agents. It uses refs from current snapshots, generated Playwright code, modal-state gating, action/navigation timeouts, and optional assertion tools.
- Self-learning / memory: Weak. Persistent browser profiles preserve login/session state, but there is no agent memory system.
- Popular skills: The repo points coding agents toward Playwright CLI + skills. The runtime also marks several tools as `skillOnly`, so MCP intentionally exposes a smaller default surface than the CLI skill mode.

## Core Execution Path

A typical client starts the server with `npx @playwright/mcp@latest`. `cli.js` imports `program` and `tools` from `playwright-core`, then `decorateMCPCommand()` adds options such as `--browser`, `--headless`, `--isolated`, `--caps`, `--allowed-hosts`, `--allowed-origins`, `--blocked-origins`, `--allow-unrestricted-file-access`, `--storage-state`, `--secrets`, `--snapshot-mode`, and `--port`.

After CLI parsing, `resolveCLIConfigForMCP()` merges defaults, config file, environment variables, and CLI options. It validates browser settings, resolves init script/page paths, sets Chrome defaults, auto-headless on Linux without `DISPLAY`, default timeouts, and output directory constraints.

`filteredTools(config)` selects all core tools plus opt-in capabilities from `--caps`, then removes `skillOnly` tools. `start()` uses stdio by default via `StdioServerTransport`; with `--port`, it starts Streamable HTTP at `/mcp` and legacy SSE at `/sse`.

The MCP server exposes `listTools` and `callTool`. On first tool call, it reads MCP client roots if available, chooses the first root as `cwd`, creates a backend lazily, and starts heartbeat only for HTTP transport. Tool schemas are converted from Zod to JSON Schema and annotated with read-only/destructive/open-world hints.

Browser creation branches through `createBrowserWithInfo()`: remote Playwright endpoint, CDP endpoint, isolated browser, existing browser through the extension relay, or a persistent browser profile keyed by client workspace. The browser is bound to the client name and workspace when possible.

Each call reaches `BrowserBackend.callTool()`, which parses arguments, honors `_meta.cwd`, `_meta.raw`, and `_meta.json`, creates a `Response`, and dispatches the tool. `Context` owns tabs, routes, output files, network restrictions, secret lookup, video state, and unhandled rejection capture. `Tab` tracks console messages, page errors, requests, downloads, dialogs, file choosers, crashes, and current page state.

Actions use `targetLocator()` to resolve either an accessibility ref like `e2`/`f1e2` or a selector/locator string. Snapshot capture calls `page.ariaSnapshot({ mode: "ai" })` or element `ariaSnapshot()` and returns YAML. Responses can include result text, generated Playwright code, page/tab summaries, snapshot YAML or snapshot file links, console/event links, and image attachments.

## Architecture

The package layer is intentionally thin:

- `cli.js`: executable entrypoint and browser-install shim.
- `index.js` / `index.d.ts`: programmatic `createConnection(config, contextGetter)` export.
- `config.d.ts`: public TypeScript config surface copied from Playwright source.
- `server.json`: MCP registry metadata for stdio npm package.
- `update-readme.js`: generated README options/tools/config from compiled modules.
- `roll.js`: updates pinned Playwright packages, copies config, regenerates README.

The runtime architecture in `playwright-core/lib/coreBundle.js` is split into:

- MCP transport/server utilities: source markers `tools/utils/mcp/server.ts`, `http.ts`, and `tool.ts`.
- MCP config and startup: `tools/mcp/program.ts`, `config.ts`, `index.ts`, `browserFactory.ts`, `extensionContextFactory.ts`, and `cdpRelay.ts`.
- Browser backend: `tools/backend/browserBackend.ts`, `context.ts`, `tab.ts`, `response.ts`, `tool.ts`, and `tools.ts`.
- Tool families: snapshot/actions, screenshot, keyboard, mouse, navigation, network, route, storage, cookies, console, files, forms, tabs, tracing, video, PDF, evaluate/run-code, wait, and verification.

Tests in this wrapper repo use a real MCP client over stdio, local HTTP/HTTPS test servers, and Playwright browser projects. They cover startup, basic navigation/click behavior, tool list/capability gating, CommonJS import, and install-browser help.

## Design Choices

Accessibility snapshots are the primary interaction protocol. `browser_snapshot` says it is better than screenshots, and `browser_take_screenshot` explicitly says screenshots should not be the basis for actions. Coordinate tools exist only behind `--caps=vision`.

Tool outputs include generated Playwright code by default. This makes the MCP useful both for immediate browser control and for converting successful agent actions into durable tests or scripts.

The default browser mode is a persistent profile keyed by workspace hash. `--isolated` starts fresh contexts and can load storage state. `--shared-browser-context` lets HTTP clients reuse a browser context, but the README warns persistent profiles are single-instance.

Permissions are guardrails, not hard isolation. File access is limited to workspace/output roots unless unrestricted access is enabled, but docs and config type say this is not a secure boundary. Network allow/block origin filters are useful for mistake prevention, yet their own help text says they do not handle redirects and are not security boundaries.

The server intentionally keeps dangerous power in the same surface. `browser_evaluate` executes JavaScript in page context, while `browser_run_code_unsafe` executes JavaScript in the Playwright server process and labels itself RCE-equivalent. `--init-page` can also load arbitrary TypeScript setup code.

`defineTabTool()` gates tools when a modal dialog or file chooser is active, forcing the agent to handle modal state first. This reduces confused actions after blocking browser events.

## Strengths

The snapshot/ref design is the main strength. It gives agents a compact, structured tree and exact element refs instead of requiring visual inference for routine UI work.

Playwright code generation is practical. Every successful action can return the corresponding locator/action snippet, which is useful for tests and reproducibility.

The browser lifecycle options are mature: persistent profiles, isolated sessions, storage state, CDP attach, remote endpoint attach, extension attach, Docker, stdio, HTTP, and programmatic embedding.

Response serialization is thoughtful. It can inline or file-link snapshots/logs/results, redact configured secrets, include page/tab summaries, and emit raw/json formats for CLI-like consumption.

Tool capability gating keeps the default MCP set smaller than the full runtime. Vision, PDF, devtools, network mocking, storage, and testing assertions can be opted in.

The repo is honest about security. It repeatedly states Playwright MCP is not a security boundary, and the unsafe server-side code execution tool is named/described plainly.

## Weaknesses

The reviewed repo is mostly a wrapper. The real source is in Playwright and only present here as a bundled dependency, so repository review requires following generated/bundled code rather than normal TypeScript source files.

For coding agents, MCP overhead is a real concern. The README itself says CLI + skills are often more token-efficient because MCP loads schemas and verbose accessibility trees into context.

The default tool surface includes `browser_run_code_unsafe`, which is RCE-equivalent in the server process. That is powerful for trusted local workflows but risky as a default capability for broad agent deployments.

Security controls are not boundaries. Host allowlists reduce DNS rebinding risk for HTTP transport, file guards reduce accidental path wandering, and network origin rules reduce mistakes, but none replace sandboxing and client-level permissions.

Persistent profiles can leak or cross-contaminate state between tasks if reused carelessly. They also conflict when multiple clients share the same workspace unless isolated or separate `--user-data-dir` is used.

Snapshot-driven automation can miss visual-only state, canvas apps, layout regressions, and accessibility-poor UI. Screenshots and vision tools exist, but the core action model is accessibility-tree dependent.

Wrapper tests are thin. They verify basic navigation/click/tool-list/import paths but do not cover most security-sensitive options, network restrictions, file guardrails, unsafe code execution, storage, tracing, extension relay, or HTTP transport in depth.

Dependency audit is clean for production install (`npm audit --omit=dev`), but the full dev audit reports high-severity `fast-uri` advisories through `@modelcontextprotocol/sdk`/`ajv` with no fix available at review time.

There is a small documentation mismatch: README/config type show testing assertion tools as opt-in via `--caps=testing`, but the CLI `--caps` help text only lists `vision`, `pdf`, and `devtools`.

## Ideas To Steal

Use accessibility snapshots as the default browser action surface, with stable refs and a screenshot fallback only when visual inspection matters.

Return generated automation code with tool results so exploration can become durable tests.

Separate core tools from opt-in capability families to reduce schema/context cost and permission blast radius.

Add explicit file-root checks for all LLM-supplied paths, and label them as convenience guardrails rather than security boundaries.

Gate modal states so agents cannot keep clicking/typing while a dialog or file chooser blocks JavaScript.

Support both MCP and CLI/skill modes. For coding-agent workflows, prefer CLI commands when repeated browser automation would otherwise flood context.

Expose session logs, console logs, network logs, trace/video artifacts, and raw/json response modes for auditability and automation.

## Do Not Copy

Do not expose RCE-equivalent `run_code_unsafe` to untrusted prompts or remote users without an explicit approval model.

Do not treat network allowlists, file-root checks, or secret redaction as security isolation.

Do not default long-lived coding agents to persistent browser profiles unless profile state is intentional and scoped.

Do not rely only on accessibility snapshots for visual QA, canvas-heavy apps, or inaccessible UIs.

Do not split source and wrapper packages in a way that makes normal code review depend on generated bundles unless the release process makes provenance obvious.

## Fit For Agentic Coding Lab

Fit is in-scope and strong as a browser verification subsystem. Agentic Coding Lab should copy the snapshot/ref/action-result pattern, modal-state gating, capability gating, and code-generation feedback loop.

For day-to-day coding agents, the repo's own recommendation matters: prefer CLI + skill flows when token efficiency is the priority. MCP is better as an optional long-lived browser session for exploratory automation, debugging, and verification where persistent browser state and rich introspection are worth the context cost.

## Reviewed Paths

- `/tmp/myagents-research/microsoft-playwright-mcp/README.md`
- `/tmp/myagents-research/microsoft-playwright-mcp/package.json`
- `/tmp/myagents-research/microsoft-playwright-mcp/package-lock.json` (pinned Playwright/runtime versions and npm provenance only)
- `/tmp/myagents-research/microsoft-playwright-mcp/cli.js`
- `/tmp/myagents-research/microsoft-playwright-mcp/index.js`
- `/tmp/myagents-research/microsoft-playwright-mcp/index.d.ts`
- `/tmp/myagents-research/microsoft-playwright-mcp/config.d.ts`
- `/tmp/myagents-research/microsoft-playwright-mcp/server.json`
- `/tmp/myagents-research/microsoft-playwright-mcp/src/README.md`
- `/tmp/myagents-research/microsoft-playwright-mcp/CONTRIBUTING.md`
- `/tmp/myagents-research/microsoft-playwright-mcp/CLAUDE.md`
- `/tmp/myagents-research/microsoft-playwright-mcp/SECURITY.md`
- `/tmp/myagents-research/microsoft-playwright-mcp/Dockerfile`
- `/tmp/myagents-research/microsoft-playwright-mcp/update-readme.js`
- `/tmp/myagents-research/microsoft-playwright-mcp/roll.js`
- `/tmp/myagents-research/microsoft-playwright-mcp/playwright.config.ts`
- `/tmp/myagents-research/microsoft-playwright-mcp/tests/fixtures.ts`
- `/tmp/myagents-research/microsoft-playwright-mcp/tests/core.spec.ts`
- `/tmp/myagents-research/microsoft-playwright-mcp/tests/capabilities.spec.ts`
- `/tmp/myagents-research/microsoft-playwright-mcp/tests/click.spec.ts`
- `/tmp/myagents-research/microsoft-playwright-mcp/tests/cli.spec.ts`
- `/tmp/myagents-research/microsoft-playwright-mcp/tests/library.spec.ts`
- `/tmp/myagents-research/microsoft-playwright-mcp/tests/testserver/index.ts`
- `/tmp/myagents-research/microsoft-playwright-mcp/node_modules/playwright-core/package.json`
- `/tmp/myagents-research/microsoft-playwright-mcp/node_modules/playwright-core/lib/entry/mcp.js`
- `/tmp/myagents-research/microsoft-playwright-mcp/node_modules/playwright-core/lib/coreBundle.js` source-marked sections for `packages/playwright-core/src/tools/utils/mcp/server.ts`, `http.ts`, `tool.ts`; `src/tools/mcp/program.ts`, `config.ts`, `index.ts`, `browserFactory.ts`, `extensionContextFactory.ts`, `cdpRelay.ts`; and `src/tools/backend/browserBackend.ts`, `context.ts`, `tab.ts`, `response.ts`, `tool.ts`, `tools.ts`, `snapshot.ts`, `screenshot.ts`, `network.ts`, `evaluate.ts`, `runCode.ts`, `verify.ts`.

## Excluded Paths

- `/tmp/myagents-research/microsoft-playwright-mcp/.git/`: VCS internals; reviewed commit recorded separately.
- `/tmp/myagents-research/microsoft-playwright-mcp/.github/workflows/`: CI and publish automation, not the MCP runtime path.
- `/tmp/myagents-research/microsoft-playwright-mcp/.devcontainer/`: local development container config, not runtime or tool behavior.
- `/tmp/myagents-research/microsoft-playwright-mcp/.claude/skills/release.md`: release workflow instructions; not browser automation design.
- `/tmp/myagents-research/microsoft-playwright-mcp/node_modules/` except the pinned `playwright-core` files listed above: vendored dependencies; reviewed only where they are the actual bundled MCP runtime.
- `/tmp/myagents-research/microsoft-playwright-mcp/node_modules/playwright-core/lib/vite/`, `lib/tools/dashboard/`, recorder assets, trace viewer assets, fonts, SVGs, PNGs, CSS, and HTML bundles: UI/static assets unrelated to MCP execution path.
- `/tmp/myagents-research/microsoft-playwright-mcp/node_modules/@modelcontextprotocol/`, `node_modules/playwright/`, `node_modules/@playwright/test/`, and other dependency packages: third-party/vendored libraries outside this repo's design.
- `/tmp/myagents-research/microsoft-playwright-mcp/tests/testserver/*.pem` and `tests/testserver/san.cnf`: TLS fixtures for the local test server, not agent/browser tool design.
- Client-specific README installation examples for every IDE/app were skimmed but not reviewed line-by-line; they are generated setup documentation, while the execution path is in CLI/server/tool code.
