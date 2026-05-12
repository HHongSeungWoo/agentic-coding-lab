# trycua/cua

- URL: https://github.com/trycua/cua
- Category: agent-support-systems
- Stars snapshot: 15,965 (GitHub API, 2026-05-12; repository updated_at 2026-05-12T02:41:33Z)
- Reviewed commit: 31bc4f86493207f7568ef6325af3c0a1963b6554
- Reviewed at: 2026-05-12 (Asia/Seoul)
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong candidate for secure computer-use infrastructure patterns. Reuse its runtime/transport/interface split, lifecycle semantics, and action trace ideas; do not copy its permissive local trust defaults or incomplete agent safety enforcement.

## Why It Matters

Cua is not just a desktop automation wrapper. It is a full computer-use substrate: cloud and local desktop sandboxes, Python and TypeScript SDKs, a guest computer-server, a model-driven ComputerAgent loop, MCP surfaces, benchmark tooling, trajectories, and a separate macOS background driver. That makes it directly relevant to coding agents that need a disposable GUI plus shell runtime, repeatable verification, and a clean boundary between model actions and operating-system effects.

The important lesson is architectural: the agent should not own the VM details. Cua puts lifecycle, runtime selection, transport, and UI primitives behind a stable API, so the same agent loop can target Linux containers, full VMs, macOS VMs, Windows, Android, or direct host control with different risk profiles.

## What It Is

Cua exposes a high-level `Sandbox` API through `cua` and `cua-sandbox`. A caller creates or connects to a sandbox, then uses typed interfaces such as `shell`, `mouse`, `keyboard`, `screen`, `clipboard`, `files`, `window`, `terminal`, `tunnel`, and `mobile`. The sandbox manager selects a runtime, starts a local or cloud computer, and binds a transport to the target.

The main runtime families are cloud VMs through `api.cua.ai`, Docker Linux desktops, QEMU Docker VMs, bare-metal QEMU, Lume macOS VMs, Android Emulator, and Hyper-V Windows VMs. The guest side is usually `computer-server`, a FastAPI service that exposes `/cmd`, `/ws`, `/responses`, PTY routes, and MCP. The agent side is `cua-agent`, which maps model tool calls to computer actions and feeds screenshots back to the model.

There are two additional tool surfaces. The Python `cua-mcp-server` wraps `ComputerAgent` as FastMCP tools for chat clients. The TypeScript `cua serve-mcp` command exposes sandbox-management and computer-control tools with coarse permission flags. Separately, `cua-driver` is a native macOS MCP/CLI driver for background control of host apps without moving the frontmost app or visible cursor.

## Research Themes

- Token efficiency: Cua has practical context controls: `only_n_most_recent_images`, image retention callbacks, trajectory screenshot extraction, Cua Driver modes (`ax`, `vision`, `som`), and `screenshot_out_file` to avoid returning inline images. It does not present a holistic token-budget system for computer-use traces, but the pieces are useful.
- Context control: The API separates sandbox state, agent messages, screenshots, tool calls, and trajectories. `ComputerAgent` callbacks can normalize tool calls, prune old images, add instructions, track budget, and save turn artifacts. Cua Driver's window-scoped snapshots and mode switches are the strongest context-control design.
- Sub-agent / multi-agent: This is more infrastructure than orchestrator. It supports many sandboxes, multiple MCP clients, and `run_multi_cua_tasks`, but it does not provide a rich planner-worker framework. CuaBot and skills/demonstrations are adjacent, not the core runtime.
- Domain-specific workflow: Strong. The code has OS-specific runtimes, transport fallbacks, Android gestures, browser-specific tooling, macOS AX and SkyLight paths, cloud/local setup guides, and examples for Claude Code inside a sandbox.
- Error prevention: Good lifecycle cleanup, explicit command schemas, permission checks in Cua Driver, authentication tests for computer-server cloud mode, HTTP retries for transient server errors, action normalizers, post-action screenshots, and clear sandbox lifecycle APIs. Agent-level safety checks are not yet strong.
- Self-learning / memory: Trajectories and human demonstrations can feed training or reusable skills. BrowserTool has in-run facts, but there is no durable self-learning layer in the main agent loop.
- Popular skills: Useful patterns include GUI automation skills, Claude Code in a cloud sandbox, MCP-exposed computer tools, and Cua Driver's background app-control skill surface.

