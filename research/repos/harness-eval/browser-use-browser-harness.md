# browser-use/browser-harness

- URL: https://github.com/browser-use/browser-harness
- Category: harness-eval
- Stars snapshot: 12,134 (GitHub API `stargazers_count`, fetched 2026-05-12)
- Reviewed commit: `0e679e2c56bdc4add10befaada4674b85882e3a6`
- Reviewed at: 2026-05-12 Asia/Seoul
- Status: reviewed
- Scope fit: conditional
- Verdict: Useful browser-agent control harness and agent skill corpus, but not a browser task evaluation framework. Strongest reusable ideas are the tiny CDP-to-IPC bridge, per-agent browser namespaces, screenshot-first verification habits, session-aware event buffering, and field-tested domain skills. Missing pieces for harness-eval are task datasets, deterministic runner, durable traces, scorers, and sandbox policy.

## Why It Matters

Browser Harness is a compact reference for giving a coding agent direct control of a real browser without a large automation framework between the agent and Chrome. The project deliberately connects to an already-running Chrome or Browser Use cloud browser, exposes raw CDP plus a few helpers, and leaves task-specific learning in editable helper and skill files.

For Agentic Coding Lab, this matters less as an eval framework and more as a browser sidecar pattern. It shows how an agent can inspect, click, type, upload, scrape, and debug web tasks while accumulating site-specific playbooks. It also exposes the hard problems a proper browser eval harness must add around reproducibility, trace retention, scoring, sandboxing, and user-profile safety.

## What It Is

`browser-use/browser-harness` is a Python package installed as the `browser-harness` CLI. The command takes `-c` Python snippets, auto-starts a daemon, and pre-imports helper functions for CDP browser control. Core code is intentionally small:

- `src/browser_harness/run.py`: CLI entrypoint, update banner, optional cloud autospawn, daemon bootstrap, and `exec` of agent-supplied Python.
- `src/browser_harness/admin.py`: daemon lifecycle, diagnostics, update flow, cloud browser provisioning, cloud profile listing, and local cookie sync helpers.
- `src/browser_harness/daemon.py`: long-lived CDP WebSocket holder and IPC relay.
- `src/browser_harness/helpers.py`: browser primitives such as `cdp`, `new_tab`, `goto_url`, `page_info`, `capture_screenshot`, `click_at_xy`, `js`, `wait_for_network_idle`, `upload_file`, and `http_get`.
- `src/browser_harness/_ipc.py`: Unix socket or Windows loopback IPC plumbing.

The repository also ships `SKILL.md`, `install.md`, interaction skills, an editable `agent-workspace/agent_helpers.py`, and about 105 domain skill files. It does not contain `evals/`, a benchmark task runner, scoring logic, or persistent trace format. Tests are conventional pytest unit tests over helpers, daemon behavior, IPC safety, and admin lifecycle.

## Research Themes

- Token efficiency: The runtime surface is terse: one CLI command runs Python with helpers pre-imported, and static pages can use `http_get` instead of browser state. Domain skills reduce repeated rediscovery of selectors, waits, auth traps, and API shortcuts. The weak point is screenshot-heavy operation; screenshots are useful but can be expensive, and the repo has no prompt budget, trace summarizer, or context compaction layer.
- Context control: Core code stays under `src/browser_harness/`, while agent-authored additions are scoped to `agent-workspace/agent_helpers.py` and optional `agent-workspace/domain-skills/`. `BH_DOMAIN_SKILLS=1` gates domain skill lookup, `BH_AGENT_WORKSPACE` moves editable helpers, and `BH_TMP_DIR` / `BH_RUNTIME_DIR` can isolate runtime files. Selection is still coarse: domain skills are surfaced by host, not by task intent or context budget.
- Sub-agent / multi-agent: `BU_NAME` namespaces daemon socket, pid, log, and cloud browser state, which is useful for parallel agents. `start_remote_daemon("work")` provisions a separate Browser Use cloud browser and prints a live URL for human watch-along. The repo does not provide a planner, dispatcher, worker pool, or multi-agent protocol.
- Domain-specific workflow: This is the strongest theme. Domain skills document site-specific routes, selectors, auth walls, API alternatives, field-tested waits, CAPTCHA or bot-detection behavior, and verification snippets. Many skills explicitly say when to avoid the browser and use a public API instead.
- Error prevention: The skill instructions require screenshot verification after meaningful actions, stop on login/auth walls, prefer compositor-level coordinate clicks before DOM hacks, and re-read page state after actions. Code handles stale sessions, internal Chrome targets, session-filtered network idle, JS exception messages, PID reuse during daemon restart, explicit CDP endpoint precedence, and cloud-browser cleanup on startup failure.
- Self-learning / memory: The learning model is file-based. Agents add helpers to `agent-workspace/agent_helpers.py` and durable site knowledge to domain skills. There is no automated memory retrieval, provenance index, learned policy store, or run-to-run scoring loop beyond whatever the agent writes.
- Popular skills: Screenshot-driven exploration, coordinate clicks, raw CDP escape hatch, `page_info`, `wait_for_load`, `wait_for_network_idle`, `js` extraction, profile sync, Browser Use cloud lifecycle, and field-tested domain playbooks.

