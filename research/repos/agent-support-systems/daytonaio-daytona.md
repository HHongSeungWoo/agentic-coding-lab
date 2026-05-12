# daytonaio/daytona

- URL: https://github.com/daytonaio/daytona
- Category: agent-support-systems
- Stars snapshot: 72,401 (GitHub REST API `stargazers_count`, captured 2026-05-12)
- Reviewed commit: efe8213bdfa731493b330bfae9ce36f5679cf7a8
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong reference for secure elastic agent runtimes, especially API/runner/daemon separation, async runner jobs, network policy, snapshots, and SDK/MCP integration. Do not copy its security posture blindly: actual open-source runner code uses Docker containers with `Privileged: true` and relies on Sysbox/runtime configuration, runner isolation, proxy auth, and network controls rather than a small in-process sandbox.

## Why It Matters

Daytona is directly relevant to coding-agent infrastructure because it treats the agent runtime as a managed remote computer, not as a subprocess bolted onto the agent host. It has a real control plane, runner fleet model, toolbox daemon inside each sandbox, SDKs, MCP tools, preview URLs, SSH, snapshots, volumes, and lifecycle policies.

The useful pattern for Agentic Coding Lab is the product boundary: users and agents ask the control plane for an isolated execution environment, then interact through narrow file/process/git/terminal APIs. The risky part is also clear from source: isolation strength depends on the deployed container runtime and runner network/host hardening, not on the daemon API alone.

## What It Is

Daytona is a monorepo for a managed and self-hostable sandbox platform for AI-generated code execution. It is split into:

- `apps/api`: NestJS control plane for authentication, organizations, quotas, sandbox lifecycle, snapshots, volumes, runners, jobs, preview and toolbox routing.
- `apps/runner`: Go compute-plane service that talks to Docker, starts sandboxes, applies resource/network policy, runs v2 jobs, sends health metrics, and hosts a runner API.
- `apps/daemon`: Go toolbox agent injected into each sandbox container, exposing file, git, process, code-run, session, PTY, LSP, computer-use, recording, terminal, and SSH services.
- `apps/proxy`: external preview/toolbox reverse proxy with auth, signed preview URLs, runner resolution, and last-activity updates.
- `apps/cli/mcp`: MCP server exposing sandbox creation, file operations, git clone, command execution, preview link generation, and sandbox deletion to AI clients.
- `libs/sdk-*`: SDK wrappers over the API and toolbox APIs.
- `images/sandbox`: default agent-oriented sandbox image with Python, Node, Claude Code, OpenCode, OpenAI/Anthropic libraries, desktop/VNC dependencies, and Daytona SDK packages.

## Research Themes

- Token efficiency: Not a token system. It reduces context pressure indirectly by giving agents persistent filesystem/process state and snapshots, so large work products live in the sandbox rather than in prompt history.
- Context control: Strong operational context boundary: a sandbox ID, toolbox URL, snapshot, volumes, env, labels, and lifecycle state become the context handle. The OpenCode/Codex/OpenAI guides inject sandbox path and preview instructions into agent prompts.
- Sub-agent / multi-agent: Supports many sandboxes and many agent sessions; no native multi-agent orchestration layer in core. OpenAI Agents SDK guide demonstrates handoffs and shared sandbox sessions at the integration layer.
- Domain-specific workflow: Very strong for coding/data/desktop-agent workflows: file API, git API, process sessions, PTY, LSP, code interpreter, preview URLs, VNC/computer use, snapshots, and volumes.
- Error prevention: Quotas, resource limits, state machines, pending flags, Redis locks, job uniqueness, stale-job cleanup, egress allow/block policy, auth guards, and lifecycle timeouts reduce common execution failures.
- Self-learning / memory: No agent memory system. Persistence comes from filesystem state, snapshots, pause/resume, volumes, and SDK session state.
- Popular skills: No portable skill library. Reusable patterns are runtime skills: create sandbox, execute command, upload/download file, clone repo, stream logs, create preview URL, snapshot/fork/recover.

## Core Execution Path

Sandbox creation starts in `apps/api/src/sandbox/controllers/sandbox.controller.ts` and `SandboxService.createFromSnapshot` or `createFromBuildInfo`. The API validates organization suspension, quotas, snapshot availability, network settings, volumes, resource limits, and GPU ephemerality, then selects a runner with `RunnerService.getRandomAvailableRunner`. For v2 runners, `RunnerAdapterV2.createSandbox` creates a `CREATE_SANDBOX` job row and notifies the runner through Redis.

