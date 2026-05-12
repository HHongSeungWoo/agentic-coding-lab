# e2b-dev/E2B

- URL: https://github.com/e2b-dev/E2B
- Category: agent-support-systems
- Stars snapshot: 12,150 (GitHub REST API `stargazers_count`, captured 2026-05-12)
- Reviewed commit: 9e962ae5557e88ad6e02d5d4f8da1b3f5b6c8d44
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong reference for agent-facing secure remote execution APIs: sandbox lifecycle, command/process streaming, filesystem transfer, public-port access control, outbound network policy, templates, volumes, and SDK/CLI ergonomics. Do not treat this repo alone as proof of VM isolation: the checked-out source is mostly SDKs, CLI, OpenAPI/Connect contracts, templates, and tests; the microVM runtime, hosted control plane implementation, and envd server are not present here.

## Why It Matters

E2B is directly relevant to coding agents because it gives the agent a disposable Linux computer instead of asking the agent to run arbitrary generated code on the local host. The useful abstraction is a durable sandbox handle with a narrow remote-control surface: create a sandbox from a template, run commands, stream outputs, read/write files, open a PTY, expose app ports, restrict egress, persist state through pause/snapshots/volumes, and delete the environment when done.

For Agentic Coding Lab, the strongest pattern is the split between agent workflow and execution substrate. Agent code can stay in the local assistant/client process while all unsafe code execution happens through `Sandbox`, `Commands`, `Filesystem`, `Git`, `Volume`, and `Template` APIs. The caution is equally important: this repository defines the client contract and tests hosted behavior, but it does not include the actual hypervisor runner or network-enforcement implementation. Security claims must be verified against the deployed E2B platform or the separate infrastructure repository before self-hosting assumptions are adopted.

## What It Is

E2B is a monorepo for the core E2B SDKs and CLI used to create and control secure cloud sandboxes for AI agents. The repo contains:

- `spec/openapi.yml`: cloud control-plane API contract for sandboxes, templates, snapshots, tags, auth, metrics, and volumes.
- `spec/envd/envd.yaml`, `spec/envd/process/process.proto`, `spec/envd/filesystem/filesystem.proto`: in-sandbox controller contracts for health, metrics, file transfer, command/process streaming, PTY, signals, stdin, filesystem metadata, and watch events.
- `packages/js-sdk`: TypeScript SDK exposing `Sandbox`, `Commands`, `Filesystem`, `Git`, `Volume`, `Template`, generated API clients, and runtime-specific transport handling.
- `packages/python-sdk`: Python sync and async SDKs with matching sandbox, command, filesystem, git, volume, and template abstractions.
- `packages/cli`: CLI for auth, sandbox create/connect/exec/list/info/logs/metrics/pause/resume/kill, template init/build/list/delete/migrate/publish, and interactive PTY attachment.
- `templates/base`: base template metadata and Dockerfile with Python, Node.js, Git, GitHub CLI, build tools, and package managers.
- `packages/connect-python`: Connect RPC support used by the Python SDK.

Official E2B docs describe the product as isolated Linux VM sandboxes for code execution, and product pages state Firecracker-backed microVM isolation. In this repo, the inspectable architecture is the SDK/API/envd contract around that runtime, not the runtime implementation itself.

## Research Themes

- Token efficiency: Not a token or prompt system. It reduces token pressure indirectly by moving working state into a remote filesystem, long-running processes, volumes, and snapshots instead of repeatedly serializing artifacts into prompts.
- Context control: Strong operational context handle: `sandboxId`, template ID/name, metadata, env vars, envd version, network settings, lifecycle policy, volume mounts, and snapshot IDs. It does not implement prompt-context filtering or semantic memory.
- Sub-agent / multi-agent: Supports many separate sandboxes and reconnecting to the same sandbox from multiple clients. MCP gateway support can expose MCP servers inside a sandbox. No native multi-agent scheduler or role orchestration is present.
- Domain-specific workflow: Very strong for coding/data/agent runtimes: shell commands, PTY, files, git, templates, snapshots, public app URLs, persistent volumes, and CLI workflows.
- Error prevention: Uses typed API errors, request and command timeouts, envd feature/version gates, nonzero command exit exceptions, cleanup fixtures, network policy tests, file signing tests, CI on Linux/Windows, and build log polling.
- Self-learning / memory: No learning or memory layer. Durable state comes from sandbox filesystem, pause/resume, snapshots, and volumes.
- Popular skills: Create/connect/kill sandbox, run commands with streaming output, send stdin/close stdin, open PTY, upload/download/read/write/watch files, git clone/status/commit/push/pull, restrict outbound network, protect public traffic with token, build templates, mount volumes, and expose MCP gateway.

