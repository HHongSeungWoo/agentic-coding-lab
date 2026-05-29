# google/ax

- URL: https://github.com/google/ax
- Category: agent-support-systems
- Stars snapshot: 1,280 (GitHub REST API repository search, captured 2026-05-29)
- Reviewed commit: bc1af4fb7193ac001969b74b99ec1a30dd783a84
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: conditional
- Verdict: Useful reference for distributed coding-agent runtime primitives: controller-owned execution, durable event logs, conversation replay, fork/resume, agent registry, A2A/ADK/Colab adapters, confirmation-gated shell and skill execution, and Kubernetes/Agent Substrate actor routing. Treat it as a fast-moving design source, not a ready runtime to adopt: default transport is insecure, shell/script tools execute on the controller host after approval, generated Python protos appear stale, and the newer harness path is transitional.

## Why It Matters

AX is directly aimed at the support layer that coding agents need once they move beyond a single local process. It models the runtime as a controller that owns execution state, delegates to isolated local or remote agents, logs every execution event, replays missed stream outputs, forks conversations, and can route each conversation to a resumable actor on Kubernetes Agent Substrate.

For Agentic Coding Lab, the most useful parts are the protocol and runtime patterns: conversation IDs, execution IDs, execution events, internal-only state markers, a registry that turns agents into callable tools, confirmation messages for risky tool calls, and bridges to A2A and Google ADK. The caveat is equally important: this repository is explicitly early, contains two active controller designs, and leaves several security and protocol surfaces unfinished.

## What It Is

AX, Agent eXecutor, is a Go CLI/server plus Python examples for running agentic executions through a controller. The default build provides:

- `ax exec`, `ax serve`, `ax fork`, and `ax trace` CLI commands.
- A gRPC `ControllerService` for streaming execution responses and a `ConversationService` for delete/fork.
- A controller with SQLite-backed conversation and execution logs.
- A Gemini planner that can delegate to registered agents as function tools.
- Local, native gRPC remote, A2A, Agent Substrate, Colab, and ADK-style agent integrations.
- Agent Skills support with activation and script execution tools.
- Kubernetes manifests for Agent Substrate actor deployment and an Envoy authorization/routing sidecar.

The repository also contains a newer `harness` build path around `controller2` and `internal/harness`, including a stub `HarnessService`, Substrate harness, test harness, and Antigravity subprocess harness. That path is not yet feature-equivalent with the default event-log executor path.

## Research Themes

- Token efficiency: AX is not a token optimizer, but it reduces prompt pressure by keeping durable conversation/execution logs outside the prompt, replaying from `last_seq`, and using internal-only messages for hidden state. Its skill system injects only a catalog initially and loads full skill text on activation.
- Context control: Strong context handles: `conversation_id`, `exec_id`, `seq`, `agent_id`, `agent_config`, `internal_only`, and typed content. A2A bridge state is stored as internal-only JSON markers so it survives resumption without being shown to the model or client.
- Sub-agent / multi-agent: Strong in the default path. The Gemini planner exposes registered agents as function declarations, maps tool names to agent IDs, and invokes subagents through a nested `Executor` with hierarchical execution IDs. A2A, ADK, Colab, native gRPC, and Substrate actors widen the agent boundary.
- Domain-specific workflow: Good for coding-agent support patterns: shell execution, agent skills, Dockerfile-writing example agent, coding A2A example, Colab data/plot examples, Antigravity harness, trace viewer, and Kubernetes actor deployment.
- Error prevention: Confirmation-gated bash/script calls, per-conversation in-flight guards in the server, ID validation, agent-ID mismatch checks on resume, missing `last_seq` errors, fork source-sequence validation, A2A artifact dedupe, auth-required surfacing, and tests for confirmation/resume/fork paths. These are workflow guards, not a full sandbox.
- Self-learning / memory: No semantic memory or learning system. Persistence is operational: event logs, execution logs, external agent state, A2A task markers, and Agent Substrate actor suspension/resumption.
- Popular skills: Agent Skills discovery/activation, `run_skill_script`, confirmation-gated `bash`, remote agent delegation, A2A agent cards, and Substrate actor routing are the reusable "skills" of the system.

## Core Execution Path

`ax exec` creates or accepts a `conversation_id`, builds a local controller from `ax.yaml` unless `--server` is provided, wraps user input as a typed `proto.Message`, and calls `Controller.Exec`. In server mode, `ax serve` exposes the same controller over gRPC and blocks concurrent requests for the same conversation with an in-memory `inFlight` map.

