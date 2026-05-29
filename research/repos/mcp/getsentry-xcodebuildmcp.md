# getsentry/XcodeBuildMCP

- URL: https://github.com/getsentry/XcodeBuildMCP
- Category: mcp
- Stars snapshot: 5,771 (GitHub REST API repository search, captured 2026-05-29)
- Reviewed commit: 9d56189bb7d835cf220329f13b6fe53b5c887922
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: conditional
- Verdict: Strong reference for a domain-specific MCP boundary around Apple platform build, test, simulator, device, UI automation, and debugging work. It is useful for Agentic Coding Lab as an example of workflow-scoped tools, session defaults, structured artifacts, and agent-facing skills, but it should be treated as a trusted local executor rather than a security sandbox.

## Why It Matters

Apple platform coding agents need more than generic shell access. A useful iOS/macOS agent has to discover schemes, select simulator or device destinations, run `xcodebuild`, preserve logs and `.xcresult` bundles, install and launch apps, inspect UI state, and recover from build/test failures without asking the model to memorize Xcode command-line details.

XcodeBuildMCP is a mature example of turning that domain into an MCP tool surface. It keeps the important local capabilities, but wraps them in typed schemas, workflow gating, session defaults, structured outputs, next-step hints, and bundled agent skills. The repo is especially relevant because it shows how much domain-specific machinery is required before "run tests" becomes reliable for an agent in a high-friction native toolchain.

## What It Is

XcodeBuildMCP is a TypeScript MCP server and CLI package named `xcodebuildmcp`. `xcodebuildmcp mcp` starts a stdio MCP server, while the same tool catalog is exposed through direct CLI commands. The server describes itself as `com.xcodebuildmcp/XcodeBuildMCP`, targets Node 18+, and is distributed with an MCP `server.json`.

The core feature set is split into workflow manifests. The simulator workflow is enabled by default. Device, macOS, Swift package, UI automation, debugging, Xcode IDE bridge, project discovery, project scaffolding, session management, and workflow discovery are available through manifests and can be enabled through config or environment variables. The repo also ships two agent skills: one for MCP usage and one for CLI usage.

The implementation is not a remote build service. It runs local `xcodebuild`, `xcrun simctl`, `xcrun devicectl`, `lldb`, AXe, and optional Xcode MCP bridge commands on the user's machine, with local Xcode signing, keychain, simulator, and device state.

## Research Themes

- Token efficiency: Workflow manifests limit the exposed tool set, with only simulator tools enabled by default. Session defaults hide default-backed parameters from public MCP schemas, so repeated build/test calls do not need to resend workspace, scheme, simulator, configuration, and derived-data arguments. Next-step metadata nudges the agent toward a smaller action set after each result.
- Context control: Tool visibility is controlled by workflow selection, runtime availability, predicates, and Xcode-agent mode. The MCP instructions tell agents to call `session_show_defaults` before build/run/test, avoid speculative `discover_projs`, and prefer high-level combined tools such as `build_run_sim`.
- Sub-agent / multi-agent: The repo is not a multi-agent system. Its main concurrency pattern is a local daemon for stateful operations, Unix socket ownership checks, per-workspace locks/state, and per-simulator UI automation serialization. Those pieces are still relevant for coordinating agent-initiated long-running local tools.
- Domain-specific workflow: This is the main contribution. It encodes Apple build/test/run flows for simulator, device, macOS, Swift packages, UI automation, LLDB debugging, coverage, project discovery, and optional Xcode IDE bridge calls.
- Error prevention: Zod schemas, session-aware argument merging, exclusive path checks, simulator/device resolution, structured build/test parsers, result-bundle handling, managed logs, and explicit next steps reduce common agent mistakes. Command execution mostly uses `spawn(executable, args)` rather than shell string composition.
- Self-learning / memory: There is no self-learning loop. Persistent memory is limited to project/session defaults in `.xcodebuildmcp/config.yaml`, managed workspace state, result artifacts, logs, and daemon metadata.
- Popular skills: The bundled `skills/xcodebuildmcp` and `skills/xcodebuildmcp-cli` are good compact examples of pairing an MCP tool server with agent-operating instructions: prefer MCP tools over raw shell, inspect session defaults first, use discovery only when defaults are missing or wrong, and report exact next commands.

