# agentscope-ai/agentscope-runtime

- URL: https://github.com/agentscope-ai/agentscope-runtime
- Category: agent-support-systems
- Stars snapshot: 804 (GitHub REST API, captured 2026-05-29)
- Reviewed commit: 723f61e835132ac820e03e7661228c9a1b7edaab
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: conditional
- Verdict: Useful as a reference implementation for agent service APIs, session-scoped sandboxes, deployment packaging, and interruptible streaming execution, but treat it as a pattern source rather than a dependency because the repo now carries an AgentScope 2.0 migration/archive notice and its default security posture requires hardening before coding-agent use.

## Why It Matters

AgentScope Runtime is one of the more complete open implementations of the "agent as a production service" layer: it turns framework-native agents into streaming HTTP services, exposes protocol adapters, manages sandbox lifecycles, and packages services for local, Kubernetes, Knative, serverless, and Alibaba Cloud targets. For Agentic Coding Lab, the interesting parts are not the agent framework integrations themselves, but the reusable support-system boundaries around tool execution, session reuse, interrupts, deployment, and runtime APIs.

The caveat is important: the README states that AgentScope Runtime capabilities have been integrated into AgentScope 2.0 and recommends migration. The GitHub API still reports the repository as not archived at this snapshot, but the latest reviewed commit is an archive notice. This makes it a strong design specimen and a weaker candidate for direct adoption.

## What It Is

The repo is a Python package (`agentscope-runtime` 1.1.6) centered on:

- `AgentApp`, a `FastAPI` subclass that registers query handlers, custom endpoints, background tasks, interrupt controls, and protocol adapters.
- `Runner`, which normalizes agent execution into a structured event stream with request/session IDs and framework-specific message adapters.
- A sandbox subsystem with local embedded and remote manager modes, Docker/gVisor/BoxLite/Kubernetes/cloud backends, per-sandbox inner HTTP servers, bearer-token calls, MCP server attachment, and stateful workspace mounting.
- Deployment managers that package an app or runner, build container images, and deploy locally, to Kubernetes/Knative/Kruise, or to cloud/serverless targets.

## Research Themes

- Token efficiency: Low direct relevance. It streams deltas and stores only final responses for background stream tasks, but it does not implement prompt compression, context budgeting, or cache-aware coding workflows.
- Context control: Moderate relevance. The structured `AgentRequest`/`AgentResponse` protocol, session IDs, user IDs, and framework adapters provide clean context ingress/egress boundaries. Session persistence is delegated to the developer's session service.
- Sub-agent / multi-agent: Conditional relevance. It exposes A2A endpoints and registry hooks, but this is service discovery and protocol interop, not a rich internal multi-agent planner.
- Domain-specific workflow: High relevance for coding agents that need shell, Python, filesystem, browser, GUI, or mobile tools behind a runtime service boundary.
- Error prevention: Moderate relevance. It has typed request/response schemas, lifecycle hooks, task state, interrupt state, heartbeat-based sandbox reaping, and tests around deployment and routing. It lacks policy-level tool approval and verification semantics.
- Self-learning / memory: Low-to-moderate relevance. It includes memory/session examples and ModelStudio memory tools, but durable learning is not the core runtime design.
- Popular skills: Sandboxed command execution, stateful IPython, workspace file operations, browser/GUI/mobile automation, MCP server injection, SSE agent APIs, OpenAI Responses-compatible endpoints, A2A registration, background task polling, and interrupt/resume patterns.

## Core Execution Path

`AgentApp` initializes FastAPI with an internal lifespan manager, then builds a `Runner` from decorated `init`, `query`, and `shutdown` handlers. A query handler registered with `@app.query(framework="agentscope")` is bound onto the runner with `types.MethodType`, and `_add_endpoint_router` creates a `POST /process` endpoint that returns Server-Sent Events.

At request time, the endpoint passes request JSON into `_stream_generator`. If interrupt support is active, the request is wrapped by `InterruptMixin.run_and_stream` using the `user_id:session_id` key; otherwise it streams directly from `Runner.stream_query`. The runner assigns missing session/user IDs, emits response `created` and `in_progress` events, converts input messages for the selected framework, calls the user handler, adapts framework-native output back into `Event` objects, appends completed assistant messages to the final response, and emits either a completed or failed response.

The sandbox path is separate. `BaseSandbox` and its variants ask `SandboxManager` for a sandbox from a pool or a new container, then call an inner sandbox FastAPI server through `SandboxHttpClient`. Built-in generic tools call `/tools/run_ipython_cell` and `/tools/run_shell_command`; MCP tools are loaded into the sandbox process through `/mcp/add_servers`, listed through `/mcp/list_tools`, and executed through `/mcp/call_tool`.

