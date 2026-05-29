# manaflow-ai/cmux

- URL: https://github.com/manaflow-ai/cmux
- Category: ai-coding-workflow
- Stars snapshot: 20,231 (GitHub REST API repository search, captured 2026-05-29; index row confirmed 2026-05-29)
- Reviewed commit: 2311bec3a709bf9f98b6f14c21a0959986fb277d
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong reference candidate for terminal-native coding-agent orchestration. cmux is most valuable for its tmux compatibility layer, stable terminal/browser surface API, agent hook and Feed permission bridge, notification policy, session restore and hibernation model, and remote terminal relay. It is less useful as a direct dependency because it is a large GPL-licensed native macOS app with substantial AppKit, Ghostty, and WKWebView coupling.

## Why It Matters

cmux is not just another coding-agent wrapper. It is a terminal, browser, socket API, and sidebar control plane designed around the way existing coding agents actually run: long-lived shells, tmux-oriented teammate features, multiple panes, process-local environment variables, permission prompts, notifications, restores, and remote sessions.

For Agentic Coding Lab, the important research value is the orchestration substrate. cmux shows how a host app can expose durable workspace, pane, surface, and browser identities to agents; translate tmux commands into richer native panes; route agent lifecycle and permission hooks into a shared Feed; keep task state visible without forcing all context into the model; and resume or hibernate idle coding-agent sessions with explicit safety checks.

It also gives useful cautionary material. Many ideas are implemented deeply enough to study, but they are bound to macOS UI primitives, a large Swift codebase, local socket security choices, and each agent vendor's current hook coverage. The reusable lessons are mostly architectural patterns, protocol boundaries, tests, and policy gates rather than reusable library code.

## What It Is

cmux is a native macOS terminal application built on libghostty with vertical tabs, split panes, sidebar notifications, a scriptable browser, SSH/remote terminal support, and a CLI/socket API. The README positions it as a terminal and browser primitive for coding agents rather than a single opinionated agent runtime.

The reviewed repo includes:

- A Swift/AppKit application under `Sources/` with terminal surfaces, workspaces, tabs, browser panels, notification stores, Feed UI, socket control, session persistence, and agent hibernation.
- A Swift CLI under `CLI/` that implements `cmux` control commands, agent hook installation, `cmux notify`, `claude-teams`, `codex-teams`, OMO/OMX/OMC wrappers, tmux compatibility, browser commands, and Feed hook transport.
- A Go remote daemon under `daemon/remote/` for SSH-backed durable PTY sessions, proxy egress, remote `cmux` CLI relay, and tmux compatibility over an authenticated local relay.
- Documentation under `docs/` for the CLI contract, notifications, agent hooks, Feed, browser API, configuration, and remote daemon design.
- Bundled Codex-style skills under `skills/` that teach agents how to use cmux windows, workspaces, panes, browser automation, settings, diagnostics, markdown, and customization.
- Tests under `cmuxTests/`, `tests/`, and daemon test files covering restore behavior, hook persistence, Feed coordination, socket permissions, tmux compatibility, notifications, browser behavior, and remote daemon behavior.

## Research Themes