## Core Execution Path

1. The user calls `Sandbox.ephemeral(...)`, `Sandbox.create(...)`, or `Sandbox.connect(...)` with an `Image`.
2. `cua-sandbox` chooses cloud transport or a local runtime. Local runtime selection maps containers to Docker, macOS to Lume, Android to Android Emulator, Windows to Hyper-V or QEMU, and disk-backed images to QEMU.
3. The runtime starts a container or VM and returns connection details such as API, VNC, QMP, SSH, gRPC, and environment metadata.
4. The sandbox binds a transport: HTTP computer-server, VNC+SSH, VNC-only, QMP, ADB/gRPC for Android, or direct local host transport.
5. Interface calls such as `sb.shell.run`, `sb.mouse.click`, or `sb.screenshot` send structured commands through the transport.
6. `computer-server` dispatches commands to OS-specific handlers, `cua_auto`, VNC, shell, file, window, accessibility, PTY, or mobile backends.
7. `ComputerAgent` adapts a `Sandbox` into an async computer handler, asks the model for actions, executes them, waits if configured, and returns screenshots after computer actions.
8. Optional MCP layers expose either agent tasks or lower-level sandbox computer tools to external coding/chat clients.

## Architecture

The cleanest boundary is `Sandbox -> Runtime -> Transport -> Interface`. `Sandbox` owns lifecycle and user-facing capabilities. Runtimes own provisioning and process/VM management. Transports own command delivery. Interfaces own typed operations.

`cua-sandbox` is the control plane. It stores local persistent state under `~/.cua/sandboxes`, cleans up ephemeral resources on exit, writes runtime environment variables into guests, supports snapshots for cloud/local runtimes, and offers `suspend`, `resume`, `delete`, and `list`.

`computer-server` is the guest/target data plane. It exposes HTTP, WebSocket, PTY, `/responses`, and MCP interfaces. In cloud mode, authentication is tied to `CONTAINER_NAME` plus Cua API validation. In local dev mode, no container name means the server allows access, so deployment posture matters.

`cua-agent` is the model loop. It resolves model-specific tool schemas, supports OpenAI native computer-use and function-style computer tools, adds callbacks, tracks budget and telemetry, saves trajectories, and wraps `Sandbox`, legacy `Computer`, browser, or custom function tools.

`cua-driver` is a distinct native macOS path. It uses Accessibility, Screen Recording, AX trees, browser accessibility observers, SkyLight per-process event posting, and MCP tool schemas to automate target apps in the background. It is not a VM sandbox and depends on explicit macOS TCC permissions.

## Design Choices

Cua favors one API across many isolation levels. That is productive, but it means the same high-level method can target a cloud VM, a Docker desktop, a full local VM, Android, or the developer's own host through `Localhost`. The docs usually call out that distinction, and the code marks `Localhost` as unsandboxed.

The project defaults to cloud for the newest sandbox API and uses `local=True` for local runtimes. Local auto-selection is pragmatic: Docker for Linux containers, Lume for macOS, Android Emulator for Android, Hyper-V on supported Windows hosts, and QEMU otherwise.

Image construction is declarative. `Image` supports package installs, shell layers, environment variables, app installs, file copies, and exposed ports. The docs correctly warn that `Image.env()` is visible in image specs and should not hold secrets.

The server boundary is broad by design. Shell, file writes, clipboard, tunnels, terminal PTYs, and GUI control are first-class capabilities. This is appropriate inside a disposable VM, but unsafe when pointed at a host or exposed network service.

## Strengths