## Architecture

The service layer is a set of mixins around FastAPI:

- `UnifiedRoutingMixin` discovers/restores custom endpoints and adds task endpoints.
- `TaskEngineMixin` supports Celery-backed tasks when broker/backend URLs are configured and falls back to in-memory asyncio tasks.
- `InterruptMixin` uses a local in-memory backend or Redis backend for run-state CAS, pub/sub stop signals, and single-run-per-session conflict control.
- Protocol adapters mount OpenAI Responses-compatible, A2A, and AG-UI endpoints over the same runner stream.

The sandbox layer has two trust zones:

- The outer `runtime-sandbox-server` manages sandbox containers, pools, heartbeat, restore, storage, and release. Its bearer token is optional.
- Each sandbox container runs an inner FastAPI app behind Nginx and `SECRET_TOKEN`. The manager creates a random runtime token per container and sends it as bearer auth for tool calls.

Deployment is package-first. The deployer discovers the app/runner source, copies the project while ignoring `.env`, `.git`, virtualenvs, caches, build output, logs, and `.agentscope_runtime`, generates an entrypoint if needed, writes requirements, builds images for container targets, and records deployment state. Local deployment supports daemon-thread and detached-process modes.

## Design Choices

- Direct FastAPI inheritance keeps `AgentApp` compatible with native routes, middleware, OpenAPI generation, and lifespan patterns.
- The core API uses a small event schema with `sequence_number`, object/status fields, message/content subtypes, and OpenAI-like request parameters.
- Protocol compatibility is adapter-based rather than hard-coded into `Runner`, which keeps A2A, Responses API, and AG-UI as replaceable boundary modules.
- Sandbox state is keyed by a composite session context and can reuse the same container across calls, preserving IPython variables and workspace state.
- Sandbox creation defaults to Docker but can be switched to gVisor, BoxLite, Kubernetes, AgentRun, Function Compute, or other registered backends.
- Sandbox tool execution is intentionally powerful: shell commands and IPython cells are first-class tools. The isolation boundary is the sandbox runtime, not command filtering.
- Interrupts cancel the outer async generator and require developer cooperation inside the handler to interrupt the underlying agent/model loop and persist state.

## Strengths

- Clear runtime API surface for exposing agents as streaming services, background tasks, OpenAI-compatible Responses endpoints, A2A endpoints, and custom FastAPI routes.
- Good separation between agent execution, protocol conversion, deployment packaging, and sandbox orchestration.
- Practical sandbox lifecycle model: pool allocation, per-session mapping, heartbeat touch/reap, restore markers, workspace storage upload/download, and explicit release.
- The sandbox client supports stateful shell/IPython execution, MCP server injection, file workspace operations, and GUI/browser/mobile variants.
- Deployment coverage is broad, with mocked unit tests for image packaging and multiple deployers plus examples for local daemon, detached, Kubernetes, serverless, and cloud targets.
- The package ignore rules explicitly exclude common secret/build directories such as `.env`, `.git`, virtualenvs, logs, and `.agentscope_runtime`.
- Interrupt state uses CAS semantics to reject duplicate active runs for the same `user_id:session_id`, and Redis support makes that pattern portable beyond one process.

## Weaknesses

- The repository is effectively superseded by AgentScope 2.0 according to its own README archive notice, so direct adoption has maintenance risk.
- Security defaults are permissive: `AgentApp` has no authentication by default, both the agent app and sandbox manager add wildcard CORS, and sandbox manager bearer auth is skipped when `BEARER_TOKEN` is unset.
- The base sandbox image runs under supervisord as root and the Docker backend relies on default container isolation unless users select gVisor/BoxLite or pass stricter runtime config.
- `run_shell_command` executes arbitrary shell strings inside the sandbox with no allowlist or approval layer, and marks errors based on stderr rather than nonzero return code.
- Response API adapter declares a timeout field but the streaming timeout wrapper does not actually wrap iteration in `asyncio.wait_for`, so long streams are not bounded by that setting.
- Framework compatibility is uneven: the runner contains adapters beyond what `AgentApp.query` allows, and docs/examples still show deprecated `@app.init` patterns in several places.
- The sandbox manager has optional Redis for multi-worker state; without Redis, manager state is process-local and not safe for horizontally scaled manager workers.

## Ideas To Steal