- Token efficiency: Moderate and indirect. cmux does not compress model context, but it reduces attention and context pressure by keeping workspace state, latest notifications, git/PR/cwd/port metadata, Feed decisions, browser snapshots, and terminal topology outside the chat transcript. Bundled skills also reduce prompting overhead by giving agents stable command recipes.
- Context control: Strong. The core API uses explicit window, workspace, pane, surface, tab, browser, and notification identities. `system.identify` lets an agent discover its current cmux context, while `CMUX_WORKSPACE_ID`, `CMUX_SURFACE_ID`, and related environment variables bind CLI calls to the active terminal. Browser commands expose stable element refs and snapshots. Session restore records cwd, command, agent session ID, lifecycle, and surface mapping.
- Sub-agent / multi-agent: Strong for terminal-mediated coordination. `claude-teams` creates a tmux-compatible environment without requiring real tmux, translating teammate splits into cmux surfaces. `codex-teams` starts a Codex app server, watches thread spawn events, and opens subagent threads into managed splits up to a bounded depth. OMO/OMX/OMC wrappers and tmux compatibility support other multi-pane coding-agent flows.
- Domain-specific workflow: High. The domain is coding-agent terminal work: panes, splits, restore, notifications, approval prompts, browser automation, SSH sessions, custom commands, hook installation, and safe auto-resume. It is workflow infrastructure rather than a model or prompt library.
- Error prevention: Strong. cmux includes local socket modes, password auth, descendant-process checks, hook trust prompts, project config authorization, sanitized launch commands, noninteractive command filtering for restore, approval-gated custom resume commands, Feed timeouts, remote daemon manifest verification, HMAC relay authentication, and a broad regression suite.
- Self-learning / memory: Low as adaptive semantic memory, strong as operational memory. It persists workstream JSONL, hook session maps, restorable agent sessions, scrollback, resume bindings, notification state, and browser/terminal layout state. It does not learn reusable lessons or synthesize long-term agent memory.
- Popular skills: The repo ships practical cmux skills: `cmux`, `cmux-browser`, `cmux-settings`, `cmux-workspace`, `cmux-customization`, `cmux-keyboard-shortcuts`, `cmux-markdown`, and `cmux-diagnostics`. No usage telemetry or popularity ranking was found.

## Core Execution Path

A coding agent usually starts inside a cmux terminal surface. The app injects or exposes `CMUX_SOCKET_PATH`, optional socket password, workspace/surface/tab IDs, cwd, and agent launch metadata. The agent or its wrapper can call `cmux identify --json` or socket method `system.identify` to get stable handles for the current window, workspace, pane, surface, and browser context.

Terminal layout work flows through the CLI/socket API. Native commands such as `surface.split`, `surface.send_text`, `surface.read_text`, `workspace.create`, `tab.rename`, and browser commands operate on cmux handles. For tmux-first tools, `claude-teams` prepends a shim `tmux` binary that runs `cmux __tmux-compat`, fakes `TMUX` and `TMUX_PANE`, and maps tmux operations such as `new-session`, `split-window`, `send-keys`, `capture-pane`, `select-layout main-vertical`, and `resize-pane` onto cmux surfaces.

For Claude Teams, cmux keeps leader-pane and main-vertical state so teammate panes stack predictably. For Codex Teams, `cmux codex-teams` starts `codex app-server`, launches a root Codex session with `--remote`, runs a watcher process, subscribes to thread events over WebSocket, detects subagent spawn metadata, probes readiness with `thread/resume`, and opens managed subagent threads in splits.

Agent hooks provide the lifecycle and permission path. `cmux hooks setup` installs or removes agent-specific hook config while preserving non-cmux user entries. Hook invocations record session mappings under `~/.cmuxterm`, update lifecycle/status, set notification state, and suppress noisy nested-agent mutations when needed. The hook definitions cover Codex, Grok, OpenCode, Pi, Amp, Cursor, Gemini, Rovo, Copilot, CodeBuddy, Factory, Qoder, and related agents.

Permission and task-state events flow through Feed. `cmux hooks feed --source <agent>` reads hook JSON from stdin, classifies the event, attaches workspace/surface/session/cwd/process context, and sends `feed.push` to the app. `FeedCoordinator` stores the item in `WorkstreamStore`, appends a redacted JSONL audit event, notifies the UI, and for actionable events parks the hook on a semaphore for up to 120 seconds. User replies are encoded back into the agent-specific hook response format; timeout falls back to `{}` so the agent can use its own UI.

Restore and hibernation close the loop. Hook session stores and restorable-agent logic preserve agent session IDs and sanitized launch commands. On app restore, cmux can replay scrollback, offer manual resume, or auto-run approved resume commands such as `codex resume <id>`. Custom resume commands are manual by default and require user approval before becoming automatic. The hibernation planner only terminates eligible idle restorable agents after lifecycle checks, protected-surface checks, idle windows, and a two-phase terminal-tail confirmation.