The runner starts `healthcheck.Service`, `poller.Service`, and `executor.Executor` when `API_VERSION=2`. The poller long-polls `/jobs/poll`; the API atomically claims pending jobs by saving them as `IN_PROGRESS` with optimistic locking. Executor dispatches `CREATE_SANDBOX`, `START_SANDBOX`, `STOP_SANDBOX`, `DESTROY_SANDBOX`, `UPDATE_SANDBOX_NETWORK_SETTINGS`, `BUILD_SNAPSHOT`, `PULL_SNAPSHOT`, `SNAPSHOT_SANDBOX`, `RECOVER_SANDBOX`, and `RESIZE_SANDBOX` to Docker operations, then reports job status.

`apps/runner/pkg/docker.Create` pulls the snapshot image, validates amd64/x86_64 architecture, creates bind mounts for the daemon binary, optional computer-use plugin, and volumes, creates the Docker container, starts it, waits for the daemon on port `2280`, and applies iptables network rules when requested. `apps/daemon` then exposes toolbox APIs. Client SDKs point toolbox clients at `toolboxProxyUrl + sandbox.id`, while `apps/proxy` and the runner proxy forward authenticated requests to `http://<container-ip>:2280`.

## Architecture

The architecture has three useful planes. The interface plane is CLI, SDKs, MCP, dashboard, SSH, and preview. The control plane is API, proxy, snapshot builder/manager, PostgreSQL, Redis, object storage, and registry. The compute plane is runners, Docker, sandbox containers, daemon, SSH gateway, snapshot store, volumes, and iptables policy.

Isolation is a layered container design. Documentation says production runners use Sysbox as the container runtime for user namespaces and VM-like isolation without hardware virtualization. Source confirms the runner can set `HostConfig.Runtime` from `CONTAINER_RUNTIME`, and runner installation docs default that variable to `sysbox-runc`. Source also shows Docker `HostConfig{Privileged: true}` for sandbox containers, with daemon and computer-use plugin bind-mounted read-only. That means the secure deployment assumption is not plain Docker alone; it is Docker plus Sysbox or equivalent runtime hardening, separate runner hosts, and network policy.

Network isolation has two layers. When `INTER_SANDBOX_NETWORK_ENABLED=false`, the runner creates a `runner-bridge` Docker network with `com.docker.network.bridge.enable_icc=false`. Per-sandbox egress is implemented with iptables chains under `DOCKER-USER`: allow listed CIDRs return, and all other traffic drops. `networkBlockAll` is implemented by an empty allow list, which yields only the final drop rule. A mangle-chain limiter marks packets when organization-level limited egress is enabled.

Filesystem persistence has three modes: container filesystem while stopped, snapshots from OCI images or committed sandbox filesystem, and S3-backed FUSE volumes mounted into containers. Volume subpaths are checked both in API validation and runner mount code to prevent path traversal outside the mounted volume base.

## Design Choices

Daytona favors elastic remote execution over local sandboxing. The API state machine uses `state`, `desiredState`, and `pending` columns to serialize lifecycle changes. Runner jobs are database records with Redis notification as an optimization, not the source of truth. This is a good reliability pattern: Redis can fail and the runner still polls DB-backed jobs.

The toolbox daemon is intentionally broad. It gives agents file read/write/delete, shell commands, code execution, process sessions, PTY, LSP, git, screenshots, desktop input, logs, and terminal services. That breadth is useful for coding agents but means the security boundary must be the sandbox/container/runner boundary, not per-tool authorization inside the daemon.

Network policy is runtime mutable through the API. API guards require organization auth and `WRITE_SANDBOXES`, reject sandbox-level overrides when organization limited egress is enforced, validate CIDR syntax and max 10 entries, then send a runner job that updates iptables. The e2e test verifies default reachable, single-IP allow list, two-IP allow list, block all, and restore all behavior.

The default sandbox image is agent-friendly rather than minimal. It includes Python/Node ecosystems, ML/data libraries, Claude Code, OpenCode, browser/X11/VNC dependencies, and desktop tooling. This improves first-run agent capability but increases image size and attack surface.

## Strengths

Daytona has a mature separation between control plane, compute plane, and in-sandbox toolbox. That separation maps well to agent execution services: the agent cannot accidentally mutate the host if all tool calls are routed through a remote sandbox.

The runner job model is practical. Jobs have type/resource indexes, uniqueness constraints for incomplete jobs, optimistic claiming, Redis wakeup with DB fallback, stale timeout cleanup, and result metadata. This is a strong pattern for asynchronous sandbox lifecycle work.

The platform covers the full coding-agent loop: create runtime, install dependencies, run code, stream long-running logs, edit files, use git, expose preview URLs, snapshot successful state, pause/resume, and delete/auto-stop idle environments.