## Core Execution Path

MCP startup flows from `src/cli.ts` to `startMcpServer`, then through `bootstrapRuntime`. Bootstrap loads config, detects whether the process is running inside Xcode agent mode, registers workflow manifests, registers resources, and optionally starts the Xcode IDE bridge manager. `src/server/server.ts` creates the stdio MCP server, exposes list-changed/resource/logging capabilities, and wraps requests with Sentry configured not to record tool inputs or outputs.

Tool registration is manifest-driven. YAML workflow and tool manifests are validated by `src/core/manifest/load-manifest.ts` and `schema.ts`. `src/utils/tool-registry.ts` imports the referenced handler modules, applies visibility predicates, attaches annotations and structured output schemas, and converts handler results into MCP `content`, `structuredContent`, and `isError`.

Build/test tools use `src/utils/typed-tool-factory.ts` to merge explicit arguments with session defaults, reject missing required defaults, enforce mutually exclusive project/workspace choices, sanitize empty values, and return structured validation errors. Public schemas are narrowed when session defaults exist, which is a practical context-control pattern for agents.

Simulator build flows call `executeXcodeBuildCommand`, which assembles `xcodebuild` arguments for workspace/project, scheme, configuration, destination, derived data, package cache, and optional `extraArgs`. The xcodebuild pipeline captures logs under the managed workspace directory, parses events into diagnostics and summaries, and returns a structured build result plus artifacts such as `buildLogPath`.

`build_run_sim` composes several domain steps: build, resolve the app bundle path from build settings, resolve or boot the simulator, best-effort open the Simulator app, install the app with `simctl`, extract the bundle identifier, launch the app, and attach runtime/OS logging. The returned artifacts include app path, bundle id, process id, simulator id, build log, runtime log, and OS log path.

Simulator and device test flows create or respect an `.xcresult` result bundle path. Simulator tests can use a two-phase build-for-testing/test-without-building plan after preflight. Test results are parsed for failures, counts, diagnostics, and result-bundle artifacts so the agent can inspect failures without scraping raw console output.

Device build/run/test tools mirror the simulator structure but use `devicectl` for install and launch. They require a `deviceId` and rely on local Xcode signing/provisioning configuration rather than collecting credentials or managing signing identities themselves.

UI automation uses AXe snapshots as a temporary runtime model. `snapshot_ui` captures accessibility state, stores a per-simulator in-memory snapshot with a sequence number, screen hash, element refs, and supported actions, then action tools such as tap resolve element refs against that current snapshot, clear it after action, and try to capture a settled post-action snapshot. Debugger guard logic can block UI actions when the app appears paused.

## Architecture

The repo has a clear split between manifest definitions, runtime registration, tool handlers, shared execution utilities, and optional stateful daemons.

Manifests under `manifests/workflows`, `manifests/tools`, and `manifests/resources` define the MCP surface. They include workflow defaults, tool module references, runtime availability, predicates, annotations, structured output schemas, and next-step templates. This makes the tool boundary inspectable outside the TypeScript implementation and gives the project a single place to tune what agents see.

Runtime config is layered from defaults, `config.example.yaml` shape, environment variables, project config, and session defaults. `src/utils/config-store.ts`, `project-config.ts`, `session-store.ts`, and `session-default-args.ts` normalize workspace/project paths, simulator/device defaults, platform selection, workflow lists, telemetry flags, and incremental-build settings.

Execution utilities live mostly under `src/utils`. `command.ts` centralizes command execution, `build-utils.ts` assembles xcodebuild invocations, `xcodebuild-pipeline.ts` and related parser modules convert raw xcodebuild output into domain results, and log/result-bundle utilities manage filesystem layout under `~/Library/Developer/XcodeBuildMCP/workspaces/<workspace-key>/`.