Remote sessions use a separate daemon path. `cmux ssh` bootstraps or reuses `cmuxd-remote`, verifies release-pinned manifests and SHA-256, opens session/proxy RPC over SSH stdio, and exposes a remote `cmux` wrapper through an authenticated relay. The remote shell does not receive the local app socket directly.

## Architecture

The app layer is a Swift/AppKit codebase. `TerminalController` owns the local control socket, protocol handling, authentication, and v2 JSON method dispatch. `Workspace`, tab, pane, and surface classes model layout and terminal lifecycle. Ghostty-backed terminal views parse terminal notification OSC sequences and feed notification/session state. Browser panels use WKWebView and expose an agent-browser-style command surface where WKWebView supports it.

The CLI is a large Swift command surface. It handles direct user commands, socket JSON-RPC calls, notification commands, browser commands, hook setup, hook event dispatch, tmux compatibility, and coding-agent wrappers. Several specialized files split out hook definitions and tmux HUD/support behavior, but much of the orchestration still lives in `CLI/cmux.swift`.

The Feed subsystem is split between socket ingestion, a main-actor `FeedCoordinator`, and the `CMUXWorkstream` package. `WorkstreamStore` keeps a bounded in-memory ring for recent items, persists redacted events to `~/.cmuxterm/workstream.jsonl`, exposes pending/actionable computed views, and resolves or expires waiting permission items.

Security and policy are distributed across socket settings, project config trust, hook installation, resume approval, and remote relay code. Socket control modes range from off to cmux-only, automation, password, and allow-all. Project notification hooks and custom commands use authorization prompts. Surface resume approvals bind command, cwd, and environment details instead of blindly auto-running process-detected commands.

The remote daemon is Go. It serves JSON-RPC methods for hello/ping, proxy streams, persistent PTY sessions, attach/detach/resize/status, and WebSocket PTY leases. It tracks attachments, computes terminal size from the smallest attached client, maintains scrollback, and supports remote tmux compatibility through the authenticated relay.

## Design Choices

cmux chooses compatibility over replacement for existing multi-agent CLIs. Rather than requiring agents to adopt a new pane protocol, it supplies tmux-compatible environment variables and a shim that turns common tmux operations into cmux socket calls. This lets tools such as Claude Teams run in a richer native terminal without a real tmux server.

The public model uses stable topology primitives. Window, workspace, pane, surface, tab, and browser IDs are treated as agent-addressable resources. Short refs and deep refs are supported through skills and CLI commands, giving agents a way to act on UI state without scraping the screen.

Human-in-loop coordination is intentionally soft-blocking. Feed can hold a hook for a permission or question decision, but the timeout is capped and the fallback is an empty response. That keeps cmux from permanently wedging an agent when the app is unavailable or the user does not answer.

Restore safety is command-aware. cmux records enough launch context to resume real interactive agent sessions, but tests ensure noninteractive commands such as Codex `exec`, Claude `--print`, Gemini `--prompt`, OpenCode `run`, and similar one-shot modes are not auto-restored. Sanitizers preserve useful flags such as model, sandbox, cwd, and config while dropping prompts, credentials, old session selectors, and noninteractive invocations.

Notifications are policy-driven rather than just terminal bells. cmux recognizes terminal OSC notifications and hook-generated agent events, runs optional global and project notification hooks, applies effects such as record, unread mark, workspace reorder, desktop notification, sound, command, and pane flash, and falls back to default behavior on hook failure or invalid JSON.

Remote work does not tunnel the local app socket directly. The daemon path uses manifest verification, scoped leases, a reverse local relay, and HMAC challenge/response so browser and cmux commands from an SSH session can reach local cmux without giving the remote shell arbitrary local socket access.

## Strengths