## Core Execution Path

Sandbox creation starts in `Sandbox.create()` in both SDKs. The SDK builds a `ConnectionConfig` from options and environment variables such as `E2B_API_KEY`, `E2B_ACCESS_TOKEN`, `E2B_DOMAIN`, `E2B_API_URL`, and `E2B_SANDBOX_URL`. The JS SDK calls `POST /sandboxes` with `templateID`, metadata, env vars, timeout, `secure` defaulting to `true`, `allow_internet_access` defaulting to `true`, optional `network`, `mcp`, `volumeMounts`, and lifecycle settings. The API response returns `sandboxID`, optional domain, `envdVersion`, optional `envdAccessToken`, and optional `trafficAccessToken`.

The SDK then constructs the sandbox controller URL, normally `https://49983-{sandboxID}.{sandboxDomain}`, and attaches headers identifying the sandbox and envd port. When secure access is enabled, every envd REST or Connect RPC call includes `X-Access-Token: <envdAccessToken>`. The control API uses `X-API-KEY` or Bearer access token, while the sandbox controller uses the envd token.

Command execution goes through the envd Process Connect service. `commands.run()` starts `/bin/bash -l -c <cmd>` with optional cwd, env vars, stdin, timeout, and user. The selected Linux user is encoded as a Basic `Authorization` header with username and empty password. The RPC stream emits start, stdout/stderr/pty data, keepalive, and end events. The SDK accumulates output, exposes a handle for background commands, raises `CommandExitError` / `CommandExitException` on nonzero exit, and kills remote processes through `SIGKILL`.

Filesystem content transfer uses the envd REST `/files` endpoint. Reads support text, bytes/blob/stream variants, gzip response handling, path, and username. Writes use multipart form data or newer octet-stream upload, optionally gzip-compressed; missing parent directories are created by the server. Metadata operations use the Filesystem Connect service: stat, mkdir, move, list with depth, remove, and watch directory. Secure sandboxes can produce signed upload/download URLs based on `sha256(path:operation:user:envdAccessToken[:expiration])`.

Network boundaries are expressed in the create payload. `allowInternetAccess: false` is equivalent in docs and spec to denying `0.0.0.0/0`. `network.allowOut` and `network.denyOut` define egress allow/deny rules; allow rules take precedence. `network.allowPublicTraffic: false` protects public sandbox port URLs with `e2b-traffic-access-token`. `maskRequestHost` lets the hosted proxy rewrite Host headers for exposed services.

Template build paths serialize runtime images from Docker images or E2B templates plus RUN/COPY/ENV/USER/WORKDIR/start/ready steps. The JS SDK validates COPY sources as relative paths inside the context, reads `.dockerignore`, hashes file inputs, requests upload links, uploads tar archives, triggers the build, and polls logs until ready/error. Official docs clarify that start commands run during template build, the ready command gates snapshot creation, and the running process is captured in the template snapshot rather than re-executed on every sandbox creation.

## Architecture

E2B's inspectable architecture has three layers:

- Control plane API: authenticated API for sandboxes, templates, builds, snapshots, logs, metrics, tags, volumes, and lifecycle transitions.
- Sandbox controller: `envd` service inside each sandbox, exposed through a sandbox-scoped URL and accessed by SDKs through REST and Connect RPC.
- Public traffic proxy: per-port hostnames from `getHost(port)`, optionally protected by `trafficAccessToken`.

The security boundary is designed to be the sandbox runtime, not the SDK. The SDK intentionally exposes powerful operations: arbitrary shell, PTY, git commands, file writes/removes, root user operations when requested, and public services. This is right for a full-computer agent runtime, but it means authorization and isolation must be correct below the SDK layer.

The repo's contracts show several distinct boundaries:

- API boundary: `ApiClient` authenticates to `api.<domain>` with team API key or access token.
- Controller boundary: envd requires `X-Access-Token` when secure access is enabled.
- User boundary inside sandbox: a Basic auth username selects the Linux user for commands and filesystem operations; it is not a password-auth mechanism.
- Filesystem boundary: paths are sandbox-internal, relative paths resolve through the selected/default user, and absolute paths are allowed.
- Process boundary: started commands are normal sandbox processes with PID handles and signal delivery.
- Network boundary: outbound egress policy and inbound public traffic auth are delegated to the hosted platform/proxy, represented in API schema and tested from the SDK.
- Persistence boundary: sandbox pause/resume and snapshots preserve runtime state; volumes provide persistent storage independent of sandbox lifetime.