## Core Execution Path

1. The agent runs `browser-harness -c '<python>'`.
2. `run.py` handles help/version/doctor/update/reload flags, prints an update banner, and checks whether cloud autospawn is explicitly enabled through `BU_AUTOSPAWN`.
3. If no daemon is alive, no local Chrome is listening, no explicit `BU_CDP_URL` / `BU_CDP_WS` is set, and `BROWSER_USE_API_KEY` plus `BU_AUTOSPAWN` are present, `start_remote_daemon(NAME)` provisions a Browser Use cloud browser.
4. `ensure_daemon()` pings the daemon, probes a real CDP call to detect stale Chrome connections, restarts stale daemons, and starts `python -m browser_harness.daemon` as a detached subprocess.
5. `daemon.py` resolves a CDP WebSocket from `BU_CDP_WS`, `BU_CDP_URL`, Chrome `DevToolsActivePort`, or common local ports. It connects with `cdp-use`, attaches to the first real page or creates `about:blank`, and enables Page, DOM, Runtime, and Network domains.
6. The daemon wraps CDP event handling to keep a bounded event buffer and pending dialog state, then serves one JSON-line IPC request per client connection.
7. Helper calls in `helpers.py` send `{method, params, session_id}` or `{meta: ...}` over IPC. Responses return `{result}`, `{error}`, `{events}`, or daemon metadata.
8. Agent code calls helpers such as `new_tab`, `goto_url`, `capture_screenshot`, `click_at_xy`, `type_text`, `js`, `wait_for_element`, `wait_for_network_idle`, `upload_file`, and raw `cdp`.
9. If `BH_DOMAIN_SKILLS=1`, `goto_url` adds up to ten matching domain skill filenames for the host, prompting the agent to read existing site knowledge.
10. Remote daemons carry `BU_BROWSER_ID`; shutdown patches the Browser Use cloud browser to stop so billing ends and profile state persists.

## Architecture

The architecture is a thin runtime bridge:

- Browser layer: local Chrome/Chromium with remote debugging enabled, a dedicated Chrome launched by the user, or Browser Use cloud.
- Daemon layer: one long-lived CDP WebSocket holder per `BU_NAME`, with bounded event buffering and current-session tracking.
- IPC layer: POSIX uses AF_UNIX sockets under `/tmp` or `BH_RUNTIME_DIR` with restrictive umask; Windows uses loopback TCP plus a token stored in a port file.
- Helper layer: synchronous Python helpers that send CDP and daemon-control requests to the daemon.
- Admin layer: diagnostics, update checks, cloud browser provisioning, profile listing, profile sync, and remote shutdown.
- Agent workspace layer: editable helper module plus domain and interaction skills.
- Test layer: pytest unit tests and one JS helper test module, mostly mocking CDP and IPC boundaries.

There is no benchmark architecture. Browser tasks are represented as prose skills and ad hoc Python snippets, not as structured task definitions with setup, run, observe, score, and artifact contracts.

## Design Choices

- Keep `run.py` tiny and execute agent-supplied Python directly instead of building a command language.
- Prefer raw CDP strings over typed wrappers; `cdp-use` is used only as the CDP client transport.
- Connect to the user's running Chrome by default rather than launching an isolated automation browser.
- Use coordinate clicks by default because compositor-level CDP input can pass through iframes, shadow DOM, and cross-origin surfaces where selector work gets brittle.
- Keep task-specific code outside the protected package in `agent-workspace/agent_helpers.py`.
- Make domain skills opt-in with `BH_DOMAIN_SKILLS=1`; when enabled, surface skill filenames from the navigated host.
- Use explicit environment variables for isolation and routing: `BU_NAME`, `BU_CDP_URL`, `BU_CDP_WS`, `BH_AGENT_WORKSPACE`, `BH_TMP_DIR`, `BH_RUNTIME_DIR`, `BU_AUTOSPAWN`, and `BROWSER_USE_API_KEY`.
- Avoid a session manager, retry framework, logging framework, or config system. Reliability is handled with small targeted checks.
- Treat cloud autospawn as explicit opt-in, not implied by an API key, to avoid surprise billing or endpoint override.
- Add safety checks around stale sockets, stale CDP sessions, hostile ping payloads, PID reuse, and Windows local loopback authorization.

## Strengths