Stateful operations use a daemon. `src/daemon.ts` and `src/daemon/*` provide a length-prefixed JSON protocol over a Unix socket in `/tmp/xcodebuildmcp-<hash>/d.sock`. Socket directories and registry files are created with restrictive permissions and ownership checks. This is used for operations that need process state, such as debugging, UI automation, video recording, Swift run/stop, and Xcode IDE bridge interactions.

The optional Xcode IDE bridge connects to Apple's `xcrun mcpbridge`, lists remote Xcode tools, dynamically registers proxy tools, and provides a generic `xcode_ide_call_tool`. Raw bridge arguments and responses are saved as local artifacts with restrictive file permissions.

Sentry is integrated for internal runtime telemetry. The implementation disables default PII, strips request/user/breadcrumb data, redacts user home paths, and configures MCP request wrapping with `recordInputs: false` and `recordOutputs: false`. Telemetry can be disabled through config or `XCODEBUILDMCP_SENTRY_DISABLED=true`.

## Design Choices

Defaulting to the simulator workflow is a strong context and safety choice. Simulator build/test/run is the most common agent loop and avoids immediately exposing device install, LLDB, UI mutation, or Xcode bridge tools. Additional workflows can be enabled explicitly through `XCODEBUILDMCP_ENABLED_WORKFLOWS` or config.

The session-default model is the most reusable design. Instead of forcing every MCP tool call to carry `workspacePath`, `scheme`, `simulatorId`, `configuration`, and platform, the server can store defaults, hide them from schemas, and validate tools against the merged argument set. This lowers token cost while still preserving typed validation.

The repo favors high-level workflow tools over primitive command wrappers. `build_run_sim` and `build_run_device` are more agent-friendly than separate build, path lookup, boot, install, and launch calls, but the primitive tools remain available when the agent needs to recover or inspect intermediate state.

Artifacts are first-class. Build logs, test result bundles, runtime logs, OS logs, coverage files, and bridge response artifacts are surfaced explicitly in structured output, not left as implicit side effects. A workspace filesystem lifecycle prunes old logs/result bundles while protecting fresh and live files.

Command execution is intentionally centralized. Most commands are spawned with an executable and argument array. Shell mode exists for a few platform and simulator-management paths, but arguments are escaped with a POSIX single-quote strategy. This avoids the common mistake of interpolating model-controlled strings into a shell command.

The project treats signing and credentials as local Xcode concerns. Device tools do not ask the agent for certificates, profiles, Apple IDs, or passwords. This keeps secret handling out of the MCP protocol, but also means failures surface as Xcode diagnostics rather than preflighted credential state.

Tool annotations are used as hints, not as a complete policy model. This is visible in the manifest layer and should be copied carefully: some tools that mutate UI or simulator state are still marked with read-only hints, so an MCP client should not rely solely on annotations for approval decisions.

## Strengths

The MCP boundary is meaningfully domain-specific. It wraps Xcode and Apple device/simulator tools into operations an agent actually needs: discover projects, set session defaults, build, test, run, collect artifacts, inspect UI state, interact with UI elements, attach debuggers, and handle coverage.

The structured result model is strong. Build and test tools return domain summaries, diagnostics, failure details, artifact paths, and next-step suggestions. That is much more useful for an agent than raw terminal output.

Workflow-scoped tool exposure is a practical answer to context bloat. The default simulator surface keeps first-run MCP schemas manageable while still allowing advanced workflows for device, macOS, LLDB, UI automation, and Xcode IDE control.

Session defaults make repeated local workflows ergonomic. The MCP instructions and bundled skill both teach agents to inspect defaults first, avoid redundant discovery, and use combined tools when possible.

