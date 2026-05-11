# microsoft/playwright

- URL: https://github.com/microsoft/playwright
- Category: harness-eval
- Stars snapshot: 88,446 (GitHub API `stargazers_count`, fetched 2026-05-12)
- Reviewed commit: `cdfe71c7aeb14ead4acad3dcfc98dc0154e559e5`
- Reviewed at: 2026-05-12 Asia/Seoul
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong reference implementation for browser verification harnesses. Use Playwright directly for browser QA where possible, and copy selected harness patterns: isolated browser contexts, actionability checks, retrying assertions, failure-scoped traces, report multiplexing, and agent loops that turn live browser interactions into tests.

## Why It Matters

Playwright is one of the most mature open-source browser verification stacks. It is not only a browser automation library; the repo contains a full test runner, worker scheduler, fixture system, auto-waiting action model, assertion layer, trace recorder, HTML/blob/JSON reporters, MCP browser tools, and dedicated test-planner/test-generator/test-healer agent workflows.

For an agentic coding lab, it is important because it makes browser work verifiable instead of screenshot-driven guesswork. A coding agent can run a seed test, pause in a real browser state, inspect an accessibility snapshot, perform tool actions, record generated test code, rerun failures, and preserve traces or reports for review.

## What It Is

`microsoft/playwright` is a TypeScript monorepo for web testing and automation across Chromium, Firefox, and WebKit. The core layers are:

- `packages/playwright-core`: browser server, protocol plumbing, browser context management, actionability, tracing, MCP/browser tools, and browser-specific launch logic.
- `packages/playwright`: Playwright Test runner, fixtures, matchers, reporters, agents, and test-specific MCP tools.
- `packages/trace`: trace event schema used by the runner and core browser recorder.
- `tests`: broad self-tests for runner behavior, trace/report artifacts, MCP tools, browser actions, context reuse, and assertions.
- `docs`: public guidance for configuration, agents, MCP, assertions, traces, reporters, and best practices.

The repo also includes browser patch maintenance, language bindings, UI apps, docs site assets, and examples. Those are secondary for this review.

## Research Themes

- Token efficiency: The README explicitly positions Playwright CLI for coding agents as more token-efficient than MCP because CLI commands avoid large tool schemas and accessibility trees. The harness also supports compact dot/line reporters, JSON for machine parsing, terminal truncation of long attachment bodies, optional HTML snippet/copy-prompt suppression, and failure-only trace/video modes. MCP paused messages use ARIA snapshots instead of screenshots by default, which is cheaper than vision but still can become large on complex pages.
- Context control: Tests get fresh browser contexts by default, while context reuse is opt-in and reset between tests. Test output paths are contained under each test output directory. Trace viewer file serving is restricted to allowed roots. MCP planner/generator file writes resolve inside workspace roots, and generator test writes must land inside configured `testDir` paths. Reporter output normalizes paths and strips ANSI where needed.
- Sub-agent / multi-agent: The docs and `packages/playwright/src/agents` define a planner, generator, and healer loop. Planner explores a seeded app and saves a structured test plan. Generator executes plan steps in a live browser and writes Playwright specs. Healer runs/debugs failing tests, inspects page state/network/console, edits tests, and reruns until pass or fixme.
- Domain-specific workflow: The runner has projects, dependencies, global setup/teardown, web servers, fixtures, browser matrices, sharding, retries, last-failed filters, trace/video/screenshot artifacts, HTML/blob/JSON/JUnit/GitHub reporters, and MCP-backed seed/debug flows.
- Error prevention: Browser actions enforce actionability checks before clicking/filling/etc. Assertions retry until timeout. Locators are strict and user-facing selectors are encouraged. Workers are restarted after failures. Serial suite retry semantics keep dependent tests coherent. Timeout managers classify test/hook/fixture phases.
- Self-learning / memory: There is no durable semantic memory system. The closest equivalents are last-run failure cache, generated plans/specs, per-session generator journals, traces, reports, storage state, and artifacts. These are useful episodic artifacts, not learned policy.
- Popular skills: Locators, web-first assertions, fixture design, trace-on-retry, report triage, storage state, network mocking, project matrices, planner/generator/healer agents, and MCP snapshot-driven browser interaction.

## Core Execution Path