The default controller builds a registry, constructs a Gemini planner, clones the current registry into an execution-local map, inserts `__planner` and `gemini`, then calls `tryResuming`. Resumption reads conversation events by sequence, replays events after `last_seq` to catch up a disconnected client, identifies pending executions, loads their execution events, and resumes with the original agent ID/config. Completed conversations with new input create a fresh execution ID.

Execution is handled by `executor.DefaultExecutor`. It loads execution history, detects unanswered confirmations, rejects agent-ID changes during resume, logs `STATE_PENDING`, calls the agent's `Connect`, buffers outputs, writes execution-output events, marks completed unless the final output is a confirmation question, and appends conversation events for non-internal outputs. `internal_only` messages stay in execution logs but are filtered from conversation events, client output, and Gemini history.

The planner loop converts registry agents into Gemini function declarations. Text parts are streamed to the client. Function calls can invoke bash, activate/run skills, or delegate to a registered agent. Delegation records a tool call, creates a compact prompt containing conversation history plus the requested prompt, calls the nested executor, then returns subagent output as a tool result.

Remote native agents implement `AgentService.Connect(AgentRequest) returns (stream AgentResponse)`. The A2A bridge resolves an AgentCard, injects configured auth headers, sends either latest user input or full history, streams events, falls back to polling, emits artifacts, persists active task state via internal markers, and translates A2A input-required states into AX confirmations.

## Architecture

The architecture has four layers:

- Interface layer: `ax` CLI, gRPC controller server, trace command, examples, Python ADK helper, and `cmd/axharness`.
- Control layer: controller, registry, planner, executor, event log, confirmation/history utilities, and server in-flight guards.
- Agent boundary layer: local `agent.Agent`, native gRPC `RemoteAgent`, A2A bridge, ADK wrapper, Colab agent, Substrate agent, and V2 harness abstractions.
- Deployment layer: Kubernetes manifests, Agent Substrate worker pool/actor template, Envoy dynamic forward proxy, and `axepp` external authorization service that parses gRPC request bodies to resume/route actors by conversation ID.

The main persistence primitive is SQLite. `conversation_log` stores sequence-numbered conversation events by conversation ID; `execution_log` stores execution events by exec ID. This is enough for local durable replay and fork/resume experiments, but it is not a distributed control-plane database.

The proto surface is intentionally broad for agent content: text, thought summaries, tool calls/results, confirmations, images, audio, documents, and video. The actual Gemini and ADK conversion paths currently support a smaller subset.

## Design Choices

AX favors controller-owned state over agent-owned state. The controller logs inputs and outputs around every agent call, and agents receive history from the controller rather than owning the primary conversation log.

Agents are tool-like. The planner sees each registered agent as a Gemini function declaration, so delegation is observable as a tool call/tool result pair instead of an opaque prompt jump.

Risky local tools use protocol-level confirmation. Bash calls and skill script calls first emit a `ToolCallContent` and a `ConfirmationContent`; only an approval message with the matching ID triggers execution. The implementation still runs approved commands on the controller host via `sh -c` and approved skill scripts as local executables.

Internal state is explicitly hidden. `internal_only` messages allow resumption data such as A2A task IDs to be persisted in execution logs without entering the client stream or model context.

The repository is mid-transition from agent execution to harness execution. `controller2` introduces a cleaner `Harness`/`Execution` lifecycle, but its `Exec` path does not yet implement event-log resumption, always closes the execution after one turn, and falls back to a test harness if a requested harness is missing.

Agent Substrate deployment uses conversation IDs as actor IDs. Envoy calls `axepp`, `axepp` extracts the conversation or destination conversation ID from the raw gRPC body, creates/resumes the actor, and returns an `x-backend-ip` header so Envoy forwards to the actor-local AX server. The default server then suspends actors after output when built with ATE support.

## Strengths

AX has a clear execution log model. The split between conversation events and execution events makes it possible to replay client-visible history while preserving hidden execution details for resumption.

The confirmation protocol is practical for coding agents. Tool calls, user approval/decline, and final tool results all share typed content, so approvals can survive stream disconnects and restarts.

The A2A bridge is more than a thin adapter. It handles AgentCard discovery, auth header injection, stateful/stateless modes, streaming and polling, artifact chunk dedupe, input-required HITL pauses, auth-required errors, and state-marker recovery.