The simulator workflow is comprehensive. It covers listing, booting, opening, building, installing, launching, stopping, screenshots, videos, location/status-bar changes, and app path/bundle lookup. Build-run includes runtime and OS logging, which is exactly the artifact trail agents need.

Command execution is safer than a generic shell MCP. The dominant path uses `spawn` with arrays, centralized logging, typed validation, and managed artifact locations. Shell use is narrow and escaped.

The test suite is broad. There are unit tests across tool handlers and utilities, schema fixture validation, snapshot tests, and smoke-test harnesses for MCP invocation, discovery, sessions, UI automation, device/macOS flows, scaffolding, and error paths.

The repo ships agent skills alongside the server. That is important for research because the tool boundary and the agent operating procedure evolve together rather than relying on each client to invent usage rules.

## Weaknesses

This is not a security sandbox. A connected agent can build and run local code, install apps, manipulate simulators, erase simulator state, invoke LLDB commands, pass `xcodebuild` `extraArgs`, choose external paths, and proxy through Xcode IDE bridge tools if those workflows are enabled. It needs trusted local execution and client-side approval policy.

`extraArgs` is intentionally powerful. The arguments are not shell-injected, but they are appended directly into `xcodebuild` invocations before the action. An agent can alter build semantics, override or duplicate flags, set build settings, or route outputs outside the managed defaults.

Path handling is pragmatic rather than sandboxed. Project, workspace, derived-data, app, and result-bundle paths can be absolute or home-expanded local paths. Project discovery has root normalization checks, but the overall tool suite does not enforce a repository-only filesystem boundary.

MCP annotations are imperfect. Several UI automation and simulator state-changing tools use `readOnlyHint: true`, while destructive or mutating behavior is obvious from the implementation. Consumers should inspect workflow/tool names and arguments, not only annotations.

Device signing is mostly implicit. The device tools depend on Xcode projects, keychains, certificates, provisioning profiles, and trust state already being correct. The README documents that requirement, but there is no dedicated signing-credential model or robust preflight beyond Xcode/devicectl errors.

The official CI workflow runs on Ubuntu. It can run TypeScript build, lint, typecheck, unit tests, schema fixtures, and mocked/snapshot coverage, but it cannot exercise real macOS/Xcode/simulator/device behavior by default. The live native-tool surface is therefore more dependent on local manual use and smoke harnesses than CI.

The Xcode IDE bridge is high trust. It dynamically proxies tools from `xcrun mcpbridge` and has a generic call tool that accepts arbitrary argument records. Raw request/response artifacts are written with 0600 permissions, but not redacted.

Telemetry is opt-out. Sentry is carefully configured not to capture tool inputs or outputs and redacts user paths, but users requiring zero external telemetry need to disable it explicitly.

## Ideas To Steal

Use manifest-driven workflow gates for large MCP servers. Default to the smallest common workflow, then let users enable advanced domains through config or environment variables.

Adopt session defaults as a first-class MCP concept. Store project, workspace, scheme, platform, simulator/device, configuration, and derived-data defaults, then hide those parameters from public schemas once known.

Return structured domain results with artifacts and next steps. Build/test/run tools should not just return logs; they should surface diagnostics, counts, failing tests, result bundles, runtime logs, app identifiers, and the next safe operation.

Pair MCP servers with compact skills. The included skills are short but valuable because they teach agents when to discover, when to use defaults, when to prefer combined tools, and how to report results.

Centralize command execution and logging. A single executor plus log-capture pipeline makes it much easier to reason about injection risk, environment, lifecycle, and artifact retention.

Model UI automation as snapshot refs with a short TTL. The snapshot/action/post-action pattern is a useful way to keep element references grounded in current UI state and avoid acting on stale accessibility trees.

Expose local state through resources and artifacts instead of hiding it in prose. Workspace logs, result bundles, bridge artifacts, session defaults, and workflow metadata give agents concrete handles for recovery.

Treat optional high-risk domains as opt-in workflows. Device install, LLDB, UI automation, project scaffolding, and Xcode IDE bridge are useful, but they should not appear in the default tool surface.