1. The CLI loads config and builds CLI overrides for trace/video/headed/debug/reuse/workers/snapshots/reporters.
2. Runner tasks apply rebaselines, run global setup, load tests out of process, apply grep/location/test-list/changed/last-failed filters, and create project dependency phases.
3. Test groups are built by project id, worker hash, required file, repeat index, parallel mode, and serial-suite constraints.
4. The dispatcher schedules groups across `WorkerHost` child processes, respecting global and per-project worker limits. Failed tests or serial groups are unshifted for retry when retry budget remains.
5. Each worker loads the test file, creates `TestInfoImpl`, resolves fixtures, starts test tracing when configured, runs before hooks, the test function, after hooks, fixture teardown, and artifact preservation logic.
6. The Playwright fixtures launch one browser per worker and normally create one browser context and page per test. Context reuse is only allowed when compatible with artifact settings and is reset between tests.
7. Core browser/server code executes actions through progress controllers, actionability retries, frame/DOM helpers, browser contexts, downloads, permissions, storage state, and tracing instrumentation.
8. Reporters receive begin/test/step/stdout/stderr/attach/end events through a multiplexer. Terminal reporters print concise summaries, JSON/blob reporters emit machine-readable data, and HTML embeds report data and trace links.
9. Agent workflows use a seed test to pause a real test context, initialize a testing-capable browser MCP backend, return page URL/title/ARIA snapshot, accept tool calls with `intent`, journal generated actions, and rerun/debug tests.

## Architecture

Playwright has a layered harness:

- Runner layer: `testRunner.ts`, `tasks.ts`, `dispatcher.ts`, `workerHost.ts`, and `processHost.ts` manage config, phases, worker processes, IPC, retries, interrupts, and reporter lifecycle.
- Worker layer: `workerMain.ts`, `testInfo.ts`, `fixtureRunner.ts`, `timeoutManager.ts`, and `testTracing.ts` handle test execution, fixtures, errors, stdout/stderr attribution, output paths, and test-level trace zips.
- Browser fixture layer: `packages/playwright/src/index.ts` defines `browser`, `context`, `page`, `request`, video, screenshot, trace, and reuse fixtures.
- Browser server layer: `browser.ts`, `browserType.ts`, `browserContext.ts`, `dom.ts`, `frames.ts`, and browser-specific launch files implement context creation, process launch, permissions, storage, actionability, locator waits, and assertion polling.
- Trace layer: test-level tracing in `packages/playwright/src/worker/testTracing.ts` wraps core tracing in `packages/playwright-core/src/server/trace/recorder`. Events are typed by `packages/trace/src/trace.ts` and shown by the trace viewer server.
- Reporter layer: base, list/line/dot, JSON, blob, HTML, JUnit, GitHub, multiplexer, and internal reporters produce human and machine output. Blob reports support shard merge with attachment path patching.
- Agent/MCP layer: `packages/playwright/src/agents` generates editor-agent definitions; `packages/playwright/src/mcp/test` exposes planner/generator/test/debug tools over a paused test; `packages/playwright-core/src/tools` provides browser MCP tools and file/root controls.

## Design Choices

- Per-test isolation is the default: one fresh browser context/page per test, with per-worker browser processes for efficiency.
- Failed workers are stopped and replaced, reducing hidden cross-test contamination after unhandled exceptions or browser state corruption.
- Actions are guarded by actionability: visible, stable, receives events, enabled, editable, and strict element resolution depending on action.
- Assertions are "web-first": they refetch and retry until timeout instead of snapshotting a stale element once.
- Trace and video collection are failure-scoped by common config (`on-first-retry`, `retain-on-failure`) to keep artifact volume manageable.
- Runner/reporters separate concise console output from rich artifacts. JSON/blob output is suitable for machine consumers, while HTML is for human triage.
- MCP agent flows use the existing runner instead of a separate browser harness. Seed tests run setup/projects/fixtures, then pause in the same test environment the generated specs will use.
- Path controls are explicit in several places: `resolveWithinRoot`, `isPathInside`, test output containment, trace viewer allowed roots, and MCP file upload/write restrictions.

## Strengths

- Mature end-to-end verification stack with real browser behavior, not DOM mocks.
- Excellent failure forensics: action logs, ARIA snapshots, screenshots/videos, traces, stdout/stderr, source snippets, network, console, and HTML report links.
- Strong anti-flake defaults: auto-waiting, retrying assertions, isolated contexts, worker restart after failures, fixture teardown ordering, and timeout phase labels.
- CI-ready outputs: dot/list/line, JSON, JUnit, GitHub annotations, sharded blob reports, merged HTML, and command-hash report naming.
- Agent-specific QA workflows are first-class, not a thin prompt around generic automation.
- Accessibility-tree snapshots and locator codegen provide a practical middle ground between raw screenshots and brittle selectors.
- Multiple containment checks reduce accidental file/root escapes in traces, uploads, generated tests, and output files.

## Weaknesses

