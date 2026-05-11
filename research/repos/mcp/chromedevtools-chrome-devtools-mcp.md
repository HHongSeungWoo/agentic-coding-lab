# ChromeDevTools/chrome-devtools-mcp

- URL: https://github.com/ChromeDevTools/chrome-devtools-mcp
- Category: mcp
- Stars snapshot: 39,219 (GitHub REST API, captured 2026-05-11)
- Reviewed commit: aa5e21cd02a1f8ad25a76f41df767b33b43dd02e
- Reviewed at: 2026-05-11
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong reference MCP server for giving coding agents real browser state, DevTools diagnostics, screenshots, network/console context, and performance traces. Best patterns are lazy browser startup, explicit tool categories, UID-based a11y snapshots, stable request/message IDs, file-path handling for large outputs, roots-based file access, and tests around dialogs/permissions/CLI daemon behavior. Main risk is expected: it is a powerful browser-control bridge, not a sandbox.

## Why It Matters

Chrome DevTools MCP closes a major verification gap for coding agents. It lets an agent move from static code edits to a live browser loop: navigate pages, inspect accessible structure, click/fill elements, capture screenshots, read console and network events, record performance traces, and run Lighthouse audits.

For Agentic Coding Lab, this is directly relevant as an MCP boundary design. The server turns a broad browser automation surface into composable tools with tool annotations, category flags, stable resource IDs, and response formatting optimized for agents.

## What It Is

The repo is a TypeScript MCP server and companion CLI published as `chrome-devtools-mcp`. It exposes an MCP stdio server named `chrome_devtools` and a `chrome-devtools` CLI that talks to a background daemon.

The MCP server either launches Chrome through Puppeteer or connects to an already running debuggable Chrome via `--browser-url`, `--ws-endpoint`, or `--auto-connect`. Tools cover navigation, input automation, emulation, performance tracing, network inspection, console/issues, screenshots, accessibility snapshots, Lighthouse, memory snapshots, extensions, third-party developer tools, and WebMCP.

It also ships agent skills for Chrome DevTools workflows, CLI automation, LCP debugging, accessibility debugging, memory leak debugging, and troubleshooting.

## Research Themes

- Token efficiency: Strong. The server returns summaries, stable IDs, paginated console/network lists, file paths for large screenshots/traces/reports, and optional structured content instead of raw browser dumps.
- Context control: Strong. Page state is selected explicitly, tools are category-gated, snapshots provide UIDs for later actions, and network/console data is scoped to current or recent navigations.
- Sub-agent / multi-agent: Conditional. There is no coordinator, but page IDs, isolated browser contexts, focused-page emulation, and CLI session IDs support parallel agent workflows if the client manages them carefully.
- Domain-specific workflow: Strong. It is purpose-built for browser debugging, frontend verification, performance, accessibility, and extension testing.
- Error prevention: Strong. Dialog blocking, action waits, Zod schemas, disabled tool messages, path validation, and broad tests reduce common browser-automation failures.
- Self-learning / memory: Weak. It stores short-lived page, trace, console, network, and telemetry state, but no durable agent learning memory.
- Popular skills: Strong. Bundled skills encode recommended use of snapshots before input actions, performance trace workflows, a11y audit workflows, and CLI scripting patterns.

## Core Execution Path

MCP mode starts at `src/bin/chrome-devtools-mcp.ts`, checks supported Node versions, then imports `src/bin/chrome-devtools-mcp-main.ts`. The main file checks for updates, parses CLI flags, optionally writes logs, installs an unhandled rejection logger, creates the MCP server through `createMcpServer()`, connects it to `StdioServerTransport`, prints disclaimers, and starts telemetry if enabled.

`src/index.ts` builds the `McpServer`, handles MCP logging-level and roots requests, initializes telemetry, creates all tools with `createTools(args)`, and registers each tool. Tool registration applies category and condition gates. In normal MCP mode, disabled off-by-default tools are not registered. In CLI mode, disabled tools can return actionable "enable this flag" messages.

The first tool that needs browser state calls `getContext()`. That function either connects to Chrome through `ensureBrowserConnected()` when `browserUrl`, `wsEndpoint`, or `autoConnect` is configured, or launches Chrome through `ensureBrowserLaunched()`. Browser launch uses Puppeteer with `pipe: true`, optional profile isolation, optional custom Chrome args, optional extensions, optional viewport, and optional insecure cert acceptance.

Once a browser exists, `McpContext.from()` snapshots pages, creates network and console collectors, detects DevTools windows, tracks the selected page, and wraps pages in `McpPage`. Each page wrapper owns the text snapshot, element UID mapping, dialog state, emulation state, optional DevTools page, and optional page-exposed tools.