Security and operations are treated as product features: auth strategies and guards are tested, organization boundaries are enforced, quotas are checked before provisioning, runners report health and resource usage, and network restrictions are both documented and e2e-tested.

## Weaknesses

The sandbox isolation claims in docs are stronger than the plain source path. Source creates privileged Docker containers. Strong isolation depends on `CONTAINER_RUNTIME=sysbox-runc` or a comparable runtime and correct runner deployment. A self-hosted user who runs the compose defaults or omits Sysbox should not assume VM-grade isolation.

The daemon toolbox itself does not enforce its initialized `authToken` on routes; `authToken` is stored and used for telemetry attributes. Access control is at proxy/API/runner layers. That is acceptable if the container network is private and inter-sandbox traffic is disabled, but direct container-network reachability would expose powerful unauthenticated toolbox APIs.

The file API accepts arbitrary paths inside the sandbox OS. That is expected for a full-computer sandbox, but it means a compromised or over-permissioned agent can alter the whole sandbox filesystem, including home/config files and mounted volumes within its mount permissions.

The default image bundles many high-risk packages and agent CLIs. This is convenient but not least-privilege. For sensitive workloads, custom snapshots should be smaller, pinned, scanned, and role-specific.

Open-source deployment defaults are development-oriented in places: Docker Compose sets `RESOURCE_LIMITS_DISABLED=true`, includes demo secrets, and runs API/runner as privileged containers. The docs warn about these, but the safe production path is not the same as the quick local path.

## Ideas To Steal

Use a remote runtime handle as the agent execution boundary: `sandbox_id`, `toolbox_url`, `snapshot`, `resource_limits`, `network_policy`, `auto_stop`, `auto_delete`, and `labels`.

Adopt API-created, runner-polled jobs for lifecycle operations. Store jobs durably; use Redis or another queue only as a notification path; enforce one incomplete lifecycle job per resource; add stale-job cleanup.

Split agent runtime services into two layers: narrow control-plane lifecycle APIs and broad in-sandbox toolbox APIs. Keep toolbox broad enough for coding work, but rely on network and auth boundaries outside the sandbox.

Make egress policy first-class. Support `block_all`, CIDR allow lists, organization-level non-overridable restrictions, and runtime update jobs. Add e2e probes for allowed/blocked destinations.

Prefer snapshots and volumes over prompt memory for long-horizon coding tasks. Snapshots capture configured environments; volumes share caches/datasets; paused sandboxes preserve workspace state.

Inject environment-specific agent instructions at session start: correct working directory, preview URL pattern, background process conventions, cleanup policy, and credential handling warnings.

## Do Not Copy

Do not copy privileged Docker as the security model. If using privileged containers, require Sysbox/Kata/gVisor/microVM or equivalent, document the actual boundary, and test host breakout assumptions.

Do not expose the in-sandbox toolbox on any network reachable by untrusted containers unless toolbox routes enforce auth. Daytona relies on proxy/runner/private-network positioning; copying only the daemon would be unsafe.

Do not ship broad default images for all workloads. Keep agent images task-specific when secrets, tenant data, or regulated code are involved.

Do not treat public preview URLs as a harmless convenience. Daytona correctly keeps toolbox/terminal ports authenticated even when a sandbox is public; preserve that separation.

Do not skip lifecycle cleanup. Auto-stop, auto-archive, auto-delete, stale-job handling, and orphan cleanup are part of the safety story, not operational polish.

## Fit For Agentic Coding Lab

Daytona is one of the best reviewed candidates for the `agent-support-systems` category. It provides concrete patterns for secure elastic runtimes, coding-agent tool surfaces, job execution, preview URLs, snapshots, and runtime persistence.

For Agentic Coding Lab, the strongest reusable artifacts are: a sandbox lifecycle state machine, runner job schema, network policy update workflow, toolbox API shape, MCP tool set, and integration prompt snippets. The main open question is isolation substrate: if the lab wants a local or self-hosted runtime, it should specify microVM/Sysbox/Kata/gVisor requirements and verify them independently instead of inheriting Daytona's deployment assumption.

## Reviewed Paths