## Do Not Copy

Do not copy the tool annotations as an approval policy. Some mutating tools are annotated as read-only, so approval and safety decisions need a separate policy layer.

Do not expose `extraArgs` or arbitrary pass-through bridge calls without considering local trust boundaries. They are useful for expert workflows, but they turn a typed MCP operation back into a high-capability local command surface.

Do not assume logs and artifacts are safe to share. Build settings, Xcode output, `.xcresult` bundles, raw bridge responses, and runtime logs can contain project metadata, paths, team identifiers, device names, or app data.

Do not treat the Ubuntu CI signal as proof that live simulator/device flows work everywhere. A project borrowing this pattern should add macOS/Xcode integration tests if it depends on those paths.

Do not move signing credentials into the agent loop just because device workflows need them. The safer design is to keep signing in Xcode/keychain and give the agent diagnostics, not secrets.

Do not rely on a generic shell MCP for this domain if a domain tool boundary is feasible. The value here comes from typed defaults, simulator/device abstractions, result parsing, and workflow-specific recovery.

## Fit For Agentic Coding Lab

This is a strong `mcp` index candidate because it demonstrates how a specialized local MCP server can turn a difficult developer toolchain into agent-sized actions. It is most valuable as a design study for MCP tool boundaries, not as a general-purpose security model.

The best patterns to study are workflow-gated exposure, session-default schema narrowing, high-level composite tools, structured build/test artifacts, result-bundle parsing, short bundled skills, and stateful handling for UI/debug/video flows.

The key caveat for Agentic Coding Lab is trust. XcodeBuildMCP is designed for a local developer who wants an agent to operate their Apple toolchain. It does not try to confine the agent to a repository, prevent all destructive simulator actions, or eliminate high-capability passthroughs. Any adoption should pair the server with explicit client approval rules for destructive workflows, `extraArgs`, path overrides, LLDB commands, Xcode IDE bridge calls, and device install/launch.

The candidate row was confirmed in `research/index.md` on 2026-05-29. The index was not edited during this review.

## Reviewed Paths