- Small enough to audit. The actual browser-control core is about a thousand lines across a few files.
- Direct CDP access gives agents full escape hatches for cases helpers do not cover.
- Real-profile mode is powerful for personal workflows because it inherits existing cookies, extensions, and logged-in state.
- Remote cloud mode gives parallel agents isolated browsers through separate `BU_NAME` daemons.
- The field-tested domain skill corpus is high-signal: many files record selectors, API shortcuts, auth boundaries, bot-detection traps, waits, and concrete failure modes.
- Session-aware network idle and old-session `Network.disable` handle a subtle multi-tab trace problem.
- Tests cover several practical safety regressions: endpoint precedence, stale daemon probing, PID reuse, non-dict ping payloads, session switching, and screenshot resizing.
- Issue templates require `browser-harness --doctor`, exact repro steps, environment, and troubleshooting review before bug reports.

## Weaknesses

- Not an eval framework: no task dataset schema, runner, grading interface, score aggregation, result JSON, benchmark fixtures, baseline comparison, or reproducible task reset.
- Tracing is shallow. The daemon buffers recent CDP events and writes a log, and helpers can save screenshots, but there is no durable trace artifact comparable to Playwright traces or LLM-agent spans.
- Default local mode attaches to the user's real browser profile. That is convenient but high-risk for secrets, cookies, account state, unintended purchases, and irreversible UI actions.
- `browser-harness -c` executes arbitrary Python in the caller environment. There is no code sandbox, permission prompt, filesystem policy, network policy, or restricted helper DSL.
- Browser reproducibility depends on external state: Chrome version, profile state, cookies, extensions, viewport, geolocation/proxy, cloud profile state, site A/B tests, and live web changes.
- The domain skill corpus is uneven. Some interaction skills are one-line stubs, while other domain skills are detailed and field-tested.
- No CI workflow was present under `.github/`; tests exist, but repository automation was not visible in the reviewed tree.
- Package dependencies are pinned, but there is no lockfile and no declared browser or OS matrix for repeatable harness behavior.

## Ideas To Steal

- A tiny CDP daemon plus JSON-line IPC can give coding agents browser access without exposing a large tool schema.
- Namespace runtime state by agent/session (`BU_NAME`) so parallel agents do not fight over one browser connection.
- Separate runtime socket dir from screenshot/log temp dir with `BH_RUNTIME_DIR` and `BH_TMP_DIR`.
- Make browser task learning file-based and reviewable: helper code for reusable primitives, domain skills for durable site maps.
- Prefer "API first, browser only when needed" inside domain skills to save tokens, time, and browser state risk.
- Require screenshot or state verification after meaningful actions, especially before claiming UI success.
- Keep auth-wall rules explicit: stop and ask the human rather than typing credentials from screenshots.
- Filter network-idle traces by active CDP session so background tabs do not poison current-tab waits.
- Add cloud zombie cleanup scripts as live regression artifacts for external lifecycle APIs.
- Use bug-report templates that demand doctor output, exact command, exact output, OS, browser version, and harness version.

## Do Not Copy

- Do not treat this as a complete benchmark or eval harness. It needs a task model, runner, scoring, artifacts, and reset policy before it can measure agent quality.
- Do not default a coding-agent harness to the user's personal browser profile without a clear permission and blast-radius model.
- Do not expose arbitrary Python execution as the only automation API for untrusted or unattended agents.
- Do not persist or publish domain skills that include secrets, account-specific data, pixel coordinates, or one-off task narration.
- Do not rely on screenshot-only verification when a deterministic API, DOM assertion, trace event, or test assertion can express the expected state.
- Do not allow cloud browsers to run without a timeout, stop hook, and zombie cleanup path.
- Do not copy the absence of durable traces. A coding-agent eval harness should preserve structured actions, observations, screenshots, console/network events, errors, commands, and final score.

## Fit For Agentic Coding Lab

Fit is conditional and useful. Browser Harness is a good browser-control sidecar for agent workflows, especially tasks that need a human's existing browser session or a cheap cloud browser per sub-agent. It is not by itself a harness-eval substrate because it does not define tasks, scoring, or reproducible environments.

Best adoption path:

- Use the CDP daemon and helper shape as an optional browser backend.
- Wrap it in a Lab-owned runner that defines task setup, allowed browser/session mode, exact inputs, scoring, and artifact capture.
- Default eval tasks to isolated Chrome profiles or cloud browsers, not a human's real profile.
- Store durable traces outside the prompt: action log, CDP event slices, screenshots, page info, console/network summaries, helper code diff, and final scorer output.
- Keep domain skills as reviewed, public, provenance-bearing playbooks, with lint rules banning secrets and pixel coordinates.
- Pair with Playwright for deterministic web-app QA when the target project can run local tests; use Browser Harness for exploratory, authenticated, or hard-to-script browser work.