Every registered tool call is serialized by a `Mutex`. The handler logs params, resolves context, detects open DevTools windows, chooses `McpResponse` or `SlimMcpResponse`, sets network-header redaction from args, dispatches to the tool handler, then lets the response object attach requested browser data such as page list, snapshot, network request, console message, trace summary, Lighthouse report, extension list, or image.

CLI mode starts at `src/bin/chrome-devtools.ts`. It generates yargs commands from generated CLI options, starts a daemon on first tool command if needed, then sends one `invoke_tool` command over a Unix socket or Windows named pipe. `src/daemon/daemon.ts` runs a local socket server and starts the MCP server as a child process over stdio.

## Architecture

The main architecture layers are:

- `src/bin/`: MCP and CLI entrypoints plus CLI option definitions.
- `src/browser.ts`: singleton browser launch/connect logic and Chrome target filtering.
- `src/index.ts`: MCP server creation, roots handling, tool registration, category/condition gating, telemetry hooks, and disclaimers.
- `src/McpContext.ts`: session state, page selection, roots/path validation, network/console collectors, file writes, extension operations, emulation, trace storage, heap snapshot access, and page/context lifecycle.
- `src/McpPage.ts`: per-page dialog handling, text snapshot element resolution, action wait helper, DevTools UI data extraction, and page-exposed third-party tool execution.
- `src/PageCollector.ts`: per-page console/network data collection, stable IDs, and preservation across the latest navigations.
- `src/McpResponse.ts`: response assembly for text, images, structured content, snapshots, network details, console details, trace insights, Lighthouse reports, pagination, extensions, and page lists.
- `src/tools/`: tool definitions and schemas for input, pages, emulation, performance, network, console, screenshot, snapshot, script, Lighthouse, memory, screencast, extensions, third-party developer tools, WebMCP, and slim mode.
- `src/daemon/`: persistent CLI daemon, socket/named-pipe client, PID handling, and arg serialization.
- `src/telemetry/`: Clearcut usage logging, local daily-active state, watchdog process, and sanitized tool invocation metrics.

Important browser boundaries:

- Browser state is global per server process, not per tool call.
- The default profile is persistent under `~/.cache/chrome-devtools-mcp`; `--isolated` switches to a temporary user-data-dir.
- `new_page` can create named isolated browser contexts inside a browser for cookie/storage separation.
- Existing-browser modes can expose whatever is open in the connected Chrome profile.
- Target filtering hides `chrome://`, `chrome-untrusted://`, and extension pages by default, with exceptions for new tab and inspect pages and with extension exposure when enabled.

## Design Choices

The server intentionally uses small deterministic tools rather than a single broad "operate browser" command. The a11y-tree snapshot is the central interaction boundary: `take_snapshot` creates stable UIDs, and input tools act on those UIDs. Screenshot is available for visual inspection, but the skill explicitly prefers text snapshots for automation.

Tool categories are a useful permission surface. Emulation, performance, and network are on by default but can be disabled. Extensions, third-party developer tools, and WebMCP are off by default. Extra conditions gate experimental tools such as coordinate clicking, memory exploration, screencast, page-id routing, interop, and navigation allowlists.

The response layer is agent-oriented. Large screenshots over 2 MB are written to temp files; traces and Lighthouse reports can be saved to files; network and console lists support pagination; response bodies are truncated around 10 KB unless written to files; structured content can be enabled for CLI/programmatic use.

Network and console context is stateful but bounded. Collectors assign stable IDs and preserve data across the current plus recent navigations, which lets an agent list first and fetch details later without embedding all bodies immediately.

Security responsibility is split. The README and `SECURITY.md` state that the server exposes browser contents and powerful actions, and that clients are expected to validate tool calls and parameters. The server adds some local guardrails, but it does not try to make arbitrary browser automation safe.

Path validation uses MCP roots when the client advertises roots capability. If roots are present, writes/reads are allowed only inside roots plus the OS temp dir. If roots are absent, legacy behavior allows any path. This is practical for compatibility but important for agent hardening.

Telemetry is opt-out. Usage statistics are on by default unless `--no-usage-statistics`, `CHROME_DEVTOOLS_MCP_NO_USAGE_STATISTICS`, or `CI` is set. Tool parameters sent to telemetry are sanitized into lengths/counts and omit `uid`, `reqid`, and `msgid`, but local debug logging can still include full params when enabled.

## Strengths