- `README.md`, `SECURITY.md`, `package.json`, `package-lock.json`, `server.json`, and `config.example.yaml` for project purpose, distribution, runtime requirements, config, telemetry, and scripts.
- `skills/xcodebuildmcp/SKILL.md` and `skills/xcodebuildmcp-cli/SKILL.md` for agent-facing workflow guidance.
- `manifests/workflows/*.yaml`, `manifests/tools/*.yaml`, `manifests/resources/*.yaml`, and `schemas/structured-output/**` for MCP surface, workflow gating, annotations, output schema mapping, and next-step metadata.
- `src/cli.ts`, `src/server/server.ts`, `src/server/start-mcp-server.ts`, `src/server/bootstrap.ts`, `src/server/mcp-lifecycle.ts`, `src/server/mcp-idle-shutdown.ts`, and `src/server/mcp-shutdown.ts` for MCP/CLI startup, lifecycle, idle shutdown, and runtime bootstrap.
- `src/core/manifest/*`, `src/core/resources.ts`, `src/core/structured-output-schema.ts`, `src/visibility/*`, `src/utils/tool-registry.ts`, and `src/runtime/*` for manifest loading, resource registration, visibility predicates, and tool registration.
- `src/utils/typed-tool-factory.ts`, `src/utils/config-store.ts`, `src/utils/project-config.ts`, `src/utils/session-store.ts`, `src/utils/session-default-args.ts`, `src/utils/path.ts`, and `src/utils/schema-helpers.ts` for session defaults, argument merging, config normalization, and validation.
- `src/utils/command.ts`, `src/utils/shell-escape.ts`, `src/utils/build-utils.ts`, `src/utils/test-common.ts`, `src/utils/xcodebuild-pipeline.ts`, `src/utils/xcodebuild-domain-results.ts`, `src/utils/xcodebuild-event-parser.ts`, `src/utils/xcodebuild-run-state.ts`, `src/utils/xcodebuild-log-capture.ts`, `src/utils/result-bundle-args.ts`, `src/utils/result-bundle-path.ts`, `src/utils/derived-data-path.ts`, `src/utils/log-paths.ts`, and `src/utils/workspace-filesystem-lifecycle.ts` for command safety, xcodebuild construction, parser behavior, result artifacts, log layout, and cleanup.
- `src/mcp/tools/simulator/*` with focus on `build_sim.ts`, `test_sim.ts`, `build_run_sim.ts`, `list_sims.ts`, `boot_sim.ts`, `install_app_sim.ts`, `launch_app_sim.ts`, `stop_app_sim.ts`, `record_sim_video.ts`, and `get_sim_app_path.ts`.
- `src/mcp/tools/device/*` and `src/utils/device-steps.ts` with focus on device build/test/run, `devicectl` install/launch, and signing assumptions.
- `src/mcp/tools/macos/*` for macOS build/test/run, app path resolution, launch, and stop behavior.
- `src/mcp/tools/project-discovery/*`, including project discovery, scheme listing, build settings, and bundle id helpers.
- `src/mcp/tools/session-management/*` and `src/mcp/tools/workflow-discovery/manage_workflows.ts` for defaults and workflow management.
- `src/mcp/tools/simulator-management/*` for simulator mutation tools such as erase, location, appearance, status bar, and keyboard handling.
- `src/mcp/tools/ui-automation/*`, `src/utils/axe-helpers.ts`, and `src/utils/debugger/ui-automation-guard.ts` for AXe snapshots, element refs, action serialization, stale snapshot handling, and debugger guard behavior.
- `src/mcp/tools/debugging/*` and `src/utils/debugger/*` for LLDB/debug state, breakpoint, continue, detach, command, stack, and variable flows.
- `src/mcp/tools/coverage/*` and `src/utils/xcresult-test-failures.ts` for coverage and test-failure extraction.
- `src/integrations/xcode-tools-bridge/*` and `src/mcp/tools/xcode-ide/*` for Xcode MCP bridge discovery, dynamic proxy registration, raw artifact handling, and generic bridge calls.
- `src/daemon.ts`, `src/daemon/*`, `src/cli/daemon-*`, `src/cli/register-tool-commands.ts`, `src/cli/yargs-app.ts`, and `src/cli/commands/{init,setup,tools,daemon,upgrade}.ts` for CLI parity, stateful tool invocation, daemon socket controls, setup, skill install, and upgrade behavior.
- `src/utils/sentry.ts`, `src/utils/sentry-config.ts`, and `src/mcp/tools/doctor/doctor.ts` for telemetry controls, redaction, and environment diagnostics.
- `src/**/__tests__`, `src/snapshot-tests/**`, `src/smoke-tests/**`, `vitest*.config.*`, and `.github/workflows/ci.yml` for verification coverage, mocked/snapshot testing, smoke harnesses, and CI limits.

## Excluded Paths

- `.git/**`: VCS internals, not part of the reviewed runtime or research surface.
- `assets/*.png`: README/branding images, not relevant to MCP boundary behavior.
- `example_projects/**`: sample and fixture Apple projects used for tests; skimmed for role, not reviewed as product code.
- `src/snapshot-tests/__fixtures__/**`: generated and fixture outputs used to confirm output shapes; not independently reviewed as implementation.
- `benchmarks/claude-ui/**`: benchmark harness material outside the core MCP server and tool-boundary review.
- `.github/workflows/release.yml`, publish, Sentry, warden, and stale workflows: release/ops automation outside the core execution path. CI workflow was reviewed separately.
- `CHANGELOG.md`, `CODE_OF_CONDUCT.md`, `THIRD_PARTY_LICENSES`, and `THIRD_PARTY_PACKAGE_LICENSES.md`: governance/license metadata outside the implementation review.