## Reviewed Paths

- `README.md`: project positioning, setup prompt, architecture list, cloud browser pitch, domain skill contribution model.
- `SKILL.md`: day-to-day agent workflow, helper invocation shape, remote browser examples, interaction skills, screenshot/click verification rules, design constraints, gotchas, domain skill rules.
- `install.md`: installation, global skill setup, update behavior, browser connection modes, cloud/local profile behavior, IPC architecture summary, troubleshooting flow.
- `AGENTS.md`: code priorities, protected core files, editable agent workspace boundaries.
- `pyproject.toml`: package metadata, dependencies, console script, pytest config.
- `.env.example`: cloud API key loading convention.
- `docs/setup-remote-debugging.png` and `docs/allow-remote-debugging.png`: UI-only setup screenshots referenced by README.
- `src/browser_harness/run.py`: CLI control flow, cloud autospawn guard, explicit endpoint precedence, daemon ensure before `exec`.
- `src/browser_harness/admin.py`: daemon lifecycle, diagnostics, Browser Use API calls, profile sync, update path, PID-reuse-safe restart.
- `src/browser_harness/daemon.py`: CDP WebSocket resolution, first-page attach, domain enabling, event tap, IPC request handling, stale-session recovery, shutdown.
- `src/browser_harness/helpers.py`: CDP wrapper, navigation, screenshots, coordinate input, JS evaluation, waits, network idle, upload, HTTP fallback, agent helper loading.
- `src/browser_harness/_ipc.py`: socket and port-file IPC, name validation, Windows token, ping/identify sanitation, endpoint cleanup.
- `tests/unit/test_run.py`: CLI exec, cloud autospawn, endpoint precedence, local Chrome probing, stdin behavior.
- `tests/unit/test_daemon.py`: session switching, default domain enablement, network-disable behavior, parallel enable calls, current-tab metadata.
- `tests/unit/test_helpers.py`: screenshot resizing, domain-skill lookup, JS errors, input typing, element waits, network-idle behavior.
- `tests/unit/test_admin.py`: doctor output, browser connection listing, remote-daemon cleanup, restart PID safety, process start fingerprinting.
- `tests/unit/test_ipc.py`: ping and identify payload hardening.
- `tests/integration/test_js.py`: JS expression wrapping and exception handling.
- `.github/ISSUE_TEMPLATE/*.yml` and `.github/VOUCHED.td`: bug/feature report gates and bot moderation metadata.
- `interaction-skills/screenshots.md`, `connection.md`, `tabs.md`, `profile-sync.md`, `network-requests.md`, `iframes.md`, and `uploads.md`: interaction guidance quality and stub coverage.
- `agent-workspace/agent_helpers.py`: editable helper extension point.
- `agent-workspace/domain-skills/browser-use-cloud/cloud.md` and `cleanup-zombies.py`: cloud API lifecycle, provenance, and live regression script.
- `agent-workspace/domain-skills/github/repo-actions.md`: state-changing browser task skill with verification.
- `agent-workspace/domain-skills/shopify-admin/README.md`: authenticated admin workflow and auth-wall policy.
- `agent-workspace/domain-skills/amazon/product-search.md`: field-tested scraping skill and CAPTCHA detection.
- `domain-skills/amazon/cart.md` and `domain-skills/amazon/orders.md`: root-level domain skill examples outside `agent-workspace`.
- File map and targeted searches across `agent-workspace/domain-skills/**`: domain skill count, provenance patterns, auth guidance, API-first guidance, bot/CAPTCHA handling, screenshot verification, and live-test claims.

## Excluded Paths

- `.git/`: VCS internals, not review material.
- `docs/*.png` beyond file identity and README context: binary UI screenshots for setup, not architecture.
- Full line-by-line review of all `agent-workspace/domain-skills/**`: the corpus has about 105 files and many are site-specific playbooks. I sampled representative authenticated, scraping, cloud, admin, and shopping skills and searched the corpus for provenance, auth, CAPTCHA, screenshot, wait, and verification patterns.
- Most individual domain-skill implementation details for sites such as Steam, Walmart, Glassdoor, Facebook, YouTube, Medium, and others: useful operational playbooks, but not central to harness architecture.
- One-line interaction skill stubs such as `downloads.md`, `uploads.md`, `viewport.md`, `cookies.md`, and similar files: noted as quality gaps, not summarized as implemented features.
- `.github/VOUCHED.td` user list details: reviewed only as bot/moderation metadata; individual handles are unrelated to browser harness design.
- GitHub issue template prose beyond required fields: useful for QA workflow, but not execution architecture.
- External blog links and Browser Use hosted docs linked from README: outside the cloned repo snapshot and not needed to understand the local code path.