- Mature terminal/session orchestration for coding agents, with explicit panes, surfaces, workspaces, tabs, browser targets, and socket methods.
- Practical tmux compatibility that supports tmux-oriented agent-team tools without forcing users into a real tmux environment.
- Concrete multi-agent support for Claude Teams and Codex Teams, including managed splits, subagent depth bounds, launch metadata, and layout equalization.
- Feed turns permissions, plan exits, questions, and side-effecting tool events into shared task state instead of leaving them buried in individual terminal sessions.
- Restore and hibernation are designed around real agent lifecycle risks: sanitized launch commands, idle/lifecycle gates, noninteractive filtering, tail rechecks, and approval-gated custom resume.
- Security posture is unusually explicit for a local terminal app: socket modes, password auth, peer process checks, project trust prompts, signed resume approvals, and remote relay authentication are all present.
- Test coverage directly targets the risky parts: tmux command translation, Claude Teams env and layout, Codex hook trust, Feed waiters, socket access, notification parsing, restorable session rules, and remote daemon behavior.

## Weaknesses

- The reusable logic is embedded in a large native macOS product. AppKit, Ghostty, WKWebView, Xcode project structure, and UI state make direct extraction expensive.
- Much of the CLI orchestration is concentrated in very large Swift files, especially `CLI/cmux.swift` and `TerminalController.swift`, which makes individual patterns harder to audit or reuse in isolation.
- Feed coverage depends on each agent's hook surface. The docs explicitly note that stock Codex TUI plan-mode `request_user_input` and `update_plan` events remain in Codex's app-server path rather than cmux hooks today.
- Browser automation is limited by WKWebView. The port preserves agent-browser-style commands where possible, but CDP-only behavior and some browser internals are not equivalent.
- The local socket model is powerful and therefore risky if misconfigured. `allowAll` exists for automation but is not an appropriate default for shared machines or untrusted local users.
- The workflow stores useful operational history, but not a typed universal task schema or mandatory verification result. Lab adoption would still need its own task/check/run contract.
- GPL-3.0-or-later licensing and a UI-heavy repo shape make it better as a design reference than a source dependency for many downstream systems.

## Ideas To Steal

- Expose `system.identify` and stable topology handles so agents can discover and control their host workspace without screen scraping.
- Use a tmux shim as an adapter layer for existing tools that already speak tmux, while mapping only the needed command subset to native primitives.
- Represent human-in-loop approvals as persisted workstream items with a bounded hook wait, UI reply path, timeout fallback, and native per-agent response encoders.
- Keep an append-only, redacted workstream log alongside a bounded in-memory UI ring.
- Build a restorable agent registry from hook events, cwd, surface IDs, launch command metadata, lifecycle, and process IDs.
- Sanitize launch commands and refuse auto-restore for noninteractive or prompt-bearing commands.
- Gate auto-running resume commands through explicit user approval tied to command, cwd, and environment rather than process detection alone.
- Hibernation should be conservative: require idle lifecycle, no unconfirmed input, protected-surface checks, visible-panel checks, idle duration, and a second tail/process confirmation before terminating.
- Notification policy should be data-driven: hook input, context envelope, effects list, project trust, failure fallback, and tests for terminal escape parsing.
- Remote agent terminals should use an authenticated relay and verified daemon artifacts instead of passing privileged local sockets into remote shells.

## Do Not Copy

- Do not copy the macOS UI stack or monolithic CLI structure if the goal is a small cross-platform lab harness.
- Do not assume partial tmux compatibility is harmless. It needs a tested corpus of command shapes, format strings, target semantics, and layout expectations.
- Do not auto-resume arbitrary commands discovered from a process table. cmux's sanitizers and approvals are part of the safety story.
- Do not rely on Feed for every possible Codex interaction today; Codex plan questions still need app-server integration or upstream hook coverage.
- Do not expose allow-all local sockets in production workflow tooling without a separate threat model and explicit user consent.
- Do not persist raw tool inputs, command outputs, or browser snapshots without redaction and retention controls.
- Do not treat notification hooks or project custom commands as trusted just because they live in a repo; project-level authorization matters.