- Mature decomposition of provisioning, transport, and UI automation. The same agent interface can run against cloud VMs, Docker, QEMU, Lume, Android, Hyper-V, or host control.
- Good sandbox lifecycle ergonomics: ephemeral context managers, persistent named sandboxes, local state files, cloud cleanup on failed creation, suspend/resume/delete, and snapshots.
- Rich computer-use surface: screenshots, shell, files, clipboard, mouse, keyboard, windows, terminal, mobile gestures, tunnels, browser tooling, and MCP.
- Cua Driver is a strong macOS reference for background app control: permission gates, AX/SOM/vision modes, window scoping, action recording, and front-app restoration.
- Verification exists where it matters operationally: sandbox interface integration tests, HTTP transport tests, computer-server auth/availability tests, TypeScript interface tests, examples for cloud/local sandboxes, and driver tests around permissions and background actions.
- Trajectory saving, image retention, budget callbacks, and action normalization are directly useful for agent evaluation and debugging.

## Weaknesses

- Local `computer-server` defaults are risky if exposed: the CLI/server binds to `0.0.0.0`, CORS is permissive, and no `CONTAINER_NAME` means auth is skipped. The docs warn about this, but the default deserves a stronger fail-closed posture.
- Agent safety checks are incomplete. `ComputerAgent._handle_item` acknowledges pending safety checks while leaving enforcement for a future safety callback, instead of requiring a human or policy decision now.
- Custom function tools run on the host unless explicitly sandboxed. That is a sharp boundary for coding agents because file/network side effects can escape the desktop sandbox.
- Isolation levels vary widely under one API. Docker desktops, local host transport, cloud VMs, QEMU, and Lume do not have the same security properties, but tool call sites can look identical.
- VNC+SSH transport uses automatic host-key acceptance and default credentials, which is acceptable only in tightly controlled local sandboxes.
- The Python MCP server tests are mostly import/smoke tests, while the TypeScript MCP surface exposes powerful shell/file/window tools by default unless permissions are restricted.
- Some security/privacy features are incomplete or opt-out: telemetry defaults to enabled, PII anonymization is unfinished, and shared VNC display URLs can contain embedded passwords.

## Ideas To Steal

- Keep `Sandbox`, `Runtime`, `Transport`, and typed tool interfaces as separate contracts.
- Make sandbox lifecycle explicit with ephemeral context managers and persistent named sessions.
- Require every computer action to produce a verifiable observation, usually a screenshot or structured state.
- Store action trajectories as first-class artifacts for debugging, replay, benchmarking, and skill creation.
- Add context levers at the UI automation boundary: AX-only, screenshot-only, SOM, output-to-file, and recent-image retention.
- Treat macOS host automation as a different trust tier from VM automation, with explicit permission gates and window-scoped tools.
- Add fail-closed availability tests for services that should only run inside provisioned containers or VMs.

## Do Not Copy

- Do not bind a powerful local computer-control server to all interfaces without authentication by default.
- Do not make safety checks advisory only. Tool calls that model providers mark as unsafe need an explicit policy or user-approval callback.
- Do not expose shell, file write, clipboard, tunnel, and window tools as one default MCP permission set.
- Do not blur host tools and sandbox tools. Function tools should default to sandbox execution or declare host execution loudly in schema/metadata.
- Do not rely on automatic SSH host-key trust or default credentials outside disposable local test environments.
- Do not place secrets in image specs or reusable sandbox definitions.

## Fit For Agentic Coding Lab

Cua is a high-fit reference for a coding-agent lab that wants secure GUI-capable execution. The strongest applicability is running a coding agent inside a cloud/local VM while still giving another supervisor agent screenshots, shell results, files, and trajectories. The Claude Code in sandbox example is especially relevant because it combines package install, isolated filesystem, terminal execution, and artifact verification.