The important gap is runtime implementation. There is no runner, Firecracker manager, kernel/jailer config, envd server implementation, or network firewall implementation in this repo. Official docs and product pages describe isolated VMs and Firecracker-backed sandboxes, but the reviewed source only verifies that SDKs request and test those behaviors.

## Design Choices

E2B chooses a remote runtime object over local sandboxing. `Sandbox` is not a process wrapper; it is a client-side handle to a hosted Linux environment. This makes agent integration easy and keeps untrusted execution off the agent host.

Secure access defaults to on. JS and Python SDKs pass `secure: true` by default, attach the returned envd token to controller calls, and generate pre-signed file URLs when needed. Docs explicitly discourage disabling secure access. Version checks force users to rebuild templates when envd is too old for required SDK features.

Commands run through a shell (`/bin/bash -l -c`). This is ergonomic for agents and mirrors terminal use, but callers must not concatenate untrusted user strings without quoting. The Git helper is better hardened: it builds shell-safe git commands, strips embedded credentials after clone by default, disables interactive prompts, and marks global credential storage as dangerous.

The filesystem API is deliberately broad. It supports arbitrary reads/writes/removes within the sandbox, including root-owned paths when run as root. This is appropriate for coding agents that must install dependencies, edit config, and inspect outputs, but not a fine-grained data-access-control model.

Network defaults favor convenience. Internet access is on by default, and public port URLs are public unless `allowPublicTraffic` is set to `false`. For sensitive agent workloads, callers should explicitly set egress allow lists or `allowInternetAccess: false`, and protect public traffic with a traffic token.

Templates prioritize fast, ready-to-use environments. Build-time start/ready commands and snapshots let users prewarm servers or tools. The base template includes Python, Node.js, Git, GitHub CLI, build tools, npm, and yarn, which is useful for coding agents but broader than a least-privilege runtime.

The SDKs are generated-contract friendly. Large OpenAPI and protobuf outputs are generated from `spec/`, while hand-written code wraps the generated clients with higher-level errors, timeouts, compatibility checks, and idiomatic JS/Python overloads.

## Strengths

The SDK/API surface maps very well to coding-agent needs. A model can get a clean Linux environment, install packages, run test commands, stream logs, inspect files, commit changes, and expose preview services without touching the user's local machine.

The auth model separates control-plane credentials from sandbox-controller credentials. `X-API-KEY` or access token controls the account/team API, while `envdAccessToken` controls the per-sandbox controller, and optional traffic tokens protect app ports.

Network policy is first-class and tested. JS and Python tests verify deny-all, allow exceptions, deny specific IPs, allow-over-deny precedence, disabled internet, public traffic token behavior, and host masking.

Filesystem and process APIs are practical rather than toy examples. They include background process handles, reconnect, stdin, close-stdin, PTY resize/input, file streaming/blob/bytes formats, gzip, recursive watch, metadata, symlinks, and path ownership.

Lifecycle persistence is useful for long-running agents. Pause/resume, auto-resume, snapshots, volume mounts, and timeout changes let agents survive across function invocations or reuse prepared runtime state.

The repo has broad cross-language verification. JS SDK tests cover node, browser, bun, and deno paths; Python tests cover sync and async APIs; CLI tests cover exec stdin and backend integration; GitHub Actions run Linux and Windows matrices with real `E2B_API_KEY` integration.

## Weaknesses

The repo does not include the core isolation implementation. Firecracker/microVM, host networking, envd server, and self-hosted infrastructure cannot be audited from this checkout. The note can verify SDK contracts and tests, not the VM security substrate.

Public app access is easy to under-secure. `secure: true` protects envd controller APIs, but exposed app ports are a separate surface. Callers must set `network.allowPublicTraffic: false` when they want token-protected preview URLs.

The command API is intentionally shell-based. Agent authors must quote inputs carefully. The SDK cannot prevent command injection if application code builds shell strings from untrusted user content.

Filesystem access is all-or-nothing at sandbox scope. There is no SDK-level allowlist restricting agents to a workspace directory, no policy for secrets in home directories, and no redaction layer for file reads.

Network controls are represented at create time in SDK source, but the latest docs also describe runtime `PUT /sandboxes/{sandboxID}/network`. That endpoint was not present in the reviewed `spec/openapi.yml`, showing docs/API drift that should be checked before depending on runtime network updates.

One JS test appears stale: `packages/js-sdk/tests/sandbox/commands/kill.test.ts` imports `ProcessExitError`, while source exports `CommandExitError`. This may be hidden by test selection or package aliasing, but it is a local consistency risk.