## Fit For Agentic Coding Lab

cmux is in-scope and highly relevant as a workflow design reference. It covers the lab's target concerns around terminal session orchestration, multi-agent panes, task/permission state, notification routing, restore/hibernation, remote coding sessions, browser control, and agent-facing skills.

The best adoption path is selective:

- Use the topology model: workspace, pane, surface, browser target, and self-identify APIs.
- Reuse the tmux-adapter idea for tools that already emit tmux commands, but keep the compatibility contract small and tested.
- Adapt the Feed pattern into a lab-native task/approval stream with a typed verification result schema.
- Borrow the restore safety model: restorable session registry, launch sanitizer, noninteractive detection, and approval-gated resume commands.
- Borrow notification policy as a data model, not as UI behavior.
- Treat cmux as a reference implementation for local-first control-plane design, not as a direct dependency.

Direct product adoption is conditional because cmux is macOS-first, UI-heavy, GPL-licensed, and broader than the research index needs. The repo should remain indexed as a strong reviewed candidate for terminal/tmux/session orchestration patterns.

## Reviewed Paths

- `/tmp/myagents-research/manaflow-ai-cmux/README.md`: product scope, terminal/browser primitive framing, notifications, browser automation, custom commands, SSH, Claude Teams, and session restore notes.
- `/tmp/myagents-research/manaflow-ai-cmux/package.json`: repository metadata and license signal.
- `/tmp/myagents-research/manaflow-ai-cmux/docs/cli-contract.md`: CLI/socket command surface, global options, environment variables, browser commands, notification commands, tmux compatibility, and v2 method families.
- `/tmp/myagents-research/manaflow-ai-cmux/docs/notifications.md`: notification hook envelope, effects, project trust behavior, fallback semantics, and agent integration examples.
- `/tmp/myagents-research/manaflow-ai-cmux/docs/agent-hooks.md`: supported agent hook matrix, session restore mapping, Feed support, sanitizer behavior, hibernation conditions, and custom surface resume approvals.
- `/tmp/myagents-research/manaflow-ai-cmux/docs/feed.md`: Feed event flow, blocking permission replies, JSONL audit log, event stream, timeout behavior, and Codex hook coverage caveat.
- `/tmp/myagents-research/manaflow-ai-cmux/docs/agent-browser-port-spec.md`: agent-browser API goals, window/workspace/pane/surface model, browser command parity, and WKWebView limitations.
- `/tmp/myagents-research/manaflow-ai-cmux/docs/remote-daemon-spec.md`: remote session goals, implemented daemon capabilities, manifest verification, relay security, proxy behavior, and open design decisions.
- `/tmp/myagents-research/manaflow-ai-cmux/docs/configuration.md`: user configuration, custom commands, hooks, and automation-relevant settings.
- `/tmp/myagents-research/manaflow-ai-cmux/CLI/cmux.swift`: main CLI dispatcher, Claude Teams wrapper, Codex Teams watcher, hook setup, generic hooks, Feed hook transport, tmux compatibility command mapping, and socket calls.
- `/tmp/myagents-research/manaflow-ai-cmux/CLI/CMUXCLI+AgentHookDefinitions.swift`: agent hook definitions, event sets, config targets, feed hook events, and restore command metadata.
- `/tmp/myagents-research/manaflow-ai-cmux/CLI/CMUXCLI+TmuxCompatSupport.swift`: tmux compatibility helpers, target parsing, format contexts, layout state, and persistence.
- `/tmp/myagents-research/manaflow-ai-cmux/CLI/CMUXCLI+TmuxCompatHUDSupport.swift`: tmux compatibility HUD/startup support for OMX-style workflows.
- `/tmp/myagents-research/manaflow-ai-cmux/Sources/TerminalController.swift`: local socket server, peer authentication, v2 JSON methods, Feed push handling, notification methods, browser/surface methods, and surface resume approval path.
- `/tmp/myagents-research/manaflow-ai-cmux/Sources/SocketControlSettings.swift`: socket control modes, password store, permissions, environment overrides, and legacy mode parsing.
- `/tmp/myagents-research/manaflow-ai-cmux/Sources/Workspace.swift`: session restore, auto-resume decisions, scrollback replay, restorable agent handling, and hibernation entry/resume behavior.
- `/tmp/myagents-research/manaflow-ai-cmux/Sources/RestorableAgentSession.swift`: restorable session index, command construction, lifecycle data, and storage behavior.
- `/tmp/myagents-research/manaflow-ai-cmux/Sources/RestorableAgentTypes.swift`: restorable agent type modeling and resume capability metadata.
- `/tmp/myagents-research/manaflow-ai-cmux/Sources/App/AgentHibernationController.swift`: hibernation planner, eligibility gates, two-phase confirmation, and scoped termination behavior.
- `/tmp/myagents-research/manaflow-ai-cmux/Sources/Feed/FeedCoordinator.swift`: Feed ingestion, waiter registration, timeout behavior, PID-exit expiry, and reply delivery.
- `/tmp/myagents-research/manaflow-ai-cmux/Sources/TerminalNotificationPolicy.swift`: notification policy evaluation, hook context, effects, authorization, and failure handling.
- `/tmp/myagents-research/manaflow-ai-cmux/Sources/TerminalNotificationQueue.swift`: queued/coalesced notification mutations and stale-generation clearing.
- `/tmp/myagents-research/manaflow-ai-cmux/Sources/TerminalNotificationStore.swift`: notification persistence, desktop notification integration, sound settings, and panel state.
- `/tmp/myagents-research/manaflow-ai-cmux/Packages/CMUXWorkstream/Sources/CMUXWorkstream/WorkstreamStore.swift`: in-memory workstream ring, pending/actionable views, ingest, resolve, and persistence integration.
- `/tmp/myagents-research/manaflow-ai-cmux/Packages/CMUXWorkstream/Sources/CMUXWorkstream/WorkstreamPersistence.swift`: redacted JSONL append/load behavior and history paging.
- `/tmp/myagents-research/manaflow-ai-cmux/Packages/CMUXWorkstream/Sources/CMUXWorkstream/WorkstreamEvent.swift`: event schema for hook, agent, workspace, tool, and context fields.
- `/tmp/myagents-research/manaflow-ai-cmux/Packages/CMUXAgentLaunch/Sources/CMUXAgentLaunch/*`: launch metadata and agent command modeling used by restore paths.
- `/tmp/myagents-research/manaflow-ai-cmux/daemon/remote/README.md`: remote daemon protocol, deployment, CLI relay, browser bridge, WebSocket PTY, and security boundaries.
- `/tmp/myagents-research/manaflow-ai-cmux/daemon/remote/cmd/cmuxd-remote/main.go`: remote JSON-RPC server, capability handshake, proxy methods, session methods, and PTY attachment management.
- `/tmp/myagents-research/manaflow-ai-cmux/daemon/remote/cmd/cmuxd-remote/ws_pty.go`: WebSocket PTY lease handling, session binding, scrollback, idle TTL, and token validation.
- `/tmp/myagents-research/manaflow-ai-cmux/daemon/remote/cmd/cmuxd-remote/tmux_compat.go`: remote-side tmux compatibility relay.
- `/tmp/myagents-research/manaflow-ai-cmux/cmuxTests/FeedCoordinatorTests.swift`: Feed waiter, timeout, and reply behavior tests.
- `/tmp/myagents-research/manaflow-ai-cmux/cmuxTests/RestorableAgentNonInteractiveTests.swift`: noninteractive command filtering for restore safety.
- `/tmp/myagents-research/manaflow-ai-cmux/cmuxTests/AgentHibernationControllerTests.swift`: hibernation eligibility and planner behavior.
- `/tmp/myagents-research/manaflow-ai-cmux/cmuxTests/SocketControlSettingsTests.swift`: socket mode and password behavior tests.
- `/tmp/myagents-research/manaflow-ai-cmux/cmuxTests/TerminalNotificationPolicyTests.swift`: notification policy and hook behavior tests.
- `/tmp/myagents-research/manaflow-ai-cmux/tests/test_cli_claude_teams_tmux_sequence.py`: Claude Teams tmux command sequence behavior.
- `/tmp/myagents-research/manaflow-ai-cmux/tests/test_cli_claude_teams_main_vertical.py`: main-vertical split behavior for teammate panes.
- `/tmp/myagents-research/manaflow-ai-cmux/tests/test_cli_claude_teams_env.py`: Claude Teams environment setup and NODE_OPTIONS handling.
- `/tmp/myagents-research/manaflow-ai-cmux/tests/test_codex_feed_hooks.py`: Codex hook installation, trust, and Feed hook behavior.
- `/tmp/myagents-research/manaflow-ai-cmux/tests/test_socket_access.py`: local socket access and authentication behavior.
- `/tmp/myagents-research/manaflow-ai-cmux/tests/test_notifications.py`: terminal notification and OSC parsing coverage.
- `/tmp/myagents-research/manaflow-ai-cmux/skills/cmux/SKILL.md`: agent-facing control workflow for windows, workspaces, panes, surfaces, and notifications.
- `/tmp/myagents-research/manaflow-ai-cmux/skills/cmux-browser/SKILL.md`: browser automation workflow and snapshot/action guidance.
- `/tmp/myagents-research/manaflow-ai-cmux/skills/cmux-settings/SKILL.md`: settings read/write helper behavior and config schema usage.
- `/tmp/myagents-research/manaflow-ai-cmux/skills/cmux-workspace/SKILL.md`, `/tmp/myagents-research/manaflow-ai-cmux/skills/cmux-customization/SKILL.md`, `/tmp/myagents-research/manaflow-ai-cmux/skills/cmux-diagnostics/SKILL.md`, `/tmp/myagents-research/manaflow-ai-cmux/skills/cmux-keyboard-shortcuts/SKILL.md`, and `/tmp/myagents-research/manaflow-ai-cmux/skills/cmux-markdown/SKILL.md`: bundled skill surface for workspace, customization, diagnostics, shortcuts, and markdown workflows.
- `/tmp/myagents-research/manaflow-ai-cmux/skills.sh`: skill installer behavior and selected-skill installation flow.