Tests cover many important failure modes by source inspection: controller resume, `last_seq`, internal-only filtering, fork sequence validation, execution confirmation, fanout, agent-ID mismatch, SQLite concurrent append, A2A conversion/state/auth, and Controller V2 harness fallback.

The Substrate deployment pattern is valuable even if not copied directly: route by conversation ID, resume an isolated actor on demand, stream through a router, then suspend the actor when the turn is complete.

## Weaknesses

AX is explicitly early and breaking-change-prone. The README warns that core, resumption protocols, and runtime specs are still changing, and the code confirms this with parallel V1/V2 controller paths.

Security defaults are development-oriented. Native remote agents and controller clients use insecure gRPC credentials by default; ATE client paths use `InsecureSkipVerify` in several places; the ADK server adds an insecure port and states auth is not implemented. A2A has better outbound auth support, but the core AXP remote-agent path does not honor the `auth` config.

The local tool boundary is not a sandbox. After confirmation, bash executes via `sh -c` on the controller host, and skill scripts execute directly from the configured skill directory. Approval helps with user control, but it is not isolation, egress policy, filesystem containment, or per-command authorization.

The Python ADK generated proto files appear stale relative to `proto/ax.proto`: Python generated code still exposes `AgentMessage` and older services, while the Go proto uses `AgentRequest` and `AgentResponse`. The ADK wrapper therefore looks like an example under active migration rather than a reliable integration surface.

The `harness` build path appears incomplete. `cmd/ax/internal/cliutil/cliutil_harness.go` constructs `controller2.Config` without a registry, while `controller2.New` requires one; source tests instantiate the registry manually. Controller V2 also does not yet persist execution turns to the event log.

Documentation and implementation diverge in places. The skills README says omitted `skills_dir` falls back to `~/.agents/skills`, but `NewSkillsTool("")` returns a no-op unless `SKILLS_DIR` is set. Tests assert that no-dir behavior.

I could not execute the candidate's Go test suite in the review environment because `go` was not installed or reachable through `rtk`; test assessment is based on source inspection.

## Ideas To Steal

Use `conversation_id`, `exec_id`, `seq`, and event-log records as first-class runtime handles. Keep client-visible history separate from execution-private recovery data.

Represent agent delegation as function calls. A planner that calls registered agents as tools creates a clean audit trail and makes subagent boundaries easier to inspect.

Make human approval a content primitive, not a UI-only feature. Persist confirmation questions and answers with stable IDs so shell/script/HITL operations can resume after disconnects.

Adopt internal-only state markers for bridge state. This is a compact pattern for hiding operational state from the model while still letting adapters recover long-running remote tasks.

Copy the A2A bridge ideas: AgentCard-derived metadata, auth header resolution, streaming-to-poll fallback, artifact dedupe, input-required-to-confirmation mapping, and stale task cleanup.

Use actor-per-conversation deployment for expensive long-running coding tasks. Resume the actor by conversation ID, route streams to it, and suspend it after the turn to preserve state without keeping full compute active.

Use skill activation as lazy context loading. Inject only skill names/descriptions initially, then load full instructions and run scripts only when the model explicitly selects a skill.

## Do Not Copy

Do not copy insecure gRPC or `InsecureSkipVerify` defaults into a multi-tenant coding-agent runtime. Require authenticated transport, explicit trust roots, and tested authorization at every remote boundary.

Do not execute shell and skill scripts on the controller host as the long-term tool model. Put approved commands inside a sandbox, container, microVM, or remote actor with resource, filesystem, and network policy.

Do not rely on process-local context values to disable subagent confirmations across durable resume. Persist approval policy in execution state if it affects safety behavior.

Do not silently fall back to a test harness when a requested production harness is missing. That is convenient for demos but dangerous for real task routing because it can mask misconfiguration.

Do not ship generated protos or adapters that lag the authoritative proto. AX shows how quickly bridge code becomes misleading when protocol shapes are changing.

Do not adopt the V2 harness path until it has feature parity for registry setup, event logging, resumption, remote harness protocol, and security.

## Fit For Agentic Coding Lab

AX is a strong conditional candidate for the `agent-support-systems` index. It is one of the clearest current examples of a distributed agent runtime that treats execution, delegation, confirmation, resumption, and remote agent protocols as runtime primitives rather than prompt conventions.

The best Agentic Coding Lab artifacts to derive from AX are: an event-log schema, a confirmation content protocol, internal-only recovery markers, an agent-registry-to-tool adapter, A2A bridge behavior, fork/replay semantics, and actor-per-conversation deployment notes.