Adoption should be selective. Use VM-backed or cloud-backed sandboxes for untrusted code, keep direct host drivers as opt-in power tools, and put policy around shell/file/network capabilities. The Cua architecture can support coding-agent experiments well, but the lab should tighten defaults around auth, permissions, safety checks, and tool provenance.

## Reviewed Paths

- `README.md`, `Development.md`, `TESTING.md`, `pyproject.toml`: project scope, package map, install/test posture, and meta-package dependencies.
- `docs/content/docs/cua/guide/get-started`, `docs/content/docs/cua/guide/fundamentals`, `docs/content/docs/cua/guide/advanced`, `docs/content/docs/cua/guide/agents-in-sandbox`, `docs/content/docs/cua/reference/desktop-sandbox`, `docs/content/docs/cua/reference/sandbox-sdk`: sandbox concepts, local/cloud setup, lifecycle, secrets, custom tools, telemetry, trajectories, Claude Code sandbox flow, and generated API orientation.
- `libs/python/cua`: public meta-package exports and lazy imports for sandbox, runtimes, interfaces, CLI, auth, and agent APIs.
- `libs/python/cua-sandbox/cua_sandbox`: `Sandbox`, `Image`, auth/config, local state, runtimes, transports, and interfaces for shell/mouse/keyboard/files/window/mobile/tunnel/terminal.
- `libs/python/computer-server/computer_server`: HTTP/WebSocket/PTYS/MCP command server, auth middleware behavior, `/responses` agent endpoint, handlers, and tests.
- `libs/python/agent/cua_agent`: `ComputerAgent`, model loops, tool schemas, callbacks, browser tool, budget manager, trajectory saver, image retention, tool normalization, and computer adapters.
- `libs/python/mcp-server`: FastMCP wrapper, session manager, concurrent task support, and smoke tests.
- `libs/typescript/computer`, `libs/typescript/agent`, `libs/typescript/cua-cli/src/commands/serve-mcp.ts`: TypeScript cloud computer SDK, agent client, WebSocket auth path, MCP permissions, and sandbox command proxying.
- `libs/cua-driver`: native macOS driver docs and Swift sources for permissions, MCP registry, window state, screenshots, clicks, keyboard/mouse event posting, recording, and tool annotations.
- `examples/agents`, `examples/sandboxes`, `docs/content/docs/cua/examples`: cloud/local sandbox smoke examples, Android/Windows/macOS/Linux usage, and coding-agent-in-sandbox examples.
- `libs/python/cua-sandbox/tests`, `libs/python/computer-server/tests`, `libs/python/agent/tests`, `libs/typescript/computer/tests`, `libs/python/mcp-server/tests`: available verification coverage and gaps.

## Excluded Paths

- Lockfiles and generated dependency metadata such as `uv.lock`, `pnpm-lock.yaml`, `package-lock.json`, and package-manager caches: dependency resolution artifacts, not architecture.
- Generated API reference/changelog pages under `docs/content/docs/cua/reference/*/api.mdx` and generated MCP reference material: used only for orientation where needed; source code and guides were preferred.
- Binary and media assets under `img`, docs static assets, videos, screenshots, icons, and app bundles: useful for product presentation, not sandbox/control-plane design.
- Docs site UI, playground visual components, blog, marketing pages, and landing-page assets: UI-only or narrative material outside the secure runtime path.
- Benchmark datasets and bulk task fixtures under `libs/cua-bench`, `tests`, and benchmark example data: relevant to evaluation scale, but not needed to understand runtime boundaries.
- Docker/image packaging internals in `libs/kasm`, `libs/xfce`, `libs/qemu-docker`, and app catalog assets: skimmed conceptually through docs/runtime callers; deep review would be image hardening rather than agent-support architecture.
- Generated protobuf/gRPC stubs, build output, cache folders, notebooks, and demo artifacts: mechanical or exploratory artifacts with low signal for tool-boundary analysis.
- Unrelated app-specific examples such as CRM/export demos, provider-specific long-form examples, and UI playground state code: representative usage only, not core architecture.