The execution path is clear and testable: stdio MCP entrypoint, lazy browser launch/connect, context wrapper, serialized tool dispatch, and response formatter.

The browser-tool boundary is well shaped for agents. UIDs, selected pages, optional page IDs, isolated contexts, and action waits reduce brittle coordinate-driven automation.

The screenshot/log/network design is practical. The server uses image attachment for small screenshots, file paths for large artifacts, concise network rows first, detail fetches by request ID, console message details by message ID, and DevTools UI selected-request integration when available.

The permission model has meaningful levers: `--isolated`, roots, category flags, experimental flags, remote-debugging warnings, off-by-default extensions/third-party/WebMCP, and optional header redaction.

The test suite exercises real MCP behavior, tool registration gates, roots/path denial, dialog blocking, browser launch/connect, CLI daemon start/stop, screenshot output modes, network preservation, console issue aggregation, telemetry watchdog behavior, and CLI disabled-tool messages.

The bundled skills are unusually useful. They do not just document commands; they encode efficient agent workflows like navigate/wait/snapshot/act, LCP trace analysis, a11y snapshot plus Lighthouse, and persistent CLI use.

## Weaknesses

The server is powerful by design. `evaluate_script` runs arbitrary JavaScript in the page; input tools can mutate state; upload/download/screenshot/trace/memory tools can read or write local files; extension tools can load unpacked extensions; page-exposed third-party tools and WebMCP execute code controlled by the inspected page when enabled.

Safe defaults are mixed. Telemetry, update checks, CrUX URL lookups, persistent browser profile, and unredacted network headers are default-on or default-permissive unless flags are set. For coding-agent verification in sensitive workspaces, users should configure safer flags explicitly.

Roots enforcement depends on client support. If the MCP client does not advertise roots, `validatePath()` allows all paths for compatibility.

Remote debugging connection modes can expose real browser state. The README warns that a remote debugging port lets local applications control the browser, and `--autoConnect` can access all open windows for the selected profile after user permission.

The tool mutex serializes calls. That simplifies page state and avoids races, but limits true parallel browser operations inside one server process.

Header redaction is opt-in through `--redact-network-headers`; without it, detailed network output may include cookies or other sensitive headers.

Some high-risk controls are hidden or experimental, including navigation allowlists and page-id routing. They are useful for hardened agents but not part of the default user-facing setup.

## Ideas To Steal

Use a text snapshot plus stable UID model as the primary browser automation interface.

Separate list/detail tools for high-volume data such as network requests and console messages.

Keep heavy artifacts out of context by returning file paths for large screenshots, traces, Lighthouse reports, heap snapshots, and response bodies.

Gate tools with both categories and per-tool conditions, and test the exposed tool list against definitions.

Serialize tool calls when shared browser/page state would otherwise create hard-to-debug races.

Honor MCP roots for file reads/writes and always include temp dir as an artifact escape hatch.

Make risky modes explicit: persistent profile vs isolated profile, browser launch vs remote connection, extension tools, page-exposed tools, coordinate clicking, screencast, and insecure certs.

Ship workflow skills next to the MCP server so agents learn the intended order of operations, not just tool schemas.

## Do Not Copy

Do not expose arbitrary browser control as "safe" just because it is behind MCP. Treat it as equivalent to giving the agent DevTools control over the browser.

Do not leave sensitive projects on default settings. Prefer `--isolated`, `--headless`, `--no-usage-statistics`, `--no-performance-crux`, `--redact-network-headers`, and roots-aware clients.

Do not rely on screenshots alone for automation. The repo's own workflow prefers a11y snapshots and UIDs.

Do not let page-exposed tools or WebMCP run in untrusted sites without a separate trust decision.

Do not assume file protection exists when the MCP client lacks roots capability.

Do not copy the persistent CLI daemon pattern for sensitive sessions unless state reuse is explicitly desired and session cleanup is clear.

## Fit For Agentic Coding Lab

Fit is in-scope and strong. This is one of the clearest examples of MCP improving coding-agent verification rather than just adding information retrieval.

Agentic Coding Lab should treat it as a reference for browser-verification tools: snapshot first, act through semantic IDs, fetch diagnostics by stable IDs, write bulky artifacts to files, and make risky capabilities opt-in. It is especially applicable to frontend bug fixing, UI test debugging, accessibility review, performance optimization, network regression analysis, extension testing, and "agent sees what browser sees" verification loops.

The most reusable design pattern is not Chrome-specific: create a narrow response layer that turns a noisy runtime into compact, stable, follow-up handles for agents.

## Reviewed Paths

- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/README.md`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/SECURITY.md`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/package.json`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/server.json`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/docs/cli.md`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/docs/design-principles.md`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/docs/tool-reference.md`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/docs/troubleshooting.md`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/src/bin/chrome-devtools-mcp.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/src/bin/chrome-devtools-mcp-main.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/src/bin/chrome-devtools-mcp-cli-options.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/src/bin/chrome-devtools.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/src/browser.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/src/index.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/src/McpContext.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/src/McpPage.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/src/McpResponse.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/src/PageCollector.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/src/tools/categories.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/src/tools/ToolDefinition.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/src/tools/tools.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/src/tools/pages.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/src/tools/input.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/src/tools/screenshot.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/src/tools/snapshot.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/src/tools/network.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/src/tools/console.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/src/tools/script.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/src/tools/emulation.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/src/tools/performance.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/src/tools/lighthouse.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/src/tools/screencast.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/src/tools/memory.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/src/tools/extensions.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/src/tools/thirdPartyDeveloper.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/src/tools/webmcp.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/src/tools/slim/tools.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/src/formatters/NetworkFormatter.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/src/daemon/daemon.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/src/daemon/client.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/src/daemon/utils.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/src/telemetry/ClearcutLogger.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/src/telemetry/persistence.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/src/telemetry/WatchdogClient.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/src/telemetry/watchdog/main.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/src/telemetry/watchdog/ClearcutSender.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/src/utils/check-for-updates.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/src/utils/files.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/skills/chrome-devtools/SKILL.md`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/skills/chrome-devtools-cli/SKILL.md`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/skills/debug-optimize-lcp/SKILL.md`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/skills/a11y-debugging/SKILL.md`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/tests/index.test.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/tests/browser.test.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/tests/McpContext.test.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/tests/roots.test.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/tests/cli.test.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/tests/daemon/client.test.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/tests/daemon/utils.test.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/tests/e2e/chrome-devtools-start-stop.test.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/tests/e2e/chrome-devtools-status.test.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/tests/e2e/chrome-devtools-commands.test.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/tests/e2e/chrome-devtools-disclaimers.test.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/tests/e2e/telemetry.test.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/tests/tools/pagesNavigateAllowlist.test.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/tests/tools/screenshot.test.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/tests/tools/network.test.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/tests/tools/console.test.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/tests/formatters/NetworkFormatter.test.ts`
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/tests/telemetry/ClearcutLogger.test.ts`

## Excluded Paths

- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/.git/`: VCS internals; reviewed commit captured separately.
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/.github/`: CI and repository automation, not runtime MCP/browser behavior.
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/.agents/`, `.claude-plugin/`, `.codex/`, `.gemini/`: plugin/config packaging metadata; relevant only to distribution, not core server execution.
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/CHANGELOG.md`: release history, not needed for current execution path.
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/CONTRIBUTING.md`: contributor process, not runtime behavior.
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/LICENSE`: legal text, not runtime behavior.
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/package-lock.json`: generated dependency lock; dependency versions sampled through `package.json`.
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/docs/slim-tool-reference.md`: generated slim reference; slim behavior reviewed from `src/tools/slim/tools.ts`.
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/docs/debugging-android.md`: platform setup guide, not core MCP execution path.
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/docs/third-party-developer-tools.md`: concept docs; source implementation reviewed instead.
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/scripts/`: build, generation, eval, and release utilities; not runtime server path except package scripts sampled from `package.json`.
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/src/third_party/`: vendored/generated Lighthouse and DevTools bundles plus notices; reviewed only at boundary through imports and formatters.
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/tests/trace-processing/fixtures/*.json.gz`: compressed binary fixtures for trace parsing, not source behavior.
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/tests/fixtures/example.heapsnapshot`: large heap snapshot fixture, not needed for execution path.
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/tests/tools/fixtures/`: Chrome extension fixture files, sampled only through extension tool tests.
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/tests/*.js.snapshot` and `tests/**/*.js.snapshot`: generated test snapshots, used as test outputs rather than implementation.
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/skills/*/references/`: workflow reference snippets; sampled skill entrypoints enough to understand agent applicability.
- `/tmp/myagents-research/ChromeDevTools-chrome-devtools-mcp/release-please-config.json`, `.release-please-manifest.json`, `.prettierrc.cjs`, `eslint.config.mjs`, `tsconfig.json`, `rollup.config.mjs`, `puppeteer.config.cjs`, `.npmrc`, `.nvmrc`, `.gitattributes`, `.gitignore`: build/config metadata, not browser/tool/security execution path.