- `README.md`: product scope, planes, apps, SDKs, quick start, managed/self-hosted/customer-managed compute.
- `apps/docs/src/content/docs/en/architecture.mdx`: interface/control/compute plane architecture, API/proxy/snapshot builder/sandbox manager, runners, daemon, snapshot store, volumes.
- `apps/docs/src/content/docs/en/sandboxes.mdx`: sandbox lifecycle, resources, GPU ephemerality, stop/archive/recover/fork/snapshot/delete, auto-stop/archive/delete.
- `apps/docs/src/content/docs/en/runners.mdx`: custom regions/runners, runner credentials, health/resource fields, deployment, `CONTAINER_RUNTIME=sysbox-runc`.
- `apps/docs/src/content/docs/en/security-exhibit.mdx`: security claims, Sysbox/user namespace model, sandbox isolation, egress controls, vulnerability and audit posture.
- `apps/docs/src/content/docs/en/oss-deployment.mdx` and `docker/docker-compose.yaml`: local deployment defaults, privileged services, disabled resource limits in compose, inter-sandbox networking warning, demo-secret warning.
- `apps/docs/src/content/docs/en/network-limits.mdx`, `volumes.mdx`, `snapshots.mdx`, `process-code-execution.mdx`, `file-system-operations.mdx`, `mcp.mdx`, `preview.mdx`, `ssh-access.mdx`, `computer-use.mdx`: runtime operations and agent-facing features.
- `apps/api/src/sandbox/**`: sandbox DTO/entity/service/controller, runner service, runner adapters, job service/entity, guards, auth specs, network validation, warm pool, snapshot/volume services.
- `apps/runner/cmd/runner/**`, `apps/runner/pkg/api/**`, `apps/runner/pkg/runner/v2/**`, `apps/runner/pkg/docker/**`, `apps/runner/pkg/netrules/**`: runner config, API auth, poller/executor/healthcheck, Docker lifecycle, resource config, privileged host config, network bridge/iptables, volumes, backup/recovery/snapshot paths.
- `apps/daemon/cmd/daemon/**`, `apps/daemon/pkg/toolbox/**`, `apps/daemon/pkg/session/**`, `apps/daemon/pkg/ssh/**`, `apps/daemon/pkg/terminal/**`: in-sandbox daemon startup, toolbox routes, process/code-run/session/PTTY/LSP/git/filesystem/computer-use APIs.
- `apps/proxy/pkg/proxy/**`: preview/toolbox routing, auth tokens, signed preview URL handling, runner lookup, last-activity updates, protected toolbox/terminal routing.
- `apps/cli/mcp/**`: MCP stdio server, tool definitions for sandbox/file/git/command/preview operations.
- `libs/sdk-typescript/src/Sandbox.ts`, `Process.ts`, related tests: SDK toolbox wiring, command/code-run/session ergonomics.
- `examples/typescript/exec-command/index.ts`, `examples/python/*`, `examples/go/*`, `examples/ruby/*`, `examples/java/*`: SDK usage examples for lifecycle, exec, files, volumes, network settings, PTY, pagination, snapshots.
- `apps/daytona-e2e/*.go`: lifecycle, toolbox proxy chain, runtime network settings, git clone, snapshot-from-sandbox, cleanup, health.
- `apps/docs/src/content/docs/en/guides/codex/**`, `claude/**`, `opencode/**`, `openai-agents/**`: coding-agent integration patterns, prompt injection, sandbox-hosted agents, preview links, pause/resume, git sync, and credential cautions.
- `images/sandbox/Dockerfile`, `images/sandbox/README.md`, `images/sandbox-slim/**`: default runtime image contents and agent tooling.

## Excluded Paths

- `apps/dashboard/**`, most `apps/docs/src/components/**`, `apps/docs/src/assets/**`: UI and static site presentation; reviewed only docs content relevant to runtime/security.
- `libs/api-client*`, `libs/toolbox-api-client*`, `libs/runner-api-client*`, generated Java/Python/Ruby/Go/TypeScript model tests: OpenAPI-generated clients and model snapshots; useful for API surface but not runtime architecture.
- `apps/api/src/migrations/**`, generated Swagger/OpenAPI JSON/YAML in API/runner/daemon/toolbox docs: schema output from source; excluded to avoid generated duplication.
- `hack/**`, `scripts/**` except deployment/security references: packaging/client-generation helper scripts, not sandbox runtime paths.
- `examples/java/**/gradle/wrapper/*.jar`, font/icon/image binaries, GIFs, dashboards JSON, notebooks: binary or UI/demo assets; not needed for architecture.
- `functions/auth0/**`, email templates, dashboard pages, marketing/SEO/docs tooling: authentication provider glue or UI-only concerns outside sandbox runtime.
- `apps/otel-collector/**` and most telemetry dashboards: observability plumbing; noted only where runner/daemon trace propagation affects job/runtime verification.
- `guides/**` source projects beyond representative coding-agent docs: examples are useful for applicability, but many are tutorial apps rather than Daytona runtime implementation.