- Model the coding-agent runtime as a normal web service wrapper, not as a special agent class: native FastAPI routes plus a narrow runner stream is a useful shape.
- Use a structured event stream with stable sequence numbers and explicit response/message/content lifecycle statuses.
- Keep protocol adapters outside the core runner so OpenAI-compatible, A2A, UI, and internal APIs can share one execution path.
- Treat sandbox sessions as managed resources with allocation, heartbeat, restore, release, storage sync, and per-session reuse, rather than as one-off subprocess calls.
- Provide both streaming and submit/poll task modes; for long coding jobs, store final state separately from transient stream deltas.
- Add distributed interrupt as a small backend interface with local and Redis implementations; require handlers to catch cancellation and persist state.
- Package deployments from an entrypoint plus explicit ignore rules, and make the generated runtime entrypoint visible and testable.

## Do Not Copy

- Do not expose remote shell/IPython execution behind optional auth and wildcard CORS.
- Do not rely on Docker default isolation for hostile coding-agent workloads; require gVisor, VM/microVM isolation, rootless containers, seccomp/AppArmor, network policy, resource quotas, and explicit mount policy.
- Do not use session IDs supplied by clients as the only isolation boundary without authenticated identity and authorization checks.
- Do not implement tool safety only at the sandbox boundary; coding agents need command intent review, path restrictions, secret redaction, output caps, and verification hooks.
- Do not silently ignore configured timeouts or use comments/docs that imply enforcement not present in code.
- Do not keep deprecated lifecycle examples as primary docs; they increase copy-paste risk for new users.

## Fit For Agentic Coding Lab

Fit is conditional but valuable. The repo is not specifically about AI coding workflows, yet it implements several support-system primitives a coding lab needs: service APIs around agent execution, sandboxed shell/Python/file/browser tools, per-session workspaces, streaming events, task polling, interrupts, and deployable runtimes.

The best use is as an architectural reference for a hardened coding-agent runtime. Agentic Coding Lab should borrow the session-scoped sandbox manager, event protocol, adapter boundary, and interrupt lifecycle, but replace the permissive defaults with mandatory auth, explicit authorization, hardened isolation, policy-aware tool mediation, and coding-specific verification.

## Reviewed Paths

- `README.md`
- `pyproject.toml`
- `src/agentscope_runtime/engine/app/agent_app.py`
- `src/agentscope_runtime/engine/runner.py`
- `src/agentscope_runtime/engine/schemas/agent_schemas.py`
- `src/agentscope_runtime/engine/deployers/local_deployer.py`
- `src/agentscope_runtime/engine/deployers/kubernetes_deployer.py`
- `src/agentscope_runtime/engine/deployers/utils/package.py`
- `src/agentscope_runtime/engine/deployers/utils/detached_app.py`
- `src/agentscope_runtime/engine/deployers/utils/service_utils/routing/`
- `src/agentscope_runtime/engine/deployers/utils/service_utils/interrupt/`
- `src/agentscope_runtime/engine/deployers/adapter/responses/`
- `src/agentscope_runtime/engine/deployers/adapter/a2a/`
- `src/agentscope_runtime/engine/deployers/adapter/agui/`
- `src/agentscope_runtime/engine/services/sandbox/`
- `src/agentscope_runtime/sandbox/box/sandbox.py`
- `src/agentscope_runtime/sandbox/box/base/`
- `src/agentscope_runtime/sandbox/box/shared/`
- `src/agentscope_runtime/sandbox/client/`
- `src/agentscope_runtime/sandbox/manager/`
- `src/agentscope_runtime/common/container_clients/`
- `src/agentscope_runtime/adapters/agentscope/tool/`
- `cookbook/en/concept.md`
- `cookbook/en/agent_app.md`
- `cookbook/en/sandbox/sandbox.md`
- `cookbook/en/sandbox/advanced.md`
- `cookbook/en/deployment.md`
- `cookbook/en/advanced_deployment.md`
- `examples/deployments/`
- `examples/interrupt/interrupt_and_restore_example.py`
- `tests/unit/`
- `tests/integrated/`
- `tests/sandbox/`
- `tests/deploy/`

## Excluded Paths

- `README_zh.md` and `cookbook/zh/`: Chinese duplicates of English docs; English docs were reviewed.
- `web/starter_webui/`: UI shell for chat interactions; not central to runtime APIs, sandboxing, or coding-agent isolation.
- Provider-specific tool implementations under `src/agentscope_runtime/tools/` such as Alipay, generation, ASR/TTS, RAG, and search tools; reviewed only at the adapter boundary because the task focus was runtime and sandbox support.
- Binary/media fixtures under `tests/tools/assets/` and image-heavy docs examples; not relevant to architecture or security assessment.
- Generated package metadata, cache/build outputs, and static cookbook assets; excluded as non-runtime implementation.