## Excluded Paths

- `/tmp/myagents-research/manaflow-ai-cmux/.git/**`: VCS internals; only the reviewed HEAD commit was needed.
- `/tmp/myagents-research/manaflow-ai-cmux/vendor/stack-auth-swift-sdk-prerelease/**`: vendored third-party auth SDK, not coding-agent workflow logic.
- `/tmp/myagents-research/manaflow-ai-cmux/Resources/ghostty/themes/**`: bundled terminal color themes, not orchestration behavior.
- `/tmp/myagents-research/manaflow-ai-cmux/Resources/markdown-viewer/**`: generated/bundled markdown viewer web assets, not agent workflow logic.
- `/tmp/myagents-research/manaflow-ai-cmux/Assets.xcassets/**`, icon sets, screenshots, and marketing images: static UI assets.
- `/tmp/myagents-research/manaflow-ai-cmux/web/**`: documentation/website surface was excluded except where linked docs clarified runtime behavior.
- `/tmp/myagents-research/manaflow-ai-cmux/docs/assets/**` and image/media files: illustrative documentation assets.
- `/tmp/myagents-research/manaflow-ai-cmux/README.*.md`: localized README variants were excluded after the primary README was reviewed.
- `/tmp/myagents-research/manaflow-ai-cmux/*.xcodeproj/**`, derived build outputs, and generated dependency caches: project/build metadata rather than workflow design.
- `/tmp/myagents-research/manaflow-ai-cmux/Package.resolved`, lockfiles, release packaging metadata, Homebrew formulas, and entitlement/plist details: sampled only for context where relevant, not deep-reviewed.