- The full stack is large and browser-dependent. Adopting internals wholesale would bring substantial dependency, install, and maintenance cost.
- Traces and reports can capture sensitive DOM, network, console, attachments, storage-derived behavior, and source snippets. Artifact retention needs policy.
- Chromium launch defaults add `--no-sandbox` unless `chromiumSandbox: true` is requested. MCP CLI also has explicit `--sandbox`/`--no-sandbox` controls. This is operationally convenient but security-sensitive.
- `browser_run_code_unsafe` is intentionally dangerous and documented as trusted-client-only. Tests show guardrails such as no `require`, but it is still an arbitrary browser-control escape hatch.
- Planner/generator save/write tools are marked `readOnly` in tool schemas despite writing files. The path checks are good, but the permission label is misleading for agent policy systems.
- ARIA snapshots are cheaper than screenshots, but broad pages can still produce too much context. A downstream agent harness needs budgets and summarization.
- There is no built-in long-term learning loop. Generated plans/tests and traces are artifacts, not memory.

## Ideas To Steal

- Treat browser verification as a first-class harness with projects, retries, workers, traces, and machine-readable reports, not as ad hoc browser scripting.
- Capture traces as structured event zips with `before`, `input`, `after`, `stdout`, `stderr`, `error`, `resource-snapshot`, and `frame-snapshot` events.
- Use failure-only trace/video/screenshot policies by default to control cost.
- Add a pause-on-error debug bridge that returns URL, title, console/network context, and an ARIA snapshot, then lets an agent inspect and repair before rerun.
- Require an `intent` field on agent browser actions and journal the resulting Playwright code, so exploration can become a reproducible test.
- Keep file writes path-contained and test-dir-contained, and make output directories per test.
- Split output channels: concise terminal summary, strict JSON for agents, blob for shard merge, rich HTML/trace for humans.
- Restart workers after failures and make serial retries rerun coherent groups, not single dependent tests in isolation.
- Embed best-practice constraints in the generator journal: prefer locators/assertions, avoid sleeps, avoid `networkidle`, and validate each step live.

## Do Not Copy

- Do not reimplement the browser protocol/server stack unless building a browser automation product.
- Do not copy the default `--no-sandbox` posture without a deployment-specific threat model.
- Do not expose `browser_run_code_unsafe` to untrusted clients or unreviewed autonomous agents.
- Do not label file-writing tools as read-only in an agent permission model.
- Do not keep full traces, sources, network payloads, or screenshots indefinitely without redaction and retention controls.
- Do not use the HTML/trace viewer UI internals as a model for context output. The useful harness pattern is the artifact contract, not the UI implementation.
- Do not rely on screenshot/vision inspection where ARIA snapshots, locators, and assertions can express the state.

## Fit For Agentic Coding Lab

Fit is high. Playwright should be an integration target and a pattern source for any coding-agent system that needs browser QA. The most practical adoption path is:

- Run Playwright Test directly for web projects with `line` or `dot` plus JSON/blob output for the agent.
- Default traces to `retain-on-failure` or `on-first-retry`, and attach only concise links or summarized trace facts to the coding context.
- Use a planner/generator/healer loop for test creation, but wrap file writes in an explicit permission layer that distinguishes read, write, and unsafe execution.
- Feed agents ARIA snapshots, locator suggestions, focused console/network failures, and test error snippets before resorting to screenshots.
- Preserve trace/report artifacts outside the prompt, with stable references and retention/redaction policy.

The direct code to borrow is limited; the architectural shape is the valuable part.

## Reviewed Paths