The generated MCP server type file comes from a very large registry JSON. Useful for MCP gateway configuration, but high-noise for security review and potentially expands the attack surface when arbitrary third-party MCP servers are pulled into a sandbox.

## Ideas To Steal

Use a remote sandbox handle as the coding-agent execution boundary. Persist only `sandbox_id`, template, network policy, volume mounts, and lifecycle state in agent context; keep files/processes in the sandbox.

Separate API credentials from per-sandbox controller tokens. A leaked file URL or sandbox hostname should not grant team-wide API access.

Expose a small set of high-value primitives: `commands.run`, `commands.connect`, `commands.kill`, `files.read/write/list/watch`, `git.clone/status/commit`, `getHost`, `snapshot`, `pause`, and `volumeMounts`.

Make network policy explicit in every sensitive agent run. Default to deny-all plus allowlist for package registries, source hosts, and test endpoints when possible.

Use pre-signed file URLs for direct artifact transfer. Include path, operation, user, token, and expiration in the signature input.

Gate SDK features by runtime controller version. Produce actionable errors that tell users to rebuild templates when old sandboxes lack secure access, stdin close, recursive watch, metrics, or octet-stream upload.

Capture ready runtime state during template build. Start servers or prepare dependency caches once, wait with ready commands, and snapshot the state so agent sessions start fast.

Add integration tests that verify security behavior from outside and inside the sandbox: blocked egress, allowed egress, protected public ports, expired signatures, reconnection, stdin EOF, and process cleanup.

## Do Not Copy

Do not copy the isolation claim without the isolation implementation. A client SDK plus tests is not a sandbox. If building local/self-hosted execution, specify and verify the runtime substrate separately: Firecracker, gVisor, Kata, Sysbox, or another hardened boundary.

Do not expose app ports publicly by default for private agent work. Keep preview URLs authenticated or short-lived when code, logs, or generated apps may reveal secrets.

Do not treat shell commands as structured execution. For user-provided inputs, add argument arrays or robust quoting helpers instead of interpolating strings into `/bin/bash -c`.

Do not give agents root by default unless the task needs it. E2B supports root operations, but an agent execution policy should choose the least privileged sandbox user that still works.

Do not mix long-lived secrets into sandbox environment variables casually. Commands can print env vars, files can persist, snapshots can capture state, and volumes can outlive sandboxes.

Do not rely on generated clients as the security model. Generated schemas help consistency, but the meaningful safety controls are auth, runtime isolation, network policy, lifecycle cleanup, and tests that actually execute blocked paths.

## Fit For Agentic Coding Lab

E2B is a high-fit reference for the `agent-support-systems` category. It shows what a production-grade coding-agent execution surface should feel like: one object for a disposable computer, narrow but powerful file/process/network APIs, lifecycle persistence, templates, and verification coverage around unsafe edges.

The best reusable artifacts are not the exact SDK code, but the boundaries: control API vs sandbox controller, per-sandbox envd token, signed file URLs, explicit network policy, typed command handles, version-gated capabilities, and template snapshots for fast startup. Agentic Coding Lab should combine these with stricter local policy: workspace allowlists, shell quoting requirements, default egress denial, preview auth by default, and independently verified runtime isolation.

## Reviewed Paths