It is not a drop-in runtime candidate today. The lab should borrow the primitives and test cases, then pair them with a stronger sandbox, authenticated transport, stable proto generation, and a single coherent controller path.

## Reviewed Paths

- `README.md`: project status, runtime goals, quick start, controller/agent/tool diagram, CLI commands, Gemini auth, skills, bash confirmation, custom agent modes, roadmap.
- `ax.yaml` and `internal/config/config.go`: server/event-log/planner defaults, remote/A2A/auth/header/Colab/Substrate config shapes, credential-env model.
- `proto/ax.proto` and `proto/content.proto`: core services, conversation/execution events, agent request/response protocol, harness stub, typed content, confirmation, tool call/result, media payloads.
- `cmd/ax/**`: CLI command flow for `exec`, `serve`, `fork`, `trace`, remote server connection, local controller construction, signal cancellation, confirmation prompts, and display filtering.
- `internal/server/**`: gRPC server surface, in-flight conversation guard, fork/delete validation, health service, ATE actor suspension hook, harness build variant.
- `internal/controller/**`: default controller, registry, validation, ATE registration, fork/resume logic, event-log replay, internal-only filtering, tests.
- `internal/controller2/**`: harness-era controller, registry with harness map, tests for Antigravity/test harness fallback, fork behavior, and visible migration gaps.
- `internal/controller/executor/**`: default executor, nested agent executor, SQLite event log, memory test log, confirmation handling, resume behavior, fanout tests, SQLite tests.
- `internal/agent/**`: local agent interface, executor interface, native gRPC remote agent client, insecure transport default, response ID validation.
- `internal/gemini/**`: Gemini planner, agent-as-tool conversion, bash tool, skills tool, subagent delegation, confirmation answer handling, proto-to-Gemini conversion, tests.
- `internal/skills/**` and `examples/skills/**`: Agent Skills discovery, metadata parsing, script path restrictions, tool schema, sample skills, documented fallback mismatch.
- `internal/experimental/a2abridge/**` and `internal/experimental/agent/a2a.go`: A2A card resolution, auth interception, content conversion, state markers, stream/poll handling, artifact emission, HITL confirmation, tests.
- `python/adk/**`, `examples/adk_agent/**`, and `examples/a2a_agent/**`: ADK wrapper, stale Python proto surface, A2A coding-agent example, optional auth, generated-file constraints.
- `internal/experimental/agent/colab.go` and `examples/colab_agent/**`: Colab session lifecycle, Drive auth, requirements install, notebook/script execution, retry and cleanup behavior.
- `internal/harness/**`, `cmd/axharness/**`, `examples/antigravity_agent/**`, and `e2e.go`: harness abstraction, Substrate harness, stub harness service, Antigravity subprocess harness, demo fallback behavior.
- `internal/experimental/k8s/ate/**`, `cmd/axepp/main.go`, `manifests/**`, and `hack/install-ax.sh`: Agent Substrate control API client, actor create/resume/suspend, Envoy ext_authz routing, Kubernetes worker pool/template/service deployment.
- `examples/docker_agent/**` and `examples/remote_agent/**`: native remote-agent examples, Docker skill agent, server-streaming AgentService usage.
- `Makefile`, `go.mod`, and test files under `internal/**`: build tags, image targets, dependency posture, and source-level test coverage.

## Excluded Paths

- `proto/*.pb.go`, `python/proto/*_pb2*.py`, and other generated protobuf files: excluded from detailed implementation review except where the stale Python generated surface affected ADK integration assessment.
- `go.sum`: dependency lock data; reviewed only through `go.mod` for runtime dependency shape.
- `.github/**`, `.gitignore`, `.dockerignore`, `.ko.yaml`, `LICENSE`, and `CONTRIBUTING.md`: repository operations and legal metadata, not runtime architecture.
- Notebook and binary/demo outputs under `examples/colab_agent/*.ipynb` and potential example output directories: examples were reviewed through code and README files rather than notebook cell contents.
- Trace UI HTML/JavaScript embedded in `cmd/ax/trace.go`: noted as an observability feature, not deeply reviewed because it is not an execution or security boundary.
- Generated or deployment-rendered manifests under `internal/manifests/**`: reviewed representative public manifests and deployment script instead of duplicate or transitional manifests.
- External systems referenced by docs, such as Agent Substrate implementation internals, Google Antigravity package internals, Gemini service behavior, and Colab CLI internals: treated as dependencies and not vendored source.