- `README.md`: product scope, Playwright Test positioning, CLI/MCP agent notes, trace and browser isolation claims.
- `docs/src/intro-js.md`: runner features, config, report, UI mode, and trace positioning.
- `docs/src/best-practices-js.md`: locator, isolation, assertion, debugging, and trace recommendations.
- `docs/src/actionability.md`: auto-wait/actionability matrix and force behavior.
- `docs/src/test-assertions-js.md`: retrying assertions, soft assertions, `expect.poll`, and `expect.toPass`.
- `docs/src/trace-viewer-intro-js.md` and `docs/src/trace-viewer.md`: trace modes, trace viewer capabilities, local/remote trace handling, and trace privacy note.
- `docs/src/test-reporters-js.md`: built-in reporters, blob merge, custom reporters, and HTML options.
- `docs/src/test-configuration-js.md`: project/retry/worker/webServer/trace/output/snapshot config surface.
- `docs/src/test-agents-js.md`: planner/generator/healer workflow and seed-test model.
- `docs/src/getting-started-mcp.md`: MCP snapshot model, tools, profile modes, headless/isolated modes, and unsafe code warning.
- `packages/playwright/src/runner/testRunner.ts`: top-level runner, CLI overrides, reporter creation, global setup, task orchestration.
- `packages/playwright/src/runner/tasks.ts`: task runner, loading, phases, output cleanup, dependencies, and dispatch.
- `packages/playwright/src/runner/dispatcher.ts`: worker scheduling, retries, serial handling, max-failure stop, reporter event routing.
- `packages/playwright/src/runner/testGroups.ts`: grouping and sharding semantics.
- `packages/playwright/src/runner/workerHost.ts` and `processHost.ts`: worker fork, artifact dirs, IPC, shutdown, and stderr/stdout capture.
- `packages/playwright/src/worker/workerMain.ts`: worker execution lifecycle, errors, hooks, fixtures, tracing, pause/debug flow.
- `packages/playwright/src/worker/testInfo.ts`: output path guard, attachments, steps, errors, snapshot paths, trace integration.
- `packages/playwright/src/worker/fixtureRunner.ts` and `timeoutManager.ts`: fixture dependency setup/teardown and phase-specific timeout control.
- `packages/playwright/src/worker/testTracing.ts`: test trace modes, attachment/source dedupe, trace zipping, stdout/stderr/error events.
- `packages/playwright/src/index.ts`: browser/context/page fixtures, per-test isolation, context reuse, video/screenshot/trace integration.
- `packages/playwright/src/reporters/internalReporter.ts`, `multiplexer.ts`, `base.ts`, `json.ts`, `blob.ts`, `html.ts`, `merge.ts`, and `runner/reporters.ts`: reporter fanout, terminal formatting, JSON/blob/HTML output, merge path checks, command hashing.
- `packages/playwright/src/agents/*`: generated planner/generator/healer agent instructions and provider config generation.
- `packages/playwright/src/mcp/test/*`: test MCP backend, planner/generator/test tools, seed/debug execution, paused browser backend, generator journal.
- `packages/playwright-core/src/server/browser.ts`, `browserType.ts`, `browserContext.ts`, `chromium/chromium.ts`: browser launch, context lifecycle, permissions/storage, sandbox flags, profile/temp dirs.
- `packages/playwright-core/src/server/dom.ts`, `frames.ts`, and `progress.ts`: actionability retries, locator wait/assertion retry loops, progress cancellation/timeouts.
- `packages/playwright-core/src/server/trace/recorder/tracing.ts` and `snapshotter.ts`: core trace chunks, HAR/network/resource snapshots, DOM snapshots, screencast throttling.
- `packages/playwright-core/src/server/trace/viewer/traceViewer.ts`: local trace viewer HTTP server and allowed-root file serving.
- `packages/playwright-core/src/tools/mcp/program.ts`, `tools/backend/context.ts`, and `tools/utils/mcp/server.ts`: MCP CLI options, roots, output/file access checks, and server lifecycle.
- `packages/utils/fileUtils.ts`: path containment helpers.
- `packages/trace/src/trace.ts`: trace event schema.
- `tests/playwright-test/runner.spec.ts`: worker failure, interrupt, forbidOnly, duplicate titles, teardown, and JSON interruption behavior.
- `tests/playwright-test/playwright.trace.spec.ts`: trace-on-retry, action tree, sources, multi-context traces, and trace integrity.
- `tests/playwright-test/reporter-json.spec.ts`, `reporter-blob.spec.ts`, and `playwright.artifacts.spec.ts`: machine output, shard/blob merge, HTML merge, screenshots/videos/error context artifacts.
- `tests/playwright-test/playwright.reuse.spec.ts`: context reuse and reset behavior, trace with reused context, storage cleanup.
- `tests/playwright-test/expect.spec.ts`: assertion output control, huge diff truncation, custom messages, type coverage.
- `tests/mcp/planner.spec.ts`, `generator.spec.ts`, `test-debug.spec.ts`, `files.spec.ts`, `roots.spec.ts`, and `run-code.spec.ts`: agent seed/debug flow, intent journaling, generated test writes, root-restricted files, and unsafe-code behavior.

## Excluded Paths

- `browser_patches/`: browser fork patch payloads and maintenance machinery. Important to Playwright maintainers, but not transferable harness-eval architecture.
- Generated protocol/type files such as `packages/playwright-core/src/server/chromium/protocol.d.ts` and other generated API/protocol surfaces: too large and protocol-specific; reviewed only when search results referenced them, not as design material.
- `packages/*/lib`, build outputs, bundled Vite assets, and generated report/viewer assets: generated distribution artifacts, not source architecture.
- `packages/html-reporter/src/*`, trace viewer UI component trees, CSS, icons, images, and docs screenshots: UI-only implementation. I reviewed reporter/server integration and artifact contracts instead.
- Language binding implementation for Python, Java, and .NET, plus language-specific docs not tied to the JavaScript runner: useful product surface, but unrelated to coding-agent harness patterns in this pass.
- `examples/` and tutorial/demo projects: examples of usage, not the verification architecture itself.
- Binary and fixture assets under tests, including screenshots, videos, certificates, downloads, image fixtures, and snapshot baselines: necessary for upstream tests, but not meaningful to summarize as architecture.
- Android driver, WebView-specific plumbing, browser-specific protocol details, and browser patch build scripts: outside the assigned focus on browser verification harness, traces, reporters, runner, server, permissions, and agent QA workflows.