- `README.md`, `packages/js-sdk/README.md`, `packages/python-sdk/README.md`, `packages/cli/README.md`: product scope, secure isolated cloud sandbox positioning, API key setup, basic command execution, Code Interpreter pointer, CLI auth distinction between API key and access token.
- `spec/openapi.yml`: control-plane auth schemes, sandbox create/get/list/kill/connect/pause/timeout/snapshot/metrics/logs, network config, secure flag, env vars, lifecycle, templates, tags, volumes, and envd/traffic tokens.
- `spec/envd/envd.yaml`: in-sandbox envd REST surface for health, metrics, init/env vars, `/files` download/upload, `X-Access-Token`, username, signature, and signature expiration.
- `spec/envd/process/process.proto`, `spec/envd/filesystem/filesystem.proto`: Connect RPC contracts for processes, PTY, stdin, signals, close stdin, list/connect/start, filesystem metadata, move/list/mkdir/remove/watch.
- `packages/js-sdk/src/connectionConfig.ts`, `api/index.ts`, `sandbox/index.ts`, `sandbox/sandboxApi.ts`, `sandbox/signature.ts`, `envd/*.ts`: JS SDK connection/auth, envd URL construction, secure headers, sandbox creation, lifecycle, signed URLs, error mapping, HTTP/2/undici transport, and RPC auth user header.
- `packages/js-sdk/src/sandbox/commands/**`, `filesystem/**`, `git/**`: command execution, streaming handles, PTY, file operations, watch handles, git helper quoting, credential handling, and dangerous credential storage warning.
- `packages/js-sdk/src/template/**`, `packages/js-sdk/src/volume/**`: template builder, Dockerfile parser, relative path validation, file hashing/tar upload, build polling, ready commands, volume token API, standalone volume file operations.
- `packages/python-sdk/e2b/connection_config.py`, `api/__init__.py`, `sandbox/**`, `sandbox_sync/**`, `sandbox_async/**`, `volume/**`, `template*`: Python parity for sync/async sandbox, command, filesystem, signature, API auth, volume, and template flows.
- `packages/cli/src/api.ts`, `terminal.ts`, `commands/sandbox/**`, `commands/template/**`: CLI credential lookup, sandbox create/connect/exec, PTY bridge, stdin piping with close-stdin, keepalive, template build/init/list/delete/migrate/publish behavior.
- `templates/base/e2b.toml`, `templates/base/e2b.Dockerfile`: default base template configuration and included runtime tools.
- `packages/js-sdk/tests/sandbox/**`, `packages/python-sdk/tests/**`: create/connect/kill/timeout/metrics/snapshot/lifecycle, secure access, network egress and public traffic auth, commands, PTY, filesystem, git, config propagation, sync and async parity.
- `packages/js-sdk/tests/template/**`, `packages/js-sdk/tests/volume/**`, `packages/cli/tests/**`, `.github/workflows/*_tests.yml`: template build/upload/tag/stacktrace tests, volume CRUD/file tests, CLI exec tests, and CI verification setup.
- `packages/js-sdk/example.mts`, `packages/python-sdk/example.py`, `packages/js-sdk/tests/integration/template/**`: minimal SDK examples and integration template example.
- Official docs reviewed through crawled pages: `https://e2b.dev/docs`, `https://e2b.dev/docs/sandbox/secured-access`, `https://e2b.dev/docs/sandbox/internet-access`, `https://e2b.dev/docs/sandbox/auto-resume`, `https://e2b.dev/docs/sandbox/persistence`, `https://e2b.dev/docs/sandbox/snapshots`, `https://e2b.dev/docs/commands`, `https://e2b.dev/docs/filesystem/read-write`, `https://e2b.dev/docs/volumes`, `https://e2b.dev/docs/sandbox-template`, and `https://e2b.dev/docs/template/start-ready-command`.

## Excluded Paths

- `packages/js-sdk/src/api/schema.gen.ts`, `packages/js-sdk/src/envd/**/*_pb.ts`, `packages/js-sdk/src/envd/**/*_connect.ts`, `packages/js-sdk/src/volume/schema.gen.ts`: generated OpenAPI/protobuf clients; reviewed source specs and handwritten wrappers instead.
- `packages/python-sdk/e2b/api/client/**`, `packages/python-sdk/e2b/envd/**/*_pb2.py`, `packages/python-sdk/e2b/envd/**/*_connect.py`, `packages/python-sdk/e2b/volume/client/**`: generated Python clients and models; useful for typing but redundant with `spec/` and wrapper code.
- `spec/mcp-server.json` and generated `packages/js-sdk/src/sandbox/mcp.d.ts`: very large MCP registry/type output. Not reviewed deeply because it is third-party catalog data rather than E2B sandbox runtime logic; MCP gateway integration was reviewed through SDK creation flow.
- `readme-assets/*.png`: binary/visual assets unrelated to runtime architecture.
- `pnpm-lock.yaml`, `packages/python-sdk/poetry.lock`, `go.sum`, `package-lock`-style dependency snapshots if present: lockfiles; noted dependency posture but not architecture.
- `supabase/**`: local Supabase development configuration and functions, not part of the sandbox runtime/control SDK path reviewed here.
- `packages/connect-python/cmd/protoc-gen-connect-python/**`: generator internals for Python Connect support; only README and role in Python RPC stack were reviewed.
- `packages/cli/src/templates/*.hbs`, `packages/cli/src/commands/template/generators/**`: CLI scaffolding presentation for new templates; lower signal than template SDK/build/runtime code.
- Browser UI-only tests under `packages/js-sdk/tests/runtimes/browser/**`: runtime compatibility smoke tests; not central to secure sandbox execution.
- External repositories linked from README/docs such as `e2b-dev/infra`, `e2b-dev/code-interpreter`, and `e2b-dev/e2b-cookbook`: relevant ecosystem context but outside the assigned `e2b-dev/E2B` checkout.
